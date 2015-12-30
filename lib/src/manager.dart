library hotkey.src.manager;

import 'dart:async';
import 'dart:html';

import 'package:hotkey/src/binding.dart';
import 'package:hotkey/src/combination.dart';
import 'package:hotkey/src/event_provider.dart';
import 'package:hotkey/src/typedefs.dart';

// TODO: Add getter for "help" data structure based on descriptions and available bindings.
// TODO: Crib whatever we can from datatables hotkey manager.
// TODO: Contextual hotkeys that fire only when a particular element has focus.
// TODO: Consider allowing consumers to temporarily override handlers (stack).
// FIXME: Do not reset matching when the only key pressed was a modifier.
class KeyBindingsManager {
  /// The maximum amount of time the manager will wait between kepresses
  /// before assuming that the user has abandoned the sequence and
  /// resetting itself.
  static final Duration sequenceTimeout = const Duration(seconds: 1);

  /// A tree of bindings. Each inner node represents a parsed binding
  /// combination, such as "CTRL+N", or "CTRL+SHIFT+INSERT". Each leaf
  /// is a callback function to be called when the binding sequence
  /// that forms the path to that leaf from the root is detected.
  final Map<Combination, dynamic> _bindingsTree = {};

  /// The current position in the bindings tree, based on the last
  /// keyboard event observed.
  dynamic _currentNode;

  Timer _timeoutTimer;

  EventProvider _provider;

  KeyBindingsManager() {
    _provider = new KeyboardEventProvider(window);
    _initialize();
  }

  KeyBindingsManager.forTarget(EventTarget target) {
    _provider = new KeyboardEventProvider(target);
    _initialize();
  }

  KeyBindingsManager.withProvider(EventProvider provider) {
    _provider = provider;
    _initialize();
  }

  // TODO: Add optional [description] parameter.
  void add(String bindingsString, KeyBindingCallback callback) {
    var bindings = parseBindingsString(bindingsString);
    bindings.forEach((sequence) {
      Map previous = null;
      var current = _bindingsTree;
      sequence.forEach((combo) {
        if (current is Map) {
          previous = current;
          current = current.putIfAbsent(combo, () => {});
        } else {
          throw new ArgumentError(
              'Key binding "$sequence" shadows an existing key binding.');
        }
      });
      previous[sequence.last] = () => callback(sequence);
    });
  }

  void addAll(Map<String, KeyBindingCallback> bindings) {
    bindings
        .forEach((bindingsString, callback) => add(bindingsString, callback));
  }

  void remove(String bindingsString) {
    var bindings = parseBindingsString(bindingsString);
    Map previous = null;
    var current = _bindingsTree;
    bindings.forEach((binding) {
      binding.forEach((combo) {
        if (current is Map) {
          previous = current;
          current = current.putIfAbsent(combo, () => {});
        } else {
          throw new ArgumentError(
              'Key binding "$binding" does not currently exist.');
        }
      });
      previous.remove(binding.last);
    });
  }

  void removeAll() {
    for (var key in _bindingsTree.keys.toList()) {
      _bindingsTree.remove(key);
    }
  }

  void _detectSequence(KeyEvent event) {
    // We do this check here because the user pressing a key that
    // isn't allowed to be part of a combination is not an error.
    if (!Combination.ALLOWED_KEYS.containsKey(event.keyCode)) {
      _resetCurrentNode();
      return;
    }

    // Allow textareas and such to capture the user input without
    // triggering key bindings unless modifiers are held down.
    var activeElement = _getActiveElement(event.target);
    if (_isEditable(activeElement) &&
        !event.ctrlKey &&
        !event.altKey &&
        !event.metaKey) {
      _resetCurrentNode();
      return;
    }

    _resetTimeout();

    var combo = new Combination.fromKeyboardEvent(event);
    _currentNode = _currentNode[combo];

    if (_currentNode == null) {
      // Abandon the current string of combinations and start
      // over from the beginning if that would give us something
      // valid, otherwise just reset and wait.
      _currentNode = _bindingsTree[combo] ?? _bindingsTree;
    }

    if (_currentNode is Map) {
      return;
    }

    // TODO: Find a more elegant way to express this.
    if (_currentNode is Function) {
      _currentNode();
    } else {
      assert(false); // This can't happen
    }

    _currentNode = _bindingsTree;

    event.preventDefault();
    event.stopPropagation();
  }

  /// Returns the true active element, even across Shadow DOM boundaries.
  Element _getActiveElement(Element root) {
    if (root == null) {
      root = document.activeElement;
    }
    while (root.shadowRoot != null) {
      root = root.shadowRoot.activeElement;
    }
    return root;
  }

  void _initialize() {
    _currentNode = _bindingsTree;
    // TODO: Should we keep track of the subscription? Would we ever cancel it?
    _provider.stream.listen(_detectSequence);
  }

  /// Tests whether [element] is an editable element.
  bool _isEditable(Element element) {
    if (element is TextAreaElement) {
      return !element.disabled;
    }
    if (element is InputElement) {
      return !element.disabled &&
          (element.type == 'tel' ||
              element.type == 'text' ||
              element.type == 'email' ||
              element.type == 'search' ||
              element.type == 'password');
    }
    while (element != null) {
      if (element.isContentEditable) {
        return true;
      }
      element = element.parent;
    }
    return false;
  }

  void _resetCurrentNode() {
    _currentNode = _bindingsTree;
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = new Timer(sequenceTimeout, _resetCurrentNode);
  }
}

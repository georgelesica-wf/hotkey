library hotkey.src.manager;

import 'dart:html';

import 'package:hotkey/src/binding.dart';
import 'package:hotkey/src/combination.dart';
import 'package:hotkey/src/typedefs.dart';

class KeyBindingsManager {
  /// Delimiter to specify different key bindings for the same action.
  /// For example, to bind two hotkeys 'CTRL+ENTER' and 'ALT+S' to an action,
  /// set its key combination to 'CTRL+ENTER | ALT+S'.
  static final String BINDING_DELIMITER = '|';

  /// The delimiter to separate key combinations within a key binding.
  /// Example: 'CTRL+M > CTRL+I' means pressing CTRL + G then CTRL + I.
  static final String SEQUENCE_DELIMITER = '>';

  /// A tree of bindings. Each inner node represents a parsed binding
  /// combination, such as "CTRL+N", or "CTRL+SHIFT+INSERT". Each leaf
  /// is a callback function to be called when the binding sequence
  /// that forms the path to that leaf from the root is detected.
  final Map<Combination, dynamic> _bindingsTree = {};

  /// The current position in the bindings tree, based on the last
  /// keyboard event observed.
  dynamic _currentNode;

  KeyBindingsManager() {
    _currentNode = _bindingsTree;
    _subscribe(window);
  }

  KeyBindingsManager.forTarget(EventTarget target) {
    _subscribe(target);
  }

  void add(String bindingsString, KeyBindingCallback callback) {
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
              'Key binding "$binding" shadows an existing key binding.');
        }
      });
      previous[binding.last] = callback;
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

  void _detectKeyBindingPress(KeyboardEvent event) {
    // We do this check here because the user pressing a key that
    // isn't allowed to be part of a combination is not an error.
    if (!Combination.ALLOWED_KEYS.containsKey(event.keyCode)) {
      return;
    }

    // Allow textareas and such to capture the user input without
    // triggering key bindings unless modifiers are held down.
    var activeElement = _getActiveElement(event.target);
    if (_isEditable(activeElement) &&
        !event.ctrlKey &&
        !event.altKey &&
        !event.metaKey) {
      return;
    }

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
    if (_currentNode is KeyBindingCallback) {
      _currentNode(combo);
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

  void _subscribe(EventTarget target) {
    // TODO: Should we keep track of the subscription? Would we ever cancel it?
    Element.keyDownEvent
        .forTarget(target, useCapture: true)
        .listen(_detectKeyBindingPress);
  }
}

library hotkey.src.manager;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:hotkey/src/binding.dart';
import 'package:hotkey/src/combination.dart';
import 'package:hotkey/src/event_provider.dart';
import 'package:hotkey/src/handler.dart';
import 'package:hotkey/src/typedefs.dart';

// TODO: DT may want us to support scroll lock.
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

  List<Handler> _handlers = [];

  /// Used internally for tree traversal bookkeeping.
  Queue<Map> _vertexStack = new Queue();

  /// Used internally for tree traversal bookkeeping.
  Queue<Combination> _edgeStack = new Queue();

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

  Iterable<Handler> get handlers => _handlers;

  void addAll(Map<String, KeyBindingCallback> bindings, {bool replace: false}) {
    bindings.forEach((bindingsString, callback) =>
        addBinding(bindingsString, callback, replace: replace));
  }

  /// Add a key binding to the manager. Accepts a [bindingString], which
  /// can actually specify more than one key combination sequence, and a
  /// [callback] that will be called when one of the associated
  /// sequences is detected and will be passed the sequence that was
  /// actually detected.
  ///
  /// Some example bindings strings are given below:
  ///
  /// ```
  /// CTRL+A
  /// CTRL+A > CTRL+B // CTRL+A followed by CTRL+B
  /// CTRL+A | CTRL+B // CTRL+A and CTRL+B do the same thing.
  /// ```
  ///
  /// Optionally, a description may be provided. This will be included
  /// in the [Handler] that is created for the key binding and can be
  /// accessed by iterating over the [handlers] property of the manager.
  ///
  /// If [selector] is specified, and is a CSS selector that identifies
  /// one or more focusable DOM elements, the key binding will only
  /// call the callback when one of those DOM elements has focus. Otherwise
  /// it will do nothing.
  ///
  /// By default, attempting to overwrite or shadow an existing binding
  /// will result in an exception. If `replace` is `true`, however, any
  /// existing bindings that would be made ambiguous or redundant
  /// will be removed before the new binding is added.
  void addBinding(String bindingsString, KeyBindingCallback callback,
      {String description: '', String selector: '', bool replace: false}) {
    var bindings = parseBindingsString(bindingsString);
    for (var sequence in bindings) {
      _addHandler(
          new Handler(sequence, callback,
              description: description, selector: selector),
          replace: replace);
    }
  }

  /// Remove all key bindings from this manager.
  void removeAll() {
    for (var key in _bindingsTree.keys.toList()) {
      _bindingsTree.remove(key);
    }
    _handlers = [];
  }

  /// Remove a binding based on its binding string. If the original
  /// binding string that was used to add the handler consisted of
  /// several OR'd parts (separated with `|`), a subset of the parts
  /// may be specified for removal and only those parts will be
  /// removed.
  ///
  /// If a binding is to be removed only to be immediately replaced,
  /// consider using the `replace` parameter of `addBinding` instead.
  void removeBinding(String bindingsString) {
    var bindings = parseBindingsString(bindingsString);
    bindings.forEach((sequence) {
      _removeSequence(sequence);
    });
  }

  void _addHandler(Handler handler, {bool replace: false}) {
    var previous = null;
    var current = _bindingsTree;
    for (var combo in handler.sequence) {
      if (current is Map) {
        previous = current;
        current = current.putIfAbsent(combo, () => {});
      } else {
        throw new ArgumentError(
            'Key binding "${handler.sequence}" shadows existing key binding.'
            ' Try adding `replace: true` to replace the handler.');
      }
    }

    if (current is Handler || current.keys.isNotEmpty) {
      // We ran into a leaf node or we didn't make it to the leaves.
      // Either way, if we are replacing, we need to remove everything
      // below us in the tree, then try to add the [Handler] again.
      // The recursion can never go more than one level deep.
      _pruneTree(current);
      _addHandler(handler);
      return;
    }

    assert(previous is Map);
    assert(current is Map);

    previous[handler.sequence.last] = handler;
    _handlers.add(handler);
  }

  void _detectSequence(KeyEvent event) {
    // Check for presses on modifier keys. This indicates that the
    // user may be changing to a different modifier as part of a
    // sequence, like Ctrl+A > Alt+B, so we don't want to reset.
    if (Combination.MODIFIER_CODES.contains(event.keyCode)) {
      return;
    }

    // If the user presses a key that isn't allowed to be a part
    // of a key binding (and isn't a modifier, which would have
    // been caught above), then we want to reset our state.
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

    var combo = new Combination.fromKeyEvent(event);
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

    // At this point we should have a [Handler], if we don't,
    // then something went terribly wrong and we have a bug.
    assert(_currentNode is Handler);
    Handler handler = _currentNode;

    // Abort if the active element doesn't match the selector
    // specified for this handler.
    if (handler.selector != '') {
      var elements = querySelectorAll(handler.selector);
      if (!elements.contains(activeElement)) {
        _resetCurrentNode();
        return;
      }
    }

    handler();
    _resetCurrentNode();

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

  /// Find all [Handler] objects (leaves) that are below [pruneRoot] in
  /// the tree and remove them. This is recursive, but doing it this way
  /// is conceptually simpler than the alternative, and the tree is never
  /// expected to be more than two or three levels deep.
  void _pruneTree(pruneRoot) {
    if (pruneRoot is Handler) {
      _removeHandler(pruneRoot);
      return;
    }

    assert(pruneRoot is Map);

    for (var nextRoot in pruneRoot.values) {
      _pruneTree(nextRoot);
    }
  }

  /// Remove a [Handler] from the manager.
  void _removeHandler(Handler handler) {
    _removeSequence(handler.sequence);
  }

  /// Remove the [Handler] that exactly matches a particular sequence
  /// of key combinations. If the sequence doesn't match exactly,
  /// do nothing.
  void _removeSequence(Iterable<Combination> sequence) {
    _vertexStack.clear();
    _edgeStack.clear();

    var current = _bindingsTree;
    for (var combo in sequence) {
      if (current is Map) {
        _vertexStack.addFirst(current);
        _edgeStack.addFirst(combo);
        current = current[combo];
      } else {
        // Sequence was too long.
        return;
      }
    }

    if (current is Map) {
      // Sequence was too short.
      return;
    }

    assert(current is Handler);

    while (_vertexStack.isNotEmpty) {
      var vertex = _vertexStack.removeFirst();
      var combo = _edgeStack.removeFirst();
      vertex.remove(combo);
      if (vertex.keys.length > 0) {
        break;
      }
    }

    _handlers.remove(current);
  }

  void _resetCurrentNode() {
    _currentNode = _bindingsTree;
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = new Timer(sequenceTimeout, _resetCurrentNode);
  }
}

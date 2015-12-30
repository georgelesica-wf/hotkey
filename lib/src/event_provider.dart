library hotkey.src.event_provider;

import 'dart:async';
import 'dart:html';

abstract class EventProvider {
  Stream<KeyEvent> stream;

  EventProvider();
}

class KeyboardEventProvider extends EventProvider {
  StreamController<KeyEvent> _controller;

  KeyboardEventProvider(EventTarget target) {
    _controller = new StreamController();
    stream = _controller.stream;

    Element.keyDownEvent
        .forTarget(target, useCapture: true)
        .listen(_handleKeyboardEvent);
  }

  void _handleKeyboardEvent(KeyboardEvent event) {
    KeyEvent keyEvent = new KeyEvent.wrap(event);
    _controller.add(keyEvent);
  }
}

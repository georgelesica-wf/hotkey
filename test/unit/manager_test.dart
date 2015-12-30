@TestOn('browser')
@Timeout(const Duration(seconds: 3))
library hotkey.test.manager_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';

import 'package:hotkey/hotkey.dart';
import '../../lib/src/combination.dart';

// We inject this provider so that we can avoid Dart's brokenness related
// to programmatically creating keyboard events.
class KeyEventProvider extends EventProvider {
  StreamController<KeyEvent> _controller;

  KeyEventProvider() {
    _controller = new StreamController();
    stream = _controller.stream;
  }

  void add(KeyEvent event) {
    _controller.add(event);
  }
}

main() {
  group('KeyBindingsManager', () {
    KeyEventProvider provider;
    KeyBindingsManager manager;

    void typeCombo(String char,
        {bool control: false,
        bool alt: false,
        bool meta: false,
        bool shift: false,
        EventTarget target}) {
      target ??= window;
      var keyCode = Combination.ALLOWED_KEYS.inverse[char.toUpperCase()];
      var keyEvent = new KeyEvent('keydown',
          keyCode: keyCode,
          ctrlKey: control,
          altKey: alt,
          metaKey: meta,
          shiftKey: shift);
      provider.add(keyEvent);
    }

    void typeCode(int keyCode) {
      var keyEvent = new KeyEvent('keydown', keyCode: keyCode);
      provider.add(keyEvent);
    }

    Map<String, Function> sequences = {
      'CTRL+A > CTRL+A': () {
        typeCombo('A', control: true);
        typeCombo('A', control: true);
      },
      'CTRL+B': () {
        typeCombo('B', control: true);
      },
      // Bare key.
      'C': () {
        typeCombo('C');
      },
      // Alt key.
      'CTRL+SHIFT+D > ALT+E': () {
        typeCombo('D', control: true, shift: true);
        typeCombo('E', alt: true);
      },
      // Meta key.
      'META+F': () {
        typeCombo('F', meta: true);
      },
      // Shift key.
      'SHIFT+F': () {
        typeCombo('F', shift: true);
      },
      // Next two are both sides of an "or".
      'CTRL+G | ALT+G': () {
        typeCombo('G', control: true);
      },
      'CTRL+H | ALT+H': () {
        typeCombo('H', alt: true);
      },
      // Meta keypresses interleaved into sequence.
      'CTRL+I > ALT+I': () {
        typeCombo('I', control: true);
        typeCode(KeyCode.ALT);
        typeCombo('I', alt: true);
      }
    };

    setUp(() {
      provider = new KeyEventProvider();
      manager = new KeyBindingsManager.withProvider(provider);
    });

    for (var sequence in sequences.keys) {
      test('should respond to the key sequence "$sequence"', () {
        manager.add(sequence, expectAsync((_) {}));
        sequences[sequence]();
      });
    }

    group('timeout', () {
      test('should reset sequence after too long between keypresses', () async {
        manager.add('CTRL+A > CTRL+A', expectAsync((_) {}, count: 0));
        typeCombo('A', control: true);
        // Wait slightly longer than the timeout.
        await new Future.delayed(KeyBindingsManager.sequenceTimeout * 1.1);
        typeCombo('A', control: true);
      });
    });
  });
}
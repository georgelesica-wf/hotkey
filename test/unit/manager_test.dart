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
        bool shift: false}) {
      var keyCode = Combination.ALLOWED_KEYS.inverse[char.toUpperCase()];
      var keyEvent = new KeyEvent('keydown',
          keyCode: keyCode,
          ctrlKey: control,
          altKey: alt,
          metaKey: meta,
          shiftKey: shift);
      provider.add(keyEvent);
    }

    void typeCode(int keyCode,
        {bool control: false,
        bool alt: false,
        bool meta: false,
        bool shift: false}) {
      var keyEvent = new KeyEvent('keydown',
          keyCode: keyCode,
          ctrlKey: control,
          altKey: alt,
          metaKey: meta,
          shiftKey: shift);
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
      // Modifier keypresses interleaved into sequence.
      'CTRL+I > ALT+I': () {
        typeCombo('I', control: true);
        typeCode(KeyCode.ALT);
        typeCombo('I', alt: true);
      },
      // Arrow keys.
      'CTRL+UP': () {
        typeCode(KeyCode.UP, control: true);
      },
      'CTRL+LEFT': () {
        typeCode(KeyCode.LEFT, control: true);
      },
      // Brackets.
      'CTRL+[': () {
        typeCombo('[', control: true);
      }
    };

    setUp(() {
      provider = new KeyEventProvider();
      manager = new KeyBindingsManager.withProvider(provider);
    });

    for (var sequence in sequences.keys) {
      test('should respond to the key sequence "$sequence"', () {
        manager.addBinding(sequence, expectAsync((_) {}));
        sequences[sequence]();
      });
    }

    group('addBinding', () {
      test('should add the indicated binding', () {
        manager.addBinding('CTRL+A', (_) {});
        expect(manager.handlers.length, equals(1));
      });

      test('should overwrite a binding if `replace: true` is used', () {
        manager.addBinding('CTRL+A', expectAsync((_) {}, count: 0));
        expect(manager.handlers.length, equals(1));
        manager.addBinding('CTRL+A', expectAsync((_) {}, count: 1),
            replace: true);
        typeCombo('A', control: true);
        expect(manager.handlers.length, equals(1));
      });
    });

    group('removeBinding', () {
      test('should remove the indicated binding', () {
        manager.addBinding('CTRL+A', (_) {});
        expect(manager.handlers.length, equals(1));
        manager.removeBinding('CTRL+A');
        expect(manager.handlers, isEmpty);
      });
    });

    group('timeout', () {
      test('should reset sequence after too long between keypresses', () async {
        manager.addBinding('CTRL+A > CTRL+A', expectAsync((_) {}, count: 0));
        typeCombo('A', control: true);
        // Wait slightly longer than the timeout.
        await new Future.delayed(KeyBindingsManager.sequenceTimeout * 1.1);
        typeCombo('A', control: true);
      });
    });
  });
}

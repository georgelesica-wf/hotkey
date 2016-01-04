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
        {bool ctrlKey: false,
        bool altKey: false,
        bool metaKey: false,
        bool shiftKey: false}) {
      var keyCode = Combination.ALLOWED_KEYS.inverse[char.toUpperCase()];
      var keyEvent = new KeyEvent('keydown',
          keyCode: keyCode,
          ctrlKey: ctrlKey,
          altKey: altKey,
          metaKey: metaKey,
          shiftKey: shiftKey);
      provider.add(keyEvent);
    }

    void typeCode(int keyCode,
        {bool ctrlKey: false,
        bool altKey: false,
        bool metaKey: false,
        bool shiftKey: false}) {
      var keyEvent = new KeyEvent('keydown',
          keyCode: keyCode,
          ctrlKey: ctrlKey,
          altKey: altKey,
          metaKey: metaKey,
          shiftKey: shiftKey);
      provider.add(keyEvent);
    }

    Map<String, Function> sequences = {
      'CTRL+A > CTRL+A': () {
        typeCombo('A', ctrlKey: true);
        typeCombo('A', ctrlKey: true);
      },
      'CTRL+B': () {
        typeCombo('B', ctrlKey: true);
      },
      // Bare key.
      'C': () {
        typeCombo('C');
      },
      // Alt key.
      'CTRL+SHIFT+D > ALT+E': () {
        typeCombo('D', ctrlKey: true, shiftKey: true);
        typeCombo('E', altKey: true);
      },
      // Meta key.
      'META+F': () {
        typeCombo('F', metaKey: true);
      },
      // Shift key.
      'SHIFT+F': () {
        typeCombo('F', shiftKey: true);
      },
      // Next two are both sides of an "or".
      'CTRL+G | ALT+G': () {
        typeCombo('G', ctrlKey: true);
      },
      'CTRL+H | ALT+H': () {
        typeCombo('H', altKey: true);
      },
      // Modifier keypresses interleaved into sequence.
      'CTRL+I > ALT+I': () {
        typeCombo('I', ctrlKey: true);
        typeCode(KeyCode.ALT);
        typeCombo('I', altKey: true);
      },
      // Arrow keys.
      'CTRL+UP': () {
        typeCode(KeyCode.UP, ctrlKey: true);
      },
      'CTRL+LEFT': () {
        typeCode(KeyCode.LEFT, ctrlKey: true);
      },
      // Brackets.
      'CTRL+[': () {
        typeCombo('[', ctrlKey: true);
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
        typeCombo('A', ctrlKey: true);
        expect(manager.handlers.length, equals(1));
      });

      test('should overwrite all shadowed bindings when replace is true', () {
        manager.addBinding('CTRL+A > CTRL+B', expectAsync((_) {}, count: 0));
        expect(manager.handlers.length, equals(1));
        manager.addBinding('CTRL+A > CTRL+C', expectAsync((_) {}, count: 0));
        expect(manager.handlers.length, equals(2));
        manager.addBinding('CTRL+A', expectAsync((_) {}, count: 3),
            replace: true);
        expect(manager.handlers.length, equals(1));

        typeCombo('A', ctrlKey: true);

        typeCombo('A', ctrlKey: true);
        typeCombo('B', ctrlKey: true);

        typeCombo('A', ctrlKey: true);
        typeCombo('C', ctrlKey: true);
      });

      test('should throw exception on overwrite if `replace` is false', () {
        manager.addBinding('CTRL+A', expectAsync((_) {}, count: 0));
        expect(manager.handlers.length, equals(1));
        expect(
            () => manager.addBinding('CTRL+A', expectAsync((_) {}, count: 0)),
            throwsArgumentError);
      });
    });

    group('removeBinding', () {
      test('should remove the indicated binding', () {
        manager.addBinding('CTRL+A', (_) {});
        expect(manager.handlers.length, equals(1));
        manager.removeBinding('CTRL+A');
        expect(manager.handlers, isEmpty);
      });

      test('should do nothing if binding does not match a handler', () {
        manager.addBinding('CTRL+A', (_) {});
        expect(manager.handlers.length, equals(1));
        manager.removeBinding('CTRL+B');
        expect(manager.handlers.length, equals(1));
      });
    });

    group('timeout', () {
      test('should reset sequence after too long between keypresses', () async {
        manager.addBinding('CTRL+A > CTRL+A', expectAsync((_) {}, count: 0));
        typeCombo('A', ctrlKey: true);
        // Wait slightly longer than the timeout.
        await new Future.delayed(KeyBindingsManager.sequenceTimeout * 1.1);
        typeCombo('A', ctrlKey: true);
      });
    });
  });
}

@TestOn('browser')
library hotkey.test.combination;

import 'dart:html';

import 'package:test/test.dart';

import '../../lib/src/combination.dart';

main() {
  group('Combination', () {
    test('should construct from a binding string', () {
      var combo = new Combination.fromString('CTRL+A');
      expect(combo.keyCode, equals(Combination.ALLOWED_KEYS.inverse['A']));
      expect(combo.keyString, equals('A'));
      expect(combo.control, isTrue);
    });

    test('should construct from a complex binding string', () {
      var combo = new Combination.fromString('ALT+META+SHIFT+CTRL+A');
      expect(combo.keyCode, equals(Combination.ALLOWED_KEYS.inverse['A']));
      expect(combo.keyString, equals('A'));
      expect(combo.control, isTrue);
      expect(combo.alt, isTrue);
      expect(combo.meta, isTrue);
      expect(combo.shift, isTrue);
    });

    test('should construct from a KeyEvent', () {
      var combo = new Combination.fromKeyEvent(new KeyEvent('keydown',
          keyCode: Combination.ALLOWED_KEYS.inverse['A'], ctrlKey: true));
      expect(combo.keyCode, equals(Combination.ALLOWED_KEYS.inverse['A']));
      expect(combo.keyString, equals('A'));
      expect(combo.control, isTrue);
    });

    test('should compare on value', () {
      var combo0 = new Combination.fromString('CTRL+A');
      var combo1 = new Combination.fromString('CTRL+A');
      expect(combo0, equals(combo1));
    });
  });
}

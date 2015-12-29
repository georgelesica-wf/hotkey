@TestOn('browser')
library hotkey.test.binding_test;

import 'package:test/test.dart';

import '../../lib/src/binding.dart';

main() {
  group('parseBindingsString', () {
    test('should parse multiple bindings', () {
      var parsed = parseBindingsString('CTRL+A | CTRL+B');

      expect(parsed.length, equals(2));
      expect(parsed[0].length, equals(1));
      expect(parsed[1].length, equals(1));
      expect(parsed[0][0].toString(), equals('CTRL+A'));
      expect(parsed[1][0].toString(), equals('CTRL+B'));
    });

    test('should parse a sequence', () {
      var parsed = parseBindingsString('CTRL+A > CTRL+B');

      expect(parsed.length, equals(1));
      expect(parsed[0].length, equals(2));
      expect(parsed[0][0].toString(), equals('CTRL+A'));
      expect(parsed[0][1].toString(), equals('CTRL+B'));
    });

    test('should parse multiple sequences', () {
      var parsed = parseBindingsString('CTRL+A > CTRL+B | CTRL+C > CTRL+D');

      expect(parsed.length, equals(2));
      expect(parsed[0].length, equals(2));
      expect(parsed[1].length, equals(2));
      expect(parsed[0][0].toString(), equals('CTRL+A'));
      expect(parsed[0][1].toString(), equals('CTRL+B'));
      expect(parsed[1][0].toString(), equals('CTRL+C'));
      expect(parsed[1][1].toString(), equals('CTRL+D'));
    });

    test('should parse all modifier keys', () {
      void testModifierKey(key) {
        var parsed = parseBindingsString('$key+A');

        expect(parsed.length, equals(1));
        expect(parsed[0].length, equals(1));
        expect(parsed[0][0].toString(), equals('$key+A'));
      }

      testModifierKey('ALT');
      testModifierKey('CTRL');
      testModifierKey('META');
      testModifierKey('SHIFT');
    });

    test('should parse bindings with multiple modifiers', () {
      var parsed = parseBindingsString('CTRL+ALT+A');

      expect(parsed.length, equals(1));
      expect(parsed[0].length, equals(1));
      expect(parsed[0][0].toString(), equals('ALT+CTRL+A'));
    });
  });
}
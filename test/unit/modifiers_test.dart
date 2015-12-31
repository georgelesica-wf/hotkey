@TestOn('vm')
library hotkey.test.combination;

import 'package:test/test.dart';

import 'package:hotkey/src/modifiers.dart';

main() {
  group('ModifierKeys', () {
    test('should support inequality', () {
      expect(noKey, equals(noKey));
      expect(altKey, equals(altKey));
      expect(ctrlKey, equals(ctrlKey));
      expect(metaKey, equals(metaKey));
      expect(shiftKey, equals(shiftKey));
    });

    test('should support addition (combination)', () {
      var noAltShiftKeys = noKey + altKey + shiftKey;
      expect(noAltShiftKeys.flag, equals(9));
      var altCtrlKeys = altKey + ctrlKey;
      expect(altCtrlKeys.flag, equals(3));
      var altCtrlMetaKeys = altKey + ctrlKey + metaKey;
      expect(altCtrlMetaKeys.flag, equals(7));
    });

    test('should update string representation', () {
      expect(altKey.toString(), equals('ALT'));
      expect((altKey + shiftKey).toString(), equals('ALT+SHIFT'));
    });
  });
}

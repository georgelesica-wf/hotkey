library hotkey.src.combination;

import 'dart:html';

import 'package:quiver/collection.dart';

import 'package:hotkey/src/constants.dart';
import 'package:hotkey/src/modifiers.dart';

class Combination {
  int _keyCode;
  String _keyString;
  Modifiers _modifiers;

  int _hashCode;

  int get keyCode => _keyCode;

  String get keyString => _keyString;

  Modifiers get modifiers => _modifiers;

  Combination(int keyCode, Modifiers modifiers) {
    if (!ALLOWED_KEYS.containsKey(keyCode)) {
      throw new ArgumentError('Invalid key code: $keyCode');
    }

    _keyCode = keyCode;
    _keyString = ALLOWED_KEYS[keyCode];
    _modifiers = modifiers;
  }

  factory Combination.fromKeyEvent(KeyEvent event) {
    Modifiers modifiers = noKey;
    if (event.altKey) {
      modifiers += altKey;
    }
    if (event.ctrlKey) {
      modifiers += ctrlKey;
    }
    if (event.metaKey) {
      modifiers += metaKey;
    }
    if (event.shiftKey) {
      modifiers += shiftKey;
    }
    return new Combination(event.keyCode, modifiers);
  }

  factory Combination.fromString(String comboString) {
    var keyCode;
    Modifiers modifiers = noKey;

    var tokens = _tokenize(comboString);
    tokens.forEach((t) {
      switch (t) {
        case 'ALT':
          modifiers += altKey;
          break;
        case 'CTRL':
          modifiers += ctrlKey;
          break;
        case 'META':
          modifiers += metaKey;
          break;
        case 'SHIFT':
          modifiers += shiftKey;
          break;
        default:
          keyCode = keyCode ?? ALLOWED_KEYS.inverse[t];
          break;
      }
    });

    return new Combination(keyCode, modifiers);
  }

  /// Allowed key identifiers used in key bindings.
  static final BiMap<int, String> ALLOWED_KEYS = new BiMap()
    ..addAll({
      8: 'BACKSPACE',
      9: 'TAB',
      13: 'ENTER',
      19: 'PAUSE',
      20: 'CAPS_LOCK',
      27: 'ESC',
      32: 'SPACE',
      33: 'PAGE_UP',
      34: 'PAGE_DOWN',
      35: 'END',
      36: 'HOME',
      37: 'LEFT',
      38: 'UP',
      39: 'RIGHT',
      40: 'DOWN',
      45: 'INSERT',
      46: 'DELETE',
      48: '0',
      49: '1',
      50: '2',
      51: '3',
      52: '4',
      53: '5',
      54: '6',
      55: '7',
      56: '8',
      57: '9',
      65: 'A',
      66: 'B',
      67: 'C',
      68: 'D',
      69: 'E',
      70: 'F',
      71: 'G',
      72: 'H',
      73: 'I',
      74: 'J',
      75: 'K',
      76: 'L',
      77: 'M',
      78: 'N',
      79: 'O',
      80: 'P',
      81: 'Q',
      82: 'R',
      83: 'S',
      84: 'T',
      85: 'U',
      86: 'V',
      87: 'W',
      88: 'X',
      89: 'Y',
      90: 'Z',
      112: 'F1',
      113: 'F2',
      114: 'F3',
      115: 'F4',
      116: 'F5',
      117: 'F6',
      118: 'F7',
      119: 'F8',
      120: 'F9',
      121: 'F10',
      122: 'F11',
      123: 'F12',
      144: 'NUM_LOCK',
      145: 'SCROLL_LOCK',
      186: ';',
      187: '=',
      188: ',',
      189: '-',
      190: '.',
      191: '/',
      192: '`',
      219: '[',
      220: '\\', // \
      221: ']',
      222: '\'' // '
    });

  /// Allowed modifiers used in key bindings.
  static final List<String> ALLOWED_MODIFIERS = const [
    'ALT',
    'CTRL',
    'META',
    'SHIFT'
  ];

  /// Some of the modifier keys have multiple codes, partly because of
  /// the differences between Mac and PC keyboards. This provides a
  /// list of all of the key codes that could possibly be associated
  /// with modifier keys.
  static final List<String> MODIFIER_CODES = const [
    16, // shift
    17, // ctrl
    18, // alt
    91, // windows logo (left) / left cmd
    92, // windows logo (right)
    93 // windows menu / right cmd
  ];

  static final RegExp _whitespace = new RegExp(r'\s+');

  /// Breaks a binding string into tokens and does some basic syntax checking
  /// on the result. If you want to reject a string for any reason, this is
  /// probably the best place to do so.
  static List<String> _tokenize(String comboString) {
    var tokens = comboString
        .replaceAll(_whitespace, '')
        .toUpperCase()
        .split(KEY_DELIMITER);
    int modifiersCount = 0;
    int nonModifiersCount = 0;
    tokens.forEach((t) {
      if (ALLOWED_MODIFIERS.contains(t)) {
        modifiersCount += 1;
      }
      if (ALLOWED_KEYS.containsValue(t)) {
        nonModifiersCount += 1;
      }
    });
    if (nonModifiersCount != 1 ||
        nonModifiersCount + modifiersCount != tokens.length) {
      throw new ArgumentError('Invalid binding string: $comboString');
    }
    return tokens;
  }

  bool operator ==(other) => other is Combination && other.hashCode == hashCode;

  int get hashCode {
    if (_hashCode != null) {
      return _hashCode;
    }
    // TODO: This shouldn't use details about the Modifiers implementation.
    return _keyCode * 100 + _modifiers.hashCode;
  }

  String toString() {
    return '$_modifiers${_modifiers == noKey ? '' : KEY_DELIMITER}$keyString';
  }
}

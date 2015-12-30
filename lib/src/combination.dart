library hotkey.src.combination;

import 'dart:html';

import 'package:quiver/collection.dart';

const KEY_DELIMITER = '+';

class Combination {
  final bool alt;
  final bool control;
  final bool meta;
  final bool shift;
  int _keyCode;
  String _keyString;

  int get keyCode => _keyCode;
  String get keyString => _keyString;

  Combination(int keyCode,
      {this.alt: false,
      this.control: false,
      this.meta: false,
      this.shift: false}) {
    // TODO: Is this check necessary or can we just let the key string be null?
    if (!ALLOWED_KEYS.containsKey(keyCode)) {
      throw new ArgumentError('Invalid key code: $keyCode');
    }
    _keyCode = keyCode;
    _keyString = ALLOWED_KEYS[keyCode];
  }

  factory Combination.fromKeyboardEvent(KeyboardEvent event) {
    // TODO: May want to check that keyCode is allowed.
    return new Combination(event.keyCode,
        alt: event.altKey,
        control: event.ctrlKey,
        meta: event.metaKey,
        shift: event.shiftKey);
  }

  factory Combination.fromString(String comboString) {
    var alt = false;
    var control = false;
    var meta = false;
    var shift = false;
    var keyCode;

    var tokens = _tokenize(comboString);
    tokens.forEach((t) {
      alt = alt ? alt : t == 'ALT';
      control = control ? control : t == 'CTRL';
      meta = meta ? meta : t == 'META';
      shift = shift ? shift : t == 'SHIFT';
      keyCode = keyCode ?? ALLOWED_KEYS.inverse[t];
    });

    return new Combination(keyCode,
        alt: alt, control: control, meta: meta, shift: shift);
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
    int modifiers = 0;
    int nonModifiers = 0;
    tokens.forEach((t) {
      if (ALLOWED_MODIFIERS.contains(t)) {
        modifiers += 1;
      }
      if (ALLOWED_KEYS.containsValue(t)) {
        nonModifiers += 1;
      }
    });
    if (nonModifiers != 1 || nonModifiers + modifiers != tokens.length) {
      throw new ArgumentError('Invalid binding string: $comboString');
    }
    return tokens;
  }

  bool operator ==(other) =>
      other is Combination &&
      other.alt == alt &&
      other.control == control &&
      other.meta == meta &&
      other.shift == shift &&
      other._keyCode == _keyCode;

  int get hashCode {
    var code = _keyCode * 10000;
    code += alt ? 1000 : 0;
    code += control ? 100 : 0;
    code += meta ? 10 : 0;
    code += shift ? 1 : 0;
    return code;
  }

  String toString() {
    // TODO: Use the + constant instead of the character.
    return '${alt ? 'ALT+' : ''}${control ? 'CTRL+' : ''}'
        '${meta ? 'META+' : ''}${shift ? 'SHIFT+' : ''}$keyString';
  }
}

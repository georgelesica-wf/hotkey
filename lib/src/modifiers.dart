library hotkey.src.modifiers;

import 'package:hotkey/src/constants.dart';

const _noKeyFlag = 0;
const _altKeyFlag = 1;
const _ctrlKeyFlag = 2;
const _metaKeyFlag = 4;
const _shiftKeyFlag = 8;

abstract class Modifiers {
  int get hashCode;

  operator +(Modifiers other);

  operator ==(Modifiers other);

  String toString();
}

/// A class to abstract the concept of a set of modifier keys. Consumers
/// will only ever use a base set of instances exposed by the library
/// to represent the simplest states: no modifier keys, only Alt, only
/// Control, only Meta, and only Shift. Other states can be created
/// by composing the basic states.
class _ModifierKeys extends Modifiers {
  final int flag;
  final List<String> _names;

  _ModifierKeys(this.flag, List<String> names)
      : _names = new Set.from(names).toList()..sort();

  int get hashCode => flag;

  Iterable<String> get names => _names;

  String toString() => _names.join(KEY_DELIMITER);

  operator +(_ModifierKeys other) => new _ModifierKeys(
      flag | other.flag, []..addAll(names)..addAll(other.names));

  operator ==(_ModifierKeys other) => flag == other.flag;
}

final _ModifierKeys noKey = new _ModifierKeys(_noKeyFlag, []);
final _ModifierKeys altKey = new _ModifierKeys(_altKeyFlag, ['ALT']);
final _ModifierKeys ctrlKey = new _ModifierKeys(_ctrlKeyFlag, ['CTRL']);
final _ModifierKeys metaKey = new _ModifierKeys(_metaKeyFlag, ['META']);
final _ModifierKeys shiftKey = new _ModifierKeys(_shiftKeyFlag, ['SHIFT']);

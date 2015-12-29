library hotkey.src.binding;

import 'package:hotkey/src/combination.dart';

/// Delimiter to specify different key bindings for the same action.
/// For example, to bind two hotkeys 'CTRL+ENTER' and 'ALT+S' to an action,
/// set its key combination to 'CTRL+ENTER, ALT+S'.
const BINDING_DELIMITER = '|';

/// The delimiter to separate key combinations within a key binding.
/// Example: 'CTRL+M > CTRL+I' means pressing CTRL + G then CTRL + I.
const SEQUENCE_DELIMITER = '>';

/// Parses a string specifying one or more key bindings into a list
/// of bindings, each of which is represented as a list of
/// [Combination] objects.
List<List<Combination>> parseBindingsString(String bindingsString) {
  return bindingsString
      .split(BINDING_DELIMITER)
      .map((bindingString) => bindingString
          .split(SEQUENCE_DELIMITER)
          .map((comboString) => new Combination.fromString(comboString))
          .toList())
      .toList();
}

library hotkey.src.binding;

import 'package:hotkey/src/combination.dart';

const BINDING_DELIMITER = ',';
const COMBINATION_DELIMITER = '>';

/// Parses a string specifying one or more key bindings into a list
/// of bindings, each of which is represented as a list of
/// [Combination] objects.
List<List<Combination>> parseBindingsString(String bindingsString) {
  return bindingsString
      .split(BINDING_DELIMITER)
      .map((bindingString) => bindingString
          .split(COMBINATION_DELIMITER)
          .map((comboString) => new Combination.fromString(comboString))
          .toList())
      .toList();
}

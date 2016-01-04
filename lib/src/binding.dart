library hotkey.src.binding;

import 'package:hotkey/src/combination.dart';
import 'package:hotkey/src/constants.dart';

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

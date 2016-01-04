library hotkey.src.typedefs;

import 'package:hotkey/src/combination.dart';

/// Keyboard binding callbacks are provided with the sequence
/// that was used to trigger them.
typedef void KeyBindingCallback(List<Combination> sequence);

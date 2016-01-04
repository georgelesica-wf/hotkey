library hotkey.src.constants;

/// Delimiter to specify different key bindings for the same action.
/// For example, to bind two hotkeys 'CTRL+ENTER' and 'ALT+S' to an action,
/// set its key combination to 'CTRL+ENTER, ALT+S'.
const BINDING_DELIMITER = '|';

/// The character used to separate keys from one another in bindings
/// strings. For example: `CTRL+A`.
const KEY_DELIMITER = '+';

/// The delimiter to separate key combinations within a key binding.
/// Example: 'CTRL+M > CTRL+I' means pressing CTRL + G then CTRL + I.
const SEQUENCE_DELIMITER = '>';

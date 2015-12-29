# Key Bindings

A Dart library for creating keyboard shortcuts and other key bindings.
Combinations of keypresses, such as "Control X" may be bound to callback
functions. The library supports fairly complex shortcuts including
any combination of the Control, Alt, Meta, and Shift modifer keys,
and key combination sequences, such as "Control X" followed immediately
by "Alt Z", etcetera.

## Examples

Key Bindings uses the [dart_dev](https://github.com/Workiva/dart_dev) package.
Clone the repo, then do `pub get` followed by `pub run dart_dev examples`.
The example application provides a playground for testing and experimenting
with key bindings.

## Installation

## Usage

First, create a `KeyBindingsManager`, then add key bindings to it.

```{.dart}
var manager = new KeyBindingsManager();
manager.addAll({
  'CTRL+A': (_) => print('You pressed CTRL+A'),
  'CTRL+SHIFT+A': (_) => print('You pressed CTRL+SHIFT+A')
});
manager.add('A', (_) => print('You pressed A');
manager.remove('A');
```

### Binding Syntax

There are four available modifier keys:

  * `CTRL` - Control key
  * `ALT` - Alt key
  * `META` - Command (Mac) or Windows Logo key (Windows, Linux)
  * `SHIFT` - Shift key

These are optionally combined with the rest of the keys on the keyboard
using the `+` character. Other keys
are represented by the character they would normally produce if
pressed without holding down the Shift key. For example, `CTRL+;` would
capture a keypress on the semicolon key while the Control key is
held down.

Sequences of keypresses may also be specified, they are delimited with
the `>` key (like a little arrow pointing forward in time). For example,
`CTRL+A > CTRL+A` would capture "Control A" pressed twice in a row.

It is illegal to specify two conflicting or ambiguous key bindings.
For example, it is not possible to define an action for both
`CTRL+A` *and* `CTRL+A > CTRL+A`.

Separating two key binding specifications with a comma will match
both of them. For example, `CTRL+A, CTRL+B` would cause "Control A"
and "Control B" to do the same thing.

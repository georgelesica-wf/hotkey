library hotkey.src.handler;

import 'package:hotkey/src/combination.dart';
import 'package:hotkey/src/typedefs.dart';

class Handler {
  final KeyBindingCallback callback;
  final String description;
  final String selector;
  final List<Combination> _sequence;

  Handler(List<Combination> sequence, this.callback,
      {this.description, this.selector})
      : _sequence = sequence;

  Iterable<Combination> get sequence => _sequence;

  void call() {
    callback(sequence);
  }
}

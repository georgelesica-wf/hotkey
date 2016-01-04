import 'dart:html';

import 'package:hotkey/hotkey.dart';

main() {
  var manager = new KeyBindingsManager();
  var bindingsText = querySelector('#bindings') as TextAreaElement;
  var messageDiv = querySelector('#message');

  void setMessage(String message) {
    messageDiv.setInnerHtml('You triggered "$message"');
  }

  void clearMessage() {
    messageDiv.setInnerHtml('');
  }

  void updateBindings([_]) {
    manager.removeAllBindings();
    clearMessage();
    bindingsText.value.split('\n').forEach((b) {
      manager.addBinding(b, (_) => setMessage(b));
    });
    manager
      ..addBinding('CTRL+T > CTRL+1', (_) => setMessage('hit target 1'),
          selector: '#target-1 input')
      ..addBinding('CTRL+T > CTRL+2', (_) => setMessage('hit target 2'),
          selector: '#target-2 input')
      ..addBinding(
          'UP > UP > DOWN > DOWN > LEFT > RIGHT > LEFT > RIGHT > B > A',
          (_) => setMessage('the Konami code!'));
  }

  updateBindings();
  querySelector('#update')..onClick.listen(updateBindings);
}

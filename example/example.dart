import 'dart:html';

import 'package:hotkey/hotkey.dart';

main() {
  var manager = new KeyBindingsManager();
  var bindingsText = querySelector('#bindings') as TextAreaElement;
  var messageDiv = querySelector('#message');

  void updateBindings([_]) {
    manager.removeAll();
    bindingsText.value.split('\n').forEach((b) {
      manager.add(b, (_) => messageDiv.setInnerHtml('You pressed "$b"'));
    });
  }

  updateBindings();
  querySelector('#update')..onClick.listen(updateBindings);
}

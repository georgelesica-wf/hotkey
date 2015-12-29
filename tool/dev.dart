library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  config.analyze.entryPoints = [
    'example/',
    'lib/',
    'lib/src',
    'test/unit/',
    'tool/'
  ];

  config.examples.port = 9000;

  config.format.directories = [
    'example/',
    'lib/',
    'test/unit/',
    'tool/',
  ];

  config.test.platforms = ['vm', 'content-shell'];

  config.test.unitTests = ['test/unit/'];

  await dev(args);
}
import 'dart:io';

import 'package:assets_gen/src/const.dart';
import 'package:assets_gen/src/generator.dart';
import 'package:assets_gen/src/log.dart';
import 'package:assets_gen/src/pubspec.dart';

void runBuild() async {
  File f = File(pubspecFile);
  if (!f.existsSync()) {
    logger.severe('Can not find pubspec.yaml');
    return;
  }

  logger.info('Building...');
  PubSpec pubspec = PubSpec.parse(f);
  generate(pubspec);
  logger.info('Build finished.');
}

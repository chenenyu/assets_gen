import 'dart:io';

import 'package:assets_gen/src/const.dart';
import 'package:assets_gen/src/generator.dart';
import 'package:assets_gen/src/log.dart';
import 'package:assets_gen/src/pubspec.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

// ignore_for_file: avoid_print
void runWatch() {
  File f = File(pubspecFile);
  if (!f.existsSync()) {
    logger.severe('Can not find pubspec.yaml');
    return;
  }
  PubSpec pubspec = PubSpec.parse(f);

  generate(pubspec);

  if (pubspec.options.enable == true) {
    print('');
    logger.info('Watching...');
    print('');

    // watch pubspec.yaml
    FileWatcher watcher = FileWatcher(pubspec.pubspecPath);
    watcher.events.listen((event) {
      switch (event.type) {
        case ChangeType.ADD:
        case ChangeType.REMOVE:
          break;
        case ChangeType.MODIFY:
          pen
            ..reset()
            ..xterm(033);
          logger.info(pen('${event.type}: ${event.path}'));
          pubspec.update();
          generate(pubspec);
          print('');
          break;
      }
    });

    // watch assets
    Directory assetsDir = Directory(p.join(pubspec.packagePath, 'assets'));
    if (assetsDir.existsSync()) {
      DirectoryWatcher dirWatcher = DirectoryWatcher(assetsDir.path);
      dirWatcher.events.listen((event) {
        if ((event.type == ChangeType.ADD || event.type == ChangeType.REMOVE) &&
            !p.basename(event.path).startsWith('.')) {
          switch (event.type) {
            case ChangeType.ADD:
              pen
                ..reset()
                ..xterm(010);
              break;
            case ChangeType.MODIFY: // ignore
              break;
            case ChangeType.REMOVE:
              pen
                ..reset()
                ..xterm(009);
              break;
          }
          logger.info(pen('${event.type}: ${event.path}'));
          generate(pubspec);
          print('');
        }
      });
    }
  }
}

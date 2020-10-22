import 'dart:io';

import 'package:assets_gen/src/const.dart';
import 'package:assets_gen/src/generator.dart';
import 'package:assets_gen/src/log.dart';
import 'package:assets_gen/src/pubspec.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

void runWatch() {
  File f = File(pubspec_file);
  if (!f.existsSync()) {
    logger.severe('Can not find pubspec.yaml');
    return;
  }
  logger.info('Watching...');
  PubSpec pubspec = PubSpec.parse(f, isRoot: true);

  Set<PubSpec> allPubs = <PubSpec>{pubspec};

  generate(pubspec);
  pubspec.pathDependencies?.forEach((element) {
    allPubs.add(element);
    generate(element);
  });

  allPubs.forEach((element) {
    if (element.options.enable == true) {
      // watch pubspec.yaml
      FileWatcher watcher = FileWatcher(element.pubspecPath);
      watcher.events.listen((event) {
        logger.info('${event.type}: ${event.path}');
        generate(element);
      });
      // watch assets
      Directory assetsDir = Directory(p.join(element.path, 'assets'));
      if (assetsDir.existsSync()) {
        DirectoryWatcher dirWatcher = DirectoryWatcher(assetsDir.path);
        dirWatcher.events.listen((event) {
          if ((event.type == ChangeType.ADD ||
                  event.type == ChangeType.REMOVE) &&
              !p.basename(event.path).startsWith('.')) {
            logger.info('${event.type}: ${event.path}');
            generate(element);
          }
        });
      }
    }
  });
}

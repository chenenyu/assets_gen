import 'package:ansicolor/ansicolor.dart';
import 'package:logging/logging.dart';

final AnsiPen pen = AnsiPen();

final Logger logger = Logger('assets_gen')
  ..onRecord.listen((record) {
    String log = '[${record.level.name}] ${record.message}';
    if (record.level >= Level.SEVERE) {
      pen
        ..reset()
        ..xterm(001);
      log = pen(log);
    } else if (record.level >= Level.WARNING) {
      pen
        ..reset()
        ..xterm(003);
      log = pen(log);
    }
    print(log);
  });

import 'package:logging/logging.dart';

Logger logger = Logger('assets_gen')
  ..onRecord.listen((record) {
    record.message;
    print(
        '${record.time.toIso8601String()}[${record.level.name}]: ${record.message}');
  });

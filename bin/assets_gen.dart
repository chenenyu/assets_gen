import 'package:args/args.dart';

import 'src/build.dart';
import 'src/watch.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) return;
  // arguments.forEach(print);

  final ArgParser parser = ArgParser();
  parser.addCommand('build');
  parser.addCommand('watch');

  ArgResults results = parser.parse(arguments);
  if (results.command == null) return;
  if (results.command.name == 'build') {
    runBuild();
  } else if (results.command.name == 'watch') {
    runWatch();
  }
}

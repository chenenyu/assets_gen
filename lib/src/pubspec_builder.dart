import 'dart:async';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'const.dart';

Builder pubspecBuilder(BuilderOptions options) => PubspecBuilder();

/// Cache flutter.assets section from pubspec.yaml
class PubspecBuilder implements Builder {
  PubspecBuilder();

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      'pubspec.yaml': [cache_file]
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    log.fine('PubspecBuilder#build');
    AssetId id = buildStep.inputId;
    String yaml = await buildStep.readAsString(id);
    YamlMap yamlMap = loadYaml(yaml);
    if (!yamlMap.containsKey('flutter')) {
      log.warning(
          'Ignored: ${id.toString()} does not contain \'flutter\' section.');
      return;
    }
    YamlMap flutter = yamlMap['flutter'];
    if (!flutter.containsKey('assets')) {
      log.warning(
          'Ignored: ${id.toString()} does not contain \'assets\' section.');
      return;
    }
    YamlList assets = flutter['assets'];
    if (assets.isEmpty) {
      log.warning(
          'Ignored: ${id.toString()} contains empty \'assets\' section.');
      return;
    }

    AssetId gen = AssetId(id.package, cache_file);
    await buildStep.writeAsString(
        gen, _generate(id.package, Set<String>.from(assets)));
    return;
  }

  _generate(String package, Iterable<String> assets) {
    StringBuffer content = StringBuffer();
    assets.forEach((asset) {
      content.writeln(asset);
    });
    return content.toString();
  }
}

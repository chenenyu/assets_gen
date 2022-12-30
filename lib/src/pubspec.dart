import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'const.dart';
import 'log.dart';
import 'options.dart';

class PubSpec {
  /// raw yaml content
  late YamlMap yaml;

  /// package name
  late String name;

  /// package path
  String path = '';

  /// flutter assets section
  List<String>? flutterAssets;

  /// gen options
  AssetsGenOptions options = AssetsGenOptions();

  /// pubspec.yaml file path
  String get pubspecPath => p.join(path, pubspecFile);

  /// assets_gen.yaml file path
  String get optionsPath => p.join(path, optionsFile);

  PubSpec.parse(File f) {
    path = p.normalize(f.parent.path);
    update();
  }

  void update() {
    yaml = loadYaml(File(pubspecPath).readAsStringSync());
    name = yaml['name'];
    flutterAssets = _readAssets(yaml);
    _parseOptions();
  }

  /// Read assets from pubspec
  List<String>? _readAssets(YamlMap yamlMap) {
    YamlMap? flutter = yamlMap['flutter'];
    if (flutter == null) {
      logger.warning(
          'Ignored: package:${yamlMap['name']} does not contain \'flutter\' section.');
      return null;
    }
    YamlList? assets = flutter['assets'];
    if (assets == null) {
      logger.warning(
          'Ignored: package:${yamlMap['name']} does not contain \'assets\' section.');
      return null;
    }
    return List<String>.from(assets);
  }

  void _parseOptions() {
    // update from pubspec
    final assetsGen = yaml['assets_gen'];
    if (assetsGen is YamlMap) {
      options.update(assetsGen);
      return;
    }

    _parseOptionsFromFile();
  }

  void _parseOptionsFromFile() {
    File optionsFile = File(optionsPath);
    if (!optionsFile.existsSync()) {
      return;
    }
    final optionsYaml = loadYaml(optionsFile.readAsStringSync());
    if (optionsYaml == null || optionsYaml.isEmpty) {
      logger.info('$optionsFile is empty.');
      return;
    }
    if (optionsYaml is! YamlMap) {
      logger.warning(
          '$optionsFile(${optionsYaml.runtimeType}) is not map format.');
      return;
    }
    options.update(optionsYaml['assets_gen']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PubSpec &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

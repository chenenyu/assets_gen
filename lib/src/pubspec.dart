import 'dart:io';

import 'package:assets_gen/src/log.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'const.dart';
import 'options.dart';

class PubSpec {
  /// raw yaml content
  YamlMap yaml;

  /// package name
  String name;

  /// package path
  String path = '';
  List<String> flutterAssets;
  AssetsGenOptions options = AssetsGenOptions();

  /// only contains native direct dependencies
  List<PubSpec> pathDependencies = [];

  /// pubspec file path
  String get pubspecPath => p.join(path, pubspec_file);

  PubSpec.parse(File f, {bool isRoot = false}) {
    yaml = loadYaml(f.readAsStringSync());
    name = yaml['name'];
    path = p.normalize(f.parent.path);
    flutterAssets = _readAssets(yaml);
    _parseOptions();
    if (isRoot == true) {
      _parseDependencies();
    }
  }

  /// Read assets from pubspec
  List<String> _readAssets(YamlMap yamlMap) {
    YamlMap flutter = yamlMap['flutter'];
    if (flutter == null) {
      logger.warning(
          'Ignored: ${yamlMap['name']} does not contain \'flutter\' section.');
      return null;
    }
    YamlList assets = flutter['assets'];
    if (assets == null) {
      logger.warning(
          'Ignored: ${yamlMap['name']} does not contain \'assets\' section.');
      return null;
    }
    return List<String>.from(assets);
  }

  void _parseOptions() {
    // update from pubspec
    final assets_gen = yaml['assets_gen'];
    if (assets_gen is YamlMap) {
      options.update(assets_gen);
    }

    // update from options file
    File optionsFile = File(p.join(path, options_file));
    if (!optionsFile.existsSync()) {
      return;
    }
    final optionsYaml = loadYaml(optionsFile.readAsStringSync());
    if (optionsYaml == null || optionsYaml.isEmpty) {
      logger.info('$options_file is empty.');
      return;
    }
    if (optionsYaml is! YamlMap) {
      logger.warning(
          '$options_file(${optionsYaml.runtimeType}) is not map format.');
      return;
    }
    options.update(optionsYaml.value);
  }

  void _parseDependencies() {
    YamlMap deps = yaml['dependencies'];
    if (deps != null && deps.isNotEmpty) {
      deps.forEach((k, v) {
        if (k is String && v is YamlMap) {
          String _path = v['path'];
          if (_path != null) {
            File pubspecFile = File(p.join(path, _path, pubspec_file));
            if (pubspecFile.existsSync()) {
              PubSpec pubspec = PubSpec.parse(pubspecFile);
              pathDependencies.add(pubspec);
            }
          }
        }
      });
    }
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

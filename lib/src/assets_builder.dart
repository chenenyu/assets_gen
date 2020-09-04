import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'options.dart';

Builder assetsBuilder(BuilderOptions options) => AssetsBuilder();

const String options_file = 'assets_gen_options.yaml';

class AssetsBuilder implements Builder {
  AssetsBuilder();

  AssetsGenOptions genOptions;

  @override
  Map<String, List<String>> get buildExtensions {
    _prepare();
    return {
      r'$lib$': [genOptions.output]
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    log.fine('AssetsBuilder#build');
    _prepare();
    AssetId id = buildStep.inputId; // package|lib/$lib$

    Iterable<String> assets = await _readPubspec(buildStep, id.package);
    if (assets == null) {
      return;
    }
    Iterable<String> paths = await _findAssets(buildStep, assets);

    AssetId gen = AssetId(id.package, p.join('lib', genOptions.output));
    await buildStep.writeAsString(gen, _generate(id.package, paths));
    return null;
  }

  _prepare() {
    if (genOptions != null) {
      return;
    }
    genOptions = AssetsGenOptions();
    File optionsFile = File(options_file);
    if (!optionsFile.existsSync()) {
      log.info('$options_file not exists.');
      return;
    }
    final yamlMap = loadYaml(optionsFile.readAsStringSync());
    if (yamlMap == null || yamlMap.isEmpty) {
      log.info('$options_file is empty.');
      return;
    }
    if (yamlMap is! YamlMap) {
      log.warning('$options_file(${yamlMap.runtimeType}) is not map format.');
      return;
    }
    genOptions.update(yamlMap.value);
  }

  Future<Iterable<String>> _readPubspec(
      BuildStep buildStep, String package) async {
    AssetId pubspec = AssetId(package, 'pubspec.yaml');
    if ((await buildStep.canRead(pubspec)) != true) {
      log.severe('Can not read ${pubspec.toString()}.');
      return null;
    }
    String yaml = await buildStep.readAsString(pubspec);
    YamlMap yamlMap = loadYaml(yaml);
    if (!yamlMap.containsKey('flutter')) {
      log.warning(
          'Ignored: ${pubspec.toString()} does not contain \'flutter\' section.');
      return null;
    }
    YamlMap flutter = yamlMap['flutter'];
    if (!flutter.containsKey('assets')) {
      log.warning(
          'Ignored: ${pubspec.toString()} does not contain \'assets\' section.');
      return null;
    }
    YamlList assets = flutter['assets'];
    if (assets.isEmpty) {
      log.warning(
          'Ignored: ${pubspec.toString()} contains empty \'assets\' section.');
      return null;
    }
    return List<String>.from(assets);
  }

  Future<Iterable<String>> _findAssets(
      BuildStep buildStep, Iterable<String> assets) async {
    Set<String> validAssets = assets.toSet();
    Set<String> paths = <String>{};
    for (String asset in validAssets) {
      // log.fine(asset);
      if (asset.endsWith('/')) {
        // dir
        Glob glob = Glob('$asset*', recursive: false, caseSensitive: false);
        Set<AssetId> assets = await buildStep.findAssets(glob).toSet();
        if (assets.isNotEmpty) {
          assets.forEach((assetId) {
            if (!genOptions.shouldExclude(assetId.path)) {
              paths.add(assetId.path);
            }
          });
        } else {
          Directory dir = Directory(asset);
          if (dir.existsSync()) {
            Iterable<FileSystemEntity> children =
                dir.listSync().whereType<File>();
            children.forEach((f) {
              if (!genOptions.shouldExclude(f.path)) {
                paths.add(f.path);
              }
            });
          }
        }
      } else {
        // file
        if (!genOptions.shouldExclude(asset)) {
          paths.add(asset);
        }
      }
    }
    return List<String>.from(paths)..sort();
  }

  _generate(String package, Iterable<String> paths) {
    StringBuffer content = StringBuffer();
    content.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    content.writeln();
    content.writeln(
        '// **************************************************************************');
    content.writeln('// Total assets: ${paths.length}.');
    content.writeln('// Powered by https://pub.dev/packages/assets_gen.');
    content.writeln(
        '// **************************************************************************');

    content.writeln('class ${genOptions.className} {');
    content.writeln("  static const String package = '${package}';");
    for (String path in paths) {
      content.writeln();
      String key = genOptions.includePath ? path : p.basename(path);
      key = key.replaceAll('/', '_').replaceAll('-', '_').replaceAll('.', '_');
      // 如果key不是以字母或$开头，前面加一个$
      content.writeln(
          "  static const String ${key.startsWith(RegExp(r'[a-zA-Z$]')) ? '' : '\$'}$key = '${path}';");
      if (genOptions.includePackage &&
          !path.startsWith('packages/${package}')) {
        content.writeln(
            "  static const String ${package}\$$key = 'packages/${package}/${path}';");
      }
    }
    content.writeln('}');

    return content.toString();
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'asset.dart';
import 'options.dart';

Builder assetsBuilder(BuilderOptions options) => AssetsBuilder();

const String options_file = 'assets_gen_options.yaml';
const String pubspec_file = 'pubspec.yaml';

/// Builder
class AssetsBuilder implements Builder {
  AssetsBuilder();

  AssetsGenOptions _options;

  @override
  Map<String, List<String>> get buildExtensions {
    _prepare();
    return {
      r'$lib$': [_options.output]
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    print('AssetsBuilder#build');
    _prepare();
    AssetId id = buildStep.inputId; // package|lib/$lib$

    Iterable<String> inputs =
        await _readAssetsFromPubspec(buildStep, id.package);
    if (inputs == null) {
      return null;
    }
    Iterable<Asset> outputs = await _findAssets(buildStep, inputs);
    AssetId gen = AssetId(id.package, p.join('lib', _options.output));
    await buildStep.writeAsString(gen, _generate(id.package, outputs));
    return null;
  }

  /// Update options
  void _prepare() {
    if (_options != null) {
      return;
    }
    _options = AssetsGenOptions();

    // update from pubspec
    File pubspecFile = File(pubspec_file);
    if (!pubspecFile.existsSync()) {
      return;
    }
    YamlMap pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
    if (pubspecYaml.containsKey('assets_gen')) {
      final assets_gen = pubspecYaml['assets_gen'];
      if (assets_gen is YamlMap) {
        _options.update(assets_gen);
      }
    }

    // update from options file
    File optionsFile = File(options_file);
    if (!optionsFile.existsSync()) {
      // log.info('$options_file not exists.');
      return;
    }
    final optionsYaml = loadYaml(optionsFile.readAsStringSync());
    if (optionsYaml == null || optionsYaml.isEmpty) {
      log.info('$options_file is empty.');
      return;
    }
    if (optionsYaml is! YamlMap) {
      log.warning(
          '$options_file(${optionsYaml.runtimeType}) is not map format.');
      return;
    }
    _options.update(optionsYaml.value);
  }

  /// Read assets from pubspec
  Future<Iterable<String>> _readAssetsFromPubspec(
      BuildStep buildStep, String package) async {
    AssetId pubspec = AssetId(package, pubspec_file);
    if ((await buildStep.canRead(pubspec)) != true) {
      log.severe('Can not read ${pubspec.toString()}.');
      return null;
    }
    String yaml = await buildStep.readAsString(pubspec);
    YamlMap yamlMap = loadYaml(yaml);
    if (!yamlMap.containsKey('flutter')) {
      log.severe(
          'Ignored: ${pubspec.toString()} does not contain \'flutter\' section.');
      return null;
    }
    YamlMap flutter = yamlMap['flutter'];

    if (!flutter.containsKey('assets')) {
      log.severe(
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

  Future<Iterable<Asset>> _findAssets(
      BuildStep buildStep, Iterable<String> paths) async {
    Set<String> pathSet = paths.toSet();
    Set<Asset> assets = <Asset>{};
    for (String item in pathSet) {
      // log.fine(item);
      if (item.endsWith('/')) {
        // dir
        Glob glob = Glob('$item*', recursive: false, caseSensitive: false);
        Set<AssetId> subAssets = await buildStep.findAssets(glob).toSet();
        if (subAssets.isNotEmpty) {
          subAssets.forEach((assetId) {
            if (!_options.shouldExclude(assetId.path)) {
              Asset asset = Asset(assetId.path);
              _options.matchPlural(asset);
              bool r = assets.add(asset);
              // if (r) print('plural添加成功: $asset');
            }
          });
        } else {
          Directory dir = Directory(item);
          if (dir.existsSync()) {
            Iterable<FileSystemEntity> children =
                dir.listSync().whereType<File>();
            children.forEach((f) {
              if (!_options.shouldExclude(f.path)) {
                Asset asset = Asset(f.path);
                _options.matchPlural(asset);
                assets.add(asset);
              }
            });
          }
        }
      } else {
        // file
        if (!_options.shouldExclude(item)) {
          Asset asset = Asset(item);
          _options.matchPlural(asset);
          assets.add(asset);
        }
      }
    }
    return List<Asset>.from(assets)..sort();
  }

  String _generate(String package, Iterable<Asset> assets) {
    StringBuffer content = StringBuffer();
    content.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    content.writeln();
    content.writeln(
        '// **************************************************************************');
    content.writeln('// Total assets: ${assets.length}.');
    content.writeln('// Generated by https://pub.dev/packages/assets_gen.');
    content.writeln(
        '// **************************************************************************');

    content.writeln('class ${_options.className} {');
    content.writeln("  static const String package = '${package}';");
    for (Asset asset in assets) {
      content.writeln();

      String key = asset.isPlural ? asset.plural : asset.path;
      if (_options.omitPathLevels > 0) {
        // 省略路径层级
        List<String> pathSegments = p.split(p.dirname(key));
        if (pathSegments.isNotEmpty) {
          pathSegments = pathSegments
              .sublist(min(_options.omitPathLevels, pathSegments.length));
          key = p.join(p.joinAll(pathSegments), p.basename(key));
        }
      }
      // 替换非法字符
      key = key.replaceAll('/', '_').replaceAll('-', '_').replaceAll('.', '_');

      if (asset.isPlural) {
        key = key.replaceAll('*', 'x');
        Iterable<Match> matches = '\*'.allMatches(asset.plural);
        // print('${asset.plural}中*的个数: ${matches.length}');
        String params = '(';
        String body = '';
        for (int i = 0, l = matches.length; i < l; i++) {
          params += 'Object p$i${i == l - 1 ? '' : ', '}';
        }
        params += ')';
        List<Match> list = matches.toList();
        int index = 0;
        for (int i = 0, l = matches.length; i < l; i++) {
          Match match = list[i];
          body += asset.plural.substring(index, match.start);
          body += '\${p$i.toString()}';
          index = match.end;
        }
        body += asset.plural.substring(index);

        content.writeln(
            "  static String ${key.startsWith(RegExp(r'[a-zA-Z$]')) ? '' : '\$'}$key$params => '$body';");
        if (_options.genPackagePath &&
            !asset.path.startsWith('packages/${package}')) {
          content.writeln(
              "  static String ${package}\$$key$params => 'packages/${package}/$body';");
        }
      } else {
        // 如果key不是以字母或$开头，前面加一个$
        content.writeln(
            "  static const String ${key.startsWith(RegExp(r'[a-zA-Z$]')) ? '' : '\$'}$key = '${asset.path}';");
        if (_options.genPackagePath &&
            !asset.path.startsWith('packages/${package}')) {
          content.writeln(
              "  static const String ${package}\$$key = 'packages/${package}/${asset.path}';");
        }
      }
    }
    content.writeln('}');

    return content.toString();
  }
}

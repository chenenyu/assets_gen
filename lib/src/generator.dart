import 'dart:io';
import 'dart:math';

import 'package:build/build.dart' hide log;
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import 'asset.dart';
import 'log.dart';
import 'pubspec.dart';

void generate(PubSpec pubspec) {
  if (pubspec.options.enable != true || pubspec.flutterAssets == null) return;
  logger.info('Generating package:${pubspec.name}');
  Iterable<Asset>? assets = findAssets(pubspec);
  if (assets != null && assets.isNotEmpty) {
    String content = genContent(pubspec, assets);
    File output = File(p.join(pubspec.path, 'lib', pubspec.options.output));
    content = formatDartContent(content);
    output.writeAsStringSync(content);
  }
}

/// Formats Dart file content.
/// 格式化生成的代码
String formatDartContent(String content) {
  try {
    var formatter = DartFormatter();
    return formatter.format(content);
  } catch (e) {
    return content;
  }
}

void generateForBuilder(PubSpec pubspec, BuildStep buildStep) async {
  if (pubspec.options.enable != true || pubspec.flutterAssets == null) return;
  Iterable<Asset>? assets = findAssets(pubspec);
  if (assets != null && assets.isNotEmpty) {
    AssetId id = buildStep.inputId; // package|lib/$lib$
    AssetId gen = AssetId(id.package, p.join('lib', pubspec.options.output));
    await buildStep.writeAsString(gen, genContent(pubspec, assets));
  }
}

Iterable<Asset>? findAssets(PubSpec pubspec) {
  if (pubspec.flutterAssets == null || pubspec.flutterAssets!.isEmpty) {
    return null;
  }

  Set<Asset> assets = <Asset>{};

  void addAsset(String path) {
    if (!pubspec.options.shouldExclude(path)) {
      Asset asset = Asset(path);
      pubspec.options.handlePlural(asset);
      assets.add(asset);
    }
  }

  for (String item in pubspec.flutterAssets!) {
    if (item.endsWith('/')) {
      // dir
      Directory dir = Directory(p.join(pubspec.path, item));
      if (dir.existsSync()) {
        Iterable<File> files = dir.listSync().whereType<File>();
        if (files.isNotEmpty) {
          files.forEach((f) {
            // 工作路径转换为当前package的相对路径
            addAsset(p.relative(p.normalize(f.path), from: pubspec.path));
          });
        }
      }
    } else {
      // file
      addAsset(item);
    }
  }
  return List<Asset>.from(assets)..sort();
}

String genContent(PubSpec pubspec, Iterable<Asset> assets) {
  StringBuffer content = StringBuffer();
  content.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  content.writeln();
  content.writeln(
      '// **************************************************************************');
  content.writeln('// Total assets: ${assets.length}.');
  content.writeln('// Generated by https://pub.dev/packages/assets_gen.');
  content.writeln(
      '// **************************************************************************');

  content.writeln('class ${pubspec.options.className} {');
  content.writeln("  static const String package = '${pubspec.name}';");
  for (Asset asset in assets) {
    content.writeln();

    String key = asset.path;
    if (pubspec.options.omitPathLevels > 0) {
      // 省略路径层级
      List<String> pathSegments = p.split(p.dirname(key));
      if (pathSegments.isNotEmpty) {
        pathSegments = pathSegments
            .sublist(min(pubspec.options.omitPathLevels, pathSegments.length));
        key = p.join(p.joinAll(pathSegments), p.basename(key));
      }
    }
    if (!pubspec.options.withFileExtensionName) {
      //不包括文件后缀名
      key = key.substring(0, key.lastIndexOf('.'));
    }
    // 替换非法字符
    key = key.replaceAll('/', '_').replaceAll('-', '_').replaceAll('.', '_');

    if (pubspec.options.codeStyle == 'lowerCamelCase') {
      //按照"_" 拆分成小驼峰命名格式
      var items = key.split('_');
      items.forEach((element) {});
      String result = items[0];
      for (int i = 1; i < items.length; i++) {
        var item = items[i];
        item = item.substring(0, 1).toUpperCase() +
            // (item.length > 1 ? item.substring(1).toLowerCase() : '');
            (item.length > 1 ? item.substring(1) : ''); //单词可能有些是大小，交给用户
        result += item;
      }
      key = result;
    } else if (pubspec.options.codeStyle == 'UpperCamelCase') {
      //如果是小驼峰
      var items = key.split('_');
      items.forEach((element) {});
      String result = '';
      for (int i = 0; i < items.length; i++) {
        var item = items[i];
        item = item.substring(0, 1).toUpperCase() +
            (item.length > 1 ? item.substring(1) : '');
        // (item.length > 1 ? item.substring(1).toLowerCase() : '');
        result += item;
      }
      key = result;
    }
    if (asset.isPlural) {
      Iterable<Match>? matches;
      if (key.contains('**')) {
        key = key.replaceAll('**', 'x');
        matches = '\*\*'.allMatches(asset.path);
      } else if (key.contains('*')) {
        key = key.replaceAll('*', 'x');
        matches = '\*'.allMatches(asset.path);
      } else if (key.contains('?')) {
        key = key.replaceAll('?', 'x');
        matches = '\?'.allMatches(asset.path);
      }
      if (matches == null) {
        logger.severe('Unsupported plural: $key');
        break;
      }
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
        body += asset.path.substring(index, match.start);
        body += '\${p$i.toString()}';
        index = match.end;
      }
      body += asset.path.substring(index);

      content.writeln(
          "  static String ${key.startsWith(RegExp(r'[a-zA-Z$]')) ? '' : '\$'}$key$params => '$body';");
      if (pubspec.options.genPackagePath &&
          !asset.path.startsWith('packages/${pubspec.name}')) {
        content.writeln(
            "  static String ${pubspec.name}\$$key$params => 'packages/${pubspec.name}/$body';");
      }
    } else {
      // 如果key不是以字母或$开头，前面加一个$
      content.writeln(
          "  static const String ${key.startsWith(RegExp(r'[a-zA-Z$]')) ? '' : '\$'}$key = '${asset.path}';");
      if (pubspec.options.genPackagePath &&
          !asset.path.startsWith('packages/${pubspec.name}')) {
        content.writeln(
            "  static const String ${pubspec.name}\$$key = 'packages/${pubspec.name}/${asset.path}';");
      }
    }
  }
  content.writeln('}');

  return content.toString();
}

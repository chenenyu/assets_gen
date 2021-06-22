import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'asset.dart';

/// Parse options from assets_gen options.
class AssetsGenOptions {
  AssetsGenOptions();

  bool _enable = true;

  bool get enable => _enable;

  /// output file path
  String _output = 'assets.dart';

  String get output => _output;

  /// class name
  String _className = 'Assets';

  String get className => _className;

  /// 是否额外生成带package的资源路径
  /// e.g. packages/${package}/path/to/img.png
  bool _genPackagePath = true;

  bool get genPackagePath => _genPackagePath;

  /// asset key 省略路径层级
  /// 0 表示不省略
  int _omitPathLevels = 0;

  int get omitPathLevels => _omitPathLevels;

  /// 是否忽略分辨率variant
  bool _ignoreResolution = true;

  /// 忽略的文件/文件夹
  /// 支持glob语法
  List<String> _exclude;

  List<String> _plurals;

  void update(Map json) {
    if (json['enable'] is bool) {
      _enable = json['enable'];
    }
    if (json['output'] is String) {
      _output = json['output'];
      if (!_output.endsWith('.dart')) {
        throw ArgumentError("'output'(${_output}) must end with '.dart'.");
      }
    }
    if (json['class_name'] is String) {
      _className = json['class_name'];
    }
    if (json['gen_package_path'] is bool) {
      _genPackagePath = json['gen_package_path'];
    }
    if (json['omit_path_levels'] is int) {
      _omitPathLevels = json['omit_path_levels'];
    }
    if (json['ignore_resolution'] is bool) {
      _ignoreResolution = json['ignore_resolution'];
    }
    if (json['exclude'] is List) {
      _exclude = (json['exclude'] as List).map((e) => e.toString()).toList();
    }
    if (json['plurals'] is List) {
      _plurals = (json['plurals'] as List).map((e) => e.toString()).toList();
    }
  }

  /// 是否排除该资源
  bool shouldExclude(String path) {
    if (p.basename(path).startsWith('.')) {
      // ignore hidden file
      return true;
    }
    if (_ignoreResolution == true && _isResolution(path)) {
      return true;
    }
    if (_exclude == null || _exclude.isEmpty) {
      return false;
    }
    for (String glob in _exclude) {
      if (Glob(glob).matches(path)) {
        return true;
      }
    }
    return false;
  }

  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  bool _isResolution(String path) {
    final Uri assetUri = Uri.parse(path);
    String directoryPath = '';
    if (assetUri.pathSegments.length > 1) {
      directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
    }
    if (_extractRatioRegExp.hasMatch(directoryPath)) {
      return true;
    }
    return false;
  }

  /// 查找是否有对应的plural
  void handlePlural(Asset asset) {
    if (_plurals == null || _plurals.isEmpty) {
      return;
    }
    for (String plural in _plurals) {
      if (Glob(plural).matches(asset.path)) {
        asset.path = plural;
        asset.isPlural = true;
        return;
      }
    }
  }
}

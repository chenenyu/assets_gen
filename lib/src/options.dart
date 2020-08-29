import 'package:glob/glob.dart';

/// Parse options from 'assets_gen_options.yaml'
class AssetsGenOptions {
  /// 生成的dart文件
  String _output = 'assets.g.dart';

  /// 生成的类名
  String _className = 'Assets';

  /// 是否额外生成带package的资源路径
  /// e.g. packages/${package}/path/to/img.png
  bool _includePackage = true;

  /// 生成的变量名是否包含路径
  bool _includePath = true;

  /// 是否忽略分辨率variant
  bool _ignoreResolution = true;

  /// 忽略的文件/文件夹
  /// 支持正则
  List<String> _exclude;

  AssetsGenOptions();

  String get output => _output;

  String get className => _className;

  bool get includePackage => _includePackage;

  bool get includePath => _includePath;

  update(Map json) {
    if (json['output'] is String) {
      _output = json['output'];
      if (!_output.endsWith('.dart')) {
        throw ArgumentError("'output'(${_output}) must end with '.dart'.");
      }
    }
    if (json['class_name'] is String) {
      _className = json['class_name'];
    }
    if (json['include_package'] is bool) {
      _includePackage = json['include_package'];
    }
    if (json['include_path'] is bool) {
      _includePath = json['include_path'];
    }
    if (json['ignore_resolution'] is bool) {
      _ignoreResolution = json['ignore_resolution'];
    }
    if (json['exclude'] is List) {
      _exclude = (json['exclude'] as List).map((e) => e.toString()).toList();
    }
  }

  /// 是否排除该资源
  bool shouldExclude(String path) {
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
}

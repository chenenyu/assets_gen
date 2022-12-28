import 'dart:async';
import 'dart:io';

import 'package:build/build.dart' hide log;

import 'const.dart';
import 'generator.dart';
import 'pubspec.dart';

Builder assetsBuilder(BuilderOptions options) => AssetsBuilder();

/// Builder
class AssetsBuilder implements Builder {
  AssetsBuilder();

  PubSpec? _pubspec;

  @override
  Map<String, List<String>> get buildExtensions {
    _prepare();
    return {
      r'$lib$': [_pubspec?.options.output ?? 'assets.dart']
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    _prepare();
    if (_pubspec != null) {
      generateForBuilder(_pubspec!, buildStep);
    }
    return null;
  }

  void _prepare() {
    if (_pubspec != null) {
      return;
    }
    File f = File(pubspecFile);
    if (!f.existsSync()) {
      return;
    }
    _pubspec = PubSpec.parse(f);
  }
}

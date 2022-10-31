# assets_gen

[![Pub Version](https://img.shields.io/pub/v/assets_gen)](https://pub.dev/packages/assets_gen)

The `assets_gen` package helps you to generate a .dart file that contains all assets according to `pubspec.yaml`.

| Way to reference asset path | Sample Code                                  |          |
| ---------------------------- | -------------------------------------------- | -------- |
| Use string path directly     | `Image.asset('assets/images/foo.png');`      | ❌ Unsafe |
| Use `assets_gen`             | `Image.asset(Assets.assets_images_foo_png);` | ✅ Good   |

## Getting Started

### Install

```yaml
dev_dependencies:
  assets_gen: any # Replace 'any' with version number.
  build_runner: any # Optional.
```

### Usage

|                                            | Call directly (Recommend)          | Use `build_runner`                   |
| ------------------------------------------ | ---------------------------------- | ------------------------------------ |
| Run a single build and exit.               | `flutter pub run assets_gen build` | `flutter pub run build_runner build` |
| Continuously run builds as you edit files. | `flutter pub run assets_gen watch` | `flutter pub run build_runner watch` |

Note: Call `assets_gen` script directly will take effect on the target package and all it's dependencies.

More info about [pub-run](https://dart.dev/tools/pub/cmd/pub-run) and [build_runner](https://pub.dev/packages/build_runner).

### Options

```yaml
# Specify an assets_gen section in pubspec.yaml
flutter:
  assets:
    - path/to/asset
assets_gen:
  ...
```

| option              | type         | default value                |                                                                                                                                                                               |
| ------------------- |--------------|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `enable` | bool         | `true`                       | Enable or not.                                                                                                                                                                |
| `output`            | String       | `assets.dart`                | Output position, always under `lib/`.                                                                                                                                         |
| `class_name`        | String       | `Assets`                     | The generated class name.                                                                                                                                                     |
| `gen_package_path` | bool         | `true`                       | Whether the builder should generate extra const variable with package info, e.g. `packages/${package}/path/to/foo.png`                                                        |
| `ignore_resolution` | bool         | `true`                       | Whether the builder should ignore resolution variant. e.g. `path/to/3.0x/foo.png` will be ignored.                                                                            |
| `omit_path_levels` | int          | `0`                          | The path levels of generated key that the builder will omit. e.g. if levels is 2, the key of `path/to/foo.png` is `foo_png`.                                                  |
| `exclude`           | List<String> | none                         | Listed assets in exclude will be ignored in generated class. It supports [glob](https://github.com/dart-lang/glob) syntax.                                                    |
| `plurals` | List<String> | none                         | Plurals support. e.g.  Specify a plural `- assets/vip/*.svg` will generate a function like `static String assets_vip_x_svg(Object p0) => 'assets/vip/${p0.toString()}.svg';`. |
| `code_style` | String       | `lowercase_with_underscores` | [Identifiers come in three flavors in Dart](https://dart.dev/guides/language/effective-dart/style): `UpperCamelCase`、`lowerCamelCase`、`lowercase_with_underscores`            |
| `with_file_extension_name` | bool | `true`                         | Whether to include the suffix of the assets file                                                                                                                              |
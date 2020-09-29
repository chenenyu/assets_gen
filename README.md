# assets_gen

[![Pub Version](https://img.shields.io/pub/v/assets_gen)](https://pub.dev/packages/assets_gen)

The `assets_gen` package provides a builder to generate a .dart file that contains all assets according to `pubspec.yaml`.

| Way to reference asset path | Sample Code                                  |          |
| ---------------------------- | -------------------------------------------- | -------- |
| Use string path directly     | `Image.asset('assets/images/foo.png');`      | ❌ Unsafe |
| Use `assets_gen`             | `Image.asset(Assets.assets_images_foo_png);` | ✅ Good   |

## Getting Started

### Install

```yaml
dev_dependencies:
  build_runner: ">=1.0.0 < 2.0.0"
  assets_gen: any
```

### Usage

`flutter pub run build_runner build`: Run a single build and exit.

`flutter pub run build_runner watch`: Continuously run builds as you edit files.

More info about [build_runner](https://pub.dev/packages/build_runner).

### Options

Here are two ways to custom the generated file:

* Offer an `assets_gen_options.yaml` file

* ```yaml
  # Specify an assets_gen section in pubspec.yaml
  flutter:
    assets:
      - path/to/asset
  assets_gen:
    ...
  ```

| option              | type         | default value   |                                                              |
| ------------------- | ------------ | --------------- | ------------------------------------------------------------ |
| `output`            | String       | `assets.g.dart` | Output position, always under `lib/`.                        |
| `class_name`        | String       | `Assets`        | The generated class name.                                    |
| `gen_package_path` | bool         | `true`         | Whether the builder should generate extra const variable with package info, e.g. `packages/${package}/path/to/foo.png` |
| `ignore_resolution` | bool         | `true`          | Whether the builder should ignore resolution variant. e.g. `path/to/3.0x/foo.png` will be ignored. |
| `omit_path_levels` | int | `0` | The path levels of generated key that the builder will omit. e.g. if levels is 2, the key of `path/to/foo.png` is `foo_png`. |
| `exclude`           | List<String> | none            | Listed assets in exclude will be ignored in generated class. It supports [glob](https://github.com/dart-lang/glob) syntax. |
| `plurals` | List<String> | none | Plurals support. e.g.  Specify a plural `- assets/vip/*.svg` will generate a function like `static String assets_vip_x_svg(Object p0) => 'assets/vip/${p0.toString()}.svg';`. |


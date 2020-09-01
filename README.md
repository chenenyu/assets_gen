# assets_gen

![[Pub Version](https://pub.dev/packages/assets_gen)](https://img.shields.io/pub/v/assets_gen)

The `assets_gen` package provides a builder to generate a .dart file that contains all assets according to `pubspec.yaml`.

## Getting Started

### Install

```yaml
dev_dependencies:
  build_runner: ">=1.0.0 < 2.0.0"
  assets_gen: ^0.1.2
```

### Usage

`flutter pub run build_runner build`: Run a single build and exit.

`flutter pub run build_runner watch`: Continuously run builds as you edit files.

More info about [build_runner](https://pub.dev/packages/build_runner).

### Options

You can custom the generated file by offer an `assets_gen_options.yaml` file.  

| option              | type         | default value   |                                                              |
| ------------------- | ------------ | --------------- | ------------------------------------------------------------ |
| `output`            | String       | `assets.g.dart` | Output position, always under `lib/`.                        |
| `class_name`        | String       | `Assets`        | The generated class name.                                    |
| `include_package`   | bool         | `true`         | Whether the builder should generate extra const variable with package info, e.g. `packages/${package}/path/to/img.png` |
| `include_path`      | bool         | `true`          | Whether the generated const variables should contains path. If false, the variable only contains asset basename with extension. |
| `ignore_resolution` | bool         | `true`          | Whether the builder should ignore resolution variant. e.g. `path/to/3.0x/foo.png` will be ignored. |
| `exclude`           | List<String> | none            | The exclude assets will be ignored in generated class. It supports [glob](https://github.com/dart-lang/glob) syntax. |


/// Asset bean
class Asset implements Comparable<Asset> {
  String path;
  bool isPlural = false;

  Asset(this.path);

  @override
  int compareTo(Asset other) {
    return path.compareTo(other.path);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          (path == other.path);

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'Asset{path: $path, isPlural: $isPlural}';
  }
}

/// Asset bean
class Asset implements Comparable<Asset> {
  final String path;
  String plural;

  Asset(this.path);

  bool get isPlural => plural != null;

  @override
  int compareTo(Asset other) {
    return path.compareTo(other.path);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          (isPlural ? plural == other.plural : path == other.path);

  @override
  int get hashCode => isPlural ? plural.hashCode : path.hashCode;

  @override
  String toString() {
    return 'Asset{path: $path, plural: $plural}';
  }
}

/// Asset bean
class Asset implements Comparable<Asset> {
  String path;
  String? plural;

  bool get isPlural => plural != null;

  String get key => plural ?? path;

  Asset(this.path);

  @override
  int compareTo(Asset other) {
    return path.compareTo(other.path);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return 'Asset{path: $path, plural: $plural}';
  }
}

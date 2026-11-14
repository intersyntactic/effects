import 'package:path/path.dart' as p;

/// A path relative to wherever a driver's root is, `/`-separated and
/// normalised. The root itself is the empty path.
///
/// Carries no promise about staying inside that root: whether a path may
/// leave it, and whether a symlink along the way does, are the operator's
/// choice, enforced by the driver that touches disk. This type only
/// normalises the text.
final class RelativePath {
  RelativePath(String raw) : value = _normalise(raw);

  const RelativePath._(this.value);

  static const root = RelativePath._('');

  final String value;

  static String _normalise(String raw) {
    final normal = p.posix.normalize(raw.startsWith('/') ? '.$raw' : raw);
    return normal == '.' ? '' : normal;
  }

  /// The folder this path is in; the root's folder is the root.
  RelativePath get folder {
    final dir = p.posix.dirname(value.isEmpty ? '.' : value);
    return dir == '.' ? root : RelativePath._(dir);
  }

  String get extension => p.posix.extension(value);

  @override
  bool operator ==(Object other) =>
      other is RelativePath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

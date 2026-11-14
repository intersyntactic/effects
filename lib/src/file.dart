import 'relative_path.dart';

/// [text] for the file at [path]. The driver decides whether it may be
/// written, including whether [path] must stay within its root.
final class FileText {
  const FileText(this.path, this.text);

  final RelativePath path;
  final String text;
}

/// What a read found.
sealed class ReadResult {
  const ReadResult();
}

final class ReadText extends ReadResult {
  const ReadText(this.text);

  final String text;
}

/// No file at the path.
final class ReadMissing extends ReadResult {
  const ReadMissing();
}

/// Written; [replaced] when a file was there before.
final class Wrote {
  const Wrote({required this.replaced});

  final bool replaced;
}

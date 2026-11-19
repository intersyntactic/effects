import 'dart:typed_data';

import 'relative_path.dart';

/// [text] for the file at [path]. The driver decides whether it may be
/// written, including whether [path] must stay within its root.
final class FileText {
  const FileText(this.path, this.text);

  final RelativePath path;
  final String text;
}

/// What a text read found.
sealed class ReadResult {
  const ReadResult();
}

final class ReadText extends ReadResult {
  const ReadText(this.text);

  final String text;
}

/// What a bytes read found.
sealed class BytesReadResult {
  const BytesReadResult();
}

/// The file's exact bytes, such as a .docx's zip.
final class ReadBytes extends BytesReadResult {
  const ReadBytes(this.bytes);

  final Uint8List bytes;
}

/// No file at the path; what either kind of read can find.
final class ReadMissing implements ReadResult, BytesReadResult {
  const ReadMissing();
}

/// Written; [replaced] when a file was there before.
final class Wrote {
  const Wrote({required this.replaced});

  final bool replaced;
}

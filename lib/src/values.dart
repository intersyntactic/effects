import 'path_in_repo.dart';

/// What became of a run.
sealed class Outcome<O> {
  const Outcome();
}

/// It ran, and gave [output].
final class Ran<O> extends Outcome<O> {
  const Ran(this.output);

  final O output;
}

/// It did not run: the airlock denied it, the journey path was stopped, its
/// driver refused it, or this machine has no driver for its program. An
/// [Outcome] of every program, since [Never] is a subtype of every type.
final class Refused extends Outcome<Never> {
  const Refused(this.why);

  final String why;
}

/// [text] for the file at [path]. The driver decides whether it may be
/// written; that [path] stays inside the repo is fixed by its type.
final class FileText {
  const FileText(this.path, this.text);

  final PathInRepo path;
  final String text;
}

/// A program the home can start, by name, such as `git`.
final class ProgramName {
  const ProgramName._(this.value);

  /// [raw] as a program's name, or null when it is blank or holds
  /// whitespace: `git status` is `git` with an argument.
  static ProgramName? parse(String raw) =>
      raw.isEmpty || raw.contains(RegExp(r'\s')) ? null : ProgramName._(raw);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProgramName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// What a started program is given. How long it may run, and when it is
/// killed, is the driver's to decide.
final class Args {
  const Args(this.args, {this.stdin, this.inFolder = PathInRepo.root});

  final List<String> args;

  /// Written to the program's stdin, then closed. Null: stdin is closed at
  /// once.
  final String? stdin;

  /// The folder it runs in.
  final PathInRepo inFolder;
}

/// What a driver reports while a run is underway, before its outcome.
sealed class Progress {
  const Progress();
}

/// A started program printed [text] on [channel].
final class Printed extends Progress {
  const Printed(this.channel, this.text);

  final Channel channel;
  final String text;
}

enum Channel { stdout, stderr }

/// Where a driver reports [Progress] for the run it is carrying out.
typedef Report = void Function(Progress progress);

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

/// What a program did once it started: it [Exited], or it was [Killed].
///
/// One that never started is [Refused], with its own reason, so there is no
/// refused case here.
sealed class ExecResult {
  const ExecResult({required this.stdout, required this.stderr});

  final String stdout;
  final String stderr;
}

/// It ended by itself, with [exitCode].
final class Exited extends ExecResult {
  const Exited(this.exitCode, {required super.stdout, required super.stderr});

  final int exitCode;
}

/// The driver killed it, because [why], such as `timed out after 600s`; it
/// has no exit code.
final class Killed extends ExecResult {
  const Killed(this.why, {required super.stdout, required super.stderr});

  final String why;
}

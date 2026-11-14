import 'relative_path.dart';

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
  const Args(this.args, {this.stdin, this.inFolder = RelativePath.root});

  final List<String> args;

  /// Written to the program's stdin, then closed. Null: stdin is closed at
  /// once.
  final String? stdin;

  /// The folder it runs in, relative to the driver's root. Whether this may
  /// leave that root is the operator's choice, enforced by the driver.
  final RelativePath inFolder;
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

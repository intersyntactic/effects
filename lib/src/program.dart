import 'model.dart';
import 'outcome.dart';
import 'relative_path.dart';

/// A program this machine can start, by name, such as `git`: named, never
/// located, so the machine's driver decides which file that name runs.
final class ProgramName {
  const ProgramName._(this.value);

  /// [raw] as a program's name, or null when it is blank, holds
  /// whitespace (`git status` is `git` with an argument) or a NUL, holds a
  /// `/` (`/bin/sh`, `../../x` would be a path, which an executor runs as
  /// that file), or is `.` or `..`.
  static ProgramName? parse(String raw) =>
      raw.isEmpty ||
          raw == '.' ||
          raw == '..' ||
          raw.contains('/') ||
          raw.contains('\u0000') ||
          raw.contains(RegExp(r'\s'))
      ? null
      : ProgramName._(raw);

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

/// What the airlock asks the program driver to do.
sealed class ProgramRequest {
  const ProgramRequest();
}

/// Run [program] with [args]; the answer is a line per [ProgramMessage].
final class RunProgramRequest extends ProgramRequest {
  const RunProgramRequest(this.program, this.args);

  final ProgramName program;
  final Args args;
}

/// Say which programs are installed; the answer is one line, their names
/// as a sorted JSON list.
final class ListInstalledProgramsRequest extends ProgramRequest {
  const ListInstalledProgramsRequest();
}

/// What a driver reports while an action is underway, before its outcome.
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

/// A piece of the model's reply as it arrives. Never recorded: only the
/// whole reply, once the call is over, is kept.
final class ReplyArriving extends Progress {
  const ReplyArriving(this.text);

  final String text;
}

/// Where a driver reports [Progress] for the action it is carrying out.
typedef Report = void Function(Progress progress);

/// What a program did once it started: it [Exited], or it was [Killed].
///
/// One that never started is [NothingRan], with its own reason, so there is
/// no such case here.
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

/// What a program driver sends back about one action it was asked to start:
/// any number of [Reported] while the action is underway, then one
/// [Finished] with an [Outcome] of [O] — an [ExecResult] for a started
/// program, a [ModelReply] for a model call.
///
/// The driver's [Report] carries [Progress] and its return value carries the
/// [Outcome]; across a wire both travel as these, in order.
sealed class ProgramMessage<O> {
  const ProgramMessage();
}

/// The driver reported [progress] while the action was underway.
final class Reported<O> extends ProgramMessage<O> {
  const Reported(this.progress);

  final Progress progress;
}

/// The action is over, with [outcome]; nothing follows it.
final class Finished<O> extends ProgramMessage<O> {
  const Finished(this.outcome);

  final Outcome<O> outcome;
}

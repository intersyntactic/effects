import 'file.dart';
import 'outcome.dart';
import 'program.dart';
import 'relative_path.dart';
import 'web.dart';

/// Operates one part of the world. A machine loads the drivers it can run: a
/// phone's loads no [ProgramDriver].
///
/// A driver knows the effect it carries out and nothing of who decided it:
/// it is reached only once that is decided.
abstract interface class Driver {}

/// Reads and writes files under its own root. Whether a path may leave that
/// root — by its text, or by a symlink only the disk can show — is the
/// operator's choice; this driver is where that choice is enforced.
abstract interface class FileDriver implements Driver {
  Future<Outcome<ReadResult>> read(RelativePath path);
  Future<Outcome<Wrote>> write(FileText file);
}

/// Starts programs as processes, reporting what they print as they print
/// it. How long one may run, and when it is killed, is the driver's.
abstract interface class ProgramDriver implements Driver {
  Future<Outcome<ExecResult>> start(
    ProgramName program,
    Args args, {
    required Report report,
  });
}

/// Sends requests out of the home. Holds each sign-in's secret and applies
/// it, so the airlock decides a [Request] without ever seeing one.
abstract interface class WebDriver implements Driver {
  Future<Outcome<Sent>> send(Request request);
}

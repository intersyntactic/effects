import 'path_in_repo.dart';
import 'values.dart';

/// Operates one part of the world. A machine loads the drivers it can run: a
/// phone's loads no [ProgramDriver].
///
/// A driver knows the effect it carries out and nothing of who decided it:
/// it is reached only once that is settled.
abstract interface class Driver {}

/// Reads and writes files in the journey's working tree. Refuses a path
/// whose text stays inside but which a symlink leads out of.
abstract interface class FileDriver implements Driver {
  Future<Outcome<ReadResult>> read(PathInRepo path);
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

/// Sends requests out of the home. Holds each provider's address and each
/// sign-in's secret, and adds them; reports what arrives as it arrives.
abstract interface class NetworkDriver implements Driver {
  Future<Outcome<Response>> send(Request request, {required Report report});
}

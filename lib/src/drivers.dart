import 'package:is_path_confinement/is_path_confinement.dart' show isInsideTree;

import 'file.dart';
import 'outcome.dart';
import 'program.dart';
import 'relative_path.dart';
import 'web.dart';

/// Operates one part of the world. A machine loads the drivers it can run: a
/// phone's loads no [StartsPrograms].
///
/// A driver knows the action it carries out and nothing of who decided it:
/// it is reached only once that is decided.
abstract interface class CarriesOutActions {}

/// Reads and writes files under its own root. Whether a path may leave that
/// root — by its text, or by a symlink only the disk can show — is the
/// operator's choice; this driver is where that choice is enforced, with
/// [isInsideTree].
abstract interface class ReadsAndWritesFiles implements CarriesOutActions {
  Future<Outcome<ReadResult>> read(RelativePath path);
  Future<Outcome<Wrote>> write(FileText file);
}

/// Starts programs as processes, reporting what they print as they print
/// it. How long one may run, and when it is killed, is the driver's.
abstract interface class StartsPrograms implements CarriesOutActions {
  Future<Outcome<ExecResult>> start(
    ProgramName program,
    Args args, {
    required Report report,
  });
}

/// Reaches the world: carries out requests. Holds each sign-in's secret and
/// applies it, so the airlock decides a [Request] without ever seeing one.
abstract interface class CarriesOutWebRequests implements CarriesOutActions {
  Future<Outcome<WebRequestOutcome>> carryOutWebRequest(Request request);
}

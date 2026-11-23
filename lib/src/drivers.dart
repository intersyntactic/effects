import 'package:is_path_confinement/is_path_confinement.dart' show isInsideTree;

import 'file.dart';
import 'model.dart';
import 'outcome.dart';
import 'program.dart';
import 'relative_path.dart';
import 'web.dart';

/// Operates one part of the world. A machine loads the drivers it can run: a
/// phone's loads no [RunsPrograms].
///
/// A driver knows the action it carries out and nothing of who decided it:
/// it is reached only once that is decided.
abstract interface class CarriesOutActions {}

/// Reads and writes files under its own root. Whether a path may leave that
/// root — by its text, or by a symlink only the disk can show — is the
/// operator's choice; this driver is where that choice is enforced, with
/// [isInsideTree].
///
/// The caller chooses text or bytes, so the airlock decides on exactly what
/// will come back. A file [read] as text that isn't UTF-8 is [Refused], never
/// decoded loosely. [ReadText] is the file's exact text, a leading byte order
/// mark (U+FEFF) included, which Dart's `utf8.decode` would drop; a [write]
/// of it puts back the bytes that were read. How large a file [readBytes]
/// returns is the driver's to decide: one over that is [Refused], since
/// every byte returned is recorded.
abstract interface class ReadsAndWritesFiles implements CarriesOutActions {
  Future<Outcome<ReadResult>> read(RelativePath path);
  Future<Outcome<BytesReadResult>> readBytes(RelativePath path);
  Future<Outcome<Wrote>> write(FileText file);
}

/// Runs a program as a process from start to exit (or kill), reporting what
/// it prints as it prints it. How long it may run, and when it is killed,
/// is the driver's.
abstract interface class RunsPrograms implements CarriesOutActions {
  Future<Outcome<ExecResult>> runProgram(
    ProgramName program,
    Args args, {
    required Report report,
  });
}

/// Says which programs this machine has, so loop_launcher can check a
/// trajectory's rules against the machine before it starts. Not a
/// [CarriesOutActions]: it is asked before anything is decided, and
/// changes nothing.
abstract interface class ListsInstalledPrograms {
  /// The programs a [RunsPrograms] here would find by name.
  Future<Set<ProgramName>> installedPrograms();
}

/// Reaches the world: carries out granted requests. Holds each sign-in's
/// secret and applies it, so the airlock decides a [ProposedRequest]
/// without ever seeing one.
///
/// A 2xx response's body comes back as [ProposedRequest.keep] asks:
/// [TextBody] for text, [BytesBody] for bytes, [NoBody] otherwise. A text
/// body that isn't UTF-8 is [Refused], never decoded loosely, and a
/// [TextBody] keeps a leading byte order mark (U+FEFF), as a file read
/// does. How large a body it keeps is the driver's to decide: one over that
/// is [Refused], since every byte kept is recorded.
///
/// Which redirects it follows is the driver's, and it never sends a
/// sign-in's secret across to another origin; every hop it followed is
/// named, in order, in [WebResponse.redirects]. A hop on the request's own
/// origin that leaves its [GrantedRequest.grantedPathPrefix] is [Refused],
/// never followed.
abstract interface class CarriesOutWebRequests implements CarriesOutActions {
  Future<Outcome<WebResponse>> carryOutWebRequest(GrantedRequest request);
}

/// Calls the model. Holds every model sign-in: the model is outside the
/// station, so the loop that proposes a call reaches it only through here,
/// never directly. [systemPrompt] and [request] are each the exact bytes
/// the airlock has approved, verbatim; [report] carries each
/// [ReplyArriving] piece as it streams, never recorded, until the whole
/// [ModelReply] is.
///
/// When [request] itself names a model, that name must be [model], or the
/// driver refuses without calling: the airlock decided on [model], so the
/// logbook must not show one thing decided and another called.
abstract interface class AsksTheModel implements CarriesOutActions {
  Future<Outcome<ModelReply>> askTheModel(
    ModelSignInName signIn,
    ModelName model,
    String systemPrompt,
    String request, {
    required Report report,
  });
}

import 'dart:typed_data';

import 'drivers.dart' show CarriesOutWebRequests;
import 'model.dart';
import 'web.dart';

/// Builds the requests that post back to where an event came from, such as
/// a Teams conversation: the card saying a trajectory opened for it, and
/// the model's reply. One implementation per relay whose events can be
/// answered, so the airlock never knows any relay's wire; it picks the
/// implementation by the event's address and decides the requests it
/// builds as they are.
///
/// It only builds: sending is a [CarriesOutWebRequests]' job, and the
/// requests reach it only once the airlock has decided on them.
///
/// Each method takes [relayedEvent] as the event's bytes exactly as its
/// relay recorded them, which name where an answer goes, and is null when
/// that is not an event this implementation can answer.
abstract interface class BuildsRequestsAnsweringEvents {
  /// The requests that tell [relayedEvent]'s sender a trajectory opened for
  /// it, going as [signIn].
  List<Request>? trajectoryOpenedRequests({
    required Uint8List relayedEvent,
    required SignIn signIn,
  });

  /// The requests that post [reply] in answer to [relayedEvent], in posting
  /// order, going as [signIn].
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required ModelReply reply,
    required SignIn signIn,
  });
}

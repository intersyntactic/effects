import 'dart:typed_data';

import 'drivers.dart' show CarriesOutWebRequests;
import 'model.dart';
import 'outcome.dart' show Refused;
import 'place_in_trajectory.dart';
import 'web.dart';

/// Builds the requests that post back to where an event came from, such as
/// a Teams conversation: the card saying a trajectory opened for it, the
/// model's reply, and the notice that an action was refused. One implementation per relay whose events can be
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
///
/// Each method also takes the [PlaceInTrajectory] it answers from, for a
/// card to print or leave off. The place is the loop's claim, from its
/// proposal, and the airlock verifies nothing about it: show it, never
/// decide anything by it.
abstract interface class BuildsRequestsAnsweringEvents {
  /// The requests that tell [relayedEvent]'s sender a trajectory opened for
  /// it at [place], going as [signIn].
  List<Request>? trajectoryOpenedRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required SignIn signIn,
  });

  /// The requests that post [reply], made at [place], in answer to
  /// [relayedEvent], in posting order, going as [signIn].
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required ModelReply reply,
    required SignIn signIn,
  });

  /// The requests that tell [relayedEvent]'s sender an action at [place]
  /// was refused because [why], so they can decide what happens next,
  /// going as [signIn].
  ///
  /// [why] is a [Refused.why] as the airlock recorded it, which the airlock
  /// has checked came from a refusal, never from an action that ran.
  List<Request>? refusalNoticeRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required String why,
    required SignIn signIn,
  });
}

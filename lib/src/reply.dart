import 'dart:typed_data';

import 'drivers.dart' show CarriesOutWebRequests;
import 'model.dart';
import 'web.dart';

/// Builds the requests that post a model's reply back to where an event
/// came from, such as a Teams conversation. One implementation per relay
/// that can be answered; the airlock picks it by the event's address and
/// decides the requests it builds as they are.
///
/// It only builds: sending is a [CarriesOutWebRequests]' job, and the
/// requests reach it only once the airlock has decided on them.
abstract interface class BuildsReplyRequests {
  /// The requests that post [reply] in answer to [relayedEvent], in posting
  /// order, going as [signIn]; or null when [relayedEvent] is not an event
  /// this module can answer.
  ///
  /// [relayedEvent] is the event's bytes exactly as its relay recorded
  /// them, which name where a reply to it goes.
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required ModelReply reply,
    required SignIn signIn,
  });
}

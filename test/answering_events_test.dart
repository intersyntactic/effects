import 'dart:convert';
import 'dart:typed_data';

import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

/// Answers events whose bytes are a site's address, posting there with the
/// turn it answers from.
final class _PostsToTheNamedSite implements BuildsRequestsAnsweringEvents {
  @override
  List<Request>? trajectoryOpenedRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required SignIn signIn,
  }) => _post(relayedEvent, signIn, 'opened at turn ${place.turn}');

  @override
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required ModelReply reply,
    required SignIn signIn,
  }) => _post(relayedEvent, signIn, switch (reply) {
    FinishedReply(:final text) ||
    CutOffReply(:final text) => 'turn ${place.turn}: $text',
  });

  @override
  List<Request>? refusalNoticeRequests({
    required Uint8List relayedEvent,
    required PlaceInTrajectory place,
    required String why,
    required SignIn signIn,
  }) => _post(relayedEvent, signIn, 'turn ${place.turn} refused: $why');

  List<Request>? _post(Uint8List relayedEvent, SignIn signIn, String body) {
    final origin = Origin.parse(utf8.decode(relayedEvent));
    if (origin == null) return null;
    return [Request(origin, method: Method.post, signIn: signIn, body: body)];
  }
}

void main() {
  final module = _PostsToTheNamedSite();
  final signIn = SignIn.parse('cam-teams')!;
  const reply = FinishedReply(text: 'done', usage: null);
  final opening = PlaceInTrajectory.at(0, 0);
  final later = PlaceInTrajectory.at(3, 0);
  final answerable = utf8.encode('https://chat.example.com');
  final unanswerable = utf8.encode('not an address');

  test('builds the reply for an event it can answer, from its place', () {
    final requests = module.replyRequests(
      relayedEvent: answerable,
      place: later,
      reply: reply,
      signIn: signIn,
    )!;
    expect(requests.single.origin, Origin.parse('https://chat.example.com'));
    expect(requests.single.signIn, signIn);
    expect(requests.single.body, 'turn 3: done');
  });

  test('builds the trajectory-opened requests for an event it can answer', () {
    final requests = module.trajectoryOpenedRequests(
      relayedEvent: answerable,
      place: opening,
      signIn: signIn,
    )!;
    expect(requests.single.body, 'opened at turn 0');
  });

  test('builds the refusal notice for an event it can answer', () {
    final requests = module.refusalNoticeRequests(
      relayedEvent: answerable,
      place: later,
      why: 'the airlock denied it',
      signIn: signIn,
    )!;
    expect(requests.single.body, 'turn 3 refused: the airlock denied it');
  });

  test('is null for an event it cannot answer, from every method', () {
    expect(
      module.refusalNoticeRequests(
        relayedEvent: unanswerable,
        place: later,
        why: 'the airlock denied it',
        signIn: signIn,
      ),
      isNull,
    );
    expect(
      module.replyRequests(
        relayedEvent: unanswerable,
        place: later,
        reply: reply,
        signIn: signIn,
      ),
      isNull,
    );
    expect(
      module.trajectoryOpenedRequests(
        relayedEvent: unanswerable,
        place: opening,
        signIn: signIn,
      ),
      isNull,
    );
  });
}

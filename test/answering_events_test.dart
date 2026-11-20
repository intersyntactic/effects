import 'dart:convert';
import 'dart:typed_data';

import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

/// Answers events whose bytes are a site's address, posting there.
final class _PostsToTheNamedSite implements BuildsRequestsAnsweringEvents {
  @override
  List<Request>? trajectoryOpenedRequests({
    required Uint8List relayedEvent,
    required SignIn signIn,
  }) => _post(relayedEvent, signIn, 'opened');

  @override
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required ModelReply reply,
    required SignIn signIn,
  }) => _post(relayedEvent, signIn, switch (reply) {
    FinishedReply(:final text) || CutOffReply(:final text) => text,
  });

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
  final answerable = utf8.encode('https://chat.example.com');
  final unanswerable = utf8.encode('not an address');

  test('builds the reply for an event it can answer', () {
    final requests = module.replyRequests(
      relayedEvent: answerable,
      reply: reply,
      signIn: signIn,
    )!;
    expect(requests.single.origin, Origin.parse('https://chat.example.com'));
    expect(requests.single.signIn, signIn);
    expect(requests.single.body, 'done');
  });

  test('builds the trajectory-opened requests for an event it can answer', () {
    final requests = module.trajectoryOpenedRequests(
      relayedEvent: answerable,
      signIn: signIn,
    )!;
    expect(requests.single.body, 'opened');
  });

  test('is null for an event it cannot answer, from either method', () {
    expect(
      module.replyRequests(
        relayedEvent: unanswerable,
        reply: reply,
        signIn: signIn,
      ),
      isNull,
    );
    expect(
      module.trajectoryOpenedRequests(
        relayedEvent: unanswerable,
        signIn: signIn,
      ),
      isNull,
    );
  });
}

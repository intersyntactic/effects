import 'dart:convert';
import 'dart:typed_data';

import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

/// Answers events whose bytes are a site's address, posting the reply's
/// text there.
final class _PostsToTheNamedSite implements BuildsReplyRequests {
  @override
  List<Request>? replyRequests({
    required Uint8List relayedEvent,
    required ModelReply reply,
    required SignIn signIn,
  }) {
    final origin = Origin.parse(utf8.decode(relayedEvent));
    if (origin == null) return null;
    return [
      Request(
        origin,
        method: Method.post,
        signIn: signIn,
        body: switch (reply) {
          FinishedReply(:final text) || CutOffReply(:final text) => text,
        },
      ),
    ];
  }
}

void main() {
  final module = _PostsToTheNamedSite();
  final signIn = SignIn.parse('cam-teams')!;
  const reply = FinishedReply(text: 'done', usage: null);

  test('builds the requests for an event it can answer', () {
    final requests = module.replyRequests(
      relayedEvent: utf8.encode('https://chat.example.com'),
      reply: reply,
      signIn: signIn,
    )!;
    expect(requests.single.origin, Origin.parse('https://chat.example.com'));
    expect(requests.single.signIn, signIn);
    expect(requests.single.body, 'done');
  });

  test('is null for an event it cannot answer', () {
    expect(
      module.replyRequests(
        relayedEvent: utf8.encode('not an address'),
        reply: reply,
        signIn: signIn,
      ),
      isNull,
    );
  });
}

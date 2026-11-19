import 'program.dart';

/// One of the person's model sign-ins, by name, such as `anthropic-api`.
/// Never the secret: the driver holds that, so it reaches neither a tool
/// nor the record.
final class ModelSignInName {
  const ModelSignInName._(this.name);

  /// [raw] as a model sign-in's name, or null unless it is lowercase
  /// letters, digits, `-` and `_`.
  static ModelSignInName? parse(String raw) =>
      _name.hasMatch(raw) ? ModelSignInName._(raw) : null;

  final String name;

  @override
  bool operator ==(Object other) =>
      other is ModelSignInName && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

final _name = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

/// A model this machine can call, by id, such as `claude-opus-5-5`.
final class ModelName {
  const ModelName._(this.value);

  /// [raw] as a model's id, or null when it is blank or holds whitespace.
  static ModelName? parse(String raw) =>
      raw.isEmpty || raw.contains(RegExp(r'\s')) ? null : ModelName._(raw);

  final String value;

  @override
  bool operator ==(Object other) => other is ModelName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// What the model said, in reply to one call: not the transport it
/// arrived in, nor the pieces streamed beforehand ([ReplyArriving],
/// never recorded) — a driver whose wire is a stream of events gives the
/// one marking the call as done (such as a `result` event's own text).
/// Recorded once, as an outcome.
///
/// Either [FinishedReply] (the model was done) or [CutOffReply] (the call
/// ran and spent tokens, but the reply ended before the model was —
/// such as ChatGPT's own `incomplete` status). Still recorded as [Ran],
/// never [Refused]: tokens were spent, and a reply, however partial,
/// came back. The two are a closed set on purpose: a cut-off reply reads
/// a caller handles differently from a whole one (it isn't the agent's
/// full word, isn't what the model actually said in full to post or to
/// hand back as history), and a type that forces every reader to say
/// which it means can't be mistaken for the other just because nobody
/// thought to check a flag.
sealed class ModelReply {
  const ModelReply({required this.text, this.usage});

  /// The model's text: whole if [FinishedReply], only as far as the call
  /// got if [CutOffReply].
  final String text;

  /// What the call spent, when the driver can report it. Null for a
  /// driver that can't (ChatGPT's plan has no cache-creation count or
  /// context window), and for every reply recorded before [usage]
  /// existed.
  final ModelUsage? usage;
}

/// The model was done: [text] is its whole reply.
final class FinishedReply extends ModelReply {
  const FinishedReply({required super.text, super.usage});
}

/// The call ran and spent tokens, but [text] ends before the model was
/// done.
final class CutOffReply extends ModelReply {
  const CutOffReply({required super.text, super.usage});
}

/// What one model call spent. [input], [cacheRead] and [output] are what
/// every driver checked so far can report; [cacheCreation] is null for a
/// driver that can't tell it apart from [input] (ChatGPT's plan has no
/// such count). [contextWindow] is the model's own limit, null when the
/// driver can't tell it (ChatGPT's plan doesn't say).
final class ModelUsage {
  const ModelUsage({
    required this.input,
    required this.cacheRead,
    required this.output,
    this.cacheCreation,
    this.contextWindow,
  });

  final int input;
  final int cacheRead;
  final int output;
  final int? cacheCreation;
  final int? contextWindow;

  /// What counts against [contextWindow]: [input] and [cacheRead] (already
  /// in context) plus whatever this call newly wrote into the cache.
  /// Never [output]: a reply's tokens leave with the reply, not the
  /// context.
  int get context => input + cacheRead + (cacheCreation ?? 0);

  @override
  bool operator ==(Object other) =>
      other is ModelUsage &&
      other.input == input &&
      other.cacheRead == cacheRead &&
      other.output == output &&
      other.cacheCreation == cacheCreation &&
      other.contextWindow == contextWindow;

  @override
  int get hashCode =>
      Object.hash(input, cacheRead, output, cacheCreation, contextWindow);
}

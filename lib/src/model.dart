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

/// The model's final text, whole: not the transport it arrived in, nor
/// the pieces streamed beforehand ([ReplyArriving], never recorded) —
/// a driver whose wire is a stream of events gives the one marking the
/// call as done (such as a `result` event's own text). Recorded once,
/// as an outcome.
final class ModelReply {
  const ModelReply(this.text, {this.usage, this.incomplete = false});

  final String text;

  /// What the call spent, when the driver can report it. Null for a
  /// driver that can't (ChatGPT's plan has no cache-creation count or
  /// context window), and for every reply recorded before [usage]
  /// existed.
  final ModelUsage? usage;

  /// The call ran and spent tokens, but the reply was cut off before the
  /// model was done — such as ChatGPT's own `incomplete` status. Still
  /// recorded as [Ran], never [Refused]: tokens were spent, and a reply,
  /// however partial, came back.
  final bool incomplete;
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

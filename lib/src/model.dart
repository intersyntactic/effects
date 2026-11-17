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
  const ModelReply(this.text);

  final String text;
}

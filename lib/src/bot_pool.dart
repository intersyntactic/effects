/// A pool of bots, by name, such as `teams`, that a trajectory leases one
/// bot from.
final class BotPool {
  const BotPool._(this.name);

  /// [raw] as a bot pool's name, or null unless it is lowercase letters,
  /// digits, `-` and `_`.
  static BotPool? parse(String raw) =>
      _name.hasMatch(raw) ? BotPool._(raw) : null;

  final String name;

  @override
  bool operator ==(Object other) => other is BotPool && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

final _name = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

/// What became of an action.
sealed class Outcome<O> {
  const Outcome();
}

/// It ran, and gave [output].
final class Ran<O> extends Outcome<O> {
  const Ran(this.output);

  final O output;
}

/// It did not run: the airlock denied it, the trajectory was stopped, its
/// driver refused it, or this machine has no driver for its program. An
/// [Outcome] of every program, since [Never] is a subtype of every type.
final class Refused extends Outcome<Never> {
  const Refused(this.why);

  /// Why, in the refuser's own words. It is recorded and can be shown to
  /// the person who started the trajectory, such as on a Teams card, so it
  /// never carries what an action read (file text, a response body) or a
  /// secret (a token, or an address with its query).
  final String why;
}

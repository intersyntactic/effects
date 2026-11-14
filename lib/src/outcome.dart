/// What became of a run.
sealed class Outcome<O> {
  const Outcome();
}

/// It ran, and gave [output].
final class Ran<O> extends Outcome<O> {
  const Ran(this.output);

  final O output;
}

/// It did not run: the airlock denied it, the journey path was stopped, its
/// driver refused it, or this machine has no driver for its program. An
/// [Outcome] of every program, since [Never] is a subtype of every type.
final class Refused extends Outcome<Never> {
  const Refused(this.why);

  final String why;
}

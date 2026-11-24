/// What became of an action, split on one question: did the world change?
sealed class Outcome<O> {
  const Outcome();
}

/// It ran, and gave [output].
final class Ran<O> extends Outcome<O> {
  const Ran(this.output);

  final O output;
}

/// Nothing ran, so the world is as it was: the airlock denied it, the
/// trajectory was stopped, its inputs were bad or missing, or this machine
/// has no driver for its program. [why] says which. An [Outcome] of every
/// program, since [Never] is a subtype of every type.
final class NothingRan extends Outcome<Never> {
  const NothingRan(this.why);

  final String why;
}

/// It started and stopped before the end, after [done] had already
/// happened, for [why]. Never safe to retry as if nothing ran.
final class StoppedPartway extends Outcome<Never> {
  const StoppedPartway({required this.why, required this.done});

  final String why;
  final String done;
}

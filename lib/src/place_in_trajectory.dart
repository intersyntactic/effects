/// Where in its trajectory a loop proposed an action: the [turn], one model
/// call and what it caused, and the [step] within it. The model call is
/// step 0 and a tool call's actions follow it, so a loop that restarts
/// proposes the same steps at the same places, and a place the record
/// already answers is one it need not propose again.
final class PlaceInTrajectory implements Comparable<PlaceInTrajectory> {
  const PlaceInTrajectory._(this.turn, this.step);

  /// The place [step] of [turn]; both are counted from 0.
  factory PlaceInTrajectory.at(int turn, int step) => turn >= 0 && step >= 0
      ? PlaceInTrajectory._(turn, step)
      : throw ArgumentError('a place is counted from 0: $turn, $step');

  /// [json], as [toJson] writes it, read back; null when it is not one.
  static PlaceInTrajectory? parse(Object? json) => switch (json) {
    [final int turn, final int step] when turn >= 0 && step >= 0 =>
      PlaceInTrajectory._(turn, step),
    _ => null,
  };

  final int turn;
  final int step;

  Object? toJson() => [turn, step];

  /// By [turn], then by [step]: a trajectory's places in the order they
  /// were proposed.
  @override
  int compareTo(PlaceInTrajectory other) => turn != other.turn
      ? turn.compareTo(other.turn)
      : step.compareTo(other.step);

  @override
  bool operator ==(Object other) =>
      other is PlaceInTrajectory && other.turn == turn && other.step == step;

  @override
  int get hashCode => Object.hash(turn, step);

  @override
  String toString() => '$turn.$step';
}

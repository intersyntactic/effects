import 'dart:convert';

import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

void main() {
  test('a place is a turn and a step, read back strictly and in order', () {
    final place = PlaceInTrajectory.at(2, 5);
    expect(place.toJson(), [2, 5]);
    expect(
      PlaceInTrajectory.parse(jsonDecode(jsonEncode(place.toJson()))),
      place,
    );
    for (final json in [
      null,
      1,
      'first',
      [1],
      [1, 2, 3],
      [1.0, 2],
      [-1, 0],
      [0, -1],
      ['1', '2'],
    ]) {
      expect(PlaceInTrajectory.parse(json), isNull, reason: '$json');
    }
    expect(() => PlaceInTrajectory.at(-1, 0), throwsArgumentError);
    expect(PlaceInTrajectory.at(1, 0), isNot(PlaceInTrajectory.at(2, 0)));
    expect(PlaceInTrajectory.at(1, 0), isNot(PlaceInTrajectory.at(1, 1)));
    expect(
      [
        PlaceInTrajectory.at(2, 0),
        PlaceInTrajectory.at(1, 9),
        PlaceInTrajectory.at(1, 0),
      ]..sort(),
      [
        PlaceInTrajectory.at(1, 0),
        PlaceInTrajectory.at(1, 9),
        PlaceInTrajectory.at(2, 0),
      ],
    );
  });

  test('prints as turn.step', () {
    expect('${PlaceInTrajectory.at(3, 1)}', '3.1');
  });
}

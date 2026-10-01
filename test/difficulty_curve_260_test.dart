import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/exercise_difficulty.dart';

/// Build 260 Revision 7 (owner decisions of 1 October 2026): the QQL Demo
/// Courses follow a difficulty curve: a larger share of the harder types in
/// later Rounds, the variety kept, picture exercises preferred.

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

List<LearningRound> _practice(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds)
      if (!round.isStory) round,
];

List<Exercise> _answered(LearningRound round) => [
  for (final exercise in round.exercises)
    if ((ExerciseDifficulty.of(exercise)?.value ?? 0) > 0) exercise,
];

double _mean(Iterable<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _hardShare(LearningRound round) {
  final answered = _answered(round);
  return answered
          .where((exercise) => ExerciseDifficulty.of(exercise)!.value >= 3)
          .length /
      answered.length;
}

void main() {
  for (final file in [
    'english_from_italian_it_en.json',
    'piedmontese_mixed_en.json',
  ]) {
    group(file, () {
      final course = _load(file);
      final rounds = _practice(course);
      final averages = [
        for (final round in rounds) ExerciseDifficulty.averageOf(round)!,
      ];

      test('the Rounds get harder', () {
        final third = rounds.length ~/ 3;
        final first = _mean(averages.take(third));
        final middle = _mean(averages.skip(third).take(third));
        final last = _mean(averages.skip(rounds.length - third));
        expect(first, lessThan(middle), reason: '$averages');
        expect(middle, lessThan(last), reason: '$averages');
        expect(_hardShare(rounds.first), lessThan(_hardShare(rounds.last)));
        expect(_hardShare(rounds.last), greaterThanOrEqualTo(.6));
      });

      test('every Round keeps its variety', () {
        for (final round in rounds) {
          final types = {
            for (final content in round.content)
              if (content.editorTemplate != 'before_you_start')
                content.editorTemplate,
          };
          expect(types, hasLength(6), reason: round.id);
        }
      });

      test('every Round still plays with Audio Exercises off', () {
        for (final round in rounds) {
          final heard = round.exercises
              .where((exercise) => ExerciseFeatures(exercise).requiresAudio)
              .length;
          expect(heard, lessThanOrEqualTo(2), reason: round.id);
          expect(
            _answered(round).length - heard,
            greaterThanOrEqualTo(3),
            reason: round.id,
          );
        }
      });
    });
  }

  test('QQL Demo: English from Italian prefers picture exercises', () {
    final course = _load('english_from_italian_it_en.json');
    final rounds = _practice(course);
    final withPictures = [
      for (final round in rounds)
        for (final exercise in round.exercises)
          if (exercise.promptElements.any((element) => element.isImage) ||
              exercise.items.any(
                (item) => item.content.any(
                  (element) => element.isImage || element.role == 'icon',
                ),
              ))
            exercise.id,
    ];
    expect(withPictures.length, greaterThanOrEqualTo(15));
    // One exercise that needs audio in each Round, the easier ones first.
    final heardLevels = [
      for (final round in rounds)
        for (final exercise in round.exercises)
          if (ExerciseFeatures(exercise).requiresAudio)
            ExerciseDifficulty.of(exercise)!.value,
    ];
    expect(heardLevels, hasLength(6));
    expect(heardLevels, orderedEquals([...heardLevels]..sort()));
  });
}

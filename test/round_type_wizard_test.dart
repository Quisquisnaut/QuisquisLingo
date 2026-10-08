import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';

void main() {
  final course = Course.fromJson(
    jsonDecode(
          File(
            'assets/courses/english_from_italian_it_en.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final guidebook = course.lessons.first.guidebook;

  test('Wizard replans compatible types from the same GuideBook', () {
    final generator = GuidebookRoundGenerator(randomSeed: 3);
    final plan = generator.plan(guidebook, roundCount: 4, exercisesPerRound: 2);
    final revised = GuidebookGenerationPlan(
      roundCount: 4,
      exercisesPerRound: 2,
      rounds: [
        generator.changeType(guidebook, plan.rounds[0], RoundType.discover),
        generator.changeType(guidebook, plan.rounds[1], RoundType.listening),
        generator.changeType(guidebook, plan.rounds[2], RoundType.sequence),
        generator.changeType(guidebook, plan.rounds[3], RoundType.test),
      ],
    );
    final drafts = generator.createDrafts(guidebook, revised);
    expect(drafts.map((r) => r.roundType), [
      RoundType.discover,
      RoundType.listening,
      RoundType.sequence,
      RoundType.test,
    ]);
    expect(drafts[2].flow?.isLinear, isTrue);
    expect(
      drafts.every((r) => r.publicationState == PublicationState.draft),
      isTrue,
    );
  });

  test('Wizard refuses unsupported reading and narrative invention', () {
    final generator = GuidebookRoundGenerator();
    final plan = generator.plan(guidebook, roundCount: 1, exercisesPerRound: 2);
    expect(
      () => generator.changeType(
        guidebook,
        plan.rounds.single,
        RoundType.reading,
      ),
      throwsA(isA<GuidebookGenerationException>()),
    );
    expect(
      () =>
          generator.changeType(guidebook, plan.rounds.single, RoundType.story),
      throwsA(isA<GuidebookGenerationException>()),
    );
  });
}

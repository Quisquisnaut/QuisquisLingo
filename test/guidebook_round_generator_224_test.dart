import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';

void main() {
  test('default plan is 6 by 8 and difficulty rises monotonically', () {
    final plan = GuidebookRoundGenerator(randomSeed: 11).plan(_guidebook());

    expect(plan.roundCount, 6);
    expect(plan.exercisesPerRound, 8);
    expect(plan.totalExercises, 48);
    expect(plan.rounds, hasLength(6));
    for (var i = 1; i < plan.rounds.length; i++) {
      expect(
        plan.rounds[i].difficulty,
        greaterThan(plan.rounds[i - 1].difficulty),
      );
    }
    expect(
      plan.rounds.first.presetIds,
      everyElement(
        isIn({'choice', 'gap_choice', 'listening_choice', 'word_match'}),
      ),
    );
    expect(plan.rounds.last.presetIds, contains('type_translation'));
    expect(
      plan.rounds.expand((round) => round.presetIds),
      everyElement(
        predicate<String>((id) => ExercisePresetRegistry.byId(id) != null),
      ),
    );
  });

  test('one-Round and configurable plans respect documented limits', () {
    final generator = GuidebookRoundGenerator();
    final plan = generator.plan(
      _guidebook(),
      roundCount: 1,
      exercisesPerRound: 3,
    );
    expect(plan.totalExercises, 3);
    expect(plan.rounds.single.difficulty, .5);
    expect(
      () => generator.plan(_guidebook(), roundCount: 0),
      throwsArgumentError,
    );
    expect(
      () => generator.plan(
        _guidebook(),
        exercisesPerRound: GuidebookRoundGenerator.maximumExercisesPerRound + 1,
      ),
      throwsArgumentError,
    );
  });

  test('insufficient GuideBook content blocks generation', () {
    expect(
      () => GuidebookRoundGenerator().plan(
        Guidebook(vocabulary: const ['casa = house']),
      ),
      throwsA(isA<GuidebookGenerationException>()),
    );
  });

  test('draft generation is grounded, valid and uses fresh descendant IDs', () {
    final guidebook = _guidebook();
    final generator = GuidebookRoundGenerator(
      randomSeed: 7,
      draftIds: _SequenceIds('draft'),
    );
    final plan = generator.plan(guidebook, roundCount: 3, exercisesPerRound: 8);
    final drafts = generator.createDrafts(guidebook, plan);

    expect(drafts, hasLength(3));
    expect(drafts.expand((round) => round.exercises), hasLength(24));
    final ids = <String>{};
    for (final round in drafts) {
      expect(ids.add(round.id), isTrue);
      for (final content in round.content) {
        expect(ids.add(content.id), isTrue);
        expect(
          content.sourceRefs,
          everyElement(isIn(guidebook.content.map((item) => item.id))),
        );
        final exercise = content.exercise;
        if (exercise == null) continue;
        for (final item in exercise.interaction.items) {
          expect(ids.add(item.id), isTrue);
        }
        expect(
          CourseAuditService()
              .auditExercise(exercise)
              .where((issue) => issue.severity == AuditSeverity.error),
          isEmpty,
        );
      }
    }
  });

  test(
    'approval copying allocates final IDs without touching existing Rounds',
    () {
      final guidebook = _guidebook();
      final generator = GuidebookRoundGenerator(
        draftIds: _SequenceIds('draft'),
      );
      final draft = generator
          .createDrafts(
            guidebook,
            generator.plan(guidebook, roundCount: 1, exercisesPerRound: 2),
          )
          .single;
      final approved = AuthoringDuplicationService(
        ids: _SequenceIds('final'),
      ).duplicateRound(draft);
      final existing = LearningRound(
        id: 'existing_round',
        title: 'Existing',
        exercises: const [],
      );
      final result = [existing, approved];

      expect(result.first, same(existing));
      expect(approved.id, startsWith('final_'));
      expect(
        approved.content.map((content) => content.id),
        everyElement(startsWith('final_')),
      );
    },
  );
}

Guidebook _guidebook() => Guidebook(
  overview: 'Everyday food and drinks.',
  vocabulary: const [
    'cappuccino = cappuccino',
    'pane = bread',
    'acqua = water',
    'tavolo = table',
  ],
  examples: const [
    'Vorrei un cappuccino oggi.',
    'Il pane è sul tavolo.',
    'Bevo acqua ogni mattina.',
    'Il tavolo è libero.',
  ],
);

class _SequenceIds implements AuthoringIdGenerator {
  _SequenceIds(this.prefix);
  final String prefix;
  int _next = 0;

  @override
  String next(String kind) => '${prefix}_${kind}_${_next++}';
}

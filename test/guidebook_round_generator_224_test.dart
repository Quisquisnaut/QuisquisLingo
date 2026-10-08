import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'support/guidebook_fixtures.dart';

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
        isIn({
          'choice_target',
          'gap_choice',
          'listening_choose_target',
          'word_match',
        }),
      ),
    );
    expect(plan.rounds.last.presetIds, contains('type_translation_to_target'));
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
        testGuidebook(wordLines: const ['casa = house']),
      ),
      throwsA(isA<GuidebookGenerationException>()),
    );
  });

  // Build 256 Revision 7 fourth follow-up (owner, 29 September 2026): the
  // Round Wizard creates only preset exercises, each represented by the
  // preset it carries, so every one opens in its preset's form.
  test('every generated exercise is represented by its own preset', () {
    final guidebook = _guidebook();
    final generator = GuidebookRoundGenerator(
      randomSeed: 7,
      draftIds: _SequenceIds('draft'),
    );
    final plan = generator.plan(guidebook, roundCount: 6, exercisesPerRound: 8);
    final seen = <String>{};
    final unrepresented = <String>{};
    for (final round in generator.createDrafts(guidebook, plan)) {
      for (final content in round.content) {
        final exercise = content.exercise;
        if (exercise == null) continue;
        final preset = exercise.editorTemplate;
        seen.add(preset);
        expect(ExercisePresetRegistry.byId(preset), isNotNull, reason: preset);
        if (!PresetRecipes.represents(exercise, preset)) {
          unrepresented.add(preset);
        }
      }
    }
    expect(unrepresented, isEmpty);
    expect(seen, isNot(contains('reading_answer_target')));
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
    // 24 exercises, and the first Round opens with a Draft Before you start
    // card (Build 257).
    expect(drafts.expand((round) => round.exercises), hasLength(25));
    expect(drafts.first.exercises.first.editorTemplate, 'before_you_start');
    final ids = <String>{};
    for (final round in drafts) {
      expect(ids.add(round.id), isTrue);
      for (final content in round.content) {
        expect(ids.add(content.id), isTrue);
        expect(
          content.sourceRefs,
          everyElement(isIn(guidebook.entries.map((item) => item.id))),
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

Guidebook _guidebook() => testGuidebook(
  overview: 'Everyday food and drinks.',
  wordLines: const [
    'cappuccino = cappuccino',
    'pane = bread',
    'acqua = water',
    'tavolo = table',
  ],
  sentenceLines: const [
    'Vorrei un cappuccino oggi. = I would like a cappuccino today.',
    'Il pane è sul tavolo. = The bread is on the table.',
    'Bevo acqua ogni mattina. = I drink water every morning.',
    'Il tavolo è libero. = The table is free.',
  ],
);

class _SequenceIds implements AuthoringIdGenerator {
  _SequenceIds(this.prefix);
  final String prefix;
  int _next = 0;

  @override
  String next(String kind) => '${prefix}_${kind}_${_next++}';
}

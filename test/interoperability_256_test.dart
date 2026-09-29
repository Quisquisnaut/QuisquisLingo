import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_interoperability.dart';
import 'package:quisquislingo_app/models/normalized_import_exercise.dart';
import 'package:quisquislingo_app/services/canonical_exercise_import.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';

/// Build 256 Revision 6: interoperability on canonical semantics. Every
/// catalog mapping names a legal canonical configuration whose
/// executability matches its status, with the preset only as a hint; a
/// normalized external exercise becomes a canonical exercise without any
/// preset, and the hint is recorded only when QQL's recipe represents the
/// result.
final _stamp = DateTime.utc(2026, 9, 28, 23);

NormalizedImportExercise _pickOne({String? presetHint}) =>
    NormalizedImportExercise(
      sourceType: 'PickOne',
      primitive: ExercisePrimitive.select,
      prompt: const [
        PromptElement(type: 'text', role: 'question', text: 'Which is a cat?'),
      ],
      items: const [
        ExerciseItem(
          id: 'a',
          content: [PromptElement(type: 'text', text: 'gatto')],
        ),
        ExerciseItem(
          id: 'b',
          content: [PromptElement(type: 'text', text: 'cane')],
        ),
      ],
      evaluation: const CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['a'],
      ),
      presetHint: presetHint,
    );

void main() {
  group('the catalog', () {
    test('covers every survey pattern', () {
      final mapped = ExerciseInteroperabilityCatalog.mappings
          .map((mapping) => mapping.sourcePattern)
          .toSet();
      expect(mapped, containsAll(ExerciseInteroperabilityCatalog.externalSetA));
      expect(mapped, containsAll(ExerciseInteroperabilityCatalog.externalSetB));
      expect(
        mapped,
        containsAll(ExerciseInteroperabilityCatalog.broaderPatterns),
      );
    });

    test(
      'every mapping is a legal canonical configuration, a flow, or unsupported',
      () {
        for (final mapping in ExerciseInteroperabilityCatalog.mappings) {
          final configuration = mapping.configuration;
          if (mapping.status == ImportabilityStatus.unsupported) {
            expect(configuration, isNull, reason: mapping.sourcePattern);
            expect(mapping.flow, isFalse, reason: mapping.sourcePattern);
            continue;
          }
          if (mapping.flow) {
            expect(configuration, isNull, reason: mapping.sourcePattern);
            continue;
          }
          expect(configuration, isNotNull, reason: mapping.sourcePattern);
          expect(
            configuration!.validate(),
            isEmpty,
            reason: '${mapping.sourcePattern} must be legal',
          );
          // Speak waits for a later version; everything else plays today.
          expect(
            configuration.runtimeSupport.state,
            configuration.primitive == ExercisePrimitive.speak
                ? ExerciseSupportState.readableButNotExecutable
                : ExerciseSupportState.executable,
            reason: mapping.sourcePattern,
          );
        }
      },
    );

    test('a preset hint names a catalogue preset of the same primitive', () {
      for (final mapping in ExerciseInteroperabilityCatalog.mappings) {
        final hint = mapping.presetHint;
        if (hint == null) continue;
        final preset = ExercisePresetRegistry.byId(hint);
        expect(preset, isNotNull, reason: '${mapping.sourcePattern}: $hint');
        expect(
          preset!.primitive,
          mapping.configuration!.primitive,
          reason: '${mapping.sourcePattern}: $hint',
        );
      }
      expect(
        ExerciseInteroperabilityCatalog.mappings
            .where((mapping) => mapping.sourcePattern == 'PickOneAudio')
            .single
            .status,
        ImportabilityStatus.unsupported,
      );
      expect(
        ExerciseInteroperabilityCatalog.mappings
            .where(
              (mapping) => mapping.sourcePattern == 'Story-based comprehension',
            )
            .single
            .flow,
        isTrue,
      );
    });
  });

  group('normalized import', () {
    test('builds a canonical exercise; the source label never enters it', () {
      final exercise = _pickOne().toExercise(
        stableId: 'stable_external_id',
        updatedAt: _stamp,
      );
      expect(exercise.id, 'stable_external_id');
      expect(exercise.primitive, ExercisePrimitive.select);
      expect(exercise.editorTemplate, '');
      expect(exercise.toJson().toString(), isNot(contains('PickOne')));
      expect(exercise.isExecutable, isTrue);
    });

    test('a confirmed hint is recorded, a wrong one is dropped', () {
      const import = CanonicalExerciseImport();
      final confirmed = import.adopt(
        _pickOne(presetHint: 'choice_target'),
        stableId: 'ex1',
        updatedAt: _stamp,
      );
      expect(confirmed.isValid, isTrue);
      expect(confirmed.presetId, 'choice_target');
      expect(confirmed.exercise.editorTemplate, 'choice_target');
      expect(confirmed.hintRejected, isFalse);
      expect(
        PresetRecipes.represents(confirmed.exercise, 'choice_target'),
        isTrue,
      );
      expect(
        confirmed.exercise.semanticallyEquals(
          _pickOne().toExercise(stableId: 'ex1', updatedAt: _stamp),
        ),
        isTrue,
        reason: 'the hint changes nothing canonical',
      );

      final rejected = import.adopt(
        _pickOne(presetHint: 'word_match'),
        stableId: 'ex2',
        updatedAt: _stamp,
      );
      expect(rejected.isValid, isTrue);
      expect(rejected.presetId, isNull);
      expect(rejected.hintRejected, isTrue);
      expect(rejected.exercise.authoringMetadata, isEmpty);

      final none = import.adopt(_pickOne(), stableId: 'ex3', updatedAt: _stamp);
      expect(none.presetId, isNull);
      expect(none.hintRejected, isFalse);
      expect(none.exercise.authoringMetadata, isEmpty);
    });

    test('a Speak exercise is adopted as readable but not executable', () {
      final result = const CanonicalExerciseImport().adopt(
        const NormalizedImportExercise(
          sourceType: 'speaking/repeat',
          primitive: ExercisePrimitive.speak,
          options: {OptionKey.speechMode: EnumOptionValue(SpeechMode.repeat)},
          prompt: [PromptElement(type: 'text', text: 'Buongiorno')],
          evaluation: CanonicalEvaluation(
            mode: EvaluationMode.transcriptionMatch,
          ),
          presetHint: 'say_it',
        ),
        stableId: 'sp1',
        updatedAt: _stamp,
      );
      expect(result.isValid, isTrue);
      expect(
        result.support.state,
        ExerciseSupportState.readableButNotExecutable,
      );
      // A greyed, coming-later preset has no recipe: the hint is dropped.
      expect(result.presetId, isNull);
      expect(result.hintRejected, isTrue);
      final json = result.exercise.toJson();
      expect(
        Exercise.fromJson(
          json,
          contentId: 'sp1',
          publicationState: PublicationState.published,
        ).semanticallyEquals(result.exercise),
        isTrue,
      );
    });

    test('an illegal pairing is invalid and stays without a preset', () {
      final result = const CanonicalExerciseImport().adopt(
        const NormalizedImportExercise(
          sourceType: 'odd',
          primitive: ExercisePrimitive.select,
          evaluation: CanonicalEvaluation(mode: EvaluationMode.exactText),
          presetHint: 'choice_target',
        ),
        stableId: 'bad',
        updatedAt: _stamp,
      );
      expect(result.isValid, isFalse);
      expect(result.support.state, ExerciseSupportState.invalid);
      expect(result.presetId, isNull);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/exercise_creation_planner.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 256 Revision 4, Stage 1 (`docs/256_PRESET_CATALOGUE_PLAN.md`):
/// skill groups, directions, the coming-later list, the picker's filter,
/// chips and greyed tiles.
Course _laboratory() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
  });

  group('registry', () {
    test(
      'every recipe preset sits in a skill group, never in Coming later',
      () {
        expect(ExerciseCategory.values, hasLength(7));
        for (final preset in ExercisePresetRegistry.presets) {
          expect(
            preset.category,
            isNot(ExerciseCategory.comingLater),
            reason: preset.id,
          );
          expect(PresetRecipes.kinds.containsKey(preset.id), isTrue);
          expect(preset.action, isNotEmpty);
        }
        expect(
          ExercisePresetRegistry.inCategory(ExerciseCategory.comingLater),
          isEmpty,
        );
        final populated = ExerciseCategory.values
            .where(
              (category) =>
                  ExercisePresetRegistry.inCategory(category).isNotEmpty,
            )
            .toSet();
        expect(
          populated,
          containsAll([
            ExerciseCategory.vocabulary,
            ExerciseCategory.grammarAndSentences,
            ExerciseCategory.listening,
            ExerciseCategory.readingAndDialogue,
            ExerciseCategory.picturesAndCharacters,
            ExerciseCategory.cardsAndNotes,
          ]),
        );
      },
    );

    test('directions and the approved renames', () {
      ExercisePreset preset(String id) => ExercisePresetRegistry.byId(id)!;
      expect(
        preset('translation_choice_to_target').direction,
        PresetDirection.toTarget,
      );
      expect(
        preset('translation_choice_to_source').direction,
        PresetDirection.toSource,
      );
      expect(preset('word_match').direction, PresetDirection.both);
      expect(preset('flashcard').direction, PresetDirection.none);
      expect(preset('word_order').direction, PresetDirection.toTarget);
      expect(preset('choice_target').name, 'Choose the answer (to target)');
      expect(preset('choice_source').twin, 'choice_target');
      expect(preset('gap_choice').name, 'Pick the missing word');
      expect(preset('super_match').name, 'Match by meaning');
      expect(preset('missing_word').name, 'Listen and fill the gaps');
      expect(preset('image_word').name, 'Spell the word in the picture');
      expect(
        preset('translation_choice_to_target').name,
        'Pick the translation (to target)',
      );
      expect(preset('choice_target').action, 'Choose');
      expect(preset('type_translation_to_target').action, 'Type');
      expect(preset('word_order').action, 'Arrange');
      expect(preset('word_match').action, 'Match');
      expect(preset('flashcard').action, 'Card');
    });

    test('the coming-later presets are listed but never offered', () {
      final later = ExercisePresetRegistry.comingLater;
      // Six since the Revision 7 follow-up: Sort into groups is a preset.
      expect(later, hasLength(6));
      expect(
        later.map((preset) => preset.id),
        isNot(contains('sort_into_groups')),
      );
      for (final preset in later) {
        expect(preset.reason.trim(), isNotEmpty, reason: preset.id);
        expect(
          ExercisePresetRegistry.byId(preset.id),
          isNull,
          reason: preset.id,
        );
        expect(
          ExercisePresetRegistry.presets.any((p) => p.name == preset.name),
          isFalse,
          reason: preset.id,
        );
      }
      expect(later.map((preset) => preset.id), contains('adventure'));
    });

    test('the Wizard planner skips empty skill groups', () {
      final planner = ExerciseCreationPlanner();
      final balanced = planner.create(
        count: 12,
        criterion: ExerciseWizardCriterion.balanced,
      );
      expect(balanced.presetIds, hasLength(12));
      for (final id in balanced.presetIds) {
        expect(ExercisePresetRegistry.byId(id), isNotNull, reason: id);
      }
      // A group without recipes (Coming later) is refused with the planner's
      // usual message, not with a crash.
      expect(
        () => planner.create(
          count: 3,
          criterion: ExerciseWizardCriterion.byCategory,
          categories: const [ExerciseCategory.comingLater],
        ),
        throwsArgumentError,
      );
    });
  });

  group('picker', () {
    Future<void> openPicker(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final course = _laboratory();
      // The preset selector is offered while an exercise is new.
      final blank = Exercise(
        id: 'ex_picker',
        publicationState: PublicationState.draft,
        type: 'translation_choice_to_target',
        prompt: '',
        question: '',
        answers: const [],
        correct: null,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: blank,
            title: 'New exercise',
            isNew: true,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('exercise-preset-selector')));
      await tester.pumpAndSettle();
    }

    testWidgets('skill groups, action chips, greyed tiles', (tester) async {
      await openPicker(tester);
      expect(find.text('Vocabulary'), findsOneWidget);
      expect(find.text('Choose'), findsWidgets);
      // The twins sit at the top of the lazy list, before scrolling.
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_source'),
        ),
        findsOneWidget,
      );
      // The sheet's list is lazy: the greyed presets sit at its end, so
      // drag the sheet's content up until they are built.
      final later = find.byKey(const ValueKey('exercise-preset-later-say_it'));
      await tester.dragUntilVisible(
        later,
        find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(ListView),
            )
            .first,
        const Offset(0, -600),
      );
      expect(later, findsOneWidget);
      expect(find.text('Coming later'), findsOneWidget);
      final tile = tester.widget<ListTile>(
        find.descendant(of: later, matching: find.byType(ListTile)),
      );
      expect(tile.enabled, isFalse);
      expect(find.textContaining('In a later version:'), findsWidgets);
    });

    testWidgets('the direction filter keeps only one side', (tester) async {
      await openPicker(tester);
      await tester.tap(find.text('To source'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_source'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_target'),
        ),
        findsNothing,
      );
      // Both-sided presets stay, cards and coming-later presets go.
      expect(
        find.byKey(const ValueKey('exercise-preset-word_match')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-preset-flashcard')),
        findsNothing,
      );
      expect(find.text('Coming later'), findsNothing);
      await tester.tap(find.text('To target'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_target'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_source'),
        ),
        findsNothing,
      );
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-preset-flashcard')),
        findsOneWidget,
      );
    });
  });

  testWidgets('Exercise Help lists the coming-later presets', (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ExerciseHelpScreen()));
    await tester.pumpAndSettle();
    final later = find.byKey(const ValueKey('exercise-help-later-adventure'));
    await tester.scrollUntilVisible(
      later,
      600,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('exercise-help-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(later, findsOneWidget);
    expect(find.text('Coming later'), findsOneWidget);
  });
}

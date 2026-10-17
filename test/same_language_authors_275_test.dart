import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/new_course_dialog.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/exercise_creation_planner.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/exercise_labels.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/guidebook_paste_list.dart';
import 'package:quisquislingo_app/services/new_course_structure.dart';
import 'package:quisquislingo_app/services/preset_examples.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publish_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Build 275 Revision 4 (the plan's "what authors read", owner decisions of
// 16 and 17 October 2026): in a Course in the same language the authors'
// screens speak of words and meanings. One owner names a preset
// (ExercisePresetRegistry.nameIn), the three "to source" twins that would
// do what their "to target" twin does are not offered for new exercises,
// the forms, the GuideBook page and its Help, the samples and the Wizard's
// texts follow the kind; New Course's Continue to Editor asks before the
// kind and languages become fixed. A translation Course is unchanged.

const _profile = LearnerProfile(
  learnerProfileId: '27500000-0000-4000-8000-000000000401',
  displayName: 'Authors',
);
final _operations = CourseLibraryOperations(
  clock: () => DateTime.utc(2026, 10, 17, 15),
);

/// An English to English Course holding the Laboratory's Lessons, made In
/// the same language or (with [sameLanguage] false) Through another
/// language.
Course _english(Course laboratory, {required bool sameLanguage}) =>
    Course.fromJson({
      ..._operations
          .newWizardCourse(
            creator: _profile,
            title: 'Authors',
            sourceLanguage: 'English',
            targetLanguage: 'English',
            sourceLanguageTag: 'en',
            targetLanguageTag: 'en',
            sameLanguage: sameLanguage,
          )
          .toJson(),
      'lessons': laboratory.toJson()['lessons'],
    });

Exercise _example(Course course, String presetId) {
  final id = PresetExamples.exampleIds[presetId]!;
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        if (exercise.id == id) return exercise;
      }
    }
  }
  throw StateError('No example of $presetId');
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the owner of the names', () {
    test('the translation presets and the four "to target" ones', () {
      for (final (id, name) in [
        ('translation_choice_to_target', 'Pick the word'),
        ('translation_choice_to_source', 'Pick the meaning'),
        ('type_translation_to_target', 'Type the word'),
        ('type_translation_to_source', 'Type the meaning'),
        ('build_translation_to_target', 'Build the sentence'),
        ('build_translation_to_source', 'Build the meaning'),
        ('word_match', 'Match words and meanings'),
        ('choice_target', 'Choose the answer'),
        ('listening_choose_target', 'Listen and choose'),
        ('listening_answer_target', 'Listen and answer'),
        ('reading_answer_target', 'Read and answer'),
      ]) {
        expect(
          ExercisePresetRegistry.nameIn(id, sameLanguage: true),
          name,
          reason: id,
        );
        expect(
          ExercisePresetRegistry.nameIn(id, sameLanguage: false),
          ExercisePresetRegistry.byId(id)!.name,
          reason: id,
        );
      }
      // Every other preset keeps its name.
      for (final preset in ExercisePresetRegistry.presets) {
        if (preset.direction == PresetDirection.none) {
          expect(
            ExercisePresetRegistry.nameIn(preset.id, sameLanguage: true),
            preset.name,
            reason: preset.id,
          );
        }
      }
    });

    test('a retired ID, the descriptions and the directions', () {
      // A retired ID still stored on an exercise is named as its successor.
      expect(
        ExercisePresetRegistry.nameIn('type_translation', sameLanguage: true),
        'Type the word',
      );
      expect(
        ExercisePresetRegistry.nameIn('choice', sameLanguage: true),
        'Choose the answer',
      );
      expect(
        ExercisePresetRegistry.nameIn('type_translation', sameLanguage: false),
        ExercisePresetRegistry.nameOrId('type_translation'),
      );
      final renamed = {
        ...ExercisePresetRegistry.sameLanguageNames.keys,
        'choice_target',
        'listening_choose_target',
        'listening_answer_target',
        'reading_answer_target',
      };
      for (final preset in ExercisePresetRegistry.presets) {
        final same = ExercisePresetRegistry.descriptionIn(
          preset.id,
          sameLanguage: true,
        );
        expect(
          ExercisePresetRegistry.descriptionIn(preset.id, sameLanguage: false),
          preset.description,
          reason: preset.id,
        );
        if (renamed.contains(preset.id)) {
          expect(same, isNot(preset.description), reason: preset.id);
          for (final word in ['translation', 'source', 'target']) {
            expect(
              same.toLowerCase(),
              isNot(contains(word)),
              reason: preset.id,
            );
          }
        } else {
          expect(same, preset.description, reason: preset.id);
        }
      }
      for (final id in [
        'choice_target',
        'listening_choose_target',
        'listening_answer_target',
        'reading_answer_target',
      ]) {
        final preset = ExercisePresetRegistry.byId(id)!;
        expect(
          ExercisePresetRegistry.directionOfIn(preset, sameLanguage: true),
          PresetDirection.both,
          reason: id,
        );
        expect(
          ExercisePresetRegistry.directionOfIn(preset, sameLanguage: false),
          preset.direction,
          reason: id,
        );
      }
      final pick = ExercisePresetRegistry.byId('translation_choice_to_source')!;
      expect(
        ExercisePresetRegistry.directionOfIn(pick, sameLanguage: true),
        PresetDirection.toSource,
      );
    });

    test('the three "to source" twins are not offered; every other preset '
        'is', () {
      for (final preset in ExercisePresetRegistry.presets) {
        final notOffered = {
          'choice_source',
          'listening_choose_source',
          'listening_answer_source',
        }.contains(preset.id);
        expect(
          ExercisePresetRegistry.offeredIn(preset.id, sameLanguage: true),
          !notOffered,
          reason: preset.id,
        );
        expect(
          ExercisePresetRegistry.offeredIn(preset.id, sameLanguage: false),
          isTrue,
        );
      }
      expect(
        ExercisePresetRegistry.directionIn(
          PresetDirection.toTarget,
          sameLanguage: true,
        ),
        'To the word',
      );
      expect(
        ExercisePresetRegistry.directionIn(
          PresetDirection.toSource,
          sameLanguage: false,
        ),
        'To source',
      );
    });

    test('the Exercise Wizard draws no twin in a same-language Course', () {
      const planner = ExerciseCreationPlanner();
      for (final criterion in [
        ExerciseWizardCriterion.balanced,
        ExerciseWizardCriterion.random,
        ExerciseWizardCriterion.byCategory,
      ]) {
        List<String> plan(bool sameLanguage) => planner
            .create(
              count: ExerciseCreationPlanner.maximumExerciseCount,
              criterion: criterion,
              categories: ExerciseCategory.values,
              randomSeed: 275,
              sameLanguage: sameLanguage,
            )
            .presetIds;
        expect(
          plan(true).where(ExercisePresetRegistry.notInSameLanguage.contains),
          isEmpty,
          reason: criterion.name,
        );
      }
      // A translation Course still draws them.
      expect(
        planner
            .create(
              count: ExerciseCreationPlanner.maximumExerciseCount,
              criterion: ExerciseWizardCriterion.byCategory,
              categories: ExerciseCategory.values,
            )
            .presetIds,
        contains('choice_source'),
      );
    });
  });

  group('the Course\'s names', () {
    late Course laboratory;
    late Course same;
    late Course other;

    setUpAll(() async {
      laboratory = await CourseService().loadCourse('IT');
      same = _english(laboratory, sameLanguage: true);
      other = _english(laboratory, sameLanguage: false);
    });

    test('the Round editor\'s rows, Search and the Audit', () {
      final pick = _example(same, 'translation_choice_to_target');
      expect(
        ExerciseLabels.typeLabel(pick, sameLanguage: true),
        'Pick the word',
      );
      expect(
        ExerciseLabels.typeLabel(pick),
        'Pick the translation (to target)',
      );
      // An exercise that records no preset is named by its learner kind.
      final noPreset = pick.withAuthoringMetadata(const {});
      expect(
        ExerciseLabels.typeLabel(noPreset, sameLanguage: true),
        'Pick the word or the meaning',
      );
      expect(ExerciseLabels.typeLabel(noPreset), 'Pick the translation');
      final query = pick.id;
      String nameFound(Course course) => ExerciseSearchService()
          .search(course, query: query)
          .first
          .exerciseDisplayName;
      expect(nameFound(same), 'Pick the word');
      expect(nameFound(other), 'Pick the translation (to target)');
      // An exercise its preset no longer describes: the Audit names the
      // preset as the Course does.
      final mismatched = _example(same, 'type_translation_to_target')
          .withAuthoringMetadata(const {
            'presetId': 'translation_choice_to_target',
          });
      String message(bool sameLanguage) => CourseAuditService()
          .auditExercise(mismatched, sameLanguage: sameLanguage)
          .firstWhere((issue) => issue.code == 'PRESET_CANONICAL_MISMATCH')
          .message;
      expect(message(true), startsWith('Pick the word configures'));
      expect(
        message(false),
        startsWith('Pick the translation (to target) configures'),
      );
    });

    test('the Audit\'s messages and the publish gate speak of words and '
        'meanings', () {
      List<String> messages(Exercise exercise, {required bool sameLanguage}) =>
          [
            for (final issue in const PublishGate().exerciseIssues(
              exercise,
              sameLanguage: sameLanguage,
            ))
              issue.message,
          ];
      // A blank Type or Build the translation plays as a fill-in or as word
      // blocks: the Laboratory's own examples, without their answers, play
      // as the translation kinds.
      Exercise withoutAnswers(String presetId) {
        final exercise = _example(same, presetId);
        return exercise.copyWith(
          canonicalEvaluation: CanonicalEvaluation(
            mode: exercise.canonicalEvaluation.mode,
          ),
        );
      }

      for (final (id, exercise, name) in [
        (
          'translation_choice_to_target',
          PresetRecipes.blankFor('translation_choice_to_target', 'authors_a'),
          'Pick the word',
        ),
        (
          'type_translation_to_source',
          withoutAnswers('type_translation_to_source'),
          'Type the meaning',
        ),
        (
          'build_translation_to_target',
          withoutAnswers('build_translation_to_target'),
          'Build the sentence',
        ),
      ]) {
        final same = messages(exercise, sameLanguage: true);
        expect(
          same.where((message) => message.startsWith(name)),
          isNotEmpty,
          reason: '$id: $same',
        );
        for (final message in same) {
          expect(message, isNot(contains('translat')), reason: '$id: $message');
        }
        expect(
          messages(
            exercise,
            sameLanguage: false,
          ).where((message) => message.contains('translat')),
          isNotEmpty,
          reason: id,
        );
      }
      // A Pick the translation that plays as Type is "This exercise".
      final pickPlayingAsType = withoutAnswers('type_translation_to_source')
          .withAuthoringMetadata(const {
            'presetId': 'translation_choice_to_target',
          });
      expect(
        messages(pickPlayingAsType, sameLanguage: true),
        contains('This exercise needs at least one accepted answer.'),
      );
      // The learner kind is named in words and meanings.
      final pickAsChoose = _example(
        same,
        'translation_choice_to_target',
      ).withAuthoringMetadata(const {'presetId': 'choice_target'});
      String kindMessage(bool sameLanguage) => CourseAuditService()
          .auditExercise(pickAsChoose, sameLanguage: sameLanguage)
          .firstWhere((issue) => issue.code == 'PRESET_CANONICAL_MISMATCH')
          .message;
      expect(
        kindMessage(true),
        'This exercise no longer matches Choose the answer: it plays as '
        'Pick the word or the meaning.',
      );
      expect(kindMessage(false), contains('it plays as Pick the translation.'));
      // The hint that ends PRESET_CANONICAL_MISMATCH names the preset as
      // the Course does.
      final mismatched = _example(
        same,
        'translation_choice_to_target',
      ).withAuthoringMetadata(const {'presetId': 'listening_choose_target'});
      String hint(bool sameLanguage) => CourseAuditService()
          .auditExercise(mismatched, sameLanguage: sameLanguage)
          .firstWhere((issue) => issue.code == 'PRESET_CANONICAL_MISMATCH')
          .message;
      expect(hint(true), endsWith(' Listen and choose needs its spoken text.'));
      expect(
        hint(false),
        endsWith(
          ' ${ExercisePresetRegistry.byId('listening_choose_target')!.name} '
          'needs its spoken text.',
        ),
      );
    });
  });

  group('the exercise form', () {
    Future<void> pumpForm(
      WidgetTester tester, {
      required bool same,
      required String preset,
    }) async {
      _tall(tester);
      final laboratory = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      final course = _english(laboratory, sameLanguage: same);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: PresetRecipes.blankFor(preset, 'authors_new'),
            title: 'New Exercise',
            isNew: true,
            course: course,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    String headerOf(WidgetTester tester) => tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('exercise-preset-selector')),
                matching: find.byType(Text),
              )
              .first,
        )
        .data!;

    testWidgets('the header and the preset list name and offer what the '
        'Course\'s kind gives', (tester) async {
      await pumpForm(
        tester,
        same: true,
        preset: 'translation_choice_to_target',
      );
      expect(headerOf(tester), 'Pick the word');
      await tester.tap(find.byKey(const Key('exercise-preset-selector')));
      await tester.pumpAndSettle();
      expect(find.text('To the word'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('exercise-preset-search')),
        'Choose the answer',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-preset-choice_target')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-preset-choice_source')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const Key('exercise-preset-search')),
        'Pick the meaning',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('exercise-preset-translation_choice_to_source'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a translation Course: the earlier names and every preset', (
      tester,
    ) async {
      await pumpForm(
        tester,
        same: false,
        preset: 'translation_choice_to_target',
      );
      expect(headerOf(tester), 'Pick the translation (to target)');
      await tester.tap(find.byKey(const Key('exercise-preset-selector')));
      await tester.pumpAndSettle();
      expect(find.text('To target'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('exercise-preset-search')),
        'Choose the answer',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-preset-choice_source')),
        findsOneWidget,
      );
    });

    testWidgets('an exercise made with a twin still opens', (tester) async {
      _tall(tester);
      final laboratory = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      final course = _english(laboratory, sameLanguage: true);
      final twin = _example(course, 'choice_source');
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: twin,
            title: 'Exercise',
            isNew: false,
            course: course,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Exercise type'), findsOneWidget);
      expect(find.text('Choose the answer (to source)'), findsOneWidget);
    });

    test('the field Help of the renamed presets speaks of words and '
        'meanings', () {
      const renamed = [
        'translation_choice_to_target',
        'translation_choice_to_source',
        'type_translation_to_target',
        'type_translation_to_source',
        'build_translation_to_target',
        'build_translation_to_source',
        'word_match',
        'reading_answer_target',
        'listening_answer_target',
        'listening_answer_source',
      ];
      for (final preset in renamed) {
        for (final field in ExerciseFieldHelpRegistry.editorFieldKeys(preset)) {
          final text = ExerciseFieldHelpRegistry.forEditorField(
            preset,
            field,
            sameLanguage: true,
          ).text.toLowerCase();
          for (final word in [
            'translat',
            'source-language',
            'target-language',
            'source language',
            'target language',
          ]) {
            expect(text, isNot(contains(word)), reason: '$preset $field');
          }
        }
      }
      // The titles are the forms' labels.
      for (final (preset, field, title) in [
        ('type_translation_to_target', 'accepted', 'Accepted answers'),
        ('build_translation_to_source', 'tokens', 'Available blocks'),
        ('build_translation_to_target', 'correctTranslation', 'Correct answer'),
        ('word_match', 'pairs', 'Meaning and word pairs'),
        ('reading_answer_target', 'prompt', 'Text to read'),
        ('listening_answer_target', 'question', 'Question'),
      ]) {
        expect(
          ExerciseFieldHelpRegistry.forEditorField(
            preset,
            field,
            sameLanguage: true,
          ).title,
          title,
          reason: '$preset $field',
        );
      }
      // A translation Course and every other preset are as before, but for
      // the Instruction or context, which no longer speaks of translations.
      final instruction = ExerciseFieldHelpRegistry.forField(
        ExerciseAuthoringField.instruction,
      ).text;
      for (final preset in ExercisePresetRegistry.presets) {
        for (final field in ExerciseFieldHelpRegistry.editorFieldKeys(
          preset.id,
        )) {
          final before = ExerciseFieldHelpRegistry.forEditorField(
            preset.id,
            field,
          ).text;
          if (before == instruction) {
            expect(
              ExerciseFieldHelpRegistry.forEditorField(
                preset.id,
                field,
                sameLanguage: true,
              ).text.toLowerCase(),
              isNot(contains('translat')),
              reason: '${preset.id} $field',
            );
          } else if (!renamed.contains(preset.id)) {
            expect(
              ExerciseFieldHelpRegistry.forEditorField(
                preset.id,
                field,
                sameLanguage: true,
              ).text,
              before,
              reason: '${preset.id} $field',
            );
          }
        }
      }
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'type_translation_to_target',
          'accepted',
        ).title,
        'Accepted translations',
      );
    });

    testWidgets('a field\'s Help button, Read and answer and Exercise Help '
        'follow the kind', (tester) async {
      await pumpForm(
        tester,
        same: true,
        preset: 'translation_choice_to_target',
      );
      final help = find.byKey(const ValueKey('exercise-field-help-question'));
      expect(
        tester.widget<IconButton>(help.first).tooltip,
        ExerciseFieldHelpRegistry.forEditorField(
          'translation_choice_to_target',
          'question',
          sameLanguage: true,
        ).purpose,
      );
      await tester.tap(help.first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The meaning the learner reads'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      final exerciseHelp = find.text('Exercise Help');
      await tester.ensureVisible(exerciseHelp);
      await tester.pumpAndSettle();
      await tester.tap(exerciseHelp);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('exercise-help-search')),
            )
            .controller!
            .text,
        'Pick the word',
      );
      await pumpForm(tester, same: true, preset: 'reading_answer_target');
      expect(find.text('Text to read'), findsOneWidget);
      expect(find.text('Text to read (source language)'), findsNothing);
      expect(
        find.text(
          'One line per turn as Speaker: text, in the target language.',
        ),
        findsNothing,
      );
      await pumpForm(tester, same: false, preset: 'reading_answer_target');
      expect(find.text('Text to read (source language)'), findsOneWidget);
    });

    testWidgets('the forms speak of answers and meanings', (tester) async {
      for (final (preset, sameText, otherText) in [
        (
          'type_translation_to_source',
          'Accepted answers',
          'Accepted translations',
        ),
        (
          'build_translation_to_target',
          'Available blocks',
          'Available target-language blocks',
        ),
        (
          'build_translation_to_target',
          'Correct answers',
          'Correct translations',
        ),
        ('word_match', 'Meaning and word pairs', 'Translation pairs'),
      ]) {
        await pumpForm(tester, same: true, preset: preset);
        expect(find.text(sameText), findsOneWidget, reason: preset);
        expect(find.text(otherText), findsNothing, reason: preset);
        await pumpForm(tester, same: false, preset: preset);
        expect(find.text(otherText), findsOneWidget, reason: preset);
      }
    });
  });

  group('the Story steps', () {
    testWidgets('the Story sheet leaves out the twins and names the presets', (
      tester,
    ) async {
      _tall(tester);
      final laboratory = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      for (final sameLanguage in [true, false]) {
        final course = _english(laboratory, sameLanguage: sameLanguage);
        final (lesson, round, index) = [
          for (final lesson in course.lessons)
            for (final (index, round) in lesson.rounds.indexed)
              if (round.isStory) (lesson, round, index),
        ].first;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            home: RoundEditorScreen(
              course: course,
              lesson: lesson,
              round: round,
              roundIndex: index,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('round-add-step')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('story-step-exercise')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('story-wizard-preset-choice_source')),
          sameLanguage ? findsNothing : findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('story-wizard-preset-choice_target')),
            matching: find.text(
              sameLanguage
                  ? 'Choose the answer'
                  : 'Choose the answer (to target)',
            ),
          ),
          findsOneWidget,
        );
      }
    });
  });

  group('the GuideBook', () {
    final module = GuidebookModule(
      id: 'authors_module',
      title: 'Café',
      sentences: const [
        GuidebookEntry(
          id: 'authors_sentence',
          target: 'Are you tired?',
          source: 'Do you need to rest?',
        ),
      ],
      words: const [
        GuidebookEntry(
          id: 'authors_word',
          target: 'espresso',
          source: 'a small, strong coffee',
        ),
      ],
      overview: '',
    );

    Future<void> pumpModule(
      WidgetTester tester, {
      required bool same,
      GuidebookModule? shown,
    }) async {
      _tall(tester);
      final course = _operations.newWizardCourse(
        creator: _profile,
        title: 'Authors',
        sourceLanguage: same ? 'English' : 'English',
        targetLanguage: same ? 'English' : 'Italian',
        sourceLanguageTag: 'en',
        targetLanguageTag: same ? 'en' : 'it',
        sameLanguage: same,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookModuleEditorScreen(
            module: shown ?? module,
            course: course,
            ids: TimestampAuthoringIdGenerator(seed: 2754),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the rows say word, sentence and meaning', (tester) async {
      await pumpModule(tester, same: true);
      expect(find.text('Word: English'), findsOneWidget);
      expect(find.text('Sentence: English'), findsOneWidget);
      expect(find.text('Meaning: English'), findsNWidgets(2));
      expect(find.text('Target: English'), findsNothing);
      // The field Help of a meaning.
      await tester.tap(
        find.byKey(const ValueKey('guidebook-module-word-0-source-help')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meaning'), findsOneWidget);
      expect(
        find.textContaining('Its meaning, in the same language'),
        findsOneWidget,
      );
    });

    testWidgets('a half row is named by its side; the braces line and the '
        'title example', (tester) async {
      await pumpModule(
        tester,
        same: true,
        shown: GuidebookModule(
          id: 'authors_half',
          title: 'Café',
          sentences: const [
            GuidebookEntry(
              id: 'authors_half_sentence',
              target: 'Are you tired?',
              source: '',
            ),
          ],
          words: const [
            GuidebookEntry(
              id: 'authors_half_word',
              target: '',
              source: 'a small, strong coffee',
            ),
          ],
          overview: '',
        ),
      );
      expect(
        find.text('The module\'s own name, for example "At the café".'),
        findsOneWidget,
      );
      expect(
        find.textContaining('I would like {just} an espresso.'),
        findsNWidgets(2),
      );
      expect(find.textContaining('{io}'), findsNothing);
      final done = find.byKey(const Key('guidebook-module-done'));
      await tester.ensureVisible(done);
      await tester.pumpAndSettle();
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Write the Meaning, or clear the row.'),
        findsWidgets,
      );
      expect(
        find.textContaining('Write the Word, or clear the row.'),
        findsWidgets,
      );
      expect(find.textContaining('Write the Target'), findsNothing);
      expect(find.textContaining('Write the Source'), findsNothing);
    });

    test('Paste list names the sides as the module page does', () {
      List<String> reasons(
        String text, {
        bool same = true,
        bool sentences = false,
      }) => [
        for (final line in GuidebookPasteList.read(
          text,
          sameLanguage: same,
          sentences: sentences,
        ).unread)
          line.reason,
      ];
      expect(reasons('no separator'), ['write it as word = meaning']);
      expect(reasons('{} = empty').single, startsWith('Word: '));
      expect(reasons('no separator', sentences: true), [
        'write it as sentence = meaning',
      ]);
      expect(
        reasons('{} = empty', sentences: true).single,
        startsWith('Sentence: '),
      );
      expect(reasons('no separator', same: false), [
        'write it as target = source',
      ]);
      expect(reasons('{} = empty', same: false).single, startsWith('Target: '));
    });

    test(
      'the Help of the module title and of the picture in three languages',
      () {
        for (final locale in [
          AppLocale.english,
          AppLocale.italian,
          AppLocale.spanish,
        ]) {
          for (final field in ['title', 'picture']) {
            for (final part in ['title', 'body']) {
              final key = 'guidebookHelp.field.$field.sameLanguage.$part';
              final text = helpText.lookup(locale, key);
              expect(text, isNot(key), reason: '$locale $key');
              expect(text.trim(), isNotEmpty, reason: '$locale $key');
            }
          }
          final picture = helpText.lookup(
            locale,
            'guidebookHelp.field.picture.sameLanguage.body',
          );
          expect(picture, isNot(contains('Target')), reason: '$locale');
          expect(picture, isNot(contains('gatti')), reason: '$locale');
          expect(
            helpText.lookup(
              locale,
              'guidebookHelp.field.title.sameLanguage.body',
            ),
            contains('At the café'),
            reason: '$locale',
          );
        }
      },
    );

    testWidgets('a translation Course keeps Target and Source', (tester) async {
      await pumpModule(tester, same: false);
      expect(find.text('Target: Italian'), findsNWidgets(2));
      expect(find.text('Source: English'), findsNWidgets(2));
      expect(find.text('Meaning: English'), findsNothing);
      expect(find.text('Word: Italian'), findsNothing);
    });

    testWidgets('Fill with an example and the paste list in English', (
      tester,
    ) async {
      await pumpModule(
        tester,
        same: true,
        shown: GuidebookModule(
          id: 'authors_empty',
          title: '',
          sentences: [],
          words: [],
          overview: '',
        ),
      );
      await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(
        const Key('guidebook-module-fill-example-confirm'),
      );
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('guidebook-module-title')))
            .controller!
            .text,
        'At the café',
      );
      final paste = find.byKey(const Key('guidebook-module-paste-words'));
      await tester.ensureVisible(paste);
      await tester.pumpAndSettle();
      await tester.tap(paste);
      await tester.pumpAndSettle();
      expect(find.textContaining('word = meaning [context]'), findsOneWidget);
    });

    test('New Course\'s sample exercise names a meaning and a word', () {
      List<String> texts(bool sameLanguage) {
        final exercise = NewCourseStructure.sampleExercise(
          TimestampAuthoringIdGenerator(seed: 2757),
          sourceLanguage: 'English',
          learningLanguage: 'English',
          updatedAt: DateTime.utc(2026, 10, 17),
          sameLanguage: sameLanguage,
        ).exercise!;
        return [
          for (final element in exercise.promptElements) element.text,
          for (final item in exercise.items) item.text,
        ];
      }

      expect(texts(true), [
        'Meaning in English',
        'Word in English',
        'Wrong Answer',
      ]);
      expect(texts(false), [
        'Text in English',
        'Translation in English',
        'Wrong Answer',
      ]);
      final lessons = NewCourseStructure.create(
        lessonCount: 1,
        roundsPerLesson: 1,
        sourceLanguage: 'English',
        learningLanguage: 'English',
        updatedAt: DateTime.utc(2026, 10, 17),
        sameLanguage: true,
      );
      expect(
        lessons.single.rounds.single.exercises.single.items.first.text,
        'Word in English',
      );
    });

    test('the samples are well formed', () {
      final read = GuidebookPasteList.read(
        GuidebookPasteList.sameLanguageExampleLines.join('\n'),
      );
      expect(read.unread, isEmpty);
      expect(read.entries, hasLength(4));
      final modules = CourseWizardSample.guidebook(
        TimestampAuthoringIdGenerator(seed: 2755),
        sameLanguage: true,
      );
      expect(modules.single.title, 'At the café');
      expect(modules.single.words.first.target, 'espresso');
      // English never leaves out its subject: the optional word is another.
      expect(
        modules.single.sentences.first.target,
        'I would like {just} an espresso, please.',
      );
      final bills = modules.single.words
          .where((entry) => entry.target == 'the bill')
          .toList();
      expect(
        [for (final bill in bills) bill.picture?.asset],
        [
          'assets/exercise_images/bill.webp',
          'assets/exercise_images/beak.webp',
        ],
      );
      expect(
        CourseWizardSample.guidebook(
          TimestampAuthoringIdGenerator(seed: 2756),
        ).single.title,
        'Al bar',
      );
    });
  });

  group('Exercise Help', () {
    testWidgets('names a preset as a same-language Course does, and says a '
        'twin is not offered there', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExerciseHelpScreen(initialQuery: 'Pick the word'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('exercise-help-result-translation_choice_to_target'),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'In a Course in the same language it is called Pick the word.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-help-search')),
        'there Choose the answer does the same',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-help-result-choice_source')),
        findsOneWidget,
      );
    });
  });

  group("New Course's question", () {
    testWidgets('Continue to Editor asks before the kind and languages become '
        'fixed', (tester) async {
      _tall(tester);
      NewCourseDialog.confirmsLanguages = true;
      addTearDown(() => NewCourseDialog.confirmsLanguages = false);
      Course? created;
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  created = await showNewCourseDialog(
                    context,
                    creator: _profile,
                    maintainers: const [_profile],
                    operations: _operations,
                    titleTaken: (_) => false,
                    prefill: CourseWizardSample.sameLanguageBasics,
                  );
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text(NewCourseDialog.languagesFixedMessage), findsOneWidget);
      // Cancel keeps the form.
      await tester.tap(
        find.byKey(const Key('new-course-languages-fixed-cancel')),
      );
      await tester.pumpAndSettle();
      expect(closed, isFalse);
      expect(create, findsOneWidget);
      await tester.tap(create);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('new-course-languages-fixed-confirm')),
      );
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(created?.sameLanguage, isTrue);
    });
  });
}

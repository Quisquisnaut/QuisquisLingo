import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 7 follow-up (owner review, 29 September 2026): the
/// Assign presets Sort into groups and Fill the slots (recipes over
/// canonical data, forms, Help, Search, Audit), the Match picture to word
/// form whose cards follow the words as they are typed, the Flashcard form
/// with named languages and a Read aloud choice instead of a pronunciation
/// field, and the spelling presets' single field.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 29, 9);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

ExerciseDraftBuildResult _build(
  String type, {
  Exercise? original,
  PublicationState state = PublicationState.published,
  String question = '',
  String groups = '',
  String slots = '',
  String extraWords = '',
  bool slotReuse = false,
  String prompt = '',
  String order = '',
  String tokens = '',
  String tts = '',
  String cardReadAloud = 'manual',
  String imageAsset = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: original ?? _blank('x'),
    type: type,
    publicationState: state,
    question: question,
    groups: groups,
    slots: slots,
    extraWords: extraWords,
    slotReuse: slotReuse,
    prompt: prompt,
    order: order,
    tokens: tokens,
    tts: tts,
    cardReadAloud: cardReadAloud,
    imageAsset: imageAsset,
  ),
);

Exercise _built(
  String type, {
  Exercise? original,
  PublicationState state = PublicationState.published,
  String question = '',
  String groups = '',
  String slots = '',
  String extraWords = '',
  bool slotReuse = false,
  String prompt = '',
  String order = '',
  String tokens = '',
  String tts = '',
  String cardReadAloud = 'manual',
  String imageAsset = '',
}) {
  final result = _build(
    type,
    original: original,
    state: state,
    question: question,
    groups: groups,
    slots: slots,
    extraWords: extraWords,
    slotReuse: slotReuse,
    prompt: prompt,
    order: order,
    tokens: tokens,
    tts: tts,
    cardReadAloud: cardReadAloud,
    imageAsset: imageAsset,
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
}

List<String> _wordsOf(Exercise e, Iterable<String> ids) => [
  for (final id in ids) e.items.singleWhere((item) => item.id == id).value,
];

Exercise _formExercise(String preset) => Exercise(
  id: 'form-$preset',
  type: PresetVariants.formBase(preset),
  editorTemplate: preset,
  publicationState: PublicationState.draft,
  updatedAt: _stamp,
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

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<Exercise? Function()> _mountForm(
  WidgetTester tester,
  Exercise exercise,
) async {
  Exercise? saved;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        exercise: exercise,
        title: 'Follow-up form',
        isNew: true,
        onExerciseSaved: (value) => saved = value,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => saved;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Follow-up author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
  });

  group('Sort into groups and Fill the slots', () {
    test('Sort into groups builds an Assign with groups of any size', () {
      // Every word belongs to a group (fourth follow-up of 29 September
      // 2026: the words that belong nowhere were removed).
      final e = _built(
        'sort_into_groups',
        question: 'Sort the words: animals or plants?',
        groups: 'Animals: gatto, cane\nPlants: rosa, pino',
      );
      final f = ExerciseFeatures(e);
      expect(e.primitive, ExercisePrimitive.assign);
      expect(e.editorTemplate, 'sort_into_groups');
      expect(f.kind, LearnerExerciseKind.assignGroups);
      expect(f.assignTargetMode, AssignTargetMode.categories);
      expect(f.targetCapacity, TargetCapacity.unlimited);
      expect(f.assignItemReuse, isFalse);
      expect(f.questionText, 'Sort the words: animals or plants?');
      expect(e.items.map((item) => item.value), [
        'gatto',
        'cane',
        'rosa',
        'pino',
      ]);
      expect(e.targets, hasLength(2));
      expect(e.targets.map((t) => f.targetLabel(t.id)), ['Animals', 'Plants']);
      final byTarget = f.assignmentsByTarget;
      expect(_wordsOf(e, byTarget[e.targets[0].id]!), ['gatto', 'cane']);
      expect(_wordsOf(e, byTarget[e.targets[1].id]!), ['rosa', 'pino']);
      expect(e.isExecutable, isTrue);
      expect(
        CourseAuditService()
            .auditExercise(e)
            .where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
      );
      // The form reads its fields back and the recipe represents the result.
      final draft = PresetRecipes.decompose(e, 'sort_into_groups');
      expect(draft.question, 'Sort the words: animals or plants?');
      expect(draft.groups, 'Animals: gatto, cane\nPlants: rosa, pino');
      expect(PresetRecipes.represents(e, 'sort_into_groups'), isTrue);
      final stripped = e.withAuthoringMetadata(const {});
      expect(PresetRecipes.recognize(stripped), 'sort_into_groups');
      expect(PresetRecipes.presetToEdit(stripped), 'sort_into_groups');
      expect(PresetRecipes.represents(e, 'fill_the_slots'), isFalse);
    });

    test('Fill the slots: one word per slot unless reuse is allowed', () {
      final refused = _build(
        'fill_the_slots',
        question: 'Which article goes with each noun?',
        slots: '… cane = il\n… libro = il\n… casa = la',
      );
      expect(refused.error?.code, ExerciseDraftErrorCode.slotWordRepeated);
      expect(refused.error?.line, 2);
      expect(refused.error?.detail, 'il');
      final e = _built(
        'fill_the_slots',
        question: 'Which article goes with each noun?',
        slots: '… cane = il\n… libro = il\n… casa = la',
        extraWords: 'lo',
        slotReuse: true,
      );
      final f = ExerciseFeatures(e);
      expect(f.kind, LearnerExerciseKind.assignSlots);
      expect(f.assignTargetMode, AssignTargetMode.slots);
      expect(f.targetCapacity, TargetCapacity.single);
      expect(f.assignItemReuse, isTrue);
      expect(e.items.map((item) => item.value), ['il', 'la', 'lo']);
      expect(e.targets, hasLength(3));
      expect(e.targets.map((t) => f.targetLabel(t.id)), [
        '… cane',
        '… libro',
        '… casa',
      ]);
      final byTarget = f.assignmentsByTarget;
      expect(_wordsOf(e, byTarget[e.targets[0].id]!), ['il']);
      expect(_wordsOf(e, byTarget[e.targets[1].id]!), ['il']);
      expect(_wordsOf(e, byTarget[e.targets[2].id]!), ['la']);
      expect(e.isExecutable, isTrue);
      final draft = PresetRecipes.decompose(e, 'fill_the_slots');
      expect(draft.slots, '… cane = il\n… libro = il\n… casa = la');
      expect(draft.extraWords, 'lo');
      expect(draft.slotReuse, isTrue);
      expect(PresetRecipes.represents(e, 'fill_the_slots'), isTrue);
      expect(
        PresetRecipes.recognize(e.withAuthoringMetadata(const {})),
        'fill_the_slots',
      );
    });

    test('malformed lines are refused; empty answers only on publish', () {
      ExerciseDraftFieldError? error(ExerciseDraftBuildResult result) =>
          result.error;
      final noColon = error(
        _build('sort_into_groups', groups: 'Animals gatto'),
      );
      expect(noColon?.code, ExerciseDraftErrorCode.groupLine);
      expect(noColon?.line, 1);
      final twice = error(
        _build('sort_into_groups', groups: 'Animals: gatto\nPlants: gatto'),
      );
      expect(twice?.code, ExerciseDraftErrorCode.groupWordRepeated);
      expect(twice?.line, 2);
      expect(twice?.detail, 'gatto');
      expect(
        error(_build('sort_into_groups'))?.code,
        ExerciseDraftErrorCode.groupsRequired,
      );
      expect(
        error(_build('sort_into_groups', state: PublicationState.draft)),
        isNull,
      );
      // One group asks nothing: at least two (no words that belong nowhere).
      expect(
        error(_build('sort_into_groups', groups: 'Animals: gatto, cane'))?.code,
        ExerciseDraftErrorCode.groupsRequired,
      );
      expect(
        error(
          _build(
            'sort_into_groups',
            groups: 'Animals: gatto, cane\nPlants: rosa',
          ),
        ),
        isNull,
      );
      expect(
        error(_build('fill_the_slots', slots: '… gatto il'))?.code,
        ExerciseDraftErrorCode.slotLine,
      );
      expect(
        error(_build('fill_the_slots'))?.code,
        ExerciseDraftErrorCode.slotsRequired,
      );
      expect(
        error(_build('fill_the_slots', state: PublicationState.draft)),
        isNull,
      );
      expect(
        error(
          _build('fill_the_slots', slots: '… gatto = il', extraWords: 'il'),
        )?.code,
        ExerciseDraftErrorCode.slotWordRepeated,
      );
      // A blank exercise of either preset is what the picker creates.
      final blank = _built(
        'sort_into_groups',
        original: _blank('new'),
        state: PublicationState.draft,
      );
      expect(blank.primitive, ExercisePrimitive.assign);
      expect(blank.items, isEmpty);
      expect(PresetRecipes.presetToEdit(blank), 'sort_into_groups');
    });

    test('an edit keeps the IDs of the words and targets it keeps', () {
      final first = _built(
        'sort_into_groups',
        groups: 'Animals: gatto, cane\nPlants: rosa',
      );
      final edited = _built(
        'sort_into_groups',
        original: first,
        groups: 'Animals: cane, gatto\nPlants: rosa, pino',
      );
      String idOf(Exercise e, String word) =>
          e.items.singleWhere((item) => item.value == word).id;
      for (final word in ['gatto', 'cane', 'rosa']) {
        expect(idOf(edited, word), idOf(first, word), reason: word);
      }
      expect(idOf(edited, 'pino'), isNot(isIn(first.items.map((i) => i.id))));
      expect(edited.targets.map((t) => t.id), first.targets.map((t) => t.id));
      expect(edited.id, first.id);
      // Unchanged fields rebuild the same exercise.
      final same = _built(
        'sort_into_groups',
        original: first,
        groups: 'Animals: gatto, cane\nPlants: rosa',
      );
      expect(same.semanticallyEquals(first), isTrue);
    });

    test(
      "the Laboratory's Assign examples are recognized with their own IDs",
      () {
        final course = Course.fromJson(
          jsonDecode(
                File(
                  'assets/courses/exercise_laboratory_en_it.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>,
        );
        final assign = course.lessons.singleWhere(
          (lesson) => lesson.title == 'Assign',
        );
        final examples = [
          for (final round in assign.rounds)
            for (final content in round.content)
              if (content.exercise != null) content,
        ];
        expect(examples, hasLength(4));
        expect(assign.rounds, hasLength(1));
        for (final content in examples) {
          final exercise = content.exercise!;
          expect(
            content.editorTemplate,
            isIn(['sort_into_groups', 'fill_the_slots']),
            reason: content.id,
          );
          // Generator IDs (`qql_lab254_…`), not the recipe's: recognition
          // compares targets by position, as it does items.
          expect(exercise.targets.first.id, startsWith('qql_lab254_'));
          expect(
            PresetRecipes.recognize(exercise.withAuthoringMetadata(const {})),
            content.editorTemplate,
            reason: content.id,
          );
        }
      },
    );

    test('the catalogue, kinds, forms, Help, Search and Audit know them', () {
      final sort = ExercisePresetRegistry.byId('sort_into_groups')!;
      final fill = ExercisePresetRegistry.byId('fill_the_slots')!;
      for (final preset in [sort, fill]) {
        expect(preset.category, ExerciseCategory.grammarAndSentences);
        expect(preset.primitive, ExercisePrimitive.assign);
        expect(preset.action, 'Sort');
        expect(preset.direction, PresetDirection.none);
        expect(preset.base, preset.id);
        expect(PresetRecipes.canonicalOnly, contains(preset.id));
        expect(PresetVariants.formFor(preset.id), preset.id);
        expect(ExercisePresetRegistry.helpByPreset[preset.id], isNotEmpty);
        expect(
          ExerciseSearchRegistry.definitions.map((d) => d.presetId),
          contains(preset.id),
        );
      }
      expect(
        ExercisePresetRegistry.comingLater.map((preset) => preset.id),
        isNot(contains('sort_into_groups')),
      );
      expect(PresetRecipes.kinds['sort_into_groups'], {
        LearnerExerciseKind.assignGroups,
      });
      expect(PresetRecipes.kinds['fill_the_slots'], {
        LearnerExerciseKind.assignSlots,
      });
      expect(PresetRecipes.defaultPresetFor(ExercisePrimitive.assign), isNull);
      expect(ExerciseFieldHelpRegistry.editorFieldKeys('sort_into_groups'), [
        'question',
        'groups',
        'image',
      ]);
      expect(ExerciseFieldHelpRegistry.editorFieldKeys('fill_the_slots'), [
        'question',
        'slots',
        'extraWords',
        'slotReuse',
        'image',
      ]);
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'fill_the_slots',
          'slotReuse',
        ).title,
        'A word may fill more than one slot',
      );
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'sort_into_groups',
          'groups',
        ).example,
        'Animals: gatto, cane\nPlants: rosa, pino',
      );
      // The Audit names what a mislabelled exercise lacks.
      final slots = _built('fill_the_slots', slots: '… gatto = il');
      final mislabelled = slots.withAuthoringMetadata({
        'presetId': 'sort_into_groups',
      });
      expect(
        CourseAuditService()
            .auditExercise(mislabelled)
            .map((issue) => issue.message)
            .where((m) => m.contains('Sort into groups needs groups')),
        isNotEmpty,
      );
    });

    testWidgets('the Fill the slots form saves an Assign', (tester) async {
      _bigWindow(tester);
      final saved = await _mountForm(
        tester,
        _built(
          'fill_the_slots',
          original: _blank('new-slots'),
          state: PublicationState.draft,
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'Which article goes with each noun?',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-slots')),
        '… cane = il\n… libro = il',
      );
      await tester.pump();
      await _tap(tester, find.byKey(const Key('slot-reuse')));
      await _tap(tester, find.byKey(const Key('exercise-save')));
      final exercise = saved();
      expect(exercise, isNotNull);
      final f = ExerciseFeatures(exercise!);
      expect(f.kind, LearnerExerciseKind.assignSlots);
      expect(f.assignItemReuse, isTrue);
      expect(exercise.items.map((item) => item.value), ['il']);
      expect(exercise.targets, hasLength(2));
      expect(exercise.editorTemplate, 'fill_the_slots');
      expect(exercise.publicationState, PublicationState.published);
    });
  });

  group('Match picture to word form', () {
    testWidgets('the picture cards follow the words as they are typed', (
      tester,
    ) async {
      _bigWindow(tester);
      await _mountForm(tester, _formExercise('picture_word_match'));
      expect(
        find.text('Enter the answers above first; each gets a picture here.'),
        findsOneWidget,
      );
      final words = find.byKey(const ValueKey('exercise-field-answers'));
      await tester.enterText(words, 'gatto\ncane');
      await tester.pump();
      expect(find.text('1. gatto'), findsOneWidget);
      expect(find.text('2. cane'), findsOneWidget);
      // A word typed later gets its card and number at once (the owner saw
      // the last picture without them).
      await tester.enterText(words, 'gatto\ncane\ncasa');
      await tester.pump();
      expect(find.text('3. casa'), findsOneWidget);
      expect(find.byKey(const ValueKey('answer-picture-2')), findsOneWidget);
      // One shared prompt image card; the per-word cards carry the word.
      expect(find.text('Exercise image'), findsOneWidget);
      expect(find.text('Pictures, in the order of the words'), findsOneWidget);
      await tester.enterText(words, 'gatto');
      await tester.pump();
      expect(find.text('2. cane'), findsNothing);
      expect(find.byKey(const ValueKey('answer-picture-1')), findsNothing);
    });
  });

  group('Flashcard read-aloud', () {
    test('the read-aloud speaks the word and is never an audio exercise', () {
      final availability = AudioExerciseAvailabilityService();
      final none = _built(
        'flashcard',
        prompt: 'buongiorno',
        question: 'good morning',
        cardReadAloud: 'none',
        tts: 'ignored',
      );
      expect(ExerciseFeatures(none).audioElements, isEmpty);
      final manual = _built(
        'flashcard',
        prompt: 'buongiorno',
        question: 'good morning',
      );
      final audio = ExerciseFeatures(manual).audioElements.single;
      expect(audio.text, 'buongiorno');
      expect(audio.role, 'audio');
      expect(audio.isRequired, isFalse);
      expect(audio.effectivePlayback, AudioPlayback.manual);
      expect(availability.isAudioExercise(manual), isFalse);
      // Pronunciation TTS (if different): empty while the spoken text is
      // the word itself, kept when it differs.
      expect(PresetRecipes.decompose(manual, 'flashcard').tts, isEmpty);
      final different = _built(
        'flashcard',
        prompt: 'Dott.',
        question: 'Doctor',
        tts: 'dottore',
      );
      expect(ExerciseFeatures(different).audioElements.single.text, 'dottore');
      expect(PresetRecipes.decompose(different, 'flashcard').tts, 'dottore');
      expect(PresetRecipes.represents(different, 'flashcard'), isTrue);
      final automatic = _built(
        'flashcard',
        prompt: 'buongiorno',
        question: 'good morning',
        cardReadAloud: 'automatic',
      );
      expect(ExerciseFeatures(automatic).automaticAudio?.text, 'buongiorno');
      expect(availability.isAudioExercise(automatic), isFalse);
      for (final (exercise, choice) in [
        (none, 'none'),
        (manual, 'manual'),
        (automatic, 'automatic'),
      ]) {
        expect(
          PresetRecipes.decompose(exercise, 'flashcard').cardReadAloud,
          choice,
        );
        expect(PresetRecipes.represents(exercise, 'flashcard'), isTrue);
        expect(
          PresetRecipes.recognize(exercise.withAuthoringMetadata(const {})),
          'flashcard',
        );
      }
      // A blank card starts on request; a card without audio reads none.
      expect(
        PresetRecipes.decompose(_blank('b'), 'flashcard').cardReadAloud,
        'manual',
      );
      final picture = _built(
        'picture_flashcard',
        prompt: 'la mela',
        question: 'apple',
        imageAsset: 'assets/exercise_images/apple.webp',
        cardReadAloud: 'automatic',
      );
      expect(ExerciseFeatures(picture).automaticAudio?.text, 'la mela');
      expect(ExerciseFeatures(picture).illustrationAsset, isNotEmpty);
      expect(availability.isAudioExercise(picture), isFalse);
      expect(
        PresetRecipes.decompose(picture, 'picture_flashcard').cardReadAloud,
        'automatic',
      );
      expect(PresetRecipes.represents(picture, 'picture_flashcard'), isTrue);
    });

    testWidgets('the form names the languages and offers Read aloud', (
      tester,
    ) async {
      _bigWindow(tester);
      final saved = await _mountForm(tester, _formExercise('flashcard'));
      expect(find.text('Word or expression (target language)'), findsOneWidget);
      expect(
        find.text('Translation or meaning (source language)'),
        findsOneWidget,
      );
      expect(find.text('Pronunciation TTS (if different)'), findsOneWidget);
      expect(find.byKey(const ValueKey('exercise-field-tts')), findsOneWidget);
      final choice = find.byKey(const ValueKey('exercise-choice-readAloud'));
      expect(choice, findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-prompt')),
        'buongiorno',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'good morning',
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('exercise-choice-readAloud-manual')),
      );
      await _tap(
        tester,
        find.text('Automatically, when the card appears').last,
      );
      await _tap(tester, find.byKey(const Key('exercise-save-draft')));
      final exercise = saved();
      expect(exercise, isNotNull);
      expect(ExerciseFeatures(exercise!).automaticAudio?.text, 'buongiorno');
      expect(ExerciseFeatures(exercise).textOf('term'), 'buongiorno');
      expect(ExerciseFeatures(exercise).textOf('meaning'), 'good morning');
    });
  });

  group('Choose the answer (owner review)', () {
    testWidgets('a new single-answer Choose starts with answer 1', (
      tester,
    ) async {
      _bigWindow(tester);
      await _mountForm(tester, _formExercise('choice_target'));
      expect(find.text('Prompt (optional)'), findsOneWidget);
      expect(find.text('Question or sentence to complete'), findsOneWidget);
      final correct = find.byKey(const ValueKey('exercise-field-correct'));
      expect(tester.widget<TextField>(correct).controller!.text, '1');
    });

    test('a stored Choose without a correct answer keeps its empty field', () {
      final draft = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _formExercise('choice_target'),
          type: 'choice_target',
          publicationState: PublicationState.draft,
          question: 'Which article goes with casa?',
          answers: 'la\nil',
        ),
      ).candidate!;
      expect(PresetRecipes.decompose(draft, 'choice_target').correct, isEmpty);
    });

    test(
      'the Audit warns when every answer of a multiple Choose is correct',
      () {
        Exercise build(String correct) => ExerciseDraftBuilder.build(
          ExerciseDraftValues(
            original: _formExercise('choice_target'),
            type: 'choice_target',
            publicationState: PublicationState.published,
            useMultiSelect: true,
            question: 'Which words are colours?',
            answers: 'rosso\nblu',
            correct: correct,
          ),
        ).candidate!;
        List<String> codes(Exercise e) => CourseAuditService()
            .auditExercise(e)
            .map((issue) => issue.code)
            .toList();
        expect(codes(build('1, 2')), contains('CHOICE_ALL_ANSWERS_CORRECT'));
        expect(
          codes(build('1')),
          isNot(contains('CHOICE_ALL_ANSWERS_CORRECT')),
        );
        expect(
          AuditCodeRegistry.byCode('CHOICE_ALL_ANSWERS_CORRECT')!.severity,
          AuditSeverity.warning,
        );
      },
    );
  });

  group('Match by meaning (owner review)', () {
    test('a Match never gets the "opposite" instruction guessed for it', () {
      final course = Course.fromJson(
        jsonDecode(
              File(
                'assets/courses/exercise_laboratory_en_it.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final opposites = course.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises)
          .singleWhere((e) => e.id == 'qql_lab254_match_opposites');
      expect(ExerciseFeatures(opposites).primaryText, contains('contrario'));
      expect(
        ExerciseCopyService.instructionForExercise(course, opposites),
        ExerciseCopyService.instruction(course, LearnerExerciseKind.match),
      );
      expect(
        ExerciseCopyService.instructionForExercise(course, opposites),
        isNot(contains('opposite')),
      );
    });
  });

  group('Spelling presets', () {
    test(
      'one field: the blocks of the word are the blocks the learner gets',
      () {
        final image = _built(
          'image_word',
          prompt: 'Build the word shown in the image.',
          order: 'ga\ntto',
          tokens: 'ignored\nblocks',
          imageAsset: 'assets/exercise_images/cat.webp',
        );
        expect(image.tokens, ['ga', 'tto']);
        expect(image.orderAnswer, ['ga', 'tto']);
        expect(ExerciseFeatures(image).kind, LearnerExerciseKind.arrangeWord);
        expect(PresetRecipes.represents(image, 'image_word'), isTrue);
        final heard = _built('spell_heard', tts: 'pane', order: 'p\na\nn\ne');
        expect(heard.tokens, ['p', 'a', 'n', 'e']);
        expect(
          PresetRecipes.recognize(heard.withAuthoringMetadata(const {})),
          'spell_heard',
        );
        final clue = _built(
          'spell_word',
          prompt: 'cat (the animal)',
          order: 'g\na\nt\nt\no',
        );
        expect(clue.tokens, ['g', 'a', 't', 't', 'o']);
        expect(
          PresetRecipes.recognize(clue.withAuthoringMetadata(const {})),
          'spell_word',
        );
        // A stored spelling exercise with an extra block is nothing the
        // one-field form can show: no recipe represents it.
        final extra = heard.copyWith(
          items: [
            ...heard.items,
            const ExerciseItem(
              id: 'extra',
              content: [PromptElement(type: 'text', text: 'z')],
            ),
          ],
        );
        expect(
          PresetRecipes.recognize(extra.withAuthoringMetadata(const {})),
          isNull,
        );
      },
    );

    testWidgets('the spelling forms show one field for the blocks', (
      tester,
    ) async {
      _bigWindow(tester);
      for (final preset in ['image_word', 'spell_word', 'spell_heard']) {
        await _mountForm(tester, _formExercise(preset));
        expect(
          find.text('Blocks of the word, in order'),
          findsOneWidget,
          reason: preset,
        );
        expect(
          find.text('Available letter / syllable blocks'),
          findsNothing,
          reason: preset,
        );
        expect(
          find.byKey(const ValueKey('exercise-field-tokens')),
          findsNothing,
          reason: preset,
        );
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 265 Revision 11 (owner report of 7 October 2026): a spelling
/// exercise needs two blocks or more, as its Help said; one block is no
/// puzzle. A draft may still be saved with fewer. The spelling forms also
/// get optional Extra blocks, distractors, with a note (owner decision).

Exercise _blank(String type) => Exercise(
  id: 'spelling-265',
  publicationState: PublicationState.draft,
  updatedAt: DateTime.utc(2026, 10, 7),
  type: type,
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

ExerciseDraftBuildResult _build(
  String preset,
  String blocks,
  PublicationState state, {
  String extra = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank('image_word'),
    type: preset,
    publicationState: state,
    order: blocks,
    extraWords: extra,
    // Each preset its own source of the word: a picture, a clue or a sound.
    imageAsset: preset == 'image_word'
        ? 'assets/exercise_images/house.webp'
        : '',
    tts: preset == 'spell_heard' ? 'casa' : '',
    prompt: preset == 'spell_word' ? 'house' : '',
  ),
);

void main() {
  for (final preset in ['image_word', 'spell_word', 'spell_heard']) {
    group(preset, () {
      test('one block is refused when published', () {
        final result = _build(preset, 'casa', PublicationState.published);
        expect(result.candidate, isNull);
        expect(result.error?.code, ExerciseDraftErrorCode.blocksTooFew);
        expect(result.error?.field, ExerciseDraftField.order);
      });

      test('two blocks are enough', () {
        final result = _build(preset, 'ca\nsa', PublicationState.published);
        expect(result.error, isNull);
        expect(result.candidate?.items, hasLength(2));
      });

      test('a draft may keep one block', () {
        final result = _build(preset, 'casa', PublicationState.draft);
        expect(result.error, isNull);
        expect(result.candidate, isNotNull);
      });

      test('Extra blocks are distractors the form reads back', () {
        final exercise = _build(
          preset,
          'ca\nsa',
          PublicationState.published,
          extra: 'e',
        ).candidate!;
        expect(exercise.items, hasLength(3));
        // The word is built from the first two blocks only.
        final order = exercise.canonicalEvaluation.correctOrders.single;
        expect(order.itemIds, hasLength(2));
        expect(
          exercise.items
              .where((item) => !order.itemIds.contains(item.id))
              .map((item) => item.value),
          ['e'],
        );
        final draft = PresetRecipes.decompose(exercise, preset);
        expect(draft.order, 'ca\nsa');
        expect(draft.extraWords, 'e');
        expect(PresetRecipes.represents(exercise, preset), isTrue);
        // A recommendation, never an error.
        final issues = CourseAuditService().auditExercise(
          exercise.copyWith(authoringMetadata: {'presetId': preset}),
        );
        final distractors = issues.where(
          (issue) => issue.code == 'WORD_BLOCK_DISTRACTOR_COUNT',
        );
        expect(distractors, isNotEmpty);
        expect(
          distractors.every((issue) => issue.severity == AuditSeverity.info),
          isTrue,
        );
      });
    });
  }

  testWidgets('the form notes that extra blocks are distractors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Spelling author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationSupportDirectory') {
              return testSupportDirectory.path;
            }
            throw PlatformException(code: 'test-storage');
          },
        );
    keepCrashLogUnavailable();
    tester.view.physicalSize = const Size(2400, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final exercise = _build(
      'spell_word',
      'ca\nsa',
      PublicationState.published,
    ).candidate!.copyWith(authoringMetadata: const {'presetId': 'spell_word'});
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: exercise,
          title: 'Spelling',
          isNew: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final extra = find.byKey(const ValueKey('exercise-field-extraWords'));
    expect(extra, findsOneWidget);
    expect(find.byKey(const Key('spelling-extra-blocks-note')), findsNothing);
    await tester.enterText(extra, 'e');
    await tester.pump();
    expect(find.byKey(const Key('spelling-extra-blocks-note')), findsOneWidget);
  });

  test('other word-block exercises are unchanged', () {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _blank('word_order'),
        type: 'word_order',
        publicationState: PublicationState.draft,
        tokens: 'ciao',
        order: 'ciao',
      ),
    );
    expect(result.error?.code, isNot(ExerciseDraftErrorCode.blocksTooFew));
  });
}

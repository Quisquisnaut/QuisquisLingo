import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 7, third follow-up (owner review, 29 September 2026):
/// Type the missing word accepts words with different first letters while
/// Show the first letter is off, and its form says so.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 29, 10);

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
        title: 'Third follow-up form',
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
          displayName: 'Third follow-up author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
  });

  group('Type the missing word', () {
    testWidgets(
      'with Show the first letter off, words may start with different letters',
      (tester) async {
        _bigWindow(tester);
        final saved = await _mountForm(
          tester,
          _formExercise('type_missing_word'),
        );
        const sameLetter =
            'One complete word per line. With the first letter shown, all answers must start with the same letter (Unicode grapheme).';
        const anyLetter =
            'One complete word per line. They may start with different letters.';
        final reveal = find.byKey(const Key('type-missing-word-reveal'));
        bool revealOn() => tester.widget<SwitchListTile>(reveal).value;
        // The helper and the note follow the switch both ways.
        for (var i = 0; i < 2; i++) {
          final on = revealOn();
          expect(find.text(sameLetter), on ? findsOneWidget : findsNothing);
          expect(find.text(anyLetter), on ? findsNothing : findsOneWidget);
          expect(
            find.text(
              'Enter the complete missing word. The learner types it without a hint.',
            ),
            on ? findsNothing : findsOneWidget,
          );
          await _tap(tester, reveal);
        }
        if (revealOn()) await _tap(tester, reveal);
        expect(revealOn(), isFalse);

        await tester.enterText(
          find.byKey(const ValueKey('exercise-field-prompt')),
          'La ___ è grande.',
        );
        await tester.enterText(
          find.byKey(const ValueKey('exercise-field-accepted')),
          'casa\nabitazione',
        );
        await tester.pump();
        await _tap(tester, find.byKey(const Key('exercise-save')));
        final exercise = saved();
        expect(exercise, isNotNull);
        final f = ExerciseFeatures(exercise!);
        expect(f.acceptedAnswers, ['casa', 'abitazione']);
        expect(f.revealTarget, isNull);
        expect(
          CourseAuditService()
              .auditExercise(exercise, location: 'form')
              .where((issue) => issue.severity == AuditSeverity.error),
          isEmpty,
        );
      },
    );
  });
}

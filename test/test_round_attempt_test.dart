import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

class _Speech extends TtsCacheService {
  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async => true;
  @override
  Future<void> stop() async {}
}

Exercise _question(String id, String text) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', role: 'question', text: text)],
  items: [
    ExerciseItem(
      id: '${id}_right',
      content: [PromptElement(type: 'text', text: 'Right $id')],
    ),
    ExerciseItem(
      id: '${id}_wrong',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_right'],
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Tester',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => testSupportDirectory.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
  });

  testWidgets('Test defers correctness and corrections until all answers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final round = LearningRound(
      id: 'test-round',
      title: 'Quiz',
      roundType: RoundType.test,
      testFixedOrder: true,
      testPassingPercent: 60,
      exercises: [_question('q1', 'First?'), _question('q2', 'Second?')],
    );
    final lesson = Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]);
    final course = Course(
      courseId: 'test-course',
      title: 'Course',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      ttsLanguage: 'it-IT',
      lessons: [lesson],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: lesson,
          round: round,
          ttsLanguage: 'it-IT',
          roundIndex: 0,
          previewMode: true,
          ttsCacheService: _Speech(),
        ),
      ),
    );
    for (var i = 0; i < 100 && find.text('First?').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('First?'), findsOneWidget);
    await tester.tap(find.text('Wrong q1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exercise-feedback-surface')), findsNothing);
    expect(find.textContaining('Correct answer:'), findsNothing);
    await tester.tap(find.byKey(const Key('test-next')));
    await tester.pumpAndSettle();
    expect(find.text('Second?'), findsOneWidget);
    await tester.tap(find.text('Right q2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exercise-feedback-surface')), findsNothing);
    await tester.tap(find.byKey(const Key('test-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-results')), findsOneWidget);
    expect(find.text('Below passing threshold · 50%'), findsOneWidget);
    expect(find.textContaining('Right q1'), findsWidgets);
  });
  // Build 270 Revision 7: a second Continue while the last answer's results
  // are being prepared completes nothing twice.
  testWidgets('two quick taps on the last Continue show one result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final round = LearningRound(
      id: 'test-round',
      title: 'Quiz',
      roundType: RoundType.test,
      testFixedOrder: true,
      exercises: [_question('q1', 'First?')],
    );
    final lesson = Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]);
    final course = Course(
      courseId: 'test-course',
      title: 'Course',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      ttsLanguage: 'it-IT',
      lessons: [lesson],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: lesson,
          round: round,
          ttsLanguage: 'it-IT',
          roundIndex: 0,
          previewMode: true,
          ttsCacheService: _Speech(),
        ),
      ),
    );
    for (var i = 0; i < 100 && find.text('First?').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.tap(find.text('Right q1'));
    await tester.pumpAndSettle();
    // Two presses before anything is drawn again.
    final next = tester.widget<FilledButton>(
      find.byKey(const Key('test-next')),
    );
    next.onPressed!();
    next.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-results')), findsOneWidget);
  });
}

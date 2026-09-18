// QQL Build 239: while GuideBook is turned off for a Course, the Lesson
// Guidebook card must not show any colored (green, red) audit border.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';

Course _course({required bool useGuidebook}) {
  final lesson = Lesson(
    lessonId: 'lesson-1',
    title: 'Lesson one',
    rounds: [LearningRound(id: 'round-1', title: 'Round', content: const [])],
  );
  return Course(
    courseId: 'guidebook-off-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Guidebook off',
    ttsLanguage: 'it-IT',
    useGuidebook: useGuidebook,
    lessons: [lesson],
  );
}

void main() {
  Course validCourse({required bool useGuidebook}) {
    final exercise = Exercise(
      id: 'valid-exercise',
      updatedAt: DateTime.utc(2026, 9, 19),
      type: 'translation_choice_to_target',
      prompt: '',
      question: 'I am going to London',
      answers: const ['Vado a Londra.', 'Vengo da Londra.'],
      correct: 0,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    final round = LearningRound(
      id: 'round-valid',
      title: 'Round',
      content: [LearningContent.fromExercise(exercise)],
    );
    final lesson = Lesson(
      lessonId: 'lesson-valid',
      title: 'Lesson',
      rounds: [round],
    );
    return Course(
      courseId: 'valid-course',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Valid',
      ttsLanguage: 'it-IT',
      useGuidebook: useGuidebook,
      lessons: [lesson],
    );
  }

  test(
    'Lesson and Course borders ignore an empty GuideBook while it is off',
    () {
      final off = validCourse(useGuidebook: false);
      final offStatus = AuthoringHierarchyStatus.fromCourse(off);
      expect(offStatus.lessonHasAuditConcern(off.lessons.single), isFalse);
      expect(offStatus.hasLessonsAuditConcern, isFalse);
      expect(offStatus.hasCourseAuditConcern, isFalse);

      // With GuideBook on, the same empty GuideBook is a concern.
      final on = validCourse(useGuidebook: true);
      final onStatus = AuthoringHierarchyStatus.fromCourse(on);
      expect(onStatus.lessonHasAuditConcern(on.lessons.single), isTrue);
    },
  );
  test('the Guidebook border has no status while GuideBook is off', () {
    final off = _course(useGuidebook: false);
    final status = AuthoringHierarchyStatus.fromCourse(off);
    expect(status.lessonGuidebookAuditStatus(off.lessons.single), isNull);
  });

  test('the Guidebook border keeps its status while GuideBook is on', () {
    final on = _course(useGuidebook: true);
    final status = AuthoringHierarchyStatus.fromCourse(on);
    final lesson = on.lessons.single;
    expect(status.lessonGuidebookAuditStatus(lesson), isNotNull);
    expect(
      status.lessonGuidebookAuditStatus(lesson),
      status.lessonGuidebookHasAuditConcern(lesson),
    );
  });

  testWidgets('a status card without a status draws no border', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthoringStatusCard(
            indicatorKey: Key('indicator'),
            draftIndicatorKey: Key('draft'),
            hasDraft: false,
            hasAuditConcern: null,
            neutralAuditMessage: 'No colored border: GuideBook is turned off.',
            child: SizedBox(height: 20),
          ),
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side, BorderSide.none);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, contains('GuideBook is turned off'));
  });

  testWidgets('a status card with a clean audit still draws green', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthoringStatusCard(
            indicatorKey: Key('indicator'),
            draftIndicatorKey: Key('draft'),
            hasDraft: false,
            hasAuditConcern: false,
            child: SizedBox(height: 20),
          ),
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.width, greaterThan(0));
  });
}

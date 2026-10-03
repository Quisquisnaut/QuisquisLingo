import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _stamp = DateTime.utc(2026, 10, 3);

Course _course() => Course(
  courseId: 'round_types',
  title: 'Types',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'one',
      title: 'Lesson',
      updatedAt: _stamp,
      rounds: const [],
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('New Round selects a type before creating content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _course();
    Course? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(
          course: course,
          lesson: course.lessons.first,
          onCourseChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rounds-new-story')), findsNothing);
    await tester.tap(find.byKey(const Key('rounds-new-round')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-round-type-speak')), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('new-round-type-speak')))
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(changed, isNull);
    await tester.tap(find.byKey(const Key('rounds-new-round')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('new-round-type-sequence')),
    );
    await tester.tap(find.byKey(const Key('new-round-type-sequence')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Ordered');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(changed!.lessons.first.rounds.single.roundType, RoundType.sequence);
    expect(changed!.lessons.first.rounds.single.flow?.isLinear, isTrue);
  });

  testWidgets('every non-flow implemented type can be created as a Draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final type in [
      RoundType.discover,
      RoundType.practice,
      RoundType.listening,
      RoundType.reading,
      RoundType.flashcard,
      RoundType.test,
    ]) {
      final course = _course();
      Course? changed;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: LessonRoundsScreen(
            course: course,
            lesson: course.lessons.first,
            onCourseChanged: (value) => changed = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rounds-new-round')));
      await tester.pumpAndSettle();
      final choice = find.byKey(Key('new-round-type-${type.name}'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Example');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final created = changed!.lessons.first.rounds.single;
      expect(created.roundType, type);
      expect(created.publicationState, PublicationState.draft);
      expect(created.flow, isNull);
    }
  });
}

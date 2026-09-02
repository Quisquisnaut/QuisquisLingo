import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';

Lesson _lesson(String id, {bool section = false, String? sectionName}) =>
    Lesson(
      lessonId: id,
      title: 'Lesson $id',
      rounds: const [],
      section: section,
      sectionName: sectionName,
    );

void main() {
  final lessons = [
    _lesson('a1', section: true, sectionName: 'A'),
    _lesson('a2', section: true, sectionName: 'A'),
    _lesson('plain'),
    _lesson('b1', section: true, sectionName: 'B'),
    _lesson('a3', section: true, sectionName: 'A'),
    _lesson('plain2'),
  ];

  test('Section grouping and relative numbering derive from Lesson order', () {
    expect(
      List.generate(
        lessons.length,
        (index) => learnerShowsSectionHeader(lessons, index),
      ),
      [true, false, false, true, true, false],
    );
    expect(
      List.generate(
        lessons.length,
        (index) => learnerSectionLessonNumber(lessons, index),
      ),
      [1, 2, 0, 1, 1, 0],
    );
  });

  testWidgets(
    'Section headers render once per consecutive block and add nothing otherwise',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                for (var index = 0; index < lessons.length; index++) ...[
                  if (learnerShowsSectionHeader(lessons, index))
                    LessonSectionHeader(lesson: lessons[index]),
                  Text(
                    lessons[index].title,
                    key: ValueKey('lesson-body-${lessons[index].lessonId}'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      expect(find.text('A'), findsNWidgets(2));
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(LessonSectionHeader), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('lesson-section-header-a1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lesson-section-header-a2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('lesson-section-header-plain')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('lesson-section-header-b1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lesson-section-header-a3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lesson-section-header-plain2')),
        findsNothing,
      );

      final columnChildren = tester
          .widget<ListView>(find.byType(ListView))
          .childrenDelegate;
      expect(columnChildren.estimatedChildCount, 9);
      expect(
        find.descendant(
          of: find.byType(LessonSectionHeader),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(LessonSectionHeader),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
    },
  );
}

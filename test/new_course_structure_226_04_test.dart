import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/new_course_structure.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 6);

  for (final counts in [(1, 1), (3, 1), (12, 6), (100, 20)]) {
    test('atomic ${counts.$1} × ${counts.$2} scaffold and v6 round trip', () {
      final lessons = NewCourseStructure.create(
        lessonCount: counts.$1,
        roundsPerLesson: counts.$2,
        sourceLanguage: 'English',
        learningLanguage: 'Italian',
        updatedAt: now,
      );
      _expectStructure(lessons, counts.$1, counts.$2);
      final course = _course(lessons);
      final reloaded = Course.fromJson(jsonDecode(jsonEncode(course.toJson())));
      expect(reloaded.toJson(), course.toJson());
      expect(course.toJson(), isNot(contains('lessonCount')));
      expect(course.toJson(), isNot(contains('roundsPerLesson')));
      final audit = CourseAuditService().auditCourse(course);
      expect(
        audit.issues.where((issue) => issue.code == 'ROUND_CONTENT_EMPTY'),
        isEmpty,
      );
      expect(
        audit.issues.where((issue) => issue.code == 'LESSON_ROUNDS_EMPTY'),
        isEmpty,
      );
      final hierarchy = AuthoringHierarchyStatus.fromCourse(course);
      expect(hierarchy.hasLessonsAuditConcern, isTrue);
      expect(hierarchy.courseHasDraft, isTrue);
    });
  }

  test(
    'invalid counts reject before generation; generator failure returns no partial hierarchy',
    () {
      final ids = _FailingIds();
      for (final counts in [(0, 1), (101, 1), (1, 0), (1, 21)]) {
        expect(
          () => NewCourseStructure.create(
            lessonCount: counts.$1,
            roundsPerLesson: counts.$2,
            sourceLanguage: 'English',
            learningLanguage: 'Italian',
            updatedAt: now,
            ids: ids,
          ),
          throwsRangeError,
        );
      }
      expect(ids.calls, 0);
      List<Lesson>? adopted;
      expect(() {
        adopted = NewCourseStructure.create(
          lessonCount: 3,
          roundsPerLesson: 2,
          sourceLanguage: 'English',
          learningLanguage: 'Italian',
          updatedAt: now,
          ids: ids,
        );
      }, throwsStateError);
      expect(adopted, isNull);
    },
  );

  for (final languages in [
    ('Spanish', 'German'),
    ('日本語', 'العربية'),
    ('cy-GB', 'fi-FI'),
  ]) {
    test('sample placeholders adapt ${languages.$1} → ${languages.$2}', () {
      final lessons = NewCourseStructure.create(
        lessonCount: 1,
        roundsPerLesson: 1,
        sourceLanguage: languages.$1,
        learningLanguage: languages.$2,
        updatedAt: now,
      );
      final course = Course.fromJson({
        ..._course(lessons).toJson(),
        'sourceLanguage': languages.$1,
        'interfaceLanguage': languages.$1,
        'learningLanguage': languages.$2,
        'targetLanguage': languages.$2,
      });
      final reloaded = Course.fromJson(jsonDecode(jsonEncode(course.toJson())));
      final sample = reloaded.lessons.single.rounds.single.exercises.single;
      expect(sample.editorTemplate, 'choice');
      expect(sample.interaction.kind, 'select');
      expect(
        sample.prompt,
        'Write a ${languages.$1} instruction to translate into ${languages.$2}.',
      );
      expect(sample.question, 'Text in ${languages.$1}');
      expect(sample.answers, [
        'Translation in ${languages.$2}',
        'Wrong Answer',
      ]);
      expect(sample.correct, 0);
      expect(sample.publicationState, PublicationState.draft);
      expect(sample.updatedAt, now);
      expect(reloaded.toJson(), course.toJson());

      // Publishing an ancestor must not silently publish placeholder material.
      final publishedParents = Course.fromJson({
        ...reloaded.toJson(),
        'publicationState': 'published',
        'lessons': [
          {
            ...reloaded.lessons.single.toJson(),
            'publicationState': 'published',
          },
        ],
      });
      final visible = PublicationService().learnerCourse(publishedParents)!;
      expect(
        visible.lessons
            .expand((lesson) => lesson.rounds)
            .expand((round) => round.exercises),
        isEmpty,
      );
      expect(reloaded.lessons.single.rounds.single.exercises, hasLength(1));
    });
  }

  test(
    'invalid languages fail before IDs and later failures adopt nothing',
    () {
      final unusedIds = _FailingIds();
      for (final languages in [('', 'German'), ('Spanish', '  ')]) {
        expect(
          () => NewCourseStructure.create(
            lessonCount: 1,
            roundsPerLesson: 1,
            sourceLanguage: languages.$1,
            learningLanguage: languages.$2,
            updatedAt: now,
            ids: unusedIds,
          ),
          throwsArgumentError,
        );
      }
      expect(unusedIds.calls, 0);
      for (final failAt in [3, 4, 5, 7, 10]) {
        List<Lesson>? adopted;
        expect(() {
          adopted = NewCourseStructure.create(
            lessonCount: 3,
            roundsPerLesson: 1,
            sourceLanguage: 'Spanish',
            learningLanguage: 'German',
            updatedAt: now,
            ids: _FailingIds(failAt: failAt),
          );
        }, throwsStateError);
        expect(adopted, isNull);
      }
    },
  );

  testWidgets(
    'dialog displays 3 and 1; defaults create only a complete working copy',
    (tester) async {
      await _open(tester);
      expect(tester.widget<TextField>(_lessons).controller!.text, '3');
      expect(tester.widget<TextField>(_rounds).controller!.text, '1');
      expect(
        find.text('Each Round starts with a sample exercise.'),
        findsOneWidget,
      );
      await _create(tester);
      final course = tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course;
      _expectStructure(course.lessons, 3, 1);
      expect(await CourseEditorService().listUserCourses(), isEmpty);
    },
  );

  for (final counts in [(1, 1), (12, 6), (100, 20)]) {
    testWidgets(
      'dialog creates requested ${counts.$1} × ${counts.$2} hierarchy',
      (tester) async {
        await _open(tester);
        await _enter(tester, _lessons, '${counts.$1}');
        await _enter(tester, _rounds, '${counts.$2}');
        await _create(tester);
        _expectStructure(
          tester
              .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
              .course
              .lessons,
          counts.$1,
          counts.$2,
        );
        expect(await CourseEditorService().listUserCourses(), isEmpty);
      },
    );
  }

  testWidgets('dialog uses both chosen languages in every Draft sample', (
    tester,
  ) async {
    await _open(tester);
    await _enter(
      tester,
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Source language *',
      ),
      'Spanish',
    );
    await _enter(
      tester,
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Target language *',
      ),
      'German',
    );
    await _create(tester);
    final course = tester
        .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
        .course;
    final samples = course.lessons
        .expand((lesson) => lesson.rounds)
        .expand((round) => round.exercises)
        .toList();
    expect(samples, hasLength(3));
    for (final sample in samples) {
      expect(
        sample.prompt,
        'Write a Spanish instruction to translate into German.',
      );
      expect(sample.question, 'Text in Spanish');
      expect(sample.answers, ['Translation in German', 'Wrong Answer']);
      expect(sample.publicationState, PublicationState.draft);
    }
    expect(samples.map((sample) => sample.id).toSet(), hasLength(3));
    expect(await CourseEditorService().listUserCourses(), isEmpty);
  });

  testWidgets(
    'missing, nonnumeric, fractional and out-of-range values disable Create inline',
    (tester) async {
      await _open(tester);
      for (final field in [_lessons, _rounds]) {
        final maximum = field == _lessons ? 100 : 20;
        for (final value in [
          '',
          'abc',
          '1.5',
          '1e1',
          '-1',
          '0',
          '${maximum + 1}',
          '999999999999999999999999',
        ]) {
          await _enter(tester, field, value);
          expect(
            tester.widget<TextField>(field).decoration!.errorText,
            isNotNull,
          );
          expect(tester.widget<FilledButton>(_createButton).onPressed, isNull);
          expect(find.byType(CourseEditorScreen), findsNothing);
          expect(await CourseEditorService().listUserCourses(), isEmpty);
        }
        await _enter(tester, field, '1');
        expect(tester.widget<TextField>(field).decoration!.errorText, isNull);
      }
      expect(tester.widget<FilledButton>(_createButton).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorScreen), findsNothing);
      expect(await CourseEditorService().listUserCourses(), isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Create new course'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_lessons).controller!.text, '3');
      expect(tester.widget<TextField>(_rounds).controller!.text, '1');
    },
  );

  test(
    'supported import accepts 101 Lessons and 21 Rounds without scaffolding limits',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_22604_large_import_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final original = _largeCourse();
      await File(
        '${directory.path}/import.json',
      ).writeAsString(jsonEncode(original.toJson()));
      final imported = await CustomCourseTransferService(
        directory: () async => directory,
      ).importCourse();
      expect(imported.toJson(), original.toJson());
      expect(imported.lessons, hasLength(101));
      expect(imported.lessons.first.rounds, hasLength(21));
    },
  );

  testWidgets('later editing can add Lesson 102 and Round 22', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var course = _largeCourse();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(
          course: course,
          initiallyLocked: false,
          onCourseChanged: (value) => course = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New lesson'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Lesson beyond initial limits',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    expect(course.lessons, hasLength(102));
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(
          course: course,
          lesson: course.lessons.first,
          onCourseChanged: (value) => course = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New round'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(course.lessons.first.rounds, hasLength(22));
    expect(course.lessons.first.rounds.last.exercises, hasLength(3));
    expect(course.lessons.first.rounds.first.exercises, isEmpty);
    expect(Course.fromJson(course.toJson()).lessons, hasLength(102));
  });
}

final _lessons = find.byKey(const Key('new-course-lesson-count'));
final _rounds = find.byKey(const Key('new-course-round-count'));
final _createButton = find.widgetWithText(FilledButton, 'Create');

Future<void> _open(WidgetTester tester) async {
  const profile = '12345678-1234-4234-9234-123456789abc';
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      const LearnerProfile(
        learnerProfileId: profile,
        displayName: 'Structure Author',
      ).encode(),
    ],
    ProfileService.activeProfileIdKey: profile,
  });
  await tester.pumpWidget(
    MaterialApp(home: CourseProjectsScreen(currentCourse: _course([]))),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Create new course'));
  await tester.pumpAndSettle();
  await _enter(
    tester,
    find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Course title *',
    ),
    'New structure',
  );
  await _enter(
    tester,
    find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Target language *',
    ),
    'Italian',
  );
}

Future<void> _enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _create(WidgetTester tester) async {
  await tester.tap(_createButton);
  await tester.pumpAndSettle();
  expect(find.byType(CourseEditorScreen), findsOneWidget);
}

void _expectStructure(List<Lesson> lessons, int lessonCount, int roundCount) {
  expect(lessons, hasLength(lessonCount));
  final identities = <String>[];
  for (var index = 0; index < lessons.length; index++) {
    final lesson = lessons[index];
    expect(lesson.title, 'Lesson ${index + 1}');
    expect(lesson.rounds, hasLength(roundCount));
    identities.addAll([lesson.lessonId, lesson.guidebookId, lesson.duel.id]);
    for (var round = 0; round < lesson.rounds.length; round++) {
      final value = lesson.rounds[round];
      expect(value.title, isEmpty);
      expect(value.displayTitle(round), 'Round ${round + 1}');
      expect(value.content, hasLength(1));
      expect(value.exercises, hasLength(1));
      final sample = value.exercises.single;
      expect(sample.editorTemplate, 'choice');
      expect(sample.answers, ['Translation in Italian', 'Wrong Answer']);
      expect(sample.publicationState, PublicationState.draft);
      expect(value.content.single.publicationState, PublicationState.draft);
      expect(value.content.single.id, sample.id);
      expect(value.publicationState, PublicationState.published);
      identities.add(value.id);
      identities.add(sample.id);
      identities.addAll(sample.interaction.items.map((item) => item.id));
    }
  }
  expect(identities.every((id) => id.isNotEmpty), isTrue);
  expect(identities.toSet(), hasLength(identities.length));
}

Course _course(List<Lesson> lessons) => Course(
  courseId: 'structure-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Structure',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: lessons,
);

Course _largeCourse() => _course([
  for (var lesson = 0; lesson < 101; lesson++)
    Lesson(
      lessonId: 'existing_lesson_$lesson',
      title: 'Existing $lesson',
      rounds: [
        if (lesson == 0)
          for (var round = 0; round < 21; round++)
            LearningRound(id: 'existing_round_$round', title: '', content: []),
      ],
    ),
]);

class _FailingIds implements AuthoringIdGenerator {
  _FailingIds({this.failAt = 4});
  final int failAt;
  int calls = 0;
  @override
  String next(String kind) {
    if (++calls == failAt) throw StateError('Injected generation failure');
    return '${kind}_$calls';
  }
}

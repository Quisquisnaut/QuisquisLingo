import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileName = 'My test author';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;

  setUp(() async {
    for (final asset in CourseService.courseAssets.values) {
      rootBundle.evict(asset);
    }
    resetLockedLessonPreviewSessionForTesting();
    documents = await Directory.systemTemp.createTemp('qql-mytest-workflow-');

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => documents.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final arguments = call.arguments as Map<Object?, Object?>;
          _installEventChannelMock(
            messenger,
            'xyz.luan/audioplayers/events/${arguments['playerId']}',
          );
        }
        return null;
      },
    );
    _installEventChannelMock(messenger, 'xyz.luan/audioplayers.global/events');

    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
      'sound_effects_enabled': false,
      'skip_tts_exercises': true,
      CourseService.bundledCourseIndexStorageKey: const [
        'IT',
        'DE',
        'ES',
        'EN',
        'CY',
        'NL',
        'PT',
        'FI',
      ],
      'audio_orphan_check_last_IT': DateTime.now().toIso8601String(),
    });
    await ProfileService().addProfile(_profileName);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  testWidgets(
    'MyTest publishes one ready provisional Lesson without parent Save actions',
    (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        MaterialApp(home: CourseProjectsScreen(currentCourse: _hostCourse())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create new course'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Course title *'), 'MyTest');
      await tester.enterText(_field('Target language *'), 'Italian');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('new-course-lesson-count')))
            .controller!
            .text,
        '3',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('new-course-round-count')))
            .controller!
            .text,
        '1',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      final created = tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course;
      final courseId = created.courseId;
      final lessonIds = created.lessons
          .map((lesson) => lesson.lessonId)
          .toList();
      final roundIds = created.lessons
          .map((lesson) => lesson.rounds.single.id)
          .toList();
      final sampleIds = created.lessons
          .map((lesson) => lesson.rounds.single.exercises.single.id)
          .toList();
      final allIds = <String>{
        courseId,
        ...lessonIds,
        ...roundIds,
        ...sampleIds,
        for (final lesson in created.lessons)
          ...lesson.rounds.single.exercises.single.interaction.items.map(
            (item) => item.id,
          ),
      };

      expect(created.title, 'MyTest');
      expect(created.publicationState, PublicationState.draft);
      expect(created.lessons, hasLength(3));
      expect(allIds, hasLength(16));
      for (final lesson in created.lessons) {
        expect(lesson.publicationState, PublicationState.draft);
        expect(lesson.provisionalDraft, isTrue);
        expect(
          lesson.rounds.single.publicationState,
          PublicationState.published,
        );
        expect(lesson.rounds.single.provisionalDraft, isFalse);
        expect(lesson.rounds.single.exercises, hasLength(1));
        expect(
          lesson.rounds.single.exercises.single.publicationState,
          PublicationState.draft,
        );
      }
      expect(await CourseEditorService().listUserCourses(), isEmpty);

      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      final lock = find.byKey(const Key('lesson-management-lock'));
      if (tester.widget<IconButton>(lock).isSelected == true) {
        await tester.tap(lock);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey(lessonIds.first)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(roundIds.first)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-exercise')), findsOneWidget);
      expect(find.byKey(ValueKey(sampleIds.first)), findsOneWidget);

      await _openExistingExercise(tester, sampleIds.first);
      expect(
        tester
            .widget<ExerciseEditorScreen>(find.byType(ExerciseEditorScreen))
            .isNew,
        isFalse,
      );
      await tester.enterText(
        _field('Prompt / instruction'),
        'Choose the correct Italian translation.',
      );
      await tester.enterText(_field('Question'), 'hello');
      await tester.enterText(_field('Answers'), 'ciao\narrivederci');
      await tester.enterText(_field('Correct answer number'), '1');
      final exerciseSave = find.byKey(const Key('exercise-save'));
      await tester.scrollUntilVisible(
        exerciseSave,
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(exerciseSave);
      await tester.pumpAndSettle();
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(find.byKey(ValueKey(sampleIds.first)), findsOneWidget);
      expect(
        find.byKey(ValueKey('exercise-draft-indicator-${sampleIds.first}')),
        findsNothing,
      );

      // Reopen the same row only to inspect the current canonical hierarchy.
      // No second Exercise is created and no second Save is performed.
      await _openExistingExercise(tester, sampleIds.first);
      final currentEditor = tester.widget<ExerciseEditorScreen>(
        find.byType(ExerciseEditorScreen),
      );
      expect(currentEditor.exercise.id, sampleIds.first);
      expect(
        currentEditor.exercise.publicationState,
        PublicationState.published,
      );
      expect(currentEditor.round!.id, roundIds.first);
      expect(currentEditor.round!.publicationState, PublicationState.published);
      expect(currentEditor.round!.exercises, hasLength(1));
      expect(currentEditor.round!.exercises.single.id, sampleIds.first);
      final currentCourseExercise =
          currentEditor.course!.lessons.first.rounds.single.exercises.single;
      expect(currentCourseExercise.id, sampleIds.first);
      expect(
        currentCourseExercise.publicationState,
        PublicationState.published,
      );
      expect(
        currentEditor.course!.lessons.first.publicationState,
        PublicationState.draft,
      );
      expect(currentEditor.course!.lessons.first.provisionalDraft, isTrue);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();

      // Return without invoking Round Save or Lesson Save.
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('lesson-guidebook-navigation')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Overview'), 'Learn a first greeting.');
      await tester.enterText(_field('Usage examples'), 'Ciao, Anna!');
      await tester.enterText(_field('Vocabulary'), 'ciao = hello');
      await tester.enterText(_field('Grammar'), 'Ciao is a greeting.');
      final guidebookSave = find.byKey(const Key('guidebook-save'));
      await tester.scrollUntilVisible(
        guidebookSave,
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(guidebookSave);
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.byKey(const Key('lesson-own-draft-indicator')), findsNothing);
      expect(await CourseEditorService().listUserCourses(), isEmpty);

      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(
        find.byKey(ValueKey('lesson-draft-indicator-${lessonIds.first}')),
        findsNothing,
      );
      for (final siblingId in lessonIds.skip(1)) {
        expect(
          find.byKey(ValueKey('lesson-draft-indicator-$siblingId')),
          findsOneWidget,
        );
      }
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorScreen), findsOneWidget);

      final delivery = find.byKey(const Key('course-draft-status'));
      expect(
        find.descendant(of: delivery, matching: find.text('Not published')),
        findsOneWidget,
      );
      final publish = find.descendant(
        of: delivery,
        matching: find.widgetWithText(TextButton, 'Publish'),
      );
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: delivery, matching: find.text('Published')),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('course-version-notes')),
        'Complete the first provisional Lesson.',
      );
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await _pumpUntilWithIo(tester, find.byType(CourseProjectsScreen));

      final storedCourses = await CourseEditorService().listUserCourses();
      expect(storedCourses, hasLength(1));
      final stored = storedCourses.single;
      _expectFinalAuthoringTree(
        stored,
        courseId: courseId,
        lessonIds: lessonIds,
        roundIds: roundIds,
        sampleIds: sampleIds,
      );
      expect(
        Course.fromJson(jsonDecode(jsonEncode(stored.toJson()))).toJson(),
        stored.toJson(),
      );
      await _expectRawTree(
        courseId: courseId,
        lessonIds: lessonIds,
        roundIds: roundIds,
        sampleIds: sampleIds,
      );

      await SettingsService().setLastSelectedCourseCode('custom:$courseId');
      await _openHome(tester);
      _expectHome(
        tester,
        courseId: courseId,
        lessonIds: lessonIds,
        roundId: roundIds.first,
        sampleId: sampleIds.first,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);
      await _openHome(tester);
      _expectHome(
        tester,
        courseId: courseId,
        lessonIds: lessonIds,
        roundId: roundIds.first,
        sampleId: sampleIds.first,
      );
      expect(
        await SettingsService().getLastSelectedCourseCode(),
        'custom:$courseId',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openExistingExercise(
  WidgetTester tester,
  String exerciseId,
) async {
  await tester.tap(find.byKey(ValueKey('exercise-actions-$exerciseId')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit').last);
  await tester.pumpAndSettle();
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

void _expectFinalAuthoringTree(
  Course course, {
  required String courseId,
  required List<String> lessonIds,
  required List<String> roundIds,
  required List<String> sampleIds,
}) {
  expect(course.courseId, courseId);
  expect(course.title, 'MyTest');
  expect(course.courseVersion, '1');
  expect(course.publicationState, PublicationState.published);
  expect(course.lessons.map((lesson) => lesson.lessonId), lessonIds);
  expect(course.lessons.map((lesson) => lesson.rounds.single.id), roundIds);
  expect(
    course.lessons.map((lesson) => lesson.rounds.single.exercises.single.id),
    sampleIds,
  );
  expect(course.lessons.first.publicationState, PublicationState.published);
  expect(course.lessons.first.provisionalDraft, isFalse);
  expect(
    course.lessons.first.guidebook.publicationState,
    PublicationState.published,
  );
  expect(course.lessons.first.guidebook.content, isNotEmpty);
  expect(
    course.lessons.first.guidebook.content.every(
      (content) => content.publicationState.isPublished,
    ),
    isTrue,
  );
  expect(
    course.lessons.first.rounds.single.publicationState,
    PublicationState.published,
  );
  expect(course.lessons.first.rounds.single.exercises, hasLength(1));
  final edited = course.lessons.first.rounds.single.exercises.single;
  expect(edited.id, sampleIds.first);
  expect(edited.publicationState, PublicationState.published);
  expect(edited.prompt, 'Choose the correct Italian translation.');
  expect(edited.question, 'hello');
  expect(edited.answers, ['ciao', 'arrivederci']);
  for (var index = 1; index < course.lessons.length; index++) {
    final sibling = course.lessons[index];
    expect(sibling.publicationState, PublicationState.draft);
    expect(sibling.provisionalDraft, isTrue);
    expect(sibling.rounds.single.publicationState, PublicationState.published);
    expect(sibling.rounds.single.exercises, hasLength(1));
    expect(
      sibling.rounds.single.exercises.single.publicationState,
      PublicationState.draft,
    );
  }
}

Future<void> _expectRawTree({
  required String courseId,
  required List<String> lessonIds,
  required List<String> roundIds,
  required List<String> sampleIds,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final root = Map<String, dynamic>.from(
    jsonDecode(
          preferences.getString(CourseEditorService.userCoursesStorageKey)!,
        )
        as Map,
  );
  expect(root.keys, [courseId]);
  final envelope = Map<String, dynamic>.from(root[courseId] as Map);
  expect(envelope['savedAt'], isA<String>());
  final course = Map<String, dynamic>.from(envelope['course'] as Map);
  expect(course['courseId'], courseId);
  expect(course['courseVersion'], '1');
  expect(course['publicationState'], 'published');
  final lessons = (course['lessons'] as List)
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList();
  expect(lessons.map((lesson) => lesson['lessonId']), lessonIds);
  for (var index = 0; index < lessons.length; index++) {
    final lesson = lessons[index];
    expect(lesson['publicationState'], index == 0 ? 'published' : 'draft');
    expect(lesson.containsKey('provisionalDraft'), index != 0);
    final rounds = lesson['rounds'] as List;
    expect(rounds, hasLength(1));
    final round = Map<String, dynamic>.from(rounds.single as Map);
    expect(round['id'], roundIds[index]);
    expect(round['publicationState'], 'published');
    expect(round.containsKey('provisionalDraft'), isFalse);
    final content = round['content'] as List;
    expect(content, hasLength(1));
    final exercise = Map<String, dynamic>.from(content.single as Map);
    expect(exercise['id'], sampleIds[index]);
    expect(exercise['publicationState'], index == 0 ? 'published' : 'draft');
  }
}

void _expectHome(
  WidgetTester tester, {
  required String courseId,
  required List<String> lessonIds,
  required String roundId,
  required String sampleId,
}) {
  final backdrop = tester.widget<CourseFlagBackdrop>(
    find.byKey(const Key('unified-learner-flag-background')),
  );
  expect(backdrop.course.courseId, courseId);
  expect(backdrop.course.lessons, hasLength(1));
  expect(backdrop.course.lessons.single.lessonId, lessonIds.first);
  expect(
    backdrop.course.lessons.single.rounds.single.exercises.single.id,
    sampleId,
  );
  expect(
    find.byKey(ValueKey('unified-lesson-section-${lessonIds.first}')),
    findsOneWidget,
  );
  for (final siblingId in lessonIds.skip(1)) {
    expect(
      find.byKey(ValueKey('unified-lesson-section-$siblingId')),
      findsNothing,
    );
  }
  expect(find.byKey(ValueKey('unified-round-$roundId')), findsOneWidget);
}

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  final alphaNotice = find.text('Alpha expiry');
  await _pumpUntilWithIo(tester, alphaNotice);
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await _pumpUntilWithIo(
    tester,
    find.byKey(const Key('unified-learner-flag-background')),
  );
}

Future<void> _pumpUntilWithIo(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 160; frame++) {
    await _pumpIo(tester, frames: 1);
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data);
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

Future<void> _pumpIo(WidgetTester tester, {required int frames}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void _viewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Course _hostCourse() => Course(
  courseId: 'host-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Host course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: const [],
);

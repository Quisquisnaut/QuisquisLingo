import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/course_version_history_screen.dart';
import 'package:quisquislingo_app/screens/official_course_inspection_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CourseEditorService service;
  late _HistoryBackups backups;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Fork Creator',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
    backups = _HistoryBackups();
    service = CourseEditorService(
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 5, 10),
    );
  });

  for (final origin in [
    CourseOriginType.bundledOfficial,
    CourseOriginType.externalOfficial,
  ]) {
    testWidgets('${origin.name} inspection has no authoring workflow', (
      tester,
    ) async {
      final official = _official(origin: origin);
      await _storeSource(official);
      final before = await _preferences();
      await _open(tester, official, service);
      expect(find.byType(OfficialCourseInspectionScreen), findsOneWidget);
      expect(find.text('Official course - read only'), findsOneWidget);
      _expectNoAuthoring();

      await tester.tap(find.byKey(const Key('official-course-info')));
      await _settle(tester);
      expect(find.byType(CourseInfoScreen), findsOneWidget);
      expect(find.textContaining('Original Publisher'), findsWidgets);
      expect(find.textContaining('Original Author'), findsWidgets);
      _expectNoAuthoring();
      await _back(tester);

      await tester.tap(find.byKey(const Key('official-course-audit')));
      await _settle(tester);
      expect(find.byType(CourseAuditScreen), findsOneWidget);
      expect(find.byKey(const Key('copy-audit-report')), findsOneWidget);
      _expectNoAuthoring();
      await _back(tester);

      await tester.tap(find.byKey(const Key('official-course-history')));
      await _settle(tester);
      expect(find.byType(CourseVersionHistoryScreen), findsOneWidget);
      expect(find.text('Restore this version'), findsNothing);
      expect(find.text('Open as custom copy'), findsNothing);
      expect(backups.officialHistoryReads, 1);
      expect(backups.customHistoryReads, 0);
      await _back(tester);

      await tester.tap(find.byKey(const ValueKey('official-lesson-lesson')));
      await _settle(tester);
      expect(find.text('Guidebook'), findsOneWidget);
      expect(find.text('Preview Lesson'), findsOneWidget);
      _expectNoAuthoring();
      await tester.tap(find.byKey(const ValueKey('official-round-round')));
      await _settle(tester);
      expect(find.text('Preview Round'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('official-exercise-exercise')),
      );
      await _settle(tester);
      expect(find.text('Exercise inspection'), findsOneWidget);
      expect(find.textContaining('Publisher prompt'), findsOneWidget);
      _expectNoAuthoring();
      await tester.tap(find.text('Preview Exercise'));
      await _settle(tester, frames: 30);
      expect(find.byType(RoundScreen), findsOneWidget);
      expect(
        tester.widget<RoundScreen>(find.byType(RoundScreen)).previewMode,
        isTrue,
      );
      expect(find.text('Publisher prompt'), findsOneWidget);
      expect(await _preferences(), before);
      expect(
        await service.listUserCourses(),
        origin == CourseOriginType.externalOfficial ? hasLength(1) : isEmpty,
      );
    });
  }

  for (final policy in [
    DerivativeWorksPolicy.forbidden,
    DerivativeWorksPolicy.unspecified,
  ]) {
    testWidgets('$policy disables the fork action with an explanation', (
      tester,
    ) async {
      final official = _official(policy: policy);
      await _open(tester, official, service);
      final action = tester.widget<FilledButton>(
        find.byKey(const Key('fork-official-course')),
      );
      expect(action.onPressed, isNull);
      expect(
        find.textContaining(
          policy == DerivativeWorksPolicy.forbidden
              ? 'publisher forbids derivative works'
              : 'has not been specified by the publisher',
        ),
        findsOneWidget,
      );
      expect(await service.listUserCourses(), isEmpty);
    });
  }

  testWidgets(
    'licensed fork opens a custom transaction and preserves attribution through rename and confirmation',
    (tester) async {
      final official = _official();
      final original = official.toJson();
      await _open(tester, official, service);
      await tester.tap(find.byKey(const Key('fork-official-course')));
      await _settle(tester);
      final editor = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen).last,
      );
      expect(editor.isNewCourse, isTrue);
      expect(editor.course.originType, CourseOriginType.custom);
      expect(editor.course.courseId, isNot(official.courseId));
      expect(editor.course.authors.single.name, 'Original Author');
      expect(
        editor.course.forkProvenance!.forkCreatedByUsername,
        'Fork Creator',
      );
      expect(await service.listUserCourses(), isEmpty);
      await tester.tap(find.text('Course info'));
      await _settle(tester);
      expect(find.byType(CourseForkProvenanceCard), findsOneWidget);
      expect(
        find.textContaining('Original authors:\nOriginal Author'),
        findsOneWidget,
      );
      expect(find.textContaining('Forked by: Fork Creator'), findsOneWidget);
      final title = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Course name',
      );
      await tester.enterText(title, 'My renamed custom fork');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);
      await _back(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await _settle(tester, frames: 30);
      final saved = (await service.listUserCourses()).single;
      expect(saved.title, 'My renamed custom fork');
      expect(saved.courseVersion, '1');
      expect(saved.authors.single.name, 'Original Author');
      expect(saved.forkProvenance!.originalCourseTitle, official.title);
      expect(
        saved.forkProvenance!.originalOfficialChecksum,
        official.officialChecksum,
      );
      expect(saved.forkProvenance!.forkCreatedByProfileId, _profileId);
      expect(official.toJson(), original);
      expect(find.byType(OfficialCourseInspectionScreen), findsOneWidget);
    },
  );

  testWidgets(
    'missing official source fails closed without edit or fork actions',
    (tester) async {
      final course = _official(origin: CourseOriginType.externalOfficial);
      await _open(tester, course, service);
      expect(
        find.textContaining('immutable official source is unavailable'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('fork-official-course')), findsNothing);
      _expectNoAuthoring();
    },
  );

  for (final width in [320.0, 375.0, 430.0, 1200.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'official inspection and fork explanation fit $width $brightness',
        (tester) async {
          await _open(
            tester,
            _official(),
            service,
            width: width,
            brightness: brightness,
          );
          expect(find.text('Official course - read only'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const Key('official-course-info')));
          await _settle(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

void _expectNoAuthoring() {
  expect(find.byType(TextField), findsNothing);
  expect(find.byType(TextFormField), findsNothing);
  expect(find.byType(SwitchListTile), findsNothing);
  expect(find.byType(FloatingActionButton), findsNothing);
  for (final label in [
    'Save',
    'Save as draft',
    'Edit',
    'Restore official version',
    'Copy edits as JSON',
    'Reset local edits',
  ]) {
    expect(find.text(label), findsNothing);
  }
  expect(
    find.byKey(const Key('course-transaction-confirmation')),
    findsNothing,
  );
}

Future<void> _open(
  WidgetTester tester,
  Course course,
  CourseEditorService service, {
  double width = 1200,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1500);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => CourseEditorScreen(
                course: course,
                editorService: service,
                courseService: _OfficialSource(course),
              ),
            ),
          ),
          child: const Text('Open official'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open official'));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester, {int frames = 15}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
}

Future<void> _storeSource(Course course) async {
  if (course.originType != CourseOriginType.externalOfficial) return;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    CourseEditorService.externalOfficialStorageKey,
    jsonEncode({
      course.courseId: {'source': course.toJson()},
    }),
  );
}

Future<Map<String, Object?>> _preferences() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)};
}

class _OfficialSource extends CourseService {
  _OfficialSource(this.course);
  final Course course;
  @override
  Future<Course> loadBundledCourse(String languageCode) async => course;
}

class _HistoryBackups extends CourseBackupService {
  int officialHistoryReads = 0;
  int customHistoryReads = 0;
  @override
  Future<Directory> courseBackupDirectory(
    String courseId, {
    bool create = false,
  }) async =>
      Directory('${Directory.systemTemp.path}/qql_22601_readonly_ui/$courseId');
  @override
  Future<List<CourseBackupRecord>> listOfficialBackups(String courseId) async {
    officialHistoryReads++;
    return [];
  }

  @override
  Future<List<CourseBackupRecord>> listBackups(String courseId) async {
    customHistoryReads++;
    return [];
  }
}

Course _official({
  CourseOriginType origin = CourseOriginType.bundledOfficial,
  DerivativeWorksPolicy policy = DerivativeWorksPolicy.allowed,
}) {
  final course = Course(
    courseId: 'readonly-official',
    originType: origin,
    publisherId: 'publisher',
    publisherName: 'Original Publisher',
    officialCourseVersion: '3',
    officialReleaseDateUtc: '2026-09-01T10:00:00.000Z',
    officialChecksum: '0' * 64,
    distributionChannel: origin == CourseOriginType.bundledOfficial
        ? 'app'
        : 'package',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Publisher Course',
    ttsLanguage: 'it-IT',
    version: '1',
    authors: const [
      CourseAuthor(name: 'Original Author', roles: ['Course Creator']),
    ],
    license: 'Publisher content license',
    derivativeWorksPolicy: policy,
    lessons: [
      Lesson(
        lessonId: 'lesson',
        updatedAt: DateTime.utc(2026, 9, 1),
        title: 'Publisher Lesson',
        rounds: [
          LearningRound(
            id: 'round',
            updatedAt: DateTime.utc(2026, 9, 1),
            title: 'Publisher Round',
            exercises: [
              Exercise(
                id: 'exercise',
                updatedAt: DateTime.utc(2026, 9, 1),
                type: 'choice',
                prompt: 'Publisher prompt',
                question: 'Choose one.',
                answers: const ['One', 'Two'],
                correct: 0,
                tts: null,
                accepted: const [],
                tokens: const [],
                orderAnswer: const [],
                pairs: const [],
                hint: '',
                icons: const [],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(course),
  });
}

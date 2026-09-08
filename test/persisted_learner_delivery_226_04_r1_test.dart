import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _courseId = 'course_31b11b63-e6d2-4f2a-a731-a71ba236960c';
const _lessonId = 'persisted-published-lesson';
const _roundId = 'persisted-published-round';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory backupRoot;
  late CourseEditorService editor;
  late SettingsService settings;

  setUp(() async {
    for (final asset in CourseService.courseAssets.values) {
      rootBundle.evict(asset);
    }
    resetLockedLessonPreviewSessionForTesting();
    backupRoot = await Directory.systemTemp.createTemp(
      'qql-persisted-learner-delivery-',
    );
    addTearDown(() async {
      if (await backupRoot.exists()) {
        await backupRoot.delete(recursive: true);
      }
    });

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => throw PlatformException(code: 'test-storage'),
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
    });
    await ProfileService().addProfile('Persisted delivery tester');
    await SettingsService().setAudioExercisesEnabled(false);
    editor = CourseEditorService(
      backupService: CourseBackupService(
        documentsDirectoryProvider: () async => backupRoot,
      ),
      clock: () => DateTime.utc(2026, 9, 7, 12),
    );
    settings = SettingsService();
  });

  testWidgets(
    'a persisted 0E 0W published custom course reaches Home and survives restart',
    (tester) async {
      final authored = _course(lessonState: PublicationState.published);
      final audit = CourseAuditService().auditCourse(authored);
      expect(audit.count(AuditSeverity.error), 0);
      expect(audit.count(AuditSeverity.warning), 0);

      final confirmation = await editor.confirmCourseTransaction(
        originalCourse: authored,
        workingCourse: authored,
        languageCode: 'IT',
        versionNotes: 'Initial published learner-delivery fixture.',
        isNewCourse: true,
        committedAt: DateTime.utc(2026, 9, 7, 12),
      );
      await settings.setLastSelectedCourseCode('custom:$_courseId');

      _expectPersistedPublishedTree(await editor.listUserCourses());
      await _expectRawPublishedTree();
      expect(confirmation.course.courseId, _courseId);
      expect(await settings.getLastSelectedCourseCode(), 'custom:$_courseId');

      await _openHome(tester);
      _expectPublishedTreeOnHome(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);
      await _openHome(tester);
      _expectPublishedTreeOnHome(tester);
      expect(await settings.getLastSelectedCourseCode(), 'custom:$_courseId');
    },
  );

  testWidgets(
    'raw all-green Course reveals its Draft Lesson; real Lesson Save restores same-ID delivery',
    (tester) async {
      const otherId = 'different-course-with-the-same-title';
      // Start at the storage boundary, without constructing or serializing
      // a Course/Lesson that could conceal a parser/defaulting regression.
      final rawCourse =
          jsonDecode(_rawDraftLessonCourse) as Map<String, dynamic>;
      final rawOther = <String, dynamic>{
        ...rawCourse,
        'courseId': otherId,
        'lessons': <Object>[],
      };
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        CourseEditorService.userCoursesStorageKey,
        jsonEncode({
          otherId: {'savedAt': '2026-09-07T10:00:00.000Z', 'course': rawOther},
          _courseId: {
            'savedAt': '2026-09-07T10:00:00.000Z',
            'course': rawCourse,
          },
        }),
      );
      final decoded = await editor.listUserCourses();
      expect(decoded, hasLength(2));
      expect(decoded.map((course) => course.title).toSet(), hasLength(1));
      final persistedDraft = decoded.singleWhere(
        (course) => course.courseId == _courseId,
      );
      final audit = CourseAuditService().auditCourse(persistedDraft);
      expect(audit.count(AuditSeverity.error), 0);
      expect(audit.count(AuditSeverity.warning), 0);
      expect(persistedDraft.publicationState, PublicationState.published);
      expect(
        persistedDraft.lessons.single.publicationState,
        PublicationState.draft,
      );
      expect(
        persistedDraft
            .lessons
            .single
            .rounds
            .single
            .exercises
            .single
            .publicationState,
        PublicationState.published,
      );
      final status = AuthoringHierarchyStatus.fromCourse(persistedDraft);
      expect(status.hasLessonsAuditConcern, isFalse);
      expect(status.courseHasDraft, isTrue);
      expect(status.lessonHasDraft(persistedDraft.lessons.single), isTrue);
      await settings.setLastSelectedCourseCode('custom:$otherId');

      await _openHome(tester);
      await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
      await _pumpUntilWithIo(tester, find.text('Choose course'));
      await tester.pumpAndSettle();
      final selectedTile = find.byKey(
        const ValueKey('local-course-$_courseId'),
      );
      await tester.scrollUntilVisible(
        selectedTile,
        300,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 15,
      );
      await tester.pumpAndSettle();
      await tester.tap(selectedTile);
      await _pumpIo(tester, frames: 12);
      final draftTopBar = tester.widget<UnifiedLearnerTopBar>(
        find.byType(UnifiedLearnerTopBar),
      );
      expect(draftTopBar.course.courseId, _courseId);
      expect(draftTopBar.course.lessons, isEmpty);
      expect(await settings.getLastSelectedCourseCode(), 'custom:$_courseId');
      expect(
        find.byKey(const ValueKey('unified-lesson-section-$_lessonId')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);

      await settings.setCourseEditorLocked(_courseId, false);
      await settings.markAudioOrphanCheckRun(
        CourseService.codeForCourse(persistedDraft),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: persistedDraft,
            userCourse: true,
            editorService: editor,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('course-lessons-draft-indicator')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('lesson-draft-indicator-$_lessonId')),
        findsOneWidget,
      );
      await _openFixtureLesson(tester);
      final lessonEditor = tester.widget<LessonEditorScreen>(
        find.byType(LessonEditorScreen),
      );
      expect(lessonEditor.course.courseId, _courseId);
      expect(lessonEditor.lesson.lessonId, _lessonId);
      expect(lessonEditor.lesson.publicationState, PublicationState.draft);
      expect(
        find.byKey(const Key('lesson-own-draft-indicator')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('lesson-draft-indicator-$_lessonId')),
        findsNothing,
      );
      await _openFixtureLesson(tester);
      final explicitlyPublished = tester
          .widget<LessonEditorScreen>(find.byType(LessonEditorScreen))
          .course;
      expect(
        explicitlyPublished.lessons.single.publicationState,
        PublicationState.published,
      );
      expect(find.byKey(const Key('lesson-own-draft-indicator')), findsNothing);
      // Nested Save updates the working copy only. Confirm the complete
      // immutable result through the normal course transaction boundary.
      expect(
        (await editor.listUserCourses())
            .singleWhere((course) => course.courseId == _courseId)
            .lessons
            .single
            .publicationState,
        PublicationState.draft,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);
      final secondConfirmation = await tester
          .runAsync<CourseConfirmationResult>(
            () => editor.confirmCourseTransaction(
              originalCourse: persistedDraft,
              workingCourse: explicitlyPublished,
              languageCode: 'IT',
              versionNotes: 'Explicitly publish the existing Lesson.',
              committedAt: DateTime.utc(2026, 9, 7, 13),
            ),
          );
      expect(secondConfirmation, isNotNull);
      final confirmed = secondConfirmation!;

      expect(confirmed.course.courseId, _courseId);
      expect(confirmed.course.lessons.single.lessonId, _lessonId);
      expect(
        confirmed.course.lessons.single.publicationState,
        PublicationState.published,
      );
      _expectPersistedPublishedTree(await editor.listUserCourses());
      await _expectRawPublishedTree();
      final finalAudit = CourseAuditService().auditCourse(confirmed.course);
      expect(finalAudit.count(AuditSeverity.error), 0);
      expect(finalAudit.count(AuditSeverity.warning), 0);
      expect(
        (await editor.listUserCourses())
            .singleWhere((course) => course.courseId == otherId)
            .lessons,
        isEmpty,
      );

      await _openHome(tester);
      _expectPublishedTreeOnHome(tester);
      expect(await settings.getLastSelectedCourseCode(), 'custom:$_courseId');
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);
      await _openHome(tester);
      _expectPublishedTreeOnHome(tester);
      expect(await settings.getLastSelectedCourseCode(), 'custom:$_courseId');
    },
  );
}

Future<void> _openFixtureLesson(WidgetTester tester) async {
  final actions = find.byKey(const ValueKey('lesson-actions-$_lessonId'));
  await tester.ensureVisible(actions);
  await tester.tap(actions);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Edit'));
  await tester.pumpAndSettle();
  expect(find.byType(LessonEditorScreen), findsOneWidget);
}

// Synthetic v6 storage fixture, deliberately written independently of model
// constructors and toJson. This is not a user's Course or bundled content.
const _rawDraftLessonCourse = r'''
{
  "formatVersion": 6,
  "publicationState": "published",
  "lessonNumberingMode": "lesson",
  "defaultLessonIconStyle": "monochrome",
  "createDuels": false,
  "useGuidebook": false,
  "courseId": "course_31b11b63-e6d2-4f2a-a731-a71ba236960c",
  "originType": "custom",
  "learningLanguage": "Italian",
  "interfaceLanguage": "English",
  "sourceLanguage": "English",
  "targetLanguage": "Italian",
  "title": "Persisted published delivery",
  "ttsLanguage": "it-IT",
  "version": "1",
  "contentRevision": "1",
  "updateSummary": "",
  "audioMode": "tts",
  "license": "All rights reserved",
  "textDirection": "ltr",
  "flagCode": "IT",
  "temporarySample": false,
  "lessons": [{
    "lessonId": "persisted-published-lesson",
    "publicationState": "draft",
    "updatedAt": "2026-09-07T10:00:00.000Z",
    "title": "Persisted greetings",
    "section": false,
    "guidebook": {"content": []},
    "rounds": [{
      "id": "persisted-published-round",
      "publicationState": "published",
      "updatedAt": "2026-09-07T10:01:00.000Z",
      "title": "Published words",
      "visualType": "generic",
      "content": [{
        "id": "persisted-published-exercise",
        "publicationState": "published",
        "kind": "exercise",
        "required": false,
        "editorTemplate": "choice",
        "exercise": {
          "updatedAt": "2026-09-07T10:02:00.000Z",
          "prompt": [
            {"role": "primary", "type": "text", "text": "Choose the Italian translation."},
            {"role": "question", "type": "text", "text": "water"}
          ],
          "interaction": {
            "kind": "select", "minSelections": 1, "maxSelections": 1,
            "items": [
              {"id": "item_0", "content": [{"role": "primary", "type": "text", "text": "acqua"}]},
              {"id": "item_1", "content": [{"role": "primary", "type": "text", "text": "libro"}]}
            ]
          },
          "evaluation": {"kind": "selected_items", "correctItemIds": ["item_0"]}
        }
      }]
    }],
    "duel": {"id": "persisted-published-lesson_duel", "title": "Duel"}
  }]
}
''';

Course _course({required PublicationState lessonState}) => Course(
  courseId: _courseId,
  originType: CourseOriginType.custom,
  publicationState: PublicationState.published,
  createDuels: false,
  useGuidebook: false,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Persisted published delivery',
  ttsLanguage: 'it-IT',
  version: '1',
  flagCode: 'IT',
  lessons: [
    Lesson(
      lessonId: _lessonId,
      publicationState: lessonState,
      updatedAt: DateTime.utc(2026, 9, 7, 10),
      title: 'Persisted greetings',
      rounds: [
        LearningRound(
          id: _roundId,
          publicationState: PublicationState.published,
          updatedAt: DateTime.utc(2026, 9, 7, 10, 1),
          title: 'Published words',
          exercises: [
            Exercise(
              id: 'persisted-published-exercise',
              publicationState: PublicationState.published,
              updatedAt: DateTime.utc(2026, 9, 7, 10, 2),
              type: 'choice',
              prompt: 'Choose the Italian translation.',
              question: 'water',
              answers: const ['acqua', 'libro'],
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

void _expectPersistedPublishedTree(List<Course> courses) {
  final persisted = courses.singleWhere(
    (course) => course.courseId == _courseId,
  );
  expect(persisted.publicationState, PublicationState.published);
  expect(persisted.lessons.single.lessonId, _lessonId);
  expect(persisted.lessons.single.publicationState, PublicationState.published);
  expect(persisted.lessons.single.rounds.single.id, _roundId);
  expect(
    persisted.lessons.single.rounds.single.publicationState,
    PublicationState.published,
  );
  expect(
    persisted.lessons.single.rounds.single.exercises.single.publicationState,
    PublicationState.published,
  );
}

Future<void> _expectRawPublishedTree() async {
  final prefs = await SharedPreferences.getInstance();
  final root = Map<String, dynamic>.from(
    jsonDecode(prefs.getString(CourseEditorService.userCoursesStorageKey)!)
        as Map,
  );
  final entry = Map<String, dynamic>.from(root[_courseId] as Map);
  final course = Map<String, dynamic>.from(entry['course'] as Map);
  final lesson = Map<String, dynamic>.from(
    (course['lessons'] as List).single as Map,
  );
  final round = Map<String, dynamic>.from(
    (lesson['rounds'] as List).single as Map,
  );
  final content = Map<String, dynamic>.from(
    (round['content'] as List).single as Map,
  );

  expect(course['courseId'], _courseId);
  expect(course['publicationState'], 'published');
  expect(lesson['lessonId'], _lessonId);
  expect(lesson['publicationState'], 'published');
  expect(round['id'], _roundId);
  expect(round['publicationState'], 'published');
  expect(content['publicationState'], 'published');
}

void _expectPublishedTreeOnHome(WidgetTester tester) {
  final topBar = tester.widget<UnifiedLearnerTopBar>(
    find.byType(UnifiedLearnerTopBar),
  );
  expect(topBar.course.courseId, _courseId);
  expect(topBar.course.lessons.single.lessonId, _lessonId);
  expect(
    find.byKey(const ValueKey('unified-lesson-section-$_lessonId')),
    findsOneWidget,
  );
  expect(find.byKey(const ValueKey('unified-round-$_roundId')), findsOneWidget);
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}

Future<void> _openHome(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  final alphaNotice = find.text('Alpha expiry');
  await _pumpUntilWithIo(tester, alphaNotice);
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await _pumpUntilWithIo(tester, find.byType(UnifiedLearnerTopBar));
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

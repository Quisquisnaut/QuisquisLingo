import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _lessonId = 'guidebook-status-lesson';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseEditorService service;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_guidebook_status_');
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Guidebook author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'course_editor_locked_GUIDEBOOK-STATUS-COURSE': false,
    });
    service = CourseEditorService(
      backupService: CourseBackupService(
        documentsDirectoryProvider: () async => documents,
      ),
      clock: () => DateTime.utc(2026, 9, 6, 12),
    );
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  testWidgets(
    'Guidebook Draft save updates live ancestors independently of Audit and survives confirmation and reload',
    (tester) async {
      final course = _course();
      await service.saveUserCourse(course);
      expect(
        _concerns(CourseAuditService().auditLesson(course, _lessonId)),
        isEmpty,
      );
      await _openLesson(tester, course, service);
      _expectBranches(tester, draft: false, guidebookConcern: false);

      await _openGuidebook(tester);
      await _saveGuidebook(tester, draft: true);
      _expectBranches(tester, draft: true, guidebookConcern: false);
      // Nested saves still belong to the one Course working-copy transaction.
      expect(
        (await service.listUserCourses())
            .single
            .lessons
            .single
            .guidebook
            .publicationState,
        PublicationState.published,
      );
      await _openGuidebook(tester);
      final draftGuidebook = tester
          .widget<GuidebookEditorScreen>(find.byType(GuidebookEditorScreen))
          .guidebook;
      expect(draftGuidebook.publicationState, PublicationState.draft);
      expect(draftGuidebook.toJson()['publicationState'], 'draft');
      await _back(tester);
      await _confirmCourse(tester);

      final drafted = (await service.listUserCourses()).single;
      expect(
        drafted.lessons.single.guidebook.publicationState,
        PublicationState.draft,
      );
      expect(
        _concerns(CourseAuditService().auditLesson(drafted, _lessonId)),
        isEmpty,
      );
      await _openLesson(tester, drafted, service);
      _expectBranches(tester, draft: true, guidebookConcern: false);
      await _openGuidebook(tester);
      await _saveGuidebook(tester, draft: false);
      _expectBranches(tester, draft: false, guidebookConcern: false);
      await _confirmCourse(tester);

      final published = (await service.listUserCourses()).single;
      expect(
        published.lessons.single.guidebook.publicationState,
        PublicationState.published,
      );
      expect(
        Guidebook.fromJson(
          published.lessons.single.guidebook.toJson(),
        ).publicationState,
        PublicationState.published,
      );
      await _openLesson(tester, published, service);
      _expectBranches(tester, draft: false, guidebookConcern: false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty Guidebook saved as Draft is red and blue through Lesson and Lessons while Rounds stays green',
    (tester) async {
      final course = _course();
      await service.saveUserCourse(course);
      await _openLesson(tester, course, service);
      await _openGuidebook(tester);
      await tester.enterText(_field('Overview'), '');
      await _saveGuidebook(tester, draft: true);
      _expectBranches(tester, draft: true, guidebookConcern: true);
      await _confirmCourse(tester);

      final reloaded = (await service.listUserCourses()).single;
      final guidebook = reloaded.lessons.single.guidebook;
      expect(guidebook.content, isEmpty);
      expect(guidebook.publicationState, PublicationState.draft);
      expect(guidebook.toJson()['publicationState'], 'draft');
      final findings = _concerns(
        CourseAuditService().auditLesson(reloaded, _lessonId),
      );
      expect(findings.map((issue) => issue.code), ['LESSON_GUIDEBOOK_EMPTY']);
      await _openLesson(tester, reloaded, service);
      _expectBranches(tester, draft: true, guidebookConcern: true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guidebook source-reference Error reaches its ancestors without coloring the Rounds branch',
    (tester) async {
      final course = _course(missingGuidebookSource: true);
      final audit = CourseAuditService();
      final findings = _concerns(audit.auditLesson(course, _lessonId));
      expect(findings.map((issue) => issue.code), ['SOURCE_REF_MISSING']);
      expect(findings.single.roundId, isNull);
      expect(
        _concerns(audit.auditRound(course, 'guidebook-status-round')),
        isEmpty,
      );
      await service.saveUserCourse(course);
      await _openLesson(tester, course, service);
      _expectBranches(tester, draft: false, guidebookConcern: true);
      await _openGuidebook(tester);
      await _saveGuidebook(tester, draft: true);
      _expectBranches(tester, draft: true, guidebookConcern: true);
      await _openGuidebook(tester);
      final retained = tester
          .widget<GuidebookEditorScreen>(find.byType(GuidebookEditorScreen))
          .guidebook;
      expect(retained.content.single.sourceRefs, ['missing-guidebook-source']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Published Lesson can be saved while its Round retains provenance to a Draft Guidebook',
    (tester) async {
      final course = _courseWithPublishedGuidebookRefs();
      await service.saveUserCourse(course);
      await _openLesson(tester, course, service);
      await _openGuidebook(tester);
      await _saveGuidebook(tester, draft: true);

      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsNothing);
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(
        find.textContaining('cannot be saved as normal content'),
        findsNothing,
      );
      await _back(tester);
      expect(find.byType(CourseEditorScreen), findsOneWidget);
      await _back(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      for (var attempt = 0; attempt < 100; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(CourseEditorScreen).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();

      final reloaded = (await service.listUserCourses()).single;
      expect(reloaded.lessons.single.publicationState.isPublished, isTrue);
      expect(
        reloaded.lessons.single.guidebook.publicationState,
        PublicationState.draft,
      );
      expect(
        reloaded.lessons.single.rounds.single.content
            .where((content) => content.kind == 'exercise')
            .every(
              (content) =>
                  content.sourceRefs.contains('guidebook-status-overview'),
            ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guidebook save controls fit a 320px layout', (tester) async {
    _viewport(tester, width: 320);
    Guidebook? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Guidebook>(
                  MaterialPageRoute(
                    builder: (_) => GuidebookEditorScreen(
                      guidebook: _course().lessons.single.guidebook,
                    ),
                  ),
                );
              },
              child: const Text('Open Guidebook'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Guidebook'));
    await tester.pumpAndSettle();
    final draft = find.byKey(const Key('guidebook-save-draft'));
    await tester.scrollUntilVisible(
      draft,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.byKey(const Key('guidebook-save')));
    expect(tester.getRect(draft).right, lessThanOrEqualTo(320));
    expect(
      tester.getRect(find.byKey(const Key('guidebook-save'))).right,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(draft);
    await tester.pumpAndSettle();
    expect(saved!.publicationState, PublicationState.draft);
  });
}

Future<void> _openLesson(
  WidgetTester tester,
  Course course,
  CourseEditorService service,
) async {
  _viewport(tester);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CourseEditorScreen(
                  course: course,
                  userCourse: true,
                  editorService: service,
                ),
              ),
            ),
            child: const Text('Open editor'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
  await tester.pumpAndSettle();
  final lock = find.byKey(const Key('lesson-management-lock'));
  if (tester.widget<SwitchListTile>(lock).value) {
    await tester.tap(lock);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Lesson 1: Guidebook status Lesson'));
  await tester.pumpAndSettle();
}

Future<void> _openGuidebook(WidgetTester tester) async {
  final link = find.byKey(const Key('lesson-guidebook-navigation'));
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
  expect(find.byType(GuidebookEditorScreen), findsOneWidget);
}

Future<void> _saveGuidebook(WidgetTester tester, {required bool draft}) async {
  final save = find.byKey(
    Key(draft ? 'guidebook-save-draft' : 'guidebook-save'),
  );
  await tester.scrollUntilVisible(
    save,
    350,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(save);
  await tester.pumpAndSettle();
  expect(find.byType(LessonEditorScreen), findsOneWidget);
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

Future<void> _confirmCourse(WidgetTester tester) async {
  await _back(tester);
  expect(find.byType(LessonManagementScreen), findsOneWidget);
  await _back(tester);
  expect(find.byType(CourseEditorScreen), findsOneWidget);
  await _back(tester);
  expect(
    find.byKey(const Key('course-transaction-confirmation')),
    findsOneWidget,
  );
  await tester.tap(find.byKey(const Key('confirm-course-changes')));
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CourseEditorScreen).evaluate().isEmpty) break;
  }
  expect(find.byType(CourseEditorScreen), findsNothing);
  await tester.pumpAndSettle();
}

void _expectBranches(
  WidgetTester tester, {
  required bool draft,
  required bool guidebookConcern,
}) {
  for (final pair in const [
    ('lesson-guidebook-status-indicator', 'lesson-guidebook-draft-indicator'),
    (
      'lesson-status-indicator-guidebook-status-lesson',
      'lesson-draft-indicator-guidebook-status-lesson',
    ),
    ('course-lessons-status-indicator', 'course-lessons-draft-indicator'),
  ]) {
    _expectIndicator(
      tester,
      pair.$1,
      pair.$2,
      draft: draft,
      concern: guidebookConcern,
    );
  }
  _expectIndicator(
    tester,
    'lesson-rounds-status-indicator',
    'lesson-rounds-draft-indicator',
    draft: false,
    concern: false,
  );
}

void _expectIndicator(
  WidgetTester tester,
  String statusKey,
  String draftKey, {
  required bool draft,
  required bool concern,
}) {
  final status = find.byWidgetPredicate(
    (widget) =>
        widget is AuthoringStatusCard &&
        widget.indicatorKey == ValueKey(statusKey),
    skipOffstage: false,
  );
  expect(status, findsOneWidget, reason: statusKey);
  final statusWidget = tester.widget<AuthoringStatusCard>(status);
  expect(statusWidget.hasAuditConcern, concern, reason: statusKey);
  expect(statusWidget.hasDraft, draft, reason: draftKey);
  expect(
    find.byKey(ValueKey(draftKey), skipOffstage: false),
    draft ? findsOneWidget : findsNothing,
    reason: draftKey,
  );
}

Iterable<CourseAuditIssue> _concerns(CourseAuditResult result) =>
    result.issues.where(
      (issue) =>
          issue.severity == AuditSeverity.error ||
          issue.severity == AuditSeverity.warning,
    );

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void _viewport(WidgetTester tester, {double width = 1000}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Course _course({bool missingGuidebookSource = false}) => Course(
  courseId: 'guidebook-status-course',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Guidebook status Course',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: _lessonId,
      publicationState: PublicationState.published,
      title: 'Guidebook status Lesson',
      guidebook: Guidebook(
        publicationState: PublicationState.published,
        content: [
          LearningContent(
            id: 'guidebook-status-overview',
            publicationState: PublicationState.published,
            kind: 'explanation',
            role: 'overview',
            text: 'A reviewed Lesson overview.',
            sourceRefs: [
              if (missingGuidebookSource) 'missing-guidebook-source',
            ],
          ),
        ],
      ),
      rounds: [
        LearningRound(
          id: 'guidebook-status-round',
          publicationState: PublicationState.published,
          title: 'Reviewed Round',
          content: [
            LearningContent.textual(
              id: 'guidebook-status-intro',
              kind: 'text',
              role: 'lesson_intro',
              text: 'A short introduction.',
            ),
            for (var index = 1; index <= 3; index++)
              LearningContent.fromExercise(
                Exercise(
                  id: 'guidebook-status-exercise-$index',
                  publicationState: PublicationState.published,
                  updatedAt: DateTime.utc(2026, 9, 6),
                  type: 'gap_choice',
                  prompt: 'Complete sentence $index.',
                  question: 'La ___ casa è qui $index.',
                  answers: const ['mia', 'tua'],
                  correct: 0,
                  tts: null,
                  accepted: const [],
                  tokens: const [],
                  orderAnswer: const [],
                  pairs: const [],
                  hint: '',
                  icons: const [],
                ),
              ),
          ],
        ),
      ],
    ),
  ],
);

Course _courseWithPublishedGuidebookRefs() {
  final json = _course().toJson();
  final lesson = (json['lessons'] as List).single as Map;
  final round = (lesson['rounds'] as List).single as Map;
  for (final content in (round['content'] as List).whereType<Map>()) {
    if (content['kind'] == 'exercise') {
      content['sourceRefs'] = ['guidebook-status-overview'];
    }
  }
  return Course.fromJson(json);
}

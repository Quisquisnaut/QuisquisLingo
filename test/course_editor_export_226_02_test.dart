import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the Course Editor offers no export of the working copy', (
    tester,
  ) async {
    // Export left the Editor: it ran on the unconfirmed working copy, so a
    // cancelled session could produce a package of a Course that exists
    // nowhere. Course Manager exports the stored Course instead.
    _viewport(tester);
    for (final course in [_customCourse(), _customCourse(fork: true)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: course, userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-editor-export-json')), findsNothing);
      expect(find.byKey(const Key('course-editor-save-json-to')), findsNothing);
      expect(find.text('Quick Export'), findsNothing);
      expect(
        find.byKey(const Key('course-editor-copy-as-new-course')),
        findsNothing,
        reason: 'Copy as New Course copied the working copy for the same '
            'reason and also moved to Course Manager.',
      );
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    }
  });

  for (final origin in [
    CourseOriginType.bundledOfficial,
    CourseOriginType.externalOfficial,
  ]) {
    testWidgets('${origin.name} has no Course-page export or overflow menu', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: _officialCourse(origin))),
      );
      await tester.pump();
      expect(find.byKey(const Key('course-editor-export-json')), findsNothing);
      expect(find.text('Quick Export'), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  }

  testWidgets(
    'custom course outside the local authoring path has no export entry',
    (tester) async {
      _viewport(tester);
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: _customCourse())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-editor-export-json')), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    },
  );
}


void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Course _customCourse({bool fork = false}) => Course(
  courseId: fork ? 'custom-fork' : 'custom-course',
  originType: CourseOriginType.custom,
  originalCourseCreator: fork
      ? const CourseProvenanceIdentity.publisher(
          publisherId: 'publisher-id',
          displayName: 'Publisher',
        )
      : const CourseProvenanceIdentity.qqlUser(
          profileId: '11111111-1111-4111-8111-111111111111',
          displayName: 'Course creator',
        ),
  maintainer: const CourseMaintainer('11111111-1111-4111-8111-111111111111'),
  originalCreatedAtUtc: '2026-09-01T10:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: fork ? 'Licensed fork' : 'Custom course',
  ttsLanguage: 'it-IT',
  courseVersion: '4',
  license: 'CC BY 4.0',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  forkProvenance: fork
      ? CourseForkProvenance(
          sourceCourseId: 'official-id',
          sourceCourseTitle: 'Official course',
          sourceCourseVersion: '12',
          sourceOriginType: CourseOriginType.bundledOfficial,
          sourcePublisherId: 'publisher-id',
          sourcePublisherName: 'Publisher',
          sourceOfficialChecksum:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          sourceAuthors: const [
            CourseAuthor(name: 'Original author', roles: ['Author']),
          ],
          forkCreatedByProfileId: '11111111-1111-4111-8111-111111111111',
          forkCreatedByDisplayName: 'Fork creator',
          forkCreatedAtUtc: '2026-09-05T10:00:00.000Z',
        )
      : null,
  lessons: const [],
);

Course _officialCourse(CourseOriginType origin) => Course(
  courseId: '${origin.name}-course',
  originType: origin,
  publisherId: 'publisher-id',
  publisherName: origin == CourseOriginType.externalOfficial
      ? 'External team'
      : 'QuisquisLingo',
  officialCourseVersion: '12',
  officialReleaseDateUtc: '2026-09-05T10:00:00.000Z',
  officialChecksum:
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  distributionChannel: origin == CourseOriginType.externalOfficial
      ? 'external'
      : 'bundled',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Official course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

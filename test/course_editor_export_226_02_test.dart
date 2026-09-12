import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'custom export is the final page entry and uses existing service',
    (tester) async {
      _viewport(tester);
      final course = _customCourse();
      final transfer = _RecordingTransfer();
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: course,
            userCourse: true,
            transferService: transfer,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final export = find.byKey(const Key('course-editor-export-json'));
      await tester.scrollUntilVisible(
        export,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(export, findsOneWidget);
      expect(find.text('Export Course JSON'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNothing);

      final list = tester.widget<ListView>(find.byType(ListView));
      final children =
          (list.childrenDelegate as SliverChildListDelegate).children;
      expect(children.last.key, const Key('course-editor-export-json'));

      await tester.tap(export);
      await tester.pump();
      expect(transfer.exported?.toJson(), equals(course.toJson()));
      expect(find.textContaining('Exported “Custom course”'), findsOneWidget);
    },
  );

  testWidgets('licensed custom fork exports with provenance unchanged', (
    tester,
  ) async {
    _viewport(tester);
    final course = _customCourse(fork: true);
    final before = course.toJson();
    final transfer = _RecordingTransfer();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          userCourse: true,
          transferService: transfer,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final export = find.byKey(const Key('course-editor-export-json'));
    await tester.scrollUntilVisible(
      export,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(export);
    await tester.pump();
    expect(transfer.exported?.toJson(), before);
    expect(transfer.exported?.forkProvenance?.sourceCourseId, 'official-id');
    expect(transfer.exported?.originType, CourseOriginType.custom);
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
      expect(find.text('Export Course JSON'), findsNothing);
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

class _RecordingTransfer extends CustomCourseTransferService {
  Course? exported;

  @override
  Future<String> exportCourse(Course course) async {
    exported = course;
    return r'C:\Exports\custom_course.json';
  }
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

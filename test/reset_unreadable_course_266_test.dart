import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/device_administration_screen.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner report of 8 October 2026: the reset buttons of Advanced (Admin) did
/// nothing. Since Build 266 a stored Course whose GuideBook has the earlier
/// shape cannot be opened (`Guidebook.earlierShapeMessage`); the reset
/// preview parsed every stored Course and stopped at it, and the button had
/// no error handling. Such a Course is now skipped like an unreadable file,
/// and a preview that fails is reported instead of ignored.

const _admin = '11111111-1111-4111-8111-111111111111';
const _learner = '22222222-2222-4222-8222-222222222222';

Course _course(String id, String maintainer) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-10-01T09:00:00.000Z',
  courseVersion: '1',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      updatedAt: DateTime.utc(2026, 10, 1),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

class _FailingPreview extends AppResetService {
  _FailingPreview({super.profiles});

  @override
  Future<AppResetPreview> preview() async =>
      throw const FileSystemException('the folder is locked');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory support;
  late ProfileService profiles;
  late AppResetService reset;

  /// Stores a readable Course maintained by the learner and one whose
  /// GuideBook has the shape before Build 266, written as an earlier build
  /// left it.
  Future<File> storeCourses() async {
    final editor = CourseEditorService(
      courseStore: CourseFileStore(supportDirectory: () async => support),
      clock: () => DateTime.utc(2026, 10, 8, 9),
    );
    await profiles.setActiveProfileById(_learner);
    await editor.installImportedCustomCourse(_course('readable', _learner));
    await editor.installImportedCustomCourse(_course('earlier', _learner));
    await profiles.setActiveProfileById(_admin);
    final store = CourseFileStore(supportDirectory: () async => support);
    final folder = await store.directoryFor(CourseStoreKind.custom);
    final file = (await folder.list().toList()).whereType<File>().firstWhere(
      (file) => file.path.contains('earlier'),
    );
    final record = jsonDecode(await file.readAsString()) as Map;
    final lesson =
        ((record['entry'] as Map)['course'] as Map)['lessons'][0] as Map;
    lesson['guidebook'] = {'content': <Object>[], 'insights': <Object>[]};
    await file.writeAsString(jsonEncode(record));
    return file;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_reset_266_');
    support = Directory('${root.path}/support');
    await support.create();
    profiles = ProfileService();
    for (final (id, name) in [(_admin, 'Admin'), (_learner, 'Learner')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_admin);
    reset = AppResetService(
      profiles: profiles,
      documentsDirectory: () async => Directory('${root.path}/docs'),
      supportDirectory: () async => support,
    );
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  test('the earlier GuideBook shape no longer stops the preview', () async {
    await storeCourses();
    final preview = await reset.preview();
    expect(preview.hasCustomCourses, isTrue);
    // Revision 2: a Course this version cannot open counts by the
    // Maintainer its JSON names, so the learner is not removed with it.
    expect(preview.coursesMaintainedByNonAdmins, [
      '“Course readable”',
      '“Course earlier” (which this version cannot open)',
    ]);
  });

  test('Remove custom courses removes the unreadable one too', () async {
    final earlier = await storeCourses();
    await profiles.setOwnAccessPin(actorProfileId: _admin, pin: '4321');
    await reset.reset(
      AppResetScope.customCourses,
      actorProfileId: _admin,
      pin: '4321',
    );
    expect(await earlier.exists(), isFalse);
    expect((await reset.preview()).hasCustomCourses, isFalse);
  });

  group('the Advanced (Admin) page', () {
    final shown = _course('shown', _admin);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
      }
      await tester.pumpAndSettle();
    }

    Future<void> open(WidgetTester tester, AppResetService service) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceAdministrationScreen(
            course: shown,
            onManageLearners: (_) async {},
            profileService: profiles,
            resetService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a reset button opens its explanation', (tester) async {
      await tester.runAsync(storeCourses);
      await profiles.setOwnAccessPin(actorProfileId: _admin, pin: '4321');
      await open(tester, reset);
      final button = find.byKey(const Key('admin-reset-button-customCourses'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await settle(tester);
      await settle(tester);
      expect(find.byKey(const Key('admin-reset-continue')), findsOneWidget);
    });

    testWidgets('a preview that fails is reported, not ignored', (
      tester,
    ) async {
      await profiles.setOwnAccessPin(actorProfileId: _admin, pin: '4321');
      await open(tester, _FailingPreview(profiles: profiles));
      final button = find.byKey(
        const Key('admin-reset-button-learnerProgress'),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await settle(tester);
      expect(
        find.byKey(const Key('admin-reset-preview-error')),
        findsOneWidget,
      );
      expect(find.textContaining('the folder is locked'), findsOneWidget);
      expect(find.byKey(const Key('admin-reset-continue')), findsNothing);
    });
  });
}

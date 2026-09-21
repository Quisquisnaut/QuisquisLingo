import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_presentation.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_artwork.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';

class _DeviceCourses extends CourseEditorService {
  final List<Course> courses;
  _DeviceCourses(this.courses);
  @override
  Future<List<Course>> listUserCourses() async => courses;
}

Course _course({
  String id = 'user_rows',
  String title = 'Row Course',
  CourseOriginType origin = CourseOriginType.custom,
  String courseVersion = '',
  String officialVersion = '',
  String? modifiedAtUtc,
  int? hours,
  String cover = '',
  PublicationState state = PublicationState.published,
}) => Course(
  courseId: id,
  originType: origin,
  officialCourseVersion: officialVersion,
  courseVersion: courseVersion,
  modifiedAtUtc: modifiedAtUtc,
  estimatedStudyHours: hours,
  coverImage: cover,
  publicationState: state,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  lessons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('display values', () {
    test(
      'Custom Courses show courseVersion, official ones their release',
      () async {
        expect(
          CourseLibraryPresentation.version(_course(courseVersion: '4')),
          '4',
        );
        expect(CourseLibraryPresentation.version(_course()), isNull);
        final bundled = await CourseService().loadCourse('IT');
        expect(bundled.officialCourseVersion, isNotEmpty);
        expect(
          CourseLibraryPresentation.version(bundled),
          bundled.officialCourseVersion,
        );
        final publisher = Course.fromJson(
          jsonDecode(
                await File(
                  'test/fixtures/publishers/dummy-signed-v1.json',
                ).readAsString(),
              )
              as Map<String, dynamic>,
        );
        expect(
          CourseLibraryPresentation.version(publisher),
          publisher.officialCourseVersion,
        );
      },
    );

    test('last edited parses the UTC instant or reports it unknown', () {
      expect(
        CourseLibraryPresentation.lastEdited(
          _course(modifiedAtUtc: '2026-09-20T08:30:00.000Z'),
        ),
        DateTime.utc(2026, 9, 20, 8, 30),
      );
      // The model refuses malformed timestamps; the parser stays defensive.
      expect(CourseLibraryPresentation.parseUtcInstant('soon'), isNull);
      expect(CourseLibraryPresentation.parseUtcInstant(''), isNull);
    });

    test('duration uses the declared hours only', () {
      expect(CourseLibraryPresentation.duration(_course(hours: 1)), '1 hour');
      expect(
        CourseLibraryPresentation.duration(_course(hours: 12)),
        '12 hours',
      );
      expect(CourseLibraryPresentation.duration(_course()), isNull);
    });
  });

  group('rows', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      await ProfileService().setActiveProfileById(_alice);
    });

    Future<void> pumpRows(
      WidgetTester tester,
      List<Course> courses, {
      Size size = const Size(800, 4000),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AvailableCoursesScreen(editorService: _DeviceCourses(courses)),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Bundled Courses').evaluate().isNotEmpty,
      );
    }

    Finder inRow(Course course, Finder matching) => find.descendant(
      of: find.byKey(ValueKey('device-course-${course.courseId}')),
      matching: matching,
    );

    testWidgets('expanded row shows every available field in order', (
      tester,
    ) async {
      final full = _course(
        courseVersion: '4',
        modifiedAtUtc: '2026-09-20T12:00:00.000Z',
        hours: 12,
      );
      await pumpRows(tester, [full]);
      final lines = [
        'English → Italian',
        'Version: 4',
        'Last edited: Sep 20, 2026',
        'Maintainer: ',
        'Duration: 12 hours',
      ];
      final tops = [
        for (final line in lines)
          tester.getTopLeft(inRow(full, find.textContaining(line))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(
        tester.getTopLeft(inRow(full, find.text(full.title))).dy,
        lessThan(tops.first),
      );
    });

    testWidgets('absent version and duration are omitted', (tester) async {
      final sparse = _course();
      await pumpRows(tester, [sparse]);
      expect(inRow(sparse, find.textContaining('Version:')), findsNothing);
      expect(inRow(sparse, find.textContaining('Duration:')), findsNothing);
      expect(
        inRow(sparse, find.textContaining('Last edited: ')),
        findsOneWidget,
      );
    });

    Future<String> storeCover(Uint8List bytes, String courseId) async =>
        CourseMediaStore().addBytes(courseId, bytes, 'png');

    testWidgets('a readable cover replaces the flag with a bounded decode', (
      tester,
    ) async {
      final bytes = await tester.runAsync(
        () => File('test/fixtures/import/valid_cover.png').readAsBytes(),
      );
      final reference = (await tester.runAsync(
        () => storeCover(bytes!, 'user_cover'),
      ))!;
      final covered = _course(id: 'user_cover', cover: reference);
      await pumpRows(tester, [covered]);
      await tester.pumpUntilFileIoState(
        () => inRow(covered, find.byType(Image)).evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const ValueKey('course-artwork-flag-user_cover')),
        findsNothing,
      );
      final image = tester.widget<Image>(inRow(covered, find.byType(Image)));
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, lessThanOrEqualTo(64 * 3));
      expect(
        tester.getSize(find.byKey(const ValueKey('course-artwork-user_cover'))),
        const Size(64, 64),
      );
    });

    testWidgets('no cover, a missing file or unreadable bytes show the flag', (
      tester,
    ) async {
      final garbage = (await tester.runAsync(
        () => storeCover(
          Uint8List.fromList(List.generate(200, (i) => i)),
          'user_broken',
        ),
      ))!;
      final plain = _course(id: 'user_plain', title: 'A plain');
      final missing = _course(
        id: 'user_missing',
        title: 'B missing',
        cover: 'media:${'a' * 64}.png',
      );
      final broken = _course(
        id: 'user_broken',
        title: 'C broken',
        cover: garbage,
      );
      await pumpRows(tester, [plain, missing, broken]);
      for (final course in [plain, missing, broken]) {
        await tester.pumpUntilFileIoState(
          () => find
              .byKey(ValueKey('course-artwork-flag-${course.courseId}'))
              .evaluate()
              .isNotEmpty,
        );
        expect(
          tester.getSize(
            find.byKey(ValueKey('course-artwork-${course.courseId}')),
          ),
          const Size(64, 64),
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow rows with every label do not overflow', (tester) async {
      final crowded = _course(
        id: 'user_crowded',
        title:
            'A very long Course title that has to wrap across several lines on a phone',
        courseVersion: '12',
        modifiedAtUtc: '2026-09-20T12:00:00.000Z',
        hours: 1000,
        state: PublicationState.draft,
      );
      await pumpRows(tester, [crowded], size: const Size(320, 8000));
      await tester.tap(find.byKey(const Key('show-unavailable-courses')));
      await tester.pump();
      expect(inRow(crowded, find.text('Unpublished')), findsOneWidget);
      final add = inRow(crowded, find.text('Add to my courses'));
      expect(
        tester.getTopLeft(add).dy,
        greaterThan(
          tester
              .getTopLeft(inRow(crowded, find.text('Duration: 1000 hours')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('CourseArtwork keeps its slot size for any size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: CourseArtwork(course: _course(), size: 40)),
      ),
    );
    expect(tester.getSize(find.byType(CourseArtwork)), const Size(40, 40));
  });
}

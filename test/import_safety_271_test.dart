import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_import_refusals.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/image_validator.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/stored_course_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unique_png.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
final _when = DateTime.utc(2026, 10, 12, 9);

Course _course(
  String id, {
  String maintainer = _alice,
  bool private = false,
  String? title,
  List<String> images = const [],
  bool noSourceLanguage = false,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-10-12T09:00:00.000Z',
  courseVersion: '1',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  temporarySample: private,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  // Without a source language the Audit has an Error.
  sourceLanguage: noSourceLanguage ? '' : 'English',
  targetLanguage: 'Italian',
  title: title ?? 'Course $id',
  ttsLanguage: 'it-IT',
  imageLibrary: [
    for (final image in images) CourseImageLibraryEntry(asset: image),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      updatedAt: DateTime.utc(2026, 10, 12),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

/// A PNG whose parts are all in place and checked, with picture data that
/// is not a picture: the structure passes, no device can draw it.
Uint8List _undrawablePng() {
  Uint8List chunk(String type, List<int> data) {
    final body = Uint8List.fromList([...type.codeUnits, ...data]);
    final out = ByteData(12 + data.length);
    out.setUint32(0, data.length);
    final bytes = out.buffer.asUint8List()..setAll(4, body);
    out.setUint32(8 + data.length, getCrc32(body));
    return bytes;
  }

  final header = ByteData(13)
    ..setUint32(0, 4)
    ..setUint32(4, 4)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    ...chunk('IHDR', header.buffer.asUint8List()),
    ...chunk('IDAT', List.filled(48, 0x5a)),
    ...chunk('IEND', const []),
  ]);
}

// Build 271 Revision 4: an import checks what it brings in. Pictures from
// packages and Image Banks are decoded once; every import action refuses
// what the screen refuses; the dialog about a Course ID already in use
// never names someone else's Private course; official versions compare
// their parts as text when they are not numbers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('qql_271_import_');
    final profiles = ProfileService();
    for (final (id, name) in [(_alice, 'Alice'), (_bob, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_alice);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  group('pictures are decoded once at import', () {
    test('the fixture: its structure passes, drawing it does not', () async {
      final bytes = _undrawablePng();
      expect(
        ImageValidator.inspect(bytes, ImageProfile.exerciseImage).width,
        4,
      );
      await expectLater(
        ImageValidator.validate(bytes, ImageProfile.exerciseImage),
        throwsA(isA<ImageValidationException>()),
      );
      // A real picture passes both.
      final good = await ImageValidator.validate(
        uniquePng(1),
        ImageProfile.exerciseImage,
      );
      expect(good.width, 4);
    });

    test('a Course package with a picture no device can draw is refused by '
        'name; with real pictures it is read', () async {
      final media = CourseMediaStore(supportDirectory: () async => temp);
      final packages = CoursePackageService(mediaStore: media);
      Future<CoursePackage> roundTrip(Uint8List picture) async {
        final reference = await media.addBytes('package', picture, 'png');
        final course = _course('package', images: [reference]);
        final json = Uint8List.fromList(
          utf8.encode(jsonEncode(course.toJson())),
        );
        return packages.parse(
          await packages.build(course, json),
          (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
        );
      }

      final bad = _undrawablePng();
      await expectLater(
        roundTrip(bad),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains(
                CourseMediaStore.fileNameOf(
                  CourseMediaStore.referenceFor(bad, 'png'),
                ),
              ),
              contains('The image is damaged'),
            ),
          ),
        ),
      );

      final good = await roundTrip(uniquePng(2));
      expect(good.mediaReferences, hasLength(1));
      await good.discard();
    });

    test('an Image Bank with a picture no device can draw is refused by '
        'name; with real pictures it is read', () async {
      Future<ParsedImageBank> read(Uint8List picture) async {
        final manifest = utf8.encode(
          jsonEncode([
            {
              'id': 'thing',
              'primary_term': 'Thing',
              'filename': 'thing.png',
              'keywords': ['thing'],
            },
          ]),
        );
        final archive = Archive()
          ..addFile(
            ArchiveFile('image_bank_manifest.json', manifest.length, manifest),
          )
          ..addFile(ArchiveFile.bytes('thing.png', picture));
        final zip = File('${temp.path}${Platform.pathSeparator}bank.zip');
        await zip.writeAsBytes(ZipEncoder().encode(archive), flush: true);
        return ImageBankService().readBank(zip);
      }

      await expectLater(
        read(_undrawablePng()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Image Bank image thing.png'),
              contains('The image is damaged'),
            ),
          ),
        ),
      );
      expect((await read(uniquePng(3))).images.single.filename, 'thing.png');
    });
  });

  group('every import action refuses what the screen refuses', () {
    late CourseEditorService editor;

    setUp(() => editor = CourseEditorService(clock: () => _when));

    CoursePackageImport attempt(Course course) => CoursePackageImport(
      CoursePackage(course, Uint8List(0), const {}),
      editor: editor,
    );

    Matcher refused(String part) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        contains(part),
      ),
    );

    test('someone else\'s Private course: install, copy and Fork', () async {
      final theirs = _course('theirs', maintainer: _bob, private: true);
      const part = 'is a Private course';

      await expectLater(attempt(theirs).installCustomCourse(), refused(part));
      await expectLater(
        attempt(theirs).copyAsNewCourse(title: 'Mine now'),
        refused(part),
      );
      await expectLater(attempt(theirs).fork(), refused(part));
      expect(await editor.listUserCourses(), isEmpty);

      // Its Maintainer imports it.
      await attempt(_course('mine', private: true)).installCustomCourse();
      expect((await editor.listUserCourses()).single.courseId, 'mine');
    });

    test('a Course whose Audit has errors: install, copy and Fork', () async {
      final broken = _course('broken', noSourceLanguage: true);
      final errors = CourseAuditService()
          .auditCourse(broken)
          .count(AuditSeverity.error);
      expect(errors, greaterThan(0));
      final part = CourseImportRefusals.auditErrors(errors);

      await expectLater(attempt(broken).installCustomCourse(), refused(part));
      await expectLater(
        attempt(broken).copyAsNewCourse(title: 'A copy'),
        refused(part),
      );
      await expectLater(attempt(broken).fork(), refused(part));
      expect(await editor.listUserCourses(), isEmpty);

      // The same Course without the error is imported.
      await attempt(_course('broken')).installCustomCourse();
      expect((await editor.listUserCourses()).single.courseId, 'broken');
    });

    test('a refused attempt has ended: its package is released and it '
        'cannot be used again', () async {
      final refusedAttempt = attempt(_course('broken', noSourceLanguage: true));
      await expectLater(
        refusedAttempt.installCustomCourse(),
        throwsFormatException,
      );
      await expectLater(refusedAttempt.installCustomCourse(), throwsStateError);
    });

    test('the two refusals in words', () {
      expect(
        CourseImportRefusals.privateCourse(_course('x', title: 'Segreto')),
        '“Segreto” is a Private course: only its Course Maintainer and the '
        'members of its assigned Team can import it or use it in a Merge. '
        'Ask its Maintainer for a copy that is not private.',
      );
      expect(
        CourseImportRefusals.auditErrors(2),
        'Course Audit found 2 errors. Fix these errors before importing the '
        'course.',
      );
      // The screen's texts are these.
      expect(
        CourseLibraryReports.importBlocked(1),
        CourseImportRefusals.auditErrors(1),
      );
    });
  });

  group('a Course ID already in use', () {
    late CourseEditorService editor;
    late CourseLibraryOperations ops;

    setUp(() {
      editor = CourseEditorService(clock: () => _when);
      ops = CourseLibraryOperations(
        editor: editor,
        transfer: CustomCourseTransferService(),
        clock: () => _when,
      );
    });

    Future<CourseImportReview> review(Course course) async {
      final library = await ops.load(importOnly: true);
      final attempt = CoursePackageImport(
        CoursePackage(course, Uint8List(0), const {}),
        editor: editor,
      );
      try {
        return await ops.reviewImport(attempt, library);
      } finally {
        await attempt.close();
      }
    }

    test('someone else\'s Private course is "a Private course", never its '
        'title', () async {
      final profiles = ProfileService();
      await profiles.setActiveProfileById(_bob);
      await editor.installImportedCustomCourse(
        _course('shared', maintainer: _bob, private: true, title: 'Segreto'),
      );
      await profiles.setActiveProfileById(_alice);

      // Alice imports an earlier copy that was not private.
      final result = await review(
        _course('shared', maintainer: _bob, title: 'Aperto'),
      );

      expect(result.existing?.title, 'Segreto');
      expect(result.existingHidden, isTrue);
      final text = CourseLibraryReports.matchingCourseId(result);
      expect(
        text,
        'A custom Course with ID “shared” already exists: a Private course. '
        'Replace it, create an available Copy as New Course or Fork, or '
        'cancel?',
      );
      expect(text, isNot(contains('Segreto')));
    });

    test('a Course the learner may see is named', () async {
      await editor.installImportedCustomCourse(
        _course('mine', private: true, title: 'Il mio'),
      );

      final result = await review(_course('mine', title: 'Il mio, di nuovo'));

      expect(result.existingHidden, isFalse);
      expect(
        CourseLibraryReports.matchingCourseId(result),
        'A custom Course with ID “mine” already exists. Replace “Il mio”, '
        'create an available Copy as New Course or Fork, or cancel?',
      );
    });

    test('a stored Course this version cannot open', () {
      CourseImportReview stored(UnopenableStoredCourse course, bool hidden) =>
          CourseImportReview(
            course: _course('old'),
            errors: const [],
            warnings: const [],
            existing: null,
            choices: const [],
            existingUnopenable: course,
            existingHidden: hidden,
          );
      const theirs = UnopenableStoredCourse(
        courseId: 'old',
        reason: 'an earlier GuideBook',
        title: 'Segreto',
        maintainerProfileId: _bob,
        private: true,
      );

      final hidden = CourseLibraryReports.matchingCourseId(
        stored(theirs, true),
      );
      expect(
        hidden,
        'A Private course stored with ID “old” cannot be opened by this '
        'version (an earlier GuideBook). Replace it with the Course you are '
        'importing, create an available Copy as New Course or Fork, or '
        'cancel?',
      );
      expect(hidden, isNot(contains('Segreto')));
      expect(
        CourseLibraryReports.matchingCourseId(stored(theirs, false)),
        'The stored Course “Segreto” with ID “old” cannot be opened by this '
        'version (an earlier GuideBook). Replace it with the Course you are '
        'importing, create an available Copy as New Course or Fork, or '
        'cancel?',
      );
    });
  });

  group('official Course versions', () {
    int compare(String left, String right) =>
        CourseEditorService.compareOfficialVersions(left, right).sign;

    test('whole numbers compare as numbers', () {
      expect(compare('2', '10'), -1);
      expect(compare('1.10', '1.9'), 1);
      expect(compare('1.0', '1'), 0);
      expect(compare('1.02', '1.2'), 0);
      expect(compare('3.0.0', '2.9.9'), 1);
      expect(compare('1.99999999999999999999', '1.100000000000000000000'), -1);
    });

    test('other parts compare as text, not as 0', () {
      // Before, these two were one version and the update was refused.
      expect(compare('1.0.rc', '1.0.beta'), 1);
      expect(compare('1.0.beta', '1.0.rc'), -1);
      expect(compare('1.0.beta', '1.0.beta'), 0);
      expect(compare('2026-10', '2026-09'), 1);
      expect(compare('1.0b', '1.0a'), 1);
      // A part of letters comes after the same place left empty.
      expect(compare('1.0.beta', '1.0'), 1);
      expect(compare(' 1 . 2 ', '1.2'), 0);
    });
  });
}

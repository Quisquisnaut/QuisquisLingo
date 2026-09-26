import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tools/convert_course_to_v11.dart';
import 'support/publisher_fixtures.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '22222222-2222-4222-8222-222222222222';
final _when = DateTime.utc(2026, 9, 21, 9);
final _sha = 'a' * 64;

Map<String, dynamic> _merge() => {
  'leftSourceCourseId': 'older-left',
  'leftSourceCourseVersion': '1',
  'rightSourceCourseId': 'older-right',
  'rightSourceCourseVersion': '2',
  'mergedAtUtc': '2026-09-03T00:00:00.000Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Course Model v11 clean cut', () {
    test('v11 is the only accepted format', () {
      final json = _course().toJson();
      expect(json['formatVersion'], 11);
      expect(Course.fromJson(json).formatVersion, 11);
      for (final old in [9, 10]) {
        expect(
          () => Course.fromJson({...json, 'formatVersion': old}),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(contains('format 11 only'), contains('convert_course')),
            ),
          ),
          reason: 'v$old must be refused, never read',
        );
      }
      expect(() => _course(formatVersion: 10), throwsA(isA<FormatException>()));
    });

    test('merge provenance is optional and custom-only in v11', () {
      final merged = Course.fromJson({
        ..._course().toJson(),
        'mergeProvenance': _merge(),
      });
      expect(merged.formatVersion, 11);
      expect(merged.mergeProvenance!.leftSourceCourseId, 'older-left');
      expect(
        Course.fromJson(merged.toJson()).toJson()['mergeProvenance'],
        merged.toJson()['mergeProvenance'],
      );
      expect(_course().toJson().containsKey('mergeProvenance'), isFalse);
      expect(
        () => Course.fromJson({
          ..._course().toJson(),
          'mergeProvenance': 'not an object',
        }),
        throwsA(isA<FormatException>()),
      );
      final bundled = _bundled('german_en.json');
      expect(
        () => Course.fromJson({...bundled, 'mergeProvenance': _merge()}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('v11 storage clean cut', () {
    late Directory root;
    setUp(() async => root = await Directory.systemTemp.createTemp('qql_v11_'));
    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    File write(String relative, String contents) {
      final file = File(
        '${root.path}${Platform.pathSeparator}'
        '${relative.replaceAll('/', Platform.pathSeparator)}',
      )..createSync(recursive: true);
      file.writeAsStringSync(contents);
      return file;
    }

    test(
      'stored v9 Courses stay on disk and never block the Course list',
      () async {
        final old = write(
          'qql_courses_v1/custom/old.json',
          jsonEncode({
            'courseId': 'old',
            'entry': {..._course().toJson(), 'formatVersion': 9},
          }),
        );
        final store = CourseFileStore(supportDirectory: () async => root);
        expect(CourseFileStore.rootDirectoryName, 'qql_courses_v2');
        expect(await store.readAll(CourseStoreKind.custom), isEmpty);
        expect(await old.exists(), isTrue);
      },
    );

    test(
      'v9 Course Backups stay on disk and never block Version History',
      () async {
        final old = write(
          'QuisquisLingo/Exports/Course Backups v9/v11-course/old.json',
          jsonEncode({
            'format': 'QuisquisLingo Course Backup v9',
            'course': {..._course().toJson(), 'formatVersion': 9},
          }),
        );
        final backups = CourseBackupService(
          supportDirectoryProvider: () async => root,
        );
        expect(
          (await backups.backupRoot()).path,
          endsWith('qql_course_backups_v11'),
        );
        expect(await backups.listBackups('v11-course'), isEmpty);
        expect(await old.exists(), isTrue);
      },
    );
  });

  group('v11 descriptive fields', () {
    test('all fields are omitted when unset', () {
      final json = _course().toJson();
      for (final key in const [
        'minimumAppBuild',
        'publisherContact',
        'estimatedStudyHours',
        'minimumAge',
        'keywords',
        'coverImage',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });

    test('all fields survive a JSON round trip', () {
      final course = _course(
        minimumAppBuild: Course.appBuildNumber,
        publisherContact: CoursePublisherContact(
          websiteUrl: 'https://example.org/courses',
          email: 'errata@example.org',
        ),
        estimatedStudyHours: 40,
        minimumAge: 13,
        keywords: const ['travel', 'Grammar'],
        coverImage: 'media:$_sha.png',
      );
      final restored = Course.fromJson(
        jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
      );
      expect(restored.minimumAppBuild, Course.appBuildNumber);
      expect(
        restored.publisherContact!.websiteUrl,
        'https://example.org/courses',
      );
      expect(restored.publisherContact!.email, 'errata@example.org');
      expect(restored.estimatedStudyHours, 40);
      expect(restored.minimumAge, 13);
      expect(restored.keywords, ['travel', 'Grammar']);
      expect(restored.coverImage, 'media:$_sha.png');
      expect(restored.toJson(), course.toJson());
    });

    test('a Course needing a newer build is refused with guidance', () {
      final json = _course().toJson();
      expect(
        () => Course.fromJson({
          ...json,
          'minimumAppBuild': Course.appBuildNumber + 1,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Update QuisquisLingo'),
          ),
        ),
      );
      expect(
        Course.fromJson({
          ...json,
          'minimumAppBuild': Course.appBuildNumber,
        }).minimumAppBuild,
        Course.appBuildNumber,
      );
      expect(
        () => Course.fromJson({...json, 'minimumAppBuild': 0}),
        throwsA(isA<FormatException>()),
      );
    });

    test('invalid values are rejected, not ignored', () {
      final json = _course().toJson();
      void rejects(Map<String, Object?> patch, String reason) => expect(
        () => Course.fromJson({...json, ...patch}),
        throwsA(isA<FormatException>()),
        reason: reason,
      );

      rejects({'minimumAppBuild': '243000'}, 'build as text');
      rejects({'estimatedStudyHours': 0}, 'zero hours');
      rejects({'estimatedStudyHours': 1001}, 'too many hours');
      rejects({'estimatedStudyHours': 2.5}, 'fractional hours');
      rejects({'minimumAge': 5}, 'not an App Store class');
      rejects({'minimumAge': '13'}, 'age as text');
      rejects({
        'keywords': [for (var i = 0; i <= 20; i++) 'k$i'],
      }, '21 keywords');
      rejects({
        'keywords': ['a' * 33],
      }, 'keyword too long');
      rejects({
        'keywords': ['Travel', 'travel'],
      }, 'case-insensitive duplicate');
      rejects({
        'keywords': [' padded'],
      }, 'untrimmed keyword');
      rejects({
        'keywords': [''],
      }, 'blank keyword');
      rejects({'keywords': 'travel'}, 'keywords not a list');
      rejects({'coverImage': 'C:/pictures/cover.png'}, 'cover path');
      rejects({'coverImage': 'media:$_sha.gif'}, 'cover format');
      rejects({'coverImage': 'media:${'A' * 64}.png'}, 'uppercase digest');
      rejects({'publisherContact': 'https://example.org'}, 'contact shape');
      rejects({'publisherContact': <String, Object>{}}, 'empty contact');
      rejects({
        'publisherContact': {'websiteUrl': 'http://example.org'},
      }, 'insecure website');
      rejects({
        'publisherContact': {'email': 'not-an-address'},
      }, 'bad email');
      for (final age in Course.minimumAgeClasses) {
        expect(Course.fromJson({...json, 'minimumAge': age}).minimumAge, age);
      }
    });

    test('keyword normalisation trims, drops blanks and duplicates', () {
      expect(
        Course.normalizeKeywords([' Travel ', '', 'travel', 'food ', '  ']),
        ['Travel', 'food'],
      );
      expect(CoursePublisherContact.fromFields('  ', ''), isNull);
    });
  });

  group('v11 fields travel with derived Courses', () {
    final rich = _course(
      minimumAppBuild: Course.appBuildNumber,
      publisherContact: CoursePublisherContact(email: 'a@example.org'),
      estimatedStudyHours: 12,
      minimumAge: 9,
      keywords: const ['food'],
      coverImage: 'media:$_sha.webp',
      derivative: DerivativeWorksPolicy.allowed,
    );

    void expectCarried(Course copy) {
      expect(copy.minimumAppBuild, rich.minimumAppBuild);
      expect(copy.publisherContact!.email, 'a@example.org');
      expect(copy.estimatedStudyHours, 12);
      expect(copy.minimumAge, 9);
      expect(copy.keywords, ['food']);
      expect(copy.coverImage, 'media:$_sha.webp');
    }

    test('Copy as New Course and Fork', () {
      final service = AuthoringDuplicationService();
      expectCarried(
        service.copyCourseAsNew(
          rich,
          title: 'Copy',
          originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
            profileId: _otherProfileId,
            displayName: 'Copier',
          ),
          maintainer: const CourseMaintainer(_otherProfileId),
        ),
      );
      expectCarried(
        service.forkCustomCourse(
          rich,
          provenance: CourseForkProvenance(
            sourceCourseId: rich.courseId,
            sourceCourseTitle: rich.title,
            sourceCourseVersion: rich.courseVersion,
            sourceOriginType: rich.originType,
            forkCreatedByProfileId: _otherProfileId,
            forkCreatedByDisplayName: 'Forker',
            forkCreatedAtUtc: '2026-09-21T09:00:00.000Z',
          ),
          maintainer: const CourseMaintainer(_otherProfileId),
        ),
      );
    });

    test('in-Course moves keep the fields and merge provenance', () {
      final merged = Course.fromJson({
        ...rich.toJson(),
        'mergeProvenance': _merge(),
      });
      final moved = CourseAuthoringTransferService(clock: () => _when)
          .copyRound(
            merged,
            sourceLessonId: 'lesson-1',
            roundId: 'round-1',
            destinationLessonId: 'lesson-1',
          );
      expectCarried(moved);
      expect(moved.mergeProvenance, isNotNull);
    });

    test('differing descriptive metadata never blocks a merge', () {
      final left = _course(
        id: 'course-left',
        keywords: const ['left'],
        minimumAge: 4,
      );
      final right = _course(
        id: 'course-right',
        keywords: const ['right'],
        minimumAge: 16,
        minimumAppBuild: Course.appBuildNumber,
      );
      expect(
        () => CourseMergeService().validateCompatibility(left, right),
        returnsNormally,
        reason: 'descriptive metadata never blocks a merge',
      );
    });

    test('a merge keeps left values and the higher minimum build', () async {
      SharedPreferences.setMockInitialValues({});
      final profiles = ProfileService();
      await profiles.createProfile(
        'Merge Author',
        learnerProfileId: _profileId,
      );
      final left = _course(
        id: 'course-left',
        keywords: const ['left'],
        minimumAge: 4,
      );
      final right = _course(
        id: 'course-right',
        keywords: const ['right'],
        minimumAge: 16,
        minimumAppBuild: Course.appBuildNumber,
      );
      final merged =
          await CourseMergeService(
            profileService: profiles,
            clock: () => _when,
          ).createMergedCourse(
            left: left,
            right: right,
            choices: const [LessonMergeChoice.left],
            options: CourseMergeOptions.fromCourse(left),
          );
      expect(merged.formatVersion, 11);
      expect(merged.mergeProvenance, isNotNull);
      expect(merged.keywords, ['left']);
      expect(merged.minimumAge, 4);
      expect(merged.minimumAppBuild, Course.appBuildNumber);
    });
  });

  group('bundled and fixture Courses are v11', () {
    const bundledIds = {
      'english_es.json': 'sample_en_es_en',
      'german_en.json': 'sample_de_en_de',
      'korean_en.json': 'sample_ko_en_ko',
      'neapolitan_it.json': 'sample_nap_it_nap',
      'portuguese_en.json': 'sample_pt_en_pt',
      'spanish_en.json': 'sample_es_en_es',
      'welsh_en.json': 'sample_cy_en_cy',
    };

    test('bundled Courses keep the Course IDs learner progress uses', () {
      for (final entry in bundledIds.entries) {
        final json = _bundled(entry.key);
        final course = Course.fromJson(json);
        expect(course.formatVersion, 11, reason: entry.key);
        expect(course.courseId, entry.value, reason: entry.key);
        expect(
          course.officialChecksum,
          CourseChecksums.official(course),
          reason: entry.key,
        );
      }
    });

    test('Dummy fixtures verify, and tampering is refused', () async {
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      for (final name in const [
        'dummy-signed-v1.json',
        'dummy-signed-v2.json',
      ]) {
        final course = Course.fromJson(_fixture(name));
        expect(course.formatVersion, 11);
        final verified = await verifier.requireVerified(course);
        expect(
          verified.publisherVerificationStatus,
          PublisherVerificationStatus.verified,
          reason: name,
        );
        final tampered = Course.fromJson({
          ...course.toJson(),
          'title': 'Changed after signing',
        });
        await expectLater(
          verifier.requireVerified(tampered),
          throwsA(anything),
          reason: '$name must refuse a changed title',
        );
      }
      final unsigned = Course.fromJson(_fixture('dummy-unsigned.json'));
      expect(unsigned.formatVersion, 11);
      await expectLater(verifier.requireVerified(unsigned), throwsA(anything));
    });
  });

  group('convert_course_to_v11 tool', () {
    test('a v9 bundled Course converts back to exactly the shipped file', () {
      for (final file in const ['german_en.json', 'neapolitan_it.json']) {
        final shipped = _bundled(file);
        final asV9 = {
          ...shipped,
          'formatVersion': 9,
          'officialChecksum': 'b' * 64,
        };
        expect(convertCourseJsonToV11(asV9), shipped, reason: file);
      }
    });

    test('a v10 merged Course becomes v11 with its merge provenance', () {
      final v10 = {
        ..._course().toJson(),
        'formatVersion': 10,
        'mergeProvenance': _merge(),
      };
      final converted = convertCourseJsonToV11(v10);
      expect(converted['formatVersion'], 11);
      expect(Course.fromJson(converted).mergeProvenance, isNotNull);
    });

    test('the official version can be raised during conversion', () {
      final converted = convertCourseJsonToV11({
        ..._bundled('german_en.json'),
        'formatVersion': 9,
      }, officialVersion: '9.9.9');
      final course = Course.fromJson(converted);
      expect(course.officialCourseVersion, '9.9.9');
      expect(course.officialChecksum, CourseChecksums.official(course));
      expect(
        () => convertCourseJsonToV11({
          ..._course().toJson(),
          'formatVersion': 9,
        }, officialVersion: '2'),
        throwsA(isA<FormatException>()),
      );
    });

    test('a Publisher Course loses its signature and must be re-signed', () {
      final converted = convertCourseJsonToV11({
        ..._fixture('dummy-signed-v1.json'),
        'formatVersion': 9,
      });
      expect(converted.containsKey('publisherSignature'), isFalse);
      expect(converted['publisherVerificationStatus'], 'unverified');
    });

    test('media outside assets/ stops the conversion and is listed', () {
      final json = {
        ..._course(
          exerciseImage: 'C:/pictures/mine.png',
          audioPath: '/home/me/clip.mp3',
        ).toJson(),
        'formatVersion': 9,
      };
      expect(
        () => convertCourseJsonToV11(json),
        throwsA(
          isA<ExternalMediaReferences>().having(
            (error) => error.locations,
            'locations',
            allOf(
              hasLength(2),
              contains(endsWith('= C:/pictures/mine.png')),
              contains(endsWith('= /home/me/clip.mp3')),
            ),
          ),
        ),
      );
      // Bundled and embedded media are fine.
      expect(
        convertCourseJsonToV11({
          ..._course(
            exerciseImage: 'assets/exercise_images/apple.webp',
            audioPath: 'assets/audio/it_sample/sample_1.mp3',
          ).toJson(),
          'formatVersion': 9,
        })['formatVersion'],
        11,
      );
    });

    test('v11 and older formats are not converted', () {
      final json = _course().toJson();
      expect(
        () => convertCourseJsonToV11(json),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => convertCourseJsonToV11({...json, 'formatVersion': 8}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _bundled(String file) => Map<String, dynamic>.from(
  jsonDecode(File('assets/courses/$file').readAsStringSync()) as Map,
);

Map<String, dynamic> _fixture(String file) => Map<String, dynamic>.from(
  jsonDecode(File('test/fixtures/publishers/$file').readAsStringSync()) as Map,
);

Course _course({
  String id = 'v11-course',
  int formatVersion = Course.currentFormatVersion,
  int? minimumAppBuild,
  CoursePublisherContact? publisherContact,
  int? estimatedStudyHours,
  int? minimumAge,
  List<String> keywords = const [],
  String coverImage = '',
  String? exerciseImage,
  String? audioPath,
  DerivativeWorksPolicy derivative = DerivativeWorksPolicy.unspecified,
}) => Course(
  formatVersion: formatVersion,
  courseId: id,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originType: CourseOriginType.custom,
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  modifiedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Original Creator',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'v11 course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  derivativeWorksPolicy: derivative,
  minimumAppBuild: minimumAppBuild,
  publisherContact: publisherContact,
  estimatedStudyHours: estimatedStudyHours,
  minimumAge: minimumAge,
  keywords: keywords,
  coverImage: coverImage,
  audioLibrary: [
    if (audioPath != null)
      CourseAudioClip(id: 'clip', text: 'ciao', filePath: audioPath),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-1',
      publicationState: PublicationState.published,
      updatedAt: _when,
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round-1',
          publicationState: PublicationState.published,
          updatedAt: _when,
          title: 'Round',
          exercises: [
            Exercise.v2(
              id: 'exercise-1',
              publicationState: PublicationState.published,
              updatedAt: _when,
              editorTemplate: 'translate_to_target',
              promptElements: [
                const PromptElement(type: 'text', text: 'Hello'),
                if (exerciseImage != null)
                  PromptElement(
                    role: 'clue',
                    type: 'image',
                    asset: exerciseImage,
                  ),
              ],
              interaction: const ExerciseInteraction(kind: 'input'),
              evaluation: const ExerciseEvaluation(
                kind: 'text_match',
                accepted: ['ciao'],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

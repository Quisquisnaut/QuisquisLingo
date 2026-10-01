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
import 'package:quisquislingo_app/services/course_model_v12_converter.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('Course Model v12 clean cut', () {
    test('v12 is the only accepted format', () {
      final json = _course().toJson();
      expect(json['formatVersion'], 12);
      expect(Course.fromJson(json).formatVersion, 12);
      for (final old in [9, 10, 11]) {
        expect(
          () => Course.fromJson({...json, 'formatVersion': old}),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('format 12 only'),
                contains('convert_course_to_v12'),
              ),
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
      expect(merged.formatVersion, Course.currentFormatVersion);
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
      final bundled = _bundled('piedmontais_en.json');
      expect(
        () => Course.fromJson({...bundled, 'mergeProvenance': _merge()}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('v12 storage clean cut', () {
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
        expect(CourseFileStore.rootDirectoryName, 'QQL_Courses_v12');
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
          backupsDirectoryProvider: () async => Directory(
            [
              root.path,
              'QuisquisLingo',
              'Backups',
              'Courses',
            ].join(Platform.pathSeparator),
          ),
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
      expect(merged.formatVersion, Course.currentFormatVersion);
      expect(merged.mergeProvenance, isNotNull);
      expect(merged.keywords, ['left']);
      expect(merged.minimumAge, 4);
      expect(merged.minimumAppBuild, Course.appBuildNumber);
    });
  });

  group('bundled and fixture Courses are v12', () {
    const bundledIds = {
      'edge_case_it_en.json': 'course_6f6a1fa3-b834-4936-b324-92fb57f73502',
      'exercise_laboratory_en_it.json':
          'course_50d68435-d2c2-4b63-9a0b-b23161357f1d',
      'piedmontais_en.json': 'course_e5f5585a-7762-43a0-a6b2-62754e02d17b',
      'piedmontese_mixed_en.json':
          'course_69ff369e-bb4f-46a3-85f0-57ff9d51b453',
    };

    test('bundled Courses keep the Course IDs learner progress uses', () {
      for (final entry in bundledIds.entries) {
        final json = _bundled(entry.key);
        final course = Course.fromJson(json);
        expect(course.formatVersion, 12, reason: entry.key);
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
        expect(course.formatVersion, 12);
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
      expect(unsigned.formatVersion, 12);
      await expectLater(verifier.requireVerified(unsigned), throwsA(anything));
    });
  });

  group('convert_course_to_v12 library', () {
    Map<String, dynamic> v11(String file) => Map<String, dynamic>.from(
      jsonDecode(File('test/fixtures/v11/$file').readAsStringSync()) as Map,
    );

    test(
      'the generated Courses agree with the converter exercise by exercise',
      () {
        for (final file in const [
          'exercise_laboratory_en_it.json',
          'edge_case_it_en.json',
          'piedmontais_en.json',
        ]) {
          final result = convertCourseJsonToV12(v11(file));
          expect(result.notes, isEmpty, reason: file);
          final converted = Course.fromJson(result.json);
          final shipped = Course.fromJson(_bundled(file));
          expect(converted.courseId, shipped.courseId, reason: file);
          List<LearningContent> contents(Course course) => [
            for (final lesson in course.lessons)
              for (final round in lesson.rounds) ...round.content,
          ];
          final a = contents(converted);
          // Build 256 Revision 5: a Story's lines and covers have no v11
          // shape, so the fixtures omit the Story Lessons; every shipped
          // content the fixture lacks belongs to a Story Round or carries a
          // canonical-only preset (the Story cover Lesson).
          final knownIds = a.map((c) => c.id).toSet();
          final b = <LearningContent>[];
          for (final lesson in shipped.lessons) {
            for (final round in lesson.rounds) {
              // Build 256 Revision 7: the Assign Lesson is canonical content
              // without a preset and has no v11 shape either.
              final storyRound =
                  round.flow != null ||
                  round.content.any(
                    (content) =>
                        PresetRecipes.canonicalOnly.contains(
                          content.editorTemplate,
                        ) ||
                        (content.exercise != null &&
                            content.editorTemplate.isEmpty),
                  );
              for (final content in round.content) {
                if (knownIds.contains(content.id)) {
                  b.add(content);
                } else {
                  expect(
                    storyRound,
                    isTrue,
                    reason:
                        '$file ${content.id} is neither converted nor a Story',
                  );
                }
              }
            }
          }
          expect(a.map((c) => c.id), b.map((c) => c.id), reason: file);
          for (var i = 0; i < a.length; i++) {
            final reason = '$file ${a[i].id}';
            expect(a[i].kind, b[i].kind, reason: reason);
            expect(
              a[i].authoringMetadata,
              b[i].authoringMetadata,
              reason: reason,
            );
            expect(
              a[i].exercise == null,
              b[i].exercise == null,
              reason: reason,
            );
            if (a[i].exercise case final exercise?) {
              expect(
                exercise.semanticallyEquals(b[i].exercise!),
                isTrue,
                reason: reason,
              );
              expect(
                exercise.updatedAt,
                b[i].exercise!.updatedAt,
                reason: reason,
              );
            }
          }
          expect(
            shipped.officialChecksum,
            CourseChecksums.official(shipped),
            reason: file,
          );
        }
      },
    );

    test('a custom demo Course converts without notes', () {
      final result = convertCourseJsonToV12(
        v11('italian_demo_2_pick_the_translation.json'),
      );
      expect(result.notes, isEmpty);
      expect(
        result.json,
        Map<String, dynamic>.from(
          jsonDecode(
                File(
                  'demo_courses/italian_demo_2_pick_the_translation.json',
                ).readAsStringSync(),
              )
              as Map,
        ),
      );
    });

    test('a Publisher Course loses its signature and must be re-signed', () {
      final result = convertCourseJsonToV12(
        {
            ..._v11Custom(),
            'originType': 'externalOfficial',
            'publisherId': 'org.example',
            'publisherName': 'Example',
            'officialCourseVersion': '1',
            'officialReleaseDateUtc': '2026-09-01T00:00:00.000Z',
            'officialChecksum': '0' * 64,
            'distributionChannel': 'test',
            'publisherVerificationStatus': 'verified',
            'publisherSignature': 'qql-ed25519-v1:key-1:AAAA',
            'originalCourseCreator': {
              'type': 'publisher',
              'id': 'org.example',
              'displayName': 'Example',
            },
          }
          ..remove('maintainer')
          ..remove('courseVersion'),
      );
      expect(result.json.containsKey('publisherSignature'), isFalse);
      expect(result.json['publisherVerificationStatus'], 'unverified');
      expect(result.json['officialChecksum'], isA<String>());
      expect(result.json['officialChecksum'], isNot('0' * 64));
      expect(result.notes.single, contains('signature was removed'));
    });

    test('stale fields and non-standard presentation actions are noted', () {
      final json = _v11Custom();
      final content =
          (((json['lessons'] as List).first as Map)['rounds'] as List).first
              as Map;
      final exercise =
          ((content['content'] as List).first as Map)['exercise'] as Map;
      (exercise['evaluation'] as Map)['pairs'] = [
        ['item_0', 'item_1'],
      ];
      (content['content'] as List).add({
        'id': 'card',
        'publicationState': 'published',
        'kind': 'presentation',
        'required': true,
        'presentation': {
          'content': [
            {'role': 'term', 'type': 'text', 'text': 'acqua'},
          ],
          'completion': {
            'actions': ['ok'],
          },
        },
      });
      final result = convertCourseJsonToV12(json);
      expect(
        result.notes,
        containsAll([
          contains('pairs are not used by Select and were dropped'),
          contains('actions [ok] became completionMode continue'),
        ]),
      );
      final course = Course.fromJson(result.json);
      final card = course.lessons.single.rounds.single.content.last;
      expect(card.kind, 'exercise');
      expect(card.exercise!.primitive, ExercisePrimitive.presentation);
      expect(card.exercise!.updatedAt, DateTime.utc(2026, 9, 7, 10, 1));
      expect(card.editorTemplate, 'flashcard');
    });

    test('v12 and older formats are not converted', () {
      expect(
        () => convertCourseJsonToV12(_course().toJson()),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('already'),
          ),
        ),
      );
      for (final old in [8, 9, 10]) {
        expect(
          () => convertCourseJsonToV12({..._v11Custom(), 'formatVersion': old}),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('convert_course_to_v11'),
            ),
          ),
          reason: 'v$old',
        );
      }
    });

    test('a device path is refused by the final v12 check', () {
      final json = _v11Custom();
      final exercise =
          ((((((json['lessons'] as List).first as Map)['rounds'] as List).first
                              as Map)['content']
                          as List)
                      .first
                  as Map)['exercise']
              as Map;
      (exercise['prompt'] as List).add({
        'role': 'clue',
        'type': 'image',
        'asset': 'C:/pictures/mine.png',
      });
      expect(
        () => convertCourseJsonToV12(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('not supported'),
          ),
        ),
      );
    });
  });
}

/// A hand-written Course Model v11 custom Course: one Lesson, one Round, one
/// Choose exercise. Written independently of the model, as a converter input.
Map<String, dynamic> _v11Custom() => {
  'formatVersion': 11,
  'publicationState': 'published',
  'lessonNumberingMode': 'lesson',
  'defaultLessonIconStyle': 'monochrome',
  'createDuels': false,
  'useGuidebook': false,
  'courseId': 'course_31b11b63-e6d2-4f2a-a731-a71ba236960c',
  'originType': 'custom',
  'originalCourseCreator': {
    'type': 'qqlUser',
    'id': _profileId,
    'displayName': 'Converter tester',
  },
  'maintainer': {'profileId': _profileId},
  'originalCreatedAtUtc': '2026-09-07T10:00:00.000Z',
  'lastVersionEditorProfileId': _profileId,
  'lastVersionEditorDisplayName': 'Converter tester',
  'modifiedAtUtc': '2026-09-07T10:00:00.000Z',
  'learningLanguage': 'Italian',
  'interfaceLanguage': 'English',
  'sourceLanguage': 'English',
  'targetLanguage': 'Italian',
  'title': 'v11 input',
  'ttsLanguage': 'it-IT',
  'courseVersion': '1',
  'audioMode': 'tts',
  'license': 'All rights reserved',
  'textDirection': 'ltr',
  'flagCode': 'IT',
  'temporarySample': false,
  'lessons': [
    {
      'lessonId': 'lesson-1',
      'publicationState': 'published',
      'updatedAt': '2026-09-07T10:00:00.000Z',
      'title': 'Greetings',
      'section': false,
      'guidebook': {'content': []},
      'rounds': [
        {
          'id': 'round-1',
          'publicationState': 'published',
          'updatedAt': '2026-09-07T10:01:00.000Z',
          'visualType': 'generic',
          'content': [
            {
              'id': 'exercise-1',
              'publicationState': 'published',
              'kind': 'exercise',
              'required': true,
              'editorTemplate': 'choice',
              'exercise': {
                'updatedAt': '2026-09-07T10:02:00.000Z',
                'prompt': [
                  {'role': 'question', 'type': 'text', 'text': 'water'},
                ],
                'interaction': {
                  'kind': 'select',
                  'minSelections': 1,
                  'maxSelections': 1,
                  'items': [
                    {
                      'id': 'item_0',
                      'content': [
                        {'role': 'primary', 'type': 'text', 'text': 'acqua'},
                      ],
                    },
                    {
                      'id': 'item_1',
                      'content': [
                        {'role': 'primary', 'type': 'text', 'text': 'libro'},
                      ],
                    },
                  ],
                },
                'evaluation': {
                  'kind': 'selected_items',
                  'correctItemIds': ['item_0'],
                },
              },
            },
          ],
        },
      ],
      'duel': {'id': 'lesson-1_duel', 'title': 'Duel'},
    },
  ],
};

// The Edge Case is a test fixture since Build 259 Revision 5.
Map<String, dynamic> _bundled(String file) => Map<String, dynamic>.from(
  jsonDecode(
        File(
          file == 'edge_case_it_en.json'
              ? 'test/fixtures/v12/$file'
              : 'assets/courses/$file',
        ).readAsStringSync(),
      )
      as Map,
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

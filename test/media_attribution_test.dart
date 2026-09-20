import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';

import 'support/publisher_fixtures.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _when = DateTime.utc(2026, 9, 20, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseMediaAttribution', () {
    test('an empty list leaves the Course JSON exactly as it was', () {
      final course = _course();
      expect(course.mediaAttributions, isEmpty);
      expect(course.toJson().containsKey('mediaAttributions'), isFalse);
      // Round-tripping must not introduce the key either.
      expect(
        Course.fromJson(course.toJson()).toJson().containsKey(
          'mediaAttributions',
        ),
        isFalse,
      );
    });

    test('entries survive a JSON round trip and keep their order', () {
      final course = _course(
        attributions: const [
          CourseMediaAttribution(
            author: 'Ipankonin',
            license: 'CC BY-SA 3.0',
            title: 'Friuli Flag',
            source: 'Wikimedia Commons, File:Friuli_Flag.svg',
            appliesTo: 'Course flag',
          ),
          CourseMediaAttribution(author: 'A Performer', license: 'CC BY 4.0'),
        ],
      );
      final restored = Course.fromJson(
        jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
      );
      expect(restored.mediaAttributions, hasLength(2));
      expect(restored.mediaAttributions.first.author, 'Ipankonin');
      expect(restored.mediaAttributions.first.appliesTo, 'Course flag');
      expect(restored.mediaAttributions.last.license, 'CC BY 4.0');
      // Optional empty fields stay out of the serialised entry.
      final encoded = restored.mediaAttributions.last.toJson();
      expect(encoded.keys, unorderedEquals(['author', 'license']));
    });

    test('required fields, length, duplicates and shape are validated', () {
      Course parseWith(Object? raw) =>
          Course.fromJson({..._course().toJson(), 'mediaAttributions': raw});

      expect(
        () => parseWith('not a list'),
        throwsA(isA<FormatException>()),
        reason: 'a non-list must be rejected, not ignored',
      );
      expect(() => parseWith(['not an object']), throwsA(isA<FormatException>()));
      expect(
        () => parseWith([
          {'author': '   ', 'license': 'CC BY 4.0'},
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseWith([
          {'author': 'Someone', 'license': ''},
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseWith([
          {'author': 'a' * 201, 'license': 'CC BY 4.0'},
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseWith([
          {'author': 'Someone', 'license': 'CC BY 4.0', 'source': 'a' * 501},
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parseWith([
          {'author': 'Someone', 'license': 'CC BY 4.0'},
          {'author': 'Someone', 'license': 'CC BY 4.0'},
        ]),
        throwsA(isA<FormatException>()),
        reason: 'an identical repeated credit is an authoring mistake',
      );
      expect(
        () => parseWith([
          for (var i = 0; i <= CourseMediaAttribution.maxEntries; i++)
            {'author': 'Author $i', 'license': 'CC BY 4.0'},
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('whitespace is normalised rather than preserved verbatim', () {
      final course = Course.fromJson({
        ..._course().toJson(),
        'mediaAttributions': [
          {'author': '  Two   Names  ', 'license': ' CC BY 4.0 '},
        ],
      });
      expect(course.mediaAttributions.single.author, 'Two Names');
      expect(course.mediaAttributions.single.license, 'CC BY 4.0');
    });
  });

  group('checksum compatibility', () {
    test('a Course without attributions checksums exactly as before', () {
      // The field is omitted when empty and the canonical digest sorts keys,
      // so no existing course, backup or signature can be disturbed.
      final course = _course();
      final asStoredBefore = Map<String, dynamic>.from(course.toJson())
        ..remove('mediaAttributions');
      expect(
        CourseChecksums.whole(course),
        CourseChecksums.whole(Course.fromJson(asStoredBefore)),
      );
      expect(
        CourseChecksums.official(course),
        CourseChecksums.official(Course.fromJson(asStoredBefore)),
      );
    });

    test('both signed Dummy fixtures still verify unchanged', () async {
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      for (final name in const ['dummy-signed-v1.json', 'dummy-signed-v2.json']) {
        final course = Course.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              File('test/fixtures/publishers/$name').readAsStringSync(),
            ) as Map,
          ),
        );
        final verified = await verifier.requireVerified(course);
        expect(
          verified.publisherVerificationStatus,
          PublisherVerificationStatus.verified,
          reason: '$name must still verify after the model gained a field',
        );
      }
    });
  });

  group('MEDIA_ATTRIBUTION_MISSING', () {
    final service = CourseAuditService();

    bool warns(Course course) => service.auditCourse(course).issues.any(
      (issue) => issue.code == AuditCode.mediaAttributionMissing.code,
    );

    test('a course using only bundled app media stays silent', () {
      expect(
        warns(_course(exerciseImage: 'assets/exercise_images/apple.webp')),
        isFalse,
      );
      expect(warns(_course()), isFalse);
    });

    test('each kind of course-owned media raises the warning', () {
      expect(
        warns(_course(exerciseImage: 'C:/pictures/mine.png')),
        isTrue,
        reason: 'an imported exercise image',
      );
      expect(
        warns(_course(exerciseImage: 'data:image/png;base64,AAAA')),
        isTrue,
        reason: 'an embedded portable image',
      );
      expect(
        warns(_course(audioPath: 'C:/audio/clip.mp3')),
        isTrue,
        reason: 'an imported recording',
      );
      expect(
        warns(_course(flagImageBase64: 'AAAA')),
        isTrue,
        reason: 'an embedded custom flag',
      );
      expect(
        warns(_course(audioPath: 'assets/audio/it_sample/sample_1.mp3')),
        isFalse,
        reason: 'a bundled recording is QQL media',
      );
    });

    test('recording the credit clears the warning', () {
      expect(
        warns(
          _course(
            exerciseImage: 'C:/pictures/mine.png',
            attributions: const [
              CourseMediaAttribution(
                author: 'Someone',
                license: 'CC BY-SA 4.0',
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('it is a warning, so it never blocks publication', () {
      expect(AuditCode.mediaAttributionMissing.severity, AuditSeverity.warning);
      expect(AuditCode.mediaAttributionMissing.blocking, isFalse);
    });
  });
}

Course _course({
  List<CourseMediaAttribution> attributions = const [],
  String? exerciseImage,
  String? audioPath,
  String flagImageBase64 = '',
}) => Course(
  courseId: 'media-attribution-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originType: CourseOriginType.custom,
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Media attribution course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  flagImageBase64: flagImageBase64,
  mediaAttributions: attributions,
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
                const PromptElement(type: 'text', text: 'Say hello'),
                if (exerciseImage != null)
                  PromptElement(type: 'image', asset: exerciseImage),
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

import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '11111111-1111-4111-8111-111111111111';
final _mergeTime = DateTime.utc(2026, 9, 17, 10);

Course _course({
  required String id,
  required String created,
  required String version,
  String modifiedAtUtc = '2026-09-16T10:00:00.000Z',
  String title = 'English for Italian speakers',
  String flagCode = 'IT',
  String worldFlagId = '',
  String flagImageBase64 = '',
  String ttsLanguage = 'it-IT',
  String buyACoffeeUrl = '',
  String courseDescription = '',
  String startLevel = '',
  String targetLevel = '',
  PublicationState publicationState = PublicationState.published,
  bool createDuels = true,
  bool useGuidebook = true,
  LessonNumberingMode lessonNumberingMode = LessonNumberingMode.lesson,
  String customLessonLabel = '',
  List<String> sectionNames = const [],
  String originalCreatorProfileId = _profileId,
  List<Lesson>? lessons,
}) => Course(
  courseId: id,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: originalCreatorProfileId,
    displayName: 'Merge Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: created,
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Merge Author',
  modifiedAtUtc: modifiedAtUtc,
  publicationState: publicationState,
  createDuels: createDuels,
  useGuidebook: useGuidebook,
  lessonNumberingMode: lessonNumberingMode,
  customLessonLabel: customLessonLabel,
  sectionNames: sectionNames,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: ttsLanguage,
  flagCode: flagCode,
  worldFlagId: worldFlagId,
  flagImageBase64: flagImageBase64,
  buyACoffeeUrl: buyACoffeeUrl,
  courseDescription: courseDescription,
  startLevel: startLevel,
  targetLevel: targetLevel,
  courseVersion: version,
  lessons:
      lessons ??
      [
        Lesson(
          lessonId: '$id-lesson',
          publicationState: PublicationState.published,
          updatedAt: DateTime.utc(2026, 9, 1),
          title: 'Greetings',
          rounds: const [],
        ),
      ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'merge path is isolated in Merges and source file remains readable',
    () async {
      final directory = await Directory.systemTemp.createTemp('qql_merges_');
      addTearDown(() => directory.delete(recursive: true));
      final transfer = CustomCourseTransferService(
        mergeDirectory: () async => directory,
      );
      final source = _course(
        id: 'course-right',
        created: '2026-09-02T00:00:00.000Z',
        version: '2',
      );
      final file = File(await transfer.mergeFilePath());
      await file.writeAsString(jsonEncode(source.toJson()));

      expect(
        await transfer.mergeCourse().then((course) => course.courseId),
        'course-right',
      );
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'merge creates a v11 Course with fresh Lesson identity and immediate sources',
    () async {
      final profiles = ProfileService();
      await profiles.createProfile(
        'Merge Author',
        learnerProfileId: _profileId,
      );
      final left = _course(
        id: 'course-left',
        created: '2026-09-01T00:00:00.000Z',
        version: '2',
      );
      final right = _course(
        id: 'course-right',
        created: '2026-09-02T00:00:00.000Z',
        version: '3',
        lessons: [
          Lesson(
            lessonId: 'course-right-lesson',
            updatedAt: DateTime.utc(2026, 9, 2),
            title: 'Travel',
            rounds: const [],
          ),
        ],
      );
      final merged =
          await CourseMergeService(
            profileService: profiles,
            clock: () => _mergeTime,
          ).createMergedCourse(
            left: left,
            right: right,
            choices: const [LessonMergeChoice.right],
            options: CourseMergeOptions.fromCourse(left),
          );

      expect(merged.formatVersion, Course.currentFormatVersion);
      expect(merged.title, 'English for Italian speakers merged');
      expect(merged.originalCreatedAtUtc, left.originalCreatedAtUtc);
      expect(merged.modifiedAtUtc, _mergeTime.toIso8601String());
      expect(merged.courseVersion, '1');
      expect(merged.lessons.single.title, 'Travel');
      expect(
        merged.lessons.single.lessonId,
        isNot(right.lessons.single.lessonId),
      );
      expect(
        merged.lessons.single.publicationState,
        PublicationState.published,
      );
      expect(merged.mergeProvenance!.leftSourceCourseId, left.courseId);
      expect(merged.mergeProvenance!.rightSourceCourseVersion, '3');
      expect(
        merged.mergeProvenance!.rightSourceModifiedAtUtc,
        right.modifiedAtUtc,
      );
      expect(Course.fromJson(merged.toJson()).mergeProvenance, isNotNull);
    },
  );

  test(
    'merge rejects mismatched Course info and accepts merged sources',
    () async {
      final left = _course(
        id: 'course-left',
        created: '2026-09-01T00:00:00.000Z',
        version: '1',
      );
      final right = _course(
        id: 'course-right',
        created: '2026-09-02T00:00:00.000Z',
        version: '2',
        ttsLanguage: 'fr-FR',
      );
      final service = CourseMergeService();
      expect(
        () => service.validateCompatibility(left, right),
        throwsA(isA<FormatException>()),
      );
      final merged = Course.fromJson({
        ...right.toJson(),
        'ttsLanguage': 'it-IT',
        'mergeProvenance': {
          'leftSourceCourseId': 'older-left',
          'leftSourceCourseVersion': '1',
          'rightSourceCourseId': 'older-right',
          'rightSourceCourseVersion': '2',
          'mergedAtUtc': '2026-09-03T00:00:00.000Z',
        },
      });
      expect(
        () => service.validateCompatibility(left, merged),
        returnsNormally,
      );
      expect(
        () => service.validateCompatibility(
          left,
          _course(
            id: 'course-third',
            created: '2026-09-02T00:00:00.000Z',
            version: '2',
            originalCreatorProfileId: '22222222-2222-4222-8222-222222222222',
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('merge accepts distinct revisions of the same Course identity', () {
    final left = _course(
      id: 'course-identity',
      created: '2026-09-01T00:00:00.000Z',
      version: '4',
    );
    final service = CourseMergeService();

    expect(
      () => service.validateCompatibility(
        left,
        _course(
          id: 'course-identity',
          created: '2026-09-02T00:00:00.000Z',
          version: '5',
        ),
      ),
      returnsNormally,
    );
    expect(
      () => service.validateCompatibility(
        left,
        _course(
          id: 'course-identity',
          created: '2026-09-03T00:00:00.000Z',
          version: '4',
          modifiedAtUtc: '2026-09-17T10:00:00.000Z',
        ),
      ),
      returnsNormally,
    );
    expect(
      () => service.validateCompatibility(
        left,
        _course(
          id: 'course-identity',
          created: '2026-09-03T00:00:00.000Z',
          version: '4',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('merged Course title uses the first available progressive suffix', () {
    expect(
      CourseMergeService.nextAvailableTitle('English merged', [
        'English merged',
        'English merged 2',
      ]),
      'English merged 3',
    );
  });

  test(
    'merge accepts approved setting differences and uses chosen values',
    () async {
      final profiles = ProfileService();
      await profiles.createProfile(
        'Merge Author',
        learnerProfileId: _profileId,
      );
      final left = _course(
        id: 'course-left',
        created: '2026-09-01T00:00:00.000Z',
        version: '1',
      );
      final right = _course(
        id: 'course-right',
        created: '2026-09-02T00:00:00.000Z',
        version: '2',
        publicationState: PublicationState.draft,
        createDuels: false,
        useGuidebook: false,
        lessonNumberingMode: LessonNumberingMode.numberOnly,
        sectionNames: const ['Travel'],
        title: 'English for Italian speakers revised',
        flagCode: 'FR',
        worldFlagId: 'france',
        flagImageBase64: 'AQID',
        buyACoffeeUrl: 'https://example.com/coffee',
        courseDescription: 'Revised description',
        startLevel: 'A1',
        targetLevel: 'B1',
      );
      final merged =
          await CourseMergeService(
            profileService: profiles,
            clock: () => _mergeTime,
          ).createMergedCourse(
            left: left,
            right: right,
            choices: const [LessonMergeChoice.left],
            options: CourseMergeOptions.fromCourse(right),
          );

      expect(merged.publicationState, PublicationState.draft);
      expect(merged.createDuels, isFalse);
      expect(merged.useGuidebook, isFalse);
      expect(merged.lessonNumberingMode, LessonNumberingMode.numberOnly);
      expect(merged.sectionNames, ['Travel']);
      expect(merged.title, 'English for Italian speakers revised merged');
      expect(merged.flagCode, 'FR');
      expect(merged.worldFlagId, 'france');
      expect(merged.flagImageBase64, 'AQID');
      expect(merged.buyACoffeeUrl, 'https://example.com/coffee');
      expect(merged.courseDescription, 'Revised description');
      expect(merged.startLevel, 'A1');
      expect(merged.targetLevel, 'B1');
    },
  );
}

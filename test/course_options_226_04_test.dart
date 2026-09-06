import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_transaction.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';

Map<String, dynamic> _bundledJson() =>
    jsonDecode(File('assets/courses/italian_en.json').readAsStringSync())
        as Map<String, dynamic>;

Course _course({bool options = true}) => Course.fromJson({
  ..._bundledJson(),
  'originType': 'custom',
  if (options) ...{
    'createDuels': false,
    'useGuidebook': false,
    'sectionNames': [' Planned ', 'Planned', 'Unused'],
    'worldFlagId': 'italy',
  },
});

void _expectOptions(Course course) {
  expect(course.createDuels, isFalse);
  expect(course.useGuidebook, isFalse);
  expect(course.sectionNames, ['Planned', 'Unused']);
  expect(course.worldFlagId, 'italy');
  expect(course.formatVersion, 6);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy v6 defaults omit new fields and retain required Duel identity',
    () {
      final course = Course.fromJson(_bundledJson());
      expect(course.createDuels, isTrue);
      expect(course.useGuidebook, isTrue);
      expect(course.sectionNames, isEmpty);
      expect(course.worldFlagId, isEmpty);
      for (final key in [
        'createDuels',
        'useGuidebook',
        'sectionNames',
        'worldFlagId',
      ]) {
        expect(course.toJson(), isNot(contains(key)));
      }
      expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
      final lesson = course.lessons.first;
      expect(lesson.duel.id, isNotEmpty);
      expect(
        () => Lesson.fromJson({...lesson.toJson()}..remove('duel')),
        throwsFormatException,
      );
    },
  );

  test(
    'section catalog is immutable, trimmed, deduplicated and includes legacy assignments',
    () {
      final course = _course();
      final legacy = Course.fromJson({
        ...course.toJson(),
        'lessons': [
          {
            ...course.lessons.first.toJson(),
            'section': true,
            'sectionName': ' Existing ',
          },
        ],
      });
      expect(legacy.sectionNames, ['Planned', 'Unused']);
      expect(legacy.availableSectionNames, ['Planned', 'Unused', 'Existing']);
      expect(() => legacy.sectionNames.add('Oops'), throwsUnsupportedError);
      final oldJson = legacy.toJson()..remove('sectionNames');
      final old = Course.fromJson(oldJson);
      expect(old.availableSectionNames, ['Existing']);
      expect(old.toJson(), isNot(contains('sectionNames')));
    },
  );

  for (final invalid in <(String, dynamic)>[
    ('createDuels', 'false'),
    ('createDuels', null),
    ('useGuidebook', 0),
    ('useGuidebook', null),
    ('worldFlagId', 4),
    ('worldFlagId', null),
    ('sectionNames', 'Section'),
    ('sectionNames', null),
    ('sectionNames', [42]),
    ('sectionNames', ['   ']),
  ]) {
    test('rejects invalid ${invalid.$1} value ${invalid.$2}', () {
      expect(
        () => Course.fromJson({..._bundledJson(), invalid.$1: invalid.$2}),
        throwsFormatException,
      );
    });
  }

  test('all existing canonical fields survive optional settings roundtrip', () {
    final old = _course(options: false).toJson();
    final course = _course();
    _expectOptions(course);
    final reloaded = Course.fromJson(jsonDecode(jsonEncode(course.toJson())));
    _expectOptions(reloaded);
    final stripped = reloaded.toJson()
      ..remove('createDuels')
      ..remove('useGuidebook')
      ..remove('sectionNames')
      ..remove('worldFlagId');
    expect(stripped, old);
    expect(
      reloaded.lessons.first.duel.toJson(),
      course.lessons.first.duel.toJson(),
    );
  });

  test(
    'working-copy cancellation and historical restore preserve complete options',
    () {
      final course = _course();
      final transaction = CourseEditorTransaction(course);
      _expectOptions(transaction.workingCourse);
      transaction.replaceWorkingCourse(
        Course.fromJson({
          ...course.toJson(),
          'createDuels': true,
          'sectionNames': ['Changed'],
        }),
      );
      expect(transaction.hasChanges, isTrue);
      transaction.cancel();
      expect(transaction.hasChanges, isFalse);
      expect(transaction.workingCourse.toJson(), course.toJson());
      transaction.loadHistoricalCourse(
        Course.fromJson({
          ...course.toJson(),
          'worldFlagId': 'france',
          'sectionNames': ['History'],
        }),
      );
      expect(transaction.workingCourse.worldFlagId, 'france');
      expect(transaction.workingCourse.sectionNames, ['History']);
      transaction.cancel();
      _expectOptions(transaction.workingCourse);
    },
  );

  test(
    'Move and Copy use complete Course and preserve Lesson-owned GuideBook identities',
    () {
      final course = _course();
      final snapshot = course.toJson();
      final first = course.lessons.first;
      final second = course.lessons[1];
      final service = CourseAuthoringTransferService();
      final moved = service.moveRound(
        course,
        sourceLessonId: first.lessonId,
        roundId: first.rounds.first.id,
        destinationLessonId: second.lessonId,
      );
      final copied = service.copyRound(
        course,
        sourceLessonId: first.lessonId,
        roundId: first.rounds.first.id,
        destinationLessonId: second.lessonId,
      );
      for (final result in [moved, copied]) {
        _expectOptions(result);
        expect(
          {...result.toJson()}..remove('lessons'),
          {...snapshot}..remove('lessons'),
        );
        expect(result.lessons.first.guidebookId, first.guidebookId);
        expect(result.lessons[1].guidebookId, second.guidebookId);
      }
      expect(course.toJson(), snapshot);
    },
  );

  test(
    'duplicates retain options and allocate fresh Lesson-owned GuideBook identities',
    () {
      final source = _course();
      final copy = AuthoringDuplicationService().duplicateCourse(
        source,
        title: 'Independent copy',
      );
      _expectOptions(copy);
      expect(copy.courseId, isNot(source.courseId));
      expect(
        copy.lessons.first.guidebookId,
        isNot(source.lessons.first.guidebookId),
      );
      expect(
        copy.lessons.first.guidebook.content.length,
        source.lessons.first.guidebook.content.length,
      );
      expect(
        copy.authors.map((author) => author.toJson()).toList(),
        source.authors.map((author) => author.toJson()).toList(),
      );
      expect(copy.license, source.license);
      expect(copy.flagCode, source.flagCode);
      final renamed = Lesson.fromJson({
        ...source.lessons.first.toJson(),
        'title': 'Renamed',
      });
      expect(renamed.guidebookId, source.lessons.first.guidebookId);
      expect(renamed.toJson(), isNot(contains('guidebookId')));
      expect(renamed.guidebook.toJson(), isNot(contains('id')));
    },
  );

  test(
    'licensed official fork preserves options and immutable original provenance',
    () {
      final source = Course.fromJson({
        ..._course().toJson(),
        'originType': 'bundledOfficial',
        'derivativeWorksPolicy': 'allowed',
      });
      final provenance = CourseForkProvenance(
        originalPublisherId: source.publisherId,
        originalPublisherName: source.publisherName,
        originalCourseId: source.courseId,
        originalOfficialCourseVersion: source.officialCourseVersion,
        originalOfficialChecksum: source.officialChecksum,
        originalCourseTitle: source.title,
        originalAuthor: source.author,
        originalAuthors: source.authors,
        forkCreatedByProfileId: 'profile',
        forkCreatedByUsername: 'Fork author',
        forkCreatedAtUtc: '2026-09-06T00:00:00.000Z',
      );
      final fork = AuthoringDuplicationService().forkOfficialCourse(
        source,
        provenance: provenance,
      );
      _expectOptions(fork);
      expect(fork.forkProvenance!.toJson(), provenance.toJson());
      expect(
        fork.lessons.first.guidebookId,
        isNot(source.lessons.first.guidebookId),
      );
      expect(fork.courseId, isNot(source.courseId));
    },
  );

  test(
    'export/import and verified backup restore preserve complete options',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql-options-22604-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final course = _course();
      final transfer = CustomCourseTransferService(
        directory: () async => directory,
      );
      final exported = await transfer.exportCourse(course);
      await File(exported).copy(await transfer.importFilePath());
      final imported = await transfer.importCourse();
      expect(imported.toJson(), course.toJson());
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
      );
      final backup = await backups.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 9, 6),
        reason: '226.04 options',
      );
      final restored = await backups.loadBackup(
        backup.manifestFile,
        expectedCourseId: course.courseId,
      );
      expect(restored.course.toJson(), course.toJson());
      _expectOptions(restored.course);
    },
  );
}

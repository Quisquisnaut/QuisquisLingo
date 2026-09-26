import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _authorId = '12345678-1234-4234-9234-123456789abc';
const _receiverId = '22345678-1234-4234-9234-123456789abc';
const _demos = {
  'Laboratory': 'assets/courses/exercise_laboratory_en_it.json',
  'Piedmontais': 'assets/courses/piedmontais_en.json',
};
const _allNewDemoAssets = [
  'assets/courses/exercise_laboratory_en_it.json',
  'assets/courses/piedmontais_en.json',
  'assets/courses/edge_case_it_en.json',
];
final _clock = DateTime.utc(2026, 9, 25, 14);

Future<Course> _load(String asset) async => Course.fromJson(
  Map<String, dynamic>.from(
    jsonDecode(await rootBundle.loadString(asset)) as Map,
  ),
);

List<LearningContent> _contents(Course course) => [
  for (final lesson in course.lessons) ...[
    ...lesson.guidebook.content,
    for (final round in lesson.rounds) ...round.content,
  ],
];

List<Map<String, dynamic>> _contentJson(Course course) => [
  for (final content in _contents(course)) content.toJson(),
];

// Only declared identities and their references change when forking. Keep
// every other payload leaf intact, including answer expressions, layout gap
// IDs, image bytes, custom feedback, prompt roles and Presentation usage.
void _expectForkContent(Course source, Course fork) {
  final before = _contents(source);
  final after = _contents(fork);
  expect(after, hasLength(before.length));
  final identityMap = <String, String>{};
  for (var index = 0; index < before.length; index++) {
    identityMap[before[index].id] = after[index].id;
    final sourceItems = before[index].exercise?.interaction.items ?? [];
    final forkItems = after[index].exercise?.interaction.items ?? [];
    expect(forkItems, hasLength(sourceItems.length), reason: before[index].id);
    for (var item = 0; item < sourceItems.length; item++) {
      identityMap[sourceItems[item].id] = forkItems[item].id;
    }
  }
  expect(identityMap.values.toSet(), hasLength(identityMap.length));
  expect(
    identityMap.keys.toSet().intersection(identityMap.values.toSet()),
    isEmpty,
  );

  Object? remap(Object? value) => switch (value) {
    String() => identityMap[value] ?? value,
    List() => value.map(remap).toList(),
    Map() => {for (final entry in value.entries) entry.key: remap(entry.value)},
    _ => value,
  };

  for (var index = 0; index < before.length; index++) {
    final expected = Map<String, dynamic>.from(
      remap(before[index].toJson())! as Map,
    )..['publicationState'] = 'draft';
    expect(after[index].toJson(), expected, reason: before[index].id);
  }
}

void _expectFlashcardUsage(Course course) {
  final cards = _contents(
    course,
  ).where((content) => content.kind == 'presentation');
  expect(cards, isNotEmpty);
  for (final card in cards) {
    final fields = {
      for (final element in card.presentation!.content)
        element.role: element.text,
    };
    final runnable = card.asRunnableExercise()!;
    expect(runnable.answers, [
      if (fields['usage']?.isNotEmpty == true) fields['usage'],
      if (fields['usage_translation']?.isNotEmpty == true)
        fields['usage_translation'],
    ], reason: card.id);
    const optionalUsageRoles = {'usage', 'usage_translation'};
    final restored = Presentation.fromLegacyExercise(runnable);
    expect(
      {
        for (final element in restored.content)
          if (optionalUsageRoles.contains(element.role))
            element.role: element.text,
      },
      {
        for (final entry in fields.entries)
          if (optionalUsageRoles.contains(entry.key)) entry.key: entry.value,
      },
      reason: card.id,
    );
    expect(card.presentation!.actions, ['understood', 'review_later']);
  }
}

class _Device {
  _Device(this.directory) {
    media = CourseMediaStore(supportDirectory: () async => directory);
    packages = CoursePackageService(
      mediaStore: media,
      stager: ImportStager(supportDirectory: () async => directory),
    );
    editor = CourseEditorService(
      courseStore: CourseFileStore(supportDirectory: () async => directory),
      mediaStore: media,
      backupService: CourseBackupService(
        supportDirectoryProvider: () async => directory,
        mediaStore: media,
      ),
      clock: () => _clock,
    );
    transfer = CustomCourseTransferService(
      directory: () async => directory,
      packageService: packages,
    );
  }

  final Directory directory;
  late final CourseMediaStore media;
  late final CoursePackageService packages;
  late final CourseEditorService editor;
  late final CustomCourseTransferService transfer;

  Future<File> exportFile(Course course, String name) async {
    await directory.create(recursive: true);
    final payload = await transfer.buildCourseExport(course);
    return File('${directory.path}/$name.zip').writeAsBytes(payload.bytes);
  }
}

void _profile(String id, String name) {
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      LearnerProfile(learnerProfileId: id, displayName: name).encode(),
    ],
    ProfileService.activeProfileIdKey: id,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late _Device author;
  late _Device receiver;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('qql_demo_package_254_');
    author = _Device(Directory('${sandbox.path}/author'));
    receiver = _Device(Directory('${sandbox.path}/receiver'));
    _profile(_authorId, 'Demo Package Author');
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  for (final demo in _demos.entries) {
    test(
      '${demo.key} original ZIP preserves every canonical Content payload',
      () async {
        final source = await _load(demo.value);
        final originalJson = source.toJson();
        final originalContent = _contentJson(source);
        final file = await author.exportFile(
          source,
          '${demo.key} original café_日本語',
        );
        // Bundled sources are inspected using the real model parser. Ordinary
        // external Import must reject their installation, as checked below.
        final parsed = await author.packages.parseFile(
          file,
          (bytes, _) async => Course.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          ),
        );
        try {
          expect(parsed.course.toJson(), originalJson);
          expect(_contentJson(parsed.course), originalContent);
          expect(
            CourseChecksums.official(parsed.course),
            source.officialChecksum,
          );
          expect(
            parsed.mediaReferences,
            isEmpty,
            reason:
                'Shipped bundled asset paths remain bundled; glyphs stay embedded.',
          );
          _expectFlashcardUsage(parsed.course);
        } finally {
          await parsed.discard();
        }
        await expectLater(
          author.packages.parseFile(file, author.transfer.courseFromBytes),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('Bundled official courses are installed only'),
            ),
          ),
        );
        expect(await author.editor.listUserCourses(), isEmpty);
        expect(source.toJson(), originalJson);
      },
    );

    test(
      '${demo.key} personal Fork survives real export, receiver Import and re-export',
      () async {
        final source = await _load(demo.value);
        final sourceJson = source.toJson();
        expect(
          CourseAccessPolicy.evaluate(source, profileId: _authorId).canFork,
          isTrue,
        );
        final created = (await author.editor.createFork(source: source)).course;
        final fork = (await author.editor.listUserCourses()).single;
        expect(fork.toJson(), created.toJson());
        expect(fork.courseId, isNot(source.courseId));
        expect(fork.originType, CourseOriginType.custom);
        expect(fork.maintainer!.profileId, _authorId);
        expect(fork.forkProvenance!.sourceCourseId, source.courseId);
        expect(
          fork.forkProvenance!.sourceOfficialChecksum,
          source.officialChecksum,
        );
        _expectForkContent(source, fork);
        _expectFlashcardUsage(fork);
        final savedJson = fork.toJson();
        final savedContent = _contentJson(fork);
        final file = await author.exportFile(fork, '${demo.key} personal fork');

        // A separate storage tree and profile contain no author's local record.
        // Import uses its ordinary parser, including actual image validation.
        _profile(_receiverId, 'Demo Package Receiver');
        expect(await receiver.editor.listUserCourses(), isEmpty);
        final parsed = await receiver.packages.parseFile(
          file,
          receiver.transfer.courseFromBytes,
        );
        try {
          expect(parsed.course.toJson(), savedJson);
          expect(_contentJson(parsed.course), savedContent);
          expect(
            CourseAuditService()
                .auditCourse(parsed.course)
                .count(AuditSeverity.error),
            0,
          );
          await CoursePackageImport(
            parsed,
            editor: receiver.editor,
          ).installCustomCourse();
        } finally {
          await parsed.discard();
        }
        final installed = (await receiver.editor.listUserCourses()).single;
        expect(installed.toJson(), savedJson);
        expect(_contentJson(installed), savedContent);
        expect(installed.maintainer!.profileId, _authorId);
        expect(
          CourseAccessPolicy.evaluate(
            installed,
            profileId: _receiverId,
          ).canEditOriginal,
          isFalse,
        );
        _expectFlashcardUsage(installed);
        final reexport = await receiver.exportFile(
          installed,
          '${demo.key} receiver re-export',
        );
        final reparsed = await receiver.packages.parseFile(
          reexport,
          receiver.transfer.courseFromBytes,
        );
        try {
          expect(reparsed.course.toJson(), savedJson);
          expect(_contentJson(reparsed.course), savedContent);
          expect(reparsed.mediaReferences, isEmpty);
          _expectFlashcardUsage(reparsed.course);
        } finally {
          await reparsed.discard();
        }
        expect(source.toJson(), sourceJson);
      },
    );
  }

  test(
    'all three new bundled identities reject valid custom impersonations',
    () async {
      for (final asset in _allNewDemoAssets) {
        final bundled = await _load(asset);
        final collision = Course(
          courseId: bundled.courseId,
          learningLanguage: 'Italian',
          interfaceLanguage: 'English',
          sourceLanguage: 'English',
          targetLanguage: 'Italian',
          title: 'Custom identity collision probe',
          ttsLanguage: 'it-IT',
          originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
            profileId: _authorId,
            displayName: 'Demo Package Author',
          ),
          originalCreatedAtUtc: _clock.toIso8601String(),
          modifiedAtUtc: _clock.toIso8601String(),
          lastVersionEditorProfileId: _authorId,
          lastVersionEditorDisplayName: 'Demo Package Author',
          maintainer: const CourseMaintainer(_authorId),
          lessons: const [],
        );
        expect(
          Course.fromJson(collision.toJson()).originType,
          CourseOriginType.custom,
        );
        final rejection = throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'A custom course cannot replace an official course identity',
            ),
          ),
        );
        await expectLater(author.editor.saveUserCourse(collision), rejection);
        await expectLater(
          author.editor.installImportedCustomCourse(collision),
          rejection,
        );
        expect(await author.editor.listUserCourses(), isEmpty);
        expect((await _load(asset)).toJson(), bundled.toJson());
      }
    },
  );
}

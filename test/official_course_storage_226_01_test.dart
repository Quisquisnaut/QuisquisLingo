import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled discovery ignores and preserves Build 225 official overrides',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = CourseService();
      final official = await service.loadBundledCourse('IT');
      final oldStorage = jsonEncode({
        'IT': {
          'course': {
            ...official.toJson(),
            'title': 'Old locally edited official title',
            'baseCourseId': official.courseId,
            'basePublisherId': official.publisherId,
            'baseOfficialCourseVersion': official.officialCourseVersion,
            'baseOfficialChecksum': official.officialChecksum,
            'localCourseVersion': 99,
          },
        },
      });
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'quisquislingo_course_editor_overrides_v6_225',
        oldStorage,
      );
      expect((await service.loadCourse('IT')).toJson(), official.toJson());
      expect(
        preferences.getString('quisquislingo_course_editor_overrides_v6_225'),
        oldStorage,
      );
    },
  );

  test('even malformed obsolete bundled storage is never read', () async {
    const raw = 'not JSON: old override data';
    SharedPreferences.setMockInitialValues({
      'quisquislingo_course_editor_overrides_v6_225': raw,
    });
    final course = await CourseService().loadCourse('IT');
    expect(course.originType, CourseOriginType.bundledOfficial);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {
      'quisquislingo_course_editor_overrides_v6_225',
    });
    expect(
      preferences.getString('quisquislingo_course_editor_overrides_v6_225'),
      raw,
    );
  });

  test(
    'external discovery and update ignore opaque old override content',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bundled = await CourseService().loadBundledCourse('IT');
      Course package(String version) {
        final draft = Course.fromJson({
          ...bundled.toJson(),
          'courseId': 'external_storage_fixture',
          'originType': 'externalOfficial',
          'distributionChannel': 'file',
          'publisherVerificationStatus': 'unverified',
          'officialCourseVersion': version,
        });
        return Course.fromJson({
          ...draft.toJson(),
          'officialChecksum': CourseBackupService.officialContentChecksum(
            draft,
          ),
        });
      }

      final original = package('1');
      final preferences = await SharedPreferences.getInstance();
      const legacy = {
        'localCourseVersion': 99,
        'course': 'unsupported obsolete payload',
      };
      await preferences.setString(
        CourseEditorService.externalOfficialStorageKey,
        jsonEncode({
          original.courseId: {'source': original.toJson(), 'override': legacy},
        }),
      );
      final directory = await Directory.systemTemp.createTemp(
        'qql22601_sources_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
      );
      final editor = CourseEditorService(backupService: backups);
      expect(
        (await editor.listUserCourses()).single.toJson(),
        original.toJson(),
      );
      expect(
        (await editor.officialSourceFor(original))!.toJson(),
        original.toJson(),
      );
      final next = package('2');
      await editor.installExternalOfficialUpdate(next);
      expect((await editor.listUserCourses()).single.toJson(), next.toJson());
      final stored = jsonDecode(
        preferences.getString(CourseEditorService.externalOfficialStorageKey)!,
      );
      expect(stored[original.courseId]['override'], legacy);
      expect(
        (await backups.listOfficialBackups(
          original.courseId,
        )).single.course.toJson(),
        original.toJson(),
      );
      expect(
        preferences.getString(CourseEditorService.userCoursesStorageKey),
        isNull,
      );
    },
  );

  test(
    'official history skips old local manifests without parsing or deleting them',
    () async {
      SharedPreferences.setMockInitialValues({});
      final official = await CourseService().loadBundledCourse('IT');
      final directory = await Directory.systemTemp.createTemp(
        'qql22601_history_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
      );
      await backups.createBackup(
        official,
        backedUpAt: DateTime.utc(2026, 9, 5),
        reason: 'Official source',
      );
      final courseDirectory = await backups.courseBackupDirectory(
        official.courseId,
      );
      final oldManifest = File('${courseDirectory.path}/legacy.json');
      final raw = jsonEncode({
        'course': {'localCourseVersion': 99, 'title': 'Old local content'},
      });
      await oldManifest.writeAsString(raw);
      final history = await backups.listOfficialBackups(official.courseId);
      expect(history.single.course.toJson(), official.toJson());
      expect(history.single.displayedVersion, isNull);
      expect(await oldManifest.readAsString(), raw);
    },
  );

  test(
    'official checksum covers derivative permission and serialized restore metadata',
    () async {
      SharedPreferences.setMockInitialValues({});
      final source = await CourseService().loadBundledCourse('IT');
      final hash = CourseBackupService.officialContentChecksum(source);
      for (final change in [
        {'derivativeWorksPolicy': 'allowed'},
        {'restoredFromVersion': 7},
      ]) {
        expect(
          CourseBackupService.officialContentChecksum(
            Course.fromJson({...source.toJson(), ...change}),
          ),
          isNot(hash),
        );
      }
      final metadataOnly = Course.fromJson({
        ...source.toJson(),
        'publisherVerificationStatus': 'unverified',
        'publisherSignature': 'declared signature',
        'officialChecksum': 'a' * 64,
      });
      expect(CourseBackupService.officialContentChecksum(metadataOnly), hash);
    },
  );

  test(
    'official audio backup verifies assets without rewriting publisher payload paths',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'qql22601_official_audio_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final audio = File('${directory.path}/source.mp3');
      await audio.writeAsBytes([1, 2, 3, 4]);
      final bundled = await CourseService().loadBundledCourse('IT');
      final payload = Course.fromJson({
        ...bundled.toJson(),
        'courseId': 'external_audio_history',
        'originType': 'externalOfficial',
        'distributionChannel': 'file',
        'publisherVerificationStatus': 'unverified',
        'audioLibrary': [
          {'id': 'official-audio', 'text': 'Hello', 'filePath': audio.path},
        ],
      });
      final official = Course.fromJson({
        ...payload.toJson(),
        'officialChecksum': CourseBackupService.officialContentChecksum(
          payload,
        ),
      });
      final backups = CourseBackupService(
        documentsDirectoryProvider: () async => directory,
      );
      final record = await backups.createBackup(
        official,
        backedUpAt: DateTime.utc(2026, 9, 5),
        reason: 'Publisher source update',
      );
      expect(record.assets, hasLength(1));
      expect(record.course.toJson(), official.toJson());
      final loaded = (await backups.listOfficialBackups(
        official.courseId,
      )).single.course;
      expect(
        CourseBackupService.officialContentChecksum(loaded),
        official.officialChecksum,
      );
      expect(loaded.audioLibrary.single.filePath, audio.path);
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _idA = '00000000-0000-4000-8000-00000000000a';
const _idB = '00000000-0000-4000-8000-00000000000b';
const _idC = '00000000-0000-4000-8000-00000000000c';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('new profiles receive unique stable IDs and duplicate names', () async {
    final ids = [_idA, _idB].iterator;
    final profiles = ProfileService(
      idGenerator: () {
        ids.moveNext();
        return ids.current;
      },
    );

    final first = await profiles.createProfile('Marco');
    final second = await profiles.createProfile('Marco');

    expect(first.learnerProfileId, _idA);
    expect(second.learnerProfileId, _idB);
    expect(first.learnerProfileId, isNot(second.learnerProfileId));
    expect(await profiles.getProfiles(), ['Marco', 'Marco']);
    expect(await profiles.getActiveProfileId(), _idB);

    await profiles.setActiveProfileById(_idA);
    expect(await profiles.getActiveProfileId(), _idA);
    expect((await profiles.getProfileById(_idA))?.displayName, 'Marco');
  });

  test(
    'legacy name registry and namespace are ignored by the clean cut',
    () async {
      SharedPreferences.setMockInitialValues({
        'learner_profiles': ['Legacy'],
        'active_learner': 'Legacy',
        'learner_Legacy_xp_IT': 99,
      });
      final profiles = ProfileService();

      expect(await profiles.getProfileRecords(), isEmpty);
      expect(await profiles.getActiveProfileId(), isNull);
      expect(await profiles.getActiveProfile(), isNull);
    },
  );

  test('avatar progress XP and settings are isolated by profile ID', () async {
    final ids = [_idA, _idB].iterator;
    final profiles = ProfileService(
      idGenerator: () {
        ids.moveNext();
        return ids.current;
      },
    );
    await profiles.createProfile('Same', skinTone: 'light', hairTone: 'light');
    final progress = ProgressService(now: () => DateTime(2026, 9, 2));
    final settings = SettingsService();
    await progress.addXp(15, courseCode: 'IT', courseId: 'course-a');
    await progress.completeRound(
      'round-a',
      courseId: 'course-a',
      courseCode: 'IT',
    );
    await profiles.setThemeMode(LearnerThemeMode.dark);
    await settings.setLastSelectedCourseCode('IT');

    await profiles.createProfile('Same', skinTone: 'dark', hairTone: 'dark');
    expect(await progress.getXp(courseCode: 'IT'), 0);
    expect(await progress.getCompletedRounds(courseId: 'course-a'), isEmpty);
    expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);
    expect(await settings.getLastSelectedCourseCode(), isNull);
    expect(
      await profiles.getAvatarAppearanceForProfile(_idB),
      isA<ProfileAvatarAppearance>()
          .having((value) => value.skinTone, 'skin', 'dark')
          .having((value) => value.hairTone, 'hair', 'dark'),
    );

    await profiles.setActiveProfileById(_idA);
    expect(await progress.getXp(courseCode: 'IT'), 15);
    expect(await progress.getCompletedRounds(courseId: 'course-a'), {
      'round-a',
    });
    expect(await profiles.getThemeMode(), LearnerThemeMode.dark);
    expect(await settings.getLastSelectedCourseCode(), 'IT');
  });

  test(
    'logout clears only active ID and creates no default namespace',
    () async {
      final profiles = ProfileService(idGenerator: () => _idA);
      await profiles.createProfile('Logout');
      final prefs = await SharedPreferences.getInstance();
      final before = Map<String, Object?>.fromEntries(
        prefs.getKeys().map((key) => MapEntry(key, prefs.get(key))),
      );

      await profiles.clearActiveProfile();
      await profiles.setSkinTone('dark');
      await SettingsService().setLastSelectedCourseCode('DE');

      expect(prefs.containsKey(ProfileService.activeProfileIdKey), isFalse);
      expect(await profiles.getProfileById(_idA), isNotNull);
      expect(
        prefs.getKeys().where((key) => key.startsWith('learner_default_')),
        isEmpty,
      );
      expect(
        prefs.getString('${ProfileService.prefixForProfileId(_idA)}skin_tone'),
        'medium',
      );
      expect(
        before[ProfileService.profilesKey],
        prefs.get(ProfileService.profilesKey),
      );
    },
  );

  test('deletion removes only the exact opaque namespace', () async {
    final ids = [_idA, _idB].iterator;
    final profiles = ProfileService(
      idGenerator: () {
        ids.moveNext();
        return ids.current;
      },
    );
    await profiles.createProfile('A');
    await profiles.createProfile('A_B');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${ProfileService.prefixForProfileId(_idA)}probe',
      'A',
    );
    await prefs.setString(
      '${ProfileService.prefixForProfileId(_idB)}probe',
      'A_B',
    );

    await profiles.deleteProfileById(_idA);

    expect(await profiles.getProfileById(_idA), isNull);
    expect(await profiles.getProfileById(_idB), isNotNull);
    expect(
      prefs.getString('${ProfileService.prefixForProfileId(_idA)}probe'),
      isNull,
    );
    expect(
      prefs.getString('${ProfileService.prefixForProfileId(_idB)}probe'),
      'A_B',
    );
  });

  test('backup v2 restore preserves identity', () async {
    final profiles = ProfileService(idGenerator: () => _idA);
    final backup = LearnerBackupService(profileService: profiles);
    final document = backup.decodeDocument(
      utf8.encode(
        jsonEncode({
          'format': LearnerBackupService.format,
          'schemaVersion': LearnerBackupService.schemaVersion,
          'learnerProfileId': _idB,
          'displayName': 'Restored',
          'data': {'xp_IT': 42, 'skin_tone': 'dark', 'hair_tone': 'light'},
        }),
      ),
    );

    final restored = await backup.restorePreservingIdentity(document);

    expect(restored.learnerProfileId, _idB);
    expect(restored.displayName, 'Restored');
    expect(await profiles.getActiveProfileId(), _idB);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('${ProfileService.prefixForProfileId(_idB)}xp_IT'), 42);
  });

  test('preserve collision is explicit and replace is non-merging', () async {
    final profiles = ProfileService(idGenerator: () => _idA);
    await profiles.createProfile('Existing');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${ProfileService.prefixForProfileId(_idA)}old',
      'remove',
    );
    final backup = LearnerBackupService(profileService: profiles);
    final document = LearnerBackupDocument(
      schemaVersion: LearnerBackupService.schemaVersion,
      learnerProfileId: _idA,
      displayName: 'Backup name',
      data: const {'new': 'keep'},
    );

    expect(
      () => backup.restorePreservingIdentity(document),
      throwsA(isA<LearnerBackupIdentityCollision>()),
    );
    await backup.restorePreservingIdentity(document, replaceExisting: true);

    expect((await profiles.getProfileById(_idA))?.displayName, 'Backup name');
    expect(
      prefs.getString('${ProfileService.prefixForProfileId(_idA)}old'),
      isNull,
    );
    expect(
      prefs.getString('${ProfileService.prefixForProfileId(_idA)}new'),
      'keep',
    );
  });

  test(
    'separate copy gets a new ID, chosen name, and independent data',
    () async {
      final ids = [_idB, _idC].iterator;
      final profiles = ProfileService(
        idGenerator: () {
          ids.moveNext();
          return ids.current;
        },
      );
      final backup = LearnerBackupService(profileService: profiles);
      final document = LearnerBackupDocument(
        schemaVersion: LearnerBackupService.schemaVersion,
        learnerProfileId: _idA,
        displayName: 'Marco',
        data: const {'xp_IT': 12},
      );

      final sameNameCopy = await backup.importAsSeparateCopy(
        document,
        displayName: 'Marco',
      );
      final renamedCopy = await backup.importAsSeparateCopy(
        document,
        displayName: 'Marco Copy',
      );

      expect(sameNameCopy.learnerProfileId, _idB);
      expect(sameNameCopy.displayName, 'Marco');
      expect(renamedCopy.learnerProfileId, _idC);
      expect(renamedCopy.displayName, 'Marco Copy');
      expect(_idB, isNot(document.learnerProfileId));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${ProfileService.prefixForProfileId(_idB)}xp_IT', 99);
      expect(
        prefs.getInt('${ProfileService.prefixForProfileId(_idC)}xp_IT'),
        12,
      );
      expect(
        prefs.getInt('${ProfileService.prefixForProfileId(_idB)}xp_IT'),
        99,
      );
    },
  );

  test(
    'backup v1 is rejected and export contains v2 identity fields',
    () async {
      final profiles = ProfileService(idGenerator: () => _idA);
      await profiles.createProfile('Exported');
      final backup = LearnerBackupService(profileService: profiles);

      expect(
        () => backup.decodeDocument(
          utf8.encode(
            jsonEncode({'format': 'quisquislingo_learner_backup_v1'}),
          ),
        ),
        throwsFormatException,
      );
      final exported = await backup.exportActiveProfile();
      expect(exported['schemaVersion'], 2);
      expect(exported['learnerProfileId'], _idA);
      expect(exported['displayName'], 'Exported');
    },
  );

  test('learner import reads only Imports/learner_import.json', () async {
    final documents = await Directory.systemTemp.createTemp(
      'qql_learner_import_path_',
    );
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    final backup = LearnerBackupService(
      documentsDirectoryProvider: () async => documents,
    );
    final payload = jsonEncode({
      'format': LearnerBackupService.format,
      'schemaVersion': LearnerBackupService.schemaVersion,
      'learnerProfileId': _idA,
      'displayName': 'Imported',
      'data': {'xp_IT': 42},
    });
    final importPath = await backup.importFilePath();
    expect(
      importPath,
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Imports${Platform.pathSeparator}'
      'learner_import.json',
    );
    await File(importPath).writeAsString(payload);

    final document = await backup.readImportFile();
    expect(document.learnerProfileId, _idA);
    expect(document.displayName, 'Imported');
    expect(document.data['xp_IT'], 42);
  });

  test(
    'learner import no longer reads learner_import.json from Exports',
    () async {
      final documents = await Directory.systemTemp.createTemp(
        'qql_learner_export_not_import_',
      );
      addTearDown(() async {
        if (await documents.exists()) await documents.delete(recursive: true);
      });
      final backup = LearnerBackupService(
        documentsDirectoryProvider: () async => documents,
      );
      final exportDirectory = await backup.transferDirectory();
      await File(
        '${exportDirectory.path}${Platform.pathSeparator}'
        'learner_import.json',
      ).writeAsString('{}');

      expect(
        backup.readImportFile,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              '${Platform.pathSeparator}Imports${Platform.pathSeparator}',
            ),
          ),
        ),
      );
    },
  );

  test('learner export keeps Exports and learner-based filenames', () async {
    final documents = await Directory.systemTemp.createTemp(
      'qql_learner_export_path_',
    );
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    final profiles = ProfileService(idGenerator: () => _idA);
    await profiles.createProfile('Export Name');
    final backup = LearnerBackupService(
      profileService: profiles,
      documentsDirectoryProvider: () async => documents,
    );

    final first = await backup.saveActiveProfile();
    final second = await backup.saveActiveProfile();
    final exportDirectory =
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Exports';
    expect(
      first,
      '$exportDirectory${Platform.pathSeparator}quisquislingo_export_name_backup.json',
    );
    expect(
      second,
      '$exportDirectory${Platform.pathSeparator}quisquislingo_export_name_backup_2.json',
    );
    expect(await File(first).exists(), isTrue);
    expect(await File(second).exists(), isTrue);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/user_recovery_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _identityId = '40000000-0000-4000-8000-000000000004';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory exports;
  late Directory imports;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    root = await Directory.systemTemp.createTemp('qql_recovery_key_test_');
    exports = Directory('${root.path}${Platform.pathSeparator}Exports');
    imports = Directory('${root.path}${Platform.pathSeparator}Imports');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'export writes identity-only sensitive key directly to Exports',
    () async {
      final profiles = ProfileService(
        idGenerator: () => _identityId,
        numericSuffixGenerator: () => 12345,
        randomIndex: (_) => 0,
        secureBytes: (length) => List<int>.generate(length, (i) => i + 1),
      );
      await profiles.createProfile(
        'Mario Rossi',
        discordHandle: 'mario',
        accessPin: '1234',
      );
      final service = _service(profiles, exports, imports);

      final path = await service.exportActiveUserRecoveryKey();
      expect(File(path).parent.path, exports.path);
      final decoded = jsonDecode(await File(path).readAsString()) as Map;
      expect(decoded['format'], UserRecoveryKeyService.format);
      expect(decoded['learnerProfileId'], _identityId);
      expect(decoded.containsKey('displayName'), isFalse);
      expect(decoded.containsKey('discordHandle'), isFalse);
      expect(decoded.toString().contains('1234'), isFalse);
      expect(decoded.containsKey('accessPin'), isFalse);
      final backupService = LearnerBackupService(
        profileService: profiles,
        documentsDirectoryProvider: () async => root,
      );
      final backup = await backupService.exportActiveProfile();
      expect(backup['screenNameSuffix'], '12345');
      expect(
        backupService
            .decodeDocument(utf8.encode(jsonEncode(backup)))
            .screenNameSuffix,
        '12345',
      );
      final backupData = backup['data'] as Map;
      expect(backupData.containsKey('access_pin_verifier_v1'), isFalse);
      expect(backupData.containsKey('user_recovery_secret_v1'), isFalse);
    },
  );

  test(
    'import restores the same identity but accepts a different visible name',
    () async {
      final originalProfiles = ProfileService(
        idGenerator: () => _identityId,
        numericSuffixGenerator: () => 12345,
        randomIndex: (_) => 0,
        secureBytes: (length) => List<int>.filled(length, 7),
      );
      await originalProfiles.createProfile('Mario Rossi');
      final originalService = _service(originalProfiles, exports, imports);
      final exported = await originalService.exportActiveUserRecoveryKey();
      await imports.create(recursive: true);
      final importFile = File(
        '${imports.path}${Platform.pathSeparator}mario.user-recovery-key.json',
      );
      await importFile.writeAsBytes(await File(exported).readAsBytes());

      SharedPreferences.setMockInitialValues({});
      ProfileService.beginAccessSession();
      final otherDeviceProfiles = ProfileService(
        idGenerator: () => '50000000-0000-4000-8000-000000000005',
        numericSuffixGenerator: () => 54321,
        randomIndex: (_) => 0,
      );
      final otherDeviceService = _service(
        otherDeviceProfiles,
        exports,
        imports,
      );
      final keys = await otherDeviceService.findImportableUserRecoveryKeys();
      expect(keys, hasLength(1));

      final recovered = await otherDeviceService.importIdentity(
        keys.single.document,
        screenNameText: 'Aldo Bianchi',
      );
      expect(recovered.learnerProfileId, _identityId);
      expect(recovered.displayName, 'Aldo Bianchi 54321');
      expect(await otherDeviceProfiles.getActiveProfileId(), _identityId);
      final ownedCourse = Course(
        courseId: 'recovered-owner-course',
        creatorProfileId: _identityId,
        ownership: const CourseOwnership.individual(_identityId),
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Recovered ownership',
        ttsLanguage: 'it-IT',
        version: '1',
        lessons: const [],
      );
      expect(
        CourseAccessPolicy.evaluate(
          ownedCourse,
          profileId: recovered.learnerProfileId,
        ).canEditOriginal,
        isTrue,
      );
    },
  );

  test('zero, multiple and existing-identity conflicts are explicit', () async {
    final profiles = ProfileService(
      idGenerator: () => _identityId,
      numericSuffixGenerator: () => 12345,
      randomIndex: (_) => 0,
      secureBytes: (length) => List<int>.filled(length, 9),
    );
    final service = _service(profiles, exports, imports);
    expect(await service.findImportableUserRecoveryKeys(), isEmpty);

    await profiles.createProfile('Mario Rossi');
    final first = await service.exportActiveUserRecoveryKey();
    final second = await service.exportActiveUserRecoveryKey();
    await imports.create(recursive: true);
    await File(first).copy(
      '${imports.path}${Platform.pathSeparator}first.user-recovery-key.json',
    );
    await File(second).copy(
      '${imports.path}${Platform.pathSeparator}second.user-recovery-key.json',
    );
    final candidates = await service.findImportableUserRecoveryKeys();
    expect(candidates, hasLength(2));
    await expectLater(
      service.importIdentity(
        candidates.first.document,
        screenNameText: 'Other Name',
      ),
      throwsA(isA<UserRecoveryIdentityConflict>()),
    );
    expect(await profiles.getProfileRecords(), hasLength(1));
  });
}

UserRecoveryKeyService _service(
  ProfileService profiles,
  Directory exports,
  Directory imports,
) => UserRecoveryKeyService(
  profileService: profiles,
  exportsDirectoryProvider: () async => exports,
  importsDirectoryProvider: () async => imports,
  secureBytes: (length) => List<int>.generate(length, (i) => i + 20),
);

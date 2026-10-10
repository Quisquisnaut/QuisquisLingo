import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/import/safe_file_name.dart';
import 'package:quisquislingo_app/services/page_blocks.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/user_recovery_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

// Build 270 Revision 6: the audit's smaller import, link and log findings.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Windows device names are not file names', () {
    for (final name in [
      'NUL.png',
      'nul.PNG',
      'con.webp',
      'COM1.jpg',
      'lpt9',
      'aux',
      'picture.',
    ]) {
      expect(isReservedWindowsName(name), isTrue, reason: name);
    }
    for (final name in [
      'null.png',
      'console.webp',
      'com10.png',
      'picture.png',
    ]) {
      expect(isReservedWindowsName(name), isFalse, reason: name);
    }
  });

  test('a Page link may not hide its site behind a user part', () {
    expect(
      PageBlocks.isAcceptableLink('https://www.youtube.com/watch?v=x'),
      isTrue,
    );
    expect(
      PageBlocks.isAcceptableLink('https://youtube.com@other.example/'),
      isFalse,
    );
    expect(
      PageBlocks.isAcceptableLink('https://user:pw@example.org/'),
      isFalse,
    );
    expect(PageBlocks.isAcceptableLink('http://example.org/'), isFalse);
  });

  test('an imported Course ID is short and plain', () async {
    final pattern = CustomCourseTransferService.importableCourseId;
    for (final id in [
      'course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05',
      'italian-demo-2-239',
      'sample_ko_en_ko',
      'a' * 64,
    ]) {
      expect(pattern.hasMatch(id), isTrue, reason: id);
    }
    for (final id in ['a' * 65, '../x', 'a b', '.hidden', 'x\u202Ey', '']) {
      expect(pattern.hasMatch(id), isFalse, reason: id);
    }
    final json =
        jsonDecode(
              File(
                'assets/courses/english_from_italian_it_en.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    json['courseId'] = 'c' * 70;
    await expectLater(
      CustomCourseTransferService().courseFromBytes(
        Uint8List.fromList(utf8.encode(jsonEncode(json))),
        'long.json',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Course ID must be'),
        ),
      ),
    );
  });

  test('logs write the person\'s own folder as ~', () {
    final home =
        Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME']!;
    final sep = Platform.pathSeparator;
    expect(
      DiagnosticLogService.redact(
        'Cannot open $home${sep}Documents${sep}x.json',
      ),
      'Cannot open ~${sep}Documents${sep}x.json',
    );
    expect(DiagnosticLogService.redact('no path here'), 'no path here');
  });

  group('User Recovery Keys', () {
    late Directory exports;
    late Directory imports;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ProfileService.beginAccessSession();
      keepCrashLogUnavailable();
      exports = await Directory.systemTemp.createTemp('qql_270_keys_out_');
      imports = await Directory.systemTemp.createTemp('qql_270_keys_in_');
    });

    tearDown(() async {
      for (final directory in [exports, imports]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    });

    UserRecoveryKeyService service(ProfileService profiles) =>
        UserRecoveryKeyService(
          profileService: profiles,
          exportsDirectoryProvider: () async => exports,
          importsDirectoryProvider: () async => imports,
          secureBytes: (length) => List<int>.generate(length, (i) => i + 20),
        );

    test('one file that is not a key does not hide the others', () async {
      final profiles = ProfileService(
        idGenerator: () => '50000000-0000-4000-8000-000000000005',
      );
      await profiles.createProfile('Mario Rossi');
      final exported = await service(profiles).exportActiveUserRecoveryKey();
      final sep = Platform.pathSeparator;
      await File(
        '${imports.path}${sep}a-broken.user-recovery-key.json',
      ).writeAsString('{"not": "a key"');
      await File(
        '${imports.path}${sep}mario.user-recovery-key.json',
      ).writeAsBytes(await File(exported).readAsBytes());

      final keys = await service(profiles).findImportableUserRecoveryKeys();
      expect(keys, hasLength(1));
      expect(keys.single.path, endsWith('mario.user-recovery-key.json'));
      expect(
        (await SharedPreferences.getInstance()).getString(
          'quisquislingo_diagnostic_log',
        ),
        contains('a-broken.user-recovery-key.json'),
      );
    });

    test('with no usable key the reason of each file is given', () async {
      await File(
        '${imports.path}${Platform.pathSeparator}only.user-recovery-key.json',
      ).writeAsString('{"not": "a key"');
      await expectLater(
        service(ProfileService()).findImportableUserRecoveryKeys(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('only.user-recovery-key.json'),
              contains('not valid JSON'),
            ),
          ),
        ),
      );
    });
  });
}

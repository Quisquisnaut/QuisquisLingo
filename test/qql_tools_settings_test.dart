import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProfileService profiles;
  late String adminId;
  late String learnerId;
  late File executable;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_tools_settings_');
    profiles = ProfileService();
    adminId = (await profiles.createProfile('Admin')).learnerProfileId;
    learnerId = (await profiles.createProfile('Learner')).learnerProfileId;
    await profiles.setActiveProfileById(adminId);
    executable = File(
      '${root.path}${Platform.pathSeparator}qql-tools'
      '${Platform.isWindows ? '.exe' : ''}',
    );
    await executable.writeAsString('test executable');
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a file handle.
    }
  });

  test('path survives a new service instance and profile switch', () async {
    final settings = SettingsService();
    final prefs = await SharedPreferences.getInstance();
    final keysBeforeRead = prefs.getKeys();
    expect(await settings.getQqlToolsExecutablePath(), isNull);
    expect(prefs.getKeys(), keysBeforeRead, reason: 'a read must not write');

    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: executable.path,
    );
    await profiles.setActiveProfileById(learnerId);
    expect(
      await SettingsService().getQqlToolsExecutablePath(),
      executable.path,
    );

    final matchingKeys = prefs.getKeys().where(
      (key) => prefs.get(key) == executable.path,
    );
    expect(matchingKeys, hasLength(1));
    expect(
      matchingKeys.single.startsWith(
        ProfileService.prefixForProfileId(adminId),
      ),
      isFalse,
    );
    expect(
      matchingKeys.single.startsWith(
        ProfileService.prefixForProfileId(learnerId),
      ),
      isFalse,
    );
  });

  test('only the active Admin can set or clear the device path', () async {
    final settings = SettingsService();
    await expectLater(
      settings.setQqlToolsExecutablePath(
        actorProfileId: learnerId,
        path: executable.path,
      ),
      throwsStateError,
    );
    expect(await settings.getQqlToolsExecutablePath(), isNull);

    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: executable.path,
    );
    await profiles.setActiveProfileById(learnerId);
    await expectLater(
      settings.setQqlToolsExecutablePath(
        actorProfileId: adminId,
        path: executable.path,
      ),
      throwsStateError,
    );
    await expectLater(
      settings.clearQqlToolsExecutablePath(actorProfileId: learnerId),
      throwsStateError,
    );
    expect(await settings.getQqlToolsExecutablePath(), executable.path);

    await profiles.setActiveProfileById(adminId);
    await settings.clearQqlToolsExecutablePath(actorProfileId: adminId);
    expect(await SettingsService().getQqlToolsExecutablePath(), isNull);
  });

  test('invalid local paths do not replace a configured executable', () async {
    final settings = SettingsService();
    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: executable.path,
    );

    for (final path in <String>[
      '',
      '   ',
      'https://example.com/qql-tools',
      'file:///tmp/qql-tools',
      root.path,
      '${root.path}${Platform.pathSeparator}missing-qql-tools',
    ]) {
      await expectLater(
        settings.setQqlToolsExecutablePath(
          actorProfileId: adminId,
          path: path,
        ),
        throwsArgumentError,
        reason: path,
      );
      expect(await settings.getQqlToolsExecutablePath(), executable.path);
    }
  });

  test('stores the exact selected filename, including spaces', () async {
    final name = Platform.isWindows ? 'qql tools.exe' : 'qql tools ';
    final spaced = File('${root.path}${Platform.pathSeparator}$name');
    await spaced.writeAsString('test executable');

    final settings = SettingsService();
    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: spaced.path,
    );
    expect(await SettingsService().getQqlToolsExecutablePath(), spaced.path);
  });

  test(
    'POSIX accepts a link to a file but rejects directory and dangling links',
    () async {
      final settings = SettingsService();
      final executableLink = Link(
        '${root.path}${Platform.pathSeparator}qql-tools-link',
      );
      await executableLink.create(executable.path);
      await settings.setQqlToolsExecutablePath(
        actorProfileId: adminId,
        path: executableLink.path,
      );
      expect(
        await SettingsService().getQqlToolsExecutablePath(),
        executableLink.path,
      );

      final directoryLink = Link(
        '${root.path}${Platform.pathSeparator}directory-link',
      );
      await directoryLink.create(root.path);
      final danglingLink = Link(
        '${root.path}${Platform.pathSeparator}dangling-link',
      );
      await danglingLink.create(
        '${root.path}${Platform.pathSeparator}missing-target',
      );
      for (final path in [directoryLink.path, danglingLink.path]) {
        await expectLater(
          settings.setQqlToolsExecutablePath(
            actorProfileId: adminId,
            path: path,
          ),
          throwsArgumentError,
        );
        expect(
          await settings.getQqlToolsExecutablePath(),
          executableLink.path,
        );
      }
    },
    skip: Platform.isWindows ? 'POSIX symlink behavior' : null,
  );

  test('Windows accepts an exe file and rejects shell scripts', () async {
    if (!Platform.isWindows) return;
    final settings = SettingsService();
    for (final extension in ['.bat', '.cmd']) {
      final script = File('${root.path}${Platform.pathSeparator}tool$extension');
      await script.writeAsString('echo test');
      await expectLater(
        settings.setQqlToolsExecutablePath(
          actorProfileId: adminId,
          path: script.path,
        ),
        throwsArgumentError,
      );
    }
    expect(await settings.getQqlToolsExecutablePath(), isNull);
    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: executable.path,
    );
    expect(await settings.getQqlToolsExecutablePath(), executable.path);
  });
}

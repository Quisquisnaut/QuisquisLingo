import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/device_administration_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/app_restart_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _course = Course(
  courseId: 'qql-239-admin-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 239 Admin Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late ProfileService profiles;
  late AppResetService service;
  late String adminId;
  var restarted = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_admin_ui_');
    profiles = ProfileService();
    adminId = (await profiles.createProfile('Admin One')).learnerProfileId;
    await profiles.setActiveProfileById(adminId);
    service = AppResetService(
      profiles: profiles,
      documentsDirectory: () async => Directory('${root.path}/docs'),
      supportDirectory: () async => Directory('${root.path}/support'),
    );
    restarted = 0;
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  // Real file-system calls inside the reset flow do not complete under the
  // test clock, so give them real time before settling the frame.
  Future<void> settle(WidgetTester tester) async {
    // Each file-system call needs a real-time window; the flow makes several.
    for (var i = 0; i < 12; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceAdministrationScreen(
          course: _course,
          onManageLearners: (_) async {},
          profileService: profiles,
          resetService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a non-admin sees only an explanation', (tester) async {
    final learner = await profiles.createProfile('Learner');
    await profiles.setActiveProfileById(learner.learnerProfileId);
    await open(tester);
    expect(
      find.text('Device Administration is available only to admins.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('admin-reset-locked')), findsNothing);
  });

  testWidgets('without a PIN the reset options are locked and explained', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('admin-reset-locked')), findsOneWidget);
    expect(
      find.textContaining('every reset asks for your admin PIN'),
      findsOneWidget,
    );
    for (final scope in AppResetScope.values) {
      expect(find.byKey(Key('admin-reset-button-${scope.name}')), findsNothing);
    }

    await tester.tap(find.byKey(const Key('admin-reset-set-pin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('admin-set-pin')), '1234');
    await tester.enterText(
      find.byKey(const Key('admin-set-pin-confirm')),
      '1234',
    );
    await tester.tap(find.text('Save PIN'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-reset-locked')), findsNothing);
    expect(
      find.byKey(const Key('admin-reset-button-everything')),
      findsOneWidget,
    );
  });

  testWidgets('every reset states what it removes and keeps as visible text', (
    tester,
  ) async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '1234');
    await open(tester);
    for (final scope in AppResetScope.values) {
      expect(find.byKey(Key('admin-reset-${scope.name}')), findsOneWidget);
    }
    expect(find.text('Removes'), findsNWidgets(AppResetScope.values.length));
    expect(find.text('Keeps'), findsNWidgets(AppResetScope.values.length));
    expect(find.text('Wipe out everything (NUKE EVERYTHING!)'), findsOneWidget);
    // The explanations are ordinary text, not tooltips, so they show on touch.
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
  });

  testWidgets('the layout stays usable on a narrow phone', (tester) async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '1234');
    await open(tester, size: const Size(320, 700));
    await tester.scrollUntilVisible(
      find.byKey(const Key('admin-reset-button-everything')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the help button opens a help page that lists admin powers and limits',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('admin-team-manager')), findsNothing);
      expect(find.text('Team Manager'), findsNothing);

      await tester.tap(find.byKey(const Key('admin-help')));
      await tester.pumpAndSettle();
      expect(find.text('Device Administration Help'), findsOneWidget);
      for (final title in const [
        'What admins CAN do',
        'What admins CANNOT do',
        'The reset options',
        'Forgotten PIN',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Tooltip),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('the startup mode toggle is saved and explained', (tester) async {
    await open(tester);
    expect(
      find.textContaining('opens directly as the learner who used it last'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('admin-startup-mode')));
    await tester.pumpAndSettle();
    expect(await profiles.asksWhichLearnerAtStartup(), isTrue);
    expect(find.textContaining('every time QQL starts'), findsOneWidget);
  });

  testWidgets('resetting learner progress walks through every step', (
    tester,
  ) async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '1234');
    final prefs = await SharedPreferences.getInstance();
    final key = '${ProfileService.prefixForProfileId(adminId)}xp_it';
    await prefs.setInt(key, 50);
    await open(tester);

    await tester.tap(
      find.byKey(const Key('admin-reset-button-learnerProgress')),
    );
    await settle(tester);
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('This cannot be undone.'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('admin-reset-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Back up first?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-reset-skip-backup')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(prefs.getInt(key), 50, reason: 'nothing deleted before the PIN');

    await tester.enterText(find.byKey(const Key('admin-reset-pin')), '0000');
    await tester.tap(find.byKey(const Key('admin-reset-run')));
    await settle(tester);
    expect(find.text('Incorrect PIN. Nothing was changed.'), findsOneWidget);
    expect(prefs.getInt(key), 50);

    await tester.enterText(find.byKey(const Key('admin-reset-pin')), '1234');
    await tester.tap(find.byKey(const Key('admin-reset-run')));
    await settle(tester);
    expect(prefs.containsKey(key), isFalse);

    // Regression: the admin must stay logged in and see the page afterwards.
    expect(
      find.text('Device Administration is available only to admins.'),
      findsNothing,
    );
    expect(await profiles.getActiveProfileId(), adminId);
    expect(await profiles.hasAccessPin(adminId), isTrue);
    expect(
      find.byKey(const Key('admin-reset-button-everything')),
      findsOneWidget,
    );
  });

  testWidgets('the backup step is honest that it covers only the admin', (
    tester,
  ) async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '1234');
    await profiles.createProfile('Learner Two');
    await profiles.setActiveProfileById(adminId, accessPin: '1234');
    await open(tester);

    await tester.tap(
      find.byKey(const Key('admin-reset-button-learnerProgress')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('admin-reset-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Back up first?'), findsOneWidget);
    expect(find.textContaining('only YOUR OWN data'), findsOneWidget);
    expect(find.textContaining('ask each of them to log in'), findsOneWidget);
    expect(find.textContaining('Learner Two'), findsWidgets);
    expect(find.text('Open my User Data to back up'), findsOneWidget);
  });

  testWidgets('NUKE needs the typed phrase, the PIN, and restarts the app', (
    tester,
  ) async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '1234');
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppRestartScope(
        child: Builder(
          builder: (context) {
            restarted++;
            return MaterialApp(
              home: DeviceAdministrationScreen(
                course: _course,
                onManageLearners: (_) async {},
                profileService: profiles,
                resetService: service,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final builds = restarted;

    await tester.ensureVisible(
      find.byKey(const Key('admin-reset-button-everything')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-reset-button-everything')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('admin-reset-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-reset-skip-backup')));
    await tester.pumpAndSettle();

    final proceed = find.byKey(const Key('admin-nuke-continue'));
    expect(tester.widget<FilledButton>(proceed).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('admin-nuke-phrase')), 'nuke');
    await tester.pump();
    expect(tester.widget<FilledButton>(proceed).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('admin-nuke-phrase')), 'NUKE');
    await tester.pump();
    await tester.tap(proceed);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('admin-reset-pin')), '1234');
    await tester.tap(find.byKey(const Key('admin-reset-run')));
    await settle(tester);

    expect(await profiles.getProfileRecords(), isEmpty);
    expect(restarted, greaterThan(builds));
  });

  testWidgets('Settings shows Device Administration only to admins', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      find.byKey(const Key('settings-device-administration')),
      findsOneWidget,
    );

    final learner = await profiles.createProfile('Learner');
    await profiles.setActiveProfileById(learner.learnerProfileId);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      find.byKey(const Key('settings-device-administration')),
      findsNothing,
    );
  });

  test(
    'startup policy asks only when there is more than one learner',
    () async {
      final second = await profiles.createProfile('Second');
      await profiles.setActiveProfileById(second.learnerProfileId);
      await profiles.setAsksWhichLearnerAtStartup(
        actorProfileId: adminId,
        enabled: true,
      );
      await profiles.applyStartupProfilePolicy();
      expect(await profiles.getActiveProfileId(), isNull);

      await profiles.deleteProfileById(
        second.learnerProfileId,
        actorProfileId: adminId,
      );
      await profiles.setActiveProfileById(adminId);
      await profiles.applyStartupProfilePolicy();
      expect(await profiles.getActiveProfileId(), adminId);
    },
  );

  test('startup mode can be changed only by an admin', () async {
    final learner = await profiles.createProfile('Learner');
    expect(
      () => profiles.setAsksWhichLearnerAtStartup(
        actorProfileId: learner.learnerProfileId,
        enabled: true,
      ),
      throwsStateError,
    );
  });

  test(
    'deleting the active learner does not auto-pick another in ask mode',
    () async {
      final second = await profiles.createProfile('Second');
      await profiles.setAsksWhichLearnerAtStartup(
        actorProfileId: adminId,
        enabled: true,
      );
      await profiles.setActiveProfileById(second.learnerProfileId);
      await profiles.deleteProfileById(
        second.learnerProfileId,
        actorProfileId: adminId,
      );
      expect(await profiles.getActiveProfileId(), isNull);
    },
  );
}

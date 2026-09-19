import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/device_administration_screen.dart';
import 'package:quisquislingo_app/screens/update_settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/update_notice_service.dart';
import 'package:quisquislingo_app/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

UpdateRelease _release(String version) => UpdateRelease(
  tagName: 'v$version',
  version: version,
  title: 'Release $version',
  notes: '',
  htmlUrl: 'https://github.com/example/releases/tag/v$version',
  assets: const [],
);

final _course = Course(
  courseId: 'qql-239-update-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Update Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileService profiles;
  late String adminId;
  late String otherId;
  var today = DateTime(2026, 9, 20, 9);

  UpdateNoticeService notices() =>
      UpdateNoticeService(profiles: profiles, now: () => today);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    UpdateNoticeService.setPending(null);
    today = DateTime(2026, 9, 20, 9);
    profiles = ProfileService();
    adminId = (await profiles.createProfile(
      'Admin One',
      generateScreenNameSuffix: false,
    )).learnerProfileId;
    otherId = (await profiles.createProfile(
      'Learner Two',
      generateScreenNameSuffix: false,
    )).learnerProfileId;
    await profiles.setActiveProfileById(adminId);
  });

  tearDown(() => UpdateNoticeService.setPending(null));

  test('nothing is due without a pending release', () async {
    expect(await notices().dueForActiveLearner(), isNull);
  });

  test('a learner sees the notice once a day and again the next day', () async {
    UpdateNoticeService.setPending(_release('2.0.40'));
    expect(await notices().dueForActiveLearner(), isNotNull);

    await notices().markShown(_release('2.0.40'));
    expect(await notices().dueForActiveLearner(), isNull);

    today = DateTime(2026, 9, 20, 23, 59);
    expect(await notices().dueForActiveLearner(), isNull);

    today = DateTime(2026, 9, 21, 0, 1);
    expect(await notices().dueForActiveLearner(), isNotNull);
  });

  test('every learner is told, not only the first one', () async {
    UpdateNoticeService.setPending(_release('2.0.40'));
    await notices().markShown(_release('2.0.40'));
    expect(await notices().dueForActiveLearner(), isNull);

    await profiles.setActiveProfileById(otherId);
    expect(
      await notices().dueForActiveLearner(),
      isNotNull,
      reason: 'the second learner has not been told yet',
    );
    await notices().markShown(_release('2.0.40'));
    expect(await notices().dueForActiveLearner(), isNull);
  });

  test('a newer release is announced again even on the same day', () async {
    UpdateNoticeService.setPending(_release('2.0.40'));
    await notices().markShown(_release('2.0.40'));
    UpdateNoticeService.setPending(_release('2.0.41'));
    expect(await notices().dueForActiveLearner(), isNotNull);
  });

  test('nobody is told before a learner is active', () async {
    UpdateNoticeService.setPending(_release('2.0.40'));
    await profiles.clearActiveProfile();
    expect(await notices().dueForActiveLearner(), isNull);
  });

  testWidgets('the popup offers Not today, not Not now, and says why', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => UpdateNoticeService.show(
              context,
              _release('2.0.40'),
              UpdateService(),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('QuisquisLingo update available'), findsOneWidget);
    expect(find.text('Not today'), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
    expect(find.textContaining('appears again tomorrow'), findsOneWidget);
    await tester.tap(find.byKey(const Key('update-notice-not-today')));
    await tester.pumpAndSettle();
    expect(find.text('QuisquisLingo update available'), findsNothing);
  });

  test('the update check does not depend on the one-time Beta notice', () {
    final source = File('lib/main.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _showInstructions()');
    final end = source.indexOf('Future<void> _checkForUpdateAtStartup()');
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    // The Beta notice returns early once seen, so the check must not live in it.
    expect(
      source.substring(start, end).contains('_checkForUpdateAtStartup()'),
      isFalse,
    );
    expect(source.contains('await _showInstructions();'), isTrue);
  });

  testWidgets('only an admin can change the startup update check', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: UpdateSettingsScreen(profileService: profiles)),
    );
    await tester.pumpAndSettle();
    SwitchListTile tile() => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Check automatically at startup'),
    );
    expect(tile().onChanged, isNotNull);
    expect(find.textContaining('only by an admin'), findsNothing);

    await profiles.setActiveProfileById(otherId);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(home: UpdateSettingsScreen(profileService: profiles)),
    );
    await tester.pumpAndSettle();
    expect(tile().onChanged, isNull);
    expect(find.textContaining('only by an admin'), findsOneWidget);
  });

  testWidgets('Device Administration lists Update first', (tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceAdministrationScreen(
          course: _course,
          onManageLearners: (_) async {},
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final update = find.byKey(const Key('admin-update'));
    expect(update, findsOneWidget);
    expect(
      tester.getTopLeft(update).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('admin-manage-learners'))).dy,
      ),
    );
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(find.byType(UpdateSettingsScreen), findsOneWidget);
  });
}

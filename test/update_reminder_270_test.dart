import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/update_settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/update_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

// Build 270 Revision 10 (owner decisions of 10 October 2026): Android has
// no internet permission, so QQL reminds each learner every two weeks to
// check for a newer QuisquisLingo instead of checking itself.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final applies = UpdateReminder.applies;
  late DateTime now;
  final profiles = ProfileService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    for (final (id, name) in [(_alice, 'Alice'), (_bob, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_alice);
    now = DateTime.utc(2026, 10, 10, 9);
    UpdateReminder.applies = () => true;
  });

  tearDown(() => UpdateReminder.applies = applies);

  UpdateReminder reminder() => UpdateReminder(now: () => now);

  test(
    'nothing right after install; then every two weeks, per learner',
    () async {
      expect(await reminder().dueForActiveLearner(), isFalse);
      now = now.add(const Duration(days: 13, hours: 23));
      expect(await reminder().dueForActiveLearner(), isFalse);
      now = now.add(const Duration(hours: 1));
      expect(await reminder().dueForActiveLearner(), isTrue);
      await reminder().markShown();
      expect(await reminder().dueForActiveLearner(), isFalse);

      // Bob's count starts with his own first start-up.
      await profiles.setActiveProfileById(_bob);
      expect(await reminder().dueForActiveLearner(), isFalse);
      now = now.add(const Duration(days: 14));
      expect(await reminder().dueForActiveLearner(), isTrue);
    },
  );

  test('never on other systems, never with the setting off', () async {
    expect(await reminder().dueForActiveLearner(), isFalse);
    now = now.add(const Duration(days: 30));
    await SettingsService().setAutomaticUpdateCheckEnabled(false);
    expect(await reminder().dueForActiveLearner(), isFalse);
    await SettingsService().setAutomaticUpdateCheckEnabled(true);
    UpdateReminder.applies = () => false;
    expect(await reminder().dueForActiveLearner(), isFalse);
    UpdateReminder.applies = () => true;
    expect(await reminder().dueForActiveLearner(), isTrue);
  });

  testWidgets('the reminder says what to do', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => UpdateReminder.show(context),
            child: const Text('show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update-reminder')), findsOneWidget);
    expect(find.text('Check for a newer QuisquisLingo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('update-reminder-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update-reminder')), findsNothing);
  });

  testWidgets('on Android the Update page has the reminder and no check', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UpdateSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Remind me to check for a newer version'), findsOneWidget);
    expect(find.text('Check for updates'), findsNothing);
    expect(find.text('Last checked'), findsNothing);

    UpdateReminder.applies = () => false;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: UpdateSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Check automatically at startup'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
  });
}

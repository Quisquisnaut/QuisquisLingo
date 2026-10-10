import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Build 270 Revision 2 (audit item 4): the week key in calendar days, and a
// weekly rollover that a crash or a concurrent award cannot spoil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Week learner');
  });

  test('every day of a week has its Sunday as week key, clock changes '
      'included', () {
    final xp = XpService();
    // UTC days have no clock changes: the expected Sunday, counted in days.
    for (
      var utc = DateTime.utc(2026);
      utc.year == 2026;
      utc = utc.add(const Duration(days: 1))
    ) {
      final sunday = utc.subtract(Duration(days: utc.weekday % 7));
      for (final hour in [0, 1, 12, 23]) {
        final local = DateTime(utc.year, utc.month, utc.day, hour, 30);
        expect(xp.weekKeyFor(local), _day(sunday), reason: '$local');
      }
    }
  });

  test('XP of the week the clocks go forward stays one week', () async {
    // In Europe/Rome the clocks went forward on Sunday 29 March 2026.
    final clock = _Clock(DateTime(2026, 3, 29, 10));
    final xp = XpService(now: clock.call);
    await xp.addXp(10, courseCode: 'IT', courseId: 'c');
    clock.value = DateTime(2026, 3, 30, 0, 30);
    expect(await xp.getWeeklyXp(), 10);
    await xp.addXp(5, courseCode: 'IT', courseId: 'c');
    clock.value = DateTime(2026, 4, 4, 23, 30);
    expect(await xp.getWeeklyXp(), 15);
    clock.value = DateTime(2026, 4, 5, 0, 30);
    expect(await xp.getWeeklyXp(), 0);
    expect(await xp.getLastWeekXp(), 15);
  });

  Future<void> seed(Map<String, Object> values) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = ProfileService();
    for (final MapEntry(:key, :value) in values.entries) {
      final k = await profiles.key(key);
      if (value is int) await prefs.setInt(k, value);
      if (value is String) await prefs.setString(k, value);
    }
  }

  for (final (label, values) in [
    (
      'after last week was copied',
      <String, Object>{
        'week_xp_week': '2026-10-04',
        'week_xp': 50,
        'last_week_xp_week': '2026-10-04',
        'last_week_xp': 50,
      },
    ),
    (
      'after the totals were zeroed',
      <String, Object>{
        'week_xp_week': '2026-10-04',
        'week_xp': 0,
        'week_xp_by_course': '{}',
        'last_week_xp_week': '2026-10-04',
        'last_week_xp': 50,
      },
    ),
  ]) {
    test('a rollover cut short $label keeps last week', () async {
      await seed(values);
      final xp = XpService(now: () => DateTime(2026, 10, 12, 9));
      expect(await xp.getWeeklyXp(), 0);
      expect(await xp.getLastWeekXp(), 50);
    });
  }

  test('awards made at the same time all count', () async {
    final clock = _Clock(DateTime(2026, 10, 10, 9));
    final xp = XpService(now: clock.call);
    await xp.addXp(1, courseCode: 'IT', courseId: 'c');
    // A new week: the awards race the rollover too.
    clock.value = DateTime(2026, 10, 12, 9);
    await Future.wait([
      for (var i = 0; i < 20; i++) xp.addXp(5, courseCode: 'IT', courseId: 'c'),
    ]);
    expect(await xp.getXp(courseCode: 'IT'), 101);
    expect(await xp.getWeeklyXp(), 100);
    expect(await xp.getLastWeekXp(), 1);
  });
}

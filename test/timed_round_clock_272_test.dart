import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/timed_round_clock.dart';

/// Build 272 Revision 7: the countdown of a Timed Round attempt has an owner.
///
/// `testWidgets` is used only for its clock of timers: `tester.pump(d)` lets
/// `d` of timer time pass. The time the clock reads is `now`, set by hand,
/// as on the Round screen's `timedClock`.
void main() {
  late DateTime now;
  late int refreshes;
  late int dues;
  late bool running;
  late TimedRoundClock clock;

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 12);
    refreshes = 0;
    dues = 0;
    running = true;
    clock = TimedRoundClock(
      now: () => now,
      canRefresh: () => running,
      onSecondsChanged: () => refreshes++,
      onDue: () => dues++,
    );
  });

  test('before the start it shows the whole limit, or zero without one', () {
    expect(clock.limitSeconds, isNull);
    expect(clock.secondsLeft, 0);
    clock.setLimit(90);
    expect(clock.limitSeconds, 90);
    expect(clock.secondsLeft, 90);
    expect(clock.isDue, isFalse);
    expect(clock.expired, isFalse);
    expect(clock.completedInTime, isFalse);
    clock.setLimit(null);
    expect(clock.secondsLeft, 0);
  });

  testWidgets('without a limit it never starts', (tester) async {
    clock.start();
    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(hours: 1));
    expect(refreshes, 0);
    expect(dues, 0);
    expect(clock.isDue, isFalse);
  });

  testWidgets('a started second counts until it ends', (tester) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(milliseconds: 1));
    await tester.pump(TimedRoundClock.refresh);
    expect(clock.secondsLeft, 30);
    now = now.add(const Duration(milliseconds: 999));
    await tester.pump(TimedRoundClock.refresh);
    expect(clock.secondsLeft, 29);
    now = now.add(const Duration(milliseconds: 28999));
    await tester.pump(TimedRoundClock.refresh);
    expect(clock.secondsLeft, 1);
    expect(refreshes, 3);
    expect(dues, 0);
    clock.stop();
  });

  testWidgets('the deadline is told at the next refresh after the time read '
      'passes it, and the attempt ends only when the page says so', (
    tester,
  ) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(seconds: 30));
    expect(clock.isDue, isTrue);
    expect(dues, 0);
    await tester.pump(TimedRoundClock.refresh);
    expect(dues, 1);
    expect(clock.expired, isFalse);
    // The page did not end the attempt: told again at the next refresh.
    await tester.pump(TimedRoundClock.refresh);
    expect(dues, 2);
    clock.expire();
    expect(clock.expired, isTrue);
    expect(clock.secondsLeft, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(dues, 2);
    expect(refreshes, 0);
  });

  testWidgets('the deadline is also told after the limit of timer time, '
      'whatever the time read says', (tester) async {
    clock.setLimit(30);
    clock.start();
    await tester.pump(const Duration(milliseconds: 29900));
    expect(dues, 0);
    expect(clock.isDue, isFalse);
    expect(clock.secondsLeft, 30);
    await tester.pump(const Duration(milliseconds: 100));
    expect(dues, 1);
    clock.stop();
  });

  testWidgets('one moment before the deadline is not due; the deadline '
      'itself is', (tester) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(milliseconds: 29999));
    expect(clock.isDue, isFalse);
    now = now.add(const Duration(milliseconds: 1));
    expect(clock.isDue, isTrue);
    clock.stop();
  });

  testWidgets('starting twice keeps the first deadline', (tester) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(seconds: 20));
    clock.start();
    now = now.add(const Duration(seconds: 10));
    expect(clock.isDue, isTrue);
    clock.stop();
  });

  testWidgets('while the page is not running nothing is refreshed or told at '
      'a refresh', (tester) async {
    clock.setLimit(30);
    clock.start();
    running = false;
    now = now.add(const Duration(seconds: 5));
    await tester.pump(TimedRoundClock.refresh);
    expect(refreshes, 0);
    expect(clock.secondsLeft, 30);
    now = now.add(const Duration(seconds: 30));
    await tester.pump(TimedRoundClock.refresh);
    expect(dues, 0);
    running = true;
    await tester.pump(TimedRoundClock.refresh);
    expect(dues, 1);
    clock.stop();
  });

  testWidgets('the last answer in time stops the clock where it is', (
    tester,
  ) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(milliseconds: 4200));
    await tester.pump(TimedRoundClock.refresh);
    expect(clock.secondsLeft, 26);
    clock.completeInTime();
    expect(clock.completedInTime, isTrue);
    expect(clock.expired, isFalse);
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(minutes: 2));
    expect(clock.secondsLeft, 26);
    expect(dues, 0);
    expect(refreshes, 1);
  });

  testWidgets('after the time ran out it does not start again', (tester) async {
    clock.setLimit(30);
    clock.expire();
    clock.start();
    await tester.pump(const Duration(minutes: 1));
    expect(dues, 0);
    expect(clock.isDue, isFalse);
  });

  testWidgets('stopped timers leave the state as it is', (tester) async {
    clock.setLimit(30);
    clock.start();
    now = now.add(const Duration(seconds: 3));
    await tester.pump(TimedRoundClock.refresh);
    clock.stop();
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(clock.secondsLeft, 27);
    expect(clock.expired, isFalse);
    expect(clock.completedInTime, isFalse);
    expect(dues, 0);
    // The deadline itself is still known: the page asks before an answer.
    expect(clock.isDue, isTrue);
  });
}

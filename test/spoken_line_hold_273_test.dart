import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/spoken_line_hold.dart';
import 'package:quisquislingo_app/services/spoken_line_pace.dart';

/// Build 273 Revision 4: the held Story line has an owner. The Round
/// screen's own cases stay in `spoken_lines_269_test` (the line on the page,
/// Continue greyed and released) and pass before and after; these pin each
/// rule on the owner.
///
/// `testWidgets` is used only for its clock of timers: `tester.pump(d)` lets
/// `d` of timer time pass.
void main() {
  late SpokenLinePace pace;
  late int changes;
  late int neverStarted;
  late int neverEnded;
  late SpokenLineHold hold;

  // 23 characters: about two seconds at the default pace of 12 a second.
  const line = 'Buongiorno, come stai??';

  setUp(() {
    pace = SpokenLinePace();
    changes = 0;
    neverStarted = 0;
    neverEnded = 0;
    hold = SpokenLineHold(
      onChanged: () => changes++,
      onVoiceNeverStarted: () => neverStarted++,
      onVoiceNeverEnded: () => neverEnded++,
      pace: pace,
    );
  });

  tearDown(() => hold.dispose());

  test('nothing to read aloud holds nothing', () {
    hold.prepare(spoken: '', active: true);
    expect(hold.held, isFalse);
    expect(hold.waits, isFalse);
    expect(hold.estimate, Duration.zero);
  });

  test('a line to read aloud holds Continue for its estimate', () {
    hold.prepare(spoken: line, active: false);
    expect(hold.held, isTrue);
    expect(hold.waits, isTrue);
    expect(hold.estimate, pace.estimate(line));
    expect(hold.speaking, isFalse);
  });

  testWidgets(
    'a voice that ends for real reads the line and teaches the pace',
    (tester) async {
      hold.prepare(spoken: line, active: true);
      final token = hold.voiceStarted();
      expect(hold.speaking, isTrue);
      hold.voiceDone(
        token,
        ok: true,
        elapsed: const Duration(seconds: 3),
        spoken: line,
      );
      expect(hold.voiceEnded, isTrue);
      expect(hold.finished, isTrue);
      expect(hold.waits, isFalse);
      expect(
        pace.charactersPerSecond,
        isNot(SpokenLinePace.defaultCharactersPerSecond),
      );
      // The watchdog and the ceiling were stopped: the case ends with no
      // timer pending (a pending timer fails a testWidgets case).
    },
  );

  testWidgets('a voice that returns too early leaves it to the estimate', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: true);
    final token = hold.voiceStarted();
    hold.voiceDone(
      token,
      ok: true,
      elapsed: const Duration(milliseconds: 100),
      spoken: line,
    );
    expect(hold.voiceEnded, isTrue);
    expect(hold.finished, isFalse);
    expect(hold.waits, isTrue);
    // Not a real end: the pace learns nothing.
    expect(pace.charactersPerSecond, SpokenLinePace.defaultCharactersPerSecond);
    await tester.pump(hold.estimate - const Duration(milliseconds: 150));
    expect(hold.finished, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(hold.finished, isTrue);
    expect(hold.waits, isFalse);
  });

  testWidgets('a failed voice reads the line at once, teaching nothing', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: true);
    final token = hold.voiceStarted();
    hold.voiceDone(
      token,
      ok: false,
      elapsed: const Duration(milliseconds: 10),
      spoken: line,
    );
    expect(hold.waits, isFalse);
    expect(pace.charactersPerSecond, SpokenLinePace.defaultCharactersPerSecond);
  });

  testWidgets('the watchdog releases a voice that never starts', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: true);
    await tester.pump(
      SpokenLineHold.watchdogDelay - const Duration(milliseconds: 1),
    );
    expect(hold.held, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(neverStarted, 1);
    expect(hold.held, isFalse);
    expect(hold.waits, isFalse);
  });

  testWidgets('behind Before you start the watchdog waits for its Continue', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: false);
    await tester.pump(const Duration(minutes: 1));
    expect(neverStarted, 0);
    expect(hold.held, isTrue);
    hold.armWatchdog();
    await tester.pump(SpokenLineHold.watchdogDelay);
    expect(neverStarted, 1);
    expect(hold.held, isFalse);
  });

  testWidgets('a started voice stops the watchdog', (tester) async {
    hold.prepare(spoken: line, active: true);
    hold.voiceStarted();
    await tester.pump(SpokenLineHold.watchdogDelay);
    expect(neverStarted, 0);
    expect(hold.held, isTrue);
    // The ceiling is still running.
    await tester.pump(hold.estimate * 2 + SpokenLineHold.ceilingSlack);
  });

  testWidgets('the ceiling releases a voice that never reports its end', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: true);
    final token = hold.voiceStarted();
    final ceiling = hold.estimate * 2 + SpokenLineHold.ceilingSlack;
    await tester.pump(ceiling - const Duration(milliseconds: 1));
    expect(hold.waits, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(neverEnded, 1);
    expect(hold.voiceEnded, isTrue);
    expect(hold.finished, isTrue);
    expect(hold.waits, isFalse);
    // A late end of that voice teaches nothing.
    hold.voiceDone(token, ok: true, elapsed: ceiling, spoken: line);
    expect(pace.charactersPerSecond, SpokenLinePace.defaultCharactersPerSecond);
  });

  testWidgets('a voice or a reading of an earlier line is ignored', (
    tester,
  ) async {
    hold.prepare(spoken: line, active: false);
    final earlier = hold.voiceStarted();
    hold.prepare(spoken: line, active: false);
    expect(hold.speaking, isFalse);
    hold.voiceDone(
      earlier,
      ok: true,
      elapsed: const Duration(seconds: 3),
      spoken: line,
    );
    expect(hold.voiceEnded, isFalse);
    hold.read(earlier);
    expect(hold.finished, isFalse);
    hold.read(hold.line);
    expect(hold.finished, isTrue);
    // The earlier line's ceiling was stopped by the new line: the case ends
    // with no timer pending.
  });

  test('a tap on Play only keeps Play from being pressed twice', () {
    hold.prepare(spoken: line, active: false);
    final token = hold.tapStarted();
    expect(hold.playing, isTrue);
    expect(hold.waits, isTrue);
    hold.tapEnded(token);
    expect(hold.playing, isFalse);
    expect(hold.waits, isTrue);
    final again = hold.tapStarted();
    hold.prepare(spoken: '', active: false);
    expect(hold.playing, isFalse);
    hold.tapEnded(again);
    expect(hold.playing, isFalse);
  });

  testWidgets('after dispose nothing happens', (tester) async {
    hold.prepare(spoken: line, active: true);
    final token = hold.voiceStarted();
    final before = changes;
    hold.dispose();
    hold.voiceDone(
      token,
      ok: true,
      elapsed: const Duration(seconds: 3),
      spoken: line,
    );
    await tester.pump(const Duration(minutes: 1));
    expect(changes, before);
    expect(neverStarted, 0);
    expect(neverEnded, 0);
  });
}

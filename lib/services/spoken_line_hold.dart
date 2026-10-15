import 'dart:async';

import 'spoken_line_pace.dart';

/// Whether the active Dialogue line still holds Continue (Build 273
/// Revision 4; the rule of Build 269 Revision 0, owner decisions of 10
/// October 2026, with Build 270 Revision 2's two safety releases).
///
/// A line that reads itself aloud (automatic read-aloud, audio playable)
/// holds Continue until it has been read: its voice has finished and the
/// time to say it has passed. A voice that returns before
/// [SpokenLinePace.realEndShare] of the estimate did not report its end, so
/// the estimate alone decides. Two timers keep Continue from staying greyed:
/// the watchdog releases a line whose voice never starts, the ceiling one
/// whose voice started and never reports its end. A tap on Play changes
/// nothing; it only keeps Play from being pressed twice ([playing]).
///
/// No Flutter: the Round screen tells it when the line is prepared, when its
/// voice starts and ends, and redraws on [onChanged]. Each [prepare] starts
/// a new line; a timer, a voice or a reading of an earlier line is ignored.
class SpokenLineHold {
  SpokenLineHold({
    required this.onChanged,
    this.onVoiceNeverStarted,
    this.onVoiceNeverEnded,
    SpokenLinePace? pace,
  }) : _pace = pace;

  /// After this long without its voice starting, a line no longer holds
  /// Continue.
  static const watchdogDelay = Duration(seconds: 5);

  /// A started voice that never reports its end is released after twice
  /// the line's estimate and this.
  static const ceilingSlack = Duration(seconds: 5);

  /// Something the page shows changed.
  final void Function() onChanged;

  /// The watchdog released a line whose voice never started (for the
  /// Crash Log), just before the line stops holding.
  final void Function()? onVoiceNeverStarted;

  /// The ceiling released a line whose voice never reported its end (for
  /// the Crash Log), just before the line is taken as read.
  final void Function()? onVoiceNeverEnded;

  final SpokenLinePace? _pace;
  SpokenLinePace get _paceNow => _pace ?? SpokenLinePace.shared;

  int _line = 0;
  bool _disposed = false;
  bool _held = false;
  bool _speaking = false;
  bool _voiceEnded = false;
  bool _finished = false;
  bool _playing = false;
  bool _ceilingReached = false;
  Duration _estimate = Duration.zero;
  Timer? _readTimer;
  Timer? _watchdog;
  Timer? _ceiling;

  /// Which line is active: a token for [read] and [voiceDone].
  int get line => _line;

  /// The active line reads itself aloud and holds Continue.
  bool get held => _held;

  /// Its voice has started.
  bool get speaking => _speaking;

  /// Its voice has finished (or was given up on).
  bool get voiceEnded => _voiceEnded;

  /// Its time has passed: all its words are bright.
  bool get finished => _finished;

  /// A tap on its Play is playing.
  bool get playing => _playing;

  /// The time to say the line, from the shared pace.
  Duration get estimate => _estimate;

  /// Whether Continue waits for the active line to be read.
  bool get waits => _held && !(_voiceEnded && _finished);

  /// A new exercise: a line that reads [spoken] aloud holds Continue (an
  /// empty [spoken], for anything else, holds nothing). With [active] the
  /// exercise is on the page now and the watchdog starts; behind Before you
  /// start it starts at that page's Continue ([armWatchdog]).
  void prepare({required String spoken, required bool active}) {
    _line++;
    _readTimer?.cancel();
    _watchdog?.cancel();
    _watchdog = null;
    _ceiling?.cancel();
    _ceiling = null;
    _ceilingReached = false;
    _playing = false;
    _speaking = false;
    _voiceEnded = false;
    _finished = false;
    _held = spoken.isNotEmpty;
    _estimate = _held ? _paceNow.estimate(spoken) : Duration.zero;
    if (_held && active) armWatchdog();
  }

  /// Continue never stays greyed for a line whose voice does not start:
  /// after [watchdogDelay] the line no longer holds it.
  void armWatchdog() {
    if (!_held) return;
    _watchdog?.cancel();
    final line = _line;
    _watchdog = Timer(watchdogDelay, () {
      if (_disposed || line != _line || _speaking) return;
      onVoiceNeverStarted?.call();
      _held = false;
      onChanged();
    });
  }

  /// The line's own voice starts reading it aloud; returns the token for
  /// [voiceDone].
  int voiceStarted() {
    _watchdog?.cancel();
    if (!_disposed) {
      _speaking = true;
      onChanged();
    }
    _armCeiling();
    return _line;
  }

  void _armCeiling() {
    if (_disposed) return;
    _ceiling?.cancel();
    _ceilingReached = false;
    final line = _line;
    _ceiling = Timer(_estimate * 2 + ceilingSlack, () {
      if (_disposed || line != _line || _voiceEnded) return;
      onVoiceNeverEnded?.call();
      _ceilingReached = true;
      _voiceEnded = true;
      _finished = true;
      onChanged();
    });
  }

  /// The voice started for [line] has finished after [elapsed], or failed.
  /// A real end, or a failure, completes the line (a real end teaches the
  /// shared pace); an end reported too early leaves it to the estimate.
  void voiceDone(
    int line, {
    required bool ok,
    required Duration elapsed,
    required String spoken,
  }) {
    if (_disposed || line != _line) return;
    _ceiling?.cancel();
    // Released by the ceiling: the time is not this voice's pace.
    if (_ceilingReached) return;
    final realEnd = !ok || SpokenLinePace.isRealEnd(elapsed, _estimate);
    if (ok && realEnd) _paceNow.record(spoken, elapsed);
    _voiceEnded = true;
    if (realEnd) _finished = true;
    onChanged();
    if (!realEnd) {
      _readTimer?.cancel();
      _readTimer = Timer(_estimate - elapsed, () => read(line));
    }
  }

  /// The time of [line] has passed (its words are all bright).
  void read(int line) {
    if (_disposed || line != _line || _finished) return;
    _finished = true;
    onChanged();
  }

  /// A tap on Play starts; returns the token for [tapEnded].
  int tapStarted() {
    _playing = true;
    onChanged();
    return _line;
  }

  /// The tap on Play for [line] has ended.
  void tapEnded(int line) {
    if (_disposed || line != _line) return;
    _playing = false;
    onChanged();
  }

  /// The page is gone: nothing more happens.
  void dispose() {
    _disposed = true;
    _readTimer?.cancel();
    _watchdog?.cancel();
    _ceiling?.cancel();
  }
}

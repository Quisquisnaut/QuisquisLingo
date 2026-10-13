import 'dart:async';

/// The countdown of one attempt at a Timed Round (Build 272 Revision 7).
///
/// It owns the limit of the attempt, the deadline, the two timers, the
/// seconds shown, and the two ends an attempt can have: the time ran out, or
/// the last answer came in time. What follows either end (locking the page,
/// saving XP, claiming the limit) is the Round screen's.
///
/// Pure Dart: time comes from [now], so tests set it.
class TimedRoundClock {
  TimedRoundClock({
    required DateTime Function() now,
    required this.canRefresh,
    required this.onSecondsChanged,
    required this.onDue,
  }) : _now = now;

  /// How often the seconds shown are refreshed while the clock runs.
  static const refresh = Duration(milliseconds: 250);

  final DateTime Function() _now;

  /// False while the page is not there to be refreshed (gone, or finishing
  /// the Round): the refresh then does nothing.
  final bool Function() canRefresh;

  /// The seconds shown changed.
  final void Function() onSecondsChanged;

  /// The deadline has passed. The page decides whether the attempt ends
  /// ([expire]) or the Round was already finishing.
  final void Function() onDue;

  Timer? _refresher;
  Timer? _atDeadline;
  DateTime? _deadline;
  int? _limitSeconds;
  int _secondsLeft = 0;
  bool _expired = false;
  bool _completedInTime = false;

  /// The limit of this attempt, in seconds; null when the Round has none.
  int? get limitSeconds => _limitSeconds;

  /// The whole seconds still shown; a started second counts until it ends.
  int get secondsLeft => _secondsLeft;

  /// The time ran out before the last answer.
  bool get expired => _expired;

  /// The last answer came before the time ran out.
  bool get completedInTime => _completedInTime;

  /// The attempt's limit, set before it starts: the clock shows it whole.
  void setLimit(int? seconds) {
    _limitSeconds = seconds;
    _secondsLeft = seconds ?? 0;
  }

  /// Starts counting, once: nothing happens without a limit, after the start
  /// or after the time ran out.
  void start() {
    final limit = _limitSeconds;
    if (_deadline != null || _expired || limit == null) return;
    _deadline = _now().add(Duration(seconds: limit));
    _atDeadline = Timer(Duration(seconds: limit), onDue);
    _refresher = Timer.periodic(refresh, (_) {
      if (_expired || !canRefresh()) return;
      final millis = _deadline!.difference(_now()).inMilliseconds;
      if (millis <= 0) {
        onDue();
      } else {
        _secondsLeft = (millis + 999) ~/ 1000;
        onSecondsChanged();
      }
    });
  }

  /// The clock was started and its deadline has passed.
  bool get isDue => _deadline != null && !_now().isBefore(_deadline!);

  /// The time ran out: the clock stops at zero.
  void expire() {
    stop();
    _expired = true;
    _secondsLeft = 0;
  }

  /// The last answer came in time: the clock stops where it is.
  void completeInTime() {
    stop();
    _completedInTime = true;
  }

  /// Stops the timers; the state stays as it is.
  void stop() {
    _refresher?.cancel();
    _atDeadline?.cancel();
  }
}

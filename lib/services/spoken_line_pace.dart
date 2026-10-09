/// How long a Story dialogue line takes to read aloud, and which of its
/// words are bright at a moment of the reading (Build 269 Revision 0, owner
/// decisions of 10 October 2026: the whole line shows at once, dimmer, and
/// each word becomes bright as the time to say it passes; Continue waits
/// until the line has been read).
///
/// No voice QQL uses reports its words as it speaks them, and on some
/// systems the call returns before the voice has finished, so the reading is
/// paced by the line's length. The pace starts at a usual speaking speed and
/// follows the voices of this device: every line whose end the voice did
/// report is measured (the start-up time of a voice included). Nothing is
/// stored; the pace lasts while the app runs.
class SpokenLinePace {
  SpokenLinePace();

  /// The pace shared by every Round while the app runs.
  static final SpokenLinePace shared = SpokenLinePace();

  /// The pace before any line has been measured.
  static const double defaultCharactersPerSecond = 12;

  /// The measured pace is kept between these bounds.
  static const double slowestCharactersPerSecond = 6;
  static const double fastestCharactersPerSecond = 25;

  /// The shortest reading of a line, however short it is.
  static const Duration shortestLine = Duration(milliseconds: 800);

  /// A voice that "finishes" before this share of the estimated time has
  /// not reported its real end (the call returned early): the line is then
  /// paced by the estimate alone.
  static const double realEndShare = 0.4;

  int _characters = 0;
  int _microseconds = 0;

  /// Characters per second: the measured pace once there is one, else
  /// [defaultCharactersPerSecond].
  double get charactersPerSecond {
    if (_characters == 0 || _microseconds == 0) {
      return defaultCharactersPerSecond;
    }
    final measured =
        _characters / (_microseconds / Duration.microsecondsPerSecond);
    return measured
        .clamp(slowestCharactersPerSecond, fastestCharactersPerSecond)
        .toDouble();
  }

  /// How long reading [text] aloud is expected to take.
  Duration estimate(String text) {
    final characters = text.trim().length;
    final micros =
        (characters / charactersPerSecond * Duration.microsecondsPerSecond)
            .round();
    final estimated = Duration(microseconds: micros);
    return estimated < shortestLine ? shortestLine : estimated;
  }

  /// Whether a voice that finished after [elapsed] reported the real end of
  /// a line expected to take [estimated].
  static bool isRealEnd(Duration elapsed, Duration estimated) =>
      elapsed.inMicroseconds >= estimated.inMicroseconds * realEndShare;

  /// Measures a line whose voice reported its end after [elapsed].
  void record(String text, Duration elapsed) {
    final characters = text.trim().length;
    if (characters == 0 || elapsed <= Duration.zero) return;
    _characters += characters;
    _microseconds += elapsed.inMicroseconds;
  }

  /// Forgets every measurement (tests).
  void reset() {
    _characters = 0;
    _microseconds = 0;
  }
}

/// The words of a line, for drawing them bright one after another.
class SpokenLineWords {
  SpokenLineWords._();

  static final RegExp _word = RegExp(r'\S+');

  /// The length of the bright beginning of [text] when [fraction] (0 to 1)
  /// of its reading time has passed: every word whose turn has come, a word
  /// together with its punctuation. A word's turn comes at the share of the
  /// time that its first character holds in the text, so the first word is
  /// bright as soon as the reading starts; at 1 the whole text is bright.
  static int brightLength(String text, double fraction) {
    if (text.isEmpty) return 0;
    if (fraction >= 1) return text.length;
    final reached = fraction.clamp(0, 1) * text.length;
    var bright = 0;
    for (final word in _word.allMatches(text)) {
      if (word.start > reached) break;
      bright = word.end;
    }
    return bright;
  }
}

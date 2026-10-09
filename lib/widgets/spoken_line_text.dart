import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/course_models.dart';
import '../services/spoken_line_pace.dart';
import 'word_lookup_view.dart';

/// A Story dialogue line while it is read aloud (Build 269 Revision 0, owner
/// decisions of 10 October 2026): the whole line shows at once, dimmer, and
/// its words become bright one after another as the time to say them passes
/// ([SpokenLineWords]). Once every word is bright it is the line's ordinary
/// [LookupText] (Word Lookup works again).
///
/// The bubble keeps its size throughout: the dim words are drawn, not left
/// out. Screen readers read the whole line.
class SpokenLineText extends StatefulWidget {
  const SpokenLineText(
    this.text, {
    super.key,
    required this.duration,
    required this.speaking,
    required this.finished,
    this.onDone,
    this.style,
    this.language,
  });

  final String text;

  /// How long reading the line is expected to take ([SpokenLinePace]).
  final Duration duration;

  /// The voice has been asked to read the line: the words start to brighten.
  final bool speaking;

  /// The line has been read (the voice reported its end, or failed): the
  /// words still dim brighten quickly ([catchUp]).
  final bool finished;

  /// Called once, when every word is bright.
  final VoidCallback? onDone;

  final TextStyle? style;
  final TextLanguage? language;

  /// How long the words still dim take to brighten once the line is read.
  static const Duration catchUp = Duration(milliseconds: 250);

  /// The share of the text colour a word keeps before its turn.
  static const double dimOpacity = .4;

  @override
  State<SpokenLineText> createState() => _SpokenLineTextState();
}

class _SpokenLineTextState extends State<SpokenLineText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  bool _started = false;
  bool _done = false;
  double _fraction = 0;

  /// When the line was read, on the ticker's clock, and how far the words
  /// had come then.
  Duration? _finishedAt;
  double _finishedFrom = 0;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.finished) {
      _done = true;
    } else if (widget.speaking) {
      _start();
    }
  }

  @override
  void didUpdateWidget(SpokenLineText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_done) return;
    if (widget.speaking || widget.finished) _start();
    if (widget.finished && _finishedAt == null) {
      _finishedAt = _elapsed;
      _finishedFrom = _fraction;
    }
  }

  void _start() {
    if (_started) return;
    _started = true;
    _ticker.start();
  }

  double _reading(Duration elapsed) => widget.duration <= Duration.zero
      ? 1
      : elapsed.inMicroseconds / widget.duration.inMicroseconds;

  void _tick(Duration elapsed) {
    _elapsed = elapsed;
    var fraction = _reading(elapsed);
    final finishedAt = _finishedAt;
    if (finishedAt != null) {
      final sweep =
          _finishedFrom +
          (1 - _finishedFrom) *
              ((elapsed - finishedAt).inMicroseconds /
                  SpokenLineText.catchUp.inMicroseconds);
      if (sweep > fraction) fraction = sweep;
    }
    if (fraction >= 1) {
      _ticker.stop();
      setState(() {
        _fraction = 1;
        _done = true;
      });
      widget.onDone?.call();
      return;
    }
    if (SpokenLineWords.brightLength(widget.text, fraction) !=
        SpokenLineWords.brightLength(widget.text, _fraction)) {
      setState(() => _fraction = fraction);
    } else {
      _fraction = fraction;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return LookupText(
        widget.text,
        style: widget.style,
        language: widget.language,
      );
    }
    final text = widget.text;
    final bright = _started ? SpokenLineWords.brightLength(text, _fraction) : 0;
    final colour =
        DefaultTextStyle.of(context).style.merge(widget.style).color ??
        Theme.of(context).colorScheme.onSurface;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, bright)),
          TextSpan(
            text: text.substring(bright),
            style: TextStyle(
              color: colour.withValues(
                alpha: colour.a * SpokenLineText.dimOpacity,
              ),
            ),
          ),
        ],
      ),
      key: const Key('story-line-spoken'),
      style: widget.style,
    );
  }
}

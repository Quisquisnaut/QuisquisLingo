import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/course_models.dart';
import '../services/word_lookup/word_lookup.dart';
import 'guidebook_picture_thumbnail.dart';

/// Build 265: Word Lookup on the learner's screen.
///
/// The Round screen puts a [WordLookupScope] around its page when the
/// Course's Use GuideBook and Word Lookup are on and the Round is not a Test;
/// the Duel never does. A [LookupText] inside the scope lets the learner tap
/// a word of the learning language and see its GuideBook entries in a small
/// card; without a scope it draws exactly the plain text it replaces.
class WordLookupScope extends StatefulWidget {
  const WordLookupScope({
    super.key,
    required this.index,
    required this.currentLessonIndex,
    required this.lessonName,
    required this.note,
    required this.notePlural,
    required this.actionLabel,
    this.courseId = '',
    required this.child,
  });

  final WordLookupIndex index;

  /// The Course whose media folder holds an entry picture stored as Course
  /// media (Build 266).
  final String courseId;

  /// The position of the Round's Lesson in the Course the learner is shown.
  final int currentLessonIndex;

  /// The Lesson's name as the learner's path shows it.
  final String Function(int lessonIndex) lessonName;

  /// The card's fixed line, in the learner panel's language.
  final String note;

  /// The same line for a card with several entries ("Some possible
  /// translations…", owner request of 6 October 2026).
  final String notePlural;

  /// The screen readers' action that lists a text's entries ("Vocabulary in
  /// this text"), in the learner panel's language (Build 265 Revision 2).
  final String actionLabel;

  final Widget child;

  static WordLookupScopeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WordLookupInherited>()?.data;

  @override
  State<WordLookupScope> createState() => _WordLookupScopeState();
}

/// What a [LookupText] reads from its [WordLookupScope].
class WordLookupScopeData {
  const WordLookupScopeData._(this._state);

  final _WordLookupScopeState _state;

  WordLookupIndex get index => _state.widget.index;
  int get currentLessonIndex => _state.widget.currentLessonIndex;
  String lessonName(int lessonIndex) => _state.widget.lessonName(lessonIndex);
  String get note => _state.widget.note;
  String get notePlural => _state.widget.notePlural;
  String get actionLabel => _state.widget.actionLabel;
  String get courseId => _state.widget.courseId;

  /// One card at a time: opening one closes the card open before.
  void opened(VoidCallback close) => _state._opened(close);
  void closed(VoidCallback close) => _state._closed(close);
}

class _WordLookupScopeState extends State<WordLookupScope> {
  VoidCallback? _close;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        _close == null) {
      return false;
    }
    _closeOpen();
    return true;
  }

  void _opened(VoidCallback close) {
    final previous = _close;
    _close = close;
    if (previous != null && previous != close) previous();
  }

  void _closed(VoidCallback close) {
    if (_close == close) _close = null;
  }

  void _closeOpen() {
    final close = _close;
    _close = null;
    close?.call();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollUpdateNotification>(
        onNotification: (_) {
          _closeOpen();
          return false;
        },
        child: _WordLookupInherited(
          data: WordLookupScopeData._(this),
          index: widget.index,
          currentLessonIndex: widget.currentLessonIndex,
          note: widget.note,
          notePlural: widget.notePlural,
          actionLabel: widget.actionLabel,
          child: widget.child,
        ),
      );
}

class _WordLookupInherited extends InheritedWidget {
  const _WordLookupInherited({
    required this.data,
    required this.index,
    required this.currentLessonIndex,
    required this.note,
    required this.notePlural,
    required this.actionLabel,
    required super.child,
  });

  final WordLookupScopeData data;
  final WordLookupIndex index;
  final int currentLessonIndex;
  final String note;
  final String notePlural;
  final String actionLabel;

  @override
  bool updateShouldNotify(_WordLookupInherited old) =>
      old.index != index ||
      old.currentLessonIndex != currentLessonIndex ||
      old.note != note ||
      old.notePlural != notePlural ||
      old.actionLabel != actionLabel;
}

/// The one-time notice that introduces Word Lookup, once per learner and
/// Course (Build 265).
abstract final class WordLookupNotice {
  /// Test seam: off in `test/flutter_test_config.dart`, so a Round opened by
  /// another test shows no dialog.
  static bool enabled = true;

  static String noticeId(String courseId) =>
      'word_lookup_${Uri.encodeComponent(courseId)}';
}

/// A run of [LookupText] with its own style (Page marks: bold, italic).
class LookupRun {
  const LookupRun(this.text, [this.style]);

  final String text;
  final TextStyle? style;
}

/// Text the learner can look words up in (Build 265).
///
/// Without a [WordLookupScope], or for text stated in the learner's own
/// language ([language] source; owner decision Q1 of 6 October 2026), it is
/// the plain [Text] it replaces, with [textKey] on that [Text], so finders
/// and keys keep working.
class LookupText extends StatefulWidget {
  LookupText(
    String text, {
    super.key,
    this.textKey,
    this.style,
    this.textAlign,
    this.language,
    this.leading,
    this.trailing,
  }) : runs = [LookupRun(text)];

  const LookupText.runs(
    this.runs, {
    super.key,
    this.textKey,
    this.style,
    this.textAlign,
    this.language,
    this.leading,
    this.trailing,
  });

  final List<LookupRun> runs;
  final Key? textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextLanguage? language;

  /// Drawn before and after the text and never looked up (a label such as
  /// "Correct answer: ", a speaker's name).
  final TextSpan? leading;
  final TextSpan? trailing;

  String get plainText => runs.map((run) => run.text).join();

  @override
  State<LookupText> createState() => _LookupTextState();
}

class _LookupTextState extends State<LookupText> {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _paragraphKey = GlobalKey();
  final Object _tapGroup = Object();
  final FocusNode _focus = FocusNode(debugLabel: 'word lookup');
  WordLookupScopeData? _scope;
  WordLookupResult? _open;
  Rect? _anchor;
  bool _hovering = false;

  /// The open card lists the whole text's entries (keyboard or screen
  /// reader), so no word is highlighted.
  bool _openWhole = false;

  int get _leadingLength => widget.leading?.toPlainText().length ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = WordLookupScope.maybeOf(context);
  }

  @override
  void didUpdateWidget(LookupText old) {
    super.didUpdateWidget(old);
    if (old.plainText != widget.plainText && _open != null) _close();
  }

  @override
  void dispose() {
    final scope = _scope;
    if (scope != null) scope.closed(_close);
    _focus.dispose();
    super.dispose();
  }

  WordLookupAnalysis? _analysis() {
    final scope = _scope;
    final text = widget.plainText;
    if (scope == null ||
        widget.language == TextLanguage.source ||
        text.trim().isEmpty) {
      return null;
    }
    final analysis = scope.index.analyze(
      text,
      currentLessonIndex: scope.currentLessonIndex,
    );
    return analysis.tappableRanges.isEmpty ? null : analysis;
  }

  RenderParagraph? _paragraph() {
    final root = _paragraphKey.currentContext?.findRenderObject();
    RenderParagraph? found;
    void visit(RenderObject object) {
      if (found != null) return;
      if (object is RenderParagraph) {
        found = object;
        return;
      }
      object.visitChildren(visit);
    }

    if (root != null) visit(root);
    return found;
  }

  /// The offset in the looked-up text under the global [position], or null.
  int? _offsetAt(Offset position) {
    final paragraph = _paragraph();
    if (paragraph == null || !paragraph.hasSize) return null;
    final local = paragraph.globalToLocal(position);
    final caret = paragraph.getPositionForOffset(local).offset;
    for (final start in [caret, caret - 1]) {
      if (start < 0) continue;
      for (final length in const [1, 2]) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + length),
        );
        if (boxes.isEmpty) continue;
        if (boxes.any((box) => box.toRect().inflate(1).contains(local))) {
          final offset = start - _leadingLength;
          return offset < 0 || offset >= widget.plainText.length
              ? null
              : offset;
        }
        break;
      }
    }
    return null;
  }

  Rect? _globalRectOf(WordLookupRange range) {
    final paragraph = _paragraph();
    if (paragraph == null || !paragraph.hasSize) return null;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: _leadingLength + range.start,
        extentOffset: _leadingLength + range.end,
      ),
    );
    if (boxes.isEmpty) return null;
    var rect = boxes.first.toRect();
    for (final box in boxes.skip(1)) {
      rect = rect.expandToInclude(box.toRect());
    }
    final topLeft = paragraph.localToGlobal(rect.topLeft);
    return topLeft & rect.size;
  }

  void _tap(TapUpDetails details, WordLookupAnalysis analysis) {
    final offset = _offsetAt(details.globalPosition);
    final result = offset == null ? null : analysis.resultAt(offset);
    final open = _open;
    if (result == null || (open != null && open.range == result.range)) {
      if (open != null) _close();
      return;
    }
    final anchor = _globalRectOf(result.range);
    if (anchor == null) return;
    setState(() {
      _open = result;
      _anchor = anchor;
      _openWhole = false;
    });
    _portal.show();
    _scope?.opened(_close);
  }

  /// Opens the card with every entry the text finds, beside the whole text
  /// (Enter on the focused text, or the screen readers' action).
  void _openAll(WordLookupAnalysis analysis) {
    final entries = analysis.allEntries;
    if (entries.isEmpty) return;
    final range = WordLookupRange(0, widget.plainText.length);
    final anchor = _globalRectOf(range);
    if (anchor == null) return;
    setState(() {
      _open = WordLookupResult(entries: entries, range: range);
      _anchor = anchor;
      _openWhole = true;
    });
    _portal.show();
    _scope?.opened(_close);
  }

  KeyEventResult _onKey(
    FocusNode node,
    KeyEvent event,
    WordLookupAnalysis analysis,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.enter &&
        key != LogicalKeyboardKey.numpadEnter &&
        key != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (_open != null) {
      _close();
    } else {
      _openAll(analysis);
    }
    return KeyEventResult.handled;
  }

  void _close() {
    _scope?.closed(_close);
    if (!mounted) return;
    if (_portal.isShowing) _portal.hide();
    if (_open != null) {
      setState(() {
        _open = null;
        _anchor = null;
        _openWhole = false;
      });
    }
  }

  void _hover(PointerHoverEvent event, WordLookupAnalysis analysis) {
    final offset = _offsetAt(event.position);
    final over =
        offset != null &&
        analysis.tappableRanges.any((range) => range.contains(offset));
    if (over != _hovering) setState(() => _hovering = over);
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis();
    if (analysis == null) return _text(context, null);
    // Build 265 Revision 2: the text takes keyboard focus (Tab) and Enter
    // opens the card with its entries; screen readers get the same as an
    // action. An outline shows only while the keyboard focuses it.
    final focused =
        _focus.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final colors = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) => _onKey(node, event, analysis),
      child: MergeSemantics(
        child: Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: _scope!.actionLabel): () =>
                _openAll(analysis),
          },
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: focused
                ? BoxDecoration(
                    border: Border.all(color: colors.primary, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  )
                : const BoxDecoration(),
            child: _interactive(context, analysis),
          ),
        ),
      ),
    );
  }

  Widget _interactive(BuildContext context, WordLookupAnalysis analysis) {
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) {
        if (_open != null) _close();
      },
      child: MouseRegion(
        cursor: _hovering ? SystemMouseCursors.click : MouseCursor.defer,
        onHover: (event) => _hover(event, analysis),
        onExit: (_) {
          if (_hovering) setState(() => _hovering = false);
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTapUp: (details) => _tap(details, analysis),
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _card,
            child: KeyedSubtree(
              key: _paragraphKey,
              // Build 265 Revision 3 (owner decision of 6 October 2026): a
              // light dotted underline marks the words that have an entry,
              // drawn over the plain text so the text itself is unchanged.
              child: CustomPaint(
                key: const Key('word-lookup-marks'),
                foregroundPainter: _WordMarksPainter(
                  paragraph: _paragraph,
                  ranges: analysis.tappableRanges,
                  leading: _leadingLength,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .6),
                ),
                child: _text(context, _openWhole ? null : _open?.range),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Unstyled text with nothing highlighted is the plain [Text] it
  /// replaces (its `data` is the whole line), as before Build 265.
  Widget _text(BuildContext context, WordLookupRange? highlight) {
    bool plain(TextSpan? span) =>
        span == null || (span.style == null && span.children == null);
    if (highlight == null &&
        plain(widget.leading) &&
        plain(widget.trailing) &&
        widget.runs.every((run) => run.style == null)) {
      return Text(
        '${widget.leading?.text ?? ''}${widget.plainText}'
        '${widget.trailing?.text ?? ''}',
        key: widget.textKey,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    }
    final marked = TextStyle(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: .22),
    );
    final spans = <InlineSpan>[];
    var at = 0;
    for (final run in widget.runs) {
      final start = at;
      final end = at + run.text.length;
      at = end;
      if (highlight == null ||
          highlight.end <= start ||
          highlight.start >= end) {
        spans.add(TextSpan(text: run.text, style: run.style));
        continue;
      }
      final from = max(highlight.start, start) - start;
      final to = min(highlight.end, end) - start;
      if (from > 0) {
        spans.add(
          TextSpan(text: run.text.substring(0, from), style: run.style),
        );
      }
      spans.add(
        TextSpan(
          text: run.text.substring(from, to),
          style: (run.style ?? const TextStyle()).merge(marked),
        ),
      );
      if (to < run.text.length) {
        spans.add(TextSpan(text: run.text.substring(to), style: run.style));
      }
    }
    return Text.rich(
      TextSpan(
        children: [
          if (widget.leading != null) widget.leading!,
          ...spans,
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
      key: widget.textKey,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }

  Widget _card(BuildContext context) {
    final open = _open;
    final anchor = _anchor;
    final scope = _scope;
    if (open == null || anchor == null || scope == null) {
      return const SizedBox.shrink();
    }
    final overlay = Overlay.of(context).context.findRenderObject();
    final local = overlay is RenderBox
        ? overlay.globalToLocal(anchor.topLeft) & anchor.size
        : anchor;
    return CustomSingleChildLayout(
      delegate: _CardLayout(local),
      // The card is the scope's descendant, so its own scrolling would
      // reach the scope and close it (Build 265 Revision 4): only the
      // page's scrolling closes the card.
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: TapRegion(
          groupId: _tapGroup,
          child: WordLookupCard(
            entries: open.entries,
            courseId: scope.courseId,
            lessonName: scope.lessonName,
            currentLessonIndex: scope.currentLessonIndex,
            note: open.entries.length > 1 ? scope.notePlural : scope.note,
          ),
        ),
      ),
    );
  }
}

/// The dotted underline under each word that has an entry.
class _WordMarksPainter extends CustomPainter {
  _WordMarksPainter({
    required this.paragraph,
    required this.ranges,
    required this.leading,
    required this.color,
  });

  final RenderParagraph? Function() paragraph;
  final List<WordLookupRange> ranges;
  final int leading;
  final Color color;

  static const double _dash = 2;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final text = paragraph();
    if (text == null || !text.hasSize) return;
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final range in ranges) {
      final boxes = text.getBoxesForSelection(
        TextSelection(
          baseOffset: leading + range.start,
          extentOffset: leading + range.end,
        ),
      );
      for (final box in boxes) {
        final y = box.bottom - 1.5;
        for (var x = box.left; x < box.right; x += _dash + _gap) {
          canvas.drawLine(
            Offset(x, y),
            Offset(min(x + _dash, box.right), y),
            pen,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WordMarksPainter old) =>
      !identical(old.ranges, ranges) ||
      old.leading != leading ||
      old.color != color;
}

class _CardLayout extends SingleChildLayoutDelegate {
  _CardLayout(this.anchor);

  final Rect anchor;

  static const double _margin = 8;
  static const double _gap = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: min(320, max(0, constraints.maxWidth - 2 * _margin)),
        maxHeight: max(0, constraints.maxHeight - 2 * _margin),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = anchor.left
        .clamp(_margin, max(_margin, size.width - childSize.width - _margin))
        .toDouble();
    var top = anchor.bottom + _gap;
    if (top + childSize.height > size.height - _margin) {
      top = anchor.top - _gap - childSize.height;
    }
    top = top
        .clamp(_margin, max(_margin, size.height - childSize.height - _margin))
        .toDouble();
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_CardLayout old) => old.anchor != anchor;
}

/// The card a lookup opens: each entry's learning-language side, its
/// meaning with its Context as a small grey label (Build 266), its picture
/// beside the target when it has one, and its Lesson; then the fixed line
/// saying it is one possible translation.
class WordLookupCard extends StatelessWidget {
  const WordLookupCard({
    super.key = const Key('word-lookup-card'),
    required this.entries,
    this.courseId = '',
    required this.lessonName,
    required this.currentLessonIndex,
    required this.note,
  });

  final List<WordLookupEntry> entries;
  final String courseId;
  final String Function(int lessonIndex) lessonName;

  /// An entry of this Lesson shows no Lesson line; one from another Lesson
  /// names it (owner decision of 6 October 2026).
  final int currentLessonIndex;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entries[i].picture case final picture?) ...[
                      GuidebookPictureThumbnail(
                        key: ValueKey('word-lookup-picture-$i'),
                        courseId: courseId,
                        picture: picture,
                        size: 44,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(child: _entry(theme, i)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Text(
                note,
                key: const Key('word-lookup-note'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(ThemeData theme, int i) => Column(
    key: ValueKey('word-lookup-entry-$i'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        entries[i].target,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      Text.rich(
        TextSpan(
          text: entries[i].source,
          style: theme.textTheme.bodyLarge,
          children: [
            if (entries[i].context.isNotEmpty)
              TextSpan(
                text: '  ${entries[i].context}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      if (entries[i].lessonIndex != currentLessonIndex &&
          lessonName(entries[i].lessonIndex).isNotEmpty)
        Text(
          lessonName(entries[i].lessonIndex),
          key: ValueKey('word-lookup-lesson-$i'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}

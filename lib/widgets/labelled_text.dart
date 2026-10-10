import 'package:flutter/material.dart';

/// Build 270 Revision 12 (owner decisions of 10 October 2026): the label and
/// number of a Lesson or a Round ("Lesson 2", "Step 3 · Practice", "4") look
/// as on the learner path, small and grey, so they never look like a title.
TextStyle numberingLabelStyle(BuildContext context) => TextStyle(
  fontSize: 12,
  height: 1.3,
  fontWeight: FontWeight.w400,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
);

/// [text] with its first [label] in [numberingLabelStyle]; the plain text is
/// [text] unchanged, so a name reads and is found as before.
class LabelledText extends StatelessWidget {
  LabelledText(
    this.text, {
    super.key,
    required String? label,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : labels = [label];

  /// [text] with each of [labels] styled, found in order ("Lesson 2: Food >
  /// Step 1 · Practice > …").
  const LabelledText.all(
    this.text, {
    super.key,
    required this.labels,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final List<String?> labels;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final label in labels) {
      final part = label?.trim() ?? '';
      if (part.isEmpty) continue;
      final at = text.indexOf(part, cursor);
      if (at < 0) continue;
      if (at > cursor) spans.add(TextSpan(text: text.substring(cursor, at)));
      spans.add(TextSpan(text: part, style: numberingLabelStyle(context)));
      cursor = at + part.length;
    }
    if (spans.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// A small grey [label] line above a [title], as on the learner path; a
/// missing title reads [emptyTitle] in grey, so the label never stands in
/// for it.
class LabelledTitle extends StatelessWidget {
  const LabelledTitle({
    super.key,
    required this.label,
    required this.title,
    this.titleStyle,
    this.emptyTitle = 'No title',
    this.titleMaxLines = 2,
  });

  final String? label;
  final String title;
  final TextStyle? titleStyle;
  final String emptyTitle;

  /// Null lets a heading wrap freely.
  final int? titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final line = label?.trim() ?? '';
    final grey = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (line.isNotEmpty)
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: numberingLabelStyle(context),
          ),
        title.trim().isEmpty
            ? Text(
                emptyTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (titleStyle ?? const TextStyle()).copyWith(color: grey),
              )
            : Text(
                title,
                maxLines: titleMaxLines,
                overflow: titleMaxLines == null ? null : TextOverflow.ellipsis,
                style: titleStyle,
              ),
      ],
    );
  }
}

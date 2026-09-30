import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/inline_marks.dart';
import '../services/page_blocks.dart';

/// Build 258: a Page, a presentation drawn from its blocks in order:
/// headings, paragraphs, quotes and lists with inline marks, alignment and
/// a palette colour; pictures with a size, alignment and caption; audio
/// blocks; and links opened in the browser. The Round screen supplies how
/// pictures are drawn and how speech and links are handled, so the GuideBook
/// can reuse the same blocks later.
class PageCardView extends StatelessWidget {
  const PageCardView({
    super.key,
    required this.blocks,
    required this.pictureBuilder,
    this.onSpeak,
    this.onOpenLink,
    this.background,
    this.forExport = false,
  });

  /// Build 258 Revision 4: the page as it goes into a PDF: no audio or
  /// read-aloud buttons, and each link printed with its address.
  final bool forExport;

  /// The Page's blocks, in order (elements with role `block`).
  final List<PromptElement> blocks;

  /// Draws a picture block at the given width.
  final Widget Function(PromptElement picture, double width) pictureBuilder;

  /// Speaks a text block (read-aloud) or plays an audio block; null hides
  /// read-aloud and audio buttons (audio unavailable).
  final void Function(PromptElement element)? onSpeak;

  /// Opens a link block's address; null disables links.
  final void Function(String url)? onOpenLink;

  final Color? background;

  /// The palette colour of [color] in [theme], or null for the theme's own
  /// text colour. Every name keeps enough contrast in light and dark.
  static Color? colorOf(BlockColor? color, ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    return switch (color) {
      null || BlockColor.normal => null,
      BlockColor.accent => theme.colorScheme.primary,
      BlockColor.red => dark ? Colors.red.shade300 : Colors.red.shade800,
      BlockColor.green => dark ? Colors.green.shade300 : Colors.green.shade800,
      BlockColor.blue => dark ? Colors.blue.shade300 : Colors.blue.shade800,
      BlockColor.grey => dark ? Colors.grey.shade400 : Colors.grey.shade700,
    };
  }

  static TextAlign textAlignOf(BlockAlign? align) => switch (align) {
    null || BlockAlign.start => TextAlign.start,
    BlockAlign.center => TextAlign.center,
    BlockAlign.end => TextAlign.end,
    BlockAlign.justify => TextAlign.justify,
  };

  /// The share of the available width a picture of [size] takes.
  static double widthShareOf(BlockSize? size) => switch (size) {
    BlockSize.small => .35,
    null || BlockSize.medium => .6,
    BlockSize.large => .85,
    BlockSize.full => 1,
  };

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('page-card'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            key: ValueKey('page-block-$i'),
            padding: EdgeInsets.only(bottom: i + 1 < blocks.length ? 14 : 0),
            child: _block(context, blocks[i], i),
          ),
      ],
    ),
  );

  Widget _block(BuildContext context, PromptElement block, int index) {
    if (block.isImage) return _picture(context, block, index);
    if (block.isLink) return _link(context, block, index);
    if (block.isAudio) return _audio(block, index);
    if (block.isText) return _text(context, block, index);
    return const SizedBox.shrink();
  }

  Widget _text(BuildContext context, PromptElement block, int index) {
    final theme = Theme.of(context);
    final style = block.textStyle ?? BlockTextStyle.paragraph;
    final base = switch (style) {
      BlockTextStyle.heading1 => theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      BlockTextStyle.heading2 => theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BlockTextStyle.quote => theme.textTheme.bodyLarge?.copyWith(
        fontStyle: FontStyle.italic,
      ),
      _ => theme.textTheme.bodyLarge,
    };
    final textStyle = base?.copyWith(color: colorOf(block.color, theme));
    final align = textAlignOf(block.align);
    Widget body;
    if (style.isList) {
      final items = block.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    style == BlockTextStyle.numbered ? '${i + 1}.' : '•',
                    style: textStyle,
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    _spans(items[i], style),
                    style: textStyle,
                    textAlign: align,
                  ),
                ),
              ],
            ),
        ],
      );
    } else {
      body = Text.rich(
        _spans(block.text, style),
        style: textStyle,
        textAlign: align,
      );
    }
    if (style == BlockTextStyle.quote) {
      body = Container(
        padding: const EdgeInsetsDirectional.only(start: 12),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: theme.colorScheme.outline, width: 3),
          ),
        ),
        child: body,
      );
    }
    final speak = onSpeak;
    if (block.readAloud != true || speak == null) return body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: body),
        IconButton(
          key: ValueKey('page-read-aloud-$index'),
          tooltip: 'Read aloud',
          icon: const Icon(Icons.volume_up_outlined),
          onPressed: () => speak(block),
        ),
      ],
    );
  }

  /// Headings take no marks: they are drawn as typed.
  TextSpan _spans(String text, BlockTextStyle style) {
    if (!style.isBody) return TextSpan(text: text);
    return TextSpan(
      children: [
        for (final run in InlineMarks.parse(text))
          TextSpan(
            text: run.text,
            style: TextStyle(
              fontWeight: run.bold ? FontWeight.w700 : null,
              fontStyle: run.italic ? FontStyle.italic : null,
            ),
          ),
      ],
    );
  }

  AlignmentDirectional _alignmentOf(
    BlockAlign? align, {
    bool centered = false,
  }) => switch (align) {
    BlockAlign.start => AlignmentDirectional.centerStart,
    BlockAlign.end => AlignmentDirectional.centerEnd,
    BlockAlign.center => AlignmentDirectional.center,
    _ =>
      centered ? AlignmentDirectional.center : AlignmentDirectional.centerStart,
  };

  Widget _picture(BuildContext context, PromptElement block, int index) {
    final caption = block.text.trim();
    final alignment = _alignmentOf(block.align, centered: true);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * widthShareOf(block.size);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              key: ValueKey('page-picture-$index'),
              alignment: alignment,
              child: SizedBox(
                width: width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pictureBuilder(block, width),
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: alignment,
                child: SizedBox(
                  width: width,
                  child: Text(
                    caption,
                    textAlign: switch (block.align) {
                      BlockAlign.start => TextAlign.start,
                      BlockAlign.end => TextAlign.end,
                      _ => TextAlign.center,
                    },
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _audio(PromptElement block, int index) {
    final speak = onSpeak;
    if (speak == null || forExport) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FilledButton.tonalIcon(
        key: ValueKey('page-audio-$index'),
        onPressed: () => speak(block),
        icon: const Icon(Icons.volume_up_outlined),
        label: const Text('Listen'),
      ),
    );
  }

  Widget _link(BuildContext context, PromptElement block, int index) {
    if (forExport) {
      final label = block.text.trim().isEmpty
          ? 'Watch the video'
          : block.text.trim();
      return Text(
        '$label: ${block.url.trim()}',
        key: ValueKey('page-link-$index'),
        textAlign: textAlignOf(block.align),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      );
    }
    final open = onOpenLink;
    final acceptable = PageBlocks.isAcceptableLink(block.url);
    final label = block.text.trim().isEmpty
        ? 'Watch the video'
        : block.text.trim();
    return Align(
      alignment: _alignmentOf(block.align),
      child: OutlinedButton.icon(
        key: ValueKey('page-link-$index'),
        onPressed: open == null || !acceptable
            ? null
            : () => open(block.url.trim()),
        icon: const Icon(Icons.open_in_new),
        label: Text(label),
      ),
    );
  }
}

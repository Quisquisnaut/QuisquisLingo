import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/page_blocks.dart';
import 'course_media_image.dart';
import 'exercise_image_field.dart';
import 'page_card.dart';
import 'portable_exercise_image.dart';

/// Build 258 Revision 2: the Page form's blocks. The author adds, moves and
/// removes blocks, writes their text with the bold and italic marks (a
/// toolbar wraps the selection), picks a style, an alignment, a palette
/// colour and read-aloud for text; a picture, its size, alignment and
/// caption; the spoken text of an audio block; the label and https address
/// of a video link. A live preview under the list is drawn by the learner's
/// own renderer. Every change goes to [onChanged] as the Page's blocks.
class PageBlockEditor extends StatefulWidget {
  const PageBlockEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    required this.helpButton,
    this.course,
    this.readOnly = false,
  });

  /// The Page's blocks when the form opens (role `block`).
  final List<PromptElement> blocks;
  final ValueChanged<List<PromptElement>> onChanged;

  /// The Help control every block field shows (one shared Help entry).
  final Widget Function() helpButton;
  final Course? course;
  final bool readOnly;

  static String styleLabel(BlockTextStyle style) => switch (style) {
    BlockTextStyle.heading1 => 'Heading 1',
    BlockTextStyle.heading2 => 'Heading 2',
    BlockTextStyle.paragraph => 'Paragraph',
    BlockTextStyle.quote => 'Quote or example',
    BlockTextStyle.bulleted => 'Bulleted list',
    BlockTextStyle.numbered => 'Numbered list',
  };

  static String colorLabel(BlockColor color) => switch (color) {
    BlockColor.normal => 'Default',
    BlockColor.accent => 'Accent',
    BlockColor.red => 'Red',
    BlockColor.green => 'Green',
    BlockColor.blue => 'Blue',
    BlockColor.grey => 'Grey',
  };

  static String sizeLabel(BlockSize size) => switch (size) {
    BlockSize.small => 'Small',
    BlockSize.medium => 'Medium',
    BlockSize.large => 'Large',
    BlockSize.full => 'Full width',
  };

  @override
  State<PageBlockEditor> createState() => _PageBlockEditorState();
}

class _Block {
  _Block(this.element)
    : text = TextEditingController(text: element.text),
      url = TextEditingController(text: element.url);

  PromptElement element;
  final TextEditingController text;
  final TextEditingController url;

  PromptElement get current =>
      element.copyWith(role: 'block', text: text.text, url: url.text);

  void dispose() {
    text.dispose();
    url.dispose();
  }
}

enum _NewBlock { heading, paragraph, quote, list, picture, audio, link }

class _PageBlockEditorState extends State<PageBlockEditor> {
  late final List<_Block> _blocks = [
    for (final element in widget.blocks) _watch(_Block(element)),
  ];

  _Block _watch(_Block block) {
    block.text.addListener(_emit);
    block.url.addListener(_emit);
    return block;
  }

  @override
  void dispose() {
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }

  List<PromptElement> get _current => [for (final b in _blocks) b.current];

  void _emit() {
    widget.onChanged(_current);
    if (mounted) setState(() {});
  }

  void _update(int index, PromptElement element) {
    _blocks[index].element = element;
    _emit();
  }

  void _add(_NewBlock kind) {
    final element = switch (kind) {
      _NewBlock.heading => const PromptElement(
        role: 'block',
        type: 'text',
        textStyle: BlockTextStyle.heading2,
      ),
      _NewBlock.paragraph => const PromptElement(role: 'block', type: 'text'),
      _NewBlock.quote => const PromptElement(
        role: 'block',
        type: 'text',
        textStyle: BlockTextStyle.quote,
      ),
      _NewBlock.list => const PromptElement(
        role: 'block',
        type: 'text',
        textStyle: BlockTextStyle.bulleted,
      ),
      _NewBlock.picture => const PromptElement(role: 'block', type: 'image'),
      _NewBlock.audio => const PromptElement(
        role: 'block',
        type: 'audio',
        required: false,
      ),
      _NewBlock.link => const PromptElement(role: 'block', type: 'link'),
    };
    _blocks.add(_watch(_Block(element)));
    _emit();
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _blocks.length) return;
    final block = _blocks.removeAt(index);
    _blocks.insert(target, block);
    _emit();
  }

  void _remove(int index) {
    final block = _blocks.removeAt(index);
    block.text.removeListener(_emit);
    block.url.removeListener(_emit);
    _emit();
    WidgetsBinding.instance.addPostFrameCallback((_) => block.dispose());
  }

  /// Wraps the selection of [controller] in [mark] (`**` or `*`); with no
  /// selection the marks are inserted at the cursor.
  void _wrap(TextEditingController controller, String mark) {
    final value = controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final text = value.text;
    final chosen = text.substring(start, end);
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, '$mark$chosen$mark'),
      selection: TextSelection(
        baseOffset: start + mark.length,
        extentOffset: end + mark.length,
      ),
    );
  }

  String _kindLabel(PromptElement element) {
    if (element.isImage) return 'Picture';
    if (element.isAudio) return 'Audio';
    if (element.isLink) return 'Video link';
    return PageBlockEditor.styleLabel(
      element.textStyle ?? BlockTextStyle.paragraph,
    );
  }

  IconData _kindIcon(PromptElement element) {
    if (element.isImage) return Icons.image_outlined;
    if (element.isAudio) return Icons.volume_up_outlined;
    if (element.isLink) return Icons.smart_display_outlined;
    final style = element.textStyle ?? BlockTextStyle.paragraph;
    return switch (style) {
      BlockTextStyle.heading1 || BlockTextStyle.heading2 => Icons.title,
      BlockTextStyle.quote => Icons.format_quote,
      BlockTextStyle.bulleted => Icons.format_list_bulleted,
      BlockTextStyle.numbered => Icons.format_list_numbered,
      BlockTextStyle.paragraph => Icons.notes,
    };
  }

  InputDecoration _decoration(String label, {String? helper, String? error}) =>
      InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        errorText: error,
        suffixIcon: widget.helpButton(),
      );

  Widget _alignment(int index, PromptElement element, {required bool text}) {
    final values = [
      BlockAlign.start,
      BlockAlign.center,
      BlockAlign.end,
      if (text &&
          (element.textStyle ?? BlockTextStyle.paragraph).isBody &&
          !(element.textStyle ?? BlockTextStyle.paragraph).isList)
        BlockAlign.justify,
    ];
    final current =
        element.align ??
        (element.isImage ? BlockAlign.center : BlockAlign.start);
    return SegmentedButton<BlockAlign>(
      key: ValueKey('page-block-align-$index'),
      showSelectedIcon: false,
      segments: [
        for (final align in values)
          ButtonSegment(
            value: align,
            tooltip: switch (align) {
              BlockAlign.start => 'Start',
              BlockAlign.center => 'Center',
              BlockAlign.end => 'End',
              BlockAlign.justify => 'Justify',
            },
            icon: Icon(switch (align) {
              BlockAlign.start => Icons.format_align_left,
              BlockAlign.center => Icons.format_align_center,
              BlockAlign.end => Icons.format_align_right,
              BlockAlign.justify => Icons.format_align_justify,
            }),
          ),
      ],
      selected: {values.contains(current) ? current : BlockAlign.start},
      onSelectionChanged: widget.readOnly
          ? null
          : (selection) =>
                _update(index, element.copyWith(align: selection.single)),
    );
  }

  Widget _palette(int index, PromptElement element) {
    final theme = Theme.of(context);
    final current = element.color ?? BlockColor.normal;
    return Wrap(
      spacing: 6,
      children: [
        for (final color in BlockColor.values)
          Tooltip(
            message: PageBlockEditor.colorLabel(color),
            child: InkResponse(
              key: ValueKey('page-block-color-$index-${color.serialized}'),
              onTap: widget.readOnly
                  ? null
                  : () => _update(index, element.copyWith(color: color)),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      PageCardView.colorOf(color, theme) ??
                      theme.colorScheme.onSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: current == color
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: current == color ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _textBlock(int index, _Block block) {
    final element = block.element;
    final style = element.textStyle ?? BlockTextStyle.paragraph;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<BlockTextStyle>(
          key: ValueKey('page-block-style-$index'),
          value: style,
          items: [
            for (final value in BlockTextStyle.values)
              DropdownMenuItem(
                value: value,
                child: Text(PageBlockEditor.styleLabel(value)),
              ),
          ],
          onChanged: widget.readOnly
              ? null
              : (value) {
                  if (value == null) return;
                  var next = element.copyWith(textStyle: value);
                  // Justify is for paragraphs and quotes only.
                  if ((!value.isBody || value.isList) &&
                      element.align == BlockAlign.justify) {
                    next = PromptElement.fromJson(
                      {...next.toJson()}..remove('align'),
                    );
                  }
                  _update(index, next);
                },
        ),
        if (style.isBody)
          Row(
            children: [
              IconButton(
                key: ValueKey('page-block-bold-$index'),
                tooltip: 'Bold: wraps the selection in **',
                icon: const Icon(Icons.format_bold),
                onPressed: widget.readOnly
                    ? null
                    : () => _wrap(block.text, '**'),
              ),
              IconButton(
                key: ValueKey('page-block-italic-$index'),
                tooltip: 'Italic: wraps the selection in *',
                icon: const Icon(Icons.format_italic),
                onPressed: widget.readOnly
                    ? null
                    : () => _wrap(block.text, '*'),
              ),
            ],
          ),
        TextField(
          key: ValueKey('page-block-text-$index'),
          controller: block.text,
          readOnly: widget.readOnly,
          minLines: style.isBody ? 3 : 1,
          maxLines: style.isBody ? 10 : 3,
          decoration: _decoration(
            style.isList
                ? 'Items, one per line'
                : style.isBody
                ? 'Text'
                : 'Heading text',
            helper: style.isBody
                ? '**bold**, *italic*; write \\* to show a star.'
                : null,
          ),
        ),
        const SizedBox(height: 8),
        _alignment(index, element, text: true),
        const SizedBox(height: 8),
        _palette(index, element),
        SwitchListTile(
          key: ValueKey('page-block-read-aloud-$index'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Read aloud'),
          subtitle: const Text(
            'A speaker button reads this block, when the learner has audio on.',
          ),
          value: element.readAloud ?? false,
          onChanged: widget.readOnly
              ? null
              : (value) => _update(
                  index,
                  value
                      ? element.copyWith(readAloud: true)
                      : PromptElement.fromJson(
                          {...element.toJson()}..remove('readAloud'),
                        ),
                ),
        ),
        if (element.readAloud ?? false)
          DropdownButton<TextLanguage>(
            key: ValueKey('page-block-language-$index'),
            value: element.language ?? TextLanguage.target,
            items: const [
              DropdownMenuItem(
                value: TextLanguage.target,
                child: Text('Target language'),
              ),
              DropdownMenuItem(
                value: TextLanguage.source,
                child: Text('Source language'),
              ),
            ],
            onChanged: widget.readOnly
                ? null
                : (value) => _update(index, element.copyWith(language: value)),
          ),
      ],
    );
  }

  Widget _pictureBlock(int index, _Block block) {
    final element = block.element;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExerciseImageField(
          course: widget.course,
          title: 'Picture',
          compact: true,
          asset: element.asset,
          sharedSource: element.sharedImageSource,
          readOnly: widget.readOnly,
          onChanged: (change) => _update(
            index,
            PromptElement.fromJson(
              {
                ...element.toJson(),
                'asset': change.asset,
                if (change.source != null)
                  'sharedImageSource': change.source!.toJson(),
              }..removeWhere(
                (key, value) =>
                    key == 'sharedImageSource' && change.source == null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<BlockSize>(
          key: ValueKey('page-block-size-$index'),
          value: element.size ?? BlockSize.medium,
          items: [
            for (final size in BlockSize.values)
              DropdownMenuItem(
                value: size,
                child: Text(PageBlockEditor.sizeLabel(size)),
              ),
          ],
          onChanged: widget.readOnly
              ? null
              : (value) => _update(index, element.copyWith(size: value)),
        ),
        const SizedBox(height: 8),
        _alignment(index, element, text: false),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('page-block-text-$index'),
          controller: block.text,
          readOnly: widget.readOnly,
          decoration: _decoration(
            'Caption',
            helper: 'Also what a screen reader says about the picture.',
          ),
        ),
      ],
    );
  }

  Widget _audioBlock(int index, _Block block) => TextField(
    key: ValueKey('page-block-text-$index'),
    controller: block.text,
    readOnly: widget.readOnly,
    minLines: 1,
    maxLines: 4,
    decoration: _decoration(
      'Spoken text',
      helper:
          'Played with text-to-speech, or the matching recording of the Audio Library.',
    ),
  );

  Widget _linkBlock(int index, _Block block) {
    final address = block.url.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: ValueKey('page-block-text-$index'),
          controller: block.text,
          readOnly: widget.readOnly,
          decoration: _decoration(
            'Label',
            helper: 'Empty shows “Watch the video”.',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('page-block-url-$index'),
          controller: block.url,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.url,
          decoration: _decoration(
            'Address',
            helper: 'https:// only; the learner’s browser opens it.',
            error: address.isEmpty || PageBlocks.isAcceptableLink(address)
                ? null
                : 'Enter a full address starting with https://',
          ),
        ),
        const SizedBox(height: 8),
        _alignment(index, block.element, text: false),
      ],
    );
  }

  Widget _blockCard(int index) {
    final block = _blocks[index];
    final element = block.element;
    final body = element.isImage
        ? _pictureBlock(index, block)
        : element.isAudio
        ? _audioBlock(index, block)
        : element.isLink
        ? _linkBlock(index, block)
        : _textBlock(index, block);
    return Card(
      key: ValueKey('page-block-editor-$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_kindIcon(element), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${index + 1}. ${_kindLabel(element)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  key: ValueKey('page-block-up-$index'),
                  tooltip: 'Move up',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: widget.readOnly || index == 0
                      ? null
                      : () => _move(index, -1),
                ),
                IconButton(
                  key: ValueKey('page-block-down-$index'),
                  tooltip: 'Move down',
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: widget.readOnly || index + 1 == _blocks.length
                      ? null
                      : () => _move(index, 1),
                ),
                IconButton(
                  key: ValueKey('page-block-remove-$index'),
                  tooltip: 'Remove block',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.readOnly ? null : () => _remove(index),
                ),
              ],
            ),
            Padding(padding: const EdgeInsets.only(right: 8), child: body),
          ],
        ),
      ),
    );
  }

  Widget _picture(PromptElement picture, double width) {
    final course = widget.course;
    if (picture.asset.isEmpty) {
      return SizedBox(
        width: width,
        height: width * .5,
        child: const Center(child: Icon(Icons.image_outlined)),
      );
    }
    return picture.asset.startsWith('media:') && course != null
        ? CourseMediaImage(
            courseId: course.courseId,
            asset: picture.asset,
            width: width,
            cacheWidth: 1024,
          )
        : PortableExerciseImage(asset: picture.asset, width: width);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < _blocks.length; i++) _blockCard(i),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: PopupMenuButton<_NewBlock>(
          key: const Key('page-add-block'),
          enabled: !widget.readOnly,
          tooltip: 'Add block',
          onSelected: _add,
          itemBuilder: (_) => const [
            PopupMenuItem(value: _NewBlock.heading, child: Text('Heading')),
            PopupMenuItem(value: _NewBlock.paragraph, child: Text('Paragraph')),
            PopupMenuItem(
              value: _NewBlock.quote,
              child: Text('Quote or example'),
            ),
            PopupMenuItem(value: _NewBlock.list, child: Text('List')),
            PopupMenuItem(value: _NewBlock.picture, child: Text('Picture')),
            PopupMenuItem(value: _NewBlock.audio, child: Text('Audio')),
            PopupMenuItem(value: _NewBlock.link, child: Text('Video link')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Add block'),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('Preview', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      PageCardView(
        key: const Key('page-live-preview'),
        blocks: _current,
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
        pictureBuilder: _picture,
      ),
    ],
  );
}

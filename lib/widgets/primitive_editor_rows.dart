import 'package:flutter/material.dart';
import '../models/course_models.dart';

// The rows of the canonical editor: one element, one item, one target,
// one piece of the layout (Build 272 Revision 12; before, private
// widgets at the end of the canonical editor's file).

/// A menu entry's text on one line, cut with an ellipsis when the menu is
/// narrower than the text (Build 261 Revision 6 follow-up: the editor's
/// menus fit a 360-pixel window).
Text menuText(String text) =>
    Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);

class PrimitiveElementRow extends StatelessWidget {
  const PrimitiveElementRow({
    super.key,
    required this.element,
    required this.primitive,
    required this.place,
    required this.index,
    required this.count,
    required this.locked,
    required this.chooseImage,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
    this.compact = false,
  });

  final PromptElement element;

  /// The exercise's primitive and where the element sits: together with
  /// the element's type they decide the roles the Role menu offers.
  final ExercisePrimitive primitive;
  final ElementPlace place;
  final int index;
  final int count;
  final bool locked;
  final Future<String?> Function() chooseImage;
  final ValueChanged<PromptElement> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;
  final bool compact;

  PromptElement _with({
    String? role,
    String? text,
    String? asset,
    String? speaker,
    Object? language = _keep,
    Object? playback = _keep,
    Object? required = _keep,
    Object? sharedImageSource = _keep,
  }) => PromptElement(
    type: element.type,
    role: role ?? element.role,
    text: text ?? element.text,
    asset: asset ?? element.asset,
    speaker: speaker ?? element.speaker,
    sharedImageSource: identical(sharedImageSource, _keep)
        ? element.sharedImageSource
        : sharedImageSource as SharedImageSource?,
    language: identical(language, _keep)
        ? element.language
        : language as TextLanguage?,
    playback: identical(playback, _keep)
        ? element.playback
        : playback as AudioPlayback?,
    required: identical(required, _keep) ? element.required : required as bool?,
    // Attributes this row has no field for are kept (Build 258: a Page
    // block's style, alignment, colour, size, read-aloud and link; the
    // speaker of a Dialogue line was dropped here before).
    speakerId: element.speakerId,
    textStyle: element.textStyle,
    align: element.align,
    color: element.color,
    size: element.size,
    readAloud: element.readAloud,
    url: element.url,
    // Build 265 Revision 11: a picture's Plural mark, kept while the element
    // is still a picture (a text element carries it only as an icon key).
    plural: element.isText && !pluralTextRoles.contains(role ?? element.role)
        ? null
        : element.plural,
  );

  static const _keep = Object();

  @override
  Widget build(BuildContext context) {
    final label = switch (element.type) {
      'audio' => 'Audio',
      'image' => 'Image',
      _ => 'Text',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: locked || index == 0 ? null : () => onMove(-1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: locked || index >= count - 1
                      ? null
                      : () => onMove(1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: locked ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _roleField(context),
            const SizedBox(height: 8),
            if (element.type == 'image') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('asset-${element.asset}'),
                      initialValue: element.asset,
                      readOnly: locked,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Image asset',
                      ),
                      onChanged: (value) => onChanged(
                        _with(asset: value.trim(), sharedImageSource: null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: locked
                        ? null
                        : () async {
                            final asset = await chooseImage();
                            if (asset != null) {
                              onChanged(
                                _with(asset: asset, sharedImageSource: null),
                              );
                            }
                          },
                    child: const Text('Choose'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: element.text,
                readOnly: locked,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Caption (optional)',
                ),
                onChanged: (value) => onChanged(_with(text: value)),
              ),
            ] else ...[
              TextFormField(
                key: const Key('element-text'),
                initialValue: element.text,
                readOnly: locked,
                maxLines: null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: element.type == 'audio' ? 'Spoken text' : 'Text',
                ),
                onChanged: (value) => onChanged(_with(text: value)),
              ),
              if (element.type == 'audio') ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('audio-asset-${element.asset}'),
                  initialValue: element.asset,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Recording (optional media reference)',
                  ),
                  onChanged: (value) => onChanged(_with(asset: value.trim())),
                ),
              ],
              if (!compact && element.type == 'text') ...[
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: element.speaker,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Speaker (dialogue turns)',
                  ),
                  onChanged: (value) => onChanged(_with(speaker: value.trim())),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice<TextLanguage?>(
                  'Language',
                  element.language,
                  const [null, ...TextLanguage.values],
                  (value) => value?.serialized ?? 'Not set',
                  (value) => onChanged(_with(language: value)),
                ),
                if (element.type == 'audio')
                  _choice<AudioPlayback?>(
                    'Playback',
                    element.playback,
                    const [null, ...AudioPlayback.values],
                    (value) => value?.serialized ?? 'Not set',
                    (value) => onChanged(_with(playback: value)),
                  ),
                if (element.type != 'text')
                  _choice<bool?>(
                    'Required',
                    element.required,
                    const [null, true, false],
                    (value) => switch (value) {
                      null => 'Not set',
                      true => 'Yes',
                      false => 'No',
                    },
                    (value) => onChanged(_with(required: value)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The Role menu (Build 261 Revision 6, owner decision of 2 October
  /// 2026): only the roles QQL reads for this element's type, place and
  /// primitive ([ElementRoles]), each with its description. A stored role
  /// outside them stays selected, marked, and is never rewritten unless
  /// the author picks another.
  Widget _roleField(BuildContext context) {
    final offered = ElementRoles.offered(
      type: element.type,
      place: place,
      primitive: primitive,
    );
    final current = ElementRoles.find(
      element.role,
      type: element.type,
      place: place,
      primitive: primitive,
    );
    final note = current == null
        ? ElementRoles.notOfferedNote(
            element.role,
            type: element.type,
            place: place,
          )
        : null;
    String name(String id) => id.isEmpty ? '(none)' : id;
    final entries = [
      if (current == null)
        (id: element.role, description: 'Kept as stored: $note.'),
      for (final role in offered) (id: role.id, description: role.description),
    ];
    final small = Theme.of(context).textTheme.bodySmall;
    return DropdownButtonFormField<String>(
      // Keyed by the menu's contents, so a new primitive or type rebuilds it.
      key: ValueKey(
        'element-role-${primitive.serialized}-${place.name}-${element.type}',
      ),
      initialValue: element.role,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: 'Role',
        helperText: current?.description ?? 'Kept as stored: $note.',
        helperMaxLines: 3,
      ),
      selectedItemBuilder: (context) => [
        for (final entry in entries)
          Text(
            entry.id == element.role && current == null
                ? '${name(entry.id)} ($note)'
                : name(entry.id),
            overflow: TextOverflow.ellipsis,
          ),
      ],
      items: [
        for (final entry in entries)
          DropdownMenuItem<String>(
            value: entry.id,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name(entry.id),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(entry.description, style: small),
                ],
              ),
            ),
          ),
      ],
      onChanged: locked
          ? null
          : (value) {
              if (value != null && value != element.role) {
                onChanged(_with(role: value));
              }
            },
    );
  }

  Widget _choice<T>(
    String label,
    T current,
    List<T> values,
    String Function(T) name,
    ValueChanged<T> onSelected,
  ) => SizedBox(
    width: 170,
    child: DropdownButtonFormField<T>(
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        isDense: true,
      ),
      items: [
        for (final value in values)
          DropdownMenuItem<T>(value: value, child: Text(name(value))),
      ],
      onChanged: locked ? null : (value) => onSelected(value as T),
    ),
  );
}

class PrimitiveItemRow extends StatelessWidget {
  const PrimitiveItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.locked,
    required this.showSide,
    required this.primitive,
    required this.chooseImage,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final ExerciseItem item;
  final int index;
  final int count;
  final bool locked;
  final bool showSide;
  final ExercisePrimitive primitive;
  final Future<String?> Function() chooseImage;
  final ValueChanged<ExerciseItem> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1} · ${item.id}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Move up',
                onPressed: locked || index == 0 ? null : () => onMove(-1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: locked || index >= count - 1
                    ? null
                    : () => onMove(1),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: locked ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // Below the header, so the header fits a 360-pixel window (Build
          // 261 Revision 6 follow-up).
          if (showSide) ...[
            DropdownButtonFormField<MatchSide?>(
              key: ValueKey('item-side-${item.id}'),
              initialValue: item.side,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Side',
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: menuText('No side')),
                DropdownMenuItem(
                  value: MatchSide.left,
                  child: menuText('Left'),
                ),
                DropdownMenuItem(
                  value: MatchSide.right,
                  child: menuText('Right'),
                ),
              ],
              onChanged: locked
                  ? null
                  : (value) => onChanged(
                      ExerciseItem(
                        id: item.id,
                        content: item.content,
                        side: value,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < item.content.length; i++)
            PrimitiveElementRow(
              key: ValueKey('${item.id}-$i-${item.content[i].type}'),
              element: item.content[i],
              primitive: primitive,
              place: ElementPlace.item,
              index: i,
              count: item.content.length,
              locked: locked,
              compact: true,
              chooseImage: chooseImage,
              onChanged: (element) {
                final content = List<PromptElement>.of(item.content);
                content[i] = element;
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
              onMove: (delta) {
                final content = List<PromptElement>.of(item.content);
                final moved = content.removeAt(i);
                content.insert(i + delta, moved);
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
              onRemove: () {
                final content = List<PromptElement>.of(item.content)
                  ..removeAt(i);
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final type in const ['text', 'audio', 'image'])
                OutlinedButton.icon(
                  onPressed: locked
                      ? null
                      : () => onChanged(
                          ExerciseItem(
                            id: item.id,
                            content: [
                              ...item.content,
                              PromptElement(type: type),
                            ],
                            side: item.side,
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: Text(switch (type) {
                    'audio' => 'Audio',
                    'image' => 'Image',
                    _ => 'Text',
                  }),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class PrimitiveTargetRow extends StatelessWidget {
  const PrimitiveTargetRow({
    super.key,
    required this.target,
    required this.locked,
    required this.onChanged,
    required this.onRemove,
  });

  final ExerciseTarget target;
  final bool locked;
  final ValueChanged<ExerciseTarget> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(target.id)),
              IconButton(
                tooltip: 'Remove',
                onPressed: locked ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // Below the ID, so the row fits a 360-pixel window (Build 261
          // Revision 6 follow-up).
          DropdownButtonFormField<TargetReveal?>(
            key: ValueKey('target-reveal-${target.id}'),
            initialValue: target.reveal,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Reveal',
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: null, child: menuText('Reveal nothing')),
              DropdownMenuItem(
                value: TargetReveal.firstGrapheme,
                child: menuText('Reveal the first letter'),
              ),
            ],
            onChanged: locked
                ? null
                : (value) => onChanged(
                    ExerciseTarget(
                      id: target.id,
                      reveal: value,
                      region: target.region,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class PrimitiveLayoutRow extends StatelessWidget {
  const PrimitiveLayoutRow({
    super.key,
    required this.element,
    required this.index,
    required this.count,
    required this.locked,
    required this.targetIds,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final LayoutElement element;
  final int index;
  final int count;
  final bool locked;
  final List<String> targetIds;
  final ValueChanged<LayoutElement> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: element.isTarget
              ? DropdownButtonFormField<String>(
                  initialValue: targetIds.contains(element.targetId)
                      ? element.targetId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Gap',
                  ),
                  items: [
                    for (final id in targetIds)
                      DropdownMenuItem(value: id, child: menuText(id)),
                  ],
                  onChanged: locked
                      ? null
                      : (value) {
                          if (value != null) {
                            onChanged(LayoutElement.target(value));
                          }
                        },
                )
              : TextFormField(
                  initialValue: element.text,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Text',
                  ),
                  onChanged: (value) => onChanged(LayoutElement.text(value)),
                ),
        ),
        IconButton(
          tooltip: 'Move up',
          onPressed: locked || index == 0 ? null : () => onMove(-1),
          icon: const Icon(Icons.arrow_upward),
        ),
        IconButton(
          tooltip: 'Move down',
          onPressed: locked || index >= count - 1 ? null : () => onMove(1),
          icon: const Icon(Icons.arrow_downward),
        ),
        IconButton(
          tooltip: 'Remove',
          onPressed: locked ? null : onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

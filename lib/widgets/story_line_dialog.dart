import 'package:flutter/material.dart';

import '../models/course_models.dart';

/// One Dialogue line as the Story Wizard types it (Build 256 Revision 5):
/// the speaker (empty for the narrator), the line, its mode (`text`,
/// `audio`, `both`), its read-aloud (`story`, `automatic`, `manual`) and
/// when its text shows (`immediate`, `afterAudio`). The draft builder turns
/// these into a Dialogue line exercise.
typedef StoryLineValues = ({
  String speakerId,
  String text,
  String mode,
  String readAloud,
  String textReveal,
});

/// Adds or edits a line of a Story in the Wizard. Returns null when
/// cancelled.
Future<StoryLineValues?> showStoryLineDialog(
  BuildContext context, {
  required StorySpeaker narrator,
  required List<StorySpeaker> characters,
  StoryLineValues? initial,
}) => showDialog<StoryLineValues>(
  context: context,
  builder: (_) => _StoryLineDialog(
    narrator: narrator,
    characters: characters,
    initial: initial,
  ),
);

class _StoryLineDialog extends StatefulWidget {
  const _StoryLineDialog({
    required this.narrator,
    required this.characters,
    this.initial,
  });

  final StorySpeaker narrator;
  final List<StorySpeaker> characters;
  final StoryLineValues? initial;

  @override
  State<_StoryLineDialog> createState() => _StoryLineDialogState();
}

class _StoryLineDialogState extends State<_StoryLineDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late String _speakerId = widget.initial?.speakerId ?? '';
  late String _mode = widget.initial?.mode ?? 'both';
  late String _readAloud = widget.initial?.readAloud ?? 'story';
  late String _textReveal = widget.initial?.textReveal ?? 'immediate';

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    // A line of a character that is no longer listed speaks as the narrator.
    if (_speakerId.isNotEmpty &&
        !widget.characters.any((character) => character.id == _speakerId)) {
      _speakerId = '';
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Widget _choice({
    required Key key,
    required String label,
    required String value,
    required Map<String, String> choices,
    required ValueChanged<String> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      items: [
        for (final entry in choices.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (selected) {
        if (selected != null) setState(() => onChanged(selected));
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final narratorName = widget.narrator.name.isEmpty
        ? 'Narrator'
        : 'Narrator (${widget.narrator.name})';
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add line' : 'Edit line'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _choice(
                key: const Key('story-line-speaker'),
                label: 'Speaker',
                value: _speakerId,
                choices: {
                  '': narratorName,
                  for (final character in widget.characters)
                    character.id: character.name,
                },
                onChanged: (value) => _speakerId = value,
              ),
              TextField(
                key: const Key('story-line-text'),
                controller: _text,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Line',
                  helperText:
                      'In the speaker\'s language; the learner reads it, hears it or both.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              _choice(
                key: const Key('story-line-mode'),
                label: 'Mode',
                value: _mode,
                choices: const {
                  'both': 'Text and audio',
                  'text': 'Text only',
                  'audio': 'Audio only',
                },
                onChanged: (value) => _mode = value,
              ),
              if (_mode != 'text')
                _choice(
                  key: const Key('story-line-read-aloud'),
                  label: 'Read-aloud',
                  value: _readAloud,
                  choices: const {
                    'story': 'As the Story says',
                    'automatic': 'Automatic',
                    'manual': 'On request',
                  },
                  onChanged: (value) => _readAloud = value,
                ),
              if (_mode == 'both')
                _choice(
                  key: const Key('story-line-text-reveal'),
                  label: 'Show text',
                  value: _textReveal,
                  choices: const {
                    'immediate': 'Immediately',
                    'afterAudio': 'After listening',
                  },
                  onChanged: (value) => _textReveal = value,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('story-line-save'),
          onPressed: _text.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (
                  speakerId: _speakerId,
                  text: _text.text.trim(),
                  mode: _mode,
                  readAloud: _readAloud,
                  textReveal: _textReveal,
                )),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

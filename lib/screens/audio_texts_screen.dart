import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course_models.dart';
import '../services/course_audio_texts.dart';
import '../services/file_dialog_service.dart';
import '../widgets/course_preview_flag.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/reported_action.dart';

/// Texts in this Course (Build 271 Revision 2, owner decisions of 10 and 11
/// October 2026): every text the Course speaks with how far its recordings
/// go, for an author who is recording. Opened from the Audio Library's Check
/// menu, and from Associate recording, where a tap on a text returns it
/// ([pick]). It reads the working copy and changes nothing.
class AudioTextsScreen extends StatefulWidget {
  const AudioTextsScreen({
    super.key,
    required this.course,
    this.pick = false,
    this.dialogs,
  });

  final Course course;

  /// Whether a tap on a text closes the screen and returns that text.
  final bool pick;

  /// The system dialogs (a test seam).
  final FileDialogService? dialogs;

  @override
  State<AudioTextsScreen> createState() => _AudioTextsScreenState();
}

class _AudioTextsScreenState extends State<AudioTextsScreen> {
  final _search = TextEditingController();
  late final FileDialogService _dialogs = widget.dialogs ?? FileDialogService();
  late final List<CourseSpokenText> _all = CourseAudioTexts.of(widget.course);
  bool _onlyIncomplete = false;

  List<CourseSpokenText> get _shown => CourseAudioTexts.filtered(
    _all,
    query: _search.text,
    onlyIncomplete: _onlyIncomplete,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _count(int count) => '$count text${count == 1 ? '' : 's'}';

  Future<void> _copy() async {
    final shown = _shown;
    await Clipboard.setData(
      ClipboardData(text: CourseAudioTexts.export(shown)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('audio-texts-copied'),
        content: Text('Copied ${_count(shown.length)}.'),
      ),
    );
  }

  Future<void> _saveAs() => runReported(context, 'Saving the texts', () async {
    final shown = _shown;
    final result = await _dialogs.saveBytes(
      bytes: Uint8List.fromList(utf8.encode(CourseAudioTexts.export(shown))),
      suggestedName: CourseAudioTexts.exportFileName(widget.course),
      extensions: const ['txt'],
      artifact: 'course-texts',
    );
    if (!mounted) return;
    showFileDialogFeedback(
      context,
      result,
      saving: true,
      savedMessage: '${_count(shown.length)} saved as ${result.displayName}.',
      fallbackHint: 'You can use Copy instead and paste the texts elsewhere.',
    );
  });

  Color _dot(AudioTextState state, ColorScheme scheme) => switch (state) {
    AudioTextState.ownRecording => Colors.green.shade600,
    AudioTextState.allParts => Colors.teal.shade400,
    AudioTextState.someParts => Colors.amber.shade700,
    AudioTextState.none => scheme.outline,
  };

  Widget _row(int index, CourseSpokenText text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final grey = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return ListTile(
      key: Key('audio-text-$index'),
      dense: true,
      title: Text(text.text),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  key: Key('audio-text-state-$index-${text.state.name}'),
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: text.state == AudioTextState.none
                        ? null
                        : _dot(text.state, scheme),
                    border: Border.all(
                      color: _dot(text.state, scheme),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              TextSpan(text: CourseAudioTexts.stateLabel(text)),
              TextSpan(text: ' · ${CourseAudioTexts.exercisesLabel(text)}'),
              if (text.draft) const TextSpan(text: ' · Draft'),
            ],
          ),
          style: grey,
        ),
      ),
      onTap: widget.pick ? () => Navigator.pop(context, text.text) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: CoursePreviewTitle(
          course: widget.course,
          title: const Text('Texts in this Course'),
        ),
        actions: [
          IconButton(
            key: const Key('audio-texts-copy'),
            tooltip: 'Copy the texts shown',
            onPressed: shown.isEmpty ? null : _copy,
            icon: const Icon(Icons.copy_outlined),
          ),
          if (_dialogs.isAvailable)
            IconButton(
              key: const Key('audio-texts-save-as'),
              tooltip: 'Save as…',
              onPressed: shown.isEmpty ? null : _saveAs,
              icon: const Icon(Icons.save_alt_outlined),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              widget.pick
                  ? 'Every text this Course speaks, Draft exercises '
                        'included. Tap a text to give it to the recording.'
                  : 'Every text this Course speaks, Draft exercises '
                        'included, with what its recordings say of it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              key: const Key('audio-texts-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.search),
                labelText: 'Search',
              ),
            ),
          ),
          SwitchListTile(
            key: const Key('audio-texts-only-incomplete'),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text('Only texts without a complete recording'),
            value: _onlyIncomplete,
            onChanged: (value) => setState(() => _onlyIncomplete = value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Text(
              shown.length == _all.length
                  ? _count(_all.length)
                  : '${shown.length} of ${_count(_all.length)}',
              key: const Key('audio-texts-count'),
              style: theme.textTheme.labelMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _all.isEmpty
                          ? 'This Course speaks no text yet.'
                          : _onlyIncomplete && _search.text.trim().isEmpty
                          ? 'Every text has a complete recording.'
                          : 'No text matches.',
                      key: const Key('audio-texts-empty'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    key: const Key('audio-texts-list'),
                    itemCount: shown.length,
                    itemBuilder: (context, index) => _row(index, shown[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

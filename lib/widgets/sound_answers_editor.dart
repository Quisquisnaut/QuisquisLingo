import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/exercise_draft_builder.dart';
import '../services/recorded_audio_service.dart';

/// Build 274 Revision 3: the answers of Listen and pick the missing word in
/// its form. Each answer is a word the voice reads, or, in a Course with
/// recordings (Recorded MP3 only or Hybrid), a recording of the Audio
/// Library; each may have a text shown once the learner has answered. Every
/// change goes to [onChanged] as the form's answers.
class SoundAnswersEditor extends StatefulWidget {
  const SoundAnswersEditor({
    super.key,
    required this.answers,
    required this.onChanged,
    required this.helpButton,
    this.course,
    this.readOnly = false,
    this.recordedAudio,
  });

  /// The answers when the form opens; two empty rows when there are none.
  final List<SoundAnswerDraft> answers;
  final ValueChanged<List<SoundAnswerDraft>> onChanged;

  /// The Help control of the answers.
  final Widget Function() helpButton;
  final Course? course;
  final bool readOnly;

  /// Test seam for the recordings' Play buttons.
  final RecordedAudioService? recordedAudio;

  /// The name of [clip] in the recording menu: its text, else the name its
  /// file came with, else its place in the Audio Library.
  static String recordingLabel(CourseAudioClip clip, int index) {
    if (clip.text.trim().isNotEmpty) return clip.text.trim();
    if (clip.originalFileName.isNotEmpty) return clip.originalFileName;
    return 'Recording ${index + 1}';
  }

  @override
  State<SoundAnswersEditor> createState() => _SoundAnswersEditorState();
}

class _Row {
  _Row(SoundAnswerDraft answer)
    : word = TextEditingController(text: answer.word),
      afterAnswer = TextEditingController(text: answer.afterAnswer),
      recording = answer.recording,
      useRecording = answer.recording.isNotEmpty;

  final TextEditingController word;
  final TextEditingController afterAnswer;
  String recording;
  bool useRecording;

  SoundAnswerDraft get value => SoundAnswerDraft(
    word: useRecording ? '' : word.text,
    recording: useRecording ? recording : '',
    afterAnswer: afterAnswer.text,
  );

  void dispose() {
    word.dispose();
    afterAnswer.dispose();
  }
}

class _SoundAnswersEditorState extends State<SoundAnswersEditor> {
  late final List<_Row> _rows = [
    for (final answer
        in widget.answers.isEmpty
            ? const [SoundAnswerDraft(), SoundAnswerDraft()]
            : widget.answers)
      _Row(answer),
  ];
  late final RecordedAudioService _audio =
      widget.recordedAudio ?? RecordedAudioService();

  List<CourseAudioClip> get _library =>
      widget.course?.audioLibrary ?? const <CourseAudioClip>[];

  /// Recordings are offered in a Course that plays them (owner decision of
  /// 16 October 2026: On-Device TTS plays none), and kept for an answer that
  /// already has one.
  bool get _recordingsOffered =>
      widget.course != null && widget.course!.audioMode != 'tts';

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _changed() => widget.onChanged([for (final row in _rows) row.value]);

  void _add() {
    setState(() => _rows.add(_Row(const SoundAnswerDraft())));
    _changed();
  }

  void _remove(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _changed();
  }

  Future<void> _play(CourseAudioClip clip) async {
    final course = widget.course;
    if (course == null) return;
    final played = await _audio.playClips([clip], courseId: course.courseId);
    if (!played && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This recording cannot be played: its file is missing.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('sound-answers-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Answers',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            widget.helpButton(),
          ],
        ),
        Text(
          _recordingsOffered
              ? 'At least two. Each answer is a word the voice reads (or its recording, found by its text) or a recording of the Audio Library.'
              : 'At least two. Each answer is a word the voice reads. Recordings can be chosen in a Course whose audio source is Recorded MP3 only or Hybrid (Audio Library).',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _rows.length; i++) _answerRow(i),
        if (!widget.readOnly)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('sound-answers-add'),
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add answer'),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _answerRow(int i) {
    final row = _rows[i];
    final library = _library;
    final known = library.any((clip) => clip.id == row.recording);
    final choice = row.useRecording || _recordingsOffered;
    return Card(
      key: ValueKey('sound-answer-row-$i'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Answer ${i + 1}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                if (!widget.readOnly)
                  IconButton(
                    key: ValueKey('sound-answer-remove-$i'),
                    tooltip: 'Remove this answer',
                    onPressed: () => _remove(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (choice) ...[
              SegmentedButton<bool>(
                key: ValueKey('sound-answer-kind-$i'),
                segments: const [
                  ButtonSegment(value: false, label: Text('Word')),
                  ButtonSegment(value: true, label: Text('Recording')),
                ],
                selected: {row.useRecording},
                onSelectionChanged: widget.readOnly
                    ? null
                    : (value) {
                        setState(() => row.useRecording = value.first);
                        _changed();
                      },
              ),
              const SizedBox(height: 10),
            ],
            if (!row.useRecording)
              TextField(
                key: ValueKey('sound-answer-word-$i'),
                controller: row.word,
                readOnly: widget.readOnly,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Word',
                  helperText: 'The voice reads it, or its recording plays.',
                  suffixIcon: widget.helpButton(),
                ),
                onChanged: (_) => _changed(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('sound-answer-recording-$i'),
                      initialValue: row.recording.isEmpty
                          ? null
                          : row.recording,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Recording',
                      ),
                      items: [
                        for (final (index, clip) in library.indexed)
                          DropdownMenuItem(
                            value: clip.id,
                            child: Text(
                              SoundAnswersEditor.recordingLabel(clip, index),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (row.recording.isNotEmpty && !known)
                          DropdownMenuItem(
                            value: row.recording,
                            child: const Text(
                              'Missing from the Audio Library',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: widget.readOnly
                          ? null
                          : (value) {
                              setState(() => row.recording = value ?? '');
                              _changed();
                            },
                    ),
                  ),
                  IconButton(
                    key: ValueKey('sound-answer-play-$i'),
                    tooltip: 'Play the recording',
                    onPressed: !known
                        ? null
                        : () => unawaited(
                            _play(
                              library.firstWhere(
                                (clip) => clip.id == row.recording,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.play_arrow_outlined),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            TextField(
              key: ValueKey('sound-answer-after-$i'),
              controller: row.afterAnswer,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Text shown after the answer (optional)',
                helperText:
                    'Recommended for a recording. Without it the answer shows its word, else its recording’s text.',
                helperMaxLines: 3,
                suffixIcon: widget.helpButton(),
              ),
              onChanged: (_) => _changed(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/exercise_labels.dart';
import '../services/file_dialog_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/course_models.dart';
import '../services/audio_library_index.dart';
import '../services/exercise_search_service.dart';
import '../services/lesson_presentation_service.dart';
import '../services/recorded_audio_service.dart';
import 'editor_help_screen.dart';
import 'exercise_editor_screen.dart';
import '../services/round_type_presentation.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/course_preview_flag.dart';
import '../widgets/import_summary.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/quick_import_access.dart';
import '../widgets/labelled_text.dart';
import '../services/course_audio_usage.dart';
import '../services/course_audio_texts.dart';
import '../services/course_media_store.dart';
import '../services/sound_answers.dart';
import '../widgets/folder_opener.dart';
import '../widgets/library_save_notice.dart';
import 'audio_texts_screen.dart';

class AudioLibraryScreen extends StatefulWidget {
  final Course course;
  const AudioLibraryScreen({super.key, required this.course});

  /// The Editor Help question the screen's Help opens at: the first of its
  /// sound questions (audio modes, adding recordings, the texts to record,
  /// how recordings travel).
  static const helpQuestion = 'audioModes';

  /// What a recording without a text says in the list.
  static const noTextLabel = 'Tap to give it its text';

  /// The body height from which the notice, the audio source and the A–Z
  /// bar stay in place; a shorter window scrolls them with the recordings.
  static const fixedHeaderMinimumHeight = 420.0;

  /// The one line under the audio source (Build 271 Revision 2, the owner's
  /// wording); the rest is in the Editor Help.
  static String sourceLine(String audioMode) => switch (audioMode) {
    'recorded' =>
      'Only your recordings play; a text without a complete recording stays '
          'silent.',
    'hybrid' =>
      'Your recordings play first; the device’s voice reads a text they '
          'don’t fully cover.',
    _ => 'The device’s voice reads every text; no recordings are needed.',
  };

  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final _audio = RecordedAudioService();
  final AudioPlayer _previewPlayer = AudioPlayer();
  late Course _course;
  bool _routeMayPop = false;

  /// Rebuilds the audio source menu when a switch is kept back (Build 274
  /// Revision 3), so it shows the source the Course keeps.
  int _sourceMenuVersion = 0;

  /// The recording whose preview plays; its row and Associate recording
  /// both show it.
  final _playing = ValueNotifier<String?>(null);
  final Map<String, GlobalKey> _letterKeys = {};

  /// Clips whose file no longer resolves. A clip that still carries its word
  /// is not an orphan, so the orphan tool never reports it; without this the
  /// only sign would be a failed preview.
  Set<String> _missingClipIds = const {};

  /// Which exercises play each recording (Build 270 Revision 13), worked
  /// out again only when the draft changes.
  Course? _usesCourse;
  Map<String, List<AudioClipUse>> _usesCache = const {};
  Map<String, List<AudioClipUse>> get _uses {
    if (!identical(_usesCourse, _course)) {
      _usesCourse = _course;
      _usesCache = CourseAudioUsage.usesByClip(
        _course,
        (text) => _audio.segment(text, _course.audioLibrary),
      );
    }
    return _usesCache;
  }

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) _playing.value = null;
    });
    _refreshMissingClips();
  }

  Future<void> _refreshMissingClips() async {
    final missing = <String>{};
    for (final clip in _course.audioLibrary) {
      final source = await _audio.resolveSourceForClip(
        clip,
        courseId: _course.courseId,
      );
      if (source == null) missing.add(clip.id);
    }
    if (!mounted) return;
    setState(() => _missingClipIds = Set.unmodifiable(missing));
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    _playing.dispose();
    super.dispose();
  }

  Course _copy({String? mode, List<CourseAudioClip>? clips}) =>
      Course.fromJson({
        ..._course.toJson(),
        'audioMode': mode ?? _course.audioMode,
        'audioLibrary': (clips ?? _course.audioLibrary)
            .map((clip) => clip.toJson())
            .toList(),
      });
  Future<void> _importFromDialog() async {
    try {
      // Open from…: up to 100 MP3s, each checked like a folder import.
      final picked = await _audio.importMp3sFromDialog(
        _course.courseId,
        existingReferences: {
          for (final clip in _course.audioLibrary) clip.filePath,
        },
      );
      if (!mounted) return;
      if (picked.dialog.outcome != FileDialogOutcome.opened) {
        showFileDialogFeedback(
          context,
          picked.dialog,
          saving: false,
          fallbackHint: mp3FallbackHint,
        );
        return;
      }
      if (picked.clips.isNotEmpty) {
        setState(
          () => _course = _copy(
            clips: [..._course.audioLibrary, ...picked.clips],
          ),
        );
        unawaited(_refreshMissingClips());
      }
      await showImportSummary(
        context,
        title: 'MP3 files imported',
        items: picked.results,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  Future<void> _import() async {
    switch (await ensureQuickImportAccess(
      context,
      offerOpenFrom: _audio.fileDialogsAvailable,
    )) {
      case QuickImportAccess.ready:
        break;
      case QuickImportAccess.openFrom:
        return _importFromDialog();
      case QuickImportAccess.stop:
        return;
    }
    if (!mounted) return;
    try {
      final clips = await _audio.importMp3Files(
        _course.courseId,
        existingReferences: {
          for (final clip in _course.audioLibrary) clip.filePath,
        },
      );
      if (clips.isNotEmpty && mounted) {
        setState(
          () => _course = _copy(clips: [..._course.audioLibrary, ...clips]),
        );
        unawaited(_refreshMissingClips());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Imported ${clips.length} MP3 file${clips.length == 1 ? '' : 's'} from ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  /// Whether Open folder can show where this recording is stored: only for
  /// a recording in the Course's own folder, on a system that opens folders.
  bool _canOpenFolder(CourseAudioClip clip) =>
      FolderOpener.available() && CourseMediaStore.isReference(clip.filePath);

  /// Opens the Course's media folder; false when it could not be shown.
  Future<bool> _openMediaFolder() async {
    try {
      final folder = await CourseMediaStore().courseDirectory(_course.courseId);
      if (!await folder.exists()) return false;
      return await FolderOpener.open(folder.path);
    } catch (_) {
      return false;
    }
  }

  /// Associate recording (Build 271 Revision 2): the file's names, Play,
  /// Open folder, the text and Texts in this Course. A text that another
  /// recording already says by itself takes that recording's place, after
  /// the author agrees; the other one then waits under #.
  Future<void> _editById(String id) async {
    final i = _course.audioLibrary.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final clip = _course.audioLibrary[i];
    final result = await showDialog<({String text, String? replaced})>(
      context: context,
      builder: (ctx) => _AssociateRecordingDialog(
        course: _course,
        clip: clip,
        missing: _missingClipIds.contains(clip.id),
        playing: _playing,
        onPlay: () => _preview(clip),
        onOpenFolder: _canOpenFolder(clip) ? _openMediaFolder : null,
      ),
    );
    if (result == null || !mounted) return;
    setState(
      () => _course = _copy(
        clips: [
          for (final entry in _course.audioLibrary)
            if (entry.id == id)
              entry.withText(result.text)
            else if (entry.id == result.replaced)
              entry.withText('')
            else
              entry,
        ],
      ),
    );
  }

  void _showTexts() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => AudioTextsScreen(course: _course)),
    );
  }

  Future<void> _deleteById(String id) async {
    final i = _course.audioLibrary.indexWhere((e) => e.id == id);
    if (i < 0) return;
    // Build 274 Revision 3 (owner decision of 16 October 2026): a recording
    // that answers name by its id is deleted only after asking.
    final naming = CourseAudioUsage.answersNaming(_course, id);
    if (naming.isNotEmpty && !await _confirmDeleteNamed(naming)) return;
    if (!mounted) return;
    final at = _course.audioLibrary.indexWhere((e) => e.id == id);
    if (at < 0) return;
    if (_playing.value == id) {
      await _previewPlayer.stop();
      _playing.value = null;
    }
    final list = [..._course.audioLibrary]..removeAt(at);
    setState(() => _course = _copy(clips: list));
    unawaited(_refreshMissingClips());
  }

  /// Build 274 Revision 3 (owner decision of 16 October 2026): On-Device TTS
  /// plays no recordings, chosen ones included, so switching to it while
  /// answers play recordings asks first.
  Future<void> _chooseSource(String mode) async {
    if (mode == _course.audioMode) return;
    final named = SoundAnswers.answersWithRecordings(_course);
    if (mode == 'tts' && named > 0) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('audio-tts-named-dialog'),
          title: const Text('Answers will lose their sound'),
          content: Text(
            '$named answer${named == 1 ? '' : 's'} of this Course play'
            '${named == 1 ? 's' : ''} a recording of the Audio Library. '
            'On-Device TTS plays no recordings, so '
            '${named == 1 ? 'it' : 'those answers'} will have no sound and '
            'the Course Audit shows an Error for each exercise concerned. '
            'Until ${named == 1 ? 'it is' : 'they are'} fixed, learners skip '
            '${named == 1 ? 'that exercise' : 'those exercises'} and the '
            'Course cannot be imported on another device.',
          ),
          actions: [
            TextButton(
              key: const Key('audio-tts-named-keep'),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep the current source'),
            ),
            FilledButton(
              key: const Key('audio-tts-named-switch'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Switch to On-Device TTS'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (go != true) {
        setState(() => _sourceMenuVersion++);
        return;
      }
    }
    setState(() => _course = _copy(mode: mode));
  }

  /// Asks before deleting a recording that answers play, naming their
  /// exercises.
  Future<bool> _confirmDeleteNamed(List<AudioClipUse> naming) async {
    final count = naming.length;
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('audio-delete-named-dialog'),
        title: const Text('Answers play this recording'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  count == 1
                      ? '1 exercise plays this recording as an answer. Once '
                            'it is deleted, the answers that play it have no '
                            'sound and the Course Audit shows an Error for the '
                            'exercise. '
                            'Until it is fixed, learners skip the exercise '
                            'and the Course cannot be imported on another '
                            'device.'
                      : '$count exercises play this recording as an answer. '
                            'Once it is deleted, those answers have no sound '
                            'and the Course Audit shows an Error for each '
                            'exercise. Until they are fixed, learners skip '
                            'those exercises and the Course cannot be imported '
                            'on another device.',
                ),
              ),
              for (final (index, use) in naming.indexed)
                ListTile(
                  key: Key('audio-delete-named-$index'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    ExerciseLabels.summary(use.exercise),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _usePlace(use),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('audio-delete-named-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('audio-delete-named-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _preview(CourseAudioClip clip) async {
    if (_playing.value == clip.id) {
      await _previewPlayer.stop();
      if (mounted) _playing.value = null;
      return;
    }
    try {
      final source = await _audio.resolveSourceForClip(
        clip,
        courseId: _course.courseId,
      );
      if (source == null) throw StateError('MP3 source is missing');
      await _previewPlayer.stop();
      await _previewPlayer.play(source);
      if (mounted) _playing.value = clip.id;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Could not play this MP3 file.'),
        ),
      );
    }
  }

  Future<void> _orphans() async {
    // Build 270 Revision 13 (owner decision): the recordings no exercise
    // plays; those without text are under # already.
    final list = CourseAudioUsage.unused(_course, _uses);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('audio-unused-dialog'),
        title: Text(
          '${list.length} unused MP3 file${list.length == 1 ? '' : 's'}',
        ),
        content: SingleChildScrollView(
          child: Text(
            list.isEmpty
                ? 'Every recording with a text is played by an exercise.'
                : 'No exercise plays these recordings. Removing them takes '
                      'them out of this Course; their files are deleted when '
                      'the Course is saved.\n\n'
                      '${list.map((clip) => clip.text.trim()).join('\n')}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (list.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final ids = list.map((e) => e.id).toSet();
                setState(
                  () => _course = _copy(
                    clips: _course.audioLibrary
                        .where((e) => !ids.contains(e.id))
                        .toList(),
                  ),
                );
                unawaited(_refreshMissingClips());
              },
              child: const Text('Remove these recordings'),
            ),
        ],
      ),
    );
  }

  /// "Used in N exercises", opening the list, or "Not used by any
  /// exercise" (Build 270 Revision 13).
  Widget _usesLine(CourseAudioClip clip) {
    final uses = _uses[clip.id] ?? const <AudioClipUse>[];
    final scheme = Theme.of(context).colorScheme;
    if (uses.isEmpty) {
      return Text(
        'Not used by any exercise',
        key: Key('audio-clip-unused-${clip.id}'),
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }
    return InkWell(
      key: Key('audio-clip-uses-${clip.id}'),
      onTap: () => _showUses(clip, uses),
      child: Text(
        'Used in ${uses.length} exercise${uses.length == 1 ? '' : 's'}',
        style: TextStyle(
          color: scheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  /// The exercises that play [clip]; a tap opens one, as Search does, and
  /// its changes stay in this draft.
  Future<void> _showUses(CourseAudioClip clip, List<AudioClipUse> uses) async {
    final chosen = await showDialog<AudioClipUse>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('audio-clip-uses-dialog'),
        title: Text(
          clip.text.trim().isEmpty
              ? 'This recording is heard in'
              : '“${clip.text.trim()}” is heard in',
        ),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Only texts that recordings say from beginning to end '
                  'count, and answers that name the recording. Tap an '
                  'exercise to open it.',
                ),
              ),
              for (final (index, use) in uses.indexed)
                ListTile(
                  key: Key('audio-clip-use-$index'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    ExerciseLabels.summary(use.exercise),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: _usePlace(use),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(ctx, use),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    final lesson = _course.lessons[chosen.lessonIndex];
    final round = lesson.rounds[chosen.roundIndex];
    final changed = await openSearchResult(
      context,
      course: _course,
      result: ExerciseSearchResult(
        lessonIndex: chosen.lessonIndex,
        roundIndex: chosen.roundIndex,
        exerciseIndex: chosen.exerciseIndex,
        lessonId: lesson.lessonId,
        roundId: round.id,
        exerciseId: chosen.exercise.id,
        exerciseType: chosen.exercise.primitive.serialized,
        exerciseDisplayName: ExerciseLabels.summary(chosen.exercise),
        matchingExcerpt: '',
        matchedFieldLabel: '',
        idMatch: false,
      ),
      readOnly: false,
      initiallyInspecting: false,
    );
    if (changed != null && mounted) {
      setState(() => _course = changed);
      unawaited(_refreshMissingClips());
    }
  }

  /// "Lesson 2: Food › Step 3 · Practice › Exercise 4", labels in the label
  /// style (Build 270 Revision 12).
  Widget _usePlace(AudioClipUse use) {
    final identity = const LessonPresentationService().identity(
      _course,
      use.lessonIndex,
    );
    final round = _course.lessons[use.lessonIndex].rounds[use.roundIndex];
    final roundPrefix = RoundTypePresentation.prefix(
      round.roundType,
      use.roundIndex + 1,
      _course.roundNumberingMode,
      customPrefix: _course.customRoundLabel,
    );
    final roundTitle = RoundTypePresentation.title(
      round,
      use.roundIndex + 1,
      _course.roundNumberingMode,
      customPrefix: _course.customRoundLabel,
    );
    return LabelledText.all(
      '${identity.fullText} › $roundTitle › Exercise ${use.exerciseIndex + 1}',
      labels: [identity.prefix, roundPrefix],
    );
  }

  /// Build 270 Revision 12 (owner report): the clips are built only near
  /// the screen, so a letter's header is a sliver of its own that is always
  /// built. The first move lands where the clips in between are estimated to
  /// end; once they are laid out, the next moves put the letter in place.
  Future<void> _jump(String letter) async {
    for (var pass = 0; pass < 3; pass++) {
      final ctx = _letterKeys[letter]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await Scrollable.ensureVisible(
        ctx,
        duration: pass == 0 ? const Duration(milliseconds: 250) : Duration.zero,
        alignment: .08,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) => PopupMenuItem<String>(
    key: key,
    value: value,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    ),
  );

  /// Build 271 Revision 2 (owner decisions of 10 and 11 October 2026): what
  /// stays in place above the recordings. The one-line notice, the audio
  /// source with its one line and the A–Z bar.
  Widget _header(List<AudioLibraryGroup> groups) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LibrarySaveNotice(key: Key('audio-library-save-notice')),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: ValueKey('audio-source-$_sourceMenuVersion'),
            child: DropdownButtonFormField<String>(
              key: const Key('audio-source'),
              initialValue: _course.audioMode,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: 'Course audio source',
              ),
              items: const [
                DropdownMenuItem(value: 'tts', child: Text('On-Device TTS')),
                DropdownMenuItem(
                  value: 'recorded',
                  child: Text('Recorded MP3 only'),
                ),
                DropdownMenuItem(
                  value: 'hybrid',
                  child: Text('Hybrid: MP3 + TTS fallback'),
                ),
              ],
              onChanged: (v) {
                if (v != null) unawaited(_chooseSource(v));
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AudioLibraryScreen.sourceLine(_course.audioMode),
            key: const Key('audio-source-line'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: ListView(
                key: const Key('audio-library-letters'),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final group in groups)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        label: Text(group.key),
                        onPressed: () => _jump(group.key),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build 270 Revision 12 (owner decisions): # (no text), 0–9, the
    // letters without accents, other scripts; AudioLibraryIndex owns the rule.
    final groups = AudioLibraryIndex.groups(_course.audioLibrary);
    // Recordings are managed only where the Course plays them.
    final recorded = _course.audioMode != 'tts';
    const chooseFirst = 'choose Recorded MP3 only or Hybrid first';
    final slivers = <Widget>[
      if (groups.isEmpty && recorded)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No recordings yet. Add to the Course, at the top, imports '
              'MP3 files.',
              key: Key('audio-library-empty'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      for (final group in groups) ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: Padding(
              key: _letterKeys.putIfAbsent(group.key, () => GlobalKey()),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: Text(
                group.heading,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
            itemCount: group.clips.length,
            itemBuilder: (context, index) => _clipCard(group.clips[index]),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
    ];
    return PopScope<Course>(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: CoursePreviewTitle(
            course: _course,
            title: const Text('Audio Library'),
          ),
          // Three icons (owner rule): Help, Add to the Course, Check.
          actions: [
            IconButton(
              key: const Key('audio-library-help'),
              tooltip: 'Help: sound',
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const EditorHelpScreen(
                    question: AudioLibraryScreen.helpQuestion,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              key: const Key('audio-library-add'),
              enabled: recorded,
              tooltip: recorded
                  ? 'Add to the Course'
                  : 'Add to the Course: $chooseFirst',
              icon: const Icon(Icons.library_add_outlined),
              onSelected: (value) =>
                  value == 'open' ? _importFromDialog() : _import(),
              itemBuilder: (_) => [
                _menuItem(
                  value: 'quick',
                  key: const Key('audio-quick-import'),
                  icon: Icons.library_music_outlined,
                  title: 'Quick Import',
                  subtitle:
                      'Every MP3 in '
                      '${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}',
                ),
                if (_audio.fileDialogsAvailable)
                  _menuItem(
                    value: 'open',
                    key: const Key('open-mp3-from'),
                    icon: Icons.folder_open_outlined,
                    title: 'Open from…',
                    subtitle: 'Choose MP3 files',
                  ),
              ],
            ),
            PopupMenuButton<String>(
              key: const Key('audio-library-check'),
              enabled: recorded,
              tooltip: recorded ? 'Check' : 'Check: $chooseFirst',
              icon: const Icon(Icons.fact_check_outlined),
              onSelected: (value) =>
                  value == 'texts' ? _showTexts() : _orphans(),
              itemBuilder: (_) => [
                _menuItem(
                  value: 'texts',
                  key: const Key('audio-check-texts'),
                  icon: Icons.format_list_bulleted,
                  title: 'Texts in this Course',
                  subtitle: 'What is recorded and what is missing',
                ),
                _menuItem(
                  value: 'unused',
                  key: const Key('audio-check-unused'),
                  icon: Icons.cleaning_services_outlined,
                  title: 'Unused MP3 files',
                  subtitle: 'Recordings no exercise plays',
                ),
              ],
            ),
          ],
        ),
        // Only the groups and recordings scroll; a window too short for
        // that scrolls everything, so the recordings always have room.
        body: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxHeight >=
                  AudioLibraryScreen.fixedHeaderMinimumHeight
              ? Column(
                  children: [
                    _header(groups),
                    Expanded(
                      child: CustomScrollView(
                        key: const Key('audio-library-list'),
                        slivers: slivers,
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  key: const Key('audio-library-list'),
                  slivers: [
                    SliverToBoxAdapter(child: _header(groups)),
                    ...slivers,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _clipCard(CourseAudioClip clip) {
    final hasText = clip.text.trim().isNotEmpty;
    final missing = _missingClipIds.contains(clip.id);
    // Build 274 Revision 3: a recording without text that answers name is
    // used too, and says where.
    final named = !hasText && (_uses[clip.id] ?? const []).isNotEmpty;
    // Follow-up (owner decision of 11 October 2026): a recording without
    // text shows the name its file came with, in grey, so freshly imported
    // recordings can be told apart without opening each one.
    final original = hasText ? '' : clip.originalFileName;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        key: Key('audio-clip-row-${clip.id}'),
        leading: ValueListenableBuilder<String?>(
          valueListenable: _playing,
          builder: (context, playing, _) => IconButton(
            tooltip: playing == clip.id ? 'Stop preview' : 'Play preview',
            icon: Icon(
              playing == clip.id
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
            onPressed: () => _preview(clip),
          ),
        ),
        // The stored file name says nothing to an author; Associate
        // recording shows it. A recording with a text shows no file name.
        title: hasText
            ? Text(clip.text)
            : Text(
                AudioLibraryScreen.noTextLabel,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
        subtitle: hasText || named || missing || original.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (original.isNotEmpty)
                    Text(
                      original,
                      key: Key('audio-clip-original-${clip.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  if (missing)
                    Text(
                      'File missing. Delete this recording to remove its '
                      'reference, then save the Course.',
                      key: Key('audio-clip-missing-${clip.id}'),
                      style: TextStyle(color: scheme.error),
                    ),
                  if (hasText || named) _usesLine(clip),
                ],
              )
            : null,
        isThreeLine: (hasText || named) && missing,
        onTap: () => _editById(clip.id),
        trailing: IconButton(
          tooltip: 'Delete this recording',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteById(clip.id),
        ),
      ),
    );
  }

  /// Leaving the screen returns the draft, so there is no Save button. The
  /// Course Editor stages it in the working copy; the single top-level Course
  /// confirmation is still the only thing that writes it.
  Future<void> _leave() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _course);
  }
}

/// Associate recording (Build 271 Revision 2, owner decisions of 10 and 11
/// October 2026): what the author needs to say which text a recording
/// speaks. It returns the text and, when another recording already said it
/// by itself and the author agreed to replace it, that recording's ID.
class _AssociateRecordingDialog extends StatefulWidget {
  const _AssociateRecordingDialog({
    required this.course,
    required this.clip,
    required this.missing,
    required this.playing,
    required this.onPlay,
    required this.onOpenFolder,
  });

  final Course course;
  final CourseAudioClip clip;

  /// Whether the recording's file is no longer on the device.
  final bool missing;

  /// The ID of the recording whose preview plays.
  final ValueNotifier<String?> playing;
  final VoidCallback onPlay;

  /// Opens the folder that stores the file; null where it is not offered.
  final Future<bool> Function()? onOpenFolder;

  @override
  State<_AssociateRecordingDialog> createState() =>
      _AssociateRecordingDialogState();
}

class _AssociateRecordingDialogState extends State<_AssociateRecordingDialog> {
  late final _text = TextEditingController(text: widget.clip.text);
  String? _folderMessage;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// The file's name in the Course's folder, in full.
  String get _storedName => CourseMediaStore.isReference(widget.clip.filePath)
      ? CourseMediaStore.fileNameOf(widget.clip.filePath)
      : widget.clip.filePath;

  Future<void> _openFolder() async {
    final opened = await widget.onOpenFolder!();
    if (!mounted) return;
    setState(
      () => _folderMessage = opened ? null : 'The folder could not be opened.',
    );
  }

  Future<void> _pickText() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AudioTextsScreen(course: widget.course, pick: true),
      ),
    );
    if (picked == null || !mounted) return;
    // A text of several lines is one text for a recording.
    final oneLine = picked.trim().split(RegExp(r'\s*\n\s*')).join(' ');
    setState(() {
      _text.text = oneLine;
      _text.selection = TextSelection.collapsed(offset: oneLine.length);
    });
  }

  Future<void> _apply() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final other = CourseAudioTexts.ownRecordingOf(
      text,
      widget.course.audioLibrary,
      except: widget.clip.id,
    );
    if (other != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('audio-replace-dialog'),
          title: const Text('Replace the recording?'),
          content: Text(
            '“$text” already has a recording. Replace it? The old one '
            'loses its text and moves under #.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('audio-replace-confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    Navigator.pop(context, (text: text, replaced: other?.id));
  }

  Widget _fileLine(String label, String name, Key key) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SelectableText(name, key: key, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const Key('audio-associate-dialog'),
      title: const Text('Associate recording'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.clip.originalFileName.isNotEmpty)
                _fileLine(
                  'Original file',
                  widget.clip.originalFileName,
                  const Key('audio-associate-original'),
                ),
              _fileLine(
                'Stored as',
                _storedName,
                const Key('audio-associate-stored'),
              ),
              if (widget.missing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'This file is no longer on the device.',
                    key: const Key('audio-associate-missing'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: widget.playing,
                    builder: (context, playing, _) => OutlinedButton.icon(
                      key: const Key('audio-associate-play'),
                      onPressed: widget.onPlay,
                      icon: Icon(
                        playing == widget.clip.id
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      label: Text(playing == widget.clip.id ? 'Stop' : 'Play'),
                    ),
                  ),
                  if (widget.onOpenFolder != null)
                    OutlinedButton.icon(
                      key: const Key('audio-associate-open-folder'),
                      onPressed: _openFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Open folder'),
                    ),
                ],
              ),
              if (_folderMessage case final message?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    message,
                    key: const Key('audio-associate-folder-error'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('audio-associate-text'),
                controller: _text,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _apply(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Word or expression',
                  helperText: 'Exactly what the recording says.',
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('audio-associate-texts'),
                  onPressed: _pickText,
                  icon: const Icon(Icons.format_list_bulleted),
                  label: const Text('Texts in this Course'),
                ),
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
          key: const Key('audio-associate-apply'),
          onPressed: _text.text.trim().isEmpty ? null : _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

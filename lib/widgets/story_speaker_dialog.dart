import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/course_cover_service.dart';
import '../services/course_media_store.dart';
import '../services/image_credit.dart';
import '../services/import/image_validator.dart';
import 'course_media_image.dart';
import 'cover_crop_dialog.dart';
import 'file_dialog_feedback.dart';
import 'image_credit_reminder.dart';
import 'portable_exercise_image.dart';
import 'quick_import_access.dart';

/// The bundled Story avatars (Build 256 Revision 5): one per mascot, the
/// whole figure, made by `tools/make_avatars.ps1` from `design/mascots`.
const bundledStoryAvatars = <String, String>{
  'cat': 'assets/avatars/cat.png',
  'dog': 'assets/avatars/dog.png',
  'kid': 'assets/avatars/kid.png',
  'monkey': 'assets/avatars/monkey.png',
  'robot': 'assets/avatars/robot.png',
};

/// What the speaker dialog returns: the edited speaker and, when its avatar
/// was just taken from the image library, the credit QQL knows for it.
typedef StorySpeakerChoice = ({
  StorySpeaker speaker,
  CourseMediaAttribution? credit,
});

/// A speaker's avatar as a small circle: a bundled avatar, a Course medium,
/// or the speaker's initial when they have none.
class StoryAvatar extends StatelessWidget {
  const StoryAvatar({
    super.key,
    required this.speaker,
    this.courseId,
    this.size = 44,
    this.mediaStore,
  });

  final StorySpeaker speaker;
  final String? courseId;
  final double size;
  final CourseMediaStore? mediaStore;

  @override
  Widget build(BuildContext context) {
    final asset = speaker.avatar;
    if (asset.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: CircleAvatar(
          child: Text(
            speaker.name.isEmpty
                ? '?'
                : speaker.name.characters.first.toUpperCase(),
          ),
        ),
      );
    }
    final courseId = this.courseId;
    final image = CourseMediaStore.isReference(asset) && courseId != null
        ? CourseMediaImage(
            courseId: courseId,
            asset: asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: 256,
            cacheHeight: 256,
            mediaStore: mediaStore,
          )
        : PortableExerciseImage(
            asset: asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: image),
    );
  }
}

/// Edits the narrator or a character of a Course's Stories: name, avatar
/// (a bundled avatar, a picture of the author's own cropped to a square, or
/// none), language and voice preference. Returns null when cancelled.
Future<StorySpeakerChoice?> showStorySpeakerDialog(
  BuildContext context, {
  required Course course,
  required StorySpeaker speaker,
  required bool narrator,
  bool readOnly = false,
  CourseCoverService? coverService,
  CourseMediaStore? mediaStore,
}) => showDialog<StorySpeakerChoice>(
  context: context,
  builder: (_) => _StorySpeakerDialog(
    course: course,
    speaker: speaker,
    narrator: narrator,
    readOnly: readOnly,
    coverService: coverService,
    mediaStore: mediaStore,
  ),
);

class _StorySpeakerDialog extends StatefulWidget {
  const _StorySpeakerDialog({
    required this.course,
    required this.speaker,
    required this.narrator,
    required this.readOnly,
    this.coverService,
    this.mediaStore,
  });

  final Course course;
  final StorySpeaker speaker;
  final bool narrator;
  final bool readOnly;
  final CourseCoverService? coverService;
  final CourseMediaStore? mediaStore;

  @override
  State<_StorySpeakerDialog> createState() => _StorySpeakerDialogState();
}

class _StorySpeakerDialogState extends State<_StorySpeakerDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.speaker.name,
  );
  late String _avatar = widget.speaker.avatar;
  late TextLanguage _language = widget.speaker.language;
  late StoryVoice _voice = widget.speaker.voice;
  late final _media = widget.mediaStore ?? CourseMediaStore();
  late final _covers =
      widget.coverService ?? CourseCoverService(mediaStore: _media);

  /// The credit QQL knows for the picture taken from the image library, and
  /// what the last chosen picture needs said about its credit.
  CourseMediaAttribution? _credit;
  String? _creditNote;
  bool _busy = false;
  String? _error;

  bool get _canSave =>
      !widget.readOnly &&
      !_busy &&
      (widget.narrator || _name.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(String asset) => setState(() {
    _avatar = asset;
    _credit = null;
    _creditNote = null;
    _error = null;
  });

  /// Reads a picture (null when the user cancelled), lets the author choose
  /// its square and stores it as this Course's own medium, like a cover.
  Future<void> _use(
    Future<Uint8List?> Function() read, {
    CourseMediaAttribution? credit,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await read();
      if (bytes == null || !mounted) return;
      final facts = ImageValidator.inspect(
        bytes,
        ImageProfile.courseCoverSource,
      );
      setState(() => _busy = false);
      final crop = await showCoverCropDialog(
        context,
        bytes: bytes,
        width: facts.width,
        height: facts.height,
      );
      if (crop == null || !mounted) return;
      setState(() => _busy = true);
      final reference = await _covers.storeAvatar(
        widget.course.courseId,
        bytes,
        crop: crop,
      );
      if (!mounted) return;
      setState(() {
        _avatar = reference;
        _credit = credit;
        _creditNote = credit == null
            ? imageCreditReminder
            : 'Credited in Course Info › Media credits: ${credit.author}, '
                  '${credit.license}.';
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseImage() async {
    final selected = await Navigator.of(context).push<ExerciseImageMetadata>(
      MaterialPageRoute(
        builder: (_) => FlatImageLibraryScreen(
          readOnly: true,
          course: widget.course,
          mediaStore: _media,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _use(
      () =>
          _covers.readLibraryImage(widget.course.courseId, selected.assetPath),
      credit: knownImageCredit(selected, appliesTo: 'Story avatar'),
    );
  }

  Future<void> _quickImport() async {
    switch (await ensureQuickImportAccess(
      context,
      offerOpenFrom: _covers.fileDialogsAvailable,
    )) {
      case QuickImportAccess.ready:
        break;
      case QuickImportAccess.openFrom:
        return _openFrom();
      case QuickImportAccess.stop:
        return;
    }
    if (!mounted) return;
    await _use(() async => (await _covers.readQuickImport()).bytes);
  }

  Future<void> _openFrom() => _use(() async {
    final result = await _covers.readFromDialog();
    final source = result.source;
    if (source == null && mounted) {
      showFileDialogFeedback(
        context,
        result.dialog,
        saving: false,
        fallbackHint: courseCoverFallbackHint,
      );
    }
    return source?.bytes;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.speaker.copyWith(
      name: _name.text.trim(),
      avatar: _avatar,
    );
    return AlertDialog(
      title: Text(
        widget.narrator
            ? 'Narrator'
            : widget.speaker.name.isEmpty
            ? 'New character'
            : 'Character',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('story-speaker-name'),
                controller: _name,
                readOnly: widget.readOnly,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Name',
                  helperText: widget.narrator
                      ? 'Optional: the narrator speaks unnamed unless you name it.'
                      : 'Shown beside the character\'s lines. Required.',
                ),
              ),
              const SizedBox(height: 14),
              Text('Avatar', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoryAvatar(
                    key: const Key('story-speaker-avatar-preview'),
                    speaker: preview,
                    courseId: widget.course.courseId,
                    size: 64,
                    mediaStore: _media,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final entry in bundledStoryAvatars.entries)
                          _AvatarChoice(
                            key: ValueKey('story-avatar-${entry.key}'),
                            asset: entry.value,
                            selected: _avatar == entry.value,
                            onTap: widget.readOnly
                                ? null
                                : () => _pick(entry.value),
                          ),
                        ChoiceChip(
                          key: const Key('story-avatar-none'),
                          label: const Text('None'),
                          selected: _avatar.isEmpty,
                          onSelected: widget.readOnly ? null : (_) => _pick(''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Or a picture of your own: you choose the square it shows, '
                'it becomes a small PNG stored with this Course.',
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('story-avatar-choose'),
                    onPressed: widget.readOnly || _busy ? null : _chooseImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose image'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('story-avatar-quick-import'),
                    onPressed: widget.readOnly || _busy ? null : _quickImport,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Quick Import'),
                  ),
                  if (_covers.fileDialogsAvailable)
                    OutlinedButton.icon(
                      key: const Key('story-avatar-open-from'),
                      onPressed: widget.readOnly || _busy ? null : _openFrom,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Open from…'),
                    ),
                ],
              ),
              if (_creditNote case final note?) ...[
                const SizedBox(height: 6),
                Text(note, key: const Key('story-avatar-credit-note')),
              ],
              if (_busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  key: const Key('story-avatar-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<TextLanguage>(
                key: const Key('story-speaker-language'),
                initialValue: _language,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Language',
                  helperText:
                      'The language the speaker\'s lines are in unless a line says otherwise.',
                  helperMaxLines: 2,
                ),
                items: const [
                  DropdownMenuItem(
                    value: TextLanguage.source,
                    child: Text('Source language'),
                  ),
                  DropdownMenuItem(
                    value: TextLanguage.target,
                    child: Text('Target language'),
                  ),
                ],
                onChanged: widget.readOnly
                    ? null
                    : (value) => setState(() => _language = value ?? _language),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<StoryVoice>(
                key: const Key('story-speaker-voice'),
                initialValue: _voice,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Voice',
                  helperText:
                      'Matched against the voices installed on the learner\'s device; a miss never blocks speech.',
                  helperMaxLines: 3,
                ),
                items: const [
                  DropdownMenuItem(value: StoryVoice.any, child: Text('Any')),
                  DropdownMenuItem(value: StoryVoice.male, child: Text('Male')),
                  DropdownMenuItem(
                    value: StoryVoice.female,
                    child: Text('Female'),
                  ),
                ],
                onChanged: widget.readOnly
                    ? null
                    : (value) => setState(() => _voice = value ?? _voice),
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
          key: const Key('story-speaker-save'),
          onPressed: _canSave
              ? () => Navigator.pop(context, (
                  speaker: widget.speaker.copyWith(
                    name: _name.text.trim(),
                    avatar: _avatar,
                    language: _language,
                    voice: _voice,
                  ),
                  credit: _credit,
                ))
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipOval(
          child: Image.asset(asset, width: 48, height: 48, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

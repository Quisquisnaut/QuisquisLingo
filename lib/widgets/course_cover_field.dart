import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/course_cover_service.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import 'course_media_image.dart';
import 'file_dialog_feedback.dart';
import 'flag_art.dart';
import 'quick_import_access.dart';

/// The Course Info Editor's cover (Build 255 Revision 6): a preview with
/// Choose image, Quick Import, Open from… and Remove cover.
///
/// A chosen picture becomes the Course's own media at once, like an image
/// added to an Exercise; the Course keeps it only when the Course changes are
/// confirmed, and an unconfirmed session removes it again.
class CourseCoverField extends StatefulWidget {
  const CourseCoverField({
    super.key,
    required this.course,
    required this.cover,
    required this.onChanged,
    this.coverService,
    this.mediaStore,
  });

  /// The Course being edited; its cover is stored in its own media.
  final Course course;

  /// The chosen cover reference, or '' for none.
  final String cover;
  final ValueChanged<String> onChanged;
  final CourseCoverService? coverService;
  final CourseMediaStore? mediaStore;

  @override
  State<CourseCoverField> createState() => _CourseCoverFieldState();
}

class _CourseCoverFieldState extends State<CourseCoverField> {
  late final _media = widget.mediaStore ?? CourseMediaStore();
  late final _covers =
      widget.coverService ?? CourseCoverService(mediaStore: _media);
  bool _busy = false;
  String? _error;

  /// Reads a picture (null when the user cancelled) and makes it the cover.
  Future<void> _use(Future<Uint8List?> Function() read) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await read();
      if (bytes == null || !mounted) return;
      final reference = await _covers.store(widget.course.courseId, bytes);
      if (mounted) widget.onChanged(reference);
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
    final hasCover = Course.coverImagePattern.hasMatch(widget.cover);
    final flag = Center(
      child: CourseFlagBadge(
        course: widget.course,
        fallbackCode: CourseService.codeForCourse(widget.course),
        width: 64,
        height: 44,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cover image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Shown instead of the flag in Courses, Course Info and the Course '
          'Editor. Any picture is cropped to its centred square and scaled to '
          '512 × 512 pixels; a cover may be up to 1 MB.',
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              key: const Key('course-cover-preview'),
              dimension: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasCover
                    ? CourseMediaImage(
                        key: const Key('course-cover-preview-image'),
                        courseId: widget.course.courseId,
                        asset: widget.cover,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        semanticLabel: '${widget.course.title} cover',
                        missing: flag,
                        mediaStore: _media,
                      )
                    : flag,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('course-cover-choose'),
                    onPressed: _busy ? null : _chooseImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose image'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('course-cover-quick-import'),
                    onPressed: _busy ? null : _quickImport,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Quick Import'),
                  ),
                  if (_covers.fileDialogsAvailable)
                    OutlinedButton.icon(
                      key: const Key('course-cover-open-from'),
                      onPressed: _busy ? null : _openFrom,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Open from…'),
                    ),
                  if (hasCover)
                    TextButton.icon(
                      key: const Key('course-cover-remove'),
                      onPressed: _busy ? null : () => widget.onChanged(''),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove cover'),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (!hasCover) ...[
          const SizedBox(height: 6),
          const Text('No cover: the flag is shown.'),
        ],
        if (_busy) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 8),
          Text(
            error,
            key: const Key('course-cover-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

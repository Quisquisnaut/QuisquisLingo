import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/course_cover_service.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import '../services/image_credit.dart';
import '../services/import/image_validator.dart';
import 'course_media_image.dart';
import 'cover_crop_dialog.dart';
import 'file_dialog_feedback.dart';
import 'flag_art.dart';
import 'image_credit_reminder.dart';
import 'quick_import_access.dart';

/// A cover choice: the cover reference ('' for none) and the credit QQL knows
/// for its picture, if any.
typedef CourseCoverChoice = ({String cover, CourseMediaAttribution? credit});

/// A Course's cover (Build 255 Revision 6): a preview with Choose image,
/// Quick Import, Open from… and Remove cover. The Course Info Editor has it,
/// and from Revision 7 Create new course too.
///
/// A chosen picture is cropped to the square its author picks and becomes the
/// Course's own media at once, like an image added to an Exercise; the Course
/// keeps it only when the Course changes are confirmed, and an unconfirmed
/// session removes it again.
class CourseCoverField extends StatefulWidget {
  const CourseCoverField({
    super.key,
    required this.courseId,
    required this.cover,
    required this.onChanged,
    this.course,
    this.coverService,
    this.mediaStore,
  });

  /// The Course whose own media folder stores the cover.
  final String courseId;

  /// The stored Course, when there is one: without a cover its flag is shown,
  /// and Choose image also offers its own images. Null while a Course is
  /// being created.
  final Course? course;

  /// The chosen cover reference, or '' for none.
  final String cover;
  final ValueChanged<CourseCoverChoice> onChanged;
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

  /// What the picture chosen last needs said about its credit: the credit QQL
  /// knew, or the reminder for a picture of unknown origin.
  String? _creditNote;

  /// Reads a picture (null when the user cancelled), lets the author choose
  /// its square and makes it the cover. [credit] is what QQL knows of its
  /// maker.
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
      // The header is enough to place the square; the full check runs when
      // the cover is made.
      final facts = ImageValidator.inspect(
        bytes,
        ImageProfile.courseCoverSource,
      );
      // Nothing is working while the author chooses the square.
      setState(() => _busy = false);
      final crop = await showCoverCropDialog(
        context,
        bytes: bytes,
        width: facts.width,
        height: facts.height,
      );
      if (crop == null || !mounted) return;
      setState(() => _busy = true);
      final reference = await _covers.store(
        widget.courseId,
        bytes,
        crop: crop,
      );
      if (!mounted) return;
      setState(
        () => _creditNote = credit == null
            ? imageCreditReminder
            : 'Credited in Course Info › Media credits: ${credit.author}, '
                  '${credit.license}.',
      );
      widget.onChanged((cover: reference, credit: credit));
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
      () => _covers.readLibraryImage(widget.courseId, selected.assetPath),
      credit: knownImageCredit(selected, appliesTo: 'Course cover'),
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
    final course = widget.course;
    final flag = Center(
      child: course == null
          ? const Icon(Icons.flag_outlined, size: 40)
          : CourseFlagBadge(
              course: course,
              fallbackCode: CourseService.codeForCourse(course),
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
          'Shown instead of the flag in Courses, the Course Selector, Course '
          'Info and the Course Editor; the Course flag still appears in the '
          'top bar, the Flag Background and the Course entry animation. You '
          'choose the square it shows; it becomes 512 × 512 pixels, up to '
          '1 MB. If someone else made the picture, credit them in Course Info '
          '› Media credits with author and licence; QQL does it for you when '
          'its image library knows them.',
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
                        courseId: widget.courseId,
                        asset: widget.cover,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        semanticLabel: course == null
                            ? 'Course cover'
                            : '${course.title} cover',
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
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() => _creditNote = null);
                              widget.onChanged((cover: '', credit: null));
                            },
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
          // Build 267 Revision 9 (owner): the flag also shows on the
          // learner page when there is a cover, so "only".
          const Text('No cover: only the flag is shown.'),
        ] else if (_creditNote case final note?) ...[
          const SizedBox(height: 6),
          Text(note, key: const Key('course-cover-credit-note')),
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

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/course_cover_service.dart';
import '../services/course_image_usage.dart';
import '../services/course_media_store.dart';
import '../services/exercise_image_service.dart';
import '../services/image_credit.dart';
import '../services/import/image_validator.dart';
import 'bundled_picture.dart';
import 'cover_crop_dialog.dart';
import 'course_media_image.dart';
import 'file_dialog_feedback.dart';
import 'image_badges.dart';
import 'image_credit_reminder.dart';
import 'plural_picture.dart';
import '../services/storage/qql_storage.dart';
import 'quick_import_access.dart';

/// A new image for an Exercise: the asset, and the Shared Image Library
/// record it came from when there is one. An empty asset removes the image.
typedef ExerciseImageChange = ({String asset, SharedImageSource? source});

/// The Exercise editor's image section: preview with badges, Choose flat
/// image, Import custom image, Open image from… and Remove image.
///
/// It does not hold the image itself: the editor passes [asset] and
/// [sharedSource] in and receives each change through [onChanged].
class ExerciseImageField extends StatefulWidget {
  const ExerciseImageField({
    super.key,
    required this.course,
    required this.asset,
    required this.sharedSource,
    required this.readOnly,
    required this.onChanged,
    this.help,
    this.imageService,
    this.mediaStore,
    this.title = 'Exercise image',
    this.compact = false,
    this.cropSquare = false,
    this.cropButtonKey,
    this.plural = false,
    this.onPluralChanged,
    this.pluralKey,
  });

  /// The Course the Exercise belongs to; images become its own media.
  final Course? course;

  /// The heading of the card: the shared prompt image by default, the
  /// answer's number and text for a picture on an answer (Build 256
  /// Revision 7 follow-up).
  final String title;

  /// Without the guidance paragraph (a picture on an answer: the section
  /// explains the pickers once).
  final bool compact;

  /// Offers Crop square for the picture (a picture answer, Build 263
  /// Revision 2): the square the author chooses becomes a cropped copy in
  /// the Course.
  final bool cropSquare;
  final Key? cropButtonKey;

  /// Build 265 Revision 11: whether the picture is shown as several, and
  /// the switch that changes it (no switch without [onPluralChanged]).
  final bool plural;
  final ValueChanged<bool>? onPluralChanged;
  final Key? pluralKey;
  final String asset;
  final SharedImageSource? sharedSource;
  final bool readOnly;
  final ValueChanged<ExerciseImageChange> onChanged;

  /// The editor's Help button for this section.
  final Widget? help;
  final ExerciseImageService? imageService;
  final CourseMediaStore? mediaStore;

  @override
  State<ExerciseImageField> createState() => _ExerciseImageFieldState();
}

class _ExerciseImageFieldState extends State<ExerciseImageField> {
  late final _imageService = widget.imageService ?? ExerciseImageService();
  late final _media = widget.mediaStore ?? CourseMediaStore();

  /// A picked or imported image becomes the Course's own media: its bytes are
  /// copied into the Course folder and the Exercise names them by content, so
  /// the Course never depends on the library file or the source path.
  Future<String> _asCourseMedia(String selected) async {
    if (selected.startsWith('assets/') ||
        selected.startsWith('data:') ||
        CourseMediaStore.isReference(selected)) {
      return selected;
    }
    final course = widget.course;
    if (course == null) {
      throw StateError('Open this Exercise from its Course to add an image.');
    }
    return _media.addFile(course.courseId, File(selected));
  }

  SharedImageSource? _courseImageSource(String reference) {
    final course = widget.course;
    return course == null
        ? null
        : CourseImageUsage.sharedSourceOf(course, reference);
  }

  void _change(String asset, SharedImageSource? source) =>
      widget.onChanged((asset: asset, source: source));

  Future<void> _chooseFlatImage() async {
    if (widget.readOnly) return;
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
    try {
      final reference = await _asCourseMedia(selected.assetPath);
      if (!mounted) return;
      _change(
        reference,
        selected.origin.startsWith('course')
            ? _courseImageSource(reference)
            : selected.origin == 'bundled'
            ? null
            : SharedImageSource(
                id: selected.id,
                label: selected.label,
                category: selected.category,
                tags: selected.tags,
                origin: selected.origin,
                attribution: selected.attribution,
              ),
      );
      // Build 255 Revision 7: a picture whose maker QQL does not know.
      if (knownImageCredit(selected, appliesTo: 'Exercise image') == null) {
        showImageCreditReminder(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  /// Crop square (Build 263 Revision 2, owner decisions of 4 October 2026):
  /// the author moves and sizes a square over the picture (crop and zoom);
  /// the square is stored as a new picture of the Course, which replaces
  /// this one. The original stays where it was.
  Future<void> _cropSquare() async {
    final course = widget.course;
    if (widget.readOnly || course == null || widget.asset.isEmpty) return;
    final covers = CourseCoverService(
      mediaStore: _media,
      images: _imageService,
    );
    try {
      final bytes = await covers.readLibraryImage(
        course.courseId,
        widget.asset,
      );
      final picture = await ImageValidator.validate(
        bytes,
        ImageProfile.courseCoverSource,
      );
      if (!mounted) return;
      final crop = await showCoverCropDialog(
        context,
        bytes: picture.bytes,
        width: picture.width,
        height: picture.height,
        title: 'Crop square',
        guidance:
            'Drag the square to choose what the answer shows. Make it '
            'smaller to zoom in.',
      );
      if (crop == null || !mounted) return;
      final reference = await covers.storeSquare(
        course.courseId,
        picture.bytes,
        crop: crop,
      );
      if (!mounted) return;
      _change(reference, widget.sharedSource);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  Future<void> _importCustomImage({bool fromDialog = false}) async {
    if (widget.readOnly) return;
    if (!fromDialog) {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _imageService.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _importCustomImage(fromDialog: true);
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    try {
      final PickedImage picked;
      if (fromDialog) {
        // Open from…: the same staging and image check as the folder import.
        final result = await _imageService.readImageFromDialog();
        if (!mounted) return;
        final image = result.picked;
        if (image == null) {
          showFileDialogFeedback(
            context,
            result.dialog,
            saving: false,
            fallbackHint: exerciseImageFallbackHint,
          );
          return;
        }
        picked = image;
      } else {
        picked = await _imageService.readImage();
      }
      final course = widget.course;
      if (course == null) {
        throw StateError('Open this Exercise from its Course to add an image.');
      }
      // Straight into the Course's own media: nothing is written to the
      // shared image folder.
      final reference = await _media.addValidated(
        course.courseId,
        picked.image,
      );
      if (!mounted) return;
      _change(reference, null);
      showImageCreditReminder(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (widget.asset.isEmpty) {
      preview = const SizedBox(
        height: 120,
        child: Center(child: Text('No image selected')),
      );
    } else {
      preview = PluralPicture.wrap(
        plural: widget.plural,
        child: CourseMediaImage(
          courseId: widget.course?.courseId ?? '',
          asset: widget.asset,
          height: 150,
          // Bound the decode: nothing limits a course-media image's pixels.
          cacheHeight: 300,
          missing: const SizedBox(
            height: 120,
            child: Center(child: Text('Image asset file is missing.')),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                ?widget.help,
              ],
            ),
            const SizedBox(height: 8),
            if (widget.asset.isEmpty)
              preview
            else
              // Loose constraints let the Stack hug the image, so the badges
              // sit on the image itself and the image stays centered.
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    preview,
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: ImageBadges(fontSize: 10, [
                        (
                          label: 'IN USE',
                          message: 'This image is used by this Course.',
                        ),
                        if (widget.asset.startsWith('assets/'))
                          (
                            label: 'QQL',
                            message: 'App-bundled image, supplied by QQL.',
                          )
                        else if (widget.sharedSource != null)
                          (
                            label: 'DEVICE',
                            message:
                                'Originally from the Admin Shared Image Library.',
                          ),
                        if (CourseMediaStore.isImageReference(widget.asset))
                          (
                            label: 'COURSE',
                            message:
                                'The image bytes are stored in this Course folder.',
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.readOnly ? null : _chooseFlatImage,
                  icon: const Icon(Icons.grid_view_outlined),
                  label: const Text('Choose flat image'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.readOnly ? null : _importCustomImage,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import custom image'),
                ),
                if (_imageService.fileDialogsAvailable)
                  IconButton.outlined(
                    key: const Key('open-custom-image-from'),
                    tooltip: 'Open image from…',
                    onPressed: widget.readOnly
                        ? null
                        : () => _importCustomImage(fromDialog: true),
                    icon: const Icon(Icons.folder_open_outlined),
                  ),
                // A drawing (a World Flag) is never cropped.
                if (widget.cropSquare &&
                    widget.asset.isNotEmpty &&
                    !widget.asset.startsWith('data:') &&
                    !isSvgPicture(widget.asset))
                  OutlinedButton.icon(
                    key: widget.cropButtonKey,
                    onPressed: widget.readOnly ? null : _cropSquare,
                    icon: const Icon(Icons.crop),
                    label: const Text('Crop square'),
                  ),
                if (widget.onPluralChanged != null && widget.asset.isNotEmpty)
                  FilterChip(
                    key: widget.pluralKey,
                    avatar: const Icon(Icons.filter_none, size: 18),
                    label: const Text('Plural'),
                    tooltip:
                        'Several of this thing: the learner sees stacked copies, for a plural word ("cats").',
                    selected: widget.plural,
                    onSelected: widget.readOnly
                        ? null
                        : (value) => widget.onPluralChanged!(value),
                  ),
                if (widget.asset.isNotEmpty)
                  TextButton.icon(
                    onPressed: widget.readOnly ? null : () => _change('', null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove image'),
                  ),
              ],
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 4),
              Text(
                'The shared image library (admin-managed) has lightweight flat images. For Import custom image, place exactly one PNG, JPG, JPEG or WEBP file in ${QqlStorageLayout.current.folderLabel(QqlStorageRole.imageImports)}. Image-prompt ordering requires an image; otherwise it is optional and can be changed at any time.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

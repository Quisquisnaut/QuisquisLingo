import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../screens/flat_image_library_screen.dart';
import '../services/course_image_usage.dart';
import '../services/course_media_store.dart';
import '../services/exercise_image_service.dart';
import 'course_media_image.dart';
import 'file_dialog_feedback.dart';
import 'image_badges.dart';

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
  });

  /// The Course the Exercise belongs to; images become its own media.
  final Course? course;
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
      final reference = await _media.addValidated(course.courseId, picked.image);
      if (mounted) _change(reference, null);
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
      preview = CourseMediaImage(
        courseId: widget.course?.courseId ?? '',
        asset: widget.asset,
        height: 150,
        // Bound the decode: nothing limits a course-media image's pixels.
        cacheHeight: 300,
        missing: const SizedBox(
          height: 120,
          child: Center(child: Text('Image asset file is missing.')),
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
                const Expanded(
                  child: Text(
                    'Exercise image',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
                if (widget.asset.isNotEmpty)
                  TextButton.icon(
                    onPressed: widget.readOnly ? null : () => _change('', null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove image'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'The shared image library (admin-managed) has lightweight flat images. For Import custom image, place exactly one PNG, JPG, JPEG or WEBP file in Documents/QuisquisLingo/Imports/Images. Image-prompt ordering requires an image; otherwise it is optional and can be changed at any time.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

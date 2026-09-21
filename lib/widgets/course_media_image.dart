import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/course_media_store.dart';
import 'portable_exercise_image.dart';

/// Shows any image a Course refers to: a bundled `assets/` image, an embedded
/// `data:` image, or the Course's own `media:<sha256>.<ext>` file, which is
/// looked up in [courseId]'s media folder. Anything else, or a missing file,
/// shows [missing] (a broken-image icon by default).
class CourseMediaImage extends StatefulWidget {
  const CourseMediaImage({
    super.key,
    required this.courseId,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
    this.missing,
    this.mediaStore,
  });

  final String courseId;
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Decode bounds: nothing else limits the pixel dimensions of a file image.
  final int? cacheWidth;
  final int? cacheHeight;
  final String? semanticLabel;
  final Widget? missing;
  final CourseMediaStore? mediaStore;

  @override
  State<CourseMediaImage> createState() => _CourseMediaImageState();
}

class _CourseMediaImageState extends State<CourseMediaImage> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CourseMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset ||
        oldWidget.courseId != widget.courseId) {
      _resolve();
    }
  }

  void _resolve() {
    _bytes = CourseMediaStore.isReference(widget.asset) ? _read() : null;
  }

  /// Course images are at most 50 KB, so they are read into memory rather
  /// than shown with Image.file, which maps the file and keeps it open; on
  /// Windows an open file cannot be deleted by the course-media cleanup.
  Future<Uint8List?> _read() async {
    try {
      final file = await (widget.mediaStore ?? CourseMediaStore()).existingFile(
        widget.courseId,
        widget.asset,
      );
      return file == null ? null : await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Widget _missing() =>
      widget.missing ??
      SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Tooltip(
            message: 'Exercise image is unavailable.',
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    if (asset.startsWith('assets/')) {
      return Image.asset(
        asset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        semanticLabel: widget.semanticLabel,
        errorBuilder: (_, _, _) => _missing(),
      );
    }
    if (asset.startsWith('data:')) {
      return PortableExerciseImage(
        asset: asset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    final bytes = _bytes;
    if (bytes == null) return _missing();
    return FutureBuilder<Uint8List?>(
      future: bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        final resolved = snapshot.data;
        if (resolved == null) return _missing();
        return Image.memory(
          resolved,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          semanticLabel: widget.semanticLabel,
          errorBuilder: (_, _, _) => _missing(),
        );
      },
    );
  }
}

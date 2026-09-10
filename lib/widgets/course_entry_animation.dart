import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/world_flag_entity.dart';
import '../services/course_flag_service.dart';
import '../services/world_flag_repository.dart';
import 'flag_art.dart';
import 'world_flag_art.dart';

typedef WorldFlagLookup = Future<WorldFlagEntity?> Function(String id);
typedef CourseFlagImageValidator = Future<bool> Function(Uint8List bytes);

enum CourseEntryFlagKind { worldFlag, customImage, builtIn }

class CourseEntryFlagSource {
  final CourseEntryFlagKind kind;
  final String identifier;
  final WorldFlagEntity? worldFlag;
  final Uint8List? imageBytes;

  const CourseEntryFlagSource._({
    required this.kind,
    required this.identifier,
    this.worldFlag,
    this.imageBytes,
  });

  CourseEntryFlagSource.worldFlag(WorldFlagEntity entity)
    : this._(
        kind: CourseEntryFlagKind.worldFlag,
        identifier: entity.id,
        worldFlag: entity,
      );

  const CourseEntryFlagSource.customImage(Uint8List bytes)
    : this._(
        kind: CourseEntryFlagKind.customImage,
        identifier: 'custom-image',
        imageBytes: bytes,
      );

  const CourseEntryFlagSource.builtIn(String code)
    : this._(kind: CourseEntryFlagKind.builtIn, identifier: code);
}

/// Decides whether a real course switch has the same resolved, renderable flag
/// used by the other course surfaces. Explicit course data takes precedence;
/// otherwise the caller supplies the established automatic language fallback.
abstract final class CourseEntryAnimationPolicy {
  static const duration = Duration(seconds: 2);

  static const _builtInFlagCodes = <String>{
    'DE',
    'IT',
    'ES',
    'PT',
    'NL',
    'FI',
    'CY',
    'EN',
    'UK',
    'KO',
    'KR',
  };

  static Future<CourseEntryFlagSource?> requestForSwitch({
    required String? currentCourseId,
    required Course destination,
    required String fallbackCode,
    required bool animationsEnabled,
    required bool reducedMotion,
    WorldFlagLookup? worldFlagLookup,
    CourseFlagImageValidator? imageValidator,
  }) async {
    if (currentCourseId == null ||
        currentCourseId == destination.courseId ||
        !animationsEnabled ||
        reducedMotion) {
      return null;
    }

    final resolved = CourseFlagService.resolve(
      destination,
      fallbackCode: fallbackCode,
    );
    if (resolved.kind == ResolvedCourseFlagKind.worldFlag) {
      final entity = await (worldFlagLookup ?? WorldFlagRepository().findById)(
        resolved.identifier,
      );
      return entity == null ? null : CourseEntryFlagSource.worldFlag(entity);
    }

    if (resolved.kind == ResolvedCourseFlagKind.customImage) {
      try {
        final bytes = base64Decode(resolved.identifier);
        final valid = await (imageValidator ?? _isDecodableImage)(bytes);
        if (valid) return CourseEntryFlagSource.customImage(bytes);
      } on FormatException {
        // Invalid explicit data resolves neutrally on every consumer.
      }
      return null;
    }

    if (resolved.kind == ResolvedCourseFlagKind.builtIn) {
      return _builtInFlagCodes.contains(resolved.identifier)
          ? CourseEntryFlagSource.builtIn(resolved.identifier)
          : null;
    }
    return null;
  }

  static Future<bool> _isDecodableImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class CourseEntryAnimation extends StatefulWidget {
  final CourseEntryFlagSource flag;
  final VoidCallback onComplete;

  const CourseEntryAnimation({
    super.key,
    required this.flag,
    required this.onComplete,
  });

  @override
  State<CourseEntryAnimation> createState() => _CourseEntryAnimationState();
}

class _CourseEntryAnimationState extends State<CourseEntryAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CourseEntryAnimationPolicy.duration,
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(.55, 1, curve: Curves.easeOut),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: AbsorbPointer(
      child: ColoredBox(
        key: const Key('course-entry-animation'),
        color: Colors.black,
        child: _flagArt(),
      ),
    ),
  );

  Widget _flagArt() => switch (widget.flag.kind) {
    CourseEntryFlagKind.worldFlag => WorldFlagArt(
      key: ValueKey('course-entry-world-flag-${widget.flag.identifier}'),
      entity: widget.flag.worldFlag!,
      fit: BoxFit.contain,
      semanticsLabel: 'Course entry flag',
      showFrame: false,
    ),
    CourseEntryFlagKind.customImage => Image.memory(
      widget.flag.imageBytes!,
      key: const Key('course-entry-custom-flag'),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      semanticLabel: 'Course entry flag',
    ),
    CourseEntryFlagKind.builtIn => FlagBackdrop(
      key: ValueKey('course-entry-built-in-flag-${widget.flag.identifier}'),
      code: widget.flag.identifier,
      opacity: 1,
      fit: BoxFit.contain,
    ),
  };
}

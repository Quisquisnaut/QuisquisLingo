import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/flag_background_palette_service.dart';
import '../services/profile_service.dart';

final CourseFlagPaletteResolver _sharedCourseFlagPaletteResolver =
    CourseFlagPaletteResolver();

/// A static, adapted color surface for Tinted and Inspired modes.
///
/// The real flag artwork remains exclusive to Small and Extended. A safe
/// built-in/neutral palette is shown while an image-backed palette resolves.
class CourseFlagInspiredBackground extends StatefulWidget {
  final Course course;
  final String fallbackCode;
  final Brightness brightness;
  final LearnerFlagBackgroundMode mode;
  final CourseFlagPaletteResolver? resolver;

  const CourseFlagInspiredBackground({
    super.key,
    required this.course,
    required this.fallbackCode,
    required this.brightness,
    required this.mode,
    this.resolver,
  }) : assert(
         mode == LearnerFlagBackgroundMode.tinted ||
             mode == LearnerFlagBackgroundMode.softInspired,
       );

  @override
  State<CourseFlagInspiredBackground> createState() =>
      _CourseFlagInspiredBackgroundState();
}

class _CourseFlagInspiredBackgroundState
    extends State<CourseFlagInspiredBackground> {
  late FlagBackgroundPalette _palette;
  int _loadGeneration = 0;

  CourseFlagPaletteResolver get _resolver =>
      widget.resolver ?? _sharedCourseFlagPaletteResolver;

  @override
  void initState() {
    super.initState();
    _palette = _safeInitialPalette();
    _load();
  }

  @override
  void didUpdateWidget(covariant CourseFlagInspiredBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.courseId != widget.course.courseId ||
        oldWidget.course.flagCode != widget.course.flagCode ||
        oldWidget.course.flagImageBase64 != widget.course.flagImageBase64 ||
        oldWidget.course.worldFlagId != widget.course.worldFlagId ||
        oldWidget.fallbackCode != widget.fallbackCode ||
        oldWidget.brightness != widget.brightness ||
        !identical(oldWidget.resolver, widget.resolver)) {
      _palette = _safeInitialPalette();
      _load();
    }
  }

  FlagBackgroundPalette _safeInitialPalette() {
    final code = widget.course.flagCode.trim().isEmpty
        ? widget.fallbackCode
        : widget.course.flagCode;
    return const FlagBackgroundPaletteService().derive(
      FlagBackgroundPaletteService.builtInColors(code),
      brightness: widget.brightness,
    );
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    late final CourseFlagPaletteResult result;
    try {
      result = await _resolver.resolve(
        widget.course,
        fallbackCode: widget.fallbackCode,
        brightness: widget.brightness,
      );
    } catch (_) {
      // Retain the safe initial palette if an unexpected decoder or asset
      // failure escapes the resolver.
      return;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() => _palette = result.palette);
  }

  @override
  Widget build(BuildContext context) {
    final tinted = widget.mode == LearnerFlagBackgroundMode.tinted;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey(
            tinted
                ? 'unified-learner-flag-background-tinted'
                : 'unified-learner-flag-background-inspired',
          ),
          decoration: BoxDecoration(
            color: tinted ? _palette.tinted : null,
            gradient: tinted
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _palette.inspiredColors,
                    stops: const [0, .48, 1],
                  ),
          ),
        ),
      ),
    );
  }
}

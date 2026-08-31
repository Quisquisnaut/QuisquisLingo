import 'package:flutter/material.dart';

import '../controllers/learner_status_controller.dart';
import '../models/course_models.dart';
import '../models/learner_status_state.dart';
import 'flag_art.dart';

const double unifiedLearnerTopBarHeight = 64;

/// The fixed Home header row containing course access and learner metrics.
class UnifiedLearnerTopBar extends StatelessWidget {
  static const _logoAsset = 'assets/branding/quisquislingo_logo.png';

  final LearnerStatusController controller;
  final Course course;
  final String courseCode;
  final VoidCallback onCoursePressed;
  final VoidCallback onLogoPressed;
  final VoidCallback onSettingsPressed;

  const UnifiedLearnerTopBar({
    super.key,
    required this.controller,
    required this.course,
    required this.courseCode,
    required this.onCoursePressed,
    required this.onLogoPressed,
    required this.onSettingsPressed,
  });

  Future<void> _showExplanation(BuildContext context, String text) =>
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

  String _languageName(LearnerStatusState state) {
    final stateLanguage = state.course?.targetLanguage.trim() ?? '';
    if (stateLanguage.isNotEmpty) return stateLanguage;
    final targetLanguage = course.targetLanguage.trim();
    return targetLanguage.isEmpty ? course.learningLanguage : targetLanguage;
  }

  String _streakSemantics(LearnerStatusState state) {
    final days = state.streak ?? 0;
    return '${_languageName(state)} streak: $days '
        '${days == 1 ? 'day' : 'days'}';
  }

  String _streakExplanation() =>
      'Your streak is specific to the language you are learning and is shared '
      'across courses in that language. Studying another language does not '
      'count toward that streak, but studying any language freezes all your '
      'streaks, preventing them from resetting.';

  String _laurelSemantics(LearnerStatusState state) =>
      'Laurels in this course: ${state.laurels ?? 0} out of '
      '${state.laurelMaximum ?? 0}';

  String _laurelExplanation() =>
      'Laurels are specific to each course. A Laurel earned in this course '
      'belongs to this course only and does not carry over to other courses, '
      'even if the target language is the same.';

  String _xpSemantics(LearnerStatusState state) {
    final goal = state.weeklyXpGoal;
    return goal == null
        ? 'Weekly XP: ${state.weeklyXp}'
        : 'Weekly XP: ${state.weeklyXp} out of $goal';
  }

  String _xpExplanation(LearnerStatusState state) =>
      '${_xpSemantics(state)}. It totals this learner\'s XP across all courses '
      'for the current week.';

  Widget _numberLine({
    required Key key,
    required String text,
    required TextStyle style,
    required double width,
    required double height,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, key: key, maxLines: 1, softWrap: false, style: style),
      ),
    );
  }

  Widget _metric({
    required Key key,
    required String tooltip,
    required String semanticsLabel,
    required VoidCallback onTap,
    required IconData icon,
    required Key iconKey,
    required Color iconColor,
    required double iconSize,
    required double width,
    required double spacing,
    required Widget numbers,
  }) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: semanticsLabel,
        onTap: onTap,
        child: SizedBox(
          key: key,
          width: width,
          height: 48,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, key: iconKey, size: iconSize, color: iconColor),
                SizedBox(width: spacing),
                numbers,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gap(String name, double width) =>
      SizedBox(key: ValueKey('unified-topbar-gap-$name'), width: width);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final brightness = Theme.of(context).brightness;
        final isDark = brightness == Brightness.dark;
        final surfaceColor = isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white;
        final contentColor = isDark ? Colors.white : const Color(0xFF111111);

        return Material(
          key: const Key('unified-learner-top-bar'),
          color: surfaceColor,
          surfaceTintColor: Colors.transparent,
          child: SizedBox(
            height: unifiedLearnerTopBarHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dense = constraints.maxWidth < 400;
                final gap = dense ? 3.0 : 6.0;
                final iconSize = dense ? 15.0 : 19.0;
                final iconSpacing = dense ? 2.0 : 3.0;
                final numberStyle = TextStyle(
                  color: contentColor,
                  fontSize: dense ? 10 : 11,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );
                final maximumStyle = numberStyle.copyWith(
                  fontSize: dense ? 9 : 10,
                  fontWeight: FontWeight.w700,
                );
                final streakSemantics = _streakSemantics(state);
                final laurelSemantics = _laurelSemantics(state);
                final xpSemantics = _xpSemantics(state);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: dense ? 1 : 6),
                  child: Row(
                    key: const Key('unified-topbar-row'),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Tooltip(
                        message:
                            '${courseCode.trim().toUpperCase()} - ${course.title}',
                        child: Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: 'Choose course: ${course.title}',
                          onTap: onCoursePressed,
                          child: SizedBox(
                            key: const Key('unified-topbar-course-selector'),
                            width: dense ? 48 : 52,
                            height: 48,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onCoursePressed,
                              child: Center(
                                child: CourseFlagBadge(
                                  course: course,
                                  fallbackCode: courseCode,
                                  width: dense ? 40 : 44,
                                  height: dense ? 28 : 31,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _gap('course-streak', gap),
                      _metric(
                        key: const Key('unified-topbar-streak'),
                        tooltip: 'Language Streak',
                        semanticsLabel: streakSemantics,
                        onTap: () =>
                            _showExplanation(context, _streakExplanation()),
                        icon: Icons.local_fire_department,
                        iconKey: const Key('unified-topbar-flame-icon'),
                        iconColor: isDark
                            ? const Color(0xFFFF8A5B)
                            : const Color(0xFFC8430F),
                        iconSize: iconSize,
                        width: dense ? 49 : 56,
                        spacing: iconSpacing,
                        numbers: _numberLine(
                          key: const Key('unified-topbar-streak-number'),
                          text: '${state.streak ?? 0}',
                          style: numberStyle,
                          width: dense ? 32 : 34,
                          height: 18,
                        ),
                      ),
                      _gap('streak-laurel', gap),
                      _metric(
                        key: const Key('unified-topbar-laurels'),
                        tooltip: 'Course Laurels',
                        semanticsLabel: laurelSemantics,
                        onTap: () =>
                            _showExplanation(context, _laurelExplanation()),
                        icon: Icons.workspace_premium_outlined,
                        iconKey: const Key('unified-topbar-laurel-icon'),
                        iconColor: isDark
                            ? const Color(0xFF69DB9C)
                            : const Color(0xFF18733B),
                        iconSize: iconSize,
                        width: dense ? 51 : 64,
                        spacing: iconSpacing,
                        numbers: SizedBox(
                          width: dense ? 34 : 42,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _numberLine(
                                key: const Key('unified-topbar-laurel-current'),
                                text: '${state.laurels ?? 0}',
                                style: numberStyle,
                                width: dense ? 34 : 42,
                                height: 15,
                              ),
                              _numberLine(
                                key: const Key('unified-topbar-laurel-maximum'),
                                text: '/ ${state.laurelMaximum ?? 0}',
                                style: maximumStyle,
                                width: dense ? 34 : 42,
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _gap('laurel-xp', gap),
                      _metric(
                        key: const Key('unified-topbar-weekly-xp'),
                        tooltip: 'Weekly XP across all courses',
                        semanticsLabel: xpSemantics,
                        onTap: () =>
                            _showExplanation(context, _xpExplanation(state)),
                        icon: Icons.bolt,
                        iconKey: const Key('unified-topbar-xp-icon'),
                        iconColor: contentColor,
                        iconSize: iconSize,
                        width: dense ? 65 : 80,
                        spacing: iconSpacing,
                        numbers: SizedBox(
                          width: dense ? 48 : 58,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _numberLine(
                                key: const Key('unified-topbar-xp-current'),
                                text: '${state.weeklyXp}',
                                style: numberStyle,
                                width: dense ? 48 : 58,
                                height: 15,
                              ),
                              _numberLine(
                                key: const Key('unified-topbar-xp-maximum'),
                                text: state.weeklyXpGoal == null
                                    ? '/ —'
                                    : '/ ${state.weeklyXpGoal}',
                                style: maximumStyle,
                                width: dense ? 48 : 58,
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _gap('xp-logo', gap),
                      Tooltip(
                        message: 'QuisquisLingo App Info',
                        child: Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: 'QuisquisLingo logo, open App Info',
                          onTap: onLogoPressed,
                          child: SizedBox(
                            key: const Key('unified-topbar-logo'),
                            width: 48,
                            height: 48,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onLogoPressed,
                              child: Center(
                                child: SizedBox(
                                  key: const Key('unified-topbar-logo-mark'),
                                  width: dense ? 29 : 37,
                                  height: 48,
                                  child: ClipRect(
                                    key: const Key('unified-topbar-logo-clip'),
                                    child: OverflowBox(
                                      alignment: Alignment.centerLeft,
                                      minWidth: dense ? 120 : 156,
                                      maxWidth: dense ? 120 : 156,
                                      minHeight: dense ? 40 : 52,
                                      maxHeight: dense ? 40 : 52,
                                      child: Image.asset(
                                        _logoAsset,
                                        key: const Key(
                                          'unified-topbar-logo-image',
                                        ),
                                        width: dense ? 120 : 156,
                                        height: dense ? 40 : 52,
                                        fit: BoxFit.fill,
                                        filterQuality: FilterQuality.high,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _gap('logo-settings', gap),
                      Semantics(
                        button: true,
                        excludeSemantics: true,
                        label: 'Settings',
                        onTap: onSettingsPressed,
                        child: IconButton(
                          key: const Key('unified-topbar-settings'),
                          tooltip: 'Settings',
                          visualDensity: dense
                              ? const VisualDensity(horizontal: -4)
                              : VisualDensity.compact,
                          constraints: BoxConstraints(
                            minWidth: dense ? 40 : 44,
                            minHeight: 48,
                          ),
                          color: contentColor,
                          iconSize: dense ? 18 : 22,
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: onSettingsPressed,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../controllers/learner_status_controller.dart';
import '../models/learner_status_state.dart';
import '../services/course_service.dart';
import 'flag_art.dart';
import 'learner_navigation.dart';

enum LearnerStatusForeground { light, dark }

class LearnerStatusBar extends StatelessWidget {
  final LearnerStatusController controller;
  final LearnerStatusForeground foreground;

  const LearnerStatusBar({
    super.key,
    required this.controller,
    required this.foreground,
  });

  Color get _foregroundColor => foreground == LearnerStatusForeground.light
      ? Colors.white
      : const Color(0xFF173F35);

  Future<void> _showExplanation(BuildContext context, String text) {
    return showDialog<void>(
      context: learnerNavigatorKey.currentContext ?? context,
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
  }

  String _xpExplanation(LearnerStatusState state) {
    final goal = state.weeklyXpGoal;
    return goal == null
        ? 'Weekly XP: ${state.weeklyXp}'
        : 'Weekly XP: ${state.weeklyXp} out of $goal';
  }

  String _streakExplanation(LearnerStatusState state) {
    final language = state.course!.targetLanguage;
    final days = state.streak!;
    return '$language streak: $days ${days == 1 ? 'day' : 'days'}';
  }

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _stableWidth(
    BuildContext context,
    String actual,
    String reserved,
    TextStyle style,
  ) {
    final actualWidth = _textWidth(context, actual, style);
    final reservedWidth = _textWidth(context, reserved, style);
    return actualWidth > reservedWidth ? actualWidth : reservedWidth;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final course = state.course;
        final title = course?.title ?? '';
        final xpText = state.weeklyXpGoal == null
            ? '${state.weeklyXp}'
            : '${state.weeklyXp} / ${state.weeklyXpGoal}';
        final streakText = state.streak?.toString() ?? '';
        final laurelText = state.laurels?.toString() ?? '';

        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: learnerStatusSlotHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 480;
                final numberStyle =
                    (compact
                            ? Theme.of(context).textTheme.labelSmall
                            : Theme.of(context).textTheme.labelLarge)
                        ?.copyWith(
                          color: _foregroundColor,
                          fontSize: compact ? 10 : null,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        );
                final effectiveNumberStyle =
                    numberStyle ??
                    TextStyle(
                      color: _foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    );
                final titleStyle =
                    (compact
                            ? Theme.of(context).textTheme.labelSmall
                            : Theme.of(context).textTheme.labelLarge)
                        ?.copyWith(
                          color: _foregroundColor,
                          fontSize: compact ? 10 : null,
                          fontWeight: FontWeight.w800,
                        );
                final gap = compact ? 1.0 : 8.0;
                final iconSize = compact ? 14.0 : 19.0;
                final code = state.courseCode?.trim().toUpperCase() ?? '';
                final showLanguageCode =
                    course != null &&
                    code.isNotEmpty &&
                    constraints.maxWidth >= 600;
                final xpWidth = _stableWidth(
                  context,
                  xpText,
                  '99999 / 99999',
                  effectiveNumberStyle,
                );
                final streakWidth = _stableWidth(
                  context,
                  streakText,
                  compact ? streakText : '9999',
                  effectiveNumberStyle,
                );
                final laurelWidth = _stableWidth(
                  context,
                  laurelText,
                  compact ? laurelText : '9999',
                  effectiveNumberStyle,
                );

                return Padding(
                  padding: EdgeInsets.only(
                    left: compact ? 1 : 10,
                    right: compact ? 0 : 10,
                  ),
                  child: Row(
                    children: [
                      if (course != null && state.streak != null) ...[
                        Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: _streakExplanation(state),
                          child: InkWell(
                            key: const Key('learner-status-streak'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showExplanation(
                              context,
                              _streakExplanation(state),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  key: const Key('learner-status-flame-icon'),
                                  size: iconSize,
                                  color: const Color(0xFFF05A28),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  key: const Key(
                                    'learner-status-streak-number',
                                  ),
                                  width: streakWidth,
                                  child: Text(
                                    streakText,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    style: effectiveNumberStyle,
                                  ),
                                ),
                                SizedBox(width: compact ? 2 : 4),
                                ExcludeSemantics(
                                  child: CourseFlagBadge(
                                    course: course,
                                    fallbackCode:
                                        state.courseCode ??
                                        CourseService.codeForCourse(course),
                                    width: compact ? 19 : 28,
                                    height: compact ? 14 : 20,
                                  ),
                                ),
                                if (showLanguageCode) ...[
                                  const SizedBox(width: 3),
                                  Text(code, style: effectiveNumberStyle),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: Semantics(
                            button: true,
                            excludeSemantics: true,
                            label: 'Current course: $title',
                            child: InkWell(
                              key: const Key('learner-status-course'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showExplanation(context, title),
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                        Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: 'Laurels in this course: $laurelText',
                          child: InkWell(
                            key: const Key('learner-status-laurels'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showExplanation(
                              context,
                              'Laurels in this course: $laurelText',
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium_outlined,
                                  key: const Key('learner-status-laurel-icon'),
                                  size: iconSize,
                                  color: const Color(0xFF2E8B57),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  key: const Key(
                                    'learner-status-laurel-number',
                                  ),
                                  width: laurelWidth,
                                  child: Text(
                                    laurelText,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    style: effectiveNumberStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                      ] else
                        const Spacer(),
                      Semantics(
                        button: true,
                        excludeSemantics: true,
                        label: _xpExplanation(state),
                        child: InkWell(
                          key: const Key('learner-status-xp'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              _showExplanation(context, _xpExplanation(state)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                key: const Key('learner-status-xp-icon'),
                                size: iconSize,
                                color: _foregroundColor,
                              ),
                              const SizedBox(width: 1),
                              SizedBox(
                                key: const Key('learner-status-xp-numbers'),
                                width: xpWidth,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    xpText,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: effectiveNumberStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

import 'package:flutter/material.dart';

import '../controllers/learner_status_controller.dart';
import '../models/learner_status_state.dart';

const double unifiedLearnerTopBarHeight = 64;

/// The fixed Home header row. Course identity remains in the selector below.
class UnifiedLearnerTopBar extends StatelessWidget {
  static const _logoAsset = 'assets/branding/quisquislingo_logo.png';

  final LearnerStatusController controller;
  final String? learnerName;
  final VoidCallback onUserPressed;
  final VoidCallback onSettingsPressed;

  const UnifiedLearnerTopBar({
    super.key,
    required this.controller,
    required this.learnerName,
    required this.onUserPressed,
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

  String _streakExplanation(LearnerStatusState state) {
    final language = state.course?.targetLanguage ?? 'Learning language';
    final days = state.streak ?? 0;
    return '$language streak: $days ${days == 1 ? 'day' : 'days'}';
  }

  String _laurelExplanation(LearnerStatusState state) =>
      'Laurels in this course: ${state.laurels ?? 0} out of ${state.laurelMaximum ?? 0}';

  String _xpExplanation(LearnerStatusState state) {
    final goal = state.weeklyXpGoal;
    return goal == null
        ? 'Weekly XP: ${state.weeklyXp}'
        : 'Weekly XP: ${state.weeklyXp} out of $goal';
  }

  double _reservedTextWidth(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  Widget _number(
    BuildContext context, {
    required Key key,
    required String text,
    required String reserved,
    required TextStyle style,
    required TextAlign textAlign,
    double? reservedWidth,
  }) {
    return SizedBox(
      key: key,
      width: reservedWidth ?? _reservedTextWidth(context, reserved, style),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: textAlign == TextAlign.start
            ? AlignmentDirectional.centerStart
            : Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          textAlign: textAlign,
          style: style,
        ),
      ),
    );
  }

  Widget _metric({
    required BuildContext context,
    required Key key,
    required String semanticsLabel,
    required VoidCallback onTap,
    required IconData icon,
    required Key iconKey,
    required Color iconColor,
    required double iconSize,
    required Widget number,
  }) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semanticsLabel,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, key: iconKey, size: iconSize, color: iconColor),
              const SizedBox(width: 2),
              number,
            ],
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
        final resolvedLearner = state.activeProfile ?? learnerName ?? 'Learner';
        final streakText = '${state.streak ?? 0}';
        final laurelText =
            '${state.laurels ?? 0} / ${state.laurelMaximum ?? 0}';
        final xpText = state.weeklyXpGoal == null
            ? '${state.weeklyXp}'
            : '${state.weeklyXp} / ${state.weeklyXpGoal}';
        final colorScheme = Theme.of(context).colorScheme;

        return Material(
          key: const Key('unified-learner-top-bar'),
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          child: SizedBox(
            height: unifiedLearnerTopBarHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth <= 430;
                final gap = constraints.maxWidth < 400 ? 3.0 : 6.0;
                final iconSize = compact ? 14.0 : 17.0;
                final numberStyle = TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 6),
                  child: Row(
                    key: const Key('unified-topbar-row'),
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          excludeSemantics: true,
                          label: 'Learner: $resolvedLearner',
                          child: InkWell(
                            key: const Key('unified-topbar-user'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: onUserPressed,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.face_outlined,
                                    size: iconSize,
                                    color: colorScheme.onSurface,
                                  ),
                                  SizedBox(width: compact ? 1 : 3),
                                  Expanded(
                                    child: Text(
                                      resolvedLearner,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: numberStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _gap('user-logo', gap),
                      Semantics(
                        label: 'QuisquisLingo logo',
                        image: true,
                        child: SizedBox(
                          key: const Key('unified-topbar-logo-mark'),
                          width: compact ? 29 : 37,
                          height: 48,
                          child: ClipRect(
                            key: const Key('unified-topbar-logo-clip'),
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: compact ? 120 : 156,
                              maxWidth: compact ? 120 : 156,
                              minHeight: compact ? 40 : 52,
                              maxHeight: compact ? 40 : 52,
                              child: Image.asset(
                                _logoAsset,
                                key: const Key('unified-topbar-logo-image'),
                                width: compact ? 120 : 156,
                                height: compact ? 40 : 52,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _gap('logo-streak', gap),
                      _metric(
                        context: context,
                        key: const Key('unified-topbar-streak'),
                        semanticsLabel: _streakExplanation(state),
                        onTap: () => _showExplanation(
                          context,
                          _streakExplanation(state),
                        ),
                        icon: Icons.local_fire_department,
                        iconKey: const Key('unified-topbar-flame-icon'),
                        iconColor: const Color(0xFFF05A28),
                        iconSize: iconSize,
                        number: _number(
                          context,
                          key: const Key('unified-topbar-streak-number'),
                          text: streakText,
                          reserved: '9999',
                          style: numberStyle,
                          textAlign: TextAlign.center,
                          reservedWidth: compact ? 27 : null,
                        ),
                      ),
                      _gap('streak-laurel', gap),
                      _metric(
                        context: context,
                        key: const Key('unified-topbar-laurels'),
                        semanticsLabel: _laurelExplanation(state),
                        onTap: () => _showExplanation(
                          context,
                          _laurelExplanation(state),
                        ),
                        icon: Icons.workspace_premium_outlined,
                        iconKey: const Key('unified-topbar-laurel-icon'),
                        iconColor: const Color(0xFF2E8B57),
                        iconSize: iconSize,
                        number: _number(
                          context,
                          key: const Key('unified-topbar-laurel-numbers'),
                          text: laurelText,
                          reserved: '999 / 999',
                          style: numberStyle,
                          textAlign: TextAlign.center,
                          reservedWidth: compact ? 60 : null,
                        ),
                      ),
                      _gap('laurel-xp', gap),
                      _metric(
                        context: context,
                        key: const Key('unified-topbar-weekly-xp'),
                        semanticsLabel: _xpExplanation(state),
                        onTap: () =>
                            _showExplanation(context, _xpExplanation(state)),
                        icon: Icons.bolt,
                        iconKey: const Key('unified-topbar-xp-icon'),
                        iconColor: colorScheme.onSurface,
                        iconSize: iconSize,
                        number: _number(
                          context,
                          key: const Key('unified-topbar-xp-numbers'),
                          text: xpText,
                          reserved: '99999 / 99999',
                          style: numberStyle,
                          textAlign: TextAlign.start,
                          reservedWidth: compact ? 87 : null,
                        ),
                      ),
                      _gap('xp-settings', gap),
                      Semantics(
                        button: true,
                        excludeSemantics: true,
                        label: 'Settings',
                        onTap: onSettingsPressed,
                        child: IconButton(
                          key: const Key('unified-topbar-settings'),
                          tooltip: 'Settings',
                          visualDensity: compact
                              ? const VisualDensity(horizontal: -4)
                              : VisualDensity.compact,
                          constraints: BoxConstraints(
                            minWidth: compact ? 40 : 44,
                            minHeight: 48,
                          ),
                          color: colorScheme.onSurface,
                          iconSize: compact ? 18 : 22,
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

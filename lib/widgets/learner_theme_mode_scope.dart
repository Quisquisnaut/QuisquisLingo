import 'package:flutter/widgets.dart';

import '../services/profile_service.dart';

class LearnerThemeModeScope extends InheritedWidget {
  final LearnerThemeMode mode;

  const LearnerThemeModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  static LearnerThemeMode? maybeModeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LearnerThemeModeScope>()?.mode;

  @override
  bool updateShouldNotify(LearnerThemeModeScope oldWidget) =>
      oldWidget.mode != mode;
}

class LearnerFlagBackgroundModeScope extends InheritedWidget {
  final LearnerFlagBackgroundMode mode;

  const LearnerFlagBackgroundModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  static LearnerFlagBackgroundMode? maybeModeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LearnerFlagBackgroundModeScope>()
      ?.mode;

  @override
  bool updateShouldNotify(LearnerFlagBackgroundModeScope oldWidget) =>
      oldWidget.mode != mode;
}

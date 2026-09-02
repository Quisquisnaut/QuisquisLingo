import 'dart:async';

import 'package:flutter/material.dart';

import '../services/learner_status_events.dart';
import '../services/profile_service.dart';
import 'learner_avatar.dart';

const double learnerBottomActionsHeight = 68;

class LearnerBottomActions extends StatefulWidget {
  final VoidCallback onProfile;
  final VoidCallback onReview;
  final VoidCallback onCourseInfo;
  final ProfileService? profileService;

  const LearnerBottomActions({
    super.key,
    required this.onProfile,
    required this.onReview,
    required this.onCourseInfo,
    this.profileService,
  });

  @override
  State<LearnerBottomActions> createState() => _LearnerBottomActionsState();
}

class _LearnerBottomActionsState extends State<LearnerBottomActions> {
  late final ProfileService _profiles;
  StreamSubscription<LearnerStatusInvalidation>? _subscription;
  String? _learnerName;
  ProfileAvatarAppearance? _appearance;
  LearnerThemeMode _themeMode = LearnerThemeMode.defaultMode;
  LearnerFlagBackgroundMode _flagBackgroundMode =
      LearnerFlagBackgroundMode.small;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _subscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.activeProfile ||
          event == LearnerStatusInvalidation.avatar ||
          event == LearnerStatusInvalidation.theme ||
          event == LearnerStatusInvalidation.flagBackground) {
        _load();
      }
    });
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    String? learnerName;
    ProfileAvatarAppearance? appearance;
    var themeMode = LearnerThemeMode.defaultMode;
    var flagBackgroundMode = LearnerFlagBackgroundMode.small;
    try {
      final active = await _profiles.getActiveProfileRecord();
      final fallbackName = active == null
          ? await _profiles.getActiveProfile()
          : null;
      final cleanName = (active?.displayName ?? fallbackName)?.trim() ?? '';
      if (cleanName.isNotEmpty) {
        learnerName = active?.displayName ?? fallbackName;
        appearance = await _profiles.getAvatarAppearanceForProfile(
          active?.learnerProfileId ?? cleanName,
        );
        themeMode = await _profiles.getThemeMode();
        flagBackgroundMode = await _profiles.getFlagBackgroundMode();
      }
    } catch (_) {
      // Presentation falls through to the best information that was readable.
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _learnerName = learnerName;
      _appearance = appearance;
      _themeMode = themeMode;
      _flagBackgroundMode = flagBackgroundMode;
    });
  }

  Future<void> _cycleThemeMode() async {
    if (_learnerName == null) {
      if (_themeMode != LearnerThemeMode.defaultMode) {
        setState(() => _themeMode = LearnerThemeMode.defaultMode);
      }
      return;
    }
    final nextMode = _themeMode.next;
    setState(() => _themeMode = nextMode);
    try {
      await _profiles.setThemeMode(nextMode);
    } catch (_) {
      await _load();
    }
  }

  Future<void> _cycleFlagBackgroundMode() async {
    if (_learnerName == null) {
      if (_flagBackgroundMode != LearnerFlagBackgroundMode.small) {
        setState(() => _flagBackgroundMode = LearnerFlagBackgroundMode.small);
      }
      return;
    }
    final nextMode = _flagBackgroundMode.next;
    setState(() => _flagBackgroundMode = nextMode);
    try {
      await _profiles.setFlagBackgroundMode(nextMode);
    } catch (_) {
      await _load();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('learner-bottom-actions'),
    height: learnerBottomActionsHeight,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _ProfileAction(
                  learnerName: _learnerName,
                  appearance: _appearance,
                  onTap: widget.onProfile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BottomAction(
                  key: const Key('learner-bottom-review'),
                  icon: Icons.history_edu_outlined,
                  label: 'Review',
                  onTap: widget.onReview,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BottomAction(
                  key: const Key('learner-bottom-course-info'),
                  icon: Icons.info_outline,
                  label: 'Course Info',
                  onTap: widget.onCourseInfo,
                ),
              ),
              const SizedBox(width: 8),
              _ThemeModeAction(mode: _themeMode, onTap: _cycleThemeMode),
              const SizedBox(width: 4),
              _FlagBackgroundModeAction(
                mode: _flagBackgroundMode,
                onTap: _cycleFlagBackgroundMode,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FlagBackgroundModeAction extends StatelessWidget {
  final LearnerFlagBackgroundMode mode;
  final VoidCallback onTap;

  const _FlagBackgroundModeAction({required this.mode, required this.onTap});

  IconData get _icon => switch (mode) {
    LearnerFlagBackgroundMode.small => Icons.flag_outlined,
    LearnerFlagBackgroundMode.off => Icons.hide_image_outlined,
    LearnerFlagBackgroundMode.extended => Icons.flag,
  };

  @override
  Widget build(BuildContext context) {
    final label = 'Flag background: ${mode.label}';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      key: const Key('learner-bottom-flag-background'),
      width: 40,
      height: 40,
      child: Tooltip(
        message: label,
        child: Material(
          color: isDark
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .36)
              : Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          child: Semantics(
            button: true,
            label: label,
            onTap: onTap,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Center(
                child: Icon(_icon, size: 20, color: _actionColor(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeAction extends StatelessWidget {
  final LearnerThemeMode mode;
  final VoidCallback onTap;

  const _ThemeModeAction({required this.mode, required this.onTap});

  IconData get _icon => switch (mode) {
    LearnerThemeMode.defaultMode => Icons.brightness_auto_outlined,
    LearnerThemeMode.light => Icons.light_mode_outlined,
    LearnerThemeMode.dark => Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final label = 'Theme: ${mode.label}';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      key: const Key('learner-bottom-theme'),
      width: 40,
      height: 40,
      child: Tooltip(
        message: label,
        child: Material(
          color: isDark
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .36)
              : Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          child: Semantics(
            button: true,
            label: label,
            onTap: onTap,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Center(
                child: Icon(_icon, size: 20, color: _actionColor(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final String? learnerName;
  final ProfileAvatarAppearance? appearance;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.learnerName,
    required this.appearance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = learnerName?.trim() ?? '';
    final tooltip = cleanName.isEmpty ? 'Profile' : learnerName!;
    final semanticsLabel = cleanName.isEmpty
        ? 'Profile'
        : 'Profile, $learnerName';
    final avatar = appearance;
    final visual = avatar != null
        ? SizedBox(
            width: 32,
            height: 32,
            child: LearnerAvatar(
              key: const Key('learner-bottom-profile-avatar'),
              skinTone: avatar.skinTone,
              hairTone: avatar.hairTone,
            ),
          )
        : cleanName.isNotEmpty
        ? Text(
            learnerName!,
            key: const Key('learner-bottom-profile-name'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          )
        : Icon(
            Icons.person_outline,
            key: const Key('learner-bottom-profile-icon'),
            size: 24,
            color: _actionColor(context),
          );
    return _ActionSurface(
      key: const Key('learner-bottom-profile'),
      tooltip: tooltip,
      semanticsLabel: semanticsLabel,
      onTap: onTap,
      child: visual,
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => _ActionSurface(
    tooltip: label,
    semanticsLabel: label,
    onTap: onTap,
    child: Icon(icon, size: 24, color: _actionColor(context)),
  );
}

class _ActionSurface extends StatelessWidget {
  final String tooltip;
  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  const _ActionSurface({
    super.key,
    required this.tooltip,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .72)
            : Colors.white.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          button: true,
          label: semanticsLabel,
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(height: 44, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

Color _actionColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF9AD5B3)
    : const Color(0xFF3D704F);

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
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _subscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.activeProfile ||
          event == LearnerStatusInvalidation.avatar) {
        _load();
      }
    });
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    String? learnerName;
    ProfileAvatarAppearance? appearance;
    try {
      final active = await _profiles.getActiveProfile();
      final cleanName = active?.trim() ?? '';
      if (cleanName.isNotEmpty) {
        learnerName = active;
        appearance = await _profiles.getAvatarAppearanceForProfile(active!);
      }
    } catch (_) {
      // Presentation falls through to the best information that was readable.
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _learnerName = learnerName;
      _appearance = appearance;
    });
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
            ],
          ),
        ),
      ),
    ),
  );
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

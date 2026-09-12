import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/learner_status_events.dart';
import '../services/learner_status_level_service.dart';
import '../services/profile_service.dart';
import '../services/status_service.dart';
import '../widgets/learner_avatar.dart';
import 'avatar_settings_screen.dart';
import 'gamification_settings_screen.dart';
import 'statistics_screen.dart';
import 'user_data_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Course course;
  final Future<void> Function(BuildContext context) onManageLearners;
  final ProfileService? profileService;

  const ProfileScreen({
    super.key,
    required this.course,
    required this.onManageLearners,
    this.profileService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profiles;
  late final LearnerStatusLevelService _statusLevels;
  StreamSubscription<LearnerStatusInvalidation>? _subscription;
  bool _loading = true;
  LearnerProfile? _profile;
  ProfileAvatarAppearance? _appearance;
  StatusRank? _statusRank;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _statusLevels = LearnerStatusLevelService();
    _subscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.activeProfile ||
          event == LearnerStatusInvalidation.avatar ||
          event == LearnerStatusInvalidation.xp ||
          event == LearnerStatusInvalidation.activity ||
          event == LearnerStatusInvalidation.laurels) {
        _load();
      }
    });
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final profile = await _profiles.getActiveProfileRecord();
    final appearance = profile == null
        ? null
        : await _profiles.getAvatarAppearanceForProfile(
            profile.learnerProfileId,
          );
    StatusRank? statusRank;
    if (profile != null) {
      try {
        statusRank = await _statusLevels.rankForActiveLearner(
          courseId: widget.course.courseId,
          courseCode: CourseService.codeForCourse(widget.course),
        );
      } catch (_) {
        // Profile remains usable if one progression projection cannot load.
      }
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _profile = profile;
      _appearance = appearance;
      _statusRank = statusRank;
      _loading = false;
    });
  }

  Future<void> _openAvatar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvatarSettingsScreen(
          course: widget.course,
          profileService: _profiles,
          statusLevelService: _statusLevels,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openLearnerProfiles() async {
    await widget.onManageLearners(context);
    if (mounted) await _load();
  }

  Future<void> _editProfileIdentity() async {
    final profile = _profile;
    if (profile == null) return;
    final screenName = TextEditingController(text: profile.displayName);
    final discord = TextEditingController(
      text: profile.discordHandle?.replaceFirst('@', '') ?? '',
    );
    final replacement = await showDialog<LearnerProfile>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: screenName,
                maxLength: ProfileService.maxNameLength,
                decoration: const InputDecoration(labelText: 'Screen Name'),
              ),
              TextField(
                controller: discord,
                maxLength: ProfileService.maxDiscordHandleLength - 1,
                decoration: const InputDecoration(
                  labelText: 'Discord name (optional)',
                  prefixText: '@',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              try {
                Navigator.pop(
                  dialogContext,
                  LearnerProfile(
                    learnerProfileId: profile.learnerProfileId,
                    displayName: ProfileService.validateDisplayName(
                      screenName.text,
                    ),
                    discordHandle: ProfileService.normalizeDiscordHandle(
                      discord.text,
                    ),
                  ),
                );
              } on ArgumentError {
                // Invalid text remains in the dialog for correction.
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    screenName.dispose();
    discord.dispose();
    if (replacement == null) return;
    await _profiles.replaceProfileRecord(replacement);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    await _load();
  }

  Future<void> _openGamification() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamificationSettingsScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _openUserData() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserDataSettingsScreen(course: widget.course),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openStatistics() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
    if (mounted) await _load();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of this local profile?'),
        content: const Text(
          'You will return to learner selection. No profile or progress data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _profiles.clearActiveProfile();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learnerName = _profile?.displayName.trim() ?? '';
    final statusRank = _statusRank;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: 112,
                    height: 128,
                    child: _appearance == null
                        ? const Icon(
                            Icons.person_outline,
                            key: Key('profile-large-avatar-fallback'),
                            size: 88,
                          )
                        : LearnerAvatar(
                            key: const Key('profile-large-avatar'),
                            level: statusRank?.index ?? 0,
                            skinTone: _appearance!.skinTone,
                            hairTone: _appearance!.hairTone,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  learnerName.isEmpty ? 'Profile' : _profile!.displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_profile?.discordHandle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _profile!.discordHandle!,
                    key: const Key('profile-discord-handle'),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (statusRank != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Current Status: ${statusRank.name}',
                    key: const Key('profile-current-status'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ListTile(
                  key: const Key('profile-identity-link'),
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Profile identity'),
                  subtitle: Text(
                    _profile?.discordHandle == null
                        ? 'Screen Name and optional Discord name.'
                        : '${_profile!.displayName} · ${_profile!.discordHandle}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _editProfileIdentity,
                ),
                ListTile(
                  key: const Key('profile-avatar-link'),
                  leading: const Icon(Icons.face_retouching_natural_outlined),
                  title: const Text('Avatar'),
                  subtitle: const Text('Customize this learner avatar.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAvatar,
                ),
                ListTile(
                  key: const Key('profile-learners-link'),
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Learner profiles'),
                  subtitle: const Text('Switch, add or delete local profiles.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openLearnerProfiles,
                ),
                ListTile(
                  key: const Key('profile-gamification-link'),
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Gamification'),
                  subtitle: const Text(
                    'Weekly goals and the local leaderboard.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openGamification,
                ),
                ListTile(
                  key: const Key('profile-statistics-link'),
                  leading: const Icon(Icons.query_stats_outlined),
                  title: const Text('Statistics'),
                  subtitle: const Text(
                    'Study days and language streak history.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openStatistics,
                ),
                ListTile(
                  key: const Key('profile-user-data-link'),
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('User Data'),
                  subtitle: const Text(
                    'Export or import learner data, or reset the current course progress.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openUserData,
                ),
                const Divider(height: 32),
                const Text('This is a local profile only.'),
                const SizedBox(height: 4),
                const Text('Logging out does not contact any remote server.'),
                const SizedBox(height: 4),
                const Text(
                  'Your learner profile and progress remain stored on this device.',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('profile-logout'),
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ],
            ),
    );
  }
}

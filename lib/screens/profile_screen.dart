import 'dart:async';

import 'package:flutter/material.dart';

import '../services/learner_status_events.dart';
import '../services/profile_service.dart';
import '../widgets/learner_avatar.dart';
import 'avatar_settings_screen.dart';
import 'gamification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function(BuildContext context) onManageLearners;
  final ProfileService? profileService;

  const ProfileScreen({
    super.key,
    required this.onManageLearners,
    this.profileService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profiles;
  StreamSubscription<LearnerStatusInvalidation>? _subscription;
  bool _loading = true;
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
    final profile = await _profiles.getActiveProfileRecord();
    final appearance = profile == null
        ? null
        : await _profiles.getAvatarAppearanceForProfile(
            profile.learnerProfileId,
          );
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _learnerName = profile?.displayName;
      _appearance = appearance;
      _loading = false;
    });
  }

  Future<void> _openAvatar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvatarSettingsScreen(profileService: _profiles),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openLearnerProfiles() async {
    await widget.onManageLearners(context);
    if (mounted) await _load();
  }

  Future<void> _openGamification() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamificationSettingsScreen()),
    );
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
    final learnerName = _learnerName?.trim() ?? '';
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
                            skinTone: _appearance!.skinTone,
                            hairTone: _appearance!.hairTone,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  learnerName.isEmpty ? 'Profile' : _learnerName!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
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

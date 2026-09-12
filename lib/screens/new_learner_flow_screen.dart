import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../widgets/avatar_customization_content.dart';

class NewLearnerFlowScreen extends StatefulWidget {
  final ProfileService? profileService;
  final bool canCancel;
  final ValueChanged<LearnerProfile>? onComplete;

  const NewLearnerFlowScreen({
    super.key,
    this.profileService,
    required this.canCancel,
    this.onComplete,
  });

  @override
  State<NewLearnerFlowScreen> createState() => _NewLearnerFlowScreenState();
}

class _NewLearnerFlowScreenState extends State<NewLearnerFlowScreen> {
  late final ProfileService _profiles;
  final TextEditingController _screenName = TextEditingController();
  final TextEditingController _discord = TextEditingController();
  LearnerProfile? _profile;
  String _skinTone = 'medium';
  String _hairTone = 'dark';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
  }

  Future<void> _continue() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await _profiles.createProfile(
        _screenName.text,
        discordHandle: _discord.text,
      );
      final appearance = await _profiles.getAvatarAppearanceForProfile(
        profile.learnerProfileId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _skinTone = appearance?.skinTone ?? 'medium';
        _hairTone = appearance?.hairTone ?? 'dark';
        _busy = false;
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message?.toString() ?? 'Check the profile details.';
        _busy = false;
      });
    }
  }

  Future<void> _setSkin(String value) async {
    await _profiles.setSkinTone(value);
    if (mounted) setState(() => _skinTone = value);
  }

  Future<void> _setHair(String value) async {
    await _profiles.setHairTone(value);
    if (mounted) setState(() => _hairTone = value);
  }

  void _finish() {
    final profile = _profile;
    if (profile == null) return;
    final callback = widget.onComplete;
    if (callback != null) {
      callback(profile);
    } else {
      Navigator.pop(context, profile);
    }
  }

  @override
  void dispose() {
    _screenName.dispose();
    _discord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return PopScope(
      canPop: widget.canCancel || profile != null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            profile == null ? 'Create Profile' : 'Avatar Customization',
          ),
        ),
        body: profile == null ? _buildProfileStep() : _buildAvatarStep(),
      ),
    );
  }

  Widget _buildProfileStep() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      Text('Step 1 of 2', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Text(
        'Create Profile',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('new-learner-screen-name'),
        controller: _screenName,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: ProfileService.maxNameLength,
        decoration: const InputDecoration(
          labelText: 'Screen Name',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('new-learner-discord'),
        controller: _discord,
        maxLength: ProfileService.maxDiscordHandleLength - 1,
        decoration: const InputDecoration(
          labelText: 'Discord name (optional)',
          helperText: 'Enter the name without @. QQL adds it automatically.',
          prefixText: '@',
          border: OutlineInputBorder(),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: 18),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _busy ? null : _continue,
          child: const Text('Continue'),
        ),
      ),
    ],
  );

  Widget _buildAvatarStep() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      Text('Step 2 of 2', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 12),
      AvatarCustomizationContent(
        currentLevel: 0,
        skinTone: _skinTone,
        hairTone: _hairTone,
        onSkinChanged: _setSkin,
        onHairChanged: _setHair,
      ),
      const SizedBox(height: 18),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(onPressed: _finish, child: const Text('Done')),
      ),
    ],
  );
}

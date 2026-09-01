import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class AvatarSettingsScreen extends StatefulWidget {
  final ProfileService? profileService;

  const AvatarSettingsScreen({super.key, this.profileService});

  @override
  State<AvatarSettingsScreen> createState() => _AvatarSettingsScreenState();
}

class _AvatarSettingsScreenState extends State<AvatarSettingsScreen> {
  late final ProfileService _profiles;
  bool _loading = true;
  String _skinTone = 'medium';
  String _hairTone = 'dark';

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _load();
  }

  Future<void> _load() async {
    final skinTone = await _profiles.getSkinTone();
    final hairTone = await _profiles.getHairTone();
    if (!mounted) return;
    setState(() {
      _skinTone = skinTone;
      _hairTone = hairTone;
      _loading = false;
    });
  }

  Future<void> _setSkin(String value) async {
    await _profiles.setSkinTone(value);
    if (mounted) setState(() => _skinTone = value);
  }

  Future<void> _setHair(String value) async {
    await _profiles.setHairTone(value);
    if (mounted) setState(() => _hairTone = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Avatar appearance'),
                  subtitle: Text(
                    'These options change only the avatar linked to the active learner profile.',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Avatar skin color'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('light', 'Light'),
                      ('medium', 'Medium'),
                      ('dark', 'Dark'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: _skinTone == item.$1,
                        onSelected: (_) => _setSkin(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Avatar hair color'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('light', 'Light'),
                      ('dark', 'Dark'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: _hairTone == item.$1,
                        onSelected: (_) => _setHair(item.$1),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

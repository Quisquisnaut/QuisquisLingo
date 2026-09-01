import 'package:shared_preferences/shared_preferences.dart';
import 'learner_status_events.dart';

class ProfileAvatarAppearance {
  final String skinTone;
  final String hairTone;

  const ProfileAvatarAppearance({
    required this.skinTone,
    required this.hairTone,
  });
}

/// Manages local learner profiles and appearance preferences.
///
/// Avatar skin/hair choices belong to the local profile and describe only the
/// avatar appearance. Learning progress belongs to the profile plus the selected
/// course/language.
class ProfileService {
  static const _profilesKey = 'learner_profiles';
  static const _activeKey = 'active_learner';
  static const int _maxNameLength = 60;

  Future<List<String>> getProfiles() async =>
      (await SharedPreferences.getInstance()).getStringList(_profilesKey) ?? [];

  Future<String?> getActiveProfile() async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    final active = p.getString(_activeKey);
    if (active != null && profiles.contains(active)) return active;
    return null;
  }

  Future<ProfileAvatarAppearance?> getAvatarAppearanceForProfile(
    String profileName,
  ) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    if (!profiles.contains(profileName)) return null;
    final prefix = 'learner_${Uri.encodeComponent(profileName)}_';
    final skinTone = p.getString('${prefix}skin_tone');
    final hairTone = p.getString('${prefix}hair_tone');
    if (!const {'light', 'medium', 'dark'}.contains(skinTone) ||
        !const {'light', 'dark'}.contains(hairTone)) {
      return null;
    }
    return ProfileAvatarAppearance(skinTone: skinTone!, hairTone: hairTone!);
  }

  Future<void> addProfile(
    String name, {
    String skinTone = 'medium',
    String hairTone = 'dark',
  }) async {
    if (!const {'light', 'medium', 'dark'}.contains(skinTone))
      throw ArgumentError('Invalid avatar skin color');
    if (!const {'light', 'dark'}.contains(hairTone))
      throw ArgumentError('Invalid avatar hair color');
    var clean = name.trim();
    if (clean.isEmpty) return;
    if (clean.length > _maxNameLength)
      clean = clean.substring(0, _maxNameLength);
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    if (!profiles.contains(clean)) profiles.add(clean);
    await p.setStringList(_profilesKey, profiles);
    await p.setString(_activeKey, clean);
    final prefix = 'learner_${Uri.encodeComponent(clean)}_';
    await p.setString('${prefix}skin_tone', skinTone);
    await p.setString('${prefix}hair_tone', hairTone);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> setActiveProfile(String name) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    if (!profiles.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Unknown learner profile');
    }
    await p.setString(_activeKey, name);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> clearActiveProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_activeKey);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> deleteProfile(String name) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    profiles.remove(name);
    await p.setStringList(_profilesKey, profiles);
    final prefix = 'learner_${Uri.encodeComponent(name)}_';
    final keys = p.getKeys().where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      await p.remove(key);
    }
    if (p.getString(_activeKey) == name) {
      if (profiles.isEmpty) {
        await p.remove(_activeKey);
      } else {
        await p.setString(_activeKey, profiles.first);
      }
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<String> key(String base) async {
    final active = await getActiveProfile() ?? 'default';
    return 'learner_${Uri.encodeComponent(active)}_$base';
  }

  Future<String> getSkinTone() async {
    final p = await SharedPreferences.getInstance();
    final value = p.getString(await key('skin_tone'));
    return const {'light', 'medium', 'dark'}.contains(value)
        ? value!
        : 'medium';
  }

  Future<void> setSkinTone(String value) async {
    if (!const {'light', 'medium', 'dark'}.contains(value))
      throw ArgumentError('Invalid skin tone');
    final p = await SharedPreferences.getInstance();
    await p.setString(await key('skin_tone'), value);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.avatar);
  }

  Future<String> getHairTone() async {
    final p = await SharedPreferences.getInstance();
    final value = p.getString(await key('hair_tone'));
    return const {'light', 'dark'}.contains(value) ? value! : 'dark';
  }

  Future<void> setHairTone(String value) async {
    if (!const {'light', 'dark'}.contains(value))
      throw ArgumentError('Invalid hair tone');
    final p = await SharedPreferences.getInstance();
    await p.setString(await key('hair_tone'), value);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.avatar);
  }
}

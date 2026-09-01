import 'package:shared_preferences/shared_preferences.dart';
import 'learner_status_events.dart';

enum LearnerThemeMode {
  defaultMode('default', 'Default'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  final String storageValue;
  final String label;

  const LearnerThemeMode(this.storageValue, this.label);

  LearnerThemeMode get next => switch (this) {
    LearnerThemeMode.defaultMode => LearnerThemeMode.light,
    LearnerThemeMode.light => LearnerThemeMode.dark,
    LearnerThemeMode.dark => LearnerThemeMode.defaultMode,
  };

  static LearnerThemeMode fromStorage(String? value) => values.firstWhere(
    (mode) => mode.storageValue == value,
    orElse: () => LearnerThemeMode.defaultMode,
  );
}

enum LearnerFlagBackgroundMode {
  small('small', 'Small'),
  off('off', 'Off'),
  extended('extended', 'Extended');

  final String storageValue;
  final String label;

  const LearnerFlagBackgroundMode(this.storageValue, this.label);

  LearnerFlagBackgroundMode get next => switch (this) {
    LearnerFlagBackgroundMode.small => LearnerFlagBackgroundMode.off,
    LearnerFlagBackgroundMode.off => LearnerFlagBackgroundMode.extended,
    LearnerFlagBackgroundMode.extended => LearnerFlagBackgroundMode.small,
  };

  static LearnerFlagBackgroundMode fromStorage(String? value) =>
      values.firstWhere(
        (mode) => mode.storageValue == value,
        orElse: () => LearnerFlagBackgroundMode.small,
      );
}

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
/// Avatar skin/hair, theme and flag-background choices belong to the local
/// profile. Learning progress belongs to the profile plus the selected
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

  Future<LearnerThemeMode> getThemeMode() async {
    final active = await getActiveProfile();
    if (active == null) return LearnerThemeMode.defaultMode;
    return getThemeModeForProfile(active);
  }

  Future<LearnerThemeMode> getThemeModeForProfile(String profileName) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    if (!profiles.contains(profileName)) return LearnerThemeMode.defaultMode;
    final prefix = 'learner_${Uri.encodeComponent(profileName)}_';
    return LearnerThemeMode.fromStorage(p.getString('${prefix}theme_mode'));
  }

  Future<void> setThemeMode(LearnerThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    final active = p.getString(_activeKey);
    if (active == null || !profiles.contains(active)) return;
    final prefix = 'learner_${Uri.encodeComponent(active)}_';
    await p.setString('${prefix}theme_mode', mode.storageValue);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.theme);
  }

  Future<LearnerFlagBackgroundMode> getFlagBackgroundMode() async {
    final active = await getActiveProfile();
    if (active == null) return LearnerFlagBackgroundMode.small;
    return getFlagBackgroundModeForProfile(active);
  }

  Future<LearnerFlagBackgroundMode> getFlagBackgroundModeForProfile(
    String profileName,
  ) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    if (!profiles.contains(profileName)) {
      return LearnerFlagBackgroundMode.small;
    }
    final prefix = 'learner_${Uri.encodeComponent(profileName)}_';
    return LearnerFlagBackgroundMode.fromStorage(
      p.getString('${prefix}flag_background_mode'),
    );
  }

  Future<void> setFlagBackgroundMode(LearnerFlagBackgroundMode mode) async {
    final p = await SharedPreferences.getInstance();
    final profiles = p.getStringList(_profilesKey) ?? [];
    final active = p.getString(_activeKey);
    if (active == null || !profiles.contains(active)) return;
    final prefix = 'learner_${Uri.encodeComponent(active)}_';
    await p.setString('${prefix}flag_background_mode', mode.storageValue);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.flagBackground);
  }

  String keyForProfile(String profileName, String base) =>
      'learner_${Uri.encodeComponent(profileName)}_$base';

  Future<String> key(String base) async {
    final active = await getActiveProfile() ?? 'default';
    return keyForProfile(active, base);
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

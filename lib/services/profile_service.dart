import 'dart:convert';
import 'dart:math';

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

class LearnerProfile {
  final String learnerProfileId;
  final String displayName;

  const LearnerProfile({
    required this.learnerProfileId,
    required this.displayName,
  });

  String encode() => jsonEncode({
    'learnerProfileId': learnerProfileId,
    'displayName': displayName,
  });

  static LearnerProfile? decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final id = value['learnerProfileId'];
      final name = value['displayName'];
      if (id is! String ||
          !ProfileService.isValidLearnerProfileId(id) ||
          name is! String ||
          name.trim().isEmpty ||
          name.length > ProfileService.maxNameLength) {
        return null;
      }
      return LearnerProfile(learnerProfileId: id, displayName: name);
    } catch (_) {
      return null;
    }
  }
}

class ProfileAvatarAppearance {
  final String skinTone;
  final String hairTone;

  const ProfileAvatarAppearance({
    required this.skinTone,
    required this.hairTone,
  });
}

/// Manages opaque local learner identities and profile appearance.
///
/// Build 222 is an intentional clean cut. The v2 registry and active-ID key do
/// not read or migrate the former display-name-based registry or namespaces.
class ProfileService {
  static const profilesKey = 'learner_profiles_v2';
  static const activeProfileIdKey = 'active_learner_profile_id';
  static const int maxNameLength = 60;
  static final RegExp _profileIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String Function() _idGenerator;

  ProfileService({String Function()? idGenerator})
    : _idGenerator = idGenerator ?? _generateUuidV4;

  static bool isValidLearnerProfileId(String value) =>
      _profileIdPattern.hasMatch(value);

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  static String validateDisplayName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(name, 'displayName', 'Learner name is empty');
    }
    if (clean.length > maxNameLength) {
      throw ArgumentError.value(
        name,
        'displayName',
        'Learner name exceeds the $maxNameLength-character limit',
      );
    }
    return clean;
  }

  Future<List<LearnerProfile>> getProfileRecords() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(
      profilesKey,
    );
    if (raw == null) return const [];
    final seen = <String>{};
    return raw
        .map(LearnerProfile.decode)
        .whereType<LearnerProfile>()
        .where((profile) => seen.add(profile.learnerProfileId))
        .toList(growable: false);
  }

  /// Presentation-only compatibility facade. Duplicate names are retained.
  Future<List<String>> getProfiles() async => (await getProfileRecords())
      .map((profile) => profile.displayName)
      .toList();

  Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(activeProfileIdKey);
    if (activeId == null) return null;
    final profiles = await getProfileRecords();
    return profiles.any((profile) => profile.learnerProfileId == activeId)
        ? activeId
        : null;
  }

  Future<LearnerProfile?> getActiveProfileRecord() async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return null;
    return (await getProfileRecords()).firstWhere(
      (profile) => profile.learnerProfileId == activeId,
    );
  }

  /// Presentation-only active learner name.
  Future<String?> getActiveProfile() async =>
      (await getActiveProfileRecord())?.displayName;

  Future<LearnerProfile?> getProfileById(String learnerProfileId) async {
    for (final profile in await getProfileRecords()) {
      if (profile.learnerProfileId == learnerProfileId) return profile;
    }
    return null;
  }

  Future<LearnerProfile?> _resolveProfile(String idOrDisplayName) async {
    final profiles = await getProfileRecords();
    for (final profile in profiles) {
      if (profile.learnerProfileId == idOrDisplayName) return profile;
    }
    for (final profile in profiles) {
      if (profile.displayName == idOrDisplayName) return profile;
    }
    return null;
  }

  Future<ProfileAvatarAppearance?> getAvatarAppearanceForProfile(
    String learnerProfileIdOrDisplayName,
  ) async {
    final profile = await _resolveProfile(learnerProfileIdOrDisplayName);
    if (profile == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final prefix = prefixForProfileId(profile.learnerProfileId);
    final skinTone = prefs.getString('${prefix}skin_tone');
    final hairTone = prefs.getString('${prefix}hair_tone');
    if (!const {'light', 'medium', 'dark'}.contains(skinTone) ||
        !const {'light', 'dark'}.contains(hairTone)) {
      return null;
    }
    return ProfileAvatarAppearance(skinTone: skinTone!, hairTone: hairTone!);
  }

  Future<LearnerProfile> createProfile(
    String displayName, {
    String skinTone = 'medium',
    String hairTone = 'dark',
    String? learnerProfileId,
  }) async {
    if (!const {'light', 'medium', 'dark'}.contains(skinTone)) {
      throw ArgumentError('Invalid avatar skin color');
    }
    if (!const {'light', 'dark'}.contains(hairTone)) {
      throw ArgumentError('Invalid avatar hair color');
    }
    final clean = validateDisplayName(displayName);
    final id = learnerProfileId ?? _idGenerator();
    if (!isValidLearnerProfileId(id)) {
      throw ArgumentError.value(id, 'learnerProfileId', 'Invalid profile ID');
    }
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    if (profiles.any((profile) => profile.learnerProfileId == id)) {
      throw ArgumentError.value(id, 'learnerProfileId', 'Profile ID exists');
    }
    final profile = LearnerProfile(learnerProfileId: id, displayName: clean);
    await prefs.setStringList(
      profilesKey,
      [...profiles, profile].map((value) => value.encode()).toList(),
    );
    await prefs.setString(activeProfileIdKey, id);
    final prefix = prefixForProfileId(id);
    await prefs.setString('${prefix}skin_tone', skinTone);
    await prefs.setString('${prefix}hair_tone', hairTone);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    return profile;
  }

  Future<void> addProfile(
    String name, {
    String skinTone = 'medium',
    String hairTone = 'dark',
  }) async {
    await createProfile(name, skinTone: skinTone, hairTone: hairTone);
  }

  Future<void> replaceProfileRecord(LearnerProfile replacement) async {
    final clean = validateDisplayName(replacement.displayName);
    if (!isValidLearnerProfileId(replacement.learnerProfileId)) {
      throw ArgumentError('Invalid learner profile ID');
    }
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    final index = profiles.indexWhere(
      (profile) => profile.learnerProfileId == replacement.learnerProfileId,
    );
    final value = LearnerProfile(
      learnerProfileId: replacement.learnerProfileId,
      displayName: clean,
    );
    final updated = [...profiles];
    if (index < 0) {
      updated.add(value);
    } else {
      updated[index] = value;
    }
    await prefs.setStringList(
      profilesKey,
      updated.map((profile) => profile.encode()).toList(),
    );
  }

  Future<void> setActiveProfileById(String learnerProfileId) async {
    if (await getProfileById(learnerProfileId) == null) {
      throw ArgumentError.value(
        learnerProfileId,
        'learnerProfileId',
        'Unknown learner profile',
      );
    }
    await (await SharedPreferences.getInstance()).setString(
      activeProfileIdKey,
      learnerProfileId,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  /// Compatibility facade; IDs are authoritative and names resolve first-match.
  Future<void> setActiveProfile(String idOrDisplayName) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile == null) {
      throw ArgumentError.value(
        idOrDisplayName,
        'profile',
        'Unknown learner profile',
      );
    }
    await setActiveProfileById(profile.learnerProfileId);
  }

  Future<void> clearActiveProfile() async {
    await (await SharedPreferences.getInstance()).remove(activeProfileIdKey);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> deleteProfileById(String learnerProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    if (!profiles.any(
      (profile) => profile.learnerProfileId == learnerProfileId,
    )) {
      return;
    }
    final remaining = profiles
        .where((profile) => profile.learnerProfileId != learnerProfileId)
        .toList();
    await prefs.setStringList(
      profilesKey,
      remaining.map((profile) => profile.encode()).toList(),
    );
    final prefix = prefixForProfileId(learnerProfileId);
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      await prefs.remove(key);
    }
    if (prefs.getString(activeProfileIdKey) == learnerProfileId) {
      if (remaining.isEmpty) {
        await prefs.remove(activeProfileIdKey);
      } else {
        await prefs.setString(
          activeProfileIdKey,
          remaining.first.learnerProfileId,
        );
      }
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> deleteProfile(String idOrDisplayName) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile != null) await deleteProfileById(profile.learnerProfileId);
  }

  static String prefixForProfileId(String learnerProfileId) {
    if (!isValidLearnerProfileId(learnerProfileId)) {
      throw ArgumentError.value(
        learnerProfileId,
        'learnerProfileId',
        'Invalid learner profile ID',
      );
    }
    return 'learner_${learnerProfileId}_';
  }

  String keyForProfileId(String learnerProfileId, String base) =>
      '${prefixForProfileId(learnerProfileId)}$base';

  Future<String> key(String base) async {
    final activeId = await getActiveProfileId();
    if (activeId == null) throw StateError('No active learner profile');
    return keyForProfileId(activeId, base);
  }

  Future<LearnerThemeMode> getThemeMode() async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return LearnerThemeMode.defaultMode;
    return getThemeModeForProfile(activeId);
  }

  Future<LearnerThemeMode> getThemeModeForProfile(
    String idOrDisplayName,
  ) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile == null) return LearnerThemeMode.defaultMode;
    final prefs = await SharedPreferences.getInstance();
    return LearnerThemeMode.fromStorage(
      prefs.getString(keyForProfileId(profile.learnerProfileId, 'theme_mode')),
    );
  }

  Future<void> setThemeMode(LearnerThemeMode mode) async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      keyForProfileId(activeId, 'theme_mode'),
      mode.storageValue,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.theme);
  }

  Future<LearnerFlagBackgroundMode> getFlagBackgroundMode() async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return LearnerFlagBackgroundMode.small;
    return getFlagBackgroundModeForProfile(activeId);
  }

  Future<LearnerFlagBackgroundMode> getFlagBackgroundModeForProfile(
    String idOrDisplayName,
  ) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile == null) return LearnerFlagBackgroundMode.small;
    final prefs = await SharedPreferences.getInstance();
    return LearnerFlagBackgroundMode.fromStorage(
      prefs.getString(
        keyForProfileId(profile.learnerProfileId, 'flag_background_mode'),
      ),
    );
  }

  Future<void> setFlagBackgroundMode(LearnerFlagBackgroundMode mode) async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      keyForProfileId(activeId, 'flag_background_mode'),
      mode.storageValue,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.flagBackground);
  }

  Future<String> getSkinTone() async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return 'medium';
    final value = (await SharedPreferences.getInstance()).getString(
      keyForProfileId(activeId, 'skin_tone'),
    );
    return const {'light', 'medium', 'dark'}.contains(value)
        ? value!
        : 'medium';
  }

  Future<void> setSkinTone(String value) async {
    if (!const {'light', 'medium', 'dark'}.contains(value)) {
      throw ArgumentError('Invalid skin tone');
    }
    final activeId = await getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      keyForProfileId(activeId, 'skin_tone'),
      value,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.avatar);
  }

  Future<String> getHairTone() async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return 'dark';
    final value = (await SharedPreferences.getInstance()).getString(
      keyForProfileId(activeId, 'hair_tone'),
    );
    return const {'light', 'dark'}.contains(value) ? value! : 'dark';
  }

  Future<void> setHairTone(String value) async {
    if (!const {'light', 'dark'}.contains(value)) {
      throw ArgumentError('Invalid hair tone');
    }
    final activeId = await getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      keyForProfileId(activeId, 'hair_tone'),
      value,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.avatar);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/authoring_team.dart';
import 'course_ownership_guard.dart';
import 'formal_name_policy.dart';
import 'learner_status_events.dart';

enum LearnerThemeMode {
  light('light', 'Light'),
  dark('dark', 'Dark'),
  defaultMode('default', 'System'),
  dayNight('day_night', 'Day/Night');

  final String storageValue;
  final String label;

  const LearnerThemeMode(this.storageValue, this.label);

  LearnerThemeMode get next => switch (this) {
    LearnerThemeMode.light => LearnerThemeMode.dark,
    LearnerThemeMode.dark => LearnerThemeMode.defaultMode,
    LearnerThemeMode.defaultMode => LearnerThemeMode.dayNight,
    LearnerThemeMode.dayNight => LearnerThemeMode.light,
  };

  static LearnerThemeMode fromStorage(String? value) => values.firstWhere(
    (mode) => mode.storageValue == value,
    orElse: () => LearnerThemeMode.defaultMode,
  );
}

enum LearnerFlagBackgroundMode {
  small('small', 'Small'),
  off('off', 'Off'),
  extended('extended', 'Extended'),
  tinted('tinted', 'Tinted'),
  softInspired('soft_inspired', 'Inspired');

  final String storageValue;
  final String label;

  const LearnerFlagBackgroundMode(this.storageValue, this.label);

  LearnerFlagBackgroundMode get next => switch (this) {
    LearnerFlagBackgroundMode.small => LearnerFlagBackgroundMode.off,
    LearnerFlagBackgroundMode.off => LearnerFlagBackgroundMode.extended,
    LearnerFlagBackgroundMode.extended => LearnerFlagBackgroundMode.tinted,
    LearnerFlagBackgroundMode.tinted => LearnerFlagBackgroundMode.softInspired,
    LearnerFlagBackgroundMode.softInspired => LearnerFlagBackgroundMode.small,
  };

  static LearnerFlagBackgroundMode fromStorage(String? value) =>
      values.firstWhere(
        (mode) => mode.storageValue == value,
        orElse: () => LearnerFlagBackgroundMode.off,
      );
}

class LearnerProfile {
  final String learnerProfileId;
  final String displayName;
  final String? discordHandle;
  final String? screenNameSuffix;

  const LearnerProfile({
    required this.learnerProfileId,
    required this.displayName,
    this.discordHandle,
    this.screenNameSuffix,
  });

  String get presentationName => discordHandle ?? displayName;

  String get editableScreenNameText {
    final suffix = screenNameSuffix;
    if (suffix == null || !displayName.endsWith(' $suffix')) return displayName;
    return displayName.substring(0, displayName.length - suffix.length - 1);
  }

  String encode() => jsonEncode({
    'learnerProfileId': learnerProfileId,
    'displayName': displayName,
    if (discordHandle != null) 'discordHandle': discordHandle,
    if (screenNameSuffix != null) 'screenNameSuffix': screenNameSuffix,
  });

  static LearnerProfile? decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final id = value['learnerProfileId'];
      final name = value['displayName'];
      final discord = value['discordHandle'];
      final suffix = value['screenNameSuffix'];
      if (id is! String ||
          !ProfileService.isValidLearnerProfileId(id) ||
          name is! String ||
          name.trim().isEmpty ||
          name.length > ProfileService.maxNameLength ||
          (discord != null && discord is! String) ||
          (suffix != null &&
              (suffix is! String || !RegExp(r'^\d{5}$').hasMatch(suffix)))) {
        return null;
      }
      return LearnerProfile(
        learnerProfileId: id,
        displayName: name,
        discordHandle: ProfileService.normalizeDiscordHandle(
          discord as String?,
        ),
        screenNameSuffix: suffix as String?,
      );
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

class ProfilePinException implements Exception {
  final String message;

  const ProfilePinException(this.message);

  @override
  String toString() => message;
}

/// Manages opaque local learner identities and profile appearance.
///
/// Build 222 is an intentional clean cut. The v2 registry and active-ID key do
/// not read or migrate the former display-name-based registry or namespaces.
class ProfileService {
  static const profilesKey = 'learner_profiles_v2';
  static const activeProfileIdKey = 'active_learner_profile_id';
  static const adminProfileIdsKey = 'local_admin_profile_ids_v1';
  static const deviceDisplayNameKey = 'qql_device_display_name_v1';
  static const int maxNameLength = 60;
  static const int maxDiscordHandleLength = 33;
  static const String _accessPinKeyBase = 'access_pin_verifier_v1';
  static const String recoveryCredentialKeyBase = 'user_recovery_secret_v1';
  static final Set<String> _sessionUnlockedProfileIds = <String>{};
  static const skinTones = <String>['light', 'medium', 'dark'];
  static const hairTones = <String>['light', 'dark'];
  static final RegExp _profileIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String Function() _idGenerator;
  final int Function(int upperBound) _randomIndex;
  final int Function() _numericSuffixGenerator;
  final List<int> Function(int length) _secureBytes;
  final String Function() _systemDeviceName;

  ProfileService({
    String Function()? idGenerator,
    int Function(int upperBound)? randomIndex,
    int Function()? numericSuffixGenerator,
    List<int> Function(int length)? secureBytes,
    String Function()? systemDeviceName,
  }) : _idGenerator = idGenerator ?? _generateUuidV4,
       _randomIndex = randomIndex ?? Random.secure().nextInt,
       _numericSuffixGenerator =
           numericSuffixGenerator ??
           (() => 10000 + Random.secure().nextInt(90000)),
       _secureBytes =
           secureBytes ??
           ((length) =>
               List<int>.generate(length, (_) => Random.secure().nextInt(256))),
       _systemDeviceName = systemDeviceName ?? (() => Platform.localHostname);

  static void beginAccessSession() => _sessionUnlockedProfileIds.clear();

  static bool isSensitiveCredentialPreferenceSuffix(String suffix) =>
      suffix == _accessPinKeyBase || suffix == recoveryCredentialKeyBase;

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

  static String validateScreenNameText(String name) =>
      FormalNamePolicy.validateUserScreenName(name);

  static bool isFormallyValidDiscordUsername(String? value) {
    final original = value ?? '';
    if (original.isEmpty) return true;
    if (original != original.trim()) return false;
    final username = original.startsWith('@')
        ? original.substring(1)
        : original;
    if (username.length < 2 || username.length > 32) return false;
    if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) return false;
    if (username.startsWith('.') ||
        username.endsWith('.') ||
        username.contains('..')) {
      return false;
    }
    return true;
  }

  static String? normalizeDiscordHandle(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return null;
    final withoutMarker = clean.replaceFirst(RegExp(r'^@+'), '');
    if (withoutMarker.isEmpty || withoutMarker.contains(RegExp(r'[\r\n]'))) {
      throw ArgumentError.value(value, 'discordHandle', 'Invalid Discord name');
    }
    final normalized = '@$withoutMarker';
    if (normalized.length > maxDiscordHandleLength) {
      throw ArgumentError.value(
        value,
        'discordHandle',
        'Discord name exceeds the $maxDiscordHandleLength-character limit',
      );
    }
    return normalized;
  }

  ProfileAvatarAppearance randomAvatarAppearance() => ProfileAvatarAppearance(
    skinTone: skinTones[_randomIndex(skinTones.length)],
    hairTone: hairTones[_randomIndex(hairTones.length)],
  );

  Future<bool> hasDuplicateScreenName(
    String displayName, {
    String? excludingProfileId,
  }) async {
    final key = FormalNamePolicy.comparisonKey(displayName);
    return (await getProfileRecords()).any(
      (profile) =>
          profile.learnerProfileId != excludingProfileId &&
          FormalNamePolicy.comparisonKey(profile.displayName) == key,
    );
  }

  Future<String> generateAvailableScreenNameSuffix(
    String screenNameText,
  ) async {
    final text = validateScreenNameText(screenNameText);
    for (var attempt = 0; attempt < 100000; attempt++) {
      final value = _numericSuffixGenerator();
      if (value < 10000 || value > 99999) {
        throw StateError(
          'Generated Screen Name suffix must contain five digits.',
        );
      }
      final suffix = value.toString();
      if (!await hasDuplicateScreenName('$text $suffix')) return suffix;
    }
    throw StateError('No available Screen Name suffix could be generated.');
  }

  String newScreenNameSuffixCandidate() {
    final value = _numericSuffixGenerator();
    if (value < 10000 || value > 99999) {
      throw StateError(
        'Generated Screen Name suffix must contain five digits.',
      );
    }
    return value.toString();
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
    if (!profiles.any((profile) => profile.learnerProfileId == activeId)) {
      return null;
    }
    if (await hasAccessPin(activeId) &&
        !_sessionUnlockedProfileIds.contains(activeId)) {
      return null;
    }
    return activeId;
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
    String? discordHandle,
    String? skinTone,
    String? hairTone,
    String? learnerProfileId,
    String? screenNameSuffix,
    String? accessPin,
    bool generateScreenNameSuffix = true,
  }) async {
    final initialAppearance = skinTone == null || hairTone == null
        ? randomAvatarAppearance()
        : null;
    final initialSkinTone = skinTone ?? initialAppearance!.skinTone;
    final initialHairTone = hairTone ?? initialAppearance!.hairTone;
    if (!skinTones.contains(initialSkinTone)) {
      throw ArgumentError('Invalid avatar skin color');
    }
    if (!hairTones.contains(initialHairTone)) {
      throw ArgumentError('Invalid avatar hair color');
    }
    final screenNameText = generateScreenNameSuffix
        ? validateScreenNameText(displayName)
        : validateDisplayName(displayName);
    final normalizedDiscord = normalizeDiscordHandle(discordHandle);
    final id = learnerProfileId ?? _idGenerator();
    if (!isValidLearnerProfileId(id)) {
      throw ArgumentError.value(id, 'learnerProfileId', 'Invalid profile ID');
    }
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    if (profiles.any((profile) => profile.learnerProfileId == id)) {
      throw ArgumentError.value(id, 'learnerProfileId', 'Profile ID exists');
    }
    String? suffix;
    var clean = screenNameText;
    if (generateScreenNameSuffix) {
      suffix = screenNameSuffix;
      if (suffix == null || !RegExp(r'^\d{5}$').hasMatch(suffix)) {
        suffix = await generateAvailableScreenNameSuffix(screenNameText);
      } else if (profiles.any(
        (profile) =>
            FormalNamePolicy.comparisonKey(profile.displayName) ==
            FormalNamePolicy.comparisonKey('$screenNameText $suffix'),
      )) {
        suffix = await generateAvailableScreenNameSuffix(screenNameText);
      }
      clean = '$screenNameText $suffix';
    }
    final profile = LearnerProfile(
      learnerProfileId: id,
      displayName: clean,
      discordHandle: normalizedDiscord,
      screenNameSuffix: suffix,
    );
    await prefs.setStringList(
      profilesKey,
      [...profiles, profile].map((value) => value.encode()).toList(),
    );
    await prefs.setString(activeProfileIdKey, id);
    _sessionUnlockedProfileIds.add(id);
    final admins = await getAdminProfileIds();
    if (admins.isEmpty) {
      await prefs.setStringList(adminProfileIdsKey, [id]);
    }
    final prefix = prefixForProfileId(id);
    await prefs.setString('${prefix}skin_tone', initialSkinTone);
    await prefs.setString('${prefix}hair_tone', initialHairTone);
    if (accessPin != null && accessPin.isNotEmpty) {
      await _writePinVerifier(prefs, id, accessPin);
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    return profile;
  }

  Future<void> addProfile(
    String name, {
    String? discordHandle,
    String? skinTone,
    String? hairTone,
  }) async {
    await createProfile(
      name,
      discordHandle: discordHandle,
      skinTone: skinTone,
      hairTone: hairTone,
      generateScreenNameSuffix: false,
    );
  }

  Future<void> replaceProfileRecord(LearnerProfile replacement) async {
    final suffix = replacement.screenNameSuffix;
    final clean = suffix == null
        ? validateDisplayName(replacement.displayName)
        : '${validateScreenNameText(replacement.editableScreenNameText)} $suffix';
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
      discordHandle: normalizeDiscordHandle(replacement.discordHandle),
      screenNameSuffix: suffix,
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

  Future<LearnerProfile> renameProfileText({
    required String learnerProfileId,
    required String screenNameText,
    String? discordHandle,
  }) async {
    final current = await getProfileById(learnerProfileId);
    if (current == null) {
      throw StateError('The learner profile is unavailable.');
    }
    final text = validateScreenNameText(screenNameText);
    final suffix = current.screenNameSuffix;
    final replacement = LearnerProfile(
      learnerProfileId: learnerProfileId,
      displayName: suffix == null ? text : '$text $suffix',
      discordHandle: normalizeDiscordHandle(discordHandle),
      screenNameSuffix: suffix,
    );
    await replaceProfileRecord(replacement);
    return replacement;
  }

  Future<void> setActiveProfileById(
    String learnerProfileId, {
    String? accessPin,
  }) async {
    if (await getProfileById(learnerProfileId) == null) {
      throw ArgumentError.value(
        learnerProfileId,
        'learnerProfileId',
        'Unknown learner profile',
      );
    }
    if (await hasAccessPin(learnerProfileId) &&
        !await verifyAccessPin(learnerProfileId, accessPin ?? '')) {
      throw const ProfilePinException('The Access PIN is incorrect.');
    }
    await (await SharedPreferences.getInstance()).setString(
      activeProfileIdKey,
      learnerProfileId,
    );
    _sessionUnlockedProfileIds.add(learnerProfileId);
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
    final activeId = await getActiveProfileId();
    if (activeId != null) _sessionUnlockedProfileIds.remove(activeId);
    await (await SharedPreferences.getInstance()).remove(activeProfileIdKey);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> deleteProfileById(
    String learnerProfileId, {
    String? actorProfileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    if (!profiles.any(
      (profile) => profile.learnerProfileId == learnerProfileId,
    )) {
      return;
    }
    final actor = actorProfileId ?? await getActiveProfileId();
    if (actor == null || (actor != learnerProfileId && !await isAdmin(actor))) {
      throw StateError(
        'You may delete only your own profile unless you are an admin.',
      );
    }
    final admins = await getAdminProfileIds();
    if (admins.contains(learnerProfileId) && admins.length == 1) {
      throw StateError('QQL must always have at least one admin.');
    }
    CourseOwnershipGuard.ensureProfileDoesNotOwnCourses(
      prefs,
      learnerProfileId,
    );
    await _removeProfileFromAuthoringTeams(prefs, learnerProfileId);
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
    await prefs.setStringList(
      adminProfileIdsKey,
      admins.where((id) => id != learnerProfileId).toList(),
    );
    _sessionUnlockedProfileIds.remove(learnerProfileId);
    if (prefs.getString(activeProfileIdKey) == learnerProfileId) {
      if (remaining.isEmpty ||
          prefs.containsKey(
            keyForProfileId(
              remaining.first.learnerProfileId,
              _accessPinKeyBase,
            ),
          )) {
        await prefs.remove(activeProfileIdKey);
      } else {
        await prefs.setString(
          activeProfileIdKey,
          remaining.first.learnerProfileId,
        );
        _sessionUnlockedProfileIds.add(remaining.first.learnerProfileId);
      }
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> _removeProfileFromAuthoringTeams(
    SharedPreferences prefs,
    String learnerProfileId,
  ) async {
    final raw = prefs.getString(AuthoringTeam.storageKey);
    if (raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((item) => item is! Map)) {
      throw const FormatException('Stored authoring-team registry is invalid.');
    }
    var changed = false;
    final teams = decoded.map((item) {
      final team = AuthoringTeam.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      if (!team.hasMember(learnerProfileId)) return team;
      if (team.hasLead(learnerProfileId) && team.leadProfileIds.length == 1) {
        throw StateError(
          'This profile is the final Team Leader of ${team.displayName}. '
          'Promote another member before deleting the profile.',
        );
      }
      changed = true;
      return team.copyWith(
        memberProfileIds: team.memberProfileIds.where(
          (id) => id != learnerProfileId,
        ),
        leadProfileIds: team.leadProfileIds.where(
          (id) => id != learnerProfileId,
        ),
      );
    }).toList();
    if (!changed) return;
    final encoded = jsonEncode(teams.map((team) => team.toJson()).toList());
    if (!await prefs.setString(AuthoringTeam.storageKey, encoded) ||
        prefs.getString(AuthoringTeam.storageKey) != encoded) {
      throw StateError('Verified authoring-team storage write failed.');
    }
  }

  Future<void> deleteProfile(String idOrDisplayName) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile != null) await deleteProfileById(profile.learnerProfileId);
  }

  Future<Set<String>> getAdminProfileIds() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfileRecords();
    final existingIds = profiles
        .map((profile) => profile.learnerProfileId)
        .toSet();
    final stored = prefs.getStringList(adminProfileIdsKey) ?? const <String>[];
    final admins = stored.where(existingIds.contains).toSet();
    if (admins.isEmpty && profiles.isNotEmpty) {
      admins.add(profiles.first.learnerProfileId);
    }
    if (stored.toSet().difference(admins).isNotEmpty ||
        admins.difference(stored.toSet()).isNotEmpty) {
      await prefs.setStringList(adminProfileIdsKey, admins.toList());
    }
    return admins;
  }

  Future<bool> isAdmin(String learnerProfileId) async =>
      (await getAdminProfileIds()).contains(learnerProfileId);

  Future<void> promoteToAdmin({
    required String actorProfileId,
    required String targetProfileId,
  }) async {
    if (!await isAdmin(actorProfileId)) {
      throw StateError('Only an admin may promote another admin.');
    }
    if (await getProfileById(targetProfileId) == null) {
      throw StateError('The learner profile is unavailable.');
    }
    final admins = await getAdminProfileIds();
    admins.add(targetProfileId);
    await (await SharedPreferences.getInstance()).setStringList(
      adminProfileIdsKey,
      admins.toList(),
    );
  }

  Future<void> relinquishAdmin(String actorProfileId) async {
    final admins = await getAdminProfileIds();
    if (!admins.contains(actorProfileId)) {
      throw StateError('This profile is not an admin.');
    }
    if (admins.length == 1) {
      throw StateError('QQL must always have at least one admin.');
    }
    admins.remove(actorProfileId);
    await (await SharedPreferences.getInstance()).setStringList(
      adminProfileIdsKey,
      admins.toList(),
    );
  }

  Future<bool> hasAccessPin(String learnerProfileId) async =>
      (await SharedPreferences.getInstance()).containsKey(
        keyForProfileId(learnerProfileId, _accessPinKeyBase),
      );

  Future<bool> verifyAccessPin(String learnerProfileId, String pin) async {
    final value = (await SharedPreferences.getInstance()).getString(
      keyForProfileId(learnerProfileId, _accessPinKeyBase),
    );
    if (value == null) return true;
    final parts = value.split(':');
    if (parts.length != 3 || parts.first != 'v1') return false;
    final candidate = sha256.convert([
      ...base64Url.decode(base64Url.normalize(parts[1])),
      ...utf8.encode(pin),
    ]).toString();
    return candidate == parts[2];
  }

  Future<void> setOwnAccessPin({
    required String actorProfileId,
    required String? pin,
  }) async {
    if (await getProfileById(actorProfileId) == null) {
      throw StateError('The learner profile is unavailable.');
    }
    final prefs = await SharedPreferences.getInstance();
    if (pin == null || pin.isEmpty) {
      await prefs.remove(keyForProfileId(actorProfileId, _accessPinKeyBase));
      return;
    }
    await _writePinVerifier(prefs, actorProfileId, pin);
    _sessionUnlockedProfileIds.add(actorProfileId);
  }

  Future<void> resetAccessPinAsAdmin({
    required String actorProfileId,
    required String targetProfileId,
  }) async {
    if (actorProfileId == targetProfileId || !await isAdmin(actorProfileId)) {
      throw StateError('Only an admin may reset another learner’s Access PIN.');
    }
    if (await getProfileById(targetProfileId) == null) {
      throw StateError('The learner profile is unavailable.');
    }
    await (await SharedPreferences.getInstance()).remove(
      keyForProfileId(targetProfileId, _accessPinKeyBase),
    );
  }

  Future<void> _writePinVerifier(
    SharedPreferences prefs,
    String learnerProfileId,
    String pin,
  ) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError.value(
        pin,
        'pin',
        'Access PIN must contain exactly 4 digits.',
      );
    }
    final salt = _secureBytes(16);
    final encodedSalt = base64Url.encode(salt);
    final digest = sha256.convert([...salt, ...utf8.encode(pin)]).toString();
    await prefs.setString(
      keyForProfileId(learnerProfileId, _accessPinKeyBase),
      'v1:$encodedSalt:$digest',
    );
  }

  Future<String> getDeviceDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(deviceDisplayNameKey)?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    final system = _systemDeviceName().trim();
    return system.isEmpty ? 'This device' : system;
  }

  Future<void> setDeviceDisplayName({
    required String actorProfileId,
    required String displayName,
  }) async {
    if (!await isAdmin(actorProfileId)) {
      throw StateError('Only an admin may change the QQL device name.');
    }
    final name = FormalNamePolicy.validatePresentationLabel(
      displayName,
      parameterName: 'deviceName',
      maximumLength: 60,
    );
    await (await SharedPreferences.getInstance()).setString(
      deviceDisplayNameKey,
      name,
    );
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

  Future<LearnerFlagBackgroundMode> getFlagBackgroundMode(
    String courseId,
  ) async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return LearnerFlagBackgroundMode.off;
    return getFlagBackgroundModeForProfile(activeId, courseId);
  }

  Future<LearnerFlagBackgroundMode> getFlagBackgroundModeForProfile(
    String idOrDisplayName,
    String courseId,
  ) async {
    final profile = await _resolveProfile(idOrDisplayName);
    if (profile == null) return LearnerFlagBackgroundMode.off;
    final prefs = await SharedPreferences.getInstance();
    return LearnerFlagBackgroundMode.fromStorage(
      prefs.getString(
        keyForProfileId(
          profile.learnerProfileId,
          _flagBackgroundKeyBase(courseId),
        ),
      ),
    );
  }

  Future<void> setFlagBackgroundMode(
    String courseId,
    LearnerFlagBackgroundMode mode,
  ) async {
    final activeId = await getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      keyForProfileId(activeId, _flagBackgroundKeyBase(courseId)),
      mode.storageValue,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.flagBackground);
  }

  static String _flagBackgroundKeyBase(String courseId) {
    final digest = sha256.convert(utf8.encode(courseId.trim()));
    return 'flag_background_mode_course_$digest';
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

import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';
import 'learner_status_events.dart';

/// Persistent device-level settings.
///
/// Learner-specific appearance lives in ProfileService. TTS skipping is a
/// device preference because it changes which exercise types the app presents.
class SettingsService {
  static const _ttsEnabledKey = 'tts_enabled';
  static const _ttsVoicePreferenceKey = 'tts_voice_preference';
  static const _skipTtsExercisesKey = 'skip_tts_exercises';
  static const _soundEffectsKey = 'sound_effects_enabled';
  static const _startupAnimationKey =
      'startup_animation_enabled'; // Legacy key retained for compatibility.
  static const _oneTimeNoticePrefix = 'one_time_notice_seen_';
  static const _courseEditorUnlockedKey = 'course_editor_unlocked';
  static const _audioOrphanCheckKey = 'audio_orphan_check_last_';
  static const _lastSelectedCourseKey = 'last_selected_course_code';
  static const _automaticUpdateCheckKey = 'automatic_update_check_enabled';
  static const _updateLastCheckedKey = 'update_last_checked_at';

  Future<bool> isAutomaticUpdateCheckEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(
        _automaticUpdateCheckKey,
      ) ??
      false;
  Future<void> setAutomaticUpdateCheckEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(
        _automaticUpdateCheckKey,
        enabled,
      );

  Future<DateTime?> getUpdateLastCheckedAt() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _updateLastCheckedKey,
    );
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setUpdateLastCheckedAt(DateTime value) async =>
      (await SharedPreferences.getInstance()).setString(
        _updateLastCheckedKey,
        value.toIso8601String(),
      );

  Future<String?> getLastSelectedCourseCode() async {
    final value = (await SharedPreferences.getInstance())
        .getString(_lastSelectedCourseKey)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setLastSelectedCourseCode(String courseCode) async {
    await (await SharedPreferences.getInstance()).setString(
      _lastSelectedCourseKey,
      courseCode.trim(),
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeCourse);
  }

  Future<String?> getLastVisitedChapterId(String courseId) async {
    final key = await ProfileService().key(
      'last_chapter_${Uri.encodeComponent(courseId.trim())}',
    );
    final value = (await SharedPreferences.getInstance())
        .getString(key)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setLastVisitedChapterId(
    String courseId,
    String chapterId,
  ) async {
    final key = await ProfileService().key(
      'last_chapter_${Uri.encodeComponent(courseId.trim())}',
    );
    await (await SharedPreferences.getInstance()).setString(
      key,
      chapterId.trim(),
    );
  }

  Future<bool> isIddqdModeEnabled(String courseId) async {
    final key = await ProfileService().key(
      'iddqd_${Uri.encodeComponent(courseId.trim())}',
    );
    return (await SharedPreferences.getInstance()).getBool(key) ?? false;
  }

  Future<void> setIddqdModeEnabled(String courseId, bool enabled) async {
    final key = await ProfileService().key(
      'iddqd_${Uri.encodeComponent(courseId.trim())}',
    );
    await (await SharedPreferences.getInstance()).setBool(key, enabled);
  }

  Future<String?> getLastVisitedTopicId(String courseId) async {
    final key = await ProfileService().key(
      'last_topic_${Uri.encodeComponent(courseId.trim())}',
    );
    final value = (await SharedPreferences.getInstance())
        .getString(key)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setLastVisitedTopicId(String courseId, String topicId) async {
    final key = await ProfileService().key(
      'last_topic_${Uri.encodeComponent(courseId.trim())}',
    );
    await (await SharedPreferences.getInstance()).setString(
      key,
      topicId.trim(),
    );
  }

  Future<bool> isTtsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_ttsEnabledKey) ?? true;
  Future<void> setTtsEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(_ttsEnabledKey, enabled);

  /// Voice gender is a preference rather than a hard requirement. If a
  /// platform exposes no matching voice, TTS falls back to another compatible
  /// voice in the requested language family.
  Future<String> getTtsVoicePreference() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _ttsVoicePreferenceKey,
    );
    return const {'system', 'female', 'male'}.contains(value)
        ? value!
        : 'system';
  }

  Future<void> setTtsVoicePreference(String value) async {
    if (!const {'system', 'female', 'male'}.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Invalid TTS voice preference');
    }
    await (await SharedPreferences.getInstance()).setString(
      _ttsVoicePreferenceKey,
      value,
    );
  }

  Future<bool> shouldSkipTtsExercises() async =>
      (await SharedPreferences.getInstance()).getBool(_skipTtsExercisesKey) ??
      false;
  Future<void> setSkipTtsExercises(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(
        _skipTtsExercisesKey,
        value,
      );

  Future<bool> areSoundEffectsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_soundEffectsKey) ?? true;
  Future<void> setSoundEffectsEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(
        _soundEffectsKey,
        enabled,
      );

  Future<bool> isStartupAnimationEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_startupAnimationKey) ??
      true;
  Future<void> setStartupAnimationEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(
        _startupAnimationKey,
        enabled,
      );

  /// Global animation preference. Uses the legacy startup key so existing users
  /// keep their choice after the setting was broadened from startup-only.
  Future<bool> areAnimationsEnabled() => isStartupAnimationEnabled();
  Future<void> setAnimationsEnabled(bool enabled) =>
      setStartupAnimationEnabled(enabled);

  Future<bool> hasSeenOneTimeNotice(String id) async =>
      (await SharedPreferences.getInstance()).getBool(
        '$_oneTimeNoticePrefix$id',
      ) ??
      false;
  Future<void> markOneTimeNoticeSeen(String id) async =>
      (await SharedPreferences.getInstance()).setBool(
        '$_oneTimeNoticePrefix$id',
        true,
      );
  Future<void> resetOneTimeNotices() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs
            .getKeys()
            .where((k) => k.startsWith(_oneTimeNoticePrefix))
            .toList()) {
      await prefs.remove(key);
    }
  }

  Future<bool> isCourseEditorUnlocked() async =>
      (await SharedPreferences.getInstance()).getBool(
        _courseEditorUnlockedKey,
      ) ??
      false;
  Future<void> setCourseEditorUnlocked(bool unlocked) async =>
      (await SharedPreferences.getInstance()).setBool(
        _courseEditorUnlockedKey,
        unlocked,
      );

  Future<bool> isAudioOrphanCheckDue(String courseCode) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      '$_audioOrphanCheckKey${courseCode.toUpperCase()}',
    );
    final last = raw == null ? null : DateTime.tryParse(raw);
    return last == null ||
        DateTime.now().difference(last) >= const Duration(days: 7);
  }

  Future<void> markAudioOrphanCheckRun(String courseCode) async =>
      (await SharedPreferences.getInstance()).setString(
        '$_audioOrphanCheckKey${courseCode.toUpperCase()}',
        DateTime.now().toIso8601String(),
      );

  Future<bool> shouldShowCourseUpdate(
    String courseCode,
    String contentRevision,
  ) async {
    final key = await ProfileService().key(
      'course_update_seen_${courseCode.toUpperCase()}',
    );
    final seen = (await SharedPreferences.getInstance()).getString(key);
    return seen != contentRevision;
  }

  Future<void> markCourseUpdateSeen(
    String courseCode,
    String contentRevision,
  ) async {
    final key = await ProfileService().key(
      'course_update_seen_${courseCode.toUpperCase()}',
    );
    await (await SharedPreferences.getInstance()).setString(
      key,
      contentRevision,
    );
  }

  Future<int> getWeeklyXpTarget() async =>
      (await SharedPreferences.getInstance()).getInt('weekly_xp_target') ??
      1000;
  Future<void> setWeeklyXpTarget(int value) async {
    if (value < 1)
      throw ArgumentError.value(
        value,
        'value',
        'Weekly XP target must be positive',
      );
    await (await SharedPreferences.getInstance()).setInt(
      'weekly_xp_target',
      value,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.weeklyGoal);
  }

  Future<bool> isCourseEditorLocked(String courseId) async =>
      (await SharedPreferences.getInstance()).getBool(
        'course_editor_locked_${courseId.toUpperCase()}',
      ) ??
      true;
  Future<void> setCourseEditorLocked(String courseId, bool locked) async =>
      (await SharedPreferences.getInstance()).setBool(
        'course_editor_locked_${courseId.toUpperCase()}',
        locked,
      );
}

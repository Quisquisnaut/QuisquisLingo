import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';
import 'learner_status_events.dart';

enum LearnerIddqdMode {
  off('Off'),
  on('On'),
  viewOnly('View Only');

  final String label;

  const LearnerIddqdMode(this.label);

  LearnerIddqdMode get next => switch (this) {
    LearnerIddqdMode.off => LearnerIddqdMode.on,
    LearnerIddqdMode.on => LearnerIddqdMode.viewOnly,
    LearnerIddqdMode.viewOnly => LearnerIddqdMode.off,
  };

  bool get bypassesLocks => this != LearnerIddqdMode.off;
}

enum LearnerLessonExpansionMode {
  expanded('Expanded', 'expanded'),
  collapseCompleted('Collapse completed', 'collapse_completed'),
  focused('Focused', 'focused');

  const LearnerLessonExpansionMode(this.label, this.storageValue);

  final String label;
  final String storageValue;

  LearnerLessonExpansionMode get next => switch (this) {
    LearnerLessonExpansionMode.expanded =>
      LearnerLessonExpansionMode.collapseCompleted,
    LearnerLessonExpansionMode.collapseCompleted =>
      LearnerLessonExpansionMode.focused,
    LearnerLessonExpansionMode.focused => LearnerLessonExpansionMode.expanded,
  };

  static LearnerLessonExpansionMode fromStorage(String? value) =>
      LearnerLessonExpansionMode.values.firstWhere(
        (mode) => mode.storageValue == value,
        orElse: () => LearnerLessonExpansionMode.expanded,
      );
}

enum CourseEditorMode {
  locked('Locked', 'locked'),
  viewOnly('View only', 'view'),
  inspection('Inspection mode', 'inspection'),
  edit('Edit', 'edit');

  const CourseEditorMode(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static CourseEditorMode fromStorage(String? value) =>
      CourseEditorMode.values.firstWhere(
        (mode) => mode.storageValue == value,
        orElse: () => CourseEditorMode.viewOnly,
      );
}

/// Persistent device and learner-scoped settings.
///
/// Learner-specific appearance lives in ProfileService. Learner audio exercise
/// enablement and the last active course are learner-scoped; recent courses
/// remain device-wide.
class SettingsService {
  static const _ttsEnabledKey = 'tts_enabled';
  static const _ttsVoicePreferenceKey = 'tts_voice_preference';
  static const _audioExercisesEnabledKey = 'audio_exercises_enabled';
  static const _soundEffectsKey = 'sound_effects_enabled';
  static const _startupAnimationKey =
      'startup_animation_enabled'; // Legacy key retained for compatibility.
  static const _oneTimeNoticePrefix = 'one_time_notice_seen_';
  static const _courseEditorUnlockedKey = 'course_editor_unlocked';
  static const _courseEditorModeKeyPrefix = 'course_editor_mode_';
  static const _audioOrphanCheckKey = 'audio_orphan_check_last_';
  static const _lastSelectedCourseKeyBase = 'last_selected_course_code';
  static const _recentCourseRefsKey = 'recent_course_refs';
  static const _hiddenCourseKeyPrefix = 'course_hidden_';
  static const _lessonExpansionModeKeyPrefix = 'lesson_expansion_mode_';
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
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return null;
    final key = profiles.keyForProfileId(activeId, _lastSelectedCourseKeyBase);
    final value = (await SharedPreferences.getInstance())
        .getString(key)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setLastSelectedCourseCode(String courseCode) async {
    final normalized = courseCode.trim();
    final preferences = await SharedPreferences.getInstance();
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId != null) {
      final key = profiles.keyForProfileId(
        activeId,
        _lastSelectedCourseKeyBase,
      );
      await preferences.setString(key, normalized);
    }
    final recent = (preferences.getStringList(_recentCourseRefsKey) ?? [])
      ..remove(normalized)
      ..insert(0, normalized);
    await preferences.setStringList(
      _recentCourseRefsKey,
      recent.take(4).toList(),
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeCourse);
  }

  Future<List<String>> getRecentCourseRefs() async => List.unmodifiable(
    (await SharedPreferences.getInstance()).getStringList(
          _recentCourseRefsKey,
        ) ??
        const <String>[],
  );

  static String _coursePreferenceKey(String prefix, String courseId) =>
      '$prefix${Uri.encodeComponent(courseId.trim())}';

  Future<bool> isCourseHidden(String courseId) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return false;
    return (await SharedPreferences.getInstance()).getBool(
          profiles.keyForProfileId(
            activeId,
            _coursePreferenceKey(_hiddenCourseKeyPrefix, courseId),
          ),
        ) ??
        false;
  }

  Future<Set<String>> getHiddenCourseIds(Iterable<String> courseIds) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return const <String>{};
    final preferences = await SharedPreferences.getInstance();
    return {
      for (final courseId in courseIds.map((id) => id.trim()).toSet())
        if (courseId.isNotEmpty &&
            (preferences.getBool(
                  profiles.keyForProfileId(
                    activeId,
                    _coursePreferenceKey(_hiddenCourseKeyPrefix, courseId),
                  ),
                ) ??
                false))
          courseId,
    };
  }

  Future<void> setCourseHidden(String courseId, bool hidden) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final key = profiles.keyForProfileId(
      activeId,
      _coursePreferenceKey(_hiddenCourseKeyPrefix, courseId),
    );
    if (hidden) {
      await preferences.setBool(key, true);
    } else {
      await preferences.remove(key);
    }
  }

  Future<LearnerLessonExpansionMode> getLessonExpansionMode(
    String courseId,
  ) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return LearnerLessonExpansionMode.expanded;
    return LearnerLessonExpansionMode.fromStorage(
      (await SharedPreferences.getInstance()).getString(
        profiles.keyForProfileId(
          activeId,
          _coursePreferenceKey(_lessonExpansionModeKeyPrefix, courseId),
        ),
      ),
    );
  }

  Future<void> setLessonExpansionMode(
    String courseId,
    LearnerLessonExpansionMode mode,
  ) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      profiles.keyForProfileId(
        activeId,
        _coursePreferenceKey(_lessonExpansionModeKeyPrefix, courseId),
      ),
      mode.storageValue,
    );
  }

  Future<String> _iddqdKey(String courseId) =>
      ProfileService().key('iddqd_${Uri.encodeComponent(courseId.trim())}');

  Future<LearnerIddqdMode> getIddqdMode(String courseId) async {
    final value = (await SharedPreferences.getInstance()).get(
      await _iddqdKey(courseId),
    );
    return switch (value) {
      true => LearnerIddqdMode.on,
      'view_only' => LearnerIddqdMode.viewOnly,
      _ => LearnerIddqdMode.off,
    };
  }

  Future<void> setIddqdMode(String courseId, LearnerIddqdMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _iddqdKey(courseId);
    switch (mode) {
      case LearnerIddqdMode.off:
        await preferences.setBool(key, false);
      case LearnerIddqdMode.on:
        await preferences.setBool(key, true);
      case LearnerIddqdMode.viewOnly:
        await preferences.setString(key, 'view_only');
    }
  }

  Future<bool> isIddqdModeEnabled(String courseId) async {
    return (await getIddqdMode(courseId)).bypassesLocks;
  }

  Future<void> setIddqdModeEnabled(String courseId, bool enabled) async {
    await setIddqdMode(
      courseId,
      enabled ? LearnerIddqdMode.on : LearnerIddqdMode.off,
    );
  }

  Future<String?> getLastVisitedLessonId(String courseId) async {
    final key = await ProfileService().key(
      'last_lesson_${Uri.encodeComponent(courseId.trim())}',
    );
    final value = (await SharedPreferences.getInstance())
        .getString(key)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setLastVisitedLessonId(String courseId, String lessonId) async {
    final key = await ProfileService().key(
      'last_lesson_${Uri.encodeComponent(courseId.trim())}',
    );
    await (await SharedPreferences.getInstance()).setString(
      key,
      lessonId.trim(),
    );
  }

  Future<bool> isTtsEnabled() async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return false;
    return (await SharedPreferences.getInstance()).getBool(
          profiles.keyForProfileId(activeId, _ttsEnabledKey),
        ) ??
        false;
  }

  Future<void> setTtsEnabled(bool enabled) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setBool(
      profiles.keyForProfileId(activeId, _ttsEnabledKey),
      enabled,
    );
  }

  /// Voice gender is a preference rather than a hard requirement. If a
  /// platform exposes no matching voice, TTS falls back to another compatible
  /// voice in the requested language family.
  Future<String> getTtsVoicePreference() async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return 'system';
    final value = (await SharedPreferences.getInstance()).getString(
      profiles.keyForProfileId(activeId, _ttsVoicePreferenceKey),
    );
    return const {'system', 'female', 'male'}.contains(value)
        ? value!
        : 'system';
  }

  Future<void> setTtsVoicePreference(String value) async {
    if (!const {'system', 'female', 'male'}.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Invalid TTS voice preference');
    }
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      profiles.keyForProfileId(activeId, _ttsVoicePreferenceKey),
      value,
    );
  }

  Future<bool> areAudioExercisesEnabled() async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return false;
    return (await SharedPreferences.getInstance()).getBool(
          profiles.keyForProfileId(activeId, _audioExercisesEnabledKey),
        ) ??
        false;
  }

  Future<void> setAudioExercisesEnabled(bool value) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setBool(
      profiles.keyForProfileId(activeId, _audioExercisesEnabledKey),
      value,
    );
  }

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
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    final profileNoticePrefix = activeId == null
        ? null
        : profiles.keyForProfileId(activeId, _oneTimeNoticePrefix);
    for (final key
        in prefs
            .getKeys()
            .where(
              (k) =>
                  k.startsWith(_oneTimeNoticePrefix) ||
                  (profileNoticePrefix != null &&
                      k.startsWith(profileNoticePrefix)),
            )
            .toList()) {
      await prefs.remove(key);
    }
  }

  String _courseEditorViewNoticeId(String courseId) =>
      'course_editor_view_${Uri.encodeComponent(courseId.trim())}';

  Future<bool> hasSeenCourseEditorViewNotice(String courseId) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return false;
    return (await SharedPreferences.getInstance()).getBool(
          profiles.keyForProfileId(
            activeId,
            '$_oneTimeNoticePrefix${_courseEditorViewNoticeId(courseId)}',
          ),
        ) ??
        false;
  }

  Future<void> markCourseEditorViewNoticeSeen(String courseId) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setBool(
      profiles.keyForProfileId(
        activeId,
        '$_oneTimeNoticePrefix${_courseEditorViewNoticeId(courseId)}',
      ),
      true,
    );
  }

  Future<bool> isCourseEditorUnlocked() async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return false;
    return (await SharedPreferences.getInstance()).getBool(
          profiles.keyForProfileId(activeId, _courseEditorUnlockedKey),
        ) ??
        false;
  }

  Future<void> setCourseEditorUnlocked(bool unlocked) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final key = profiles.keyForProfileId(activeId, _courseEditorUnlockedKey);
    if (unlocked) {
      await preferences.setBool(key, true);
    } else {
      await preferences.remove(key);
    }
  }

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
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'value',
        'Weekly XP target must be positive',
      );
    }
    await (await SharedPreferences.getInstance()).setInt(
      'weekly_xp_target',
      value,
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.weeklyGoal);
  }

  Future<CourseEditorMode> getCourseEditorMode(String courseId) async {
    final preferences = await SharedPreferences.getInstance();
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId != null) {
      final stored = preferences.getString(
        profiles.keyForProfileId(
          activeId,
          _coursePreferenceKey(_courseEditorModeKeyPrefix, courseId),
        ),
      );
      if (stored != null) return CourseEditorMode.fromStorage(stored);
    }
    // Preserve a user's former two-state choice once. A fresh course/editor
    // has no legacy value and therefore starts in View only.
    final legacy = preferences.getBool(
      'course_editor_locked_${courseId.toUpperCase()}',
    );
    return switch (legacy) {
      true => CourseEditorMode.locked,
      false => CourseEditorMode.edit,
      null => CourseEditorMode.viewOnly,
    };
  }

  Future<void> setCourseEditorMode(
    String courseId,
    CourseEditorMode mode,
  ) async {
    final profiles = ProfileService();
    final activeId = await profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      profiles.keyForProfileId(
        activeId,
        _coursePreferenceKey(_courseEditorModeKeyPrefix, courseId),
      ),
      mode.storageValue,
    );
  }

  /// Compatibility facade for older callers and tests.
  Future<bool> isCourseEditorLocked(String courseId) async =>
      await getCourseEditorMode(courseId) == CourseEditorMode.locked;

  /// Compatibility facade for the former two-state lock. Unlocking maps to the
  /// old editable behavior; the QQL 231 UI uses [setCourseEditorMode].
  Future<void> setCourseEditorLocked(String courseId, bool locked) async {
    final profiles = ProfileService();
    if (await profiles.getActiveProfileId() != null) {
      await setCourseEditorMode(
        courseId,
        locked ? CourseEditorMode.locked : CourseEditorMode.edit,
      );
      return;
    }
    // Headless tools and older callers can legitimately run before a learner
    // profile exists. Keep their former global preference path functional;
    // normal signed-in app use is stored through the profile-scoped mode key.
    await (await SharedPreferences.getInstance()).setBool(
      'course_editor_locked_${courseId.toUpperCase()}',
      locked,
    );
  }
}

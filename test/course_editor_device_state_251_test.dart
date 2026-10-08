import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_editor_device_state.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ownerId = '00000000-0000-4000-8000-000000002511';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        LearnerProfile(
          learnerProfileId: _ownerId,
          displayName: 'Owner',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _ownerId,
    });
  });

  test('device state writes mode and View-only notice immediately', () async {
    final state = CourseEditorDeviceState();
    final preferences = await SharedPreferences.getInstance();
    const courseId = 'owner:course';
    const modeKey =
        'learner_00000000-0000-4000-8000-000000002511_course_editor_mode_owner%3Acourse';
    const noticeKey =
        'learner_00000000-0000-4000-8000-000000002511_one_time_notice_seen_course_editor_view_owner%3Acourse';

    expect(
      await state.openingMode(courseId, canEditOriginal: true),
      CourseEditorMode.viewOnly,
    );
    await state.setMode(courseId, CourseEditorMode.edit);
    expect(preferences.getString(modeKey), 'edit');
    expect(
      await state.openingMode(courseId, canEditOriginal: false),
      CourseEditorMode.viewOnly,
    );
    expect(preferences.getString(modeKey), 'edit');
    expect(await state.hasSeenViewOnlyNotice(courseId), isFalse);
    await state.markViewOnlyNoticeSeen(courseId);
    expect(preferences.getBool(noticeKey), isTrue);
  });

  test(
    'automatic orphan check records only after the callback completes',
    () async {
      final state = CourseEditorDeviceState();
      final preferences = await SharedPreferences.getInstance();
      final entered = Completer<void>();
      final finish = Completer<void>();

      final run = state.runAutomaticOrphanCheck(
        courseCode: 'it',
        canEditOriginal: true,
        mode: CourseEditorMode.edit,
        check: () async {
          entered.complete();
          await finish.future;
        },
      );
      await entered.future;
      expect(preferences.getString('audio_orphan_check_last_IT'), isNull);
      finish.complete();
      await run;
      expect(preferences.getString('audio_orphan_check_last_IT'), isNotNull);
    },
  );

  test(
    'automatic orphan check respects rights, mode and the stored date',
    () async {
      final state = CourseEditorDeviceState();
      final settings = SettingsService();
      final preferences = await SharedPreferences.getInstance();
      var checks = 0;
      Future<void> check() async => checks++;

      await state.runAutomaticOrphanCheck(
        courseCode: 'it',
        canEditOriginal: false,
        mode: CourseEditorMode.edit,
        check: check,
      );
      await state.runAutomaticOrphanCheck(
        courseCode: 'it',
        canEditOriginal: true,
        mode: CourseEditorMode.viewOnly,
        check: check,
      );
      expect(checks, 0);
      expect(preferences.getString('audio_orphan_check_last_IT'), isNull);

      await settings.markAudioOrphanCheckRun('IT');
      await state.runAutomaticOrphanCheck(
        courseCode: 'it',
        canEditOriginal: true,
        mode: CourseEditorMode.edit,
        check: check,
      );
      expect(checks, 0);

      await state.runAutomaticOrphanCheck(
        courseCode: 'de',
        canEditOriginal: true,
        mode: CourseEditorMode.edit,
        check: check,
      );
      expect(checks, 1);
      expect(preferences.getString('audio_orphan_check_last_DE'), isNotNull);
    },
  );
}

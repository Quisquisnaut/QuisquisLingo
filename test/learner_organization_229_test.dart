import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/lesson_expansion_policy.dart';
import 'package:quisquislingo_app/services/lesson_unlock_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _learnerA = '12345678-1234-4234-9234-123456789abc';
const _learnerB = '87654321-4321-4321-8321-cba987654321';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _learnerA,
          displayName: 'Learner A',
        ).encode(),
        const LearnerProfile(
          learnerProfileId: _learnerB,
          displayName: 'Learner B',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _learnerA,
    });
  });

  test(
    'Hide is isolated by learner and course and Unhide restores visibility',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();

      expect(
        await settings.getHiddenCourseIds(['official', 'custom']),
        isEmpty,
      );
      await settings.setCourseHidden('official', true);
      expect(await settings.isCourseHidden('official'), isTrue);
      expect(await settings.getHiddenCourseIds(['official', 'custom']), {
        'official',
      });

      await profiles.setActiveProfileById(_learnerB);
      expect(await settings.isCourseHidden('official'), isFalse);
      await settings.setCourseHidden('custom', true);
      expect(await settings.getHiddenCourseIds(['official', 'custom']), {
        'custom',
      });

      await profiles.setActiveProfileById(_learnerA);
      expect(await settings.getHiddenCourseIds(['official', 'custom']), {
        'official',
      });
      await settings.setCourseHidden('official', false);
      expect(await SettingsService().isCourseHidden('official'), isFalse);
    },
  );

  test(
    'Lesson expansion defaults Expanded and survives restart per learner and course',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();

      expect(
        await settings.getLessonExpansionMode('course-a'),
        LearnerLessonExpansionMode.expanded,
      );
      await settings.setLessonExpansionMode(
        'course-a',
        LearnerLessonExpansionMode.focused,
      );
      await settings.setLessonExpansionMode(
        'course-b',
        LearnerLessonExpansionMode.collapseCompleted,
      );

      final restarted = SettingsService();
      expect(
        await restarted.getLessonExpansionMode('course-a'),
        LearnerLessonExpansionMode.focused,
      );
      expect(
        await restarted.getLessonExpansionMode('course-b'),
        LearnerLessonExpansionMode.collapseCompleted,
      );

      await profiles.setActiveProfileById(_learnerB);
      expect(
        await restarted.getLessonExpansionMode('course-a'),
        LearnerLessonExpansionMode.expanded,
      );
      await restarted.setLessonExpansionMode(
        'course-a',
        LearnerLessonExpansionMode.collapseCompleted,
      );

      await profiles.setActiveProfileById(_learnerA);
      expect(
        await SettingsService().getLessonExpansionMode('course-a'),
        LearnerLessonExpansionMode.focused,
      );
    },
  );

  test(
    'Lesson expansion policy respects access, completion, focus and Duel unlocks',
    () {
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.expanded,
          hasAccess: true,
          isCompleted: false,
          isCurrent: false,
        ),
        isTrue,
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.expanded,
          hasAccess: false,
          isCompleted: false,
          isCurrent: true,
        ),
        isFalse,
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.expanded,
          hasAccess: true,
          isCompleted: false,
          isCurrent: false,
        ),
        isTrue,
        reason: 'IDDQD-accessible incomplete Lessons follow Expanded mode',
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.collapseCompleted,
          hasAccess: true,
          isCompleted: true,
          isCurrent: true,
        ),
        isFalse,
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.collapseCompleted,
          hasAccess: true,
          isCompleted: false,
          isCurrent: false,
        ),
        isTrue,
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.focused,
          hasAccess: true,
          isCompleted: false,
          isCurrent: true,
        ),
        isTrue,
      );
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.focused,
          hasAccess: true,
          isCompleted: false,
          isCurrent: false,
        ),
        isFalse,
      );

      final course = _course();
      final nextUnlockedByDuel = const LessonUnlockService().isLessonUnlocked(
        lessonIndex: 1,
        course: course,
        completedLessons: const {},
        wonDuels: {course.lessons.first.duel.id},
      );
      expect(nextUnlockedByDuel, isTrue);
      expect(
        LessonExpansionPolicy.isExpanded(
          mode: LearnerLessonExpansionMode.collapseCompleted,
          hasAccess: nextUnlockedByDuel,
          isCompleted: false,
          isCurrent: false,
        ),
        isTrue,
        reason: 'Duel access does not imply Lesson completion',
      );
    },
  );
}

Course _course() => Course(
  courseId: 'course-a',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Organization course',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(lessonId: 'lesson-1', title: 'One', rounds: []),
    Lesson(lessonId: 'lesson-2', title: 'Two', rounds: []),
  ],
);

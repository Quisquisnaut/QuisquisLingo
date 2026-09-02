import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/lesson_unlock_service.dart';

Lesson _lesson(String id) => Lesson(
  lessonId: id,
  title: id,
  rounds: const [],
  duel: Duel(id: 'duel_$id', title: 'Duel $id'),
);

Course _course({List<Lesson>? lessons}) => Course(
  courseId: 'test',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Test',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: lessons ?? [_lesson('t1'), _lesson('t2'), _lesson('t3')],
);

void main() {
  const service = LessonUnlockService();

  test('first Lesson is unlocked when it exists', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: 0,
        course: _course(),
        completedLessons: const {},
        wonDuels: const {},
      ),
      isTrue,
    );
  });

  test('later Lesson stays locked without previous Lesson progress', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: 1,
        course: _course(),
        completedLessons: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
  });

  test('later Lesson unlocks after completing the previous Lesson', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: 1,
        course: _course(),
        completedLessons: const {'t1'},
        wonDuels: const {},
      ),
      isTrue,
    );
  });

  test('later Lesson unlocks after winning the previous Lesson Duel', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: 1,
        course: _course(),
        completedLessons: const {},
        wonDuels: const {'duel_t1'},
      ),
      isTrue,
    );
  });

  test('only the immediately previous Lesson can unlock a later Lesson', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: 2,
        course: _course(),
        completedLessons: const {'t1', 'unrelated'},
        wonDuels: const {'duel_t1'},
      ),
      isFalse,
    );
  });

  test('missing Lesson indices are not unlocked', () {
    expect(
      service.isLessonUnlocked(
        lessonIndex: -1,
        course: _course(),
        completedLessons: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
    expect(
      service.isLessonUnlocked(
        lessonIndex: 3,
        course: _course(),
        completedLessons: const {'t3'},
        wonDuels: const {'duel_t3'},
      ),
      isFalse,
    );
    expect(
      service.isLessonUnlocked(
        lessonIndex: 0,
        course: _course(lessons: const []),
        completedLessons: const {},
        wonDuels: const {},
      ),
      isFalse,
    );
  });
}

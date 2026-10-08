import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Vocabulary learner');
  });

  test(
    'resolves published vocabulary pairs in authored order without fabrication',
    () {
      final service = VocabularyReviewService();
      final course = _course(
        vocabulary: const [
          LearningContent(
            id: 'equals',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'casa = house',
          ),
          LearningContent(
            id: 'arrow',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'pane → bread',
          ),
          LearningContent(
            id: 'dash',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'acqua - water',
          ),
          LearningContent(
            id: 'colon',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'grazie:thank you',
          ),
          LearningContent(
            id: 'draft',
            publicationState: PublicationState.draft,
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'bozza = draft',
          ),
          LearningContent(
            id: 'malformed',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'no answer here',
          ),
          LearningContent(
            id: 'other-kind',
            kind: 'text',
            text: 'ignored = ignored',
          ),
        ],
      );

      final entries = service.resolveEntries(course, course.lessons.single);
      expect(entries.map((entry) => entry.prompt), [
        'casa',
        'pane',
        'acqua',
        'grazie',
      ]);
      expect(entries.map((entry) => entry.answer), [
        'house',
        'bread',
        'water',
        'thank you',
      ]);
      expect(entries.every((entry) => entry.supplementary.isEmpty), isTrue);
    },
  );

  test('disabled and Draft GuideBooks expose no vocabulary', () {
    const vocabulary = [
      LearningContent(id: 'word', kind: 'vocabulary', text: 'casa = house'),
    ];
    final disabled = _course(vocabulary: vocabulary, useGuidebook: false);
    final draft = _course(
      vocabulary: vocabulary,
      guidebookState: PublicationState.draft,
    );

    expect(
      VocabularyReviewService().resolveEntries(
        disabled,
        disabled.lessons.single,
      ),
      isEmpty,
    );
    expect(
      VocabularyReviewService().resolveEntries(draft, draft.lessons.single),
      isEmpty,
    );
  });

  test(
    'missing, known, and reinforcement states drive eligibility across reloads',
    () async {
      final course = _course();
      final lesson = course.lessons.single;
      final service = VocabularyReviewService();
      final entries = service.resolveEntries(course, lesson);

      expect(await service.eligibleEntries(course, lesson), entries);

      await service.markKnown(course.courseId, lesson.lessonId, entries.first);
      expect(
        await VocabularyReviewService().stateFor(
          course.courseId,
          lesson.lessonId,
          entries.first,
        ),
        const VocabularyReviewState(
          encountered: true,
          needsReinforcement: false,
        ),
      );
      expect(await VocabularyReviewService().eligibleEntries(course, lesson), [
        entries.last,
      ]);

      await VocabularyReviewService().requestReinforcement(
        course.courseId,
        lesson.lessonId,
        entries.first,
      );
      expect(
        await VocabularyReviewService().eligibleEntries(course, lesson),
        entries,
      );

      await VocabularyReviewService().keepReinforcement(
        course.courseId,
        lesson.lessonId,
        entries.first,
      );
      expect(
        (await VocabularyReviewService().stateFor(
          course.courseId,
          lesson.lessonId,
          entries.first,
        )).needsReinforcement,
        isTrue,
      );
    },
  );

  test(
    'content changes are new while Course and Lesson title changes preserve state',
    () async {
      final service = VocabularyReviewService();
      final original = _course(
        title: 'Original course',
        lessonTitle: 'Original lesson',
      );
      final originalEntry = service
          .resolveEntries(original, original.lessons.single)
          .first;
      await service.markKnown(
        original.courseId,
        original.lessons.single.lessonId,
        originalEntry,
      );

      final renamed = _course(
        title: 'Renamed course',
        lessonTitle: 'Renamed lesson',
      );
      expect(await service.eligibleEntries(renamed, renamed.lessons.single), [
        service.resolveEntries(renamed, renamed.lessons.single).last,
      ]);

      final changed = _course(
        title: 'Renamed course',
        lessonTitle: 'Renamed lesson',
        vocabulary: const [
          LearningContent(
            id: 'casa-home',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'casa = home',
          ),
        ],
      );
      expect(
        await service.eligibleEntries(changed, changed.lessons.single),
        hasLength(1),
      );
      expect(
        (await service.stateFor(
          changed.courseId,
          changed.lessons.single.lessonId,
          service.resolveEntries(changed, changed.lessons.single).single,
        )).encountered,
        isFalse,
      );
    },
  );

  test(
    'duplicate authored occurrences have independent deterministic identities',
    () async {
      const duplicates = [
        LearningContent(
          id: 'duplicate',
          kind: 'vocabulary',
          text: 'casa = house',
        ),
        LearningContent(
          id: 'duplicate',
          kind: 'vocabulary',
          text: 'casa = house',
        ),
        LearningContent(id: '', kind: 'vocabulary', text: 'casa = house'),
        LearningContent(id: '', kind: 'vocabulary', text: 'casa = house'),
      ];
      final course = _course(vocabulary: duplicates);
      final service = VocabularyReviewService();
      final entries = service.resolveEntries(course, course.lessons.single);

      expect(entries.map((entry) => entry.identity).toSet(), hasLength(4));
      expect(
        service
            .resolveEntries(course, course.lessons.single)
            .map((entry) => entry.identity),
        entries.map((entry) => entry.identity),
      );

      await service.markKnown(
        course.courseId,
        course.lessons.single.lessonId,
        entries.first,
      );
      expect(await service.eligibleEntries(course, course.lessons.single), [
        entries[1],
        entries[2],
        entries[3],
      ]);
    },
  );

  test('learner, Course, and Lesson scopes do not collide', () async {
    final profiles = ProfileService();
    final aliceId =
        (await profiles.getProfileRecords()).single.learnerProfileId;
    final courseA = _course(courseId: 'course-a', lessonId: 'shared-lesson');
    final courseB = _course(courseId: 'course-b', lessonId: 'shared-lesson');
    final service = VocabularyReviewService();
    final entryA = service
        .resolveEntries(courseA, courseA.lessons.single)
        .first;
    await service.markKnown(
      courseA.courseId,
      courseA.lessons.single.lessonId,
      entryA,
    );

    expect(
      await service.eligibleEntries(courseB, courseB.lessons.single),
      hasLength(2),
    );

    await profiles.addProfile('Second learner');
    expect(
      await service.eligibleEntries(courseA, courseA.lessons.single),
      hasLength(2),
    );

    await profiles.setActiveProfileById(aliceId);
    expect(
      await service.eligibleEntries(courseA, courseA.lessons.single),
      hasLength(1),
    );
  });

  test(
    'malformed storage is absent and a valid write replaces it safely',
    () async {
      final course = _course();
      final lesson = course.lessons.single;
      final service = VocabularyReviewService();
      final prefs = await SharedPreferences.getInstance();
      final digest = sha256
          .convert(utf8.encode(course.courseId.trim()))
          .toString();
      final key = await ProfileService().key(
        'v1_vocabulary_review_course_$digest',
      );
      await prefs.setString(key, '{not valid json');

      expect(await service.eligibleEntries(course, lesson), hasLength(2));
      final entry = service.resolveEntries(course, lesson).first;
      await service.markKnown(course.courseId, lesson.lessonId, entry);
      expect(prefs.getString(key), contains('"version":1'));
      expect(
        (await service.stateFor(
          course.courseId,
          lesson.lessonId,
          entry,
        )).encountered,
        isTrue,
      );
    },
  );

  test(
    'reset removes only active learner current-Course vocabulary state',
    () async {
      final profiles = ProfileService();
      final aliceId =
          (await profiles.getProfileRecords()).single.learnerProfileId;
      final courseA = _course(courseId: 'course-a');
      final courseB = _course(courseId: 'course-b');
      final service = VocabularyReviewService();
      final entryA = service
          .resolveEntries(courseA, courseA.lessons.single)
          .first;
      final entryB = service
          .resolveEntries(courseB, courseB.lessons.single)
          .first;
      await service.markKnown(
        courseA.courseId,
        courseA.lessons.single.lessonId,
        entryA,
      );
      await service.markKnown(
        courseB.courseId,
        courseB.lessons.single.lessonId,
        entryB,
      );

      await profiles.addProfile('Second learner');
      await service.markKnown(
        courseA.courseId,
        courseA.lessons.single.lessonId,
        entryA,
      );
      await profiles.setActiveProfileById(aliceId);
      await service.resetCourse(courseA.courseId);

      expect(
        await service.eligibleEntries(courseA, courseA.lessons.single),
        hasLength(2),
      );
      expect(
        await service.eligibleEntries(courseB, courseB.lessons.single),
        hasLength(1),
      );
      await profiles.setActiveProfile('Second learner');
      expect(
        await service.eligibleEntries(courseA, courseA.lessons.single),
        hasLength(1),
      );
    },
  );

  test(
    'vocabulary actions and reset leave all unrelated preferences unchanged',
    () async {
      final course = _course(courseId: 'course-isolation');
      final lesson = course.lessons.single;
      final progress = ProgressService(now: () => DateTime.utc(2026, 9, 1, 10));
      await progress.completeRound(
        'completed',
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await progress.completeLesson(
        lesson.lessonId,
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await progress.recordRecentRound(
        course.courseId,
        lesson.lessonId,
        'completed',
        errors: 4,
      );
      await progress.markPerfectRound('completed', courseId: course.courseId);
      await progress.winDuel(
        'duel',
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await progress.addXp(17, courseCode: 'IT', courseId: course.courseId);

      final prefs = await SharedPreferences.getInstance();
      final before = _preferencesSnapshot(prefs);
      final service = VocabularyReviewService();
      final entries = service.resolveEntries(course, lesson);
      await service.markKnown(course.courseId, lesson.lessonId, entries.first);
      await service.requestReinforcement(
        course.courseId,
        lesson.lessonId,
        entries.last,
      );
      await service.keepReinforcement(
        course.courseId,
        lesson.lessonId,
        entries.last,
      );
      await service.resetCourse(course.courseId);

      expect(_preferencesSnapshot(prefs), before);
    },
  );
}

Map<String, Object?> _preferencesSnapshot(SharedPreferences prefs) => {
  for (final key in prefs.getKeys()) key: prefs.get(key),
};

Course _course({
  String courseId = 'course-vocabulary',
  String title = 'Vocabulary course',
  String lessonId = 'lesson-vocabulary',
  String lessonTitle = 'Vocabulary lesson',
  bool useGuidebook = true,
  PublicationState guidebookState = PublicationState.published,
  List<LearningContent>? vocabulary,
}) => Course(
  courseId: courseId,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  useGuidebook: useGuidebook,
  lessons: [
    Lesson(
      lessonId: lessonId,
      title: lessonTitle,
      guidebook: Guidebook(
        publicationState: guidebookState,
        content:
            vocabulary ??
            const [
              LearningContent(
                id: 'casa-home',
                kind: 'vocabulary',
                role: 'vocabulary',
                text: 'casa = house',
              ),
              LearningContent(
                id: 'pane-bread',
                kind: 'vocabulary',
                role: 'vocabulary',
                text: 'pane = bread',
              ),
            ],
      ),
      rounds: [LearningRound(id: 'round', title: 'Round', exercises: const [])],
    ),
  ],
);

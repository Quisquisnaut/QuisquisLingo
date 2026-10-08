import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/guidebook_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Vocabulary learner');
  });

  // Build 266: Words & Expressions only, never Sentences; the Context and
  // the picture come with the entry, optional words show as "(io)".
  test(
    'resolves published Words & Expressions in authored order without fabrication',
    () {
      final service = VocabularyReviewService();
      final picture = GuidebookPicture(
        asset: 'assets/exercise_images/cat.webp',
        plural: true,
      );
      final course = _course(
        vocabulary: [
          testEntry('equals', 'casa = house'),
          testEntry('bakery', 'pane = bread', context: 'bakery'),
          testEntry('subject', '{io} sono stanco = I am tired'),
          testEntry('cats', 'i gatti = the cats', picture: picture),
        ],
        sentences: [testEntry('sentence', 'La casa è grande. = The house is big.')],
      );

      final entries = service.resolveEntries(course, course.lessons.single);
      expect(entries.map((entry) => entry.prompt), [
        'casa',
        'pane',
        '(io) sono stanco',
        'i gatti',
      ]);
      expect(entries.map((entry) => entry.answer), [
        'house',
        'bread',
        'I am tired',
        'the cats',
      ]);
      expect(entries.map((entry) => entry.context), ['', 'bakery', '', '']);
      expect(entries.last.picture, picture);
      expect(entries.every((entry) => entry.supplementary.isEmpty), isTrue);
    },
  );

  test('the Context joins the fingerprint, the picture does not', () {
    final service = VocabularyReviewService();
    String fingerprint(GuidebookEntry entry) => service
        .resolveEntries(
          _course(vocabulary: [entry]),
          _course(vocabulary: [entry]).lessons.single,
        )
        .single
        .fingerprint;
    final plain = testEntry('conto', 'il conto = the bill');
    final withContext = testEntry(
      'conto',
      'il conto = the bill',
      context: 'restaurant',
    );
    final withPicture = testEntry(
      'conto',
      'il conto = the bill',
      picture: const GuidebookPicture(asset: 'assets/exercise_images/bill.webp'),
    );
    expect(fingerprint(withContext), isNot(fingerprint(plain)));
    expect(fingerprint(withPicture), fingerprint(plain));
  });

  test('disabled and Draft GuideBooks expose no vocabulary', () {
    final vocabulary = [testEntry('word', 'casa = house')];
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
        vocabulary: [testEntry('casa-home', 'casa = home')],
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
      final duplicates = [
        testEntry('duplicate', 'casa = house'),
        testEntry('duplicate', 'casa = house'),
        testEntry('', 'casa = house'),
        testEntry('', 'casa = house'),
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
  List<GuidebookEntry>? vocabulary,
  List<GuidebookEntry> sentences = const [],
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
      guidebook: testGuidebook(
        publicationState: guidebookState,
        sentences: sentences,
        words:
            vocabulary ??
            [
              testEntry('casa-home', 'casa = house'),
              testEntry('pane-bread', 'pane = bread'),
            ],
      ),
      rounds: [LearningRound(id: 'round', title: 'Round', exercises: const [])],
    ),
  ],
);

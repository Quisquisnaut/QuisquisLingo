import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 259 Revision 6 (owner request of 1 October 2026): QQL Demo:
/// Piedmontese holds the Piedmontese demo's exercises mixed at random in
/// one Lesson of 20 Rounds of six, each opening with a Before you start
/// card, then the Story; since Revision 7 each Lesson has a GuideBook.

const _asset = 'assets/courses/piedmontese_mixed_en.json';

Map<String, dynamic> _raw(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// A Content's JSON with its own ID (and so its items' IDs) neutralized.
String _withoutIds(LearningContent content) =>
    jsonEncode(content.toJson()).replaceAll('"${content.id}', '"ID');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final raw = _raw(_asset);
  final mixed = Course.fromJson(raw);
  final source = Course.fromJson(_raw('assets/courses/piedmontais_en.json'));

  test('is the third bundled Course, beside the Piedmontese demo', () async {
    expect(CourseService.courseAssets['PMS_MIX'], _asset);
    final loaded = await CourseService().loadBundledCourse('PMS_MIX');
    expect(loaded.title, 'QQL Demo: Piedmontese');
    expect(loaded.originType, CourseOriginType.bundledOfficial);
    expect(CourseService.bundledCodeForCourse(loaded), 'PMS_MIX');
    // Language XP and streaks stay with Piedmontese.
    expect(CourseService.codeForCourse(loaded), 'PMS');
    expect(loaded.courseId, isNot(source.courseId));
    expect(mixed.toJson(), raw);
    expect(CourseChecksums.official(mixed), mixed.officialChecksum);
  });

  test('holds exactly the Piedmontese exercises, mixed', () {
    final sourceExercises = [
      for (final lesson in source.lessons.take(40))
        for (final round in lesson.rounds) ...round.content.skip(1),
    ];
    final practice = mixed.lessons.first;
    // Build 260 Revision 3: only the first Round opens with a card.
    final mixedExercises = [
      for (final round in practice.rounds)
        ...round.content.where(
          (content) => content.editorTemplate != 'before_you_start',
        ),
    ];
    expect(mixedExercises, hasLength(120));
    expect(
      mixedExercises.map(_withoutIds).toList()..sort(),
      sourceExercises.map(_withoutIds).toList()..sort(),
    );
    // No Round is one exercise type, as in the source.
    for (final round in practice.rounds) {
      final types = round.content
          .where((content) => content.editorTemplate != 'before_you_start')
          .map((content) => content.editorTemplate)
          .toSet();
      expect(types.length, greaterThan(2), reason: round.id);
    }
  });

  test(
    'one Lesson of 20 Rounds of six, the first with a card, then the Story',
    () {
      // Revision 7: both Lessons have a GuideBook, and every card offers it.
      expect(mixed.useGuidebook, isTrue);
      expect(mixed.lessons, hasLength(2));
      final practice = mixed.lessons.first;
      expect(practice.title, 'Mixed practice');
      expect(practice.rounds, hasLength(20));
      // Build 260 Revision 3 (owner decision): the Lesson's first Round alone
      // opens with a Before you start card.
      final card = ExerciseFeatures(practice.rounds.first.exercises.first);
      expect(card.kind, LearnerExerciseKind.roundIntro);
      expect(
        card.introText,
        'Mixed practice: 20 Rounds of 6 exercises of different types. '
        'Open the GuideBook for the notes and the words.',
      );
      expect(card.guidebookButton, isTrue);
      for (final (index, round) in practice.rounds.indexed) {
        expect(round.flow, isNull);
        expect(round.content, hasLength(index == 0 ? 7 : 6));
        expect(
          round.exercises
              .skip(index == 0 ? 1 : 0)
              .any(
                (exercise) =>
                    ExerciseFeatures(exercise).kind ==
                    LearnerExerciseKind.roundIntro,
              ),
          isFalse,
          reason: round.id,
        );
        expect(
          round.exercises.any(
            (exercise) =>
                exercise.canonicalEvaluation.mode != EvaluationMode.none,
          ),
          isTrue,
          reason: round.id,
        );
      }
      final story = mixed.lessons.last;
      expect(story.rounds.single.isStory, isTrue);
      expect(
        story.rounds.single.content.map(_withoutIds).skip(1),
        source.lessons.last.rounds.single.content
            .map(_withoutIds)
            .skip(1)
            .map(
              (text) => text.replaceAll(
                'pms_e5f5585a_character_',
                'pmsmix_69ff369e_character_',
              ),
            ),
      );
    },
  );

  test('each Lesson has a GuideBook with notes and vocabulary', () {
    final practice = mixed.lessons.first.guidebook.content;
    expect(practice.first.role, 'overview');
    expect(practice.where((c) => c.role == 'grammar'), hasLength(3));
    final vocabulary = VocabularyReviewService();
    final words = vocabulary.resolveEntries(mixed, mixed.lessons.first);
    expect(words, hasLength(32));
    expect(
      words.singleWhere((entry) => entry.prompt == 'I am happy').answer,
      'i son content',
    );
    final story = vocabulary.resolveEntries(mixed, mixed.lessons.last);
    expect(story.map((entry) => entry.answer), [
      'bondì',
      'un pan',
      'për piasì',
      'grassie',
      'bon-a giornà',
    ]);
    final storyCard = ExerciseFeatures(
      mixed.lessons.last.rounds.single.exercises.first,
    );
    expect(storyCard.guidebookButton, isTrue);
  });

  test('passes the Audit with no error', () {
    final audit = CourseAuditService().auditCourse(mixed);
    expect(audit.count(AuditSeverity.error), 0);
    expect(
      audit.issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .map((issue) => '${issue.code}:${issue.exerciseId}'),
      isEmpty,
    );
  });
}

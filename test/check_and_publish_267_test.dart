import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_articles.dart';

/// Build 267 Revision 4: the Course Wizard's step 8, Check and publish
/// (plan docs/267_COURSE_WIZARD_PLAN.md §7).
void main() {
  test('a clean Course is published whole', () {
    final course = _wizardCourse();
    final before = CourseWizardCheck.of(course);
    expect(before.lessons, hasLength(1));
    final lesson = before.lessons.single;
    expect(lesson.modules, 1);
    expect(lesson.rounds, 6);
    expect(lesson.exercises, greaterThan(0));
    expect(lesson.drafts, greaterThan(0));

    final result = CourseWizardPublish.publish(course, now: _later);
    expect(result.published, isTrue);
    expect(result.keptDraft, isEmpty);
    final published = result.course.lessons.single;
    expect(published.publicationState.isPublished, isTrue);
    expect(published.provisionalDraft, isFalse);
    expect(published.guidebook.publicationState.isPublished, isTrue);
    for (final round in published.rounds) {
      expect(round.publicationState.isPublished, isTrue);
      expect(round.provisionalDraft, isFalse);
      expect(
        round.content.every((content) => content.publicationState.isPublished),
        isTrue,
      );
    }
    expect(CourseWizardCheck.of(result.course).lessons.single.drafts, 0);
  });

  test('what an Audit error names stays Draft and is listed', () {
    // A Before you start card without its note is an Error
    // (ROUND_INTRO_EMPTY): the card stays Draft, the rest is published.
    final json = _wizardCourse().toJson();
    final rounds = ((json['lessons'] as List).single as Map)['rounds'] as List;
    final first = rounds.first as Map;
    final card = (first['content'] as List).cast<Map>().firstWhere(
      (content) =>
          (content['authoringMetadata'] as Map?)?['presetId'] ==
          'before_you_start',
    );
    for (final element in (card['exercise'] as Map)['prompt'] as List) {
      (element as Map)['text'] = '';
    }
    final course = Course.fromJson(json);
    expect(CourseWizardCheck.of(course).lessons.single.errors, greaterThan(0));

    final result = CourseWizardPublish.publish(course, now: _later);
    expect(result.published, isTrue);
    expect(result.keptDraft, hasLength(1));
    expect(result.keptDraft.single, startsWith('Lesson 1 · '));
    expect(result.keptDraft.single, contains('item 1'));
    final round = result.course.lessons.single.rounds.first;
    expect(round.publicationState.isPublished, isTrue);
    final kept = round.content.firstWhere((c) => c.id == card['id']);
    expect(kept.publicationState.isPublished, isFalse);
    expect(
      round.content
          .where((c) => c.id != card['id'])
          .every((c) => c.publicationState.isPublished),
      isTrue,
    );
  });
}

final _now = DateTime.utc(2026, 10, 9, 12);
final _later = DateTime.utc(2026, 10, 9, 13);

/// One Lesson of the Wizard's sample with its approved GuideBook and the
/// Round Wizard's Rounds, as step 7 leaves it.
Course _wizardCourse() {
  var course = CourseWizardLessons.applyTo(
    CourseLibraryOperations(clock: () => _now).newWizardCourse(
      creator: const LearnerProfile(
        learnerProfileId: '12345678-1234-4234-9234-123456789abc',
        displayName: 'Author',
      ),
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
    ),
    [CourseWizardSample.lessons.first],
    now: _now,
    ids: _Ids(),
  );
  course = CourseWizardGuidebook.withModules(
    course,
    course.lessons.single.lessonId,
    CourseWizardSample.guidebook(_Ids()),
    state: PublicationState.published,
    now: _now,
  );
  final guidebook = course.lessons.single.guidebook;
  final generator = GuidebookRoundGenerator(
    randomSeed: 1,
    draftIds: _Ids(),
    now: () => _now,
    articles: WordLookupArticles.forLanguage('it'),
  );
  final plan = generator.plan(guidebook, roundCount: 6, exercisesPerRound: 8);
  return CourseWizardRounds.withRounds(
    course,
    course.lessons.single.lessonId,
    generator.createDrafts(guidebook, plan),
    now: _now,
  );
}

class _Ids implements AuthoringIdGenerator {
  static var _next = 0;

  @override
  String next(String kind) => '${kind}_publish_${_next++}';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/story_cast.dart';

/// Build 273 Revision 0: `StoryCast`, the one owner of the Story cast rules
/// the Course Editor's Story characters and the Story Wizard shared. Each
/// case states what the screens did before the owner existed (the widget
/// cases of `story_editor_256_test` still drive them).
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 10, 15);

const _anna = StorySpeaker(
  id: 'character_anna',
  name: 'Anna',
  avatar: 'assets/avatars/cat.png',
  language: TextLanguage.target,
  voice: StoryVoice.female,
);
const _bob = StorySpeaker(
  id: 'character_bob',
  name: 'Bob',
  language: TextLanguage.target,
);

Exercise _line(String id, String text, {String speakerId = ''}) =>
    ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: Exercise.canonical(
          id: id,
          publicationState: PublicationState.draft,
          primitive: ExercisePrimitive.presentation,
          canonicalEvaluation: CanonicalEvaluation.none,
          updatedAt: _stamp,
        ),
        type: 'dialogue_line',
        publicationState: PublicationState.published,
        prompt: text,
        speakerId: speakerId,
      ),
    ).candidate!;

LearningRound _round(String id, List<Exercise> exercises) => LearningRound(
  id: id,
  title: id,
  updatedAt: _stamp,
  visualType: LearningRound.storyVisualType,
  content: [for (final e in exercises) LearningContent.fromExercise(e)],
);

Course _course({
  StorySpeaker? narrator,
  List<StorySpeaker> characters = const [_anna, _bob],
  List<CourseMediaAttribution> credits = const [],
}) => Course(
  courseId: 'story_cast_273',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Story cast course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyNarrator: narrator,
  storyCharacters: characters,
  mediaAttributions: credits,
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      title: 'Lesson one',
      updatedAt: _stamp,
      rounds: [
        _round('round_one', [
          _line('n1', 'Anna walks in.'),
          _line('a1', 'Ciao!', speakerId: 'character_anna'),
          _line('a2', 'Un caffè.', speakerId: 'character_anna'),
        ]),
        _round('round_two', [_line('n2', 'Later.')]),
      ],
    ),
    Lesson(
      lessonId: 'lesson_two',
      title: 'Lesson two',
      updatedAt: _stamp,
      rounds: [
        _round('round_three', [
          _line('a3', 'Arrivederci.', speakerId: 'character_anna'),
        ]),
      ],
    ),
  ],
);

CourseMediaAttribution _credit(String title) => CourseMediaAttribution(
  title: title,
  author: 'Someone',
  license: 'CC BY 4.0',
);

Map<String, Object?> _withoutCast(Course course) => {...course.toJson()}
  ..remove('storyNarrator')
  ..remove('storyCharacters')
  ..remove('mediaAttributions');

void main() {
  test('describe names the language and the voice of a speaker', () {
    expect(StoryCast.describe(_anna), 'Target language · voice female');
    expect(
      StoryCast.describe(StorySpeaker.defaultNarrator),
      'Source language · voice any',
    );
  });

  test('summaryOf names the narrator and counts the characters', () {
    expect(StoryCast.summaryOf(_course()), 'Unnamed narrator · 2 characters');
    expect(
      StoryCast.summaryOf(
        _course(
          narrator: const StorySpeaker(
            name: 'Teller',
            language: TextLanguage.source,
          ),
          characters: const [_anna],
        ),
      ),
      'Narrator: Teller · 1 character',
    );
    expect(
      StoryCast.summaryOf(_course(characters: const [])),
      'Unnamed narrator · 0 characters',
    );
  });

  test('linesSpokenBy counts the lines of every Lesson and Round', () {
    final course = _course();
    expect(StoryCast.linesSpokenBy(course, 'character_anna'), 3);
    expect(StoryCast.linesSpokenBy(course, 'character_bob'), 0);
    // The narrator's lines name no character.
    expect(StoryCast.linesSpokenBy(course, ''), 2);
  });

  test('stillSpeaksMessage counts lines in the singular and the plural', () {
    expect(
      StoryCast.stillSpeaksMessage(1),
      startsWith('1 Dialogue line of this Course name this character.'),
    );
    expect(
      StoryCast.stillSpeaksMessage(3),
      '3 Dialogue lines of this Course name this character. Give those lines '
      'another speaker first; QQL never hands them to the narrator silently.',
    );
  });

  test('replacing and without keep the other characters in order', () {
    final renamed = _anna.copyWith(name: 'Annie');
    expect(StoryCast.replacing(const [_anna, _bob], renamed), [renamed, _bob]);
    expect(StoryCast.replacing(const [_bob], renamed), [_bob]);
    expect(StoryCast.without(const [_anna, _bob], 'character_anna'), [_bob]);
    expect(StoryCast.without(const [_anna, _bob], 'nobody'), [_anna, _bob]);
  });

  group('withSpeakers', () {
    test('the default narrator saved unchanged is not stored', () {
      final course = _course();
      final updated = StoryCast.withSpeakers(
        course,
        narrator: course.narrator,
        characters: course.storyCharacters,
      );
      expect(updated.storyNarrator, isNull);
      expect(updated.toJson(), course.toJson());
    });

    test('a stored narrator stays stored, also when it equals the default', () {
      final course = _course(narrator: StorySpeaker.defaultNarrator);
      final updated = StoryCast.withSpeakers(
        course,
        narrator: StorySpeaker.defaultNarrator,
        characters: course.storyCharacters,
      );
      expect(updated.storyNarrator, isNotNull);
      expect(updated.toJson(), course.toJson());
    });

    test('a stored narrator of its own saved unchanged changes nothing', () {
      final course = _course(
        narrator: const StorySpeaker(
          name: 'Teller',
          language: TextLanguage.target,
          voice: StoryVoice.male,
        ),
      );
      final updated = StoryCast.withSpeakers(
        course,
        narrator: course.narrator,
        characters: course.storyCharacters,
      );
      expect(updated.toJson(), course.toJson());
    });

    test('a changed narrator is stored', () {
      const teller = StorySpeaker(
        name: 'Teller',
        language: TextLanguage.source,
      );
      final updated = StoryCast.withSpeakers(
        _course(),
        narrator: teller,
        characters: const [_anna, _bob],
      );
      expect(updated.storyNarrator?.toJson(), teller.toJson());
    });

    test('characters are written in order; none leaves no key', () {
      final course = _course();
      final reordered = StoryCast.withSpeakers(
        course,
        narrator: course.narrator,
        characters: const [_bob, _anna],
      );
      expect(reordered.storyCharacters.map((c) => c.id), [
        'character_bob',
        'character_anna',
      ]);
      final none = StoryCast.withSpeakers(
        course,
        narrator: course.narrator,
        characters: const [],
      );
      expect(none.storyCharacters, isEmpty);
      expect(none.toJson().containsKey('storyCharacters'), isFalse);
    });

    test('each credit is added once, after the Course\'s own', () {
      final course = _course(credits: [_credit('Cat avatar')]);
      final updated = StoryCast.withSpeakers(
        course,
        narrator: course.narrator,
        characters: course.storyCharacters,
        credits: [_credit('Cat avatar'), _credit('Dog'), _credit('Dog')],
      );
      expect(updated.mediaAttributions.map((c) => c.title), [
        'Cat avatar',
        'Dog',
      ]);
      expect(
        StoryCast.withSpeakers(
          _course(),
          narrator: course.narrator,
          characters: course.storyCharacters,
        ).toJson().containsKey('mediaAttributions'),
        isFalse,
      );
    });

    test('everything else of the Course is kept', () {
      final course = _course(credits: [_credit('Cat avatar')]);
      final updated = StoryCast.withSpeakers(
        course,
        narrator: const StorySpeaker(
          name: 'Teller',
          language: TextLanguage.source,
        ),
        characters: const [_bob],
        credits: [_credit('Dog')],
      );
      expect(_withoutCast(updated), _withoutCast(course));
    });
  });
}

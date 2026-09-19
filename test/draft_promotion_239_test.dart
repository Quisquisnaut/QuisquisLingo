// QQL Build 239 Revision 1: a Draft Round or Lesson is promoted when its last
// Draft child is saved as Published, a turned-off GuideBook never shows or
// counts a Draft state, and importing keeps the publication states in the file.
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/provisional_publication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _draft = PublicationState.draft;
const _published = PublicationState.published;
final _now = DateTime.utc(2026, 9, 19, 12);

Exercise _exercise(String id, PublicationState state) => Exercise(
  id: id,
  publicationState: state,
  updatedAt: DateTime.utc(2026, 9, 18),
  type: 'translation_choice_to_target',
  prompt: '',
  question: 'I am going to London',
  answers: const ['Vado a Londra.', 'Vengo da Londra.'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

/// One Lesson with two Rounds. [firstStates] and [secondStates] list the
/// Exercise states of each Round.
Course _course({
  List<PublicationState> firstStates = const [_draft],
  List<PublicationState> secondStates = const [_published],
  PublicationState firstRound = _draft,
  PublicationState secondRound = _published,
  PublicationState lesson = _draft,
  PublicationState guidebook = _draft,
  bool useGuidebook = false,
}) {
  LearningRound round(
    String id,
    PublicationState state,
    List<PublicationState> exercises,
  ) => LearningRound(
    id: id,
    publicationState: state,
    title: id,
    exercises: [
      for (var i = 0; i < exercises.length; i++)
        _exercise('$id-e$i', exercises[i]),
    ],
  );

  return Course(
    courseId: 'promotion-course',
    publicationState: _draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Promotion',
    ttsLanguage: 'it-IT',
    useGuidebook: useGuidebook,
    createDuels: false,
    lessons: [
      Lesson(
        lessonId: 'lesson-1',
        title: 'Lesson',
        publicationState: lesson,
        guidebook: Guidebook(publicationState: guidebook, content: const []),
        rounds: [
          round('round-1', firstRound, firstStates),
          round('round-2', secondRound, secondStates),
        ],
      ),
    ],
  );
}

Course _reconcile(Course source, Course? previous) =>
    const ProvisionalPublicationService().reconcile(
      source,
      updatedAt: _now,
      previous: previous,
    );

void main() {
  group('promotion of Draft parents', () {
    test(
      'the last Draft Exercise saved as Published promotes Round and Lesson',
      () {
        final before = _course(firstStates: const [_draft]);
        final after = _course(firstStates: const [_published]);
        final result = _reconcile(after, before);
        final lesson = result.lessons.single;
        expect(lesson.rounds.first.publicationState, _published);
        expect(lesson.publicationState, _published);
        // The Course delivery choice is never changed.
        expect(result.publicationState, _draft);
      },
    );

    test('a Round with a remaining Draft Exercise stays Draft', () {
      final before = _course(firstStates: const [_draft, _draft]);
      final after = _course(firstStates: const [_published, _draft]);
      final result = _reconcile(after, before);
      expect(result.lessons.single.rounds.first.publicationState, _draft);
      expect(result.lessons.single.publicationState, _draft);
    });

    test('a Lesson stays Draft while another Round is Draft', () {
      final before = _course(
        firstStates: const [_draft],
        secondRound: _draft,
        secondStates: const [_draft],
      );
      final after = _course(
        firstStates: const [_published],
        secondRound: _draft,
        secondStates: const [_draft],
      );
      final result = _reconcile(after, before);
      expect(result.lessons.single.rounds.first.publicationState, _published);
      expect(result.lessons.single.publicationState, _draft);
    });

    test('an explicit Draft with nothing newly completed is not undone', () {
      final same = _course(firstStates: const [_published]);
      final result = _reconcile(same, same);
      expect(result.lessons.single.rounds.first.publicationState, _draft);
      expect(result.lessons.single.publicationState, _draft);
    });

    test('without the previous course nothing is promoted', () {
      final after = _course(firstStates: const [_published]);
      final result = _reconcile(after, null);
      expect(result.lessons.single.rounds.first.publicationState, _draft);
      expect(result.lessons.single.publicationState, _draft);
    });

    test('a Draft GuideBook blocks the Lesson only while GuideBook is on', () {
      final before = _course(firstStates: const [_draft]);
      final on = _reconcile(
        _course(firstStates: const [_published], useGuidebook: true),
        _course(firstStates: const [_draft], useGuidebook: true),
      );
      expect(on.lessons.single.rounds.first.publicationState, _published);
      expect(on.lessons.single.publicationState, _draft);

      final off = _reconcile(_course(firstStates: const [_published]), before);
      expect(off.lessons.single.publicationState, _published);
    });
  });

  group('turned-off GuideBook', () {
    test('never shows a Draft badge and never counts in the Lesson badge', () {
      // Everything is Published except the (empty) Draft GuideBook.
      final off = _course(
        firstStates: const [_published],
        firstRound: _published,
        lesson: _published,
      );
      final offStatus = AuthoringHierarchyStatus.fromCourse(off);
      final lessonOff = off.lessons.single;
      expect(offStatus.lessonGuidebookHasDraft(lessonOff), isFalse);
      expect(offStatus.lessonHasDraft(lessonOff), isFalse);
      expect(offStatus.courseHasDraft, isFalse);

      final on = _course(
        firstStates: const [_published],
        firstRound: _published,
        lesson: _published,
        useGuidebook: true,
      );
      final onStatus = AuthoringHierarchyStatus.fromCourse(on);
      expect(onStatus.lessonGuidebookHasDraft(on.lessons.single), isTrue);
      expect(onStatus.lessonHasDraft(on.lessons.single), isTrue);
    });
  });

  group('import', () {
    test('keeps every publication state stored in the file', () async {
      SharedPreferences.setMockInitialValues({});
      final base = _course(
        firstStates: const [_published],
        firstRound: _published,
        lesson: _published,
        guidebook: _published,
      );
      final json = base.toJson();
      const profile = 'f2a7b4c8-f7c4-4b02-a9e3-baa4566cb396';
      json['publicationState'] = _published.name;
      json['originalCourseCreator'] = {
        'type': 'qqlUser',
        'id': profile,
        'displayName': 'Importer',
      };
      json['maintainer'] = {'profileId': profile};
      json['lastVersionEditorProfileId'] = profile;
      json['lastVersionEditorDisplayName'] = 'Importer';
      json['originalCreatedAtUtc'] = _now.toIso8601String();
      json['modifiedAtUtc'] = _now.toIso8601String();
      final imported = Course.fromJson(json);

      final service = CourseEditorService();
      await service.installImportedCustomCourse(imported);
      final stored = (await service.listUserCourses()).single;
      expect(stored.publicationState, _published);
      final lesson = stored.lessons.single;
      expect(lesson.publicationState, _published);
      expect(lesson.guidebook.publicationState, _published);
      expect(lesson.rounds.first.publicationState, _published);
      expect(lesson.rounds.first.exercises.single.publicationState, _published);
    });
  });
}

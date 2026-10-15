import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/answer_grader.dart';
import 'package:quisquislingo_app/services/publish_gate.dart';
import 'package:quisquislingo_app/services/round_type_compatibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 273 Revision 3: the owner's decisions of 15 October 2026 on the
/// differences Revisions 1 and 2 found.
/// 1. The Round type is checked before Apply wherever an exercise is
///    applied (the preset form and the Round editor's list too, not only
///    the canonical editor), with the Audit's own rule (a Before you start
///    card is exempt except in a FlashCard or a Test Round).
/// 2. A refused Preview lists "CODE: message" in both exercise forms.
/// 3. Gaps typed into follow the exercise's capitals, punctuation, spaces
///    and accents options, and never forgive a typo.
final _stamp = DateTime.utc(2026, 10, 15);

final Map<String, dynamic> _labJson =
    jsonDecode(
          File(
            'assets/courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

/// The Laboratory's Content entry [id], as JSON.
Map<String, dynamic> _content(String id) {
  for (final lesson in _labJson['lessons'] as List) {
    for (final round in (lesson as Map)['rounds'] as List) {
      for (final content in (round as Map)['content'] as List) {
        if ((content as Map)['id'] == id) {
          return jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
        }
      }
    }
  }
  throw StateError('no Content $id');
}

Exercise _lab(String id) => LearningContent.fromJson(_content(id)).exercise!;

/// The Laboratory exercise [id] with [options] added to its own.
Exercise _labWith(String id, Map<String, String> options) {
  final json = _content(id);
  final exercise = json['exercise'] as Map<String, dynamic>;
  exercise['options'] = {
    ...(exercise['options'] as Map? ?? const {}),
    ...options,
  };
  return LearningContent.fromJson(json).exercise!;
}

Exercise _choice(String id) => _lab(
  'qql_lab254_select_single',
).copyWith(id: id, publicationState: PublicationState.draft);

Exercise _card(String id) => _lab(
  'qql_lab254_intro_select_basics',
).copyWith(id: id, publicationState: PublicationState.draft);

LearningRound _round(RoundType type, List<Exercise> exercises) => LearningRound(
  id: 'r3-round',
  title: 'Round',
  updatedAt: _stamp,
  publicationState: PublicationState.draft,
  roundType: type,
  visualType: type == RoundType.listening ? 'listening' : 'generic',
  exercises: exercises,
);

Course _course(LearningRound round) => Course(
  courseId: 'r3-course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision 3 course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'r3-lesson',
      title: 'Lesson',
      publicationState: PublicationState.draft,
      updatedAt: _stamp,
      guidebook: testGuidebook(
        moduleId: 'r3_module',
        overview: 'Reviewed overview.',
        words: [testEntry('r3_word', 'casa = house')],
      ),
      rounds: [round],
    ),
  ],
);

const _audioRequired =
    'This required exercise does not structurally require audio.';

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PublishGate.roundTypeIssues', () {
    test('no Round, nothing to check', () {
      expect(PublishGate.roundTypeIssues(null, _choice('x')), isEmpty);
    });

    test('a choice in a Listen Round breaks it; not when not required', () {
      final exercise = _choice('x');
      expect(
        PublishGate.roundTypeIssues(
          _round(RoundType.listening, [exercise]),
          exercise,
        ),
        [RoundTypeIssue.audioRequired],
      );
      // An exercise the Round does not hold yet counts as required.
      expect(
        PublishGate.roundTypeIssues(
          _round(RoundType.listening, const []),
          exercise,
        ),
        [RoundTypeIssue.audioRequired],
      );
      final optional = LearningRound(
        id: 'r3-round',
        title: 'Round',
        updatedAt: _stamp,
        roundType: RoundType.listening,
        visualType: 'listening',
        content: [
          LearningContent.fromJson({
            ...LearningContent.fromExercise(exercise).toJson(),
            'required': false,
          }),
        ],
      );
      expect(PublishGate.roundTypeIssues(optional, exercise), isEmpty);
    });

    test('a Before you start card is exempt, except in FlashCard and Test', () {
      final card = _card('card');
      expect(
        PublishGate.roundTypeIssues(_round(RoundType.listening, [card]), card),
        isEmpty,
      );
      expect(
        PublishGate.roundTypeIssues(_round(RoundType.flashcard, [card]), card),
        isNotEmpty,
      );
      expect(
        PublishGate.roundTypeIssues(_round(RoundType.test, [card]), card),
        [RoundTypeIssue.evaluatableOnly],
      );
    });

    test('the list\'s one-line refusal', () {
      expect(
        PublishGate.roundTypeRefusal(const [RoundTypeIssue.audioRequired]),
        'Exercise cannot be applied as normal content: $_audioRequired',
      );
    });
  });

  group('gaps follow the exercise\'s options, never typos', () {
    const grader = AnswerGrader();
    const id = 'qql_lab254_input_missing_many';

    test('capitals: ignored by default, counted when exact', () {
      expect(
        grader.missingWords(ExerciseFeatures(_lab(id)), [
          'Legge',
          'libro',
          'giardino',
        ]),
        isTrue,
      );
      expect(
        grader.missingWords(
          ExerciseFeatures(_labWith(id, {'caseHandling': 'exact'})),
          ['Legge', 'libro', 'giardino'],
        ),
        isFalse,
      );
    });

    test('a wrong accent: refused by default, accepted when ignored', () {
      expect(
        grader.missingWords(ExerciseFeatures(_lab(id)), [
          'lègge',
          'libro',
          'giardino',
        ]),
        isFalse,
      );
      expect(
        grader.missingWords(
          ExerciseFeatures(_labWith(id, {'accentHandling': 'ignore'})),
          ['lègge', 'libro', 'giardino'],
        ),
        isTrue,
      );
    });

    test('a gap is trimmed first, as one typed answer is', () {
      expect(
        grader.missingWords(
          ExerciseFeatures(_labWith(id, {'whitespaceHandling': 'exact'})),
          ['legge ', ' libro', 'giardino'],
        ),
        isTrue,
      );
    });

    test('a doubled letter is never forgiven in a gap', () {
      final tolerant = ExerciseFeatures(
        _labWith(id, {'typoTolerance': 'conservative'}),
      );
      expect(tolerant.toleratesTypos, isTrue);
      expect(
        grader.missingWords(tolerant, ['legge', 'libro', 'giarddino']),
        isFalse,
      );
    });
  });

  group('the preset form', () {
    Future<Exercise?> apply(
      WidgetTester tester,
      Exercise exercise,
      LearningRound round, {
      String key = 'exercise-save',
      bool isNew = false,
    }) async {
      _viewport(tester);
      Exercise? saved;
      final course = _course(round);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Exercise',
            isNew: isNew,
            course: course,
            lesson: course.lessons.single,
            round: round,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(Key(key));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      return saved;
    }

    testWidgets('Apply refuses an exercise that breaks its Round type', (
      tester,
    ) async {
      final exercise = _choice('choice');
      final saved = await apply(
        tester,
        exercise,
        _round(RoundType.listening, [exercise]),
      );
      expect(find.text('Round type compatibility'), findsOneWidget);
      expect(find.text(_audioRequired), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
    });

    testWidgets('a new exercise is checked too', (tester) async {
      final saved = await apply(
        tester,
        _choice('new-choice'),
        _round(RoundType.listening, const []),
        isNew: true,
      );
      expect(find.text('Round type compatibility'), findsOneWidget);
      expect(saved, isNull);
    });

    testWidgets('Apply as draft is not checked', (tester) async {
      final exercise = _choice('choice');
      final saved = await apply(
        tester,
        exercise,
        _round(RoundType.listening, [exercise]),
        key: 'exercise-save-draft',
      );
      expect(find.text('Round type compatibility'), findsNothing);
      expect(saved?.publicationState, PublicationState.draft);
    });

    testWidgets('a Before you start card in a Listen Round is applied', (
      tester,
    ) async {
      final card = _card('card');
      final saved = await apply(
        tester,
        card,
        _round(RoundType.listening, [card]),
      );
      expect(find.text('Round type compatibility'), findsNothing);
      if (find.text('Use anyway').evaluate().isNotEmpty) {
        await tester.tap(find.text('Use anyway'));
        await tester.pumpAndSettle();
      }
      expect(saved?.publicationState, PublicationState.published);
    });

    testWidgets('a refused Preview lists CODE: message', (tester) async {
      final page = Exercise.canonical(
        id: 'page',
        updatedAt: _stamp,
        primitive: ExercisePrimitive.presentation,
        promptElements: const [
          PromptElement(role: 'block', type: 'text', text: 'A page'),
          PromptElement(
            role: 'block',
            type: 'link',
            text: 'Example',
            url: 'http://example.org',
          ),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
      );
      await apply(
        tester,
        page,
        _round(RoundType.practice, [page]),
        key: 'exercise-preview',
      );
      expect(find.text('Complete these fields to Preview'), findsOneWidget);
      expect(find.textContaining('PAGE_LINK_INVALID: '), findsOneWidget);
    });
  });

  testWidgets('the canonical editor keeps its check, with the card exempt', (
    tester,
  ) async {
    _viewport(tester);
    final card = _card('card');
    final round = _round(RoundType.listening, [card]);
    Exercise? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: PrimitiveEditorScreen(
          exercise: card,
          title: 'Card',
          isNew: false,
          round: round,
          onExerciseSaved: (e) => saved = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('primitive-round-type-warning')), findsNothing);
    final save = find.byKey(const Key('primitive-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    if (find.text('Use anyway').evaluate().isNotEmpty) {
      await tester.tap(find.text('Use anyway'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Round type compatibility'), findsNothing);
    expect(saved?.publicationState, PublicationState.published);
  });

  testWidgets('the Round editor\'s list refuses it in one line', (
    tester,
  ) async {
    _viewport(tester);
    final exercise = _choice('choice');
    final round = _round(RoundType.listening, [exercise]);
    final course = _course(round);
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: course.lessons.single,
          round: round,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-actions-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Exercise cannot be applied as normal content: $_audioRequired',
      ),
      findsOneWidget,
    );
  });
}

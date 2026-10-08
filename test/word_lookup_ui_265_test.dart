import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/lesson_presentation_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/widgets/exercise_prompt_panels.dart';
import 'package:quisquislingo_app/widgets/word_lookup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';
import 'support/guidebook_fixtures.dart';

/// Build 265 Revision 1: the Word Lookup card on the learner's text, the
/// Course switch, the one-time notice, and where lookup never appears.
const _learnerId = '00000000-0000-4000-8000-000000000265';
const _created = '2026-10-06T00:00:00.000Z';
final _stamp = DateTime.utc(2026, 10, 6);

GuidebookEntry _word(String id, String text) => testEntry(id, text);

Exercise _choose(String id, String question, {TextLanguage? language}) =>
    Exercise.canonical(
      id: id,
      primitive: ExercisePrimitive.select,
      promptElements: [
        PromptElement(
          type: 'text',
          role: 'question',
          text: question,
          language: language,
        ),
      ],
      items: [
        ExerciseItem(
          id: '${id}_a',
          content: [PromptElement(type: 'text', text: 'Yes')],
        ),
        ExerciseItem(
          id: '${id}_b',
          content: [PromptElement(type: 'text', text: 'No')],
        ),
      ],
      canonicalEvaluation: CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['${id}_a'],
      ),
      updatedAt: _stamp,
    );

Exercise _page(String id, String paragraph) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.presentation,
  promptElements: [PromptElement(type: 'text', role: 'block', text: paragraph)],
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

LearningRound _round(
  List<Exercise> exercises, {
  RoundType roundType = RoundType.practice,
}) => LearningRound(
  id: 'round-$roundType',
  title: 'Animals',
  roundType: roundType,
  updatedAt: _stamp,
  content: [for (final e in exercises) LearningContent.fromExercise(e)],
);

Course _course(
  LearningRound round, {
  bool useGuidebook = true,
  bool wordLookup = true,
}) => Course(
  courseId: 'word-lookup-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _learnerId,
    displayName: 'Lookup learner',
  ),
  originalCreatedAtUtc: _created,
  maintainer: const CourseMaintainer(_learnerId),
  lastVersionEditorProfileId: _learnerId,
  lastVersionEditorDisplayName: 'Lookup learner',
  modifiedAtUtc: _created,
  title: 'Word Lookup',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  useGuidebook: useGuidebook,
  wordLookup: wordLookup,
  lessons: [
    Lesson(
      lessonId: 'animals',
      title: 'Animali',
      guidebook: testGuidebook(
        moduleId: 'animals-module',
        words: [
          _word('w1', 'il gatto = the cat'),
          _word('w2', 'il pane = the bread'),
          _word('w3', 'dorme = sleeps'),
        ],
      ),
      rounds: [round],
    ),
    Lesson(
      lessonId: 'more',
      title: 'Altro',
      guidebook: testGuidebook(
        moduleId: 'more-module',
        words: [_word('w4', 'il cane = the dog')],
      ),
      rounds: [
        LearningRound(
          id: 'other-round',
          title: 'Other',
          content: [LearningContent.fromExercise(_choose('o1', 'Il cane.'))],
        ),
      ],
    ),
  ],
);

void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (_) async => null,
  );
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpRound(
  WidgetTester tester,
  Course course, {
  bool preview = false,
  Finder? waitFor,
  Size size = const Size(1000, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final lesson = course.lessons.first;
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: lesson,
        round: lesson.rounds.single,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
      ),
    ),
  );
  await _until(
    tester,
    waitFor ?? find.byKey(const Key('select-question-text')),
  );
}

/// Taps the middle of [word] inside the [Text] that [text] finds.
Future<void> _tapWord(WidgetTester tester, Finder text, String word) async {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final plain = paragraph.text.toPlainText();
  final start = plain.indexOf(word);
  expect(start, greaterThanOrEqualTo(0), reason: '"$word" in "$plain"');
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + word.length),
  );
  await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
  await tester.pump();
}

Exercise _line(String id, String text, {String speakerId = ''}) =>
    ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: Exercise.canonical(
          id: id,
          primitive: ExercisePrimitive.presentation,
          canonicalEvaluation: CanonicalEvaluation.none,
          updatedAt: _stamp,
        ),
        type: 'dialogue_line',
        publicationState: PublicationState.published,
        prompt: text,
        speakerId: speakerId,
        lineMode: 'text',
      ),
    ).candidate!;

Course _storyCourse() {
  final content = [
    LearningContent.fromExercise(_line('n1', 'The cat, il gatto, sleeps.')),
    LearningContent.fromExercise(
      _line('a1', 'Il gatto dorme.', speakerId: 'character_anna'),
    ),
  ];
  final course = _course(
    LearningRound(
      id: 'story',
      title: 'Story',
      visualType: 'story',
      roundType: RoundType.story,
      updatedAt: _stamp,
      content: content,
      flow: RoundFlowAuthoring.linearFor(content, title: 'Al bar'),
    ),
  );
  return Course.fromJson({
    ...course.toJson(),
    'storyNarrator': const StorySpeaker(
      name: 'Narrator',
      language: TextLanguage.source,
    ).toJson(),
    'storyCharacters': [
      const StorySpeaker(
        id: 'character_anna',
        name: 'Anna',
        language: TextLanguage.target,
      ).toJson(),
    ],
  });
}

final _card = find.byKey(const Key('word-lookup-card'));
final _question = find.byKey(const Key('select-question-text'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
    });
    await ProfileService().createProfile(
      'Lookup learner',
      learnerProfileId: _learnerId,
      generateScreenNameSuffix: false,
    );
    _platforms();
    keepCrashLogUnavailable();
  });

  group('the card', () {
    testWidgets('a tap on a word shows its entry and the note', (tester) async {
      final course = _course(
        _round([_choose('q', 'Il gatto dorme sul letto.')]),
      );
      await _pumpRound(tester, course);
      expect(_card, findsNothing);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      final entry = find.byKey(const ValueKey('word-lookup-entry-0'));
      expect(
        find.descendant(of: entry, matching: find.text('il gatto')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: entry, matching: find.text('the cat')),
        findsOneWidget,
      );
      // An entry of the current Lesson names no Lesson (owner decision).
      expect(find.byKey(const ValueKey('word-lookup-lesson-0')), findsNothing);
      expect(
        find.text(
          const LessonPresentationService().identity(course, 0).fullText,
        ),
        findsNothing,
      );
      expect(
        find.text("One possible translation from this Course's GuideBook."),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('word-lookup-entry-1')), findsNothing);
      // The question keeps its key and its words.
      expect(
        tester.widget<Text>(_question).textSpan?.toPlainText(),
        'Il gatto dorme sul letto.',
      );
    });

    testWidgets('an entry from another Lesson names that Lesson', (
      tester,
    ) async {
      final course = _course(_round([_choose('q', 'Il cane dorme.')]));
      await _pumpRound(tester, course);
      await _tapWord(tester, _question, 'cane');
      expect(_card, findsOneWidget);
      expect(find.text('the dog'), findsOneWidget);
      final lesson = find.byKey(const ValueKey('word-lookup-lesson-0'));
      expect(
        tester.widget<Text>(lesson).data,
        const LessonPresentationService().identity(course, 1).fullText,
      );
    });

    testWidgets('a word without an entry does nothing', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme sul letto.')])),
      );
      await _tapWord(tester, _question, 'letto');
      expect(_card, findsNothing);
      // The plain question keeps its data, as before Build 265.
      expect(tester.widget<Text>(_question).data, 'Il gatto dorme sul letto.');
    });

    testWidgets('the expression wins, and another word opens its own card', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme. Mangio il pane.')])),
      );
      await _tapWord(tester, _question, 'pane');
      expect(find.text('il pane'), findsOneWidget);
      expect(find.text('the bread'), findsOneWidget);
      await _tapWord(tester, _question, 'dorme');
      expect(_card, findsOneWidget);
      expect(find.text('sleeps'), findsOneWidget);
      expect(find.text('the bread'), findsNothing);
    });

    testWidgets('Escape and a tap elsewhere close the card', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme sul letto.')])),
      );
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_card, findsNothing);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      await tester.tapAt(const Offset(500, 1500));
      await tester.pump();
      expect(_card, findsNothing);
      // The same word again opens it again; a second tap on it closes it.
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsNothing);
    });

    testWidgets('scrolling the page closes the card', (tester) async {
      await _pumpRound(
        tester,
        _course(
          _round([
            _choose(
              'q',
              'Il gatto dorme. ${List.filled(60, 'Il gatto dorme.').join(' ')}',
            ),
          ]),
        ),
        size: const Size(400, 600),
      );
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pump();
      expect(_card, findsNothing);
    });

    // Build 265 Revision 4: the card's own scrolling reached the scope and
    // closed it, so a long card could not be read past its first entries.
    testWidgets('scrolling inside a long card keeps it open', (tester) async {
      final page = ScrollController();
      addTearDown(page.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordLookupScope(
              index: WordLookupIndex.build([
                for (var i = 0; i < 15; i++)
                  WordLookupSourceEntry(
                    id: 'e$i',
                    target: 'gatto',
                    source: 'cat number $i',
                    lessonIndex: 0,
                  ),
              ]),
              currentLessonIndex: 0,
              lessonName: (_) => '',
              note: 'One possible translation.',
              notePlural: 'Some possible translations.',
              actionLabel: 'Vocabulary in this text',
              child: ListView(
                controller: page,
                children: [
                  LookupText('gatto', textKey: const Key('word')),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
      await _tapWord(tester, find.byKey(const Key('word')), 'gatto');
      await tester.pumpAndSettle();
      expect(_card, findsOneWidget);
      expect(
        find.byKey(const ValueKey('word-lookup-entry-14')),
        findsOneWidget,
      );
      await tester.drag(_card, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(page.offset, 0);
      expect(_card, findsOneWidget);
    });

    testWidgets('looking a word up records nothing', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme sul letto.')])),
      );
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      final before = {
        for (final key in prefs!.getKeys()) key: prefs.get(key).toString(),
      };
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      final after = {
        for (final key in prefs.getKeys()) key: prefs.get(key).toString(),
      };
      expect(after, before);
    });
  });

  group('the dotted marks (owner decision)', () {
    final marks = find.byKey(const Key('word-lookup-marks'));

    testWidgets('words with entries are underlined with dots', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme sul letto.')])),
      );
      expect(find.ancestor(of: _question, matching: marks), findsOneWidget);
      expect(tester.renderObject(marks), paints..line());
      // The text itself is unchanged.
      expect(tester.widget<Text>(_question).data, 'Il gatto dorme sul letto.');
    });

    testWidgets("nothing to mark, or the learner's own language: no marks", (
      tester,
    ) async {
      await _pumpRound(tester, _course(_round([_choose('q', 'Luca legge.')])));
      expect(marks, findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pumpRound(
        tester,
        _course(
          _round([
            _choose('q', 'Il gatto dorme.', language: TextLanguage.source),
          ]),
        ),
      );
      expect(marks, findsNothing);
    });
  });

  group('no lookup', () {
    Future<void> expectNoCard(WidgetTester tester, Course course) async {
      await _pumpRound(tester, course);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsNothing);
      expect(find.byType(WordLookupScope), findsNothing);
    }

    testWidgets('in a Test Round', (tester) async {
      await expectNoCard(
        tester,
        _course(
          _round([_choose('q', 'Il gatto dorme.')], roundType: RoundType.test),
        ),
      );
    });

    testWidgets('with Use GuideBook off', (tester) async {
      await expectNoCard(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme.')]), useGuidebook: false),
      );
    });

    testWidgets('with Word Lookup off', (tester) async {
      await expectNoCard(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme.')]), wordLookup: false),
      );
    });

    testWidgets('on text in the learner\'s own language', (tester) async {
      final course = _course(
        _round([
          _choose(
            'q',
            'Il gatto: the cat sleeps.',
            language: TextLanguage.source,
          ),
        ]),
      );
      await _pumpRound(tester, course);
      expect(find.byType(WordLookupScope), findsOneWidget);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsNothing);
    });

    testWidgets('in the panels the Duel shares, without a scope', (
      tester,
    ) async {
      final exercise = Exercise.canonical(
        id: 'duel',
        primitive: ExercisePrimitive.select,
        promptElements: [
          PromptElement(type: 'text', role: 'passage', text: 'Il gatto dorme.'),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
        updatedAt: _stamp,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExercisePromptPanels(
              features: ExerciseFeatures(exercise),
              panelColor: Colors.white,
            ),
          ),
        ),
      );
      final passage = find.descendant(
        of: find.byKey(const Key('exercise-passage')),
        matching: find.byType(Text),
      );
      expect(tester.widget<Text>(passage).data, 'Il gatto dorme.');
      await _tapWord(tester, passage, 'gatto');
      expect(_card, findsNothing);
    });
  });

  group('other surfaces', () {
    testWidgets('a Story line in the learning language, not the narrator', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _storyCourse(),
        preview: true,
        waitFor: find.byKey(const Key('story-line-narrator')),
      );
      final narrator = find.descendant(
        of: find.byKey(const Key('story-line-narrator')),
        matching: find.text('The cat, il gatto, sleeps.'),
      );
      await _tapWord(tester, narrator, 'gatto');
      expect(_card, findsNothing);
      await tester.tap(find.byKey(const Key('story-line-continue')));
      await _until(tester, find.byKey(const Key('story-line-bubble')));
      final line = find.descendant(
        of: find.byKey(const Key('story-line-bubble')),
        matching: find.text('Il gatto dorme.'),
      );
      await _tapWord(tester, line, 'gatto');
      expect(_card, findsOneWidget);
    });

    testWidgets('never on the authored Instruction', (tester) async {
      final exercise = Exercise.canonical(
        id: 'q',
        primitive: ExercisePrimitive.select,
        promptElements: [
          PromptElement(
            type: 'text',
            role: 'primary',
            text: 'Il gatto, prego.',
          ),
          PromptElement(
            type: 'text',
            role: 'question',
            text: 'Il gatto dorme.',
          ),
        ],
        items: [
          ExerciseItem(
            id: 'q_a',
            content: [PromptElement(type: 'text', text: 'Yes')],
          ),
          ExerciseItem(
            id: 'q_b',
            content: [PromptElement(type: 'text', text: 'No')],
          ),
        ],
        canonicalEvaluation: CanonicalEvaluation(
          mode: EvaluationMode.exactItem,
          correctItemIds: ['q_a'],
        ),
        updatedAt: _stamp,
      );
      await _pumpRound(tester, _course(_round([exercise])));
      final instruction = find.byKey(const Key('exercise-instruction'));
      expect(tester.widget<Text>(instruction).data, 'Il gatto, prego.');
      await _tapWord(tester, instruction, 'gatto');
      expect(_card, findsNothing);
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
    });

    testWidgets('the Preview looks words up too', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme.')])),
        preview: true,
      );
      await _tapWord(tester, _question, 'gatto');
      expect(_card, findsOneWidget);
    });

    testWidgets('a Page paragraph keeps its marks and looks words up', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(_round([_page('p', 'Il **gatto** dorme.')])),
        waitFor: find.byKey(const Key('page-card')),
      );
      final paragraph = find.descendant(
        of: find.byKey(const ValueKey('page-block-0')),
        matching: find.byType(Text),
      );
      await _tapWord(tester, paragraph, 'gatto');
      expect(_card, findsOneWidget);
      expect(find.text('the cat'), findsOneWidget);
    });
  });

  group('keyboard and screen readers', () {
    const text = 'Il gatto dorme. Mangio il pane.';

    List<String> cardTargets(WidgetTester tester) {
      final targets = <String>[];
      for (var i = 0; ; i++) {
        final entry = find.byKey(ValueKey('word-lookup-entry-$i'));
        if (entry.evaluate().isEmpty) return targets;
        targets.add(
          tester
              .widgetList<Text>(
                find.descendant(of: entry, matching: find.byType(Text)),
              )
              .first
              .data!,
        );
      }
    }

    testWidgets('Tab reaches the text and Enter lists its entries', (
      tester,
    ) async {
      await _pumpRound(tester, _course(_round([_choose('q', text)])));
      for (var i = 0; i < 30; i++) {
        if (FocusManager.instance.primaryFocus?.debugLabel == 'word lookup') {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'word lookup');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_card, findsOneWidget);
      expect(cardTargets(tester), ['il gatto', 'dorme', 'il pane']);
      // Several entries: the line is plural (owner request).
      expect(
        find.text("Some possible translations from this Course's GuideBook."),
        findsOneWidget,
      );
      expect(
        find.text("One possible translation from this Course's GuideBook."),
        findsNothing,
      );
      // The whole text is listed, so no word is highlighted.
      expect(tester.widget<Text>(_question).data, text);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_card, findsNothing);
    });

    testWidgets('screen readers get "Vocabulary in this text"', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRound(tester, _course(_round([_choose('q', text)])));
      const action = CustomSemanticsAction(label: 'Vocabulary in this text');
      final node = find.semantics.byLabel(text);
      expect(
        node.evaluate().single.getSemanticsData().customSemanticsActionIds,
        contains(CustomSemanticsAction.getIdentifier(action)),
      );
      tester.semantics.performAction(
        node,
        SemanticsAction.customAction,
        args: CustomSemanticsAction.getIdentifier(action),
      );
      await tester.pump();
      expect(_card, findsOneWidget);
      expect(cardTargets(tester), ['il gatto', 'dorme', 'il pane']);
      semantics.dispose();
    });

    testWidgets('a text with nothing to look up takes no focus', (
      tester,
    ) async {
      await _pumpRound(tester, _course(_round([_choose('q', 'Luca legge.')])));
      expect(
        find
            .ancestor(of: _question, matching: find.byType(Focus))
            .evaluate()
            .where(
              (element) =>
                  (element.widget as Focus).focusNode?.debugLabel ==
                  'word lookup',
            ),
        isEmpty,
      );
    });
  });

  group('the one-time notice', () {
    setUp(() => WordLookupNotice.enabled = true);
    tearDown(() => WordLookupNotice.enabled = false);

    testWidgets('once per learner and Course, again after a reset', (
      tester,
    ) async {
      final course = _course(_round([_choose('q', 'Il gatto dorme.')]));
      await _pumpRound(tester, course);
      await _until(tester, find.byKey(const Key('word-lookup-notice')));
      expect(
        find.text(
          "Tap a word with a dotted underline to see a translation from "
          "this Course's GuideBook. Only some exercise types have them. It is "
          "a hint, one possible translation: it does not always match the "
          "answer to the exercise.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('word-lookup-notice-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('word-lookup-notice')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await _pumpRound(tester, course);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('word-lookup-notice')), findsNothing);

      await tester.runAsync(() => SettingsService().resetOneTimeNotices());
      await tester.pumpWidget(const SizedBox());
      await _pumpRound(tester, course);
      await _until(tester, find.byKey(const Key('word-lookup-notice')));
    });

    testWidgets('not in the Preview, nor where lookup is off', (tester) async {
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme.')])),
        preview: true,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('word-lookup-notice')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pumpRound(
        tester,
        _course(_round([_choose('q', 'Il gatto dorme.')]), wordLookup: false),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('word-lookup-notice')), findsNothing);
    });
  });

  group('the Course switch', () {
    test('stored only when off, strictly a boolean', () {
      final on = _course(_round([_choose('q', 'Il gatto.')]));
      expect(on.toJson().containsKey('wordLookup'), isFalse);
      expect(Course.fromJson(on.toJson()).wordLookup, isTrue);
      final off = _course(
        _round([_choose('q', 'Il gatto.')]),
        wordLookup: false,
      );
      expect(off.toJson()['wordLookup'], isFalse);
      expect(Course.fromJson(off.toJson()).wordLookup, isFalse);
      expect(
        () => Course.fromJson({...off.toJson(), 'wordLookup': 'no'}),
        throwsFormatException,
      );
    });

    test('Copy as New Course keeps it', () {
      final off = _course(
        _round([_choose('q', 'Il gatto.')]),
        wordLookup: false,
      );
      final copy = AuthoringDuplicationService().copyCourseAsNew(
        off,
        title: 'Copy',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: _learnerId,
          displayName: 'Lookup learner',
        ),
        maintainer: const CourseMaintainer(_learnerId),
      );
      expect(copy.wordLookup, isFalse);
    });

    testWidgets('Lesson Options shows it only while Use GuideBook is on', (
      tester,
    ) async {
      await tester.runAsync(SettingsService().completeWelcomeWizard);
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: _course(_round([_choose('q', 'Il gatto.')])),
            userCourse: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-lesson-options')));
      await tester.pumpAndSettle();
      final lookup = find.byKey(const Key('course-word-lookup'));
      await tester.ensureVisible(lookup);
      expect(tester.widget<SwitchListTile>(lookup).value, isTrue);
      await tester.tap(lookup);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(lookup).value, isFalse);
      final guidebook = find.byKey(const Key('course-use-guidebook'));
      await tester.ensureVisible(guidebook);
      await tester.tap(guidebook);
      await tester.pumpAndSettle();
      // Build 267: turning the GuideBook off asks first.
      await tester.tap(find.byKey(const Key('course-use-guidebook-turn-off')));
      await tester.pumpAndSettle();
      expect(lookup, findsNothing);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/correct_answer_text.dart';
import 'package:quisquislingo_app/services/course_audio_usage.dart';
import 'package:quisquislingo_app/services/exercise_mascot_policy.dart';
import 'package:quisquislingo_app/services/playback_on_request.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/translation_choice_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/exercise_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 274 Revision 2: playback on request (the owner's points 4 and 6 of
/// 13 October 2026, and the decision of 15 October 2026 on Select the
/// image's words). Nothing plays by itself; a speaker is offered for
/// target-language text only.
const _asset = 'assets/courses/exercise_laboratory_en_it.json';

final _course = Course.fromJson(
  jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>,
);

Exercise _example(String id) => [
  for (final lesson in _course.lessons)
    for (final round in lesson.rounds) ...round.exercises,
].firstWhere((exercise) => exercise.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _platforms();
    keepCrashLogUnavailable();
  });

  group('the owner of what may be heard', () {
    test('Type the translation into the target: the answer, once answered', () {
      final ex = _example('qql_lab254_input_literal');
      final f = ExerciseFeatures(ex);
      expect(PlaybackOnRequest.promptText(f), isNull);
      expect(PlaybackOnRequest.answerText(ex, f, answered: false), isNull);
      expect(PlaybackOnRequest.answerText(ex, f, answered: true), 'grazie');
    });

    test('an answer expression is heard as its first answer', () {
      final ex = _example('qql_lab254_input_optional');
      final f = ExerciseFeatures(ex);
      expect(
        PlaybackOnRequest.answerText(ex, f, answered: true),
        CorrectAnswerText.variantOf('{io} mangio una mela'),
      );
      expect(
        PlaybackOnRequest.answerText(ex, f, answered: true),
        isNot(contains('{')),
      );
    });

    test('Type the translation into the source: the sentence, any time', () {
      final ex = _example('qql_lab254_type_source_literal');
      final f = ExerciseFeatures(ex);
      expect(PlaybackOnRequest.promptText(f), 'Grazie.');
      // The answer is in the source language: nothing to hear.
      expect(PlaybackOnRequest.answerText(ex, f, answered: true), isNull);
    });

    test('an Instruction or context is never heard as the sentence', () {
      final ex = _example('qql_lab254_type_source_literal');
      final base = ex.promptElements.first;
      final instructed = ex.copyWith(
        promptElements: [
          PromptElement(
            type: base.type,
            role: 'primary',
            text: 'Translate what the waiter says.',
          ),
          PromptElement(
            type: base.type,
            role: 'clue',
            text: 'Grazie.',
            language: TextLanguage.target,
          ),
        ],
      );
      final f = ExerciseFeatures(instructed);
      // Still a translation into the source, with a target-language clue.
      expect(f.kind, LearnerExerciseKind.inputTranslation);
      expect(f.promptLanguage, TextLanguage.target);
      expect(PlaybackOnRequest.promptText(f), isNull);
    });

    test(
      'Build the translation: the answer the blocks make, once answered',
      () {
        final ex = _example('qql_lab254_build_single');
        final f = ExerciseFeatures(ex);
        expect(PlaybackOnRequest.promptText(f), isNull);
        expect(PlaybackOnRequest.answerText(ex, f, answered: false), isNull);
        expect(
          PlaybackOnRequest.answerText(ex, f, answered: true),
          'Bevo acqua',
        );
        final source = _example('qql_lab254_build_source_single');
        final sourceFeatures = ExerciseFeatures(source);
        expect(PlaybackOnRequest.promptText(sourceFeatures), isNotEmpty);
        expect(
          PlaybackOnRequest.answerText(source, sourceFeatures, answered: true),
          isNull,
        );
      },
    );

    test('Pick the translation hears what it heard before', () {
      // Into the target: the right answer, once answered.
      final toTarget = _example('qql_lab254_translation_target_two');
      final target = ExerciseFeatures(toTarget);
      expect(PlaybackOnRequest.promptText(target), isNull);
      expect(
        PlaybackOnRequest.answerText(toTarget, target, answered: false),
        isNull,
      );
      expect(
        PlaybackOnRequest.answerText(toTarget, target, answered: true),
        'Buongiorno.',
      );
      // Into the source: the question, any time; the answers not at all.
      final toSource = _example('qql_lab254_translation_source_two');
      final source = ExerciseFeatures(toSource);
      expect(PlaybackOnRequest.promptText(source), 'Grazie.');
      expect(
        PlaybackOnRequest.answerText(toSource, source, answered: true),
        isNull,
      );
      // As `TranslationChoice` decided before this revision.
      for (final f in [target, source]) {
        expect(
          PlaybackOnRequest.promptText(f) ??
              PlaybackOnRequest.answerText(
                f == target ? toTarget : toSource,
                f,
                answered: true,
              ),
          TranslationChoice.spokenTextFor(f, answered: true),
        );
      }
    });

    test('Select the image: a named icon\'s word, never a picture', () {
      final icons = _example('qql_lab254_select_named_icons');
      final f = ExerciseFeatures(icons);
      expect(
        [for (final item in f.items) PlaybackOnRequest.optionWord(f, item)],
        ['sole', 'luna', 'albero'],
      );
      for (final id in [
        'qql_lab254_select_asset_options',
        'qql_lab254_listening_image',
      ]) {
        final pictures = ExerciseFeatures(_example(id));
        for (final item in pictures.items) {
          expect(PlaybackOnRequest.optionWord(pictures, item), isNull);
        }
      }
    });

    test('a listening exercise never says its answers', () {
      // Listen and pick the image with named icons: a speaker on an option
      // would give the answer away.
      final listening = _example(
        'qql_lab254_listening_image',
      ).copyWith(items: _example('qql_lab254_select_named_icons').items);
      final f = ExerciseFeatures(listening);
      expect(f.kind, isNot(LearnerExerciseKind.selectImage));
      for (final item in f.items) {
        expect(PlaybackOnRequest.optionWord(f, item), isNull);
      }
    });

    test('several answers are drawn without the picture grid: no speaker', () {
      final icons = _example('qql_lab254_select_named_icons');
      final multiple = icons.copyWith(
        options: icons.options.withEnum(
          OptionKey.selectionMode,
          SelectionMode.multiple,
        ),
      );
      final f = ExerciseFeatures(multiple);
      expect(f.multipleSelection, isTrue);
      for (final item in f.items) {
        expect(PlaybackOnRequest.optionWord(f, item), isNull);
      }
    });

    test('answers that fill gaps are drawn without the picture grid too', () {
      final icons = _example('qql_lab254_select_named_icons');
      final gapped = icons.copyWith(
        layout: const [
          LayoutElement.text('Il ___ splende.'),
          LayoutElement.target('gap'),
        ],
      );
      final f = ExerciseFeatures(gapped);
      expect(f.hasInlineTargets, isTrue);
      expect(f.kind, LearnerExerciseKind.selectImage);
      for (final item in f.items) {
        expect(PlaybackOnRequest.optionWord(f, item), isNull);
      }
    });

    test('a word marked as the source language is not heard', () {
      final icons = _example('qql_lab254_select_named_icons');
      final marked = icons.copyWith(
        items: [
          for (final item in icons.items)
            item.copyWith(
              content: [
                for (final element in item.content)
                  element.role == 'primary'
                      ? PromptElement(
                          type: element.type,
                          role: element.role,
                          text: element.text,
                          language: TextLanguage.source,
                        )
                      : element,
              ],
            ),
        ],
      );
      final f = ExerciseFeatures(marked);
      for (final item in f.items) {
        expect(PlaybackOnRequest.optionWord(f, item), isNull);
      }
    });

    test('Match pictures to words: its words, not Match the words', () {
      final ex = _example('qql_lab254_picture_word_match');
      final f = ExerciseFeatures(ex);
      for (final item in f.items) {
        expect(
          PlaybackOnRequest.optionWord(f, item),
          item.side == MatchSide.right ? item.label : isNull,
          reason: item.id,
        );
      }
      final words = ExerciseFeatures(_example('qql_lab254_match_four'));
      for (final item in words.items) {
        expect(PlaybackOnRequest.optionWord(words, item), isNull);
      }
    });

    test('a Match without sides: the sides the Round screen pairs', () {
      final ex = _example('qql_lab254_picture_word_match');
      final unsided = ex.copyWith(
        items: [
          for (final item in ex.items)
            ExerciseItem(id: item.id, content: item.content),
        ],
      );
      final f = ExerciseFeatures(unsided);
      expect(
        [for (final item in f.items) PlaybackOnRequest.optionWord(f, item)],
        [null, 'il gatto', null, 'il cane', null, 'la casa'],
      );
    });

    test('the Audio Library counts every text that may be heard', () {
      for (final (id, heard) in [
        ('qql_lab254_input_literal', ['grazie']),
        ('qql_lab254_type_source_literal', ['Grazie.']),
        ('qql_lab254_build_single', ['Bevo acqua']),
        ('qql_lab254_select_named_icons', ['sole', 'luna', 'albero']),
        ('qql_lab254_picture_word_match', ['il gatto', 'il cane', 'la casa']),
        ('qql_lab254_translation_target_two', ['Buongiorno.']),
      ]) {
        final ex = _example(id);
        expect(PlaybackOnRequest.texts(ex), heard, reason: id);
        expect(
          CourseAudioUsage.spokenTexts(ex),
          containsAll(heard),
          reason: id,
        );
      }
    });

    testWidgets('the mascot leaves room for the sentence\'s speaker', (
      tester,
    ) async {
      // 600 pixels: 476 pixels beside the mascot, 428 once the speaker has
      // its 48. A glyph of the test font is as wide as its size (16) plus
      // titleMedium's letter spacing (0.15), so 29 letters fit a line beside
      // the mascot and 26 beside the mascot and the speaker: 81 letters take
      // three lines without the speaker's room and four with it, 71 letters
      // take three either way. A sentence in the source language has no
      // speaker, so it keeps the whole room.
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ex = _example('qql_lab254_type_source_literal');
      Exercise sentence(
        int letters, [
        TextLanguage language = TextLanguage.target,
      ]) => ex.copyWith(
        promptElements: [
          PromptElement(
            type: ex.promptElements.first.type,
            role: 'primary',
            text: '${'a' * (letters - 1)}.',
            language: language,
          ),
        ],
      );
      final rooms = <int, ExerciseMascotRoom?>{};
      ExerciseMascotRoom? sourceRoom;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              for (final letters in [71, 81]) {
                rooms[letters] = ExerciseMascotRoom.of(
                  context,
                  sentence(letters),
                  promptAsInstruction: false,
                );
              }
              sourceRoom = ExerciseMascotRoom.of(
                context,
                sentence(81, TextLanguage.source),
                promptAsInstruction: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(rooms[71]?.anchor, ExerciseMascotAnchor.prompt);
      expect(rooms[81], isNull);
      expect(sourceRoom?.anchor, ExerciseMascotAnchor.prompt);
    });
  });

  group('the Round screen', () {
    testWidgets('Type the translation into the source: a speaker, on request', (
      tester,
    ) async {
      final speech = await _show(
        tester,
        _example('qql_lab254_type_source_literal'),
      );
      expect(speech.spoken, isEmpty);
      final speaker = find.byKey(const Key('translation-choice-audio'));
      expect(speaker, findsOneWidget);
      await tester.tap(speaker);
      await tester.pumpAndSettle();
      expect(speech.spoken, ['Grazie.']);
    });

    testWidgets('Build the translation into the target: Listen to the answer', (
      tester,
    ) async {
      final ex = _example('qql_lab254_build_single');
      final speech = await _show(tester, ex);
      expect(find.byKey(const Key('translation-choice-audio')), findsNothing);
      for (final id in ex.canonicalEvaluation.correctOrders.first.itemIds) {
        final value = ex.items.firstWhere((item) => item.id == id).value;
        final block = find.widgetWithText(ActionChip, value).first;
        await tester.ensureVisible(block);
        await tester.pumpAndSettle();
        await tester.tap(block);
        await tester.pumpAndSettle();
      }
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Listen to the answer'), findsOneWidget);
      expect(speech.spoken, isEmpty);
      await tester.tap(find.byKey(const Key('translation-choice-audio')));
      await tester.pumpAndSettle();
      expect(speech.spoken, ['Bevo acqua']);
    });

    testWidgets('a named icon\'s word is heard from its corner', (
      tester,
    ) async {
      final speech = await _show(
        tester,
        _example('qql_lab254_select_named_icons'),
      );
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('option-speaker-$i')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('option-speaker-0')));
      await tester.pumpAndSettle();
      expect(speech.spoken, hasLength(1));
      expect(['sole', 'luna', 'albero'], contains(speech.spoken.single));
      // The speaker does not answer.
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
    });

    testWidgets('Match pictures to words: each word in the menu', (
      tester,
    ) async {
      final ex = _example('qql_lab254_picture_word_match');
      final speech = await _show(tester, ex);
      // The closed fields show no speaker: it is in the menu.
      expect(_matchSpeakers(), findsNothing);
      final menu = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      final right = ex.items.where((item) => item.side == MatchSide.right);
      for (final item in right) {
        expect(
          find.byKey(ValueKey('match-word-speaker-${item.id}')),
          findsOneWidget,
          reason: item.id,
        );
      }
      final first = right.first;
      await tester.tap(find.byKey(ValueKey('match-word-speaker-${first.id}')));
      await tester.pumpAndSettle();
      expect(speech.spoken, [first.label]);
      // The speaker does not choose the word: the menu is still open.
      expect(
        find.byKey(ValueKey('match-word-speaker-${first.id}')),
        findsOneWidget,
      );
      // A word chosen: the closed field shows it, without a speaker.
      await tester.tap(find.text(first.label).last);
      await tester.pumpAndSettle();
      expect(_matchSpeakers(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>).first,
          matching: find.text(first.label),
        ),
        findsOneWidget,
      );
    });

    testWidgets('with the learner\'s audio off: greyed, and no word speakers', (
      tester,
    ) async {
      // Not a Preview: the learner's own Audio Exercises.
      await ProfileService().addProfile('Playback learner');
      final off = _Settings(audio: false);
      await _show(
        tester,
        _example('qql_lab254_select_named_icons'),
        preview: false,
        settings: off,
      );
      expect(find.byKey(const ValueKey('option-speaker-0')), findsNothing);
      await _show(
        tester,
        _example('qql_lab254_picture_word_match'),
        preview: false,
        settings: off,
      );
      await _openFirstMatchMenu(tester);
      expect(_matchSpeakers(), findsNothing);
      await _show(
        tester,
        _example('qql_lab254_type_source_literal'),
        preview: false,
        settings: off,
      );
      final speaker = tester.widget<IconButton>(
        find.byKey(const Key('translation-choice-audio')),
      );
      expect(speaker.onPressed, isNull);
      expect(
        find.byKey(const Key('translation-choice-audio-note')),
        findsOneWidget,
      );
      // With the learner's audio on, the same speakers as in the Preview.
      final on = _Settings(audio: true);
      await _show(
        tester,
        _example('qql_lab254_select_named_icons'),
        preview: false,
        settings: on,
      );
      expect(find.byKey(const ValueKey('option-speaker-0')), findsOneWidget);
      await _show(
        tester,
        _example('qql_lab254_type_source_literal'),
        preview: false,
        settings: on,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('translation-choice-audio')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        find.byKey(const Key('translation-choice-audio-note')),
        findsNothing,
      );
    });

    testWidgets('a 360-pixel phone has room for every speaker', (tester) async {
      for (final id in [
        'qql_lab254_type_source_literal',
        'qql_lab254_select_named_icons',
        'qql_lab254_picture_word_match',
      ]) {
        await _show(tester, _example(id), width: 360);
        expect(tester.takeException(), isNull, reason: id);
      }
      expect(find.byKey(const ValueKey('option-speaker-0')), findsNothing);
      await _openFirstMatchMenu(tester);
      expect(tester.takeException(), isNull);
      expect(_matchSpeakers(), findsNWidgets(3));
      await _show(
        tester,
        _example('qql_lab254_type_source_literal'),
        width: 360,
      );
      expect(find.byKey(const Key('translation-choice-audio')), findsOneWidget);
      await _show(
        tester,
        _example('qql_lab254_select_named_icons'),
        width: 360,
      );
      expect(find.byKey(const ValueKey('option-speaker-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Finder _matchSpeakers() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('match-word-speaker-'),
);

Future<void> _openFirstMatchMenu(WidgetTester tester) async {
  final menu = find.byType(DropdownButtonFormField<String>).first;
  await tester.ensureVisible(menu);
  await tester.pumpAndSettle();
  await tester.tap(menu);
  await tester.pumpAndSettle();
}

class _Settings extends SettingsService {
  _Settings({required this.audio});
  final bool audio;

  @override
  Future<bool> areAudioExercisesEnabled() async => audio;

  @override
  Future<bool> isTtsEnabled() async => audio;
}

class _Speech extends TtsCacheService {
  final spoken = <String>[];

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
}

Future<_Speech> _show(
  WidgetTester tester,
  Exercise exercise, {
  bool preview = true,
  SettingsService? settings,
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final round = LearningRound(
    id: 'r274_${exercise.id}',
    title: 'Playback on request',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'r274_lesson',
    title: 'Playback',
    rounds: [round],
  );
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: ValueKey('${exercise.id}-$preview-${settings.hashCode}-$width'),
        course: _course,
        lesson: lesson,
        round: round,
        ttsLanguage: _course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
        ttsCacheService: speech,
        settingsService: settings,
      ),
    ),
  );
  await _until(
    tester,
    find.byKey(Key('exercise-renderer-${exercise.primitive.serialized}')),
  );
  return speech;
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  // Round start awaits diagnostic file I/O: real time is allowed too.
  final deadline = DateTime.now().add(const Duration(seconds: 30));
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
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

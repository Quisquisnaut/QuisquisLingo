import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audio_usage.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Build 270 Revision 13 (owner decisions of 10 October 2026): each
// recording says which exercises play it, and Check unused MP3 files finds
// the recordings no exercise plays (those without text are under #).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Course laboratory(List<(String, String)> clips) {
    final json =
        jsonDecode(
              File(
                'assets/courses/exercise_laboratory_en_it.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    return Course.fromJson({
      ...json,
      'audioMode': 'recorded',
      'audioLibrary': [
        for (final (id, text) in clips)
          {
            'id': id,
            'text': text,
            'filePath': 'assets/audio_usage_test/$id.mp3',
          },
      ],
    });
  }

  final library = [
    ('maria', 'Maria compra'),
    ('mele', 'due mele'),
    ('pane', 'e un chilo di pane'),
    ('mercato', 'al mercato'),
    ('part', 'per Roma'),
    ('nothing', 'zzz'),
    ('no-text', ''),
  ];

  Map<String, List<AudioClipUse>> usesOf(Course course) {
    final audio = RecordedAudioService();
    return CourseAudioUsage.usesByClip(
      course,
      (text) => audio.segment(text, course.audioLibrary),
    );
  }

  test('recordings that say a text from end to end are used by its '
      'exercise', () {
    final course = laboratory(library);
    final uses = usesOf(course);
    for (final id in ['maria', 'mele', 'pane', 'mercato']) {
      expect(
        uses[id]!.map((use) => use.exercise.id),
        contains('qql_lab254_select_listening_passage'),
        reason: id,
      );
    }
  });

  test('a recording that covers only part of a text is not used', () {
    final uses = usesOf(laboratory(library));
    // "Il treno per Roma parte alle nove." has words no recording says.
    expect(uses['part'], isNull);
    expect(uses['nothing'], isNull);
  });

  test('unused lists recordings with a text that no exercise plays, not '
      'those without text', () {
    final course = laboratory(library);
    expect(
      CourseAudioUsage.unused(course, usesOf(course)).map((clip) => clip.id),
      ['part', 'nothing'],
    );
  });

  test('the spoken texts include a dialogue read aloud line by line', () {
    final course = laboratory(const []);
    final exercise = course.lessons
        .expand((lesson) => lesson.rounds)
        .expand((round) => round.exercises)
        .firstWhere(
          (exercise) => exercise.id == 'qql_lab254_reading_dialogue_automatic',
        );
    expect(
      CourseAudioUsage.spokenTexts(exercise),
      containsAll(['Vuoi un caffè?', 'Sì, senza zucchero.']),
    );
  });

  group('the Audio Library', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: AudioLibraryScreen(course: laboratory(library))),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('each recording with a text says whether it is used', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('audio-clip-uses-maria')),
          matching: find.textContaining('Used in'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('audio-clip-unused-nothing')), findsOne);
      expect(find.byKey(const Key('audio-clip-unused-part')), findsOne);
      expect(find.byKey(const Key('audio-clip-uses-no-text')), findsNothing);
      expect(find.byKey(const Key('audio-clip-unused-no-text')), findsNothing);
    });

    testWidgets('the list of uses names the exercise and opens it', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('audio-clip-uses-maria')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-clip-uses-dialog')), findsOneWidget);
      final entry = find.descendant(
        of: find.byKey(const Key('audio-clip-uses-dialog')),
        matching: find.textContaining('Exercise'),
      );
      expect(entry, findsWidgets);
      await tester.tap(find.byKey(const Key('audio-clip-use-0')));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ExerciseEditorScreen || widget is PrimitiveEditorScreen,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Check › Unused MP3 files lists the recordings no exercise '
        'plays', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('audio-library-check')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('audio-check-unused')));
      await tester.pumpAndSettle();
      final dialog = find.byKey(const Key('audio-unused-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('2 unused MP3 files')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('per Roma')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('zzz')),
        findsOneWidget,
      );
      await tester.tap(find.text('Remove these recordings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-clip-unused-nothing')), findsNothing);
      expect(find.byKey(const Key('audio-clip-uses-maria')), findsOneWidget);
      expect(find.text(AudioLibraryScreen.noTextLabel), findsOneWidget);
    });
  });
}

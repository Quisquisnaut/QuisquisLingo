import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/exercise_difficulty.dart';
import 'package:quisquislingo_app/widgets/difficulty_badge.dart';

/// Build 260 Revision 5 (owner decision of 1 October 2026): every exercise
/// has a difficulty level from 0 to 4, computed from its canonical data and
/// never stored; the editor shows it as bars.

final _laboratory = Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

/// The level each preset's Laboratory examples have; null for what is not
/// answered or studied. Recognize characters depends on its direction.
const _expected = <String, int?>{
  'before_you_start': null,
  'story_cover': null,
  'dialogue_line': null,
  'flashcard': 0,
  'picture_flashcard': 0,
  'note_card': 0,
  'page': 0,
  'icon_choice': 1,
  'translation_choice_to_source': 1,
  'choice_source': 1,
  'true_false': 1,
  'listening_choose_source': 1,
  'listening_answer_source': 1,
  'listening_image_choice': 1,
  'word_match': 1,
  'picture_word_match': 1,
  'audio_match': 1,
  'choice_target': 2,
  'gap_choice': 2,
  'one_word_fills_all': 2,
  'reading_answer_target': 2,
  'listening_choose_target': 2,
  'listening_answer_target': 2,
  'translation_choice_to_target': 2,
  'picture_choice': 2,
  'super_match': 2,
  'sort_into_groups': 2,
  'word_order': 3,
  'picture_blocks': 3,
  'gap_blocks': 3,
  'build_translation_to_target': 3,
  'build_translation_to_source': 3,
  'image_word': 3,
  'sentence_order': 3,
  'spell_heard': 3,
  'spell_word': 3,
  'fill_the_slots': 3,
  'type_translation_to_target': 4,
  'type_translation_to_source': 4,
  'type_missing_word': 4,
  'listening_spelling': 4,
  'missing_word': 4,
  'complete_text': 4,
  'missing_letters': 4,
  'picture_name': 4,
};

void main() {
  test('every Laboratory example has its preset\'s level', () {
    final seen = <String>{};
    for (final lesson in _laboratory.lessons) {
      for (final round in lesson.rounds) {
        for (final content in round.content) {
          final exercise = content.exercise;
          final preset = content.editorTemplate;
          if (exercise == null || preset == 'script_recognition') continue;
          expect(_expected.containsKey(preset), isTrue, reason: preset);
          seen.add(preset);
          expect(
            ExerciseDifficulty.of(exercise)?.value,
            _expected[preset],
            reason: '${content.id} ($preset)',
          );
        }
      }
    }
    expect(seen, _expected.keys.toSet());
  });

  test('Recognize characters: a picture to pick is a meaning', () {
    final levels = {
      for (final lesson in _laboratory.lessons)
        for (final round in lesson.rounds)
          for (final content in round.content)
            if (content.editorTemplate == 'script_recognition')
              ExerciseDifficulty.of(content.exercise!)?.value,
    };
    expect(levels, isNotEmpty);
    expect(levels.difference({1, 2}), isEmpty);
  });

  test('a Round shows the average of its answered exercises', () {
    LearningRound round(List<Exercise> exercises) =>
        LearningRound(id: 'r', title: 'R', exercises: exercises);
    Exercise example(String preset) => _laboratory.lessons
        .expand((lesson) => lesson.rounds)
        .expand((round) => round.content)
        .firstWhere((content) => content.editorTemplate == preset)
        .exercise!;
    expect(
      ExerciseDifficulty.averageOf(
        round([
          example('flashcard'),
          example('translation_choice_to_source'),
          example('word_order'),
          example('type_translation_to_target'),
        ]),
      ),
      2.7,
    );
    expect(ExerciseDifficulty.averageOf(round([example('flashcard')])), isNull);
  });

  testWidgets('the badge names the level', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DifficultyBadge(level: DifficultyLevel.build),
              DifficultyBadge.average(average: 2.5),
            ],
          ),
        ),
      ),
    );
    expect(
      find.byTooltip('Difficulty 3 of 4: Build with blocks'),
      findsOneWidget,
    );
    expect(find.byTooltip('Average difficulty 2.5 of 4'), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
  });

  test('Editor Help explains the bars in EN, IT and ES', () {
    expect(editorHelpQuestionsByTopic['exercises'], contains('difficulty'));
    final english = helpText.lookup(
      AppLocale.english,
      'editorHelp.qa.difficulty.a',
    );
    expect(english, contains('4 write'));
    for (final locale in [AppLocale.italian, AppLocale.spanish]) {
      expect(
        helpText.lookup(locale, 'editorHelp.qa.difficulty.a'),
        isNot(english),
        reason: locale.id,
      );
    }
    expect(
      helpText.lookup(AppLocale.italian, 'editorHelp.qa.difficulty.q'),
      'Che cosa indicano le barre di difficoltà?',
    );
  });
}

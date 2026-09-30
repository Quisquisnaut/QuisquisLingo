import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';

import 'support/edge_case_fixture.dart';

/// Build 259 Revision 5 (owner review of 30 September 2026, night, points
/// 1–5): Match pictures to words is renamed, needs two words and has no
/// Exercise image; a Story shows its step count only above the title block
/// and no line under a Dialogue line (story_runtime_256_test,
/// revision3_followup_256_test); the Edge Case leaves the bundle and is a
/// Course to import (edge_case_course_254_test).

final _stamp = DateTime.utc(2026, 9, 30);

ExerciseDraftBuildResult _match(
  String words, {
  PublicationState state = PublicationState.published,
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: Exercise(
      id: 'match-259-5',
      type: PresetVariants.formBase('picture_word_match'),
      editorTemplate: 'picture_word_match',
      publicationState: PublicationState.draft,
      updatedAt: _stamp,
      prompt: '',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    ),
    type: 'picture_word_match',
    publicationState: state,
    // The form sends one "picture = word" line per word.
    answers: words,
    pairs: [for (final word in words.split('\n')) ' = $word'].join('\n'),
  ),
);

void main() {
  group('Match pictures to words', () {
    test('is named in the plural', () {
      expect(
        ExercisePresetRegistry.byId('picture_word_match')!.name,
        'Match pictures to words',
      );
    });

    test('a Published save needs two words', () {
      for (final words in ['', 'gatto', 'gatto\n\n']) {
        final result = _match(words);
        expect(
          result.error?.code,
          ExerciseDraftErrorCode.wordsTooFew,
          reason: words,
        );
        expect(result.error?.field, ExerciseDraftField.answers);
      }
      expect(
        _match('gatto\ncane').error?.code,
        isNot(ExerciseDraftErrorCode.wordsTooFew),
      );
      // A Draft keeps what it has.
      expect(
        _match('gatto', state: PublicationState.draft).error?.code,
        isNot(ExerciseDraftErrorCode.wordsTooFew),
      );
    });

    test('has no Exercise image field, only the pictures of its words', () {
      final keys = ExerciseFieldHelpRegistry.editorFieldKeys(
        'picture_word_match',
      );
      expect(keys, isNot(contains('image')));
      expect(keys, contains('icons'));
    });
  });

  group('the Edge Case leaves the bundle', () {
    test('only the Laboratory and the Piedmontese demo are bundled', () {
      expect(CourseService.courseAssets.keys, ['IT', 'PMS']);
      expect(File('assets/courses/edge_case_it_en.json').existsSync(), isFalse);
      expect(File(edgeCaseImportPath).existsSync(), isTrue);
      expect(File(edgeCaseFixturePath).existsSync(), isTrue);
    });
  });
}

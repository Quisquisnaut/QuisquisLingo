import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/course_models.dart';
import 'app_errors.dart';
import 'course_service.dart';
import 'diagnostic_log_service.dart';

/// Fill with an example in a preset form (Build 263 Revision 1, owner
/// decisions of 4 October 2026): each preset's example is one exercise of
/// the Exercise Laboratory, the Course that shows every preset. The example
/// is in English and Italian whatever the Course's languages; its pictures
/// are QQL pictures, which every installation has.
///
/// Since Build 272 Revision 17 the Laboratory is no Course of the app
/// (owner decision of 13 October 2026): its file stays in the app only as
/// the source of these examples, read here and nowhere else.
abstract final class PresetExamples {
  /// The Laboratory exercise that shows each preset best.
  static const exampleIds = <String, String>{
    'translation_choice_to_target': 'qql_lab254_translation_target_five',
    'translation_choice_to_source': 'qql_lab254_translation_source_five',
    'type_translation_to_target': 'qql_lab254_input_alternatives',
    'type_translation_to_source': 'qql_lab254_type_source_variants',
    'build_translation_to_target': 'qql_lab254_build_multiple',
    'build_translation_to_source': 'qql_lab254_build_source_distractor',
    'word_match': 'qql_lab254_match_four',
    'super_match': 'qql_lab254_match_opposites',
    'flashcard': 'qql_lab254_card_complete',
    'picture_flashcard': 'qql_lab254_picture_card',
    'choice_target': 'qql_lab254_select_single',
    'choice_source': 'qql_lab254_choice_source_meaning',
    'gap_choice': 'qql_lab254_select_gap_preset',
    'type_missing_word': 'qql_lab254_input_fragment',
    'word_order': 'qql_lab254_arrange_one',
    'true_false': 'qql_lab254_true_false_true',
    'gap_blocks': 'qql_lab254_arrange_gap_many',
    'one_word_fills_all': 'qql_lab254_select_gap_all_article',
    'complete_text': 'qql_lab254_complete_text',
    'missing_letters': 'qql_lab254_missing_letters',
    'sentence_order': 'qql_lab254_sentence_order_story',
    'sort_into_groups': 'qql_lab254_assign_groups',
    'fill_the_slots': 'qql_lab254_assign_slots',
    'listening_choose_target': 'qql_lab254_select_listening_word',
    'listening_choose_source': 'qql_lab254_listening_source',
    'listening_answer_target': 'qql_lab254_select_listening_passage',
    'listening_answer_source': 'qql_lab254_listening_source_question',
    'listening_spelling': 'qql_lab254_input_listen_sentence',
    'missing_word': 'qql_lab254_input_missing_one',
    'audio_match': 'qql_lab254_match_sounds',
    'listening_image_choice': 'qql_lab254_listening_image',
    'spell_heard': 'qql_lab254_spell_heard_letters',
    'reading_answer_target': 'qql_lab254_reading_dialogue',
    'icon_choice': 'qql_lab254_select_asset_options',
    'script_recognition': 'qql_lab254_script_image_text',
    'image_word': 'qql_lab254_image_letters',
    'picture_choice': 'qql_lab254_picture_choice',
    'picture_name': 'qql_lab254_picture_name',
    'picture_blocks': 'qql_lab254_picture_blocks',
    'spell_word': 'qql_lab254_spell_word_clue',
    'picture_word_match': 'qql_lab254_picture_word_match',
    'note_card': 'qql_lab254_note_card_grammar',
    'dialogue_line': 'qql_lab254_story_narrator',
    'story_cover': 'qql_lab254_story_cover',
    'before_you_start': 'qql_lab254_intro_select_basics',
    'page': 'qql_lab254_page_textbook',
  };

  /// The Laboratory, read from its file in the app. Read as bytes and
  /// decoded here: `loadString` decodes a file of this size in another
  /// isolate, which never finishes under a widget test's clock.
  ///
  /// A file that cannot be read is written to the Diagnostic Log, as it was
  /// while the Laboratory was read as a bundled Course: the form only says
  /// that no example could be read.
  static Future<Course> loadBundled() async {
    try {
      final data = await rootBundle.load(CourseService.laboratoryAsset);
      final decoded = jsonDecode(
        utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
      );
      return Course.fromJson(Map<String, dynamic>.from(decoded as Map));
    } catch (error, stackTrace) {
      await DiagnosticLogService().log(
        AppErrorCode.invalidCourseData,
        context: CourseService.laboratoryAsset,
        exception: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Test seam: where the Laboratory comes from.
  static Future<Course> Function() loadLaboratory = loadBundled;

  /// [presetId]'s example, or null when the preset has none or the
  /// Laboratory cannot be read.
  static Future<Exercise?> forPreset(String presetId) async {
    final id = exampleIds[presetId];
    if (id == null) return null;
    try {
      final laboratory = await loadLaboratory();
      for (final lesson in laboratory.lessons) {
        for (final round in lesson.rounds) {
          for (final exercise in round.exercises) {
            if (exercise.id == id) return exercise;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

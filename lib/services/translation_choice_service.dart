import '../models/course_models.dart';

/// Preset definitions for the two Select-based translation choice exercises.
///
/// Both are configurations of the existing Select primitive: the exercise type
/// alone determines the translation direction, the language role of the main
/// text and answer options, the single learner instruction and the
/// target-language-only audio rule. Authors never configure any of these.
abstract final class TranslationChoice {
  static const String toTarget = 'translation_choice_to_target';
  static const String toSource = 'translation_choice_to_source';

  /// Most answer options a translation choice accepts.
  static const int maxAnswers = 5;

  static bool isTranslationChoice(String type) =>
      type == toTarget || type == toSource;

  /// Comparison form used to detect repeated answers: ignores case, extra
  /// spaces and terminal punctuation, so "Vado a Londra." and "vado  a
  /// londra" count as the same answer.
  static String normalizedAnswer(String answer) => answer
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[.!?…]+$'), '')
      .trim();

  /// True when two non-blank answers repeat after [normalizedAnswer].
  static bool hasRepeatedAnswers(List<String> answers) {
    final seen = <String>{};
    for (final answer in answers) {
      final normalized = normalizedAnswer(answer);
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) return true;
    }
    return false;
  }

  /// Authoring message when the answer list is not acceptable, else null.
  static String? answersProblem(List<String> answers) {
    if (answers.length > maxAnswers) {
      return 'Answer options: enter at most $maxAnswers options, one per line.';
    }
    if (hasRepeatedAnswers(answers)) {
      return 'Answer options: two options repeat the same phrase. Make every option different.';
    }
    return null;
  }

  /// True when the main text ("Text to translate") is in the course target
  /// language, which is the case for the to-source direction only.
  static bool mainTextIsTarget(String type) => type == toSource;

  /// The language the learner must pick the translation in.
  static String answerLanguage(Course course, String type) =>
      type == toTarget ? _targetName(course) : _sourceName(course);

  /// The single learner-facing instruction. It is generated from the course
  /// language names and is deliberately not an authored field.
  static String instruction(Course course, String type) =>
      'Pick the correct ${answerLanguage(course, type)} translation';

  /// The text the optional audio button speaks, or null when this exercise
  /// has none. QQL speech always concerns the target language, so the to-target
  /// main text (source language) is never spoken; its target-language correct
  /// answer is spoken only after the learner has answered.
  static String? spokenText(Exercise exercise, {required bool answered}) {
    if (exercise.type == toSource) {
      final text = exercise.question.trim();
      return text.isEmpty ? null : text;
    }
    if (exercise.type == toTarget && answered) {
      final index = exercise.correct;
      if (index == null || index < 0 || index >= exercise.answers.length) {
        return null;
      }
      final text = exercise.answers[index].trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static String _targetName(Course course) {
    final target = course.targetLanguage.trim();
    return target.isEmpty ? course.learningLanguage.trim() : target;
  }

  static String _sourceName(Course course) {
    final source = course.sourceLanguage.trim();
    return source.isEmpty ? course.interfaceLanguage.trim() : source;
  }
}

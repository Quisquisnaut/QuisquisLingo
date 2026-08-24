import '../models/course_models.dart';

/// Temporary in-app clipboard used to copy or move one exercise between Rounds.
///
/// The buffer intentionally lives only for the current app session. A copied or
/// moved exercise is pasted explicitly from the destination Round editor.
class ExerciseTransferService {
  const ExerciseTransferService._();

  static Exercise? _exercise;
  static bool _move = false;

  static bool get hasPending => _exercise != null;
  static bool get isMove => _move;
  static String get pendingLabel => _move ? 'Move' : 'Copy';

  static void copy(Exercise exercise) {
    _exercise = exercise;
    _move = false;
  }

  static void move(Exercise exercise) {
    _exercise = exercise;
    _move = true;
  }

  static Exercise? takeForPaste() {
    final source = _exercise;
    if (source == null) return null;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final result = _move
        ? source
        : Exercise.v2(id: '${source.id}_copy_$stamp', editorTemplate: source.editorTemplate, promptElements: source.promptElements, interaction: source.interaction, evaluation: source.evaluation, hint: source.hint, feedback: source.feedback, missingWords: source.missingWords);
    clear();
    return result;
  }

  static void clear() {
    _exercise = null;
    _move = false;
  }
}

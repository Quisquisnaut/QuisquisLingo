import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import 'course_audit_service.dart';

/// The names an author reads for an exercise in the Course Editor's lists,
/// its Audit locations and the Audio Library (Build 272 Revision 6; before,
/// three private functions of the Course Editor file). An exercise in, a
/// text out: no screen state.
abstract final class ExerciseLabels {
  /// The preset an exercise carries, else its learner kind: the name the
  /// editor's lists and Audit locations show for it.
  static String kindName(Exercise e) => e.editorTemplate.isNotEmpty
      ? e.editorTemplate
      : ExerciseFeatures(e).kind.name;

  /// The friendly type label: the preset's name, else the kind's.
  static String typeLabel(Exercise e) =>
      ExercisePresetRegistry.byId(e.editorTemplate)?.name ??
      CourseAuditService.kindLabel(ExerciseFeatures(e).kind);

  /// One line that identifies an exercise in a list: its sentence, context,
  /// main text, term, question, meaning or spoken text, else its ID.
  static String summary(Exercise e) {
    final features = ExerciseFeatures(e);
    for (final text in [
      // A Story's line and cover keep their text in the line and title roles
      // (owner report, 29 September 2026: the list showed their IDs).
      features.lineText,
      features.lineAudio?.text ?? '',
      features.coverTitle,
      features.introText,
      // A Page is named by its first text block (Build 258 Revision 2).
      ...features.pageBlocks.where((block) => block.isText).map((b) => b.text),
      features.inlineSentence,
      features.contextText,
      features.primaryText,
      features.textOf('term'),
      features.questionText,
      features.textOf('meaning'),
      features.primaryAudioText ?? '',
    ]) {
      if (text.trim().isNotEmpty) return text.trim();
    }
    if (features.kind == LearnerExerciseKind.storyCover ||
        e.editorTemplate == 'story_cover') {
      final picture = features.illustrationImages
          .map((image) => image.text.trim())
          .where((text) => text.isNotEmpty)
          .firstOrNull;
      return picture == null ? 'Title block' : 'Title block · $picture';
    }
    return e.id;
  }
}

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/lesson_presentation_service.dart';
import '../services/round_type_presentation.dart';
import 'labelled_text.dart';

/// The levels of the Course Editor's pages, the top one first (Build 274
/// Revision 0). Every level but the Lessons list has a crumb.
enum EditorLevel { course, lessons, lesson, rounds, round, exercise }

/// What a Course Editor page gives the page it opens: the levels above it
/// that the author can go back to one page at a time, and the jump in
/// progress (Build 274 Revision 0).
///
/// A jump to a crumb goes through each page's own way back, so a page with
/// unsaved changes asks first, and a page that stays ends the jump there:
/// nothing is applied or discarded differently from pressing Back that many
/// times.
class EditorTrail {
  EditorTrail._(this.levels, this._jump);

  /// The trail a page at [level] gives the page it opens. A page opened
  /// outside the chain ([above] null) starts one of its own, so only its own
  /// level can be jumped to.
  factory EditorTrail.below(EditorTrail? above, EditorLevel level) =>
      above == null
      ? EditorTrail._({level}, _EditorJump())
      : EditorTrail._({...above.levels, level}, above._jump);

  /// The levels whose pages are open above the page given this trail.
  final Set<EditorLevel> levels;
  final _EditorJump _jump;

  /// The level a jump in progress is going to, or null.
  EditorLevel? get target => _jump.target;

  /// Goes back to [level] from the page given this trail: [leave] is that
  /// page's own way back; when the page stays ([stayed]), the jump ends.
  Future<void> jumpTo(
    EditorLevel level, {
    required Future<void> Function() leave,
    required bool Function() stayed,
  }) async {
    if (!levels.contains(level)) return;
    _jump.target = level;
    try {
      await leave();
    } finally {
      // A page that stays, or whose way back failed, ends the jump: a later
      // ordinary Back must never go on upward.
      if (stayed()) _jump.target = null;
    }
  }

  /// For the page at [level] when the page it opened has closed: true when
  /// a jump asks it to go back too. A jump that has reached [level] ends.
  bool passesThrough(EditorLevel level) {
    final target = _jump.target;
    if (target == null) return false;
    if (target.index < level.index) return true;
    _jump.target = null;
    return false;
  }
}

class _EditorJump {
  EditorLevel? target;
}

/// Labels come from the current working copy; IDs, never labels, locate nodes.
///
/// Build 274 Revision 0: a page reached through the Rounds list shows a
/// Rounds crumb (owner decision of 15 October 2026), an exercise is named by
/// its place in its Round, and every crumb whose page is open above this one
/// ([trail]) is a link that goes back to it ([onJump]).
class EditorBreadcrumbs extends StatelessWidget {
  const EditorBreadcrumbs({
    super.key,
    required this.course,
    this.lessonId,
    this.rounds = false,
    this.roundId,
    this.exercise = false,
    this.exerciseNumber,
    this.newExercise = false,
    this.trail,
    this.onJump,
  });

  final Course course;
  final String? lessonId;

  /// Shows the Rounds crumb (always shown before a Round).
  final bool rounds;
  final String? roundId;
  final bool exercise;

  /// The exercise's place in its Round, from 1, as the Round editor's list
  /// shows it.
  final int? exerciseNumber;

  /// An exercise not added to its Round yet.
  final bool newExercise;
  final EditorTrail? trail;
  final ValueChanged<EditorLevel>? onJump;

  /// "Step 2: Coffee", or the Round type when the numbering is off.
  (String, String?) _roundCrumb(LearningRound round, int number) {
    final label =
        RoundTypePresentation.numberLabel(
          number,
          course.roundNumberingMode,
          customPrefix: course.customRoundLabel,
        ) ??
        RoundTypePresentation.label(round.roundType);
    final title = RoundTypePresentation.authoredTitle(round);
    return (title.isEmpty ? label : '$label: $title', label);
  }

  @override
  Widget build(BuildContext context) {
    final lessonIndex = course.lessons.indexWhere(
      (l) => l.lessonId == lessonId,
    );
    final lesson = lessonIndex < 0 ? null : course.lessons[lessonIndex];
    final roundIndex = lesson?.rounds.indexWhere((r) => r.id == roundId) ?? -1;
    // Build 270 Revision 12 (owner report): each crumb's label follows the
    // Course's numbering and is drawn in the label style.
    final crumbs = <(EditorLevel, String, String?)>[
      (
        EditorLevel.course,
        course.title.isEmpty ? 'Course' : course.title,
        null,
      ),
      if (lessonId != null)
        if (lesson == null)
          (EditorLevel.lesson, 'Lesson', null)
        else
          () {
            final identity = const LessonPresentationService().identity(
              course,
              lessonIndex,
            );
            return (EditorLevel.lesson, identity.fullText, identity.prefix);
          }(),
      if (rounds || roundId != null) (EditorLevel.rounds, 'Rounds', null),
      if (roundId != null)
        if (roundIndex < 0)
          (EditorLevel.round, 'New Round', null)
        else
          () {
            final (text, label) = _roundCrumb(
              lesson!.rounds[roundIndex],
              roundIndex + 1,
            );
            return (EditorLevel.round, text, label);
          }(),
      if (exercise)
        (
          EditorLevel.exercise,
          exerciseNumber != null
              ? 'Exercise $exerciseNumber'
              : newExercise
              ? 'New Exercise'
              : 'Exercise',
          null,
        ),
    ];
    final links = trail?.levels ?? const <EditorLevel>{};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var index = 0; index < crumbs.length; index++) ...[
            if (index > 0) const Text('>'),
            if (index < crumbs.length - 1 &&
                onJump != null &&
                links.contains(crumbs[index].$1))
              TextButton(
                key: ValueKey('editor-crumb-${crumbs[index].$1.name}'),
                onPressed: () => onJump!(crumbs[index].$1),
                child: LabelledText(crumbs[index].$2, label: crumbs[index].$3),
              )
            else
              LabelledText(
                key: ValueKey('editor-crumb-${crumbs[index].$1.name}'),
                crumbs[index].$2,
                label: crumbs[index].$3,
              ),
          ],
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_service.dart';
import '../services/course_access_policy.dart';
import 'course_editor_screen.dart';
import 'guidebook_screen.dart';
import 'round_screen.dart';
import '../widgets/editor_app_bar_actions.dart';

/// Compatibility entry point that resolves the immutable publisher source and
/// opens the same capability-driven Course Editor used for custom courses.
class OfficialCourseInspectionScreen extends StatefulWidget {
  const OfficialCourseInspectionScreen({
    super.key,
    required this.course,
    this.editorService,
    this.courseService,
    this.clock,
  });

  final Course course;
  final CourseEditorService? editorService;
  final CourseService? courseService;
  final DateTime Function()? clock;

  @override
  State<OfficialCourseInspectionScreen> createState() =>
      _OfficialCourseInspectionScreenState();
}

class _OfficialCourseInspectionScreenState
    extends State<OfficialCourseInspectionScreen> {
  late final _service = widget.editorService ?? CourseEditorService();
  late final _courseService = widget.courseService ?? CourseService();
  final _access = CourseAccessPolicy();
  late final _source = _loadOfficialSource();

  Future<({Course course, CourseAccessCapabilities access})>
  _loadOfficialSource() async {
    final bundled = widget.course.originType == CourseOriginType.bundledOfficial
        ? await _courseService.loadBundledCourse(
            CourseService.codeForCourse(widget.course),
          )
        : null;
    final source = await _service.officialSourceFor(
      widget.course,
      bundledSource: bundled,
    );
    if (source == null) {
      throw StateError('The immutable official source is unavailable.');
    }
    return (course: source, access: await _access.forCurrentProfile(source));
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<({Course course, CourseAccessCapabilities access})>(
        future: _source,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Course Editor')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Official course could not be inspected: ${snapshot.error}',
                ),
              ),
            );
          }
          final value = snapshot.data!;
          return CourseEditorScreen(
            course: value.course,
            access: value.access,
            editorService: _service,
            courseService: _courseService,
            clock: widget.clock,
          );
        },
      );
}

class _OfficialHierarchyEntry extends StatelessWidget {
  const _OfficialHierarchyEntry({
    required this.label,
    required this.id,
    required this.tile,
  });

  final String label;
  final String id;
  final ListTile tile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      tile,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: EditorInternalIdText(label: label, id: id),
      ),
    ],
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'Course content - read only',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class CourseLessonInspectionScreen extends StatelessWidget {
  const CourseLessonInspectionScreen({
    super.key,
    required this.course,
    required this.lessonIndex,
  });

  final Course course;
  final int lessonIndex;

  @override
  Widget build(BuildContext context) {
    final lesson = course.lessons[lessonIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: const [EditorAppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ReadOnlyNotice(),
          EditorInternalIdText(label: 'Lesson', id: lesson.lessonId),
          ListTile(
            title: const Text('Guidebook'),
            leading: const Icon(Icons.menu_book_outlined),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => GuidebookScreen(
                  course: course,
                  lesson: lesson,
                  lessonIndex: lessonIndex,
                  includeDraftContent: true,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Preview Lesson'),
            leading: const Icon(Icons.play_circle_outline),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => LessonAuthoringPreviewScreen(
                  course: course,
                  lesson: lesson,
                ),
              ),
            ),
          ),
          EditorInternalIdText(label: 'GuideBook', id: lesson.guidebookId),
          for (var index = 0; index < lesson.rounds.length; index++)
            _OfficialHierarchyEntry(
              label: 'Round',
              id: lesson.rounds[index].id,
              tile: ListTile(
                key: ValueKey('official-round-${lesson.rounds[index].id}'),
                title: Text(lesson.rounds[index].displayTitle(index)),
                subtitle: Text(
                  '${lesson.rounds[index].exercises.length} exercises',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _OfficialRoundInspectionScreen(
                      course: course,
                      lesson: lesson,
                      roundIndex: index,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficialRoundInspectionScreen extends StatelessWidget {
  const _OfficialRoundInspectionScreen({
    required this.course,
    required this.lesson,
    required this.roundIndex,
  });

  final Course course;
  final Lesson lesson;
  final int roundIndex;

  @override
  Widget build(BuildContext context) {
    final round = lesson.rounds[roundIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(round.displayTitle(roundIndex)),
        actions: const [EditorAppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ReadOnlyNotice(),
          EditorInternalIdText(label: 'Round', id: round.id),
          ListTile(
            title: const Text('Preview Round'),
            leading: const Icon(Icons.play_circle_outline),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => RoundScreen(
                  course: course,
                  lesson: lesson,
                  round: round,
                  ttsLanguage: course.ttsLanguage,
                  roundIndex: roundIndex,
                  previewMode: true,
                ),
              ),
            ),
          ),
          for (var index = 0; index < round.exercises.length; index++)
            _OfficialHierarchyEntry(
              label: 'Exercise',
              id: round.exercises[index].id,
              tile: ListTile(
                key: ValueKey('official-exercise-${round.exercises[index].id}'),
                title: Text('Exercise ${index + 1}'),
                subtitle: Text(round.exercises[index].prompt),
                trailing: const Icon(Icons.visibility_outlined),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _OfficialExerciseInspectionScreen(
                      course: course,
                      lesson: lesson,
                      roundIndex: roundIndex,
                      exercise: round.exercises[index],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfficialExerciseInspectionScreen extends StatelessWidget {
  const _OfficialExerciseInspectionScreen({
    required this.course,
    required this.lesson,
    required this.roundIndex,
    required this.exercise,
  });

  final Course course;
  final Lesson lesson;
  final int roundIndex;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Exercise inspection'),
      actions: const [EditorAppBarActions()],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ReadOnlyNotice(),
        EditorInternalIdText(label: 'Exercise', id: exercise.id),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => RoundScreen(
                course: course,
                lesson: lesson,
                round: LearningRound(
                  id: 'preview_${exercise.id}',
                  updatedAt: lesson.rounds[roundIndex].updatedAt,
                  title: 'Preview exercise',
                  visualType: lesson.rounds[roundIndex].visualType,
                  exercises: [exercise],
                ),
                ttsLanguage: course.ttsLanguage,
                roundIndex: roundIndex,
                previewMode: true,
              ),
            ),
          ),
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Preview Exercise'),
        ),
        const SizedBox(height: 12),
        SelectableText(
          const JsonEncoder.withIndent('  ').convert(exercise.toJson()),
        ),
      ],
    ),
  );
}

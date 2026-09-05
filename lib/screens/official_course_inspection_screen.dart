import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_audit_service.dart';
import '../services/course_editor_service.dart';
import '../services/course_service.dart';
import 'course_editor_screen.dart';
import 'course_info_screen.dart';
import 'course_version_history_screen.dart';
import 'editor_help_screen.dart';
import 'guidebook_screen.dart';
import 'round_screen.dart';

/// Official inspection resolves the publisher-owned source and never creates
/// an authoring transaction. Only an explicitly licensed fork opens authoring.
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
  late final _source = _loadOfficialSource();
  bool _forking = false;

  Future<Course> _loadOfficialSource() async {
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
    return source;
  }

  Future<void> _fork(Course course) async {
    if (_forking) return;
    setState(() => _forking = true);
    try {
      final fork = await _service.forkOfficialCourse(course);
      if (!mounted) return;
      final result = await Navigator.of(context).push<CourseConfirmationResult>(
        MaterialPageRoute(
          builder: (_) => CourseEditorScreen(
            course: fork,
            userCourse: true,
            isNewCourse: true,
            editorService: _service,
            clock: widget.clock,
          ),
        ),
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Custom fork created: ${result.course.title}\n'
              'Course version: ${result.course.courseVersion}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom fork could not be created: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _forking = false);
    }
  }

  Future<void> _audit(Course course) async {
    final issue = await Navigator.of(context).push<CourseAuditIssue>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(
          course: course,
          result: CourseAuditService().auditCourse(course),
        ),
      ),
    );
    if (issue == null || !mounted) return;
    for (final lesson in course.lessons) {
      for (var index = 0; index < lesson.rounds.length; index++) {
        if (lesson.rounds[index].id != issue.roundId) continue;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => _OfficialRoundInspectionScreen(
              course: course,
              lesson: lesson,
              roundIndex: index,
            ),
          ),
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Course Editor'),
      actions: [
        IconButton(
          tooltip: 'Course Editor Help',
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const EditorHelpScreen()),
          ),
          icon: const Icon(Icons.help_outline),
        ),
      ],
    ),
    body: FutureBuilder<Course>(
      future: _source,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Official course could not be inspected: ${snapshot.error}',
            ),
          );
        }
        final course = snapshot.data!;
        final forkAllowed =
            course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              course.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const _ReadOnlyNotice(),
            Text(
              '${course.publisherName} · Official ${course.officialCourseVersion}',
            ),
            ListTile(
              key: const Key('official-course-info'),
              leading: const Icon(Icons.info_outline),
              title: const Text('Course Info'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CourseInfoScreen(course: course),
                ),
              ),
            ),
            ListTile(
              key: const Key('official-course-audit'),
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Audit'),
              onTap: () => _audit(course),
            ),
            ListTile(
              key: const Key('official-course-history'),
              leading: const Icon(Icons.history_outlined),
              title: const Text('Version history'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CourseVersionHistoryScreen(
                    course: course,
                    backupService: _service.backupService,
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              key: const Key('fork-official-course'),
              onPressed: forkAllowed && !_forking ? () => _fork(course) : null,
              icon: const Icon(Icons.fork_right_outlined),
              label: const Text('Fork as custom course'),
            ),
            const SizedBox(height: 8),
            Text(switch (course.derivativeWorksPolicy) {
              DerivativeWorksPolicy.allowed =>
                'The publisher permits derivative works. Create an independent editable custom course, preserving original authorship and provenance. Future official updates will not change your fork.',
              DerivativeWorksPolicy.forbidden =>
                'A custom fork is unavailable because the publisher forbids derivative works.',
              DerivativeWorksPolicy.unspecified =>
                'A custom fork is unavailable because permission for derivative works has not been specified by the publisher.',
            }),
            const Divider(height: 24),
            Text('Lessons', style: Theme.of(context).textTheme.titleMedium),
            for (var index = 0; index < course.lessons.length; index++)
              ListTile(
                key: ValueKey(
                  'official-lesson-${course.lessons[index].lessonId}',
                ),
                title: Text(course.lessons[index].title),
                subtitle: Text('${course.lessons[index].rounds.length} Rounds'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _OfficialLessonInspectionScreen(
                      course: course,
                      lessonIndex: index,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'Official course - read only',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class _OfficialLessonInspectionScreen extends StatelessWidget {
  const _OfficialLessonInspectionScreen({
    required this.course,
    required this.lessonIndex,
  });

  final Course course;
  final int lessonIndex;

  @override
  Widget build(BuildContext context) {
    final lesson = course.lessons[lessonIndex];
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ReadOnlyNotice(),
          ListTile(
            title: const Text('Guidebook'),
            leading: const Icon(Icons.menu_book_outlined),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => GuidebookScreen(
                  course: course,
                  lesson: lesson,
                  lessonIndex: lessonIndex,
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
          for (var index = 0; index < lesson.rounds.length; index++)
            ListTile(
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
      appBar: AppBar(title: Text(round.displayTitle(roundIndex))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ReadOnlyNotice(),
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
            ListTile(
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
    appBar: AppBar(title: const Text('Exercise inspection')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ReadOnlyNotice(),
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

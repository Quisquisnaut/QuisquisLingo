import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../services/exercise_search_service.dart';
import '../services/editor_display_preferences.dart';
import '../services/lesson_presentation_service.dart';
import '../widgets/editor_app_bar_actions.dart';

class CourseEditorSearchScreen extends StatefulWidget {
  const CourseEditorSearchScreen({
    super.key,
    required this.course,
    required this.scope,
    this.lessonId,
    this.roundId,
  });

  final Course course;
  final ExerciseSearchScope scope;
  final String? lessonId;
  final String? roundId;

  @override
  State<CourseEditorSearchScreen> createState() =>
      _CourseEditorSearchScreenState();
}

class _CourseEditorSearchScreenState extends State<CourseEditorSearchScreen> {
  final _query = TextEditingController();
  String? _exerciseType;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<ExerciseSearchResult> get _results =>
      const ExerciseSearchService().search(
        widget.course,
        query: _query.text,
        scope: widget.scope,
        lessonId: widget.lessonId,
        roundId: widget.roundId,
        exerciseType: _exerciseType,
      );

  String get _scopeLabel => switch (widget.scope) {
    ExerciseSearchScope.course => 'the whole course',
    ExerciseSearchScope.lesson => 'this Lesson',
    ExerciseSearchScope.round => 'this Round',
  };

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Exercises'),
        actions: const [EditorAppBarActions()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              key: const Key('course-editor-search-query'),
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Words, contiguous phrase or Exercise ID',
                helperText:
                    'Searching $_scopeLabel · case and diacritics are ignored',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(_query.clear),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: DropdownButtonFormField<String?>(
              key: const Key('course-editor-search-type-filter'),
              initialValue: _exerciseType,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Exercise Type',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All exercise types'),
                ),
                for (final preset in ExercisePresetRegistry.presets)
                  DropdownMenuItem<String?>(
                    value: preset.id,
                    child: Text(preset.name),
                  ),
              ],
              onChanged: (value) => setState(() => _exerciseType = value),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _query.text.trim().isEmpty
                ? const Center(
                    child: Text(
                      'Enter a word, a contiguous phrase or all or part of an Exercise ID.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : results.isEmpty
                ? const Center(child: Text('No matching Exercises.'))
                : ListView.builder(
                    key: const Key('course-editor-search-results'),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final lesson = widget.course.lessons[result.lessonIndex];
                      final round = lesson.rounds[result.roundIndex];
                      final roundLabel = round.title.trim().isEmpty
                          ? 'Round ${result.roundIndex + 1}'
                          : 'Round ${result.roundIndex + 1} · ${round.title.trim()}';
                      final lessonLabel = const LessonPresentationService()
                          .identity(widget.course, result.lessonIndex)
                          .fullText;
                      return ListTile(
                        key: ValueKey(
                          'course-editor-search-result-${result.exerciseId}',
                        ),
                        title: Text(
                          '$lessonLabel > $roundLabel > ${result.exerciseDisplayName}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result.matchedFieldLabel}: ${result.matchingExcerpt}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  EditorDisplayPreferences.showInternalIds,
                              builder: (context, visible, _) => visible
                                  ? Text(
                                      'Exercise ID: ${result.exerciseId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontFamily: 'monospace'),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

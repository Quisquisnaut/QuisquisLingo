import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../models/guidebook_text.dart';
import '../services/lesson_presentation_service.dart';
import '../services/publication_service.dart';
import '../widgets/guidebook_picture_thumbnail.dart';

/// A Lesson's GuideBook as learners read it (Build 266, GuideBook Modules):
/// the Lesson title, then each module in order with its title, Sentences,
/// Words & Expressions and Overview.
class GuidebookScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;
  final int lessonIndex;
  final bool includeDraftContent;

  /// The module to scroll to when the GuideBook opens (a Round's focus
  /// module, from Open GuideBook on a Before you start card); none or a
  /// module that does not exist opens it at the top.
  final String? focusModuleId;

  const GuidebookScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.lessonIndex,
    this.includeDraftContent = false,
    this.focusModuleId,
  });

  @override
  State<GuidebookScreen> createState() => _GuidebookScreenState();
}

class _GuidebookScreenState extends State<GuidebookScreen> {
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusModuleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _focusKey.currentContext;
        if (target != null && mounted) {
          Scrollable.ensureVisible(target, duration: Duration.zero);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.includeDraftContent
        ? widget.lesson.guidebook
        : const PublicationService().learnerGuidebook(widget.lesson.guidebook);
    final identity = const LessonPresentationService().identity(
      widget.course,
      widget.lessonIndex,
    );
    final empty = guide.modules.every(
      (module) => module.hasNoEntries && module.overview.trim().isEmpty,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guidebook',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              identity.fullText,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (!empty)
              for (final module in guide.modules)
                KeyedSubtree(
                  key: module.id == widget.focusModuleId ? _focusKey : null,
                  child: _ModuleView(
                    key: ValueKey('guidebook-module-${module.id}'),
                    module: module,
                    courseId: widget.course.courseId,
                  ),
                ),
            if (empty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    !widget.includeDraftContent &&
                            !guide.publicationState.isPublished
                        ? 'This Lesson Guidebook is not available.'
                        : 'This Lesson Guidebook is empty.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'The Guidebook is a reference for this Lesson. Reading it does not affect progress, XP, streaks, or Lesson unlocking.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleView extends StatelessWidget {
  const _ModuleView({super.key, required this.module, required this.courseId});

  final GuidebookModule module;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              module.title,
              key: ValueKey('guidebook-module-title-${module.id}'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (module.sentences.isNotEmpty) ...[
              heading('Sentences'),
              for (final entry in module.sentences)
                _EntryLine(entry: entry, courseId: courseId),
            ],
            if (module.words.isNotEmpty) ...[
              heading('Words & Expressions'),
              for (final entry in module.words)
                _EntryLine(entry: entry, courseId: courseId),
            ],
            if (module.overview.trim().isNotEmpty) ...[
              heading('Overview'),
              Text(module.overview.trim()),
            ],
          ],
        ),
      ),
    );
  }
}

/// One entry: *target — source*, the Context as a small grey label after
/// it, optional words as "(io)" in grey, and a word's picture beside it.
class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.entry, required this.courseId});

  final GuidebookEntry entry;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grey = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final text = Text.rich(
      key: ValueKey('guidebook-entry-${entry.id}'),
      TextSpan(
        children: [
          for (final run in GuidebookText.runs(entry.target))
            run.optional
                ? TextSpan(text: '(${run.text})', style: grey)
                : TextSpan(
                    text: run.text,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          TextSpan(text: ' — ${entry.source}'),
          if (entry.context.isNotEmpty)
            TextSpan(
              text: '  ${entry.context}',
              style: theme.textTheme.bodySmall?.merge(grey),
            ),
        ],
      ),
    );
    final picture = entry.picture;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: picture == null
          ? text
          : Row(
              children: [
                GuidebookPictureThumbnail(
                  key: ValueKey('guidebook-entry-picture-${entry.id}'),
                  courseId: courseId,
                  picture: picture,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(child: text),
              ],
            ),
    );
  }
}

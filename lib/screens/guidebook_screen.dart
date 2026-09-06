import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/lesson_presentation_service.dart';
import '../services/publication_service.dart';

class GuidebookScreen extends StatelessWidget {
  final Course course;
  final Lesson lesson;
  final int lessonIndex;
  final bool includeDraftContent;

  const GuidebookScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.lessonIndex,
    this.includeDraftContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final guide = includeDraftContent
        ? lesson.guidebook
        : const PublicationService().learnerGuidebook(lesson.guidebook);
    final identity = const LessonPresentationService().identity(
      course,
      lessonIndex,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guidebook',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Text(
            identity.fullText,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (guide.overview.trim().isNotEmpty) ...[
            Text(guide.overview),
            const SizedBox(height: 18),
          ],
          _GuideSection(title: 'Learning goals', items: guide.goals),
          _GuideSection(title: 'Vocabulary', items: guide.vocabulary),
          _GuideSection(title: 'Grammar', items: guide.grammar),
          _GuideSection(title: 'Useful expressions', items: guide.expressions),
          _GuideSection(title: 'Examples', items: guide.examples),
          if (guide.content.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  !includeDraftContent && !guide.publicationState.isPublished
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
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _GuideSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $item'),
              ),
          ],
        ),
      ),
    );
  }
}

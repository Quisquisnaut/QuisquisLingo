import 'package:flutter/material.dart';
import '../models/course_models.dart';

class GuidebookScreen extends StatelessWidget {
  final Lesson lesson;

  const GuidebookScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final guide = lesson.guidebook;
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
            lesson.title,
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
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('This Lesson Guidebook is empty.'),
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

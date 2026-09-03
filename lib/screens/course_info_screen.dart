import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_models.dart';
import '../widgets/learner_shell.dart';

class CourseInfoScreen extends StatelessWidget {
  final Course course;
  final Future<bool> Function(Uri uri)? launchExternal;

  const CourseInfoScreen({
    super.key,
    required this.course,
    this.launchExternal,
  });

  Future<void> _buyCoffee(BuildContext context) async {
    final uri = Uri.tryParse(course.buyACoffeeUrl);
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This course does not provide an author support link.'),
        ),
      );
      return;
    }
    final opened = launchExternal == null
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : await launchExternal!(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The author support link could not open.'),
        ),
      );
    }
  }

  String get _authors {
    if (course.authors.isNotEmpty) {
      return course.authors
          .map(
            (author) => author.roles.isEmpty
                ? author.name
                : '${author.name} — ${author.roles.join(', ')}',
          )
          .join('\n');
    }
    return course.author.trim().isEmpty
        ? 'Not specified'
        : course.author.trim();
  }

  @override
  Widget build(BuildContext context) => LearnerStatusPage(
    child: Scaffold(
      appBar: LearnerStatusAppBar(
        appBar: AppBar(title: const Text('Course Info')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(
            course.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('${course.sourceLanguage} → ${course.targetLanguage}'),
          if (course.courseDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(course.courseDescription.trim()),
          ],
          const SizedBox(height: 18),
          _InfoCard(title: 'Course authors and credits', body: _authors),
          _InfoCard(
            title: 'Course details',
            body: [
              'Course version: ${course.courseVersion.trim().isEmpty ? course.version : course.courseVersion}',
              'Content revision: ${course.contentRevision}',
              if (course.lastUpdated.trim().isNotEmpty)
                'Last updated: ${course.lastUpdated}',
              'License: ${course.license.trim().isEmpty ? 'Not specified' : course.license}',
              'Lessons: ${course.lessons.length}',
            ].join('\n'),
          ),
          if (course.buyACoffeeUrl.isNotEmpty) ...[
            const Divider(height: 24),
            ListTile(
              key: const Key('course-info-buy-coffee'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.coffee_outlined),
              title: const Text('Buy a Coffee'),
              subtitle: const Text('Support this course\'s authors.'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _buyCoffee(context),
            ),
          ],
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
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
          const SizedBox(height: 6),
          SelectableText(body),
        ],
      ),
    ),
  );
}

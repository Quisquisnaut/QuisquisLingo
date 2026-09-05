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

  String _localDateTime(BuildContext context, String utc) {
    final parsed = DateTime.tryParse(utc)?.toLocal();
    if (parsed == null) return 'Not recorded';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(parsed)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  List<String> _originDetails(BuildContext context) {
    if (course.originType.isOfficial) {
      return [
        'Origin: ${course.originType == CourseOriginType.bundledOfficial ? 'Bundled official' : 'External official'}',
        'Publisher: ${course.publisherName}',
        'Official course version: ${course.officialCourseVersion}',
        'Official release: ${_localDateTime(context, course.officialReleaseDateUtc)}',
        'Distribution channel: ${course.distributionChannel}',
        'Publisher verification: ${course.publisherVerificationStatus.name}',
        'Official checksum: ${course.officialChecksum}',
        'Official course - read only',
      ];
    }
    return [
      'Origin: Custom course',
      'Course version: ${course.courseVersion.trim().isEmpty ? 'Unconfirmed' : course.courseVersion}',
      if (course.createdByUsername.isNotEmpty)
        'Created by: ${course.createdByUsername}',
      if (course.createdAtUtc.isNotEmpty)
        'Created: ${_localDateTime(context, course.createdAtUtc)}',
      if (course.lastModifiedByUsername.isNotEmpty)
        'Last modified by: ${course.lastModifiedByUsername}',
      if (course.lastModifiedAtUtc.isNotEmpty)
        'Last modified: ${_localDateTime(context, course.lastModifiedAtUtc)}',
      if (course.versionNotes.isNotEmpty)
        'Version notes:\n${course.versionNotes}',
    ];
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
          if (course.forkProvenance != null)
            CourseForkProvenanceCard(provenance: course.forkProvenance!),
          _InfoCard(
            title: 'Course details',
            body: [
              ..._originDetails(context),
              'Content revision: ${course.contentRevision}',
              if (course.lastUpdated.trim().isNotEmpty)
                'Last updated: ${course.lastUpdated}',
              'License: ${course.license.trim().isEmpty ? 'Not specified' : course.license}',
              'Derivative works: ${course.derivativeWorksPolicy.name}',
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

/// Original attribution is distinct from the fork's editable contributor list.
class CourseForkProvenanceCard extends StatelessWidget {
  const CourseForkProvenanceCard({super.key, required this.provenance});

  final CourseForkProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final originalAuthors = provenance.originalAuthors.isNotEmpty
        ? provenance.originalAuthors
              .map(
                (author) => author.roles.isEmpty
                    ? author.name
                    : '${author.name} — ${author.roles.join(', ')}',
              )
              .join('\n')
        : provenance.originalAuthor.isEmpty
        ? 'Not specified'
        : provenance.originalAuthor;
    final created = DateTime.tryParse(provenance.forkCreatedAtUtc)?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final createdLabel = created == null
        ? 'Not recorded'
        : '${localizations.formatMediumDate(created)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(created))}';
    return _InfoCard(
      title: 'Original course and fork provenance',
      body: [
        'Original course: ${provenance.originalCourseTitle}',
        'Original publisher: ${provenance.originalPublisherName}',
        'Original publisher ID: ${provenance.originalPublisherId}',
        'Original course ID: ${provenance.originalCourseId}',
        'Original authors:\n$originalAuthors',
        if (provenance.originalAuthors.isNotEmpty &&
            provenance.originalAuthor.isNotEmpty)
          'Original author attribution: ${provenance.originalAuthor}',
        'Based on official version: ${provenance.originalOfficialCourseVersion}',
        'Original official checksum: ${provenance.originalOfficialChecksum}',
        'Forked by: ${provenance.forkCreatedByUsername}',
        'Fork creator profile ID: ${provenance.forkCreatedByProfileId}',
        'Fork created: $createdLabel',
        'Original authorship and provenance are permanent. Official updates do not change this custom fork.',
      ].join('\n'),
    );
  }
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

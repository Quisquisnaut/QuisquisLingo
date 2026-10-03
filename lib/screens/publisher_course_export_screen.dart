import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/storage/qql_storage.dart';
import '../services/trusted_publishers.dart';

/// Export as Publisher Course (Build 262 Revision 2): the unsigned Publisher
/// Course of a custom Course, for `tools/sign_course.dart`, written by Quick
/// Export or Save as…. Nothing is exported while [refusals] holds a reason.
class PublisherCourseExportScreen extends StatefulWidget {
  const PublisherCourseExportScreen({
    super.key,
    required this.course,
    required this.refusals,
    required this.publishers,
    required this.onExport,
    this.onSaveTo,
  });

  final Course course;
  final List<String> refusals;
  final List<TrustedPublisherKey> publishers;
  final Future<void> Function(TrustedPublisherKey publisher) onExport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function(TrustedPublisherKey publisher)? onSaveTo;

  @override
  State<PublisherCourseExportScreen> createState() =>
      _PublisherCourseExportScreenState();
}

class _PublisherCourseExportScreenState
    extends State<PublisherCourseExportScreen> {
  late TrustedPublisherKey? _publisher = widget.publishers.isEmpty
      ? null
      : widget.publishers.first;

  bool get _ready => widget.refusals.isEmpty && _publisher != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bold = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final publisher = _publisher;
    return Scaffold(
      appBar: AppBar(title: const Text('Export as Publisher Course')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.course.title,
            key: const Key('publisher-export-course-title'),
            style: bold,
          ),
          const SizedBox(height: 8),
          const Text(
            'Writes this Course as a Publisher Course: the same Lessons, '
            'Rounds and exercises with the same IDs, published by the '
            'publisher you choose, ready to be signed. Your Course stays as '
            'it is.',
          ),
          if (widget.refusals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              key: const Key('publisher-export-refusals'),
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Course cannot be exported as a Publisher Course yet:',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (final reason in widget.refusals)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '• $reason',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<TrustedPublisherKey>(
            key: const Key('publisher-export-publisher'),
            initialValue: publisher,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Publisher'),
            items: [
              for (final key in widget.publishers)
                DropdownMenuItem(
                  value: key,
                  child: Text(
                    '${key.publisherName} (${key.publisherId})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _publisher = value),
          ),
          const SizedBox(height: 12),
          Text(
            'Official version: ${widget.course.courseVersion.isEmpty ? '–' : widget.course.courseVersion} '
            '(the Course version, which rises each time you confirm the '
            'Course)',
            key: const Key('publisher-export-version'),
          ),
          if (publisher != null && publisher.publicKeyBase64.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'The signing key of ${publisher.publisherName} is not in this '
              'version of QuisquisLingo yet: its Courses can be exported and '
              'signed, but not imported until a version with the key.',
              key: const Key('publisher-export-key-pending'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('publisher-export-quick'),
            onPressed: _ready ? () => widget.onExport(publisher!) : null,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Quick Export'),
          ),
          const SizedBox(height: 4),
          Text(
            'Writes a ZIP holding course.json and the images and recordings '
            'this Course uses into '
            '${QqlStorageLayout.current.folderLabel(QqlStorageRole.courseExports)}, '
            'without a dialog.',
          ),
          if (widget.onSaveTo != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('publisher-export-save-as'),
              onPressed: _ready ? () => widget.onSaveTo!(publisher!) : null,
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text('Save as…'),
            ),
          ],
          const SizedBox(height: 20),
          Text('Before you distribute it', style: bold),
          const SizedBox(height: 8),
          const Text(
            '1. The Publisher Course is not signed yet, and QuisquisLingo '
            'refuses a Publisher Course without a valid signature. Unzip it '
            'and sign course.json with tools/sign_course.dart and the '
            "publisher's key, then package it with the media folder "
            '(docs/PUBLISHER_SIGNING_GUIDE.md, section 7).\n'
            '2. The Course loses its Maintainer, Team and Course version; '
            'the publisher becomes its original creator. Authors, Rights '
            'Holders and License stay.\n'
            '3. For an update, edit this Course, confirm it and export it '
            'again for the same publisher: the official version is then '
            'higher, and learners keep their progress.\n'
            '4. The Publisher Course has the same Course ID as this Course, '
            'so this device cannot install it beside this Course.',
          ),
        ],
      ),
    );
  }
}

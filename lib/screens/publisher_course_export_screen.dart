import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/publisher_course_export.dart';
import '../services/storage/qql_storage.dart';
import '../services/trusted_publishers.dart';

/// Export as Publisher Course (Build 262 Revision 2): the unsigned Publisher
/// Course of a custom Course, for `tools/sign_course.dart`, written by Quick
/// Export or Save as…. Nothing is exported while [refusals] holds a reason.
/// The author types the publisher's ID and name, so any publisher can be
/// named (owner decision of 4 October 2026); no publisher is suggested.
class PublisherCourseExportScreen extends StatefulWidget {
  const PublisherCourseExportScreen({
    super.key,
    required this.course,
    required this.refusals,
    required this.onExport,
    this.onSaveTo,
    this.initialPublisher,
    this.registry,
  });

  /// The publishers the warning compares with; null means this app's.
  final TrustedPublishers? registry;

  final Course course;
  final List<String> refusals;

  /// The publisher this Course was last exported for, filled in (owner
  /// request of 4 October 2026); null leaves both fields empty.
  final PublisherIdentity? initialPublisher;
  final Future<void> Function(PublisherIdentity publisher) onExport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function(PublisherIdentity publisher)? onSaveTo;

  @override
  State<PublisherCourseExportScreen> createState() =>
      _PublisherCourseExportScreenState();
}

class _PublisherCourseExportScreenState
    extends State<PublisherCourseExportScreen> {
  late final _publisherId = TextEditingController(
    text: widget.initialPublisher?.publisherId ?? '',
  );
  late final _publisherName = TextEditingController(
    text: widget.initialPublisher?.publisherName ?? '',
  );

  PublisherIdentity? get _publisher =>
      PublisherCourseExport.identity(_publisherId.text, _publisherName.text);

  bool get _ready => widget.refusals.isEmpty && _publisher != null;

  @override
  void dispose() {
    _publisherId.dispose();
    _publisherName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bold = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final publisher = _publisher;
    final warning = publisher == null
        ? null
        : PublisherCourseExport.trustWarning(publisher, widget.registry);
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
            'publisher you name, ready to be signed. Your Course stays as '
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
          TextField(
            key: const Key('publisher-export-publisher-id'),
            controller: _publisherId,
            decoration: InputDecoration(
              labelText: 'Publisher ID',
              helperText:
                  'The ID the publisher received when its signing key was '
                  'approved, for example org.example.courses.',
              helperMaxLines: 3,
              errorText: PublisherCourseExport.publisherIdProblem(
                _publisherId.text,
              ),
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('publisher-export-publisher-name'),
            controller: _publisherName,
            decoration: const InputDecoration(
              labelText: 'Publisher name',
              helperText:
                  'Exactly as approved, with the same capitals and spaces.',
              helperMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Row(
              key: const Key('publisher-export-trust-warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(warning)),
              ],
            ),
          ],
          if (widget.initialPublisher != null) ...[
            const SizedBox(height: 4),
            Text(
              'Filled in from the last export of this Course: keep them for '
              'an update.',
              key: const Key('publisher-export-remembered'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Official version: ${widget.course.courseVersion.isEmpty ? '–' : widget.course.courseVersion} '
            '(the Course version, which rises each time you confirm the '
            'Course)',
            key: const Key('publisher-export-version'),
          ),
          const SizedBox(height: 4),
          Text(
            'QuisquisLingo installs a Publisher Course only when it trusts '
            "the publisher's signing key: the ID and name must be the "
            'approved ones (docs/PUBLISHER_SIGNING_GUIDE.md, sections 3 to '
            '6).',
            key: const Key('publisher-export-trust-note'),
            style: theme.textTheme.bodySmall,
          ),
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
            'again with the same publisher ID and name: the official '
            'version is then higher, and learners keep their progress.\n'
            '4. The Publisher Course has the same Course ID as this Course, '
            'so this device cannot install it beside this Course.',
          ),
        ],
      ),
    );
  }
}

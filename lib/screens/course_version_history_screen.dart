import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_backup_service.dart';
import '../services/custom_course_transfer_service.dart';

class CourseHistorySelection {
  final Course course;

  const CourseHistorySelection.restore(this.course);
}

class CourseVersionHistoryScreen extends StatefulWidget {
  final Course course;
  final CourseBackupService backupService;

  const CourseVersionHistoryScreen({
    super.key,
    required this.course,
    required this.backupService,
  });

  @override
  State<CourseVersionHistoryScreen> createState() =>
      _CourseVersionHistoryScreenState();
}

class _CourseVersionHistoryScreenState
    extends State<CourseVersionHistoryScreen> {
  late final Future<({List<CourseBackupRecord> records, String path})>
  _history = _loadHistory();
  final _transfer = CustomCourseTransferService();

  Future<({List<CourseBackupRecord> records, String path})>
  _loadHistory() async {
    final directory = await widget.backupService.courseBackupDirectory(
      widget.course.courseId,
    );
    final records = widget.course.originType.isOfficial
        ? await widget.backupService.listOfficialBackups(widget.course.courseId)
        : await widget.backupService.listBackups(widget.course.courseId);
    return (records: records, path: directory.absolute.path);
  }

  String _dateTime(BuildContext context, String utc) {
    final parsed = DateTime.tryParse(utc)?.toLocal();
    if (parsed == null) return 'Not recorded';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(parsed)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
  }

  String _versionTitle(Course course) {
    if (course.originType.isOfficial) {
      return 'Official release: ${course.officialCourseVersion}';
    }
    return 'Course version: ${course.courseVersion.trim().isEmpty ? 'Unversioned' : course.courseVersion}';
  }

  List<Widget> _details(Course course) {
    final official = course.originType.isOfficial;
    final author = official ? '' : course.lastModifiedByUsername;
    final timestamp = official
        ? course.officialReleaseDateUtc
        : course.lastModifiedAtUtc;
    final notes = official ? course.officialReleaseNotes : course.versionNotes;
    return [
      if (official) ...[
        Text('Publisher: ${course.publisherName}'),
        Text('Official version: ${course.officialCourseVersion}'),
        Text('Distribution channel: ${course.distributionChannel}'),
        Text('Verification: ${course.publisherVerificationStatus.name}'),
        Text(
          'Checksum: ${course.officialChecksum.length > 16 ? '${course.officialChecksum.substring(0, 16)}…' : course.officialChecksum}',
        ),
      ],
      if (author.isNotEmpty) Text('Author: $author'),
      Text('Date and time: ${_dateTime(context, timestamp)}'),
      if (course.restoredFromVersion != null)
        Text('Restored from version: ${course.restoredFromVersion}'),
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 6),
        const Text(
          'Version notes:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SelectableText(notes),
      ],
    ];
  }

  Future<void> _exportHistorical(Course course) async {
    try {
      final path = await _transfer.exportCourse(course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Historical course exported to $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Historical export failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Version history')),
    body: FutureBuilder<({List<CourseBackupRecord> records, String path})>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Version history could not be read: ${snapshot.error}'),
          );
        }
        final data = snapshot.data!;
        final records = data.records;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SelectableText('Course Backups: ${data.path}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final opened = await widget.backupService.openBackupFolder(
                  widget.course.courseId,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'The backup folder could not be opened. The backups remain available.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open backup folder'),
            ),
            if (widget.course.originType.isOfficial) ...[
              const SizedBox(height: 12),
              const Text(
                'Official course - read only. Publisher updates control the official source; historical releases cannot be restored through local authoring.',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official release: ${widget.course.officialCourseVersion}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Publisher: ${widget.course.publisherName}'),
                      Text(
                        'Released: ${_dateTime(context, widget.course.officialReleaseDateUtc)}',
                      ),
                      Text(
                        'Verification: ${widget.course.publisherVerificationStatus.name}',
                      ),
                      if (widget.course.officialReleaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Official release notes:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SelectableText(widget.course.officialReleaseNotes),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _versionTitle(widget.course),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ..._details(widget.course),
                  ],
                ),
              ),
            ),
            for (final record in records)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _versionTitle(record.course),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ..._details(record.course),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!widget.course.originType.isOfficial)
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                context,
                                CourseHistorySelection.restore(record.course),
                              ),
                              child: const Text('Restore this version'),
                            ),
                          OutlinedButton(
                            onPressed: () => _exportHistorical(record.course),
                            child: const Text('Export historical version'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

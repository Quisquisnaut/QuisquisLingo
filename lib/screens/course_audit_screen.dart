import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/course_audit_service.dart';
import '../services/course_audit_report_service.dart';
import '../widgets/course_preview_flag.dart';

class CourseAuditScreen extends StatefulWidget {
  final Course course;
  final CourseAuditResult result;
  final String title;
  final CourseAuditReportService? reportService;
  const CourseAuditScreen({
    super.key,
    required this.course,
    required this.result,
    this.title = 'Course Audit',
    this.reportService,
  });
  @override
  State<CourseAuditScreen> createState() => _CourseAuditScreenState();
}

class _CourseAuditScreenState extends State<CourseAuditScreen> {
  AuditSeverity? _filter;
  AuditSortMode _sortMode = AuditSortMode.lesson;

  late final CourseAuditReportService _reportService =
      widget.reportService ?? CourseAuditReportService();

  Future<void> _copyReport() async {
    try {
      await _reportService.copyReport(
        course: widget.course,
        result: widget.result,
        scope: widget.title,
        sortMode: _sortMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete Audit report copied.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not copy Audit report: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportReport() async {
    try {
      final path = await _reportService.exportReport(
        course: widget.course,
        result: widget.result,
        scope: widget.title,
        sortMode: _sortMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complete Audit report exported to $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export Audit report: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _severityLabel(AuditSeverity severity) => switch (severity) {
    AuditSeverity.error => 'Errors',
    AuditSeverity.warning => 'Warnings',
    AuditSeverity.info => 'Info',
  };

  Widget _issueCard(NumberedAuditIssue numbered) {
    final issue = numbered.issue;
    return Semantics(
      label:
          '${numbered.label}. ${issue.message}. Code ${issue.code}. ${issue.location}',
      child: Card(
        child: ListTile(
          leading: Icon(
            issue.severity == AuditSeverity.error
                ? Icons.error_outline
                : issue.severity == AuditSeverity.warning
                ? Icons.warning_amber_outlined
                : Icons.info_outline,
          ),
          title: Text(issue.message),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numbered.label),
              Text('Code: ${issue.code}'),
              Text(issue.location),
            ],
          ),
          isThreeLine: true,
          trailing: issue.roundId == null
              ? null
              : Icon(
                  widget.course.originType.isOfficial
                      ? Icons.visibility_outlined
                      : Icons.edit_outlined,
                ),
          onTap: issue.roundId == null
              ? null
              : () => Navigator.pop(context, issue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issues = widget.result.numbered(_sortMode, severity: _filter);
    Widget chip(String label, AuditSeverity? severity) => ChoiceChip(
      label: Text(label),
      selected: _filter == severity,
      onSelected: (_) => setState(() => _filter = severity),
    );
    return Scaffold(
      appBar: AppBar(
        title: CoursePreviewTitle(
          course: widget.course,
          title: Text(widget.title),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip('All ${widget.result.issues.length}', null),
                  chip(
                    'Errors ${widget.result.count(AuditSeverity.error)}',
                    AuditSeverity.error,
                  ),
                  chip(
                    'Warnings ${widget.result.count(AuditSeverity.warning)}',
                    AuditSeverity.warning,
                  ),
                  chip(
                    'Info ${widget.result.count(AuditSeverity.info)}',
                    AuditSeverity.info,
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButton<AuditSortMode>(
                      isExpanded: true,
                      value: _sortMode,
                      onChanged: (value) => setState(
                        () => _sortMode = value ?? AuditSortMode.lesson,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AuditSortMode.lesson,
                          child: Text('By Lesson'),
                        ),
                        DropdownMenuItem(
                          value: AuditSortMode.exerciseType,
                          child: Text('By Exercise type'),
                        ),
                        DropdownMenuItem(
                          value: AuditSortMode.recentlyModified,
                          child: Text('Recently modified'),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('copy-audit-report'),
                    onPressed: _copyReport,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy report'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('export-audit-report'),
                    onPressed: _exportReport,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export report'),
                  ),
                ],
              ),
            ),
          ),
          if (issues.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No items in this category.'),
              ),
            ),
          for (final severity in AuditSeverity.values)
            if (issues.any((entry) => entry.issue.severity == severity)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                child: Text(
                  _severityLabel(severity),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...issues
                  .where((entry) => entry.issue.severity == severity)
                  .map(_issueCard),
            ],
        ],
      ),
    );
  }
}

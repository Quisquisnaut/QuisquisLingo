import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../screens/course_audit_screen.dart';
import '../services/course_audit_service.dart';
import '../services/course_import_check.dart';

/// Opens the Course Audit of a Course file that is not stored (owner
/// decision of 13 October 2026): every finding, with the page's filter
/// and its report. It reads the Course and stores nothing; Back returns
/// to the dialog it was opened from, which still waits for its answer.
Future<void> showCourseFileAudit(BuildContext context, Course course) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(
          course: course,
          result: CourseAuditService().auditCourse(course),
          title: courseFileAuditTitle,
        ),
      ),
    );

/// The title of the Audit page of a file that is not stored.
const courseFileAuditTitle = 'Course Audit of the file';

/// Shows what the check of a Course file found, before an import or a Merge
/// stores anything (Build 272 Revision 13, owner decisions of 13 October
/// 2026). The pop-up stays until it is answered: with anomalies it lists
/// them (Import anyway / Cancel), without it says so and tells about the
/// Course (Import / Cancel). True to go on; anything else uses nothing of
/// the file.
Future<bool> confirmCourseFile(
  BuildContext context, {
  required Course course,
  required CourseImportCheck check,
  CourseFileUse use = CourseFileUse.import,
}) async {
  if (!CourseImportCheckDialog.enabled) return true;
  final answer = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        CourseImportCheckDialog(course: course, check: check, use: use),
  );
  return answer == true;
}

/// The pop-up of [confirmCourseFile]. It lists; it never refuses.
class CourseImportCheckDialog extends StatelessWidget {
  const CourseImportCheckDialog({
    super.key,
    required this.course,
    required this.check,
    this.use = CourseFileUse.import,
  });

  final Course course;
  final CourseImportCheck check;
  final CourseFileUse use;

  /// Test seam: the import tests written before this pop-up answer no
  /// question at this point; its own tests turn it on.
  static bool enabled = true;

  @override
  Widget build(BuildContext context) =>
      check.hasAnomalies ? _anomalies(context) : _checked(context);

  String get _title => CourseImportCheck.shown(course.title);

  List<Widget> _reminders() => [
    for (final (index, reminder) in check.reminders.indexed)
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(reminder, key: Key('import-check-reminder-$index')),
      ),
  ];

  /// Every finding of the Course Audit, before the answer is given.
  Widget _seeAudit(BuildContext context) => TextButton(
    key: const Key('import-check-audit'),
    onPressed: () => showCourseFileAudit(context, course),
    child: const Text('See the Audit'),
  );

  /// The texts can be selected, to send them to the Course's author.
  Widget _content(List<Widget> children) => SizedBox(
    width: 560,
    child: SelectionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  Widget _anomalies(BuildContext context) {
    final theme = Theme.of(context);
    final count = check.anomalies.length;
    return AlertDialog(
      key: const Key('import-anomalies'),
      scrollable: true,
      title: Text('Check this Course before ${use.doing}'),
      content: _content([
        Text(
          'QuisquisLingo checked “$_title” and found '
          '${count == 1 ? 'one thing' : '$count things'} to look at before '
          '${use.doing}:',
          key: const Key('import-anomalies-intro'),
        ),
        const SizedBox(height: 12),
        for (final (index, item) in check.anomalies.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(
                  child: Text(item.text, key: Key('import-anomaly-$index')),
                ),
              ],
            ),
          ),
        ..._reminders(),
        const SizedBox(height: 4),
        Text(
          switch (use) {
            CourseFileUse.import =>
              'Import anyway goes on with the import of the Course as it '
                  'is. Cancel changes nothing on this device.',
            CourseFileUse.merge =>
              'Continue anyway goes on with the Merge, with this Course as '
                  'it is. Cancel leaves the Merge as it was.',
          },
          key: const Key('import-anomalies-outcome'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ]),
      actions: [
        _seeAudit(context),
        TextButton(
          key: const Key('import-anomalies-cancel'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('import-anomalies-import'),
          onPressed: () => Navigator.pop(context, true),
          child: Text('${use.goOn} anyway'),
        ),
      ],
    );
  }

  Widget _checked(BuildContext context) {
    final facts = check.facts;
    final localizations = MaterialLocalizations.of(context);
    final edited = facts.lastEdited;
    // The words of Course Info for a date.
    final when = edited == null
        ? 'Not recorded'
        : '${localizations.formatFullDate(edited)} · '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(edited))}';
    final team = facts.team;
    final lines = [
      ('authors', 'Authors: ${facts.authors}'),
      ('maintainer', '${facts.maintainerLabel}: ${facts.maintainer}'),
      if (team != null) ('team', 'Team: $team'),
      (
        'last-edited',
        'Last edited: $when'
            '${facts.lastEditor.isEmpty ? '' : ', by ${facts.lastEditor}'}',
      ),
      ('license', 'License: ${facts.license}'),
      ('content', facts.content),
    ];
    return AlertDialog(
      key: const Key('import-checked'),
      scrollable: true,
      title: const Text('Course checked: no anomalies'),
      content: _content([
        Text(
          'QuisquisLingo checked “$_title” for anomalies and found none.',
          key: const Key('import-checked-intro'),
        ),
        const SizedBox(height: 12),
        for (final (id, text) in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(text, key: Key('import-checked-fact-$id')),
          ),
        const SizedBox(height: 4),
        ..._reminders(),
      ]),
      actions: [
        _seeAudit(context),
        TextButton(
          key: const Key('import-checked-cancel'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('import-checked-import'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(use.goOn),
        ),
      ],
    );
  }
}

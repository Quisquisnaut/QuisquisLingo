import 'package:flutter/material.dart';

import '../services/course_audit_service.dart';
import '../services/timed_round_rules.dart';

/// Asks whether a published [entity] (Exercise, Round, Lesson) may go back to
/// Draft. Shared by the Course Editor's forms and the Generic Primitive
/// Editor, so both say the same thing.
Future<bool> confirmMoveToDraft(BuildContext context, String entity) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply $entity as draft?'),
        content: Text(
          'This $entity will disappear from learner-facing content. Existing learner progress and XP will be preserved.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply as draft'),
          ),
        ],
      ),
    ) ??
    false;

/// A list of [lines] under [title] with Keep editing: why an exercise form
/// refuses to apply an exercise (both exercise forms) or to Preview it (the
/// canonical editor) (Build 273 Revision 1).
Future<void> showEditorList(
  BuildContext context,
  String title,
  List<String> lines,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
        ],
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep editing'),
      ),
    ],
  ),
);

/// The Audit's [warnings] about an exercise about to be applied as normal
/// content, with every finding of [issues] listed: Keep editing (false) or
/// Use anyway (true). Shared by the two exercise forms (Build 273
/// Revision 1).
Future<bool> confirmUseAnyway(
  BuildContext context,
  int warnings,
  List<CourseAuditIssue> issues,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exercise audit: $warnings warnings'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${issue.severity.name.toUpperCase()} [${issue.code}]: ${issue.message}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use anyway'),
          ),
        ],
      ),
    ) ==
    true;

/// The authoring title prompt shared by the Course Editor's Lesson Options and
/// the Lessons screen. Returns null when cancelled or left empty.
Future<String?> askAuthoringName(
  BuildContext context, {
  String title = 'New Lesson',
  String initial = '',
  String confirmLabel = 'Create',
  int? maxLength,
  String fieldLabel = 'Title',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLength: maxLength,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: fieldLabel,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  return result == null || result.isEmpty ? null : result;
}

/// The Time limit menu of a Timed Round and of the default Timed limits:
/// the usual limits, or a number of seconds of the author's own.
Future<int?> chooseTimedLimit(BuildContext context) async {
  final choice = await showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      key: const Key('timed-limit-picker'),
      title: const Text('Time limit'),
      children: [
        for (final seconds in TimedRoundRules.presetSeconds)
          SimpleDialogOption(
            key: Key('timed-limit-$seconds'),
            onPressed: () => Navigator.pop(dialogContext, seconds),
            child: Text(TimedRoundRules.label(seconds)),
          ),
        SimpleDialogOption(
          key: const Key('timed-limit-custom'),
          onPressed: () => Navigator.pop(dialogContext, -1),
          child: const Text('Custom'),
        ),
      ],
    ),
  );
  if (choice != -1 || !context.mounted) return choice;
  int? custom;
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, update) => AlertDialog(
        key: const Key('timed-custom-limit-dialog'),
        title: const Text('Custom time limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('timed-custom-seconds'),
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Seconds (30–600)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => update(() => custom = int.tryParse(value)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('timed-custom-save'),
            onPressed: custom != null && TimedRoundRules.validSeconds(custom!)
                ? () => Navigator.pop(dialogContext, custom)
                : null,
            child: const Text('Use limit'),
          ),
        ],
      ),
    ),
  );
}

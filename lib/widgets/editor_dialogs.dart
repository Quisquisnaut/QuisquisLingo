import 'package:flutter/material.dart';

/// Asks whether a published [entity] (Exercise, Round, Lesson) may go back to
/// Draft. Shared by the Course Editor's forms and the Generic Primitive
/// Editor, so both say the same thing.
Future<bool> confirmMoveToDraft(BuildContext context, String entity) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save $entity as draft?'),
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
            child: const Text('Save as draft'),
          ),
        ],
      ),
    ) ??
    false;

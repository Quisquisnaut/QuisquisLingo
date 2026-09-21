import 'package:flutter/material.dart';

import '../services/import/import_result.dart';

/// The result of a multiple import: one line per outcome that occurred, and
/// each file's own reason below, expandable. File names only, never paths.
Future<void> showImportSummary(
  BuildContext context, {
  required String title,
  required List<ImportItemResult> items,
}) {
  final batch = ImportBatchResult(items);
  final problems = [
    for (final item in items)
      if (item.outcome != ImportItemOutcome.imported &&
          item.outcome != ImportItemOutcome.staged)
        item,
  ];
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in batch.summaryLines())
                Text(line, key: ValueKey('import-summary-$line')),
              if (problems.isNotEmpty)
                ExpansionTile(
                  key: const Key('import-summary-details'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Details'),
                  children: [
                    for (final item in problems)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.displayName),
                        subtitle: Text(item.message ?? item.outcome.label),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

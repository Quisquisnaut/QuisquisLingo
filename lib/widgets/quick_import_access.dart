import 'package:flutter/material.dart';

import '../services/storage/qql_storage.dart';

/// What a Quick Import does after [ensureQuickImportAccess].
enum QuickImportAccess {
  /// Go on: QQL can read the Quick Import folders now.
  ready,

  /// The person chose Open from… instead; run the dialog route.
  openFrom,

  /// Stop quietly: cancelled, or access was not given (already explained).
  stop,
}

/// Call before every Quick Import. On desktop it returns at once. On
/// Android, while QQL does not hold (or no longer holds) its one permission
/// for `Download/QuisquisLingo`, it explains why, asks Android once, and
/// offers Open from… as the alternative. It never uses private storage
/// instead.
Future<QuickImportAccess> ensureQuickImportAccess(
  BuildContext context, {
  required bool offerOpenFrom,
  QqlStorage? storage,
}) async {
  final qql = storage ?? QqlStorage();
  if (await qql.hasImportAccess()) return QuickImportAccess.ready;
  final steps = await qql.importAccessSteps();
  if (!context.mounted) return QuickImportAccess.stop;
  final folder = qql.importAccessLabel;
  final choice = await showDialog<QuickImportAccess>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('quick-import-access-dialog'),
      title: const Text('Allow Quick Import'),
      content: Text(
        'Quick Import reads the files you put in the '
        '${QqlTopFolder.import.folderName} and '
        '${QqlTopFolder.toBeMerged.folderName} folders of $folder, without a '
        'dialog. Android asks you once to let QQL read $folder.'
        '${steps == null ? '' : '\n\n$steps'}'
        '${offerOpenFrom ? '\n\nOr choose Open from… to pick one file '
                  'anywhere, without giving folder access.' : ''}',
      ),
      actions: [
        TextButton(
          key: const Key('quick-import-access-cancel'),
          onPressed: () => Navigator.pop(dialogContext, QuickImportAccess.stop),
          child: const Text('Cancel'),
        ),
        if (offerOpenFrom)
          TextButton(
            key: const Key('quick-import-access-open-from'),
            onPressed: () =>
                Navigator.pop(dialogContext, QuickImportAccess.openFrom),
            child: const Text('Open from… instead'),
          ),
        FilledButton(
          key: const Key('quick-import-access-continue'),
          onPressed: () =>
              Navigator.pop(dialogContext, QuickImportAccess.ready),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (choice != QuickImportAccess.ready) {
    return choice ?? QuickImportAccess.stop;
  }
  final result = await qql.requestImportAccess();
  if (result == QuickImportAccessResult.granted) return QuickImportAccess.ready;
  if (context.mounted) {
    final alternative = offerOpenFrom ? ' You can use Open from… instead.' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(switch (result) {
          QuickImportAccessResult.wrongFolder =>
            'That was not $folder. Quick Import needs exactly that folder; '
                'choose Quick Import again to retry.$alternative',
          _ =>
            'Quick Import cannot read $folder without that permission.'
                '$alternative',
        }),
      ),
    );
  }
  return QuickImportAccess.stop;
}

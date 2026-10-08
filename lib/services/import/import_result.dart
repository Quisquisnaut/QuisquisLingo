import 'import_stager.dart';

/// What happened to one selected file. A multiple import reports one of these
/// per file, never a single success flag.
enum ImportItemOutcome {
  /// Read into staging, not yet validated or committed.
  staged('Ready'),
  imported('Imported'),
  duplicateSkipped('Duplicates skipped'),
  skippedByUser('Skipped'),
  invalidType('Wrong type'),
  malformed('Unreadable or damaged'),
  tooLarge('Too large'),
  metadataTooLarge('Metadata too large'),
  unauthorized('Not allowed'),
  storageFailure('Storage failure'),
  accessFailure('Could not be read'),
  cancelled('Cancelled'),
  notProcessedBatchLimit('Not processed: batch limit');

  const ImportItemOutcome(this.label);

  /// A short heading for the batch summary.
  final String label;
}

class ImportItemResult {
  const ImportItemResult(
    this.displayName,
    this.outcome, {
    this.message,
    this.staged,
  });

  /// The sanitized file name, never a full path.
  final String displayName;
  final ImportItemOutcome outcome;
  final String? message;

  /// The staged copy for [ImportItemOutcome.staged]; the caller discards it.
  final StagedFile? staged;
}

class ImportBatchResult {
  const ImportBatchResult(this.items);

  final List<ImportItemResult> items;

  int count(ImportItemOutcome outcome) =>
      items.where((item) => item.outcome == outcome).length;

  Iterable<StagedFile> get staged =>
      items.map((item) => item.staged).whereType<StagedFile>();

  /// `Selected: 24` then one line per outcome that occurred, in enum order.
  List<String> summaryLines() => [
    'Selected: ${items.length}',
    for (final outcome in ImportItemOutcome.values)
      if (count(outcome) > 0) '${outcome.label}: ${count(outcome)}',
  ];

  /// Discards every staged copy; never throws.
  Future<void> discardAll() async {
    for (final file in staged) {
      await file.discard();
    }
  }
}

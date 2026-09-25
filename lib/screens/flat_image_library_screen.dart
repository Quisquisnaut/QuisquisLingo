import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../services/course_image_removal.dart';
import '../services/course_image_usage.dart';
import '../services/course_media_store.dart';
import '../services/exercise_image_metadata_service.dart';
import '../services/exercise_image_service.dart';
import '../services/file_dialog_service.dart';
import '../services/image_bank_service.dart';
import '../services/image_library_rules.dart';
import '../services/image_preview_tooltip.dart';
import '../services/import/import_result.dart';
import '../services/profile_service.dart';
import '../widgets/course_media_image.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/image_badges.dart';
import '../widgets/import_summary.dart';
import '../services/course_package_service.dart';
import '../services/import/image_validator.dart';
import '../widgets/quick_import_access.dart';

class FlatImageLibraryScreen extends StatefulWidget {
  final bool selectMode;
  final bool readOnly;
  final bool metadataEditingEnabled;
  final String? actorProfileId;
  final ExerciseImageMetadataService? metadataService;
  final ExerciseImageService? imageService;
  final ImageBankService? bankService;
  final ProfileService? profileService;
  final Course? course;
  final CourseMediaStore? mediaStore;

  /// Course Editor only: lets someone editing [course] remove an image from
  /// it. Receives the changed working copy; nothing is stored until the
  /// Course is confirmed.
  final ValueChanged<Course>? onCourseChanged;

  /// The Course as last saved, when [onCourseChanged] is set. A leftover file
  /// that neither it nor the edited Course uses can be deleted at once;
  /// otherwise files leave only through the confirmed save.
  final Course? savedCourse;

  const FlatImageLibraryScreen({
    super.key,
    this.selectMode = true,
    this.readOnly = false,
    this.metadataEditingEnabled = false,
    this.actorProfileId,
    this.metadataService,
    this.imageService,
    this.bankService,
    this.profileService,
    this.course,
    this.mediaStore,
    this.onCourseChanged,
    this.savedCourse,
  });

  @override
  State<FlatImageLibraryScreen> createState() => _FlatImageLibraryScreenState();
}

class _FlatImageLibraryScreenState extends State<FlatImageLibraryScreen> {
  late final ExerciseImageMetadataService _metadata =
      widget.metadataService ?? ExerciseImageMetadataService();
  late final ExerciseImageService _images =
      widget.imageService ?? ExerciseImageService();
  late final ImageBankService _banks = widget.bankService ?? ImageBankService();
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final CourseMediaStore _courseMedia =
      widget.mediaStore ?? CourseMediaStore();

  /// The Course as last changed here; starts as the one the screen was
  /// opened with.
  late Course? _course = widget.course;
  final _scroll = ScrollController();
  List<ExerciseImageMetadata> _all = const [];
  Set<String> _usedReferences = const {};
  Set<String> _usedSharedIds = const {};
  Set<String> _courseCopiedSharedIds = const {};
  String _query = '';
  String? _category;
  String? _badge;
  ImageSort _sort = ImageSort.name;
  Map<String, DateTime> _addedAt = const {};
  Map<String, int> _fileBytes = const {};
  bool _fileBytesLoaded = false;
  String? _loadError;
  bool _loading = true;
  bool _canManageMetadata = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final records = await _metadata.loadCatalog();
      final owned = <ExerciseImageMetadata>[];
      final ownedDates = <String, DateTime>{};
      final ownedSources = <String, String?>{};
      final course = _course;
      final imageElements = course == null
          ? const <PromptElement>[]
          : CourseImageUsage.imageElements(course).toList();
      if (course != null) {
        final sources = <String, SharedImageSource>{};
        for (final element in imageElements) {
          if (element.sharedImageSource != null) {
            sources[element.asset] = element.sharedImageSource!;
          }
        }
        final listed = <String, CourseImageLibraryEntry>{};
        for (final entry in course.imageLibrary) {
          listed[entry.asset] = entry;
          final source = entry.sharedImageSource;
          if (source != null) sources.putIfAbsent(entry.asset, () => source);
        }
        final directory = await _courseMedia.courseDirectory(course.courseId);
        if (await directory.exists()) {
          await for (final entity in directory.list(followLinks: false)) {
            if (entity is! File) continue;
            final name = entity.uri.pathSegments.last;
            final reference = 'media:$name';
            if (!CourseMediaStore.isImageReference(reference)) continue;
            final source = sources[reference];
            try {
              ownedDates['course_$name'] = (await entity.lastModified())
                  .toUtc();
            } catch (_) {}
            ownedSources['course_$name'] = source?.id;
            final entry = listed[reference];
            owned.add(
              ExerciseImageMetadata(
                id: 'course_$name',
                label:
                    source?.label ??
                    (entry != null && entry.label.isNotEmpty
                        ? entry.label
                        : 'Course image ${name.substring(0, 8)}'),
                category:
                    source?.category ??
                    (entry != null && entry.category.isNotEmpty
                        ? entry.category
                        : 'other'),
                tags: source?.tags ?? entry?.tags ?? const [],
                assetPath: reference,
                origin: source == null ? 'course' : 'course-device',
                attribution: source?.attribution ?? entry?.attribution,
              ),
            );
          }
        }
      }
      final copied = mergeCourseCopies(
        records: records,
        owned: owned,
        ownedSources: ownedSources,
        isMissing: _isMissing,
      );
      final actor = widget.actorProfileId;
      final canManage =
          !widget.readOnly &&
          widget.metadataEditingEnabled &&
          actor != null &&
          await _profiles.isAdmin(actor);
      if (!mounted) return;
      setState(() {
        _all = [...records, ...owned]
          ..sort(
            (left, right) =>
                left.label.toLowerCase().compareTo(right.label.toLowerCase()),
          );
        _usedReferences = course == null
            ? const {}
            : CourseImageUsage.usedAssets(course);
        _usedSharedIds = course == null
            ? const {}
            : {
                for (final element in imageElements)
                  if (element.sharedImageSource != null)
                    element.sharedImageSource!.id,
              };
        _addedAt = {
          for (final record in records)
            if (stampedAddedDate(record) case final date?) record.id: date,
          ...ownedDates,
        };
        _fileBytes = const {};
        _fileBytesLoaded = false;
        _courseCopiedSharedIds = copied;
        _canManageMetadata = canManage;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('FormatException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _importSingle({bool fromDialog = false}) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    if (!fromDialog) {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _images.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _importSingle(fromDialog: true);
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    try {
      final PickedImage picked;
      if (fromDialog) {
        final result = await _images.readImageFromDialog();
        if (!mounted) return;
        final image = result.picked;
        if (image == null) {
          showFileDialogFeedback(
            context,
            result.dialog,
            saving: false,
            fallbackHint: exerciseImageFallbackHint,
          );
          return;
        }
        picked = image;
      } else {
        picked = await _images.readImage();
      }
      if (mounted && (picked.image.width > 512 || picked.image.height > 512)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'This image is larger than the recommended 256 × 256 px resolution.',
            ),
          ),
        );
      }
      await _images.addToSharedLibrary(
        actorProfileId: actor,
        picked: picked,
        metadata: _metadata,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text('$error')),
      );
    }
  }

  /// Open image files from…: up to 100 images, each checked and added on its
  /// own, then one summary instead of a stream of messages.
  Future<void> _importManyFromDialog() async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    final List<PickedImageResult> items;
    try {
      final result = await _images.readImagesFromDialog();
      if (!mounted) return;
      if (result.dialog.outcome != FileDialogOutcome.opened) {
        showFileDialogFeedback(
          context,
          result.dialog,
          saving: false,
          fallbackHint: exerciseImageFallbackHint,
        );
        return;
      }
      items = result.items;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text('$error')),
      );
      return;
    }
    final outcomes = <PickedImageResult>[];
    for (final item in items) {
      final picked = item.picked;
      if (picked == null) {
        outcomes.add(item);
        continue;
      }
      try {
        await _images.addToSharedLibrary(
          actorProfileId: actor,
          picked: picked,
          metadata: _metadata,
        );
        outcomes.add(PickedImageResult(item.name, ImportItemOutcome.imported));
      } on DuplicateImageException catch (error) {
        outcomes.add(
          PickedImageResult(
            item.name,
            ImportItemOutcome.duplicateSkipped,
            message: '$error',
          ),
        );
      } on StateError catch (error) {
        outcomes.add(
          PickedImageResult(
            item.name,
            ImportItemOutcome.unauthorized,
            message: error.message,
          ),
        );
      } catch (error) {
        outcomes.add(
          PickedImageResult(
            item.name,
            ImportItemOutcome.storageFailure,
            message: '$error',
          ),
        );
      }
    }
    await _load();
    if (!mounted) return;
    await showImportSummary(
      context,
      title: 'Images imported',
      items: [
        for (final item in outcomes)
          ImportItemResult(item.name, item.outcome, message: item.message),
      ],
    );
  }

  Future<void> _importBankFromDialog() => _importBank(fromDialog: true);

  Future<void> _importBank({bool fromDialog = false}) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    if (!fromDialog) {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _banks.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _importBank(fromDialog: true);
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    try {
      final ParsedImageBank bank;
      // IDs already in the library are resolved one by one below (skip,
      // replace or keep both), not refused.
      if (fromDialog) {
        // Open from…: the same checks and the same steps below.
        final picked = await _banks.readBankFromDialog();
        if (!mounted) return;
        final read = picked.bank;
        if (read == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: imageBankFallbackHint,
          );
          return;
        }
        bank = read;
      } else {
        bank = await _banks.readBankFromFolder();
      }
      if (!mounted) return;
      final result = await _banks.importToSharedLibrary(
        bank,
        metadata: _metadata,
        actorProfileId: actor,
        chooseNewCategories: _chooseNewCategories,
        chooseConflict: _chooseConflict,
      );
      if (result == null) return;
      await _load();
      if (!mounted) return;
      final notes = [
        if (result.duplicatesSkipped > 0)
          '${result.duplicatesSkipped} already here (skipped)',
        if (result.replaced > 0) '${result.replaced} replaced',
        if (result.keptBoth > 0) '${result.keptBoth} kept as new copies',
        if (result.conflictsSkipped > 0)
          '${result.conflictsSkipped} same-ID images skipped',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Imported ${result.imported} images from ${result.bankName}'
            '${notes.isEmpty ? '' : '; ${notes.join(', ')}'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Image Bank import failed: $error'),
        ),
      );
    }
  }

  /// Asks the Admin what to do with a bank image whose ID is already used by
  /// a different picture. Closing the dialog skips it.
  Future<ConflictDecision> _chooseConflict(BankIdConflict conflict) async {
    if (!mounted) return (choice: ConflictChoice.skip, applyToAll: false);
    var applyToAll = false;
    final choice = await showDialog<ConflictChoice>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Same ID, different picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The bank’s “${conflict.incoming.label}” uses the ID '
                '${conflict.incoming.id}, which “${conflict.existing.label}” '
                'already has in Shared Images, with a different picture.'
                '${conflict.canReplace ? '' : ' QQL’s own images cannot be replaced.'}',
              ),
              CheckboxListTile(
                key: const Key('bank-conflict-all'),
                contentPadding: EdgeInsets.zero,
                value: applyToAll,
                onChanged: (value) =>
                    setDialogState(() => applyToAll = value ?? false),
                title: const Text('Apply to all'),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('bank-conflict-skip'),
              onPressed: () =>
                  Navigator.pop(dialogContext, ConflictChoice.skip),
              child: const Text('Skip'),
            ),
            TextButton(
              key: const Key('bank-conflict-keep'),
              onPressed: () =>
                  Navigator.pop(dialogContext, ConflictChoice.keepBoth),
              child: const Text('Keep both'),
            ),
            if (conflict.canReplace)
              FilledButton(
                key: const Key('bank-conflict-replace'),
                onPressed: () =>
                    Navigator.pop(dialogContext, ConflictChoice.replace),
                child: const Text('Replace'),
              ),
          ],
        ),
      ),
    );
    return (
      choice: choice ?? ConflictChoice.skip,
      applyToAll: choice != null && applyToAll,
    );
  }

  /// Asks the Admin what to do with categories an Image Bank adds.
  Future<NewCategoryChoice> _chooseNewCategories(List<String> names) async {
    if (!mounted) return NewCategoryChoice.cancel;
    final count = names.length;
    return await showDialog<NewCategoryChoice>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('New categories'),
            content: Text(
              'This bank adds $count new categor${count == 1 ? 'y' : 'ies'}: '
              '${names.join(', ')}.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, NewCategoryChoice.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                key: const Key('bank-categories-other'),
                onPressed: () =>
                    Navigator.pop(dialogContext, NewCategoryChoice.useOther),
                child: const Text('Put these images under Other'),
              ),
              FilledButton(
                key: const Key('bank-categories-add'),
                onPressed: () =>
                    Navigator.pop(dialogContext, NewCategoryChoice.add),
                child: const Text('Add them'),
              ),
            ],
          ),
        ) ??
        NewCategoryChoice.cancel;
  }

  /// Since Build 243 a Course keeps its own copy of every image it uses
  /// (course media), so deleting from the shared library never breaks one.
  static const _coursesKeepCopies =
      'Courses that use it keep their own copy and are not affected.';

  Future<void> _deleteLocal(ExerciseImageMetadata item) async {
    if (item.origin != 'local') return;
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete image?'),
            content: Text(
              'Delete “${item.label}” from the Shared Image Library? $_coursesKeepCopies',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _metadata.removeLocalRecords(
      actorProfileId: actor,
      imageIds: {item.id},
    );
    try {
      final file = File(item.assetPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _load();
  }

  Future<void> _removeBank(ExerciseImageMetadata item) async {
    final bankId = imageBankIdOf(item);
    final actor = widget.actorProfileId;
    if (bankId == null || !_canManageMetadata || actor == null) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove imported Image Bank?'),
            content: Text(
              'Remove this Image Bank and all of its local files? $_coursesKeepCopies',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remove bank'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final removedIds = await _banks.removeBank(bankId);
    // An image a later bank replaced keeps its new record.
    await _metadata.removeLocalRecords(
      actorProfileId: actor,
      imageIds: {
        for (final record in _all)
          if (removedIds.contains(record.id) && record.origin == 'bank:$bankId')
            record.id,
      },
    );
    await _load();
  }

  /// QQL images are read-only: their category and tags come from the app.
  /// An Admin may add Local words, search words for this device only.
  Future<void> _editLocalWords(ExerciseImageMetadata item, String actor) async {
    var wordsText = item.localWords.join(', ');
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Local words · ${item.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'QQL images keep the category and tags QQL gives them. '
                  'Local words are extra search words on this device only; '
                  'they are never exported.',
                ),
                const SizedBox(height: 12),
                Text('Category: ${item.category.replaceAll('_', ' ')}'),
                Text('Tags: ${item.tags.join(', ')}'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('exercise-image-local-editor'),
                  initialValue: wordsText,
                  onChanged: (value) => wordsText = value,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Local',
                    helperText: 'Separate words with commas.',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('exercise-image-metadata-save'),
              onPressed: () async {
                try {
                  await _metadata.updateLocalWords(
                    actorProfileId: actor,
                    imageId: item.id,
                    words: wordsText.split(','),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (exception) {
                  setDialogState(
                    () => error = exception.toString().replaceFirst(
                      'FormatException: ',
                      '',
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) await _load();
  }

  /// Asks for a new device category name; returns it once created.
  Future<String?> _createCategory(String actor, {String? renaming}) async {
    var name = renaming ?? '';
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(renaming == null ? 'New category' : 'Rename category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('exercise-image-category-name'),
                initialValue: name,
                autofocus: true,
                onChanged: (value) => name = value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                  helperText: 'Lowercase letters, digits and underscores.',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('exercise-image-category-save'),
              onPressed: () async {
                try {
                  final created = renaming == null
                      ? await _metadata.addDeviceCategory(
                          actorProfileId: actor,
                          name: name,
                        )
                      : await _metadata.renameDeviceCategory(
                          actorProfileId: actor,
                          from: renaming,
                          to: name,
                        );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, created);
                  }
                } catch (exception) {
                  setDialogState(
                    () => error = exception.toString().replaceFirst(
                      RegExp(r'^(FormatException|Bad state): '),
                      '',
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Lists this device's own categories for renaming or removal.
  Future<void> _manageCategories() async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    var names = await _metadata.deviceCategories();
    if (!mounted) return;
    var changed = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> refresh() async {
            final latest = await _metadata.deviceCategories();
            changed = true;
            setDialogState(() => names = latest);
          }

          return AlertDialog(
            title: const Text('Device categories'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "QQL's categories cannot change. Categories added on this "
                    'device can be renamed, or removed when no image uses them.',
                  ),
                  const SizedBox(height: 8),
                  if (names.isEmpty) const Text('No device categories yet.'),
                  for (final name in names)
                    ListTile(
                      key: ValueKey('device-category-$name'),
                      dense: true,
                      title: Text(name.replaceAll('_', ' ')),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            onPressed: () async {
                              if (await _createCategory(
                                    actor,
                                    renaming: name,
                                  ) !=
                                  null) {
                                await refresh();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () async {
                              try {
                                await _metadata.removeDeviceCategory(
                                  actorProfileId: actor,
                                  name: name,
                                );
                                await refresh();
                              } catch (exception) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      exception.toString().replaceFirst(
                                        RegExp(
                                          r'^(FormatException|Bad state): ',
                                        ),
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('device-category-add'),
                onPressed: () async {
                  if (await _createCategory(actor) != null) await refresh();
                },
                child: const Text('New category…'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
    if (changed) await _load();
  }

  Future<void> _editMetadata(ExerciseImageMetadata item) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    if (isBundledImage(item)) return _editLocalWords(item, actor);
    final categoryChoices = await _metadata.allCategories();
    if (!mounted) return;
    var category = item.category;
    var tagsText = item.tags.join(', ');
    var author = item.attribution?.author ?? '';
    var license = item.attribution?.license ?? '';
    var title = item.attribution?.title ?? '';
    var source = item.attribution?.source ?? '';
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit metadata · ${item.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('exercise-image-category-editor-$category'),
                  initialValue: category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Category',
                  ),
                  items: [
                    for (final value in categoryChoices)
                      DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) category = value;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('exercise-image-new-category'),
                    onPressed: () async {
                      final created = await _createCategory(actor);
                      if (created == null) return;
                      setDialogState(() {
                        categoryChoices
                          ..add(created)
                          ..sort();
                        category = created;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New category…'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('exercise-image-tags-editor'),
                  initialValue: tagsText,
                  onChanged: (value) => tagsText = value,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Tags',
                    helperText: 'Separate tags with commas.',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Attribution (optional; author and license go together)'),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('exercise-image-attribution-author'),
                  initialValue: author,
                  onChanged: (value) => author = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Author',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('exercise-image-attribution-license'),
                  initialValue: license,
                  onChanged: (value) => license = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'License',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('exercise-image-attribution-title'),
                  initialValue: title,
                  onChanged: (value) => title = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Work title (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('exercise-image-attribution-source'),
                  initialValue: source,
                  onChanged: (value) => source = value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Source (optional)',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('exercise-image-metadata-save'),
              onPressed: () async {
                try {
                  final hasAttribution = [author, license, title, source].any(
                    (value) => value.trim().isNotEmpty,
                  );
                  await _metadata.updateMetadata(
                    actorProfileId: actor,
                    imageId: item.id,
                    category: category,
                    tags: tagsText.split(','),
                    attribution: hasAttribution
                        ? ImageAttribution.fromJson({
                            'author': author,
                            'license': license,
                            'title': title,
                            'source': source,
                          })
                        : null,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (exception) {
                  setDialogState(
                    () => error = exception.toString().replaceFirst(
                      'FormatException: ',
                      '',
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) await _load();
  }

  /// File sizes are read only when a size order is first chosen, because the
  /// bundled images must be loaded from the asset bundle to measure them.
  Future<void> _loadFileBytes() async {
    final sizes = <String, int>{};
    final course = _course;
    for (final item in _all) {
      try {
        final path = item.assetPath;
        if (path.startsWith('assets/')) {
          sizes[item.id] = (await rootBundle.load(path)).lengthInBytes;
        } else if (CourseMediaStore.isImageReference(path)) {
          if (course == null) continue;
          final file = await _courseMedia.existingFile(course.courseId, path);
          if (file != null) sizes[item.id] = await file.length();
        } else {
          sizes[item.id] = await File(path).length();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _fileBytes = sizes;
      _fileBytesLoaded = true;
    });
  }

  void _setSort(ImageSort sort) {
    setState(() => _sort = sort);
    if ((sort == ImageSort.largest || sort == ImageSort.smallest) &&
        !_fileBytesLoaded) {
      _loadFileBytes();
    }
  }

  /// A compact filter chip: smaller text, tight padding and no checkmark (the
  /// selected fill already shows the choice), so more categories fit a row.
  static Widget _filterChip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: ChoiceChip(
      key: key,
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selected: selected,
      onSelected: (_) => onSelected(),
    ),
  );

  /// The image with its badges over its own bottom-left corner. Under loose
  /// constraints the Stack hugs the image, so a narrow or short image still
  /// carries the badges on the picture rather than on the empty tile.
  Widget _badged(ExerciseImageMetadata item) => Stack(
    clipBehavior: Clip.none,
    children: [
      _imageFor(item),
      Positioned(
        left: 0,
        bottom: 0,
        child: ImageBadges([
          for (final badge in _badges(item))
            (label: badge, message: imageBadgeMeanings[badge]!),
        ]),
      ),
    ],
  );

  /// Delete or remove-bank control laid over the image's bottom-right corner,
  /// so it takes no row of its own; null when the viewer cannot remove it.
  Widget? _removeAction(ExerciseImageMetadata item) {
    if (_canRemoveFromCourse(item)) {
      return _cornerButton(
        'Remove from this Course',
        Icons.delete_outline,
        () => _removeFromCourse(item),
      );
    }
    if (!_canManageMetadata) return null;
    if (item.origin == 'local') {
      return _cornerButton(
        'Delete imported image',
        Icons.delete_outline,
        () => _deleteLocal(item),
      );
    }
    if (imageBankIdOf(item) != null) {
      return _cornerButton(
        'Remove this imported bank',
        Icons.inventory_2_outlined,
        () => _removeBank(item),
      );
    }
    return null;
  }

  static Widget _cornerButton(
    String tooltip,
    IconData icon,
    VoidCallback onPressed,
  ) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: 13,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.all(3),
    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    icon: Icon(icon),
  );

  /// Adds images to the Course being edited, unused until an exercise uses
  /// them: one image or several, or a whole Image Bank. Every image is
  /// checked first; nothing is written if the Course would pass its 300 MB
  /// package limit; duplicates are skipped. Nothing reaches the Shared Image
  /// Library.
  Future<void> _addToCourse(String source) async {
    if (source == 'image' || source == 'bank') {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _images.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _addToCourse(source == 'image' ? 'images_from' : 'bank_from');
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    final course = _course;
    final onChanged = widget.onCourseChanged;
    if (course == null || onChanged == null) return;
    final incoming = <_IncomingImage>[];
    final results = <ImportItemResult>[];
    try {
      switch (source) {
        case 'image':
          final picked = await _images.readImage();
          incoming.add(_IncomingImage.picked(picked));
        case 'images_from':
          final picked = await _images.readImagesFromDialog();
          if (!mounted) return;
          if (picked.dialog.outcome != FileDialogOutcome.opened) {
            showFileDialogFeedback(
              context,
              picked.dialog,
              saving: false,
              fallbackHint: exerciseImageFallbackHint,
            );
            return;
          }
          for (final item in picked.items) {
            final image = item.picked;
            if (image == null) {
              results.add(
                ImportItemResult(
                  item.name,
                  item.outcome,
                  message: item.message,
                ),
              );
            } else {
              incoming.add(_IncomingImage.picked(image));
            }
          }
        case 'bank' || 'bank_from':
          final ParsedImageBank bank;
          if (source == 'bank') {
            bank = await _banks.readBankFromFolder();
          } else {
            final picked = await _banks.readBankFromDialog();
            if (!mounted) return;
            final read = picked.bank;
            if (read == null) {
              showFileDialogFeedback(
                context,
                picked.dialog,
                saving: false,
                fallbackHint: imageBankFallbackHint,
              );
              return;
            }
            bank = read;
          }
          incoming.addAll(bank.images.map(_IncomingImage.bank));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text('$error')),
      );
      return;
    }
    if (incoming.isEmpty && results.isEmpty) return;

    // Room left under the Course package limit, counted before any write.
    var stored = 0;
    try {
      final directory = await _courseMedia.courseDirectory(course.courseId);
      if (await directory.exists()) {
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is File) stored += await entity.length();
        }
      }
    } catch (_) {}
    final adding = incoming.fold<int>(
      0,
      (sum, item) => sum + item.bytes.length,
    );
    if (stored + adding > CoursePackageService.maxPackageBytes) {
      if (!mounted) return;
      final left =
          (CoursePackageService.maxPackageBytes - stored) ~/ (1024 * 1024);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'These images would take the Course past its 300 MB limit '
            '(about $left MB left). Nothing was added.',
          ),
        ),
      );
      return;
    }

    final kept = CourseMediaStore.referencesOf(course);
    final entries = <CourseImageLibraryEntry>[];
    for (final item in incoming) {
      final reference = CourseMediaStore.referenceFor(
        item.bytes,
        item.extension,
      );
      if (kept.contains(reference) ||
          entries.any((e) => e.asset == reference)) {
        results.add(
          ImportItemResult(item.name, ImportItemOutcome.duplicateSkipped),
        );
        continue;
      }
      try {
        final entry = CourseImageLibraryEntry.checked(
          asset: reference,
          label: item.label,
          category: item.category,
          tags: item.tags,
          attribution: item.attribution,
        );
        await _courseMedia.addBytes(
          course.courseId,
          item.bytes,
          item.extension,
        );
        entries.add(entry);
        results.add(ImportItemResult(item.name, ImportItemOutcome.imported));
      } on FormatException catch (error) {
        results.add(
          ImportItemResult(
            item.name,
            ImportItemOutcome.malformed,
            message: error.message,
          ),
        );
      } catch (error) {
        results.add(
          ImportItemResult(
            item.name,
            ImportItemOutcome.storageFailure,
            message: '$error',
          ),
        );
      }
    }
    if (entries.isNotEmpty) {
      final changed = CourseImageRemoval.updateLibrary(course, add: entries);
      onChanged(changed);
      setState(() => _course = changed);
      await _load();
    }
    if (!mounted) return;
    await showImportSummary(
      context,
      title: 'Images added to this Course',
      items: results,
    );
  }

  /// Removal applies to images the Course uses. A QQL or DEVICE image the
  /// Course does not use has nothing to remove.
  bool _canRemoveFromCourse(ExerciseImageMetadata item) =>
      widget.onCourseChanged != null &&
      _course != null &&
      (_isUsed(item) || _isCourseStored(item));

  /// Stored in the Course folder: a Course image, or a Shared Image Library
  /// image whose Course copy shares its tile.
  bool _isCourseStored(ExerciseImageMetadata item) =>
      item.origin.startsWith('course') ||
      _courseCopiedSharedIds.contains(item.id);

  /// The Course assets [item] stands for: its own, plus a Course copy of a
  /// Shared Image Library image shown on the same tile, used or kept.
  Set<String> _courseAssetsOf(ExerciseImageMetadata item, Course course) => {
    item.assetPath,
    if (!isBundledImage(item)) ...[
      for (final element in CourseImageUsage.imageElements(course))
        if (element.sharedImageSource?.id == item.id) element.asset,
      for (final entry in course.imageLibrary)
        if (entry.sharedImageSource?.id == item.id) entry.asset,
    ],
  };

  Future<void> _removeFromCourse(ExerciseImageMetadata item) async {
    final course = _course;
    final onChanged = widget.onCourseChanged;
    if (course == null || onChanged == null) return;
    final assets = _courseAssetsOf(item, course);
    final stored = {
      for (final asset in assets)
        if (CourseMediaStore.isImageReference(asset)) asset,
    };
    final uses = [
      for (final use in CourseImageUsage.uses(course))
        if (assets.contains(use.asset)) use,
    ];
    if (uses.isEmpty && stored.isEmpty) return;

    // Step 1: take the image out of everything that uses it.
    var changed = course;
    var cleared = 0;
    var drafted = 0;
    if (uses.isNotEmpty) {
      if (await _confirmRemoveUses(item, uses, stored.isNotEmpty) != true ||
          !mounted) {
        return;
      }
      final result = CourseImageRemoval.remove(
        course,
        assets,
        now: DateTime.now(),
      );
      changed = result.course;
      cleared = result.clearedUses;
      drafted = result.draftedContentIds.length;
    }

    // Step 2: a Course-stored image may also leave the Course's library, or
    // stay there unused. Closing the question keeps it: nothing is lost.
    var removedFromLibrary = false;
    if (stored.isNotEmpty) {
      final leave = await _confirmLeaveLibrary(wasUsed: uses.isNotEmpty);
      if (!mounted) return;
      if (leave == true) {
        removedFromLibrary = true;
        changed = CourseImageRemoval.updateLibrary(changed, remove: stored);
      } else if (uses.isNotEmpty || leave == false) {
        changed = CourseImageRemoval.updateLibrary(
          changed,
          keep: {
            for (final asset in stored)
              asset:
                  CourseImageUsage.sharedSourceOf(course, asset) ??
                  _librarySource(course, asset),
          },
        );
      }
    }
    final courseChanged =
        jsonEncode(changed.toJson()) != jsonEncode(course.toJson());
    // A leftover file changes nothing in the Course but may still be deleted.
    if (!courseChanged && !removedFromLibrary) return;
    try {
      if (courseChanged) {
        onChanged(changed);
        setState(() => _course = changed);
      }
      final deletedNow = removedFromLibrary
          ? await _deleteLeftovers(changed, stored)
          : 0;
      await _load();
      if (!mounted) return;
      final parts = [
        if (cleared > 0)
          'Removed from $cleared ${cleared == 1 ? 'place' : 'places'}.',
        if (drafted > 0)
          '$drafted ${drafted == 1 ? 'item is' : 'items are'} now Draft.',
        if (removedFromLibrary && deletedNow == stored.length)
          'Removed from the Course.'
        else if (removedFromLibrary)
          'It leaves the Course when you confirm the Course.'
        else if (stored.isNotEmpty)
          "Kept in this Course's library.",
      ];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(parts.join(' '))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text('$error')),
      );
    }
  }

  SharedImageSource? _librarySource(Course course, String asset) {
    for (final entry in course.imageLibrary) {
      if (entry.asset == asset) return entry.sharedImageSource;
    }
    return null;
  }

  /// A file that neither the saved nor the edited Course uses is a leftover:
  /// deleting it now cannot break Discard. Anything else waits for the
  /// confirmed save.
  Future<int> _deleteLeftovers(Course changed, Set<String> assets) async {
    final saved = widget.savedCourse;
    if (saved == null) return 0;
    final kept = {
      ...CourseMediaStore.referencesOf(saved),
      ...CourseMediaStore.referencesOf(changed),
    };
    var deleted = 0;
    for (final asset in assets) {
      if (!kept.contains(asset) &&
          await _courseMedia.deleteStored(changed.courseId, asset)) {
        deleted++;
      }
    }
    return deleted;
  }

  Future<bool?> _confirmRemoveUses(
    ExerciseImageMetadata item,
    List<CourseImageUse> uses,
    bool stored,
  ) {
    final kept = isBundledImage(item)
        ? 'The QQL image stays available in the library.'
        : stored
        ? "Next you choose whether it also leaves this Course's library."
        : 'The Shared Image Library image stays on this device.';
    const shown = 8;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from this Course?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uses.length == 1
                    ? 'Used in 1 place:'
                    : 'Used in ${uses.length} places:',
              ),
              const SizedBox(height: 4),
              for (final use in uses.take(shown)) Text('• ${use.location}'),
              if (uses.length > shown)
                Text('• and ${uses.length - shown} more'),
              const SizedBox(height: 12),
              Text(
                'The image is removed from all of them. $kept Exercises that '
                'no longer work without it become Draft. Nothing is saved '
                'until you confirm the Course.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('exercise-image-remove-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// True: leave the Course's library. False: keep it there, unused.
  Future<bool?> _confirmLeaveLibrary({required bool wasUsed}) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            wasUsed
                ? "Also remove it from this Course's library?"
                : "Remove it from this Course's library?",
          ),
          content: Text(
            wasUsed
                ? 'No exercise uses this image any more. Remove it from the '
                      'Course too, or keep it in the Course\'s library, '
                      'unused, to use again later.'
                : 'No exercise uses this image. Remove it from the Course, or '
                      "keep it in the Course's library to use later.",
          ),
          actions: [
            TextButton(
              key: const Key('exercise-image-keep-in-library'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep in library'),
            ),
            FilledButton(
              key: const Key('exercise-image-remove-from-library'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove from Course'),
            ),
          ],
        ),
      );

  bool _isMissing(ExerciseImageMetadata item) =>
      !item.assetPath.startsWith('assets/') &&
      !CourseMediaStore.isImageReference(item.assetPath) &&
      !File(item.assetPath).existsSync();

  List<String> _badges(ExerciseImageMetadata item) => imageBadgesOf(
    item,
    used: _isUsed(item),
    inCourse: _courseCopiedSharedIds.contains(item.id),
  );

  bool _isUsed(ExerciseImageMetadata item) =>
      _usedReferences.contains(item.assetPath) ||
      (_course != null && _usedSharedIds.contains(item.id));

  Widget _imageFor(ExerciseImageMetadata item) {
    if (_isMissing(item)) {
      return const Center(
        child: Text('Image file missing', textAlign: TextAlign.center),
      );
    }
    if (item.assetPath.startsWith('assets/')) {
      return Image.asset(
        item.assetPath,
        fit: BoxFit.contain,
        // Grid thumbnails: decode small, whatever the source declares.
        cacheWidth: 320,
        cacheHeight: 320,
        errorBuilder: (_, _, _) => const Center(
          child: Text('Image file missing', textAlign: TextAlign.center),
        ),
      );
    }
    if (CourseMediaStore.isImageReference(item.assetPath) && _course != null) {
      return CourseMediaImage(
        courseId: _course!.courseId,
        asset: item.assetPath,
        mediaStore: _courseMedia,
        fit: BoxFit.contain,
        cacheWidth: 320,
        cacheHeight: 320,
        missing: const Center(child: Text('Image file missing')),
      );
    }
    return Image.file(
      File(item.assetPath),
      fit: BoxFit.contain,
      cacheWidth: 320,
      cacheHeight: 320,
      errorBuilder: (_, _, _) => const Center(
        child: Text('Image file unreadable', textAlign: TextAlign.center),
      ),
    );
  }

  Future<String> _previewDetails(ExerciseImageMetadata item) async {
    try {
      final Uint8List bytes;
      if (item.assetPath.startsWith('assets/')) {
        final data = await rootBundle.load(item.assetPath);
        bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } else {
        final File? file;
        if (CourseMediaStore.isImageReference(item.assetPath)) {
          final course = _course;
          file = course == null
              ? null
              : await _courseMedia.existingFile(course.courseId, item.assetPath);
        } else {
          file = File(item.assetPath);
        }
        if (file == null || !await file.exists()) {
          return imagePreviewTooltip(item: item, missing: true);
        }
        bytes = await file.readAsBytes();
      }

      int? width;
      int? height;
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      try {
        buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        width = descriptor.width;
        height = descriptor.height;
      } catch (_) {
        // Old stored images are read for details, never revalidated here.
      } finally {
        descriptor?.dispose();
        buffer?.dispose();
      }
      final format = switch (ImageValidator.sniff(bytes)) {
        ImageFormat.png => 'PNG',
        ImageFormat.jpeg => 'JPEG',
        ImageFormat.webp => 'WebP',
        null => null,
      };
      String? bankName;
      final bankId = imageBankIdOf(item);
      if (bankId != null) {
        try {
          for (final bank in await _banks.banks()) {
            if (bank.id == bankId) {
              bankName = bank.name;
              break;
            }
          }
        } catch (_) {}
      }
      return imagePreviewTooltip(
        item: item,
        byteLength: bytes.length,
        width: width,
        height: height,
        format: format,
        addedAt: _addedAt[item.id],
        bankName: bankName,
        alsoStoredInCourse: _courseCopiedSharedIds.contains(item.id),
      );
    } catch (_) {
      return imagePreviewTooltip(item: item, missing: true);
    }
  }

  Future<void> _preview(ExerciseImageMetadata item) async {
    final details = _previewDetails(item);
    final size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (size.width - 32).clamp(280.0, 620.0).toDouble(),
            maxHeight: (size.height - 32).clamp(320.0, 760.0).toDouble(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Center(
                          child: FutureBuilder<String>(
                            future: details,
                            builder: (context, snapshot) => Tooltip(
                              key: const Key('image-preview-details-tooltip'),
                              message: snapshot.data ?? 'Loading image details…',
                              child: _imageFor(item),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Source: ${imageSourceCode(_badges(item))} '
                  '· ${imageSourceExplanation(item)}',
                ),
                Text('Category: ${item.category.replaceAll('_', ' ')}'),
                Tooltip(
                  message: 'Tags: ${item.tags.join(', ')}',
                  child: Text(
                    'Tags: ${item.tags.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.localWords.isNotEmpty)
                  Text(
                    'Local: ${item.localWords.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (item.attribution case final credit?)
                  Tooltip(
                    message: [
                      'Author: ${credit.author}',
                      'License: ${credit.license}',
                      if (credit.title.isNotEmpty) 'Work: ${credit.title}',
                      if (credit.source.isNotEmpty) 'Source: ${credit.source}',
                    ].join('\n'),
                    child: Text(
                      'Attribution: ${credit.author} · ${credit.license}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    if (_canManageMetadata)
                      OutlinedButton.icon(
                        key: const Key('exercise-image-metadata-edit'),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _editMetadata(item);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          isBundledImage(item)
                              ? 'Local words'
                              : 'Edit metadata',
                        ),
                      ),
                    if (_canRemoveFromCourse(item))
                      OutlinedButton.icon(
                        key: const Key('exercise-image-remove-from-course'),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _removeFromCourse(item);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove from this Course'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                    if (widget.selectMode && !_isMissing(item))
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context, item);
                        },
                        child: const Text('Use image'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _all.map((item) => item.category).toSet().toList()
      ..sort();
    final normalizedQuery = normalizeImageSearchText(_query);
    final presentBadges = {for (final item in _all) ..._badges(item)};
    final badges = imageBadgeOrder.where(presentBadges.contains).toList();
    // A filter left over from a reload that no longer offers it is ignored.
    final badge = badges.length > 1 && badges.contains(_badge) ? _badge : null;
    final items =
        _all
            .where(
              (item) =>
                  (_category == null || item.category == _category) &&
                  (badge == null || _badges(item).contains(badge)) &&
                  matchesImageSearch(item, normalizedQuery),
            )
            .toList()
          ..sort(
            (left, right) => compareImages(
              left,
              right,
              sort: _sort,
              addedAt: _addedAt,
              fileBytes: _fileBytes,
            ),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_course == null ? 'Shared Images' : 'Image Library'} '
          '· ${_all.length} images',
        ),
        actions: [
          if (widget.onCourseChanged != null && _course != null)
            PopupMenuButton<String>(
              key: const Key('course-image-add'),
              tooltip: 'Add images to this Course',
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onSelected: _addToCourse,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Text('Import image'),
                ),
                if (_images.fileDialogsAvailable)
                  const PopupMenuItem(
                    value: 'images_from',
                    child: Text('Open image files from…'),
                  ),
                const PopupMenuItem(
                  value: 'bank',
                  child: Text('Import Image Bank ZIP'),
                ),
                if (_banks.fileDialogsAvailable)
                  const PopupMenuItem(
                    value: 'bank_from',
                    child: Text('Open Image Bank ZIP from…'),
                  ),
              ],
            ),
          PopupMenuButton<ImageSort>(
            key: const Key('exercise-image-sort'),
            tooltip: 'Sort images: ${_sort.label}',
            icon: const Icon(Icons.sort),
            onSelected: _setSort,
            itemBuilder: (_) => [
              for (final sort in ImageSort.values)
                CheckedPopupMenuItem(
                  key: ValueKey('exercise-image-sort-${sort.name}'),
                  value: sort,
                  checked: sort == _sort,
                  child: Text(sort.label),
                ),
            ],
          ),
          if (_canManageMetadata)
            PopupMenuButton<String>(
              tooltip: 'Import',
              onSelected: (value) {
                if (value == 'bank') _importBank();
                if (value == 'bank_from') _importBankFromDialog();
                if (value == 'image') _importSingle();
                if (value == 'image_from') _importManyFromDialog();
                if (value == 'categories') _manageCategories();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'bank',
                  child: Text('Import Image Bank ZIP'),
                ),
                if (_banks.fileDialogsAvailable)
                  const PopupMenuItem(
                    value: 'bank_from',
                    child: Text('Open Image Bank ZIP from…'),
                  ),
                const PopupMenuItem(
                  value: 'image',
                  child: Text('Import single image'),
                ),
                if (_images.fileDialogsAvailable)
                  const PopupMenuItem(
                    value: 'image_from',
                    child: Text('Open image files from…'),
                  ),
                const PopupMenuItem(
                  value: 'categories',
                  child: Text('Manage device categories'),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Media metadata could not be loaded. $_loadError'),
              ),
            )
          : Column(
              children: [
                // Only a Course's own Image Library defers to the Course
                // confirmation; the device-wide Shared Images library writes
                // straight away and must not claim otherwise.
                if (widget.onCourseChanged != null && _course != null)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Card(
                      key: Key('course-image-save-notice'),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Changes here are kept as you make them and are '
                          'applied when you leave this screen, so there is no '
                          'Save button. They are written to the Course only '
                          'when you confirm the Course changes on leaving the '
                          'Course Editor. Cancelling the Course discards them, '
                          'and any images added in that session are removed '
                          'again.',
                        ),
                      ),
                    ),
                  ),
                if (_canManageMetadata)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin media management'),
                            SizedBox(height: 4),
                            Text(
                              'DEVICE images were added to this device by an Admin. When used, they are copied into a Course and included in its ZIP. QQL images are supplied by the app and are not included in the ZIP.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: TextField(
                    key: const Key('exercise-image-search'),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search images, categories or tags',
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _filterChip(
                        label: 'All',
                        selected: _category == null,
                        onSelected: () => setState(() => _category = null),
                      ),
                      for (final category in categories)
                        _filterChip(
                          label: category.replaceAll('_', ' '),
                          selected: _category == category,
                          onSelected: () =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                ),
                if (badges.length > 1)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      key: const Key('exercise-image-badge-filter'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _filterChip(
                          label: 'All badges',
                          selected: badge == null,
                          onSelected: () => setState(() => _badge = null),
                        ),
                        for (final option in badges)
                          _filterChip(
                            key: ValueKey('exercise-image-badge-$option'),
                            label: option,
                            selected: badge == option,
                            onSelected: () => setState(() => _badge = option),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No matching images.'))
                      : GridView.builder(
                          key: const Key('exercise-image-grid'),
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 104),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 170,
                                childAspectRatio: .74,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return InkWell(
                              key: ValueKey('exercise-image-${item.id}'),
                              onTap: () => _preview(item),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Center(
                                                child: _badged(item),
                                              ),
                                            ),
                                            if (_removeAction(item)
                                                case final action?)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: action,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // The category filter already shows the
                                      // category, so the tile carries only the
                                      // name and tags, in lowercase.
                                      Text(
                                        item.label.toLowerCase(),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (imageTileTags(item) case final tags?)
                                        Tooltip(
                                          message: tags,
                                          child: Text(
                                            tags,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 9),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _canManageMetadata
          ? FloatingActionButton.extended(
              onPressed: _importBank,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Import bank'),
            )
          : null,
    );
  }
}

/// One checked image on its way into a Course's own library.
class _IncomingImage {
  _IncomingImage.picked(PickedImage picked)
    : name = picked.sourceName,
      bytes = picked.image.bytes,
      extension = picked.image.format.extension,
      label = picked.sourceName.replaceFirst(RegExp(r'\.[^.]+$'), ''),
      category = '',
      tags = const [],
      attribution = null;

  _IncomingImage.bank(BankImage image)
    : name = image.filename,
      bytes = image.bytes,
      extension = ImageValidator.sniff(image.bytes)!.extension,
      label = image.label,
      category = _courseCategory(image.category),
      tags = image.tags,
      attribution = image.attribution;

  final String name;
  final Uint8List bytes;
  final String extension;
  final String label;
  final String category;
  final List<String> tags;
  final ImageAttribution? attribution;

  /// A bank category kept as Course-scoped text; `food`/`home` keep their
  /// usual meaning.
  static String _courseCategory(String raw) => switch (raw.trim()) {
    'food' => 'food_drinks',
    'home' => 'home_household',
    final value => value,
  };
}

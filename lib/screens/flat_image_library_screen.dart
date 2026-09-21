import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../services/course_media_store.dart';
import '../services/exercise_image_metadata_service.dart';
import '../services/exercise_image_service.dart';
import '../services/image_bank_service.dart';
import '../services/profile_service.dart';
import '../widgets/course_media_image.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/image_badges.dart';

String _normalizeImageSearchText(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('_', ' ')
    .replaceAll(RegExp(r'\s+'), ' ');

bool _matchesImageSearch(ExerciseImageMetadata asset, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  return <String>[
    asset.label,
    ...asset.tags,
    asset.id,
    asset.category,
  ].any((value) => _normalizeImageSearchText(value).contains(normalizedQuery));
}

enum _ImageSort {
  name('Name (A–Z)'),
  newest('Newest added'),
  oldest('Oldest added'),
  largest('Largest file'),
  smallest('Smallest file');

  const _ImageSort(this.label);
  final String label;
}

// No image record stores when it was added, so the date comes from values QQL
// itself generated: the microsecond stamp in a single import's ID, the stamp in
// its Image Bank ID, or when the file was written into the Course folder.
// Bundled images have no date and count as the oldest.
final _localIdStamp = RegExp(r'^local_(\d+)$');
final _bankOriginStamp = RegExp(r'^bank:bank_(\d+)$');

DateTime? _stampedDate(ExerciseImageMetadata item) {
  final match =
      _localIdStamp.firstMatch(item.id) ??
      _bankOriginStamp.firstMatch(item.origin);
  final micros = match == null ? null : int.tryParse(match.group(1)!);
  return micros == null
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
}

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
  final _scroll = ScrollController();
  List<ExerciseImageMetadata> _all = const [];
  Set<String> _usedReferences = const {};
  Set<String> _usedSharedIds = const {};
  Set<String> _courseCopiedSharedIds = const {};
  String _query = '';
  String? _category;
  String? _badge;
  _ImageSort _sort = _ImageSort.name;
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
      final course = widget.course;
      final imageElements = course == null
          ? const <PromptElement>[]
          : _courseImageElements(course).toList();
      if (course != null) {
        final sources = <String, SharedImageSource>{};
        for (final element in imageElements) {
          if (element.sharedImageSource != null) {
            sources[element.asset] = element.sharedImageSource!;
          }
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
            owned.add(
              ExerciseImageMetadata(
                id: 'course_$name',
                label: source?.label ?? 'Course image ${name.substring(0, 8)}',
                category: source?.category ?? 'other',
                tags: source?.tags ?? const [],
                assetPath: reference,
                origin: source == null ? 'course' : 'course-device',
                attribution: source?.attribution,
              ),
            );
          }
        }
      }
      // A Course copy of a Shared Image Library image whose original is still
      // on this device is shown once, as the original with a COURSE badge. A
      // record whose file is gone does not hide a working Course copy.
      final deviceIds = {
        for (final record in records)
          if (!_isBundled(record) && !_isMissing(record)) record.id,
      };
      final copied = <String>{};
      owned.removeWhere((item) {
        final sourceId = ownedSources[item.id];
        if (sourceId == null || !deviceIds.contains(sourceId)) return false;
        copied.add(sourceId);
        return true;
      });
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
            : {
                ...CourseMediaStore.referencesOf(course),
                if (course.coverImage.isNotEmpty) course.coverImage,
                for (final element in imageElements) element.asset,
              };
        _usedSharedIds = course == null
            ? const {}
            : {
                for (final element in imageElements)
                  if (element.sharedImageSource != null)
                    element.sharedImageSource!.id,
              };
        _addedAt = {
          for (final record in records)
            if (_stampedDate(record) case final date?) record.id: date,
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

  Future<void> _importSingleFromDialog() => _importSingle(fromDialog: true);

  Future<void> _importSingle({bool fromDialog = false}) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    String? path;
    try {
      if (fromDialog) {
        // Open from…: same checks and storage as the fixed-folder import,
        // then the identical size hint and metadata steps below.
        final picked = await _images.importImageFromDialog();
        if (!mounted) return;
        path = picked.path;
        if (path == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: exerciseImageFallbackHint,
          );
          return;
        }
      } else {
        path = await _images.importImage();
      }
      if (path == null) return;
      final info = await _images.inspect(path);
      if (mounted && (info.width > 512 || info.height > 512)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'This image is larger than the recommended 256 × 256 px resolution.',
            ),
          ),
        );
      }
      final file = File(path);
      final base = file.uri.pathSegments.last
          .replaceFirst(RegExp(r'^\d+_'), '')
          .replaceFirst(RegExp(r'\.[^.]+$'), '')
          .replaceAll('_', ' ')
          .trim();
      final label = base.isEmpty ? 'Imported image' : base;
      await _metadata.addLocalRecord(
        actorProfileId: actor,
        record: ExerciseImageMetadata(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          category: 'other',
          tags: [label.toLowerCase()],
          assetPath: path,
          origin: 'local',
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 8), content: Text('$error')),
      );
    }
  }

  Future<void> _importBankFromDialog() => _importBank(fromDialog: true);

  Future<void> _importBank({bool fromDialog = false}) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
    try {
      final ImageBankImportResult? result;
      final existingIds = _all.map((entry) => entry.id).toSet();
      if (fromDialog) {
        // Open from…: the same importer and the same metadata steps below.
        final picked = await _banks.importBankZipFromDialog(
          existingIds: existingIds,
        );
        if (!mounted) return;
        result = picked.result;
        if (result == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: imageBankFallbackHint,
          );
          return;
        }
      } else {
        result = await _banks.pickAndImportBank(existingIds: existingIds);
      }
      if (result == null) return;
      try {
        await _metadata.addLocalRecords(
          actorProfileId: actor,
          records: result.records,
        );
      } catch (_) {
        if (result.records.isNotEmpty) {
          final bankId = _bankId(result.records.first);
          if (bankId != null) await _banks.removeBank(bankId);
        }
        rethrow;
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Imported ${result.imported} images from ${result.bankName}.',
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
    final bankId = _bankId(item);
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
    await _metadata.removeLocalRecords(
      actorProfileId: actor,
      imageIds: removedIds,
    );
    await _load();
  }

  Future<void> _editMetadata(ExerciseImageMetadata item) async {
    final actor = widget.actorProfileId;
    if (!_canManageMetadata || actor == null) return;
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
                  key: const Key('exercise-image-category-editor'),
                  initialValue: category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Category',
                  ),
                  items: [
                    for (final value
                        in ExerciseImageMetadataService.categories.toList()
                          ..sort())
                      DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) category = value;
                  },
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
                if (!_isBundled(item)) ...[
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
                ],
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
    final course = widget.course;
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

  void _setSort(_ImageSort sort) {
    setState(() => _sort = sort);
    if ((sort == _ImageSort.largest || sort == _ImageSort.smallest) &&
        !_fileBytesLoaded) {
      _loadFileBytes();
    }
  }

  int _compareImages(ExerciseImageMetadata left, ExerciseImageMetadata right) {
    int byName() =>
        left.label.toLowerCase().compareTo(right.label.toLowerCase());
    final oldest = DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);
    int byDate() =>
        (_addedAt[left.id] ?? oldest).compareTo(_addedAt[right.id] ?? oldest);
    // An unmeasured file (missing, or sizes still loading) sorts last.
    int bySize(bool largestFirst) {
      final a = _fileBytes[left.id];
      final b = _fileBytes[right.id];
      if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
      return largestFirst ? b.compareTo(a) : a.compareTo(b);
    }

    final primary = switch (_sort) {
      _ImageSort.name => 0,
      _ImageSort.newest => -byDate(),
      _ImageSort.oldest => byDate(),
      _ImageSort.largest => bySize(true),
      _ImageSort.smallest => bySize(false),
    };
    return primary != 0 ? primary : byName();
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
            (label: badge, message: _badgeMeanings[badge]!),
        ]),
      ),
    ],
  );

  /// Delete or remove-bank control laid over the image's bottom-right corner,
  /// so it takes no row of its own; null when the viewer cannot remove it.
  Widget? _removeAction(ExerciseImageMetadata item) {
    if (!_canManageMetadata) return null;
    if (item.origin == 'local') {
      return _cornerButton(
        'Delete imported image',
        Icons.delete_outline,
        () => _deleteLocal(item),
      );
    }
    if (_bankId(item) != null) {
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

  bool _isMissing(ExerciseImageMetadata item) =>
      !item.assetPath.startsWith('assets/') &&
      !CourseMediaStore.isImageReference(item.assetPath) &&
      !File(item.assetPath).existsSync();

  List<String> _badges(ExerciseImageMetadata item) => _badgesOf(
    item,
    used: _isUsed(item),
    inCourse: _courseCopiedSharedIds.contains(item.id),
  );

  bool _isUsed(ExerciseImageMetadata item) =>
      _usedReferences.contains(item.assetPath) ||
      (widget.course != null && _usedSharedIds.contains(item.id));

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
    if (CourseMediaStore.isImageReference(item.assetPath) &&
        widget.course != null) {
      return CourseMediaImage(
        courseId: widget.course!.courseId,
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

  Future<void> _preview(ExerciseImageMetadata item) async {
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
                        child: Center(child: _imageFor(item)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Source: ${_sourceCode(_badges(item))} '
                  '· ${_sourceExplanation(item)}',
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
                        label: const Text('Edit metadata'),
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
    final normalizedQuery = _normalizeImageSearchText(_query);
    final presentBadges = {
      for (final item in _all) ..._badges(item),
    };
    final badges = _badgeOrder.where(presentBadges.contains).toList();
    // A filter left over from a reload that no longer offers it is ignored.
    final badge = badges.length > 1 && badges.contains(_badge) ? _badge : null;
    final items =
        _all
            .where(
              (item) =>
                  (_category == null || item.category == _category) &&
                  (badge == null ||
                      _badges(item).contains(badge)) &&
                  _matchesImageSearch(item, normalizedQuery),
            )
            .toList()
          ..sort(_compareImages);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.course == null ? 'Shared Image Library' : 'Image Library'} '
          '· ${_all.length} images',
        ),
        actions: [
          PopupMenuButton<_ImageSort>(
            key: const Key('exercise-image-sort'),
            tooltip: 'Sort images: ${_sort.label}',
            icon: const Icon(Icons.sort),
            onSelected: _setSort,
            itemBuilder: (_) => [
              for (final sort in _ImageSort.values)
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
                if (value == 'image_from') _importSingleFromDialog();
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
                    child: Text('Open single image from…'),
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
                                      if (_tileTags(item) case final tags?)
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

String? _bankId(ExerciseImageMetadata item) {
  if (!item.origin.startsWith('bank:')) return null;
  final id = item.origin.substring('bank:'.length).trim();
  return id.isEmpty ? null : id;
}

bool _isBundled(ExerciseImageMetadata item) =>
    item.origin == 'bundled' || item.assetPath.startsWith('assets/');

Iterable<PromptElement> _courseImageElements(Course course) sync* {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        for (final element in exercise.promptElements) {
          if (element.type == 'image') yield element;
        }
        for (final item in exercise.interaction.items) {
          for (final element in item.content) {
            if (element.type == 'image') yield element;
          }
        }
        for (final element in exercise.interaction.layout) {
          if (element.type == 'image') yield element;
        }
      }
    }
  }
}

/// Badge labels in display order; the badge filter offers the same labels.
const _badgeOrder = ['QQL', 'DEVICE', 'COURSE', 'IN USE'];

const _badgeMeanings = {
  'QQL': 'App bundled; supplied by QQL on every device.',
  'DEVICE': 'Admin-added on this device; copied into the Course ZIP when used.',
  'COURSE': 'These bytes are stored in this Course.',
  'IN USE': 'This image is used by this Course.',
};

/// [inCourse]: a device image whose Course copy is listed as this same tile.
List<String> _badgesOf(
  ExerciseImageMetadata item, {
  bool used = false,
  bool inCourse = false,
}) => [
  ...switch (item.origin) {
    // Listed on its own only when the device original is gone.
    'course' || 'course-device' => const ['COURSE'],
    _ => [_isBundled(item) ? 'QQL' : 'DEVICE', if (inCourse) 'COURSE'],
  },
  if (used) 'IN USE',
];

/// The tile's tag line, or null when the image has no tags. `Local:` will
/// follow on the same line, only when present, once Local words exist
/// (docs/IMPORT_HARDENING_PLAN.md, Tranche 0b).
String? _tileTags(ExerciseImageMetadata item) =>
    item.tags.isEmpty ? null : 'Tags: ${item.tags.join(', ').toLowerCase()}';

String _sourceCode(List<String> badges) => badges.join(' · ');

String _sourceExplanation(ExerciseImageMetadata item) => switch (item.origin) {
  'course-device' => 'Originally Admin-added; these bytes are stored in this Course.',
  'course' => 'These bytes are stored in this Course.',
  _ => _isBundled(item)
      ? 'App bundled; supplied by QQL on every device.'
      : 'Admin-added on this device; copied into the Course ZIP when used.',
};

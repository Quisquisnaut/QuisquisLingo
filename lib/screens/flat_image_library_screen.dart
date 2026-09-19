import 'dart:io';

import 'package:flutter/material.dart';

import '../models/exercise_image_metadata.dart';
import '../services/exercise_image_metadata_service.dart';
import '../services/exercise_image_service.dart';
import '../services/image_bank_service.dart';
import '../services/profile_service.dart';
import '../widgets/file_dialog_feedback.dart';

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

class FlatImageLibraryScreen extends StatefulWidget {
  final bool selectMode;
  final bool readOnly;
  final bool metadataEditingEnabled;
  final String? actorProfileId;
  final ExerciseImageMetadataService? metadataService;
  final ExerciseImageService? imageService;
  final ImageBankService? bankService;
  final ProfileService? profileService;

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
  final _scroll = ScrollController();
  List<ExerciseImageMetadata> _all = const [];
  String _query = '';
  String? _category;
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
      final actor = widget.actorProfileId;
      final canManage =
          !widget.readOnly &&
          widget.metadataEditingEnabled &&
          actor != null &&
          await _profiles.isAdmin(actor);
      if (!mounted) return;
      setState(() {
        _all = [...records]
          ..sort(
            (left, right) =>
                left.label.toLowerCase().compareTo(right.label.toLowerCase()),
          );
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
              'Delete “${item.label}” from the Shared Image Library? Existing exercise references must be changed separately.',
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
            content: const Text(
              'Remove this Image Bank and all of its local files? Existing exercise references must be changed separately.',
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
                  await _metadata.updateMetadata(
                    actorProfileId: actor,
                    imageId: item.id,
                    category: category,
                    tags: tagsText.split(','),
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

  bool _isMissing(ExerciseImageMetadata item) =>
      !item.assetPath.startsWith('assets/') &&
      !File(item.assetPath).existsSync();

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
        errorBuilder: (_, _, _) => const Center(
          child: Text('Image file missing', textAlign: TextAlign.center),
        ),
      );
    }
    return Image.file(
      File(item.assetPath),
      fit: BoxFit.contain,
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
                Text('Category: ${item.category.replaceAll('_', ' ')}'),
                Tooltip(
                  message: 'Tags: ${item.tags.join(', ')}',
                  child: Text(
                    'Tags: ${item.tags.join(', ')}',
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
                          Navigator.pop(context, item.assetPath);
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
    final items = _all
        .where(
          (item) =>
              (_category == null || item.category == _category) &&
              _matchesImageSearch(item, normalizedQuery),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Image Library · ${_all.length} images'),
        actions: [
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
                        child: Text('Admin media management'),
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
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      const SizedBox(width: 6),
                      for (final category in categories) ...[
                        ChoiceChip(
                          label: Text(category.replaceAll('_', ' ')),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                        const SizedBox(width: 6),
                      ],
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
                                        child: Center(child: _imageFor(item)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.category.replaceAll('_', ' '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                      Tooltip(
                                        message:
                                            'Tags: ${item.tags.join(', ')}',
                                        child: Text(
                                          'Tags: ${item.tags.join(', ')}',
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      ),
                                      if (_canManageMetadata &&
                                          item.origin == 'local')
                                        IconButton(
                                          tooltip: 'Delete imported image',
                                          onPressed: () => _deleteLocal(item),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                        ),
                                      if (_canManageMetadata &&
                                          _bankId(item) != null)
                                        IconButton(
                                          tooltip: 'Remove this imported bank',
                                          onPressed: () => _removeBank(item),
                                          icon: const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 18,
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

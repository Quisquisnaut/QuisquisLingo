import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/exercise_image_service.dart';
import '../services/image_bank_service.dart';

class FlatImageAsset {
  final String id;
  final String label;
  final String category;
  final String assetPath;
  final List<String> tags;
  final bool custom;
  final String? bankId;
  final String? bankName;
  final bool missing;

  const FlatImageAsset({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.assetPath,
    this.custom = false,
    this.bankId,
    this.bankName,
    this.missing = false,
  });

  factory FlatImageAsset.fromJson(Map<String, dynamic> j) => FlatImageAsset(
    id: (j['id'] ?? '').toString(),
    label: (j['label'] ?? j['primary_term'] ?? '').toString(),
    category: (j['category'] ?? 'other').toString(),
    tags: ((j['tags'] ?? j['keywords']) as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    assetPath: (j['assetPath'] ?? j['asset_path'] ?? '').toString(),
    custom: j['custom'] == true,
    bankId: j['bankId']?.toString(),
    bankName: j['bankName']?.toString(),
    missing: j['missing'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'tags': tags,
    'assetPath': assetPath,
    'custom': custom,
    if (bankId != null) 'bankId': bankId,
  };
}

class FlatImageLibraryScreen extends StatefulWidget {
  final bool selectMode;
  const FlatImageLibraryScreen({super.key, this.selectMode = true});
  @override
  State<FlatImageLibraryScreen> createState() => _FlatImageLibraryScreenState();
}

class _FlatImageLibraryScreenState extends State<FlatImageLibraryScreen> {
  static const _customKey = 'quisquislingo_custom_image_bank_v1';
  final _imageService = ExerciseImageService();
  final _bankService = ImageBankService();
  final _scroll = ScrollController();
  List<FlatImageAsset> _all = const [];
  String _query = '';
  String? _category;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(
      'assets/exercise_images/manifest.json',
    );
    final decoded = jsonDecode(raw) as List;
    final built = decoded
        .whereType<Map>()
        .map((e) => FlatImageAsset.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final prefs = await SharedPreferences.getInstance();
    final custom = <FlatImageAsset>[];
    for (final line in prefs.getStringList(_customKey) ?? const []) {
      try {
        final j = jsonDecode(line) as Map<String, dynamic>;
        final path = (j['assetPath'] ?? '').toString();
        custom.add(
          FlatImageAsset(
            id: j['id'].toString(),
            label: j['label'].toString(),
            category: 'custom',
            tags: [j['label'].toString()],
            assetPath: path,
            custom: true,
            missing: path.isEmpty || !await File(path).exists(),
          ),
        );
      } catch (_) {}
    }
    final imported = (await _bankService.loadImportedEntries())
        .map(FlatImageAsset.fromJson)
        .toList();
    if (!mounted) return;
    setState(() {
      _all = [
        ...built,
        ...imported,
        ...custom,
      ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      _loading = false;
    });
  }

  Future<void> _saveCustom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customKey,
      _all.where((e) => e.custom).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _importSingle() async {
    String? path;
    try {
      path = await _imageService.importImage();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Duration(seconds: 8), content: Text('$e')),
        );
      return;
    }
    if (path == null || !mounted) return;
    final info = await _imageService.inspect(path);
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
    final item = FlatImageAsset(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      label: base.isEmpty ? 'Imported image' : base,
      category: 'custom',
      tags: [base],
      assetPath: path,
      custom: true,
    );
    setState(
      () => _all = [
        ..._all,
        item,
      ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase())),
    );
    await _saveCustom();
  }

  Future<void> _importBank() async {
    try {
      final result = await _bankService.pickAndImportBank(
        existingIds: _all.map((e) => e.id).toSet(),
      );
      if (result == null || !mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Imported ${result.imported} images from ${result.bankName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Image Bank import failed: $e'),
        ),
      );
    }
  }

  Future<void> _delete(FlatImageAsset item) async {
    if (!item.custom) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete image?'),
            content: Text(
              'Delete “${item.label}” from Image Bank? Exercises or lessons already using this file should be changed first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      final f = File(item.assetPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _all = _all.where((e) => e.id != item.id).toList());
    await _saveCustom();
  }

  Future<void> _removeBank(FlatImageAsset item) async {
    if (item.bankId == null) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove imported Image Bank?'),
            content: Text(
              'Remove “${item.bankName ?? 'this Image Bank'}” and all of its local image files? Any exercise or Lesson using them will show a missing-image warning until another image is assigned.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove bank'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await _bankService.removeBank(item.bankId!);
    await _load();
  }

  String _initial(String s) {
    final t = s.trim();
    return t.isEmpty ? '#' : t[0].toUpperCase();
  }

  Widget _imageFor(FlatImageAsset item) {
    if (item.missing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined),
            SizedBox(height: 4),
            Text(
              'Image file missing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }
    if (item.assetPath.startsWith('assets/')) {
      return Image.asset(
        item.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Text('Image file missing', textAlign: TextAlign.center),
        ),
      );
    }
    final file = File(item.assetPath);
    if (!file.existsSync())
      return const Center(
        child: Text('Image file missing', textAlign: TextAlign.center),
      );
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(
        child: Text('Image file unreadable', textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _preview(FlatImageAsset item) async {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width - 32).clamp(280.0, 620.0).toDouble();
    final dialogHeight = (size.height * 0.82).clamp(360.0, 760.0).toDouble();
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
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
                        style: Theme.of(ctx).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
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
                  'File: ${item.assetPath}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                Text(
                  'Category: ${item.category.replaceAll('_', ' ')}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                if (item.tags.isNotEmpty)
                  Text(
                    'Keywords: ${item.tags.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                if (item.bankName != null)
                  Text(
                    'Image Bank: ${item.bankName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                    if (widget.selectMode && !item.missing) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context, item.assetPath);
                        },
                        child: const Text('Use image'),
                      ),
                    ],
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
    final cats = _all.map((e) => e.category).toSet().toList()..sort();
    final q = _query.toLowerCase().trim();
    final items =
        _all
            .where(
              (e) =>
                  (_category == null || e.category == _category) &&
                  (q.isEmpty ||
                      e.label.toLowerCase().contains(q) ||
                      e.tags.any((t) => t.toLowerCase().contains(q))),
            )
            .toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );
    final letters =
        items
            .map((e) => _initial(e.label))
            .where((e) => RegExp(r'[A-Z]').hasMatch(e))
            .toSet()
            .toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Bank · ${_all.length} assets'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Import',
            onSelected: (v) {
              if (v == 'bank') _importBank();
              if (v == 'image') _importSingle();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'bank',
                child: Text('Import Image Bank ZIP'),
              ),
              PopupMenuItem(value: 'image', child: Text('Import single image')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Import files from Documents/QuisquisLingo/Imports/Images. For Import single image, keep exactly one PNG, JPG, JPEG or WEBP image in the folder. For Import Image Bank ZIP, keep exactly one ZIP in the folder. Imported source files are left in place.',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search images',
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      for (final l in letters)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ActionChip(
                            label: Text(l),
                            onPressed: () {
                              final i = items.indexWhere(
                                (e) => _initial(e.label) == l,
                              );
                              if (i >= 0 && _scroll.hasClients)
                                _scroll.animateTo(
                                  (i ~/ 3) * 145.0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                            },
                          ),
                        ),
                    ],
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
                      for (final c in cats) ...[
                        ChoiceChip(
                          label: Text(c.replaceAll('_', ' ')),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
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
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 104),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160,
                                childAspectRatio: .78,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            return InkWell(
                              onTap: () => _preview(item),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Center(child: _imageFor(item)),
                                        ),
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
                                      if (item.missing)
                                        const Text(
                                          'Missing asset',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.red,
                                          ),
                                        ),
                                      if (item.bankName != null)
                                        Text(
                                          item.bankName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      if (item.custom)
                                        IconButton(
                                          tooltip: 'Delete imported image',
                                          onPressed: () => _delete(item),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                        ),
                                      if (!item.custom && item.bankId != null)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importBank,
        icon: const Icon(Icons.archive_outlined),
        label: const Text('Import bank'),
      ),
    );
  }
}

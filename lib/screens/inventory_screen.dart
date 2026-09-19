import 'package:flutter/material.dart';

import '../services/inventory_service.dart';

/// Admin-only list of everything QQL has stored because of what people did,
/// inside the app or by adding files to QQL's folders from outside it.
///
/// All explanations and paths are plain, selectable text so they are readable
/// and copyable on any device.
class InventoryScreen extends StatefulWidget {
  final InventoryService? service;

  const InventoryScreen({super.key, this.service});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _service = widget.service ?? InventoryService();
  late Future<List<InventorySection>> _future = _service.load();

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            key: const Key('inventory-refresh'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _service.load()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: FutureBuilder<List<InventorySection>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'The inventory could not be read: ${snapshot.error}',
                    ),
                  );
                }
                final sections = snapshot.data!;
                return ListView(
                  key: const Key('inventory-list'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _Summary(sections: sections),
                    for (final section in sections)
                      _SectionCard(section: section),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<InventorySection> sections;

  const _Summary({required this.sections});

  @override
  Widget build(BuildContext context) {
    final files = sections
        .where((s) => s.location != null)
        .fold<int>(0, (sum, s) => sum + s.count);
    final bytes = sections.fold<int>(0, (sum, s) => sum + s.totalBytes);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Everything QQL has stored on this device because of what people did: created inside the app, or added to QQL’s folders from outside it, for example by copying files with the operating system. Paths can be selected and copied. Media and files that come with the app itself are not listed.',
          ),
          const SizedBox(height: 8),
          Text(
            'Files found: $files, using ${_InventoryScreenState.formatBytes(bytes)}. Learners and courses are stored inside QQL’s own settings, not as files, and are listed separately.',
            key: const Key('inventory-summary'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final InventorySection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final isFolder = section.location != null;
    final count = section.count;
    final size = isFolder
        ? ' · ${_InventoryScreenState.formatBytes(section.totalBytes)}'
        : '';
    return Card(
      key: Key('inventory-section-${section.title}'),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${section.title} ($count)$size',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(section.description),
            if (section.location != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                'Location: ${section.location}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            if (count == 0)
              const Text('Nothing found.')
            else
              for (final item in section.items) _ItemRow(item: item),
            if (section.hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'and ${section.hiddenCount} more not shown here (showing the ${InventoryService.maxListedPerSection} most recent).',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InventoryItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (item.sizeBytes != null)
        _InventoryScreenState.formatBytes(item.sizeBytes!),
      if (item.modified != null)
        'modified ${_InventoryScreenState.formatDate(item.modified!)}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (item.path != null)
            SelectableText(
              item.path!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (details.isNotEmpty) Text(details.join(' · ')),
          if (item.owner != null) Text('Belongs to: ${item.owner}'),
          if (item.note != null) Text(item.note!),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/inventory_action_service.dart';
import '../services/inventory_service.dart';
import '../services/profile_service.dart';
import '../widgets/folder_opener.dart';

/// Admin-only list of everything QQL has stored because of what people did,
/// inside the app or by adding files to QQL's folders from outside it.
///
/// All explanations and paths are plain, selectable text so they are readable
/// and copyable on any device.
///
/// Since Build 266 Revision 2 (owner decisions of 8 October 2026) each item
/// has Delete or Forget where it applies, after the admin's PIN and under
/// the rules the rest of QQL applies, and Open folder where it has one
/// (Windows, macOS and Linux).
class InventoryScreen extends StatefulWidget {
  final InventoryService? service;
  final InventoryActionService? actionService;
  final ProfileService? profileService;

  const InventoryScreen({
    super.key,
    this.service,
    this.actionService,
    this.profileService,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _service = widget.service ?? InventoryService();
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final InventoryActionService _actions =
      widget.actionService ?? InventoryActionService(profiles: _profiles);
  late Future<List<InventorySection>> _future = _service.load();

  Future<void> _openFolder(InventoryItem item) async {
    final folder = item.folder;
    if (folder == null) return;
    var opened = false;
    try {
      opened = await FolderOpener.open(folder);
    } catch (_) {}
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('The folder could not be opened: $folder'),
      ),
    );
  }

  /// Delete or Forget: what it removes, then the admin's PIN. The service
  /// applies the same rules as the rest of QQL and says why it refuses.
  Future<void> _runAction(InventoryItem item) async {
    final action = item.action;
    if (action == null) return;
    final actor = await _profiles.getActiveProfileId();
    if (actor == null || !mounted) return;
    final pin = TextEditingController();
    String? error;
    var running = false;
    final done =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setLocal) => AlertDialog(
              key: const Key('inventory-action-dialog'),
              title: Text('${action.label} “${item.name}”?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.explanation),
                    const SizedBox(height: 8),
                    const Text('This cannot be undone. Enter your admin PIN.'),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('inventory-action-pin'),
                      controller: pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Admin PIN',
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        key: const Key('inventory-action-error'),
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: running
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('inventory-action-run'),
                  onPressed: running
                      ? null
                      : () async {
                          setLocal(() {
                            running = true;
                            error = null;
                          });
                          try {
                            await _actions.run(
                              action,
                              actorProfileId: actor,
                              pin: pin.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setLocal(() {
                              running = false;
                              error = '$e';
                            });
                          }
                        },
                  child: Text(action.label),
                ),
              ],
            ),
          ),
        ).whenComplete(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          pin.dispose();
        });
    if (done != true || !mounted) return;
    setState(() {
      _future = _service.load();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${action.label}: “${item.name}” done.')),
    );
  }

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
            onPressed: () => setState(() {
              _future = _service.load();
            }),
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
                      _SectionCard(
                        section: section,
                        onAction: _runAction,
                        onOpenFolder: FolderOpener.available()
                            ? _openFolder
                            : null,
                      ),
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
  final ValueChanged<InventoryItem> onAction;
  final ValueChanged<InventoryItem>? onOpenFolder;

  const _SectionCard({
    required this.section,
    required this.onAction,
    required this.onOpenFolder,
  });

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
              for (final (index, item) in section.items.indexed)
                _ItemRow(
                  item: item,
                  keyPrefix: 'inventory-${section.title}-$index',
                  onAction: onAction,
                  onOpenFolder: onOpenFolder,
                ),
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
  final String keyPrefix;
  final ValueChanged<InventoryItem> onAction;
  final ValueChanged<InventoryItem>? onOpenFolder;

  const _ItemRow({
    required this.item,
    required this.keyPrefix,
    required this.onAction,
    required this.onOpenFolder,
  });

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
          if (item.action != null ||
              (item.folder != null && onOpenFolder != null))
            Wrap(
              spacing: 4,
              children: [
                if (item.action case final action?)
                  TextButton.icon(
                    key: Key('$keyPrefix-action'),
                    onPressed: () => onAction(item),
                    icon: Icon(
                      action.kind == InventoryActionKind.forget
                          ? Icons.backspace_outlined
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    label: Text('${action.label}…'),
                  ),
                if (item.folder != null && onOpenFolder != null)
                  TextButton.icon(
                    key: Key('$keyPrefix-open-folder'),
                    onPressed: () => onOpenFolder!(item),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Open folder'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

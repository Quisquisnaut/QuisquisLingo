import 'package:flutter/material.dart';

import '../screens/editor_help_screen.dart';
import '../services/editor_display_preferences.dart';

/// The shared Help and internal-ID controls used by every Editor hierarchy page.
class EditorAppBarActions extends StatefulWidget {
  const EditorAppBarActions({super.key});

  @override
  State<EditorAppBarActions> createState() => _EditorAppBarActionsState();
}

class _EditorAppBarActionsState extends State<EditorAppBarActions> {
  @override
  void initState() {
    super.initState();
    EditorDisplayPreferences.load();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: const Key('editor-help-action'),
        tooltip: 'Editor Help',
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const EditorHelpScreen()),
        ),
        icon: const Icon(Icons.help_outline),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: EditorDisplayPreferences.showInternalIds,
        builder: (context, visible, _) => IconButton(
          key: const Key('editor-internal-ids-toggle'),
          tooltip: visible
              ? 'Internal IDs shown. Tap to hide'
              : 'Internal IDs hidden. Tap to show',
          isSelected: visible,
          color: visible ? Theme.of(context).colorScheme.primary : null,
          onPressed: EditorDisplayPreferences.toggleInternalIds,
          icon: Icon(visible ? Icons.badge : Icons.badge_outlined),
        ),
      ),
    ],
  );
}

/// A secondary, selectable ID line driven by the global Editor preference.
class EditorInternalIdText extends StatefulWidget {
  const EditorInternalIdText({
    super.key,
    required this.label,
    required this.id,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final String id;
  final EdgeInsetsGeometry padding;

  @override
  State<EditorInternalIdText> createState() => _EditorInternalIdTextState();
}

class _EditorInternalIdTextState extends State<EditorInternalIdText> {
  @override
  void initState() {
    super.initState();
    EditorDisplayPreferences.load();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: EditorDisplayPreferences.showInternalIds,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      final text = '${widget.label} ID: ${widget.id}';
      return Padding(
        padding: widget.padding,
        child: Tooltip(
          message: widget.id,
          child: SelectableText(
            text,
            key: ValueKey('editor-internal-id-${widget.id}'),
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    },
  );
}

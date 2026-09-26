import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/course_flag_selection.dart';
import '../models/world_flag_entity.dart';
import '../services/course_flag_catalog_service.dart';
import '../services/course_flag_service.dart';
import '../services/world_flag_repository.dart';
import 'flag_art.dart';
import 'world_flag_art.dart';
import 'quick_import_access.dart';

Future<CourseFlagSelection?> showCourseFlagPicker({
  required BuildContext context,
  required CourseFlagSelection currentSelection,
  required String languageName,
  String? languageTag,
  CourseFlagCatalogService? catalogService,
  CourseFlagService? flagService,
  WorldFlagRepository? worldFlagRepository,
  Future<CourseFlagCatalog>? catalogFuture,
}) => showDialog<CourseFlagSelection>(
  context: context,
  builder: (_) => CourseFlagPickerDialog(
    currentSelection: currentSelection,
    languageName: languageName,
    languageTag: languageTag,
    catalogService: catalogService,
    flagService: flagService,
    worldFlagRepository: worldFlagRepository,
    catalogFuture: catalogFuture,
  ),
);

class CourseFlagSelector extends StatefulWidget {
  final CourseFlagSelection selection;
  final String languageName;
  final String? languageTag;
  final ValueChanged<CourseFlagSelection> onChanged;
  final CourseFlagCatalogService? catalogService;
  final CourseFlagService? flagService;
  final WorldFlagRepository? worldFlagRepository;

  const CourseFlagSelector({
    super.key,
    required this.selection,
    required this.languageName,
    required this.onChanged,
    this.languageTag,
    this.catalogService,
    this.flagService,
    this.worldFlagRepository,
  });

  @override
  State<CourseFlagSelector> createState() => _CourseFlagSelectorState();
}

class _CourseFlagSelectorState extends State<CourseFlagSelector> {
  late WorldFlagRepository _repository;
  late CourseFlagCatalogService _service;
  late Future<CourseFlagCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _refreshCatalog();
  }

  @override
  void didUpdateWidget(CourseFlagSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageName != widget.languageName ||
        oldWidget.languageTag != widget.languageTag ||
        oldWidget.catalogService != widget.catalogService ||
        oldWidget.worldFlagRepository != widget.worldFlagRepository) {
      _refreshCatalog();
    }
  }

  void _refreshCatalog() {
    _repository = widget.worldFlagRepository ?? WorldFlagRepository();
    _service =
        widget.catalogService ??
        CourseFlagCatalogService(worldFlagRepository: _repository);
    _catalog = _service.build(
      languageName: widget.languageName,
      languageTag: widget.languageTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<CourseFlagCatalog>(
          future: _catalog,
          builder: (context, snapshot) {
            final details = _selectionDetails(
              widget.selection,
              snapshot.data,
              widget.languageName,
            );
            return Row(
              children: [
                CourseFlagSelectionPreview(
                  selection: widget.selection,
                  automaticCandidate: snapshot.data?.automaticCandidate,
                  worldFlagRepository: _repository,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flag preview',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(details.$1),
                      if (details.$2.isNotEmpty) Text(details.$2),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('course-flag-selector-open'),
          onPressed: () async {
            final selected = await showCourseFlagPicker(
              context: context,
              currentSelection: widget.selection,
              languageName: widget.languageName,
              languageTag: widget.languageTag,
              catalogService: _service,
              flagService: widget.flagService,
              worldFlagRepository: _repository,
              catalogFuture: _catalog,
            );
            if (selected != null && context.mounted) {
              widget.onChanged(selected);
            }
          },
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Choose Course flag'),
        ),
      ],
    );
  }
}

class CourseFlagPickerDialog extends StatefulWidget {
  final CourseFlagSelection currentSelection;
  final String languageName;
  final String? languageTag;
  final CourseFlagCatalogService? catalogService;
  final CourseFlagService? flagService;
  final WorldFlagRepository? worldFlagRepository;
  final Future<CourseFlagCatalog>? catalogFuture;

  const CourseFlagPickerDialog({
    super.key,
    required this.currentSelection,
    required this.languageName,
    this.languageTag,
    this.catalogService,
    this.flagService,
    this.worldFlagRepository,
    this.catalogFuture,
  });

  @override
  State<CourseFlagPickerDialog> createState() => _CourseFlagPickerDialogState();
}

class _CourseFlagPickerDialogState extends State<CourseFlagPickerDialog> {
  final TextEditingController _search = TextEditingController();
  late final CourseFlagService _flags;
  late final WorldFlagRepository _worldFlags;
  late final Future<CourseFlagCatalog> _catalog;
  String _query = '';
  String? _importError;

  @override
  void initState() {
    super.initState();
    final searchLanguageName = _searchLanguageName(widget.languageName);
    _search.text = searchLanguageName;
    _query = searchLanguageName;
    _flags = widget.flagService ?? CourseFlagService();
    _worldFlags = widget.worldFlagRepository ?? WorldFlagRepository();
    _catalog =
        widget.catalogFuture ??
        (widget.catalogService ??
                CourseFlagCatalogService(worldFlagRepository: _worldFlags))
            .build(
              languageName: widget.languageName,
              languageTag: widget.languageTag,
            );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _importCustomFlag() async {
    setState(() => _importError = null);
    // The custom flag has no Open from… route.
    if (await ensureQuickImportAccess(context, offerOpenFrom: false) !=
            QuickImportAccess.ready ||
        !mounted) {
      return;
    }
    try {
      final imported = await _flags.importPreparedFlag();
      if (!mounted) return;
      Navigator.pop(
        context,
        CourseFlagSelection.customImage(imported.base64Png),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _importError = error.toString().replaceFirst(
          'FormatException: ',
          '',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: (viewport.height - 24).clamp(240, 720).toDouble(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Text(
                'Choose Course flag',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: FutureBuilder<CourseFlagCatalog>(
                future: _catalog,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Course flags could not be loaded.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildScrollableCatalog(snapshot.data!);
                },
              ),
            ),
            Container(
              key: const Key('course-flag-picker-actions'),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('course-flag-picker-cancel'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableCatalog(CourseFlagCatalog catalog) {
    final sections = catalog.search(_query);
    final hasFlagPainterResults = sections.any(
      (section) => section.kind == CourseFlagCatalogSectionKind.qqlFlagPainter,
    );
    final children = <Widget>[
      _CurrentSelection(
        currentSelection: widget.currentSelection,
        catalog: catalog,
        languageName: widget.languageName,
        worldFlagRepository: _worldFlags,
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const Key('course-flag-picker-automatic'),
          onPressed: () =>
              Navigator.pop(context, const CourseFlagSelection.automatic()),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Use Automatic'),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const Key('course-flag-picker-upload-custom'),
          onPressed: _importCustomFlag,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload custom flag'),
        ),
      ),
      if (_importError != null) ...[
        const SizedBox(height: 6),
        Text(
          _importError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: 10),
      TextField(
        key: const Key('course-flag-picker-search'),
        controller: _search,
        autofocus: true,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search names, aliases, stable IDs or codes',
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  key: const Key('course-flag-picker-clear-search'),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
        ),
      ),
      const SizedBox(height: 8),
      if (catalog.suggestedWorldFlag != null) ...[
        Text(
          'Suggested WORLD Flag for ${_displayLanguage(widget.languageName, widget.languageTag)}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        _CandidateTile(
          candidate: catalog.suggestedWorldFlag!,
          selected:
              catalog.suggestedWorldFlag!.selection == widget.currentSelection,
          optionKey: ValueKey(
            'course-flag-suggestion-${catalog.suggestedWorldFlag!.identity}',
          ),
          onTap: () =>
              Navigator.pop(context, catalog.suggestedWorldFlag!.selection),
        ),
      ] else if (catalog.worldSuggestionUnavailableMessage.isNotEmpty) ...[
        Text(catalog.worldSuggestionUnavailableMessage),
      ],
      if (sections.isEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No FlagPainter flag found')),
        ),
      ] else ...[
        if (!hasFlagPainterResults)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text('No FlagPainter flag found')),
          ),
        for (final section in sections) ...[
          _SectionHeader(section: section),
          if (section.kind == CourseFlagCatalogSectionKind.qqlFlagPainter)
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                'Flags drawn programmatically by QQL’s FlagPainter. They are graphical reinterpretations associated with languages, not official reproductions.',
              ),
            ),
          for (final candidate in section.candidates)
            _CandidateTile(
              candidate: candidate,
              selected: candidate.selection == widget.currentSelection,
              onTap: () => Navigator.pop(context, candidate.selection),
            ),
        ],
      ],
      const SizedBox(height: 8),
    ];

    return CustomScrollView(
      key: const Key('course-flag-picker-results'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}

class _CurrentSelection extends StatelessWidget {
  final CourseFlagSelection currentSelection;
  final CourseFlagCatalog catalog;
  final String languageName;
  final WorldFlagRepository worldFlagRepository;

  const _CurrentSelection({
    required this.currentSelection,
    required this.catalog,
    required this.languageName,
    required this.worldFlagRepository,
  });

  @override
  Widget build(BuildContext context) {
    final details = _selectionDetails(currentSelection, catalog, languageName);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseFlagSelectionPreview(
          selection: currentSelection,
          automaticCandidate: catalog.automaticCandidate,
          worldFlagRepository: worldFlagRepository,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current selection',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              if (currentSelection.kind == CourseFlagSelectionKind.automatic)
                const Text('Automatic for the learning language'),
              Text(details.$1),
              if (details.$2.isNotEmpty) Text(details.$2),
            ],
          ),
        ),
      ],
    );
  }
}

class CourseFlagSelectionPreview extends StatelessWidget {
  final CourseFlagSelection selection;
  final CourseFlagCandidate? automaticCandidate;
  final WorldFlagRepository? worldFlagRepository;
  final double width;
  final double height;

  const CourseFlagSelectionPreview({
    super.key,
    required this.selection,
    this.automaticCandidate,
    this.worldFlagRepository,
    this.width = 64,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final effective = selection.kind == CourseFlagSelectionKind.automatic
        ? automaticCandidate?.selection
        : selection;
    return Container(
      key: const Key('course-flag-selection-preview'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: effective == null
          ? const Icon(Icons.outlined_flag)
          : switch (effective.kind) {
              CourseFlagSelectionKind.automatic => const Icon(
                Icons.outlined_flag,
              ),
              CourseFlagSelectionKind.builtIn => FlagBadge(
                effective.builtInCode,
                width: width,
                height: height,
              ),
              CourseFlagSelectionKind.worldFlag =>
                FutureBuilder<WorldFlagEntity?>(
                  future: (worldFlagRepository ?? WorldFlagRepository())
                      .findById(effective.worldFlagId),
                  builder: (context, snapshot) => snapshot.data == null
                      ? const Icon(Icons.outlined_flag)
                      : WorldFlagArt(entity: snapshot.data!),
                ),
              CourseFlagSelectionKind.customImage => _customImage(effective),
            },
    );
  }

  static Widget _customImage(CourseFlagSelection selection) {
    try {
      return Image.memory(
        base64Decode(selection.customImageBase64),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      );
    } catch (_) {
      return const Icon(Icons.broken_image_outlined);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final CourseFlagCatalogSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey('course-flag-section-${section.kind.name}'),
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 5),
    child: Text(
      section.title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _CandidateTile extends StatelessWidget {
  final CourseFlagCandidate candidate;
  final bool selected;
  final VoidCallback onTap;
  final Key? optionKey;

  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
    this.optionKey,
  });

  @override
  Widget build(BuildContext context) => Card(
    key: optionKey ?? ValueKey('course-flag-option-${candidate.identity}'),
    color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 58,
        height: 38,
        child: candidate.worldFlag == null
            ? FlagBadge(candidate.selection.builtInCode, width: 58, height: 38)
            : WorldFlagArt(entity: candidate.worldFlag!),
      ),
      title: Text(candidate.label),
      subtitle: Text(candidate.subtitle),
      trailing: selected ? const Icon(Icons.check) : null,
    ),
  );
}

(String, String) _selectionDetails(
  CourseFlagSelection selection,
  CourseFlagCatalog? catalog,
  String languageName,
) {
  if (selection.kind == CourseFlagSelectionKind.automatic) {
    final automatic = catalog?.automaticCandidate;
    if (automatic == null) {
      return (
        catalog?.automaticUnavailableMessage ??
            'Automatic for the learning language',
        '',
      );
    }
    if (automatic.selection.kind == CourseFlagSelectionKind.builtIn) {
      return ('${automatic.label} · QQL FlagPainter Flag', 'Generated by QQL');
    }
    return (
      '${automatic.label} · ${automatic.subtitle}',
      'No QQL FlagPainter Flag is available for ${_displayLanguage(languageName, null)}.',
    );
  }

  if (selection.kind == CourseFlagSelectionKind.customImage) {
    return ('Custom Flag', 'Uploaded custom image');
  }

  for (final candidate
      in catalog?.candidates ?? const <CourseFlagCandidate>[]) {
    if (candidate.selection == selection) {
      if (selection.kind == CourseFlagSelectionKind.builtIn) {
        return (
          '${candidate.label} · QQL FlagPainter Flag',
          'Generated by QQL',
        );
      }
      return ('${candidate.label} · ${candidate.subtitle}', '');
    }
  }
  if (selection.kind == CourseFlagSelectionKind.builtIn) {
    return ('${selection.builtInCode} · Explicit flag code', '');
  }
  return ('${selection.worldFlagId} · WORLD Flag', '');
}

String _displayLanguage(String languageName, String? languageTag) {
  final name = languageName.trim();
  if (name.isNotEmpty) return name;
  final tag = languageTag?.trim() ?? '';
  return tag.isEmpty ? 'this language' : tag;
}

String _searchLanguageName(String languageName) {
  final name = languageName.trim();
  return name.replaceFirst(
    RegExp(r'\s+\(([a-z]{2,3}(?:[-_][a-z0-9]{2,8})*)\)$', caseSensitive: false),
    '',
  );
}

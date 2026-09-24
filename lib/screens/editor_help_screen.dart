import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../localization/locale_service.dart';
import '../models/exercise_authoring.dart';
import '../services/exercise_field_help.dart';
import '../widgets/app_locale_selector.dart';
import 'audit_codes_screen.dart';
import 'publisher_signing_help_screen.dart';

String _t(AppLocale locale, String key) => helpText.lookup(locale, key);

_HelpSection _localizedSection(AppLocale locale, String key) => _HelpSection(
  title: _t(locale, '$key.title'),
  body: _t(locale, '$key.body'),
);

class EditorHelpScreen extends StatelessWidget {
  const EditorHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(_t(locale, 'editorHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('editor-help-language-toggle'),
            locale: locale,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TechnicalLinks(locale: locale),
          const SizedBox(height: 12),
          for (final id in editorHelpSectionIds)
            _localizedSection(locale, 'editorHelp.$id'),
        ],
      ),
    ),
  );
}

/// Help for the Course Studio tab, using the same language choice as Editor
/// Help while keeping the Editor's technical reference on the Editor page.
class CourseManagerHelpScreen extends StatelessWidget {
  const CourseManagerHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(_t(locale, 'courseStudioHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('course-manager-help-language-toggle'),
            locale: locale,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CourseTypesHelpSection(locale: locale),
          for (final id in courseStudioHelpSectionIds)
            _localizedSection(locale, 'editorHelp.$id'),
          _localizedSection(locale, 'courseStudioHelp.findingCourses'),
          _localizedSection(locale, 'courseStudioHelp.courseOperations'),
        ],
      ),
    ),
  );
}

class _CourseTypesHelpSection extends StatelessWidget {
  const _CourseTypesHelpSection({required this.locale});

  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    const key = 'courseStudioHelp.courseTypes';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(locale, '$key.title'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_t(locale, '$key.intro')),
            for (var type = 1; type <= 3; type++) ...[
              const SizedBox(height: 8),
              Text(_t(locale, '$key.type$type')),
            ],
            const SizedBox(height: 12),
            Table(
              key: const Key('course-manager-help-course-types-table'),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: [
                for (var row = 1; row <= 11; row++)
                  TableRow(
                    children: [
                      for (var col = 1; col <= 4; col++)
                        _CourseTypeTableCell(
                          _t(locale, '$key.row$row.col$col'),
                          bold: row == 1,
                        ),
                    ],
                  ),
              ],
            ),
            for (var note = 1; note <= 4; note++) ...[
              const SizedBox(height: 8),
              Text(_t(locale, '$key.note$note')),
            ],
            const SizedBox(height: 12),
            Text(
              _t(locale, '$key.contact'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTypeTableCell extends StatelessWidget {
  const _CourseTypeTableCell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}

class _TechnicalLinks extends StatelessWidget {
  const _TechnicalLinks({required this.locale});

  final AppLocale locale;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t(locale, 'editorHelp.technicalReference.title'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(_t(locale, 'editorHelp.technicalReference.body')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Exercise types'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseHelpScreen()),
            ),
          ),
          ListTile(
            key: const Key('editor-help-audit-codes'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Audit Codes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AuditCodesScreen())),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('QuisquisLingo Course Model v11'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CourseModelV4HelpScreen(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Exercise primitives'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExercisePrimitivesHelpScreen(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('JSON data structure'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JsonV4HelpScreen())),
          ),
          ListTile(
            key: const Key('editor-help-publisher-signing'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Publisher signing and approval'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PublisherSigningHelpScreen(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ExerciseHelpScreen extends StatefulWidget {
  /// [initialQuery] pre-fills the search box so the Help opens directly on the
  /// matching chapter (for example the name of the exercise being edited).
  const ExerciseHelpScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ExerciseHelpScreen> createState() => _ExerciseHelpScreenState();
}

class _ExerciseHelpScreenState extends State<ExerciseHelpScreen> {
  late final _search = TextEditingController(text: widget.initialQuery);
  final _scroll = ScrollController();
  final _searchFocus = FocusNode();
  final _resultsFocus = FocusNode();
  late String _query = widget.initialQuery.trim().toLowerCase();
  double _unfilteredOffset = 0;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _searchFocus.dispose();
    _resultsFocus.dispose();
    super.dispose();
  }

  void _filter(String value) {
    final query = value.trim().toLowerCase();
    if (_query.isEmpty && query.isNotEmpty && _scroll.hasClients) {
      _unfilteredOffset = _scroll.offset;
    }
    setState(() => _query = query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(
        (_query.isEmpty ? _unfilteredOffset : 0)
            .clamp(0.0, _scroll.position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  void _clear() {
    _search.clear();
    _filter('');
    _searchFocus.requestFocus();
  }

  KeyEventResult _scrollWithKeyboard(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_scroll.hasClients) return KeyEventResult.ignored;
    final position = _scroll.position;
    final destination = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => _scroll.offset + 60,
      LogicalKeyboardKey.arrowUp => _scroll.offset - 60,
      LogicalKeyboardKey.pageDown =>
        _scroll.offset + position.viewportDimension * .8,
      LogicalKeyboardKey.pageUp =>
        _scroll.offset - position.viewportDimension * .8,
      LogicalKeyboardKey.home => 0.0,
      LogicalKeyboardKey.end => position.maxScrollExtent,
      _ => null,
    };
    if (destination == null) return KeyEventResult.ignored;
    _scroll.jumpTo(destination.clamp(0.0, position.maxScrollExtent).toDouble());
    return KeyEventResult.handled;
  }

  List<Widget> _searchResults(AppLocale locale) {
    bool matches(String text) => text.toLowerCase().contains(_query);
    final results = <Widget>[];
    for (final preset in ExercisePresetRegistry.presets) {
      final description = _t(
        locale,
        'exerciseHelp.preset.${preset.id}.description',
      );
      final body = _t(locale, 'exerciseHelp.preset.${preset.id}.body');
      if (matches('${preset.name}\n$description\n$body')) {
        results.add(
          _HelpSection(
            key: ValueKey('exercise-help-result-${preset.id}'),
            title: preset.name,
            body: '$description\n\n$body',
          ),
        );
      }
      for (final field in ExerciseFieldHelpRegistry.editorFieldKeys(
        preset.id,
      )) {
        final help = ExerciseFieldHelpRegistry.forEditorField(preset.id, field);
        final key =
            exerciseHelpFieldKeyByPresetAndField['${preset.id}.$field']!;
        final body = _t(locale, key);
        if (matches('${help.title}\n$body')) {
          results.add(
            _HelpSection(
              key: ValueKey('exercise-help-result-${preset.id}-$field'),
              title: '${preset.name}: ${help.title}',
              body: body,
            ),
          );
        }
      }
    }
    for (final supplement in _supplements(locale)) {
      if (matches('${supplement.title}\n${supplement.body}')) {
        results.add(supplement);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) {
      final sections = _query.isEmpty
          ? _allSections(context, locale)
          : _searchResults(locale);
      return Scaffold(
        appBar: AppBar(
          title: Text(_t(locale, 'exerciseHelp.title')),
          actions: [
            AppLocaleSelector(
              key: const Key('exercise-help-language-toggle'),
              locale: locale,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                key: const ValueKey('exercise-help-search'),
                controller: _search,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: _t(locale, 'exerciseHelp.search'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('exercise-help-search-clear'),
                          tooltip: _t(locale, 'exerciseHelp.clearSearch'),
                          onPressed: _clear,
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: _filter,
                onSubmitted: (_) => _resultsFocus.requestFocus(),
              ),
            ),
            Expanded(
              child: Focus(
                focusNode: _resultsFocus,
                onKeyEvent: _scrollWithKeyboard,
                child: sections.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_t(locale, 'exerciseHelp.noResults')),
                        ),
                      )
                    : ListView(
                        key: const Key('exercise-help-list'),
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        children: sections,
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );

  List<Widget> _allSections(BuildContext context, AppLocale locale) => [
    for (final category in ExerciseCategory.values)
      if (ExercisePresetRegistry.inCategory(category).isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            _t(locale, 'exerciseHelp.category.${category.name}'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        for (final preset in ExercisePresetRegistry.inCategory(category))
          _HelpSection(
            title: preset.name,
            body: _t(locale, 'exerciseHelp.preset.${preset.id}.body'),
          ),
      ],
    ..._supplements(locale),
  ];

  List<_HelpSection> _supplements(AppLocale locale) => [
    for (final id in exerciseHelpSupplementIds)
      _localizedSection(locale, 'exerciseHelp.supplement.$id'),
  ];
}

class CourseModelV4HelpScreen extends StatelessWidget {
  const CourseModelV4HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const _TechnicalPage(
    prefix: 'technical.courseModel',
    sectionIds: courseModelHelpSectionIds,
  );
}

class ExercisePrimitivesHelpScreen extends StatelessWidget {
  const ExercisePrimitivesHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const _TechnicalPage(
    prefix: 'technical.exercisePrimitives',
    sectionIds: exercisePrimitivesHelpSectionIds,
  );
}

class JsonV4HelpScreen extends StatelessWidget {
  const JsonV4HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const _TechnicalPage(
    prefix: 'technical.jsonStructure',
    sectionIds: jsonStructureHelpSectionIds,
  );
}

class _TechnicalPage extends StatelessWidget {
  const _TechnicalPage({required this.prefix, required this.sectionIds});

  final String prefix;
  final List<String> sectionIds;

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(_t(locale, '$prefix.title')),
        actions: [AppLocaleSelector(locale: locale)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final id in sectionIds) _localizedSection(locale, '$prefix.$id'),
        ],
      ),
    ),
  );
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String body;
  const _HelpSection({super.key, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    ),
  );
}

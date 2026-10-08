import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../localization/locale_service.dart';
import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../services/exercise_field_help.dart';
import '../services/exercise_search_service.dart';
import 'editor_help_content.dart';
import '../widgets/app_locale_selector.dart';
import 'audit_codes_screen.dart';
import 'publisher_signing_help_screen.dart';

String _t(AppLocale locale, String key) => helpText.lookup(locale, key);

_HelpSection _localizedSection(AppLocale locale, String key) => _HelpSection(
  title: _t(locale, '$key.title'),
  body: _t(locale, '$key.body'),
);

/// Editor Help as questions and answers (Build 256 Revision 8; owner
/// decisions of 29 September 2026): the Technical reference card, a search
/// that filters the questions and their answers (capitals and accents
/// ignored), then the topics, whose questions open their answers.
class EditorHelpScreen extends StatefulWidget {
  const EditorHelpScreen({super.key, this.question});

  /// The question to open at, expanded (Build 266); null opens at the top.
  final String? question;

  @override
  State<EditorHelpScreen> createState() => _EditorHelpScreenState();
}

class _EditorHelpScreenState extends State<EditorHelpScreen> {
  final _search = TextEditingController();
  final _questionKey = GlobalKey();
  List<String> _words = const [];

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _questionKey.currentContext;
        if (target != null && mounted) {
          Scrollable.ensureVisible(target, duration: Duration.zero);
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String value) => setState(
    () => _words = ExerciseSearchService.normalize(value)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false),
  );

  bool _matches(EditorHelpQuestion question) {
    if (_words.isEmpty) return true;
    final text = ExerciseSearchService.normalize(
      '${question.question}\n${question.answer}',
    );
    return _words.every(text.contains);
  }

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) {
      final topics = [
        for (final topic in editorHelpTopics(locale))
          (topic: topic, questions: topic.questions.where(_matches).toList()),
      ].where((entry) => entry.questions.isNotEmpty).toList();
      return Scaffold(
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
          // Opened at a question, every question is built so it can be
          // scrolled to.
          scrollCacheExtent: widget.question == null
              ? null
              : const ScrollCacheExtent.pixels(100000),
          padding: const EdgeInsets.all(16),
          children: [
            _TechnicalLinks(locale: locale),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('editor-help-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: _t(locale, 'editorHelp.qa.searchLabel'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('editor-help-search-clear'),
                        tooltip: _t(locale, 'exerciseHelp.clearSearch'),
                        onPressed: () {
                          _search.clear();
                          _filter('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: _filter,
            ),
            if (topics.isEmpty)
              Padding(
                key: const Key('editor-help-no-results'),
                padding: const EdgeInsets.all(16),
                child: Text(_t(locale, 'editorHelp.qa.noResults')),
              ),
            for (final entry in topics) ...[
              Padding(
                key: ValueKey('editor-help-topic-${entry.topic.id}'),
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                child: Text(
                  entry.topic.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final question in entry.questions)
                      ExpansionTile(
                        key: ValueKey('editor-help-question-${question.id}'),
                        initiallyExpanded: question.id == widget.question,
                        title: Text(
                          question.question,
                          key: question.id == widget.question
                              ? _questionKey
                              : null,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Text(
                            question.answer,
                            key: ValueKey('editor-help-answer-${question.id}'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
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
    Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        _t(locale, 'exerciseHelp.category.comingLater'),
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
    for (final preset in ExercisePresetRegistry.comingLater)
      _HelpSection(
        key: ValueKey('exercise-help-later-${preset.id}'),
        title: preset.name,
        body:
            '${preset.description}\n\n${_t(locale, 'exerciseHelp.comingLater')} ${preset.reason}',
      ),
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

/// The Exercise primitives reference. Since Build 261 Revision 6 each
/// primitive has its own section with a screenshot of the exercise Fill
/// with an example makes (`assets/primitives_screenshots/<primitive>.png`,
/// provided by the owner; a missing file leaves the text alone), and
/// [focus] opens the page at that primitive's section: the canonical
/// editor's Help button.
class ExercisePrimitivesHelpScreen extends StatefulWidget {
  const ExercisePrimitivesHelpScreen({super.key, this.focus});

  final ExercisePrimitive? focus;

  static String screenshotOf(ExercisePrimitive primitive) =>
      'assets/primitives_screenshots/${primitive.serialized}.png';

  /// Test seam: the bundle the screenshots come from.
  static AssetBundle? bundle;

  /// The width and height a PNG file states in its header, or null when
  /// [data] is not a PNG.
  static Size? pngSize(ByteData data) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (data.lengthInBytes < 24) return null;
    for (var i = 0; i < signature.length; i++) {
      if (data.getUint8(i) != signature[i]) return null;
    }
    final width = data.getUint32(16);
    final height = data.getUint32(20);
    if (width == 0 || height == 0) return null;
    return Size(width.toDouble(), height.toDouble());
  }

  @override
  State<ExercisePrimitivesHelpScreen> createState() =>
      _ExercisePrimitivesHelpScreenState();
}

class _ExercisePrimitivesHelpScreenState
    extends State<ExercisePrimitivesHelpScreen> {
  static const _prefix = 'technical.exercisePrimitives';
  final _focusKey = GlobalKey();
  Map<ExercisePrimitive, Size>? _sizes;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  /// The screenshots' sizes, read from their PNG headers before the page
  /// is laid out, so every section has its final height at once and the
  /// page can open at [ExercisePrimitivesHelpScreen.focus]. A missing or
  /// unreadable file has no size: its section shows the text alone.
  Future<void> _loadSizes() async {
    final bundle = ExercisePrimitivesHelpScreen.bundle ?? rootBundle;
    final sizes = <ExercisePrimitive, Size>{};
    for (final primitive in ExercisePrimitive.values) {
      try {
        final size = ExercisePrimitivesHelpScreen.pngSize(
          await bundle.load(
            ExercisePrimitivesHelpScreen.screenshotOf(primitive),
          ),
        );
        if (size != null) sizes[primitive] = size;
      } catch (_) {
        // No screenshot for this primitive: the text stands alone.
      }
    }
    if (mounted) setState(() => _sizes = sizes);
  }

  ExercisePrimitive? _primitiveOf(String id) {
    for (final primitive in ExercisePrimitive.values) {
      if (exercisePrimitiveHelpSectionId(primitive.serialized) == id) {
        return primitive;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) {
      final sizes = _sizes;
      if (sizes != null && widget.focus != null && !_scrolled) {
        _scrolled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _focusKey.currentContext;
          if (target != null) Scrollable.ensureVisible(target);
        });
      }
      return Scaffold(
        key: const Key('exercise-primitives-help'),
        appBar: AppBar(
          title: Text(_t(locale, '$_prefix.title')),
          actions: [AppLocaleSelector(locale: locale)],
        ),
        body: sizes == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final id in exercisePrimitivesHelpSectionIds)
                      _section(locale, id, sizes),
                  ],
                ),
              ),
      );
    },
  );

  Widget _section(
    AppLocale locale,
    String id,
    Map<ExercisePrimitive, Size> sizes,
  ) {
    final primitive = _primitiveOf(id);
    if (primitive == null) return _localizedSection(locale, '$_prefix.$id');
    final title = _t(locale, '$_prefix.$id.title');
    final size = sizes[primitive];
    return KeyedSubtree(
      key: ValueKey('exercise-primitive-help-${primitive.serialized}'),
      child: _HelpSection(
        key: primitive == widget.focus ? _focusKey : null,
        title: title,
        body: _t(locale, '$_prefix.$id.body'),
        footer: size == null
            ? null
            : Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size.width),
                  child: AspectRatio(
                    aspectRatio: size.width / size.height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        ExercisePrimitivesHelpScreen.screenshotOf(primitive),
                        key: ValueKey(
                          'exercise-primitive-help-image-${primitive.serialized}',
                        ),
                        bundle: ExercisePrimitivesHelpScreen.bundle,
                        fit: BoxFit.contain,
                        semanticLabel: title,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
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

  /// Shown under the body: a primitive's screenshot (Build 261 Revision 6).
  final Widget? footer;
  const _HelpSection({
    super.key,
    required this.title,
    required this.body,
    this.footer,
  });
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
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    ),
  );
}

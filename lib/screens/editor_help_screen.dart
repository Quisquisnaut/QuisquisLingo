import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_authoring.dart';
import '../services/exercise_field_help.dart';
import '../widgets/help_language_toggle.dart';
import 'audit_codes_screen.dart';
import 'editor_help_content.dart';

class EditorHelpScreen extends StatefulWidget {
  const EditorHelpScreen({super.key});

  @override
  State<EditorHelpScreen> createState() => _EditorHelpScreenState();
}

class _EditorHelpScreenState extends State<EditorHelpScreen> {
  HelpLanguage _language = HelpLanguage.english;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _language == HelpLanguage.italian ? 'Guida all’Editor' : 'Editor Help',
      ),
      actions: [
        HelpLanguageToggle(
          key: const Key('editor-help-language-toggle'),
          language: _language,
          onChanged: (value) => setState(() => _language = value),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TechnicalLinks(language: _language),
        const SizedBox(height: 12),
        _CourseTypesHelpSection(language: _language),
        for (final section in editorHelpSections(_language))
          _HelpSection(title: section.title, body: section.body),
      ],
    ),
  );
}

class _CourseTypesHelpSection extends StatelessWidget {
  const _CourseTypesHelpSection({required this.language});

  final HelpLanguage language;

  @override
  Widget build(BuildContext context) {
    final content = editorHelpCourseTypes(language);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content.intro),
            for (final type in content.types) ...[
              const SizedBox(height: 8),
              Text(type),
            ],
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: [
                for (final (index, row) in content.rows.indexed)
                  TableRow(
                    children: [
                      for (final cell in row)
                        _CourseTypeTableCell(cell, bold: index == 0),
                    ],
                  ),
              ],
            ),
            for (final note in content.notes) ...[
              const SizedBox(height: 8),
              Text(note),
            ],
            const SizedBox(height: 12),
            Text(
              content.contact,
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
      style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
    ),
  );
}

class _TechnicalLinks extends StatelessWidget {
  const _TechnicalLinks({required this.language});

  final HelpLanguage language;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editorHelpTechnicalIntro(language).title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(editorHelpTechnicalIntro(language).body),
          // The linked pages below are English only; say so rather than let an
          // Italian reader discover it by tapping.
          if (editorHelpTechnicalIntro(language).note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              editorHelpTechnicalIntro(language).note,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
            title: Text('QuisquisLingo Course Models v9/v10'),
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

  List<Widget> _searchResults() {
    bool matches(String text) => text.toLowerCase().contains(_query);
    final results = <Widget>[];
    for (final preset in ExercisePresetRegistry.presets) {
      final body = ExercisePresetRegistry.helpByPreset[preset.id]!;
      if (matches('${preset.name}\n${preset.description}\n$body')) {
        results.add(
          _HelpSection(
            key: ValueKey('exercise-help-result-${preset.id}'),
            title: preset.name,
            body: '${preset.description}\n\n$body',
          ),
        );
      }
      for (final field in ExerciseFieldHelpRegistry.editorFieldKeys(
        preset.id,
      )) {
        final help = ExerciseFieldHelpRegistry.forEditorField(preset.id, field);
        if (matches('${help.title}\n${help.text}')) {
          results.add(
            _HelpSection(
              key: ValueKey('exercise-help-result-${preset.id}-$field'),
              title: '${preset.name}: ${help.title}',
              body: help.text,
            ),
          );
        }
      }
    }
    for (final supplement in _supplements) {
      if (matches('${supplement.title}\n${supplement.body}')) {
        results.add(supplement);
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _query.isEmpty ? _allSections(context) : _searchResults();
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Help')),
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
                labelText: 'Search Exercise Help',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const ValueKey('exercise-help-search-clear'),
                        tooltip: 'Clear search',
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
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No Exercise Help results match your search.',
                        ),
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
  }

  List<Widget> _allSections(BuildContext context) => [
    for (final category in ExerciseCategory.values)
      if (ExercisePresetRegistry.inCategory(category).isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            category.label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        for (final preset in ExercisePresetRegistry.inCategory(category))
          _HelpSection(
            title: preset.name,
            body: ExercisePresetRegistry.helpByPreset[preset.id]!,
          ),
      ],
    ..._supplements,
  ];

  static const _supplements = [
    _HelpSection(
      title: 'Answer variants',
      body:
          'Multiple complete equivalent answers may be entered on separate lines. Compact syntax is optional: {Io} makes “Io” optional; [prendo|vorrei] chooses one independent alternative; and (non arrivo <> oggi) swaps only declared phrase parts. Grouped alternatives use *: to link by position: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] accepts “il tuo denaro” and “i tuoi soldi”, never “il tuoi soldi” or “i tuo denaro”. Two or more linked groups are required and every linked group must have the same number of alternatives. Linked groups compose with {}, ordinary [] and valid <> scopes. During reordering, terminal punctuation stays at the final sentence end. Expansion is deterministic, removes duplicates, and rejects malformed syntax or more than 128 variants instead of truncating.',
    ),
    _HelpSection(
      title: 'Text evaluation and corrections',
      body:
          'QQL accepts any configured complete answer or syntax-expanded variant after the established case, punctuation, whitespace, apostrophe and accent rules. Type the translation also permits one omitted or duplicated repeated letter in a word of at least five characters when every word position is otherwise unchanged. Its incorrect feedback shows up to three similarity-ranked valid answers and says Some possible translations when more exist. Its correct feedback shows up to two alternatives, excluding the matched canonical answer even after typo tolerance. No alternatives means no empty section. Ties keep author order and ranking never changes correctness. Other typed presets retain their canonical Correct answer. Feedback names only differences actually used; exact answers show no false difference reason.',
    ),
    _HelpSection(
      title: 'Contextual comprehension example',
      body:
          'Question: What does Jane mean?\n\nContext:\nJane: I thought Jim was coming with us.\nJim: I changed my mind.\nJane: That’s just great.\n\nQuestion and Context are separate. Context can be text, audio, or both. Dialogue turns are optional; an announcement, short passage or situation is equally valid. Configure answer choices separately.',
    ),
  ];
}

class CourseModelV4HelpScreen extends StatelessWidget {
  const CourseModelV4HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'QuisquisLingo Course Models v9/v10',
    sections: const [
      _HelpSection(
        title: 'Status',
        body:
            'Work in progress. QuisquisLingo uses formatVersion 9 as its only native Course Model. Earlier formats are rejected without migration or deletion. Every custom Course requires an immutable Original Course Creator and one individual Course Maintainer; an optional Assigned Team remains separate.',
      ),
      _HelpSection(
        title: 'Hierarchy',
        body:
            'Course > Lesson > Guidebook + Round > Content. Every Lesson owns its Guidebook and Duel. Exercise is one Content kind rather than the only object allowed inside a Round.',
      ),
      _HelpSection(
        title: 'Content',
        body:
            'Current kinds include exercise, presentation, explanation, example, vocabulary, text and dialogue. Content has a stable ID and can be required for normal completion. Lesson, Round and Exercise objects carry required UTC updatedAt timestamps. Presentation Content can be interactive without producing a correct/incorrect result.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson GuideBook is structured Content rather than a single monolithic block. Its vocabulary, examples and explanations are learner reference material and can also act as the sole source for configurable, progressively harder draft Round generation and sourceRefs.',
      ),
      _HelpSection(
        title: 'Completion and progression',
        body:
            'required means required for normal completion. Completion, correctness and unlock state are separate. Completing a Lesson or winning its available Duel can unlock the next Lesson without marking skipped Content as completed.',
      ),
      _HelpSection(
        title: 'Language Duel',
        body:
            'Duel identity belongs directly to the Lesson. QuisquisLingo dynamically selects 25 unique eligible exercises from that Lesson and starts with 4 lives. There is no score or pass threshold. If the actual eligible pool is smaller than 25, the Lesson Duel is unavailable rather than invalid.',
      ),
      _HelpSection(
        title: 'Friendly Editor templates',
        body:
            'The Editor keeps names such as Choose a picture, What do you hear?, Build the sentence and Match the sounds. editorTemplate is optional authoring metadata. The learner executes the primitive representation.',
      ),
    ],
  );
}

class ExercisePrimitivesHelpScreen extends StatelessWidget {
  const ExercisePrimitivesHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'Exercise primitives',
    sections: const [
      _HelpSection(
        title: 'Status',
        body:
            'Work in progress. The current primitive set is the implemented Course Models v9/v10 baseline.',
      ),
      _HelpSection(
        title: 'Exercise anatomy',
        body:
            'Exercise = Prompt[] + Interaction + Evaluation, with optional hint and feedback.',
      ),
      _HelpSection(
        title: 'Interactions',
        body:
            'select: choose one or more Items. input: produce a typed response. arrange: order Items. match: create relationships between Items.',
      ),
      _HelpSection(
        title: 'Evaluations',
        body:
            'selected_items checks selected stable Item IDs. text_match checks accepted text with explicit normalization. ordered_items checks Item order. matched_items checks Item relationships.',
      ),
      _HelpSection(
        title: 'Prompt and Item media',
        body:
            'The initial media primitives are text, image and audio. Prompt elements may carry roles such as primary, passage, question, context or clue.',
      ),
      _HelpSection(
        title: 'Presentation Content',
        body:
            'Flashcard is presentation Content, not an Exercise. The learner chooses understood or review_later. Both complete the current presentation; review_later requests re-presentation and is not an incorrect answer.',
      ),
      _HelpSection(
        title: 'Templates vs primitives',
        body:
            'Friendly templates remain an authoring layer. Multiple templates can share the same primitive mechanics. Template constraints such as distractor limits do not become universal primitive rules.',
      ),
    ],
  );
}

class JsonV4HelpScreen extends StatelessWidget {
  const JsonV4HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'JSON data structure',
    sections: const [
      _HelpSection(
        title: 'Status',
        body: 'Work in progress. QuisquisLingo writes formatVersion: 9.',
      ),
      _HelpSection(
        title: 'Root',
        body:
            'The root contains formatVersion, Course metadata and lessons[]. Bundled samples use the native v9 model; custom Courses use v9 or, for merged Courses, v10. Custom roots require immutable originalCourseCreator provenance and one individual maintainer; optional assignedTeamId is separate, while Team membership itself remains outside Course JSON. Earlier Course Models are not read or migrated.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson contains a guidebook with optional publicationState and guidebook.content[] structured Content such as explanation, vocabulary and example entries. An omitted Guidebook publicationState means published; an explicit draft state keeps the Guidebook out of learner delivery. Its displayed Internal ID is derived from the immutable Lesson ID with the suffix _guidebook; no additional ID field is persisted. Guidebook Content retains its own stable IDs. The optional course useGuidebook switch changes learner access and the empty-Guidebook Warning, never the stored content.',
      ),
      _HelpSection(
        title: 'Lesson and Round',
        body:
            'Course, Lesson, Guidebook, Round and authored Exercise content carry draft/published state. Guidebook defaults to published when its optional state is absent. Lesson, Round and Exercise also require UTC updatedAt timestamps. A Course stores Lesson numbering, a legacy-compatible fallback-icon value and optional managed custom Lesson-icon assets. Both accepted legacy fallback values now render the same theme-colored number circle. A Lesson contains lessonId, title, optional Section and themeIconAsset metadata, guidebook, rounds[] and its Duel identity. Guidebook may contain ordered Insights sections with Title and Text. Round title is optional and falls back everywhere to its current Round N position without changing identity.',
      ),
      _HelpSection(
        title: 'Exercise Content',
        body:
            'Exercise Content stores editorTemplate plus exercise.prompt[], exercise.interaction and exercise.evaluation. Correctness uses stable Item IDs rather than display indexes. Build the translation stores one or more literal correctOrders with answer text and ordered Item IDs; legacy correctOrder is rejected.',
      ),
      _HelpSection(
        title: 'Duel',
        body:
            'A Lesson serializes a stable Duel ID and title. Availability is derived at runtime from the actual Lesson exercise pool under the standard eligibility and deduplication rules; it is not serialized and does not depend on Round count. Course createDuels and useGuidebook default true and serialize only when false. Optional sectionNames retains non-empty trimmed reusable names; an empty catalog is omitted. Optional worldFlagId references authoritative bundled SVG artwork and is omitted when empty.',
      ),
      _HelpSection(
        title: 'Compatibility',
        body:
            'Bundled Courses are native Course Model v9; custom Courses are native v9 or v10. Every earlier format is unsupported and is not read, migrated, converted or deleted. Attribution, provenance and Rights Holder metadata never grant Course permissions or infer Team assignment.',
      ),
    ],
  );
}

class _TechnicalPage extends StatelessWidget {
  final String title;
  final List<Widget> sections;
  const _TechnicalPage({required this.title, required this.sections});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(16), children: sections),
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

import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/guidebook_text.dart';
import '../services/authoring_duplication_service.dart';
import '../services/guidebook_round_links.dart';
import '../widgets/course_preview_flag.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/exercise_image_field.dart';
import '../widgets/guidebook_picture_thumbnail.dart';

/// The GuideBook page of the Course Editor (Build 266, GuideBook Modules): a
/// Lesson's modules in teaching order. Add module, open one to edit it, drag
/// to reorder, Remove (asking first); Save Guidebook or Save Guidebook as
/// draft returns the GuideBook, as before Build 266.
class GuidebookEditorScreen extends StatefulWidget {
  final Guidebook guidebook;
  final String guidebookId;

  /// The working copy, for the Course preview flag (Build 261 Revision 2)
  /// and the pictures of Words & Expressions.
  final Course? course;

  /// The Lesson's Rounds: Remove says how many focus on the module.
  final List<LearningRound> rounds;

  /// Where new module and entry IDs come from (a test seam).
  final AuthoringIdGenerator? ids;

  const GuidebookEditorScreen({
    super.key,
    required this.guidebook,
    this.guidebookId = '',
    this.course,
    this.rounds = const [],
    this.ids,
  });

  @override
  State<GuidebookEditorScreen> createState() => _GuidebookEditorScreenState();
}

class _GuidebookEditorScreenState extends State<GuidebookEditorScreen> {
  late final List<GuidebookModule> _modules = [...widget.guidebook.modules];
  late final AuthoringIdGenerator _ids =
      widget.ids ?? TimestampAuthoringIdGenerator();

  void _save(PublicationState publicationState) => Navigator.pop(
    context,
    widget.guidebook.copyWith(
      publicationState: publicationState,
      modules: _modules,
    ),
  );

  Future<GuidebookModule?> _edit(GuidebookModule module) =>
      Navigator.of(context).push<GuidebookModule>(
        MaterialPageRoute(
          builder: (_) => GuidebookModuleEditorScreen(
            module: module,
            course: widget.course,
            ids: _ids,
          ),
        ),
      );

  Future<void> _addModule() async {
    final added = await _edit(
      GuidebookModule(id: _ids.next('module'), title: ''),
    );
    if (added == null || !mounted) return;
    setState(() => _modules.add(added));
  }

  Future<void> _openModule(int index) async {
    final edited = await _edit(_modules[index]);
    if (edited == null || !mounted) return;
    setState(() => _modules[index] = edited);
  }

  Future<void> _removeModule(int index) async {
    final module = _modules[index];
    final focusing = GuidebookRoundLinks.focusCount(widget.rounds, module.id);
    final remove =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove module?'),
            content: Text(
              [
                'Remove “${_titleOf(module)}” with its Sentences and Words & Expressions? This takes effect when the Guidebook is saved.',
                if (focusing > 0)
                  '$focusing ${focusing == 1 ? 'Round focuses' : 'Rounds focus'} on this module; '
                      '${focusing == 1 ? 'it keeps its' : 'they keep their'} exercises and '
                      '${focusing == 1 ? 'loses' : 'lose'} the link.',
              ].join('\n\n'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              FilledButton(
                key: const Key('guidebook-module-remove-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!remove || !mounted) return;
    setState(() => _modules.removeAt(index));
  }

  static String _titleOf(GuidebookModule module) =>
      module.title.trim().isEmpty ? 'Untitled module' : module.title.trim();

  static String _counts(GuidebookModule module) {
    final s = module.sentences.length;
    final w = module.words.length;
    return '$s ${s == 1 ? 'sentence' : 'sentences'} · '
        '$w ${w == 1 ? 'word' : 'words'}';
  }

  Widget _moduleCard(int index) {
    final module = _modules[index];
    return Card(
      key: ValueKey('guidebook-module-card-${module.id}'),
      child: ListTile(
        key: ValueKey('guidebook-module-$index'),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Tooltip(
            message: 'Drag to reorder',
            child: Icon(Icons.drag_handle),
          ),
        ),
        title: Text(
          _titleOf(module),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Tooltip(
          message:
              'Sentences: example sentences with their translation. '
              'Words: the Words & Expressions entries, single words and '
              'fixed expressions with their translation.',
          child: Text(
            _counts(module),
            key: ValueKey('guidebook-module-counts-$index'),
          ),
        ),
        trailing: IconButton(
          key: ValueKey('guidebook-module-remove-$index'),
          tooltip: 'Remove module',
          onPressed: () => _removeModule(index),
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: () => _openModule(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: CoursePreviewTitle(
        course: widget.course,
        title: const Text('Guidebook'),
      ),
      actions: [
        const EditorAppBarActions(helpQuestion: 'guidebook'),
        TextButton(
          key: const Key('guidebook-save-appbar'),
          onPressed: () => _save(PublicationState.published),
          child: const Text('Save'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'A GuideBook is the Lesson\'s reference, made of modules: each '
          'module is one short topic with Sentences, Words & Expressions and '
          'a short Overview. Learners read them in this order; the Round '
          'Wizard turns them into Rounds.',
        ),
        const SizedBox(height: 12),
        if (_modules.isEmpty)
          const Card(
            key: Key('guidebook-modules-empty'),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No modules yet. A module is one short, coherent topic, for '
                'example "Al bar: ordering and paying". Press Add module to '
                'write its Sentences and Words & Expressions.',
              ),
            ),
          )
        else
          ReorderableListView(
            key: const Key('guidebook-modules-list'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            // onReorderItem gives the index after the item was removed.
            onReorderItem: (from, to) =>
                setState(() => _modules.insert(to, _modules.removeAt(from))),
            children: [
              for (var i = 0; i < _modules.length; i++) _moduleCard(i),
            ],
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('guidebook-add-module'),
            onPressed: _addModule,
            icon: const Icon(Icons.add),
            label: const Text('Add module'),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('guidebook-save-draft'),
              onPressed: () => _save(PublicationState.draft),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Save Guidebook as draft'),
            ),
            FilledButton.icon(
              key: const Key('guidebook-save'),
              onPressed: () => _save(PublicationState.published),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Guidebook'),
            ),
          ],
        ),
        if (widget.guidebookId.isNotEmpty)
          EditorInternalIdText(label: 'GuideBook', id: widget.guidebookId),
      ],
    ),
  );
}

/// One row of a module page: a sentence or a Words & Expressions entry
/// being edited.
class _EntryRow {
  _EntryRow(
    this.id, {
    String target = '',
    String source = '',
    String context = '',
    this.picture,
  }) : target = TextEditingController(text: target),
       source = TextEditingController(text: source),
       context = TextEditingController(text: context);

  factory _EntryRow.of(GuidebookEntry entry) => _EntryRow(
    entry.id,
    target: entry.target,
    source: entry.source,
    context: entry.context,
    picture: entry.picture,
  );

  final String id;
  final TextEditingController target;
  final TextEditingController source;
  final TextEditingController context;
  GuidebookPicture? picture;
  String? targetError;
  String? sourceError;
  final key = GlobalKey();

  bool get isEmpty => target.text.trim().isEmpty && source.text.trim().isEmpty;

  GuidebookEntry entry() => GuidebookEntry(
    id: id,
    target: target.text.trim(),
    source: source.text.trim(),
    context: context.text.trim(),
    picture: picture,
  );

  Object snapshot() => [
    id,
    target.text.trim(),
    source.text.trim(),
    context.text.trim(),
    picture?.toJson(),
  ];

  void dispose() {
    target.dispose();
    source.dispose();
    context.dispose();
  }
}

/// A module of a GuideBook (Build 266), its fields in the owner's order:
/// Title, Sentences, Words & Expressions, Overview. Each list is one row per
/// entry with Target, Source and Context; a Words & Expressions row may have
/// a picture, marked Plural when the word means several things.
///
/// Done (or leaving the page) returns the module to the GuideBook page,
/// which still needs Save Guidebook. A row with a Target but no Source (or
/// the reverse) is refused and pointed to; an empty row is dropped.
class GuidebookModuleEditorScreen extends StatefulWidget {
  const GuidebookModuleEditorScreen({
    super.key,
    required this.module,
    this.course,
    this.ids,
  });

  final GuidebookModule module;

  /// The working copy: pictures become its own media.
  final Course? course;
  final AuthoringIdGenerator? ids;

  @override
  State<GuidebookModuleEditorScreen> createState() =>
      _GuidebookModuleEditorScreenState();
}

class _GuidebookModuleEditorScreenState
    extends State<GuidebookModuleEditorScreen> {
  late final AuthoringIdGenerator _ids =
      widget.ids ?? TimestampAuthoringIdGenerator();
  late final _title = TextEditingController(text: widget.module.title);
  late final _overview = TextEditingController(text: widget.module.overview);
  late final List<_EntryRow> _sentences = [
    for (final entry in widget.module.sentences) _EntryRow.of(entry),
  ];
  late final List<_EntryRow> _words = [
    for (final entry in widget.module.words) _EntryRow.of(entry),
  ];
  late final String _opened = _snapshot();
  final _scroll = ScrollController();
  String? _titleError;
  bool _leaving = false;

  @override
  void dispose() {
    _title.dispose();
    _overview.dispose();
    for (final row in [..._sentences, ..._words]) {
      row.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  String _snapshot() => jsonEncode([
    _title.text.trim(),
    [for (final row in _sentences) row.snapshot()],
    [for (final row in _words) row.snapshot()],
    _overview.text.trim(),
  ]);

  bool get _changed => _snapshot() != _opened;

  /// The module the form holds, or null with the problem shown at its field.
  GuidebookModule? _validated() {
    String? firstProblem;
    _EntryRow? firstRow;
    setState(() {
      _titleError = _title.text.trim().isEmpty
          ? 'Give the module a title.'
          : null;
      if (_titleError != null) firstProblem = _titleError;
      void check(List<_EntryRow> rows, String list) {
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          row.targetError = null;
          row.sourceError = null;
          if (row.isEmpty) continue;
          final target = row.target.text.trim();
          final problem = target.isEmpty
              ? 'Write the Target, or clear the row.'
              : GuidebookText.targetProblem(target);
          if (problem != null) {
            row.targetError = target.isEmpty ? problem : 'Target: $problem.';
          }
          if (row.source.text.trim().isEmpty) {
            row.sourceError = 'Write the Source, or clear the row.';
          }
          final error = row.targetError ?? row.sourceError;
          if (error != null && firstProblem == null) {
            firstProblem = '$list row ${i + 1}: $error';
            firstRow = row;
          }
        }
      }

      check(_sentences, 'Sentences');
      check(_words, 'Words & Expressions');
    });
    if (firstProblem != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(firstProblem!)));
      final rowContext = firstRow?.key.currentContext;
      if (rowContext != null) {
        Scrollable.ensureVisible(
          rowContext,
          duration: const Duration(milliseconds: 200),
        );
      }
      return null;
    }
    return widget.module.copyWith(
      title: _title.text.trim(),
      sentences: [
        for (final row in _sentences)
          if (!row.isEmpty) row.entry().copyWith(clearPicture: true),
      ],
      words: [
        for (final row in _words)
          if (!row.isEmpty) row.entry(),
      ],
      overview: _overview.text.trim(),
    );
  }

  void _done() {
    final module = _validated();
    if (module == null) return;
    _leaving = true;
    Navigator.pop(context, module);
  }

  /// Leaving the page keeps the changes, as Done does; when the form cannot
  /// be kept the author chooses to stay or to discard.
  Future<void> _onLeave() async {
    if (!_changed) {
      _leaving = true;
      Navigator.pop(context);
      return;
    }
    final module = _validated();
    if (module != null) {
      _leaving = true;
      Navigator.pop(context, module);
      return;
    }
    final discard =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave this module?'),
            content: const Text(
              'Some rows are not complete. Keep editing to fix them, or '
              'discard the changes made to this module.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                key: const Key('guidebook-module-discard'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard changes'),
              ),
            ],
          ),
        ) ??
        false;
    if (!discard || !mounted) return;
    _leaving = true;
    Navigator.pop(context);
  }

  void _addRow(List<_EntryRow> rows) =>
      setState(() => rows.add(_EntryRow(_ids.next('entry'))));

  void _removeRow(List<_EntryRow> rows, int index) =>
      setState(() => rows.removeAt(index).dispose());

  Future<void> _choosePicture(_EntryRow row) async {
    var asset = row.picture?.asset ?? '';
    SharedImageSource? source = row.picture?.sharedImageSource;
    final word = row.target.text.trim();
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Picture'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: ExerciseImageField(
                course: widget.course,
                asset: asset,
                sharedSource: source,
                readOnly: false,
                compact: true,
                title: word.isEmpty ? 'Picture' : 'Picture of “$word”',
                onChanged: (change) => setLocal(() {
                  asset = change.asset;
                  source = change.source;
                }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('guidebook-module-picture-done'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
    if (chosen != true || !mounted) return;
    setState(
      () => row.picture = asset.isEmpty
          ? null
          // A replaced picture keeps the Plural mark, as an exercise
          // picture does.
          : GuidebookPicture(
              asset: asset,
              sharedImageSource: source,
              plural: row.picture?.plural ?? false,
            ),
    );
  }

  Widget _pictureSlot(_EntryRow row, String prefix) {
    final picture = row.picture;
    const tooltip =
        'Picture (optional): what this word looks like. Learners see it in '
        'the GuideBook, in Review and in Word Lookup; the Round Wizard uses '
        'it for picture exercises.';
    // A Wrap, so the Plural chip moves under the picture in a narrow window.
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: tooltip,
          child: InkWell(
            key: ValueKey('$prefix-picture'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => _choosePicture(row),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: picture == null
                  ? const Icon(Icons.add_photo_alternate_outlined)
                  : GuidebookPictureThumbnail(
                      courseId: widget.course?.courseId ?? '',
                      picture: picture,
                      size: 44,
                    ),
            ),
          ),
        ),
        if (picture != null) ...[
          IconButton(
            key: ValueKey('$prefix-picture-remove'),
            tooltip: 'Remove picture',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => row.picture = null),
            icon: const Icon(Icons.close, size: 18),
          ),
          FilterChip(
            key: ValueKey('$prefix-picture-plural'),
            label: const Text('Plural'),
            tooltip:
                'Plural: the word means several things (i gatti, the cats); '
                'learners see stacked copies of the picture.',
            selected: picture.plural,
            visualDensity: VisualDensity.compact,
            onSelected: (value) =>
                setState(() => row.picture = picture.withPlural(value)),
          ),
        ],
      ],
    );
  }

  Widget _rowCard(List<_EntryRow> rows, int index, {required bool word}) {
    final row = rows[index];
    final prefix = word
        ? 'guidebook-module-word-$index'
        : 'guidebook-module-sentence-$index';
    InputDecoration decoration(String label, {String? error, String? helper}) =>
        InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          labelText: label,
          errorText: error,
          helperText: helper,
        );
    return KeyedSubtree(
      key: ObjectKey(row),
      child: Card(
        key: row.key,
        child: Padding(
          key: ValueKey(prefix),
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: word
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _pictureSlot(row, prefix),
                          )
                        : Text(
                            'Sentence ${index + 1}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                  ),
                  IconButton(
                    key: ValueKey('$prefix-remove'),
                    tooltip: word
                        ? 'Remove this entry'
                        : 'Remove this sentence',
                    onPressed: () => _removeRow(rows, index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Tooltip(
                        message: 'Drag to reorder',
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                key: ValueKey('$prefix-target'),
                controller: row.target,
                decoration: decoration('Target', error: row.targetError),
                onChanged: (_) {
                  if (row.targetError != null) {
                    setState(() => row.targetError = null);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('$prefix-source'),
                controller: row.source,
                decoration: decoration('Source', error: row.sourceError),
                onChanged: (_) {
                  if (row.sourceError != null) {
                    setState(() => row.sourceError = null);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('$prefix-context'),
                controller: row.context,
                maxLength: GuidebookText.maxContextLength,
                decoration: decoration('Context (optional)'),
              ),
              EditorInternalIdText(label: 'Entry', id: row.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(
    String title,
    String description,
    String key,
    List<_EntryRow> rows, {
    required bool word,
  }) => Column(
    key: ValueKey(key),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(description),
      const SizedBox(height: 8),
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: (from, to) =>
            setState(() => rows.insert(to, rows.removeAt(from))),
        children: [
          for (var i = 0; i < rows.length; i++) _rowCard(rows, i, word: word),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: ValueKey(
            word
                ? 'guidebook-module-add-word'
                : 'guidebook-module-add-sentence',
          ),
          onPressed: () => _addRow(rows),
          icon: const Icon(Icons.add),
          label: Text(word ? 'Add word or expression' : 'Add sentence'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_leaving) _onLeave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: CoursePreviewTitle(
          course: widget.course,
          title: const Text('Module'),
        ),
        actions: [
          const EditorAppBarActions(helpQuestion: 'guidebook'),
          TextButton(
            key: const Key('guidebook-module-done'),
            onPressed: _done,
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('guidebook-module-title'),
            controller: _title,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Title',
              helperText: 'The module\'s own name, for example "Al bar".',
              errorText: _titleError,
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 20),
          _list(
            'Sentences',
            'Example sentences in use, each with its translation.',
            'guidebook-module-sentences',
            _sentences,
            word: false,
          ),
          const SizedBox(height: 20),
          _list(
            'Words & Expressions',
            'Single words and fixed expressions, each with its translation.',
            'guidebook-module-words',
            _words,
            word: true,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('guidebook-module-overview'),
            controller: _overview,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Overview',
              helperText:
                  'Two or three sentences. A longer topic is better split '
                  'into shorter modules.',
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: const Key('guidebook-module-done-button'),
              onPressed: _done,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
          ),
          EditorInternalIdText(label: 'Module', id: widget.module.id),
        ],
      ),
    ),
  );
}

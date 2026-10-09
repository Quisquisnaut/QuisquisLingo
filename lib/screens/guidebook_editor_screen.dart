import 'dart:convert';

import 'package:flutter/material.dart';

import '../localization/help/help_text.dart';
import '../localization/locale_service.dart';
import '../models/course_models.dart';
import '../models/guidebook_text.dart';
import '../services/authoring_duplication_service.dart';
import '../services/exercise_image_metadata_service.dart';
import '../services/guidebook_module_sample.dart';
import '../services/guidebook_paste_list.dart';
import '../services/guidebook_picture_match.dart';
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

  /// The image catalog the picture prefill reads (a test seam).
  final ExerciseImageMetadataService? metadataService;

  const GuidebookEditorScreen({
    super.key,
    required this.guidebook,
    this.guidebookId = '',
    this.course,
    this.rounds = const [],
    this.ids,
    this.metadataService,
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
            metadataService: widget.metadataService,
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
                'write its Sentences and Words & Expressions; on the module '
                'page, Fill with an example shows a complete one.',
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

  /// The words the picture prefill last read (Build 266 Revision 1): it
  /// runs again only when they change, so a removed picture stays removed
  /// until the word changes.
  String? prefillWords;

  /// The picture is the prefill's choice: the Suggested mark, for this
  /// editing session only.
  bool suggested = false;

  /// Several pictures have the word's name: "N matching pictures".
  GuidebookPictureMatch matches = GuidebookPictureMatch.none;
  String matchWord = '';

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
    this.metadataService,
  });

  final GuidebookModule module;

  /// The working copy: pictures become its own media.
  final Course? course;
  final AuthoringIdGenerator? ids;

  /// The image catalog the picture prefill reads (a test seam).
  final ExerciseImageMetadataService? metadataService;

  @override
  State<GuidebookModuleEditorScreen> createState() =>
      _GuidebookModuleEditorScreenState();
}

class _GuidebookModuleEditorScreenState
    extends State<GuidebookModuleEditorScreen> {
  late final AuthoringIdGenerator _ids =
      widget.ids ?? TimestampAuthoringIdGenerator();
  late final _title = TextEditingController(text: widget.module.title);
  late final _overview = TextEditingController(text: widget.module.overview)
    ..addListener(_overviewChanged);
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
  late int _overviewLength = _overview.text.trim().length;

  /// The picture prefill (Build 266 Revision 1): the side whose words name
  /// QQL pictures in this Course (null: no prefill), and the catalog once
  /// read.
  late final GuidebookPictureSide? _side = widget.course == null
      ? null
      : GuidebookPictureIndex.sideFor(widget.course!);
  GuidebookPictureIndex? _pictures;

  @override
  void initState() {
    super.initState();
    // A reopened GuideBook is never prefilled: its words count as read.
    for (final row in _words) {
      row.prefillWords = _wordsKey(row);
    }
    if (_side != null) _loadPictures();
  }

  Future<void> _loadPictures() async {
    try {
      final catalog =
          await (widget.metadataService ?? ExerciseImageMetadataService())
              .loadCatalog();
      if (mounted) _pictures = GuidebookPictureIndex(catalog);
    } catch (_) {
      // Without the catalog there is no prefill; choosing still works.
    }
  }

  void _overviewChanged() {
    final length = _overview.text.trim().length;
    if (length != _overviewLength && mounted) {
      setState(() => _overviewLength = length);
    }
  }

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

  List<String> _wordsOf(_EntryRow row) => _side == null
      ? const []
      : GuidebookPictureIndex.wordsOf(
          _side,
          target: row.target.text,
          source: row.source.text,
        );

  String? _wordsKey(_EntryRow row) => _side == null
      ? null
      : _wordsOf(row).map(GuidebookPictureIndex.key).join('\n');

  /// Fills [row]'s picture when exactly one QQL picture has its word's name
  /// (Suggested), or offers the matches when several do. Only after the
  /// word changed, never over a picture the author chose.
  void _prefill(_EntryRow row) {
    final pictures = _pictures;
    final key = _wordsKey(row);
    if (pictures == null || key == null || key == row.prefillWords) return;
    setState(() {
      row.prefillWords = key;
      row.matches = GuidebookPictureMatch.none;
      if (row.picture != null && !row.suggested) return;
      row.picture = null;
      row.suggested = false;
      _match(row, pictures);
    });
  }

  /// The prefill's choice for [row]: one picture (Suggested), several
  /// (offered as matches) or none. True when the row got something.
  bool _match(_EntryRow row, GuidebookPictureIndex pictures) {
    for (final word in _wordsOf(row)) {
      final match = pictures.find(word);
      if (match.isEmpty) continue;
      if (match.isSingle) {
        row.picture = GuidebookPicture(
          asset: match.pictures.single.assetPath,
          plural: match.plural,
        );
        row.suggested = true;
      } else {
        row.matches = match;
        row.matchWord = GuidebookPictureIndex.key(word);
      }
      return true;
    }
    return false;
  }

  /// Suggest pictures (Build 267 Revision 3, owner decision of 9 October
  /// 2026): the prefill for every Words & Expressions row without a
  /// picture, also rows written before (the prefill alone never runs on a
  /// reopened module). A picture already there is never replaced.
  Future<void> _suggestPictures() async {
    if (_pictures == null) await _loadPictures();
    final pictures = _pictures;
    if (pictures == null || !mounted) return;
    var filled = 0;
    var offered = 0;
    setState(() {
      for (final row in _words) {
        if (row.picture != null || row.isEmpty) continue;
        row.matches = GuidebookPictureMatch.none;
        row.suggested = false;
        if (_match(row, pictures)) {
          if (row.picture != null) {
            filled++;
          } else {
            offered++;
          }
        }
        row.prefillWords = _wordsKey(row);
      }
    });
    final parts = [
      if (filled > 0) 'QQL suggested $filled picture${filled == 1 ? '' : 's'}',
      if (offered > 0)
        '$offered word${offered == 1 ? ' has' : 's have'} several matching '
            'pictures',
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('guidebook-module-suggest-pictures-result'),
          content: Text(
            parts.isEmpty
                ? 'No picture of QQL\'s library has the name of a word '
                      'without a picture.'
                : '${parts.join('; ')}. Tap a picture to change it.',
          ),
        ),
      );
  }

  /// The author touched the picture: it is no longer the prefill's choice.
  void _authorChose(_EntryRow row) {
    row.suggested = false;
    row.matches = GuidebookPictureMatch.none;
    row.prefillWords = _wordsKey(row);
  }

  /// What the image library is searched for when it opens from [row]: its
  /// English word as the prefill compares it ("an apple" → "apple"), only
  /// in a Course to or from English (owner request of 8 October 2026);
  /// otherwise null, an unsearched library.
  String? _librarySearch(_EntryRow row) {
    for (final word in _wordsOf(row)) {
      final key = GuidebookPictureIndex.key(word);
      if (key.isNotEmpty) return key;
    }
    return null;
  }

  Future<void> _chooseMatch(_EntryRow row) async {
    final plural = row.matches.plural;
    final change = await chooseLibraryPicture(
      context,
      course: widget.course,
      initialSearch: row.matchWord,
      appliesTo: 'GuideBook picture',
    );
    if (change == null || !mounted) return;
    setState(() {
      _authorChose(row);
      row.picture = GuidebookPicture(
        asset: change.asset,
        sharedImageSource: change.source,
        plural: plural,
      );
    });
  }

  bool get _isBlank =>
      _title.text.trim().isEmpty &&
      _overview.text.trim().isEmpty &&
      [
        ..._sentences,
        ..._words,
      ].every((row) => row.isEmpty && row.picture == null);

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required Key key,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: key,
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  void _replaceRows(List<_EntryRow> rows, Iterable<GuidebookEntry> entries) {
    for (final row in rows) {
      row.dispose();
    }
    rows
      ..clear()
      ..addAll(entries.map(_EntryRow.of));
  }

  /// Fill with an example: the built-in sample module, every entry with a
  /// fresh ID; it asks first when the form holds something.
  Future<void> _fillExample() async {
    if (!_isBlank &&
        !await _confirm(
          title: 'Fill with an example?',
          message:
              'The example replaces everything on this page: the title, '
              'the Sentences, the Words & Expressions and the Overview.',
          action: 'Fill',
          key: const Key('guidebook-module-fill-example-confirm'),
        )) {
      return;
    }
    if (!mounted) return;
    final sample = GuidebookModuleSample.module(
      id: widget.module.id,
      ids: _ids,
    );
    setState(() {
      _title.text = sample.title;
      _overview.text = sample.overview;
      _titleError = null;
      _replaceRows(_sentences, sample.sentences);
      _replaceRows(_words, sample.words);
    });
    for (final row in _words) {
      _prefill(row);
    }
  }

  /// Clear all: an empty module, pictures included; it asks first unless
  /// the page is empty already.
  Future<void> _clearAll() async {
    if (_isBlank) return;
    if (!await _confirm(
      title: 'Clear all?',
      message:
          'This empties the title, every Sentence and Words & Expressions '
          'entry (pictures included) and the Overview.',
      action: 'Clear all',
      key: const Key('guidebook-module-clear-all-confirm'),
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _title.clear();
      _overview.clear();
      _titleError = null;
      _replaceRows(_sentences, const []);
      _replaceRows(_words, const []);
    });
  }

  /// Paste list: one entry per line, `target = source [context]`, appended
  /// with fresh IDs; the lines it cannot read are named.
  Future<void> _pasteList(List<_EntryRow> rows, {required bool word}) async {
    final pasted = await showDialog<String>(
      context: context,
      builder: (_) => _PasteListDialog(word: word),
    );
    if (pasted == null || !mounted) return;
    final read = GuidebookPasteList.read(pasted);
    final added = [
      for (final entry in read.entries)
        _EntryRow(
          _ids.next('entry'),
          target: entry.target,
          source: entry.source,
          context: entry.context,
        ),
    ];
    setState(() => rows.addAll(added));
    if (word) {
      for (final row in added) {
        _prefill(row);
      }
    }
    if (read.unread.isEmpty || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('guidebook-module-paste-unread'),
        title: Text(
          '${read.unread.length} '
          '${read.unread.length == 1 ? 'line was' : 'lines were'} not added',
        ),
        content: SingleChildScrollView(
          child: Text(
            [
              if (added.isNotEmpty)
                '${added.length} ${added.length == 1 ? 'entry was' : 'entries were'} added.',
              for (final line in read.unread)
                'Line ${line.number}: ${line.reason}.\n“${line.line}”',
            ].join('\n\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// The Help control of a module field: a tooltip, and a dialog with the
  /// field's Help in the Help Language (EN/IT/ES).
  Widget _fieldHelp(String field, {Key? key}) => IconButton(
    key: key ?? ValueKey('guidebook-field-help-$field'),
    tooltip: _fieldTooltips[field],
    onPressed: () => _showFieldHelp(field),
    icon: const Icon(Icons.help_outline),
  );

  Future<void> _showFieldHelp(String field) async {
    var locale = AppLocale.english;
    try {
      locale = await LocaleService().read();
    } catch (_) {}
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          helpText.lookup(locale, 'guidebookHelp.field.$field.title'),
        ),
        content: SingleChildScrollView(
          child: Text(
            helpText.lookup(locale, 'guidebookHelp.field.$field.body'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const _fieldTooltips = {
    'title': 'Title: the module\'s own name, one short topic.',
    'sentences': 'Sentences: examples in use, each with its translation.',
    'words':
        'Words & Expressions: single words and fixed expressions, each with '
        'its translation. Word Lookup and Review read them.',
    'target':
        'Target: the word or sentence in the language the Course teaches.',
    'source': 'Source: its translation in the learners\' language.',
    'context':
        'Context: a short note in the learners\' language: the sense, the '
        'subject area, formal or informal, who is speaking.',
    'picture': 'Picture (optional): what this word looks like.',
    'overview': 'Overview: two or three sentences about the topic.',
    'pasteList':
        'Paste list: add many entries at once, one per line, '
        'target = source [context].',
  };

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
                help: _fieldHelp('picture'),
                librarySearch: _librarySearch(row),
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
    setState(() {
      _authorChose(row);
      row.picture = asset.isEmpty
          ? null
          // A replaced picture keeps the Plural mark, as an exercise
          // picture does.
          : GuidebookPicture(
              asset: asset,
              sharedImageSource: source,
              plural: row.picture?.plural ?? false,
            );
    });
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
            onPressed: () => setState(() {
              _authorChose(row);
              row.picture = null;
            }),
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
            onSelected: (value) => setState(() {
              _authorChose(row);
              row.picture = picture.withPlural(value);
            }),
          ),
          if (row.suggested)
            Tooltip(
              message: picture.plural
                  ? 'Chosen because its name matches the word\'s singular, '
                        'and marked Plural. Change or remove it.'
                  : 'Chosen because its name matches the word. Change or '
                        'remove it.',
              child: Chip(
                key: ValueKey('$prefix-picture-suggested'),
                avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: Text(picture.plural ? 'Suggested, plural' : 'Suggested'),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ] else if (!row.matches.isEmpty)
          Tooltip(
            message:
                'Several QQL pictures have this name. Choose one, or leave '
                'the word without a picture.',
            child: TextButton.icon(
              key: ValueKey('$prefix-picture-matches'),
              onPressed: () => _chooseMatch(row),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text('${row.matches.pictures.length} matching pictures'),
            ),
          ),
      ],
    );
  }

  Widget _rowCard(List<_EntryRow> rows, int index, {required bool word}) {
    final row = rows[index];
    final prefix = word
        ? 'guidebook-module-word-$index'
        : 'guidebook-module-sentence-$index';
    InputDecoration decoration(String label, {String? error, Widget? help}) =>
        InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          labelText: label,
          errorText: error,
          suffixIcon: help,
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
              Focus(
                skipTraversal: true,
                onFocusChange: (focused) {
                  if (!focused && word) _prefill(row);
                },
                child: TextField(
                  key: ValueKey('$prefix-target'),
                  controller: row.target,
                  decoration: decoration(
                    'Target',
                    error: row.targetError,
                    help: _fieldHelp(
                      'target',
                      key: ValueKey('$prefix-target-help'),
                    ),
                  ),
                  onChanged: (_) {
                    if (row.targetError != null) {
                      setState(() => row.targetError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Focus(
                skipTraversal: true,
                onFocusChange: (focused) {
                  if (!focused && word) _prefill(row);
                },
                child: TextField(
                  key: ValueKey('$prefix-source'),
                  controller: row.source,
                  decoration: decoration(
                    'Source',
                    error: row.sourceError,
                    help: _fieldHelp(
                      'source',
                      key: ValueKey('$prefix-source-help'),
                    ),
                  ),
                  onChanged: (_) {
                    if (row.sourceError != null) {
                      setState(() => row.sourceError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('$prefix-context'),
                controller: row.context,
                maxLength: GuidebookText.maxContextLength,
                decoration: decoration(
                  'Context (optional)',
                  help: _fieldHelp(
                    'context',
                    key: ValueKey('$prefix-context-help'),
                  ),
                ),
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
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          _fieldHelp(word ? 'words' : 'sentences'),
        ],
      ),
      Text(description),
      const SizedBox(height: 4),
      Tooltip(
        message:
            'Words that may be left out, like an understood subject: shown '
            'in grey, accepted with or without.',
        child: Text(
          '{…} in a Target marks words that may be left out: {io} sono stanco.',
          key: ValueKey('$key-braces'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
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
      Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            key: ValueKey(
              word
                  ? 'guidebook-module-add-word'
                  : 'guidebook-module-add-sentence',
            ),
            onPressed: () => _addRow(rows),
            icon: const Icon(Icons.add),
            label: Text(word ? 'Add word or expression' : 'Add sentence'),
          ),
          Tooltip(
            message: _fieldTooltips['pasteList']!,
            child: TextButton.icon(
              key: ValueKey(
                word
                    ? 'guidebook-module-paste-words'
                    : 'guidebook-module-paste-sentences',
              ),
              onPressed: () => _pasteList(rows, word: word),
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste list'),
            ),
          ),
          // Build 267 Revision 3: only where the prefill works, in a Course
          // to or from English.
          if (word && _side != null)
            Tooltip(
              message:
                  'Suggest a QQL picture for every word without one, when a '
                  'picture has its name. Pictures already there stay.',
              child: TextButton.icon(
                key: const Key('guidebook-module-suggest-pictures'),
                onPressed: _suggestPictures,
                icon: const Icon(Icons.image_search_outlined),
                label: const Text('Suggest pictures'),
              ),
            ),
        ],
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
          const EditorAppBarActions(helpQuestion: 'guidebookEntries'),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tooltip(
                message:
                    'Fill every field with a complete sample module, in '
                    'Italian and English, to see how one is written.',
                child: OutlinedButton.icon(
                  key: const Key('guidebook-module-fill-example'),
                  onPressed: _fillExample,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Fill with an example'),
                ),
              ),
              Tooltip(
                message: 'Empty every field of this module.',
                child: OutlinedButton.icon(
                  key: const Key('guidebook-module-clear-all'),
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('guidebook-module-title'),
            controller: _title,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Title',
              helperText: 'The module\'s own name, for example "Al bar".',
              errorText: _titleError,
              suffixIcon: _fieldHelp('title'),
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 20),
          _list(
            'Sentences',
            'Example sentences in use, each with its translation. Example: '
                'Lei è stanca? = Are you tired?, Context: formal, to a woman.',
            'guidebook-module-sentences',
            _sentences,
            word: false,
          ),
          const SizedBox(height: 20),
          _list(
            'Words & Expressions',
            'Single words and fixed expressions, each with its translation. '
                'Examples: il conto = the bill (Context: restaurant), '
                'il conto = the account (Context: bank), buongiorno = good '
                'morning. A word with two meanings is two entries.',
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
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Overview',
              helperText:
                  'Two or three sentences. A longer topic is better split '
                  'into shorter modules.',
              helperMaxLines: 3,
              suffixIcon: _fieldHelp('overview'),
              counter: Tooltip(
                message:
                    'Characters in the Overview. From '
                    '${GuidebookText.longOverviewLength} a hint suggests '
                    'splitting the topic; it never blocks saving.',
                child: Text(
                  '$_overviewLength characters',
                  key: const Key('guidebook-module-overview-count'),
                ),
              ),
            ),
          ),
          if (_overviewLength >= GuidebookText.longOverviewLength)
            Padding(
              key: const Key('guidebook-module-overview-long'),
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Long overview. Consider splitting this topic into '
                      'shorter modules.',
                    ),
                  ),
                ],
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

/// Paste list's dialog (Build 266 Revision 1). It owns its text controller,
/// so the controller lives until the dialog's closing animation ends.
class _PasteListDialog extends StatefulWidget {
  const _PasteListDialog({required this.word});

  final bool word;

  @override
  State<_PasteListDialog> createState() => _PasteListDialogState();
}

class _PasteListDialogState extends State<_PasteListDialog> {
  final _text = TextEditingController();

  static const _sentenceExamples = [
    'Lei è stanca? = Are you tired? [formal, to a woman]',
    'Il conto, per favore. = The bill, please.',
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.word ? 'Paste Words & Expressions' : 'Paste Sentences'),
    content: SizedBox(
      width: 480,
      child: TextField(
        key: const Key('guidebook-module-paste-text'),
        controller: _text,
        autofocus: true,
        minLines: 6,
        maxLines: 12,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'One entry per line',
          helperText:
              'target = source [context], the Context optional. Example:\n'
              '${(widget.word ? GuidebookPasteList.exampleLines : _sentenceExamples).join('\n')}',
          helperMaxLines: 6,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('guidebook-module-paste-add'),
        onPressed: () => Navigator.pop(context, _text.text),
        child: const Text('Add'),
      ),
    ],
  );
}

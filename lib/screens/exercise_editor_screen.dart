import '../widgets/editor_notes_field.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/preset_action_chip.dart';
import 'package:flutter/services.dart';
import '../services/answer_engine.dart';
import '../services/answer_materialization_service.dart';
import '../services/portable_exercise_image.dart';
import '../widgets/script_recognition_editor.dart';
import '../widgets/exercise_image_field.dart';
import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import '../services/course_language_resolver.dart';
import '../services/course_hierarchy_update_service.dart';
import '../services/course_audit_service.dart';
import 'round_screen.dart';
import 'primitive_editor_screen.dart';
import 'editor_help_screen.dart';
import '../services/translation_choice_service.dart';
import '../services/exercise_field_help.dart';
import '../widgets/editor_breadcrumbs.dart';
import '../widgets/editor_dialogs.dart';
import '../widgets/exercise_editor_intro.dart';
import '../widgets/page_block_editor.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../services/authoring_duplication_service.dart';
import '../services/exercise_draft_builder.dart';
import '../services/exercise_copy_service.dart';
import '../services/round_flow_authoring.dart';
import '../services/round_type_compatibility.dart';
import '../services/preset_examples.dart';
import '../services/preset_recipes.dart';
import '../services/preset_variants.dart';
import '../widgets/course_preview_flag.dart';
import '../services/storage/qql_storage.dart';

class ExerciseEditorScreen extends StatefulWidget {
  final Exercise exercise;
  final String title;
  final bool isNew;
  final DateTime Function()? clock;
  final bool linkParent;
  final Course? course;
  final Lesson? lesson;
  final LearningRound? round;
  final ValueChanged<Exercise>? onExerciseSaved;
  final bool readOnly;
  final bool initiallyInspecting;
  const ExerciseEditorScreen({
    super.key,
    required this.exercise,
    required this.title,
    required this.isNew,
    this.clock,
    this.linkParent = false,
    this.course,
    this.lesson,
    this.round,
    this.onExerciseSaved,
    this.readOnly = false,
    this.initiallyInspecting = false,
  });
  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  bool _dirty = false;
  bool _routeMayPop = false;
  bool _navigationBusy = false;
  late bool _inspection;
  Exercise? _savedDuringSession;

  /// Every exercise this form saved in this session, by ID.
  final Map<String, Exercise> _savedInSession = {};
  late Exercise _exercise;
  ScriptRecognitionController? _scriptController;
  late final List<Exercise> _navigationExercises;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  final List<TextEditingController> _correctTranslations = [];
  Set<int> _correctTranslationErrorIndexes = const {};
  String? _correctTranslationError;
  late String _imageAsset;
  SharedImageSource? _selectedSharedSource;
  bool _useInlineGaps = false;
  bool _revealFirstLetter = true;
  String _textRole = '';
  String _audioRole = '';
  String _matchSides = '';
  bool _useMultiSelect = false;
  // Dialogue line (Build 256 Revision 5): who speaks and how the line is
  // shown; the draft builder turns them into elements and options.
  String _speakerId = '';
  String _lineMode = 'both';
  String _lineReadAloud = 'story';
  String _lineTextReveal = 'immediate';
  String _lineLanguage = '';
  // Fill the slots (Build 256 Revision 7 follow-up): whether a word may
  // fill more than one slot.
  bool _slotReuse = false;
  // Before you start (Build 257): whether the card offers Open GuideBook.
  bool _guidebookButton = false;
  // Page (Build 258 Revision 2): the Page's blocks as the form edits them.
  List<PromptElement> _pageBlocks = const [];
  // A Flashcard's read-aloud: none, manual (on request) or automatic; the
  // spoken text is the word itself.
  String _cardReadAloud = 'manual';

  /// Read and answer's dialogue read-aloud (Build 256 Revision 7 fourth
  /// follow-up): none, manual or automatic.
  String _dialogueReadAloud = 'none';

  /// The look of picture answers (Build 263 Revision 2): `course` follows
  /// the Course's Lesson Options.
  String _pictureSize = 'course';
  String _pictureShape = 'course';
  String _picturesPerRow = 'course';
  String _pictureBorder = 'course';

  /// Editor Notes (Build 267 Revision 8): only authors read them.
  final _editorNotes = TextEditingController();

  /// The pictures marked Plural (Build 265 Revision 11), by asset or QQL
  /// icon key.
  Set<String> _pluralPictures = {};
  static String labelForType(String type) =>
      ExercisePresetRegistry.nameOrId(type);
  late String _type;
  late String _contextMode;
  late final TextEditingController _prompt,
      _question,
      _tts,
      _hint,
      _answers,
      _correct,
      _accepted,
      _tokens,
      _order,
      _gapLayout,
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
      _requiredSelections,
      _groups,
      _slots,
      _extraWords;
  @override
  void initState() {
    super.initState();
    _inspection = widget.initiallyInspecting;
    _exercise = widget.exercise;
    _loadScriptController();
    _navigationExercises = [...?widget.round?.exercises];
    final e = _exercise;
    // The preset is a recipe over canonical data (Build 256): the exercise
    // opens in the preset it carries, else in the first recipe that
    // represents it exactly, else in the plainest one of its primitive.
    _type =
        PresetRecipes.presetToEdit(e) ??
        PresetRecipes.defaultPresetFor(e.primitive) ??
        'choice_target';
    _prompt = TextEditingController();
    _question = TextEditingController();
    _tts = TextEditingController();
    _hint = TextEditingController();
    _answers = TextEditingController();
    _correct = TextEditingController();
    _requiredSelections = TextEditingController();
    _accepted = TextEditingController();
    _tokens = TextEditingController();
    _order = TextEditingController();
    _gapLayout = TextEditingController();
    _pairs = TextEditingController();
    _icons = TextEditingController();
    _missingWords = TextEditingController();
    _context = TextEditingController();
    _dialogue = TextEditingController();
    _groups = TextEditingController();
    _slots = TextEditingController();
    _extraWords = TextEditingController();
    _loadDraft(e, PresetRecipes.decompose(e, _type));
    for (final controller in [
      _prompt,
      _question,
      _tts,
      _hint,
      _answers,
      _correct,
      _accepted,
      _tokens,
      _order,
      _gapLayout,
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
      _requiredSelections,
      _groups,
      _slots,
      _extraWords,
    ]) {
      _watchText(controller);
    }
    _openedSnapshot = _formSnapshot();
    // The first time the Exercise Editor opens in a Course, a short
    // introduction explains presets and the canonical editor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ExerciseEditorIntro.showIfNeeded(
          context,
          courseId: widget.course?.courseId,
        );
      }
    });
  }

  void _loadScriptController([Exercise? from]) {
    _scriptController?.dispose();
    _scriptDirty = false;
    _scriptController = ScriptRecognitionController(from ?? _exercise)
      ..addListener(() {
        _scriptDirty = true;
        _markDirty();
      });
  }

  void _watchText(TextEditingController controller) {
    var previousText = controller.text;
    controller.addListener(() {
      if (controller.text == previousText) return;
      previousText = controller.text;
      _markDirty();
    });
  }

  TextEditingController _translationController(String text) {
    final controller = TextEditingController(text: text);
    _watchText(controller);
    return controller;
  }

  void _markDirty() {
    if (!widget.readOnly &&
        mounted &&
        (!_dirty ||
            _correctTranslationError != null ||
            _correctTranslationErrorIndexes.isNotEmpty)) {
      setState(() {
        _dirty = true;
        _correctTranslationError = null;
        _correctTranslationErrorIndexes = const {};
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _prompt,
      _question,
      _tts,
      _hint,
      _answers,
      _correct,
      _accepted,
      _tokens,
      _order,
      _gapLayout,
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
      _requiredSelections,
      _groups,
      _slots,
      _extraWords,
    ]) {
      c.dispose();
    }
    for (final controller in _correctTranslations) {
      controller.dispose();
    }
    // Script fields keep their own stable option identities and controllers.
    _scriptController?.dispose();
    super.dispose();
  }

  void _addCorrectTranslation() {
    if (widget.readOnly) return;
    final controller = _translationController('');
    setState(() {
      _correctTranslations.add(controller);
      _dirty = true;
      _correctTranslationError = null;
      _correctTranslationErrorIndexes = const {};
    });
  }

  void _removeCorrectTranslation(int index) {
    if (widget.readOnly) return;
    if (_correctTranslations.length == 1) {
      _correctTranslations.single.clear();
      return;
    }
    setState(() {
      _correctTranslations.removeAt(index).dispose();
      _dirty = true;
      _correctTranslationError = null;
      _correctTranslationErrorIndexes = const {};
    });
  }

  void _reorderCorrectTranslations(int oldIndex, int newIndex) {
    if (widget.readOnly) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final controller = _correctTranslations.removeAt(oldIndex);
      _correctTranslations.insert(newIndex, controller);
      _dirty = true;
      _correctTranslationError = null;
      _correctTranslationErrorIndexes = const {};
    });
  }

  /// The words for true and false in the Course's source language when QQL
  /// knows it (the eight copy languages), else in English.
  List<String> _trueFalseAnswers() {
    final course = widget.course;
    final code = course == null
        ? ''
        : (CourseLanguageResolver.base(course).code ?? '')
              .split('-')
              .first
              .toLowerCase();
    return switch (code) {
      'it' => const ['Vero', 'Falso'],
      'es' => const ['Verdadero', 'Falso'],
      'de' => const ['Richtig', 'Falsch'],
      'pt' => const ['Verdadeiro', 'Falso'],
      'nl' => const ['Waar', 'Onwaar'],
      'fi' => const ['Totta', 'Tarua'],
      'cy' => const ['Cywir', 'Anghywir'],
      _ => const ['True', 'False'],
    };
  }

  List<String> _answerLines() => _answers.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  /// One picture per answer (Select the image, Listen and pick the image,
  /// Match pictures to words): `_icons` holds one line per answer, in the
  /// answers' order, a picture reference or a named icon key. The cards
  /// follow the answers as they are typed (owner report, 29 September
  /// 2026: the form rebuilt only on its first change, so a word typed
  /// later had no card and no number), one compact picture card per
  /// answer, headed by its number and text.
  Widget _answerPictures({
    String title = 'Pictures',
  }) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: _answers,
    builder: (context, value, child) {
      final answers = _answerLines();
      final lines = _icons.text.split('\n');
      String lineAt(int index) =>
          index < lines.length ? lines[index].trim() : '';
      return Column(
        key: const Key('answer-pictures'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (answers.isEmpty)
            const Text(
              'Enter the answers above first; each gets a picture here.',
            )
          else ...[
            Text(
              'One card per answer, in the order above. Choose flat image takes a picture from the Shared Image Library; Import custom image reads the one picture file in ${QqlStorageLayout.current.folderLabel(QqlStorageRole.imageImports)}.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < answers.length; i++)
              ExerciseImageField(
                key: ValueKey('answer-picture-$i'),
                title: '${i + 1}. ${answers[i]}',
                compact: true,
                // Build 263 Revision 2: a square crop of the picture.
                cropSquare: true,
                cropButtonKey: ValueKey('answer-picture-crop-$i'),
                course: widget.course,
                asset: PresetVariants.isImageReference(lineAt(i))
                    ? lineAt(i)
                    : '',
                sharedSource: null,
                readOnly: widget.readOnly,
                // Build 265 Revision 11: the answer's picture as several.
                plural: _pluralPictures.contains(lineAt(i)),
                pluralKey: ValueKey('answer-picture-plural-$i'),
                onPluralChanged: (plural) => setState(() {
                  _markPlural(lineAt(i), plural);
                  _dirty = true;
                }),
                onChanged: (change) => setState(() {
                  _movePlural(lineAt(i), change.asset);
                  _setIconLine(i, change.asset, answers.length);
                  _dirty = true;
                }),
              ),
          ],
          const SizedBox(height: 12),
        ],
      );
    },
  );

  /// The look of the picture answers (Build 263 Revision 2, owner decisions
  /// of 4 October 2026): size, shape and pictures per row, each following
  /// the Course's Lesson Options unless the exercise chooses its own.
  List<Widget> _pictureLookFields() {
    final course = widget.course?.pictureAnswers ?? PictureAnswerStyle.standard;
    String asCourse(String value) => 'As in Lesson Options ($value)';
    String sizeName(PictureSize size) =>
        size == PictureSize.large ? 'Large' : 'Normal';
    String shapeName(PictureShape shape) =>
        shape == PictureShape.square ? 'Square, cropped' : 'Round';
    String perRowName(PicturesPerRow perRow) =>
        '${PictureAnswerStyle(perRow: perRow).perRowCount ?? 'As many as fit'}';
    String borderName(PictureBorder border) =>
        border == PictureBorder.thin ? 'Thin grey line' : 'None';
    return [
      Text('Picture answers', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _choiceField(
        fieldKey: 'pictureSize',
        label: 'Picture size',
        value: _pictureSize,
        choices: {
          'course': asCourse(sizeName(course.size)),
          'large': sizeName(PictureSize.large),
          'normal': sizeName(PictureSize.normal),
        },
        onChanged: (value) => _pictureSize = value,
      ),
      _choiceField(
        fieldKey: 'pictureShape',
        label: 'Picture shape',
        value: _pictureShape,
        choices: {
          'course': asCourse(shapeName(course.shape)),
          'square': shapeName(PictureShape.square),
          'round': shapeName(PictureShape.round),
        },
        helper:
            'A square shows the picture cropped to a square: Crop square on '
            'each picture chooses the part and the zoom.',
        onChanged: (value) => _pictureShape = value,
      ),
      _choiceField(
        fieldKey: 'picturesPerRow',
        label: 'Pictures per row',
        value: _picturesPerRow,
        choices: {
          'course': asCourse(perRowName(course.perRow)),
          for (final perRow in [
            PicturesPerRow.one,
            PicturesPerRow.two,
            PicturesPerRow.three,
            PicturesPerRow.automatic,
          ])
            perRow.serialized: perRowName(perRow),
        },
        onChanged: (value) => _picturesPerRow = value,
      ),
      _choiceField(
        fieldKey: 'pictureBorder',
        label: 'Picture border',
        value: _pictureBorder,
        choices: {
          'course': asCourse(borderName(course.border)),
          'thin': borderName(PictureBorder.thin),
          'none': borderName(PictureBorder.none),
        },
        onChanged: (value) => _pictureBorder = value,
      ),
    ];
  }

  /// The spelling forms' optional Extra blocks and, when there are some,
  /// a note that they are distractors (Build 265 Revision 11, owner
  /// decision of 7 October 2026).
  List<Widget> _spellingExtraBlocks() => [
    _field(
      _extraWords,
      'Extra blocks (optional)',
      lines: 2,
      helper:
          'Letters or syllables that are not in the word; the learner must leave them out.',
    ),
    ValueListenableBuilder<TextEditingValue>(
      valueListenable: _extraWords,
      builder: (context, value, child) => value.text.trim().isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                key: const Key('spelling-extra-blocks-note'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Extra blocks are distractors: only the blocks of the word are recommended. Use them deliberately, fewer in a Lesson\'s first Rounds; Course Audit lists them as Info.',
                    ),
                  ),
                ],
              ),
            ),
    ),
  ];

  /// Marks [picture] Plural or not (Build 265 Revision 11).
  void _markPlural(String picture, bool plural) {
    if (picture.isEmpty) return;
    plural ? _pluralPictures.add(picture) : _pluralPictures.remove(picture);
  }

  /// A replaced picture hands its Plural mark to the new one.
  void _movePlural(String from, String to) {
    if (from == to || !_pluralPictures.remove(from)) return;
    if (to.isNotEmpty) _pluralPictures.add(to);
  }

  void _setIconLine(int index, String value, int count) {
    final lines = _icons.text.split('\n');
    while (lines.length < count) {
      lines.add('');
    }
    lines[index] = value;
    _icons.text = lines.take(count).join('\n');
  }

  /// Match pictures to words keeps its pairs as words (`_answers`) and
  /// pictures (`_icons`) in the form and as `picture = word` lines in the
  /// draft.
  String _picturePairsText() {
    final answers = _answerLines();
    final lines = _icons.text.split('\n');
    return [
      for (var i = 0; i < answers.length; i++)
        '${i < lines.length ? lines[i].trim() : ''} = ${answers[i]}',
    ].join('\n');
  }

  void _splitPicturePairs(String pairs) {
    final pictures = <String>[];
    final words = <String>[];
    for (final line in pairs.split('\n')) {
      final separator = line.indexOf('=');
      if (separator < 0) continue;
      pictures.add(line.substring(0, separator).trim());
      words.add(line.substring(separator + 1).trim());
    }
    _icons.text = pictures.join('\n');
    _answers.text = words.join('\n');
  }

  Widget _correctTranslationsEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Correct translations',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 4),
      const Text(
        'Each entry is one complete literal target-language sentence. Answer syntax and similarity matching are not used.',
      ),
      const SizedBox(height: 8),
      if (widget.readOnly)
        Column(
          key: const Key('build-translation-correct-translations'),
          children: [
            for (var index = 0; index < _correctTranslations.length; index++)
              _correctTranslationRow(index, reorderable: false),
          ],
        )
      else
        ReorderableListView.builder(
          key: const Key('build-translation-correct-translations'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _correctTranslations.length,
          onReorderItem: _reorderCorrectTranslations,
          itemBuilder: (context, index) =>
              _correctTranslationRow(index, reorderable: true),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('add-correct-translation'),
          onPressed: widget.readOnly ? null : _addCorrectTranslation,
          icon: const Icon(Icons.add),
          label: const Text('Add correct translation'),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _correctTranslationRow(int index, {required bool reorderable}) =>
      Padding(
        key: ValueKey(_correctTranslations[index]),
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('build-translation-answer-$index'),
                controller: _correctTranslations[index],
                readOnly: widget.readOnly,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Correct translation ${index + 1}',
                  suffixIcon: _helpButton('correctTranslation'),
                  errorText: _correctTranslationErrorIndexes.contains(index)
                      ? _correctTranslationError
                      : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Delete correct translation ${index + 1}',
              onPressed: widget.readOnly
                  ? null
                  : () => _removeCorrectTranslation(index),
              icon: const Icon(Icons.delete_outline),
            ),
            if (reorderable)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
      );

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Reconstructs the author-facing "Sentence with gaps" template (fixed
  /// text plus one `_answer_` block per inline gap, with the literal answer
  /// text between the underscores) from an existing Arrange exercise's
  /// layout, for display when reopening it in the Editor.
  String _fieldKey(TextEditingController controller) => {
    _prompt: 'prompt',
    _question: 'question',
    _tts: 'tts',
    _hint: 'hint',
    _answers: 'answers',
    _correct: 'correct',
    _accepted: 'accepted',
    _tokens: 'tokens',
    _order: 'order',
    _gapLayout: 'gapLayout',
    _pairs: 'pairs',
    _icons: 'icons',
    _missingWords: 'missingWords',
    _context: 'context',
    _dialogue: 'dialogue',
    _requiredSelections: 'requiredSelections',
    _groups: 'groups',
    _slots: 'slots',
    _extraWords: 'extraWords',
  }[controller]!;

  Future<void> _showFieldHelp(String fieldKey, {String? title}) {
    final help = ExerciseFieldHelpRegistry.forEditorField(_type, fieldKey);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? help.title),
        content: SingleChildScrollView(child: Text(help.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// A closed choice among a few values (Build 256 Revision 5, the Dialogue
  /// line form), with the same Help control as a text field. The value is
  /// part of the inner key so a form reload shows the reloaded value.
  Widget _choiceField({
    required String fieldKey,
    required String label,
    required String value,
    required Map<String, String> choices,
    required ValueChanged<String> onChanged,
    String? helper,
  }) => Padding(
    key: ValueKey('exercise-choice-$fieldKey'),
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey('exercise-choice-$fieldKey-$value'),
      initialValue: choices.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        suffixIcon: _helpButton(fieldKey),
        helperText: helper,
        helperMaxLines: 3,
        filled: widget.readOnly,
        fillColor: widget.readOnly
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : null,
      ),
      items: [
        for (final entry in choices.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: widget.readOnly
          ? null
          : (selected) {
              if (selected == null) return;
              setState(() {
                onChanged(selected);
                _dirty = true;
              });
            },
    ),
  );

  /// A new single-answer Choose starts with answer 1 marked as correct
  /// (owner request, 29 September 2026), as Pick the translation did; a
  /// stored exercise shows what it has.
  String _initialCorrect(Exercise e, ExerciseDraftValues draft) =>
      widget.isNew &&
          draft.correct.trim().isEmpty &&
          e.primitive == ExercisePrimitive.select &&
          !draft.useMultiSelect &&
          !draft.useInlineGaps &&
          PresetVariants.formFor(_type) != 'script_recognition'
      ? '1'
      : draft.correct;

  /// Puts [draft], [e] decomposed in the current preset, into the form's
  /// fields: the form opening, Previous and Next, Fill with an example and
  /// Clear all share it (Build 263 Revision 1).
  void _loadDraft(Exercise e, ExerciseDraftValues draft) {
    _editorNotes.text = e.editorNotes;
    _prompt.text = draft.prompt;
    _question.text = draft.question;
    _tts.text = draft.tts;
    _hint.text = draft.hint;
    _answers.text = draft.answers;
    _useMultiSelect = draft.useMultiSelect;
    _correct.text = _initialCorrect(e, draft);
    _requiredSelections.text = draft.requiredSelections;
    _accepted.text = draft.accepted;
    _useInlineGaps = draft.useInlineGaps;
    _revealFirstLetter = draft.revealFirstLetter;
    _textRole = draft.textRole;
    _audioRole = draft.audioRole;
    _matchSides = draft.matchSides;
    _readLineFields(draft);
    _slotReuse = draft.slotReuse;
    _guidebookButton = draft.guidebookButton;
    _pageBlocks = draft.pageBlocks;
    _cardReadAloud = draft.cardReadAloud;
    _dialogueReadAloud = draft.dialogueReadAloud;
    _pictureSize = draft.pictureSize;
    _pictureShape = draft.pictureShape;
    _picturesPerRow = draft.picturesPerRow;
    _pictureBorder = draft.pictureBorder;
    _pluralPictures = {...draft.pluralPictures};
    _tokens.text = draft.tokens;
    _order.text = draft.order;
    _gapLayout.text = draft.gapLayout;
    for (final controller in _correctTranslations) {
      controller.dispose();
    }
    _correctTranslations.clear();
    for (final text in draft.correctTranslations) {
      _correctTranslations.add(_translationController(text));
    }
    _correctTranslationError = null;
    _correctTranslationErrorIndexes = const {};
    _pairs.text = draft.pairs;
    _icons.text = draft.icons;
    if (_type == 'picture_word_match') _splitPicturePairs(draft.pairs);
    _missingWords.text = draft.missingWords;
    _context.text = draft.context;
    _dialogue.text = draft.dialogue;
    _groups.text = draft.groups;
    _slots.text = draft.slots;
    _extraWords.text = draft.extraWords;
    _contextMode = draft.contextMode;
    _imageAsset = draft.imageAsset;
    _selectedSharedSource = draft.selectedSharedSource;
  }

  void _readLineFields(ExerciseDraftValues draft) {
    _speakerId = draft.speakerId;
    _lineMode = draft.lineMode;
    _lineReadAloud = draft.lineReadAloud;
    _lineTextReveal = draft.lineTextReveal;
    _lineLanguage = draft.lineLanguage;
  }

  Widget _helpButton(String fieldKey) => IconButton(
    key: ValueKey('exercise-field-help-$fieldKey'),
    tooltip: ExerciseFieldHelpRegistry.forEditorField(_type, fieldKey).purpose,
    onPressed: () => _showFieldHelp(fieldKey),
    icon: const Icon(Icons.help_outline),
  );

  /// A preset form's optional Instruction or context (Build 259, owner
  /// decisions of 29 September 2026): written in the learners' language and
  /// stored without a language, it takes the place of the standard line the
  /// learner sees under the exercise heading. The helper quotes that line.
  Widget _instructionField({TextEditingController? controller}) {
    final standard = _standardInstruction();
    return _field(
      controller ?? _prompt,
      'Instruction or context (optional)',
      lines: 2,
      helper: standard == null
          ? 'In the learners’ language. The learner sees it instead of the standard instruction.'
          : 'In the learners’ language. The learner sees it instead of the standard line “$standard”',
    );
  }

  /// The standard instruction the learner sees for this preset, in the
  /// Course's source language; null without a Course.
  String? _standardInstruction() {
    final course = widget.course;
    final kind = PresetRecipes.kinds[_type]?.firstOrNull;
    if (course == null || kind == null) return null;
    // Listen and choose always gets its own listening line (Build 259
    // Revision 3).
    final variant = switch (_type) {
      'listening_choose_target' => 'selectListenHeard',
      'listening_choose_source' => 'selectListenMeaning',
      _ => null,
    };
    return variant == null
        ? ExerciseCopyService.instruction(course, kind)
        : ExerciseCopyService.instructionVariant(course, variant, kind);
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: ValueKey('exercise-field-${_fieldKey(c)}'),
      controller: c,
      readOnly: widget.readOnly,
      minLines: lines,
      maxLines: lines == 1 ? 3 : lines + 4,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        suffixIcon: _helpButton(_fieldKey(c)),
        helperText: helper,
        helperMaxLines: 3,
        filled: widget.readOnly,
        fillColor: widget.readOnly
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : null,
      ),
    ),
  );

  Future<void> _showTypeTranslationHelp() =>
      _showFieldHelp('accepted', title: 'Type the translation · answer syntax');

  Future<void> _expandTranslationAnswers() async {
    if (widget.readOnly) return;
    try {
      final expressions = _lines(_accepted);
      final normalization = ExerciseFeatures(_exercise).normalization;
      final expanded = AnswerMaterializationService.expand(
        expressions,
        normalization: normalization,
      );
      final use = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${expanded.length} answers generated'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: SelectableText(expanded.join('\n')),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: expanded.join('\n'))),
              child: const Text('Copy all'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Use expanded answers'),
            ),
          ],
        ),
      );
      if (use != true || !mounted) return;
      final result = AnswerMaterializationService.materialize(
        expressions: expressions,
        existing: _lines(_accepted),
        normalization: normalization,
      );
      _accepted.text = result.answers.join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.generated} answers generated; ${result.added} added; ${result.alreadyPresent} already present.',
          ),
        ),
      );
    } on AnswerExpressionException catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot expand answers'),
          content: Text(
            error.message.contains('128')
                ? 'This expression generates more than 128 answers. Simplify it before expanding.'
                : error.message,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> _specificFields() {
    switch (PresetVariants.formFor(_type)) {
      case 'script_recognition':
        return [
          ScriptRecognitionEditor(
            controller: _scriptController!,
            readOnly: widget.readOnly,
          ),
        ];
      case 'flashcard':
        // Build 256 Revision 7 follow-up (owner review): the languages of
        // the two texts are named, the read-aloud speaks the word itself
        // and is chosen here instead of typed again.
        return [
          _field(
            _prompt,
            'Word or expression (target language)',
            helper:
                'In the language being learned, e.g. buongiorno. Read aloud, when on, speaks this text.',
          ),
          _field(
            _question,
            'Translation or meaning (source language)',
            helper: 'In the learners’ own language, e.g. good morning.',
          ),
          _choiceField(
            fieldKey: 'readAloud',
            label: 'Read aloud',
            value: _cardReadAloud,
            choices: const {
              'automatic': 'Automatically, when the card appears',
              'manual': 'On request (speaker button)',
              'none': 'No read-aloud',
            },
            onChanged: (value) => _cardReadAloud = value,
            helper:
                'The word or expression above is spoken with the Course audio mode, unless the field below says otherwise. Read-aloud never makes the card an audio exercise.',
          ),
          _field(
            _tts,
            'Pronunciation TTS (if different)',
            helper:
                'Leave empty to read the word or expression above. Enter a text only when what is spoken should differ, e.g. an abbreviation read in full.',
          ),
          _field(
            _answers,
            'Usage sentence and optional translation',
            lines: 3,
            helper:
                'First line: a sentence using the word (target language). Second line, optional: its translation. “Usage:” is added automatically in learner mode.',
          ),
        ];
      case 'one_word_fills_all':
        // One word fills all (Build 259 Revision 4): the sentences hold two
        // or more ___ gaps that one answer fills. Build 260 Revision 3: an
        // optional Instruction or context, as Pick the missing word.
        return [
          _instructionField(),
          _field(
            _question,
            'Sentences, with ___ for each gap',
            lines: 3,
            helper:
                'In the target language, with ___ (3 underscores) wherever the same word fits; at least two gaps. Example: ___ gatto dorme. ___ cane mangia.',
          ),
          _field(
            _answers,
            'Answer words',
            lines: 4,
            helper:
                'Only one word may fit every gap; the others should fail at least one.',
          ),
          _field(_correct, 'Correct answer number'),
          _field(
            _hint,
            'Hint (optional)',
            helper: 'Give a clue without naming the word.',
          ),
        ];
      case 'gap_choice':
        // Build 260 Revision 3 (owner decision): an optional Instruction or
        // context, such as the meaning a short phrase needs.
        return [
          _instructionField(),
          _field(
            _question,
            'Sentence',
            lines: 3,
            helper:
                'In the target language, with ___ (3 underscores) for the missing word. Example: The cat ___ black.',
          ),
          _field(
            _answers,
            'Answer blocks',
            lines: 4,
            helper:
                'Use plausible options, but make sure only one answer is correct in both meaning and grammar.',
          ),
          _field(_correct, 'Correct answer number'),
          _field(
            _hint,
            'Hint (optional)',
            helper:
                'Give a clue without repeating the correct missing word or expression.',
          ),
        ];
      case 'fill_blank':
        return [
          _field(_question, 'Incomplete word / phrase', lines: 2),
          _field(_accepted, 'Accepted answers', lines: 3),
          _field(_hint, 'Hint'),
          _field(_tts, 'Complete phrase TTS (optional)'),
        ];
      case 'type_translation':
        return [
          _field(
            _prompt,
            'Sentence',
            lines: 3,
            helper: _type.endsWith('_to_source')
                ? 'In the target language: the text the learner translates into the source language.'
                : 'In the source language: the text the learner translates into the target language.',
          ),
          _field(
            _accepted,
            'Accepted translations',
            lines: 5,
            helper:
                'One complete equivalent answer per line. Optional {...}, alternatives [a|b], and scoped reorder (a <> b) syntax are supported.',
          ),
          const Text('Use lowercase except for proper names.'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('expand-translation-answers'),
              onPressed: widget.readOnly ? null : _expandTranslationAnswers,
              icon: const Icon(Icons.unfold_more),
              label: const Text('Expand answers'),
            ),
          ),
          const Text(
            'Expansion is read-only until you choose Use expanded answers. Added lines are independent: editing or deleting the expression does not change them.',
          ),
          ListTile(
            key: const Key('type-translation-answer-help'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: const Text('Answer syntax help'),
            subtitle: const Text(
              'Optional text, alternatives, reorder scopes, punctuation, capitalization and limits.',
            ),
            onTap: _showTypeTranslationHelp,
          ),
          _field(_hint, 'Hint (optional)'),
        ];
      case 'type_missing_word':
        return [
          SwitchListTile(
            key: const Key('type-missing-word-reveal'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Show the first letter'),
            subtitle: const Text(
              'On: the gap reveals the first letter of the word as a hint. Off: the learner types the whole word without help.',
            ),
            value: _revealFirstLetter,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _revealFirstLetter = value;
                    _dirty = true;
                  }),
          ),
          _field(
            _prompt,
            'Sentence',
            lines: 3,
            helper:
                'In the target language, with one ___ gap for the word. The first letter, when shown, is derived automatically from the complete accepted word.',
          ),
          // The same-first-letter rule holds only while the first letter is
          // shown (owner, 29 September 2026): off, the accepted words may
          // start with different letters.
          _field(
            _accepted,
            'Complete accepted words',
            lines: 3,
            helper: _revealFirstLetter
                ? 'One complete word per line. With the first letter shown, all answers must start with the same letter (Unicode grapheme).'
                : 'One complete word per line. They may start with different letters.',
          ),
          _field(_hint, 'Hint (optional)'),
          Text(
            _revealFirstLetter
                ? 'Enter the complete missing word. The first letter shown is a hint. Example: é______ → école, not cole.'
                : 'Enter the complete missing word. The learner types it without a hint.',
          ),
        ];
      case 'build_translation':
        return [
          _field(
            _prompt,
            'Sentence',
            lines: 3,
            helper: _type.endsWith('_to_source')
                ? 'In the target language: the complete sentence the learner translates into the source language.'
                : 'In the source language: the complete sentence the learner translates into the target language.',
          ),
          _field(
            _tokens,
            _type.endsWith('_to_source')
                ? 'Available source-language blocks'
                : 'Available target-language blocks',
            lines: 5,
            helper:
                'One literal block per line. Include enough occurrences to construct every correct translation; repeated words need separate blocks.',
          ),
          _correctTranslationsEditor(),
        ];
      case 'word_order':
        return [
          _instructionField(),
          _field(
            _tokens,
            'Available word blocks',
            lines: 4,
            helper:
                'One block per line. You may include 0, 1 or at most 2 extra distractors.',
          ),
          _field(
            _order,
            'Correct sentence',
            lines: 4,
            helper:
                'One block per line in the required order. Exercise type cannot be changed after creation.',
          ),
        ];
      case 'image_word':
        // The blocks of the word in order (Build 256 Revision 7 follow-up,
        // owner review) and, since Build 265 Revision 11, optional Extra
        // blocks with a note (owner decision of 7 October 2026).
        return [
          _instructionField(),
          _field(
            _order,
            'Blocks of the word, in order',
            lines: 5,
            helper:
                'At least two blocks: one letter or syllable per line, in the right order; the learner gets these blocks, shuffled. An image is required.',
          ),
          ..._spellingExtraBlocks(),
        ];
      case 'matching':
        return [
          _field(_prompt, 'Instruction', lines: 2),
          _field(
            _pairs,
            'Pairs',
            lines: 5,
            helper: 'One pair per line: left = right',
          ),
        ];
      case 'word_match':
        return [
          _instructionField(),
          _field(
            _pairs,
            'Translation pairs',
            lines: 5,
            helper:
                'At least two lines: source = target. Three is the usual number.',
          ),
        ];
      case 'super_match':
        return [
          _instructionField(),
          _field(
            _pairs,
            'Three target-language pairs',
            lines: 5,
            helper: 'Exactly three lines: left = right',
          ),
        ];
      case 'audio_match':
        return [
          _instructionField(),
          _field(
            _pairs,
            'Three sound matches',
            lines: 5,
            helper:
                'target audio text = matching visible text. The visible text may be target-language text or its translation. No distractors.',
          ),
        ];
      case 'icon_choice':
        return [
          _field(
            _question,
            'Question or sentence',
            lines: 2,
            helper: 'It names what the learner looks for, e.g. Select ‘gatto’.',
          ),
          _field(_answers, 'Target-language options', lines: 4),
          _field(_correct, 'Correct answer number'),
          _answerPictures(),
          ..._pictureLookFields(),
          _field(
            _icons,
            'Icons / image keys',
            lines: 4,
            helper:
                'One per answer, in the same order. Left empty, the answers are plain text and the exercise plays as Choose the answer.',
          ),
        ];
      case 'listening_choose_target':
      case 'listening_choose_source':
      case 'listening_choice':
      case 'listening_comprehension':
        // Listen and choose has no question, only an optional Instruction or
        // context; Listen and answer's question is required (Build 259
        // Revision 2).
        final listeningChoose = _type.startsWith('listening_choose');
        return [
          _field(
            _tts,
            'Spoken text',
            lines: 2,
            helper: switch (widget.course?.audioMode) {
              'recorded' =>
                'Recorded MP3: QQL matches this text to this Course’s Audio Library recordings.',
              'hybrid' =>
                'Hybrid: QQL tries this Course’s MP3 recordings, then native TTS if a complete sequence is unavailable.',
              _ => 'QQL reads this text aloud using the device’s native TTS.',
            },
          ),
          Text(
            'MP3: open Course Editor > Audio Library. Copy MP3 files to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}, press Quick Import, then Associate recording with its Word or expression. Choose Recorded MP3 only or Hybrid. This exercise uses those text mappings.',
          ),
          const SizedBox(height: 12),
          if (listeningChoose)
            _instructionField()
          else
            _field(
              _question,
              'Question',
              lines: 2,
              helper:
                  'What the learner answers about what they hear, e.g. Dove fa la spesa Maria? To ask only what was heard, use Listen and choose.',
            ),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'reading_comprehension':
        // Read and answer (Build 256 Revision 7 fourth follow-up; owner
        // decisions of 29 September 2026): the text explains the situation
        // in the source language and is never read aloud; the dialogue is in
        // the target language and may be read aloud line by line.
        return [
          _field(
            _prompt,
            'Text to read (source language)',
            lines: 5,
            helper:
                'In the learners’ own language: the situation or the explanation the dialogue needs. It is never read aloud.',
          ),
          _field(
            _dialogue,
            'Dialogue lines (optional)',
            lines: 4,
            helper:
                'One line per turn as Speaker: text, in the target language.',
          ),
          _choiceField(
            fieldKey: 'dialogueReadAloud',
            label: 'Read the dialogue aloud',
            value: _dialogueReadAloud,
            choices: const {
              'automatic': 'Automatically, line by line',
              'manual': 'On request (Play dialogue button)',
              'none': 'No read-aloud',
            },
            onChanged: (value) => _dialogueReadAloud = value,
            helper:
                'Each line is spoken in turn with a short pause. Read-aloud never makes this an audio exercise.',
          ),
          _field(
            _question,
            'Question',
            lines: 2,
            helper: 'In the target language.',
          ),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'listening_spelling':
        return [
          _instructionField(),
          _field(_tts, 'Audio text', lines: 5),
          // The Audio text is always accepted (Build 259 Revision 3): this
          // box holds only other ways to write it.
          _field(
            _missingWords,
            'Other accepted spellings (optional)',
            lines: 2,
            helper:
                'The Audio text is always accepted. Add a line only for another way to write the same thing, e.g. alle 9 for alle nove.',
          ),
        ];
      case 'missing_word':
        return [
          _field(
            _prompt,
            'Passage transcript',
            lines: 5,
            helper:
                'Enter the complete text exactly as the learner should hear it.',
          ),
          _field(
            _tts,
            'Audio text',
            lines: 5,
            helper:
                'Usually the same as the transcript. Recorded MP3 or Hybrid audio can be used.',
          ),
          _field(
            _missingWords,
            'Missing word(s)',
            lines: 3,
            helper:
                'One word or expression per line. Each must occur in the passage.',
          ),
        ];
      case 'translation_choice_to_target':
      case 'translation_choice_to_source':
        final toTarget = _type == 'translation_choice_to_target';
        return [
          _field(
            _question,
            'Sentence',
            lines: 2,
            helper: toTarget
                ? 'One word, phrase or sentence in the course source '
                      'language. Do not write an instruction: QQL shows '
                      '“Choose the correct [Target language] translation” '
                      'automatically.'
                : 'One word, phrase or sentence in the course target '
                      'language. The learner can play it with '
                      'text-to-speech when available. Do not write an '
                      'instruction: QQL shows “Choose the correct [Source '
                      'language] translation” automatically.',
          ),
          _field(
            _answers,
            'Answer options',
            lines: 4,
            helper: toTarget
                ? 'One complete target-language translation per line, from 2 '
                      'to 5 options, each a different phrase. Blank lines '
                      'are ignored. The learner sees the options in random '
                      'order.'
                : 'One complete source-language translation per line, from 2 '
                      'to 5 options, each a different phrase. Blank lines '
                      'are ignored. The learner sees the options in random '
                      'order.',
          ),
          _field(
            _correct,
            'Correct answer number',
            helper:
                'Number of the correct option, counting non-empty lines '
                'from 1.',
          ),
        ];
      case 'true_false':
        return [
          _field(
            _question,
            'Sentence',
            lines: 2,
            helper: 'A sentence in the target language that is true or false.',
          ),
          _field(
            _tts,
            'Spoken statement (optional)',
            lines: 2,
            helper:
                'Read aloud with the target-language voice when audio is on.',
          ),
          _field(
            _answers,
            'Answers',
            lines: 2,
            helper:
                'Two lines in the source language: the word for true, then the word for false.',
          ),
          _field(
            _correct,
            'Correct answer number',
            helper: '1 when the statement is true, 2 when it is false.',
          ),
        ];
      case 'complete_text':
        // Build 259 Revision 1: an Instruction or context (the form's
        // question value) and a hint.
        return [
          _instructionField(controller: _question),
          // Build 259 Revision 3: ___ marks each gap; a line may accept
          // several answers.
          _field(
            _prompt,
            'Text, with ___ for each gap',
            lines: 5,
            helper:
                'Write ___ (three underscores) where each missing word or phrase goes.',
          ),
          _field(
            _missingWords,
            'Missing words',
            lines: 4,
            helper:
                'One line per gap, in order. [il|un] gatto accepts both il gatto and un gatto.',
          ),
          _field(
            _hint,
            'Hint (optional)',
            helper:
                'A clue shown under the text; it must not give the words away.',
          ),
        ];
      case 'missing_letters':
        return [
          _field(
            _prompt,
            'Text with the missing letters between underscores',
            lines: 4,
            helper:
                'Write the complete text and put the missing letters between underscores: My cat doesn\'t dr_ink_ milk. The learner sees dr___ milk and types ink.',
          ),
          _field(
            _tts,
            'Spoken text (optional)',
            lines: 2,
            helper:
                'The complete text, read aloud as an aid. A learner with audio off gets the exercise without it.',
          ),
          _field(_hint, 'Hint (optional)'),
        ];
      case 'gap_blocks':
        return [
          _instructionField(),
          _field(
            _gapLayout,
            'Sentence with gaps',
            lines: 3,
            helper:
                'Write the fixed sentence and put each answer word or phrase between underscores: _answer_. Each word fills one gap. Example: Io _vorrei_ un caffè.',
          ),
          _field(
            _tokens,
            'Extra distractor words (optional)',
            lines: 3,
            helper:
                'One extra word per line that fills no gap. Include 0, 1 or at most 2 distractors.',
          ),
          _field(
            _tts,
            'Spoken prompt (optional)',
            lines: 2,
            helper: 'Optional audio played before the learner fills the gaps.',
          ),
        ];
      case 'sentence_order':
        // Build 259 Revision 1: the lines are entered once, in order.
        return [
          _instructionField(),
          _field(
            _order,
            'Lines, in the correct order',
            lines: 6,
            helper:
                'One line per line, in the order the learner must find. They are shuffled for the learner.',
          ),
          _field(
            _extraWords,
            'Extra lines (optional)',
            lines: 2,
            helper: 'Lines that belong nowhere: 0, 1 or at most 2.',
          ),
          _field(
            _hint,
            'Hint (optional)',
            helper:
                'A clue shown above the lines; it must not give the order away.',
          ),
        ];
      case 'listening_image_choice':
        return [
          _field(
            _tts,
            'Spoken text',
            lines: 2,
            helper: 'The word or sentence the learner hears.',
          ),
          _instructionField(),
          _field(
            _answers,
            'Answers',
            lines: 4,
            helper: 'One per line; each answer gets a picture below.',
          ),
          _field(_correct, 'Correct answer number'),
          _answerPictures(),
          ..._pictureLookFields(),
        ];
      case 'spell_heard':
        return [
          _field(
            _tts,
            'Spoken word',
            helper: 'The word the learner hears and spells.',
          ),
          _field(
            _order,
            'Blocks of the word, in order',
            lines: 5,
            helper:
                'At least two blocks: one letter or syllable per line, in the right order; the learner gets these blocks, shuffled.',
          ),
          ..._spellingExtraBlocks(),
        ];
      case 'picture_choice':
        return [
          _instructionField(),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'picture_name':
        return [
          _instructionField(),
          _field(
            _accepted,
            'Accepted answers',
            lines: 4,
            helper:
                'One complete answer per line. Optional {...}, alternatives [a|b] and scoped reorder (a <> b) are supported.',
          ),
          const Text('Use lowercase except for proper names.'),
          const SizedBox(height: 8),
          _field(_hint, 'Hint (optional)'),
        ];
      case 'picture_blocks':
        // Name what you see (Revision 7 fourth follow-up): the picture is
        // the Exercise image below; the name is built from word blocks.
        return [
          _instructionField(),
          _field(
            _order,
            'Blocks of the name, in order',
            lines: 4,
            helper:
                'One word per line, in the right order; the learner builds the name from these blocks, shuffled. An image is required.',
          ),
          _field(
            _extraWords,
            'Extra blocks (optional)',
            lines: 2,
            helper:
                'At most two words that are not part of the name; the learner must leave them out.',
          ),
          _field(_hint, 'Hint (optional)'),
        ];
      case 'spell_word':
        return [
          _field(
            _prompt,
            'Clue (source language)',
            lines: 2,
            helper:
                'The word or a definition in the source language, e.g. cat (the animal).',
          ),
          _field(
            _order,
            'Blocks of the word, in order',
            lines: 5,
            helper:
                'At least two blocks: one letter or syllable per line, in the right order; the learner gets these blocks, shuffled.',
          ),
          ..._spellingExtraBlocks(),
        ];
      case 'picture_word_match':
        return [
          _instructionField(),
          _field(
            _answers,
            'Words',
            lines: 4,
            helper:
                'One word per line, at least two. The pictures below follow this order: the first picture goes with the first word, and so on.',
          ),
          _answerPictures(title: 'Pictures, in the order of the words'),
        ];
      case 'sort_into_groups':
        return [
          _instructionField(),
          _field(
            _groups,
            'Groups',
            lines: 4,
            helper:
                'One group per line: the group name, a colon, then its words separated by commas. At least two groups; every word belongs to one. Example: Animals: gatto, cane',
          ),
        ];
      case 'fill_the_slots':
        return [
          _instructionField(),
          _field(
            _slots,
            'Slots',
            lines: 4,
            helper:
                'One slot per line: what the learner sees, an equals sign, then the word that fills it. Example: … gatto = il',
          ),
          _field(
            _extraWords,
            'Extra words (optional)',
            lines: 2,
            helper: 'Words offered that fill no slot, one per line.',
          ),
          SwitchListTile(
            key: const Key('slot-reuse'),
            contentPadding: EdgeInsets.zero,
            title: const Text('A word may fill more than one slot'),
            subtitle: const Text(
              'On: a word stays in the bank after each use, so the same word can be the answer of several slots.',
            ),
            secondary: _helpButton('slotReuse'),
            value: _slotReuse,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _slotReuse = value;
                    _dirty = true;
                  }),
          ),
        ];
      case 'dialogue_line':
        final characters =
            widget.course?.storyCharacters ?? const <StorySpeaker>[];
        return [
          _choiceField(
            fieldKey: 'speaker',
            label: 'Speaker',
            value: _speakerId,
            choices: {
              '': 'Narrator',
              for (final character in characters)
                character.id: character.name.isEmpty
                    ? character.id
                    : character.name,
              if (_speakerId.isNotEmpty &&
                  !characters.any((character) => character.id == _speakerId))
                _speakerId: 'Unknown character ($_speakerId)',
            },
            onChanged: (value) => _speakerId = value,
            helper: characters.isEmpty
                ? 'Characters are added in the Course Editor › Story characters.'
                : 'The narrator or one of this Course\'s Story characters.',
          ),
          _field(
            _prompt,
            'Line',
            lines: 2,
            helper:
                'What is said, in the speaker\'s language unless Language says otherwise.',
          ),
          _choiceField(
            fieldKey: 'lineMode',
            label: 'Mode',
            value: _lineMode,
            choices: const {
              'both': 'Text and audio',
              'text': 'Text only',
              'audio': 'Audio only',
            },
            onChanged: (value) => _lineMode = value,
          ),
          if (_lineMode != 'text')
            _choiceField(
              fieldKey: 'readAloud',
              label: 'Read-aloud',
              value: _lineReadAloud,
              choices: const {
                'story': 'As the Story says',
                'automatic': 'Automatic',
                'manual': 'On request',
              },
              onChanged: (value) => _lineReadAloud = value,
            ),
          if (_lineMode == 'both')
            _choiceField(
              fieldKey: 'textReveal',
              label: 'Show text',
              value: _lineTextReveal,
              choices: const {
                'immediate': 'Immediately',
                'afterAudio': 'After listening',
              },
              onChanged: (value) => _lineTextReveal = value,
            ),
          _choiceField(
            fieldKey: 'language',
            label: 'Language',
            value: _lineLanguage,
            choices: const {
              '': 'The speaker\'s language',
              'target': 'Target language',
              'source': 'Source language',
            },
            onChanged: (value) => _lineLanguage = value,
          ),
        ];
      case 'story_cover':
        return [
          _field(
            _prompt,
            'Title line',
            helper:
                'Optional: a line under the Story title on the cover. The cover picture is the image below.',
          ),
        ];
      case 'page':
        // Build 258 Revision 2: the Page's blocks and their live preview; a
        // new Page starts with an empty heading and paragraph.
        return [
          PageBlockEditor(
            key: ValueKey('page-editor-${_exercise.id}-$_formGeneration'),
            blocks: _pageBlocks.isEmpty
                ? ExerciseDraftBuilder.pageStarterBlocks
                : _pageBlocks,
            course: widget.course,
            readOnly: widget.readOnly,
            helpButton: () => _helpButton('blocks'),
            onChanged: (blocks) => setState(() {
              _pageBlocks = blocks;
              _dirty = true;
            }),
          ),
        ];
      case 'before_you_start':
        // Build 257: Open GuideBook only means something while the Course
        // uses GuideBooks, so the switch is greyed out otherwise.
        final usesGuidebook = widget.course?.useGuidebook ?? false;
        return [
          _field(
            _prompt,
            'Note',
            lines: 5,
            helper:
                'What the learner reads before the Round starts. Shown on its own page with Continue to Round, never in Review.',
          ),
          SwitchListTile(
            key: const Key('before-you-start-guidebook-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Open GuideBook button'),
            subtitle: Text(
              usesGuidebook
                  ? 'On: the card offers the Lesson’s GuideBook. Learners see the button once the GuideBook is published.'
                  : 'Turn on Use GuideBook in Lesson Options to offer the Lesson’s GuideBook from this card.',
            ),
            secondary: _helpButton('guidebookButton'),
            value: _guidebookButton,
            onChanged: widget.readOnly || !usesGuidebook
                ? null
                : (value) => setState(() {
                    _guidebookButton = value;
                    _dirty = true;
                  }),
          ),
        ];
      case 'note_card':
        return [
          _field(_prompt, 'Title'),
          _field(
            _question,
            'Note',
            lines: 6,
            helper:
                'A tip, a grammar or a cultural note, in the language you prefer.',
          ),
        ];
      case 'choice':
        return [
          _instructionField(),
          _field(
            _question,
            'Question or sentence',
            lines: 2,
            helper:
                'What the learner answers: a question, or a sentence with ___ where the answer fits, e.g. Which article goes with casa?',
          ),
          _field(_answers, 'Answers', lines: 4),
          SwitchListTile(
            key: const Key('choice-use-multi-select'),
            title: const Text('Multiple correct answers'),
            subtitle: const Text(
              'Let the learner select more than one option. The answer '
              'counts as correct only when the selected options exactly '
              'match the correct set.',
            ),
            value: _useMultiSelect,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _useMultiSelect = value;
                    _dirty = true;
                  }),
          ),
          if (_useMultiSelect) ...[
            _field(
              _correct,
              'Correct answer numbers',
              helper:
                  'Numbers of every correct answer, starting at 1, '
                  'separated by commas. Example: 1, 3',
            ),
            _field(
              _requiredSelections,
              'Required selections (optional)',
              helper:
                  'Minimum number of options the learner must select '
                  'before checking. Leave blank to default to the number '
                  'of correct answers.',
            ),
          ] else
            _field(_correct, 'Correct answer number'),
        ];
      default:
        return [
          _instructionField(),
          _field(
            _question,
            'Question or sentence',
            lines: 2,
            helper:
                'What the learner answers: a question, or a sentence with ___ where the answer fits, e.g. Which article goes with casa?',
          ),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
    }
  }

  Future<void> _choosePreset() async {
    if (widget.readOnly) return;
    final search = TextEditingController();
    var query = '';
    // The direction filter (owner decision, Build 256 Revision 4): every
    // preset, or only those the learner answers in the target language, or
    // in the source language. Cards and notes have no direction and show
    // under All only.
    PresetDirection? direction;
    bool matchesDirection(ExercisePreset preset) =>
        direction == null ||
        preset.direction == direction ||
        preset.direction == PresetDirection.both;
    bool matchesQuery(String name, String description, String group) {
      final needle = query.toLowerCase();
      return needle.isEmpty ||
          name.toLowerCase().contains(needle) ||
          description.toLowerCase().contains(needle) ||
          group.toLowerCase().contains(needle);
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = ExercisePresetRegistry.presets
              .where(
                (preset) =>
                    (widget.round == null ||
                        RoundTypeCompatibility.canOfferPreset(
                          widget.round!.roundType,
                          preset,
                        )) &&
                    matchesDirection(preset) &&
                    matchesQuery(
                      preset.name,
                      preset.description,
                      preset.category.label,
                    ),
              )
              .toList();
          final later = direction != null
              ? const <ComingLaterPreset>[]
              : ExercisePresetRegistry.comingLater
                    .where(
                      (preset) => matchesQuery(
                        preset.name,
                        preset.description,
                        ExerciseCategory.comingLater.label,
                      ),
                    )
                    .toList();
          return SafeArea(
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: .85,
              minChildSize: .55,
              builder: (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Choose an exercise preset',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('exercise-preset-search'),
                    controller: search,
                    onChanged: (value) =>
                        setSheetState(() => query = value.trim()),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search presets',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PresetDirection?>(
                    key: const Key('exercise-preset-direction'),
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(
                        value: PresetDirection.toTarget,
                        label: Text('To target'),
                      ),
                      ButtonSegment(
                        value: PresetDirection.toSource,
                        label: Text('To source'),
                      ),
                    ],
                    selected: {direction},
                    onSelectionChanged: (values) =>
                        setSheetState(() => direction = values.first),
                  ),
                  for (final category in ExerciseCategory.values)
                    if (visible.any(
                      (preset) => preset.category == category,
                    )) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          category.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final preset in visible.where(
                        (preset) => preset.category == category,
                      ))
                        Card(
                          key: ValueKey('exercise-preset-${preset.id}'),
                          child: ListTile(
                            leading: PresetActionChip(preset.action),
                            title: Text(preset.name),
                            subtitle: Text(
                              preset.direction == PresetDirection.none ||
                                      preset.direction == PresetDirection.both
                                  ? preset.description
                                  : '${preset.description} · ${preset.direction.label}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(sheetContext, preset.id),
                          ),
                        ),
                    ],
                  if (later.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                      child: Text(
                        ExerciseCategory.comingLater.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final preset in later)
                      Card(
                        key: ValueKey('exercise-preset-later-${preset.id}'),
                        child: ListTile(
                          enabled: false,
                          leading: PresetActionChip(preset.action),
                          title: Text(preset.name),
                          subtitle: Text(
                            '${preset.description}\nIn a later version: ${preset.reason}',
                          ),
                        ),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Text(
                      'Every primitive',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Card(
                    key: const Key('exercise-preset-canonical'),
                    child: ListTile(
                      leading: const Icon(Icons.tune),
                      title: const Text('Canonical editor'),
                      subtitle: const Text(
                        'Every canonical field of any primitive, with the values the capability registry allows. No preset.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pop(sheetContext, _canonicalEditorChoice),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => search.dispose());
    if (selected == _canonicalEditorChoice) {
      await _openCanonicalEditor();
      return;
    }
    if (selected != null && mounted) {
      final previousType = _type;
      final untouched = _formSnapshot() == _openedSnapshot;
      setState(() {
        const arrangeFamily = {
          'word_order',
          'build_translation_to_target',
          'build_translation_to_source',
        };
        final staySameFamily =
            arrangeFamily.contains(previousType) &&
            arrangeFamily.contains(selected);
        if (!staySameFamily) {
          _useInlineGaps = false;
          _useMultiSelect = false;
        }
        _type = selected;
        _applyPresetStart(selected);
        _dirty = true;
        // A new exercise with nothing typed yet: the chosen type is its
        // starting point, not a change to keep (owner report, 27 September
        // 2026). An existing exercise's type change stays a change.
        if (widget.isNew && untouched) _openedSnapshot = _formSnapshot();
      });
      // As in the canonical editor (Build 263 Revision 1, owner request of
      // 4 October 2026): a type changed over a form that holds something.
      if (!untouched && selected != previousType) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              key: Key('exercise-preset-changed-notice'),
              content: Text(
                'You changed exercise type. Please check all fields.',
              ),
            ),
          );
      }
    }
  }

  /// What a preset starts with in a new form, when those fields are empty.
  void _applyPresetStart(String preset) {
    // Pick the translation always starts with the first option correct.
    if (TranslationChoice.isTranslationChoice(preset) &&
        _correct.text.trim().isEmpty) {
      _correct.text = '1';
    }
    // True or false starts with its two answers in the source language.
    if (preset == 'true_false' && _answers.text.trim().isEmpty) {
      _answers.text = _trueFalseAnswers().join('\n');
      if (_correct.text.trim().isEmpty) _correct.text = '1';
    }
  }

  /// Asks before the form's content is replaced; true to go on.
  Future<bool> _confirmReplace({
    required String title,
    required String content,
    required String action,
    required String key,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: Key(key),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  /// Fill with an example (Build 263 Revision 1, owner request of 4 October
  /// 2026): the Italian Exercise Lab's example of this preset, as in the
  /// canonical editor, after a confirmation when the form holds something.
  Future<void> _fillWithExample() async {
    if (widget.readOnly || !widget.isNew) return;
    if (_hasUnsavedChanges) {
      final replace = await _confirmReplace(
        title: 'Replace with an example?',
        content: 'The example replaces what this form holds now.',
        action: 'Replace',
        key: 'exercise-fill-example-confirm',
      );
      if (!replace || !mounted) return;
    }
    final preset = _type;
    final example = await PresetExamples.forPreset(preset);
    if (!mounted || preset != _type) return;
    if (example == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('exercise-fill-example-missing'),
          content: Text('No example could be read for this exercise type.'),
        ),
      );
      return;
    }
    // The example gets this exercise's ID and fresh item IDs, so nothing of
    // the Laboratory's identity enters the Course.
    final own = AuthoringDuplicationService()
        .duplicateExercise(example)
        .copyWith(id: _exercise.id);
    setState(() {
      if (PresetVariants.formFor(_type) == 'script_recognition') {
        _loadScriptController(own);
        _scriptDirty = true;
      }
      _loadDraft(own, PresetRecipes.decompose(own, _type));
      // The Laboratory's Story characters are not this Course's.
      if (_speakerId.isNotEmpty &&
          widget.course?.speakerOf(_speakerId) == null) {
        _speakerId = '';
      }
      _formGeneration++;
      _dirty = true;
    });
  }

  /// Clear all (Build 263 Revision 1): the form as this preset starts in a
  /// new exercise, after a confirmation when the form holds something.
  Future<void> _clearAll() async {
    if (widget.readOnly || !widget.isNew) return;
    if (_hasUnsavedChanges) {
      final clear = await _confirmReplace(
        title: 'Clear all fields?',
        content:
            'Every field returns to how this exercise type starts; what the '
            'form holds now is lost.',
        action: 'Clear all',
        key: 'exercise-clear-all-confirm',
      );
      if (!clear || !mounted) return;
    }
    final blank = PresetRecipes.blankFor(_type, _exercise.id);
    setState(() {
      if (PresetVariants.formFor(_type) == 'script_recognition') {
        _loadScriptController(blank);
      }
      _loadDraft(blank, PresetRecipes.decompose(blank, _type));
      _applyPresetStart(_type);
      _formGeneration++;
      // Back at this type's start: nothing to keep.
      _dirty = false;
      _openedSnapshot = _formSnapshot();
    });
  }

  Exercise? _buildCandidate(
    PublicationState publicationState, {
    bool requireValidAnswer = false,
    bool attachSelectedSharedSource = false,
  }) {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _exercise,
        type: _type,
        publicationState: publicationState,
        requireValidAnswer: requireValidAnswer,
        useInlineGaps: _useInlineGaps,
        useMultiSelect: _useMultiSelect,
        revealFirstLetter: _revealFirstLetter,
        textRole: _textRole,
        audioRole: _audioRole,
        matchSides: _matchSides,
        speakerId: _speakerId,
        lineMode: _lineMode,
        lineReadAloud: _lineReadAloud,
        lineTextReveal: _lineTextReveal,
        lineLanguage: _lineLanguage,
        groups: _groups.text,
        slots: _slots.text,
        extraWords: _extraWords.text,
        slotReuse: _slotReuse,
        guidebookButton: _guidebookButton,
        pageBlocks: _pageBlocks,
        cardReadAloud: _cardReadAloud,
        dialogueReadAloud: _dialogueReadAloud,
        pictureSize: _pictureSize,
        pictureShape: _pictureShape,
        picturesPerRow: _picturesPerRow,
        pictureBorder: _pictureBorder,
        pluralPictures: _pluralPictures,
        prompt: _prompt.text,
        question: _question.text,
        tts: _tts.text,
        hint: _hint.text,
        answers: _answers.text,
        correct: _correct.text,
        accepted: _accepted.text,
        tokens: _tokens.text,
        order: _order.text,
        gapLayout: _gapLayout.text,
        pairs: _type == 'picture_word_match'
            ? _picturePairsText()
            : _pairs.text,
        icons: _icons.text,
        missingWords: _missingWords.text,
        context: _context.text,
        dialogue: _dialogue.text,
        requiredSelections: _requiredSelections.text,
        correctTranslations: [
          for (final controller in _correctTranslations) controller.text,
        ],
        contextMode: _contextMode,
        imageAsset: _imageAsset,
        selectedSharedSource: _selectedSharedSource,
        attachSelectedSharedSource: attachSelectedSharedSource,
        scriptCandidate: _type == 'script_recognition'
            ? _scriptController!.build(publicationState)
            : null,
      ),
    );
    final error = result.error;
    if (error != null) {
      _showDraftError(error);
      return null;
    }
    // Build 267 Revision 8: the notes go with the exercise, whatever else
    // the form changed.
    return result.candidate?.copyWith(editorNotes: _editorNotes.text.trim());
  }

  void _showDraftError(ExerciseDraftFieldError error) {
    if (error.field == ExerciseDraftField.correctTranslations) {
      setState(() {
        _correctTranslationErrorIndexes = error.indexes;
        _correctTranslationError =
            error.code == ExerciseDraftErrorCode.correctTranslationsRequired
            ? 'Add at least one non-empty correct translation.'
            : 'Correct translations contain duplicates after ignoring case, spacing and final punctuation. Remove or change the repeated entry.';
      });
      return;
    }
    final message = switch (error.code) {
      ExerciseDraftErrorCode.translationChoiceAnswers ||
      ExerciseDraftErrorCode.answerExpression => error.detail!,
      ExerciseDraftErrorCode.correctTranslationsRequired =>
        'Add at least one non-empty correct translation.',
      ExerciseDraftErrorCode.correctTranslationsDuplicate =>
        'Correct translations contain duplicates after ignoring case, spacing and final punctuation. Remove or change the repeated entry.',
      ExerciseDraftErrorCode.pairLine =>
        'Pairs line ${error.line}: enter both values as left = right, one pair per line. Complete or remove this line before Preview or Save.',
      ExerciseDraftErrorCode.correctAnswerNumber =>
        'Correct answer number: enter the number of an existing answer, starting at 1.',
      ExerciseDraftErrorCode.arrangeGapBraces =>
        'Sentence with gaps: put each answer word or phrase between two '
            'underscores, e.g. _go_. A lone _ can\'t be used elsewhere in '
            'the sentence.',
      ExerciseDraftErrorCode.arrangeGapMissing =>
        'Sentence with gaps: add at least one gap, e.g. _go_.',
      ExerciseDraftErrorCode.arrangeGapEmpty =>
        'Sentence with gaps: each _…_ gap must contain the answer '
            'text, e.g. _go_.',
      ExerciseDraftErrorCode.arrangeGapConflict =>
        'Sentence with gaps: could not resolve every gap answer to a '
            'block. Check the extra distractor blocks for a conflict.',
      ExerciseDraftErrorCode.multiAnswersMissing =>
        'Answers: add at least one answer.',
      ExerciseDraftErrorCode.multiCorrectNumbers =>
        'Correct answer numbers: enter the numbers of existing '
            'answers, starting at 1, separated by commas.',
      ExerciseDraftErrorCode.multiCorrectRequired =>
        'Correct answer numbers: enter at least one correct answer '
            'number to publish.',
      ExerciseDraftErrorCode.multiRequiredSelections =>
        'Required selections: enter a number between 1 and the number '
            'of answers, or leave blank.',
      ExerciseDraftErrorCode.selectGapBraces =>
        'Sentence with gaps: put each answer between two underscores, '
            'e.g. _answer_. A lone _ can\'t be used elsewhere in the '
            'sentence.',
      ExerciseDraftErrorCode.selectGapMissing =>
        'Sentence with gaps: add at least one gap, e.g. _answer_.',
      ExerciseDraftErrorCode.selectGapEmpty =>
        'Sentence with gaps: each _…_ gap must contain the answer '
            'text, e.g. _answer_.',
      ExerciseDraftErrorCode.scriptCandidateMissing =>
        'Recognize characters: reopen this Exercise to restore its options.',
      ExerciseDraftErrorCode.groupLine =>
        'Groups line ${error.line}: write the group name, a colon, then '
            'its words separated by commas, e.g. Animals: gatto, cane.',
      ExerciseDraftErrorCode.groupsRequired =>
        'Groups: enter at least two groups with their words.',
      ExerciseDraftErrorCode.groupWordRepeated =>
        'Groups: “${error.detail}” is listed more than once. A word can '
            'be in one group only.',
      ExerciseDraftErrorCode.slotLine =>
        'Slots line ${error.line}: write what the learner sees, an equals '
            'sign, then the word that fills the slot, e.g. … gatto = il.',
      ExerciseDraftErrorCode.slotsRequired =>
        'Slots: enter at least one slot with its word.',
      ExerciseDraftErrorCode.nameBlocksRequired =>
        'Blocks of the name: enter the name, one word per line.',
      ExerciseDraftErrorCode.textRequired =>
        '${error.detail}: required. Enter it, or save as draft.',
      ExerciseDraftErrorCode.linesRequired =>
        'Lines, in the correct order: enter at least two lines.',
      ExerciseDraftErrorCode.pictureRequired =>
        'Picture: required. Choose one, or save as draft.',
      ExerciseDraftErrorCode.gapsRequired =>
        'Text: mark each gap with ___ (three underscores).',
      ExerciseDraftErrorCode.wordsTooFew =>
        'Words: enter at least two words, one per line.',
      ExerciseDraftErrorCode.blocksTooFew =>
        'Blocks of the word: enter at least two blocks, one per line.',
      ExerciseDraftErrorCode.blanksTooFew =>
        'Sentences: mark at least two gaps with ___ (three underscores). '
            'For one gap, use Pick the missing word.',
      ExerciseDraftErrorCode.gapCountMismatch =>
        '${error.detail}: give one line per ___ gap, in order.',
      ExerciseDraftErrorCode.slotWordRepeated =>
        'Slots: “${error.detail}” is listed more than once. Turn on “A '
            'word may fill more than one slot” when one word answers '
            'several slots; an extra word cannot repeat a slot word.',
    };
    final longFeedback =
        error.code == ExerciseDraftErrorCode.translationChoiceAnswers ||
        error.code == ExerciseDraftErrorCode.correctAnswerNumber ||
        error.code == ExerciseDraftErrorCode.multiCorrectNumbers;
    ScaffoldMessenger.of(context).showSnackBar(
      longFeedback
          ? SnackBar(
              duration: const Duration(seconds: 8),
              content: Text(message),
            )
          : SnackBar(content: Text(message)),
    );
  }

  Future<bool> _validateScriptImages(Exercise candidate) async {
    if (candidate.editorTemplate != 'script_recognition') return true;
    final assets = {
      for (final element in candidate.promptElements)
        if (element.type == 'image' && element.asset.isNotEmpty) element.asset,
      for (final item in candidate.items)
        for (final element in item.content)
          if (element.type == 'image' && element.asset.isNotEmpty)
            element.asset,
    };
    try {
      for (final asset in assets) {
        await PortableExerciseImageService.validate(asset);
      }
      return mounted;
    } on FormatException catch (error) {
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check character images'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep editing'),
            ),
          ],
        ),
      );
      return false;
    }
  }

  Future<bool> _save(
    PublicationState publicationState, {
    bool close = true,
  }) async {
    if (widget.readOnly || _inspection || _unrepresentable) return false;
    if (!publicationState.isPublished &&
        _exercise.publicationState.isPublished &&
        !await confirmMoveToDraft(context, 'Exercise')) {
      return false;
    }
    if (!mounted) return false;
    final candidate = _buildCandidate(
      publicationState,
      attachSelectedSharedSource: true,
    );
    if (candidate == null) return false;
    if (!await _validateScriptImages(candidate)) return false;
    if (!mounted) return false;
    final ex =
        widget.isNew ||
            jsonEncode(candidate.toJson()) != jsonEncode(_exercise.toJson())
        ? candidate.withPublicationState(publicationState, updatedAt: _clock())
        : candidate;
    if (!publicationState.isPublished) {
      await _persistAndClose(ex, close: close);
      return true;
    }
    final issues = CourseAuditService().auditExercise(ex);
    final errors = issues
            .where((i) => i.severity == AuditSeverity.error)
            .length,
        warnings = issues
            .where((i) => i.severity == AuditSeverity.warning)
            .length;
    if (errors > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Exercise audit: $errors errors'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final issue in issues.where(
                  (issue) => issue.severity == AuditSeverity.error,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${issue.code}: ${issue.message}'),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep editing'),
            ),
          ],
        ),
      );
      return false;
    }
    if (warnings > 0) {
      final use = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Exercise audit: $warnings warnings'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final issue in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${issue.severity.name.toUpperCase()} [${issue.code}]: ${issue.message}',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Use anyway'),
            ),
          ],
        ),
      );
      if (use != true) return false;
    }
    await _persistAndClose(ex, close: close);
    return true;
  }

  Future<void> _persistAndClose(Exercise exercise, {bool close = true}) async {
    if (widget.readOnly || !mounted) return;
    final index = _navigationExercises.indexWhere(
      (item) => item.id == exercise.id,
    );
    if (index >= 0) _navigationExercises[index] = exercise;
    _savedDuringSession = exercise;
    _savedInSession[exercise.id] = exercise;
    widget.onExerciseSaved?.call(exercise);
    setState(() {
      _exercise = exercise;
      _dirty = false;
      _scriptDirty = false;
      _openedSnapshot = _formSnapshot();
      _routeMayPop = close;
    });
    if (!close) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, exercise);
  }

  /// The Course preview from this form (Build 261 Revision 2, owner
  /// decision): the working copy with what the form saved in this session,
  /// never its unsaved edits.
  Course? get _previewCourse {
    final course = widget.course;
    final lesson = widget.lesson;
    final round = widget.round;
    if (course == null || lesson == null || round == null) return course;
    var preview = course;
    try {
      for (final exercise in _savedInSession.values) {
        preview = const CourseHierarchyUpdateService().apply(
          preview,
          UpsertExercise(lesson.lessonId, round.id, exercise),
        );
      }
    } on Object {
      return course;
    }
    return preview;
  }

  Future<void> _preview() async {
    final course = widget.course;
    final lesson = widget.lesson;
    final round = widget.round;
    if (course == null || lesson == null || round == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open this Exercise from its Course and Round to preview it with the correct language and media settings.',
          ),
        ),
      );
      return;
    }
    final candidate = widget.readOnly
        ? _exercise
        : _buildCandidate(_exercise.publicationState, requireValidAnswer: true);
    if (candidate == null) return;
    if (!await _validateScriptImages(candidate)) return;
    if (!mounted) return;
    final errors = CourseAuditService()
        .auditExercise(candidate)
        .where((issue) => issue.severity == AuditSeverity.error)
        .toList();
    if (errors.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete these fields to Preview'),
          content: SingleChildScrollView(
            child: Text(errors.map((issue) => issue.message).join('\n\n')),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep editing'),
            ),
          ],
        ),
      );
      return;
    }
    final previewRound = LearningRound(
      id: 'preview_${round.id}',
      updatedAt: round.updatedAt,
      title: 'Preview Exercise',
      visualType: round.visualType,
      roundType: round.roundType,
      testFixedOrder: round.testFixedOrder,
      testPassingPercent: round.testPassingPercent,
      timedLimitsSeconds: round.timedLimitsSeconds,
      flow: RoundFlowAuthoring.singleExercisePreviewFlow(
        round.roundType,
        candidate,
      ),
      exercises: [candidate],
    );
    // Preview receives detached data and uses the existing no-progress runtime.
    final detachedCourse = Course.fromJson(
      jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
    );
    final detachedLesson = Lesson.fromJson(
      jsonDecode(jsonEncode(lesson.toJson())) as Map<String, dynamic>,
    );
    final detachedRound = LearningRound.fromJson(
      jsonDecode(jsonEncode(previewRound.toJson())) as Map<String, dynamic>,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: detachedCourse,
          lesson: detachedLesson,
          round: detachedRound,
          ttsLanguage: CourseLanguageResolver.learning(course).code ?? '',
          roundIndex: lesson.rounds
              .indexWhere((item) => item.id == round.id)
              .clamp(0, lesson.rounds.length),
          previewMode: true,
        ),
      ),
    );
  }

  int get _exerciseIndex => widget.isNew
      ? -1
      : _navigationExercises.indexWhere((item) => item.id == _exercise.id);

  /// The form's fields as one comparable string: what the creator can
  /// change in this preset form, in the state it was opened or last saved.
  String _formSnapshot() => [
    _type,
    _contextMode,
    _useMultiSelect,
    _useInlineGaps,
    _revealFirstLetter,
    _speakerId,
    _lineMode,
    _lineReadAloud,
    _lineTextReveal,
    _lineLanguage,
    _slotReuse,
    _guidebookButton,
    jsonEncode([for (final block in _pageBlocks) block.toJson()]),
    _cardReadAloud,
    _dialogueReadAloud,
    _pictureSize,
    _pictureShape,
    _picturesPerRow,
    _pictureBorder,
    _editorNotes.text.trim(),
    (_pluralPictures.toList()..sort()).join(''),
    _imageAsset,
    _selectedSharedSource?.id ?? '',
    for (final controller in [
      _prompt,
      _question,
      _tts,
      _hint,
      _answers,
      _correct,
      _accepted,
      _tokens,
      _order,
      _gapLayout,
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
      _requiredSelections,
      _groups,
      _slots,
      _extraWords,
    ])
      controller.text,
    for (final controller in _correctTranslations) controller.text,
  ].join('\u0001');

  String _openedSnapshot = '';

  /// Counts the forms Fill with an example and Clear all put in place, so
  /// a field that keeps its own state (the Page blocks) starts again.
  int _formGeneration = 0;

  /// True when the form differs from what it opened with (or last saved).
  /// The dirty flag alone is not enough: a control touched without a change
  /// must not ask the creator to discard anything.
  bool get _hasUnsavedChanges =>
      _dirty &&
      (_formSnapshot() != _openedSnapshot ||
          (_type == 'script_recognition' && _scriptDirty));

  bool _scriptDirty = false;

  Future<bool> _resolveUnsavedChanges() async {
    if (!_hasUnsavedChanges) return true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise changes not applied'),
        content: const Text(
          'Apply these changes to the Course you are editing, discard this Exercise form, or keep editing. Nothing is written to the device until Save course.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard changes'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'draft'),
            child: const Text('Apply as draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == 'stay') return false;
    if (action == 'discard') return true;
    return _save(
      action == 'draft' ? PublicationState.draft : PublicationState.published,
      close: false,
    );
  }

  Future<void> _leave() async {
    if (_navigationBusy || _routeMayPop) return;
    _navigationBusy = true;
    try {
      if (!await _resolveUnsavedChanges() || !mounted) return;
      setState(() => _routeMayPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, _savedDuringSession);
    } finally {
      _navigationBusy = false;
    }
  }

  Future<void> _navigate(int offset) async {
    final index = _exerciseIndex;
    final target = index + offset;
    if (_navigationBusy ||
        index < 0 ||
        target < 0 ||
        target >= _navigationExercises.length) {
      return;
    }
    _navigationBusy = true;
    try {
      if (!await _resolveUnsavedChanges() || !mounted) return;
      final e = _navigationExercises[target];
      setState(() {
        _exercise = e;
        _loadScriptController();
        _type =
            PresetRecipes.presetToEdit(e) ??
            PresetRecipes.defaultPresetFor(e.primitive) ??
            'choice_target';
        _loadDraft(e, PresetRecipes.decompose(e, _type));
        _dirty = false;
        _inspection = widget.initiallyInspecting;
        _openedSnapshot = _formSnapshot();
      });
    } finally {
      _navigationBusy = false;
    }
  }

  void _setInspection(bool value) {
    if (_inspection == value) return;
    setState(() => _inspection = value);
  }

  static const _canonicalEditorChoice = '__canonical_editor__';

  /// True when no preset represents the stored exercise exactly: the preset
  /// form then shows its closest reading but must not save it, because a
  /// save would drop what the form cannot show (plan A.13).
  bool get _unrepresentable =>
      !widget.isNew && PresetRecipes.presetToEdit(_exercise) == null;

  /// Opens the Generic Primitive Editor on this exercise; a saved result is
  /// accepted exactly as a preset-form save is.
  Future<void> _openCanonicalEditor() async {
    if (widget.readOnly) return;
    final exercise = _unrepresentable
        ? _exercise
        : (_buildCandidate(
                _exercise.publicationState,
                attachSelectedSharedSource: true,
              ) ??
              _exercise);
    final result = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => PrimitiveEditorScreen(
          exercise: exercise,
          title: widget.title,
          isNew: widget.isNew,
          clock: _clock,
          course: widget.course,
          lesson: widget.lesson,
          round: widget.round,
          readOnly: widget.readOnly,
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _persistAndClose(result);
  }

  Widget _unrepresentableNotice() => Card(
    key: const Key('exercise-unrepresentable-notice'),
    child: ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('No preset represents this exercise exactly'),
      subtitle: const Text(
        'This form shows its closest reading and cannot apply it, because applying would drop what the form does not show. Edit it in the canonical editor.',
      ),
      trailing: widget.readOnly
          ? null
          : FilledButton(
              key: const Key('exercise-open-canonical'),
              onPressed: _openCanonicalEditor,
              child: const Text('Open'),
            ),
    ),
  );

  String get _pageTitle {
    if (_inspection) return 'Exercise inspection';
    if (_exerciseIndex < 0) return widget.title;
    return '${widget.readOnly ? 'View' : 'Edit'} Exercise ${_exerciseIndex + 1}';
  }

  Widget _presentationNotice() => Card(
    key: ValueKey(
      _inspection ? 'exercise-inspection-notice' : 'exercise-read-only-notice',
    ),
    child: ListTile(
      leading: Icon(_inspection ? Icons.code : Icons.visibility_outlined),
      title: Text(_inspection ? 'Inspection' : 'View only'),
      subtitle: Text(
        _inspection
            ? 'Technical exercise representation. Inspection is always read-only.'
            : 'This is the normal exercise form in read-only mode. Preview and field Help remain available.',
      ),
    ),
  );

  Widget _inspectionPanel() => Card(
    key: const Key('exercise-inspection-presentation'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Technical exercise representation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_exercise.toJson()),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _routeMayPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _leave),
        title: CoursePreviewTitle(
          course: _previewCourse,
          title: Text(_pageTitle),
        ),
        actions: const [EditorAppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (widget.course != null)
            EditorBreadcrumbs(
              course: widget.course!,
              lessonId: widget.lesson?.lessonId,
              roundId: widget.round?.id,
              exercise: true,
              onParent: widget.linkParent ? _leave : null,
            ),
          if (_exercise.id.trim().isNotEmpty)
            EditorInternalIdText(label: 'Exercise', id: _exercise.id),
          if (_unrepresentable) _unrepresentableNotice(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('exercise-previous'),
                onPressed: _exerciseIndex > 0 ? () => _navigate(-1) : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              OutlinedButton.icon(
                key: const Key('exercise-next'),
                onPressed:
                    _exerciseIndex >= 0 &&
                        _exerciseIndex + 1 < _navigationExercises.length
                    ? () => _navigate(1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
          if (_inspection || widget.readOnly) _presentationNotice(),
          if (_inspection)
            _inspectionPanel()
          else ...[
            if (widget.isNew)
              Card(
                key: const Key('exercise-preset-selector'),
                child: ListTile(
                  // The preset's name in bold (owner request, 29 September
                  // 2026), here and on the locked "Exercise type" line.
                  title: Text(
                    labelForType(_type),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${ExercisePresetRegistry.byId(_type)!.category.label} · ${ExercisePresetRegistry.byId(_type)!.description}',
                  ),
                  trailing: const Icon(Icons.unfold_more),
                  onTap: widget.readOnly ? null : _choosePreset,
                ),
              ),
            // Build 263 Revision 1: as in the canonical editor.
            if (widget.isNew && !widget.readOnly) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('exercise-fill-example'),
                    onPressed: _fillWithExample,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Fill with an example'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('exercise-clear-all'),
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear all'),
                  ),
                ],
              ),
            ],
            if (!widget.isNew)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exercise type'),
                subtitle: Text(
                  labelForType(_type),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.lock_outline),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseHelpScreen(
                      // Pick the translation opens straight on its own
                      // chapter by pre-filling the search with its name.
                      initialQuery: TranslationChoice.isTranslationChoice(_type)
                          ? labelForType(_type)
                          : '',
                    ),
                  ),
                ),
                icon: const Icon(Icons.help_outline),
                label: const Text('Exercise Help'),
              ),
            ),
            const SizedBox(height: 12),
            ..._specificFields(),
            const SizedBox(height: 12),
            // Match pictures to words has only the pictures of its words
            // (Build 259 Revision 5); Select the image and Listen and pick
            // the image only the pictures of their answers (Build 263
            // Revision 0).
            if (_type != 'script_recognition' &&
                _type != 'before_you_start' &&
                _type != 'page' &&
                _type != 'picture_word_match' &&
                _type != 'icon_choice' &&
                _type != 'listening_image_choice')
              ExerciseImageField(
                course: widget.course,
                asset: _imageAsset,
                sharedSource: _selectedSharedSource,
                readOnly: widget.readOnly,
                help: _helpButton('image'),
                // Build 265 Revision 11: the exercise picture as several;
                // a Story's cover is one picture.
                plural: _pluralPictures.contains(_imageAsset),
                pluralKey: const Key('exercise-image-plural'),
                onPluralChanged: _type == 'story_cover'
                    ? null
                    : (plural) => setState(() {
                        _markPlural(_imageAsset, plural);
                        _dirty = true;
                      }),
                onChanged: (change) => setState(() {
                  _movePlural(_imageAsset, change.asset);
                  _imageAsset = change.asset;
                  _selectedSharedSource = change.source;
                  _dirty = true;
                }),
              ),
          ],
          const SizedBox(height: 12),
          EditorNotesField(
            key: const Key('exercise-editor-notes'),
            controller: _editorNotes,
            // Inspection saves nothing, so its notes are read-only too
            // (Build 267 Revision 9).
            readOnly: widget.readOnly || _inspection,
            onChanged: (_) => _dirty = true,
            help: _helpButton('editorNotes'),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('exercise-preview'),
                onPressed: _preview,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Preview'),
              ),
              FilterChip(
                key: const Key('exercise-inspection-toggle'),
                avatar: const Icon(Icons.code),
                label: const Text('Inspection'),
                selected: _inspection,
                onSelected: _setInspection,
              ),
              OutlinedButton.icon(
                key: const Key('exercise-save-draft'),
                onPressed: widget.readOnly || _inspection || _unrepresentable
                    ? null
                    : () => _save(PublicationState.draft),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Apply as draft'),
              ),
              FilledButton.icon(
                key: const Key('exercise-save'),
                onPressed: widget.readOnly || _inspection || _unrepresentable
                    ? null
                    : () => _save(PublicationState.published),
                // The disk icon is Save now's: it writes the Course. Apply
                // only changes the working copy (Build 271 Revision 2
                // follow-up).
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

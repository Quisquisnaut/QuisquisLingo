import '../widgets/editor_notes_field.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../services/canonical_exercise_draft.dart';
import '../services/canonical_exercise_samples.dart';
import '../services/course_audit_service.dart';
import '../services/course_language_resolver.dart';
import '../services/round_type_compatibility.dart';
import '../services/round_flow_authoring.dart';
import '../services/portable_exercise_image.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/editor_breadcrumbs.dart';
import '../widgets/editor_dialogs.dart';
import '../widgets/exercise_editor_intro.dart';
import '../widgets/image_credit_reminder.dart';
import '../widgets/primitive_intro.dart';
import 'flat_image_library_screen.dart';
import 'round_screen.dart';
import '../widgets/course_preview_flag.dart';

/// The Generic Primitive Editor (Build 256 Session 4, plan A.12/A.13): one
/// form for every canonical exercise, whatever its primitive, with its
/// controls and legal values taken from [PrimitiveCapabilityRegistry]. It
/// edits a [CanonicalExerciseDraft] and hands the saved [Exercise] to
/// [onExerciseSaved] exactly as the preset form does; the Course confirmation
/// still decides what is stored.
class PrimitiveEditorScreen extends StatefulWidget {
  const PrimitiveEditorScreen({
    super.key,
    required this.exercise,
    required this.title,
    required this.isNew,
    this.clock,
    this.course,
    this.lesson,
    this.round,
    this.onExerciseSaved,
    this.readOnly = false,
    this.initiallyInspecting = false,
    this.linkParent = false,
  });

  final Exercise exercise;
  final String title;
  final bool isNew;
  final DateTime Function()? clock;
  final Course? course;
  final Lesson? lesson;
  final LearningRound? round;
  final ValueChanged<Exercise>? onExerciseSaved;
  final bool readOnly;
  final bool initiallyInspecting;
  final bool linkParent;

  @override
  State<PrimitiveEditorScreen> createState() => _PrimitiveEditorScreenState();
}

/// One editable row with a stable widget key, so text fields keep their
/// state when rows above them are added or removed.
class _Slot<T> {
  _Slot(this.value);
  final Key key = UniqueKey();
  T value;
}

/// A menu entry's text on one line, cut with an ellipsis when the menu is
/// narrower than the text (Build 261 Revision 6 follow-up: the editor's
/// menus fit a 360-pixel window).
Text _menuText(String text) =>
    Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);

class _PrimitiveEditorScreenState extends State<PrimitiveEditorScreen> {
  late final CanonicalExerciseDraft _draft;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  final _prompt = <_Slot<PromptElement>>[];
  final _items = <_Slot<ExerciseItem>>[];
  final _targets = <_Slot<ExerciseTarget>>[];
  final _layout = <_Slot<LayoutElement>>[];
  final _orders = <_Slot<OrderedAnswer>>[];
  final _relations = <_Slot<List<String>>>[];
  late bool _inspection = widget.initiallyInspecting;
  bool _dirty = false;

  /// Renewed when an example fills the form, so every field shows it.
  int _formGeneration = 0;
  bool _routeMayPop = false;

  bool get _locked => widget.readOnly || _inspection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIntroductions());
    _draft = CanonicalExerciseDraft.fromExercise(widget.exercise);
    _prompt.addAll(_draft.prompt.map(_Slot.new));
    _items.addAll(_draft.items.map(_Slot.new));
    _targets.addAll(_draft.targets.map(_Slot.new));
    _layout.addAll(_draft.layout.map(_Slot.new));
    _orders.addAll(_draft.evaluation.correctOrders.map(_Slot.new));
    _relations.addAll(
      _draft.evaluation.relations.map((pair) => _Slot(List.of(pair))),
    );
  }

  /// The Course's introduction to the two ways of creating an exercise,
  /// then this primitive's popup (Build 261 Revision 6), each when due.
  Future<void> _showIntroductions() async {
    if (!mounted) return;
    await ExerciseEditorIntro.showIfNeeded(
      context,
      courseId: widget.course?.courseId,
    );
    await _showPrimitiveIntro();
  }

  /// The popup that explains the primitive on screen, once per learner,
  /// primitive and Course; not while the form is read-only.
  Future<void> _showPrimitiveIntro() async {
    if (!mounted || _locked) return;
    await PrimitiveIntro.showIfNeeded(
      context,
      primitive: _draft.primitive,
      courseId: widget.course?.courseId,
    );
  }

  // ---------------------------------------------------------------- state

  void _change(VoidCallback mutate) {
    if (_locked) return;
    setState(() {
      mutate();
      _draft.prompt
        ..clear()
        ..addAll(_prompt.map((slot) => slot.value));
      _draft.items
        ..clear()
        ..addAll(_items.map((slot) => slot.value));
      _draft.targets
        ..clear()
        ..addAll(_targets.map((slot) => slot.value));
      _draft.layout
        ..clear()
        ..addAll(_layout.map((slot) => slot.value));
      _draft.evaluation = _evaluationWith(
        _draft.evaluation,
        correctOrders: _orders.map((slot) => slot.value).toList(),
        relations: _relations
            .map((slot) => List<String>.unmodifiable(slot.value))
            .toList(),
      );
      _dirty = true;
    });
  }

  CanonicalEvaluation _evaluationWith(
    CanonicalEvaluation base, {
    EvaluationMode? mode,
    List<String>? correctItemIds,
    List<TargetAssignment>? assignments,
    List<String>? answers,
    List<String>? literalAnswers,
    List<TargetAnswers>? targetAnswers,
    NumericAnswer? numeric,
    bool clearNumeric = false,
    String? pattern,
    List<OrderedAnswer>? correctOrders,
    List<List<String>>? relations,
    List<AcceptedTarget>? acceptedTargets,
  }) => CanonicalEvaluation(
    mode: mode ?? base.mode,
    correctItemIds: correctItemIds ?? base.correctItemIds,
    assignments: assignments ?? base.assignments,
    answers: answers ?? base.answers,
    literalAnswers: literalAnswers ?? base.literalAnswers,
    targetAnswers: targetAnswers ?? base.targetAnswers,
    numeric: clearNumeric ? null : (numeric ?? base.numeric),
    pattern: pattern ?? base.pattern,
    correctOrders: correctOrders ?? base.correctOrders,
    relations: relations ?? base.relations,
    acceptedTargets: acceptedTargets ?? base.acceptedTargets,
  );

  void _setEvaluation(CanonicalEvaluation evaluation) =>
      _change(() => _draft.evaluation = evaluation);

  /// The exercise the form describes right now. An unchanged existing
  /// exercise is returned as it is, so its timestamp and metadata stay.
  Exercise _candidate(PublicationState state) {
    final built = _draft.toExercise(
      publicationState: state,
      updatedAt: _clock().toUtc(),
    );
    if (widget.isNew) return built;
    final original = widget.exercise;
    if (!built.semanticallyEquals(original)) return built;
    return original.publicationState == state
        ? original
        : original.withPublicationState(state);
  }

  List<String> _lines(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  List<String> _ids(String text) => text
      .split(RegExp(r'[,\n]'))
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList();

  // -------------------------------------------------------------- actions

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
    final violations = _draft.violations;
    if (violations.isNotEmpty) {
      await _showList(
        'Fix these before Preview',
        violations.map((violation) => violation.message).toList(),
      );
      return;
    }
    final candidate = _candidate(widget.exercise.publicationState);
    final errors = CourseAuditService()
        .auditExercise(candidate)
        .where((issue) => issue.severity == AuditSeverity.error)
        .map((issue) => '${issue.code}: ${issue.message}')
        .toList();
    if (errors.isNotEmpty) {
      await _showList('Complete these fields to Preview', errors);
      return;
    }
    if (!mounted) return;
    final previewRound = LearningRound(
      id: 'preview_${round.id}',
      updatedAt: round.updatedAt,
      title: 'Preview Exercise',
      visualType: round.visualType,
      roundType: round.roundType,
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

  Future<void> _showList(String title, List<String> lines) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep editing'),
        ),
      ],
    ),
  );

  Future<bool> _save(PublicationState state) async {
    if (_locked) return false;
    if (!state.isPublished &&
        widget.exercise.publicationState.isPublished &&
        !await confirmMoveToDraft(context, 'Exercise')) {
      return false;
    }
    if (!mounted) return false;
    final violations = _draft.violations;
    if (violations.isNotEmpty) {
      await _showList(
        'The capability registry refuses this exercise',
        violations.map((violation) => violation.message).toList(),
      );
      return false;
    }
    final exercise = _candidate(state);
    if (state.isPublished) {
      final type = widget.round?.roundType;
      if (type != null) {
        final required =
            widget.round?.content
                .where((content) => content.id == widget.exercise.id)
                .firstOrNull
                ?.required ??
            true;
        final incompatible = RoundTypeCompatibility.issuesForExercise(
          type,
          exercise,
          required: required,
        );
        if (incompatible.isNotEmpty) {
          await _showList(
            'Round type compatibility',
            incompatible.map(RoundTypeCompatibility.message).toList(),
          );
          return false;
        }
      }
      final issues = CourseAuditService().auditExercise(exercise);
      final errors = issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .toList();
      if (errors.isNotEmpty) {
        await _showList(
          'Exercise audit: ${errors.length} errors',
          errors.map((issue) => '${issue.code}: ${issue.message}').toList(),
        );
        return false;
      }
      final warnings = issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .length;
      if (warnings > 0) {
        if (!mounted) return false;
        final use = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use anyway'),
              ),
            ],
          ),
        );
        if (use != true) return false;
      }
    }
    if (!mounted) return false;
    widget.onExerciseSaved?.call(exercise);
    setState(() {
      _dirty = false;
      _routeMayPop = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, exercise);
    return true;
  }

  /// Whether the form now describes another exercise than the one it opened
  /// with. Decided by comparing, not by the dirty flag, so touching a control
  /// without changing anything never asks to discard.
  bool get _hasUnsavedChanges {
    if (!_dirty) return false;
    final built = _draft.toExercise(
      publicationState: widget.exercise.publicationState,
      updatedAt: widget.exercise.updatedAt,
    );
    // Editor Notes are not part of the exercise's meaning (Build 267
    // Revision 8), so they are compared on their own.
    if (built.semanticallyEquals(widget.exercise) &&
        built.editorNotes == widget.exercise.editorNotes.trim()) {
      return false;
    }
    // A new exercise still blank for its primitive has nothing to lose,
    // whichever primitive the creator has picked so far (owner report,
    // 27 September 2026).
    if (widget.isNew) return !_isBlank;
    return true;
  }

  /// Whether the form holds only the blank defaults of its primitive: no
  /// content, the default evaluation mode and the required options.
  bool get _isBlank => _draft
      .toExercise(
        publicationState: widget.exercise.publicationState,
        updatedAt: widget.exercise.updatedAt,
      )
      .semanticallyEquals(
        CanonicalExerciseDraft.blankExercise(
          _draft.primitive,
          id: widget.exercise.id,
          updatedAt: widget.exercise.updatedAt,
        ),
      );

  /// A new exercise's primitive changes: content that still applies stays,
  /// the rest is cleared. When the form held something, a message asks the
  /// creator to check every field (Build 261 Revision 6), after the new
  /// primitive's popup when it is due.
  Future<void> _changePrimitive(ExercisePrimitive? value) async {
    if (value == null || value == _draft.primitive) return;
    final hadContent = !_isBlank;
    _change(() {
      _draft.changePrimitive(value);
      _items
        ..clear()
        ..addAll(_draft.items.map(_Slot.new));
      _targets
        ..clear()
        ..addAll(_draft.targets.map(_Slot.new));
      _layout
        ..clear()
        ..addAll(_draft.layout.map(_Slot.new));
      _orders.clear();
      _relations.clear();
    });
    await _showPrimitiveIntro();
    if (!hadContent || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: Key('primitive-changed-notice'),
          content: Text('You changed exercise type. Please check all fields.'),
        ),
      );
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

  /// Loads [exercise]'s content into the form and rebuilds every card.
  void _replaceForm(Exercise exercise) {
    setState(() {
      _draft.fillFrom(exercise);
      _prompt
        ..clear()
        ..addAll(_draft.prompt.map(_Slot.new));
      _items
        ..clear()
        ..addAll(_draft.items.map(_Slot.new));
      _targets
        ..clear()
        ..addAll(_draft.targets.map(_Slot.new));
      _layout
        ..clear()
        ..addAll(_draft.layout.map(_Slot.new));
      _orders
        ..clear()
        ..addAll(_draft.evaluation.correctOrders.map(_Slot.new));
      _relations
        ..clear()
        ..addAll(
          _draft.evaluation.relations.map((pair) => _Slot(List.of(pair))),
        );
      _formGeneration++;
      _dirty = true;
    });
  }

  /// Fill with an example (Build 261 Revision 5, owner decision of 2
  /// October 2026): a working exercise of the chosen primitive, after a
  /// confirmation when the form already holds something.
  Future<void> _fillWithExample() async {
    if (_locked) return;
    if (_hasUnsavedChanges) {
      final replace = await _confirmReplace(
        title: 'Replace with an example?',
        content: 'The example replaces what this form holds now.',
        action: 'Replace',
        key: 'primitive-fill-example-confirm',
      );
      if (!replace || !mounted) return;
    }
    _replaceForm(
      CanonicalExerciseSamples.forPrimitive(
        _draft.primitive,
        id: _draft.id,
        updatedAt: _clock().toUtc(),
      ),
    );
  }

  /// Clear all (Build 261 Revision 6, owner request of 2 October 2026): the
  /// blank defaults of this primitive, after a confirmation when the form
  /// holds something.
  Future<void> _clearAll() async {
    if (_locked) return;
    if (!_isBlank) {
      final clear = await _confirmReplace(
        title: 'Clear all fields?',
        content:
            'Every field returns to its default for this primitive; what the '
            'form holds now is lost.',
        action: 'Clear all',
        key: 'primitive-clear-all-confirm',
      );
      if (!clear || !mounted) return;
    }
    _replaceForm(
      CanonicalExerciseDraft.blankExercise(
        _draft.primitive,
        id: _draft.id,
        updatedAt: _clock().toUtc(),
      ),
    );
  }

  Future<void> _leave() async {
    if (_hasUnsavedChanges && !_locked) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Exercise changes'),
          content: const Text(
            'Discard this Exercise form, or keep editing? Nothing is confirmed to storage here.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!mounted) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<String?> _chooseImage() async {
    final selected = await Navigator.of(context).push<ExerciseImageMetadata>(
      MaterialPageRoute(
        builder: (_) => const FlatImageLibraryScreen(readOnly: true),
      ),
    );
    if (selected == null) return null;
    final asset = selected.assetPath;
    // Existing locally imported bank images become course-owned bytes, as in
    // Recognize characters.
    final image = PortableExerciseImageService.isPortable(asset)
        ? asset
        : await PortableExerciseImageService.fromFile(File(asset));
    if (mounted) showImageCreditReminder(context);
    return image;
  }

  // ---------------------------------------------------------------- build

  String get _pageTitle {
    if (_inspection) return 'Exercise inspection';
    return widget.readOnly ? 'View ${widget.title}' : widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final support = PrimitiveCapabilityRegistry.runtimeSupport(
      primitive: _draft.primitive,
      options: PrimitiveOptions(_draft.options),
      evaluationMode: _draft.evaluation.mode,
    );
    final violations = _draft.violations;
    final type = widget.round?.roundType;
    final compatibility = type == null || violations.isNotEmpty
        ? const <RoundTypeIssue>[]
        : RoundTypeCompatibility.issuesForExercise(
            type,
            _candidate(PublicationState.draft),
            required:
                widget.round?.content
                    .where((content) => content.id == widget.exercise.id)
                    .firstOrNull
                    ?.required ??
                true,
          );
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        key: const Key('primitive-editor'),
        appBar: AppBar(
          leading: BackButton(onPressed: _leave),
          title: CoursePreviewTitle(
            course: widget.course,
            title: Text(_pageTitle),
          ),
          actions: [EditorAppBarActions(helpPrimitive: _draft.primitive)],
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
            EditorInternalIdText(label: 'Exercise', id: _draft.id),
            if (_locked) _presentationNotice(),
            if (_inspection) ...[
              _inspectionPanel(),
            ] else ...[
              _primitiveCard(support),
              if (violations.isNotEmpty) _violationsCard(violations),
              if (compatibility.isNotEmpty)
                Card(
                  key: const Key('primitive-round-type-warning'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      compatibility
                          .map(RoundTypeCompatibility.message)
                          .join('\n'),
                    ),
                  ),
                ),
              _generation(0, _optionsCard()),
              _generation(1, _promptCard()),
              if (_draft.capability.usesItems) _generation(2, _itemsCard()),
              if (_draft.capability.usesTargets) ...[
                _generation(3, _targetsCard()),
                _generation(4, _layoutCard()),
              ],
              _generation(5, _evaluationCard()),
              _generation(6, _feedbackCard()),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const Key('primitive-preview'),
                  onPressed: _preview,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Preview'),
                ),
                OutlinedButton.icon(
                  key: const Key('primitive-inspection-toggle'),
                  onPressed: () => setState(() => _inspection = !_inspection),
                  icon: const Icon(Icons.code),
                  label: const Text('Inspection'),
                ),
                OutlinedButton.icon(
                  key: const Key('primitive-save-draft'),
                  onPressed: _locked
                      ? null
                      : () => _save(PublicationState.draft),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Save as draft'),
                ),
                FilledButton.icon(
                  key: const Key('primitive-save'),
                  onPressed: _locked
                      ? null
                      : () => _save(PublicationState.published),
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A card rebuilt from the draft after an example fills the form.
  Widget _generation(int index, Widget card) => KeyedSubtree(
    key: ValueKey('primitive-form-$_formGeneration-$index'),
    child: card,
  );

  Widget _presentationNotice() => Card(
    key: ValueKey(
      _inspection
          ? 'primitive-inspection-notice'
          : 'primitive-read-only-notice',
    ),
    child: ListTile(
      leading: Icon(_inspection ? Icons.code : Icons.visibility_outlined),
      title: Text(_inspection ? 'Inspection' : 'View only'),
      subtitle: Text(
        _inspection
            ? 'Technical exercise representation. Inspection is always read-only.'
            : 'This is the canonical exercise form in read-only mode. Preview remains available.',
      ),
    ),
  );

  Widget _inspectionPanel() => Card(
    key: const Key('primitive-inspection-presentation'),
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
            const JsonEncoder.withIndent(
              '  ',
            ).convert(_candidate(widget.exercise.publicationState).toJson()),
          ),
        ],
      ),
    ),
  );

  Widget _section(String title, String help, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (help.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(help, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  // ------------------------------------------------------------ primitive

  Widget _primitiveCard(ExerciseRuntimeSupport support) {
    final playable = support.state == ExerciseSupportState.executable;
    return _section(
      'Primitive',
      widget.isNew
          ? 'What the learner does. Locked once the exercise exists.'
          : 'Locked: the primitive of an existing exercise cannot change.',
      [
        DropdownButtonFormField<ExercisePrimitive>(
          key: const Key('primitive-editor-primitive'),
          initialValue: _draft.primitive,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Primitive',
          ),
          items: [
            for (final primitive in ExercisePrimitive.values)
              DropdownMenuItem(
                value: primitive,
                child: _menuText(primitive.label),
              ),
          ],
          onChanged: widget.isNew && !_locked ? _changePrimitive : null,
        ),
        if (widget.isNew && !_locked) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('primitive-fill-example'),
                onPressed: _fillWithExample,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Fill with an example'),
              ),
              OutlinedButton.icon(
                key: const Key('primitive-clear-all'),
                onPressed: _clearAll,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(_draft.primitive.learnerAction),
        const SizedBox(height: 8),
        ListTile(
          key: const Key('primitive-support-state'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            playable ? Icons.check_circle_outline : Icons.info_outline,
            color: playable
                ? Colors.green.shade700
                : Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            playable
                ? 'Playable in this version'
                : 'Not playable in this version',
          ),
          subtitle: Text(
            playable
                ? (support.configuration?.description ?? '')
                : '${support.reason} The exercise is kept in the Course as it is.',
          ),
        ),
      ],
    );
  }

  Widget _violationsCard(List<CapabilityViolation> violations) => Card(
    key: const Key('primitive-violations'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The capability registry refuses this combination',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final violation in violations)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(violation.message),
            ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------- options

  Widget _optionsCard() => _section(
    'Options',
    'Only values you set are written; "Default" leaves the registry default.',
    [
      for (final definition in _draft.capability.options) ...[
        _optionField(definition),
        const SizedBox(height: 12),
      ],
      if (_draft.capability.options.isEmpty)
        const Text('This primitive has no options.'),
    ],
  );

  Widget _optionField(OptionDefinition definition) {
    final key = definition.key;
    final current = _draft.options[key];
    final defaultText = definition.defaultValue == null
        ? 'Default'
        : 'Default (${definition.defaultValue!.serialized})';
    final label = definition.required ? '${key.name} *' : key.name;
    switch (key.kind) {
      case OptionValueKind.enumeration:
        return DropdownButtonFormField<String>(
          key: Key('primitive-option-${key.name}'),
          initialValue: current == null ? '' : '${current.serialized}',
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            helperText: definition.description.isEmpty
                ? null
                : definition.description,
            helperMaxLines: 3,
          ),
          items: [
            DropdownMenuItem(value: '', child: _menuText(defaultText)),
            for (final value in definition.legalValues)
              DropdownMenuItem(
                value: value.serialized,
                child: _menuText(value.serialized),
              ),
          ],
          onChanged: _locked
              ? null
              : (value) => _change(
                  () => _draft.setOption(
                    key,
                    value == null || value.isEmpty
                        ? null
                        : OptionValue.parse(key, value),
                  ),
                ),
        );
      case OptionValueKind.boolean:
        final currentText = current == null ? '' : '${current.serialized}';
        return DropdownButtonFormField<String>(
          key: Key('primitive-option-${key.name}'),
          initialValue: currentText,
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            helperText: definition.description.isEmpty
                ? null
                : definition.description,
            helperMaxLines: 3,
          ),
          items: [
            DropdownMenuItem(value: '', child: _menuText(defaultText)),
            const DropdownMenuItem(value: 'true', child: Text('On')),
            const DropdownMenuItem(value: 'false', child: Text('Off')),
          ],
          onChanged: _locked
              ? null
              : (value) => _change(
                  () => _draft.setOption(
                    key,
                    value == null || value.isEmpty
                        ? null
                        : OptionValue.parse(key, value == 'true'),
                  ),
                ),
        );
      case OptionValueKind.integer:
        return TextFormField(
          key: Key('primitive-option-${key.name}'),
          initialValue: current == null ? '' : '${current.serialized}',
          readOnly: _locked,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            hintText: defaultText,
            helperText: definition.description.isEmpty
                ? null
                : definition.description,
            helperMaxLines: 3,
          ),
          onChanged: (value) {
            final parsed = int.tryParse(value.trim());
            _change(
              () => _draft.setOption(
                key,
                parsed == null ? null : OptionValue.parse(key, parsed),
              ),
            );
          },
        );
      case OptionValueKind.language:
        return TextFormField(
          key: Key('primitive-option-${key.name}'),
          initialValue: current == null ? '' : '${current.serialized}',
          readOnly: _locked,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            hintText: 'Language tag, for example it or pt-BR',
            helperText: definition.description.isEmpty
                ? null
                : definition.description,
            helperMaxLines: 3,
          ),
          onChanged: (value) => _change(
            () => _draft.setOption(
              key,
              value.trim().isEmpty
                  ? null
                  : OptionValue.parse(key, value.trim()),
            ),
          ),
        );
    }
  }

  // --------------------------------------------------------------- prompt

  Widget _promptCard() => _section(
    'Prompt',
    'What the learner sees and hears. Each element has a role: the part it '
        'plays, chosen from the roles QQL reads for its type.',
    [
      for (var i = 0; i < _prompt.length; i++)
        _ElementRow(
          key: _prompt[i].key,
          element: _prompt[i].value,
          primitive: _draft.primitive,
          place: ElementPlace.prompt,
          index: i,
          count: _prompt.length,
          locked: _locked,
          chooseImage: _chooseImage,
          onChanged: (element) => _change(() => _prompt[i].value = element),
          onMove: (delta) => _change(() {
            final slot = _prompt.removeAt(i);
            _prompt.insert(i + delta, slot);
          }),
          onRemove: () => _change(() => _prompt.removeAt(i)),
        ),
      _addRow([
        _addButton('primitive-prompt-add-text', 'Text', () {
          _change(() => _prompt.add(_Slot(const PromptElement(type: 'text'))));
        }),
        _addButton('primitive-prompt-add-audio', 'Audio', () {
          _change(() => _prompt.add(_Slot(const PromptElement(type: 'audio'))));
        }),
        _addButton('primitive-prompt-add-image', 'Image', () {
          _change(() => _prompt.add(_Slot(const PromptElement(type: 'image'))));
        }),
      ]),
    ],
  );

  Widget _addRow(List<Widget> buttons) =>
      Wrap(spacing: 8, runSpacing: 8, children: buttons);

  Widget _addButton(String key, String label, VoidCallback onPressed) =>
      OutlinedButton.icon(
        key: Key(key),
        onPressed: _locked ? null : onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      );

  // ---------------------------------------------------------------- items

  Widget _itemsCard() => _section(
    'Items',
    _draft.primitive == ExercisePrimitive.match
        ? 'The things the learner pairs. Each item has a side.'
        : 'The things the learner chooses, orders or places. Answers name items by ID.',
    [
      for (var i = 0; i < _items.length; i++)
        _ItemRow(
          key: _items[i].key,
          item: _items[i].value,
          index: i,
          count: _items.length,
          locked: _locked,
          showSide: _draft.primitive == ExercisePrimitive.match,
          primitive: _draft.primitive,
          chooseImage: _chooseImage,
          onChanged: (item) => _change(() => _items[i].value = item),
          onMove: (delta) => _change(() {
            final slot = _items.removeAt(i);
            _items.insert(i + delta, slot);
          }),
          onRemove: () => _change(() => _items.removeAt(i)),
        ),
      _addRow([
        _addButton('primitive-item-add', 'Item', () {
          _change(
            () => _items.add(
              _Slot(
                ExerciseItem(
                  id: _draft.nextItemId(),
                  content: const [PromptElement(type: 'text')],
                  side: _draft.primitive == ExercisePrimitive.match
                      ? MatchSide.left
                      : null,
                ),
              ),
            ),
          );
        }),
      ]),
    ],
  );

  // -------------------------------------------------------------- targets

  Widget _targetsCard() => _section(
    'Targets',
    'The gaps, slots or regions the learner fills. The layout below places them in the text.',
    [
      for (var i = 0; i < _targets.length; i++)
        _TargetRow(
          key: _targets[i].key,
          target: _targets[i].value,
          locked: _locked,
          onChanged: (target) => _change(() => _targets[i].value = target),
          onRemove: () => _change(() {
            final removed = _targets.removeAt(i).value.id;
            _layout.removeWhere(
              (slot) => slot.value.isTarget && slot.value.targetId == removed,
            );
          }),
        ),
      _addRow([
        _addButton('primitive-target-add', 'Target', () {
          _change(() {
            final id = _draft.nextTargetId();
            _targets.add(_Slot(ExerciseTarget(id: id)));
            _layout.add(_Slot(LayoutElement.target(id)));
          });
        }),
      ]),
    ],
  );

  Widget _layoutCard() => _section(
    'Layout',
    'The sentence as the learner sees it: text pieces and target gaps in order.',
    [
      for (var i = 0; i < _layout.length; i++)
        _LayoutRow(
          key: _layout[i].key,
          element: _layout[i].value,
          index: i,
          count: _layout.length,
          locked: _locked,
          targetIds: _targets.map((slot) => slot.value.id).toList(),
          onChanged: (element) => _change(() => _layout[i].value = element),
          onMove: (delta) => _change(() {
            final slot = _layout.removeAt(i);
            _layout.insert(i + delta, slot);
          }),
          onRemove: () => _change(() => _layout.removeAt(i)),
        ),
      _addRow([
        _addButton('primitive-layout-add-text', 'Text', () {
          _change(() => _layout.add(_Slot(const LayoutElement.text(''))));
        }),
        if (_targets.isNotEmpty)
          _addButton('primitive-layout-add-target', 'Gap', () {
            _change(
              () => _layout.add(
                _Slot(LayoutElement.target(_targets.first.value.id)),
              ),
            );
          }),
      ]),
    ],
  );

  // ----------------------------------------------------------- evaluation

  Widget _evaluationCard() {
    final evaluation = _draft.evaluation;
    final mode = evaluation.mode;
    return _section(
      'Evaluation',
      'How the answer is checked. The mode decides which answer data applies.',
      [
        DropdownButtonFormField<EvaluationMode>(
          key: const Key('primitive-evaluation-mode'),
          initialValue: mode,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Mode',
          ),
          items: [
            for (final candidate in _draft.capability.evaluationModes)
              DropdownMenuItem(
                value: candidate,
                child: _menuText(candidate.serialized),
              ),
            if (!_draft.capability.evaluationModes.contains(mode))
              DropdownMenuItem(value: mode, child: _menuText(mode.serialized)),
          ],
          onChanged: _locked
              ? null
              : (value) {
                  if (value == null) return;
                  _setEvaluation(_evaluationWith(evaluation, mode: value));
                },
        ),
        const SizedBox(height: 12),
        ..._evaluationFields(evaluation),
      ],
    );
  }

  List<Widget> _evaluationFields(CanonicalEvaluation evaluation) {
    switch (evaluation.mode) {
      case EvaluationMode.exactItem:
      case EvaluationMode.exactSet:
      case EvaluationMode.subset:
      case EvaluationMode.orderedSelections:
      case EvaluationMode.perSelection:
        return _correctItemsFields(evaluation);
      case EvaluationMode.exactText:
      case EvaluationMode.acceptedTexts:
      case EvaluationMode.expression:
      case EvaluationMode.regex:
      case EvaluationMode.transcriptionMatch:
      case EvaluationMode.acceptedTranscriptions:
        return _textFields(evaluation);
      case EvaluationMode.numericExact:
      case EvaluationMode.numericRange:
      case EvaluationMode.numericTolerance:
        return _numericFields(evaluation);
      case EvaluationMode.exactOrder:
      case EvaluationMode.acceptedOrders:
        return _orderFields(evaluation);
      case EvaluationMode.gapAssignments:
      case EvaluationMode.exactAssignments:
      case EvaluationMode.partialAssignments:
      case EvaluationMode.categoryMembership:
        return _assignmentFields(evaluation);
      case EvaluationMode.acceptedTargets:
        return _acceptedTargetFields(evaluation);
      case EvaluationMode.exactRelations:
      case EvaluationMode.requiredRelations:
      case EvaluationMode.partialRelations:
        return _relationFields(evaluation);
      case EvaluationMode.pronunciation:
      case EvaluationMode.combined:
      case EvaluationMode.recognition:
      case EvaluationMode.strokeMatch:
      case EvaluationMode.shapeSimilarity:
      case EvaluationMode.presence:
      case EvaluationMode.manual:
      case EvaluationMode.none:
        return const [Text('This mode needs no answer data.')];
    }
  }

  String _itemLabel(ExerciseItem item) {
    final text = item.content
        .where((element) => element.isText || element.isAudio)
        .map((element) => element.text)
        .firstWhere((text) => text.trim().isNotEmpty, orElse: () => '');
    return text.isEmpty ? item.id : '${item.id} · $text';
  }

  List<Widget> _correctItemsFields(CanonicalEvaluation evaluation) => [
    const Text('Correct items'),
    if (_items.isEmpty) const Text('Add items first.'),
    for (final slot in _items)
      CheckboxListTile(
        key: Key('primitive-correct-${slot.value.id}'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(_itemLabel(slot.value)),
        value: evaluation.correctItemIds.contains(slot.value.id),
        onChanged: _locked
            ? null
            : (checked) {
                final ids = List<String>.of(evaluation.correctItemIds);
                if (checked == true) {
                  ids.add(slot.value.id);
                } else {
                  ids.remove(slot.value.id);
                }
                _setEvaluation(
                  _evaluationWith(evaluation, correctItemIds: ids),
                );
              },
      ),
  ];

  List<Widget> _textFields(CanonicalEvaluation evaluation) => [
    TextFormField(
      key: const Key('primitive-evaluation-answers'),
      initialValue: evaluation.answers.join('\n'),
      readOnly: _locked,
      maxLines: null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Answers (one per line; {a|b} expands variants)',
      ),
      onChanged: (value) =>
          _setEvaluation(_evaluationWith(evaluation, answers: _lines(value))),
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('primitive-evaluation-literal-answers'),
      initialValue: evaluation.literalAnswers.join('\n'),
      readOnly: _locked,
      maxLines: null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Literal answers (one per line, never expanded)',
      ),
      onChanged: (value) => _setEvaluation(
        _evaluationWith(evaluation, literalAnswers: _lines(value)),
      ),
    ),
    if (evaluation.mode == EvaluationMode.regex) ...[
      const SizedBox(height: 12),
      TextFormField(
        key: const Key('primitive-evaluation-pattern'),
        initialValue: evaluation.pattern,
        readOnly: _locked,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Pattern (regular expression)',
        ),
        onChanged: (value) =>
            _setEvaluation(_evaluationWith(evaluation, pattern: value.trim())),
      ),
    ],
    if (_targets.isNotEmpty) ...[
      const SizedBox(height: 12),
      const Text('Answers per target (used instead of the lists above)'),
      for (final slot in _targets) ...[
        const SizedBox(height: 8),
        TextFormField(
          key: Key('primitive-target-answers-${slot.value.id}'),
          initialValue:
              evaluation.targetAnswers
                  .where((entry) => entry.targetId == slot.value.id)
                  .map((entry) => entry.answers.join('\n'))
                  .firstOrNull ??
              '',
          readOnly: _locked,
          maxLines: null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: '${slot.value.id}: answers (one per line)',
          ),
          onChanged: (value) {
            final others = evaluation.targetAnswers
                .where((entry) => entry.targetId != slot.value.id)
                .toList();
            final lines = _lines(value);
            _setEvaluation(
              _evaluationWith(
                evaluation,
                targetAnswers: [
                  ...others,
                  if (lines.isNotEmpty)
                    TargetAnswers(targetId: slot.value.id, answers: lines),
                ],
              ),
            );
          },
        ),
      ],
    ],
  ];

  List<Widget> _numericFields(CanonicalEvaluation evaluation) {
    final numeric = evaluation.numeric ?? const NumericAnswer();
    Widget field(
      String label,
      double? value,
      NumericAnswer Function(double?) update,
    ) => TextFormField(
      key: Key('primitive-numeric-${label.toLowerCase()}'),
      initialValue: value == null ? '' : '$value',
      readOnly: _locked,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      onChanged: (text) => _setEvaluation(
        _evaluationWith(
          evaluation,
          numeric: update(double.tryParse(text.trim())),
        ),
      ),
    );
    return [
      field(
        'Value',
        numeric.value,
        (v) => NumericAnswer(
          value: v,
          minimum: numeric.minimum,
          maximum: numeric.maximum,
          tolerance: numeric.tolerance,
        ),
      ),
      const SizedBox(height: 12),
      field(
        'Minimum',
        numeric.minimum,
        (v) => NumericAnswer(
          value: numeric.value,
          minimum: v,
          maximum: numeric.maximum,
          tolerance: numeric.tolerance,
        ),
      ),
      const SizedBox(height: 12),
      field(
        'Maximum',
        numeric.maximum,
        (v) => NumericAnswer(
          value: numeric.value,
          minimum: numeric.minimum,
          maximum: v,
          tolerance: numeric.tolerance,
        ),
      ),
      const SizedBox(height: 12),
      field(
        'Tolerance',
        numeric.tolerance,
        (v) => NumericAnswer(
          value: numeric.value,
          minimum: numeric.minimum,
          maximum: numeric.maximum,
          tolerance: v,
        ),
      ),
    ];
  }

  List<Widget> _orderFields(CanonicalEvaluation evaluation) => [
    const Text('Correct orders: the answer text and its item IDs in order.'),
    for (var i = 0; i < _orders.length; i++)
      Padding(
        key: _orders[i].key,
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    key: Key('primitive-order-text-$i'),
                    initialValue: _orders[i].value.text,
                    readOnly: _locked,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Answer text',
                    ),
                    onChanged: (value) => _change(
                      () => _orders[i].value = OrderedAnswer(
                        text: value,
                        itemIds: _orders[i].value.itemIds,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: Key('primitive-order-ids-$i'),
                    initialValue: _orders[i].value.itemIds.join(', '),
                    readOnly: _locked,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Item IDs in order, comma-separated',
                    ),
                    onChanged: (value) => _change(
                      () => _orders[i].value = OrderedAnswer(
                        text: _orders[i].value.text,
                        itemIds: _ids(value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: _locked
                  ? null
                  : () => _change(() => _orders.removeAt(i)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    const SizedBox(height: 8),
    _addRow([
      _addButton('primitive-order-add', 'Order', () {
        _change(
          () => _orders.add(
            _Slot(
              OrderedAnswer(
                text: '',
                itemIds: _items.map((slot) => slot.value.id).toList(),
              ),
            ),
          ),
        );
      }),
    ]),
  ];

  List<Widget> _assignmentFields(CanonicalEvaluation evaluation) => [
    const Text('Which item IDs belong in each target (comma-separated).'),
    if (_targets.isEmpty) const Text('Add targets first.'),
    for (final slot in _targets) ...[
      const SizedBox(height: 8),
      TextFormField(
        key: Key('primitive-assignment-${slot.value.id}'),
        initialValue:
            evaluation.assignments
                .where((entry) => entry.targetId == slot.value.id)
                .map((entry) => entry.itemIds.join(', '))
                .firstOrNull ??
            '',
        readOnly: _locked,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: slot.value.id,
        ),
        onChanged: (value) {
          final others = evaluation.assignments
              .where((entry) => entry.targetId != slot.value.id)
              .toList();
          final ids = _ids(value);
          _setEvaluation(
            _evaluationWith(
              evaluation,
              assignments: [
                ...others,
                if (ids.isNotEmpty)
                  TargetAssignment(targetId: slot.value.id, itemIds: ids),
              ],
            ),
          );
        },
      ),
    ],
  ];

  List<Widget> _acceptedTargetFields(CanonicalEvaluation evaluation) => [
    const Text('Which target IDs accept each item (comma-separated).'),
    for (final slot in _items) ...[
      const SizedBox(height: 8),
      TextFormField(
        key: Key('primitive-accepted-${slot.value.id}'),
        initialValue:
            evaluation.acceptedTargets
                .where((entry) => entry.itemId == slot.value.id)
                .map((entry) => entry.targetIds.join(', '))
                .firstOrNull ??
            '',
        readOnly: _locked,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: _itemLabel(slot.value),
        ),
        onChanged: (value) {
          final others = evaluation.acceptedTargets
              .where((entry) => entry.itemId != slot.value.id)
              .toList();
          final ids = _ids(value);
          _setEvaluation(
            _evaluationWith(
              evaluation,
              acceptedTargets: [
                ...others,
                if (ids.isNotEmpty)
                  AcceptedTarget(itemId: slot.value.id, targetIds: ids),
              ],
            ),
          );
        },
      ),
    ],
  ];

  List<Widget> _relationFields(CanonicalEvaluation evaluation) {
    final left = _items.where((slot) => slot.value.side != MatchSide.right);
    final right = _items.where((slot) => slot.value.side != MatchSide.left);
    return [
      const Text('Pairs: a left item and the right item it matches.'),
      for (var i = 0; i < _relations.length; i++)
        Padding(
          key: _relations[i].key,
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: _idDropdown(
                  'primitive-relation-left-$i',
                  'Left',
                  _relations[i].value.firstOrNull,
                  left.map((slot) => slot.value).toList(),
                  (id) => _change(
                    () => _relations[i].value = [
                      id,
                      if (_relations[i].value.length > 1)
                        _relations[i].value[1],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _idDropdown(
                  'primitive-relation-right-$i',
                  'Right',
                  _relations[i].value.length > 1
                      ? _relations[i].value[1]
                      : null,
                  right.map((slot) => slot.value).toList(),
                  (id) => _change(
                    () => _relations[i].value = [
                      _relations[i].value.firstOrNull ?? '',
                      id,
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: _locked
                    ? null
                    : () => _change(() => _relations.removeAt(i)),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      _addRow([
        _addButton('primitive-relation-add', 'Pair', () {
          _change(() => _relations.add(_Slot(<String>[])));
        }),
      ]),
    ];
  }

  Widget _idDropdown(
    String key,
    String label,
    String? current,
    List<ExerciseItem> items,
    ValueChanged<String> onChanged,
  ) {
    final known = items.any((item) => item.id == current);
    return DropdownButtonFormField<String>(
      key: Key(key),
      initialValue: known ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item.id, child: _menuText(_itemLabel(item))),
      ],
      onChanged: _locked
          ? null
          : (value) {
              if (value != null) onChanged(value);
            },
    );
  }

  // ------------------------------------------------------------- feedback

  Widget _feedbackCard() => _section(
    'Feedback and hint',
    'Optional texts shown after the answer, and a hint that must not reveal the solution.',
    [
      TextFormField(
        key: const Key('primitive-feedback-correct'),
        initialValue: _draft.feedback.correct,
        readOnly: _locked,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'After a correct answer',
        ),
        onChanged: (value) => _change(
          () => _draft.feedback = ExerciseFeedback(
            correct: value,
            incorrect: _draft.feedback.incorrect,
            showAlternatives: _draft.feedback.showAlternatives,
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        key: const Key('primitive-feedback-incorrect'),
        initialValue: _draft.feedback.incorrect,
        readOnly: _locked,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'After a wrong answer',
        ),
        onChanged: (value) => _change(
          () => _draft.feedback = ExerciseFeedback(
            correct: _draft.feedback.correct,
            incorrect: value,
            showAlternatives: _draft.feedback.showAlternatives,
          ),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<FeedbackAlternatives>(
        key: const Key('primitive-feedback-alternatives'),
        initialValue: _draft.feedback.showAlternatives,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Show alternatives',
        ),
        items: [
          for (final value in FeedbackAlternatives.values)
            DropdownMenuItem(value: value, child: _menuText(value.serialized)),
        ],
        onChanged: _locked
            ? null
            : (value) {
                if (value == null) return;
                _change(
                  () => _draft.feedback = ExerciseFeedback(
                    correct: _draft.feedback.correct,
                    incorrect: _draft.feedback.incorrect,
                    showAlternatives: value,
                  ),
                );
              },
      ),
      const SizedBox(height: 12),
      TextFormField(
        key: const Key('primitive-hint'),
        initialValue: _draft.hint,
        readOnly: _locked,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Hint',
        ),
        onChanged: (value) => _change(() => _draft.hint = value),
      ),
      const SizedBox(height: 12),
      // Build 267 Revision 8: the author's notes.
      EditorNotesField(
        key: const Key('primitive-editor-notes'),
        initialValue: _draft.editorNotes,
        readOnly: _locked,
        onChanged: (value) => _change(() => _draft.editorNotes = value),
      ),
    ],
  );
}

// ------------------------------------------------------------------ rows

class _ElementRow extends StatelessWidget {
  const _ElementRow({
    super.key,
    required this.element,
    required this.primitive,
    required this.place,
    required this.index,
    required this.count,
    required this.locked,
    required this.chooseImage,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
    this.compact = false,
  });

  final PromptElement element;

  /// The exercise's primitive and where the element sits: together with
  /// the element's type they decide the roles the Role menu offers.
  final ExercisePrimitive primitive;
  final ElementPlace place;
  final int index;
  final int count;
  final bool locked;
  final Future<String?> Function() chooseImage;
  final ValueChanged<PromptElement> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;
  final bool compact;

  PromptElement _with({
    String? role,
    String? text,
    String? asset,
    String? speaker,
    Object? language = _keep,
    Object? playback = _keep,
    Object? required = _keep,
    Object? sharedImageSource = _keep,
  }) => PromptElement(
    type: element.type,
    role: role ?? element.role,
    text: text ?? element.text,
    asset: asset ?? element.asset,
    speaker: speaker ?? element.speaker,
    sharedImageSource: identical(sharedImageSource, _keep)
        ? element.sharedImageSource
        : sharedImageSource as SharedImageSource?,
    language: identical(language, _keep)
        ? element.language
        : language as TextLanguage?,
    playback: identical(playback, _keep)
        ? element.playback
        : playback as AudioPlayback?,
    required: identical(required, _keep) ? element.required : required as bool?,
    // Attributes this row has no field for are kept (Build 258: a Page
    // block's style, alignment, colour, size, read-aloud and link; the
    // speaker of a Dialogue line was dropped here before).
    speakerId: element.speakerId,
    textStyle: element.textStyle,
    align: element.align,
    color: element.color,
    size: element.size,
    readAloud: element.readAloud,
    url: element.url,
    // Build 265 Revision 11: a picture's Plural mark, kept while the element
    // is still a picture (a text element carries it only as an icon key).
    plural: element.isText && !pluralTextRoles.contains(role ?? element.role)
        ? null
        : element.plural,
  );

  static const _keep = Object();

  @override
  Widget build(BuildContext context) {
    final label = switch (element.type) {
      'audio' => 'Audio',
      'image' => 'Image',
      _ => 'Text',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: locked || index == 0 ? null : () => onMove(-1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: locked || index >= count - 1
                      ? null
                      : () => onMove(1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: locked ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            _roleField(context),
            const SizedBox(height: 8),
            if (element.type == 'image') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('asset-${element.asset}'),
                      initialValue: element.asset,
                      readOnly: locked,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Image asset',
                      ),
                      onChanged: (value) => onChanged(
                        _with(asset: value.trim(), sharedImageSource: null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: locked
                        ? null
                        : () async {
                            final asset = await chooseImage();
                            if (asset != null) {
                              onChanged(
                                _with(asset: asset, sharedImageSource: null),
                              );
                            }
                          },
                    child: const Text('Choose'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: element.text,
                readOnly: locked,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Caption (optional)',
                ),
                onChanged: (value) => onChanged(_with(text: value)),
              ),
            ] else ...[
              TextFormField(
                key: const Key('element-text'),
                initialValue: element.text,
                readOnly: locked,
                maxLines: null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: element.type == 'audio' ? 'Spoken text' : 'Text',
                ),
                onChanged: (value) => onChanged(_with(text: value)),
              ),
              if (element.type == 'audio') ...[
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('audio-asset-${element.asset}'),
                  initialValue: element.asset,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Recording (optional media reference)',
                  ),
                  onChanged: (value) => onChanged(_with(asset: value.trim())),
                ),
              ],
              if (!compact && element.type == 'text') ...[
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: element.speaker,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Speaker (dialogue turns)',
                  ),
                  onChanged: (value) => onChanged(_with(speaker: value.trim())),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice<TextLanguage?>(
                  'Language',
                  element.language,
                  const [null, ...TextLanguage.values],
                  (value) => value?.serialized ?? 'Not set',
                  (value) => onChanged(_with(language: value)),
                ),
                if (element.type == 'audio')
                  _choice<AudioPlayback?>(
                    'Playback',
                    element.playback,
                    const [null, ...AudioPlayback.values],
                    (value) => value?.serialized ?? 'Not set',
                    (value) => onChanged(_with(playback: value)),
                  ),
                if (element.type != 'text')
                  _choice<bool?>(
                    'Required',
                    element.required,
                    const [null, true, false],
                    (value) => switch (value) {
                      null => 'Not set',
                      true => 'Yes',
                      false => 'No',
                    },
                    (value) => onChanged(_with(required: value)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The Role menu (Build 261 Revision 6, owner decision of 2 October
  /// 2026): only the roles QQL reads for this element's type, place and
  /// primitive ([ElementRoles]), each with its description. A stored role
  /// outside them stays selected, marked, and is never rewritten unless
  /// the author picks another.
  Widget _roleField(BuildContext context) {
    final offered = ElementRoles.offered(
      type: element.type,
      place: place,
      primitive: primitive,
    );
    final current = ElementRoles.find(
      element.role,
      type: element.type,
      place: place,
      primitive: primitive,
    );
    final note = current == null
        ? ElementRoles.notOfferedNote(
            element.role,
            type: element.type,
            place: place,
          )
        : null;
    String name(String id) => id.isEmpty ? '(none)' : id;
    final entries = [
      if (current == null)
        (id: element.role, description: 'Kept as stored: $note.'),
      for (final role in offered) (id: role.id, description: role.description),
    ];
    final small = Theme.of(context).textTheme.bodySmall;
    return DropdownButtonFormField<String>(
      // Keyed by the menu's contents, so a new primitive or type rebuilds it.
      key: ValueKey(
        'element-role-${primitive.serialized}-${place.name}-${element.type}',
      ),
      initialValue: element.role,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: 'Role',
        helperText: current?.description ?? 'Kept as stored: $note.',
        helperMaxLines: 3,
      ),
      selectedItemBuilder: (context) => [
        for (final entry in entries)
          Text(
            entry.id == element.role && current == null
                ? '${name(entry.id)} ($note)'
                : name(entry.id),
            overflow: TextOverflow.ellipsis,
          ),
      ],
      items: [
        for (final entry in entries)
          DropdownMenuItem<String>(
            value: entry.id,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name(entry.id),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(entry.description, style: small),
                ],
              ),
            ),
          ),
      ],
      onChanged: locked
          ? null
          : (value) {
              if (value != null && value != element.role) {
                onChanged(_with(role: value));
              }
            },
    );
  }

  Widget _choice<T>(
    String label,
    T current,
    List<T> values,
    String Function(T) name,
    ValueChanged<T> onSelected,
  ) => SizedBox(
    width: 170,
    child: DropdownButtonFormField<T>(
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        isDense: true,
      ),
      items: [
        for (final value in values)
          DropdownMenuItem<T>(value: value, child: Text(name(value))),
      ],
      onChanged: locked ? null : (value) => onSelected(value as T),
    ),
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.locked,
    required this.showSide,
    required this.primitive,
    required this.chooseImage,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final ExerciseItem item;
  final int index;
  final int count;
  final bool locked;
  final bool showSide;
  final ExercisePrimitive primitive;
  final Future<String?> Function() chooseImage;
  final ValueChanged<ExerciseItem> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1} · ${item.id}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Move up',
                onPressed: locked || index == 0 ? null : () => onMove(-1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: locked || index >= count - 1
                    ? null
                    : () => onMove(1),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: locked ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // Below the header, so the header fits a 360-pixel window (Build
          // 261 Revision 6 follow-up).
          if (showSide) ...[
            DropdownButtonFormField<MatchSide?>(
              key: ValueKey('item-side-${item.id}'),
              initialValue: item.side,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Side',
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: _menuText('No side')),
                DropdownMenuItem(
                  value: MatchSide.left,
                  child: _menuText('Left'),
                ),
                DropdownMenuItem(
                  value: MatchSide.right,
                  child: _menuText('Right'),
                ),
              ],
              onChanged: locked
                  ? null
                  : (value) => onChanged(
                      ExerciseItem(
                        id: item.id,
                        content: item.content,
                        side: value,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
          for (var i = 0; i < item.content.length; i++)
            _ElementRow(
              key: ValueKey('${item.id}-$i-${item.content[i].type}'),
              element: item.content[i],
              primitive: primitive,
              place: ElementPlace.item,
              index: i,
              count: item.content.length,
              locked: locked,
              compact: true,
              chooseImage: chooseImage,
              onChanged: (element) {
                final content = List<PromptElement>.of(item.content);
                content[i] = element;
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
              onMove: (delta) {
                final content = List<PromptElement>.of(item.content);
                final moved = content.removeAt(i);
                content.insert(i + delta, moved);
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
              onRemove: () {
                final content = List<PromptElement>.of(item.content)
                  ..removeAt(i);
                onChanged(
                  ExerciseItem(id: item.id, content: content, side: item.side),
                );
              },
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final type in const ['text', 'audio', 'image'])
                OutlinedButton.icon(
                  onPressed: locked
                      ? null
                      : () => onChanged(
                          ExerciseItem(
                            id: item.id,
                            content: [
                              ...item.content,
                              PromptElement(type: type),
                            ],
                            side: item.side,
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: Text(switch (type) {
                    'audio' => 'Audio',
                    'image' => 'Image',
                    _ => 'Text',
                  }),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    super.key,
    required this.target,
    required this.locked,
    required this.onChanged,
    required this.onRemove,
  });

  final ExerciseTarget target;
  final bool locked;
  final ValueChanged<ExerciseTarget> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(target.id)),
              IconButton(
                tooltip: 'Remove',
                onPressed: locked ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          // Below the ID, so the row fits a 360-pixel window (Build 261
          // Revision 6 follow-up).
          DropdownButtonFormField<TargetReveal?>(
            key: ValueKey('target-reveal-${target.id}'),
            initialValue: target.reveal,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Reveal',
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: null, child: _menuText('Reveal nothing')),
              DropdownMenuItem(
                value: TargetReveal.firstGrapheme,
                child: _menuText('Reveal the first letter'),
              ),
            ],
            onChanged: locked
                ? null
                : (value) => onChanged(
                    ExerciseTarget(
                      id: target.id,
                      reveal: value,
                      region: target.region,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _LayoutRow extends StatelessWidget {
  const _LayoutRow({
    super.key,
    required this.element,
    required this.index,
    required this.count,
    required this.locked,
    required this.targetIds,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
  });

  final LayoutElement element;
  final int index;
  final int count;
  final bool locked;
  final List<String> targetIds;
  final ValueChanged<LayoutElement> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: element.isTarget
              ? DropdownButtonFormField<String>(
                  initialValue: targetIds.contains(element.targetId)
                      ? element.targetId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Gap',
                  ),
                  items: [
                    for (final id in targetIds)
                      DropdownMenuItem(value: id, child: _menuText(id)),
                  ],
                  onChanged: locked
                      ? null
                      : (value) {
                          if (value != null) {
                            onChanged(LayoutElement.target(value));
                          }
                        },
                )
              : TextFormField(
                  initialValue: element.text,
                  readOnly: locked,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Text',
                  ),
                  onChanged: (value) => onChanged(LayoutElement.text(value)),
                ),
        ),
        IconButton(
          tooltip: 'Move up',
          onPressed: locked || index == 0 ? null : () => onMove(-1),
          icon: const Icon(Icons.arrow_upward),
        ),
        IconButton(
          tooltip: 'Move down',
          onPressed: locked || index >= count - 1 ? null : () => onMove(1),
          icon: const Icon(Icons.arrow_downward),
        ),
        IconButton(
          tooltip: 'Remove',
          onPressed: locked ? null : onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

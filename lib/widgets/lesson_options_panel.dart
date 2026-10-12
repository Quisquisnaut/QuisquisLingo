import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/lesson_options.dart';
import '../services/timed_round_rules.dart';
import 'editor_dialogs.dart';

/// The Course Editor's **Lesson Options**: the Course-level settings shown
/// under the Lessons tile (Build 272 Revision 4: a widget of its own;
/// before, members of the Course Editor screen).
///
/// It draws the working copy and hands every change to [onChanged] as a new
/// Course; what a change does to the Course is [LessonOptions]' rule. While
/// [canModify] is false every control is greyed.
///
/// The panel is one item of the Course Editor's list, and a list lets go of
/// an item that leaves the screen (the page shrinks under a dialog when the
/// keyboard opens). So its dialogs and messages open on [host], the page
/// itself, and a dialog's answer is staged while the page is there, whether
/// the panel still is or not; and a change starts from [working] as it is
/// at that moment, not from the Course that was drawn.
class LessonOptionsPanel extends StatefulWidget {
  const LessonOptionsPanel({
    super.key,
    required this.working,
    required this.canModify,
    required this.onChanged,
    required this.host,
  });

  /// The Course Editor's working copy, read whenever it is needed.
  final Course Function() working;

  /// Whether the Course Editor is in Edit mode with the right to edit.
  final bool canModify;

  /// The Course with one setting changed, to stage in the working copy.
  final ValueChanged<Course> onChanged;

  /// The Course Editor page: where the panel's dialogs and messages open.
  final BuildContext host;

  @override
  State<LessonOptionsPanel> createState() => _LessonOptionsPanelState();
}

class _LessonOptionsPanelState extends State<LessonOptionsPanel> {
  /// Raised when a custom label is cancelled, so the numbering menu is drawn
  /// again from the Course's unchanged numbering.
  int _numberingFieldVersion = 0;
  int _roundNumberingFieldVersion = 0;

  Course get _course => widget.working();

  bool get _canModify => widget.canModify;

  void _updateDraft(Course course) => widget.onChanged(course);

  /// The label of a Lesson numbering of earlier Courses, still shown for a
  /// Course that has it.
  String? get _earlierNumbering =>
      LessonOptions.earlierLessonNumberingLabel(_course.lessonNumberingMode);

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: _lessonOptions());

  /// Use GuideBook off asks first (Build 267, owner decision of 6 October
  /// 2026: explain that the GuideBook is recommended).
  Future<bool> _confirmGuidebookOff(BuildContext host) async =>
      await showDialog<bool>(
        context: host,
        builder: (dialogContext) => AlertDialog(
          key: const Key('course-use-guidebook-off-notice'),
          title: const Text('Turn off the GuideBook?'),
          content: const SingleChildScrollView(
            child: Text(
              'The GuideBook is recommended. Without it there is no Round '
              'Wizard, no Word Lookup, no Open GuideBook on Before you start '
              'cards and no vocabulary in Review.\n\n'
              'The GuideBooks you have written are kept: learners do not see '
              'them while it is off, and they come back when you turn it on '
              'again.',
            ),
          ),
          actions: [
            TextButton(
              key: const Key('course-use-guidebook-turn-off'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Turn it off'),
            ),
            FilledButton(
              key: const Key('course-use-guidebook-keep'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it on'),
            ),
          ],
        ),
      ) ??
      false;

  void _setDefaultTimedLimits(List<int> limits) {
    _updateDraft(LessonOptions.apply(_course, defaultTimedLimits: limits));
  }

  Future<void> _editDefaultTimedLimit(int? index) async {
    if (!_canModify) return;
    final host = widget.host;
    final seconds = await chooseTimedLimit(host);
    if (seconds == null || !host.mounted) return;
    final limits = LessonOptions.timedLimitsWith(
      _course.defaultTimedLimitsSeconds,
      seconds,
      index: index,
    );
    if (limits == null) {
      ScaffoldMessenger.of(host).showSnackBar(
        const SnackBar(content: Text(LessonOptions.timedLimitRepeated)),
      );
      return;
    }
    _setDefaultTimedLimits(limits);
  }

  void _moveDefaultTimedLimit(int index, int offset) {
    _setDefaultTimedLimits(
      LessonOptions.timedLimitsMoved(
        _course.defaultTimedLimitsSeconds,
        index,
        offset,
      ),
    );
  }

  List<Widget> _lessonOptions() => [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DropdownButtonFormField<LessonNumberingMode>(
        key: ValueKey(
          'lesson-numbering-${_course.lessonNumberingMode.name}-$_numberingFieldVersion',
        ),
        initialValue: _course.lessonNumberingMode,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Lesson label and numbering',
        ),
        items: [
          const DropdownMenuItem(
            value: LessonNumberingMode.none,
            child: Text('Off'),
          ),
          const DropdownMenuItem(
            value: LessonNumberingMode.lesson,
            child: Text('Lesson + number'),
          ),
          const DropdownMenuItem(
            value: LessonNumberingMode.numberOnly,
            child: Text('Number only'),
          ),
          // Build 270 Revision 12 (owner report): the label chosen shows
          // in the menu itself.
          DropdownMenuItem(
            value: LessonNumberingMode.other,
            child: Text(
              LessonOptions.customNumberingText(_course.customLessonLabel),
            ),
          ),
          if (_earlierNumbering != null)
            DropdownMenuItem(
              value: _course.lessonNumberingMode,
              child: Text('$_earlierNumbering + number (existing)'),
            ),
        ],
        onChanged: _canModify ? _setLessonNumbering : null,
      ),
    ),
    if (_course.lessonNumberingMode == LessonNumberingMode.other)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextButton(
          onPressed: _canModify
              ? () => _setLessonNumbering(LessonNumberingMode.other)
              : null,
          child: Text('Custom Lesson label: ${_course.customLessonLabel}'),
        ),
      ),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DropdownButtonFormField<RoundNumberingMode>(
        key: ValueKey(
          'round-numbering-${_course.roundNumberingMode.name}-$_roundNumberingFieldVersion',
        ),
        initialValue: _course.roundNumberingMode,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Round label and numbering',
        ),
        items: [
          const DropdownMenuItem(
            value: RoundNumberingMode.off,
            child: Text('Off'),
          ),
          const DropdownMenuItem(
            value: RoundNumberingMode.roundAndNumber,
            child: Text('Round + number'),
          ),
          const DropdownMenuItem(
            value: RoundNumberingMode.numberOnly,
            child: Text('Number only'),
          ),
          DropdownMenuItem(
            value: RoundNumberingMode.customAndNumber,
            child: Text(
              LessonOptions.customNumberingText(_course.customRoundLabel),
            ),
          ),
        ],
        onChanged: _canModify ? _setRoundNumbering : null,
      ),
    ),
    if (_course.roundNumberingMode == RoundNumberingMode.customAndNumber)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextButton(
          onPressed: _canModify
              ? () => _setRoundNumbering(RoundNumberingMode.customAndNumber)
              : null,
          child: Text('Custom Round label: ${_course.customRoundLabel}'),
        ),
      ),
    // Lesson Options lists GuideBook, Duel, Timed, then Picture answers
    // (owner decision of 4 October 2026, Build 263 Revision 2 follow-up).
    SwitchListTile(
      key: const Key('course-use-guidebook'),
      title: const Text('Use GuideBook'),
      value: _course.useGuidebook,
      onChanged: _canModify
          ? (value) async {
              // Build 267 (owner decision): turning it off says first why
              // the GuideBook is recommended.
              final host = widget.host;
              if (!value && !await _confirmGuidebookOff(host)) return;
              if (!host.mounted) return;
              _updateDraft(LessonOptions.apply(_course, useGuidebook: value));
            }
          : null,
    ),
    // Build 265: Word Lookup reads the GuideBooks, so it exists only while
    // Use GuideBook is on (owner decision of 5 October 2026).
    if (_course.useGuidebook)
      SwitchListTile(
        key: const Key('course-word-lookup'),
        title: const Text('Word Lookup'),
        subtitle: const Text(
          'Learners can tap a word of the learning language to see its translation from the GuideBook vocabulary. Never in Test Rounds or Duels.',
        ),
        value: _course.wordLookup,
        onChanged: _canModify
            ? (value) =>
                  _updateDraft(LessonOptions.apply(_course, wordLookup: value))
            : null,
      ),
    SwitchListTile(
      key: const Key('course-create-duels'),
      title: const Text('Create Duels'),
      subtitle: const Text(
        'When enough eligible Exercises are available, winning a Duel unlocks the next Lesson without completing the preceding Lesson.',
      ),
      value: _course.createDuels,
      onChanged: _canModify
          ? (value) =>
                _updateDraft(LessonOptions.apply(_course, createDuels: value))
          : null,
    ),
    const ListTile(
      title: Text('Default Timed limits'),
      subtitle: Text(
        'New Timed Rounds copy these limits in order. Existing Rounds keep their own limits.',
      ),
    ),
    for (
      var index = 0;
      index < _course.defaultTimedLimitsSeconds.length;
      index++
    )
      ListTile(
        key: Key('default-timed-limit-$index'),
        title: Text(
          'Stage ${index + 1} · ${TimedRoundRules.label(_course.defaultTimedLimitsSeconds[index])}',
        ),
        onTap: _canModify ? () => _editDefaultTimedLimit(index) : null,
        trailing: _canModify
            ? Wrap(
                children: [
                  IconButton(
                    key: Key('default-timed-limit-up-$index'),
                    tooltip: 'Move up',
                    onPressed: index == 0
                        ? null
                        : () => _moveDefaultTimedLimit(index, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    key: Key('default-timed-limit-down-$index'),
                    tooltip: 'Move down',
                    onPressed:
                        index == _course.defaultTimedLimitsSeconds.length - 1
                        ? null
                        : () => _moveDefaultTimedLimit(index, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    key: Key('default-timed-limit-remove-$index'),
                    tooltip: 'Remove time limit',
                    onPressed: () => _setDefaultTimedLimits(
                      LessonOptions.timedLimitsWithout(
                        _course.defaultTimedLimitsSeconds,
                        index,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : null,
      ),
    if (_canModify)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('default-timed-limit-add'),
            onPressed: () => _editDefaultTimedLimit(null),
            icon: const Icon(Icons.add),
            label: const Text('Add default time limit'),
          ),
        ),
      ),
    // Build 263 Revision 2 (owner decisions of 4 October 2026): how picture
    // answers look in this Course unless an exercise chooses otherwise.
    const ListTile(
      title: Text('Picture answers'),
      subtitle: Text(
        'How Select the image and Listen and pick the image show their '
        'pictures: large squares, two per row (in a new Course with a thin '
        'grey line around each), unless you choose otherwise here. An '
        'exercise can choose its own look.',
      ),
    ),
    _pictureAnswerOption<PictureSize>(
      key: 'course-picture-size',
      label: 'Picture size',
      value: _course.pictureAnswers.size,
      choices: const {PictureSize.large: 'Large', PictureSize.normal: 'Normal'},
      apply: (style, value) => style.copyWith(size: value),
    ),
    _pictureAnswerOption<PictureShape>(
      key: 'course-picture-shape',
      label: 'Picture shape',
      value: _course.pictureAnswers.shape,
      choices: const {
        PictureShape.square: 'Square, cropped',
        PictureShape.round: 'Round',
      },
      apply: (style, value) => style.copyWith(shape: value),
    ),
    _pictureAnswerOption<PicturesPerRow>(
      key: 'course-pictures-per-row',
      label: 'Pictures per row',
      value: _course.pictureAnswers.perRow,
      choices: const {
        PicturesPerRow.one: '1',
        PicturesPerRow.two: '2',
        PicturesPerRow.three: '3',
        PicturesPerRow.automatic: 'As many as fit',
      },
      apply: (style, value) => style.copyWith(perRow: value),
    ),
    // Build 267 Revision 7 (owner decisions of 9 October 2026).
    _pictureAnswerOption<PictureBorder>(
      key: 'course-picture-border',
      label: 'Picture border',
      value: _course.pictureAnswers.border,
      choices: const {
        PictureBorder.thin: 'Thin grey line',
        PictureBorder.none: 'None',
      },
      apply: (style, value) => style.copyWith(border: value),
    ),
  ];

  /// One of the Course's picture answer defaults in Lesson Options.
  Widget _pictureAnswerOption<T extends OptionEnumValue>({
    required String key,
    required String label,
    required T value,
    required Map<T, String> choices,
    required PictureAnswerStyle Function(PictureAnswerStyle style, T value)
    apply,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$key-${value.serialized}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      items: [
        for (final entry in choices.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: _canModify
          ? (selected) {
              if (selected == null || selected == value) return;
              _updateDraft(
                LessonOptions.apply(
                  _course,
                  pictureAnswers: apply(_course.pictureAnswers, selected),
                ),
              );
            }
          : null,
    ),
  );

  Future<void> _setLessonNumbering(LessonNumberingMode? mode) async {
    if (!_canModify || mode == null) return;
    var label = _course.customLessonLabel;
    if (mode == LessonNumberingMode.other) {
      final host = widget.host;
      final entered = await askAuthoringName(
        host,
        title: 'Custom Lesson label',
        initial: label,
        confirmLabel: 'Apply',
        maxLength: 40,
        fieldLabel: 'Label',
      );
      if (!host.mounted) return;
      if (entered == null) {
        // Rebuild the field from the unchanged canonical selection on Cancel.
        if (mounted) setState(() => _numberingFieldVersion++);
        return;
      }
      label = entered;
    }
    _updateDraft(
      LessonOptions.apply(
        _course,
        lessonNumbering: mode,
        customLessonLabel: label,
      ),
    );
  }

  Future<void> _setRoundNumbering(RoundNumberingMode? mode) async {
    if (!_canModify || mode == null) return;
    var label = _course.customRoundLabel;
    if (mode == RoundNumberingMode.customAndNumber) {
      final host = widget.host;
      final entered = await askAuthoringName(
        host,
        title: 'Custom Round label',
        initial: label,
        confirmLabel: 'Apply',
        maxLength: 40,
        fieldLabel: 'Label',
      );
      if (!host.mounted) return;
      if (entered == null) {
        if (mounted) setState(() => _roundNumberingFieldVersion++);
        return;
      }
      label = entered;
    }
    _updateDraft(
      LessonOptions.apply(
        _course,
        roundNumbering: mode,
        customRoundLabel: label,
      ),
    );
  }
}

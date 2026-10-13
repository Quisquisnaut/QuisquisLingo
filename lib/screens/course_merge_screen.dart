import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/course_import_check.dart';
import '../services/course_merge_selection.dart';
import '../services/course_merge_service.dart';
import '../services/course_package_service.dart';
import '../services/sound_effect_service.dart';
import '../widgets/file_dialog_feedback.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/quick_import_access.dart';
import '../widgets/course_import_check_dialog.dart';
import '../widgets/course_package_notes.dart';

class CourseMergeScreen extends StatefulWidget {
  const CourseMergeScreen({
    super.key,
    required this.leftCourse,
    required this.onMerge,
    this.mergeService,
    this.checkCourse,
  });

  final Course leftCourse;
  final Future<void> Function(
    Course right,
    List<LessonMergeChoice> choices,
    CourseMergeOptions options,
  )
  onMerge;
  final CourseMergeService? mergeService;

  /// The check of the second Course's file (Build 272 Revision 13): its
  /// pop-up is shown once, when the Course is loaded, as an import shows it.
  /// Course Studio gives it; without it, or when it gives no check, the page
  /// takes the Course at once.
  final Future<CourseImportCheck?> Function(CoursePackage package)? checkCourse;

  @override
  State<CourseMergeScreen> createState() => _CourseMergeScreenState();
}

class _CourseMergeScreenState extends State<CourseMergeScreen> {
  late final CourseMergeService _merge =
      widget.mergeService ?? CourseMergeService();

  /// What the author has chosen for the two Courses; null until the second
  /// Course is loaded (Build 272 Revision 11).
  CourseMergeSelection? _selection;
  CoursePackage? _rightPackage;
  bool _showInternalIds = false;
  bool _loading = false;
  bool _submitting = false;
  final _sounds = SoundEffectService();

  Future<void> _loadMergeCourse({bool fromDialog = false}) async {
    if (!fromDialog) {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _merge.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _loadMergeCourse(fromDialog: true);
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    setState(() => _loading = true);
    try {
      final CoursePackage loaded;
      if (fromDialog) {
        // Merge From…: same validation as merge.json, then the same
        // compatibility check below.
        final picked = await _merge.readMergePackageFromDialog();
        if (!mounted) return;
        final opened = picked.package;
        if (opened == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: mergeImportFallbackHint,
          );
          return;
        }
        loaded = opened;
      } else {
        loaded = await _merge.readMergePackage();
      }
      final right = loaded.course;
      _merge.validateCompatibility(widget.leftCourse, right);
      final check = await widget.checkCourse?.call(loaded);
      final goesOn =
          check == null ||
          (mounted &&
              await confirmCourseFile(
                context,
                course: right,
                check: check,
                use: CourseFileUse.merge,
              ));
      if (!goesOn || !mounted) {
        // The Merge stays as it was; a file read for nothing is let go.
        if (!identical(_rightPackage, loaded)) unawaited(loaded.discard());
        return;
      }
      // The package being replaced no longer needs its staged media.
      final previous = _rightPackage;
      if (previous != null && !identical(previous, loaded)) {
        unawaited(previous.discard());
      }
      setState(() {
        _selection = CourseMergeSelection(widget.leftCourse, right);
        _rightPackage = loaded;
      });
      if (loaded.hadMatchingFolderWrapper) {
        showMatchingZipFolderWarning(context);
      }
    } catch (error) {
      unawaited(_sounds.playDefeat());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course merge could not start: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_sounds.dispose());
    if (!_submitting) {
      unawaited(_rightPackage?.discard() ?? Future<void>.value());
    }
    super.dispose();
  }

  void _selectAll(LessonMergeChoice choice) {
    final selection = _selection;
    if (selection == null) return;
    setState(() => selection.selectAll(choice));
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Course Merge Help'),
        content: SingleChildScrollView(
          child: Text(
            'The Course Merge tool is not intended for merging two completely different courses. '
            'A typical usage case would be two team members working on the same course: while team member, John, edits, say, lessons 1 to 5, another team member, Jane, edits lessons 6 to 8. The Merge Tool allows them, or a third member, to assemble the two sets of lessons into one unified course. Another usage case would be the same editor who wants to merge two versions of the course they are working at: let’s say they want to use lessons 1, 3, and 7 from the first version, and lessons 2, 4, 5, and 6 from the second version.\n\n'
            'Copy the second Course package to ${courseFileLabel(QqlStorageRole.mergeImports, 'merge.zip')}, or a media-free JSON to merge.json. '
            'A ZIP normally has its package files at the root. QQL also accepts one enclosing folder whose name exactly matches the ZIP filename without .zip, and shows a non-blocking warning. For merge.zip, that folder must be named merge. '
            'Both Courses must be custom. If their Course IDs match, the Course version or Modified date and time must differ.\n\n'
            'Author, Maintainer, source/target language, Original Course '
            'Creator, Assigned Team, authors and roles, Rights Holders, license/'
            'derivative policy, language tags/text direction/TTS language, language '
            'variant, custom Lesson icons, and audio configuration/library must match. '
            'Title, Publication state, Create Duels, Use GuideBooks, Lesson label and numbering/custom '
            'label, Section names, Buy a Coffee metadata, description, Flag and language '
            'levels may differ. '
            'The merge lets you choose Left or Right for each differing setting; either '
            'unpublished source makes the result unpublished.\n\n'
            'Course ID, original-created/modified dates, Course version/version notes, '
            'restore metadata, Last Version Editor details, merge provenance and Lessons '
            'may differ. Lessons are the merge payload. Check each selected Lesson '
            'carefully before merging.\n\n'
            'When the second Course is loaded, a window shows what the check '
            'of its file found, as at import: its anomalies to look at '
            '(Continue anyway or Cancel), or that none were found, with the '
            'Course’s authors, Maintainer, Team, last edit, license and '
            'numbers (Continue or Cancel). See the Audit opens the Course '
            'Audit of that file.\n\n'
            'The new Course gets a fresh ID and “ merged” title suffix. It retains the '
            'earliest Original Course Created date, records the merge-time Modified date '
            'and active Last Version Editor, starts at version 1, and records both source '
            'Course IDs and versions. Learner progress is never merged.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    final right = selection?.right;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Merge'),
        actions: [
          IconButton(
            key: const Key('course-merge-help'),
            tooltip: 'Merge Help',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            key: const Key('course-merge-internal-ids'),
            tooltip: _showInternalIds
                ? 'Hide internal IDs'
                : 'Show internal IDs',
            onPressed: () =>
                setState(() => _showInternalIds = !_showInternalIds),
            isSelected: _showInternalIds,
            color: _showInternalIds
                ? Theme.of(context).colorScheme.primary
                : null,
            icon: Icon(_showInternalIds ? Icons.badge : Icons.badge_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (selection == null || right == null) ...[
            FilledButton.icon(
              key: const Key('merge-course-json-primary'),
              onPressed: _loading || _submitting ? null : _loadMergeCourse,
              icon: const Icon(Icons.merge_type_outlined),
              label: const Text('Merge Course package or JSON'),
            ),
            if (_merge.fileDialogsAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('merge-course-json-from'),
                onPressed: _loading || _submitting
                    ? null
                    : () => _loadMergeCourse(fromDialog: true),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Merge From…'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the second Course package ZIP or media-free JSON with the system file dialog. '
                'It is checked exactly like the Merge folder route.',
              ),
              const SizedBox(height: 8),
              Text(
                cloudFolderHelpText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Merge instructions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Copy the compatible Course package to ${courseFileLabel(QqlStorageRole.mergeImports, 'merge.zip')}, or a media-free JSON to merge.json. Keep only one.\n'
              '2. A ZIP may have its files at the root or inside one folder named merge. QQL accepts the matching folder with a warning. Select Merge Course package or JSON; QQL validates both Course information blocks before changing local storage.\n'
              '3. Choose the origin of every Lesson you want to include, then check the selections carefully.\n'
              '4. DO MERGE! creates a third independent Course and leaves both sources and the imported file unchanged.\n'
              '5. The new merged Course will be available in Course Studio.',
            ),
          ] else ...[
            Text(
              'Left Course: ${widget.leftCourse.title} · Version ${widget.leftCourse.courseVersion} · Last edited ${widget.leftCourse.modifiedAtUtc}',
            ),
            Text(
              'Right Course: ${right.title} · Version ${right.courseVersion} · Last edited ${right.modifiedAtUtc}',
            ),
            if (_showInternalIds) ...[
              Text('Left Course ID: ${widget.leftCourse.courseId}'),
              Text('Right Course ID: ${right.courseId}'),
            ],
            const SizedBox(height: 12),
            Text(
              'Select Lessons carefully',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Choose the left or right source for each Lesson. An unchecked row is omitted; a Lesson cannot come from both Courses.',
            ),
            for (final setting in selection.differing)
              _sideChoice(
                label: setting.label,
                value: selection.sideOf(setting),
                onChanged: (side) =>
                    setState(() => selection.setSide(setting, side)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => _selectAll(LessonMergeChoice.left),
                  child: const Text('Select all Left'),
                ),
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => _selectAll(LessonMergeChoice.right),
                  child: const Text('Select all Right'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _lessonChoiceTable(selection),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading || _submitting || !selection.hasSelection
                  ? null
                  : () async {
                      if (_submitting) return;
                      final package = _rightPackage!;
                      final choices = List<LessonMergeChoice>.of(
                        selection.choices,
                      );
                      final options = selection.options;
                      setState(() => _submitting = true);
                      try {
                        await package.withInstalledMedia(
                          right.courseId,
                          () => widget.onMerge(right, choices, options),
                          keepOnSuccess: false,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Course merge failed: $error'),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _submitting = false);
                        } else {
                          unawaited(package.discard());
                        }
                      }
                    },
              child: const Text('DO MERGE!'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sideChoice({
    required String label,
    required CourseMergeSide value,
    required ValueChanged<CourseMergeSide> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<CourseMergeSide>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: '$label source',
      ),
      items: const [
        DropdownMenuItem(value: CourseMergeSide.left, child: Text('Use Left')),
        DropdownMenuItem(
          value: CourseMergeSide.right,
          child: Text('Use Right'),
        ),
      ],
      onChanged: (side) {
        if (side != null) onChanged(side);
      },
    ),
  );

  Widget _lessonChoiceTable(CourseMergeSelection selection) => Table(
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    columnWidths: const {
      0: FixedColumnWidth(30),
      1: FlexColumnWidth(),
      2: FlexColumnWidth(),
    },
    border: TableBorder.symmetric(
      inside: BorderSide(color: Theme.of(context).dividerColor),
    ),
    children: [
      const TableRow(
        children: [
          Padding(padding: EdgeInsets.all(2), child: Text('#')),
          Padding(padding: EdgeInsets.all(2), child: Text('Left')),
          Padding(padding: EdgeInsets.all(2), child: Text('Right')),
        ],
      ),
      for (var index = 0; index < selection.rowCount; index++)
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text('${index + 1}'),
            ),
            _lessonChoiceCell(
              selection: selection,
              index: index,
              choice: LessonMergeChoice.left,
              lesson: selection.lessonAt(LessonMergeChoice.left, index),
            ),
            _lessonChoiceCell(
              selection: selection,
              index: index,
              choice: LessonMergeChoice.right,
              lesson: selection.lessonAt(LessonMergeChoice.right, index),
            ),
          ],
        ),
    ],
  );

  Widget _lessonChoiceCell({
    required CourseMergeSelection selection,
    required int index,
    required LessonMergeChoice choice,
    required Lesson? lesson,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 30,
          child: Checkbox(
            value: selection.choiceAt(index) == choice,
            onChanged: lesson == null || _submitting
                ? null
                : (selected) => setState(
                    () => selection.choose(index, choice, selected: selected!),
                  ),
          ),
        ),
        Text(
          lesson == null
              ? 'Not available'
              : _showInternalIds
              ? '${lesson.title}\n${lesson.lessonId}'
              : lesson.title,
          maxLines: _showInternalIds ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

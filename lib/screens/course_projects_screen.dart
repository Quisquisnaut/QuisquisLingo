import 'available_courses_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_backup_service.dart';
import '../services/course_editor_service.dart';
import '../services/diagnostic_log_service.dart';
import '../services/course_file_store.dart' show SkippedCourseFile;
import '../services/course_favorite_service.dart';
import '../services/course_library_view_service.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/course_service.dart';
import '../services/course_study.dart';
import '../services/course_wizard.dart';
import '../services/course_library_operations.dart';
import '../services/course_library_categories.dart';
import '../services/course_library_presentation.dart';
import '../services/course_media_store.dart';
import '../services/course_merge_service.dart';
import '../services/course_package_import.dart';
import '../services/course_package_service.dart';
import '../services/course_access_policy.dart';
import '../services/sound_effect_service.dart';
import '../services/publisher_course_export.dart';
import '../widgets/course_library_row.dart';
import '../widgets/course_library_section.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/flag_art.dart';
import 'course_editor_screen.dart';
import 'new_course_dialog.dart';
import 'course_info_screen.dart';
import 'course_wizard_screen.dart';
import 'team_manager_screen.dart';
import 'flat_image_library_screen.dart';
import 'publisher_course_export_screen.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/quick_import_access.dart';
import '../widgets/reported_action.dart';

String _folder(QqlStorageRole role) =>
    QqlStorageLayout.current.folderLabel(role);

String _file(QqlStorageRole role, String name) =>
    QqlStorageLayout.current.fileLabel(role, name);

void _showMatchingZipFolderWarning(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      duration: Duration(seconds: 10),
      content: Text(
        'Accepted a matching ZIP folder. Course package files normally belong at the ZIP root.',
      ),
    ),
  );
}

class CourseImportScreen extends StatelessWidget {
  final Future<void> Function() onImport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function()? onOpenFrom;

  const CourseImportScreen({
    super.key,
    required this.onImport,
    this.onOpenFrom,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course Import')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          key: const Key('import-course-json-primary'),
          onPressed: onImport,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('Quick Import'),
        ),
        const SizedBox(height: 4),
        Text(
          'Reads import.zip or import.json from '
          '${_folder(QqlStorageRole.courseImports)} without a dialog.',
        ),
        if (onOpenFrom != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('open-course-json-from'),
            onPressed: onOpenFrom,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open from…'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a Course package ZIP or a media-free JSON file with the system file dialog. '
            'It is checked exactly like an ordinary import.',
          ),
          const SizedBox(height: 8),
          Text(
            cloudFolderHelpText(),
            key: const Key('cloud-folder-help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Import instructions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '1. Copy a Course package to ${_file(QqlStorageRole.courseImports, 'import.zip')}, or a media-free JSON to import.json. Keep only one.\n'
          '2. A ZIP may have its files at the root or inside one folder named import. QQL accepts the matching folder with a warning. Select Quick Import; QQL validates the complete file before changing local storage.\n'
          '3. If the Course ID already exists, choose Replace/update, Copy as New Course, Fork or Cancel, as available.\n'
          '4. A successful import is added to your courses. Only published courses are available for study. The source file remains in ${_folder(QqlStorageRole.courseImports)}.',
        ),
      ],
    ),
  );
}

/// Export counterpart of [CourseImportScreen]: the fixed-folder route and the
/// system dialog in one place, so the Course Studio menu offers one Export.
class CourseExportScreen extends StatelessWidget {
  final String courseTitle;
  final Future<void> Function() onExport;

  /// Null hides the button (no system dialog on this platform).
  final Future<void> Function()? onSaveTo;

  const CourseExportScreen({
    super.key,
    required this.courseTitle,
    required this.onExport,
    this.onSaveTo,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course Export')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          courseTitle,
          key: const Key('export-course-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('export-course-zip-primary'),
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Quick Export'),
        ),
        const SizedBox(height: 4),
        Text(
          'Writes a ZIP holding course.json and only the images and recordings this Course uses, into ${_folder(QqlStorageRole.courseExports)}, without a dialog.',
        ),
        if (onSaveTo != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('save-course-zip-to'),
            onPressed: onSaveTo,
            icon: const Icon(Icons.save_alt_outlined),
            label: const Text('Save as…'),
          ),
          const SizedBox(height: 4),
          const Text(
            'The same package, saved wherever you choose with the system file dialog.',
          ),
          const SizedBox(height: 8),
          Text(
            cloudFolderHelpText(),
            key: const Key('cloud-folder-help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Export notes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '1. The package always exports the Course as it is stored. Changes still open in the Course Editor are not included until they are confirmed.\n'
          '2. App-bundled QQL images are supplied by the application and are not packaged.\n'
          '3. A Course with blocking Audit errors can still be exported; the result names them so the recipient knows.\n'
          '4. Import the package on another device from Course Studio > Import Course.',
        ),
      ],
    ),
  );
}

class CourseMergeScreen extends StatefulWidget {
  const CourseMergeScreen({
    super.key,
    required this.leftCourse,
    required this.onMerge,
    this.mergeService,
  });

  final Course leftCourse;
  final Future<void> Function(
    Course right,
    List<LessonMergeChoice> choices,
    CourseMergeOptions options,
  )
  onMerge;
  final CourseMergeService? mergeService;

  @override
  State<CourseMergeScreen> createState() => _CourseMergeScreenState();
}

class _CourseMergeScreenState extends State<CourseMergeScreen> {
  late final CourseMergeService _merge =
      widget.mergeService ?? CourseMergeService();
  Course? _rightCourse;
  CoursePackage? _rightPackage;
  List<LessonMergeChoice> _choices = const [];
  CourseMergeSide _createDuelsSide = CourseMergeSide.left;
  CourseMergeSide _useGuidebookSide = CourseMergeSide.left;
  CourseMergeSide _lessonNumberingSide = CourseMergeSide.left;
  CourseMergeSide _sectionNamesSide = CourseMergeSide.left;
  CourseMergeSide _titleSide = CourseMergeSide.left;
  CourseMergeSide _buyACoffeeSide = CourseMergeSide.left;
  CourseMergeSide _descriptionSide = CourseMergeSide.left;
  CourseMergeSide _flagSide = CourseMergeSide.left;
  CourseMergeSide _startLevelSide = CourseMergeSide.left;
  CourseMergeSide _targetLevelSide = CourseMergeSide.left;
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
      if (!mounted) return;
      // The package being replaced no longer needs its staged media.
      final previous = _rightPackage;
      if (previous != null && !identical(previous, loaded)) {
        unawaited(previous.discard());
      }
      setState(() {
        _rightCourse = right;
        _rightPackage = loaded;
        _choices = List.filled(
          [
            widget.leftCourse.lessons.length,
            right.lessons.length,
          ].reduce((a, b) => a > b ? a : b),
          LessonMergeChoice.exclude,
        );
        _createDuelsSide = CourseMergeSide.left;
        _useGuidebookSide = CourseMergeSide.left;
        _lessonNumberingSide = CourseMergeSide.left;
        _sectionNamesSide = CourseMergeSide.left;
        _titleSide = CourseMergeSide.left;
        _buyACoffeeSide = CourseMergeSide.left;
        _descriptionSide = CourseMergeSide.left;
        _flagSide = CourseMergeSide.left;
        _startLevelSide = CourseMergeSide.left;
        _targetLevelSide = CourseMergeSide.left;
      });
      if (loaded.hadMatchingFolderWrapper) {
        _showMatchingZipFolderWarning(context);
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
    final right = _rightCourse;
    if (right == null) return;
    setState(() {
      _choices = List.generate(_choices.length, (index) {
        final available = choice == LessonMergeChoice.left
            ? index < widget.leftCourse.lessons.length
            : index < right.lessons.length;
        return available ? choice : LessonMergeChoice.exclude;
      });
    });
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
            'Copy the second Course package to ${_file(QqlStorageRole.mergeImports, 'merge.zip')}, or a media-free JSON to merge.json. '
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
    final right = _rightCourse;
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
          if (right == null) ...[
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
              '1. Copy the compatible Course package to ${_file(QqlStorageRole.mergeImports, 'merge.zip')}, or a media-free JSON to merge.json. Keep only one.\n'
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
            ..._optionChoices(right),
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
            _lessonChoiceTable(right),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _loading ||
                      _submitting ||
                      _choices.every(
                        (choice) => choice == LessonMergeChoice.exclude,
                      )
                  ? null
                  : () async {
                      if (_submitting) return;
                      final package = _rightPackage!;
                      final choices = List<LessonMergeChoice>.of(_choices);
                      final options = _options(right);
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

  CourseMergeOptions _options(Course right) {
    final createDuels = _createDuelsSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final useGuidebook = _useGuidebookSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final numbering = _lessonNumberingSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final sections = _sectionNamesSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final title = _titleSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final buyACoffee = _buyACoffeeSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final description = _descriptionSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final flag = _flagSide == CourseMergeSide.left ? widget.leftCourse : right;
    final startLevel = _startLevelSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    final targetLevel = _targetLevelSide == CourseMergeSide.left
        ? widget.leftCourse
        : right;
    return CourseMergeOptions(
      title: title.title,
      createDuels: createDuels.createDuels,
      useGuidebook: useGuidebook.useGuidebook,
      lessonNumberingMode: numbering.lessonNumberingMode,
      customLessonLabel: numbering.customLessonLabel,
      sectionNames: sections.sectionNames,
      buyACoffeeUrl: buyACoffee.buyACoffeeUrl,
      courseDescription: description.courseDescription,
      startLevel: startLevel.startLevel,
      targetLevel: targetLevel.targetLevel,
      flagCode: flag.flagCode,
      worldFlagId: flag.worldFlagId,
      flagImageBase64: flag.flagImageBase64,
    );
  }

  List<Widget> _optionChoices(Course right) => [
    if (widget.leftCourse.title != right.title)
      _sideChoice(
        label: 'Course title',
        value: _titleSide,
        onChanged: (side) => setState(() => _titleSide = side),
      ),
    if (widget.leftCourse.createDuels != right.createDuels)
      _sideChoice(
        label: 'Create Duels',
        value: _createDuelsSide,
        onChanged: (side) => setState(() => _createDuelsSide = side),
      ),
    if (widget.leftCourse.useGuidebook != right.useGuidebook)
      _sideChoice(
        label: 'Use GuideBooks',
        value: _useGuidebookSide,
        onChanged: (side) => setState(() => _useGuidebookSide = side),
      ),
    if (widget.leftCourse.lessonNumberingMode != right.lessonNumberingMode ||
        widget.leftCourse.customLessonLabel != right.customLessonLabel)
      _sideChoice(
        label: 'Lesson label and numbering',
        value: _lessonNumberingSide,
        onChanged: (side) => setState(() => _lessonNumberingSide = side),
      ),
    if (widget.leftCourse.sectionNames.join('\u0000') !=
        right.sectionNames.join('\u0000'))
      _sideChoice(
        label: 'Section names',
        value: _sectionNamesSide,
        onChanged: (side) => setState(() => _sectionNamesSide = side),
      ),
    if (widget.leftCourse.buyACoffeeUrl != right.buyACoffeeUrl)
      _sideChoice(
        label: 'Buy a Coffee',
        value: _buyACoffeeSide,
        onChanged: (side) => setState(() => _buyACoffeeSide = side),
      ),
    if (widget.leftCourse.courseDescription != right.courseDescription)
      _sideChoice(
        label: 'Course description',
        value: _descriptionSide,
        onChanged: (side) => setState(() => _descriptionSide = side),
      ),
    if (widget.leftCourse.flagCode != right.flagCode ||
        widget.leftCourse.worldFlagId != right.worldFlagId ||
        widget.leftCourse.flagImageBase64 != right.flagImageBase64)
      _sideChoice(
        label: 'Course flag',
        value: _flagSide,
        onChanged: (side) => setState(() => _flagSide = side),
      ),
    if (widget.leftCourse.startLevel != right.startLevel)
      _sideChoice(
        label: 'Start level',
        value: _startLevelSide,
        onChanged: (side) => setState(() => _startLevelSide = side),
      ),
    if (widget.leftCourse.targetLevel != right.targetLevel)
      _sideChoice(
        label: 'Target level',
        value: _targetLevelSide,
        onChanged: (side) => setState(() => _targetLevelSide = side),
      ),
  ];

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

  Widget _lessonChoiceTable(Course right) => Table(
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
      for (var index = 0; index < _choices.length; index++)
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text('${index + 1}'),
            ),
            _lessonChoiceCell(
              index: index,
              choice: LessonMergeChoice.left,
              lesson: index < widget.leftCourse.lessons.length
                  ? widget.leftCourse.lessons[index]
                  : null,
            ),
            _lessonChoiceCell(
              index: index,
              choice: LessonMergeChoice.right,
              lesson: index < right.lessons.length
                  ? right.lessons[index]
                  : null,
            ),
          ],
        ),
    ],
  );

  Widget _lessonChoiceCell({
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
            value: _choices[index] == choice,
            onChanged: lesson == null || _submitting
                ? null
                : (selected) => setState(
                    () => _choices[index] = selected!
                        ? choice
                        : LessonMergeChoice.exclude,
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

class CourseProjectsScreen extends StatefulWidget {
  final Course? currentCourse;
  final bool importOnly;
  final String? initialCourseIdToOpen;

  /// Start New Course once the library is read: the learner's Course
  /// Selector's New Course (Build 267 Revision 6).
  final bool startNewCourse;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final CourseMediaStore? mediaStore;
  final bool embedded;
  final CourseLibrarySort sort;
  final bool showUnavailable;
  final String search;
  final int refreshToken;

  /// Study and Review in the Course menu (Build 261 Revision 1); without it
  /// the menu leaves them out.
  final ValueChanged<CourseStudyRequest>? onStudy;
  const CourseProjectsScreen({
    super.key,
    required this.currentCourse,
    this.importOnly = false,
    this.initialCourseIdToOpen,
    this.startNewCourse = false,
    this.editorService,
    this.transferService,
    this.mediaStore,
    this.embedded = false,
    this.sort = CourseLibrarySort.title,
    this.showUnavailable = true,
    this.search = '',
    this.refreshToken = 0,
    this.onStudy,
  });

  @override
  CourseProjectsScreenState createState() => CourseProjectsScreenState();
}

class CourseProjectsScreenState extends State<CourseProjectsScreen> {
  late final _ops = CourseLibraryOperations(
    editor: widget.editorService,
    transfer: widget.transferService,
  );
  late final _service = _ops.editor;
  late final _transfer = _ops.transfer;
  final _favorites = CourseFavoriteService();
  final _sounds = SoundEffectService();
  CourseManagerLibrary _library = const CourseManagerLibrary();
  bool _loading = true;
  String? _loadError;
  bool _openedInitialCourse = false;
  bool _startedNewCourse = false;

  /// Each section's view, saved per learner (Build 255 Revision 6).
  final _viewService = CourseLibraryViewService();
  Map<CourseLibraryCategory, CourseLibraryView> _sectionViews = const {};

  /// Saved views are read once per learner. Later reloads keep this visit's
  /// choices, which are saved as they are made.
  bool _viewsLoaded = false;
  String? _viewsProfileId;
  Set<String> _favoriteIds = const {};
  Map<String, String> _profileNames = {};

  Future<void> createCourse() => _newCourse();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant CourseProjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCourse != widget.currentCourse ||
        oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final library = await _ops.load(
        currentCourse: widget.currentCourse,
        importOnly: widget.importOnly,
      );
      final favoriteIds = await _favorites.favoriteCourseIds(
        [
          ...library.bundledCourses,
          ...library.personalCourses,
        ].map((course) => course.courseId),
        profileId: library.activeProfileId,
      );
      final profileNames = {
        for (final profile in await _ops.profiles.getProfileRecords())
          profile.learnerProfileId: profile.displayName,
      };
      final profileId = library.activeProfileId;
      final savedViews = _viewsLoaded && _viewsProfileId == profileId
          ? null
          : await _viewService.views(
              CourseLibrarySectionSurface.courseStudio.storageName,
              profileId: profileId,
            );
      if (!mounted) return;
      setState(() {
        _library = library;
        if (savedViews != null) {
          _sectionViews = savedViews;
          _viewsLoaded = true;
          _viewsProfileId = profileId;
        }
        _favoriteIds = favoriteIds;
        _profileNames = profileNames;
        _loading = false;
      });
      if (!_openedInitialCourse && widget.initialCourseIdToOpen != null) {
        _openedInitialCourse = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openInitialCourse(),
        );
      }
      if (!_startedNewCourse && widget.startNewCourse) {
        _startedNewCourse = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _newCourse();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('StateError: ', '');
      });
    }
  }

  /// One unreadable stored Course no longer hides the others; this says which
  /// files were skipped and that they were kept.
  Widget _unreadableCoursesCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('course-manager-unreadable-courses'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _library.unreadable.length == 1
                        ? '1 stored Course could not be read'
                        : '${_library.unreadable.length} stored Courses could not be read',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'The other Courses are listed normally. These files were kept '
              'untouched and are not shown. Importing a Course with the same '
              'ID replaces one; its Maintainer, a member of its Team or an '
              'admin can also remove it (Remove here, or Delete in Advanced '
              '(Admin) › Inventory).',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 6),
            for (final (index, file) in _library.unreadable.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '${file.fileName}: ${file.reason}',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                    if (file.isRemovableCustomCourse)
                      TextButton.icon(
                        key: ValueKey(
                          'course-manager-unreadable-remove-$index',
                        ),
                        onPressed: () => _removeUnopenable(file),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove…'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInitialCourse() async {
    if (!mounted) return;
    final courseId = widget.initialCourseIdToOpen;
    if (courseId == null) return;
    final course = _library.personalCourse(courseId);
    if (course != null) {
      await _openUser(course);
      return;
    }
    if (widget.currentCourse?.courseId == courseId) await _openBundled();
  }

  Future<void> _openCourseImport() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CourseImportScreen(
        onImport: _importCourse,
        onOpenFrom: _transfer.fileDialogsAvailable
            ? _importCourseFromDialog
            : null,
      ),
    ),
  );

  Future<void> _openCourseExport(Course course) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CourseExportScreen(
            courseTitle: course.title,
            onExport: () => _exportCourse(course),
            onSaveTo: _transfer.fileDialogsAvailable
                ? () => _saveCourseTo(course)
                : null,
          ),
        ),
      );

  /// Export as Publisher Course (Build 262 Revision 2).
  Future<void> _openPublisherExport(Course course) async {
    final loaded = await runReported(
      context,
      'Export as Publisher Course',
      () async => (
        refusals: await _ops.publisherExportRefusals(course),
        remembered: await _ops.rememberedPublisher(course),
      ),
    );
    if (loaded == null || !mounted) return;
    final refusals = loaded.refusals;
    final remembered = loaded.remembered;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PublisherCourseExportScreen(
          course: course,
          refusals: refusals,
          initialPublisher: remembered,
          onExport: (publisher) => _exportAsPublisher(course, publisher),
          onSaveTo: _transfer.fileDialogsAvailable
              ? (publisher) => _savePublisherCourseTo(course, publisher)
              : null,
        ),
      ),
    );
  }

  Future<void> _openCourseMerge(Course course) => Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          builder: (_) => CourseMergeScreen(
            leftCourse: course,
            onMerge: (right, choices, options) =>
                _completeMerge(course, right, choices, options),
          ),
        ),
      )
      .then((_) => _reload());

  Future<void> _completeMerge(
    Course left,
    Course right,
    List<LessonMergeChoice> choices,
    CourseMergeOptions options,
  ) async {
    try {
      final proposal = await _ops.composeMerge(
        left: left,
        right: right,
        choices: choices,
        options: options,
        library: _library,
      );
      if (!mounted) return;
      if (proposal.hasAuditWarnings) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Course Audit warnings'),
            content: const Text(
              'The merged Course has Audit warnings. Review the generated Course before publication.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
      final result = await _ops.confirmMerge(proposal);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showConfirmationResult(result);
    } catch (error) {
      unawaited(_sounds.playDefeat());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Course merge failed: $error')));
      }
    }
  }

  /// New Course's form. [prefill] carries the title, languages and variant
  /// of the Course Wizard's first screen (Build 267, Continue by hand).
  Future<Course?> _createCourse({CourseWizardBasics? prefill}) async {
    // Build 270 Revision 7: learner data that cannot be read is reported.
    final profiles = await runReported(
      context,
      'New Course',
      () async => (
        active: await _ops.profiles.getActiveProfileRecord(),
        all: await _ops.profiles.getProfileRecords(),
      ),
    );
    if (profiles == null) return null;
    final activeProfile = profiles.active;
    if (activeProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select or create a learner profile first.'),
          ),
        );
      }
      return null;
    }
    if (!mounted) return null;
    return showNewCourseDialog(
      context,
      creator: activeProfile,
      maintainers: profiles.all,
      operations: _ops,
      // Asked when Continue to Editor is pressed, of the list as it is then.
      titleTaken: (title) => _library.hasCourseTitled(title),
      prefill: prefill,
    );
  }

  /// The Courses whose Course Wizard is paused and this learner may
  /// continue (Maintainer or Team member).
  List<Course> get _pausedWizardCourses => [
    for (final course in _library.personalCourses)
      if (_library.pausedWizards.containsKey(course.courseId) &&
          _library
              .entriesFor(course)
              .any(
                (entry) =>
                    entry.action == CourseManagerAction.continueCourseWizard &&
                    entry.available,
              ))
        course,
  ];

  /// New Course with Course Wizards still paused (owner, 9 October 2026):
  /// each one can be continued, or a new Course started. The chosen Course,
  /// true for a new one, null to cancel.
  Future<Object?> _askAboutPausedWizards(List<Course> paused) =>
      showDialog<Object>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('new-course-paused-wizards'),
          title: Text(
            paused.length == 1
                ? 'A Course Wizard is still paused'
                : '${paused.length} Course Wizards are still paused',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You started these Courses with the Course Wizard and have '
                  'not finished them. Continue one, or start a new Course.',
                ),
                const SizedBox(height: 8),
                for (final (index, course) in paused.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(course.title),
                    subtitle: Text(
                      _library.pausedWizards[course.courseId]!.describe(course),
                    ),
                    trailing: TextButton(
                      key: ValueKey('new-course-paused-continue-$index'),
                      onPressed: () => Navigator.pop(dialogContext, course),
                      child: const Text('Continue'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('new-course-paused-cancel'),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('new-course-paused-new'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Start a new Course'),
            ),
          ],
        ),
      );

  /// New Course opens the Course Wizard's first screen (Build 267); its
  /// Continue by hand continues with New Course's form. Paused Course
  /// Wizards are named first (Revision 6).
  Future<void> _newCourse() async {
    final paused = _pausedWizardCourses;
    if (paused.isNotEmpty) {
      final choice = await _askAboutPausedWizards(paused);
      if (!mounted) return;
      if (choice is Course) {
        await _continueWizard(choice);
        return;
      }
      if (choice != true) return;
    }
    final outcome = await Navigator.of(context).push<CourseWizardOutcome>(
      MaterialPageRoute(
        builder: (_) => CourseWizardScreen(
          operations: _ops,
          titleTaken: _library.hasCourseTitled,
        ),
      ),
    );
    await _afterWizard(outcome);
  }

  /// Continue Course Wizard, on the stored [course].
  Future<void> _continueWizard(Course course) async {
    final outcome = await Navigator.of(context).push<CourseWizardOutcome>(
      MaterialPageRoute(
        builder: (_) => CourseWizardScreen(
          course: course,
          access: _capabilities(course),
          pause: _library.pausedWizards[course.courseId],
          operations: _ops,
        ),
      ),
    );
    await _afterWizard(outcome);
  }

  Future<void> _afterWizard(CourseWizardOutcome? outcome) async {
    if (!mounted) return;
    switch (outcome) {
      case CourseWizardCreateManually(:final basics):
        await _newCourseByHand(basics);
      case CourseWizardOpenEditor(:final course):
        await _reload();
        if (!mounted) return;
        await _openUser(_library.personalCourse(course.courseId) ?? course);
      case CourseWizardPaused() || null:
        await _reload();
    }
  }

  Future<void> _newCourseByHand(CourseWizardBasics prefill) async {
    final course = await _createCourse(prefill: prefill);
    if (course == null) return;
    if (!mounted) return;
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(
            course,
            profileId: _library.activeProfileId,
          ).copyForUnconfirmedCreator(),
          isNewCourse: true,
          editorService: _service,
        ),
      ),
    );
    if (result != null && mounted) _showConfirmationResult(result);
    await _reload();
  }

  Future<void> _openBundled() async {
    final course = _library.bundledCourses
        .where((course) => course.courseId == widget.currentCourse?.courseId)
        .firstOrNull;
    if (course == null) return;
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: course,
          access: _capabilities(course),
          editorService: _service,
        ),
      ),
    );
    if (result != null && mounted) _showConfirmationResult(result);
    await _reload();
  }

  /// A tap on a Course's row: a paused Course Wizard the learner may go on
  /// with opens where it stopped (owner, 9 October 2026); otherwise, and
  /// from the menu's Edit, the Course Editor.
  Future<void> _openRow(Course course) {
    final wizard = _library
        .entriesFor(course)
        .any(
          (entry) =>
              entry.action == CourseManagerAction.continueCourseWizard &&
              entry.available,
        );
    return wizard ? _continueWizard(course) : _openUser(course);
  }

  Future<void> _openUser(Course course) async {
    var continueWizard = false;
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: course,
          access: _capabilities(course),
          onContinueCourseWizard: () => continueWizard = true,
        ),
      ),
    );
    if (result != null && mounted) _showConfirmationResult(result);
    await _reload();
    // The Course Editor's Continue (Build 267): the Editor closed first, so
    // the Wizard reads the Course as it is stored now.
    if (!continueWizard || !mounted) return;
    final stored = _library.personalCourse(course.courseId);
    if (stored != null) await _continueWizard(stored);
  }

  void _showConfirmationResult(CourseConfirmationResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(CourseLibraryReports.confirmed(result)),
      ),
    );
  }

  Future<void> _copyAsNewCourse(Course course) async {
    try {
      final created = await _ops.copyAsNewCourse(course, _library);
      await _reload();
      if (!mounted) return;
      _showConfirmationResult(created);
      final result = await Navigator.of(context).push<CourseConfirmationResult>(
        MaterialPageRoute(
          builder: (_) => CourseEditorScreen(
            course: created.course,
            access: _capabilities(created.course),
            editorService: _service,
          ),
        ),
      );
      if (result != null && mounted) _showConfirmationResult(result);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('StateError: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _forkCourse(Course course) async {
    try {
      final created = await _ops.fork(course);
      await _reload();
      if (!mounted) return;
      _showConfirmationResult(created);
      final result = await Navigator.of(context).push<CourseConfirmationResult>(
        MaterialPageRoute(
          builder: (_) => CourseEditorScreen(
            course: created.course,
            access: _capabilities(created.course),
            editorService: _service,
          ),
        ),
      );
      if (result != null && mounted) _showConfirmationResult(result);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom fork could not be created: $error')),
      );
    }
  }

  CourseAccessCapabilities _capabilities(Course course) =>
      _library.capabilitiesFor(course);

  Future<void> _toggleLearnerVisibility(Course course) async {
    try {
      await _ops.visibility.setHidden(
        course,
        !_library.hiddenCourseIds.contains(course.courseId),
        activeCourseId: widget.currentCourse?.courseId,
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Widget _courseActions(
    Course course, {
    required Key key,
    required VoidCallback onOpen,
  }) {
    final access = _capabilities(course);
    return PopupMenuButton<CourseManagerAction>(
      key: key,
      tooltip: 'Course actions',
      onSelected: (action) {
        switch (action) {
          case CourseManagerAction.continueCourseWizard:
            _continueWizard(course);
          case CourseManagerAction.study:
            widget.onStudy?.call(
              CourseStudyRequest(course, CourseStudyAction.study),
            );
          case CourseManagerAction.review:
            widget.onStudy?.call(
              CourseStudyRequest(course, CourseStudyAction.review),
            );
          case CourseManagerAction.courseInfo:
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CourseInfoScreen(course: course),
              ),
            );
          case CourseManagerAction.open:
            onOpen();
          case CourseManagerAction.toggleLearnerVisibility:
            _toggleLearnerVisibility(course);
          case CourseManagerAction.removeFromMyCourses:
            _removePersonal(course);
          case CourseManagerAction.removePublisherFromDevice:
            _uninstallPublisher(course);
          case CourseManagerAction.fork:
            _forkCourse(course);
          case CourseManagerAction.copyAsNewCourse:
            _copyAsNewCourse(course);
          case CourseManagerAction.merge:
            _openCourseMerge(course);
          case CourseManagerAction.audit:
            _auditCourse(course);
          case CourseManagerAction.export:
            _openCourseExport(course);
          case CourseManagerAction.exportAsPublisherCourse:
            _openPublisherExport(course);
          case CourseManagerAction.delete:
            _delete(course);
        }
      },
      itemBuilder: (_) {
        final entries = _library.entriesFor(course);
        bool wizard(CourseManagerEntry entry) =>
            entry.action == CourseManagerAction.continueCourseWizard;
        // A paused Course Wizard starts the menu (Build 267).
        return [
          for (final entry in entries.where(wizard))
            _courseActionItem(entry, access, course),
          if (widget.onStudy != null)
            for (final entry in _library.studyEntriesFor(course))
              _courseActionItem(entry, access, course),
          for (final entry in entries.where((entry) => !wizard(entry)))
            _courseActionItem(entry, access, course),
        ];
      },
    );
  }

  /// An unavailable entry is shown disabled, with its reason in place of the
  /// description.
  PopupMenuEntry<CourseManagerAction> _courseActionItem(
    CourseManagerEntry entry,
    CourseAccessCapabilities access,
    Course course,
  ) {
    final (
      IconData? icon,
      String title,
      String? description,
    ) = switch (entry.action) {
      CourseManagerAction.continueCourseWizard => (
        Icons.assistant_outlined,
        'Continue Course Wizard',
        'Go on from the step where the Course Wizard stopped.',
      ),
      CourseManagerAction.study => (Icons.school_outlined, 'Study', null),
      CourseManagerAction.review => (Icons.history_outlined, 'Review', null),
      CourseManagerAction.removeFromMyCourses => (
        null,
        'Remove from my courses',
        null,
      ),
      CourseManagerAction.removePublisherFromDevice => (
        null,
        'Remove Publisher Course from device',
        null,
      ),
      CourseManagerAction.courseInfo => (
        Icons.info_outline,
        'Course Info',
        null,
      ),
      CourseManagerAction.open => (
        access.canEditOriginal
            ? Icons.edit_outlined
            : Icons.visibility_outlined,
        access.canEditOriginal ? 'Edit' : 'View (read only)',
        null,
      ),
      CourseManagerAction.toggleLearnerVisibility => (
        _library.hiddenCourseIds.contains(course.courseId)
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        _library.hiddenCourseIds.contains(course.courseId)
            ? 'Unhide in Learner'
            : 'Hide in Learner',
        null,
      ),
      CourseManagerAction.fork => (
        Icons.fork_right_outlined,
        'Fork',
        'Create a derivative Course that preserves the source Course lineage.',
      ),
      CourseManagerAction.copyAsNewCourse => (
        Icons.copy_outlined,
        'Copy as New Course',
        'Create a new independent Course using this Course as the starting content.',
      ),
      CourseManagerAction.merge => (
        Icons.merge_type_outlined,
        'Merge',
        'Create a third Course from selected Lessons.',
      ),
      CourseManagerAction.audit => (Icons.fact_check_outlined, 'Audit', null),
      CourseManagerAction.export => (
        Icons.download_outlined,
        'Export Course',
        null,
      ),
      CourseManagerAction.exportAsPublisherCourse => (
        Icons.storefront_outlined,
        'Export as Publisher Course',
        'Write this Course as a Publisher Course, ready to be signed.',
      ),
      CourseManagerAction.delete => (
        Icons.delete_outline,
        'Delete course',
        null,
      ),
    };
    final reason = entry.unavailableReason;
    return PopupMenuItem(
      value: entry.action,
      enabled: entry.available,
      child: icon == null && reason == null
          ? Text(title)
          : ListTile(
              enabled: entry.available,
              leading: icon == null ? null : Icon(icon),
              title: Text(title),
              subtitle: reason != null
                  ? Text(
                      reason,
                      key: ValueKey(
                        'course-manager-unavailable-${entry.action.name}',
                      ),
                    )
                  : description == null
                  ? null
                  : Text(description),
            ),
    );
  }

  Future<void> _auditCourse(Course course) async {
    final audit = await runReported(
      context,
      'The Audit',
      () => _ops.audit(course),
    );
    if (audit == null || !mounted) return;
    final flagProblem = audit.flagProblem;
    if (flagProblem != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(flagProblem)));
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(course: course, result: audit.result),
      ),
    );
  }

  Future<void> _importCourseFromDialog() => _importCourse(fromDialog: true);

  void _returnImportedCourse(Course course) {
    if (widget.importOnly && mounted) Navigator.of(context).pop(course);
  }

  Future<void> _importCourse({bool fromDialog = false}) async {
    if (!fromDialog) {
      switch (await ensureQuickImportAccess(
        context,
        offerOpenFrom: _transfer.fileDialogsAvailable,
      )) {
        case QuickImportAccess.ready:
          break;
        case QuickImportAccess.openFrom:
          return _importCourse(fromDialog: true);
        case QuickImportAccess.stop:
          return;
      }
      if (!mounted) return;
    }
    // One import attempt owns the package's staged media until it ends.
    CoursePackageImport? attempt;
    try {
      final CoursePackage importedPackage;
      if (fromDialog) {
        // Open from…: same validation as the fixed-folder import, then the
        // identical audit / collision flow below.
        final picked = await _transfer.importPackageFromDialog();
        if (!mounted) return;
        final opened = picked.package;
        if (opened == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: courseImportFallbackHint,
          );
          return;
        }
        importedPackage = opened;
      } else {
        importedPackage = await _transfer.importCoursePackage();
      }
      attempt = CoursePackageImport(importedPackage, editor: _service);
      if (attempt.hadMatchingFolderWrapper && mounted) {
        _showMatchingZipFolderWarning(context);
      }
      final review = await _ops.reviewImport(attempt, _library);
      final course = review.course;
      final errors = review.errors;
      if (!mounted) return;
      if (errors.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Course import blocked'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CourseLibraryReports.importBlocked(errors.length)),
                    const SizedBox(height: 10),
                    for (final issue in errors.take(8))
                      Text(
                        '${issue.code}: ${issue.message} (${issue.location})',
                      ),
                    if (errors.length > 8)
                      Text('...and ${errors.length - 8} more errors.'),
                  ],
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      if (review.isPublisherCourse) {
        final existing = review.existing;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              existing == null
                  ? 'Install verified Publisher Course?'
                  : 'Install verified Publisher Course update?',
            ),
            content: SingleChildScrollView(
              child: Text(
                'Verified publisher: ${course.publisherName}.\nCourse ID: ${course.courseId}\nVersion: ${course.officialCourseVersion}.\n'
                'The signed Course JSON pins every packaged media file by its SHA-256 name. Official courses remain read only; custom forks remain unchanged.'
                '${existing != null && existing.publisherVerificationStatus != PublisherVerificationStatus.verified ? '\n\nVerification required for the existing version ${existing.officialCourseVersion} from ${existing.publisherName}. Confirm association with this signed release to reactivate this course and retain its progress.' : ''}'
                '${review.notExecutableCount > 0 ? '\n\n${CourseLibraryReports.notExecutableNote(review.notExecutableCount).trim()}' : ''}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  existing == null
                      ? 'Install verified course'
                      : 'Confirm signed update',
                ),
              ),
            ],
          ),
        );
        if (proceed != true) return;
        final result = await attempt.installPublisherCourse(
          confirmUnverifiedAssociation: review.confirmsUnverifiedAssociation,
        );
        await _reload();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 12),
            content: Text(
              CourseLibraryReports.publisherInstalled(course, result),
            ),
          ),
        );
        _returnImportedCourse(course);
        return;
      }
      final existing = review.existing;
      final unopenable = review.existingUnopenable;
      if (existing != null || unopenable != null) {
        final choice =
            await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                scrollable: true,
                title: const Text('Matching Course ID'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CourseLibraryReports.matchingCourseId(review),
                      key: const Key('import-matching-course-id'),
                    ),
                    if (review.receivedUpdate) ...[
                      const SizedBox(height: 12),
                      // Build 270 Revision 8 (owner decision): received
                      // Courses are not signed.
                      const Text(
                        'QuisquisLingo cannot check who made this update: '
                        'Course files are not signed. Update only if it '
                        'comes from the Course\'s author. If it does not, you '
                        'can delete the Course in Course Studio (⋮ › Delete).',
                        key: Key('import-received-update-warning'),
                      ),
                    ],
                    if (review.notExecutableCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        CourseLibraryReports.notExecutableNote(
                          review.notExecutableCount,
                        ).trim(),
                        key: const Key('import-not-executable-note'),
                      ),
                    ],
                    if (!_library.importAuthoringEnabled) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Unlock Course Studio for this profile to create your own copy (tap Version ten times in Settings). Copy as New Course and Fork are unavailable until then.',
                      ),
                    ],
                    if (review.replaceUnavailableReason != null) ...[
                      const SizedBox(height: 12),
                      Text(review.replaceUnavailableReason!),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: const Text('Cancel'),
                  ),
                  if (review.choices.contains(
                    CourseImportChoice.copyAsNewCourse,
                  ))
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'copy'),
                      child: const Text('Copy as New Course'),
                    ),
                  if (!_library.importAuthoringEnabled)
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('Copy as New Course'),
                    ),
                  if (review.choices.contains(CourseImportChoice.fork))
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'fork'),
                      child: const Text('Fork'),
                    ),
                  if (!_library.importAuthoringEnabled)
                    const OutlinedButton(onPressed: null, child: Text('Fork')),
                  if (review.choices.contains(CourseImportChoice.replace))
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, 'replace'),
                      child: Text(
                        review.receivedUpdate
                            ? 'Update to version ${course.courseVersion}'
                            : 'Replace / update',
                      ),
                    ),
                  if (!review.choices.contains(CourseImportChoice.replace) &&
                      review.replaceUnavailableReason != null)
                    const FilledButton(
                      onPressed: null,
                      child: Text('Replace / update'),
                    ),
                ],
              ),
            ) ??
            'cancel';
        if (choice == 'cancel') return;
        if (choice == 'copy') {
          final created = await attempt.copyAsNewCourse(
            title: _library.nextCopyTitle(course.title),
          );
          await _reload();
          if (!mounted) return;
          if (!widget.importOnly) _showConfirmationResult(created);
          _returnImportedCourse(created.course);
          return;
        }
        if (choice == 'fork') {
          final created = await attempt.fork();
          await _reload();
          if (!mounted) return;
          if (!widget.importOnly) _showConfirmationResult(created);
          _returnImportedCourse(created.course);
          return;
        }
      }
      await attempt.installCustomCourse();
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            CourseLibraryReports.imported(
              course,
              review.warnings.length,
              notExecutable: review.notExecutableCount,
            ),
          ),
        ),
      );
      _returnImportedCourse(course);
    } catch (error) {
      unawaited(_sounds.playDefeat());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(error.toString().replaceFirst('FormatException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      await attempt?.close();
    }
  }

  Future<void> _exportCourse(Course course) async {
    try {
      final exported = await _ops.exportCourse(course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            CourseLibraryReports.exported(
              course,
              exported.path,
              exported.notice,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(error.toString().replaceFirst('FormatException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _saveCourseTo(Course course) async {
    try {
      final saved = await _ops.saveCourseTo(course);
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        saved.result,
        saving: true,
        savedMessage: CourseLibraryReports.savedTo(
          course,
          saved.result.displayName,
          saved.notice,
        ),
        fallbackHint: exportFallbackHint,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(error.toString().replaceFirst('FormatException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportAsPublisher(
    Course course,
    PublisherIdentity publisher,
  ) async {
    try {
      final path = await _ops.exportAsPublisherCourse(course, publisher);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            CourseLibraryReports.publisherExported(course, publisher, path),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(error.toString().replaceFirst('FormatException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _savePublisherCourseTo(
    Course course,
    PublisherIdentity publisher,
  ) async {
    try {
      final result = await _ops.savePublisherCourseTo(course, publisher);
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        result,
        saving: true,
        savedMessage: CourseLibraryReports.publisherExported(
          course,
          publisher,
          result.displayName ?? '',
        ),
        fallbackHint: exportFallbackHint,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(error.toString().replaceFirst('FormatException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _removePersonal(Course course) async {
    if (await removeFromMyCourses(context, course)) await _reload();
  }

  Future<void> _uninstallPublisher(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Publisher Course from device?'),
        content: Text(
          'Uninstall “${course.title}” for this device? This is blocked while another profile has the course in My courses. Progress and version backups are kept for reinstallation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove from device'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _ops.removePublisherCourse(course);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  /// Removes a stored Course this version cannot open (Build 266 Revision
  /// 2), with the same two confirmations as Delete; the service allows it to
  /// its Maintainer, a member of its Team or an admin, as its JSON names them.
  /// Since the Build 271 Revision 1 follow-up the first confirmation offers,
  /// off, to delete all its backups too.
  Future<void> _removeUnopenable(SkippedCourseFile file) async {
    final courseId = file.courseId!;
    final held = _unopenableBackups(courseId);
    var deleteBackups = false;
    var backups = CourseBackupsSummary.none;
    final first =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
              title: const Text('Remove the stored Course?'),
              content: SingleChildScrollView(
                child: FutureBuilder<CourseBackupsSummary>(
                  future: held,
                  builder: (ctx, snapshot) {
                    final data = snapshot.data;
                    if (data != null) backups = data;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remove ${file.fileName} (Course ID $courseId) '
                          'from this device? This version cannot open it.',
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          key: const Key(
                            'course-manager-unreadable-remove-backups',
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: deleteBackups,
                          onChanged: data == null || data.isEmpty
                              ? null
                              : (value) => update(
                                  () => deleteBackups = value ?? false,
                                ),
                          title: const Text('Also delete all its backups'),
                          subtitle: Text(
                            data == null
                                ? 'Looking for its backups…'
                                : data.isEmpty
                                ? 'It has no backups.'
                                : '${CourseLibraryReports.backupsHeld(data)}, '
                                      'with the pictures and recordings only '
                                      'they hold. '
                                      '${CourseLibraryReports.unopenableBackupsCaution}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('course-manager-unreadable-remove-confirm'),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!first || !mounted) return;
    final second =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm permanent deletion'),
            content: Text(
              'This will permanently delete ${file.fileName} and the Course '
              'media stored for it'
              '${deleteBackups ? ', and its ${backups.versions} backup${backups.versions == 1 ? '' : 's'} (${CourseLibraryReports.sizeText(backups.bytes)}),' : ''}'
              ' from this device. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('course-manager-unreadable-remove-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;
    if (!second) return;
    try {
      final result = await _ops.removeUnopenableCourse(
        courseId,
        deleteBackups: deleteBackups,
      );
      if (mounted && (result.backupsDeleted > 0 || result.backupsLeft)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('course-manager-unreadable-removed'),
            duration: const Duration(seconds: 6),
            content: Text(
              CourseLibraryReports.unopenableRemoved(file.fileName, result),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'Could not remove ${file.fileName}: '
              '${error.toString().replaceFirst(RegExp(r'^(StateError|FormatException): '), '')}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    await _reload();
  }

  /// The backups of a Course this version cannot open; a check that fails
  /// offers none.
  Future<CourseBackupsSummary> _unopenableBackups(String courseId) async {
    try {
      return await _ops.backupsOf(courseId);
    } catch (_) {
      return CourseBackupsSummary.none;
    }
  }

  /// Delete (Build 271 Revision 1, owner decisions of 10 and 11 October
  /// 2026): the first dialog names the other learners who have the Course in
  /// their courses and offers, both off, to reset the learner's own progress
  /// on it and to delete all its backups; the second names everything that
  /// will go. The two confirmations are the established ones.
  Future<void> _delete(Course course) async {
    final preview = _deletePreview(course);
    var resetProgress = false;
    var deleteBackups = false;
    var backups = CourseBackupsSummary.none;
    final first =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
              title: const Text('Delete course?'),
              content: SingleChildScrollView(
                child: FutureBuilder<CourseDeletePreview>(
                  future: preview,
                  builder: (ctx, snapshot) {
                    final data = snapshot.data;
                    final others = CourseLibraryReports.otherLearnersHave(
                      data?.otherLearners ?? const [],
                    );
                    final held = data?.backups;
                    if (held != null) backups = held;
                    final scheme = Theme.of(ctx).colorScheme;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete “${course.title}” from this device?'),
                        if (others != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            key: const Key('course-delete-other-learners'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.group_outlined,
                                  color: scheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    others,
                                    style: TextStyle(
                                      color: scheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          key: const Key('course-delete-reset-progress'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: resetProgress,
                          onChanged: (value) =>
                              update(() => resetProgress = value ?? false),
                          title: const Text(
                            'Also reset my progress on this Course',
                          ),
                          subtitle: const Text(
                            'Completed Rounds and Lessons, Laurels, Duels, '
                            'GuideBooks read and recent Rounds. XP, Weekly '
                            'XP, study days and streaks are kept.',
                          ),
                        ),
                        CheckboxListTile(
                          key: const Key('course-delete-backups'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: deleteBackups,
                          onChanged: held == null || held.isEmpty
                              ? null
                              : (value) => update(
                                  () => deleteBackups = value ?? false,
                                ),
                          title: const Text('Also delete all its backups'),
                          subtitle: Text(
                            held == null
                                ? 'Looking for its backups…'
                                : held.isEmpty
                                ? 'It has no backups.'
                                : '${CourseLibraryReports.backupsHeld(held)}, '
                                      'with the pictures and recordings only '
                                      'they hold.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!first || !mounted) return;
    final second =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm permanent deletion'),
            content: SingleChildScrollView(
              child: Column(
                key: const Key('course-delete-summary'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This will permanently delete from this device:'),
                  const SizedBox(height: 8),
                  Text('• the Course “${course.title}”'),
                  if (resetProgress) const Text('• your progress on it'),
                  if (deleteBackups)
                    Text(
                      '• its ${backups.versions} '
                      'backup${backups.versions == 1 ? '' : 's'} '
                      '(${CourseLibraryReports.sizeText(backups.bytes)})',
                    ),
                  const SizedBox(height: 8),
                  const Text('This action cannot be undone.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep course'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;
    if (!second) return;
    try {
      final result = await _ops.deleteCourse(
        course,
        resetMyProgress: resetProgress,
        deleteBackups: deleteBackups,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('course-deleted'),
            duration: const Duration(seconds: 6),
            content: Text(CourseLibraryReports.deleted(course, result)),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(CourseLibraryReports.deleteFailed(course, error)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    // Either way, list what storage now holds.
    await _reload();
  }

  /// What Delete shows first; a check that fails is logged and shows
  /// nothing extra, so it never stops a Delete.
  Future<CourseDeletePreview> _deletePreview(Course course) async {
    try {
      return await _ops.previewDelete(course);
    } catch (error) {
      await DiagnosticLogService().logInfo(
        'Course Studio: the check before deleting a Course failed: $error',
      );
      return const CourseDeletePreview(
        otherLearners: [],
        backups: CourseBackupsSummary.none,
      );
    }
  }

  String _managerMaintainer(Course course) {
    if (course.originType.isOfficial) return course.publisherName;
    final id = course.maintainer?.profileId;
    if (id == null) return 'Not specified';
    return _profileNames[id] ?? 'Profile not on this device ($id)';
  }

  /// "Course Wizard paused: step 6 of 6 (GuideBook, Lesson 2)" (Build 267).
  Widget? _wizardNote(Course course) {
    final pause = _library.pausedWizards[course.courseId];
    if (pause == null) return null;
    return Text(
      pause.describe(course),
      key: ValueKey('course-wizard-paused-${course.courseId}'),
    );
  }

  Widget _courseSection(CourseLibraryCategory category) => CourseLibrarySection(
    key: ValueKey('manager-section-${category.sectionId}'),
    category: category,
    surface: CourseLibrarySectionSurface.courseStudio,
    courses: [..._library.bundledCourses, ..._library.personalCourses],
    activeProfileId: _library.activeProfileId,
    favoriteIds: _favoriteIds,
    showUnavailable: widget.showUnavailable,
    search: widget.search,
    sort: widget.sort,
    maintainerOf: _managerMaintainer,
    view: _sectionViews[category] ?? CourseLibraryView.expanded,
    onViewChanged: (view) {
      setState(() => _sectionViews = {..._sectionViews, category: view});
      // A view that could not be saved still applies while the page is open.
      unawaited(
        _viewService
            .setView(
              CourseLibrarySectionSurface.courseStudio.storageName,
              category,
              view,
            )
            .catchError((Object _) {}),
      );
    },
    rowBuilder: (course, compact, favorites) => _courseStatusCard(
      course,
      CourseLibraryRow(
        key: ValueKey(
          '${favorites ? 'manager-favorite' : 'manager-course'}-${course.courseId}',
        ),
        course: course,
        compact: compact,
        maintainer: _managerMaintainer(course),
        mediaStore: widget.mediaStore,
        hiddenInLearner: _library.hiddenCourseIds.contains(course.courseId),
        note: _wizardNote(course),
        onTap: () => _openRow(course),
        trailing: _courseActions(
          course,
          key: ValueKey(
            'course-manager-actions-${favorites ? 'favorite-' : ''}${course.courseId}',
          ),
          onOpen: () => _openUser(course),
        ),
      ),
      showIndicators: false,
    ),
  );

  Widget _embeddedBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Course Studio could not load local course data.'),
            Text(_loadError!),
            TextButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('team-manager-entry'),
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => TeamManagerScreen(
                      teamService: _ops.teams,
                      profileService: _ops.profiles,
                    ),
                  ),
                );
                await _reload();
              },
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Team Manager'),
            ),
            if (_library.isAdmin && _library.activeProfileId != null)
              OutlinedButton.icon(
                key: const Key('admin-media-library-entry'),
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => FlatImageLibraryScreen(
                        selectMode: false,
                        metadataEditingEnabled: true,
                        actorProfileId: _library.activeProfileId,
                      ),
                    ),
                  );
                  await _reload();
                },
                icon: const Icon(Icons.perm_media_outlined),
                label: const Text('Shared Images'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _courseSection(CourseLibraryCategory.favorites),
        for (final category in CourseLibraryCategories.standard)
          _courseSection(category),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded && !widget.importOnly) return _embeddedBody(context);
    return widget.importOnly
        ? (_loading || _loadError != null
              ? Scaffold(
                  appBar: AppBar(title: const Text('Course Import')),
                  body: Center(
                    child: _loadError == null
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_loadError!),
                              TextButton(
                                onPressed: _reload,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                  ),
                )
              : CourseImportScreen(
                  onImport: _importCourse,
                  onOpenFrom: _transfer.fileDialogsAvailable
                      ? _importCourseFromDialog
                      : null,
                ))
        : Scaffold(
            appBar: AppBar(
              title: const Text('Course Studio'),
              actions: [
                IconButton(
                  key: const Key('course-import-icon-action'),
                  tooltip: 'Course Import',
                  onPressed: _openCourseImport,
                  icon: const Icon(Icons.file_open_outlined),
                ),
                IconButton(
                  key: const Key('create-course-icon-action'),
                  tooltip: 'Create new course',
                  onPressed: _newCourse,
                  icon: const Icon(Icons.add),
                ),
                const EditorAppBarActions(showInternalIdsToggle: false),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    key: const Key('course-manager-load-error'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'Course Studio could not load local course data.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_library.unreadable.isNotEmpty) ...[
                        _unreadableCoursesCard(),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('team-manager-entry'),
                            onPressed: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => TeamManagerScreen(
                                    teamService: _ops.teams,
                                    profileService: _ops.profiles,
                                  ),
                                ),
                              );
                              await _reload();
                            },
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Team Manager'),
                          ),
                          if (_library.isAdmin &&
                              _library.activeProfileId != null)
                            OutlinedButton.icon(
                              key: const Key('admin-media-library-entry'),
                              onPressed: () async {
                                await Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => FlatImageLibraryScreen(
                                      selectMode: false,
                                      metadataEditingEnabled: true,
                                      actorProfileId: _library.activeProfileId,
                                    ),
                                  ),
                                );
                                await _reload();
                              },
                              icon: const Icon(Icons.perm_media_outlined),
                              label: const Text('Shared Images'),
                            ),
                        ],
                      ),
                      if (_library.bundledCourses.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Bundled Courses',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final course in _library.bundledCourses)
                          _courseStatusCard(
                            course,
                            ListTile(
                              leading: CourseFlagBadge(
                                course: course,
                                fallbackCode: CourseService.codeForCourse(
                                  course,
                                ),
                              ),
                              title: Text(course.title),
                              subtitle: const Text(
                                'Bundled Course · read only',
                              ),
                              onTap: () => _openRow(course),
                              trailing: _courseActions(
                                course,
                                key:
                                    course.courseId ==
                                        widget.currentCourse?.courseId
                                    ? const Key(
                                        'course-manager-actions-current',
                                      )
                                    : ValueKey(
                                        'course-manager-actions-${course.courseId}',
                                      ),
                                onOpen: () => _openUser(course),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Local courses',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_library.personalCourses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No local courses yet.'),
                        ),
                      for (final course in _library.personalCourses)
                        _courseStatusCard(
                          course,
                          ListTile(
                            leading: CourseFlagBadge(
                              course: course,
                              fallbackCode: CourseService.codeForCourse(course),
                            ),
                            title: Text(course.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${course.sourceLanguage} → ${course.targetLanguage} · ${course.originType.isOfficial ? 'Publisher Course · ${course.publisherName} ${course.officialCourseVersion} · read only${course.originType == CourseOriginType.externalOfficial && course.publisherVerificationStatus != PublisherVerificationStatus.verified ? ' · Verification required' : ''}' : 'custom version ${course.courseVersion.isEmpty ? 'unconfirmed' : course.courseVersion}'}',
                                ),
                                ?_wizardNote(course),
                              ],
                            ),
                            onTap: () => _openRow(course),
                            trailing: _courseActions(
                              course,
                              key: ValueKey(
                                'course-manager-actions-${course.courseId}',
                              ),
                              onOpen: () => _openUser(course),
                            ),
                          ),
                        ),
                    ],
                  ),
          );
  }
}

Widget _courseStatusCard(
  Course course,
  Widget child, {
  bool showIndicators = true,
}) {
  final status = AuthoringHierarchyStatus.fromCourse(course);
  return AuthoringStatusCard(
    indicatorKey: ValueKey('course-manager-status-${course.courseId}'),
    draftIndicatorKey: ValueKey('course-manager-draft-${course.courseId}'),
    hasDraft: showIndicators && status.courseHasDraft,
    hasUnpublished: showIndicators && !course.publicationState.isPublished,
    unpublishedIndicatorKey: ValueKey(
      'course-manager-unpublished-${course.courseId}',
    ),
    hasAuditConcern: status.hasCourseAuditConcern,
    child: child,
  );
}

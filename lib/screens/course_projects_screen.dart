import '../services/settings_service.dart';
import '../services/course_library_service.dart';
import '../services/course_file_store.dart';
import 'available_courses_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_flag_selection.dart';
import '../models/course_models.dart';
import '../models/course_metadata_options.dart';
import '../services/course_editor_service.dart';
import '../services/course_audit_service.dart';
import '../services/course_flag_service.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/course_service.dart';
import '../services/course_language_resolver.dart';
import '../services/course_merge_service.dart';
import '../services/formal_name_policy.dart';
import '../services/course_access_policy.dart';
import '../services/profile_service.dart';
import '../services/sound_effect_service.dart';
import '../services/team_service.dart';
import '../services/new_course_structure.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/flag_art.dart';
import 'course_editor_screen.dart';
import 'team_manager_screen.dart';
import 'flat_image_library_screen.dart';

class _DisposeOnUnmount extends StatefulWidget {
  final Widget child;
  final VoidCallback onDispose;
  const _DisposeOnUnmount({required this.child, required this.onDispose});

  @override
  State<_DisposeOnUnmount> createState() => _DisposeOnUnmountState();
}

class _DisposeOnUnmountState extends State<_DisposeOnUnmount> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
          label: const Text('Import Course JSON'),
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
            'Choose a course JSON file anywhere with the system file dialog. '
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
        const Text(
          '1. Copy the course JSON to Documents/QuisquisLingo/Imports/import.json.\n'
          '2. Select Import Course JSON. QQL validates the complete file before changing local storage.\n'
          '3. If the Course ID already exists, choose Replace/update, Copy as New Course, Fork or Cancel, as available.\n'
          '4. A successful import is added to your courses. Only published courses are available for study. import.json remains in Imports.',
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
  final _sounds = SoundEffectService();

  Future<void> _loadMergeCourse({bool fromDialog = false}) async {
    setState(() => _loading = true);
    try {
      final Course right;
      if (fromDialog) {
        // Merge From…: same validation as merge.json, then the same
        // compatibility check below.
        final picked = await _merge.readMergeCourseFromDialog();
        if (!mounted) return;
        final opened = picked.course;
        if (opened == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: mergeImportFallbackHint,
          );
          return;
        }
        right = opened;
      } else {
        right = await _merge.readMergeCourse();
      }
      _merge.validateCompatibility(widget.leftCourse, right);
      if (!mounted) return;
      setState(() {
        _rightCourse = right;
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
        content: const SingleChildScrollView(
          child: Text(
            'The Course Merge tool is not intended for merging two completely different courses. '
            'A typical usage case would be two team members working on the same course: while team member, John, edits, say, lessons 1 to 5, another team member, Jane, edits lessons 6 to 8. The Merge Tool allows them, or a third member, to assemble the two sets of lessons into one unified course. Another usage case would be the same editor who wants to merge two versions of the course they are working at: let’s say they want to use lessons 1, 3, and 7 from the first version, and lessons 2, 4, 5, and 6 from the second version.\n\n'
            'Copy the second Course JSON to Documents/QuisquisLingo/Merges/merge.json. '
            'Both Courses must be custom. Matching Course IDs are allowed only '
            'when the Course versions differ.\n\n'
            'Author, Maintainer, source/target language, Original Course '
            'Creator, Assigned Team, authors and roles, Rights Holders, license/'
            'derivative policy, language tags/text direction/TTS language, language '
            'variant, custom Lesson icons, and audio configuration/library must match. '
            'Title, Publication state, Create Duels, Use GuideBooks, Lesson numbering/custom '
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
              onPressed: _loading ? null : _loadMergeCourse,
              icon: const Icon(Icons.merge_type_outlined),
              label: const Text('Merge JSON Course'),
            ),
            if (_merge.fileDialogsAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('merge-course-json-from'),
                onPressed: _loading
                    ? null
                    : () => _loadMergeCourse(fromDialog: true),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Merge From…'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the second Course JSON anywhere with the system file dialog. '
                'It is checked exactly like merge.json.',
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
            const Text(
              '1. Copy the compatible Course JSON to Documents/QuisquisLingo/Merges/merge.json.\n'
              '2. Select Merge JSON Course. QQL validates both Course information blocks before changing local storage.\n'
              '3. Choose the origin of every Lesson you want to include, then check the selections carefully.\n'
              '4. DO MERGE! creates a third independent Course and leaves both sources and merge.json unchanged.\n'
              '5. The new merged Course will be available in Course Manager.',
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
                  onPressed: () => _selectAll(LessonMergeChoice.left),
                  child: const Text('Select all Left'),
                ),
                OutlinedButton(
                  onPressed: () => _selectAll(LessonMergeChoice.right),
                  child: const Text('Select all Right'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _lessonChoiceTable(right),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _choices.every(
                    (choice) => choice == LessonMergeChoice.exclude,
                  )
                  ? null
                  : () => widget.onMerge(right, _choices, _options(right)),
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
        label: 'Lesson numbering',
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
            onChanged: lesson == null
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
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  const CourseProjectsScreen({
    super.key,
    required this.currentCourse,
    this.importOnly = false,
    this.initialCourseIdToOpen,
    this.editorService,
    this.transferService,
  });

  @override
  State<CourseProjectsScreen> createState() => _CourseProjectsScreenState();
}

class _CourseProjectsScreenState extends State<CourseProjectsScreen> {
  late final _service = widget.editorService ?? CourseEditorService();
  final _courseService = CourseService();
  final _flags = CourseFlagService();
  late final _transfer =
      widget.transferService ?? CustomCourseTransferService();
  final _merge = CourseMergeService();
  final _profiles = ProfileService();
  final _sounds = SoundEffectService();
  late final _teams = TeamService(profileService: _profiles);
  List<Course> _user = [];
  bool _loading = true;
  String? _loadError;
  List<SkippedCourseFile> _unreadable = const [];
  bool _openedInitialCourse = false;
  String? _activeProfileId;
  Set<String> _memberTeamIds = const {};
  bool _isAdmin = false;
  bool _importAuthoringEnabled = false;
  List<Course> _includedBundled = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant CourseProjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCourse != widget.currentCourse) _reload();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final value = await CourseLibraryService().included(
        await _service.listUserCourses(),
      );
      final bundled = <Course>[
        if (!widget.importOnly)
          for (final code in CourseService.courseAssets.keys)
            await _courseService.loadCourse(code),
      ];
      final includedBundled = await CourseLibraryService().included([
        if (widget.currentCourse?.originType ==
            CourseOriginType.bundledOfficial)
          widget.currentCourse!,
        ...bundled.where(
          (c) =>
              c.courseId != widget.currentCourse?.courseId ||
              widget.currentCourse?.originType !=
                  CourseOriginType.bundledOfficial,
        ),
      ]);
      final importAuthoringEnabled =
          !widget.importOnly ||
          await SettingsService().isCourseEditorUnlocked();
      final activeProfileId = await _profiles.getActiveProfileId();
      final isAdmin =
          activeProfileId != null && await _profiles.isAdmin(activeProfileId);
      final memberTeamIds = activeProfileId == null
          ? const <String>{}
          : (await _teams.teamsForProfile(
              activeProfileId,
            )).map((team) => team.teamId).toSet();
      if (!mounted) return;
      setState(() {
        _user = value;
        _unreadable = _service.unreadableCourseFiles;
        _importAuthoringEnabled = importAuthoringEnabled;
        _includedBundled = includedBundled;
        _loading = false;
        _activeProfileId = activeProfileId;
        _memberTeamIds = memberTeamIds;
        _isAdmin = isAdmin;
      });
      if (!_openedInitialCourse && widget.initialCourseIdToOpen != null) {
        _openedInitialCourse = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openInitialCourse(),
        );
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
                    _unreadable.length == 1
                        ? '1 stored Course could not be read'
                        : '${_unreadable.length} stored Courses could not be read',
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
              'untouched and are not shown. Saving a Course over one of them '
              'is refused until the file is moved away.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 6),
            for (final file in _unreadable)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  '${file.fileName}: ${file.reason}',
                  style: TextStyle(color: scheme.onErrorContainer),
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
    for (final course in _user) {
      if (course.courseId == courseId) {
        await _openUser(course);
        return;
      }
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
      final outputTitle = _nextMergeTitle('${options.title} merged');
      final merged = await _merge.createMergedCourse(
        left: left,
        right: right,
        choices: choices,
        options: CourseMergeOptions(
          title: options.title,
          outputTitle: outputTitle,
          createDuels: options.createDuels,
          useGuidebook: options.useGuidebook,
          lessonNumberingMode: options.lessonNumberingMode,
          customLessonLabel: options.customLessonLabel,
          sectionNames: options.sectionNames,
          buyACoffeeUrl: options.buyACoffeeUrl,
          courseDescription: options.courseDescription,
          startLevel: options.startLevel,
          targetLevel: options.targetLevel,
          flagCode: options.flagCode,
          worldFlagId: options.worldFlagId,
          flagImageBase64: options.flagImageBase64,
        ),
      );
      if (!mounted) return;
      final audit = CourseAuditService().auditCourse(merged);
      final errors = audit.issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .toList();
      if (errors.isNotEmpty) {
        throw StateError(
          'Course Audit found ${errors.length} error${errors.length == 1 ? '' : 's'}. Fix the source Course content before merging.',
        );
      }
      if (audit.issues.any(
        (issue) => issue.severity == AuditSeverity.warning,
      )) {
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
      await _merge.copyMedia(left: left, right: right, merged: merged);
      final CourseConfirmationResult result;
      try {
        result = await _service.confirmCourseTransaction(
          originalCourse: merged,
          workingCourse: merged,
          languageCode: merged.targetLanguageTag,
          versionNotes: merged.versionNotes,
          isNewCourse: true,
        );
      } catch (_) {
        await _merge.discardMedia(merged);
        rethrow;
      }
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

  Future<Course?> _createCourse() async {
    final activeProfile = await _profiles.getActiveProfileRecord();
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
    final availableMaintainers = await _profiles.getProfileRecords();
    if (!mounted) return null;
    final title = TextEditingController();
    final source = TextEditingController(text: 'English');
    final target = TextEditingController();
    final authorNames = [
      TextEditingController(text: activeProfile.displayName),
    ];
    final authorRoles = [
      <String>{'Author'},
    ];
    final customAuthorRoles = [TextEditingController()];
    final rightsHolderNames = [TextEditingController()];
    final rightsHolderTypes = [CourseRightsHolderType.person];
    final variant = TextEditingController();
    final startLevel = TextEditingController();
    final targetLevel = TextEditingController();
    final description = TextEditingController();
    final buyACoffeeUrl = TextEditingController();
    final customLicense = TextEditingController();
    final lessonCount = TextEditingController(
      text: '${NewCourseStructure.defaultLessons}',
    );
    final roundsPerLesson = TextEditingController(
      text: '${NewCourseStructure.defaultRoundsPerLesson}',
    );
    var flagSelection = const CourseFlagSelection.automatic();
    var selectedLicense = CourseMetadataOptions.standardLicenses.first;
    var selectedDerivativePolicy = DerivativeWorksPolicy.forbidden;
    var selectedMaintainer = activeProfile.learnerProfileId;

    final result = await showDialog<Course>(
      context: context,
      builder: (ctx) => _DisposeOnUnmount(
        onDispose: () {
          title.dispose();
          source.dispose();
          target.dispose();
          for (final controller in authorNames) {
            controller.dispose();
          }
          for (final controller in customAuthorRoles) {
            controller.dispose();
          }
          for (final controller in rightsHolderNames) {
            controller.dispose();
          }
          variant.dispose();
          startLevel.dispose();
          targetLevel.dispose();
          description.dispose();
          buyACoffeeUrl.dispose();
          customLicense.dispose();
          lessonCount.dispose();
          roundsPerLesson.dispose();
        },
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Create new course'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Continue to Editor to prepare this course. It is saved only when you confirm the course changes in the editor.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course title *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: source,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Source language *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: target,
                      maxLength: 80,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Target language *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('new-course-owner'),
                      initialValue: selectedMaintainer,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course Maintainer',
                        helper: Text(
                          'The person currently responsible for maintaining this Course.',
                        ),
                      ),
                      items: [
                        for (final profile in availableMaintainers)
                          DropdownMenuItem(
                            value: profile.learnerProfileId,
                            child: Tooltip(
                              message:
                                  profile.learnerProfileId ==
                                      activeProfile.learnerProfileId
                                  ? '${profile.presentationName} (Original Course Creator)'
                                  : profile.presentationName,
                              child: Text(
                                profile.learnerProfileId ==
                                        activeProfile.learnerProfileId
                                    ? '${profile.presentationName} (Original Course Creator)'
                                    : profile.presentationName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => selectedMaintainer = value ?? selectedMaintainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Authors and credits',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Credits are descriptive only and never grant editing permission.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (
                      var authorIndex = 0;
                      authorIndex < authorNames.length;
                      authorIndex++
                    )
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      key: ValueKey(
                                        'new-course-credit-name-$authorIndex',
                                      ),
                                      controller: authorNames[authorIndex],
                                      maxLength: 120,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Name',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove credit',
                                    onPressed: authorNames.length == 1
                                        ? null
                                        : () => setDialogState(() {
                                            authorNames
                                                .removeAt(authorIndex)
                                                .dispose();
                                            authorRoles.removeAt(authorIndex);
                                            customAuthorRoles
                                                .removeAt(authorIndex)
                                                .dispose();
                                          }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final role
                                      in CourseMetadataOptions.standardRoles)
                                    FilterChip(
                                      label: Text(role),
                                      selected: authorRoles[authorIndex]
                                          .contains(role),
                                      onSelected: (selected) => setDialogState(
                                        () {
                                          if (selected) {
                                            authorRoles[authorIndex].add(role);
                                          } else {
                                            authorRoles[authorIndex].remove(
                                              role,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: customAuthorRoles[authorIndex],
                                maxLength: 240,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Custom role(s)',
                                  helper: Text(
                                    'Optional; separate roles with commas.',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('new-course-add-credit'),
                        onPressed: () => setDialogState(() {
                          authorNames.add(TextEditingController());
                          authorRoles.add({'Contributor'});
                          customAuthorRoles.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add),
                        label: const Text('Add author or contributor'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'License / Rights',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('new-course-license'),
                      initialValue: selectedLicense,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course content license',
                      ),
                      items: [
                        for (final license
                            in CourseMetadataOptions.standardLicenses)
                          DropdownMenuItem(
                            value: license,
                            child: Text(
                              license,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        selectedLicense = value ?? selectedLicense;
                        selectedDerivativePolicy =
                            CourseMetadataOptions.derivativePolicyForLicense(
                              selectedLicense,
                            );
                      }),
                    ),
                    if (selectedLicense == 'Other / Custom license') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customLicense,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Custom license',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DerivativeWorksPolicy>(
                        key: const Key('new-course-derivative-policy'),
                        initialValue: selectedDerivativePolicy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Derivative works for other users',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DerivativeWorksPolicy.allowed,
                            child: Text(
                              'Allowed',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: DerivativeWorksPolicy.forbidden,
                            child: Text(
                              'Forbidden',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: DerivativeWorksPolicy.unspecified,
                            child: Text(
                              'Not specified',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (value) => setDialogState(
                          () => selectedDerivativePolicy =
                              value ?? selectedDerivativePolicy,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rights Holder records rights ownership information. It does not control QQL permissions.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (
                      var rightsIndex = 0;
                      rightsIndex < rightsHolderNames.length;
                      rightsIndex++
                    )
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Rights Holder ${rightsIndex + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove Rights Holder',
                                    onPressed: rightsHolderNames.length == 1
                                        ? null
                                        : () => setDialogState(() {
                                            rightsHolderNames
                                                .removeAt(rightsIndex)
                                                .dispose();
                                            rightsHolderTypes.removeAt(
                                              rightsIndex,
                                            );
                                          }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButtonFormField<CourseRightsHolderType>(
                                key: ValueKey(
                                  'new-course-rights-holder-type-$rightsIndex',
                                ),
                                initialValue: rightsHolderTypes[rightsIndex],
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Rights Holder type',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: CourseRightsHolderType.person,
                                    child: Text('Person'),
                                  ),
                                  DropdownMenuItem(
                                    value: CourseRightsHolderType.organization,
                                    child: Text('Organization'),
                                  ),
                                ],
                                onChanged: (value) => setDialogState(() {
                                  rightsHolderTypes[rightsIndex] =
                                      value ?? rightsHolderTypes[rightsIndex];
                                }),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                key: ValueKey(
                                  'new-course-rights-holder-name-$rightsIndex',
                                ),
                                controller: rightsHolderNames[rightsIndex],
                                maxLength: 240,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Rights Holder',
                                  helper: Text(
                                    'A person or organization; descriptive only.',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('new-course-add-rights-holder'),
                        onPressed: () => setDialogState(() {
                          rightsHolderNames.add(TextEditingController());
                          rightsHolderTypes.add(CourseRightsHolderType.person);
                        }),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Rights Holder'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: variant,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Language variant',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startLevel,
                            maxLength: 40,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Starting level',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: targetLevel,
                            maxLength: 40,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Target level',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: description,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course description / information',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: buyACoffeeUrl,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Buy a Coffee URL (optional)',
                        helper: Text('HTTPS only.'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('new-course-lesson-count'),
                      controller: lessonCount,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Number of Lessons',
                        helper: const Text('1–100. Default: 3.'),
                        errorText: NewCourseStructure.validateCount(
                          lessonCount.text,
                          maximum: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('new-course-round-count'),
                      controller: roundsPerLesson,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Rounds per Lesson',
                        helper: const Text('1–20. Default: 1.'),
                        errorText: NewCourseStructure.validateCount(
                          roundsPerLesson.text,
                          maximum: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can add or delete Lessons and Rounds later.',
                    ),
                    const Text('Each Round starts with a sample exercise.'),
                    const SizedBox(height: 12),
                    CourseFlagSelector(
                      selection: flagSelection,
                      languageName: target.text,
                      languageTag: CourseLanguageResolver.codeFromMetadata([
                        target.text,
                      ]),
                      onChanged: (selection) =>
                          setDialogState(() => flagSelection = selection),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    NewCourseStructure.validateCount(
                              lessonCount.text,
                              maximum: 100,
                            ) !=
                            null ||
                        NewCourseStructure.validateCount(
                              roundsPerLesson.text,
                              maximum: 20,
                            ) !=
                            null
                    ? null
                    : () async {
                        String t;
                        try {
                          t = FormalNamePolicy.validatePresentationLabel(
                            title.text,
                            parameterName: 'courseName',
                          );
                        } on ArgumentError catch (error) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.message?.toString() ??
                                    'Check the Course name.',
                              ),
                            ),
                          );
                          return;
                        }
                        final s = source.text.trim();
                        final tg = target.text.trim();
                        if (s.isEmpty || tg.isEmpty) return;
                        if (_user.any(
                          (course) =>
                              FormalNamePolicy.comparisonKey(course.title) ==
                              FormalNamePolicy.comparisonKey(t),
                        )) {
                          final continueAnyway = await showDialog<bool>(
                            context: ctx,
                            builder: (warningContext) => AlertDialog(
                              title: const Text('Course name already exists'),
                              content: const Text(
                                'A Course with this name already exists.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(warningContext, false),
                                  child: const Text('Edit name'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(warningContext, true),
                                  child: const Text('Continue anyway'),
                                ),
                              ],
                            ),
                          );
                          if (continueAnyway != true || !ctx.mounted) return;
                        }
                        final license =
                            selectedLicense == 'Other / Custom license'
                            ? customLicense.text.trim()
                            : selectedLicense;
                        if (license.isEmpty) return;
                        String normalizedBuyACoffeeUrl;
                        try {
                          normalizedBuyACoffeeUrl =
                              Course.normalizeBuyACoffeeUrl(buyACoffeeUrl.text);
                        } on FormatException catch (error) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                          return;
                        }
                        final credits = <CourseAuthor>[];
                        for (
                          var index = 0;
                          index < authorNames.length;
                          index++
                        ) {
                          final name = authorNames[index].text.trim();
                          if (name.isEmpty) continue;
                          final roles = <String>[
                            ...CourseMetadataOptions.standardRoles.where(
                              authorRoles[index].contains,
                            ),
                          ];
                          for (final part
                              in customAuthorRoles[index].text.split(',')) {
                            final role = part.trim();
                            if (role.isNotEmpty && !roles.contains(role)) {
                              roles.add(role);
                            }
                          }
                          if (roles.isEmpty) roles.add('Contributor');
                          credits.add(CourseAuthor(name: name, roles: roles));
                        }
                        final rightsHolders = <CourseRightsHolder>[];
                        for (
                          var index = 0;
                          index < rightsHolderNames.length;
                          index++
                        ) {
                          final name = rightsHolderNames[index].text.trim();
                          if (name.isEmpty) continue;
                          rightsHolders.add(
                            CourseRightsHolder(
                              type: rightsHolderTypes[index],
                              name: name,
                            ),
                          );
                        }
                        final updatedAt = DateTime.now().toUtc();
                        final lessons = NewCourseStructure.create(
                          sourceLanguage: s,
                          learningLanguage: tg,
                          lessonCount: int.parse(lessonCount.text.trim()),
                          roundsPerLesson: int.parse(
                            roundsPerLesson.text.trim(),
                          ),
                          updatedAt: updatedAt,
                        );
                        final speechLanguage =
                            CourseLanguageResolver.codeFromMetadata([tg]) ??
                            'und';
                        final nowUtc = updatedAt.toIso8601String();
                        Navigator.pop(
                          ctx,
                          Course(
                            courseId: Course.newCourseId(),
                            originalCourseCreator:
                                CourseProvenanceIdentity.qqlUser(
                                  profileId: activeProfile.learnerProfileId,
                                  displayName: activeProfile.presentationName,
                                ),
                            maintainer: CourseMaintainer(selectedMaintainer),
                            originalCreatedAtUtc: nowUtc,
                            lastVersionEditorProfileId:
                                activeProfile.learnerProfileId,
                            lastVersionEditorDisplayName:
                                activeProfile.presentationName,
                            modifiedAtUtc: nowUtc,
                            publicationState: PublicationState.draft,
                            learningLanguage: tg,
                            interfaceLanguage: s,
                            sourceLanguage: s,
                            targetLanguage: tg,
                            title: t,
                            ttsLanguage: speechLanguage,
                            originType: CourseOriginType.custom,
                            courseVersion: '',
                            authors: credits,
                            license: license,
                            rightsHolders: rightsHolders,
                            derivativeWorksPolicy:
                                selectedLicense == 'Other / Custom license'
                                ? selectedDerivativePolicy
                                : CourseMetadataOptions.derivativePolicyForLicense(
                                    selectedLicense,
                                  ),
                            languageVariant: variant.text.trim(),
                            startLevel: startLevel.text.trim(),
                            targetLevel: targetLevel.text.trim(),
                            courseDescription: description.text.trim(),
                            buyACoffeeUrl: normalizedBuyACoffeeUrl,
                            flagCode: flagSelection.flagCode,
                            flagImageBase64: flagSelection.flagImageBase64,
                            worldFlagId: flagSelection.selectedWorldFlagId,
                            temporarySample: false,
                            lessons: lessons,
                          ),
                        );
                      },
                child: const Text('Continue to Editor'),
              ),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  Future<void> _newCourse() async {
    final course = await _createCourse();
    if (course == null) return;
    if (!mounted) return;
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(
            course,
            profileId: _activeProfileId,
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
    final course = widget.currentCourse;
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

  Future<void> _openUser(Course course) async {
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) =>
            CourseEditorScreen(course: course, access: _capabilities(course)),
      ),
    );
    if (result != null && mounted) _showConfirmationResult(result);
    await _reload();
  }

  void _showConfirmationResult(CourseConfirmationResult result) {
    final course = result.course;
    final version = 'New course version: ${course.courseVersion}';
    final backup = result.backupPath == null
        ? '\nNo previous version existed, so no backup was required.'
        : '\nBackup: ${result.backupPath}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 12),
        content: Text('Course changes confirmed.\n$version$backup'),
      ),
    );
  }

  String _nextCopyTitle(String sourceTitle) {
    return CourseMergeService.nextAvailableTitle(
      '$sourceTitle copy',
      _user.map((course) => course.title),
    );
  }

  String _nextMergeTitle(String sourceTitle) {
    return CourseMergeService.nextAvailableTitle(
      sourceTitle,
      _user.map((course) => course.title),
    );
  }

  Future<void> _copyAsNewCourse(Course course) async {
    try {
      final created = await _service.createCopyAsNewCourse(
        source: course,
        title: _nextCopyTitle(course.title),
      );
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
      Course source = course;
      if (course.originType.isOfficial) {
        final bundledSource =
            course.originType == CourseOriginType.bundledOfficial
            ? await _courseService.loadBundledCourse(
                CourseService.codeForCourse(course),
              )
            : null;
        final official = await _service.officialSourceFor(
          course,
          bundledSource: bundledSource,
        );
        if (official == null) {
          throw StateError('The immutable official source is unavailable.');
        }
        source = official;
      }
      final created = await _service.createFork(source: source);
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
      CourseAccessPolicy.evaluate(
        course,
        profileId: _activeProfileId,
        memberTeamIds: _memberTeamIds,
      );

  Widget _courseActions(
    Course course, {
    required Key key,
    required VoidCallback onOpen,
  }) {
    final access = _capabilities(course);
    return PopupMenuButton<String>(
      key: key,
      tooltip: 'Course actions',
      onSelected: (value) {
        if (value == 'open') onOpen();
        if (value == 'remove_personal') _removePersonal(course);
        if (value == 'uninstall_publisher') _uninstallPublisher(course);
        if (value == 'fork') _forkCourse(course);
        if (value == 'copy_as_new') _copyAsNewCourse(course);
        if (value == 'merge') _openCourseMerge(course);
        if (value == 'audit') _auditCourse(course);
        if (value == 'export') _exportCourse(course);
        if (value == 'save_to') _saveCourseTo(course);
        if (value == 'delete' && course.originType == CourseOriginType.custom) {
          _delete(course);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'remove_personal',
          child: Text('Remove from my courses'),
        ),
        if (_isAdmin && course.originType == CourseOriginType.externalOfficial)
          const PopupMenuItem(
            value: 'uninstall_publisher',
            child: Text('Remove Publisher Course from device'),
          ),
        PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: Icon(
              access.canEditOriginal
                  ? Icons.edit_outlined
                  : Icons.visibility_outlined,
            ),
            title: Text(access.canEditOriginal ? 'Edit' : 'View (read only)'),
          ),
        ),
        if (access.canFork)
          const PopupMenuItem(
            value: 'fork',
            child: ListTile(
              leading: Icon(Icons.fork_right_outlined),
              title: Text('Fork'),
              subtitle: Text(
                'Create a derivative Course that preserves the source Course lineage.',
              ),
            ),
          ),
        if (access.canCopyAsNewCourse)
          const PopupMenuItem(
            value: 'copy_as_new',
            child: ListTile(
              leading: Icon(Icons.copy_outlined),
              title: Text('Copy as New Course'),
              subtitle: Text(
                'Create a new independent Course using this Course as the starting content.',
              ),
            ),
          ),
        if (course.originType == CourseOriginType.custom &&
            access.hasOperationalAccess)
          const PopupMenuItem(
            value: 'merge',
            child: ListTile(
              leading: Icon(Icons.merge_type_outlined),
              title: Text('Merge'),
              subtitle: Text('Create a third Course from selected Lessons.'),
            ),
          ),
        const PopupMenuItem(
          value: 'audit',
          child: ListTile(
            leading: Icon(Icons.fact_check_outlined),
            title: Text('Audit'),
          ),
        ),
        if (course.originType.isOfficial || access.hasOperationalAccess)
          const PopupMenuItem(
            value: 'export',
            child: ListTile(
              leading: Icon(Icons.download_outlined),
              title: Text('Export JSON'),
            ),
          ),
        if ((course.originType.isOfficial || access.hasOperationalAccess) &&
            _transfer.fileDialogsAvailable)
          const PopupMenuItem(
            value: 'save_to',
            child: ListTile(
              leading: Icon(Icons.save_alt_outlined),
              title: Text('Save to…'),
            ),
          ),
        if (access.canDelete)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete course'),
            ),
          ),
      ],
    );
  }

  Future<void> _auditCourse(Course course) async {
    try {
      await _flags.validateWorldFlag(course);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(
          course: course,
          result: CourseAuditService().auditCourse(course),
        ),
      ),
    );
  }

  Future<void> _importCourseFromDialog() => _importCourse(fromDialog: true);

  Future<void> _importCourse({bool fromDialog = false}) async {
    try {
      final Course imported;
      if (fromDialog) {
        // Open from…: same validation as the fixed-folder import, then the
        // identical audit / collision flow below.
        final picked = await _transfer.importCourseFromDialog();
        if (!mounted) return;
        final opened = picked.course;
        if (opened == null) {
          showFileDialogFeedback(
            context,
            picked.dialog,
            saving: false,
            fallbackHint: courseImportFallbackHint,
          );
          return;
        }
        imported = opened;
      } else {
        imported = await _transfer.importCourse();
      }
      if (imported.originType == CourseOriginType.bundledOfficial) {
        throw const FormatException(
          'Bundled official courses are installed only with QuisquisLingo application builds.',
        );
      }
      // Import keeps every publication state stored in the file (Course,
      // Lessons, GuideBooks, Rounds and Exercises); it never asks and never
      // changes them.
      final course = imported;
      final installedCourses = await _service.listUserCourses();
      final audit = CourseAuditService().auditCourse(course);
      final errors = audit.issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .toList();
      final warnings = audit.issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .toList();
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
                    Text(
                      'Course Audit found ${errors.length} error${errors.length == 1 ? '' : 's'}. Fix these errors before importing the course.',
                    ),
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
      if (course.originType == CourseOriginType.externalOfficial) {
        final existing = installedCourses
            .where((candidate) => candidate.courseId == course.courseId)
            .firstOrNull;
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
                'The signature authenticates the course JSON, not separate media files. Official courses remain read only; custom forks remain unchanged.'
                '${existing != null && existing.publisherVerificationStatus != PublisherVerificationStatus.verified ? '\n\nVerification required for the existing version ${existing.officialCourseVersion} from ${existing.publisherName}. Confirm association with this signed release to reactivate this course and retain its progress.' : ''}',
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
        final result = await _service.installExternalOfficialUpdate(
          course,
          confirmUnverifiedAssociation:
              existing != null &&
              existing.publisherVerificationStatus !=
                  PublisherVerificationStatus.verified,
        );
        await _reload();
        if (!mounted) return;
        final verification =
            result.officialCourse.publisherVerificationStatus ==
                PublisherVerificationStatus.verified
            ? 'verified publisher signature'
            : 'UNVERIFIED publisher metadata';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 12),
            content: Text(
              'Installed Publisher Course version ${course.officialCourseVersion} from ${course.publisherName} ($verification).'
              '${result.backupPath == null ? '' : '\nBacked up previous official source: ${result.backupPath}'}',
            ),
          ),
        );
        return;
      }
      final existingIndex = installedCourses.indexWhere(
        (c) => c.courseId == course.courseId,
      );
      final existing = existingIndex < 0
          ? null
          : installedCourses[existingIndex];
      if (existing != null) {
        final importedAccess = _capabilities(course);
        final choice =
            await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Matching Course ID'),
                content: Text(
                  existing.originType.isOfficial
                      ? 'Official Course “${existing.title}” already uses ID “${course.courseId}”. It cannot be replaced by custom content; create an available Copy as New Course or Fork, or cancel.'
                      : 'A custom Course with ID “${course.courseId}” already exists. Replace “${existing.title}”, create an available Copy as New Course or Fork, or cancel?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: const Text('Cancel'),
                  ),
                  if (_importAuthoringEnabled &&
                      importedAccess.canCopyAsNewCourse)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'copy'),
                      child: const Text('Copy as New Course'),
                    ),
                  if (_importAuthoringEnabled && importedAccess.canFork)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'fork'),
                      child: const Text('Fork'),
                    ),
                  if (!existing.originType.isOfficial &&
                      _capabilities(existing).canEditOriginal)
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, 'replace'),
                      child: const Text('Replace / update'),
                    ),
                ],
              ),
            ) ??
            'cancel';
        if (choice == 'cancel') return;
        if (choice == 'copy') {
          final created = await _service.createCopyAsNewCourse(
            source: course,
            title: _nextCopyTitle(course.title),
          );
          await _reload();
          if (!mounted) return;
          final result = await Navigator.of(context)
              .push<CourseConfirmationResult>(
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
          return;
        }
        if (choice == 'fork') {
          final created = await _service.createFork(source: course);
          await _reload();
          if (!mounted) return;
          final result = await Navigator.of(context)
              .push<CourseConfirmationResult>(
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
          return;
        }
      }
      await _service.installImportedCustomCourse(course);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            warnings.isEmpty
                ? 'Imported “${course.title}”.'
                : 'Imported “${course.title}” with ${warnings.length} Course Audit warning${warnings.length == 1 ? '' : 's'}. Review Course Audit.',
          ),
        ),
      );
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
    }
  }

  Future<void> _exportCourse(Course course) async {
    try {
      final notice = CourseAuditService().auditCourse(course).exportNotice;
      final path = await _transfer.exportCourse(course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            'Exported “${course.title}” to $path'
            '${notice == null ? '' : ' $notice'}',
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
      final notice = CourseAuditService().auditCourse(course).exportNotice;
      final result = await _transfer.exportCourseTo(course);
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        result,
        saving: true,
        savedMessage:
            'Saved “${course.title}” as ${result.displayName}.'
            '${notice == null ? '' : ' $notice'}',
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
      await _service.removePublisherCourseFromDevice(course);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _delete(Course course) async {
    final first =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete course?'),
            content: Text(
              'Delete “${course.title}” from local authoring storage?',
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
        ) ??
        false;
    if (!first || !mounted) return;
    final second =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm permanent deletion'),
            content: Text(
              'This will permanently delete “${course.title}” from this device. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep course'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        ) ??
        false;
    if (!second) return;
    await _service.deleteUserCourse(course.courseId);
    await _reload();
  }

  @override
  Widget build(BuildContext context) => widget.importOnly
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
            title: const Text('Course Manager'),
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
                          'Course Manager could not load local course data.',
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
                    if (_unreadable.isNotEmpty) ...[
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
                                  teamService: _teams,
                                  profileService: _profiles,
                                ),
                              ),
                            );
                            await _reload();
                          },
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text('Team Manager'),
                        ),
                        if (_isAdmin && _activeProfileId != null)
                          OutlinedButton.icon(
                            key: const Key('admin-media-library-entry'),
                            onPressed: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => FlatImageLibraryScreen(
                                    selectMode: false,
                                    metadataEditingEnabled: true,
                                    actorProfileId: _activeProfileId,
                                  ),
                                ),
                              );
                              await _reload();
                            },
                            icon: const Icon(Icons.perm_media_outlined),
                            label: const Text('Shared Image Library (admin)'),
                          ),
                      ],
                    ),
                    if (_includedBundled.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Bundled Courses',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final course in _includedBundled)
                        _courseStatusCard(
                          course,
                          ListTile(
                            leading: CourseFlagBadge(
                              course: course,
                              fallbackCode: CourseService.codeForCourse(course),
                            ),
                            title: Text(course.title),
                            subtitle: const Text('Bundled Course · read only'),
                            onTap: () => _openUser(course),
                            trailing: _courseActions(
                              course,
                              key:
                                  course.courseId ==
                                      widget.currentCourse?.courseId
                                  ? const Key('course-manager-actions-current')
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_user.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No local courses yet.'),
                      ),
                    for (final course in _user)
                      _courseStatusCard(
                        course,
                        ListTile(
                          leading: CourseFlagBadge(
                            course: course,
                            fallbackCode: CourseService.codeForCourse(course),
                          ),
                          title: Text(course.title),
                          subtitle: Text(
                            '${course.sourceLanguage} → ${course.targetLanguage} · ${course.originType.isOfficial ? 'Publisher Course · ${course.publisherName} ${course.officialCourseVersion} · read only${course.originType == CourseOriginType.externalOfficial && course.publisherVerificationStatus != PublisherVerificationStatus.verified ? ' · Verification required' : ''}' : 'custom version ${course.courseVersion.isEmpty ? 'unconfirmed' : course.courseVersion}'}',
                          ),
                          onTap: () => _openUser(course),
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

Widget _courseStatusCard(Course course, Widget child) {
  final status = AuthoringHierarchyStatus.fromCourse(course);
  return AuthoringStatusCard(
    indicatorKey: ValueKey('course-manager-status-${course.courseId}'),
    draftIndicatorKey: ValueKey('course-manager-draft-${course.courseId}'),
    hasDraft: status.courseHasDraft,
    hasUnpublished: !course.publicationState.isPublished,
    unpublishedIndicatorKey: ValueKey(
      'course-manager-unpublished-${course.courseId}',
    ),
    hasAuditConcern: status.hasCourseAuditConcern,
    child: child,
  );
}

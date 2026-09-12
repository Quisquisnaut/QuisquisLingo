import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/course_metadata_options.dart';
import '../models/world_flag_entity.dart';
import '../services/course_editor_service.dart';
import '../services/course_audit_service.dart';
import '../services/course_flag_service.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/course_service.dart';
import '../services/course_language_resolver.dart';
import '../services/formal_name_policy.dart';
import '../services/settings_service.dart';
import '../services/course_access_policy.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';
import '../services/publication_service.dart';
import '../services/new_course_structure.dart';
import '../widgets/flag_art.dart';
import '../widgets/world_flag_art.dart';
import '../widgets/world_flag_picker.dart';
import '../widgets/editor_app_bar_actions.dart';
import 'course_editor_screen.dart';
import 'team_manager_screen.dart';

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

  const CourseImportScreen({super.key, required this.onImport});

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
          '3. If the Course ID already exists, choose Replace/update, Separate copy or Cancel.\n'
          '4. A successful import appears under Local courses. import.json remains in Imports.',
        ),
      ],
    ),
  );
}

class CourseProjectsScreen extends StatefulWidget {
  final Course currentCourse;
  final String? initialCourseIdToOpen;
  const CourseProjectsScreen({
    super.key,
    required this.currentCourse,
    this.initialCourseIdToOpen,
  });

  @override
  State<CourseProjectsScreen> createState() => _CourseProjectsScreenState();
}

class _CourseProjectsScreenState extends State<CourseProjectsScreen> {
  final _service = CourseEditorService();
  final _courseService = CourseService();
  final _flags = CourseFlagService();
  final _transfer = CustomCourseTransferService();
  final _settings = SettingsService();
  final _profiles = ProfileService();
  late final _teams = TeamService(profileService: _profiles);
  List<Course> _user = [];
  bool _loading = true;
  String? _loadError;
  bool _currentCourseIsCustom = false;
  bool _openedInitialCourse = false;
  String? _activeProfileId;
  Set<String> _memberTeamIds = const {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final value = await _service.listUserCourses();
      final activeProfileId = await _profiles.getActiveProfileId();
      final memberTeamIds = activeProfileId == null
          ? const <String>{}
          : (await _teams.teamsForProfile(
              activeProfileId,
            )).map((team) => team.teamId).toSet();
      final selectedRef = await _settings.getLastSelectedCourseCode();
      if (!mounted) return;
      setState(() {
        _user = value;
        // The persisted selection reference carries the actual course origin.
        // Do not infer bundled/custom status from title or courseId because a
        // custom course is allowed to reuse either without becoming bundled.
        _currentCourseIsCustom =
            selectedRef == 'custom:${widget.currentCourse.courseId}';
        _loading = false;
        _activeProfileId = activeProfileId;
        _memberTeamIds = memberTeamIds;
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
    if (widget.currentCourse.courseId == courseId) await _openBundled();
  }

  Future<void> _openCourseImport() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CourseImportScreen(onImport: _importCourse),
    ),
  );

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
    final availableOwners = await _profiles.getProfileRecords();
    if (!mounted) return null;
    final title = TextEditingController();
    final source = TextEditingController(text: 'English');
    final target = TextEditingController();
    final authorNames = [
      TextEditingController(text: activeProfile.displayName),
    ];
    final authorRoles = [
      <String>{'Course Creator'},
    ];
    final customAuthorRoles = [TextEditingController()];
    final variant = TextEditingController();
    final startLevel = TextEditingController();
    final targetLevel = TextEditingController();
    final lastUpdated = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final description = TextEditingController();
    final buyACoffeeUrl = TextEditingController();
    final customLicense = TextEditingController();
    final lessonCount = TextEditingController(
      text: '${NewCourseStructure.defaultLessons}',
    );
    final roundsPerLesson = TextEditingController(
      text: '${NewCourseStructure.defaultRoundsPerLesson}',
    );
    String selectedFlag = 'AUTO';
    String flagSource = 'Automatic';
    WorldFlagEntity? worldFlag;
    String customFlagBase64 = '';
    String customFlagLabel = '';
    String? flagError;
    var selectedLicense = CourseMetadataOptions.standardLicenses.first;
    var selectedDerivativePolicy = DerivativeWorksPolicy.forbidden;
    var selectedOwner = activeProfile.learnerProfileId;

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
          variant.dispose();
          startLevel.dispose();
          targetLevel.dispose();
          lastUpdated.dispose();
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
                      initialValue: selectedOwner,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course Owner',
                        helperText:
                            'Choose an individual user. The Creator remains permanent provenance.',
                      ),
                      items: [
                        for (final profile in availableOwners)
                          DropdownMenuItem(
                            value: profile.learnerProfileId,
                            child: Text(
                              profile.learnerProfileId ==
                                      activeProfile.learnerProfileId
                                  ? '${profile.presentationName} (Creator)'
                                  : profile.presentationName,
                            ),
                          ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => selectedOwner = value ?? selectedOwner,
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
                                  helperText:
                                      'Optional; separate roles with commas.',
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
                          labelText: 'Derivative works for non-owners',
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
                      key: const Key('new-course-last-updated'),
                      controller: lastUpdated,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Last updated (YYYY-MM-DD)',
                      ),
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
                        helperText: 'HTTPS only.',
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
                        helperText: '1–100. Default: 3.',
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
                        helperText: '1–20. Default: 1.',
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
                    DropdownButtonFormField<String>(
                      key: ValueKey('course-flag-source-$flagSource'),
                      initialValue: flagSource,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Flag source',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Automatic',
                          child: Text('Automatic'),
                        ),
                        DropdownMenuItem(
                          value: 'Existing QQL course flags',
                          child: Text('Existing QQL course flags'),
                        ),
                        DropdownMenuItem(
                          value: 'World Flags',
                          child: Text('World Flags'),
                        ),
                        DropdownMenuItem(
                          value: 'Custom uploaded flag',
                          child: Text('Custom uploaded flag'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        flagSource = value ?? 'Automatic';
                        if (flagSource == 'Existing QQL course flags' &&
                            selectedFlag == 'AUTO') {
                          selectedFlag = 'EN';
                        }
                        flagError = null;
                      }),
                    ),
                    if (flagSource == 'Existing QQL course flags') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFlag,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Course flag',
                        ),
                        items: [
                          for (final entry
                              in CourseFlagService.builtInFlags.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text('${entry.value} (${entry.key})'),
                            ),
                        ],
                        onChanged: (value) => setDialogState(() {
                          selectedFlag = value ?? 'AUTO';
                          customFlagBase64 = '';
                          customFlagLabel = '';
                          flagError = null;
                        }),
                      ),
                    ],
                    if (flagSource == 'World Flags')
                      OutlinedButton.icon(
                        key: const Key('choose-world-flag'),
                        icon: const Icon(Icons.public),
                        label: Text(
                          worldFlag?.displayNameEn ?? 'Choose World Flag',
                        ),
                        onPressed: () async {
                          final selected = await showWorldFlagPicker(
                            context: ctx,
                            initialWorldFlagId: worldFlag?.id ?? '',
                          );
                          if (selected != null && ctx.mounted) {
                            setDialogState(() => worldFlag = selected);
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(ctx).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: flagSource == 'World Flags'
                                ? worldFlag == null
                                      ? const Icon(Icons.outlined_flag)
                                      : WorldFlagArt(entity: worldFlag!)
                                : flagSource == 'Custom uploaded flag' &&
                                      customFlagBase64.isEmpty
                                ? const Icon(Icons.outlined_flag)
                                : flagSource == 'Custom uploaded flag' &&
                                      customFlagBase64.isNotEmpty
                                ? Image.memory(
                                    base64Decode(customFlagBase64),
                                    fit: BoxFit.contain,
                                  )
                                : FlagBadge(
                                    flagSource == 'Automatic'
                                        ? (_flags
                                                  .codeForLanguage(target.text)
                                                  .isEmpty
                                              ? 'EN'
                                              : _flags.codeForLanguage(
                                                  target.text,
                                                ))
                                        : selectedFlag,
                                    width: 64,
                                    height: 44,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Flag preview'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import flag'),
                            onPressed: () async {
                              try {
                                final imported = await _flags
                                    .importPreparedFlag();
                                if (!ctx.mounted) return;
                                setDialogState(() {
                                  customFlagBase64 = imported.base64Png;
                                  flagSource = 'Custom uploaded flag';
                                  customFlagLabel =
                                      '${imported.sourceWidth}×${imported.sourceHeight} → ${imported.outputWidth}×${imported.outputHeight} PNG';
                                  flagError = null;
                                });
                              } catch (error) {
                                if (!ctx.mounted) return;
                                setDialogState(
                                  () => flagError = error
                                      .toString()
                                      .replaceFirst('FormatException: ', ''),
                                );
                              }
                            },
                          ),
                          if (customFlagLabel.isNotEmpty) Text(customFlagLabel),
                        ],
                      ),
                    ),
                    if (flagError != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          flagError!,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Custom flag: copy flag.png, flag.jpg, or flag.jpeg to Documents/QuisquisLingo/Exports, then press Import flag. Maximum 2 MB, minimum 64×40 px. Large images are resized to at most 256 px on the longest side while preserving proportions.',
                      ),
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
                              title: const Text('Duplicate Course name'),
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
                        if ((flagSource == 'World Flags' &&
                                worldFlag == null) ||
                            (flagSource == 'Custom uploaded flag' &&
                                customFlagBase64.isEmpty)) {
                          setDialogState(
                            () => flagError = flagSource == 'World Flags'
                                ? 'Choose a World Flag.'
                                : 'Import a custom flag first.',
                          );
                          return;
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
                        Navigator.pop(
                          ctx,
                          Course(
                            courseId: Course.newCourseId(),
                            creatorProfileId: activeProfile.learnerProfileId,
                            ownership: CourseOwnership.individual(
                              selectedOwner,
                            ),
                            publicationState: PublicationState.draft,
                            learningLanguage: tg,
                            interfaceLanguage: s,
                            sourceLanguage: s,
                            targetLanguage: tg,
                            title: t,
                            ttsLanguage: speechLanguage,
                            version: '1.0.0',
                            originType: CourseOriginType.custom,
                            courseVersion: '',
                            lastUpdated: lastUpdated.text.trim(),
                            author: credits
                                .map((credit) => credit.name)
                                .join(', '),
                            authors: credits,
                            license: license,
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
                            flagCode: flagSource == 'Existing QQL course flags'
                                ? selectedFlag
                                : '',
                            flagImageBase64:
                                flagSource == 'Custom uploaded flag'
                                ? customFlagBase64
                                : '',
                            worldFlagId: flagSource == 'World Flags'
                                ? worldFlag!.id
                                : '',
                            temporarySample: false,
                            lessons: lessons,
                          ),
                        );
                      },
                child: const Text('Create'),
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
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: widget.currentCourse,
          access: _capabilities(widget.currentCourse),
          editorService: _service,
          courseService: _courseService,
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
    final existing = _user.map((course) => course.title).toSet();
    final first = '$sourceTitle copy';
    if (!existing.contains(first)) return first;
    var suffix = 2;
    while (existing.contains('$sourceTitle copy $suffix')) {
      suffix++;
    }
    return '$sourceTitle copy $suffix';
  }

  Future<void> _duplicateCourse(Course course) async {
    try {
      final created = await _service.createDuplicate(
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
        if (value == 'fork') _forkCourse(course);
        if (value == 'duplicate') _duplicateCourse(course);
        if (value == 'audit') _auditCourse(course);
        if (value == 'export') _exportCourse(course);
        if (value == 'delete' && course.originType == CourseOriginType.custom) {
          _delete(course);
        }
      },
      itemBuilder: (_) => [
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
              title: Text('Fork as custom course'),
            ),
          ),
        if (access.canDuplicate)
          const PopupMenuItem(
            value: 'duplicate',
            child: ListTile(
              leading: Icon(Icons.copy_outlined),
              title: Text('Duplicate custom course'),
            ),
          ),
        const PopupMenuItem(
          value: 'audit',
          child: ListTile(
            leading: Icon(Icons.fact_check_outlined),
            title: Text('Audit'),
          ),
        ),
        if (course.originType.isOfficial || access.isInsideOwnershipBoundary)
          const PopupMenuItem(
            value: 'export',
            child: ListTile(
              leading: Icon(Icons.download_outlined),
              title: Text('Export JSON'),
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

  Future<void> _importCourse() async {
    try {
      final imported = await _transfer.importCourse();
      if (imported.originType == CourseOriginType.bundledOfficial) {
        throw const FormatException(
          'Bundled official courses are installed only with QuisquisLingo application builds.',
        );
      }
      final course = imported.originType == CourseOriginType.externalOfficial
          ? imported
          : const PublicationService().asDraftAuthoringTree(imported);
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
        final existing = _user
            .where((candidate) => candidate.courseId == course.courseId)
            .firstOrNull;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              existing == null
                  ? 'Install unverified official course?'
                  : 'Install unverified official course update?',
            ),
            content: Text(
              'QQL can verify the file checksum but cannot authenticate the declared publisher. '
              'The course will be visibly labelled External official — unverified. Official courses are read only. Any existing custom forks remain unchanged.',
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
                      ? 'Install as unverified'
                      : 'Install unverified update',
                ),
              ),
            ],
          ),
        );
        if (proceed != true) return;
        final result = await _service.installExternalOfficialUpdate(course);
        await _reload();
        if (!mounted) return;
        final verification =
            result.officialCourse.publisherVerificationStatus ==
                PublisherVerificationStatus.verified
            ? 'verified publisher metadata'
            : 'UNVERIFIED publisher metadata';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 12),
            content: Text(
              'Installed official version ${course.officialCourseVersion} from ${course.publisherName} ($verification).'
              '${result.backupPath == null ? '' : '\nBacked up previous official source: ${result.backupPath}'}',
            ),
          ),
        );
        return;
      }
      final existingIndex = _user.indexWhere(
        (c) => c.courseId == course.courseId,
      );
      final existing = existingIndex < 0 ? null : _user[existingIndex];
      if (existing != null) {
        final choice =
            await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Matching Course ID'),
                content: Text(
                  existing.originType.isOfficial
                      ? 'Official course “${existing.title}” already owns ID “${course.courseId}”. It cannot be replaced by custom content; import a separate copy or cancel.'
                      : 'A custom course with ID “${course.courseId}” already exists. Replace “${existing.title}” with the imported course?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'copy'),
                    child: const Text('Separate copy'),
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
          final access = _capabilities(course);
          final created = access.canDuplicate
              ? await _service.createDuplicate(
                  source: course,
                  title: _nextCopyTitle(course.title),
                )
              : access.canFork
              ? await _service.createFork(source: course)
              : throw StateError(
                  'This course does not permit an owned Duplicate or licensed Fork.',
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
      }
      await _service.installImportedCustomCourse(course);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            warnings.isEmpty
                ? 'Imported “${course.title}” as Draft.'
                : 'Imported “${course.title}” as Draft with ${warnings.length} Course Audit warning${warnings.length == 1 ? '' : 's'}. Review Course Audit before making it learner-visible.',
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

  Future<void> _exportCourse(Course course) async {
    try {
      final path = await _transfer.exportCourse(course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Exported “${course.title}” to $path'),
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
  Widget build(BuildContext context) => Scaffold(
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
        const EditorAppBarActions(),
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
                ],
              ),
              if (!_currentCourseIsCustom) ...[
                const SizedBox(height: 18),
                Text(
                  'Current bundled course',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _courseStatusCard(
                  widget.currentCourse,
                  ListTile(
                    leading: CourseFlagBadge(
                      course: widget.currentCourse,
                      fallbackCode: CourseService.codeForCourse(
                        widget.currentCourse,
                      ),
                    ),
                    title: Text(widget.currentCourse.title),
                    subtitle: const Text(
                      'Bundled official · read only · Course Model v8',
                    ),
                    trailing: _courseActions(
                      widget.currentCourse,
                      key: const Key('course-manager-actions-current'),
                      onOpen: _openBundled,
                    ),
                    onTap: _openBundled,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Local courses',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      '${course.sourceLanguage} → ${course.targetLanguage} · ${course.originType.isOfficial ? '${course.publisherName} official ${course.officialCourseVersion} · read only' : 'custom version ${course.courseVersion.isEmpty ? 'unconfirmed' : course.courseVersion}'}',
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

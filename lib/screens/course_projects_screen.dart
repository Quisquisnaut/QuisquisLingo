import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_audit_service.dart';
import '../services/course_flag_service.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import '../widgets/flag_art.dart';
import 'course_editor_screen.dart';
import 'editor_help_screen.dart';

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

class CourseProjectsScreen extends StatefulWidget {
  final Course currentCourse;
  const CourseProjectsScreen({super.key, required this.currentCourse});

  @override
  State<CourseProjectsScreen> createState() => _CourseProjectsScreenState();
}

class _CourseProjectsScreenState extends State<CourseProjectsScreen> {
  final _service = CourseEditorService();
  final _flags = CourseFlagService();
  final _transfer = CustomCourseTransferService();
  final _settings = SettingsService();
  List<Course> _user = [];
  bool _loading = true;
  bool _currentCourseIsCustom = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final value = await _service.listUserCourses();
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
    });
  }

  Future<Course?> _createCourse() async {
    final title = TextEditingController();
    final source = TextEditingController(text: 'English');
    final target = TextEditingController();
    final author = TextEditingController();
    String selectedFlag = 'AUTO';
    String customFlagBase64 = '';
    String customFlagLabel = '';
    String? flagError;

    final result = await showDialog<Course>(
      context: context,
      builder: (ctx) => _DisposeOnUnmount(
        onDispose: () {
          title.dispose();
          source.dispose();
          target.dispose();
          author.dispose();
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
                    TextField(
                      controller: author,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Author name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFlag,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Course flag',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'AUTO',
                          child: Text('Automatic from target language'),
                        ),
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
                            child: customFlagBase64.isNotEmpty
                                ? Image.memory(
                                    base64Decode(customFlagBase64),
                                    fit: BoxFit.contain,
                                  )
                                : FlagBadge(
                                    selectedFlag == 'AUTO'
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
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'A basic Course Model v5 structure will be created with 3 placeholder Lessons. No Rounds are created automatically.',
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
                onPressed: () {
                  final t = title.text.trim();
                  final s = source.text.trim();
                  final tg = target.text.trim();
                  if (t.isEmpty || s.isEmpty || tg.isEmpty) return;
                  final stamp = DateTime.now().microsecondsSinceEpoch;
                  final lessons = <Lesson>[
                    for (var lessonIndex = 0; lessonIndex < 3; lessonIndex++)
                      Lesson(
                        lessonId: 'user_lesson_${stamp + lessonIndex}',
                        title: 'Lesson ${lessonIndex + 1}',
                        rounds: const [],
                        guidebook: Guidebook.empty(),
                      ),
                  ];
                  final automaticCode = _flags.codeForLanguage(tg);
                  Navigator.pop(
                    ctx,
                    Course(
                      courseId: Course.newCourseId(),
                      learningLanguage: tg,
                      interfaceLanguage: s,
                      sourceLanguage: s,
                      targetLanguage: tg,
                      title: t,
                      ttsLanguage: 'und',
                      version: '1.0.0',
                      courseVersion: '1.0.0',
                      lastUpdated: DateTime.now().toIso8601String().substring(
                        0,
                        10,
                      ),
                      authors: author.text.trim().isEmpty
                          ? const []
                          : [
                              CourseAuthor(
                                name: author.text.trim(),
                                roles: const ['Course Creator'],
                              ),
                            ],
                      flagCode: selectedFlag == 'AUTO'
                          ? automaticCode
                          : selectedFlag,
                      flagImageBase64: customFlagBase64,
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
    await _service.saveUserCourse(course);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(course: course, userCourse: true),
      ),
    );
    await _reload();
  }

  Future<void> _openBundled() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(course: widget.currentCourse),
      ),
    );
    await _reload();
  }

  Future<void> _openUser(Course course) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(course: course, userCourse: true),
      ),
    );
    await _reload();
  }

  Future<void> _importCourse() async {
    try {
      final course = await _transfer.importCourse();
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
                  'A custom course with ID “${course.courseId}” already exists. Replace “${existing.title}” with the imported course?',
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
          await _service.saveUserCourse(course.fork());
          await _reload();
          return;
        }
      }
      await _service.saveUserCourse(course);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            warnings.isEmpty
                ? 'Imported “${course.title}”.'
                : 'Imported “${course.title}” with ${warnings.length} Course Audit warning${warnings.length == 1 ? '' : 's'}. Review Course Audit before publishing.',
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
      title: const Text('Course Editor'),
      actions: [
        IconButton(
          tooltip: 'Course Editor Help',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditorHelpScreen())),
          icon: const Icon(Icons.help_outline),
        ),
        IconButton(
          tooltip: 'Import custom course JSON',
          onPressed: _importCourse,
          icon: const Icon(Icons.file_open_outlined),
        ),
        IconButton(
          tooltip: 'Create new course',
          onPressed: _newCourse,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _newCourse,
                    icon: const Icon(Icons.add),
                    label: const Text('Create new course'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importCourse,
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Import course JSON'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import instructions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '1. Copy the course JSON to Documents/QuisquisLingo/Exports/import.json.',
                      ),
                      Text('2. Press Import course JSON.'),
                      Text(
                        '3. The course will appear under My custom courses. import.json is left in place.',
                      ),
                    ],
                  ),
                ),
              ),
              if (!_currentCourseIsCustom) ...[
                const SizedBox(height: 18),
                Text(
                  'Current bundled course',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: CourseFlagBadge(
                      course: widget.currentCourse,
                      fallbackCode: CourseService.codeForCourse(
                        widget.currentCourse,
                      ),
                    ),
                    title: Text(widget.currentCourse.title),
                    subtitle: const Text('Bundled course · Course Model v5'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openBundled,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'My custom courses',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_user.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No custom courses yet.'),
                ),
              for (final course in _user)
                Card(
                  child: ListTile(
                    leading: CourseFlagBadge(
                      course: course,
                      fallbackCode: CourseService.codeForCourse(course),
                    ),
                    title: Text(course.title),
                    subtitle: Text(
                      '${course.sourceLanguage} → ${course.targetLanguage} · formatVersion ${course.formatVersion}',
                    ),
                    onTap: () => _openUser(course),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Course actions',
                      onSelected: (value) {
                        if (value == 'export') _exportCourse(course);
                        if (value == 'delete') _delete(course);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'export',
                          child: ListTile(
                            leading: Icon(Icons.download_outlined),
                            title: Text('Export JSON'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete course'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}

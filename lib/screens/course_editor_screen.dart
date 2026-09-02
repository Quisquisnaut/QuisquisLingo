import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../services/course_editor_service.dart';
import '../services/course_service.dart';
import '../services/course_audit_service.dart';
import '../services/settings_service.dart';
import '../services/lesson_icon_catalog.dart';
import '../services/recorded_audio_service.dart';
import 'round_screen.dart';
import 'flat_image_library_screen.dart';
import 'editor_help_screen.dart';
import '../services/exercise_image_service.dart';
import '../services/exercise_transfer_service.dart';
import '../services/custom_course_transfer_service.dart';
import '../widgets/flag_art.dart';

/// Full local authoring UI.
///
/// The hierarchy is editable at every level: Lessons, Rounds and v5
/// Content can be created, deleted and reordered. Friendly Editor template is immutable
/// after creation because changing type can silently reinterpret incompatible
/// fields. To use another type, create a new exercise and delete the old one.
class CourseEditorScreen extends StatefulWidget {
  final Course course;
  final bool userCourse;
  const CourseEditorScreen({
    super.key,
    required this.course,
    this.userCourse = false,
  });
  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _service = CourseEditorService();
  final _courseService = CourseService();
  final _settings = SettingsService();
  final _recordedAudio = RecordedAudioService();
  final _transfer = CustomCourseTransferService();
  late Course _course;
  CourseAuditResult? _lastAudit;
  bool _auditOutdated = true;
  bool _locked = true;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locked = await _settings.isCourseEditorLocked(_course.courseId);
      if (mounted) setState(() => _locked = locked);
      await _showSampleContentNoticeIfNeeded();
      if (await _settings.isAudioOrphanCheckDue(_code)) {
        await _checkOrphanAudio();
        await _settings.markAudioOrphanCheckRun(_code);
      }
    });
  }

  Future<void> _showSampleContentNoticeIfNeeded() async {
    if (!_course.temporarySample || !mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Temporary sample content'),
        content: const Text(
          'This course is marked TEMPORARY SAMPLE. The preloaded material is provided only to demonstrate and test the editor. Replace it with reviewed course content and remove the TEMPORARY SAMPLE badge before publishing or distributing the course.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String get _code => CourseService.codeForCourse(_course);

  Future<void> _persist(Course value) async {
    if (widget.userCourse) {
      await _service.saveUserCourse(value);
    } else {
      await _service.saveCourse(languageCode: _code, course: value);
    }
    if (!mounted) return;
    setState(() {
      _course = value;
      _auditOutdated = true;
    });
  }

  Future<bool> _confirmDelete(String what) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete $what?'),
          content: const Text(
            'This removes it from the local edited course. The current bundled course remains unchanged and can be restored with Reset local edits.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Course _withLessons(List<Lesson> lessons, {bool? temporarySample}) => Course(
    courseId: _course.courseId,
    parentCourseId: _course.parentCourseId,
    derivedFromVersion: _course.derivedFromVersion,
    learningLanguage: _course.learningLanguage,
    interfaceLanguage: _course.interfaceLanguage,
    sourceLanguage: _course.sourceLanguage,
    targetLanguage: _course.targetLanguage,
    title: _course.title,
    ttsLanguage: _course.ttsLanguage,
    version: _course.version,
    contentRevision: _course.contentRevision,
    updateSummary: _course.updateSummary,
    audioMode: _course.audioMode,
    audioLibrary: _course.audioLibrary,
    lessons: lessons,
    author: _course.author,
    license: _course.license,
    sourceLanguageTag: _course.sourceLanguageTag,
    targetLanguageTag: _course.targetLanguageTag,
    textDirection: _course.textDirection,
    flagCode: _course.flagCode,
    flagImageBase64: _course.flagImageBase64,
    authors: _course.authors,
    languageVariant: _course.languageVariant,
    startLevel: _course.startLevel,
    targetLevel: _course.targetLevel,
    courseVersion: _course.courseVersion,
    lastUpdated: _course.lastUpdated,
    courseDescription: _course.courseDescription,
    temporarySample: temporarySample ?? _course.temporarySample,
    supportUrl: _course.supportUrl,
  );

  Future<void> _editCourseInfo() async {
    const standardRoles = [
      'Team Leader',
      'Contributor',
      'Course Creator',
      'Editor',
      'Reviewer',
      'Native Speaker',
      'Audio Contributor',
      'Illustrator',
    ];
    const roleDescriptions = <String, String>{
      'Course Creator':
          'Created the course or designed a substantial part of its original structure and content.',
      'Editor':
          'Maintains or substantially revises existing course content over time.',
      'Contributor':
          'Provided a specific or limited contribution without creating or maintaining the course as a whole.',
      'Team Leader':
          'Coordinates the course team and its decisions. This can be combined with another role.',
      'Reviewer':
          'Checks content and reports corrections or improvements without normally maintaining the course.',
      'Native Speaker':
          'Contributes specifically to naturalness and language-quality review.',
      'Audio Contributor': 'Provides voice recordings or other course audio.',
      'Illustrator': 'Creates or supplies visual artwork for the course.',
    };
    final initialAuthors = _course.authors.isNotEmpty
        ? _course.authors
        : [
            if (_course.author.trim().isNotEmpty)
              CourseAuthor(
                name: _course.author.trim(),
                roles: const ['Course Creator'],
              ),
          ];
    final names = [
      for (final a in initialAuthors) TextEditingController(text: a.name),
    ];
    final selectedRoles = [
      for (final a in initialAuthors)
        <String>{...a.roles.where(standardRoles.contains)},
    ];
    final customRoles = [
      for (final a in initialAuthors)
        TextEditingController(
          text: a.roles.where((r) => !standardRoles.contains(r)).join(', '),
        ),
    ];
    if (names.isEmpty) {
      names.add(TextEditingController());
      selectedRoles.add({'Contributor'});
      customRoles.add(TextEditingController());
    }
    final courseTitle = TextEditingController(text: _course.title);
    final variant = TextEditingController(text: _course.languageVariant);
    final startLevel = TextEditingController(text: _course.startLevel);
    final targetLevel = TextEditingController(text: _course.targetLevel);
    final courseVersion = TextEditingController(text: _course.courseVersion);
    final lastUpdated = TextEditingController(text: _course.lastUpdated);
    final description = TextEditingController(text: _course.courseDescription);
    final supportUrl = TextEditingController(text: _course.supportUrl);
    final customLicense = TextEditingController(text: _course.license);
    const standardLicenses = <String>[
      'All rights reserved',
      'CC0 1.0',
      'CC BY 4.0',
      'CC BY-SA 4.0',
      'CC BY-NC 4.0',
      'CC BY-NC-SA 4.0',
      'Other / Custom license',
    ];
    var selected = standardLicenses.contains(_course.license)
        ? _course.license
        : 'Other / Custom license';
    final narrowCourseInfo = MediaQuery.sizeOf(context).width < 560;
    Widget readOnlyField(String label, String value) => InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        helperText: 'Read-only for now',
      ),
      child: Text(value.trim().isEmpty ? 'Not specified' : value),
    );
    final result =
        await showDialog<
          ({
            String title,
            List<CourseAuthor> authors,
            String license,
            String variant,
            String startLevel,
            String targetLevel,
            String courseVersion,
            String lastUpdated,
            String description,
            String supportUrl,
          })
        >(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setLocalState) => AlertDialog(
              title: const Text('Course info'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Course identity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: courseTitle,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Course name',
                          helperText:
                              'You can rename the course without changing its Course ID.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      readOnlyField('Course ID', _course.courseId),
                      const SizedBox(height: 14),
                      const Text(
                        'Languages',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (narrowCourseInfo) ...[
                        readOnlyField(
                          'Source language',
                          _course.sourceLanguage,
                        ),
                        const SizedBox(height: 8),
                        readOnlyField(
                          'Target language',
                          _course.targetLanguage,
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: readOnlyField(
                                'Source language',
                                _course.sourceLanguage,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: readOnlyField(
                                'Target language',
                                _course.targetLanguage,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'Authors',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Roles describe what each person did; they are not a hierarchy. More than one role may be selected.',
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < names.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: names[i],
                                          maxLength: 120,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Name',
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove author',
                                        onPressed: names.length == 1
                                            ? null
                                            : () {
                                                setLocalState(() {
                                                  names.removeAt(i).dispose();
                                                  selectedRoles.removeAt(i);
                                                  customRoles
                                                      .removeAt(i)
                                                      .dispose();
                                                });
                                              },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final role in standardRoles)
                                        FilterChip(
                                          label: Text(role),
                                          selected: selectedRoles[i].contains(
                                            role,
                                          ),
                                          onSelected: (on) => setLocalState(() {
                                            if (on) {
                                              selectedRoles[i].add(role);
                                            } else {
                                              selectedRoles[i].remove(role);
                                            }
                                          }),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  for (final role in standardRoles.where(
                                    (r) => selectedRoles[i].contains(r),
                                  ))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        '$role: ${roleDescriptions[role]}',
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: customRoles[i],
                                    maxLength: 240,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Custom role(s)',
                                      helperText:
                                          'Optional. Separate multiple custom roles with commas.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setLocalState(() {
                              names.add(TextEditingController());
                              selectedRoles.add({'Contributor'});
                              customRoles.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add author'),
                        ),
                      ),
                      const Divider(),
                      TextField(
                        controller: variant,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Language variant',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (narrowCourseInfo) ...[
                        TextField(
                          controller: startLevel,
                          maxLength: 40,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Starting level',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: targetLevel,
                          maxLength: 40,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Target level',
                          ),
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (narrowCourseInfo) ...[
                        TextField(
                          controller: courseVersion,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Course version',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: lastUpdated,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Last updated (YYYY-MM-DD)',
                          ),
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: courseVersion,
                                maxLength: 60,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Course version',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: lastUpdated,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Last updated (YYYY-MM-DD)',
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
                        controller: supportUrl,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Support URL (optional)',
                          helperText:
                              'Shown with Course information when provided.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Course content license',
                        ),
                        items: [
                          for (final v in standardLicenses)
                            DropdownMenuItem(
                              value: v,
                              child: Text(v, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) =>
                            setLocalState(() => selected = v ?? selected),
                      ),
                      if (selected == 'Other / Custom license') ...[
                        const SizedBox(height: 12),
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
                      ],
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
                    final title = courseTitle.text.trim();
                    if (title.isEmpty) return;
                    final license = selected == 'Other / Custom license'
                        ? customLicense.text.trim()
                        : selected;
                    if (license.isEmpty) return;
                    final aa = <CourseAuthor>[];
                    for (var i = 0; i < names.length; i++) {
                      final n = names[i].text.trim();
                      if (n.isEmpty) continue;
                      final rr = <String>[
                        ...standardRoles.where(selectedRoles[i].contains),
                      ];
                      for (final part in customRoles[i].text.split(',')) {
                        final value = part.trim();
                        if (value.isNotEmpty && !rr.contains(value)) {
                          rr.add(value);
                        }
                      }
                      if (rr.isEmpty) rr.add('Contributor');
                      aa.add(CourseAuthor(name: n, roles: rr));
                    }
                    Navigator.pop(ctx, (
                      title: title,
                      authors: aa,
                      license: license,
                      variant: variant.text.trim(),
                      startLevel: startLevel.text.trim(),
                      targetLevel: targetLevel.text.trim(),
                      courseVersion: courseVersion.text.trim(),
                      lastUpdated: lastUpdated.text.trim(),
                      description: description.text.trim(),
                      supportUrl: supportUrl.text.trim(),
                    ));
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
    for (final c in names) {
      c.dispose();
    }
    for (final c in customRoles) {
      c.dispose();
    }
    courseTitle.dispose();
    variant.dispose();
    startLevel.dispose();
    targetLevel.dispose();
    courseVersion.dispose();
    lastUpdated.dispose();
    description.dispose();
    supportUrl.dispose();
    customLicense.dispose();
    if (result == null || !mounted) return;
    await _persist(
      Course(
        courseId: _course.courseId,
        parentCourseId: _course.parentCourseId,
        derivedFromVersion: _course.derivedFromVersion,
        learningLanguage: _course.learningLanguage,
        interfaceLanguage: _course.interfaceLanguage,
        sourceLanguage: _course.sourceLanguage,
        targetLanguage: _course.targetLanguage,
        title: result.title,
        ttsLanguage: _course.ttsLanguage,
        version: _course.version,
        contentRevision: _course.contentRevision,
        updateSummary: _course.updateSummary,
        audioMode: _course.audioMode,
        author: result.authors.map((a) => a.name).join(', '),
        authors: result.authors,
        license: result.license,
        languageVariant: result.variant,
        startLevel: result.startLevel,
        targetLevel: result.targetLevel,
        courseVersion: result.courseVersion,
        lastUpdated: result.lastUpdated,
        courseDescription: result.description,
        supportUrl: result.supportUrl,
        sourceLanguageTag: _course.sourceLanguageTag,
        targetLanguageTag: _course.targetLanguageTag,
        textDirection: _course.textDirection,
        flagCode: _course.flagCode,
        flagImageBase64: _course.flagImageBase64,
        audioLibrary: _course.audioLibrary,
        temporarySample: _course.temporarySample,
        lessons: _course.lessons,
      ),
    );
  }

  Future<void> _openLessons() async {
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => LessonManagementScreen(
          course: _course,
          userCourse: widget.userCourse,
          initiallyLocked: _locked,
        ),
      ),
    );
    if (!mounted) return;
    final locked = await _settings.isCourseEditorLocked(_course.courseId);
    if (!mounted) return;
    setState(() {
      if (updated != null) _course = updated;
      _locked = locked;
      _auditOutdated = true;
    });
  }

  Future<void> _openAudioLibrary() async {
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (_) => AudioLibraryScreen(course: _course)),
    );
    if (updated != null && mounted) await _persist(updated);
  }

  Future<void> _checkOrphanAudio({bool prompt = true}) async {
    final orphans = _recordedAudio.orphaned(_course);
    if (orphans.isEmpty || !mounted) return;
    if (!prompt) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${orphans.length} unused MP3 file${orphans.length == 1 ? '' : 's'} found',
        ),
        content: const Text(
          'These files are not associated with any word, expression or exercise. Delete them from local course audio storage?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete unused'),
          ),
        ],
      ),
    );
    if (remove == true) {
      await _recordedAudio.deleteFiles(orphans);
      if (!mounted) return;
      final ids = orphans.map((e) => e.id).toSet();
      await _persist(
        Course(
          courseId: _course.courseId,
          learningLanguage: _course.learningLanguage,
          interfaceLanguage: _course.interfaceLanguage,
          sourceLanguage: _course.sourceLanguage,
          targetLanguage: _course.targetLanguage,
          title: _course.title,
          ttsLanguage: _course.ttsLanguage,
          version: _course.version,
          contentRevision: _course.contentRevision,
          updateSummary: _course.updateSummary,
          audioMode: _course.audioMode,
          audioLibrary: _course.audioLibrary
              .where((e) => !ids.contains(e.id))
              .toList(),
          parentCourseId: _course.parentCourseId,
          derivedFromVersion: _course.derivedFromVersion,
          lessons: _course.lessons,
          author: _course.author,
          license: _course.license,
          sourceLanguageTag: _course.sourceLanguageTag,
          targetLanguageTag: _course.targetLanguageTag,
          textDirection: _course.textDirection,
          flagCode: _course.flagCode,
          flagImageBase64: _course.flagImageBase64,
          authors: _course.authors,
          languageVariant: _course.languageVariant,
          startLevel: _course.startLevel,
          targetLevel: _course.targetLevel,
          courseVersion: _course.courseVersion,
          lastUpdated: _course.lastUpdated,
          courseDescription: _course.courseDescription,
          temporarySample: _course.temporarySample,
          supportUrl: _course.supportUrl,
        ),
      );
    }
  }

  Future<void> _runAudit() async {
    await _checkOrphanAudio();
    final fresh = widget.userCourse
        ? _course
        : await _courseService.loadCourse(_code);
    final result = CourseAuditService().auditCourse(fresh);
    if (!mounted) return;
    setState(() {
      _course = fresh;
      _lastAudit = result;
      _auditOutdated = false;
    });
    final selected = await Navigator.of(context).push<CourseAuditIssue>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(course: fresh, result: result),
      ),
    );
    if (selected != null && mounted) await _openAuditIssue(selected);
  }

  Future<void> _openAuditIssue(CourseAuditIssue issue) async {
    if (issue.roundId == null) return;
    for (var ti = 0; ti < _course.lessons.length; ti++) {
      final lesson = _course.lessons[ti];
      for (var ri = 0; ri < lesson.rounds.length; ri++) {
        final round = lesson.rounds[ri];
        if (round.id != issue.roundId) continue;
        LearningRound? updatedRound;
        if (issue.exerciseId != null) {
          final ei = round.exercises.indexWhere(
            (e) => e.id == issue.exerciseId,
          );
          if (ei >= 0) {
            if (!mounted) return;
            final updatedExercise = await Navigator.of(context).push<Exercise>(
              MaterialPageRoute(
                builder: (_) => ExerciseEditorScreen(
                  exercise: round.exercises[ei],
                  title: 'Edit exercise ${ei + 1}',
                  isNew: false,
                ),
              ),
            );
            if (updatedExercise != null) {
              final content = [
                for (final item in round.content)
                  item.id == updatedExercise.id
                      ? LearningContent.fromExercise(updatedExercise)
                      : item,
              ];
              updatedRound = LearningRound(
                id: round.id,
                title: round.title,
                visualType: round.visualType,
                content: content,
              );
            }
          }
        }
        if (!mounted) return;
        updatedRound ??= await Navigator.of(context).push<LearningRound>(
          MaterialPageRoute(
            builder: (_) => RoundEditorScreen(
              course: _course,
              lesson: lesson,
              round: round,
              roundIndex: ri,
            ),
          ),
        );
        if (updatedRound == null || !mounted) return;
        final rounds = [...lesson.rounds];
        rounds[ri] = updatedRound;
        final lessons = [..._course.lessons];
        lessons[ti] = Lesson(
          lessonId: lesson.lessonId,
          title: lesson.title,
          rounds: rounds,
          section: lesson.section,
          sectionName: lesson.sectionName,
          themeIconAsset: lesson.themeIconAsset,
          guidebook: lesson.guidebook,
          duel: lesson.duel,
        );
        await _persist(_withLessons(lessons));
        return;
      }
    }
  }

  Future<void> _exportCustomCourse() async {
    try {
      final path = await _transfer.exportCourse(_course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Exported “${_course.title}” to $path'),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 68,
      title: Row(
        children: [
          CourseFlagBadge(
            course: _course,
            fallbackCode: _code,
            width: 38,
            height: 27,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Course Editor'),
                Text(
                  _course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Course Editor Help',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditorHelpScreen())),
          icon: const Icon(Icons.help_outline),
        ),
        IconButton(
          tooltip: 'Run Course Audit',
          onPressed: _runAudit,
          icon: const Icon(Icons.fact_check_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'audio') {
              await _openAudioLibrary();
            }
            if (v == 'export_custom') {
              await _exportCustomCourse();
            }
            if (v == 'images') {
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const FlatImageLibraryScreen(selectMode: false),
                ),
              );
            }
            if (v == 'sample' && !_locked) {
              await _persist(
                _withLessons(
                  _course.lessons,
                  temporarySample: !_course.temporarySample,
                ),
              );
            }
            if (v == 'copy' && !widget.userCourse) {
              await _service.copyCourseEdits(_course.learningLanguage);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 8),
                  content: Text('Course edits copied as JSON.'),
                ),
              );
            }
            if (v == 'reset' && !widget.userCourse) {
              if (!await _confirmDelete('all local course edits')) return;
              await _service.resetCourse(_course.learningLanguage);
              final fresh = await _courseService.loadCourse(_code);
              if (!mounted) return;
              setState(() => _course = fresh);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'audio', child: Text('Audio Library')),
            const PopupMenuItem(value: 'images', child: Text('Image Bank')),
            PopupMenuItem(
              value: 'sample',
              enabled: !_locked,
              child: Text(
                _course.temporarySample
                    ? 'Remove TEMPORARY SAMPLE'
                    : 'Mark TEMPORARY SAMPLE',
              ),
            ),
            if (widget.userCourse)
              const PopupMenuItem(
                value: 'export_custom',
                child: Text('Export course JSON'),
              ),
            if (!widget.userCourse)
              const PopupMenuItem(
                value: 'copy',
                child: Text('Copy edits as JSON'),
              ),
            if (!widget.userCourse)
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset local edits'),
              ),
          ],
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_course.temporarySample)
          const ListTile(
            leading: Icon(Icons.label_outline),
            title: Text(
              'TEMPORARY SAMPLE',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Replace sample material with reviewed content before distribution.',
            ),
          ),
        ListTile(
          leading: const Icon(Icons.edit_note_outlined),
          title: const Text('Course info'),
          subtitle: Text(
            'Edit course name, authors, license and metadata · ${_course.authors.isEmpty ? (_course.author.trim().isEmpty ? 'Author not specified' : _course.author) : _course.authors.map((a) => '${a.name} (${a.role})').join(', ')}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _editCourseInfo,
        ),
        const Divider(height: 1),
        ListTile(
          key: const Key('course-editor-lessons-navigation'),
          leading: const Icon(Icons.school_outlined),
          title: const Text(
            'Lessons',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${_course.lessons.length} Lessons'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openLessons,
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            _auditOutdated ? Icons.update : Icons.fact_check_outlined,
          ),
          title: Text(
            _lastAudit == null
                ? 'Course Audit not run yet'
                : _auditOutdated
                ? 'Course Audit outdated'
                : 'Audit: ${_lastAudit!.count(AuditSeverity.error)} errors · ${_lastAudit!.count(AuditSeverity.warning)} warnings',
          ),
          subtitle: const Text(
            'Structural and authoring checks. Grammar and translation still require human review.',
          ),
          trailing: TextButton(
            onPressed: _runAudit,
            child: const Text('Run audit'),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.library_music_outlined),
          title: const Text(
            'Audio Library',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _course.audioMode == 'tts'
                ? 'System TTS · import MP3 or choose Hybrid'
                : '${_course.audioLibrary.length} MP3 mappings · ${_course.audioMode}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openAudioLibrary,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: const Text(
            'Image Bank',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            'Browse, import and manage reusable exercise images.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FlatImageLibraryScreen(selectMode: false),
            ),
          ),
        ),
      ],
    ),
  );
}

class LessonManagementScreen extends StatefulWidget {
  const LessonManagementScreen({
    super.key,
    required this.course,
    required this.userCourse,
    required this.initiallyLocked,
  });

  final Course course;
  final bool userCourse;
  final bool initiallyLocked;

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen> {
  final _service = CourseEditorService();
  final _settings = SettingsService();
  late Course _course;
  late bool _locked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _locked = widget.initiallyLocked;
  }

  String get _code => CourseService.codeForCourse(_course);

  Course _withLessons(List<Lesson> lessons) => Course(
    courseId: _course.courseId,
    parentCourseId: _course.parentCourseId,
    derivedFromVersion: _course.derivedFromVersion,
    learningLanguage: _course.learningLanguage,
    interfaceLanguage: _course.interfaceLanguage,
    sourceLanguage: _course.sourceLanguage,
    targetLanguage: _course.targetLanguage,
    title: _course.title,
    ttsLanguage: _course.ttsLanguage,
    version: _course.version,
    contentRevision: _course.contentRevision,
    updateSummary: _course.updateSummary,
    audioMode: _course.audioMode,
    audioLibrary: _course.audioLibrary,
    lessons: lessons,
    author: _course.author,
    license: _course.license,
    sourceLanguageTag: _course.sourceLanguageTag,
    targetLanguageTag: _course.targetLanguageTag,
    textDirection: _course.textDirection,
    flagCode: _course.flagCode,
    flagImageBase64: _course.flagImageBase64,
    authors: _course.authors,
    languageVariant: _course.languageVariant,
    startLevel: _course.startLevel,
    targetLevel: _course.targetLevel,
    courseVersion: _course.courseVersion,
    lastUpdated: _course.lastUpdated,
    courseDescription: _course.courseDescription,
    temporarySample: _course.temporarySample,
    supportUrl: _course.supportUrl,
  );

  Future<void> _persist(Course value) async {
    setState(() => _saving = true);
    try {
      if (widget.userCourse) {
        await _service.saveUserCourse(value);
      } else {
        await _service.saveCourse(languageCode: _code, course: value);
      }
      if (mounted) setState(() => _course = value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askName() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New lesson'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result == null || result.isEmpty ? null : result;
  }

  Future<void> _addLesson() async {
    if (_locked) return;
    final title = await _askName();
    if (title == null) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await _persist(
      _withLessons([
        ..._course.lessons,
        Lesson(
          lessonId: 'custom_lesson_$stamp',
          title: title,
          rounds: const [],
          guidebook: Guidebook.empty(),
        ),
      ]),
    );
  }

  Future<void> _deleteLesson(int index) async {
    if (_locked) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete lesson?'),
        content: const Text(
          'This removes the Lesson from the local edited course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final lessons = [..._course.lessons]..removeAt(index);
    await _persist(_withLessons(lessons));
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_locked) return;
    final lessons = [..._course.lessons];
    final lesson = lessons.removeAt(oldIndex);
    lessons.insert(newIndex, lesson);
    await _persist(_withLessons(lessons));
  }

  Future<void> _openLesson(int index) async {
    if (_locked) return;
    final updated = await Navigator.of(context).push<Lesson>(
      MaterialPageRoute(
        builder: (_) =>
            LessonEditorScreen(course: _course, lesson: _course.lessons[index]),
      ),
    );
    if (updated == null || !mounted) return;
    final lessons = [..._course.lessons]..[index] = updated;
    await _persist(_withLessons(lessons));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) Navigator.pop(context, _course);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        leading: BackButton(onPressed: () => Navigator.pop(context, _course)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || _locked ? null : _addLesson,
        icon: const Icon(Icons.add),
        label: const Text('New lesson'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            key: const Key('lesson-management-lock'),
            title: const Text('Lock'),
            subtitle: const Text(
              'Prevents accidental course edits. Stored separately for each course.',
            ),
            value: _locked,
            onChanged: (value) async {
              await _settings.setCourseEditorLocked(_course.courseId, value);
              if (mounted) setState(() => _locked = value);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _course.lessons.isEmpty
                ? const Center(child: Text('No Lessons yet.'))
                : ReorderableListView.builder(
                    key: const Key('lesson-management-list'),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                    itemCount: _course.lessons.length,
                    onReorderItem: _reorder,
                    itemBuilder: (context, index) {
                      final lesson = _course.lessons[index];
                      final section =
                          lesson.section && lesson.sectionName != null
                          ? ' · ${lesson.sectionName}'
                          : '';
                      return Card(
                        key: ValueKey(lesson.lessonId),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            enabled: !_locked,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text('Lesson ${index + 1}: ${lesson.title}'),
                          subtitle: Text(
                            '${lesson.rounds.length} Rounds$section',
                          ),
                          onTap: _locked ? null : () => _openLesson(index),
                          trailing: PopupMenuButton<String>(
                            enabled: !_locked,
                            onSelected: (value) {
                              if (value == 'delete') _deleteLesson(index);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete lesson'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class GuidebookEditorScreen extends StatefulWidget {
  final Guidebook guidebook;
  const GuidebookEditorScreen({super.key, required this.guidebook});
  @override
  State<GuidebookEditorScreen> createState() => _GuidebookEditorScreenState();
}

class _GuidebookEditorScreenState extends State<GuidebookEditorScreen> {
  late final TextEditingController _overview,
      _goals,
      _vocabulary,
      _grammar,
      _expressions,
      _examples;
  @override
  void initState() {
    super.initState();
    final g = widget.guidebook;
    _overview = TextEditingController(text: g.overview);
    _goals = TextEditingController(text: g.goals.join('\n'));
    _vocabulary = TextEditingController(text: g.vocabulary.join('\n'));
    _grammar = TextEditingController(text: g.grammar.join('\n'));
    _expressions = TextEditingController(text: g.expressions.join('\n'));
    _examples = TextEditingController(text: g.examples.join('\n'));
  }

  @override
  void dispose() {
    for (final c in [
      _overview,
      _goals,
      _vocabulary,
      _grammar,
      _expressions,
      _examples,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 4,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      minLines: lines,
      maxLines: lines + 5,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        helperText:
            helper ?? (label == 'Overview' ? null : 'One item per line'),
        helperMaxLines: 3,
      ),
    ),
  );
  List<LearningContent> _editedItems(
    String kind,
    String role,
    List<String> texts,
    String Function() newId,
  ) {
    final existing = widget.guidebook.content
        .where((content) => content.kind == kind && content.role == role)
        .toList();
    final usedIds = <String>{};
    String idFor(String text) {
      for (final content in existing) {
        if (!usedIds.contains(content.id) &&
            content.text.trim() == text.trim()) {
          usedIds.add(content.id);
          return content.id;
        }
      }
      return newId();
    }

    return [
      for (final text in texts)
        LearningContent.textual(
          id: idFor(text),
          kind: kind,
          role: role,
          text: text,
        ),
    ];
  }

  void _save() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var sequence = 0;
    String newId() => 'guide_${stamp}_${sequence++}';
    final overview = _overview.text.trim();
    final content = <LearningContent>[
      ..._editedItems('explanation', 'overview', [
        if (overview.isNotEmpty) overview,
      ], newId),
      ..._editedItems('text', 'goal', _lines(_goals), newId),
      ..._editedItems('vocabulary', 'vocabulary', _lines(_vocabulary), newId),
      ..._editedItems('explanation', 'grammar', _lines(_grammar), newId),
      ..._editedItems('example', 'expression', _lines(_expressions), newId),
      ..._editedItems('example', 'example', _lines(_examples), newId),
    ];
    Navigator.pop(context, Guidebook(content: content));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Guidebook'),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_overview, 'Overview', lines: 5),
        _field(_goals, 'Goals'),
        _field(
          _vocabulary,
          'Vocabulary',
          lines: 4,
          helper:
              'One target/source pair per line. Example: casa = house. This learner-facing Lesson Guidebook can also be used to automatically generate new exercises, which must be reviewed and approved before creation.',
        ),
        _field(_grammar, 'Grammar'),
        _field(_expressions, 'Useful expressions'),
        _field(
          _examples,
          'Examples',
          lines: 4,
          helper:
              'One target-language example sentence per line. Vocabulary and examples can be used to generate three progressively harder draft Rounds from this Lesson. Drafts must be reviewed and approved before creation.',
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Guidebook'),
        ),
      ],
    ),
  );
}

class LessonEditorScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;
  const LessonEditorScreen({
    super.key,
    required this.course,
    required this.lesson,
  });
  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late Lesson _lesson;
  late bool _belongsToSection;
  late final TextEditingController _sectionName;
  String? _themeIconAsset;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _belongsToSection = _lesson.section;
    _sectionName = TextEditingController(text: _lesson.sectionName ?? '');
    _themeIconAsset = _lesson.themeIconAsset;
  }

  @override
  void dispose() {
    _sectionName.dispose();
    super.dispose();
  }

  Lesson _copy({
    String? title,
    List<LearningRound>? rounds,
    Guidebook? guidebook,
  }) => Lesson(
    lessonId: _lesson.lessonId,
    title: title ?? _lesson.title,
    rounds: rounds ?? _lesson.rounds,
    section: _lesson.section,
    sectionName: _lesson.sectionName,
    themeIconAsset: _lesson.themeIconAsset,
    guidebook: guidebook ?? _lesson.guidebook,
    duel: _lesson.duel,
  );

  void _saveLesson() {
    final sectionName = _sectionName.text.trim();
    if (_belongsToSection && sectionName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a Section name.')));
      return;
    }
    Navigator.pop(
      context,
      Lesson(
        lessonId: _lesson.lessonId,
        title: _lesson.title,
        rounds: _lesson.rounds,
        section: _belongsToSection,
        sectionName: _belongsToSection ? sectionName : null,
        themeIconAsset: _themeIconAsset,
        guidebook: _lesson.guidebook,
        duel: _lesson.duel,
      ),
    );
  }

  Future<String?> _name(String title, {String initial = ''}) async {
    var edited = initial;
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          onChanged: (value) => edited = value,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, edited.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return v?.trim().isEmpty == true ? null : v;
  }

  Future<void> _rename() async {
    final n = await _name('Rename lesson', initial: _lesson.title);
    if (n != null) setState(() => _lesson = _copy(title: n));
  }

  Future<void> _editGuidebook() async {
    final oldGuideIds = _lesson.guidebook.content
        .map((content) => content.id)
        .toSet();
    final g = await Navigator.of(context).push<Guidebook>(
      MaterialPageRoute(
        builder: (_) => GuidebookEditorScreen(guidebook: _lesson.guidebook),
      ),
    );
    if (g == null || !mounted) return;
    final newGuideIds = g.content.map((content) => content.id).toSet();
    final rounds = [
      for (final round in _lesson.rounds)
        LearningRound(
          id: round.id,
          title: round.title,
          visualType: round.visualType,
          content: [
            for (final content in round.content)
              LearningContent(
                id: content.id,
                kind: content.kind,
                required: content.required,
                editorTemplate: content.editorTemplate,
                role: content.role,
                exercise: content.exercise,
                presentation: content.presentation,
                text: content.text,
                sourceRefs: content.sourceRefs
                    .where(
                      (ref) =>
                          !oldGuideIds.contains(ref) ||
                          newGuideIds.contains(ref),
                    )
                    .toList(),
              ),
          ],
        ),
    ];
    setState(() => _lesson = _copy(guidebook: g, rounds: rounds));
  }

  Future<void> _openRounds() async {
    final sectionName = _sectionName.text.trim();
    final draftLesson = Lesson(
      lessonId: _lesson.lessonId,
      title: _lesson.title,
      rounds: _lesson.rounds,
      section: _belongsToSection && sectionName.isNotEmpty,
      sectionName: _belongsToSection && sectionName.isNotEmpty
          ? sectionName
          : null,
      themeIconAsset: _themeIconAsset,
      guidebook: _lesson.guidebook,
      duel: _lesson.duel,
    );
    final rounds = await Navigator.of(context).push<List<LearningRound>>(
      MaterialPageRoute(
        builder: (_) =>
            LessonRoundsScreen(course: widget.course, lesson: draftLesson),
      ),
    );
    if (rounds != null && mounted) {
      setState(() => _lesson = _copy(rounds: rounds));
    }
  }

  Future<void> _chooseThemeIcon() async {
    const none = '__none__';
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .76,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Lesson theme icon',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  key: const Key('lesson-theme-icon-grid'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 132,
                    mainAxisExtent: 126,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: LessonIconCatalog.options.length + 1,
                  itemBuilder: (context, index) {
                    final option = index == 0
                        ? null
                        : LessonIconCatalog.options[index - 1];
                    final value = option?.assetPath;
                    final selected = value == _themeIconAsset;
                    return Semantics(
                      selected: selected,
                      label: option?.label ?? 'None',
                      child: Card(
                        key: ValueKey(
                          'lesson-theme-icon-option-${option?.id ?? 'none'}',
                        ),
                        color: selected
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(
                            context,
                            option == null ? none : option.assetPath,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: option == null
                                      ? const Icon(
                                          Icons.menu_book_outlined,
                                          size: 42,
                                        )
                                      : Image.asset(
                                          option.assetPath,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option?.label ?? 'None',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _themeIconAsset = selected == none ? null : selected);
  }

  String _generatorNorm(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<MapEntry<String, String>> _lessonVocabularyPairs() {
    final out = <MapEntry<String, String>>[];
    final seen = <String>{};
    for (final raw in _lesson.guidebook.vocabulary) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      var at = line.indexOf(' = ');
      var width = 3;
      if (at < 1) {
        at = line.indexOf(' → ');
        width = 3;
      }
      if (at < 1) {
        at = line.indexOf(' - ');
        width = 3;
      }
      if (at < 1) {
        at = line.indexOf(':');
        width = 1;
      }
      if (at < 1) continue;
      final target = line.substring(0, at).trim();
      final source = line.substring(at + width).trim();
      if (target.isEmpty || source.isEmpty) continue;
      final key = '${_generatorNorm(target)}|${_generatorNorm(source)}';
      if (seen.add(key)) out.add(MapEntry(target, source));
    }
    return out;
  }

  Exercise _generatedChoice(
    String id,
    String question,
    String correct,
    List<String> distractors,
  ) {
    final options = <String>[
      correct,
      ...distractors.where((d) => _generatorNorm(d) != _generatorNorm(correct)),
    ];
    final unique = <String>[];
    final seen = <String>{};
    for (final value in options) {
      if (seen.add(_generatorNorm(value))) unique.add(value);
    }
    unique.shuffle(Random());
    return Exercise(
      id: id,
      type: 'choice',
      prompt: question,
      question: '',
      answers: unique,
      correct: unique.indexOf(correct),
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
  }

  List<String> _distractors(
    List<MapEntry<String, String>> pairs,
    MapEntry<String, String> pair, {
    required bool targets,
  }) {
    final values = [for (final p in pairs) targets ? p.key : p.value]
      ..shuffle(Random());
    final answer = targets ? pair.key : pair.value;
    final out = <String>[];
    for (final value in values) {
      if (_generatorNorm(value) == _generatorNorm(answer)) continue;
      if (out.any((e) => _generatorNorm(e) == _generatorNorm(value))) continue;
      out.add(value);
      if (out.length == 2) break;
    }
    return out;
  }

  String? _exampleContaining(List<String> examples, String target) {
    final needle = _generatorNorm(target);
    if (needle.isEmpty) return null;
    for (final example in examples) {
      if (_generatorNorm(example).contains(needle)) return example;
    }
    return null;
  }

  Exercise? _gapFromExample(
    String id,
    List<MapEntry<String, String>> pairs,
    List<String> examples,
    MapEntry<String, String> pair,
  ) {
    final sentence = _exampleContaining(examples, pair.key);
    if (sentence == null) return null;
    final match = RegExp(
      RegExp.escape(pair.key),
      caseSensitive: false,
    ).firstMatch(sentence);
    if (match == null) return null;
    final question = sentence.replaceRange(match.start, match.end, '___');
    final ds = _distractors(pairs, pair, targets: true);
    if (ds.length < 2) return null;
    final answers = <String>[pair.key, ...ds]..shuffle(Random());
    return Exercise(
      id: id,
      type: 'gap_choice',
      prompt: '',
      question: question,
      answers: answers,
      correct: answers.indexOf(pair.key),
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
  }

  Exercise? _readingFromExample(
    String id,
    List<MapEntry<String, String>> pairs,
    List<String> examples,
    MapEntry<String, String> pair,
  ) {
    final sentence = _exampleContaining(examples, pair.key);
    if (sentence == null) return null;
    final ds = _distractors(pairs, pair, targets: true);
    if (ds.length < 2) return null;
    final answers = <String>[pair.key, ...ds]..shuffle(Random());
    return Exercise(
      id: id,
      type: 'reading_comprehension',
      prompt: sentence,
      question: 'Which expression in the sentence means “${pair.value}”?',
      answers: answers,
      correct: answers.indexOf(pair.key),
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
  }

  Exercise _wordOrder(String id, String sentence) {
    final words = sentence
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    return Exercise(
      id: id,
      type: 'word_order',
      prompt: 'Build the sentence.',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: words,
      orderAnswer: words,
      pairs: const [],
      hint: '',
      icons: const [],
    );
  }

  List<LearningRound> _buildThreeGuidebookRounds(
    List<MapEntry<String, String>> originalPairs,
    List<String> originalExamples,
  ) {
    final pairs = [...originalPairs]..shuffle(Random());
    final examples = [...originalExamples]..shuffle(Random());
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var seq = 0;
    String id(String label) => 'gb_${stamp}_${label}_${seq++}';
    MapEntry<String, String> p(int i) => pairs[i % pairs.length];
    List<List<String>> matchPairs(int start) => [
      for (var i = 0; i < 3; i++) [p(start + i).key, p(start + i).value],
    ];
    Exercise listenChoice(int i) {
      final pair = p(i);
      final ds = _distractors(pairs, pair, targets: true);
      final answers = <String>[pair.key, ...ds]..shuffle(Random());
      return Exercise(
        id: id('listen'),
        type: 'listening_choice',
        prompt: '',
        question: 'What do you hear?',
        answers: answers,
        correct: answers.indexOf(pair.key),
        tts: pair.key,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      );
    }

    Exercise spell(int i, {String? sentence}) {
      final text = sentence ?? p(i).key;
      return Exercise(
        id: id('spell'),
        type: 'listening_spelling',
        prompt: '',
        question: 'Type what you hear.',
        answers: const [],
        correct: null,
        tts: text,
        accepted: [text],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      );
    }

    Exercise wordMatch(int start) => Exercise(
      id: id('match'),
      type: 'word_match',
      prompt: 'Match each expression with its meaning.',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: matchPairs(start),
      hint: '',
      icons: const [],
    );
    Exercise audioMatch(int start) => Exercise(
      id: id('audio_match'),
      type: 'audio_match',
      prompt: 'Match each sound to its meaning.',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: matchPairs(start),
      hint: '',
      icons: const [],
    );
    Exercise flash(int i) {
      final pair = p(i);
      final matchingExamples = examples
          .where((e) => _exampleContaining([e], pair.key) != null)
          .toList();
      final usage = matchingExamples.isEmpty ? '' : matchingExamples.first;
      return Exercise(
        id: id('flash'),
        type: 'flashcard',
        prompt: pair.key,
        question: pair.value,
        answers: [if (usage.isNotEmpty) usage],
        correct: null,
        tts: pair.key,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      );
    }

    final round1 = <Exercise>[
      _generatedChoice(
        id('choice'),
        'Choose the best meaning of “${p(0).key}”.',
        p(0).value,
        _distractors(pairs, p(0), targets: false),
      ),
      _generatedChoice(
        id('choice'),
        'Choose the best meaning of “${p(1).key}”.',
        p(1).value,
        _distractors(pairs, p(1), targets: false),
      ),
      listenChoice(2),
      listenChoice(3),
      wordMatch(0),
      flash(0),
      flash(1),
      _generatedChoice(
        id('reverse'),
        'How would you say “${p(2).value}”?',
        p(2).key,
        _distractors(pairs, p(2), targets: true),
      ),
    ];
    final round2 = <Exercise>[
      _generatedChoice(
        id('reverse'),
        'How would you say “${p(3).value}”?',
        p(3).key,
        _distractors(pairs, p(3), targets: true),
      ),
      _generatedChoice(
        id('reverse'),
        'How would you say “${p(1).value}”?',
        p(1).key,
        _distractors(pairs, p(1), targets: true),
      ),
      spell(1),
      spell(2),
      if (examples.isNotEmpty)
        _wordOrder(id('order'), examples[0])
      else
        flash(2),
      wordMatch(1),
      audioMatch(0),
      _gapFromExample(id('gap'), pairs, examples, p(0)) ??
          _generatedChoice(
            id('choice'),
            'Choose the best meaning of “${p(2).key}”.',
            p(2).value,
            _distractors(pairs, p(2), targets: false),
          ),
    ];
    final hardReading = _readingFromExample(
      id('reading'),
      pairs,
      examples,
      p(1),
    );
    final hardGap = _gapFromExample(id('gap'), pairs, examples, p(2));
    final hardSentence = examples.length > 1 ? examples[1] : null;
    final round3 = <Exercise>[
      if (hardSentence != null)
        _wordOrder(id('order'), hardSentence)
      else
        _generatedChoice(
          id('context'),
          'Which expression would best convey “${p(0).value}” in this Lesson?',
          p(0).key,
          _distractors(pairs, p(0), targets: true),
        ),
      if (hardSentence != null) spell(0, sentence: hardSentence) else spell(0),
      hardGap ??
          _generatedChoice(
            id('reverse'),
            'In context, which expression corresponds to “${p(1).value}”?',
            p(1).key,
            _distractors(pairs, p(1), targets: true),
          ),
      hardReading ??
          _generatedChoice(
            id('choice'),
            'In context, what is the best meaning of “${p(2).key}”?',
            p(2).value,
            _distractors(pairs, p(2), targets: false),
          ),
      listenChoice(1),
      _generatedChoice(
        id('context'),
        'Choose the expression that means “${p(0).value}” in natural usage.',
        p(0).key,
        _distractors(pairs, p(0), targets: true),
      ),
      _generatedChoice(
        id('reverse'),
        'In this Lesson, which expression corresponds to “${p(2).value}”?',
        p(2).key,
        _distractors(pairs, p(2), targets: true),
      ),
      _generatedChoice(
        id('choice'),
        'Which meaning best matches “${p(0).key}” in context?',
        p(0).value,
        _distractors(pairs, p(0), targets: false),
      ),
    ];
    final refs = _lesson.guidebook.content.take(6).map((c) => c.id).toList();
    final keyTerms = pairs.take(4).map((e) => e.key).join(', ');
    final introText =
        'Before you start: ${_lesson.guidebook.overview.trim().isNotEmpty ? _lesson.guidebook.overview.trim() : _lesson.title}. Key items include $keyTerms. Read this Lesson Guidebook for more explanations, vocabulary and examples.';
    final intro = LearningContent(
      id: id('intro'),
      kind: 'explanation',
      required: false,
      role: 'lesson_intro',
      text: introText,
      sourceRefs: refs,
    );
    LearningRound round(
      int number,
      List<Exercise> exercises, {
      bool introFirst = false,
    }) => LearningRound(
      id: id('round'),
      title: 'Round $number',
      content: [
        if (introFirst) intro,
        ...exercises.map(LearningContent.fromExercise),
      ],
    );
    return [
      round(1, round1, introFirst: true),
      round(2, round2),
      round(3, round3),
    ];
  }

  Future<void> _generateThreeRoundsFromGuidebook() async {
    final pairs = _lessonVocabularyPairs();
    final examples = [
      ..._lesson.guidebook.examples,
      ..._lesson.guidebook.expressions,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (pairs.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Add at least three target/source vocabulary pairs to this Lesson Guidebook first. Example: casa = house.',
          ),
        ),
      );
      return;
    }
    final proposals = _buildThreeGuidebookRounds(pairs, examples);
    final audit = CourseAuditService();
    final issues = <CourseAuditIssue>[];
    for (final round in proposals) {
      for (final ex in round.exercises) {
        issues.addAll(
          audit.auditExercise(
            ex,
            location: '${round.title} · ${ex.type}',
            roundId: round.id,
          ),
        );
      }
    }
    final errors = issues
        .where((i) => i.severity == AuditSeverity.error)
        .toList();
    if (!mounted) return;
    final approve = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Review 3 generated Rounds'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The Lesson Guidebook is the only source. Material and option order are randomized, exact duplicate exercises are avoided, and difficulty increases across the three Rounds. Nothing is created until you approve this preview.',
                ),
                const SizedBox(height: 12),
                for (final round in proposals) ...[
                  Text(
                    '${round.title} · ${round.exercises.length} exercises',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  for (final ex in round.exercises)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 2),
                      child: Text(
                        '• ${ex.type.replaceAll('_', ' ')} · ${ex.prompt.isNotEmpty ? ex.prompt : (ex.question.isNotEmpty ? ex.question : (ex.tts ?? ex.id))}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                Text(
                  'Automatic audit: ${errors.length} errors · ${issues.where((i) => i.severity == AuditSeverity.warning).length} warnings · ${issues.where((i) => i.severity == AuditSeverity.suggestion).length} suggestions.',
                ),
                if (errors.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Creation is blocked until generator errors are resolved.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: errors.isEmpty ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Approve and create 3 Rounds'),
          ),
        ],
      ),
    );
    if (approve == true && mounted) {
      setState(
        () => _lesson = _copy(rounds: [..._lesson.rounds, ...proposals]),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_lesson.title),
      actions: [
        IconButton(
          tooltip: 'Generate 3 Rounds from Guidebook',
          onPressed: _generateThreeRoundsFromGuidebook,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        IconButton(
          tooltip: 'Rename lesson',
          onPressed: _rename,
          icon: const Icon(Icons.edit_outlined),
        ),
        TextButton(
          key: const Key('save-lesson'),
          onPressed: _saveLesson,
          child: const Text('Save'),
        ),
      ],
    ),
    body: ListView(
      key: const Key('lesson-metadata-controls'),
      children: [
        ListTile(
          key: const Key('lesson-title-control'),
          leading: const Icon(Icons.title),
          title: const Text('Lesson title'),
          subtitle: Text(_lesson.title),
          trailing: const Icon(Icons.edit_outlined),
          onTap: _rename,
        ),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Lesson Guidebook'),
          subtitle: const Text(
            'Learner reference for this Lesson. Its vocabulary and examples can also generate three progressively harder draft Rounds, which must be reviewed and approved before creation.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _editGuidebook,
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Generate 3 Rounds from Guidebook'),
          subtitle: const Text(
            'Uses this Lesson Guidebook, randomizes suitable material, avoids exact exercise repetition, previews the drafts, and creates them only after approval.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _generateThreeRoundsFromGuidebook,
        ),
        SwitchListTile(
          key: const Key('lesson-section-toggle'),
          value: _belongsToSection,
          title: const Text('Belongs to a Section'),
          subtitle: const Text(
            'Section is display metadata only and does not change progression.',
          ),
          onChanged: (value) {
            setState(() {
              _belongsToSection = value;
              if (!value) _sectionName.clear();
            });
          },
        ),
        if (_belongsToSection)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              key: const Key('lesson-section-name'),
              controller: _sectionName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Section name',
              ),
            ),
          ),
        ListTile(
          key: const Key('lesson-theme-icon-field'),
          leading: SizedBox(
            width: 56,
            height: 56,
            child: _themeIconAsset == null
                ? const Icon(Icons.menu_book_outlined, size: 38)
                : Image.asset(
                    _themeIconAsset!,
                    key: const Key('lesson-theme-icon-preview'),
                    fit: BoxFit.contain,
                  ),
          ),
          title: const Text('Lesson theme icon'),
          subtitle: Text(
            _themeIconAsset == null
                ? 'None'
                : LessonIconCatalog.options
                      .singleWhere(
                        (option) => option.assetPath == _themeIconAsset,
                      )
                      .label,
          ),
          trailing: const Icon(Icons.grid_view_outlined),
          onTap: _chooseThemeIcon,
        ),
        const Divider(),
        ListTile(
          key: const Key('lesson-rounds-navigation'),
          leading: const Icon(Icons.view_list_outlined),
          title: const Text('Rounds'),
          subtitle: Text('${_lesson.rounds.length} Rounds'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openRounds,
        ),
      ],
    ),
  );
}

class LessonRoundsScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;

  const LessonRoundsScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  State<LessonRoundsScreen> createState() => _LessonRoundsScreenState();
}

class _LessonRoundsScreenState extends State<LessonRoundsScreen> {
  late List<LearningRound> _rounds;

  @override
  void initState() {
    super.initState();
    _rounds = [...widget.lesson.rounds];
  }

  LearningRound _blankRound(String title) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final exercises = <Exercise>[
      Exercise(
        id: 'custom_ex_${stamp}_1',
        type: 'choice',
        prompt: 'Replace this question.',
        question: '',
        answers: const ['Correct answer', 'Distractor A', 'Distractor B'],
        correct: 0,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      ),
      Exercise(
        id: 'custom_ex_${stamp}_2',
        type: 'fill_blank',
        prompt: '',
        question: 'Replace this prompt.',
        answers: const [],
        correct: null,
        tts: null,
        accepted: const ['answer'],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      ),
      Exercise(
        id: 'custom_ex_${stamp}_3',
        type: 'word_order',
        prompt: 'Build the sentence.',
        question: '',
        answers: const [],
        correct: null,
        tts: null,
        accepted: const [],
        tokens: const ['Edit', 'this', 'exercise'],
        orderAnswer: const ['Edit', 'this', 'exercise'],
        pairs: const [],
        hint: '',
        icons: const [],
      ),
    ];
    return LearningRound(
      id: 'custom_round_$stamp',
      title: title,
      exercises: exercises,
    );
  }

  Future<String?> _name(String title, {String initial = ''}) async {
    var edited = initial;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          onChanged: (value) => edited = value,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, edited.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<void> _add() async {
    final title = await _name('New round');
    if (title != null && mounted) {
      setState(() => _rounds = [..._rounds, _blankRound(title)]);
    }
  }

  Lesson get _draftLesson => Lesson(
    lessonId: widget.lesson.lessonId,
    title: widget.lesson.title,
    rounds: _rounds,
    section: widget.lesson.section,
    sectionName: widget.lesson.sectionName,
    themeIconAsset: widget.lesson.themeIconAsset,
    guidebook: widget.lesson.guidebook,
    duel: widget.lesson.duel,
  );

  Future<void> _open(int index) async {
    final updated = await Navigator.of(context).push<LearningRound>(
      MaterialPageRoute(
        builder: (_) => RoundEditorScreen(
          course: widget.course,
          lesson: _draftLesson,
          round: _rounds[index],
          roundIndex: index,
        ),
      ),
    );
    if (updated != null && mounted) {
      final rounds = [..._rounds]..[index] = updated;
      setState(() => _rounds = rounds);
    }
  }

  Future<void> _remove(int index) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete round?'),
            content: const Text(
              'All exercises in this round will be removed from the local edited course.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _rounds = [..._rounds]..removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    final rounds = [..._rounds];
    final round = rounds.removeAt(oldIndex);
    rounds.insert(newIndex, round);
    setState(() => _rounds = rounds);
  }

  void _returnToLesson() => Navigator.pop(context, _rounds);

  @override
  Widget build(BuildContext context) => PopScope<List<LearningRound>>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _returnToLesson();
    },
    child: Scaffold(
      appBar: AppBar(title: Text('Rounds · ${widget.lesson.title}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('New round'),
      ),
      body: ReorderableListView.builder(
        key: const Key('lesson-rounds-list'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
        itemCount: _rounds.length,
        onReorderItem: _reorder,
        itemBuilder: (context, index) {
          final round = _rounds[index];
          return Card(
            key: ValueKey(round.id),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
              title: Text(
                round.title.trim().isEmpty ? 'Round ${index + 1}' : round.title,
              ),
              subtitle: Text('${round.exercises.length} exercises'),
              onTap: () => _open(index),
              trailing: IconButton(
                tooltip: 'Delete round',
                onPressed: () => _remove(index),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class RoundEditorScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;
  final LearningRound round;
  final int roundIndex;
  const RoundEditorScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.round,
    required this.roundIndex,
  });
  @override
  State<RoundEditorScreen> createState() => _RoundEditorScreenState();
}

class _RoundEditorScreenState extends State<RoundEditorScreen> {
  late List<Exercise> _exercises;
  late List<LearningContent> _preservedIntroContent;
  late String _title;
  @override
  void initState() {
    super.initState();
    _exercises = [...widget.round.exercises];
    _preservedIntroContent = widget.round.content
        .where((c) => c.role == 'lesson_intro')
        .toList(growable: false);
    _title = widget.round.title;
  }

  LearningRound _editedRound() => LearningRound(
    id: widget.round.id,
    title: _title,
    visualType: widget.round.visualType,
    content: [
      ..._preservedIntroContent,
      ..._exercises.map(LearningContent.fromExercise),
    ],
  );
  String _summary(Exercise e) => e.prompt.trim().isNotEmpty
      ? e.prompt.trim()
      : e.question.trim().isNotEmpty
      ? e.question.trim()
      : (e.tts ?? e.id);
  Future<void> _edit(int i) async {
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          exercise: _exercises[i],
          title: 'Edit exercise ${i + 1}',
          isNew: false,
        ),
      ),
    );
    if (e != null && mounted) setState(() => _exercises[i] = e);
  }

  Future<void> _insert() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          exercise: Exercise(
            id: 'custom_$stamp',
            type: 'choice',
            prompt: '',
            question: '',
            answers: const [],
            correct: null,
            tts: null,
            accepted: const [],
            tokens: const [],
            orderAnswer: const [],
            pairs: const [],
            hint: '',
            icons: const [],
          ),
          title: 'New exercise',
          isNew: true,
        ),
      ),
    );
    if (e == null || !mounted) return;
    setState(() => _exercises.add(e));
    _warnLength();
  }

  void _warnLength() {
    if (_exercises.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'This round now has ${_exercises.length} exercises. The standard round length is 15.',
          ),
        ),
      );
    }
  }

  void _copyExercise(int i) {
    ExerciseTransferService.copy(_exercises[i]);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text(
          'Exercise copied. Open the destination Round and tap Paste.',
        ),
      ),
    );
  }

  void _moveExercise(int i) {
    ExerciseTransferService.move(_exercises[i]);
    setState(() => _exercises.removeAt(i));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text(
          'Exercise ready to move. Open the destination Round and tap Paste.',
        ),
      ),
    );
  }

  void _pasteExercise() {
    final exercise = ExerciseTransferService.takeForPaste();
    if (exercise == null) return;
    setState(() => _exercises.add(exercise));
    _warnLength();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text('Exercise pasted into this Round.'),
      ),
    );
  }

  Future<void> _delete(int i) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete exercise?'),
            content: const Text(
              'The exercise will be removed from this local course edit.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) setState(() => _exercises.removeAt(i));
  }

  void _reorder(int oldIndex, int newIndex) {
    // onReorderItem supplies the insertion index after the item was removed.
    final item = _exercises.removeAt(oldIndex);
    setState(() => _exercises.insert(newIndex, item));
  }

  Future<void> _rename() async {
    final c = TextEditingController(text: _title);
    final n = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename round'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (n != null && mounted) {
      setState(() => _title = n.trim());
    }
  }

  Future<void> _generateFromReading(int index) async {
    final reading = _exercises[index];
    bool listening = true,
        audio = true,
        translations = true,
        wordBlocks = true,
        missingWord = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Generate exercise set from reading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The selected Reading comprehension remains the source. Choose which linked exercises to generate.',
                ),
                CheckboxListTile(
                  value: listening,
                  onChanged: (v) => setLocal(() => listening = v ?? false),
                  title: const Text('Listening comprehension'),
                ),
                CheckboxListTile(
                  value: audio,
                  onChanged: (v) => setLocal(() => audio = v ?? false),
                  title: const Text('Audio Match from passage words'),
                ),
                CheckboxListTile(
                  value: translations,
                  onChanged: (v) => setLocal(() => translations = v ?? false),
                  title: const Text('Translations from known sentence pairs'),
                ),
                CheckboxListTile(
                  value: wordBlocks,
                  onChanged: (v) => setLocal(() => wordBlocks = v ?? false),
                  title: const Text('Word Blocks from known sentence pairs'),
                ),
                CheckboxListTile(
                  value: missingWord,
                  onChanged: (v) => setLocal(() => missingWord = v ?? false),
                  title: const Text('Missing Word from passage'),
                ),
                const Text(
                  'Generated exercises are drafts and are audited immediately. Translation exercises are created only when an exact source/target pair can be inferred from existing course content.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Preview and insert'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final generated = _generateSet(
      reading,
      listening: listening,
      audio: audio,
      translations: translations,
      wordBlocks: wordBlocks,
      missingWord: missingWord,
    );
    if (generated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'No safe derived exercises could be generated from this reading.',
          ),
        ),
      );
      return;
    }
    final audit = generated
        .expand((e) => CourseAuditService().auditExercise(e))
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Insert ${generated.length} generated exercises?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in generated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '• ${e.type.replaceAll('_', ' ')}: ${_summary(e)}',
                  ),
                ),
              if (audit.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Audit: ${audit.where((i) => i.severity == AuditSeverity.error).length} errors · ${audit.where((i) => i.severity == AuditSeverity.warning).length} warnings',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Insert'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _exercises.insertAll(index + 1, generated));
      _warnLength();
    }
  }

  List<Exercise> _generateSet(
    Exercise reading, {
    required bool listening,
    required bool audio,
    required bool translations,
    required bool wordBlocks,
    required bool missingWord,
  }) {
    final out = <Exercise>[];
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final passage = reading.prompt.trim();
    final words = RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ']{2,}")
        .allMatches(passage)
        .map((m) => m.group(0)!)
        .fold<List<String>>([], (list, w) {
          if (!list.any((x) => x.toLowerCase() == w.toLowerCase())) list.add(w);
          return list;
        });
    if (listening && words.isNotEmpty) {
      final correctWord = words.first;
      final passageKeys = words.map(_norm).toSet();
      final distractors = _targetVocabularyWords()
          .where(
            (w) =>
                !passageKeys.contains(_norm(w)) &&
                _norm(w) != _norm(correctWord),
          )
          .take(3)
          .toList();
      // Only generate the recognition item when there is exactly one word from
      // the spoken passage among the choices. This prevents several options
      // from being simultaneously correct.
      if (distractors.length == 3) {
        final options = [correctWord, ...distractors];
        out.add(
          Exercise(
            id: 'gen_listen_$stamp',
            type: 'listening_comprehension',
            prompt: '',
            question: _sourceLabel(
              'Which word do you hear in the passage?',
              '¿Qué palabra oyes en el texto?',
            ),
            answers: options,
            correct: 0,
            tts: passage,
            accepted: const [],
            tokens: const [],
            orderAnswer: const [],
            pairs: const [],
            hint: '',
            icons: const [],
          ),
        );
      }
    }
    if (audio && words.length >= 5) {
      final three = words.take(3).toList();
      out.add(
        Exercise(
          id: 'gen_audio_${stamp + 1}',
          type: 'audio_match',
          prompt: _sourceLabel(
            'Match each sound to the text.',
            'Relaciona cada sonido con el texto.',
          ),
          question: '',
          answers: three,
          correct: null,
          tts: null,
          accepted: const [],
          tokens: const [],
          orderAnswer: const [],
          pairs: [
            for (final w in three) [w, w],
          ],
          hint: '',
          icons: const [],
        ),
      );
    }
    if (missingWord && words.isNotEmpty) {
      final hidden = words.length > 2 ? words[words.length ~/ 2] : words.first;
      out.add(
        Exercise(
          id: 'gen_missing_${stamp + 7}',
          type: 'missing_word',
          prompt: passage,
          question: '',
          answers: const [],
          correct: null,
          tts: passage,
          accepted: const [],
          tokens: const [],
          orderAnswer: const [],
          pairs: const [],
          hint: '',
          icons: const [],
          missingWords: [hidden],
        ),
      );
    }
    final pairs = _knownTranslationPairs();
    final sentences = passage
        .split(RegExp(r'[.!?]+\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    var seq = 2;
    for (final sentence in sentences) {
      MapEntry<String, String>? pair;
      for (final candidate in pairs.entries) {
        if (_norm(candidate.key) == _norm(sentence) ||
            _norm(candidate.value) == _norm(sentence)) {
          pair = candidate;
          break;
        }
      }
      if (pair == null) continue;
      final source = _norm(pair.key) == _norm(sentence) ? pair.value : pair.key;
      final target = sentence;
      if (translations) {
        final distractors = pairs.values
            .where((v) => _norm(v) != _norm(target))
            .take(3)
            .toList();
        final answers = [target, ...distractors];
        if (answers.length >= 2) {
          out.add(
            Exercise(
              id: 'gen_trans_${stamp + seq++}',
              type: 'choice',
              prompt: '${_sourceLabel('Translate', 'Traduce')}: “$source”',
              question: '',
              answers: answers,
              correct: 0,
              tts: null,
              accepted: const [],
              tokens: const [],
              orderAnswer: const [],
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          );
        }
      }
      if (wordBlocks) {
        final answer = target
            .split(RegExp(r'\s+'))
            .where((x) => x.isNotEmpty)
            .toList();
        final candidates = words
            .where((w) => !answer.any((a) => _norm(a) == _norm(w)))
            .toList();
        // The distractor is taken only from the same target-language passage.
        // If no safe same-language distractor exists, do not manufacture one.
        if (candidates.isNotEmpty) {
          final distractor = candidates.first;
          out.add(
            Exercise(
              id: 'gen_order_${stamp + seq++}',
              type: 'word_order',
              prompt: '${_sourceLabel('Translate', 'Traduce')}: “$source”',
              question: '',
              answers: const [],
              correct: null,
              tts: null,
              accepted: const [],
              tokens: [...answer, distractor],
              orderAnswer: answer,
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          );
        }
      }
      if (out.length >= 8) break;
    }
    return out;
  }

  List<String> _targetVocabularyWords() {
    final result = <String>[];
    final seen = <String>{};
    for (final lesson in widget.course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          // Reading passages are guaranteed target-language material in the
          // course format, so they are a safe source of same-language
          // distractors for generated listening recognition questions.
          if (exercise.type != 'reading_comprehension') continue;
          for (final match in RegExp(
            r"[A-Za-zÀ-ÖØ-öø-ÿ']{2,}",
          ).allMatches(exercise.prompt)) {
            final word = match.group(0)!;
            final key = _norm(word);
            if (key.isNotEmpty && seen.add(key)) result.add(word);
          }
        }
      }
    }
    return result;
  }

  String _sourceLabel(String english, String spanish) =>
      widget.course.sourceLanguage.toLowerCase().startsWith('spanish')
      ? spanish
      : english;
  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-zà-öø-ÿ0-9]+'), ' ').trim();
  Map<String, String> _knownTranslationPairs() {
    final result = <String, String>{};
    for (final lesson in widget.course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          if (exercise.correct == null ||
              exercise.correct! < 0 ||
              exercise.correct! >= exercise.answers.length) {
            continue;
          }
          final match = RegExp(
            r'[“\"]([^”\"]+)[”\"]',
          ).firstMatch(exercise.prompt);
          if (match == null) continue;
          final source = match.group(1)!.trim();
          final target = exercise.answers[exercise.correct!].trim();
          if (source.isNotEmpty && target.isNotEmpty) {
            result[source] = target;
          }
        }
      }
    }
    return result;
  }

  Future<void> _previewRound() async {
    final preview = _editedRound();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          lesson: widget.lesson,
          round: preview,
          ttsLanguage: widget.course.ttsLanguage,
          roundIndex: widget.roundIndex,
          previewMode: true,
        ),
      ),
    );
  }

  Future<void> _previewExercise(int index) async {
    final preview = LearningRound(
      id: 'preview_${widget.round.id}',
      title: 'Preview exercise',
      visualType: widget.round.visualType,
      exercises: [_exercises[index]],
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          lesson: widget.lesson,
          round: preview,
          ttsLanguage: widget.course.ttsLanguage,
          roundIndex: widget.roundIndex,
          previewMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_title.isEmpty ? 'Round ${widget.roundIndex + 1}' : _title),
      actions: [
        if (ExerciseTransferService.hasPending)
          IconButton(
            tooltip: 'Paste pending exercise here',
            onPressed: _pasteExercise,
            icon: const Icon(Icons.content_paste),
          ),
        IconButton(
          tooltip: 'Preview round',
          onPressed: _exercises.isEmpty ? null : _previewRound,
          icon: const Icon(Icons.play_circle_outline),
        ),
        IconButton(
          tooltip: 'Rename round',
          onPressed: _rename,
          icon: const Icon(Icons.edit_outlined),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _editedRound()),
          child: const Text('Save'),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _insert,
      icon: const Icon(Icons.add),
      label: const Text('Insert exercise'),
    ),
    body: ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
      itemCount: _exercises.length,
      onReorderItem: _reorder,
      itemBuilder: (context, i) {
        final e = _exercises[i];
        return Card(
          key: ValueKey(e.id),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: i,
              child: CircleAvatar(child: Text('${i + 1}')),
            ),
            title: Text(_ExerciseEditorScreenState.labelForType(e.type)),
            subtitle: Text(
              _summary(e),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _edit(i),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _delete(i);
                if (v == 'generate') _generateFromReading(i);
                if (v == 'preview') _previewExercise(i);
                if (v == 'copy') _copyExercise(i);
                if (v == 'move') _moveExercise(i);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'preview',
                  child: Text('Preview exercise'),
                ),
                const PopupMenuItem(value: 'copy', child: Text('Copy…')),
                const PopupMenuItem(value: 'move', child: Text('Move…')),
                if (e.type == 'reading_comprehension')
                  const PopupMenuItem(
                    value: 'generate',
                    child: Text('Generate exercise set'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete exercise'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class CourseAuditScreen extends StatefulWidget {
  final Course course;
  final CourseAuditResult result;
  const CourseAuditScreen({
    super.key,
    required this.course,
    required this.result,
  });
  @override
  State<CourseAuditScreen> createState() => _CourseAuditScreenState();
}

class _CourseAuditScreenState extends State<CourseAuditScreen> {
  AuditSeverity? _filter;
  @override
  Widget build(BuildContext context) {
    final issues = _filter == null
        ? widget.result.issues
        : widget.result.issues.where((i) => i.severity == _filter).toList();
    Widget chip(String label, AuditSeverity? severity) => ChoiceChip(
      label: Text(label),
      selected: _filter == severity,
      onSelected: (_) => setState(() => _filter = severity),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Course Audit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip('All ${widget.result.issues.length}', null),
                  chip(
                    'Errors ${widget.result.count(AuditSeverity.error)}',
                    AuditSeverity.error,
                  ),
                  chip(
                    'Warnings ${widget.result.count(AuditSeverity.warning)}',
                    AuditSeverity.warning,
                  ),
                  chip(
                    'Suggestions ${widget.result.count(AuditSeverity.suggestion)}',
                    AuditSeverity.suggestion,
                  ),
                ],
              ),
            ),
          ),
          if (issues.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No items in this category.'),
              ),
            ),
          ...issues.map(
            (i) => Card(
              child: ListTile(
                leading: Icon(
                  i.severity == AuditSeverity.error
                      ? Icons.error_outline
                      : i.severity == AuditSeverity.warning
                      ? Icons.warning_amber_outlined
                      : Icons.lightbulb_outline,
                ),
                title: Text('${i.severity.name.toUpperCase()}: ${i.message}'),
                subtitle: Text('${i.code} · ${i.location}'),
                trailing: i.roundId == null
                    ? null
                    : const Icon(Icons.edit_outlined),
                onTap: i.roundId == null
                    ? null
                    : () => Navigator.pop(context, i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseEditorScreen extends StatefulWidget {
  final Exercise exercise;
  final String title;
  final bool isNew;
  const ExerciseEditorScreen({
    super.key,
    required this.exercise,
    required this.title,
    required this.isNew,
  });
  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  final _imageService = ExerciseImageService();
  late String _imageAsset;
  static List<String> get _types =>
      ExercisePresetRegistry.presets.map((preset) => preset.id).toList();
  static String labelForType(String type) =>
      ExercisePresetRegistry.byId(type)?.name ?? type.replaceAll('_', ' ');
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
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue;
  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _type = _types.contains(e.type) ? e.type : 'choice';
    _prompt = TextEditingController(text: e.prompt);
    _question = TextEditingController(text: e.question);
    _tts = TextEditingController(text: e.tts ?? '');
    _hint = TextEditingController(text: e.hint);
    _answers = TextEditingController(text: e.answers.join('\n'));
    _correct = TextEditingController(
      text: e.correct == null ? '' : '${e.correct! + 1}',
    );
    _accepted = TextEditingController(text: e.accepted.join('\n'));
    _tokens = TextEditingController(text: e.tokens.join('\n'));
    _order = TextEditingController(text: e.orderAnswer.join('\n'));
    _pairs = TextEditingController(
      text: e.pairs.map((p) => p.join(' = ')).join('\n'),
    );
    _icons = TextEditingController(text: e.icons.join('\n'));
    _missingWords = TextEditingController(text: e.missingWords.join('\n'));
    _context = TextEditingController(text: e.contextText);
    _dialogue = TextEditingController(
      text: e.dialogueTurns
          .map((turn) => '${turn.speaker}: ${turn.text}')
          .join('\n'),
    );
    _contextMode = e.contextMode;
    _imageAsset = e.imageAsset;
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
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) => c.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  List<List<String>> _pairLines() {
    final out = <List<String>>[];
    for (final line in _lines(_pairs)) {
      final separator = line.indexOf('=');
      if (separator > 0 && separator < line.length - 1) {
        out.add([
          line.substring(0, separator).trim(),
          line.substring(separator + 1).trim(),
        ]);
      }
    }
    return out;
  }

  List<PromptElement> _dialogueTurns() {
    final turns = <PromptElement>[];
    for (final line in _lines(_dialogue)) {
      final separator = line.indexOf(':');
      if (separator <= 0 || separator >= line.length - 1) {
        turns.add(
          PromptElement(role: 'dialogue_turn', type: 'text', text: line),
        );
      } else {
        turns.add(
          PromptElement(
            role: 'dialogue_turn',
            type: 'text',
            speaker: line.substring(0, separator).trim(),
            text: line.substring(separator + 1).trim(),
          ),
        );
      }
    }
    return turns;
  }

  bool get _choices => const {
    'choice',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
  }.contains(_type);
  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      minLines: lines,
      maxLines: lines == 1 ? 3 : lines + 4,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
      ),
    ),
  );
  List<Widget> _specificFields() {
    switch (_type) {
      case 'flashcard':
        return [
          _field(_prompt, 'Word / expression'),
          _field(_question, 'Translation / meaning'),
          _field(_tts, 'Pronunciation TTS'),
          _field(
            _answers,
            'Usage sentence and optional translation',
            lines: 3,
            helper:
                'First line = usage sentence. “Usage:” is added automatically in learner mode.',
          ),
        ];
      case 'gap_choice':
        return [
          _field(
            _question,
            'Target-language sentence with one gap',
            lines: 3,
            helper: 'Use ___ to mark the missing word or expression.',
          ),
          _field(
            _answers,
            'Answer blocks',
            lines: 4,
            helper:
                'Use plausible options, but make sure only one answer is correct in both meaning and grammar.',
          ),
          _field(_correct, 'Correct answer number'),
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
            'Source text',
            lines: 3,
            helper: 'Enter the text the learner must translate.',
          ),
          _field(
            _accepted,
            'Accepted translations',
            lines: 5,
            helper:
                'One complete equivalent answer per line. Optional {...}, alternatives [a|b], and scoped reorder (a <> b) syntax are supported.',
          ),
          _field(_hint, 'Hint (optional)'),
        ];
      case 'build_translation':
        return [
          _field(_prompt, 'Source text', lines: 3),
          _field(
            _tokens,
            'Available target-language blocks',
            lines: 5,
            helper:
                'One block per line. You may include 0, 1 or at most 2 distractors.',
          ),
          _field(
            _order,
            'Correct translation',
            lines: 5,
            helper: 'One block per line in the required order.',
          ),
        ];
      case 'word_order':
        return [
          _field(_prompt, 'Translation prompt / instruction', lines: 2),
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
        return [
          _field(
            _prompt,
            'Instruction',
            lines: 2,
            helper: 'Example: Build the word shown in the image.',
          ),
          _field(
            _tokens,
            'Available letter / syllable blocks',
            lines: 5,
            helper:
                'One block per line. Do not add distractors: include only the blocks required to build the correct word.',
          ),
          _field(
            _order,
            'Correct target-language word',
            lines: 5,
            helper:
                'One letter or syllable block per line, in the correct order. An image is required.',
          ),
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
          _field(
            _prompt,
            'Instruction',
            lines: 2,
            helper: 'Source → target translation match.',
          ),
          _field(
            _pairs,
            'Three translation pairs',
            lines: 5,
            helper: 'Exactly three lines: source = target',
          ),
        ];
      case 'super_match':
        return [
          _field(
            _prompt,
            'Match type / instruction',
            lines: 2,
            helper:
                'Everything must be in the target language. Examples: Match the synonyms; Match the opposites.',
          ),
          _field(
            _pairs,
            'Three target-language pairs',
            lines: 5,
            helper: 'Exactly three lines: left = right',
          ),
        ];
      case 'audio_match':
        return [
          _field(_prompt, 'Instruction', lines: 2),
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
          _field(_question, 'Question', lines: 2),
          _field(_answers, 'Target-language options', lines: 4),
          _field(_correct, 'Correct answer number'),
          _field(_icons, 'Icons / image keys', lines: 4),
        ];
      case 'listening_choice':
        return [
          _field(_tts, 'Audio text', lines: 2),
          _field(_question, 'Question', lines: 2),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'listening_comprehension':
        return [
          _field(_tts, 'Spoken passage', lines: 4),
          _field(_question, 'Comprehension question', lines: 2),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'reading_comprehension':
        return [
          _field(_prompt, 'Reading passage', lines: 5),
          _field(_question, 'Comprehension question', lines: 2),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'dialogue_response':
        return [
          _field(
            _prompt,
            'Context sentence',
            lines: 3,
            helper: 'Write the situation in the target language.',
          ),
          _field(
            _question,
            'Question',
            lines: 2,
            helper: 'Write the question in the target language.',
          ),
          _field(
            _answers,
            'Two response options',
            lines: 3,
            helper: 'Exactly two lines, both in the target language.',
          ),
          _field(
            _correct,
            'Correct response number',
            helper:
                'Enter 1 or 2. The learner sees the responses in randomized order.',
          ),
        ];
      case 'contextual_comprehension':
        return [
          DropdownButtonFormField<String>(
            key: const Key('context-mode-selector'),
            initialValue: _contextMode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Context mode',
            ),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Text')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
              DropdownMenuItem(
                value: 'textAndAudio',
                child: Text('Text and audio'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _contextMode = value ?? _contextMode),
          ),
          const SizedBox(height: 12),
          if (_contextMode != 'audio')
            _field(
              _context,
              'Context text',
              lines: 5,
              helper:
                  'Use this for a passage, announcement, situation or other context.',
            ),
          if (_contextMode != 'text')
            _field(_tts, 'Context audio text', lines: 5),
          if (_contextMode != 'audio')
            _field(
              _dialogue,
              'Structured dialogue (optional)',
              lines: 5,
              helper:
                  'One turn per line: Speaker: text. Leave blank for non-dialogue context.',
            ),
          _field(_question, 'Question', lines: 2),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
      case 'listening_spelling':
        return [
          _field(_prompt, 'Passage transcript', lines: 5),
          _field(_tts, 'Audio text', lines: 5),
          _field(
            _missingWords,
            'Missing word',
            lines: 2,
            helper:
                'The learner types this word from the keyboard. Return/Enter submits the answer.',
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
      default:
        return [
          _field(_prompt, 'Prompt / instruction', lines: 2),
          _field(_question, 'Question', lines: 2),
          _field(_answers, 'Answers', lines: 4),
          _field(_correct, 'Correct answer number'),
        ];
    }
  }

  Future<void> _chooseFlatImage() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const FlatImageLibraryScreen()),
    );
    if (selected != null && mounted) setState(() => _imageAsset = selected);
  }

  Future<void> _importCustomImage() async {
    try {
      final selected = await _imageService.importImage();
      if (selected != null && mounted) setState(() => _imageAsset = selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  Widget _imageEditor() {
    Widget preview;
    if (_imageAsset.isEmpty) {
      preview = const SizedBox(
        height: 120,
        child: Center(child: Text('No image selected')),
      );
    } else if (_imageAsset.startsWith('assets/')) {
      preview = Image.asset(
        _imageAsset,
        height: 150,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 120,
          child: Center(child: Text('Image asset file is missing.')),
        ),
      );
    } else if (!File(_imageAsset).existsSync()) {
      preview = const SizedBox(
        height: 120,
        child: Center(child: Text('Image asset file is missing.')),
      );
    } else {
      preview = Image.file(
        File(_imageAsset),
        height: 150,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 120,
          child: Center(child: Text('Image asset file is unreadable.')),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Exercise image',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            preview,
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _chooseFlatImage,
                  icon: const Icon(Icons.grid_view_outlined),
                  label: const Text('Choose flat image'),
                ),
                OutlinedButton.icon(
                  onPressed: _importCustomImage,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import custom image'),
                ),
                if (_imageAsset.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _imageAsset = ''),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove image'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'The built-in Image Bank contains lightweight flat images. For Import custom image, place exactly one PNG, JPG, JPEG or WEBP file in Documents/QuisquisLingo/Imports/Images. An image is optional and can be changed at any time.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePreset() async {
    final search = TextEditingController();
    var query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = ExercisePresetRegistry.presets.where((preset) {
            final needle = query.toLowerCase();
            return needle.isEmpty ||
                preset.name.toLowerCase().contains(needle) ||
                preset.description.toLowerCase().contains(needle) ||
                preset.category.label.toLowerCase().contains(needle);
          }).toList();
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
                          child: ListTile(
                            title: Text(preset.name),
                            subtitle: Text(preset.description),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(sheetContext, preset.id),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => search.dispose());
    if (selected != null && mounted) setState(() => _type = selected);
  }

  Future<void> _save() async {
    final answers = _type == 'flashcard'
        ? _lines(_answers)
        : _type == 'audio_match'
        ? _pairLines().map((p) => p[1]).toList()
        : _choices
        ? _lines(_answers)
        : <String>[];
    int? correct;
    if (_choices) {
      final parsed = int.tryParse(_correct.text.trim());
      if (parsed == null || parsed < 1 || parsed > answers.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('Choose a valid correct answer number.'),
          ),
        );
        return;
      }
      correct = parsed - 1;
    }
    final Exercise ex;
    if (_type == 'contextual_comprehension') {
      final items = <ExerciseItem>[
        for (var i = 0; i < answers.length; i++)
          ExerciseItem(
            id: i < widget.exercise.interaction.items.length
                ? widget.exercise.interaction.items[i].id
                : 'item_$i',
            content: [PromptElement(type: 'text', text: answers[i])],
          ),
      ];
      ex = Exercise.v2(
        id: widget.exercise.id,
        editorTemplate: _type,
        promptElements: [
          if (_contextMode != 'audio' && _context.text.trim().isNotEmpty)
            PromptElement(
              role: 'context',
              type: 'text',
              text: _context.text.trim(),
            ),
          if (_contextMode != 'text' && _tts.text.trim().isNotEmpty)
            PromptElement(
              role: 'context',
              type: 'audio',
              text: _tts.text.trim(),
            ),
          if (_imageAsset.isNotEmpty)
            PromptElement(role: 'context', type: 'image', asset: _imageAsset),
          ..._dialogueTurns(),
          PromptElement(
            role: 'question',
            type: 'text',
            text: _question.text.trim(),
          ),
        ],
        interaction: ExerciseInteraction(kind: 'select', items: items),
        evaluation: ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: correct == null ? const [] : [items[correct].id],
        ),
        hint: '',
      );
    } else {
      ex = Exercise(
        id: widget.exercise.id,
        type: _type,
        prompt:
            const {
              'flashcard',
              'word_order',
              'build_translation',
              'type_translation',
              'image_word',
              'matching',
              'audio_match',
              'word_match',
              'super_match',
              'reading_comprehension',
              'choice',
              'missing_word',
              'listening_spelling',
              'dialogue_response',
            }.contains(_type)
            ? _prompt.text.trim()
            : '',
        question:
            const {
              'flashcard',
              'fill_blank',
              'icon_choice',
              'listening_choice',
              'listening_comprehension',
              'reading_comprehension',
              'choice',
              'gap_choice',
              'dialogue_response',
            }.contains(_type)
            ? _question.text.trim()
            : '',
        answers: answers,
        correct: correct,
        tts:
            const {
                  'flashcard',
                  'fill_blank',
                  'listening_choice',
                  'listening_comprehension',
                  'missing_word',
                  'listening_spelling',
                }.contains(_type) &&
                _tts.text.trim().isNotEmpty
            ? _tts.text.trim()
            : null,
        accepted: _type == 'listening_spelling'
            ? _lines(_missingWords)
            : const {'fill_blank', 'type_translation'}.contains(_type)
            ? _lines(_accepted)
            : const [],
        tokens:
            const {
              'word_order',
              'image_word',
              'build_translation',
            }.contains(_type)
            ? _lines(_tokens)
            : const [],
        orderAnswer:
            const {
              'word_order',
              'image_word',
              'build_translation',
            }.contains(_type)
            ? _lines(_order)
            : const [],
        pairs:
            const {
              'matching',
              'audio_match',
              'word_match',
              'super_match',
            }.contains(_type)
            ? _pairLines()
            : const [],
        hint: const {'fill_blank', 'type_translation'}.contains(_type)
            ? _hint.text.trim()
            : '',
        icons: _type == 'icon_choice' ? _lines(_icons) : const [],
        imageAsset: _imageAsset,
        missingWords:
            const {'missing_word', 'listening_spelling'}.contains(_type)
            ? _lines(_missingWords)
            : const [],
      );
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
      return;
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
      if (use != true) return;
    }
    if (!mounted) return;
    Navigator.pop(context, ex);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (widget.isNew)
          Card(
            key: const Key('exercise-preset-selector'),
            child: ListTile(
              title: Text(labelForType(_type)),
              subtitle: Text(
                '${ExercisePresetRegistry.byId(_type)!.category.label} · ${ExercisePresetRegistry.byId(_type)!.description}',
              ),
              trailing: const Icon(Icons.unfold_more),
              onTap: _choosePreset,
            ),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Exercise type'),
            subtitle: Text(labelForType(_type)),
            trailing: const Icon(Icons.lock_outline),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseHelpScreen()),
            ),
            icon: const Icon(Icons.help_outline),
            label: const Text('Exercise Help'),
          ),
        ),
        const SizedBox(height: 12),
        ..._specificFields(),
        const SizedBox(height: 12),
        _imageEditor(),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Use this exercise'),
        ),
      ],
    ),
  );
}

class AudioLibraryScreen extends StatefulWidget {
  final Course course;
  const AudioLibraryScreen({super.key, required this.course});
  @override
  State<AudioLibraryScreen> createState() => _AudioLibraryScreenState();
}

class _AudioLibraryScreenState extends State<AudioLibraryScreen> {
  final _audio = RecordedAudioService();
  final AudioPlayer _previewPlayer = AudioPlayer();
  late Course _course;
  String? _playingId;
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Course _copy({String? mode, List<CourseAudioClip>? clips}) => Course(
    courseId: _course.courseId,
    parentCourseId: _course.parentCourseId,
    derivedFromVersion: _course.derivedFromVersion,
    learningLanguage: _course.learningLanguage,
    interfaceLanguage: _course.interfaceLanguage,
    sourceLanguage: _course.sourceLanguage,
    targetLanguage: _course.targetLanguage,
    title: _course.title,
    ttsLanguage: _course.ttsLanguage,
    version: _course.version,
    contentRevision: _course.contentRevision,
    updateSummary: _course.updateSummary,
    audioMode: mode ?? _course.audioMode,
    audioLibrary: clips ?? _course.audioLibrary,
    lessons: _course.lessons,
    author: _course.author,
    license: _course.license,
    sourceLanguageTag: _course.sourceLanguageTag,
    targetLanguageTag: _course.targetLanguageTag,
    textDirection: _course.textDirection,
    flagCode: _course.flagCode,
    flagImageBase64: _course.flagImageBase64,
    authors: _course.authors,
    languageVariant: _course.languageVariant,
    startLevel: _course.startLevel,
    targetLevel: _course.targetLevel,
    courseVersion: _course.courseVersion,
    lastUpdated: _course.lastUpdated,
    courseDescription: _course.courseDescription,
    temporarySample: _course.temporarySample,
    supportUrl: _course.supportUrl,
  );
  Future<void> _import() async {
    try {
      final clips = await _audio.importMp3Files(_course.learningLanguage);
      if (clips.isNotEmpty && mounted) {
        setState(
          () => _course = _copy(clips: [..._course.audioLibrary, ...clips]),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Imported ${clips.length} MP3 file${clips.length == 1 ? '' : 's'} from Documents/QuisquisLingo/Imports/Audio.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  Future<void> _editById(String id) async {
    final i = _course.audioLibrary.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final c = TextEditingController(text: _course.audioLibrary[i].text);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Associate recording'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Word or expression',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (text != null && text.trim().isNotEmpty && mounted) {
      final list = [..._course.audioLibrary];
      final old = list[i];
      list[i] = CourseAudioClip(
        id: old.id,
        text: text.trim(),
        filePath: old.filePath,
      );
      setState(() => _course = _copy(clips: list));
    }
  }

  Future<void> _deleteById(String id) async {
    final i = _course.audioLibrary.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final clip = _course.audioLibrary[i];
    if (_playingId == id) {
      await _previewPlayer.stop();
      _playingId = null;
    }
    await _audio.deleteFiles([clip]);
    if (!mounted) return;
    final list = [..._course.audioLibrary]..removeAt(i);
    setState(() => _course = _copy(clips: list));
  }

  Future<void> _preview(CourseAudioClip clip) async {
    if (_playingId == clip.id) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      final source = _audio.sourceForClip(clip);
      if (source == null) throw StateError('MP3 source is missing');
      await _previewPlayer.stop();
      await _previewPlayer.play(source);
      if (mounted) setState(() => _playingId = clip.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Could not play this MP3 file.'),
        ),
      );
    }
  }

  Future<void> _orphans() async {
    final list = _audio.orphaned(_course);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${list.length} orphan MP3 files'),
        content: SingleChildScrollView(
          child: Text(
            list.isEmpty
                ? 'No unused MP3 files.'
                : list
                      .map((e) => e.filePath.split(Platform.pathSeparator).last)
                      .join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (list.isNotEmpty)
            FilledButton(
              onPressed: () async {
                await _audio.deleteFiles(list);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                final ids = list.map((e) => e.id).toSet();
                setState(
                  () => _course = _copy(
                    clips: _course.audioLibrary
                        .where((e) => !ids.contains(e.id))
                        .toList(),
                  ),
                );
              },
              child: const Text('Delete unused'),
            ),
        ],
      ),
    );
  }

  String _initial(CourseAudioClip c) {
    final t = c.text.trim();
    if (t.isEmpty) return '#';
    final ch = t.characters.first.toUpperCase();
    return RegExp(r'[A-ZÀ-ÖØ-Þ]').hasMatch(ch) ? ch : '#';
  }

  List<CourseAudioClip> get _sorted {
    final out = [..._course.audioLibrary];
    out.sort((a, b) {
      final ae = a.text.trim().isEmpty, be = b.text.trim().isEmpty;
      if (ae != be) return ae ? 1 : -1;
      return a.text.toLowerCase().compareTo(b.text.toLowerCase());
    });
    return out;
  }

  Future<void> _jump(String letter) async {
    final ctx = _letterKeys[letter]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        alignment: .08,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final letters =
        sorted
            .where((e) => e.text.trim().isNotEmpty)
            .map(_initial)
            .toSet()
            .toList()
          ..sort();
    final children = <Widget>[
      DropdownButtonFormField<String>(
        initialValue: _course.audioMode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Course audio source',
        ),
        items: const [
          DropdownMenuItem(value: 'tts', child: Text('System TTS')),
          DropdownMenuItem(value: 'recorded', child: Text('Recorded MP3 only')),
          DropdownMenuItem(
            value: 'hybrid',
            child: Text('Hybrid: MP3 + TTS fallback'),
          ),
        ],
        onChanged: (v) {
          if (v != null) setState(() => _course = _copy(mode: v));
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'For recorded audio, QuisquisLingo uses the longest matching word or expression first and concatenates MP3 clips. Hybrid mode falls back to TTS when a complete recorded sequence is unavailable.',
      ),
      const SizedBox(height: 8),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Import MP3: copy the MP3 files you want to import to Documents/QuisquisLingo/Imports/Audio, then press Import MP3. All MP3 files in that folder are imported. Source files are left in place, so move or remove them after a successful import to avoid importing them again.',
          ),
        ),
      ),
      ListTile(
        title: const Text('Check unused MP3 files'),
        subtitle: const Text(
          'Find recordings not associated with any course text.',
        ),
        trailing: const Icon(Icons.cleaning_services_outlined),
        onTap: _orphans,
      ),
      if (letters.isNotEmpty)
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final l in letters)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ActionChip(label: Text(l), onPressed: () => _jump(l)),
                ),
            ],
          ),
        ),
      const Divider(),
    ];
    String? previous;
    for (final clip in sorted) {
      final letter = _initial(clip);
      if (letter != previous) {
        previous = letter;
        _letterKeys.putIfAbsent(letter, () => GlobalKey());
        children.add(
          Padding(
            key: _letterKeys[letter],
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Text(
              letter == '#' ? 'Unassigned' : letter,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
      children.add(
        Card(
          child: ListTile(
            leading: IconButton(
              tooltip: _playingId == clip.id ? 'Stop preview' : 'Play preview',
              icon: Icon(
                _playingId == clip.id
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              onPressed: () => _preview(clip),
            ),
            title: Text(
              clip.text.trim().isEmpty ? 'Unassigned MP3' : clip.text,
            ),
            subtitle: Text(
              clip.filePath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _editById(clip.id),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteById(clip.id),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Library'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _course),
            child: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.library_music_outlined),
        label: const Text('Import MP3'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        children: children,
      ),
    );
  }
}

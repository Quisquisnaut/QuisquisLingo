import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/answer_engine.dart';
import '../services/answer_materialization_service.dart';
import '../services/file_dialog_service.dart';
import '../services/first_letter_answer_service.dart';
import '../services/portable_exercise_image.dart';
import '../widgets/script_recognition_editor.dart';
import '../widgets/exercise_image_field.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/course_draft_status.dart';
import '../models/course_flag_selection.dart';
import '../models/course_models.dart';
import '../models/course_metadata_options.dart';
import '../models/exercise_authoring.dart';
import '../services/course_editor_service.dart';
import '../services/course_flag_service.dart';
import '../services/course_language_resolver.dart';
import '../services/formal_name_policy.dart';
import '../services/course_governance_resolver.dart';
import '../services/course_governance_service.dart';
import '../services/course_info_update_service.dart';
import '../services/course_authoring_session.dart';
import '../services/course_access_policy.dart';
import '../services/course_service.dart';
import '../services/course_audit_service.dart';
import '../services/audit_code_registry.dart' show AuditCode;
import '../services/course_audit_report_service.dart';
import '../services/settings_service.dart';
import '../services/editor_display_preferences.dart';
import '../services/exercise_search_service.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';
import '../services/lesson_icon_catalog.dart';
import '../services/lesson_icon_service.dart';
import '../services/lesson_presentation_service.dart';
import '../services/recorded_audio_service.dart';
import 'round_screen.dart';
import 'flat_image_library_screen.dart';
import 'editor_help_screen.dart';
import 'course_version_history_screen.dart';
import 'course_info_screen.dart';
import 'guidebook_screen.dart';
import 'course_editor_search_screen.dart';
import '../services/course_authoring_transfer_service.dart';
import '../services/translation_choice_service.dart';
import '../services/exercise_field_help.dart';
import '../widgets/editor_breadcrumbs.dart';
import '../widgets/authoring_destination_dialog.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/authoring_duplication_service.dart';
import '../services/exercise_creation_planner.dart';
import '../services/guidebook_round_generator.dart';
import '../services/publication_service.dart';
import '../services/provisional_publication_service.dart';
import '../services/new_course_structure.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/flag_art.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/lesson_fallback_icon.dart';
import '../widgets/import_summary.dart';

String _exerciseCountLabel(int count) =>
    '$count ${count == 1 ? 'Exercise' : 'Exercises'}';
String _roundCountLabel(int count) =>
    '$count ${count == 1 ? 'Round' : 'Rounds'}';

const _hierarchyLinkStyle = TextStyle(fontWeight: FontWeight.w800);

class AuthoringHierarchyStatus {
  AuthoringHierarchyStatus._(this.course, CourseAuditResult audit)
    : hasCourseAuditConcern = audit.issues.any(_isAuditConcern),
      hasLessonsAuditConcern = audit.issues.any(
        (issue) =>
            _isAuditConcern(issue) &&
            (issue.code == AuditCode.courseLessonsEmpty.code ||
                issue.location.startsWith('Lesson ')),
      ),
      exerciseAuditConcernIds = {
        for (final issue in audit.issues)
          if (_isAuditConcern(issue) && issue.exerciseId != null)
            issue.exerciseId!,
      },
      roundAuditConcernIds = {
        for (final issue in audit.issues)
          if (_isAuditConcern(issue) && issue.roundId != null) issue.roundId!,
      },
      lessonAuditConcernIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                _isAuditConcern(issue) &&
                (issue.location ==
                        'Lesson ${index + 1} · ${course.lessons[index].title}' ||
                    issue.location.startsWith(
                      'Lesson ${index + 1} · ${course.lessons[index].title} ·',
                    )),
          ))
            course.lessons[index].lessonId,
      },
      lessonEmptyRoundsIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                issue.code == AuditCode.lessonRoundsEmpty.code &&
                issue.location ==
                    'Lesson ${index + 1} · ${course.lessons[index].title}',
          ))
            course.lessons[index].lessonId,
      },
      lessonGuidebookAuditConcernIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                _isAuditConcern(issue) &&
                issue.roundId == null &&
                issue.exerciseId == null &&
                (issue.location ==
                        'Lesson ${index + 1} · ${course.lessons[index].title} · Guidebook' ||
                    issue.location.startsWith(
                      'Lesson ${index + 1} · ${course.lessons[index].title} · Guidebook Content ',
                    )),
          ))
            course.lessons[index].lessonId,
      };

  static bool _isAuditConcern(CourseAuditIssue issue) =>
      issue.severity == AuditSeverity.error ||
      issue.severity == AuditSeverity.warning;

  factory AuthoringHierarchyStatus.fromCourse(Course course) =>
      AuthoringHierarchyStatus._(
        course,
        CourseAuditService().auditCourse(course),
      );

  final Course course;
  final bool hasCourseAuditConcern;
  final bool hasLessonsAuditConcern;
  final Set<String> exerciseAuditConcernIds;
  final Set<String> roundAuditConcernIds;
  final Set<String> lessonAuditConcernIds;
  final Set<String> lessonEmptyRoundsIds;
  final Set<String> lessonGuidebookAuditConcernIds;

  /// Draft rules live in [CourseDraftStatus]; these getters delegate to it.
  bool get courseHasDraft => CourseDraftStatus.courseHasDraft(course);
  bool lessonHasDraft(Lesson lesson) =>
      CourseDraftStatus.lessonHasDraft(course, lesson);
  bool lessonGuidebookHasDraft(Lesson lesson) =>
      CourseDraftStatus.lessonGuidebookHasDraft(course, lesson);
  bool lessonHasRoundDraft(Lesson lesson) =>
      CourseDraftStatus.lessonHasRoundDraft(lesson);
  bool lessonHasAuditConcern(Lesson lesson) =>
      lessonAuditConcernIds.contains(lesson.lessonId);

  /// The Guidebook card border: no color at all while GuideBook is off.
  bool? lessonGuidebookAuditStatus(Lesson lesson) =>
      course.useGuidebook ? lessonGuidebookHasAuditConcern(lesson) : null;
  bool lessonGuidebookHasAuditConcern(Lesson lesson) =>
      lessonGuidebookAuditConcernIds.contains(lesson.lessonId);
  bool lessonHasRoundAuditConcern(Lesson lesson) =>
      lessonEmptyRoundsIds.contains(lesson.lessonId) ||
      lesson.rounds.any(roundHasAuditConcern);
  bool roundHasDraft(LearningRound round) =>
      CourseDraftStatus.roundHasDraft(round);
  bool roundHasAuditConcern(LearningRound round) =>
      roundAuditConcernIds.contains(round.id);
  bool exerciseIsDraft(Exercise exercise) =>
      CourseDraftStatus.exerciseIsDraft(exercise);
  bool exerciseHasAuditConcern(Exercise exercise) =>
      exerciseAuditConcernIds.contains(exercise.id);
}

class AuthoringStatusCard extends StatelessWidget {
  const AuthoringStatusCard({
    super.key,
    required this.indicatorKey,
    required this.draftIndicatorKey,
    required this.hasDraft,
    required this.hasAuditConcern,
    required this.child,
    this.cardMargin,
    this.hasUnpublished = false,
    this.unpublishedIndicatorKey,
    this.neutralAuditMessage =
        'Audit status is not current; no red or green border is shown.',
  });

  final Key indicatorKey;
  final Key draftIndicatorKey;
  final bool hasDraft;
  final bool? hasAuditConcern;
  final Widget child;
  final EdgeInsetsGeometry? cardMargin;
  final bool hasUnpublished;
  final Key? unpublishedIndicatorKey;

  /// Tooltip text used when [hasAuditConcern] is null (no border color).
  final String neutralAuditMessage;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final auditColor = switch (hasAuditConcern) {
      true => dark ? const Color(0xFFFF5A5F) : const Color(0xFFC90000),
      false => dark ? const Color(0xFF5CFF85) : const Color(0xFF00A83B),
      null => null,
    };
    final auditMessage = switch (hasAuditConcern) {
      true => 'Red border: this branch has an Audit Error or Warning.',
      false =>
        'Green border: this branch has no Audit Error or Warning. Info guidance may remain.',
      null => neutralAuditMessage,
    };
    return Tooltip(
      message:
          '$auditMessage${hasDraft ? ' Blue Draft indicator: this branch contains authored Draft content hidden from learner delivery.' : ''}${hasUnpublished ? ' Blue Unpublished indicator: this Course is not currently delivered to learners.' : ''}',
      child: Container(
        key: indicatorKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasDraft || hasUnpublished)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (hasDraft)
                        _DraftBranchIndicator(key: draftIndicatorKey),
                      if (hasUnpublished)
                        _DraftBranchIndicator(
                          key: unpublishedIndicatorKey,
                          label: 'Unpublished',
                          message:
                              'This Course is not currently delivered to learners.',
                        ),
                    ],
                  ),
                ),
              ),
            Card(
              margin: cardMargin,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: auditColor == null
                    ? BorderSide.none
                    : BorderSide(color: auditColor, width: 2.5),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftBranchIndicator extends StatelessWidget {
  const _DraftBranchIndicator({
    super.key,
    this.label = 'Draft',
    this.message = 'At least one authored item in this branch is Draft.',
  });

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
    final foreground = dark ? const Color(0xFF001D35) : Colors.white;
    return Tooltip(
      message: message,
      child: Semantics(
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameAuthoringJson(Object a, Object b) => jsonEncode(a) == jsonEncode(b);

String _localCourseDateTime(BuildContext context, String utc) {
  final parsed = DateTime.tryParse(utc)?.toLocal();
  if (parsed == null) return 'Not recorded';
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatFullDate(parsed)} · '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
}

LearningContent _replaceLearningContentExercise(
  LearningContent source,
  Exercise exercise,
) {
  if (source.kind == 'exercise') {
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      exercise: exercise,
      text: source.text,
      sourceRefs: source.sourceRefs,
    );
  }
  if (source.kind == 'presentation') {
    final converted = Presentation.fromLegacyExercise(exercise);
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      presentation: Presentation(
        content: converted.content,
        actions: source.presentation?.actions ?? converted.actions,
      ),
      text: source.text,
      sourceRefs: source.sourceRefs,
    );
  }
  if (const {
    'explanation',
    'example',
    'vocabulary',
    'text',
    'dialogue',
  }.contains(source.kind)) {
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      text: exercise.prompt.isNotEmpty ? exercise.prompt : exercise.question,
      sourceRefs: source.sourceRefs,
    );
  }
  return LearningContent.fromExercise(exercise);
}

Future<bool> _confirmMoveToDraft(BuildContext context, String entity) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save $entity as draft?'),
        content: Text(
          'This $entity will disappear from learner-facing content. Existing learner progress and XP will be preserved.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save as draft'),
          ),
        ],
      ),
    ) ??
    false;

Exercise _withExercisePublication(
  Exercise source,
  PublicationState state, {
  DateTime? updatedAt,
}) => Exercise.v2(
  id: source.id,
  publicationState: state,
  updatedAt: updatedAt ?? source.updatedAt,
  editorTemplate: source.editorTemplate,
  promptElements: source.promptElements,
  interaction: source.interaction,
  evaluation: source.evaluation,
  hint: source.hint,
  feedback: source.feedback,
  missingWords: source.missingWords,
);

Future<Course?> _openSearchResult(
  BuildContext context, {
  required Course course,
  required ExerciseSearchResult result,
  required bool readOnly,
  required bool initiallyInspecting,
  DateTime Function()? clock,
}) async {
  final lesson = course.lessons[result.lessonIndex];
  final round = lesson.rounds[result.roundIndex];
  final exercise = round.exercises[result.exerciseIndex];
  final saved = <String, Exercise>{};
  final returned = await Navigator.of(context).push<Exercise>(
    MaterialPageRoute(
      builder: (_) => ExerciseEditorScreen(
        exercise: exercise,
        title: 'Edit exercise ${result.exerciseIndex + 1}',
        isNew: false,
        course: course,
        lesson: lesson,
        round: round,
        clock: clock,
        readOnly: readOnly,
        initiallyInspecting: initiallyInspecting,
        onExerciseSaved: readOnly ? null : (value) => saved[value.id] = value,
      ),
    ),
  );
  if (readOnly) return null;
  if (returned != null) saved[returned.id] = returned;
  if (saved.isEmpty) return null;
  final content = [
    for (final item in round.content)
      saved.containsKey(item.id)
          ? _replaceLearningContentExercise(item, saved[item.id]!)
          : item,
  ];
  final changedRound = LearningRound.fromJson({
    ...round.toJson(),
    'content': content.map((item) => item.toJson()).toList(),
  });
  final changedLesson = Lesson.fromJson({
    ...lesson.toJson(),
    'rounds': [
      for (final candidate in lesson.rounds)
        (candidate.id == round.id ? changedRound : candidate).toJson(),
    ],
  });
  return Course.fromJson({
    ...course.toJson(),
    'lessons': [
      for (final candidate in course.lessons)
        (candidate.lessonId == lesson.lessonId ? changedLesson : candidate)
            .toJson(),
    ],
  });
}

/// Custom-course authoring and read-only official-course inspection.
///
/// For custom courses, the hierarchy is editable at every level: Lessons, Rounds and v6
/// Content can be created, deleted and reordered. Friendly Editor template is immutable
/// after creation because changing type can silently reinterpret incompatible
/// fields. To use another type, create a new exercise and delete the old one.
class CourseEditorScreen extends StatelessWidget {
  final Course course;
  final bool userCourse;
  final bool isNewCourse;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final DateTime Function()? clock;
  final CourseAccessCapabilities? access;
  const CourseEditorScreen({
    super.key,
    required this.course,
    this.userCourse = false,
    this.isNewCourse = false,
    this.editorService,
    this.transferService,
    this.clock,
    this.access,
  });
  @override
  Widget build(BuildContext context) {
    final resolvedAccess =
        access ??
        (userCourse && course.originType == CourseOriginType.custom
            ? CourseAccessPolicy.evaluate(
                course,
                profileId: course.maintainer?.profileId,
                memberTeamIds: course.assignedTeamId != null
                    ? {course.assignedTeamId!}
                    : const {},
              )
            : CourseAccessPolicy.evaluate(course, profileId: null));
    return _CustomCourseEditorScreen(
      course: course,
      access: resolvedAccess,
      isNewCourse: isNewCourse,
      editorService: editorService,
      transferService: transferService,
      clock: clock,
    );
  }
}

class _CustomCourseEditorScreen extends StatefulWidget {
  const _CustomCourseEditorScreen({
    required this.course,
    required this.access,
    required this.isNewCourse,
    this.editorService,
    this.transferService,
    this.clock,
  });

  final Course course;
  final CourseAccessCapabilities access;
  final bool isNewCourse;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final DateTime Function()? clock;

  @override
  State<_CustomCourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<_CustomCourseEditorScreen> {
  late final CourseEditorService _service =
      widget.editorService ?? CourseEditorService();
  final _settings = SettingsService();
  final _profiles = ProfileService();
  late final _teams = TeamService(profileService: _profiles);
  final _recordedAudio = RecordedAudioService();
  late final CustomCourseTransferService _transfer =
      widget.transferService ?? CustomCourseTransferService();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  late final CourseAuthoringSession _session;
  bool _routeMayPop = false;

  @override
  void initState() {
    super.initState();
    _session = CourseAuthoringSession(
      course: widget.course,
      access: widget.access,
      editorService: _service,
      isNewCourse: widget.isNewCourse,
      clock: _clock,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var mode = await _settings.getCourseEditorMode(_course.courseId);
      if (!widget.access.canEditOriginal && mode == CourseEditorMode.edit) {
        mode = CourseEditorMode.viewOnly;
      }
      if (mounted) setState(() => _session.setEditorMode(mode));
      if (widget.access.canEditOriginal &&
          mode == CourseEditorMode.edit &&
          await _settings.isAudioOrphanCheckDue(_code)) {
        await _checkOrphanAudio();
        await _settings.markAudioOrphanCheckRun(_code);
      }
    });
  }

  String get _code => CourseService.codeForCourse(_course);

  Course get _course => _session.workingCourse;

  bool get _dirty => _session.hasChanges;

  bool get _canModify => _session.canModify;

  CourseEditorMode get _editorMode => _session.editorMode;

  CourseAuditResult? get _lastAudit => _session.lastAudit;

  bool get _auditOutdated => _session.auditOutdated;

  String get _pendingVersionNotes => _session.pendingVersionNotes;

  void _updateDraft(Course value) => setState(() {
    _session.stageCourse(value);
  });

  Future<void> _popEditor([CourseConfirmationResult? result]) async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _attemptLeave() async {
    if (!_dirty) {
      await _popEditor();
      return;
    }
    var versionNotes = _pendingVersionNotes;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('course-transaction-confirmation'),
        title: const Text('Unapplied course changes'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The complete Course Editor working copy differs from the persisted course. Confirm all changes as one new course version, or cancel the complete editing session.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('course-version-notes'),
                  initialValue: versionNotes,
                  onChanged: (value) => versionNotes = value,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Version notes (optional)',
                    helperText:
                        'Describe the changes made in this course version.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel-course-changes'),
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel course changes'),
          ),
          FilledButton(
            key: const Key('confirm-course-changes'),
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text('Confirm course changes'),
          ),
        ],
      ),
    );
    if (choice == 'cancel') {
      _session.cancel();
      await _popEditor();
      return;
    }
    if (choice != 'confirm') return;
    try {
      final result = await _session.confirm(
        languageCode: _code,
        versionNotes: versionNotes,
      );
      if (!mounted) return;
      await _popEditor(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'Course changes were not confirmed. The original course is unchanged and the working copy is still open. $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Course _withLessons(List<Lesson> lessons) => Course.fromJson({
    ..._course.toJson(),
    'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
  });

  Future<void> _editCourseInfo() async {
    final resolvedGovernance = await CourseGovernanceResolver(
      profileService: _profiles,
      teamService: _teams,
    ).resolve(_course);
    final profiles = await _profiles.getProfileRecords();
    final teams = await _teams.listTeams();
    final activeProfileId = await _profiles.getActiveProfileId();
    final canGovern =
        _editorMode == CourseEditorMode.edit &&
        widget.access.canTransferMaintainership &&
        activeProfileId == _course.maintainer?.profileId;
    var selectedMaintainerId = _course.maintainer!.profileId;
    var selectedAssignedTeamId = _course.assignedTeamId;
    final assignedTeamFieldKey = GlobalKey<FormFieldState<String?>>();
    if (!mounted) return;
    const standardRoles = CourseMetadataOptions.standardRoles;
    const roleDescriptions = CourseMetadataOptions.roleDescriptions;
    final initialAuthors = _course.authors;
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
    final rightsHolderNames = [
      for (final holder in _course.rightsHolders)
        TextEditingController(text: holder.name),
    ];
    final rightsHolderTypes = [
      for (final holder in _course.rightsHolders) holder.type,
    ];
    if (rightsHolderNames.isEmpty) {
      rightsHolderNames.add(TextEditingController());
      rightsHolderTypes.add(CourseRightsHolderType.person);
    }
    // Media credits: one controller set per entry. Blank rows are dropped on
    // Save, so an empty starting row costs the author nothing.
    final mediaAuthors = [
      for (final credit in _course.mediaAttributions)
        TextEditingController(text: credit.author),
    ];
    final mediaLicenses = [
      for (final credit in _course.mediaAttributions)
        TextEditingController(text: credit.license),
    ];
    final mediaTitles = [
      for (final credit in _course.mediaAttributions)
        TextEditingController(text: credit.title),
    ];
    final mediaSources = [
      for (final credit in _course.mediaAttributions)
        TextEditingController(text: credit.source),
    ];
    final mediaAppliesTo = [
      for (final credit in _course.mediaAttributions)
        TextEditingController(text: credit.appliesTo),
    ];
    void addMediaCreditRow() {
      mediaAuthors.add(TextEditingController());
      mediaLicenses.add(TextEditingController());
      mediaTitles.add(TextEditingController());
      mediaSources.add(TextEditingController());
      mediaAppliesTo.add(TextEditingController());
    }

    if (mediaAuthors.isEmpty) addMediaCreditRow();
    final courseTitle = TextEditingController(text: _course.title);
    final variant = TextEditingController(text: _course.languageVariant);
    final startLevel = TextEditingController(text: _course.startLevel);
    final targetLevel = TextEditingController(text: _course.targetLevel);
    final description = TextEditingController(text: _course.courseDescription);
    final buyACoffeeUrl = TextEditingController(text: _course.buyACoffeeUrl);
    final estimatedHours = TextEditingController(
      text: _course.estimatedStudyHours?.toString() ?? '',
    );
    var minimumAge = _course.minimumAge;
    final keywords = TextEditingController(text: _course.keywords.join(', '));
    final contactWebsite = TextEditingController(
      text: _course.publisherContact?.websiteUrl ?? '',
    );
    final contactEmail = TextEditingController(
      text: _course.publisherContact?.email ?? '',
    );
    final minimumAppBuild = TextEditingController(
      text: _course.minimumAppBuild?.toString() ?? '',
    );
    final customLicense = TextEditingController(text: _course.license);
    const standardLicenses = CourseMetadataOptions.standardLicenses;
    var selected = standardLicenses.contains(_course.license)
        ? _course.license
        : 'Other / Custom license';
    var derivativePolicy = _course.derivativeWorksPolicy;
    String? mediaCreditError;
    var flagSelection = CourseFlagSelection.fromCourse(_course);
    final learningLanguage = CourseLanguageResolver.learning(_course);
    final baseLanguage = CourseLanguageResolver.base(_course);
    final narrowCourseInfo = MediaQuery.sizeOf(context).width < 560;
    Widget readOnlyField(
      String label,
      String value, {
      String helperText = 'Read-only',
    }) => InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        helper: Text(helperText),
      ),
      child: Text(value.trim().isEmpty ? 'Not specified' : value),
    );
    final result = await showDialog<CourseInfoChange>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setLocalState) => AlertDialog(
              title: const Text('Course Info Editor'),
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
                        key: const Key('course-info-title'),
                        controller: courseTitle,
                        maxLength: 120,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Course name',
                          helper: Text('Renaming keeps the same Course ID.'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            EditorDisplayPreferences.showInternalIds,
                        builder: (context, showInternalIds, _) =>
                            showInternalIds
                            ? Column(
                                children: [
                                  readOnlyField('Course ID', _course.courseId),
                                  const SizedBox(height: 8),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      readOnlyField('Course origin', _course.originType.name),
                      const SizedBox(height: 8),
                      readOnlyField(
                        'Original Course Creator',
                        resolvedGovernance.originalCreatorLabel,
                        helperText:
                            'The person who originally created this Course. This does not change when maintainership changes or the Course is forked.',
                      ),
                      EditorInternalIdText(
                        label: 'User',
                        id: _course.originalCourseCreator.id,
                        padding: const EdgeInsets.only(top: 6),
                      ),
                      const SizedBox(height: 8),
                      if (canGovern)
                        DropdownButtonFormField<String>(
                          key: const Key('course-info-owner'),
                          initialValue: selectedMaintainerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Course Maintainer',
                            helper: Text(
                              'The person currently responsible for maintaining this Course.',
                            ),
                          ),
                          items: [
                            for (final profile in profiles)
                              DropdownMenuItem(
                                value: profile.learnerProfileId,
                                child: Tooltip(
                                  message: profile.presentationName,
                                  child: Text(
                                    profile.presentationName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (value) => setLocalState(
                            () => selectedMaintainerId =
                                value ?? selectedMaintainerId,
                          ),
                        )
                      else
                        readOnlyField(
                          'Course Maintainer',
                          resolvedGovernance.maintainerLabel,
                          helperText: _editorMode == CourseEditorMode.edit
                              ? 'Only the current Course Maintainer may change this field.'
                              : 'Read-only outside Edit mode',
                        ),
                      EditorInternalIdText(
                        label: 'User',
                        id: selectedMaintainerId,
                        padding: const EdgeInsets.only(top: 6),
                      ),
                      const SizedBox(height: 8),
                      if (canGovern)
                        KeyedSubtree(
                          key: const Key('course-info-assigned-team'),
                          child: DropdownButtonFormField<String?>(
                            key: assignedTeamFieldKey,
                            initialValue: selectedAssignedTeamId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Assigned Team',
                              helper: Text(
                                'Grants Team management access; the Course Maintainer and Original Course Creator stay unchanged.',
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No assigned Team'),
                              ),
                              for (final team in teams)
                                DropdownMenuItem<String?>(
                                  value: team.teamId,
                                  child: Tooltip(
                                    message: team.displayName,
                                    child: Text(
                                      team.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (value) async {
                              if (value == selectedAssignedTeamId) return;
                              if (value != null) {
                                final confirmed =
                                    await showDialog<bool>(
                                      context: ctx,
                                      builder: (warningContext) => AlertDialog(
                                        key: const Key(
                                          'team-assignment-warning',
                                        ),
                                        title: const Text(
                                          'Assign Course to Team?',
                                        ),
                                        content: const Text(
                                          CourseGovernanceService
                                              .teamAssignmentWarning,
                                        ),
                                        actions: [
                                          TextButton(
                                            key: const Key(
                                              'team-assignment-cancel',
                                            ),
                                            onPressed: () => Navigator.pop(
                                              warningContext,
                                              false,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            key: const Key(
                                              'team-assignment-confirm',
                                            ),
                                            onPressed: () => Navigator.pop(
                                              warningContext,
                                              true,
                                            ),
                                            child: const Text(
                                              'Confirm assignment',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!confirmed) {
                                  assignedTeamFieldKey.currentState?.didChange(
                                    selectedAssignedTeamId,
                                  );
                                  return;
                                }
                              }
                              setLocalState(
                                () => selectedAssignedTeamId = value,
                              );
                            },
                          ),
                        )
                      else ...[
                        readOnlyField(
                          'Assigned Team',
                          resolvedGovernance.assignedTeamLabel ?? 'None',
                          helperText:
                              'Only the current Course Maintainer may assign or revoke a Team.',
                        ),
                      ],
                      if (selectedAssignedTeamId != null)
                        EditorInternalIdText(
                          label: 'Team',
                          id: selectedAssignedTeamId!,
                          padding: const EdgeInsets.only(top: 6),
                        ),
                      ValueListenableBuilder<bool>(
                        valueListenable:
                            EditorDisplayPreferences.showInternalIds,
                        builder: (context, showInternalIds, _) =>
                            showInternalIds
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SelectableText(
                                  'Course Model: v${_course.formatVersion}',
                                  key: const Key('course-info-model-version'),
                                  maxLines: 1,
                                  style: Theme.of(ctx).textTheme.bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (_course.forkProvenance != null)
                        CourseForkProvenanceCard(
                          provenance: _course.forkProvenance!,
                        ),
                      ...[
                        const SizedBox(height: 8),
                        readOnlyField(
                          'Original Course Created',
                          _localCourseDateTime(
                            ctx,
                            _course.originalCreatedAtUtc,
                          ),
                        ),
                        const SizedBox(height: 8),
                        readOnlyField(
                          'Last Version Editor',
                          _course.lastVersionEditorDisplayName,
                        ),
                        const SizedBox(height: 8),
                        readOnlyField(
                          'Modified',
                          _localCourseDateTime(ctx, _course.modifiedAtUtc),
                        ),
                        if (_course.versionNotes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          readOnlyField('Version notes', _course.versionNotes),
                        ],
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openVersionHistory();
                          },
                          icon: const Icon(Icons.history_outlined),
                          label: const Text('Version history'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Languages',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (narrowCourseInfo) ...[
                        readOnlyField(
                          'Base language',
                          baseLanguage.displayLabel,
                        ),
                        const SizedBox(height: 8),
                        readOnlyField(
                          'Learning language',
                          learningLanguage.displayLabel,
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: readOnlyField(
                                'Base language',
                                baseLanguage.displayLabel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: readOnlyField(
                                'Learning language',
                                learningLanguage.displayLabel,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'Course flag',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CourseFlagSelector(
                        key: const Key('course-info-flag-selector'),
                        selection: flagSelection,
                        languageName: learningLanguage.displayLabel,
                        languageTag: learningLanguage.code,
                        onChanged: (selection) =>
                            setLocalState(() => flagSelection = selection),
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
                                        Tooltip(
                                          message: role == 'Team Leader'
                                              ? 'This is descriptive information only. To assign or change Team Leader roles in QQL, use Team Manager.'
                                              : roleDescriptions[role] ?? role,
                                          child: FilterChip(
                                            label: Text(role),
                                            selected: selectedRoles[i].contains(
                                              role,
                                            ),
                                            onSelected: (on) => setLocalState(
                                              () {
                                                if (on) {
                                                  selectedRoles[i].add(role);
                                                } else {
                                                  selectedRoles[i].remove(role);
                                                }
                                              },
                                            ),
                                          ),
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
                                      helper: Text(
                                        'Optional; separate roles with commas.',
                                      ),
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
                      readOnlyField(
                        'Course version',
                        _course.courseVersion.isEmpty
                            ? 'Not confirmed yet'
                            : _course.courseVersion,
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
                          helper: Text('HTTPS only; shown in Course Info.'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('course-info-estimated-hours'),
                              controller: estimatedHours,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Estimated study hours (optional)',
                                helper: Text('Whole number, 1–1000.'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              key: const Key('course-info-minimum-age'),
                              initialValue: minimumAge,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Minimum age',
                                helper: Text('App Store age classes.'),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Not specified'),
                                ),
                                for (final age in Course.minimumAgeClasses)
                                  DropdownMenuItem<int?>(
                                    value: age,
                                    child: Text('$age+'),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setLocalState(() => minimumAge = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('course-info-keywords'),
                        controller: keywords,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Keywords (optional)',
                          helper: Text(
                            'Separate with commas. Up to 20 keywords of up to 32 characters each.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('course-info-contact-website'),
                        controller: contactWebsite,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Publisher website (optional)',
                          helper: Text(
                            'HTTPS only; shown as plain text in Course Info.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('course-info-contact-email'),
                        controller: contactEmail,
                        maxLength: 254,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Publisher email (optional)',
                          helper: Text('Shown as plain text in Course Info.'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('course-info-minimum-app-build'),
                        controller: minimumAppBuild,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Minimum QuisquisLingo build (optional)',
                          helper: Text(
                            'Older builds refuse this Course. Leave empty unless it needs a recent feature. This is build ${Course.appBuildNumber}.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'License / Rights',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
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
                        onChanged: (v) => setLocalState(() {
                          selected = v ?? selected;
                          final inferred =
                              CourseMetadataOptions.derivativePolicyForLicense(
                                selected,
                              );
                          if (inferred != DerivativeWorksPolicy.unspecified) {
                            derivativePolicy = inferred;
                          }
                        }),
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
                        const SizedBox(height: 8),
                        DropdownButtonFormField<DerivativeWorksPolicy>(
                          initialValue: derivativePolicy,
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
                          onChanged: (value) => setLocalState(
                            () => derivativePolicy = value ?? derivativePolicy,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Rights Holder records rights ownership information. It does not control QQL permissions.',
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
                                          : () => setLocalState(() {
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
                                    'course-info-rights-holder-type-$rightsIndex',
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
                                      value:
                                          CourseRightsHolderType.organization,
                                      child: Text('Organization'),
                                    ),
                                  ],
                                  onChanged: (value) => setLocalState(() {
                                    rightsHolderTypes[rightsIndex] =
                                        value ?? rightsHolderTypes[rightsIndex];
                                  }),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  key: ValueKey(
                                    'course-info-rights-holder-name-$rightsIndex',
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
                          key: const Key('course-info-add-rights-holder'),
                          onPressed: () => setLocalState(() {
                            rightsHolderNames.add(TextEditingController());
                            rightsHolderTypes.add(
                              CourseRightsHolderType.person,
                            );
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Rights Holder'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Media credits',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Credit images and recordings made by someone else: an imported picture, a recording another person performed, a custom Lesson icon or course flag. Media that came with QuisquisLingo is already credited in App Info and needs no entry here. These credits travel inside the Course file even when the media files themselves do not. They are descriptive only and do not control QQL permissions.',
                      ),
                      const SizedBox(height: 8),
                      for (
                        var creditIndex = 0;
                        creditIndex < mediaAuthors.length;
                        creditIndex++
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
                                        'Media credit ${creditIndex + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove media credit',
                                      onPressed: mediaAuthors.length == 1
                                          ? null
                                          : () => setLocalState(() {
                                              mediaAuthors
                                                  .removeAt(creditIndex)
                                                  .dispose();
                                              mediaLicenses
                                                  .removeAt(creditIndex)
                                                  .dispose();
                                              mediaTitles
                                                  .removeAt(creditIndex)
                                                  .dispose();
                                              mediaSources
                                                  .removeAt(creditIndex)
                                                  .dispose();
                                              mediaAppliesTo
                                                  .removeAt(creditIndex)
                                                  .dispose();
                                              mediaCreditError = null;
                                            }),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  key: ValueKey(
                                    'course-info-media-author-$creditIndex',
                                  ),
                                  controller: mediaAuthors[creditIndex],
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Author',
                                    helper: Text('Who must be credited.'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  key: ValueKey(
                                    'course-info-media-license-$creditIndex',
                                  ),
                                  controller: mediaLicenses[creditIndex],
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Licence',
                                    helper: Text(
                                      'As the creator states it, for example CC BY-SA 4.0.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  key: ValueKey(
                                    'course-info-media-title-$creditIndex',
                                  ),
                                  controller: mediaTitles[creditIndex],
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Title (optional)',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  key: ValueKey(
                                    'course-info-media-source-$creditIndex',
                                  ),
                                  controller: mediaSources[creditIndex],
                                  maxLength: 500,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Source (optional)',
                                    helper: Text(
                                      'A page reference or address. Shown as plain text, never opened.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  key: ValueKey(
                                    'course-info-media-applies-to-$creditIndex',
                                  ),
                                  controller: mediaAppliesTo[creditIndex],
                                  maxLength: 200,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Applies to (optional)',
                                    helper: Text(
                                      'Which media in this course it covers.',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (mediaCreditError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Text(
                            mediaCreditError!,
                            key: const Key('course-info-media-credit-error'),
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('course-info-add-media-credit'),
                          onPressed: () =>
                              setLocalState(() => addMediaCreditRow()),
                          icon: const Icon(Icons.add),
                          label: const Text('Add media credit'),
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
                  key: const Key('course-info-save'),
                  onPressed: () async {
                    String title;
                    try {
                      title = FormalNamePolicy.validatePresentationLabel(
                        courseTitle.text,
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
                    final duplicate = (await _service.listUserCourses()).any(
                      (course) =>
                          course.courseId != _course.courseId &&
                          FormalNamePolicy.comparisonKey(course.title) ==
                              FormalNamePolicy.comparisonKey(title),
                    );
                    if (duplicate) {
                      if (!ctx.mounted) return;
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
                    final license = selected == 'Other / Custom license'
                        ? customLicense.text.trim()
                        : selected;
                    if (license.isEmpty) return;
                    String normalizedBuyACoffeeUrl;
                    int? parsedHours;
                    int? parsedMinimumBuild;
                    List<String> parsedKeywords;
                    CoursePublisherContact? parsedContact;
                    try {
                      normalizedBuyACoffeeUrl = Course.normalizeBuyACoffeeUrl(
                        buyACoffeeUrl.text,
                      );
                      int? wholeNumber(String text, String label) {
                        final value = text.trim();
                        if (value.isEmpty) return null;
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          throw FormatException(
                            '$label must be a whole number.',
                          );
                        }
                        return parsed;
                      }

                      parsedHours = wholeNumber(
                        estimatedHours.text,
                        'Estimated study hours',
                      );
                      parsedMinimumBuild = wholeNumber(
                        minimumAppBuild.text,
                        'Minimum QuisquisLingo build',
                      );
                      parsedKeywords = Course.normalizeKeywords(
                        keywords.text.split(','),
                      );
                      parsedContact = CoursePublisherContact.fromFields(
                        contactWebsite.text,
                        contactEmail.text,
                      );
                      // The model is the one authority on the limits.
                      Course.validateDescriptiveMetadata(
                        minimumAppBuild: parsedMinimumBuild,
                        estimatedStudyHours: parsedHours,
                        minimumAge: minimumAge,
                        keywords: parsedKeywords,
                      );
                    } on FormatException catch (error) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                      return;
                    }
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
                    final rightsHolders = <CourseRightsHolder>[];
                    for (var i = 0; i < rightsHolderNames.length; i++) {
                      final name = rightsHolderNames[i].text.trim();
                      if (name.isEmpty) continue;
                      rightsHolders.add(
                        CourseRightsHolder(
                          type: rightsHolderTypes[i],
                          name: name,
                        ),
                      );
                    }
                    final mediaAttributions = <CourseMediaAttribution>[];
                    for (var i = 0; i < mediaAuthors.length; i++) {
                      final author = mediaAuthors[i].text.trim();
                      final license = mediaLicenses[i].text.trim();
                      // Both identifying fields are required; a row with
                      // neither is an untouched blank and is simply dropped.
                      if (author.isEmpty && license.isEmpty) continue;
                      if (author.isEmpty || license.isEmpty) {
                        setLocalState(
                          () => mediaCreditError =
                              'Each media credit needs both an author and a licence. '
                              'Complete row ${i + 1} or clear it.',
                        );
                        return;
                      }
                      final candidate = CourseMediaAttribution(
                        author: author,
                        license: license,
                        title: mediaTitles[i].text.trim(),
                        source: mediaSources[i].text.trim(),
                        appliesTo: mediaAppliesTo[i].text.trim(),
                      );
                      if (mediaAttributions.contains(candidate)) {
                        setLocalState(
                          () => mediaCreditError =
                              'Row ${i + 1} repeats an identical media credit.',
                        );
                        return;
                      }
                      mediaAttributions.add(candidate);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx, (
                      title: title,
                      authors: aa,
                      rightsHolders: rightsHolders,
                      mediaAttributions: mediaAttributions,
                      license: license,
                      derivativePolicy: selected == 'Other / Custom license'
                          ? derivativePolicy
                          : license == _course.license
                          ? _course.derivativeWorksPolicy
                          : CourseMetadataOptions.derivativePolicyForLicense(
                              selected,
                            ),
                      variant: variant.text.trim(),
                      startLevel: startLevel.text.trim(),
                      targetLevel: targetLevel.text.trim(),
                      description: description.text.trim(),
                      buyACoffeeUrl: normalizedBuyACoffeeUrl,
                      estimatedStudyHours: parsedHours,
                      minimumAge: minimumAge,
                      keywords: parsedKeywords,
                      publisherContact: parsedContact,
                      minimumAppBuild: parsedMinimumBuild,
                      flagCode: flagSelection.flagCode,
                      flagImageBase64: flagSelection.flagImageBase64,
                      worldFlagId: flagSelection.selectedWorldFlagId,
                      maintainerProfileId: selectedMaintainerId,
                      assignedTeamId: selectedAssignedTeamId,
                    ));
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      for (final c in names) {
        c.dispose();
      }
      for (final c in customRoles) {
        c.dispose();
      }
      for (final c in rightsHolderNames) {
        c.dispose();
      }
      for (final list in [
        mediaAuthors,
        mediaLicenses,
        mediaTitles,
        mediaSources,
        mediaAppliesTo,
      ]) {
        for (final c in list) {
          c.dispose();
        }
      }
      courseTitle.dispose();
      variant.dispose();
      startLevel.dispose();
      targetLevel.dispose();
      description.dispose();
      buyACoffeeUrl.dispose();
      estimatedHours.dispose();
      keywords.dispose();
      contactWebsite.dispose();
      contactEmail.dispose();
      minimumAppBuild.dispose();
      customLicense.dispose();
    });
    if (result == null || !mounted) return;
    final update = await CourseInfoUpdateService(
      governanceService: CourseGovernanceService(
        profileService: _profiles,
        teamService: _teams,
      ),
    ).apply(_course, result, activeProfileId!);
    setState(() {
      _session.stageCourse(
        update.course,
        governanceChanged: update.governanceChanged,
      );
    });
  }

  Future<void> _openLessons() async {
    if (_editorMode == CourseEditorMode.locked) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Course Editor is locked'),
          content: const Text(
            'The Course Editor root remains available, but the Lessons and authoring structure cannot be opened while the access state is Locked. Choose View only, Inspection mode or, when authorized, Edit.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final readOnly = !_canModify;
    final activeProfileId = await _profiles.getActiveProfileId();
    if (_editorMode == CourseEditorMode.viewOnly &&
        activeProfileId != null &&
        !await _settings.hasSeenCourseEditorViewNotice(_course.courseId)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('course-editor-view-mode-notice'),
          title: const Text('View only'),
          content: Text(
            widget.access.canEditOriginal
                ? 'You are viewing this course in read-only mode. To make changes, return to the Course Editor and switch the access state to Edit.'
                : 'You are viewing this course in read-only mode. You do not have permission to edit this course.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      await _settings.markCourseEditorViewNoticeSeen(_course.courseId);
      if (!mounted) return;
    }
    if (!mounted) return;
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => LessonManagementScreen(
          course: _course,
          initiallyLocked: false,
          readOnly: readOnly,
          courseEditorMode: _editorMode,
          onCourseChanged: _canModify ? _updateDraft : null,
          clock: _clock,
        ),
      ),
    );
    if (updated != null && _canModify) _updateDraft(updated);
    if (mounted) setState(_session.markAuditOutdated);
  }

  Future<void> _setEditorMode(CourseEditorMode mode) async {
    if (mode == CourseEditorMode.edit && !widget.access.canEditOriginal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.access.effectiveEditDeniedReason)),
      );
      return;
    }
    if (_editorMode == CourseEditorMode.edit &&
        mode != CourseEditorMode.edit &&
        !await _resolveChangesBeforeModeSwitch()) {
      return;
    }
    await _settings.setCourseEditorMode(_course.courseId, mode);
    if (mounted) setState(() => _session.setEditorMode(mode));
  }

  Future<bool> _resolveChangesBeforeModeSwitch() async {
    if (!_dirty) return true;
    var versionNotes = _pendingVersionNotes;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('course-transaction-confirmation'),
        title: const Text('Unapplied course changes'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The complete Course Editor working copy differs from the persisted course. Confirm all changes as one new course version, cancel the complete editing session, or keep the editor in Edit.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('course-version-notes'),
                  initialValue: versionNotes,
                  onChanged: (value) => versionNotes = value,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Version notes (optional)',
                    helperText:
                        'Describe the changes made in this course version.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            key: const Key('cancel-course-changes'),
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel course changes'),
          ),
          TextButton(
            key: const Key('confirm-course-changes'),
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text('Confirm course changes'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == 'stay') return false;
    if (choice == 'cancel') {
      setState(_session.cancel);
      return true;
    }
    try {
      await _session.confirm(
        languageCode: _code,
        versionNotes: versionNotes,
      );
      if (!mounted) return false;
      setState(() {});
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'Course changes were not confirmed. The working copy remains open in Edit. $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return false;
    }
  }

  Future<void> _toggleCourseDraftStatus() async {
    final state = _course.publicationState.isPublished
        ? PublicationState.draft
        : PublicationState.published;
    if (!state.isPublished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Course to Not published?'),
          content: const Text(
            'After final confirmation this Course will be excluded from learner delivery. Its content and individual authoring Draft states are preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Not published'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final candidate = Course.fromJson({
      ..._course.toJson(),
      'publicationState': state.name,
    });
    if (state.isPublished) {
      final visible = const PublicationService().learnerCourse(candidate)!;
      final errors = CourseAuditService()
          .auditCourse(visible, sourceReferenceCourse: candidate)
          .issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .length;
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course cannot be saved as learner-visible content: $errors blocking error${errors == 1 ? '' : 's'}.',
            ),
          ),
        );
        return;
      }
    }
    _updateDraft(candidate);
  }

  Future<void> _openAudioLibrary() async {
    final updated = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (_) => AudioLibraryScreen(course: _course)),
    );
    if (updated != null && mounted) _updateDraft(updated);
  }

  Future<void> _openVersionHistory() async {
    final selection = await Navigator.of(context).push<CourseHistorySelection>(
      MaterialPageRoute(
        builder: (_) => CourseVersionHistoryScreen(
          course: _course,
          backupService: _service.backupService,
          allowRestore: _canModify,
        ),
      ),
    );
    if (selection == null || !mounted) return;
    if (_dirty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace working-copy changes?'),
          content: const Text(
            'Loading this historical version will replace the unapplied changes currently in the working copy. The persisted course remains unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep current working copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Load historical version'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    if (!mounted) return;
    try {
      setState(() {
        _session.loadHistoricalCourse(selection.course);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Historical version ${selection.course.courseVersion} loaded into the working copy. Confirm course changes to apply it as a new version.',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
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
          'These recordings are not associated with any word, expression or exercise. Remove their references from the working copy? The files remain on disk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove references'),
          ),
        ],
      ),
    );
    if (remove == true) {
      final ids = orphans.map((e) => e.id).toSet();
      _updateDraft(
        Course.fromJson({
          ..._course.toJson(),
          'audioLibrary': _course.audioLibrary
              .where((clip) => !ids.contains(clip.id))
              .map((clip) => clip.toJson())
              .toList(),
        }),
      );
    }
  }

  Future<void> _runAudit() async {
    try {
      await CourseFlagService().validateWorldFlag(_course);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    await _checkOrphanAudio(prompt: _canModify);
    final fresh = _course;
    final result = _session.runAudit();
    if (!mounted) return;
    setState(() {});
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
        final savedExercises = <String, Exercise>{};
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
                  course: _course,
                  lesson: lesson,
                  round: round,
                  readOnly: !_canModify,
                  initiallyInspecting:
                      _editorMode == CourseEditorMode.inspection,
                  onExerciseSaved: !_canModify
                      ? null
                      : (exercise) {
                          savedExercises[exercise.id] = exercise;
                          if (!mounted) return;
                          _updateDraft(
                            _withLessons([
                              for (final currentLesson in _course.lessons)
                                if (currentLesson.lessonId == lesson.lessonId)
                                  Lesson.fromJson({
                                    ...currentLesson.toJson(),
                                    'rounds': [
                                      for (final currentRound
                                          in currentLesson.rounds)
                                        if (currentRound.id == round.id)
                                          {
                                            ...currentRound.toJson(),
                                            'content': [
                                              for (final item
                                                  in currentRound.content)
                                                (item.id == exercise.id
                                                        ? _replaceLearningContentExercise(
                                                            item,
                                                            exercise,
                                                          )
                                                        : item)
                                                    .toJson(),
                                            ],
                                          }
                                        else
                                          currentRound.toJson(),
                                    ],
                                  })
                                else
                                  currentLesson,
                            ]),
                          );
                        },
                ),
              ),
            );
            if (updatedExercise != null) {
              savedExercises[updatedExercise.id] = updatedExercise;
            }
            if (savedExercises.isNotEmpty) {
              final content = [
                for (final item in round.content)
                  savedExercises.containsKey(item.id)
                      ? _replaceLearningContentExercise(
                          item,
                          savedExercises[item.id]!,
                        )
                      : item,
              ];
              updatedRound = LearningRound(
                id: round.id,
                publicationState: round.publicationState,
                provisionalDraft: round.provisionalDraft,
                updatedAt: round.updatedAt,
                title: round.title,
                visualType: round.visualType,
                content: content,
              );
            }
          }
        }
        if (!mounted) return;
        if (issue.exerciseId != null && updatedRound == null) return;
        updatedRound ??= await Navigator.of(context).push<LearningRound>(
          MaterialPageRoute(
            builder: (_) => RoundEditorScreen(
              course: _course,
              onCourseChanged: _canModify ? _updateDraft : null,
              lesson: lesson,
              round: round,
              roundIndex: ri,
              readOnly: !_canModify,
              courseEditorMode: _editorMode,
            ),
          ),
        );
        if (updatedRound == null || !mounted) return;
        final rounds = [..._course.lessons[ti].rounds];
        rounds[ri] = updatedRound;
        final lessons = [..._course.lessons];
        lessons[ti] = Lesson(
          lessonId: lesson.lessonId,
          publicationState: lesson.publicationState,
          provisionalDraft: lesson.provisionalDraft,
          updatedAt: lesson.updatedAt,
          title: lesson.title,
          rounds: rounds,
          section: lesson.section,
          sectionName: lesson.sectionName,
          themeIconAsset: lesson.themeIconAsset,
          guidebook: lesson.guidebook,
          duel: lesson.duel,
        );
        _updateDraft(_withLessons(lessons));
        return;
      }
    }
  }

  Future<void> _exportCustomCourse() async {
    try {
      final notice = CourseAuditService().auditCourse(_course).exportNotice;
      final path = await _transfer.exportCourse(_course);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 12),
          content: Text(
            'Exported “${_course.title}” to $path'
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

  Future<void> _saveCustomCourseTo() async {
    try {
      final notice = CourseAuditService().auditCourse(_course).exportNotice;
      final result = await _transfer.exportCourseTo(_course);
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        result,
        saving: true,
        savedMessage:
            'Saved “${_course.title}” as ${result.displayName}.'
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

  Future<void> _copyAsNewCourse() async {
    final existingTitles = (await _service.listUserCourses())
        .map((course) => course.title)
        .toSet();
    var title = '${_course.title} copy';
    var suffix = 2;
    while (existingTitles.contains(title)) {
      title = '${_course.title} copy ${suffix++}';
    }
    final created = await _service.createCopyAsNewCourse(
      source: _course,
      title: title,
    );
    final createdAccess = await _service.capabilitiesFor(created.course);
    if (!mounted) return;
    final result = await Navigator.of(context).push<CourseConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorScreen(
          course: created.course,
          access: createdAccess,
          editorService: _service,
          clock: _clock,
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New independent Course created: ${created.course.title}\n'
            'Course version: ${created.course.courseVersion}',
          ),
        ),
      );
    }
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course changes confirmed: ${result.course.title}'),
        ),
      );
    }
  }

  Future<void> _forkCourse() async {
    try {
      final created = await _service.createFork(source: _course);
      final createdAccess = await _service.capabilitiesFor(created.course);
      if (!mounted) return;
      await Navigator.of(context).push<CourseConfirmationResult>(
        MaterialPageRoute(
          builder: (_) => CourseEditorScreen(
            course: created.course,
            access: createdAccess,
            editorService: _service,
            clock: _clock,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('StateError: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(_course);
    final canExportCourse =
        widget.access.hasOperationalAccess &&
        _course.originType == CourseOriginType.custom;
    return PopScope(
      canPop: _routeMayPop || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _attemptLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          title: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                if (constraints.maxWidth >= 58) ...[
                  CourseFlagBadge(
                    course: _course,
                    fallbackCode: _code,
                    width: 38,
                    height: 27,
                  ),
                  const SizedBox(width: 10),
                ],
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            PopupMenuButton<CourseEditorMode>(
              key: const Key('course-editor-lock'),
              tooltip: 'Course Editor access: ${_editorMode.label}',
              initialValue: _editorMode,
              onSelected: _setEditorMode,
              icon: Icon(switch (_editorMode) {
                CourseEditorMode.locked => Icons.lock_outline,
                CourseEditorMode.viewOnly => Icons.visibility_outlined,
                CourseEditorMode.inspection => Icons.code,
                CourseEditorMode.edit => Icons.edit_outlined,
              }),
              itemBuilder: (context) => [
                for (final mode in CourseEditorMode.values)
                  PopupMenuItem<CourseEditorMode>(
                    value: mode,
                    enabled:
                        mode != CourseEditorMode.edit ||
                        widget.access.canEditOriginal,
                    child: Tooltip(
                      message:
                          mode == CourseEditorMode.edit &&
                              !widget.access.canEditOriginal
                          ? widget.access.effectiveEditDeniedReason
                          : switch (mode) {
                              CourseEditorMode.locked =>
                                'Keep the Course Editor root visible and block the authoring structure.',
                              CourseEditorMode.viewOnly =>
                                'Use the normal exercise form read-only while keeping Search, Preview and Audit available.',
                              CourseEditorMode.inspection =>
                                'Open exercises in their read-only technical representation by default.',
                              CourseEditorMode.edit =>
                                'Allow authoring actions under the existing Course Maintainer and assigned-Team permissions.',
                            },
                      child: Row(
                        children: [
                          Icon(switch (mode) {
                            CourseEditorMode.locked => Icons.lock_outline,
                            CourseEditorMode.viewOnly =>
                              Icons.visibility_outlined,
                            CourseEditorMode.inspection => Icons.code,
                            CourseEditorMode.edit => Icons.edit_outlined,
                          }),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mode.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mode == _editorMode) ...[const Icon(Icons.check)],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const EditorAppBarActions(),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (widget.access.readOnly)
              ListTile(
                key: const Key('course-editor-read-only-notice'),
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Read-only course'),
                subtitle: Text(
                  _course.originType.isOfficial
                      ? 'Bundled and official originals are immutable.'
                      : 'Only the Course Maintainer or members of the assigned Team can edit this Course.',
                ),
              ),
            AuthoringStatusCard(
              indicatorKey: const Key('course-lessons-status-indicator'),
              draftIndicatorKey: const Key('course-lessons-draft-indicator'),
              hasDraft: hierarchyStatus.courseHasDraft,
              hasAuditConcern: hierarchyStatus.hasLessonsAuditConcern,
              cardMargin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('course-editor-lessons-navigation'),
                leading: const Icon(Icons.school_outlined),
                title: const Text('Lessons', style: _hierarchyLinkStyle),
                subtitle: Text('${_course.lessons.length} Lessons'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openLessons,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('course-editor-course-info'),
              leading: Icon(
                _canModify ? Icons.edit_note_outlined : Icons.info_outline,
              ),
              title: Text(_canModify ? 'Course Info Editor' : 'Course Info'),
              subtitle: Text(
                '${_canModify ? 'Edit' : 'Inspect'} course name, credits, license and metadata · ${_course.authors.isEmpty ? 'Author not specified' : _course.authors.map((a) => '${a.name} (${a.roles.join(', ')})').join(', ')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _canModify
                  ? _editCourseInfo
                  : () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => CourseInfoScreen(course: _course),
                      ),
                    ),
            ),
            if (widget.access.canCopyAsNewCourse) ...[
              const Divider(height: 1),
              ListTile(
                key: const Key('course-editor-copy-as-new-course'),
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy as New Course'),
                subtitle: const Text(
                  'Create a new independent Course using this Course as the starting content.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _copyAsNewCourse,
              ),
            ],
            if (widget.access.canFork) ...[
              const Divider(height: 1),
              ListTile(
                key: const Key('course-editor-fork-course'),
                leading: const Icon(Icons.fork_right_outlined),
                title: const Text('Fork'),
                subtitle: const Text(
                  'Create a derivative Course that preserves the source Course lineage.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _forkCourse,
              ),
            ],
            const Divider(height: 1),
            ListTile(
              key: const Key('course-draft-status'),
              leading: Icon(
                _course.publicationState.isPublished
                    ? Icons.visibility_outlined
                    : Icons.edit_note_outlined,
              ),
              title: const Text('Course delivery status'),
              subtitle: Text(
                _course.publicationState.isPublished
                    ? 'Published'
                    : 'Not published',
              ),
              trailing: TextButton.icon(
                onPressed: _canModify ? _toggleCourseDraftStatus : null,
                style: _course.publicationState.isPublished
                    ? null
                    : TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF0756DF),
                      ),
                icon: Icon(
                  _course.publicationState.isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.publish_outlined,
                ),
                label: Text(
                  _course.publicationState.isPublished
                      ? 'Unpublish'
                      : 'Publish',
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('course-editor-version-history'),
              leading: const Icon(Icons.history_outlined),
              title: const Text('Version history'),
              subtitle: Text(
                'Course version ${_course.courseVersion.isEmpty ? 'not confirmed' : _course.courseVersion} · ${_course.lastVersionEditorDisplayName.isEmpty ? 'No Last Version Editor yet' : _course.lastVersionEditorDisplayName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openVersionHistory,
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
                    ? 'On-Device TTS'
                    : '${_course.audioLibrary.length} MP3 mappings · ${_course.audioMode}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _canModify ? _openAudioLibrary : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text(
                'Image Library',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Browse shared images and images stored in this Course. Only admins add to or change the Shared Image Library. Import custom image in an exercise stores a picture in this Course.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _canModify
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlatImageLibraryScreen(
                          selectMode: false,
                          readOnly: true,
                          course: _course,
                          mediaStore: _service.mediaStore,
                          onCourseChanged: _updateDraft,
                          savedCourse: _session.originalCourse,
                        ),
                      ),
                    )
                  : null,
            ),
            if (canExportCourse) ...[
              const Divider(height: 1),
              ListTile(
                key: const Key('course-editor-export-json'),
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text(
                  'Export Course package',
                  style: _hierarchyLinkStyle,
                ),
                subtitle: const Text(
                  'Export the Course and its images and recordings together as a ZIP package.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportCustomCourse,
              ),
              if (_transfer.fileDialogsAvailable)
                ListTile(
                  key: const Key('course-editor-save-json-to'),
                  leading: const Icon(Icons.save_alt_outlined),
                  title: const Text(
                    'Save Course package to…',
                    style: _hierarchyLinkStyle,
                  ),
                  subtitle: Text(
                    'The same export, saved wherever you choose with the system file dialog.\n'
                    '${cloudFolderHelpText()}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _saveCustomCourseTo,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class LessonManagementScreen extends StatefulWidget {
  const LessonManagementScreen({
    super.key,
    required this.course,
    bool userCourse = false,
    required this.initiallyLocked,
    this.readOnly = false,
    this.courseEditorMode = CourseEditorMode.edit,
    this.onCourseChanged,
    this.clock,
  });

  final Course course;
  final bool initiallyLocked;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;
  final ValueChanged<Course>? onCourseChanged;
  final DateTime Function()? clock;

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen> {
  int _numberingFieldVersion = 0;
  final _ids = TimestampAuthoringIdGenerator();
  late Course _course;
  late bool _locked;
  bool _routeMayPop = false;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _locked = widget.readOnly || widget.initiallyLocked;
  }

  Course _withLessons(
    List<Lesson> lessons, {
    List<CourseLessonIconAsset>? lessonIconAssets,
  }) => Course.fromJson({
    ..._course.toJson(),
    'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    'lessonIconAssets': (lessonIconAssets ?? _course.lessonIconAssets)
        .map((asset) => asset.toJson())
        .toList(),
  });

  void _adoptCourse(Course course) {
    if (!mounted) return;
    course = const ProvisionalPublicationService().reconcile(
      course,
      updatedAt: _clock(),
      previous: _course,
    );
    setState(() => _course = course);
    widget.onCourseChanged?.call(course);
  }

  void _replaceLessons(
    List<Lesson> lessons, {
    List<CourseLessonIconAsset>? lessonIconAssets,
  }) => _adoptCourse(_withLessons(lessons, lessonIconAssets: lessonIconAssets));

  Future<void> _setLessonNumbering(LessonNumberingMode? mode) async {
    if (_locked || mode == null) return;
    var label = _course.customLessonLabel;
    if (mode == LessonNumberingMode.other) {
      final entered = await _askName(
        title: 'Custom Lesson label',
        initial: label,
        confirmLabel: 'Save',
        maxLength: 40,
      );
      if (!mounted) return;
      if (entered == null) {
        // Rebuild the field from the unchanged canonical selection on Cancel.
        setState(() => _numberingFieldVersion++);
        return;
      }
      label = entered;
    }
    _adoptCourse(
      Course.fromJson({
        ..._course.toJson(),
        'lessonNumberingMode': mode.name,
        'customLessonLabel': mode == LessonNumberingMode.other ? label : '',
      }),
    );
  }

  Future<void> _returnToCourse() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _course);
  }

  Future<String?> _askName({
    String title = 'New lesson',
    String initial = '',
    String confirmLabel = 'Create',
    int? maxLength,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLength: maxLength,
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
            child: Text(confirmLabel),
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
    _replaceLessons([
      ..._course.lessons,
      Lesson(
        lessonId: _ids.next('lesson'),
        publicationState: PublicationState.draft,
        provisionalDraft: true,
        updatedAt: _clock(),
        title: title,
        rounds: const [],
        section: _course.lessons.lastOrNull?.section ?? false,
        sectionName: _course.lessons.lastOrNull?.sectionName,
        guidebook: Guidebook.empty(),
      ),
    ]);
  }

  Future<void> _renameLesson(int index) async {
    if (_locked) return;
    final source = _course.lessons[index];
    final title = await _askName(
      title: 'Rename lesson',
      initial: source.title,
      confirmLabel: 'Save',
    );
    if (title == null || !mounted) return;
    final renamed = Lesson(
      lessonId: source.lessonId,
      publicationState: source.publicationState,
      provisionalDraft: source.provisionalDraft,
      updatedAt: _clock(),
      title: title,
      rounds: source.rounds,
      section: source.section,
      sectionName: source.sectionName,
      themeIconAsset: source.themeIconAsset,
      guidebook: source.guidebook,
      duel: source.duel,
    );
    final lessons = [..._course.lessons]..[index] = renamed;
    _replaceLessons(lessons);
  }

  void _duplicateLesson(int index) {
    if (_locked) return;
    final copy = AuthoringDuplicationService(
      ids: _ids,
    ).duplicateLesson(_course.lessons[index]);
    final lessons = [..._course.lessons]..insert(index + 1, copy);
    _replaceLessons(lessons);
  }

  Future<void> _previewLesson(int index) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LessonAuthoringPreviewScreen(
        course: _course,
        lesson: _course.lessons[index],
      ),
    ),
  );

  Future<void> _auditLesson(int index) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CourseAuditScreen(
        course: _course,
        result: CourseAuditService().auditLesson(
          _course,
          _course.lessons[index].lessonId,
        ),
        title: 'Lesson Audit',
      ),
    ),
  );

  Future<void> _setLessonPublication(int index, PublicationState state) async {
    final source = _course.lessons[index];
    if (!state.isPublished && source.publicationState.isPublished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move Lesson to Draft?'),
          content: const Text(
            'This Lesson will disappear from the learner course. Existing learner progress and XP will be preserved.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save as draft'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    final changed = Lesson.fromJson({
      ...source.toJson(),
      'publicationState': state.name,
      'provisionalDraft': false,
      'updatedAt': _clock().toUtc().toIso8601String(),
    });
    final lessons = [..._course.lessons]..[index] = changed;
    final candidate = _withLessons(lessons);
    if (state.isPublished) {
      final validationRoot = Course.fromJson({
        ...candidate.toJson(),
        'publicationState': PublicationState.published.name,
      });
      final visible = const PublicationService().learnerCourse(validationRoot)!;
      final errors = CourseAuditService()
          .auditLesson(
            visible,
            changed.lessonId,
            sourceReferenceCourse: validationRoot,
          )
          .issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .length;
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson cannot be saved as normal content: $errors blocking error${errors == 1 ? '' : 's'}.',
            ),
          ),
        );
        return;
      }
    }
    if (mounted) _adoptCourse(candidate);
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
    _replaceLessons(lessons);
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_locked) return;
    final lessons = [..._course.lessons];
    final lesson = lessons.removeAt(oldIndex);
    lessons.insert(newIndex, lesson);
    _replaceLessons(lessons);
  }

  Future<void> _openLesson(int index) async {
    var iconAssets = _course.lessonIconAssets;
    final updated = await Navigator.of(context).push<Lesson>(
      MaterialPageRoute(
        builder: (_) => LessonEditorScreen(
          course: _course,
          lesson: _course.lessons[index],
          readOnly: _locked,
          courseEditorMode: widget.courseEditorMode,
          onLessonIconAssetsChanged: _locked
              ? null
              : (value) => iconAssets = value,
          onCourseChanged: _locked
              ? null
              : (course) {
                  iconAssets = course.lessonIconAssets;
                  _adoptCourse(course);
                },
          clock: _clock,
        ),
      ),
    );
    if (_locked || updated == null || !mounted) return;
    final currentIndex = _course.lessons.indexWhere(
      (lesson) => lesson.lessonId == updated.lessonId,
    );
    if (currentIndex < 0) return;
    final lessons = [..._course.lessons]..[currentIndex] = updated;
    _replaceLessons(lessons, lessonIconAssets: iconAssets);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<ExerciseSearchResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorSearchScreen(
          course: _course,
          scope: ExerciseSearchScope.course,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final changed = await _openSearchResult(
      context,
      course: _course,
      result: result,
      readOnly: _locked,
      initiallyInspecting:
          widget.courseEditorMode == CourseEditorMode.inspection,
      clock: _clock,
    );
    if (changed != null && mounted) _adoptCourse(changed);
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(_course);
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _returnToCourse();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lessons'),
          leading: BackButton(onPressed: _returnToCourse),
          actions: [
            IconButton(
              key: const Key('lessons-search-action'),
              tooltip: 'Search the whole course',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
            const EditorAppBarActions(),
          ],
        ),
        floatingActionButton: widget.readOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: _locked ? null : _addLesson,
                icon: const Icon(Icons.add),
                label: const Text('New lesson'),
              ),
        body: Column(
          children: [
            EditorBreadcrumbs(course: _course),
            Flexible(
              child: SingleChildScrollView(
                key: const Key('lesson-course-settings-scroll'),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Card(
                        key: const Key('lesson-appearance-settings'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Lesson appearance',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<LessonNumberingMode>(
                                key: ValueKey(
                                  'lesson-numbering-${_course.lessonNumberingMode.name}-$_numberingFieldVersion',
                                ),
                                initialValue: _course.lessonNumberingMode,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Lesson numbering',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.lesson,
                                    child: Text('Lesson + number'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.unit,
                                    child: Text('Unit'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.topic,
                                    child: Text('Topic'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.module,
                                    child: Text('Module'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.skill,
                                    child: Text('Skill'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.chapter,
                                    child: Text('Chapter'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.stage,
                                    child: Text('Stage'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.step,
                                    child: Text('Step'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.part,
                                    child: Text('Part'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.other,
                                    child: Text('Other...'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.numberOnly,
                                    child: Text('Number only'),
                                  ),
                                  DropdownMenuItem(
                                    value: LessonNumberingMode.none,
                                    child: Text('Title only'),
                                  ),
                                ],
                                onChanged: _locked ? null : _setLessonNumbering,
                              ),
                              if (_course.lessonNumberingMode ==
                                  LessonNumberingMode.other)
                                TextButton(
                                  onPressed: _locked
                                      ? null
                                      : () => _setLessonNumbering(
                                          LessonNumberingMode.other,
                                        ),
                                  child: Text(
                                    'Custom Lesson label: ${_course.customLessonLabel}',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      key: const Key('course-use-guidebook'),
                      title: const Text('Use GuideBook'),
                      value: _course.useGuidebook,
                      onChanged: _locked
                          ? null
                          : (value) => _adoptCourse(
                              Course.fromJson({
                                ..._course.toJson(),
                                'useGuidebook': value,
                              }),
                            ),
                    ),
                    SwitchListTile(
                      key: const Key('course-create-duels'),
                      title: const Text('Create Duels'),
                      subtitle: const Text(
                        'When enough eligible Exercises are available, winning a Duel unlocks the next Lesson without completing the preceding Lesson.',
                      ),
                      value: _course.createDuels,
                      onChanged: _locked
                          ? null
                          : (value) => _adoptCourse(
                              Course.fromJson({
                                ..._course.toJson(),
                                'createDuels': value,
                              }),
                            ),
                    ),
                  ],
                ),
              ),
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
                        return AuthoringStatusCard(
                          key: ValueKey(lesson.lessonId),
                          indicatorKey: ValueKey(
                            'lesson-status-indicator-${lesson.lessonId}',
                          ),
                          draftIndicatorKey: ValueKey(
                            'lesson-draft-indicator-${lesson.lessonId}',
                          ),
                          hasDraft: hierarchyStatus.lessonHasDraft(lesson),
                          hasAuditConcern: hierarchyStatus
                              .lessonHasAuditConcern(lesson),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                key: ValueKey(
                                  'lesson-entry-${lesson.lessonId}',
                                ),
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  enabled: !_locked,
                                  child: const Icon(Icons.drag_handle),
                                ),
                                title: Text(
                                  const LessonPresentationService()
                                      .identity(_course, index)
                                      .fullText,
                                ),
                                subtitle: Text(
                                  '${_roundCountLabel(lesson.rounds.length)}$section',
                                ),
                                onTap: () => _openLesson(index),
                                trailing: PopupMenuButton<String>(
                                  key: ValueKey(
                                    'lesson-actions-${lesson.lessonId}',
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') _openLesson(index);
                                    if (value == 'rename') _renameLesson(index);
                                    if (value == 'delete') _deleteLesson(index);
                                    if (value == 'duplicate') {
                                      _duplicateLesson(index);
                                    }
                                    if (value == 'preview') {
                                      _previewLesson(index);
                                    }
                                    if (value == 'audit') _auditLesson(index);
                                    if (value == 'publication') {
                                      _setLessonPublication(
                                        index,
                                        lesson.publicationState.isPublished
                                            ? PublicationState.draft
                                            : PublicationState.published,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(_locked ? 'View' : 'Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'rename',
                                      enabled: !_locked,
                                      child: const Text('Rename'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      enabled: !_locked,
                                      child: const Text('Delete'),
                                    ),
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      enabled: !_locked,
                                      child: const Text('Duplicate'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'preview',
                                      child: Text('Preview'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'audit',
                                      child: Text('Audit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'publication',
                                      enabled: !_locked,
                                      child: Text(
                                        lesson.publicationState.isPublished
                                            ? 'Save as draft'
                                            : 'Save',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              EditorInternalIdText(
                                label: 'Lesson',
                                id: lesson.lessonId,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                              ),
                            ],
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
}

class LessonAuthoringPreviewScreen extends StatelessWidget {
  const LessonAuthoringPreviewScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  final Course course;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'PREVIEW · ${course.lessons.any((candidate) => candidate.lessonId == lesson.lessonId) ? const LessonPresentationService().identity(course, course.lessons.indexWhere((candidate) => candidate.lessonId == lesson.lessonId)).fullText : lesson.title}',
      ),
    ),
    body: lesson.rounds.isEmpty
        ? const Center(child: Text('This Lesson has no Rounds to preview.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lesson.rounds.length,
            itemBuilder: (context, index) {
              final round = lesson.rounds[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text(round.displayTitle(index)),
                  subtitle: Text('${round.exercises.length} exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RoundScreen(
                        course: course,
                        lesson: lesson,
                        round: round,
                        ttsLanguage:
                            CourseLanguageResolver.learning(course).code ?? '',
                        roundIndex: index,
                        previewMode: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
  );
}

class GuidebookEditorScreen extends StatefulWidget {
  final Guidebook guidebook;
  final String guidebookId;
  const GuidebookEditorScreen({
    super.key,
    required this.guidebook,
    this.guidebookId = '',
  });
  @override
  State<GuidebookEditorScreen> createState() => _GuidebookEditorScreenState();
}

class _GuidebookEditorScreenState extends State<GuidebookEditorScreen> {
  late final TextEditingController _overview,
      _usageExamples,
      _vocabulary,
      _grammar;
  late List<GuidebookInsight> _insights;
  @override
  void initState() {
    super.initState();
    final g = widget.guidebook;
    _overview = TextEditingController(text: g.overview);
    _usageExamples = TextEditingController(
      text: g.content
          .where((content) => content.kind == 'example')
          .map((content) => content.text)
          .join('\n'),
    );
    _vocabulary = TextEditingController(text: g.vocabulary.join('\n'));
    _grammar = TextEditingController(text: g.grammar.join('\n'));
    _insights = [...g.insights];
  }

  @override
  void dispose() {
    for (final c in [_overview, _usageExamples, _vocabulary, _grammar]) {
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
    PublicationState publicationState, {
    Iterable<LearningContent>? existingItems,
  }) {
    final existing =
        (existingItems ??
                widget.guidebook.content.where(
                  (content) => content.kind == kind && content.role == role,
                ))
            .toList();
    final usedIds = <String>{};
    LearningContent? matchFor(String text) {
      for (final content in existing) {
        if (!usedIds.contains(content.id) &&
            content.text.trim() == text.trim()) {
          usedIds.add(content.id);
          return content;
        }
      }
      return null;
    }

    return [
      for (final text in texts)
        (() {
          final matched = matchFor(text);
          return LearningContent(
            id: matched?.id ?? newId(),
            publicationState: publicationState,
            kind: matched?.kind ?? kind,
            required: matched?.required ?? false,
            editorTemplate: matched?.editorTemplate ?? '',
            role: matched?.role ?? role,
            text: text,
            sourceRefs: matched?.sourceRefs ?? const [],
          );
        })(),
    ];
  }

  LearningContent _withPublicationState(
    LearningContent content,
    PublicationState publicationState,
  ) => LearningContent.fromJson({
    ...content.toJson(),
    'publicationState': publicationState.name,
  });

  bool _isPrimaryFieldContent(LearningContent content) =>
      (content.kind == 'explanation' && content.role == 'overview') ||
      content.kind == 'vocabulary' ||
      (content.kind == 'explanation' && content.role == 'grammar') ||
      content.kind == 'example';

  Future<void> _openInsights() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GuidebookInsightsEditorScreen(
          initialSections: _insights,
          onChanged: (sections) => _insights = [...sections],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _save(PublicationState publicationState) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var sequence = 0;
    String newId() => 'guide_${stamp}_${sequence++}';
    final overview = _overview.text.trim();
    final content = <LearningContent>[
      ..._editedItems(
        'explanation',
        'overview',
        [if (overview.isNotEmpty) overview],
        newId,
        publicationState,
      ),
      ..._editedItems(
        'example',
        'example',
        _lines(_usageExamples),
        newId,
        publicationState,
        existingItems: widget.guidebook.content.where(
          (content) => content.kind == 'example',
        ),
      ),
      ..._editedItems(
        'vocabulary',
        'vocabulary',
        _lines(_vocabulary),
        newId,
        publicationState,
      ),
      ..._editedItems(
        'explanation',
        'grammar',
        _lines(_grammar),
        newId,
        publicationState,
      ),
      for (final existing in widget.guidebook.content)
        if (!_isPrimaryFieldContent(existing))
          _withPublicationState(existing, publicationState),
    ];
    Navigator.pop(
      context,
      Guidebook(
        publicationState: publicationState,
        content: content,
        insights: _insights,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Guidebook'),
      actions: [
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
        _field(_overview, 'Overview', lines: 5),
        _field(
          _usageExamples,
          'Usage examples',
          helper:
              'One learner-facing example per line. These examples can support draft Round generation and must be reviewed before use.',
        ),
        _field(
          _vocabulary,
          'Vocabulary',
          lines: 4,
          helper:
              'One target/source pair per line. Example: casa = house. This learner-facing Lesson Guidebook can also be used to automatically generate new exercises, which must be reviewed and approved before creation.',
        ),
        _field(_grammar, 'Grammar'),
        ListTile(
          key: const Key('guidebook-insights-link'),
          leading: const Icon(Icons.lightbulb_outline),
          title: const Text('Insights'),
          subtitle: Text(
            '${_insights.length} ${_insights.length == 1 ? 'section' : 'sections'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openInsights,
        ),
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

class GuidebookInsightsEditorScreen extends StatefulWidget {
  final List<GuidebookInsight> initialSections;
  final ValueChanged<List<GuidebookInsight>> onChanged;

  const GuidebookInsightsEditorScreen({
    super.key,
    required this.initialSections,
    required this.onChanged,
  });

  @override
  State<GuidebookInsightsEditorScreen> createState() =>
      _GuidebookInsightsEditorScreenState();
}

class _GuidebookInsightsEditorScreenState
    extends State<GuidebookInsightsEditorScreen> {
  late final List<GuidebookInsight> _sections = [...widget.initialSections];

  void _notify() => widget.onChanged(List.unmodifiable(_sections));

  Future<void> _edit({int? index}) async {
    final existing = index == null ? null : _sections[index];
    final title = TextEditingController(text: existing?.title ?? '');
    final text = TextEditingController(text: existing?.text ?? '');
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<GuidebookInsight>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          index == null ? 'Add Insight section' : 'Edit Insight section',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('guidebook-insight-title'),
                    controller: title,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Title',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a Title.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('guidebook-insight-text'),
                    controller: text,
                    minLines: 4,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Text',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter Text.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('guidebook-insight-confirm'),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                GuidebookInsight(
                  title: title.text.trim(),
                  text: text.text.trim(),
                ),
              );
            },
            child: Text(index == null ? 'Add' : 'Apply'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      title.dispose();
      text.dispose();
    });
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        _sections.add(result);
      } else {
        _sections[index] = result;
      }
    });
    _notify();
  }

  Future<void> _remove(int index) async {
    final remove =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Insight section?'),
            content: Text(
              'Remove “${_sections[index].title}”? This takes effect when the Guidebook is saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              FilledButton(
                key: const Key('guidebook-insight-remove-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!remove || !mounted) return;
    setState(() => _sections.removeAt(index));
    _notify();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Insights')),
    body: _sections.isEmpty
        ? const Center(child: Text('No Insight sections yet.'))
        : ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _sections.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final section = _sections.removeAt(oldIndex);
                _sections.insert(newIndex, section);
              });
              _notify();
            },
            itemBuilder: (context, index) {
              final section = _sections[index];
              return Card(
                key: ValueKey('guidebook-insight-section-$index'),
                child: ListTile(
                  title: Text(section.title),
                  subtitle: Text(
                    section.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _edit(index: index),
                  trailing: IconButton(
                    tooltip: 'Remove Insight section',
                    onPressed: () => _remove(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('guidebook-add-insight'),
      onPressed: _edit,
      icon: const Icon(Icons.add),
      label: const Text('Add section'),
    ),
  );
}

class LessonEditorScreen extends StatefulWidget {
  final Course course;
  final ValueChanged<Course>? onCourseChanged;
  final Lesson lesson;
  final ValueChanged<List<CourseLessonIconAsset>>? onLessonIconAssetsChanged;
  final DateTime Function()? clock;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;
  const LessonEditorScreen({
    super.key,
    required this.course,
    this.onCourseChanged,
    required this.lesson,
    this.onLessonIconAssetsChanged,
    this.clock,
    this.readOnly = false,
    this.courseEditorMode = CourseEditorMode.edit,
  });
  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late Course _course;
  late Lesson _lesson;
  late bool _belongsToSection;
  late final TextEditingController _sectionName;
  int _sectionPickerVersion = 0;
  String? _themeIconAsset;
  late List<CourseLessonIconAsset> _lessonIconAssets;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  final _lessonIcons = LessonIconService();
  bool _routeMayPop = false;

  Course get _courseWithIcons => Course.fromJson({
    ..._course.toJson(),
    'lessons': [
      for (final lesson in _course.lessons)
        (lesson.lessonId == _lesson.lessonId ? _lesson : lesson).toJson(),
    ],
    'lessonIconAssets': _lessonIconAssets
        .map((asset) => asset.toJson())
        .toList(),
  });

  int get _lessonNumber {
    final index = _course.lessons.indexWhere(
      (lesson) => lesson.lessonId == _lesson.lessonId,
    );
    return index < 0 ? 1 : index + 1;
  }

  String get _lessonLabel {
    final course = _courseWithIcons;
    final index = course.lessons.indexWhere(
      (lesson) => lesson.lessonId == _lesson.lessonId,
    );
    return index < 0
        ? _lesson.title
        : const LessonPresentationService().identity(course, index).fullText;
  }

  void _adoptCourse(Course course) {
    if (!mounted) return;
    course = const ProvisionalPublicationService().reconcile(
      course,
      updatedAt: _clock(),
      previous: _course,
    );
    final lesson = course.lessons.firstWhere(
      (candidate) => candidate.lessonId == _lesson.lessonId,
    );
    setState(() {
      _course = course;
      _lesson = lesson;
      _lessonIconAssets = [...course.lessonIconAssets];
    });
    widget.onCourseChanged?.call(course);
  }

  void _publishLesson(Lesson lesson) {
    if (!mounted) return;
    final course = Course.fromJson({
      ..._course.toJson(),
      'lessons': [
        for (final candidate in _course.lessons)
          (candidate.lessonId == lesson.lessonId ? lesson : candidate).toJson(),
      ],
      'lessonIconAssets': _lessonIconAssets
          .map((asset) => asset.toJson())
          .toList(),
    });
    _adoptCourse(course);
  }

  Future<void> _returnToLessons() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _lesson);
  }

  CourseLessonIconAsset? _managedIcon(String? reference) {
    final id = reference == null
        ? null
        : CourseLessonIconAsset.assetIdFromReference(reference);
    if (id == null) return null;
    for (final asset in _lessonIconAssets) {
      if (asset.assetId == id) return asset;
    }
    return null;
  }

  Future<void> _chooseSection(String? choice) async {
    if (widget.readOnly) return;
    if (choice == null) return;
    if (choice == 'manage') {
      await _manageSections();
      if (mounted) setState(() => _sectionPickerVersion++);
      return;
    }
    String name = choice.startsWith('name:') ? choice.substring(5) : '';
    if (choice == 'add') {
      final controller = TextEditingController();
      final added = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add new section'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Section name'),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
      if (!mounted) return;
      if (added == null) {
        setState(() => _sectionPickerVersion++);
        return;
      }
      name = added;
      _adoptCourse(
        Course.fromJson({
          ..._courseWithIcons.toJson(),
          'sectionNames': {..._course.availableSectionNames, name}.toList(),
        }),
      );
    }
    if (!mounted) return;
    setState(() {
      _belongsToSection = name.isNotEmpty;
      _sectionName.text = name;
      _sectionPickerVersion++;
    });
  }

  Future<void> _manageSections() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Manage sections'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (_course.availableSectionNames.isEmpty)
                  const Text('No section names yet.'),
                for (final name in _course.availableSectionNames)
                  ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      tooltip: 'Remove $name',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final count = _course.lessons
                            .where(
                              (lesson) =>
                                  lesson.section && lesson.sectionName == name,
                            )
                            .length;
                        if (count > 0 ||
                            (_belongsToSection && _sectionName.text == name)) {
                          await showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Section is in use'),
                              content: Text(
                                count > 0
                                    ? 'This section is used by $count ${count == 1 ? 'Lesson' : 'Lessons'}.\nRemove or change those assignments first.'
                                    : 'This section is selected in the current Lesson. Change that assignment first.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        _adoptCourse(
                          Course.fromJson({
                            ..._courseWithIcons.toJson(),
                            'sectionNames': _course.availableSectionNames
                                .where((value) => value != name)
                                .toList(),
                          }),
                        );
                        if (context.mounted) refresh(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _lesson = widget.lesson;
    _belongsToSection = _lesson.section;
    _sectionName = TextEditingController(text: _lesson.sectionName ?? '');
    _themeIconAsset = _lesson.themeIconAsset;
    _lessonIconAssets = [..._course.lessonIconAssets];
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
    publicationState: _lesson.publicationState,
    provisionalDraft: _lesson.provisionalDraft,
    updatedAt: _lesson.updatedAt,
    title: title ?? _lesson.title,
    rounds: rounds ?? _lesson.rounds,
    section: _lesson.section,
    sectionName: _lesson.sectionName,
    themeIconAsset: _lesson.themeIconAsset,
    guidebook: guidebook ?? _lesson.guidebook,
    duel: _lesson.duel,
  );

  Lesson? _editedLesson(PublicationState state, {DateTime? updatedAt}) {
    final sectionName = _sectionName.text.trim();
    if (_belongsToSection && sectionName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a Section name.')));
      return null;
    }
    return Lesson(
      lessonId: _lesson.lessonId,
      publicationState: state,
      provisionalDraft: false,
      updatedAt: updatedAt ?? _lesson.updatedAt,
      title: _lesson.title,
      rounds: _lesson.rounds,
      section: _belongsToSection,
      sectionName: _belongsToSection ? sectionName : null,
      themeIconAsset: _themeIconAsset,
      guidebook: _lesson.guidebook,
      duel: _lesson.duel,
    );
  }

  Future<void> _saveLesson(PublicationState state) async {
    if (widget.readOnly) return;
    if (!state.isPublished &&
        _lesson.publicationState.isPublished &&
        !await _confirmMoveToDraft(context, 'Lesson')) {
      return;
    }
    if (!mounted) return;
    final candidate = _editedLesson(state);
    if (candidate == null) return;
    final edited = _sameAuthoringJson(candidate.toJson(), _lesson.toJson())
        ? candidate
        : _editedLesson(state, updatedAt: _clock())!;
    if (state.isPublished) {
      final courseJson = {
        ..._courseWithIcons.toJson(),
        'publicationState': PublicationState.published.name,
        'lessons': [
          for (final lesson in _course.lessons)
            (lesson.lessonId == edited.lessonId ? edited : lesson).toJson(),
        ],
      };
      final authored = Course.fromJson(courseJson);
      final learnerCourse = const PublicationService().learnerCourse(authored)!;
      final errors = CourseAuditService()
          .auditLesson(
            learnerCourse,
            edited.lessonId,
            sourceReferenceCourse: authored,
          )
          .issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .toList();
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson cannot be saved as normal content: ${errors.length} blocking error${errors.length == 1 ? '' : 's'}.',
            ),
          ),
        );
        return;
      }
    }
    widget.onLessonIconAssetsChanged?.call(
      List<CourseLessonIconAsset>.unmodifiable(_lessonIconAssets),
    );
    if (!mounted) return;
    _publishLesson(edited);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _lesson);
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
    if (widget.readOnly) return;
    final n = await _name('Rename lesson', initial: _lesson.title);
    if (n != null && mounted) _publishLesson(_copy(title: n));
  }

  Future<void> _editGuidebook() async {
    if (widget.readOnly) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => GuidebookScreen(
            course: _courseWithIcons,
            lesson: _lesson,
            lessonIndex: _lessonNumber - 1,
            includeDraftContent: true,
          ),
        ),
      );
      return;
    }
    final oldGuideIds = _lesson.guidebook.content
        .map((content) => content.id)
        .toSet();
    final g = await Navigator.of(context).push<Guidebook>(
      MaterialPageRoute(
        builder: (_) => GuidebookEditorScreen(
          guidebook: _lesson.guidebook,
          guidebookId: _lesson.guidebookId,
        ),
      ),
    );
    if (g == null || !mounted) return;
    final newGuideIds = g.content.map((content) => content.id).toSet();
    final rounds = [
      for (final round in _lesson.rounds)
        LearningRound(
          id: round.id,
          publicationState: round.publicationState,
          provisionalDraft: round.provisionalDraft,
          updatedAt: round.updatedAt,
          title: round.title,
          visualType: round.visualType,
          content: [
            for (final content in round.content)
              LearningContent(
                id: content.id,
                publicationState: content.publicationState,
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
    _publishLesson(_copy(guidebook: g, rounds: rounds));
  }

  Future<void> _openRounds() async {
    final sectionName = _sectionName.text.trim();
    final draftLesson = Lesson(
      lessonId: _lesson.lessonId,
      publicationState: _lesson.publicationState,
      provisionalDraft: _lesson.provisionalDraft,
      updatedAt: _lesson.updatedAt,
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
        builder: (_) => LessonRoundsScreen(
          course: _courseWithIcons,
          onCourseChanged: widget.readOnly ? null : _adoptCourse,
          lesson: draftLesson,
          readOnly: widget.readOnly,
          courseEditorMode: widget.courseEditorMode,
          clock: _clock,
        ),
      ),
    );
    if (!widget.readOnly && rounds != null && mounted) {
      _publishLesson(_copy(rounds: rounds));
    }
  }

  /// The Lessons that use a custom icon: every other Lesson's saved icon, and
  /// this Lesson's saved icon or current unsaved choice.
  List<String> _lessonsUsingIcon(CourseLessonIconAsset asset) {
    final users = <String>[];
    for (var index = 0; index < _course.lessons.length; index++) {
      final lesson = _course.lessons[index];
      final isThis = lesson.lessonId == _lesson.lessonId;
      final uses = isThis
          ? _themeIconAsset == asset.reference ||
                _lesson.themeIconAsset == asset.reference
          : lesson.themeIconAsset == asset.reference;
      if (uses) {
        users.add(
          isThis
              ? 'this Lesson'
              : (lesson.title.trim().isEmpty
                    ? 'Lesson ${index + 1}'
                    : lesson.title.trim()),
        );
      }
    }
    return users;
  }

  /// Removes a custom icon from the Course's icon list. It is a working-copy
  /// change like every other edit: it is kept when the Lesson is saved and the
  /// Course confirmed, and Cancel restores it. An icon a Lesson still uses is
  /// never removed, so no Lesson can end up pointing at a missing icon.
  Future<void> _deleteCustomIcon(String assetId) async {
    if (widget.readOnly) return;
    final asset = _lessonIconAssets
        .where((candidate) => candidate.assetId == assetId)
        .firstOrNull;
    if (asset == null) return;
    final users = _lessonsUsingIcon(asset);
    if (users.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'This icon is still used by ${users.join(', ')}. Choose another icon (or none) for ${users.length == 1 ? 'it' : 'them'}, save, then delete this icon.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete custom icon?'),
        content: const Text(
          'The icon is removed from this Course when you save the Lesson and confirm the Course. Cancel undoes it. No Lesson uses it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-custom-lesson-icon'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete icon'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _lessonIconAssets = [
        for (final candidate in _lessonIconAssets)
          if (candidate.assetId != assetId) candidate,
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Custom icon deleted. Save the Lesson to keep the change.',
        ),
      ),
    );
  }

  /// The preinstalled option currently chosen, or null (Numbers or a custom icon).
  LessonIconOption? get _selectedPreinstalledOption {
    for (final option in LessonIconCatalog.options) {
      if (option.assetPath == _themeIconAsset) return option;
    }
    return null;
  }

  // Collapsed Preinstalled row: the chosen preinstalled icon, or Numbers when
  // no icon is chosen; nothing when a custom icon is chosen.
  String _preinstalledChoiceLabel() =>
      _selectedPreinstalledOption?.label ??
      (_themeIconAsset == null ? 'Numbers' : 'Preinstalled icons');

  Widget? _preinstalledChoicePreview() {
    final option = _selectedPreinstalledOption;
    if (option != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(option.assetPath, fit: BoxFit.contain),
      );
    }
    if (_themeIconAsset == null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: LessonFallbackIcon(number: _lessonNumber, size: 44),
      );
    }
    return null;
  }

  Future<void> _chooseThemeIcon() async {
    if (widget.readOnly) return;
    const none = '__none__';
    const import = '__import__';
    const importFrom = '__import_from__';
    const deleteIconPrefix = '__delete_icon__:';
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Lesson theme icon',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Wrap(
                      children: [
                        IconButton(
                          key: const Key('import-custom-lesson-icon'),
                          tooltip: 'Import custom icon',
                          onPressed: () => Navigator.pop(context, import),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                        if (_lessonIcons.fileDialogsAvailable)
                          IconButton(
                            key: const Key('open-custom-lesson-icon-from'),
                            tooltip: 'Open custom icon from…',
                            onPressed: () => Navigator.pop(context, importFrom),
                            icon: const Icon(Icons.folder_open_outlined),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Shows only the current choice; opens to show every preinstalled
              // icon.
              ExpansionTile(
                key: const Key('lesson-theme-icon-preinstalled-toggle'),
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: _preinstalledChoicePreview(),
                title: Text(_preinstalledChoiceLabel()),
                subtitle: const Text('Preinstalled icons · tap to show all'),
                children: [
                  GridView.builder(
                    key: const Key('lesson-theme-icon-grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
                        label: option?.label ?? 'Numbers',
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
                                        ? LessonFallbackIcon(
                                            number: _lessonNumber,
                                            size: 54,
                                          )
                                        : Image.asset(
                                            option.assetPath,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option?.label ?? 'Numbers',
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
                ],
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Custom'),
                ),
              ),
              SizedBox(
                height: _lessonIconAssets.isEmpty ? 40 : 112,
                child: _lessonIconAssets.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No custom icons imported.'),
                        ),
                      )
                    : ListView.separated(
                        key: const Key('custom-lesson-icon-list'),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: _lessonIconAssets.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final asset = _lessonIconAssets[index];
                          final selected = asset.reference == _themeIconAsset;
                          return Card(
                            color: selected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                : null,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey(
                                'custom-lesson-icon-${asset.assetId}',
                              ),
                              onTap: () =>
                                  Navigator.pop(context, asset.reference),
                              child: SizedBox(
                                width: 96,
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Image.memory(
                                              base64Decode(asset.base64Png),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const Text('Custom'),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        key: ValueKey(
                                          'delete-custom-lesson-icon-${asset.assetId}',
                                        ),
                                        tooltip: 'Delete this custom icon',
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 18,
                                        onPressed: () => Navigator.pop(
                                          context,
                                          '$deleteIconPrefix${asset.assetId}',
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ),
                                  ],
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
    if (selected.startsWith(deleteIconPrefix)) {
      await _deleteCustomIcon(selected.substring(deleteIconPrefix.length));
      // Reopen so the list shows the result.
      if (mounted) await _chooseThemeIcon();
      return;
    }
    if (selected == import || selected == importFrom) {
      try {
        final ImportedLessonIcon imported;
        if (selected == importFrom) {
          // Open from…: same normalization as the fixed-folder import.
          final picked = await _lessonIcons.importPreparedIconFromDialog();
          if (!mounted) return;
          final opened = picked.icon;
          if (opened == null) {
            showFileDialogFeedback(
              context,
              picked.dialog,
              saving: false,
              fallbackHint: lessonIconFallbackHint,
            );
            return;
          }
          imported = opened;
        } else {
          imported = await _lessonIcons.importPreparedIcon();
        }
        if (!mounted) return;
        setState(() {
          _lessonIconAssets = [..._lessonIconAssets, imported.asset];
          _themeIconAsset = imported.asset.reference;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Custom icon imported and normalized to a 256x256 PNG.',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }
    setState(() => _themeIconAsset = selected == none ? null : selected);
  }

  Future<void> _openGuidebookRoundGenerator() async {
    if (widget.readOnly) return;
    final generated = await Navigator.of(context).push<List<LearningRound>>(
      MaterialPageRoute(
        builder: (_) => GuidebookRoundGeneratorScreen(
          course: _courseWithIcons,
          lesson: _lesson,
          clock: _clock,
        ),
      ),
    );
    if (generated == null || generated.isEmpty || !mounted) return;
    _publishLesson(_copy(rounds: [..._lesson.rounds, ...generated]));
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<ExerciseSearchResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorSearchScreen(
          course: _courseWithIcons,
          scope: ExerciseSearchScope.lesson,
          lessonId: _lesson.lessonId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final changed = await _openSearchResult(
      context,
      course: _courseWithIcons,
      result: result,
      readOnly: widget.readOnly,
      initiallyInspecting:
          widget.courseEditorMode == CourseEditorMode.inspection,
      clock: _clock,
    );
    if (changed != null && mounted) _adoptCourse(changed);
  }

  Future<void> _previewLesson() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LessonAuthoringPreviewScreen(
        course: _courseWithIcons,
        lesson: _lesson,
      ),
    ),
  );

  Future<void> _auditLesson() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CourseAuditScreen(
        course: _courseWithIcons,
        result: CourseAuditService().auditLesson(
          _courseWithIcons,
          _lesson.lessonId,
        ),
        title: 'Lesson Audit',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(
      _courseWithIcons,
    );
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToLessons();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _returnToLessons),
          title: Text(_lessonLabel),
          actions: [
            IconButton(
              key: const Key('lesson-search-action'),
              tooltip: 'Search this Lesson',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
            const EditorAppBarActions(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                EditorBreadcrumbs(
                  course: _courseWithIcons,
                  lessonId: _lesson.lessonId,
                ),
                if (!_lesson.publicationState.isPublished)
                  _DraftBranchIndicator(
                    key: const Key('lesson-own-draft-indicator'),
                    message: _lesson.provisionalDraft
                        ? 'This new Lesson is Draft until its required branch is complete and saved. It then becomes non-Draft automatically. Save as draft keeps the Lesson Draft until you explicitly Save it.'
                        : 'This Lesson is Draft and hidden from learner delivery, even when its Rounds and Exercises are Published. Use Save to publish the Lesson.',
                  ),
                if (!widget.readOnly) ...[
                  OutlinedButton(
                    key: const Key('save-lesson-draft'),
                    onPressed: () => _saveLesson(PublicationState.draft),
                    child: const Text('Save as draft'),
                  ),
                  FilledButton(
                    key: const Key('save-lesson'),
                    onPressed: () => _saveLesson(PublicationState.published),
                    child: const Text('Save'),
                  ),
                ],
              ],
            ),
          ),
        ),
        body: ListView(
          key: const Key('lesson-metadata-controls'),
          padding: const EdgeInsets.only(bottom: 48),
          children: [
            EditorInternalIdText(label: 'Lesson', id: _lesson.lessonId),
            AuthoringStatusCard(
              indicatorKey: const Key('lesson-rounds-status-indicator'),
              draftIndicatorKey: const Key('lesson-rounds-draft-indicator'),
              hasDraft: hierarchyStatus.lessonHasRoundDraft(_lesson),
              hasAuditConcern: hierarchyStatus.lessonHasRoundAuditConcern(
                _lesson,
              ),
              cardMargin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('lesson-rounds-navigation'),
                leading: const Icon(Icons.view_list_outlined),
                title: const Text('Rounds', style: _hierarchyLinkStyle),
                subtitle: Text(_roundCountLabel(_lesson.rounds.length)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openRounds,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('lesson-title-control'),
              leading: const Icon(Icons.title),
              title: const Text('Lesson title'),
              subtitle: Text(_lesson.title),
              trailing: Icon(
                widget.readOnly
                    ? Icons.visibility_outlined
                    : Icons.edit_outlined,
              ),
              onTap: widget.readOnly ? null : _rename,
            ),
            AuthoringStatusCard(
              indicatorKey: const Key('lesson-guidebook-status-indicator'),
              draftIndicatorKey: const Key('lesson-guidebook-draft-indicator'),
              hasDraft: hierarchyStatus.lessonGuidebookHasDraft(_lesson),
              hasAuditConcern: hierarchyStatus.lessonGuidebookAuditStatus(
                _lesson,
              ),
              neutralAuditMessage:
                  'No colored border: GuideBook is turned off for this Course.',
              cardMargin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('lesson-guidebook-navigation'),
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Lesson Guidebook'),
                subtitle: const Text(
                  'Learner reference for this Lesson. Its vocabulary and examples can propose progressively harder draft Rounds for review.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editGuidebook,
              ),
            ),
            ListTile(
              key: const Key('guidebook-round-generator'),
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Generate Rounds from GuideBook'),
              subtitle: const Text(
                'Choose Round and Exercise counts, preview the difficulty plan, review every draft, then explicitly approve insertion.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.readOnly ? null : _openGuidebookRoundGenerator,
            ),
            ListTile(
              key: const Key('lesson-preview-action'),
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Preview Lesson'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _previewLesson,
            ),
            ListTile(
              key: const Key('lesson-audit-action'),
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Audit Lesson'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _auditLesson,
            ),
            EditorInternalIdText(label: 'GuideBook', id: _lesson.guidebookId),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'lesson-section-picker-$_sectionPickerVersion-${_sectionName.text}',
                ),
                initialValue: _belongsToSection
                    ? 'name:${_sectionName.text}'
                    : 'none',
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Section',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'none',
                    child: Text('No section'),
                  ),
                  for (final name in {
                    ..._course.availableSectionNames,
                    if (_belongsToSection) _sectionName.text,
                  })
                    DropdownMenuItem(value: 'name:$name', child: Text(name)),
                  const DropdownMenuItem(
                    value: 'add',
                    child: Text('Add new section...'),
                  ),
                  const DropdownMenuItem(
                    value: 'manage',
                    child: Text('Manage sections...'),
                  ),
                ],
                onChanged: widget.readOnly ? null : _chooseSection,
              ),
            ),
            ListTile(
              key: const Key('lesson-theme-icon-field'),
              leading: SizedBox(
                width: 56,
                height: 56,
                child: _themeIconAsset == null
                    ? LessonFallbackIcon(
                        key: const Key('lesson-theme-icon-fallback-preview'),
                        number: _lessonNumber,
                        size: 52,
                      )
                    : _managedIcon(_themeIconAsset) != null
                    ? Image.memory(
                        base64Decode(_managedIcon(_themeIconAsset)!.base64Png),
                        key: const Key('lesson-theme-icon-preview'),
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        _themeIconAsset!,
                        key: const Key('lesson-theme-icon-preview'),
                        fit: BoxFit.contain,
                      ),
              ),
              title: const Text('Lesson theme icon'),
              subtitle: Text(
                _themeIconAsset == null
                    ? 'Fallback number icon'
                    : _managedIcon(_themeIconAsset) != null
                    ? 'Custom Course icon'
                    : LessonIconCatalog.options
                          .singleWhere(
                            (option) => option.assetPath == _themeIconAsset,
                          )
                          .label,
              ),
              trailing: const Icon(Icons.grid_view_outlined),
              onTap: widget.readOnly ? null : _chooseThemeIcon,
            ),
          ],
        ),
      ),
    );
  }
}

enum _GuidebookGeneratorStage { configure, plan, drafts }

class GuidebookRoundGeneratorScreen extends StatefulWidget {
  const GuidebookRoundGeneratorScreen({
    super.key,
    required this.course,
    required this.lesson,
    this.clock,
  });

  final Course course;
  final Lesson lesson;
  final DateTime Function()? clock;

  @override
  State<GuidebookRoundGeneratorScreen> createState() =>
      _GuidebookRoundGeneratorScreenState();
}

class _GuidebookRoundGeneratorScreenState
    extends State<GuidebookRoundGeneratorScreen> {
  final _roundCount = TextEditingController(
    text: '${GuidebookRoundGenerator.defaultRoundCount}',
  );
  final _exerciseCount = TextEditingController(
    text: '${GuidebookRoundGenerator.defaultExercisesPerRound}',
  );
  final _finalIds = TimestampAuthoringIdGenerator();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  _GuidebookGeneratorStage _stage = _GuidebookGeneratorStage.configure;
  GuidebookGenerationPlan? _plan;
  List<LearningRound> _drafts = const [];
  int _seed = 0;

  @override
  void dispose() {
    _roundCount.dispose();
    _exerciseCount.dispose();
    super.dispose();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(duration: const Duration(seconds: 8), content: Text(text)),
  );

  GuidebookRoundGenerator _generator() => GuidebookRoundGenerator(
    randomSeed: _seed,
    draftIds: TimestampAuthoringIdGenerator(),
    now: _clock,
  );

  void _preparePlan({bool regenerate = false}) {
    if (regenerate) _seed++;
    final rounds = int.tryParse(_roundCount.text.trim());
    final exercises = int.tryParse(_exerciseCount.text.trim());
    if (rounds == null || exercises == null) {
      _message('Enter positive whole numbers for both counts.');
      return;
    }
    try {
      final plan = _generator().plan(
        widget.lesson.guidebook,
        roundCount: rounds,
        exercisesPerRound: exercises,
      );
      setState(() {
        _plan = plan;
        _stage = _GuidebookGeneratorStage.plan;
      });
    } on ArgumentError catch (error) {
      _message(error.message?.toString() ?? error.toString());
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  void _generateDrafts() {
    try {
      final drafts = _generator().createDrafts(widget.lesson.guidebook, _plan!);
      setState(() {
        _drafts = drafts;
        _stage = _GuidebookGeneratorStage.drafts;
      });
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  void _regenerateDrafts() {
    _seed++;
    try {
      final plan = _generator().plan(
        widget.lesson.guidebook,
        roundCount: _plan!.roundCount,
        exercisesPerRound: _plan!.exercisesPerRound,
      );
      final drafts = _generator().createDrafts(widget.lesson.guidebook, plan);
      setState(() {
        _plan = plan;
        _drafts = drafts;
      });
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  Lesson get _draftLesson => Lesson(
    lessonId: widget.lesson.lessonId,
    publicationState: widget.lesson.publicationState,
    provisionalDraft: widget.lesson.provisionalDraft,
    updatedAt: widget.lesson.updatedAt,
    title: widget.lesson.title,
    rounds: [...widget.lesson.rounds, ..._drafts],
    section: widget.lesson.section,
    sectionName: widget.lesson.sectionName,
    themeIconAsset: widget.lesson.themeIconAsset,
    guidebook: widget.lesson.guidebook,
    duel: widget.lesson.duel,
  );

  Future<void> _editDraft(int index) async {
    final updated = await Navigator.of(context).push<LearningRound>(
      MaterialPageRoute(
        builder: (_) => RoundEditorScreen(
          course: widget.course,
          lesson: _draftLesson,
          round: _drafts[index],
          roundIndex: widget.lesson.rounds.length + index,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _drafts = [..._drafts]..[index] = updated);
    }
  }

  Future<void> _previewDraft(int index) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => RoundScreen(
        course: widget.course,
        lesson: _draftLesson,
        round: _drafts[index],
        ttsLanguage: CourseLanguageResolver.learning(widget.course).code ?? '',
        roundIndex: widget.lesson.rounds.length + index,
        previewMode: true,
      ),
    ),
  );

  List<CourseAuditIssue> _issues() => [
    for (var roundIndex = 0; roundIndex < _drafts.length; roundIndex++)
      for (final round in [_drafts[roundIndex]])
        for (final exercise in round.exercises)
          ...CourseAuditService().auditExercise(
            exercise,
            location: '${round.displayTitle(roundIndex)} · ${exercise.type}',
            roundId: round.id,
          ),
  ];

  void _approve() {
    final errors = _issues()
        .where((issue) => issue.severity == AuditSeverity.error)
        .toList();
    if (errors.isNotEmpty) {
      _message(
        'Fix ${errors.length} generated Exercise error${errors.length == 1 ? '' : 's'} before approval.',
      );
      return;
    }
    final duplication = AuthoringDuplicationService(ids: _finalIds);
    final approved = [
      for (final draft in _drafts) duplication.duplicateRound(draft),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, approved);
    });
  }

  Future<void> _attemptLeaveGenerator() async {
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('GuideBook Round Generator'),
      content: const SingleChildScrollView(
        child: Text(
          'The current Lesson GuideBook is the only source. Choose the number of Rounds and Exercises per Round. The plan increases production demand and reduces scaffolding across the selected Round count. Generated material remains draft: review, edit or delete every Round and Exercise before explicit approval. Generation can assist authoring but cannot guarantee pedagogical correctness.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Widget _configure() {
    final rounds = int.tryParse(_roundCount.text.trim()) ?? 0;
    final exercises = int.tryParse(_exerciseCount.text.trim()) ?? 0;
    return ListView(
      key: const Key('guidebook-generator-configure'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Generation uses only the current Lesson GuideBook. Nothing is created while configuring or previewing the plan.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('generator-round-count'),
          controller: _roundCount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Number of Rounds',
            helperText: 'Choose 1–12. Default: 6.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('generator-exercise-count'),
          controller: _exerciseCount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Exercises per Round',
            helperText: 'Choose 1–15. Default: 8.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$rounds Rounds × $exercises exercises = ${rounds * exercises} exercises',
          key: const Key('generator-total'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('generator-review-plan'),
          onPressed: _preparePlan,
          child: const Text('Review generation plan'),
        ),
      ],
    );
  }

  Widget _reviewPlan() {
    final distribution = _plan!.presetDistribution.entries.toList();
    return ListView(
      key: const Key('guidebook-generator-plan'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_plan!.roundCount} Rounds × ${_plan!.exercisesPerRound} exercises = ${_plan!.totalExercises} exercises',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Difficulty rises from guided recognition and comprehension through construction and context to freer production. The plan contains no final Round or Exercise objects.',
        ),
        const SizedBox(height: 12),
        for (final round in _plan!.rounds)
          ListTile(
            dense: true,
            leading: CircleAvatar(child: Text('${round.index + 1}')),
            title: Text(round.title),
            subtitle: Text(
              'Difficulty ${(round.difficulty * 100).round()}% · ${round.presetIds.map((id) => ExercisePresetRegistry.byId(id)!.name).join(', ')}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Planned preset distribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final entry in distribution)
          Text(
            '• ${ExercisePresetRegistry.byId(entry.key)!.name}: ${entry.value}',
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _stage = _GuidebookGeneratorStage.configure),
              child: const Text('Back'),
            ),
            TextButton(
              key: const Key('generator-cancel'),
              onPressed: _attemptLeaveGenerator,
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              key: const Key('generator-recalculate'),
              onPressed: () => _preparePlan(regenerate: true),
              child: const Text('Recalculate'),
            ),
            FilledButton(
              key: const Key('generator-generate'),
              onPressed: _generateDrafts,
              child: const Text('Generate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewDrafts() {
    final issues = _issues();
    final errors = issues
        .where((issue) => issue.severity == AuditSeverity.error)
        .length;
    return ListView(
      key: const Key('guidebook-generator-drafts'),
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Generated Rounds are drafts. Review and edit them before approval; existing Rounds will remain untouched and approved drafts will be appended.',
        ),
        const SizedBox(height: 8),
        Text(
          'Automatic audit: $errors errors · ${issues.length - errors} other findings',
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _drafts.length; index++)
          Card(
            key: ValueKey('generated-draft-${_drafts[index].id}'),
            child: ListTile(
              title: Text(_drafts[index].title),
              subtitle: Text('${_drafts[index].exercises.length} exercises'),
              onTap: () => _editDraft(index),
              trailing: PopupMenuButton<String>(
                key: ValueKey('generated-round-actions-${_drafts[index].id}'),
                onSelected: (value) {
                  if (value == 'edit') _editDraft(index);
                  if (value == 'preview') _previewDraft(index);
                  if (value == 'delete') {
                    setState(() => _drafts = [..._drafts]..removeAt(index));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'preview', child: Text('Preview')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _stage = _GuidebookGeneratorStage.plan),
              child: const Text('Back'),
            ),
            TextButton(
              key: const Key('generator-cancel'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              key: const Key('generator-regenerate'),
              onPressed: _regenerateDrafts,
              child: const Text('Regenerate'),
            ),
            FilledButton(
              key: const Key('generator-approve'),
              onPressed: _drafts.isEmpty || errors > 0 ? null : _approve,
              child: const Text('Approve and add Rounds'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: true,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _attemptLeaveGenerator();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Generate Rounds from GuideBook'),
        actions: [
          IconButton(
            tooltip: 'Generator Help',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: switch (_stage) {
        _GuidebookGeneratorStage.configure => _configure(),
        _GuidebookGeneratorStage.plan => _reviewPlan(),
        _GuidebookGeneratorStage.drafts => _reviewDrafts(),
      },
    ),
  );
}

class LessonRoundsScreen extends StatefulWidget {
  final Course course;
  final ValueChanged<Course>? onCourseChanged;
  final Lesson lesson;
  final DateTime Function()? clock;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;

  const LessonRoundsScreen({
    super.key,
    required this.course,
    this.onCourseChanged,
    required this.lesson,
    this.clock,
    this.readOnly = false,
    this.courseEditorMode = CourseEditorMode.edit,
  });

  @override
  State<LessonRoundsScreen> createState() => _LessonRoundsScreenState();
}

class _LessonRoundsScreenState extends State<LessonRoundsScreen> {
  late Course _course;
  final _ids = TimestampAuthoringIdGenerator();
  late List<LearningRound> _rounds;
  bool _routeMayPop = false;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _rounds = [...widget.lesson.rounds];
    // Adopt pending Lesson metadata once. Child callbacks thereafter own the
    // current canonical state, including first-Save publication reconciliation.
    _course = Course.fromJson({
      ..._course.toJson(),
      'lessons': [
        for (final lesson in _course.lessons)
          (lesson.lessonId == widget.lesson.lessonId ? widget.lesson : lesson)
              .toJson(),
      ],
    });
  }

  Lesson get _currentLesson => _course.lessons.firstWhere(
    (lesson) => lesson.lessonId == widget.lesson.lessonId,
    orElse: () => widget.lesson,
  );

  Course get _auditableCourse {
    final lessons = [..._course.lessons];
    final index = lessons.indexWhere(
      (lesson) => lesson.lessonId == widget.lesson.lessonId,
    );
    if (index >= 0) lessons[index] = _draftLesson;
    return Course.fromJson({
      ..._course.toJson(),
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    });
  }

  void _adoptCourse(Course course) {
    if (!mounted) return;
    course = const ProvisionalPublicationService().reconcile(
      course,
      updatedAt: _clock(),
      previous: _course,
    );
    setState(() {
      _course = course;
      _rounds = [
        ...course.lessons
            .firstWhere((l) => l.lessonId == widget.lesson.lessonId)
            .rounds,
      ];
    });
    widget.onCourseChanged?.call(course);
  }

  Course _courseWithRounds(List<LearningRound> rounds) {
    final lessons = [..._course.lessons];
    final index = lessons.indexWhere(
      (lesson) => lesson.lessonId == widget.lesson.lessonId,
    );
    if (index < 0) return _course;
    lessons[index] = Lesson.fromJson({
      ...lessons[index].toJson(),
      'rounds': rounds.map((round) => round.toJson()).toList(),
    });
    return Course.fromJson({
      ..._course.toJson(),
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    });
  }

  Future<void> _transferRound(int index, {required bool copy}) async {
    if (widget.readOnly) return;
    final source = _rounds[index];
    final course = _auditableCourse;
    final destination = await chooseAuthoringDestination(
      context,
      course: course,
      exercise: false,
      copy: copy,
      sourceLessonId: widget.lesson.lessonId,
    );
    if (destination == null || !mounted) return;
    final service = CourseAuthoringTransferService(clock: _clock);
    try {
      _adoptCourse(
        copy
            ? service.copyRound(
                course,
                sourceLessonId: widget.lesson.lessonId,
                roundId: source.id,
                destinationLessonId: destination.lessonId,
              )
            : service.moveRound(
                course,
                sourceLessonId: widget.lesson.lessonId,
                roundId: source.id,
                destinationLessonId: destination.lessonId,
              ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _updateRounds(List<LearningRound> rounds) {
    if (widget.readOnly) return;
    _adoptCourse(_courseWithRounds(rounds));
  }

  LearningRound _blankRound(String title) {
    final updatedAt = _clock();
    return LearningRound(
      id: _ids.next('round'),
      publicationState: PublicationState.draft,
      provisionalDraft: true,
      updatedAt: updatedAt,
      title: title,
      content: [
        NewCourseStructure.sampleExercise(
          _ids,
          sourceLanguage: _course.sourceLanguage,
          learningLanguage: _course.learningLanguage,
          updatedAt: updatedAt,
        ),
      ],
    );
  }

  Future<String?> _name(
    String title, {
    String initial = '',
    bool allowEmpty = false,
  }) async {
    var edited = initial;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          onChanged: (value) => edited = value,
          autofocus: true,
          onFieldSubmitted: (value) => Navigator.pop(
            context,
            value.trim().isEmpty && initial.trim().isNotEmpty
                ? initial.trim()
                : value.trim(),
          ),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: allowEmpty ? 'Title, or Enter to skip' : 'Title',
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
    if (value == null) return null;
    return value.trim().isEmpty && !allowEmpty ? null : value.trim();
  }

  Future<void> _add() async {
    if (widget.readOnly) return;
    final title = await _name('New round', allowEmpty: true);
    if (title != null && mounted) {
      _updateRounds([..._rounds, _blankRound(title)]);
    }
  }

  Lesson get _draftLesson => Lesson.fromJson({
    ..._currentLesson.toJson(),
    'rounds': _rounds.map((round) => round.toJson()).toList(),
  });

  Future<void> _open(int index) async {
    final updated = await Navigator.of(context).push<LearningRound>(
      MaterialPageRoute(
        builder: (_) => RoundEditorScreen(
          course: _auditableCourse,
          onCourseChanged: _adoptCourse,
          linkParent: true,
          lesson: _draftLesson,
          round: _rounds[index],
          roundIndex: index,
          clock: _clock,
          readOnly: widget.readOnly,
          courseEditorMode: widget.courseEditorMode,
        ),
      ),
    );
    if (!widget.readOnly && updated != null && mounted) {
      final currentIndex = _rounds.indexWhere(
        (round) => round.id == updated.id,
      );
      if (currentIndex < 0) return;
      final rounds = [..._rounds]..[currentIndex] = updated;
      _updateRounds(rounds);
    }
  }

  Future<void> _renameRound(int index) async {
    if (widget.readOnly) return;
    final source = _rounds[index];
    final title = await _name(
      'Rename Round',
      initial: source.title,
      allowEmpty: true,
    );
    if (title == null || !mounted) return;
    final rounds = [..._rounds];
    rounds[index] = LearningRound(
      id: source.id,
      publicationState: source.publicationState,
      provisionalDraft: source.provisionalDraft,
      updatedAt: _clock(),
      title: title,
      visualType: source.visualType,
      content: source.content,
    );
    _updateRounds(rounds);
  }

  void _duplicateRound(int index) {
    if (widget.readOnly) return;
    final duplicate = AuthoringDuplicationService(
      ids: _ids,
    ).duplicateRound(_rounds[index]);
    _updateRounds([..._rounds]..insert(index + 1, duplicate));
  }

  Future<void> _previewRound(int index) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => RoundScreen(
        course: _course,
        lesson: _draftLesson,
        round: _rounds[index],
        ttsLanguage: CourseLanguageResolver.learning(_course).code ?? '',
        roundIndex: index,
        previewMode: true,
      ),
    ),
  );

  Future<void> _auditRound(int index) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) {
        final course = _auditableCourse;
        return CourseAuditScreen(
          course: course,
          result: CourseAuditService().auditRound(course, _rounds[index].id),
          title: 'Round Audit',
        );
      },
    ),
  );

  Future<void> _setRoundPublication(int index, PublicationState state) async {
    if (widget.readOnly) return;
    final source = _rounds[index];
    if (!state.isPublished && source.publicationState.isPublished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move Round to Draft?'),
          content: const Text(
            'This Round will disappear from the learner path. Existing learner progress and XP will be preserved.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save as draft'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    final changed = LearningRound.fromJson({
      ...source.toJson(),
      'publicationState': state.name,
      'provisionalDraft': false,
      'updatedAt': _clock().toUtc().toIso8601String(),
    });
    final rounds = [..._rounds]..[index] = changed;
    if (state.isPublished) {
      final lessonJson = {
        ..._draftLesson.toJson(),
        'publicationState': PublicationState.published.name,
        'rounds': rounds.map((round) => round.toJson()).toList(),
      };
      final courseJson = {
        ..._course.toJson(),
        'publicationState': PublicationState.published.name,
        'lessons': [
          for (final lesson in _course.lessons)
            (lesson.lessonId == widget.lesson.lessonId
                    ? Lesson.fromJson(lessonJson)
                    : lesson)
                .toJson(),
        ],
      };
      final authored = Course.fromJson(courseJson);
      final visible = const PublicationService().learnerCourse(authored)!;
      final errors = CourseAuditService()
          .auditRound(visible, changed.id, sourceReferenceCourse: authored)
          .issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .length;
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round cannot be saved as normal content: $errors blocking error${errors == 1 ? '' : 's'}.',
            ),
          ),
        );
        return;
      }
    }
    if (mounted) _updateRounds(rounds);
  }

  Future<void> _remove(int index) async {
    if (widget.readOnly) return;
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
    _updateRounds([..._rounds]..removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (widget.readOnly) return;
    final rounds = [..._rounds];
    final round = rounds.removeAt(oldIndex);
    rounds.insert(newIndex, round);
    _updateRounds(rounds);
  }

  Future<void> _returnToLesson() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _rounds);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<ExerciseSearchResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorSearchScreen(
          course: _auditableCourse,
          scope: ExerciseSearchScope.lesson,
          lessonId: widget.lesson.lessonId,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final changed = await _openSearchResult(
      context,
      course: _auditableCourse,
      result: result,
      readOnly: widget.readOnly,
      initiallyInspecting:
          widget.courseEditorMode == CourseEditorMode.inspection,
      clock: _clock,
    );
    if (changed != null && mounted) _adoptCourse(changed);
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(
      _auditableCourse,
    );
    final lessonIndex = _course.lessons.indexWhere(
      (lesson) => lesson.lessonId == widget.lesson.lessonId,
    );
    final lessonLabel = lessonIndex < 0
        ? widget.lesson.title
        : const LessonPresentationService()
              .identity(_course, lessonIndex)
              .fullText;
    return PopScope<List<LearningRound>>(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToLesson();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Rounds · $lessonLabel'),
          actions: [
            IconButton(
              key: const Key('rounds-search-action'),
              tooltip: 'Search this Lesson',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
            const EditorAppBarActions(),
          ],
        ),
        floatingActionButton: widget.readOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('New round'),
              ),
        body: ReorderableListView.builder(
          key: const Key('lesson-rounds-list'),
          header: Column(
            children: [
              EditorBreadcrumbs(
                course: _auditableCourse,
                lessonId: widget.lesson.lessonId,
              ),
              EditorInternalIdText(label: 'Lesson', id: widget.lesson.lessonId),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
          itemCount: _rounds.length,
          onReorderItem: _reorder,
          itemBuilder: (context, index) {
            final round = _rounds[index];
            return AuthoringStatusCard(
              key: ValueKey(round.id),
              indicatorKey: ValueKey('round-status-indicator-${round.id}'),
              draftIndicatorKey: ValueKey('round-draft-indicator-${round.id}'),
              hasDraft: hierarchyStatus.roundHasDraft(round),
              hasAuditConcern: hierarchyStatus.roundHasAuditConcern(round),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    key: ValueKey('round-entry-${round.id}'),
                    leading: ReorderableDragStartListener(
                      index: index,
                      enabled: !widget.readOnly,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(round.displayTitle(index)),
                    subtitle: Text(_exerciseCountLabel(round.exercises.length)),
                    onTap: () => _open(index),
                    trailing: PopupMenuButton<String>(
                      key: ValueKey('round-actions-${round.id}'),
                      onSelected: (value) {
                        if (value == 'edit') _open(index);
                        if (value == 'rename') _renameRound(index);
                        if (value == 'delete') _remove(index);
                        if (value == 'duplicate') _duplicateRound(index);
                        if (value == 'move_to') {
                          _transferRound(index, copy: false);
                        }
                        if (value == 'copy_to') {
                          _transferRound(index, copy: true);
                        }
                        if (value == 'preview') _previewRound(index);
                        if (value == 'audit') _auditRound(index);
                        if (value == 'publication') {
                          _setRoundPublication(
                            index,
                            round.publicationState.isPublished
                                ? PublicationState.draft
                                : PublicationState.published,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(widget.readOnly ? 'View' : 'Edit'),
                        ),
                        PopupMenuItem(
                          value: 'rename',
                          enabled: !widget.readOnly,
                          child: const Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !widget.readOnly,
                          child: const Text('Delete'),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          enabled: !widget.readOnly,
                          child: const Text('Duplicate'),
                        ),
                        PopupMenuItem(
                          value: 'move_to',
                          enabled: !widget.readOnly,
                          child: const Text('Move to…'),
                        ),
                        PopupMenuItem(
                          value: 'copy_to',
                          enabled: !widget.readOnly,
                          child: const Text('Copy to…'),
                        ),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Text('Preview'),
                        ),
                        const PopupMenuItem(
                          value: 'audit',
                          child: Text('Audit'),
                        ),
                        PopupMenuItem(
                          value: 'publication',
                          enabled: !widget.readOnly,
                          child: Text(
                            round.publicationState.isPublished
                                ? 'Save as draft'
                                : 'Save',
                          ),
                        ),
                      ],
                    ),
                  ),
                  EditorInternalIdText(
                    label: 'Round',
                    id: round.id,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class RoundEditorScreen extends StatefulWidget {
  final Course course;
  final ValueChanged<Course>? onCourseChanged;
  final Lesson lesson;
  final LearningRound round;
  final int roundIndex;
  final DateTime Function()? clock;
  final bool linkParent;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;
  const RoundEditorScreen({
    super.key,
    required this.course,
    this.onCourseChanged,
    required this.lesson,
    required this.round,
    required this.roundIndex,
    this.clock,
    this.linkParent = false,
    this.readOnly = false,
    this.courseEditorMode = CourseEditorMode.edit,
  });
  @override
  State<RoundEditorScreen> createState() => _RoundEditorScreenState();
}

class _RoundEditorScreenState extends State<RoundEditorScreen> {
  late Course _course;
  late Lesson _lesson;
  final _ids = TimestampAuthoringIdGenerator();
  late List<Exercise> _exercises;
  late List<LearningContent> _originalContent;
  late String _title;
  late DateTime _updatedAt;
  late PublicationState _publicationState;
  late bool _provisionalDraft;
  bool _routeMayPop = false;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _lesson = widget.lesson;
    _exercises = [...widget.round.exercises];
    _originalContent = [...widget.round.content];
    _title = widget.round.title;
    _updatedAt = widget.round.updatedAt;
    _publicationState = widget.round.publicationState;
    _provisionalDraft = widget.round.provisionalDraft;
  }

  LearningRound _editedRound({
    PublicationState? publicationState,
    DateTime? updatedAt,
  }) => LearningRound(
    id: widget.round.id,
    publicationState: publicationState ?? _publicationState,
    provisionalDraft: publicationState == null ? _provisionalDraft : false,
    updatedAt: updatedAt ?? _updatedAt,
    title: _title,
    visualType: widget.round.visualType,
    content: _editedContent(),
  );

  List<LearningContent> _editedContent() {
    // Keep non-runnable metadata slots in place while honoring the current
    // runnable Exercise order. Each text/presentation slot is emitted once.
    final pending = _exercises.iterator;
    final content = <LearningContent>[];
    for (final original in _originalContent) {
      if (original.role == 'lesson_intro' ||
          original.asRunnableExercise() == null) {
        content.add(original);
      } else if (pending.moveNext()) {
        content.add(_contentForEditedExercise(pending.current));
      }
    }
    while (pending.moveNext()) {
      content.add(_contentForEditedExercise(pending.current));
    }
    return content;
  }

  Future<void> _returnToRounds() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      Navigator.pop(context, widget.readOnly ? widget.round : _editedRound());
    }
  }

  LearningContent _contentForEditedExercise(Exercise exercise) {
    final source = _originalContent
        .where((item) => item.id == exercise.id)
        .firstOrNull;
    if (source == null) return LearningContent.fromExercise(exercise);
    final original = source.asRunnableExercise();
    if (source.publicationState == exercise.publicationState &&
        original != null &&
        _sameAuthoringJson(original.toJson(), exercise.toJson())) {
      return source;
    }
    return _replaceLearningContentExercise(source, exercise);
  }

  Future<void> _saveRound(PublicationState state) async {
    if (widget.readOnly) return;
    if (!state.isPublished &&
        _publicationState.isPublished &&
        !await _confirmMoveToDraft(context, 'Round')) {
      return;
    }
    final candidate = _editedRound(publicationState: state);
    final edited = _sameAuthoringJson(candidate.toJson(), widget.round.toJson())
        ? candidate
        : _editedRound(publicationState: state, updatedAt: _clock());
    if (state.isPublished) {
      final lessonJson = _lesson.toJson();
      lessonJson['publicationState'] = PublicationState.published.name;
      lessonJson['rounds'] = [
        for (final round in _lesson.rounds)
          (round.id == edited.id ? edited : round).toJson(),
      ];
      final courseJson = _course.toJson();
      courseJson['publicationState'] = PublicationState.published.name;
      courseJson['lessons'] = [
        for (final lesson in _course.lessons)
          (lesson.lessonId == _lesson.lessonId
                  ? Lesson.fromJson(lessonJson)
                  : lesson)
              .toJson(),
      ];
      final authored = Course.fromJson(courseJson);
      final visible = const PublicationService().learnerCourse(authored)!;
      final errors = CourseAuditService()
          .auditRound(visible, edited.id, sourceReferenceCourse: authored)
          .issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .length;
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round cannot be saved as normal content: $errors blocking error${errors == 1 ? '' : 's'}.',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    _mutateRound(() {
      _publicationState = edited.publicationState;
      _provisionalDraft = edited.provisionalDraft;
      _updatedAt = edited.updatedAt;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _editedRound());
  }

  Future<void> _setExercisePublication(
    int index,
    PublicationState state,
  ) async {
    if (widget.readOnly) return;
    final source = _exercises[index];
    if (!state.isPublished && source.publicationState.isPublished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move Exercise to Draft?'),
          content: const Text(
            'This Exercise will disappear from the learner Round. Existing learner progress and XP will be preserved.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save as draft'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    final changed = _withExercisePublication(
      source,
      state,
      updatedAt: _clock(),
    );
    if (state.isPublished &&
        CourseAuditService()
            .auditExercise(changed)
            .any((issue) => issue.severity == AuditSeverity.error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Exercise cannot be saved as normal content until its Errors are fixed.',
          ),
        ),
      );
      return;
    }
    _mutateRound(() => _exercises[index] = changed);
  }

  String _summary(Exercise e) => e.prompt.trim().isNotEmpty
      ? e.prompt.trim()
      : e.question.trim().isNotEmpty
      ? e.question.trim()
      : (e.tts ?? e.id);

  Course get _workingCourse => Course.fromJson({
    ..._course.toJson(),
    'lessons': [
      for (final lesson in _course.lessons)
        if (lesson.lessonId == _lesson.lessonId)
          {
            ..._lesson.toJson(),
            'rounds': [
              for (final round in _lesson.rounds)
                (round.id == widget.round.id ? _editedRound() : round).toJson(),
            ],
          }
        else
          lesson.toJson(),
    ],
  });

  void _mutateRound(VoidCallback mutation) {
    if (!mounted) return;
    late Course course;
    // The working copy before this change lets a parent Draft be promoted when
    // its last Draft child is saved as Published.
    final before = _workingCourse;
    setState(() {
      mutation();
      course = const ProvisionalPublicationService().reconcile(
        _workingCourse,
        updatedAt: _clock(),
        previous: before,
      );
      _course = course;
      _lesson = course.lessons.firstWhere(
        (lesson) => lesson.lessonId == _lesson.lessonId,
      );
      final round = _lesson.rounds.firstWhere(
        (round) => round.id == widget.round.id,
        orElse: _editedRound,
      );
      _publicationState = round.publicationState;
      _provisionalDraft = round.provisionalDraft;
      _updatedAt = round.updatedAt;
    });
    widget.onCourseChanged?.call(course);
  }

  bool get _canTransfer =>
      widget.onCourseChanged != null &&
      _course.lessons.any(
        (lesson) =>
            lesson.lessonId == _lesson.lessonId &&
            lesson.rounds.any((round) => round.id == widget.round.id),
      );

  void _acceptExercise(Exercise exercise) {
    if (widget.readOnly) return;
    final index = _exercises.indexWhere((value) => value.id == exercise.id);
    _mutateRound(() {
      if (index < 0) {
        _exercises.add(exercise);
      } else {
        _exercises[index] = exercise;
      }
    });
  }

  Future<void> _edit(int i) async {
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          exercise: _exercises[i],
          title: 'Edit exercise ${i + 1}',
          isNew: false,
          course: _workingCourse,
          lesson: _lesson,
          round: _editedRound(),
          onExerciseSaved: widget.readOnly ? null : _acceptExercise,
          linkParent: true,
          clock: _clock,
          readOnly: widget.readOnly,
          initiallyInspecting:
              widget.courseEditorMode == CourseEditorMode.inspection,
        ),
      ),
    );
    if (e != null && mounted) _acceptExercise(e);
  }

  Future<void> _insert() async {
    if (widget.readOnly) return;
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          exercise: _blankExerciseForPreset(TranslationChoice.toTarget, _ids),
          title: 'New exercise',
          isNew: true,
          course: _workingCourse,
          lesson: _lesson,
          round: _editedRound(),
          onExerciseSaved: _acceptExercise,
          linkParent: true,
          clock: _clock,
        ),
      ),
    );
    if (e == null || !mounted) return;
    if (!_exercises.any((item) => item.id == e.id)) {
      _mutateRound(() => _exercises.add(e));
    }
    _warnLength();
  }

  Future<void> _openCreationWizard() async {
    if (widget.readOnly) return;
    final created = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => ExerciseCreationWizardScreen(
          course: _course,
          lesson: _lesson,
          round: _editedRound(),
          roundIndex: widget.roundIndex,
        ),
      ),
    );
    if (created == null || created.isEmpty || !mounted) return;
    _mutateRound(() => _exercises.addAll(created));
    _warnLength();
  }

  void _duplicateExercise(int index) {
    if (widget.readOnly) return;
    final duplicate = AuthoringDuplicationService(
      ids: _ids,
    ).duplicateExercise(_exercises[index]);
    _mutateRound(() => _exercises.insert(index + 1, duplicate));
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

  Future<void> _transferExercise(int index, {required bool copy}) async {
    if (widget.readOnly) return;
    if (!_canTransfer) return;
    final course = _workingCourse;
    final source = _exercises[index];
    final destination = await chooseAuthoringDestination(
      context,
      course: course,
      exercise: true,
      copy: copy,
      sourceLessonId: _lesson.lessonId,
      sourceRoundId: widget.round.id,
    );
    if (destination == null || !mounted) return;
    final service = CourseAuthoringTransferService(clock: _clock);
    try {
      final transferred = copy
          ? service.copyExercise(
              course,
              sourceLessonId: _lesson.lessonId,
              sourceRoundId: widget.round.id,
              exerciseId: source.id,
              destinationLessonId: destination.lessonId,
              destinationRoundId: destination.roundId!,
            )
          : service.moveExercise(
              course,
              sourceLessonId: _lesson.lessonId,
              sourceRoundId: widget.round.id,
              exerciseId: source.id,
              destinationLessonId: destination.lessonId,
              destinationRoundId: destination.roundId!,
            );
      final updated = const ProvisionalPublicationService().reconcile(
        transferred,
        updatedAt: _clock(),
      );
      setState(() {
        _course = updated;
        _lesson = updated.lessons.firstWhere(
          (lesson) => lesson.lessonId == _lesson.lessonId,
        );
        final round = _lesson.rounds.firstWhere(
          (round) => round.id == widget.round.id,
        );
        _exercises = [...round.exercises];
        _originalContent = [...round.content];
        _updatedAt = round.updatedAt;
        _publicationState = round.publicationState;
        _provisionalDraft = round.provisionalDraft;
      });
      widget.onCourseChanged?.call(updated);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _delete(int i) async {
    if (widget.readOnly) return;
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
    if (ok && mounted) _mutateRound(() => _exercises.removeAt(i));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (widget.readOnly) return;
    // onReorderItem supplies the insertion index after the item was removed.
    _mutateRound(() {
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Future<void> _rename() async {
    if (widget.readOnly) return;
    final c = TextEditingController(text: _title);
    final n = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Round'),
        content: TextField(
          controller: c,
          onSubmitted: (value) => Navigator.pop(
            ctx,
            value.trim().isEmpty && _title.trim().isNotEmpty
                ? _title.trim()
                : value.trim(),
          ),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title, or Enter to skip',
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
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    if (n != null && mounted) {
      _mutateRound(() => _title = n.trim());
    }
  }

  Future<void> _generateFromReading(int index) async {
    if (widget.readOnly) return;
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
      _mutateRound(() => _exercises.insertAll(index + 1, generated));
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
    final updatedAt = _clock();
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
            publicationState: PublicationState.draft,
            updatedAt: updatedAt,
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
          publicationState: PublicationState.draft,
          updatedAt: updatedAt,
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
          publicationState: PublicationState.draft,
          updatedAt: updatedAt,
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
              publicationState: PublicationState.draft,
              updatedAt: updatedAt,
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
              publicationState: PublicationState.draft,
              updatedAt: updatedAt,
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
    for (final lesson in _course.lessons) {
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
      _course.sourceLanguage.toLowerCase().startsWith('spanish')
      ? spanish
      : english;
  String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-zà-öø-ÿ0-9]+'), ' ').trim();
  Map<String, String> _knownTranslationPairs() {
    final result = <String, String>{};
    for (final lesson in _course.lessons) {
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
          course: _course,
          lesson: _lesson,
          round: preview,
          ttsLanguage: CourseLanguageResolver.learning(_course).code ?? '',
          roundIndex: widget.roundIndex,
          previewMode: true,
        ),
      ),
    );
  }

  Future<void> _previewExercise(int index) async {
    final preview = LearningRound(
      id: 'preview_${widget.round.id}',
      publicationState: PublicationState.draft,
      updatedAt: _clock(),
      title: 'Preview exercise',
      visualType: widget.round.visualType,
      exercises: [_exercises[index]],
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: _course,
          lesson: _lesson,
          round: preview,
          ttsLanguage: CourseLanguageResolver.learning(_course).code ?? '',
          roundIndex: widget.roundIndex,
          previewMode: true,
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<ExerciseSearchResult>(
      MaterialPageRoute(
        builder: (_) => CourseEditorSearchScreen(
          course: _workingCourse,
          scope: ExerciseSearchScope.round,
          lessonId: _lesson.lessonId,
          roundId: widget.round.id,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final changed = await _openSearchResult(
      context,
      course: _workingCourse,
      result: result,
      readOnly: widget.readOnly,
      initiallyInspecting:
          widget.courseEditorMode == CourseEditorMode.inspection,
      clock: _clock,
    );
    if (changed == null || !mounted) return;
    final lesson = changed.lessons.firstWhere(
      (candidate) => candidate.lessonId == _lesson.lessonId,
    );
    final round = lesson.rounds.firstWhere(
      (candidate) => candidate.id == widget.round.id,
    );
    setState(() {
      _course = changed;
      _lesson = lesson;
      _exercises = [...round.exercises];
      _originalContent = [...round.content];
      _title = round.title;
      _updatedAt = round.updatedAt;
      _publicationState = round.publicationState;
      _provisionalDraft = round.provisionalDraft;
    });
    widget.onCourseChanged?.call(changed);
  }

  Future<void> _auditRound() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CourseAuditScreen(
        course: _workingCourse,
        result: CourseAuditService().auditRound(
          _workingCourse,
          widget.round.id,
        ),
        title: 'Round Audit',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(_workingCourse);
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToRounds();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _returnToRounds),
          title: Text(
            _title.isEmpty ? 'Round ${widget.roundIndex + 1}' : _title,
          ),
          actions: [
            IconButton(
              key: const Key('round-search-action'),
              tooltip: 'Search this Round',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
            const EditorAppBarActions(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('round-preview'),
                  onPressed: _exercises.isEmpty ? null : _previewRound,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Preview'),
                ),
                if (!_publicationState.isPublished)
                  _DraftBranchIndicator(
                    key: const Key('round-own-draft-indicator'),
                    message: _provisionalDraft
                        ? 'This new Round is Draft until its required content is complete and saved. It then becomes non-Draft automatically. Save as draft keeps the Round Draft until you explicitly Save it.'
                        : 'This Round is Draft and hidden from learner delivery, even when its Exercises are Published. Use Save to publish the Round.',
                  ),
                if (!widget.readOnly) ...[
                  OutlinedButton(
                    key: const Key('round-save-draft'),
                    onPressed: () => _saveRound(PublicationState.draft),
                    child: const Text('Save as draft'),
                  ),
                  FilledButton(
                    key: const Key('round-save'),
                    onPressed: () => _saveRound(PublicationState.published),
                    child: const Text('Save'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('new-exercise'),
                    onPressed: _insert,
                    icon: const Icon(Icons.add),
                    label: const Text('New exercise'),
                  ),
                  FilledButton.icon(
                    key: const Key('exercise-creation-wizard'),
                    onPressed: _openCreationWizard,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Creation Wizard'),
                  ),
                ],
              ],
            ),
          ),
        ),
        body: ReorderableListView.builder(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorBreadcrumbs(
                course: _workingCourse,
                lessonId: _lesson.lessonId,
                roundId: widget.round.id,
                onParent: widget.linkParent ? _returnToRounds : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: EditorInternalIdText(
                  label: 'Round',
                  id: widget.round.id,
                ),
              ),
              ListTile(
                key: const Key('round-rename-action'),
                leading: const Icon(Icons.title),
                title: const Text('Rename Round'),
                subtitle: Text(
                  _title.trim().isEmpty ? 'No custom title' : _title,
                ),
                trailing: Icon(
                  widget.readOnly
                      ? Icons.visibility_outlined
                      : Icons.edit_outlined,
                ),
                onTap: widget.readOnly ? null : _rename,
              ),
              ListTile(
                key: const Key('round-audit-action'),
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Audit Round'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _auditRound,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          itemCount: _exercises.length,
          onReorderItem: _reorder,
          itemBuilder: (context, i) {
            final e = _exercises[i];
            return AuthoringStatusCard(
              key: ValueKey(e.id),
              indicatorKey: ValueKey('exercise-status-indicator-${e.id}'),
              draftIndicatorKey: ValueKey('exercise-draft-indicator-${e.id}'),
              hasDraft: hierarchyStatus.exerciseIsDraft(e),
              hasAuditConcern: hierarchyStatus.exerciseHasAuditConcern(e),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    key: ValueKey('exercise-entry-${e.id}'),
                    leading: ReorderableDragStartListener(
                      index: i,
                      enabled: !widget.readOnly,
                      child: CircleAvatar(child: Text('${i + 1}')),
                    ),
                    title: Text(
                      _ExerciseEditorScreenState.labelForType(e.type),
                    ),
                    subtitle: Text(
                      _summary(e),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _edit(i),
                    trailing: PopupMenuButton<String>(
                      key: ValueKey('exercise-actions-${e.id}'),
                      onSelected: (v) {
                        if (v == 'edit') _edit(i);
                        if (v == 'duplicate') _duplicateExercise(i);
                        if (v == 'delete') _delete(i);
                        if (v == 'generate') _generateFromReading(i);
                        if (v == 'preview') _previewExercise(i);
                        if (v == 'copy') _transferExercise(i, copy: true);
                        if (v == 'move') _transferExercise(i, copy: false);
                        if (v == 'publication') {
                          _setExercisePublication(
                            i,
                            e.publicationState.isPublished
                                ? PublicationState.draft
                                : PublicationState.published,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(widget.readOnly ? 'View' : 'Edit'),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          enabled: !widget.readOnly,
                          child: const Text('Duplicate'),
                        ),
                        const PopupMenuItem(
                          value: 'preview',
                          child: Text('Preview exercise'),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          enabled: !widget.readOnly && _canTransfer,
                          child: const Text('Copy to…'),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          enabled: !widget.readOnly && _canTransfer,
                          child: const Text('Move to…'),
                        ),
                        PopupMenuItem(
                          value: 'publication',
                          enabled: !widget.readOnly,
                          child: Text(
                            e.publicationState.isPublished
                                ? 'Save as draft'
                                : 'Save',
                          ),
                        ),
                        if (e.type == 'reading_comprehension')
                          PopupMenuItem(
                            value: 'generate',
                            enabled: !widget.readOnly,
                            child: const Text('Generate exercise set'),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !widget.readOnly,
                          child: const Text('Delete exercise'),
                        ),
                      ],
                    ),
                  ),
                  EditorInternalIdText(
                    label: 'Exercise',
                    id: e.id,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Exercise _blankExerciseForPreset(String presetId, AuthoringIdGenerator ids) =>
    Exercise(
      id: ids.next('exercise'),
      publicationState: PublicationState.draft,
      type: presetId,
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
    );

enum _ExerciseWizardStage { setup, plan, guided }

class ExerciseCreationWizardScreen extends StatefulWidget {
  const ExerciseCreationWizardScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.round,
    required this.roundIndex,
  });

  final Course course;
  final Lesson lesson;
  final LearningRound round;
  final int roundIndex;

  @override
  State<ExerciseCreationWizardScreen> createState() =>
      _ExerciseCreationWizardScreenState();
}

class _ExerciseCreationWizardScreenState
    extends State<ExerciseCreationWizardScreen> {
  final _count = TextEditingController(text: '3');
  final _planner = const ExerciseCreationPlanner();
  final _ids = TimestampAuthoringIdGenerator();
  final _categories = <ExerciseCategory>{};
  final _selectedPresets = <String>[];
  final _drafts = <int, Exercise>{};
  final _saved = <int>{};
  ExerciseWizardCriterion _criterion = ExerciseWizardCriterion.balanced;
  _ExerciseWizardStage _stage = _ExerciseWizardStage.setup;
  ExerciseCreationPlan? _plan;
  int _seed = 0;
  int _current = 0;
  bool _routeMayPop = false;

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(duration: const Duration(seconds: 8), content: Text(text)),
  );

  void _calculatePlan({bool regenerate = false}) {
    if (regenerate) _seed++;
    try {
      final count = int.tryParse(_count.text.trim());
      if (count == null) throw ArgumentError('Enter a positive whole number.');
      final plan = _planner.create(
        count: count,
        criterion: _criterion,
        categories: _categories.toList(),
        presetIds: _selectedPresets,
        pattern: _selectedPresets,
        randomSeed: _seed,
      );
      setState(() {
        _plan = plan;
        _stage = _ExerciseWizardStage.plan;
      });
    } on ArgumentError catch (error) {
      _message(error.message?.toString() ?? error.toString());
    }
  }

  void _togglePreset(String id, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedPresets.contains(id)) _selectedPresets.add(id);
      } else {
        _selectedPresets.remove(id);
      }
    });
  }

  Future<void> _editCurrent() async {
    final plan = _plan!;
    final existing = _drafts[_current];
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          exercise:
              existing ??
              _blankExerciseForPreset(plan.presetIds[_current], _ids),
          title: 'Exercise ${_current + 1} of ${plan.presetIds.length}',
          course: widget.course,
          lesson: widget.lesson,
          round: widget.round,
          isNew: existing == null,
        ),
      ),
    );
    if (exercise != null && mounted) {
      setState(
        () => _drafts[_current] = _withExercisePublication(
          exercise,
          PublicationState.draft,
        ),
      );
    }
  }

  bool _saveCurrent() {
    if (_drafts[_current] == null) {
      _message('Edit and validate this Exercise before saving it.');
      return false;
    }
    setState(() => _saved.add(_current));
    return true;
  }

  Future<void> _previewCurrent() async {
    final exercise = _drafts[_current];
    if (exercise == null) {
      _message('Edit and validate this Exercise before previewing it.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          lesson: widget.lesson,
          round: LearningRound(
            id: 'wizard_preview_${widget.round.id}',
            publicationState: PublicationState.draft,
            updatedAt: DateTime.now().toUtc(),
            title: 'Preview exercise',
            exercises: [exercise],
          ),
          ttsLanguage:
              CourseLanguageResolver.learning(widget.course).code ?? '',
          roundIndex: widget.roundIndex,
          previewMode: true,
        ),
      ),
    );
  }

  void _advance() {
    if (!_saveCurrent()) return;
    if (_current == _plan!.presetIds.length - 1) {
      _returnToRound([
        for (var i = 0; i < _plan!.presetIds.length; i++) _drafts[i]!,
      ]);
      return;
    }
    setState(() => _current++);
  }

  Future<void> _cancel() async {
    if (_saved.isEmpty) {
      await _returnToRound();
      return;
    }
    if (mounted) {
      final indexes = _saved.toList()..sort();
      await _returnToRound([for (final index in indexes) _drafts[index]!]);
    }
  }

  Future<void> _returnToRound([List<Exercise>? exercises]) async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, exercises);
  }

  Widget _setup() => ListView(
    key: const Key('wizard-setup'),
    padding: const EdgeInsets.all(16),
    children: [
      TextField(
        key: const Key('wizard-count'),
        controller: _count,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'How many exercises?',
          helperText: 'Choose 1–30.',
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<ExerciseWizardCriterion>(
        key: const Key('wizard-criterion'),
        isExpanded: true,
        initialValue: _criterion,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Type-selection criterion',
        ),
        items: [
          for (final value in ExerciseWizardCriterion.values)
            DropdownMenuItem(value: value, child: Text(value.label)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _criterion = value);
        },
      ),
      if (_criterion == ExerciseWizardCriterion.byCategory) ...[
        const SizedBox(height: 16),
        Text('Categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in ExerciseCategory.values)
              FilterChip(
                label: Text(category.label),
                selected: _categories.contains(category),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _categories.add(category);
                  } else {
                    _categories.remove(category);
                  }
                }),
              ),
          ],
        ),
      ],
      if (_criterion == ExerciseWizardCriterion.selectedTypes ||
          _criterion == ExerciseWizardCriterion.repeatPattern) ...[
        const SizedBox(height: 16),
        Text(
          _criterion == ExerciseWizardCriterion.repeatPattern
              ? 'Pattern (selection order is preserved)'
              : 'Exercise types',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in ExercisePresetRegistry.presets)
              FilterChip(
                label: Text(
                  _criterion == ExerciseWizardCriterion.repeatPattern &&
                          _selectedPresets.contains(preset.id)
                      ? '${_selectedPresets.indexOf(preset.id) + 1}. ${preset.name}'
                      : preset.name,
                ),
                selected: _selectedPresets.contains(preset.id),
                onSelected: (selected) => _togglePreset(preset.id, selected),
              ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      FilledButton(
        key: const Key('wizard-continue'),
        onPressed: _calculatePlan,
        child: const Text('Review plan'),
      ),
    ],
  );

  Widget _reviewPlan() => ListView(
    key: const Key('wizard-plan'),
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        '${_plan!.presetIds.length} planned Exercises',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text('No Exercise objects have been created yet.'),
      const SizedBox(height: 12),
      for (var i = 0; i < _plan!.presets.length; i++)
        ListTile(
          dense: true,
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(_plan!.presets[i].name),
          subtitle: Text(_plan!.presets[i].category.label),
        ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () =>
                setState(() => _stage = _ExerciseWizardStage.setup),
            child: const Text('Back'),
          ),
          OutlinedButton(
            key: const Key('wizard-regenerate'),
            onPressed: () => _calculatePlan(regenerate: true),
            child: const Text('Regenerate'),
          ),
          FilledButton(
            key: const Key('wizard-confirm'),
            onPressed: () => setState(() {
              _stage = _ExerciseWizardStage.guided;
              _current = 0;
            }),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ],
  );

  Widget _guided() {
    final preset = _plan!.presets[_current];
    final draft = _drafts[_current];
    final finalStep = _current == _plan!.presetIds.length - 1;
    return ListView(
      key: const Key('wizard-guided'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Exercise ${_current + 1} of ${_plan!.presetIds.length}',
          key: const Key('wizard-step'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: Text(preset.name),
            subtitle: Text(
              draft == null
                  ? 'Not edited yet'
                  : _ExerciseEditorScreenState.labelForType(draft.type),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editCurrent,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('wizard-edit'),
          onPressed: _editCurrent,
          icon: const Icon(Icons.edit_outlined),
          label: Text(draft == null ? 'Edit exercise' : 'Continue editing'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('wizard-save'),
              onPressed: _saveCurrent,
              child: const Text('Save'),
            ),
            OutlinedButton(
              key: const Key('wizard-preview'),
              onPressed: _previewCurrent,
              child: const Text('Preview'),
            ),
            FilledButton(
              key: Key(finalStep ? 'wizard-finish' : 'wizard-next'),
              onPressed: _advance,
              child: Text(finalStep ? 'Finish' : 'Next'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _current > 0
                  ? () => setState(() => _current--)
                  : _saved.isEmpty
                  ? () => setState(() => _stage = _ExerciseWizardStage.plan)
                  : null,
              child: const Text('Back'),
            ),
            TextButton(
              key: const Key('wizard-cancel'),
              onPressed: _cancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<List<Exercise>>(
    canPop: _routeMayPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _cancel();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Exercise Creation Wizard')),
      body: switch (_stage) {
        _ExerciseWizardStage.setup => _setup(),
        _ExerciseWizardStage.plan => _reviewPlan(),
        _ExerciseWizardStage.guided => _guided(),
      },
    ),
  );
}

class CourseAuditScreen extends StatefulWidget {
  final Course course;
  final CourseAuditResult result;
  final String title;
  final CourseAuditReportService? reportService;
  const CourseAuditScreen({
    super.key,
    required this.course,
    required this.result,
    this.title = 'Course Audit',
    this.reportService,
  });
  @override
  State<CourseAuditScreen> createState() => _CourseAuditScreenState();
}

class _CourseAuditScreenState extends State<CourseAuditScreen> {
  AuditSeverity? _filter;
  AuditSortMode _sortMode = AuditSortMode.lesson;

  late final CourseAuditReportService _reportService =
      widget.reportService ?? CourseAuditReportService();

  Future<void> _copyReport() async {
    try {
      await _reportService.copyReport(
        course: widget.course,
        result: widget.result,
        scope: widget.title,
        sortMode: _sortMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete Audit report copied.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not copy Audit report: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _exportReport() async {
    try {
      final path = await _reportService.exportReport(
        course: widget.course,
        result: widget.result,
        scope: widget.title,
        sortMode: _sortMode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complete Audit report exported to $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export Audit report: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _severityLabel(AuditSeverity severity) => switch (severity) {
    AuditSeverity.error => 'Errors',
    AuditSeverity.warning => 'Warnings',
    AuditSeverity.info => 'Info',
  };

  Widget _issueCard(NumberedAuditIssue numbered) {
    final issue = numbered.issue;
    return Semantics(
      label:
          '${numbered.label}. ${issue.message}. Code ${issue.code}. ${issue.location}',
      child: Card(
        child: ListTile(
          leading: Icon(
            issue.severity == AuditSeverity.error
                ? Icons.error_outline
                : issue.severity == AuditSeverity.warning
                ? Icons.warning_amber_outlined
                : Icons.info_outline,
          ),
          title: Text(issue.message),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numbered.label),
              Text('Code: ${issue.code}'),
              Text(issue.location),
            ],
          ),
          isThreeLine: true,
          trailing: issue.roundId == null
              ? null
              : Icon(
                  widget.course.originType.isOfficial
                      ? Icons.visibility_outlined
                      : Icons.edit_outlined,
                ),
          onTap: issue.roundId == null
              ? null
              : () => Navigator.pop(context, issue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issues = widget.result.numbered(_sortMode, severity: _filter);
    Widget chip(String label, AuditSeverity? severity) => ChoiceChip(
      label: Text(label),
      selected: _filter == severity,
      onSelected: (_) => setState(() => _filter = severity),
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                    'Info ${widget.result.count(AuditSeverity.info)}',
                    AuditSeverity.info,
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButton<AuditSortMode>(
                      isExpanded: true,
                      value: _sortMode,
                      onChanged: (value) => setState(
                        () => _sortMode = value ?? AuditSortMode.lesson,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AuditSortMode.lesson,
                          child: Text('By Lesson'),
                        ),
                        DropdownMenuItem(
                          value: AuditSortMode.exerciseType,
                          child: Text('By Exercise type'),
                        ),
                        DropdownMenuItem(
                          value: AuditSortMode.recentlyModified,
                          child: Text('Recently modified'),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('copy-audit-report'),
                    onPressed: _copyReport,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy report'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('export-audit-report'),
                    onPressed: _exportReport,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export report'),
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
          for (final severity in AuditSeverity.values)
            if (issues.any((entry) => entry.issue.severity == severity)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                child: Text(
                  _severityLabel(severity),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...issues
                  .where((entry) => entry.issue.severity == severity)
                  .map(_issueCard),
            ],
        ],
      ),
    );
  }
}

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
  bool _useMultiSelect = false;
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
      _gapLayout,
      _pairs,
      _icons,
      _missingWords,
      _context,
      _dialogue,
      _requiredSelections;
  @override
  void initState() {
    super.initState();
    _inspection = widget.initiallyInspecting;
    _exercise = widget.exercise;
    _loadScriptController();
    _navigationExercises = [...?widget.round?.exercises];
    final e = _exercise;
    _type = _types.contains(e.type) ? e.type : 'choice';
    _prompt = TextEditingController(text: e.prompt);
    _question = TextEditingController(text: e.question);
    _tts = TextEditingController(text: e.tts ?? '');
    _hint = TextEditingController(text: e.hint);
    _answers = TextEditingController(text: e.answers.join('\n'));
    _useMultiSelect = e.isMultiSelect;
    _correct = TextEditingController(
      text: e.isMultiSelect
          ? _multiSelectCorrectNumbersText(e)
          : (e.correct == null
                ? (TranslationChoice.isTranslationChoice(e.type) ? '1' : '')
                : '${e.correct! + 1}'),
    );
    _requiredSelections = TextEditingController(
      text: e.isMultiSelect ? '${e.requiredSelectionCount}' : '',
    );
    _accepted = TextEditingController(text: e.accepted.join('\n'));
    _useInlineGaps = e.hasArrangeGaps || e.hasSelectGaps;
    _tokens = TextEditingController(
      text: (e.hasArrangeGaps || e.hasSelectGaps)
          ? _distractorTexts(e).join('\n')
          : e.tokens.join('\n'),
    );
    _order = TextEditingController(text: e.orderAnswer.join('\n'));
    _gapLayout = TextEditingController(text: _gapLayoutText(e));
    final correctTranslations = e.correctTranslationTexts;
    for (final value
        in correctTranslations.isEmpty
            ? const <String>['']
            : correctTranslations) {
      final controller = TextEditingController(text: value);
      _watchText(controller);
      _correctTranslations.add(controller);
    }
    _pairs = TextEditingController(
      text: e.pairs.map((p) => p.join(' = ')).join('\n'),
    );
    _icons = TextEditingController(text: e.icons.join('\n'));
    _missingWords = TextEditingController(
      text: (e.type == 'listening_spelling' ? e.accepted : e.missingWords).join(
        '\n',
      ),
    );
    _context = TextEditingController(text: e.contextText);
    _dialogue = TextEditingController(
      text: e.dialogueTurns
          .map((turn) => '${turn.speaker}: ${turn.text}')
          .join('\n'),
    );
    _contextMode = e.contextMode;
    _imageAsset = e.imageAsset;
    _selectedSharedSource = e.promptElements
        .where(
          (element) => element.type == 'image' && element.asset == _imageAsset,
        )
        .firstOrNull
        ?.sharedImageSource;
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
    ]) {
      _watchText(controller);
    }
  }

  void _loadScriptController() {
    _scriptController?.dispose();
    _scriptController = ScriptRecognitionController(_exercise)
      ..addListener(_markDirty);
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

  List<String> get _literalCorrectTranslations => _correctTranslations
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  String _normalizedLiteralTranslation(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?…]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

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
  /// text plus one `{answer}` block per inline gap, with the literal answer
  /// text embedded directly inside the braces) from an existing Arrange
  /// exercise's layout, for display when reopening it in the Editor.
  String _gapLayoutText(Exercise e) {
    final valueById = {
      for (final item in e.interaction.items) item.id: item.value,
    };
    return e.arrangeLayout
        .map(
          (el) => el.type == 'gap'
              ? '{${valueById[e.arrangeGapAssignments[el.text]] ?? ''}}'
              : el.text,
        )
        .join(' ');
  }

  /// Reconstructs the 1-based, comma-separated "Correct answer numbers" text
  /// for a multi-select Select exercise from its correct item IDs, for
  /// display when reopening it in the Editor.
  String _multiSelectCorrectNumbersText(Exercise e) {
    final correctIds = e.correctItemIdSet;
    final numbers = <int>[];
    for (var i = 0; i < e.interaction.items.length; i++) {
      if (correctIds.contains(e.interaction.items[i].id)) numbers.add(i + 1);
    }
    return numbers.join(', ');
  }

  /// The blocks that are not used to fill any gap (optional distractors),
  /// for display in the "Extra distractor blocks" field.
  List<String> _distractorTexts(Exercise e) {
    final assignedIds = e.arrangeGapAssignments.values.toSet();
    return [
      for (final item in e.interaction.items)
        if (!assignedIds.contains(item.id)) item.value,
    ];
  }

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
    'translation_choice_to_target',
    'translation_choice_to_source',
  }.contains(_type);
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

  Widget _helpButton(String fieldKey) => IconButton(
    key: ValueKey('exercise-field-help-$fieldKey'),
    tooltip: ExerciseFieldHelpRegistry.forEditorField(_type, fieldKey).purpose,
    onPressed: () => _showFieldHelp(fieldKey),
    icon: const Icon(Icons.help_outline),
  );

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
      final normalization = _exercise.evaluation.normalization;
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
    switch (_type) {
      case 'script_recognition':
        return [
          ScriptRecognitionEditor(
            controller: _scriptController!,
            readOnly: widget.readOnly,
          ),
        ];
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
            helper:
                'Use ___ (3 underscores) for the missing word. Example: The cat ___ black.',
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
          _field(
            _prompt,
            'Sentence with one ___ gap',
            lines: 3,
            helper:
                'The first letter is derived automatically from the complete accepted word.',
          ),
          _field(
            _accepted,
            'Complete accepted words',
            lines: 3,
            helper:
                'One complete word per line. All answers must have the same first Unicode grapheme.',
          ),
          _field(_hint, 'Hint (optional)'),
          const Text(
            'Enter the complete missing word. The first letter shown is a hint. Example: é______ → école, not cole.',
          ),
        ];
      case 'build_translation':
        return [
          _field(
            _prompt,
            'Source sentence',
            lines: 3,
            helper: 'Enter the complete sentence the learner must translate.',
          ),
          SwitchListTile(
            key: const Key('build-translation-use-inline-gaps'),
            title: const Text('Inline gaps'),
            subtitle: const Text(
              'Fill one or more blanks inside a fixed target-language sentence instead of building the whole sentence from blocks. Disables multiple correct-translation variants.',
            ),
            value: _useInlineGaps,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _useInlineGaps = value;
                    _dirty = true;
                  }),
          ),
          if (_useInlineGaps) ...[
            _field(
              _gapLayout,
              'Target sentence with gaps',
              lines: 3,
              helper:
                  'Write the fixed target-language sentence and put each '
                  'answer word or phrase directly inside braces: {answer}. '
                  "Literal { or } characters can't appear anywhere else in "
                  'the sentence. Example: Io {vorrei} un caffè.',
            ),
            _field(
              _tokens,
              'Extra distractor blocks (optional)',
              lines: 3,
              helper:
                  'One extra block per line that is not used to fill any '
                  'gap. Include 0, 1 or at most 2 distractors.',
            ),
            _field(
              _tts,
              'Spoken prompt (optional)',
              lines: 2,
              helper:
                  'Optional audio played before the learner fills the gaps.',
            ),
          ] else ...[
            _field(
              _tokens,
              'Available target-language blocks',
              lines: 5,
              helper:
                  'One literal block per line. Include enough occurrences to construct every correct translation; repeated words need separate blocks.',
            ),
            _correctTranslationsEditor(),
          ],
        ];
      case 'word_order':
        return [
          _field(_prompt, 'Translation prompt / instruction', lines: 2),
          SwitchListTile(
            key: const Key('word-order-use-inline-gaps'),
            title: const Text('Inline gaps'),
            subtitle: const Text(
              'Fill one or more blanks inside a fixed sentence instead of building the whole sentence from blocks.',
            ),
            value: _useInlineGaps,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _useInlineGaps = value;
                    _dirty = true;
                  }),
          ),
          if (_useInlineGaps) ...[
            _field(
              _gapLayout,
              'Sentence with gaps',
              lines: 3,
              helper:
                  'Write the fixed sentence and put each answer word or '
                  'phrase directly inside braces: {answer}. Literal { or } '
                  "characters can't appear anywhere else in the sentence. "
                  'Example: I {am} going {to} London.',
            ),
            _field(
              _tokens,
              'Extra distractor blocks (optional)',
              lines: 4,
              helper:
                  'One extra block per line that is not used to fill any '
                  'gap. Include 0, 1 or at most 2 distractors.',
            ),
            _field(
              _tts,
              'Spoken prompt (optional)',
              lines: 2,
              helper:
                  'Optional audio played before the learner fills the gaps.',
            ),
          ] else ...[
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
          ],
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
          const Text(
            'MP3: open Course Editor > Audio Library. Copy MP3 files to Documents/QuisquisLingo/Imports/Audio, press Import MP3, then Associate recording with its Word or expression. Choose Recorded MP3 only or Hybrid. This exercise uses those text mappings.',
          ),
          const SizedBox(height: 12),
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
          _field(
            _prompt,
            'Reading passage',
            lines: 5,
            helper: 'At least three lexical words are recommended.',
          ),
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
            isExpanded: true,
            initialValue: _contextMode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Context mode',
              suffixIcon: _helpButton('contextMode'),
            ),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Text')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
              DropdownMenuItem(
                value: 'textAndAudio',
                child: Text('Text and audio'),
              ),
            ],
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _contextMode = value ?? _contextMode;
                    _dirty = true;
                  }),
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
      case 'translation_choice_to_target':
      case 'translation_choice_to_source':
        final toTarget = _type == 'translation_choice_to_target';
        return [
          _field(
            _question,
            'Text to translate',
            lines: 2,
            helper: toTarget
                ? 'One word, phrase or sentence in the course source '
                      'language. Do not write an instruction: QQL shows '
                      '“Pick the correct [Target language] translation” '
                      'automatically.'
                : 'One word, phrase or sentence in the course target '
                      'language. The learner can play it with '
                      'text-to-speech when available. Do not write an '
                      'instruction: QQL shows “Pick the correct [Source '
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
      case 'choice':
        return [
          _field(_prompt, 'Prompt / instruction', lines: 2),
          SwitchListTile(
            key: const Key('choice-use-inline-gaps'),
            title: const Text('Inline gaps'),
            subtitle: const Text(
              'Fill one or more blanks inside a fixed question by tapping '
              'options in order instead of choosing one whole answer. Each '
              'tap fills the first empty blank; the same option can be '
              'tapped again for another blank. Disables multiple correct '
              'answers.',
            ),
            value: _useInlineGaps,
            onChanged: widget.readOnly
                ? null
                : (value) => setState(() {
                    _useInlineGaps = value;
                    if (value) _useMultiSelect = false;
                    _dirty = true;
                  }),
          ),
          if (_useInlineGaps) ...[
            _field(
              _gapLayout,
              'Sentence with gaps',
              lines: 3,
              helper:
                  'Write the sentence and put each answer word or phrase '
                  'directly inside braces: {answer}. Example: I {am} going '
                  '{to} London. Each blank is filled in order by the '
                  'options the learner taps, so a wrong choice can land in '
                  'the wrong blank. If the same word answers more than one '
                  'gap, write it inside each of those braces — the '
                  'learner taps it once per blank it needs to fill: '
                  '{Was} she happy? {Was} he late? Literal { or } '
                  'characters can\'t appear anywhere else.',
            ),
            _field(
              _tokens,
              'Distractor options (optional)',
              lines: 3,
              helper:
                  'One extra option per line that is not the answer to any '
                  'gap. Include 0, 1 or at most 2 distractors.',
            ),
            _field(
              _tts,
              'Spoken prompt (optional)',
              lines: 2,
              helper:
                  'Optional audio played before the learner fills the gaps.',
            ),
          ] else ...[
            _field(_question, 'Question', lines: 2),
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
          ],
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

  Future<void> _choosePreset() async {
    if (widget.readOnly) return;
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
    if (selected != null && mounted) {
      final previousType = _type;
      setState(() {
        const arrangeFamily = {'word_order', 'build_translation'};
        final staySameFamily =
            arrangeFamily.contains(previousType) &&
            arrangeFamily.contains(selected);
        if (!staySameFamily) {
          _useInlineGaps = false;
          _useMultiSelect = false;
        }
        _type = selected;
        // Pick the translation always starts with the first option correct.
        if (TranslationChoice.isTranslationChoice(selected) &&
            _correct.text.trim().isEmpty) {
          _correct.text = '1';
        }
        _dirty = true;
      });
    }
  }

  Exercise? _buildCandidate(
    PublicationState publicationState, {
    bool requireValidAnswer = false,
  }) {
    if (_type == 'script_recognition') {
      return _scriptController!.build(publicationState);
    }
    if (const {'word_order', 'build_translation'}.contains(_type) &&
        _useInlineGaps) {
      return _buildArrangeGapCandidate(publicationState);
    }
    if (_type == 'choice' && _useInlineGaps) {
      return _buildSelectGapCandidate(publicationState);
    }
    if (_type == 'choice' && _useMultiSelect) {
      return _buildSelectMultiCandidate(publicationState);
    }
    if (TranslationChoice.isTranslationChoice(_type)) {
      final problem = TranslationChoice.answersProblem(_lines(_answers));
      if (problem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(problem),
          ),
        );
        return null;
      }
    }
    if (_type == 'type_translation' || _type == 'type_missing_word') {
      final accepted = _lines(_accepted);
      try {
        if (accepted.isNotEmpty) {
          AnswerExpressionParser.expandAll(accepted);
        }
        if (_type == 'type_missing_word' && accepted.isNotEmpty) {
          FirstLetterAnswerService.display(_prompt.text.trim(), accepted);
        }
      } on AnswerExpressionException catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return null;
      }
      var replaced = false;
      var imageReplaced = false;
      final imageChanged = _imageAsset != _exercise.imageAsset;
      final prompt = <PromptElement>[];
      for (final element in _exercise.promptElements) {
        if (imageChanged && !imageReplaced && element.type == 'image') {
          imageReplaced = true;
          if (_imageAsset.isNotEmpty) {
            prompt.add(
              PromptElement(
                role: element.role,
                type: element.type,
                text: element.text,
                asset: _imageAsset,
                speaker: element.speaker,
              ),
            );
          }
        } else if (!replaced &&
            element.role == 'primary' &&
            element.type == 'text') {
          prompt.add(
            PromptElement(
              role: element.role,
              type: element.type,
              text: _prompt.text.trim(),
              asset: element.asset,
              speaker: element.speaker,
            ),
          );
          replaced = true;
        } else {
          prompt.add(element);
        }
      }
      if (!replaced) {
        prompt.add(PromptElement(type: 'text', text: _prompt.text.trim()));
      }
      if (imageChanged && !imageReplaced && _imageAsset.isNotEmpty) {
        prompt.add(PromptElement(type: 'image', asset: _imageAsset));
      }
      return Exercise.v2(
        id: _exercise.id,
        publicationState: publicationState,
        updatedAt: _exercise.updatedAt,
        editorTemplate: _type,
        promptElements: prompt,
        interaction: _exercise.type == _type
            ? _exercise.interaction
            : const ExerciseInteraction(kind: 'input'),
        evaluation: ExerciseEvaluation(
          kind: 'text_match',
          accepted: accepted,
          correctItemIds: _exercise.type == _type
              ? _exercise.evaluation.correctItemIds
              : const [],
          correctOrders: _exercise.type == _type
              ? _exercise.evaluation.correctOrders
              : const [],
          pairs: _exercise.type == _type
              ? _exercise.evaluation.pairs
              : const [],
          normalization: _exercise.evaluation.normalization,
        ),
        hint: _hint.text.trim(),
        feedback: _exercise.feedback,
        missingWords: _exercise.missingWords,
      );
    }
    if (_type == 'build_translation') {
      final translations = _literalCorrectTranslations;
      if (translations.isEmpty) {
        setState(() {
          _correctTranslationErrorIndexes = const {0};
          _correctTranslationError =
              'Add at least one non-empty correct translation.';
        });
        return null;
      }
      final normalizedByIndex = <int, String>{
        for (var index = 0; index < _correctTranslations.length; index++)
          if (_correctTranslations[index].text.trim().isNotEmpty)
            index: _normalizedLiteralTranslation(
              _correctTranslations[index].text,
            ),
      };
      if (normalizedByIndex.values.toSet().length != normalizedByIndex.length) {
        final duplicateIndexes = <int>{};
        for (final entry in normalizedByIndex.entries) {
          if (normalizedByIndex.values
                  .where((value) => value == entry.value)
                  .length >
              1) {
            duplicateIndexes.add(entry.key);
          }
        }
        setState(() {
          _correctTranslationErrorIndexes = duplicateIndexes;
          _correctTranslationError =
              'Correct translations contain duplicates after ignoring case, spacing and final punctuation. Remove or change the repeated entry.';
        });
        return null;
      }
    }
    if (const {
      'matching',
      'audio_match',
      'word_match',
      'super_match',
    }.contains(_type)) {
      final invalidLine = _lines(_pairs).indexWhere((line) {
        final separator = line.indexOf('=');
        return separator < 0 ||
            line.substring(0, separator).trim().isEmpty ||
            line.substring(separator + 1).trim().isEmpty;
      });
      if (invalidLine >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pairs line ${invalidLine + 1}: enter both values as left = right, one pair per line. Complete or remove this line before Preview or Save.',
            ),
          ),
        );
        return null;
      }
    }
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
        if (!publicationState.isPublished && !requireValidAnswer) {
          correct = null;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 8),
              content: Text(
                'Correct answer number: enter the number of an existing answer, starting at 1.',
              ),
            ),
          );
          return null;
        }
      } else {
        correct = parsed - 1;
      }
    }
    final Exercise candidate;
    if (_type == 'contextual_comprehension') {
      final items = <ExerciseItem>[
        for (var i = 0; i < answers.length; i++)
          ExerciseItem(
            id: i < _exercise.interaction.items.length
                ? _exercise.interaction.items[i].id
                : 'item_$i',
            content: [PromptElement(type: 'text', text: answers[i])],
          ),
      ];
      candidate = Exercise.v2(
        id: _exercise.id,
        publicationState: publicationState,
        updatedAt: _exercise.updatedAt,
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
      candidate = Exercise(
        id: _exercise.id,
        publicationState: publicationState,
        updatedAt: _exercise.updatedAt,
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
              'translation_choice_to_target',
              'translation_choice_to_source',
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
        accepted: const {'listening_spelling', 'missing_word'}.contains(_type)
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
        orderAnswer: const {'word_order', 'image_word'}.contains(_type)
            ? _lines(_order)
            : const [],
        correctTranslations: _type == 'build_translation'
            ? _literalCorrectTranslations
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
        hint:
            const {
              'gap_choice',
              'fill_blank',
              'type_translation',
            }.contains(_type)
            ? _hint.text.trim()
            : '',
        icons: _type == 'icon_choice' ? _lines(_icons) : const [],
        imageAsset: _imageAsset,
        missingWords: _type == 'missing_word'
            ? _lines(_missingWords)
            : const [],
      );
    }
    return candidate;
  }

  /// Builds the inline-gap Arrange candidate for `word_order` and
  /// `build_translation` when Inline gaps is enabled. Reuses the existing
  /// token/authored-order block-matching rules and legacy prompt-role
  /// mapping so gap-fill authoring stays consistent with the unchanged
  /// whole-sentence Arrange builder.
  static final RegExp _gapBracePattern = RegExp(r'\{([^{}]*)\}');

  /// True when every `{`/`}` in [text] belongs to a well-formed `{answer}`
  /// gap marker (no stray or nested braces left over once all gap markers
  /// are removed).
  bool _gapBraceCountsBalance(String text) =>
      !text.replaceAll(_gapBracePattern, '').contains(RegExp(r'[{}]'));

  Exercise? _buildArrangeGapCandidate(PublicationState publicationState) {
    final text = _gapLayout.text;
    if (text.contains('{') && !_gapBraceCountsBalance(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sentence with gaps: every { must have a matching } directly '
            'around one answer word or phrase, e.g. {go}. Literal { or } '
            "characters can't be used elsewhere in the sentence.",
          ),
        ),
      );
      return null;
    }
    final matches = _gapBracePattern.allMatches(text).toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sentence with gaps: add at least one gap, e.g. {go}.'),
        ),
      );
      return null;
    }
    final gapAnswers = <String>[];
    for (final match in matches) {
      final answer = (match.group(1) ?? '').trim();
      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sentence with gaps: each {…} gap must contain the answer '
              'text, e.g. {go}, not an empty {}.',
            ),
          ),
        );
        return null;
      }
      gapAnswers.add(answer);
    }
    final distractors = _lines(_tokens);
    final tokens = [...gapAnswers, ...distractors];
    final itemIds = Exercise.resolveOrderedItemIds(tokens, gapAnswers);
    if (itemIds.length != gapAnswers.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sentence with gaps: could not resolve every gap answer to a '
            'block. Check the extra distractor blocks for a conflict.',
          ),
        ),
      );
      return null;
    }
    final gapIds = [for (var i = 0; i < gapAnswers.length; i++) 'gap_${i + 1}'];
    final layout = <PromptElement>[];
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final fixedText = text.substring(cursor, match.start).trim();
      if (fixedText.isNotEmpty) {
        layout.add(PromptElement(type: 'text', text: fixedText));
      }
      layout.add(PromptElement(type: 'gap', text: gapIds[i]));
      cursor = match.end;
    }
    final trailingText = text.substring(cursor).trim();
    if (trailingText.isNotEmpty) {
      layout.add(PromptElement(type: 'text', text: trailingText));
    }
    final items = [
      for (var i = 0; i < tokens.length; i++)
        ExerciseItem(
          id: 'item_$i',
          content: [PromptElement(type: 'text', text: tokens[i])],
        ),
    ];
    return Exercise.v2(
      id: _exercise.id,
      publicationState: publicationState,
      updatedAt: _exercise.updatedAt,
      editorTemplate: _type,
      promptElements: Exercise.legacyPromptElements(
        _type,
        _prompt.text.trim(),
        '',
        _tts.text.trim().isEmpty ? null : _tts.text.trim(),
        _imageAsset,
      ),
      interaction: ExerciseInteraction(
        kind: 'arrange',
        items: items,
        layout: layout,
      ),
      evaluation: ExerciseEvaluation(
        kind: 'ordered_items',
        gapAssignments: {
          for (var i = 0; i < gapIds.length; i++) gapIds[i]: itemIds[i],
        },
      ),
      hint: '',
      feedback: _exercise.feedback,
      missingWords: _exercise.missingWords,
    );
  }

  /// Builds the multiple-selection Select candidate for `choice` when
  /// Multiple correct answers is enabled. Correctness is set-based: the
  /// learner's selected options must exactly match `correctItemIds`.
  Exercise? _buildSelectMultiCandidate(PublicationState publicationState) {
    final answerLines = _lines(_answers);
    if (answerLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answers: add at least one answer.')),
      );
      return null;
    }
    final numberTexts = _correct.text
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final correctIndexes = <int>{};
    for (final numberText in numberTexts) {
      final parsed = int.tryParse(numberText);
      if (parsed == null || parsed < 1 || parsed > answerLines.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Correct answer numbers: enter the numbers of existing '
              'answers, starting at 1, separated by commas.',
            ),
          ),
        );
        return null;
      }
      correctIndexes.add(parsed - 1);
    }
    if (correctIndexes.isEmpty && publicationState.isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Correct answer numbers: enter at least one correct answer '
            'number to publish.',
          ),
        ),
      );
      return null;
    }
    final requiredText = _requiredSelections.text.trim();
    final required = requiredText.isEmpty
        ? (correctIndexes.isEmpty ? 1 : correctIndexes.length)
        : int.tryParse(requiredText);
    if (required == null || required < 1 || required > answerLines.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Required selections: enter a number between 1 and the number '
            'of answers, or leave blank.',
          ),
        ),
      );
      return null;
    }
    final items = [
      for (var i = 0; i < answerLines.length; i++)
        ExerciseItem(
          id: 'item_$i',
          content: [PromptElement(type: 'text', text: answerLines[i])],
        ),
    ];
    return Exercise.v2(
      id: _exercise.id,
      publicationState: publicationState,
      updatedAt: _exercise.updatedAt,
      editorTemplate: _type,
      promptElements: Exercise.legacyPromptElements(
        _type,
        _prompt.text.trim(),
        _question.text.trim(),
        null,
        _imageAsset,
      ),
      interaction: ExerciseInteraction(
        kind: 'select',
        items: items,
        minSelections: required,
        maxSelections: items.length,
      ),
      evaluation: ExerciseEvaluation(
        kind: 'selected_items',
        correctItemIds: [for (final i in correctIndexes) items[i].id],
      ),
      hint: '',
      feedback: _exercise.feedback,
      missingWords: _exercise.missingWords,
    );
  }

  /// Builds the linked-gap Select candidate for `choice` when Inline gaps is
  /// enabled. Unlike gap-based Arrange, the same option can be the required
  /// answer for more than one gap, so answer text is deduplicated into one
  /// shared option: the learner can tap it again to fill a later gap that
  /// also needs it, instead of needing a separate tile per occurrence.
  Exercise? _buildSelectGapCandidate(PublicationState publicationState) {
    final text = _gapLayout.text;
    if (text.contains('{') && !_gapBraceCountsBalance(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sentence with gaps: every { must have a matching } directly '
            'around one answer option, e.g. {answer}. Literal { or } '
            "characters can't be used elsewhere in the sentence.",
          ),
        ),
      );
      return null;
    }
    final matches = _gapBracePattern.allMatches(text).toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sentence with gaps: add at least one gap, e.g. {answer}.',
          ),
        ),
      );
      return null;
    }
    final gapAnswers = <String>[];
    for (final match in matches) {
      final answer = (match.group(1) ?? '').trim();
      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sentence with gaps: each {…} gap must contain the answer '
              'text, e.g. {answer}, not an empty {}.',
            ),
          ),
        );
        return null;
      }
      gapAnswers.add(answer);
    }
    final distractors = _lines(_tokens);
    final optionTexts = <String>[];
    for (final answer in [...gapAnswers, ...distractors]) {
      if (!optionTexts.contains(answer)) optionTexts.add(answer);
    }
    final idByText = {
      for (var i = 0; i < optionTexts.length; i++) optionTexts[i]: 'item_$i',
    };
    final gapIds = [for (var i = 0; i < gapAnswers.length; i++) 'gap_${i + 1}'];
    final layout = <PromptElement>[];
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final fixedText = text.substring(cursor, match.start).trim();
      if (fixedText.isNotEmpty) {
        layout.add(PromptElement(type: 'text', text: fixedText));
      }
      layout.add(PromptElement(type: 'gap', text: gapIds[i]));
      cursor = match.end;
    }
    final trailingText = text.substring(cursor).trim();
    if (trailingText.isNotEmpty) {
      layout.add(PromptElement(type: 'text', text: trailingText));
    }
    final items = [
      for (final optionText in optionTexts)
        ExerciseItem(
          id: idByText[optionText]!,
          content: [PromptElement(type: 'text', text: optionText)],
        ),
    ];
    return Exercise.v2(
      id: _exercise.id,
      publicationState: publicationState,
      updatedAt: _exercise.updatedAt,
      editorTemplate: _type,
      promptElements: Exercise.legacyPromptElements(
        _type,
        _prompt.text.trim(),
        '',
        _tts.text.trim().isEmpty ? null : _tts.text.trim(),
        _imageAsset,
      ),
      interaction: ExerciseInteraction(
        kind: 'select',
        items: items,
        layout: layout,
      ),
      evaluation: ExerciseEvaluation(
        kind: 'selected_items',
        gapAssignments: {
          for (var i = 0; i < gapIds.length; i++)
            gapIds[i]: idByText[gapAnswers[i]]!,
        },
      ),
      hint: '',
      feedback: _exercise.feedback,
      missingWords: _exercise.missingWords,
    );
  }

  Future<bool> _validateScriptImages(Exercise candidate) async {
    if (candidate.type != 'script_recognition') return true;
    final assets = {
      for (final element in candidate.promptElements)
        if (element.type == 'image' && element.asset.isNotEmpty) element.asset,
      for (final item in candidate.interaction.items)
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

  Exercise _withSelectedSharedSource(Exercise exercise) => Exercise.v2(
    id: exercise.id,
    publicationState: exercise.publicationState,
    updatedAt: exercise.updatedAt,
    editorTemplate: exercise.editorTemplate,
    promptElements: [
      for (final element in exercise.promptElements)
        if (element.type == 'image' && element.asset == _imageAsset)
          PromptElement(
            role: element.role,
            type: element.type,
            text: element.text,
            asset: element.asset,
            speaker: element.speaker,
            sharedImageSource: _selectedSharedSource,
          )
        else
          element,
    ],
    interaction: exercise.interaction,
    evaluation: exercise.evaluation,
    hint: exercise.hint,
    feedback: exercise.feedback,
    missingWords: exercise.missingWords,
  );

  Future<bool> _save(
    PublicationState publicationState, {
    bool close = true,
  }) async {
    if (widget.readOnly || _inspection) return false;
    if (!publicationState.isPublished &&
        _exercise.publicationState.isPublished &&
        !await _confirmMoveToDraft(context, 'Exercise')) {
      return false;
    }
    if (!mounted) return false;
    final built = _buildCandidate(publicationState);
    if (built == null) return false;
    final candidate = _withSelectedSharedSource(built);
    if (!await _validateScriptImages(candidate)) return false;
    if (!mounted) return false;
    final ex =
        widget.isNew ||
            !_sameAuthoringJson(candidate.toJson(), _exercise.toJson())
        ? _withExercisePublication(
            candidate,
            publicationState,
            updatedAt: _clock(),
          )
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
    widget.onExerciseSaved?.call(exercise);
    setState(() {
      _exercise = exercise;
      _dirty = false;
      _routeMayPop = close;
    });
    if (!close) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, exercise);
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

  Future<bool> _resolveUnsavedChanges() async {
    if (!_dirty) return true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Exercise changes'),
        content: const Text(
          'Save these changes to the course working copy, discard this Exercise form, or keep editing. Nothing is confirmed to storage here.',
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
            child: const Text('Save as draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
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
        _type = e.type;
        _prompt.text = e.prompt;
        _question.text = e.question;
        _tts.text = e.tts ?? '';
        _hint.text = e.hint;
        _answers.text = e.answers.join('\n');
        _useMultiSelect = e.isMultiSelect;
        _correct.text = e.isMultiSelect
            ? _multiSelectCorrectNumbersText(e)
            : (e.correct == null
                  ? (TranslationChoice.isTranslationChoice(e.type) ? '1' : '')
                  : '${e.correct! + 1}');
        _requiredSelections.text = e.isMultiSelect
            ? '${e.requiredSelectionCount}'
            : '';
        _accepted.text = e.accepted.join('\n');
        _useInlineGaps = e.hasArrangeGaps || e.hasSelectGaps;
        _tokens.text = (e.hasArrangeGaps || e.hasSelectGaps)
            ? _distractorTexts(e).join('\n')
            : e.tokens.join('\n');
        _order.text = e.orderAnswer.join('\n');
        _gapLayout.text = _gapLayoutText(e);
        _pairs.text = e.pairs.map((pair) => pair.join(' = ')).join('\n');
        _icons.text = e.icons.join('\n');
        _missingWords.text =
            (e.type == 'listening_spelling' ? e.accepted : e.missingWords).join(
              '\n',
            );
        _context.text = e.contextText;
        _dialogue.text = e.dialogueTurns
            .map((turn) => '${turn.speaker}: ${turn.text}')
            .join('\n');
        _contextMode = e.contextMode;
        _imageAsset = e.imageAsset;
        _selectedSharedSource = e.promptElements
            .where(
              (element) =>
                  element.type == 'image' && element.asset == _imageAsset,
            )
            .firstOrNull
            ?.sharedImageSource;
        for (final controller in _correctTranslations) {
          controller.dispose();
        }
        _correctTranslations.clear();
        for (final text
            in e.correctTranslationTexts.isEmpty
                ? ['']
                : e.correctTranslationTexts) {
          _correctTranslations.add(_translationController(text));
        }
        _correctTranslationError = null;
        _correctTranslationErrorIndexes = const {};
        _dirty = false;
        _inspection = widget.initiallyInspecting;
      });
    } finally {
      _navigationBusy = false;
    }
  }

  void _setInspection(bool value) {
    if (_inspection == value) return;
    setState(() => _inspection = value);
  }

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
        title: Text(_pageTitle),
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
                  title: Text(labelForType(_type)),
                  subtitle: Text(
                    '${ExercisePresetRegistry.byId(_type)!.category.label} · ${ExercisePresetRegistry.byId(_type)!.description}',
                  ),
                  trailing: const Icon(Icons.unfold_more),
                  onTap: widget.readOnly ? null : _choosePreset,
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
            if (_type != 'script_recognition')
              ExerciseImageField(
                course: widget.course,
                asset: _imageAsset,
                sharedSource: _selectedSharedSource,
                readOnly: widget.readOnly,
                help: _helpButton('image'),
                onChanged: (change) => setState(() {
                  _imageAsset = change.asset;
                  _selectedSharedSource = change.source;
                  _dirty = true;
                }),
              ),
          ],
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
                onPressed: widget.readOnly || _inspection
                    ? null
                    : () => _save(PublicationState.draft),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save as draft'),
              ),
              FilledButton.icon(
                key: const Key('exercise-save'),
                onPressed: widget.readOnly || _inspection
                    ? null
                    : () => _save(PublicationState.published),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
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

  /// Clips whose file no longer resolves. A clip that still carries its word
  /// is not an orphan, so the orphan tool never reports it; without this the
  /// only sign would be a failed preview.
  Set<String> _missingClipIds = const {};

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _refreshMissingClips();
  }

  Future<void> _refreshMissingClips() async {
    final missing = <String>{};
    for (final clip in _course.audioLibrary) {
      final source = await _audio.resolveSourceForClip(
        clip,
        courseId: _course.courseId,
      );
      if (source == null) missing.add(clip.id);
    }
    if (!mounted) return;
    setState(() => _missingClipIds = Set.unmodifiable(missing));
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Course _copy({String? mode, List<CourseAudioClip>? clips}) =>
      Course.fromJson({
        ..._course.toJson(),
        'audioMode': mode ?? _course.audioMode,
        'audioLibrary': (clips ?? _course.audioLibrary)
            .map((clip) => clip.toJson())
            .toList(),
      });
  Future<void> _importFromDialog() async {
    try {
      // Open from…: up to 100 MP3s, each checked like a folder import.
      final picked = await _audio.importMp3sFromDialog(
        _course.courseId,
        existingReferences: {
          for (final clip in _course.audioLibrary) clip.filePath,
        },
      );
      if (!mounted) return;
      if (picked.dialog.outcome != FileDialogOutcome.opened) {
        showFileDialogFeedback(
          context,
          picked.dialog,
          saving: false,
          fallbackHint: mp3FallbackHint,
        );
        return;
      }
      if (picked.clips.isNotEmpty) {
        setState(
          () => _course = _copy(
            clips: [..._course.audioLibrary, ...picked.clips],
          ),
        );
        unawaited(_refreshMissingClips());
      }
      await showImportSummary(
        context,
        title: 'MP3 files imported',
        items: picked.results,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 8), content: Text('$e')),
        );
      }
    }
  }

  Future<void> _import() async {
    try {
      final clips = await _audio.importMp3Files(
        _course.courseId,
        existingReferences: {
          for (final clip in _course.audioLibrary) clip.filePath,
        },
      );
      if (clips.isNotEmpty && mounted) {
        setState(
          () => _course = _copy(clips: [..._course.audioLibrary, ...clips]),
        );
        unawaited(_refreshMissingClips());
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
    Future<void>.delayed(const Duration(milliseconds: 300), c.dispose);
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
    if (_playingId == id) {
      await _previewPlayer.stop();
      _playingId = null;
    }
    final list = [..._course.audioLibrary]..removeAt(i);
    setState(() => _course = _copy(clips: list));
    unawaited(_refreshMissingClips());
  }

  Future<void> _preview(CourseAudioClip clip) async {
    if (_playingId == clip.id) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    try {
      final source = await _audio.resolveSourceForClip(
        clip,
        courseId: _course.courseId,
      );
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
              onPressed: () {
                Navigator.pop(ctx);
                final ids = list.map((e) => e.id).toSet();
                setState(
                  () => _course = _copy(
                    clips: _course.audioLibrary
                        .where((e) => !ids.contains(e.id))
                        .toList(),
                  ),
                );
                unawaited(_refreshMissingClips());
              },
              child: const Text('Remove references'),
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
          DropdownMenuItem(value: 'tts', child: Text('On-Device TTS')),
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
      Text(switch (_course.audioMode) {
        'recorded' =>
          'Recorded MP3 only: learners hear recordings associated with the exact words or expressions in this Course. QQL joins the longest matching clips. Add and associate MP3 files below; if no complete recording is available, there is no TTS fallback.',
        'hybrid' =>
          'Hybrid: MP3 + TTS fallback: QQL first joins matching Course recordings. When it cannot build a complete recording, it uses this device’s text-to-speech voice instead. Add and associate MP3 files below.',
        _ =>
          'On-Device TTS: this device reads the Course text aloud with its own text-to-speech voice. No MP3 files are needed. Choose Recorded MP3 only or Hybrid to manage Course recordings.',
      }),
      const SizedBox(height: 8),
      if (_course.audioMode != 'tts') const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Import MP3: copy the MP3 files you want to import to Documents/QuisquisLingo/Imports/Audio, then press Import MP3. All MP3 files in that folder are imported. Source files are left in place, so move or remove them after a successful import to avoid importing them again.',
          ),
        ),
      ),
      if (_course.audioMode != 'tts') ListTile(
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clip.filePath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_missingClipIds.contains(clip.id))
                  Text(
                    'File missing. Delete this recording to remove its '
                    'reference, then confirm the Course.',
                    key: Key('audio-clip-missing-${clip.id}'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            isThreeLine: _missingClipIds.contains(clip.id),
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
          if (_course.audioMode != 'tts' && _audio.fileDialogsAvailable)
            IconButton(
              key: const Key('open-mp3-from'),
              tooltip: 'Open MP3 from…',
              onPressed: _importFromDialog,
              icon: const Icon(Icons.folder_open_outlined),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, _course),
            child: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: _course.audioMode == 'tts' ? null : FloatingActionButton.extended(
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

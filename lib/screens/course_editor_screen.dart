import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/answer_engine.dart';
import '../services/answer_materialization_service.dart';
import '../services/file_dialog_service.dart';
import '../services/portable_exercise_image.dart';
import '../widgets/script_recognition_editor.dart';
import '../widgets/exercise_image_field.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/course_draft_status.dart';
import '../models/course_flag_selection.dart';
import '../models/course_models.dart';
import '../models/course_metadata_options.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import '../services/course_editor_service.dart';
import '../services/course_editor_device_state.dart';
import '../services/course_flag_service.dart';
import '../services/course_language_resolver.dart';
import '../services/formal_name_policy.dart';
import '../services/course_governance_resolver.dart';
import '../services/course_governance_service.dart';
import '../services/course_info_update_service.dart';
import '../services/course_hierarchy_update_service.dart';
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
import 'primitive_editor_screen.dart';
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
import '../widgets/editor_dialogs.dart';
import '../widgets/exercise_editor_intro.dart';
import '../widgets/page_block_editor.dart';
import '../widgets/authoring_destination_dialog.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/authoring_duplication_service.dart';
import '../services/exercise_creation_planner.dart';
import '../services/exercise_draft_builder.dart';
import '../services/exercise_copy_service.dart';
import '../services/canonical_exercise_draft.dart';
import '../services/round_flow_authoring.dart';
import '../services/preset_recipes.dart';
import '../services/preset_variants.dart';
import '../services/guidebook_round_generator.dart';
import '../services/publication_service.dart';
import '../services/provisional_publication_service.dart';
import '../services/new_course_structure.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/flag_art.dart';
import '../widgets/course_artwork.dart';
import '../widgets/course_cover_field.dart';
import '../widgets/course_flag_picker.dart';
import '../widgets/image_credit_reminder.dart';
import '../widgets/story_line_dialog.dart';
import '../widgets/story_speaker_dialog.dart';
import '../widgets/lesson_fallback_icon.dart';
import '../widgets/import_summary.dart';
import '../services/storage/qql_storage.dart';
import '../widgets/quick_import_access.dart';

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

/// The authoring title prompt shared by the Course Editor's Lesson Options and
/// the Lessons screen. Returns null when cancelled or left empty.
Future<String?> askAuthoringName(
  BuildContext context, {
  String title = 'New Lesson',
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

const _hierarchyUpdates = CourseHierarchyUpdateService();

String _localCourseDateTime(BuildContext context, String utc) {
  final parsed = DateTime.tryParse(utc)?.toLocal();
  if (parsed == null) return 'Not recorded';
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatFullDate(parsed)} · '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
}

/// The same canonical exercise with another publication state. Course Model
/// v12: copied canonically, never rebuilt through the v11 views, which would
/// lose an inline layout.
Exercise _withExercisePublication(
  Exercise source,
  PublicationState state, {
  DateTime? updatedAt,
}) => source.withPublicationState(state, updatedAt: updatedAt);

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
      builder: (_) => _exerciseEditorFor(
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
  var changed = course;
  for (final exercise in saved.values) {
    changed = _hierarchyUpdates.apply(
      changed,
      UpsertExercise(lesson.lessonId, round.id, exercise),
    );
  }
  return changed;
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
  final _deviceState = CourseEditorDeviceState();
  final _profiles = ProfileService();
  late final _teams = TeamService(profileService: _profiles);
  final _recordedAudio = RecordedAudioService();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  late final CourseAuthoringSession _session;
  bool _routeMayPop = false;
  int _numberingFieldVersion = 0;

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
      final mode = await _deviceState.openingMode(
        _course.courseId,
        canEditOriginal: widget.access.canEditOriginal,
      );
      if (mounted) setState(() => _session.setEditorMode(mode));
      await _deviceState.runAutomaticOrphanCheck(
        courseCode: _code,
        canEditOriginal: widget.access.canEditOriginal,
        mode: mode,
        check: _checkOrphanAudio,
      );
    });
  }

  String get _code => CourseService.codeForCourse(_course);

  Course get _course => _session.workingCourse;

  bool get _dirty => _session.hasChanges;

  final _storyIds = TimestampAuthoringIdGenerator();

  bool get _canModify => _session.canModify;

  CourseEditorMode get _editorMode => _session.editorMode;

  CourseAuditResult? get _lastAudit => _session.lastAudit;

  bool get _auditOutdated => _session.auditOutdated;

  String get _pendingVersionNotes => _session.pendingVersionNotes;

  void _updateDraft(Course value) => setState(() {
    _session.stageCourse(value);
  });

  Course _adoptHierarchyDraft(
    Course candidate, {
    Course? previous,
    bool? usePrevious,
  }) {
    setState(() {
      _session.stageCourse(
        candidate,
        previous: previous,
        usePrevious: usePrevious ?? true,
      );
    });
    return _course;
  }

  Future<void> _popEditor([CourseConfirmationResult? result]) async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    // No confirmation result means this session is leaving without saving a
    // Course, on either the cancelled or the unchanged path. The recordings it
    // imported were written straight to disk, so the session owns them until
    // here. A confirmed Course tidies up inside its own confirmation instead.
    if (result == null) await _session.discardUnconfirmedMedia();
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
    // Build 255 Revision 7: a cover made from a picture whose credit QQL
    // knows adds that credit. The credit added last leaves again with the
    // next cover while nobody has changed its row.
    CourseMediaAttribution? coverCredit;
    TextEditingController? coverCreditRow;
    bool mediaCreditRowIs(int row, CourseMediaAttribution credit) =>
        mediaAuthors[row].text.trim() == credit.author &&
        mediaLicenses[row].text.trim() == credit.license &&
        mediaTitles[row].text.trim() == credit.title &&
        mediaSources[row].text.trim() == credit.source &&
        mediaAppliesTo[row].text.trim() == credit.appliesTo;
    void creditCover(CourseMediaAttribution? credit) {
      final previous = coverCredit;
      final previousController = coverCreditRow;
      final previousRow = previousController == null
          ? -1
          : mediaAuthors.indexOf(previousController);
      coverCredit = null;
      coverCreditRow = null;
      if (previous != null &&
          previousRow >= 0 &&
          mediaCreditRowIs(previousRow, previous)) {
        if (mediaAuthors.length == 1) {
          mediaAuthors.single.clear();
          mediaLicenses.single.clear();
          mediaTitles.single.clear();
          mediaSources.single.clear();
          mediaAppliesTo.single.clear();
        } else {
          mediaAuthors.removeAt(previousRow).dispose();
          mediaLicenses.removeAt(previousRow).dispose();
          mediaTitles.removeAt(previousRow).dispose();
          mediaSources.removeAt(previousRow).dispose();
          mediaAppliesTo.removeAt(previousRow).dispose();
        }
      }
      if (credit == null) return;
      for (var row = 0; row < mediaAuthors.length; row++) {
        if (mediaCreditRowIs(row, credit)) return;
      }
      final useBlank =
          mediaAuthors.length == 1 &&
          mediaCreditRowIs(
            0,
            const CourseMediaAttribution(author: '', license: ''),
          );
      if (!useBlank) addMediaCreditRow();
      final row = mediaAuthors.length - 1;
      mediaAuthors[row].text = credit.author;
      mediaLicenses[row].text = credit.license;
      mediaTitles[row].text = credit.title;
      mediaSources[row].text = credit.source;
      mediaAppliesTo[row].text = credit.appliesTo;
      coverCredit = credit;
      coverCreditRow = mediaAuthors[row];
    }

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
    var allowPageSharing = _course.allowPageSharing;
    var privateCourse = _course.temporarySample;
    String? mediaCreditError;
    var flagSelection = CourseFlagSelection.fromCourse(_course);
    var coverImage = _course.coverImage;
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
                    valueListenable: EditorDisplayPreferences.showInternalIds,
                    builder: (context, showInternalIds, _) => showInternalIds
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
                                    key: const Key('team-assignment-warning'),
                                    title: const Text('Assign Course to Team?'),
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
                                        onPressed: () =>
                                            Navigator.pop(warningContext, true),
                                        child: const Text('Confirm assignment'),
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
                          setLocalState(() => selectedAssignedTeamId = value);
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
                    valueListenable: EditorDisplayPreferences.showInternalIds,
                    builder: (context, showInternalIds, _) => showInternalIds
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
                      _localCourseDateTime(ctx, _course.originalCreatedAtUtc),
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
                    readOnlyField('Base language', baseLanguage.displayLabel),
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
                  CourseCoverField(
                    key: const Key('course-info-cover'),
                    courseId: _course.courseId,
                    course: _course,
                    cover: coverImage,
                    onChanged: (choice) => setLocalState(() {
                      coverImage = choice.cover;
                      creditCover(choice.credit);
                      mediaCreditError = null;
                    }),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                              customRoles.removeAt(i).dispose();
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
                                        onSelected: (on) => setLocalState(() {
                                          if (on) {
                                            selectedRoles[i].add(role);
                                          } else {
                                            selectedRoles[i].remove(role);
                                          }
                                        }),
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
                                    style: Theme.of(ctx).textTheme.bodySmall,
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
                  // Build 258 Revision 4 (owner decision): on by default.
                  SwitchListTile(
                    key: const Key('course-info-page-sharing'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Learners may share, save and print pages',
                    ),
                    subtitle: const Text(
                      'Shows Share, Save PDF and Print under every Page; the PDF credits this Course, its rights holder and licence. A courtesy, not protection: a screenshot is always possible.',
                    ),
                    value: allowPageSharing,
                    onChanged: (value) =>
                        setLocalState(() => allowPageSharing = value),
                  ),
                  // Build 259 Revision 8 (owner decisions): the flag stored as
                  // temporarySample, shown as Private course.
                  SwitchListTile(
                    key: const Key('course-info-private'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Private course'),
                    subtitle: const Text(
                      'Visible in QQL only to the Course Maintainer and the members of its assigned Team; nobody else on this device sees it, admins included. An exported file stays private; Fork and Copy as New Course start non-private.',
                    ),
                    value: privateCourse,
                    onChanged: (value) =>
                        setLocalState(() => privateCourse = value),
                  ),
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
                                  icon: const Icon(Icons.remove_circle_outline),
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
                                  value: CourseRightsHolderType.organization,
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
                        rightsHolderTypes.add(CourseRightsHolderType.person);
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
                                  icon: const Icon(Icons.remove_circle_outline),
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
                      onPressed: () => setLocalState(() => addMediaCreditRow()),
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
                        error.message?.toString() ?? 'Check the Course name.',
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
                          onPressed: () => Navigator.pop(warningContext, false),
                          child: const Text('Edit name'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(warningContext, true),
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
                      throw FormatException('$label must be a whole number.');
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
                    CourseRightsHolder(type: rightsHolderTypes[i], name: name),
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
                  allowPageSharing: allowPageSharing,
                  privateCourse: privateCourse,
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
                  coverImage: coverImage,
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
    ).apply(_course, result, activeProfileId);
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
        !await _deviceState.hasSeenViewOnlyNotice(_course.courseId)) {
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
      await _deviceState.markViewOnlyNoticeSeen(_course.courseId);
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
          adoptCourse: _canModify ? _adoptHierarchyDraft : null,
          clock: _clock,
        ),
      ),
    );
    if (updated != null &&
        _canModify &&
        !_sameAuthoringJson(updated.toJson(), _course.toJson())) {
      _updateDraft(updated);
    }
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
    await _deviceState.setMode(_course.courseId, mode);
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
      await _session.confirm(languageCode: _code, versionNotes: versionNotes);
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

  /// Course-level Lesson settings, shown under the Lessons tile. They were on
  /// the Lessons screen but none of them is a Lesson property.
  /// Build 256 Revision 5: who speaks in this Course's Stories.
  String get _storyCharactersSummary {
    final narrator = _course.narrator.name;
    final count = _course.storyCharacters.length;
    return '${narrator.isEmpty ? 'Unnamed narrator' : 'Narrator: $narrator'} · '
        '$count character${count == 1 ? '' : 's'}';
  }

  static String _speakerSummary(StorySpeaker speaker) =>
      '${speaker.language == TextLanguage.source ? 'Source' : 'Target'} '
      'language · voice ${speaker.voice.serialized}';

  /// How many Dialogue lines of this Course a speaker says.
  int _linesSpokenBy(String speakerId) {
    var count = 0;
    for (final lesson in _course.lessons) {
      for (final round in lesson.rounds) {
        for (final content in round.content) {
          final exercise = content.exercise;
          if (exercise != null &&
              exercise.promptElements.any(
                (element) => element.speakerId == speakerId,
              )) {
            count++;
          }
        }
      }
    }
    return count;
  }

  /// The working copy with [narrator] and [characters] and, when a library
  /// picture with a known credit became an avatar, that credit among the
  /// Media credits (once).
  Course _withSpeakers({
    StorySpeaker? narrator,
    List<StorySpeaker>? characters,
    CourseMediaAttribution? credit,
  }) {
    final credits = [..._course.mediaAttributions];
    if (credit != null &&
        !credits.any(
          (known) => jsonEncode(known.toJson()) == jsonEncode(credit.toJson()),
        )) {
      credits.add(credit);
    }
    final json = {..._course.toJson()}
      ..remove('storyNarrator')
      ..remove('storyCharacters')
      ..remove('mediaAttributions');
    final speaker = narrator ?? _course.storyNarrator;
    final list = characters ?? _course.storyCharacters;
    return Course.fromJson({
      ...json,
      if (speaker != null) 'storyNarrator': speaker.toJson(),
      if (list.isNotEmpty)
        'storyCharacters': [for (final character in list) character.toJson()],
      if (credits.isNotEmpty)
        'mediaAttributions': [for (final known in credits) known.toJson()],
    });
  }

  Future<void> _editSpeaker(
    StorySpeaker speaker, {
    required bool narrator,
  }) async {
    final choice = await showStorySpeakerDialog(
      context,
      course: _course,
      speaker: speaker,
      narrator: narrator,
      readOnly: !_canModify,
    );
    if (choice == null || !mounted) return;
    _updateDraft(
      _withSpeakers(
        narrator: narrator ? choice.speaker : null,
        characters: narrator
            ? null
            : [
                for (final character in _course.storyCharacters)
                  character.id == choice.speaker.id
                      ? choice.speaker
                      : character,
              ],
        credit: choice.credit,
      ),
    );
  }

  Future<void> _addCharacter() async {
    final choice = await showStorySpeakerDialog(
      context,
      course: _course,
      speaker: StorySpeaker(
        id: _storyIds.next('character'),
        language: TextLanguage.target,
      ),
      narrator: false,
    );
    if (choice == null || !mounted) return;
    _updateDraft(
      _withSpeakers(
        characters: [..._course.storyCharacters, choice.speaker],
        credit: choice.credit,
      ),
    );
  }

  /// Removing a character that lines still name is refused with the count
  /// (owner decision: no silent fallback to the narrator).
  Future<void> _removeCharacter(StorySpeaker character) async {
    final lines = _linesSpokenBy(character.id);
    if (lines > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('“${character.name}” still speaks'),
          content: Text(
            '$lines Dialogue line${lines == 1 ? '' : 's'} of this Course name this character. Give those lines another speaker first; QQL never hands them to the narrator silently.',
            key: const Key('story-character-in-use'),
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
    _updateDraft(
      _withSpeakers(
        characters: [
          for (final other in _course.storyCharacters)
            if (other.id != character.id) other,
        ],
      ),
    );
  }

  List<Widget> _storyCharacterRows() => [
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        'Who speaks in this Course\'s Stories: the narrator and reusable characters, each with a name, an avatar, a language and a voice preference. A Dialogue line names one of them.',
      ),
    ),
    ListTile(
      key: const Key('story-narrator'),
      leading: StoryAvatar(
        speaker: _course.narrator,
        courseId: _course.courseId,
      ),
      title: Text(
        _course.narrator.name.isEmpty
            ? 'Narrator (unnamed)'
            : 'Narrator: ${_course.narrator.name}',
      ),
      subtitle: Text(_speakerSummary(_course.narrator)),
      trailing: Icon(_canModify ? Icons.edit_outlined : Icons.chevron_right),
      onTap: () => _editSpeaker(_course.narrator, narrator: true),
    ),
    for (final character in _course.storyCharacters)
      ListTile(
        key: ValueKey('story-character-${character.id}'),
        leading: StoryAvatar(speaker: character, courseId: _course.courseId),
        title: Text(character.name),
        subtitle: Text(_speakerSummary(character)),
        trailing: _canModify
            ? IconButton(
                key: ValueKey('story-character-remove-${character.id}'),
                tooltip: 'Remove character',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeCharacter(character),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _editSpeaker(character, narrator: false),
      ),
    if (_canModify)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('story-character-add'),
            onPressed: _addCharacter,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add character'),
          ),
        ),
      ),
  ];

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
    SwitchListTile(
      key: const Key('course-use-guidebook'),
      title: const Text('Use GuideBook'),
      value: _course.useGuidebook,
      onChanged: _canModify
          ? (value) => _updateDraft(
              Course.fromJson({..._course.toJson(), 'useGuidebook': value}),
            )
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
          ? (value) => _updateDraft(
              Course.fromJson({..._course.toJson(), 'createDuels': value}),
            )
          : null,
    ),
  ];

  Future<void> _setLessonNumbering(LessonNumberingMode? mode) async {
    if (!_canModify || mode == null) return;
    var label = _course.customLessonLabel;
    if (mode == LessonNumberingMode.other) {
      final entered = await askAuthoringName(
        context,
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
    _updateDraft(
      Course.fromJson({
        ..._course.toJson(),
        'lessonNumberingMode': mode.name,
        'customLessonLabel': mode == LessonNumberingMode.other ? label : '',
      }),
    );
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
                builder: (_) => _exerciseEditorFor(
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
                          setState(() {
                            _session.applyHierarchyUpdate(
                              UpsertExercise(
                                lesson.lessonId,
                                round.id,
                                exercise,
                              ),
                            );
                          });
                        },
                ),
              ),
            );
            if (updatedExercise != null) {
              savedExercises[updatedExercise.id] = updatedExercise;
            }
            if (savedExercises.isNotEmpty) {
              // A live Save may already have staged and reconciled this Round.
              // Build the route-result fallback from that canonical snapshot.
              final currentRound = _course.lessons
                  .firstWhere((item) => item.lessonId == lesson.lessonId)
                  .rounds
                  .firstWhere((item) => item.id == round.id);
              final content = [
                for (final item in currentRound.content)
                  savedExercises.containsKey(item.id)
                      ? _hierarchyUpdates.replaceExerciseContent(
                          item,
                          savedExercises[item.id]!,
                        )
                      : item,
              ];
              updatedRound = LearningRound(
                id: currentRound.id,
                publicationState: currentRound.publicationState,
                provisionalDraft: currentRound.provisionalDraft,
                updatedAt: currentRound.updatedAt,
                title: currentRound.title,
                visualType: currentRound.visualType,
                content: content,
                flow: currentRound.flow,
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
              adoptCourse: _canModify ? _adoptHierarchyDraft : null,
              lesson: lesson,
              round: round,
              roundIndex: ri,
              readOnly: !_canModify,
              courseEditorMode: _editorMode,
            ),
          ),
        );
        if (updatedRound == null || !mounted) return;
        final candidate = _hierarchyUpdates.apply(
          _course,
          ReplaceRound(lesson.lessonId, round.id, updatedRound),
        );
        if (!_sameAuthoringJson(candidate.toJson(), _course.toJson())) {
          _updateDraft(candidate);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyStatus = AuthoringHierarchyStatus.fromCourse(_course);
    // Even an unchanged working copy leaves through _attemptLeave, because a
    // session can have imported recordings to disk without the draft keeping
    // them. _popEditor is then the one place that ends the media's lifetime.
    return PopScope(
      canPop: _routeMayPop,
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
                  // Build 255 Revision 6: the cover, as in Courses, when the
                  // Course has one.
                  if (Course.coverImagePattern.hasMatch(_course.coverImage))
                    CourseArtwork(
                      key: const Key('course-editor-header-cover'),
                      course: _course,
                      size: 38,
                    )
                  else
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
            // These three are Course properties, not Lesson properties, so
            // they belong on the Course screen. Collapsed until tapped, and
            // the expansion is page-session presentation state only.
            ExpansionTile(
              key: const Key('course-lesson-options'),
              initiallyExpanded: false,
              leading: const Icon(Icons.tune_outlined),
              title: const Text('Lesson Options'),
              children: _lessonOptions(),
            ),
            // Build 256 Revision 5: the narrator and the characters this
            // Course's Stories reuse; collapsed like Lesson Options.
            ExpansionTile(
              key: const Key('course-story-characters'),
              initiallyExpanded: false,
              leading: const Icon(Icons.theater_comedy_outlined),
              title: const Text('Story characters'),
              subtitle: Text(_storyCharactersSummary),
              children: _storyCharacterRows(),
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
    this.adoptCourse,
    this.clock,
  });

  final Course course;
  final bool initiallyLocked;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;
  final ValueChanged<Course>? onCourseChanged;
  final CourseDraftAdopter? adoptCourse;
  final DateTime Function()? clock;

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen> {
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
  }) => _hierarchyUpdates.apply(
    _course,
    ReplaceLessons(lessons, lessonIconAssets: lessonIconAssets),
  );

  void _adoptCourse(Course course) {
    if (!mounted) return;
    course =
        widget.adoptCourse?.call(course, previous: _course) ??
        const ProvisionalPublicationService().reconcile(
          course,
          updatedAt: _clock(),
          previous: _course,
        );
    setState(() => _course = course);
    widget.onCourseChanged?.call(course);
  }

  void _receiveCourse(Course course) {
    if (!mounted) return;
    setState(() => _course = course);
    widget.onCourseChanged?.call(course);
  }

  void _replaceLessons(
    List<Lesson> lessons, {
    List<CourseLessonIconAsset>? lessonIconAssets,
  }) => _adoptCourse(_withLessons(lessons, lessonIconAssets: lessonIconAssets));

  Future<void> _returnToCourse() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _course);
  }

  Future<String?> _askName({
    String title = 'New Lesson',
    String initial = '',
    String confirmLabel = 'Create',
    int? maxLength,
  }) => askAuthoringName(
    context,
    title: title,
    initial: initial,
    confirmLabel: confirmLabel,
    maxLength: maxLength,
  );

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
                  _receiveCourse(course);
                },
          adoptCourse: _locked ? null : widget.adoptCourse,
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
    final candidate = _withLessons(lessons, lessonIconAssets: iconAssets);
    if (!_sameAuthoringJson(candidate.toJson(), _course.toJson())) {
      _adoptCourse(candidate);
    }
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
                label: const Text('New Lesson'),
              ),
        body: Column(
          children: [
            EditorBreadcrumbs(course: _course),
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
  final CourseDraftAdopter? adoptCourse;
  final Lesson lesson;
  final ValueChanged<List<CourseLessonIconAsset>>? onLessonIconAssetsChanged;
  final DateTime Function()? clock;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;
  const LessonEditorScreen({
    super.key,
    required this.course,
    this.onCourseChanged,
    this.adoptCourse,
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

  Course get _courseWithIcons => _hierarchyUpdates.apply(
    _course,
    OverlayLessonDraft(_lesson, lessonIconAssets: _lessonIconAssets),
  );

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
    course =
        widget.adoptCourse?.call(course, previous: _course) ??
        const ProvisionalPublicationService().reconcile(
          course,
          updatedAt: _clock(),
          previous: _course,
        );
    _receiveCourse(course);
  }

  void _receiveCourse(Course course) {
    if (!mounted) return;
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
    final course = _hierarchyUpdates.apply(
      _course,
      ReplaceLesson(
        lesson.lessonId,
        lesson,
        lessonIconAssets: _lessonIconAssets,
      ),
    );
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
        !await confirmMoveToDraft(context, 'Lesson')) {
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
          flow: round.flow,
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
          onCourseChanged: widget.readOnly ? null : _receiveCourse,
          adoptCourse: widget.readOnly ? null : widget.adoptCourse,
          lesson: draftLesson,
          readOnly: widget.readOnly,
          courseEditorMode: widget.courseEditorMode,
          clock: _clock,
        ),
      ),
    );
    if (!widget.readOnly && rounds != null && mounted) {
      final candidate = _copy(rounds: rounds);
      if (!_sameAuthoringJson(candidate.toJson(), _lesson.toJson())) {
        _publishLesson(candidate);
      }
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
      var fromDialog = selected == importFrom;
      if (!fromDialog) {
        switch (await ensureQuickImportAccess(
          context,
          offerOpenFrom: _lessonIcons.fileDialogsAvailable,
        )) {
          case QuickImportAccess.ready:
            break;
          case QuickImportAccess.openFrom:
            fromDialog = true;
          case QuickImportAccess.stop:
            return;
        }
        if (!mounted) return;
      }
      try {
        final ImportedLessonIcon imported;
        if (fromDialog) {
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
        showImageCreditReminder(
          context,
          lead: 'Custom icon imported and normalized to a 256x256 PNG.',
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
                OutlinedButton.icon(
                  key: const Key('lesson-preview'),
                  onPressed: _previewLesson,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Preview'),
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
            EditorBreadcrumbs(
              course: _courseWithIcons,
              lessonId: _lesson.lessonId,
            ),
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
            location:
                '${round.displayTitle(roundIndex)} · ${_exerciseKindName(exercise)}',
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

/// What the Story Wizard hands back (Build 256 Revision 5): the Story
/// Round, the narrator and characters as edited in its steps, and the
/// credits of library pictures that became avatars.
typedef StoryWizardResult = ({
  LearningRound round,
  StorySpeaker narrator,
  List<StorySpeaker> characters,
  List<CourseMediaAttribution> credits,
});

/// The presets an exercise step of a Story may use (story plan §5).
const storyWizardPresets = <String>[
  'true_false',
  'choice_target',
  'choice_source',
  'translation_choice_to_target',
  'translation_choice_to_source',
  'listening_choose_target',
  'listening_choose_source',
  'listening_answer_target',
  'listening_answer_source',
  'word_order',
  'missing_word',
  'type_missing_word',
  'complete_text',
];

enum _StoryWizardStage { story, narrator, characters, builder }

/// New Story, the Story Wizard (Build 256 Revision 5, `docs/256_STORY_PLAN.md`
/// §5; a button of the Rounds page since the third follow-up):
/// A the Story (title, cover picture, read-aloud), B the narrator, C the
/// characters, then the builder, where lines (an inline form) and
/// exercises (the normal exercise form on top of this route) are added,
/// reordered and removed. Finish creates the Round: visual type story,
/// title `Story: <title>`, a linear scrolling flow logging the dialogue,
/// the cover first, and the exercises marked as needing the Story's audio.
class StoryWizardScreen extends StatefulWidget {
  const StoryWizardScreen({
    super.key,
    required this.course,
    required this.lesson,
    this.clock,
  });

  final Course course;
  final Lesson lesson;
  final DateTime Function()? clock;

  @override
  State<StoryWizardScreen> createState() => _StoryWizardScreenState();
}

class _StoryWizardScreenState extends State<StoryWizardScreen> {
  final _title = TextEditingController();
  final _ids = TimestampAuthoringIdGenerator();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  _StoryWizardStage _stage = _StoryWizardStage.story;
  String _cover = '';
  SharedImageSource? _coverSource;
  FlowReadAloud _readAloud = FlowReadAloud.automatic;
  late StorySpeaker _narrator = widget.course.narrator;
  late final List<StorySpeaker> _characters = [
    ...widget.course.storyCharacters,
  ];
  final List<CourseMediaAttribution> _credits = [];
  final List<Exercise> _steps = [];
  final Set<String> _audio = {};

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// The Course as the exercise form should see it: with the speakers
  /// edited here, so a line form offers them.
  Course get _courseForEditing => _courseWithSpeakers(
    widget.course,
    narrator: _narrator,
    characters: _characters,
    credits: _credits,
  );

  bool get _hasLine => _steps.any(_isLine);

  static bool _isLine(Exercise exercise) =>
      ExerciseFeatures(exercise).kind == LearnerExerciseKind.dialogueLine;

  StorySpeaker _speakerOf(String speakerId) => speakerId.isEmpty
      ? _narrator
      : _characters.firstWhere(
          (character) => character.id == speakerId,
          orElse: () => StorySpeaker(
            id: speakerId,
            name: 'Unknown character',
            language: TextLanguage.target,
          ),
        );

  Exercise _blank(String id) => Exercise.canonical(
    id: id,
    primitive: ExercisePrimitive.presentation,
    canonicalEvaluation: CanonicalEvaluation.none,
    updatedAt: _clock().toUtc(),
  );

  Exercise _lineExercise(String id, StoryLineValues values) =>
      _dialogueLineExercise(id, values, updatedAt: _clock().toUtc());

  void _next() => setState(
    () => _stage =
        _StoryWizardStage.values[_StoryWizardStage.values.indexOf(_stage) + 1],
  );

  void _back() => setState(
    () => _stage =
        _StoryWizardStage.values[_StoryWizardStage.values.indexOf(_stage) - 1],
  );

  Future<void> _editNarrator() async {
    final choice = await showStorySpeakerDialog(
      context,
      course: widget.course,
      speaker: _narrator,
      narrator: true,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _narrator = choice.speaker;
      if (choice.credit case final credit?) _credits.add(credit);
    });
  }

  Future<void> _addCharacter() async {
    final choice = await showStorySpeakerDialog(
      context,
      course: widget.course,
      speaker: StorySpeaker(
        id: _ids.next('character'),
        language: TextLanguage.target,
      ),
      narrator: false,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _characters.add(choice.speaker);
      if (choice.credit case final credit?) _credits.add(credit);
    });
  }

  Future<void> _editCharacter(int index) async {
    final choice = await showStorySpeakerDialog(
      context,
      course: widget.course,
      speaker: _characters[index],
      narrator: false,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _characters[index] = choice.speaker;
      if (choice.credit case final credit?) _credits.add(credit);
    });
  }

  Future<void> _addLine() async {
    final values = await showStoryLineDialog(
      context,
      narrator: _narrator,
      characters: _characters,
    );
    if (values == null || !mounted) return;
    setState(() => _steps.add(_lineExercise(_ids.next('exercise'), values)));
  }

  Future<void> _editLine(int index) async {
    final draft = PresetRecipes.decompose(_steps[index], 'dialogue_line');
    final values = await showStoryLineDialog(
      context,
      narrator: _narrator,
      characters: _characters,
      initial: (
        speakerId: draft.speakerId,
        text: draft.prompt,
        mode: draft.lineMode,
        readAloud: draft.lineReadAloud,
        textReveal: draft.lineTextReveal,
      ),
    );
    if (values == null || !mounted) return;
    setState(() => _steps[index] = _lineExercise(_steps[index].id, values));
  }

  void _acceptStep(Exercise exercise) {
    if (!mounted) return;
    setState(() {
      final index = _steps.indexWhere((step) => step.id == exercise.id);
      if (index < 0) {
        _steps.add(exercise);
      } else {
        _steps[index] = exercise;
      }
    });
  }

  Future<void> _addExercise() async {
    final presetId = await _chooseStoryPreset(context);
    if (presetId == null || !mounted) return;
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => _exerciseEditorFor(
          exercise: _blankExerciseForPreset(presetId, _ids),
          title: 'New Exercise',
          isNew: true,
          course: _courseForEditing,
          lesson: widget.lesson,
          onExerciseSaved: _acceptStep,
          clock: _clock,
        ),
      ),
    );
    if (exercise != null && mounted) _acceptStep(exercise);
  }

  Future<void> _editExercise(int index) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => _exerciseEditorFor(
          exercise: _steps[index],
          title: 'Edit exercise',
          isNew: false,
          course: _courseForEditing,
          lesson: widget.lesson,
          onExerciseSaved: _acceptStep,
          clock: _clock,
        ),
      ),
    );
    if (exercise != null && mounted) _acceptStep(exercise);
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _steps.length) return;
    setState(() => _steps.insert(target, _steps.removeAt(index)));
  }

  void _remove(int index) => setState(() {
    _audio.remove(_steps[index].id);
    _steps.removeAt(index);
  });

  void _finish() {
    if (!_hasLine) return;
    final title = _title.text.trim();
    // The cover carries the Story title as its title line, so it is a cover
    // with or without a picture; the cover card shows the title once.
    final cover = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _blank(_ids.next('exercise')),
        type: 'story_cover',
        publicationState: PublicationState.published,
        prompt: title,
        imageAsset: _cover,
        selectedSharedSource: _coverSource,
        attachSelectedSharedSource: true,
      ),
    ).candidate!;
    final content = [
      for (final exercise in [cover, ..._steps])
        LearningContent.fromExercise(exercise),
    ];
    // The Round is named after the Story; lists derive "Story: <title>"
    // from the flow (LearningRound.displayTitle).
    final round = LearningRound(
      id: _ids.next('round'),
      publicationState: PublicationState.draft,
      provisionalDraft: true,
      updatedAt: _clock().toUtc(),
      title: title,
      visualType: 'story',
      content: content,
      flow: RoundFlowAuthoring.linearFor(
        content,
        presentation: FlowPresentation.scroll,
        title: title,
        log: FlowLog.dialogue,
        readAloud: _readAloud,
        requiresAudio: _audio,
      ),
    );
    Navigator.pop(context, (
      round: round,
      narrator: _narrator,
      characters: List<StorySpeaker>.unmodifiable(_characters),
      credits: List<CourseMediaAttribution>.unmodifiable(_credits),
    ));
  }

  static String _speakerSummary(StorySpeaker speaker) =>
      '${speaker.language == TextLanguage.source ? 'Source' : 'Target'} '
      'language · voice ${speaker.voice.serialized}';

  @override
  Widget build(BuildContext context) {
    final index = _StoryWizardStage.values.indexOf(_stage);
    const names = ['Story', 'Narrator', 'Characters', 'Steps'];
    return Scaffold(
      appBar: AppBar(
        title: Text('New Story · ${names[index]} (${index + 1} of 4)'),
        actions: const [EditorAppBarActions()],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                key: const Key('story-wizard-cancel'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (index > 0)
                OutlinedButton(
                  key: const Key('story-wizard-back'),
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              if (_stage != _StoryWizardStage.builder)
                FilledButton(
                  key: const Key('story-wizard-next'),
                  onPressed:
                      _stage == _StoryWizardStage.story &&
                          _title.text.trim().isEmpty
                      ? null
                      : _next,
                  child: const Text('Next'),
                )
              else
                FilledButton.icon(
                  key: const Key('story-wizard-finish'),
                  onPressed: _hasLine ? _finish : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish'),
                ),
            ],
          ),
        ),
      ),
      body: switch (_stage) {
        _StoryWizardStage.story => _storyStep(),
        _StoryWizardStage.narrator => _narratorStep(),
        _StoryWizardStage.characters => _charactersStep(),
        _StoryWizardStage.builder => _builderStep(),
      },
    );
  }

  Widget _storyStep() => ListView(
    key: const Key('story-wizard-step-story'),
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'A Story is a Round played in order: a cover, dialogue lines said by the narrator or by characters, and exercises about them. Name it, choose its cover picture and how its lines are read aloud.',
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('story-wizard-title'),
        controller: _title,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Story title',
          helperText:
              'Shown on the cover; the Round is called “Story: <title>”.',
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Cover picture',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      ExerciseImageField(
        course: widget.course,
        asset: _cover,
        sharedSource: _coverSource,
        readOnly: false,
        onChanged: (change) => setState(() {
          _cover = change.asset;
          _coverSource = change.source;
        }),
      ),
      const SizedBox(height: 16),
      const Text('Read-aloud', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      SegmentedButton<FlowReadAloud>(
        key: const Key('story-wizard-read-aloud'),
        segments: const [
          ButtonSegment(
            value: FlowReadAloud.automatic,
            label: Text('Read aloud automatically'),
            icon: Icon(Icons.volume_up_outlined),
          ),
          ButtonSegment(
            value: FlowReadAloud.manual,
            label: Text('On request'),
            icon: Icon(Icons.touch_app_outlined),
          ),
        ],
        selected: {_readAloud},
        onSelectionChanged: (values) =>
            setState(() => _readAloud = values.first),
      ),
      const SizedBox(height: 8),
      const Text(
        'A line may override this. Lines are never skipped: without audio the learner reads them.',
      ),
    ],
  );

  Widget _narratorStep() => ListView(
    key: const Key('story-wizard-step-narrator'),
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'The narrator says every line without a character. Its name, avatar, language and voice are Course data, shared by every Story of this Course.',
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          key: const Key('story-wizard-narrator'),
          leading: StoryAvatar(
            speaker: _narrator,
            courseId: widget.course.courseId,
          ),
          title: Text(
            _narrator.name.isEmpty
                ? 'Narrator (unnamed)'
                : 'Narrator: ${_narrator.name}',
          ),
          subtitle: Text(_speakerSummary(_narrator)),
          trailing: const Icon(Icons.edit_outlined),
          onTap: _editNarrator,
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('story-wizard-edit-narrator'),
          onPressed: _editNarrator,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit narrator'),
        ),
      ),
    ],
  );

  Widget _charactersStep() => ListView(
    key: const Key('story-wizard-step-characters'),
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Characters are Course data too: the ones below are already known to this Course. Add the ones this Story needs, or edit them. Characters are removed in the Course Editor › Story characters, which checks that no line still names them.',
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _characters.length; i++)
        Card(
          child: ListTile(
            key: ValueKey('story-wizard-character-${_characters[i].id}'),
            leading: StoryAvatar(
              speaker: _characters[i],
              courseId: widget.course.courseId,
            ),
            title: Text(_characters[i].name),
            subtitle: Text(_speakerSummary(_characters[i])),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editCharacter(i),
          ),
        ),
      if (_characters.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No character yet. A Story may also be told by the narrator alone.',
          ),
        ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('story-wizard-add-character'),
          onPressed: _addCharacter,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add character'),
        ),
      ),
    ],
  );

  Widget _builderStep() => ListView(
    key: const Key('story-wizard-step-builder'),
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'The Story in order, after its cover. Add lines and exercises, move them, remove them. Only exercises count for XP; a line is read or heard and continued. Finish needs at least one line.',
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _steps.length; i++) _stepCard(i),
      if (_steps.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No step yet.'),
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            key: const Key('story-wizard-add-line'),
            onPressed: _addLine,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Add line'),
          ),
          FilledButton.tonalIcon(
            key: const Key('story-wizard-add-exercise'),
            onPressed: _addExercise,
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Add exercise'),
          ),
        ],
      ),
    ],
  );

  Widget _stepCard(int i) {
    final step = _steps[i];
    final line = _isLine(step);
    final features = ExerciseFeatures(step);
    final preset = ExercisePresetRegistry.byId(step.editorTemplate);
    final speaker = line ? _speakerOf(features.speakerId) : null;
    return Card(
      key: ValueKey('story-wizard-step-${step.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: line
                ? StoryAvatar(
                    speaker: speaker!,
                    courseId: widget.course.courseId,
                  )
                : _PresetActionChip(preset?.action ?? 'Exercise'),
            title: Text(
              line
                  ? (features.lineText.isEmpty
                        ? '(audio only)'
                        : features.lineText)
                  : preset?.name ?? 'Exercise',
            ),
            subtitle: Text(
              line
                  ? '${i + 1}. ${speaker!.isNarrator ? (speaker.name.isEmpty ? 'Narrator' : speaker.name) : speaker.name} · ${features.lineMode}'
                  : '${i + 1}. ${step.publicationState.isPublished ? 'Published' : 'Draft'} exercise',
            ),
            onTap: () => line ? _editLine(i) : _editExercise(i),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ValueKey('story-wizard-up-$i'),
                  tooltip: 'Move up',
                  onPressed: i == 0 ? null : () => _move(i, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  key: ValueKey('story-wizard-down-$i'),
                  tooltip: 'Move down',
                  onPressed: i == _steps.length - 1 ? null : () => _move(i, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  key: ValueKey('story-wizard-remove-$i'),
                  tooltip: 'Remove',
                  onPressed: () => _remove(i),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          if (!line)
            CheckboxListTile(
              key: ValueKey('story-wizard-audio-${step.id}'),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Needs the Story\'s audio'),
              subtitle: const Text(
                'Skipped, like the audio exercises, when the learner has Audio Exercises off.',
              ),
              value: _audio.contains(step.id),
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _audio.add(step.id);
                } else {
                  _audio.remove(step.id);
                }
              }),
            ),
        ],
      ),
    );
  }
}

class LessonRoundsScreen extends StatefulWidget {
  final Course course;
  final ValueChanged<Course>? onCourseChanged;
  final CourseDraftAdopter? adoptCourse;
  final Lesson lesson;
  final DateTime Function()? clock;
  final bool readOnly;
  final CourseEditorMode courseEditorMode;

  const LessonRoundsScreen({
    super.key,
    required this.course,
    this.onCourseChanged,
    this.adoptCourse,
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
    _course = _hierarchyUpdates.apply(
      _course,
      OverlayLessonDraft(widget.lesson),
    );
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
    course =
        widget.adoptCourse?.call(course, previous: _course) ??
        const ProvisionalPublicationService().reconcile(
          course,
          updatedAt: _clock(),
          previous: _course,
        );
    _receiveCourse(course);
  }

  void _receiveCourse(Course course) {
    if (!mounted) return;
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
    final index = _course.lessons.indexWhere(
      (lesson) => lesson.lessonId == widget.lesson.lessonId,
    );
    if (index < 0) return _course;
    return _hierarchyUpdates.apply(
      _course,
      ReplaceRounds(widget.lesson.lessonId, rounds),
    );
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
    final title = await _name('New Round', allowEmpty: true);
    if (title != null && mounted) {
      _updateRounds([..._rounds, _blankRound(title)]);
    }
  }

  /// The Round Wizard (on this page since the Build 256 Revision 5 third
  /// follow-up; the Lesson editor's bottom bar before): the approved Rounds
  /// are appended after the existing ones through the authoring session.
  Future<void> _openGuidebookRoundGenerator() async {
    if (widget.readOnly) return;
    final generated = await Navigator.of(context).push<List<LearningRound>>(
      MaterialPageRoute(
        builder: (_) => GuidebookRoundGeneratorScreen(
          course: _auditableCourse,
          lesson: _draftLesson,
          clock: _clock,
        ),
      ),
    );
    if (generated == null || generated.isEmpty || !mounted) return;
    _updateRounds([..._rounds, ...generated]);
  }

  /// New Story (the Story Wizard, Build 256 Revision 5) builds one Story
  /// Round (a cover, lines and exercises) and hands back the narrator and
  /// characters it edited; both reach the working copy through the
  /// authoring session, so the Course confirmation still decides.
  Future<void> _openStoryWizard() async {
    if (widget.readOnly) return;
    final result = await Navigator.of(context).push<StoryWizardResult>(
      MaterialPageRoute(
        builder: (_) => StoryWizardScreen(
          course: _auditableCourse,
          lesson: _draftLesson,
          clock: _clock,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _adoptCourse(
      _hierarchyUpdates.apply(
        _courseWithSpeakers(
          _course,
          narrator: result.narrator,
          characters: result.characters,
          credits: result.credits,
        ),
        ReplaceRounds(widget.lesson.lessonId, [..._rounds, result.round]),
      ),
    );
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
          onCourseChanged: _receiveCourse,
          adoptCourse: widget.readOnly ? null : widget.adoptCourse,
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
      if (!_sameAuthoringJson(
        updated.toJson(),
        _rounds[currentIndex].toJson(),
      )) {
        _updateRounds(rounds);
      }
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
      flow: source.flow,
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
        bottomNavigationBar: widget.readOnly
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // New Round sits with Round Wizard and New Story, in
                      // their size and colour (owner request, 29 September
                      // 2026; it was a floating button).
                      FilledButton.icon(
                        key: const Key('rounds-new-round'),
                        style: _compactButtonStyle,
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('New Round'),
                      ),
                      Tooltip(
                        message: _course.useGuidebook
                            ? 'Generate Rounds from this Lesson\'s GuideBook.'
                            : 'The Round Wizard builds Rounds from the Lesson GuideBook. Turn on Use GuideBook in the Course Editor\'s Lesson Options to use it.',
                        child: FilledButton.icon(
                          key: const Key('rounds-round-wizard'),
                          style: _compactButtonStyle,
                          onPressed: _course.useGuidebook
                              ? _openGuidebookRoundGenerator
                              : null,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Round Wizard'),
                        ),
                      ),
                      FilledButton.icon(
                        key: const Key('rounds-new-story'),
                        style: _compactButtonStyle,
                        onPressed: _openStoryWizard,
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('New Story'),
                      ),
                    ],
                  ),
                ),
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
  final CourseDraftAdopter? adoptCourse;
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
    this.adoptCourse,
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

  /// The Round's content flow (a Story), kept through every edit: a linear
  /// flow follows the edited content order (`RoundFlowAuthoring`).
  ContentFlow? _flow;

  /// The Story title field (Build 256 Revision 5): the flow carries the
  /// title and the Round is called `Story: <title>`. In a sequence it is the
  /// optional sequence title (`Sequence: <title>`).
  late final TextEditingController _storyTitle = TextEditingController(
    text: widget.round.flow?.title ?? '',
  );

  /// A Story, made with New Story, rather than a sequence (a plain Round
  /// played in order, made with New Round and Play as a sequence): the
  /// Round carries the `story` visual type (Build 256 Revision 7, third
  /// follow-up; `LearningRound.isStory`).
  bool get _isStory =>
      _flow != null && widget.round.visualType == LearningRound.storyVisualType;

  /// What the options' texts call this Round: a Story or a sequence.
  String get _flowNoun => _isStory ? 'Story' : 'sequence';
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
    _flow = widget.round.flow;
  }

  @override
  void dispose() {
    _storyTitle.dispose();
    super.dispose();
  }

  LearningRound _editedRound({
    PublicationState? publicationState,
    DateTime? updatedAt,
  }) {
    final content = _editedContent();
    return LearningRound(
      id: widget.round.id,
      publicationState: publicationState ?? _publicationState,
      provisionalDraft: publicationState == null ? _provisionalDraft : false,
      updatedAt: updatedAt ?? _updatedAt,
      title: _title,
      visualType: widget.round.visualType,
      content: content,
      flow: RoundFlowAuthoring.forContent(_flow, content),
    );
  }

  /// Story on: the exercises play in this order, unshuffled, without a
  /// mistake review. Off: an ordinary practice Round. Turning a branching
  /// Story off removes a flow QQL's forms cannot rebuild, so it asks first.
  Future<void> _setStory(bool on) async {
    if (widget.readOnly) return;
    if (on && widget.round.visualType != LearningRound.storyVisualType) {
      // A sequence (Build 256 Revision 7, third follow-up) is a plain Round
      // played in order: one exercise per page, every finished item kept
      // when it scrolls, and an optional title the author types.
      _storyTitle.text = '';
      _mutateRound(
        () => _flow = RoundFlowAuthoring.linearFor(_editedContent()),
      );
      return;
    }
    if (on) {
      // A new Story (Build 256 Revision 5) scrolls, logs the dialogue only
      // and reads aloud automatically. It is named after the Round's own
      // title, or after the prefixed title an earlier build stored.
      final stored = _storyTitleOf(_title);
      final title = stored.isNotEmpty ? stored : _title.trim();
      _storyTitle.text = title;
      _mutateRound(
        () => _flow = RoundFlowAuthoring.linearFor(
          _editedContent(),
          presentation: FlowPresentation.scroll,
          title: title,
          log: FlowLog.dialogue,
          readAloud: FlowReadAloud.automatic,
        ),
      );
      return;
    }
    final flow = _flow;
    if (flow != null && !flow.isLinear) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove the branching $_flowNoun?'),
          content: Text(
            'This Round\'s flow branches, which QQL\'s forms cannot rebuild. Turning the $_flowNoun off removes the flow; the exercises stay.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Keep the $_flowNoun'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (remove != true || !mounted) return;
    }
    _mutateRound(() {
      _flow = null;
      // The Round keeps its name without the Story prefix.
      if (_title.startsWith(_storyTitlePrefix)) _title = _storyTitleOf(_title);
    });
  }

  static const _storyTitlePrefix = 'Story: ';

  /// The Story title a Round title carries: what follows `Story: `, else
  /// nothing.
  static String _storyTitleOf(String roundTitle) =>
      roundTitle.startsWith(_storyTitlePrefix)
      ? roundTitle.substring(_storyTitlePrefix.length).trim()
      : '';

  /// Names the Story: the flow carries the title, the Round keeps its own
  /// name, and every list derives "Story: <title>" from the flow
  /// (`LearningRound.displayTitle`), so a Rename cannot lose the prefix.
  void _setStoryTitle(String value) {
    final flow = _flow;
    if (flow == null || widget.readOnly) return;
    _mutateRound(
      () => _flow = RoundFlowAuthoring.withStoryOptions(
        flow,
        title: value.trim(),
      ),
    );
  }

  /// Marks or unmarks an exercise as needing the Story's audio (Build 256
  /// Revision 5): with Audio Exercises off the Story skips it, as it skips
  /// the audio exercises; a line is never skipped.
  void _toggleAudioDependence(int i) {
    final flow = _flow;
    if (flow == null || widget.readOnly) return;
    final id = _exercises[i].id;
    final entry = _editedContent().firstWhere((content) => content.id == id);
    final requires = !flow.audioDependentContentIds.contains(id);
    _mutateRound(
      () => _flow = RoundFlowAuthoring.withAudioDependence(
        flow,
        entry,
        requiresAudio: requires,
      ),
    );
  }

  String get _storyDescription {
    final flow = _flow;
    if (flow == null) {
      return 'Off: a practice Round with an introduction, shuffled exercises and a mistake review.';
    }
    if (flow.isLinear) {
      return flow.presentation == FlowPresentation.scroll
          ? 'On, scrolling: finished items stay on the page, the next one appears below and the page scrolls to it. No shuffle, no mistake review.'
          : 'On, step by step: the exercises play in this order, one per page, unshuffled, without a mistake review.';
    }
    return 'On: a branching $_flowNoun authored outside QQL. Edits here keep its flow as it is; the Audit reports what it no longer finds.';
  }

  List<LearningContent> _editedContent() =>
      _hierarchyUpdates.contentForExercises(_originalContent, _exercises);

  Future<void> _returnToRounds() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      Navigator.pop(context, widget.readOnly ? widget.round : _editedRound());
    }
  }

  Future<void> _saveRound(PublicationState state) async {
    if (widget.readOnly) return;
    if (!state.isPublished &&
        _publicationState.isPublished &&
        !await confirmMoveToDraft(context, 'Round')) {
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
        // A Round saved as normal content shows learners only its Published
        // Exercises. When Draft ones are the reason it cannot be saved, say
        // so and name them instead of counting blocking errors.
        final drafts = _exercises
            .where((exercise) => !exercise.publicationState.isPublished)
            .toList();
        if (drafts.isNotEmpty) {
          final titles = drafts
              .take(3)
              .map((exercise) => '“${_exerciseSummary(exercise)}”')
              .join(', ');
          final more = drafts.length > 3
              ? ' and ${drafts.length - 3} more'
              : '';
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              key: const Key('round-draft-exercises-notice'),
              title: const Text('Save the Draft Exercises first'),
              content: Text(
                '${drafts.length == 1 ? 'One Exercise is' : '${drafts.length} Exercises are'} still Draft: $titles$more. '
                'A Round saved as normal content shows only its Published Exercises, so open each Draft Exercise and press Save, or save the Round as draft.',
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

  String _summary(Exercise e) => _exerciseSummary(e);

  Course get _workingCourse => _hierarchyUpdates.apply(
    _course,
    OverlayRoundDraft(_lesson, _editedRound()),
  );

  void _mutateRound(VoidCallback mutation) {
    if (!mounted) return;
    // The working copy before this change lets a parent Draft be promoted when
    // its last Draft child is saved as Published.
    final before = _workingCourse;
    mutation();
    final candidate = _workingCourse;
    final course =
        widget.adoptCourse?.call(candidate, previous: before) ??
        const ProvisionalPublicationService().reconcile(
          candidate,
          updatedAt: _clock(),
          previous: before,
        );
    setState(() {
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
      (widget.onCourseChanged != null || widget.adoptCourse != null) &&
      _course.lessons.any(
        (lesson) =>
            lesson.lessonId == _lesson.lessonId &&
            lesson.rounds.any((round) => round.id == widget.round.id),
      );

  void _acceptExercise(Exercise exercise) => _acceptExerciseAt(exercise);

  /// A saved title block goes first: the cover is a Story's first card.
  void _acceptFirst(Exercise exercise) =>
      _acceptExerciseAt(exercise, first: true);

  void _acceptExerciseAt(Exercise exercise, {bool first = false}) {
    if (widget.readOnly) return;
    final index = _exercises.indexWhere((value) => value.id == exercise.id);
    if (index >= 0 &&
        _sameAuthoringJson(_exercises[index].toJson(), exercise.toJson())) {
      return;
    }
    _mutateRound(() {
      if (index >= 0) {
        _exercises[index] = exercise;
      } else if (first || _isRoundIntro(exercise)) {
        _exercises.insert(0, exercise);
      } else {
        _exercises.add(exercise);
      }
    });
  }

  Future<void> _edit(int i) async {
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => _exerciseEditorFor(
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

  Future<void> _insert() =>
      _insertPreset(TranslationChoice.toTarget, title: 'New Exercise');

  /// A new exercise from a preset's form. A Story's title block (`first`)
  /// goes before every other step.
  Future<void> _insertPreset(
    String presetId, {
    required String title,
    bool first = false,
  }) async {
    if (widget.readOnly) return;
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => _exerciseEditorFor(
          exercise: _blankExerciseForPreset(presetId, _ids),
          title: title,
          isNew: true,
          course: _workingCourse,
          lesson: _lesson,
          round: _editedRound(),
          onExerciseSaved: first ? _acceptFirst : _acceptExercise,
          linkParent: true,
          clock: _clock,
        ),
      ),
    );
    if (e == null || !mounted) return;
    if (!_exercises.any((item) => item.id == e.id)) {
      _mutateRound(() {
        if (first || _isRoundIntro(e)) {
          _exercises.insert(0, e);
        } else {
          _exercises.add(e);
        }
      });
    }
    _warnLength();
  }

  static bool _isCover(Exercise exercise) =>
      ExerciseFeatures(exercise).kind == LearnerExerciseKind.storyCover;

  /// A Before you start card goes before the Round's other exercises
  /// (Build 257); the Round screen shows it before the Round starts.
  static bool _isRoundIntro(Exercise exercise) =>
      ExerciseFeatures(exercise).kind == LearnerExerciseKind.roundIntro;

  static bool _isLine(Exercise exercise) =>
      ExerciseFeatures(exercise).kind == LearnerExerciseKind.dialogueLine;

  /// What the Story holds, under its options: a Story has one title block
  /// and at least one Dialogue line (owner rule, 28 September 2026).
  String get _storyStepsSummary {
    final covers = _exercises.where(_isCover).length;
    final lines = _exercises.where(_isLine).length;
    // A Before you start card is no step of the Story (Build 257).
    final intros = _exercises.where(_isRoundIntro).length;
    final exercises = _exercises.length - covers - lines - intros;
    final title = switch (covers) {
      0 => 'No title block yet: add it with Add Step',
      1 => 'Title block: 1',
      _ => 'Title blocks: $covers (a Story has one)',
    };
    final dialogue = lines == 0
        ? 'no Dialogue line yet: add at least one with Add Step'
        : 'Dialogue lines: $lines';
    return '$title · $dialogue · Exercises: $exercises.';
  }

  /// Add Step (Build 256 Revision 5, third follow-up): in a Story, one
  /// button instead of New Exercise, New Canonical and Exercise Wizard; it
  /// asks for the block type. The title block is offered once, a Dialogue
  /// line uses the short form New Story uses, an exercise the presets a
  /// Story may use.
  Future<void> _addStoryStep() async {
    if (widget.readOnly || !_isStory) return;
    final hasCover = _exercises.any(_isCover);
    final hasLine = _exercises.any(_isLine);
    final choice = await showModalBottomSheet<_StoryStepType>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                'Add a step to the Story',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'A Story has one title block, at least one Dialogue line and any number of exercises. A new step goes at the end (the title block first); drag it where it belongs.',
              ),
            ),
            Card(
              key: const Key('story-step-title'),
              child: ListTile(
                enabled: !hasCover,
                leading: const Icon(Icons.auto_stories_outlined),
                title: const Text('Title block'),
                subtitle: Text(
                  hasCover
                      ? 'This Story already has its title block; edit it in the list.'
                      : 'The cover: the Story title, its picture and an optional title line.',
                ),
                onTap: hasCover
                    ? null
                    : () => Navigator.pop(sheetContext, _StoryStepType.title),
              ),
            ),
            Card(
              key: const Key('story-step-line'),
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Dialogue line'),
                subtitle: Text(
                  hasLine
                      ? 'Said by the narrator or a character; read, heard or both.'
                      : 'Said by the narrator or a character; read, heard or both. The Story needs at least one.',
                ),
                onTap: () => Navigator.pop(sheetContext, _StoryStepType.line),
              ),
            ),
            Card(
              key: const Key('story-step-exercise'),
              child: ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('Exercise'),
                subtitle: const Text(
                  'A question about the Story, from the presets a Story may use. Only exercises score.',
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _StoryStepType.exercise),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _StoryStepType.title:
        await _insertPreset(
          'story_cover',
          title: 'New title block',
          first: true,
        );
      case _StoryStepType.line:
        await _insertLine();
      case _StoryStepType.exercise:
        final presetId = await _chooseStoryPreset(context);
        if (presetId == null || !mounted) return;
        await _insertPreset(presetId, title: 'New Exercise');
    }
  }

  /// A Dialogue line typed in the short form New Story uses; Edit opens the
  /// full form afterwards (its language, for one).
  Future<void> _insertLine() async {
    if (widget.readOnly) return;
    final values = await showStoryLineDialog(
      context,
      narrator: _course.narrator,
      characters: _course.storyCharacters,
    );
    if (values == null || !mounted) return;
    _acceptExercise(
      _dialogueLineExercise(
        _ids.next('exercise'),
        values,
        updatedAt: _clock().toUtc(),
      ),
    );
    _warnLength();
  }

  /// A new exercise in the Generic Primitive Editor: any primitive, every
  /// canonical field, no preset.
  Future<void> _insertCanonical() async {
    if (widget.readOnly) return;
    final e = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => PrimitiveEditorScreen(
          exercise: CanonicalExerciseDraft.blankExercise(
            ExercisePrimitive.select,
            id: _ids.next('exercise'),
            updatedAt: _clock().toUtc(),
          ),
          title: 'New Canonical Exercise',
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
      final updated =
          widget.adoptCourse?.call(
            transferred,
            previous: course,
            usePrevious: false,
          ) ??
          const ProvisionalPublicationService().reconcile(
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
                    '• ${_exerciseKindName(e).replaceAll('_', ' ')}: ${_summary(e)}',
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
          final features = ExerciseFeatures(exercise);
          if (features.kind != LearnerExerciseKind.selectRead) continue;
          for (final match in RegExp(
            r"[A-Za-zÀ-ÖØ-öø-ÿ']{2,}",
          ).allMatches(features.passageText)) {
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
    final course =
        widget.adoptCourse?.call(changed, previous: _workingCourse) ?? changed;
    final adoptedLesson = course.lessons.firstWhere(
      (candidate) => candidate.lessonId == _lesson.lessonId,
    );
    final adoptedRound = adoptedLesson.rounds.firstWhere(
      (candidate) => candidate.id == widget.round.id,
    );
    setState(() {
      _course = course;
      _lesson = adoptedLesson;
      _exercises = [...adoptedRound.exercises];
      _originalContent = [...adoptedRound.content];
      _title = adoptedRound.title;
      _updatedAt = adoptedRound.updatedAt;
      _publicationState = adoptedRound.publicationState;
      _provisionalDraft = adoptedRound.provisionalDraft;
      _flow = adoptedRound.flow;
    });
    widget.onCourseChanged?.call(course);
  }

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
          title: Text(_editedRound().displayTitle(widget.roundIndex)),
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
                  style: _compactButtonStyle,
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
                    style: _compactButtonStyle,
                    onPressed: () => _saveRound(PublicationState.draft),
                    child: const Text('Save as draft'),
                  ),
                  FilledButton(
                    key: const Key('round-save'),
                    style: _compactButtonStyle,
                    onPressed: () => _saveRound(PublicationState.published),
                    child: const Text('Save'),
                  ),
                  // A sequence is a plain Round played in order (Build 256
                  // Revision 7, third follow-up): the Round's own buttons.
                  if (!_isStory) ...[
                    OutlinedButton.icon(
                      key: const Key('new-exercise'),
                      style: _compactButtonStyle,
                      onPressed: _insert,
                      icon: const Icon(Icons.add),
                      label: const Text('New Exercise'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('new-canonical-exercise'),
                      style: _compactButtonStyle,
                      onPressed: _insertCanonical,
                      icon: const Icon(Icons.tune),
                      label: const Text('New Canonical'),
                    ),
                    FilledButton.icon(
                      key: const Key('exercise-creation-wizard'),
                      style: _compactButtonStyle,
                      onPressed: _openCreationWizard,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Exercise Wizard'),
                    ),
                  ] else
                    // A Story is built from steps (third follow-up): the
                    // block type is chosen first.
                    FilledButton.icon(
                      key: const Key('round-add-step'),
                      style: _compactButtonStyle,
                      onPressed: _addStoryStep,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Step'),
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
              SwitchListTile(
                key: const Key('round-story-switch'),
                title: const Text('Play as a sequence'),
                subtitle: Text(_storyDescription),
                value: _flow != null,
                onChanged: widget.readOnly ? null : _setStory,
              ),
              if (_flow != null && _flow!.isLinear) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    key: const Key('round-story-title'),
                    controller: _storyTitle,
                    readOnly: widget.readOnly,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: _isStory
                          ? 'Story title'
                          : 'Optional sequence title',
                      helperText: _isStory
                          ? 'Shown on the cover; lists call the Round “Story: <title>”. The Audit asks for one.'
                          : 'Lists and the learner\'s path call the Round “Sequence: <title>”; without a title they use the Round\'s name.',
                      helperMaxLines: 2,
                    ),
                    onChanged: _setStoryTitle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<FlowPresentation>(
                    key: const Key('round-story-presentation'),
                    segments: const [
                      ButtonSegment(
                        value: FlowPresentation.step,
                        label: Text('Step by step'),
                        icon: Icon(Icons.view_agenda_outlined),
                      ),
                      ButtonSegment(
                        value: FlowPresentation.scroll,
                        label: Text('Scrolling'),
                        icon: Icon(Icons.swipe_vertical_outlined),
                      ),
                    ],
                    selected: {_flow!.presentation},
                    onSelectionChanged: widget.readOnly
                        ? null
                        : (values) => _mutateRound(
                            () => _flow = RoundFlowAuthoring.withPresentation(
                              _flow!,
                              values.first,
                            ),
                          ),
                  ),
                ),
                if (_flow!.presentation == FlowPresentation.scroll)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SegmentedButton<FlowLog>(
                      key: const Key('round-story-log'),
                      segments: const [
                        ButtonSegment(
                          value: FlowLog.dialogue,
                          label: Text('Dialogue only'),
                          icon: Icon(Icons.forum_outlined),
                        ),
                        ButtonSegment(
                          value: FlowLog.all,
                          label: Text('Everything'),
                          icon: Icon(Icons.view_list_outlined),
                        ),
                      ],
                      selected: {_flow!.log},
                      onSelectionChanged: widget.readOnly
                          ? null
                          : (values) => _mutateRound(
                              () => _flow = RoundFlowAuthoring.withStoryOptions(
                                _flow!,
                                log: values.first,
                              ),
                            ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<FlowReadAloud>(
                    key: const Key('round-story-read-aloud'),
                    segments: const [
                      ButtonSegment(
                        value: FlowReadAloud.automatic,
                        label: Text('Read aloud automatically'),
                        icon: Icon(Icons.volume_up_outlined),
                      ),
                      ButtonSegment(
                        value: FlowReadAloud.manual,
                        label: Text('On request'),
                        icon: Icon(Icons.touch_app_outlined),
                      ),
                    ],
                    selected: {_flow!.readAloud},
                    onSelectionChanged: widget.readOnly
                        ? null
                        : (values) => _mutateRound(
                            () => _flow = RoundFlowAuthoring.withStoryOptions(
                              _flow!,
                              readAloud: values.first,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'An exercise that only makes sense with the $_flowNoun\'s audio is marked “Needs the $_flowNoun\'s audio” in its menu and is skipped with Audio Exercises off.',
                  ),
                ),
                if (_isStory)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      _storyStepsSummary,
                      key: const Key('round-story-steps'),
                    ),
                  ),
              ],
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
                    title: Text(_exerciseTypeLabel(e)),
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
                        if (v == 'audio') _toggleAudioDependence(i);
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
                          // A Story has one title block (third follow-up).
                          enabled:
                              !widget.readOnly && !(_isStory && _isCover(e)),
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
                        if (_flow != null &&
                            e.primitive != ExercisePrimitive.presentation)
                          CheckedPopupMenuItem(
                            value: 'audio',
                            enabled: !widget.readOnly,
                            checked: _flow!.audioDependentContentIds.contains(
                              e.id,
                            ),
                            child: Text('Needs the $_flowNoun\'s audio'),
                          ),
                        if (ExerciseFeatures(e).kind ==
                            LearnerExerciseKind.selectRead)
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

/// The bottom bars' buttons: slightly smaller than Material's defaults so
/// the Round editor's six actions fit two rows on a laptop window (owner
/// report, 27 September 2026).
final ButtonStyle _compactButtonStyle = ButtonStyle(
  visualDensity: VisualDensity.compact,
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
  textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
);

/// The action word of a preset tile (Choose, Type, Arrange, Match, Card, …).
class _PresetActionChip extends StatelessWidget {
  const _PresetActionChip(this.action);

  final String action;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(action),
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: EdgeInsets.zero,
  );
}

/// The preset an exercise carries, else its learner kind: the name the
/// editor's lists and Audit locations show for it.
String _exerciseKindName(Exercise e) => e.editorTemplate.isNotEmpty
    ? e.editorTemplate
    : ExerciseFeatures(e).kind.name;

/// The friendly type label: the preset's name, else the kind's.
String _exerciseTypeLabel(Exercise e) =>
    ExercisePresetRegistry.byId(e.editorTemplate)?.name ??
    CourseAuditService.kindLabel(ExerciseFeatures(e).kind);

/// One line that identifies an exercise in a list: its sentence, context,
/// main text, term, question, meaning or spoken text, else its ID.
String _exerciseSummary(Exercise e) {
  final features = ExerciseFeatures(e);
  for (final text in [
    // A Story's line and cover keep their text in the line and title roles
    // (owner report, 29 September 2026: the list showed their IDs).
    features.lineText,
    features.lineAudio?.text ?? '',
    features.coverTitle,
    features.introText,
    // A Page is named by its first text block (Build 258 Revision 2).
    ...features.pageBlocks.where((block) => block.isText).map((b) => b.text),
    features.inlineSentence,
    features.contextText,
    features.primaryText,
    features.textOf('term'),
    features.questionText,
    features.textOf('meaning'),
    features.primaryAudioText ?? '',
  ]) {
    if (text.trim().isNotEmpty) return text.trim();
  }
  if (features.kind == LearnerExerciseKind.storyCover ||
      e.editorTemplate == 'story_cover') {
    final picture = features.illustrationImages
        .map((image) => image.text.trim())
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    return picture == null ? 'Title block' : 'Title block · $picture';
  }
  return e.id;
}

/// The editor for one exercise: the preset form when a preset represents
/// the exercise (or it is new), otherwise the Generic Primitive Editor, which
/// shows every canonical field and never drops data the form cannot show
/// (Build 256 Session 4, plan A.13).
Widget _exerciseEditorFor({
  required Exercise exercise,
  required String title,
  required bool isNew,
  DateTime Function()? clock,
  bool linkParent = false,
  Course? course,
  Lesson? lesson,
  LearningRound? round,
  ValueChanged<Exercise>? onExerciseSaved,
  bool readOnly = false,
  bool initiallyInspecting = false,
}) => !isNew && PresetRecipes.presetToEdit(exercise) == null
    ? PrimitiveEditorScreen(
        exercise: exercise,
        title: title,
        isNew: isNew,
        clock: clock,
        linkParent: linkParent,
        course: course,
        lesson: lesson,
        round: round,
        onExerciseSaved: onExerciseSaved,
        readOnly: readOnly,
        initiallyInspecting: initiallyInspecting,
      )
    : ExerciseEditorScreen(
        exercise: exercise,
        title: title,
        isNew: isNew,
        clock: clock,
        linkParent: linkParent,
        course: course,
        lesson: lesson,
        round: round,
        onExerciseSaved: onExerciseSaved,
        readOnly: readOnly,
        initiallyInspecting: initiallyInspecting,
      );

/// [course] with the Story [narrator] and [characters] and any new media
/// [credits] (Build 256 Revision 5). A narrator equal to the one the Course
/// already has (or to the default, when it has none) leaves the JSON as it
/// was.
Course _courseWithSpeakers(
  Course course, {
  required StorySpeaker narrator,
  required List<StorySpeaker> characters,
  List<CourseMediaAttribution> credits = const [],
}) {
  final json = {...course.toJson()}
    ..remove('storyNarrator')
    ..remove('storyCharacters')
    ..remove('mediaAttributions');
  final known = [...course.mediaAttributions];
  for (final credit in credits) {
    if (!known.any(
      (item) => jsonEncode(item.toJson()) == jsonEncode(credit.toJson()),
    )) {
      known.add(credit);
    }
  }
  final sameNarrator =
      jsonEncode(narrator.toJson()) == jsonEncode(course.narrator.toJson());
  return Course.fromJson({
    ...json,
    if (course.storyNarrator != null || !sameNarrator)
      'storyNarrator': narrator.toJson(),
    if (characters.isNotEmpty)
      'storyCharacters': [
        for (final character in characters) character.toJson(),
      ],
    if (known.isNotEmpty)
      'mediaAttributions': [for (final item in known) item.toJson()],
  });
}

Exercise _blankExerciseForPreset(String presetId, AuthoringIdGenerator ids) {
  final id = ids.next('exercise');
  // A recipe with no v11 shape (a Dialogue line, a Story cover; Build 256
  // Revision 5) is blank as its own recipe builds it from empty fields, so
  // the exercise is a presentation from the start.
  if (PresetRecipes.canonicalOnly.contains(presetId)) {
    return ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: Exercise.canonical(
          id: id,
          publicationState: PublicationState.draft,
          primitive: ExercisePrimitive.presentation,
          canonicalEvaluation: CanonicalEvaluation.none,
        ),
        type: presetId,
        publicationState: PublicationState.draft,
      ),
    ).candidate!;
  }
  // The v11 shape needs the recipe's base type (a catalogue twin such as
  // type_translation_to_target is not a v11 type and would fall back to a
  // Select interaction); the preset itself travels as the editor template.
  return Exercise(
    id: id,
    publicationState: PublicationState.draft,
    type: ExercisePresetRegistry.byId(presetId)?.base ?? presetId,
    editorTemplate: presetId,
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
}

/// The block types Add Step offers in a Story (Build 256 Revision 5,
/// third follow-up).
enum _StoryStepType { title, line, exercise }

/// A Dialogue line built from the short line form's values (New Story's Add
/// line and the Round editor's Add Step): a presentation the dialogue_line
/// recipe fills, Published as the Wizard makes its steps.
Exercise _dialogueLineExercise(
  String id,
  StoryLineValues values, {
  required DateTime updatedAt,
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: Exercise.canonical(
      id: id,
      primitive: ExercisePrimitive.presentation,
      canonicalEvaluation: CanonicalEvaluation.none,
      updatedAt: updatedAt,
    ),
    type: 'dialogue_line',
    publicationState: PublicationState.published,
    prompt: values.text,
    speakerId: values.speakerId,
    lineMode: values.mode,
    lineReadAloud: values.readAloud,
    lineTextReveal: values.textReveal,
  ),
).candidate!;

/// The sheet that offers the presets a Story may use (`storyWizardPresets`);
/// New Story's Add exercise and the Round editor's Add Step share it.
Future<String?> _chooseStoryPreset(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'Add an exercise to the Story',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final id in storyWizardPresets)
              if (ExercisePresetRegistry.byId(id) case final preset?)
                Card(
                  key: ValueKey('story-wizard-preset-$id'),
                  child: ListTile(
                    leading: _PresetActionChip(preset.action),
                    title: Text(preset.name),
                    subtitle: Text(preset.description),
                    onTap: () => Navigator.pop(sheetContext, id),
                  ),
                ),
          ],
        ),
      ),
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
        builder: (_) => _exerciseEditorFor(
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
              if (ExercisePresetRegistry.inCategory(category).isNotEmpty)
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
    final draft = PresetRecipes.decompose(e, _type);
    _prompt = TextEditingController(text: draft.prompt);
    _question = TextEditingController(text: draft.question);
    _tts = TextEditingController(text: draft.tts);
    _hint = TextEditingController(text: draft.hint);
    _answers = TextEditingController(text: draft.answers);
    _useMultiSelect = draft.useMultiSelect;
    _correct = TextEditingController(text: _initialCorrect(e, draft));
    _requiredSelections = TextEditingController(text: draft.requiredSelections);
    _accepted = TextEditingController(text: draft.accepted);
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
    _tokens = TextEditingController(text: draft.tokens);
    _order = TextEditingController(text: draft.order);
    _gapLayout = TextEditingController(text: draft.gapLayout);
    for (final value in draft.correctTranslations) {
      final controller = TextEditingController(text: value);
      _watchText(controller);
      _correctTranslations.add(controller);
    }
    _pairs = TextEditingController(text: draft.pairs);
    _icons = TextEditingController(text: draft.icons);
    if (_type == 'picture_word_match') _splitPicturePairs(draft.pairs);
    _missingWords = TextEditingController(text: draft.missingWords);
    _context = TextEditingController(text: draft.context);
    _dialogue = TextEditingController(text: draft.dialogue);
    _groups = TextEditingController(text: draft.groups);
    _slots = TextEditingController(text: draft.slots);
    _extraWords = TextEditingController(text: draft.extraWords);
    _contextMode = draft.contextMode;
    _imageAsset = draft.imageAsset;
    _selectedSharedSource = draft.selectedSharedSource;
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

  void _loadScriptController() {
    _scriptController?.dispose();
    _scriptDirty = false;
    _scriptController = ScriptRecognitionController(_exercise)
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
                course: widget.course,
                asset: PresetVariants.isImageReference(lineAt(i))
                    ? lineAt(i)
                    : '',
                sharedSource: null,
                readOnly: widget.readOnly,
                onChanged: (change) => setState(() {
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
        // or more ___ gaps that one answer fills.
        return [
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
        return [
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
        // One field (Build 256 Revision 7 follow-up, owner review): the
        // blocks of the word in order are also the blocks the learner gets;
        // a spelling exercise has no distractors.
        return [
          _instructionField(),
          _field(
            _order,
            'Blocks of the word, in order',
            lines: 5,
            helper:
                'One letter or syllable per line, in the right order; the learner gets exactly these blocks, shuffled. An image is required.',
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
            'MP3: open Course Editor > Audio Library. Copy MP3 files to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}, press Import MP3, then Associate recording with its Word or expression. Choose Recorded MP3 only or Hybrid. This exercise uses those text mappings.',
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
            helper: 'The complete text, read aloud before the learner types.',
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
                'One letter or syllable per line, in the right order; the learner gets exactly these blocks, shuffled.',
          ),
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
                'One letter or syllable per line, in the right order; the learner gets exactly these blocks, shuffled.',
          ),
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
            key: ValueKey('page-editor-${_exercise.id}'),
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
                            leading: _PresetActionChip(preset.action),
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
                          leading: _PresetActionChip(preset.action),
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
        // Pick the translation always starts with the first option correct.
        if (TranslationChoice.isTranslationChoice(selected) &&
            _correct.text.trim().isEmpty) {
          _correct.text = '1';
        }
        // True or false starts with its two answers in the source language.
        if (selected == 'true_false' && _answers.text.trim().isEmpty) {
          _answers.text = _trueFalseAnswers().join('\n');
          if (_correct.text.trim().isEmpty) _correct.text = '1';
        }
        _dirty = true;
        // A new exercise with nothing typed yet: the chosen type is its
        // starting point, not a change to keep (owner report, 27 September
        // 2026). An existing exercise's type change stays a change.
        if (widget.isNew && untouched) _openedSnapshot = _formSnapshot();
      });
    }
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
    return result.candidate;
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
      _scriptDirty = false;
      _openedSnapshot = _formSnapshot();
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
        _type =
            PresetRecipes.presetToEdit(e) ??
            PresetRecipes.defaultPresetFor(e.primitive) ??
            'choice_target';
        final draft = PresetRecipes.decompose(e, _type);
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
        _tokens.text = draft.tokens;
        _order.text = draft.order;
        _gapLayout.text = draft.gapLayout;
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
        for (final controller in _correctTranslations) {
          controller.dispose();
        }
        _correctTranslations.clear();
        for (final text in draft.correctTranslations) {
          _correctTranslations.add(_translationController(text));
        }
        _correctTranslationError = null;
        _correctTranslationErrorIndexes = const {};
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
        'This form shows its closest reading and cannot save it, because a save would drop what the form does not show. Edit it in the canonical editor.',
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
              )
            else
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
            // (Build 259 Revision 5).
            if (_type != 'script_recognition' &&
                _type != 'before_you_start' &&
                _type != 'page' &&
                _type != 'picture_word_match')
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
                onPressed: widget.readOnly || _inspection || _unrepresentable
                    ? null
                    : () => _save(PublicationState.draft),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save as draft'),
              ),
              FilledButton.icon(
                key: const Key('exercise-save'),
                onPressed: widget.readOnly || _inspection || _unrepresentable
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
  bool _routeMayPop = false;
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
    switch (await ensureQuickImportAccess(
      context,
      offerOpenFrom: _audio.fileDialogsAvailable,
    )) {
      case QuickImportAccess.ready:
        break;
      case QuickImportAccess.openFrom:
        return _importFromDialog();
      case QuickImportAccess.stop:
        return;
    }
    if (!mounted) return;
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
              'Imported ${clips.length} MP3 file${clips.length == 1 ? '' : 's'} from ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}.',
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
      Card(
        key: const Key('audio-library-save-notice'),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Changes here are kept as you make them and are applied when you '
            'leave this screen, so there is no Save button. They are written '
            'to the Course only when you confirm the Course changes on leaving '
            'the Course Editor. Cancelling the Course discards them, and any '
            'recordings imported in that session are removed again.',
          ),
        ),
      ),
      const SizedBox(height: 8),
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
      if (_course.audioMode != 'tts')
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Import MP3: copy the MP3 files you want to import to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}, then press Import MP3. All MP3 files in that folder are imported. Source files are left in place, so move or remove them after a successful import to avoid importing them again.',
            ),
          ),
        ),
      if (_course.audioMode != 'tts')
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
    return PopScope<Course>(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
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
          ],
        ),
        floatingActionButton: _course.audioMode == 'tts'
            ? null
            : FloatingActionButton.extended(
                onPressed: _import,
                icon: const Icon(Icons.library_music_outlined),
                label: const Text('Import MP3'),
              ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: children,
        ),
      ),
    );
  }

  /// Leaving the screen returns the draft, so there is no Save button. The
  /// Course Editor stages it in the working copy; the single top-level Course
  /// confirmation is still the only thing that writes it.
  Future<void> _leave() async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, _course);
  }
}

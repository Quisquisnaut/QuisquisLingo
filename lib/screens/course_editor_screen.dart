import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/exercise_image_field.dart';

import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import '../models/exercise_image_metadata.dart';
import '../services/course_editor_service.dart';
import '../services/course_editor_device_state.dart';
import '../services/course_flag_service.dart';
import '../services/course_language_resolver.dart';
import '../services/course_governance_resolver.dart';
import '../services/course_governance_service.dart';
import '../services/course_info_update_service.dart';
import '../services/course_hierarchy_update_service.dart';
import '../services/course_authoring_session.dart';
import '../services/course_access_policy.dart';
import '../services/course_service.dart';
import '../services/course_wizard.dart';
import '../services/course_wizard_memory.dart';
import '../services/course_audit_service.dart';
import '../services/duel_eligibility_service.dart';
import '../services/settings_service.dart';
import '../services/exercise_search_service.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';
import '../services/lesson_icon_catalog.dart';
import '../services/lesson_icon_service.dart';
import '../services/lesson_presentation_service.dart';
import '../services/recorded_audio_service.dart';
import 'round_screen.dart';
import 'flat_image_library_screen.dart';
import 'course_version_history_screen.dart';
import 'course_info_editor.dart';
import 'exercise_editor_screen.dart';
import 'audio_library_screen.dart';
import 'course_audit_screen.dart';
import 'lesson_authoring_preview_screen.dart';
import '../services/authoring_hierarchy_status.dart';
import '../services/exercise_labels.dart';
import 'course_info_screen.dart';
import 'guidebook_screen.dart';
import 'guidebook_editor_screen.dart';
import '../services/guidebook_round_links.dart';
import '../services/guidebook_size_advice.dart';
import 'course_editor_search_screen.dart';
import '../services/course_authoring_transfer_service.dart';
import '../services/translation_choice_service.dart';
import '../widgets/editor_breadcrumbs.dart';
import '../widgets/editor_dialogs.dart';
import '../widgets/lesson_options_panel.dart';
import '../widgets/preset_action_chip.dart';
import '../widgets/authoring_destination_dialog.dart';
import '../widgets/editor_app_bar_actions.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/authoring_duplication_service.dart';
import '../services/exercise_creation_planner.dart';
import '../services/exercise_draft_builder.dart';
import '../services/exercise_difficulty.dart';
import '../services/round_flow_authoring.dart';
import '../services/story_cast.dart';
import '../services/round_type_presentation.dart';
import '../services/round_type_compatibility.dart';
import '../services/timed_round_rules.dart';
import '../services/preset_recipes.dart';
import '../services/guidebook_round_generator.dart';
import '../services/word_lookup/word_lookup_articles.dart';
import '../services/publish_gate.dart';
import '../services/provisional_publication_service.dart';
import '../services/new_course_structure.dart';
import '../widgets/file_dialog_feedback.dart';
import '../widgets/flag_art.dart';
import '../widgets/course_artwork.dart';
import '../widgets/course_preview_flag.dart';
import 'home_screen.dart' show openCoursePreview;
import '../widgets/image_credit_reminder.dart';
import '../widgets/story_line_dialog.dart';
import '../widgets/story_speaker_dialog.dart';
import '../widgets/lesson_fallback_icon.dart';
import '../widgets/quick_import_access.dart';
import '../widgets/reported_action.dart';
import '../services/course_backup_retention.dart';
import '../widgets/course_backup_purge.dart';
import '../widgets/labelled_text.dart';
import '../services/course_audio_usage.dart';
import '../widgets/course_saving.dart';

export '../services/authoring_hierarchy_status.dart'
    show AuthoringHierarchyStatus;
export 'audio_library_screen.dart' show AudioLibraryScreen;
export 'course_audit_screen.dart' show CourseAuditScreen;
export 'exercise_editor_screen.dart' show ExerciseEditorScreen;
export 'lesson_authoring_preview_screen.dart' show LessonAuthoringPreviewScreen;
export 'guidebook_editor_screen.dart'
    show GuidebookEditorScreen, GuidebookModuleEditorScreen;

String _exerciseCountLabel(int count) =>
    '$count ${count == 1 ? 'Exercise' : 'Exercises'}';
String _roundCountLabel(int count) =>
    '$count ${count == 1 ? 'Round' : 'Rounds'}';

const _hierarchyLinkStyle = TextStyle(fontWeight: FontWeight.w800);

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

const _hierarchyUpdates = CourseHierarchyUpdateService();

/// The same canonical exercise with another publication state. Course Model
/// v12: copied canonically, never rebuilt through the v11 views, which would
/// lose an inline layout.
Exercise _withExercisePublication(
  Exercise source,
  PublicationState state, {
  DateTime? updatedAt,
}) => source.withPublicationState(state, updatedAt: updatedAt);

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

  /// Called just before the Editor closes for Continue Course Wizard (Build
  /// 267): the opener then continues the paused Wizard on the stored
  /// Course. Without it the paused line says where to continue.
  final VoidCallback? onContinueCourseWizard;
  const CourseEditorScreen({
    super.key,
    required this.course,
    this.userCourse = false,
    this.isNewCourse = false,
    this.editorService,
    this.transferService,
    this.clock,
    this.access,
    this.onContinueCourseWizard,
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
      onContinueCourseWizard: onContinueCourseWizard,
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
    this.onContinueCourseWizard,
  });

  final Course course;
  final CourseAccessCapabilities access;
  final bool isNewCourse;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final DateTime Function()? clock;
  final VoidCallback? onContinueCourseWizard;

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

  /// The Course's paused Course Wizard, if any (Build 267).
  CourseWizardPause? _wizardPause;

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
    if (!widget.isNewCourse && !widget.course.originType.isOfficial) {
      CourseWizardMemory()
          .recall(widget.course.courseId)
          .then((pause) {
            if (pause != null && mounted) setState(() => _wizardPause = pause);
          })
          .catchError((Object _) {});
    }
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

  /// The last Save now or mode-switch save of this visit (Build 270
  /// Revision 12): leaving with nothing unsaved still returns it, so the
  /// caller reloads.
  CourseConfirmationResult? _lastSaved;

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

  Future<void> _popEditor([
    CourseConfirmationResult? result,
    VoidCallback? beforePop,
  ]) async {
    if (!mounted || _routeMayPop) return;
    setState(() => _routeMayPop = true);
    // No confirmation result means this session is leaving without saving a
    // Course, on either the cancelled or the unchanged path. The recordings it
    // imported were written straight to disk, so the session owns them until
    // here. A confirmed Course tidies up inside its own confirmation instead.
    if (result == null) await _session.discardUnconfirmedMedia();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    beforePop?.call();
    Navigator.pop(context, result ?? _lastSaved);
  }

  /// Writes the Course while a small window says so and nothing else can be
  /// pressed (Build 271 Revision 2 follow-up, owner report of 11 October
  /// 2026). A save takes a moment (its backup comes first). Until now the
  /// Editor stayed in use meanwhile with no sign of it: Back found the
  /// changes still unsaved and asked about them as if Save had not written
  /// anything, and a change applied during the save was lost when the save
  /// finished. Since Revision 3 the window shows each step and a bar
  /// ([CourseSaving]).
  Future<CourseConfirmationResult> _writeCourse(String versionNotes) =>
      CourseSaving.run(
        context,
        (onProgress) => _session.confirm(
          languageCode: _code,
          versionNotes: versionNotes,
          onProgress: onProgress,
        ),
      );

  /// Save now (Build 270 Revision 12, owner decision of 10 October 2026):
  /// writes the Course as a new version, with its version notes, and stays
  /// in the Editor, as Save now does in the Course Wizard.
  Future<void> _saveNow() async {
    if (!_dirty) return;
    var versionNotes = _pendingVersionNotes;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('course-save-now-dialog'),
        title: const Text('Save the Course now?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: TextFormField(
              key: const Key('course-version-notes'),
              initialValue: versionNotes,
              onChanged: (value) => versionNotes = value,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Version notes (optional)',
                helperText: 'Describe the changes made in this course version.',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('course-save-now-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save course'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) return;
    try {
      final result = await _writeCourse(versionNotes);
      if (!mounted) return;
      setState(() => _lastSaved = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('course-editor-saved'),
          content: Text('Saved as version ${result.course.courseVersion}.'),
        ),
      );
      await CourseBackupPurge.offer(
        context,
        result.course,
        backups: _service.backupService,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'The Course was not saved. Your changes are still open. $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// [beforePop] runs only when the Editor really closes: Continue Course
  /// Wizard (Build 267) leaves through here, so unconfirmed changes are
  /// confirmed or cancelled first.
  Future<void> _attemptLeave({VoidCallback? beforePop}) async {
    if (!_dirty) {
      await _popEditor(null, beforePop);
      return;
    }
    var versionNotes = _pendingVersionNotes;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('course-transaction-confirmation'),
        title: const Text('Unsaved course changes'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The changes applied in this Course Editor are not saved yet. Save course writes them as one new course version; Discard changes drops all of them.',
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
            child: const Text('Discard changes'),
          ),
          FilledButton(
            key: const Key('confirm-course-changes'),
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text('Save course'),
          ),
        ],
      ),
    );
    if (choice == 'cancel') {
      _session.cancel();
      await _popEditor(null, beforePop);
      return;
    }
    if (choice != 'confirm') return;
    try {
      final result = await _writeCourse(versionNotes);
      if (!mounted) return;
      await CourseBackupPurge.offer(
        context,
        result.course,
        backups: _service.backupService,
      );
      if (!mounted) return;
      await _popEditor(result, beforePop);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'The Course was not saved. The saved Course is unchanged and your changes are still open. $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// The Course Info Editor: what it needs is read first, the dialog draws
  /// its form, and an applied change is staged in the working copy.
  Future<void> _editCourseInfo() async {
    final loaded = await runReported(
      context,
      'Course Info',
      () async => (
        governance: await CourseGovernanceResolver(
          profileService: _profiles,
          teamService: _teams,
        ).resolve(_course),
        profiles: await _profiles.getProfileRecords(),
        teams: await _teams.listTeams(),
        activeProfileId: await _profiles.getActiveProfileId(),
        backupsKept: await CourseBackupRetention().keepFor(_course.courseId),
      ),
    );
    if (loaded == null || !mounted) return;
    final activeProfileId = loaded.activeProfileId;
    final editMode = _editorMode == CourseEditorMode.edit;
    final result = await showCourseInfoEditor(
      context,
      course: _course,
      governance: loaded.governance,
      profiles: loaded.profiles,
      teams: loaded.teams,
      canGovern:
          editMode &&
          widget.access.canTransferMaintainership &&
          activeProfileId == _course.maintainer?.profileId,
      editMode: editMode,
      backupsKept: loaded.backupsKept,
      otherCourses: _service.listUserCourses,
      onVersionHistory: _openVersionHistory,
    );
    if (result == null || !mounted) return;
    // Build 270 Revision 9: a setting of this device, saved with Apply.
    if (result.backupsKept != loaded.backupsKept) {
      await runReported(
        context,
        'Saving the backups kept on this device',
        () => CourseBackupRetention().setKeep(
          _course.courseId,
          result.backupsKept,
        ),
      );
      if (!mounted) return;
    }
    final update = await runReported(
      context,
      'Course Info changes',
      () => CourseInfoUpdateService(
        governanceService: CourseGovernanceService(
          profileService: _profiles,
          teamService: _teams,
        ),
      ).apply(_course, result.change, activeProfileId),
    );
    if (update == null || !mounted) return;
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
    // Build 270 Revision 7: a mode that cannot be saved is reported.
    if (!mounted) return;
    final saved = await runReported(context, 'Course Editor mode', () async {
      await _deviceState.setMode(_course.courseId, mode);
      return true;
    });
    if (saved == true && mounted) {
      setState(() => _session.setEditorMode(mode));
    }
  }

  Future<bool> _resolveChangesBeforeModeSwitch() async {
    if (!_dirty) return true;
    var versionNotes = _pendingVersionNotes;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('course-transaction-confirmation'),
        title: const Text('Unsaved course changes'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'The changes applied in this Course Editor are not saved yet. Save course writes them as one new course version, Discard changes drops all of them, or keep editing.',
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
            child: const Text('Discard changes'),
          ),
          TextButton(
            key: const Key('confirm-course-changes'),
            onPressed: () => Navigator.pop(context, 'confirm'),
            child: const Text('Save course'),
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
      final result = await _writeCourse(versionNotes);
      if (!mounted) return false;
      setState(() => _lastSaved = result);
      await CourseBackupPurge.offer(
        context,
        result.course,
        backups: _service.backupService,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'The Course was not saved. Your changes are still open in Edit. $error',
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
      final errors = const PublishGate().courseErrors(candidate);
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PublishGate.courseRefusal(errors))),
        );
        return;
      }
    }
    _updateDraft(candidate);
  }

  /// Course-level Lesson settings, shown under the Lessons tile. They were on
  /// the Lessons screen but none of them is a Lesson property.
  /// Build 256 Revision 5: who speaks in this Course's Stories.
  String get _storyCharactersSummary => StoryCast.summaryOf(_course);

  /// The working copy with [narrator] and [characters] and, when a library
  /// picture with a known credit became an avatar, that credit among the
  /// Media credits (once), by [StoryCast.withSpeakers]'s narrator rule.
  Course _withSpeakers({
    StorySpeaker? narrator,
    List<StorySpeaker>? characters,
    CourseMediaAttribution? credit,
  }) => StoryCast.withSpeakers(
    _course,
    narrator: narrator ?? _course.narrator,
    characters: characters ?? _course.storyCharacters,
    credits: [if (credit != null) credit],
  );

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
            : StoryCast.replacing(_course.storyCharacters, choice.speaker),
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
    final lines = StoryCast.linesSpokenBy(_course, character.id);
    if (lines > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('“${character.name}” still speaks'),
          content: Text(
            StoryCast.stillSpeaksMessage(lines),
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
        characters: StoryCast.without(_course.storyCharacters, character.id),
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
      subtitle: Text(StoryCast.describe(_course.narrator)),
      trailing: Icon(_canModify ? Icons.edit_outlined : Icons.chevron_right),
      onTap: () => _editSpeaker(_course.narrator, narrator: true),
    ),
    for (final character in _course.storyCharacters)
      ListTile(
        key: ValueKey('story-character-${character.id}'),
        leading: StoryAvatar(speaker: character, courseId: _course.courseId),
        title: Text(character.name),
        subtitle: Text(StoryCast.describe(character)),
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
            'Historical version ${selection.course.courseVersion} loaded into the Course Editor. Save course keeps it as a new version.',
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
    // Build 270 Revision 13 (owner decision): unused means no exercise plays
    // the recording; those without text are under # in the Audio Library.
    final orphans = CourseAudioUsage.unused(
      _course,
      CourseAudioUsage.usesByClip(
        _course,
        (text) => _recordedAudio.segment(text, _course.audioLibrary),
      ),
    );
    if (orphans.isEmpty || !mounted) return;
    if (!prompt) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${orphans.length} unused MP3 file${orphans.length == 1 ? '' : 's'} found',
        ),
        content: Text(
          'No exercise plays these recordings: '
          '${orphans.map((clip) => '“${clip.text.trim()}”').join(', ')}. '
          'Remove them from this Course? Their files are deleted when the '
          'Course is saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove these recordings'),
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
    if (!mounted) return;
    await runReported(
      context,
      'The Audio Library check',
      () => _checkOrphanAudio(prompt: _canModify),
    );
    if (!mounted) return;
    final fresh = _course;
    final result = _session.runAudit();
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
                builder: (_) => exerciseEditorFor(
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
              updatedRound = _hierarchyUpdates.roundWithContent(
                currentRound,
                content,
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
                  // Course has one. Build 261 Revision 2: a tap previews the
                  // working copy as a learner.
                  Tooltip(
                    message: 'Preview as a learner',
                    child: InkWell(
                      key: const Key('course-preview-flag'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => openCoursePreview(context, _course),
                      child:
                          Course.coverImagePattern.hasMatch(_course.coverImage)
                          ? CourseArtwork(
                              key: const Key('course-editor-header-cover'),
                              course: _course,
                              size: 38,
                            )
                          : CourseFlagBadge(
                              course: _course,
                              fallbackCode: _code,
                              width: 38,
                              height: 27,
                            ),
                    ),
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
                      // Applied but not saved yet (Build 270 Revision 12).
                      if (_dirty)
                        Text(
                          'Unsaved changes',
                          key: const Key('course-editor-unsaved'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Build 271 Revision 2 (owner rule: at most three icons in a
            // top bar): Save now, the access mode, Help.
            if (_editorMode == CourseEditorMode.edit)
              IconButton(
                key: const Key('course-editor-save-now'),
                tooltip: 'Save now: write a new version and keep editing',
                onPressed: _dirty ? _saveNow : null,
                icon: const Icon(Icons.save_outlined),
              ),
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
            // Show internal IDs is in Course Info Editor, whose IDs it
            // controls; the other Editor pages keep their toggle.
            const EditorAppBarActions(showInternalIdsToggle: false),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_wizardPause case final pause?)
              ListTile(
                key: const Key('course-editor-wizard-paused'),
                leading: const Icon(Icons.assistant_outlined),
                title: Text(pause.describe(_course)),
                subtitle: widget.onContinueCourseWizard == null
                    ? const Text(
                        'Continue it from the Course\'s ⋮ menu in Course '
                        'Studio.',
                      )
                    : null,
                trailing:
                    widget.onContinueCourseWizard == null ||
                        !widget.access.canEditOriginal
                    ? null
                    : FilledButton(
                        key: const Key('course-editor-continue-wizard'),
                        onPressed: () => _attemptLeave(
                          beforePop: widget.onContinueCourseWizard,
                        ),
                        child: const Text('Continue'),
                      ),
              ),
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
              children: [
                LessonOptionsPanel(
                  working: () => _course,
                  canModify: _canModify,
                  onChanged: _updateDraft,
                  host: context,
                ),
              ],
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
      confirmLabel: 'Rename',
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
              child: const Text('Apply as draft'),
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
      final errors = const PublishGate().lessonErrors(
        candidate,
        changed.lessonId,
      );
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PublishGate.refusal('Lesson', errors))),
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
    final changed = await openSearchResult(
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
          title: CoursePreviewTitle(
            course: _course,
            title: const Text('Lessons'),
          ),
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
                                title: _lessonName(_course, index),
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
                                            ? 'Apply as draft'
                                            : 'Apply',
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

  Widget _lessonLabelIn(Course course) {
    final index = course.lessons.indexWhere(
      (lesson) => lesson.lessonId == _lesson.lessonId,
    );
    return index < 0 ? Text(_lesson.title) : _lessonName(course, index);
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
      final authored = Course.fromJson({
        ..._courseWithIcons.toJson(),
        'lessons': [
          for (final lesson in _course.lessons)
            (lesson.lessonId == edited.lessonId ? edited : lesson).toJson(),
        ],
      });
      final errors = const PublishGate().lessonErrors(
        authored,
        edited.lessonId,
      );
      if (errors > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PublishGate.refusal('Lesson', errors))),
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
    final g = await Navigator.of(context).push<Guidebook>(
      MaterialPageRoute(
        builder: (_) => GuidebookEditorScreen(
          guidebook: _lesson.guidebook,
          guidebookId: _lesson.guidebookId,
          course: _courseWithIcons,
          rounds: _lesson.rounds,
          lessonName: GuidebookModuleEditorScreen.lessonNameFor(
            _lessonNumber,
            _lesson.title,
          ),
        ),
      ),
    );
    if (g == null || !mounted) return;
    // Build 266: Rounds lose their links to removed modules, and their
    // content the sourceRefs to removed entries.
    final rounds = GuidebookRoundLinks.afterGuidebookSave(
      _lesson.guidebook,
      g,
      _lesson.rounds,
    );
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
          'The icon is removed from this Course when you apply the Lesson and save the Course. Cancel undoes it. No Lesson uses it.',
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
          'Custom icon deleted. Apply the Lesson to keep the change.',
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
      (_themeIconAsset == null
          ? 'Numbers'
          : LessonIconCatalog.isLibraryPicture(_themeIconAsset!)
          ? libraryPictureLabel
          : 'Preinstalled icons');

  /// How the editor names a Lesson icon taken from the image library.
  static const libraryPictureLabel = 'Picture from the image library';

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
    if (LessonIconCatalog.isLibraryPicture(_themeIconAsset!)) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(_themeIconAsset!, fit: BoxFit.contain),
      );
    }
    return null;
  }

  Future<void> _chooseThemeIcon() async {
    if (widget.readOnly) return;
    const none = '__none__';
    const import = '__import__';
    const importFrom = '__import_from__';
    const fromLibrary = '__from_library__';
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
                        // Build 264 Revision 8: any QQL picture of the image
                        // library can be the Lesson icon.
                        IconButton(
                          key: const Key('lesson-icon-from-library'),
                          tooltip: 'Choose from the image library',
                          onPressed: () => Navigator.pop(context, fromLibrary),
                          icon: const Icon(Icons.photo_library_outlined),
                        ),
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
    if (selected == fromLibrary) {
      await _chooseThemeIconFromLibrary();
      return;
    }
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

  /// Opens the image library and takes the chosen picture as the Lesson
  /// icon when it is one of QQL's own (not a flag, not a device or Course
  /// picture; those can be imported as custom icons).
  Future<void> _chooseThemeIconFromLibrary() async {
    final picked = await Navigator.of(context).push<ExerciseImageMetadata>(
      MaterialPageRoute(
        builder: (_) => const FlatImageLibraryScreen(readOnly: true),
      ),
    );
    if (picked == null || !mounted) return;
    // The library's lesson icons are the preinstalled icons themselves.
    if (!LessonIconCatalog.isLibraryPicture(picked.assetPath) &&
        !LessonIconCatalog.isApproved(picked.assetPath)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('lesson-icon-from-library-refused'),
          content: Text(
            'A Lesson icon from the library must be one of QQL’s own '
            'pictures, not a flag. A picture of your own can be imported '
            'as a custom icon.',
          ),
        ),
      );
      return;
    }
    setState(() => _themeIconAsset = picked.assetPath);
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
    final changed = await openSearchResult(
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
    // Build 271 Revision 3: the Course as this page shows it is built once
    // for each build (it was built four times), and its cards take their
    // colours from the Audit of this Lesson alone.
    final shown = _courseWithIcons;
    final hierarchyStatus = AuthoringHierarchyStatus.forLesson(
      shown,
      _lesson.lessonId,
    );
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToLessons();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _returnToLessons),
          title: CoursePreviewTitle(
            course: shown,
            title: _lessonLabelIn(shown),
          ),
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
                        ? 'This new Lesson is Draft until its required branch is complete and applied. It then becomes non-Draft automatically. Apply as draft keeps the Lesson Draft until you explicitly Apply it.'
                        : 'This Lesson is Draft and hidden from learner delivery, even when its Rounds and Exercises are Published. Use Save to publish the Lesson.',
                  ),
                if (!widget.readOnly) ...[
                  OutlinedButton(
                    key: const Key('save-lesson-draft'),
                    onPressed: () => _saveLesson(PublicationState.draft),
                    child: const Text('Apply as draft'),
                  ),
                  FilledButton(
                    key: const Key('save-lesson'),
                    onPressed: () => _saveLesson(PublicationState.published),
                    child: const Text('Apply'),
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
            EditorBreadcrumbs(course: shown, lessonId: _lesson.lessonId),
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
                title: const Text('GuideBook', style: _hierarchyLinkStyle),
                // Build 266: the GuideBook is a list of modules.
                subtitle: Text(
                  '${switch (_lesson.guidebook.modules.length) {
                    0 => 'No modules yet',
                    1 => '1 module',
                    final n => '$n modules',
                  }}. Learner reference for this Lesson. The Round Wizard turns its modules into draft Rounds for review.',
                  key: const Key('lesson-guidebook-modules-count'),
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
                    : LessonIconCatalog.isLibraryPicture(_themeIconAsset!)
                    ? libraryPictureLabel
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
    this.roundTitles = true,
  });

  final Course course;
  final Lesson lesson;
  final DateTime Function()? clock;

  /// Where Round titles starts: on, off from the Course Wizard (owner,
  /// 9 October 2026: untitled by default there, to keep it simple).
  final bool roundTitles;

  @override
  State<GuidebookRoundGeneratorScreen> createState() =>
      _GuidebookRoundGeneratorScreenState();
}

class _GuidebookRoundGeneratorScreenState
    extends State<GuidebookRoundGeneratorScreen> {
  /// Approve has been pressed (Build 270 Revision 7).
  bool _approving = false;

  /// Build 266 Revision 3: the module the Rounds practise, or null for All
  /// modules, in order (the default when more than one module can be
  /// practised).
  late String? _focusModuleId = _defaultFocus();
  late final _roundCount = TextEditingController(
    text:
        '${_focusModuleId == null ? GuidebookRoundGenerator.defaultRoundsPerModule : GuidebookRoundGenerator.defaultRoundCount}',
  );

  List<GuidebookModule> get _practisable => [
    for (final module in widget.lesson.guidebook.modules)
      if (GuidebookRoundGenerator.moduleProblem(module) == null) module,
  ];

  String? _defaultFocus() {
    final practisable = _practisable;
    return practisable.length == 1 ? practisable.single.id : null;
  }

  void _chooseFocus(String? moduleId) => setState(() {
    final wasAll = _focusModuleId == null;
    _focusModuleId = moduleId;
    if (wasAll != (moduleId == null)) {
      _roundCount.text =
          '${moduleId == null ? GuidebookRoundGenerator.defaultRoundsPerModule : GuidebookRoundGenerator.defaultRoundCount}';
    }
  });
  final _exerciseCount = TextEditingController(
    text: '${GuidebookRoundGenerator.defaultExercisesPerRound}',
  );
  final _finalIds = TimestampAuthoringIdGenerator();
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  _GuidebookGeneratorStage _stage = _GuidebookGeneratorStage.configure;
  GuidebookGenerationPlan? _plan;
  List<LearningRound> _drafts = const [];
  int _seed = 0;

  /// Build 267 Revision 2: "phase: module title" on each Round, or no
  /// title (learners then see the Round type and number).
  late bool _roundTitles = widget.roundTitles;

  /// Owner decision of 9 October 2026: the middle Round of each module a
  /// Listen Round, off by default (a learner with Audio Exercises off is
  /// asked to turn them on to play it).
  bool _listenRound = false;

  /// Build 267 Revision 3: every second exercise a picture exercise; on by
  /// default when a module has three different pictures.
  late bool _preferPictures = _hasPictures;

  bool get _hasPictures =>
      widget.lesson.guidebook.modules.any(GuidebookRoundGenerator.hasPictures);

  /// The Duel questions of the Lesson once the plan's Rounds are made, for
  /// the plan the count was made for.
  GuidebookGenerationPlan? _duelPlan;
  ({int questions, int audio})? _duelCount;

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
    articles: WordLookupArticles.forLanguage(
      CourseLanguageResolver.learning(widget.course).code,
    ),
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
        focusModuleId: _focusModuleId,
        roundCount: rounds,
        exercisesPerRound: exercises,
        preferPictures: _preferPictures,
        listenRound: _listenRound,
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
      final drafts = _generator().createDrafts(
        widget.lesson.guidebook,
        _plan!,
        roundTitles: _roundTitles,
      );
      setState(() {
        _drafts = drafts;
        _stage = _GuidebookGeneratorStage.drafts;
      });
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  void _changePlanFocus(GuidebookRoundPlan round, String moduleId) {
    try {
      final revised = _generator().changeFocus(
        widget.lesson.guidebook,
        round,
        moduleId,
        preferPictures: _preferPictures,
      );
      final original = _plan!;
      setState(
        () => _plan = GuidebookGenerationPlan(
          roundCount: original.roundCount,
          exercisesPerRound: original.exercisesPerRound,
          focusModuleId: original.focusModuleId,
          skippedModules: original.skippedModules,
          rounds: [
            for (final item in original.rounds)
              item.index == round.index ? revised : item,
          ],
        ),
      );
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  void _changePlanType(GuidebookRoundPlan round, RoundType type) {
    try {
      final revised = _generator().changeType(
        widget.lesson.guidebook,
        round,
        type,
        preferPictures: _preferPictures,
      );
      final original = _plan!;
      setState(
        () => _plan = GuidebookGenerationPlan(
          roundCount: original.roundCount,
          exercisesPerRound: original.exercisesPerRound,
          focusModuleId: original.focusModuleId,
          skippedModules: original.skippedModules,
          rounds: [
            for (final item in original.rounds)
              item.index == round.index ? revised : item,
          ],
        ),
      );
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  void _regenerateDrafts() {
    _seed++;
    try {
      final plan = _generator().plan(
        widget.lesson.guidebook,
        focusModuleId: _plan!.focusModuleId,
        roundCount: _plan!.roundCount,
        exercisesPerRound: _plan!.exercisesPerRound,
        preferPictures: _preferPictures,
        listenRound: _listenRound,
      );
      // The author's focus and type for each Round stay.
      GuidebookRoundPlan kept(int i) {
        var round = plan.rounds[i];
        final chosen = _plan!.rounds[i];
        if (chosen.focusModuleId != null &&
            chosen.focusModuleId != round.focusModuleId) {
          round = _generator().changeFocus(
            widget.lesson.guidebook,
            round,
            chosen.focusModuleId!,
            preferPictures: _preferPictures,
          );
        }
        return _generator().changeType(
          widget.lesson.guidebook,
          round,
          chosen.roundType,
          preferPictures: _preferPictures,
        );
      }

      final revisedPlan = GuidebookGenerationPlan(
        roundCount: plan.roundCount,
        exercisesPerRound: plan.exercisesPerRound,
        focusModuleId: plan.focusModuleId,
        skippedModules: plan.skippedModules,
        rounds: [for (var i = 0; i < plan.rounds.length; i++) kept(i)],
      );
      final drafts = _generator().createDrafts(
        widget.lesson.guidebook,
        revisedPlan,
        roundTitles: _roundTitles,
      );
      setState(() {
        _plan = revisedPlan;
        _drafts = drafts;
      });
    } on GuidebookGenerationException catch (error) {
      _message(error.message);
    }
  }

  Lesson get _draftLesson => _lessonWith(_drafts);

  /// The Duel questions of the Lesson with the plan's Rounds (Build 267
  /// Revision 2, plan §6): counted on the Rounds the plan makes, by
  /// [DuelEligibilityService] (Drafts included); the questions that need
  /// audio apart. Null while Create Duels is off or the plan cannot be made.
  ({int questions, int audio})? get _plannedDuel {
    final plan = _plan;
    if (plan == null || !widget.course.createDuels) return null;
    if (!identical(plan, _duelPlan)) {
      _duelPlan = plan;
      try {
        final drafts = _generator().createDrafts(widget.lesson.guidebook, plan);
        final candidates = const DuelEligibilityService()
            .evaluate(_lessonWith(drafts), includeDrafts: true)
            .candidates;
        final audio = candidates
            .where(
              (candidate) => ExerciseFeatures(candidate.exercise).requiresAudio,
            )
            .length;
        _duelCount = (questions: candidates.length - audio, audio: audio);
      } on GuidebookGenerationException {
        _duelCount = null;
      }
    }
    return _duelCount;
  }

  Widget? _duelCountLine() {
    final count = _plannedDuel;
    if (count == null) return null;
    const needed = DuelEligibilityService.requiredQuestionCount;
    final enough = count.questions >= needed;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        [
          '${count.questions} Duel question${count.questions == 1 ? '' : 's'} '
              '($needed needed)',
          if (count.audio > 0)
            '${count.audio} more need${count.audio == 1 ? 's' : ''} audio',
          if (!enough)
            'raise Rounds per module or Exercises per Round to reach $needed',
        ].join(' · '),
        key: const Key('generator-duel-count'),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enough
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Lesson _lessonWith(List<LearningRound> drafts) => Lesson(
    lessonId: widget.lesson.lessonId,
    publicationState: widget.lesson.publicationState,
    provisionalDraft: widget.lesson.provisionalDraft,
    updatedAt: widget.lesson.updatedAt,
    title: widget.lesson.title,
    rounds: [...widget.lesson.rounds, ...drafts],
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

  List<CourseAuditIssue> _issues() {
    final issues = <CourseAuditIssue>[];
    for (var roundIndex = 0; roundIndex < _drafts.length; roundIndex++) {
      final round = _drafts[roundIndex];
      for (final exercise in round.exercises) {
        issues.addAll(
          CourseAuditService().auditExercise(
            exercise,
            location:
                '${round.displayTitle(roundIndex)} · ${ExerciseLabels.kindName(exercise)}',
            roundId: round.id,
          ),
        );
      }
      for (final content in round.content) {
        final exercise = content.asRunnableExercise();
        if (exercise == null ||
            ExerciseFeatures(exercise).kind == LearnerExerciseKind.roundIntro) {
          continue;
        }
        for (final issue in RoundTypeCompatibility.issuesForExercise(
          round.roundType,
          exercise,
          required: content.required,
        )) {
          issues.add(
            CourseAuditIssue(
              severity: AuditSeverity.error,
              code: 'ROUND_TYPE_${issue.name.toUpperCase()}',
              message: RoundTypeCompatibility.message(issue),
              location: RoundTypePresentation.title(
                round,
                roundIndex + 1,
                widget.course.roundNumberingMode,
                customPrefix: widget.course.customRoundLabel,
              ),
              roundId: round.id,
              exerciseId: exercise.id,
            ),
          );
        }
      }
    }
    return issues;
  }

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
    // Build 270 Revision 7: a second tap before the page closes would pop
    // the page below it too.
    if (_approving) return;
    _approving = true;
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
          'The current Lesson GuideBook is the only source. Choose the module the Rounds practise, or All modules, in order (each module then gets its own Rounds, from Foundations through Practice to Use in context), the number of Rounds (1–12; with All modules per module, at most 24 Rounds in all) and the exercises per Round (1–15). A module needs at least three Words & Expressions entries. Round titles (on by default; off from the Course Wizard) titles each Round like Practice: Al bar; off, the Rounds have no title. Each module\'s first Round is Discover, its last a Test, the others Practice; Listen Round (off by default) makes the middle one a Listen Round, where every exercise needs audio: a learner with Audio Exercises off is asked to turn them on. Prefer picture exercises (on by default when a module has three different pictures) makes every second exercise a picture exercise. With Create Duels on, the plan counts the Lesson\'s Duel questions once its Rounds are made (25 needed), the ones that need audio apart.\n\n'
          'About a third of each Round reviews the earlier modules of the Lesson, nearest first, never as the first exercise. Each exercise shows an entry\'s Context with its translation, so it has one right answer; entries that differ only by their Context are offered as wrong answers, synonyms never are, and a typed answer accepts every synonym. Sentences give Build the translation and Word order. A module with at least three Words & Expressions with pictures also gets Select the image, What is in the picture, Match pictures to words, Spell the word in the picture (a word of up to 12 letters, without its article), Name what you see (an entry of two words or more), Type what you see, Listen and pick the image and Picture flashcard, Plural marks included.\n\n'
          'Each Round records its focus module (Open GuideBook opens there) and the earlier modules it reviews; the first Round of each module opens with a Before you start card holding a copy of the module\'s Overview. Generated material remains draft: review, edit or delete every Round and Exercise before explicit approval. Generation can assist authoring but cannot guarantee pedagogical correctness.',
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
    final all = _focusModuleId == null;
    final modules = all ? _practisable.length : 1;
    final total = modules * rounds;
    return ListView(
      key: const Key('guidebook-generator-configure'),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Generation uses only the current Lesson GuideBook. Nothing is created while configuring or previewing the plan.',
        ),
        const SizedBox(height: 16),
        Tooltip(
          message:
              'The module these Rounds practise. About a third of each Round '
              'reviews earlier modules.',
          child: DropdownButtonFormField<String>(
            key: const Key('generator-focus-module'),
            initialValue: _focusModuleId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Focus module',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('All modules, in order'),
              ),
              for (final module in widget.lesson.guidebook.modules)
                DropdownMenuItem(
                  value: module.id,
                  enabled:
                      GuidebookRoundGenerator.moduleProblem(module) == null,
                  child: Text(
                    GuidebookRoundGenerator.moduleProblem(module) == null
                        ? module.title
                        : '${module.title} (fewer than '
                              '${GuidebookRoundGenerator.minimumWords} Words '
                              '& Expressions)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) =>
                _chooseFocus(value == null || value.isEmpty ? null : value),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('generator-round-count'),
          controller: _roundCount,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: all ? 'Rounds per module' : 'Number of Rounds',
            helperText: all
                ? 'Choose 1–12 per module, at most '
                      '${GuidebookRoundGenerator.maximumRoundsPerRun} Rounds in '
                      'all. Default: 3.'
                : 'Choose 1–12. Default: 6.',
            helperMaxLines: 2,
            errorText: total > GuidebookRoundGenerator.maximumRoundsPerRun
                ? 'At most ${GuidebookRoundGenerator.maximumRoundsPerRun} '
                      'Rounds per run. With $modules modules, choose up to '
                      '${GuidebookRoundGenerator.maximumRoundsPerRun ~/ modules} '
                      'Rounds per module.'
                : null,
            errorMaxLines: 3,
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
          all
              ? '$modules modules × $rounds Rounds × $exercises exercises = '
                    '${total * exercises} exercises'
              : '$rounds Rounds × $exercises exercises = ${rounds * exercises} exercises',
          key: const Key('generator-total'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          key: const Key('generator-round-titles'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Round titles'),
          subtitle: const Text(
            'On: each Round is titled like “Practice: Al bar”. Off: the '
            'Rounds have no title, and learners see the Round type and '
            'number.',
          ),
          value: _roundTitles,
          onChanged: (value) => setState(() => _roundTitles = value),
        ),
        SwitchListTile(
          key: const Key('generator-prefer-pictures'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Prefer picture exercises'),
          subtitle: Text(
            _hasPictures
                ? 'Every second exercise is a picture exercise: Select the '
                      'image, What is in the picture, Match pictures to '
                      'words, Spell the word in the picture, Name what you '
                      'see, Type what you see or Listen and pick the image.'
                : 'Needs a module with three Words & Expressions that have '
                      'different pictures.',
          ),
          value: _preferPictures && _hasPictures,
          onChanged: _hasPictures
              ? (value) => setState(() => _preferPictures = value)
              : null,
        ),
        SwitchListTile(
          key: const Key('generator-listen-round'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Listen Round'),
          subtitle: const Text(
            'The middle Round of each module, with three Rounds or more, is '
            'a Listen Round: every exercise needs audio. A learner with '
            'Audio Exercises off is asked to turn them on to play it.',
          ),
          value: _listenRound,
          onChanged: (value) => setState(() => _listenRound = value),
        ),
      ],
    );
  }

  /// The Lesson's hint and each module's, for the plan.
  List<String> get _sizeHints {
    final modules = widget.lesson.guidebook.modules;
    return [
      ?GuidebookSizeAdvice.lessonHint(modules),
      for (final module in modules) ?GuidebookSizeAdvice.moduleHint(module),
    ];
  }

  Widget _reviewPlan() {
    final distribution = _plan!.presetDistribution.entries.toList();
    return ListView(
      key: const Key('guidebook-generator-plan'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_plan!.rounds.length} Rounds × ${_plan!.exercisesPerRound} exercises = ${_plan!.totalExercises} exercises',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ?_duelCountLine(),
        if (_plan!.skippedModules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Left out, with fewer than '
              '${GuidebookRoundGenerator.minimumWords} Words & Expressions: '
              '${_plan!.skippedModules.join(', ')}.',
              key: const Key('generator-skipped-modules'),
            ),
          ),
        // Build 267 Revision 5: the GuideBook size that suits the Round
        // Wizard, advice only (owner decisions of 9 October 2026).
        if (_sizeHints case final hints when hints.isNotEmpty)
          Padding(
            key: const Key('generator-size-advice'),
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final hint in hints) GuidebookSizeHint(hint)],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Difficulty rises from guided recognition and comprehension through construction and context to freer production. Nothing is created yet: this is only the plan.',
        ),
        const SizedBox(height: 12),
        for (final round in _plan!.rounds)
          ListTile(
            dense: true,
            leading: CircleAvatar(child: Text('${round.index + 1}')),
            title: Text(
              _roundTitles
                  ? '${RoundTypePresentation.label(round.roundType)} · ${round.title}'
                  : '${RoundTypePresentation.label(round.roundType)} · no title '
                        '(${round.title})',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Difficulty ${(round.difficulty * 100).round()}% · ${round.presetIds.map((id) => ExercisePresetRegistry.byId(id)!.name).join(', ')}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _generator().wordsOf(widget.lesson.guidebook, round),
                  key: ValueKey('generator-round-words-${round.index}'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_practisable.length > 1)
                  DropdownButton<String>(
                    key: ValueKey('generator-round-focus-${round.index}'),
                    value: round.focusModuleId,
                    isDense: true,
                    items: [
                      for (final module in _practisable)
                        DropdownMenuItem(
                          value: module.id,
                          child: Text('Focus: ${module.title}'),
                        ),
                    ],
                    onChanged: (moduleId) {
                      if (moduleId != null) _changePlanFocus(round, moduleId);
                    },
                  ),
              ],
            ),
            trailing: DropdownButton<RoundType>(
              key: ValueKey('generator-round-type-${round.index}'),
              value: round.roundType,
              items: [
                for (final type in RoundType.values)
                  DropdownMenuItem(
                    value: type,
                    enabled: GuidebookRoundGenerator.supportsType(type),
                    child: Text(RoundTypePresentation.label(type)),
                  ),
              ],
              onChanged: (type) {
                if (type != null) _changePlanType(round, type);
              },
            ),
          ),
        const SizedBox(height: 8),
        Text(GuidebookRoundGenerator.unsupportedReason(RoundType.reading)),
        Text(GuidebookRoundGenerator.unsupportedReason(RoundType.story)),
        Text(GuidebookRoundGenerator.unsupportedReason(RoundType.speak)),
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
              // Build 267 Revision 10 (owner, 9 October 2026): every Round
              // shows its number and type, as in the plan, also untitled.
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(
                [
                  'Round ${index + 1} · '
                      '${RoundTypePresentation.label(_drafts[index].roundType)}',
                  if (_drafts[index].title.trim().isNotEmpty)
                    _drafts[index].title.trim(),
                ].join(' · '),
                key: ValueKey('generated-draft-title-$index'),
              ),
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
        title: CoursePreviewTitle(
          course: widget.course,
          title: const Text('Generate Rounds'),
        ),
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
      // Build 267 Revision 3: the first page's button stays in view below
      // its options (the Round titles and Prefer picture exercises
      // switches made the page longer than a phone's window).
      bottomNavigationBar: _stage == _GuidebookGeneratorStage.configure
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  key: const Key('generator-review-plan'),
                  onPressed: _preparePlan,
                  child: const Text('Review generation plan'),
                ),
              ),
            )
          : null,
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
  Course get _courseForEditing => StoryCast.withSpeakers(
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
        builder: (_) => exerciseEditorFor(
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
        builder: (_) => exerciseEditorFor(
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
      roundType: RoundType.story,
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

  @override
  Widget build(BuildContext context) {
    final index = _StoryWizardStage.values.indexOf(_stage);
    const names = ['Story', 'Narrator', 'Characters', 'Steps'];
    return Scaffold(
      appBar: AppBar(
        title: CoursePreviewTitle(
          course: widget.course,
          title: Text('New Story · ${names[index]} (${index + 1} of 4)'),
        ),
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
          subtitle: Text(StoryCast.describe(_narrator)),
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
            subtitle: Text(StoryCast.describe(_characters[i])),
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
                : PresetActionChip(preset?.action ?? 'Exercise'),
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

  LearningRound _blankRound(
    String title,
    RoundType type, {
    List<int> timedLimitsSeconds = const [],
  }) {
    final updatedAt = _clock();
    final sample =
        type == RoundType.practice ||
        type == RoundType.discover ||
        type == RoundType.sequence;
    final content = sample
        ? [
            NewCourseStructure.sampleExercise(
              _ids,
              sourceLanguage: _course.sourceLanguage,
              learningLanguage: _course.learningLanguage,
              updatedAt: updatedAt,
            ),
          ]
        : <LearningContent>[];
    return LearningRound(
      id: _ids.next('round'),
      publicationState: PublicationState.draft,
      provisionalDraft: true,
      updatedAt: updatedAt,
      title: title,
      roundType: type,
      timedLimitsSeconds: timedLimitsSeconds,
      content: content,
      flow: type == RoundType.sequence
          ? RoundFlowAuthoring.linearFor(content)
          : null,
    );
  }

  Future<String?> _name(
    String title, {
    String initial = '',
    bool allowEmpty = false,
    String confirmLabel = 'Apply',
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (value == null) return null;
    return value.trim().isEmpty && !allowEmpty ? null : value.trim();
  }

  Future<void> _add() async {
    if (widget.readOnly) return;
    final type = await showDialog<RoundType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Round type'),
        content: SizedBox(
          width: 440,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final candidate in RoundType.values)
                ListTile(
                  key: Key('new-round-type-${candidate.name}'),
                  leading: Icon(RoundTypePresentation.icon(candidate)),
                  title: Text(RoundTypePresentation.label(candidate)),
                  subtitle: Text(RoundTypePresentation.description(candidate)),
                  enabled: candidate != RoundType.speak,
                  onTap: candidate == RoundType.speak
                      ? null
                      : () => Navigator.pop(context, candidate),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (type == null || !mounted) return;
    if (type == RoundType.story) {
      await _openStoryWizard();
      return;
    }
    final title = await _name('New Round', allowEmpty: true);
    if (title != null && mounted) {
      final defaults = _course.defaultTimedLimitsSeconds;
      final limit = type == RoundType.timed && defaults.isEmpty
          ? await chooseTimedLimit(context)
          : null;
      if (!mounted ||
          (type == RoundType.timed && defaults.isEmpty && limit == null)) {
        return;
      }
      _updateRounds([
        ..._rounds,
        _blankRound(
          title,
          type,
          timedLimitsSeconds: type != RoundType.timed
              ? const []
              : defaults.isNotEmpty
              ? [...defaults]
              : [limit!],
        ),
      ]);
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
        StoryCast.withSpeakers(
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
      confirmLabel: 'Rename',
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
      roundType: source.roundType,
      testFixedOrder: source.testFixedOrder,
      testPassingPercent: source.testPassingPercent,
      timedLimitsSeconds: source.timedLimitsSeconds,
      content: source.content,
      flow: source.flow,
      focusModuleId: source.focusModuleId,
      supportingModuleIds: source.supportingModuleIds,
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
              child: const Text('Apply as draft'),
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
      final lesson = Lesson.fromJson({
        ..._draftLesson.toJson(),
        'rounds': rounds.map((round) => round.toJson()).toList(),
      });
      final authored = Course.fromJson({
        ..._course.toJson(),
        'lessons': [
          for (final other in _course.lessons)
            (other.lessonId == widget.lesson.lessonId ? lesson : other)
                .toJson(),
        ],
      });
      final errors = const PublishGate().roundErrors(
        authored,
        widget.lesson.lessonId,
        changed.id,
      );
      if (errors > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PublishGate.refusal('Round', errors))),
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
    final changed = await openSearchResult(
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
    // Build 271 Revision 3: built once for each build (it was built three
    // times), and only this Lesson is audited for the Rounds' colours.
    final shown = _auditableCourse;
    final hierarchyStatus = AuthoringHierarchyStatus.forLesson(
      shown,
      widget.lesson.lessonId,
    );
    final lessonIndex = _course.lessons.indexWhere(
      (lesson) => lesson.lessonId == widget.lesson.lessonId,
    );
    final lessonIdentity = lessonIndex < 0
        ? null
        : const LessonPresentationService().identity(_course, lessonIndex);
    final lessonLabel = lessonIdentity?.fullText ?? widget.lesson.title;
    return PopScope<List<LearningRound>>(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToLesson();
      },
      child: Scaffold(
        appBar: AppBar(
          title: CoursePreviewTitle(
            course: shown,
            title: LabelledText(
              'Rounds · $lessonLabel',
              label: lessonIdentity?.prefix,
            ),
          ),
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
                    ],
                  ),
                ),
              ),
        body: ReorderableListView.builder(
          key: const Key('lesson-rounds-list'),
          header: Column(
            children: [
              EditorBreadcrumbs(
                course: shown,
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
                    // Build 270 Revision 12 (owner decisions): one small
                    // grey line with the label (Lesson Options), the type,
                    // the count and the average difficulty, then the Round's
                    // own title, never the label.
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${RoundTypePresentation.prefix(round.roundType, index + 1, _course.roundNumberingMode, customPrefix: _course.customRoundLabel)} · ${_exerciseCountLabel(round.exercises.length)}',
                              key: ValueKey('round-label-${round.id}'),
                              style: numberingLabelStyle(context),
                            ),
                            // Build 260 Revision 5: the Round's average
                            // difficulty, so a Lesson's curve shows.
                            if (ExerciseDifficulty.averageOf(round)
                                case final average?)
                              DifficultyBadge.average(
                                key: ValueKey('round-difficulty-${round.id}'),
                                average: average,
                              ),
                          ],
                        ),
                        LabelledTitle(
                          label: null,
                          title: RoundTypePresentation.authoredTitle(round),
                        ),
                      ],
                    ),
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
                                ? 'Apply as draft'
                                : 'Apply',
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
  late bool _testFixedOrder;
  int? _testPassingPercent;
  late List<int> _timedLimitsSeconds;

  /// The Round's content flow (a Story), kept through every edit: a linear
  /// flow follows the edited content order (`RoundFlowAuthoring`).
  ContentFlow? _flow;

  /// Build 266: the GuideBook module this Round practises, and the earlier
  /// modules it also reviews (the Round Wizard records them).
  String? _focusModuleId;
  late List<String> _supportingModuleIds;

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
  bool get _isStory => widget.round.roundType == RoundType.story;

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
    _testFixedOrder = widget.round.testFixedOrder;
    _testPassingPercent = widget.round.testPassingPercent;
    _timedLimitsSeconds = [...widget.round.timedLimitsSeconds];
    _flow = widget.round.flow;
    _focusModuleId = widget.round.focusModuleId;
    _supportingModuleIds = [...widget.round.supportingModuleIds];
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
      roundType: widget.round.roundType,
      testFixedOrder: _testFixedOrder,
      testPassingPercent: _testPassingPercent,
      timedLimitsSeconds: _timedLimitsSeconds,
      content: content,
      flow: RoundFlowAuthoring.forContent(_flow, content),
      focusModuleId: _focusModuleId,
      supportingModuleIds: _supportingModuleIds,
    );
  }

  /// Changing the focus keeps the supporting modules, minus the new focus.
  void _setFocusModule(String? id) => _mutateRound(() {
    _focusModuleId = id;
    _supportingModuleIds = [
      for (final supporting in _supportingModuleIds)
        if (supporting != id) supporting,
    ];
  });

  Widget _focusModuleMenu() {
    final modules = _lesson.guidebook.modules;
    final known = {for (final module in modules) module.id};
    final focus = _focusModuleId;
    String titleOf(String id) {
      for (final module in modules) {
        if (module.id == id) return module.title;
      }
      return 'Missing module';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message:
                'The GuideBook module this Round practises. Open GuideBook on '
                'its Before you start card opens the GuideBook at this module.',
            child: DropdownButtonFormField<String>(
              key: const Key('round-focus-module'),
              initialValue: focus ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Focus module',
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('None')),
                for (final module in modules)
                  DropdownMenuItem(
                    value: module.id,
                    child: Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (focus != null && !known.contains(focus))
                  DropdownMenuItem(
                    value: focus,
                    child: const Text('Missing module (not in the GuideBook)'),
                  ),
              ],
              onChanged: widget.readOnly
                  ? null
                  : (value) => _setFocusModule(
                      value == null || value.isEmpty ? null : value,
                    ),
            ),
          ),
          if (_supportingModuleIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Also reviews: ${_supportingModuleIds.map(titleOf).join(', ')}',
                key: const Key('round-supporting-modules'),
              ),
            ),
        ],
      ),
    );
  }

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

  Future<void> _editTimedLimit(int? index) async {
    if (widget.readOnly) return;
    final seconds = await chooseTimedLimit(context);
    if (seconds == null || !mounted) return;
    if (_timedLimitsSeconds.contains(seconds) &&
        (index == null || _timedLimitsSeconds[index] != seconds)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each Timed limit must be different.')),
      );
      return;
    }
    _mutateRound(() {
      if (index == null) {
        _timedLimitsSeconds.add(seconds);
      } else {
        _timedLimitsSeconds[index] = seconds;
      }
    });
  }

  void _moveTimedLimit(int index, int offset) {
    _mutateRound(() {
      final other = index + offset;
      final value = _timedLimitsSeconds.removeAt(index);
      _timedLimitsSeconds.insert(other, value);
    });
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
      final lesson = Lesson.fromJson({
        ..._lesson.toJson(),
        'rounds': [
          for (final round in _lesson.rounds)
            (round.id == edited.id ? edited : round).toJson(),
        ],
      });
      final authored = Course.fromJson({
        ..._course.toJson(),
        'lessons': [
          for (final other in _course.lessons)
            (other.lessonId == _lesson.lessonId ? lesson : other).toJson(),
        ],
      });
      final errors = const PublishGate().roundErrors(
        authored,
        _lesson.lessonId,
        edited.id,
      );
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
              .map((exercise) => '“${ExerciseLabels.summary(exercise)}”')
              .join(', ');
          final more = drafts.length > 3
              ? ' and ${drafts.length - 3} more'
              : '';
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              key: const Key('round-draft-exercises-notice'),
              title: const Text('Apply the Draft Exercises first'),
              content: Text(
                '${drafts.length == 1 ? 'One Exercise is' : '${drafts.length} Exercises are'} still Draft: $titles$more. '
                'A Round applied as normal content shows only its Published Exercises, so open each Draft Exercise and press Apply, or apply the Round as draft.',
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
          SnackBar(content: Text(PublishGate.refusal('Round', errors))),
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
              child: const Text('Apply as draft'),
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
        PublishGate.errorsIn(
          const PublishGate().exerciseIssues(changed),
        ).isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(PublishGate.exerciseRefusal)),
      );
      return;
    }
    if (state.isPublished) {
      final incompatible = PublishGate.roundTypeIssues(_editedRound(), changed);
      if (incompatible.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(PublishGate.roundTypeRefusal(incompatible))),
        );
        return;
      }
    }
    _mutateRound(() => _exercises[index] = changed);
  }

  String _summary(Exercise e) => ExerciseLabels.summary(e);

  Course get _workingCourse => _hierarchyUpdates.apply(
    _course,
    OverlayRoundDraft(_lesson, _editedRound()),
  );

  /// The Audit of one exercise: the findings of this Round's Audit that
  /// name it, which make its card red (owner request of 9 October 2026).
  Future<void> _auditExercise(int index) {
    final course = _workingCourse;
    final exercise = _exercises[index];
    final round = CourseAuditService().auditRound(course, _editedRound().id);
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CourseAuditScreen(
          course: course,
          result: CourseAuditResult([
            for (final issue in round.issues)
              if (issue.exerciseId == exercise.id) issue,
          ]),
          title: 'Exercise Audit',
        ),
      ),
    );
  }

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
        builder: (_) => exerciseEditorFor(
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
        builder: (_) => exerciseEditorFor(
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
  /// button instead of New Exercise and Exercise Wizard; it
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
                    '• ${ExerciseLabels.kindName(e).replaceAll('_', ' ')}: ${_summary(e)}',
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
      roundType: widget.round.roundType,
      testFixedOrder: widget.round.testFixedOrder,
      testPassingPercent: widget.round.testPassingPercent,
      timedLimitsSeconds: widget.round.timedLimitsSeconds,
      flow: RoundFlowAuthoring.singleExercisePreviewFlow(
        widget.round.roundType,
        _exercises[index],
      ),
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
    final changed = await openSearchResult(
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
    // Build 271 Revision 3: built once for each build (it was built four
    // times), and only this Lesson is audited for the exercises' colours.
    final shown = _workingCourse;
    final hierarchyStatus = AuthoringHierarchyStatus.forLesson(
      shown,
      _lesson.lessonId,
    );
    return PopScope(
      canPop: _routeMayPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToRounds();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _returnToRounds),
          title: CoursePreviewTitle(
            course: shown,
            title: _roundName(shown, _editedRound(), widget.roundIndex + 1),
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
                  style: _compactButtonStyle,
                  onPressed: _exercises.isEmpty ? null : _previewRound,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Preview'),
                ),
                if (!_publicationState.isPublished)
                  _DraftBranchIndicator(
                    key: const Key('round-own-draft-indicator'),
                    message: _provisionalDraft
                        ? 'This new Round is Draft until its required content is complete and applied. It then becomes non-Draft automatically. Apply as draft keeps the Round Draft until you explicitly Apply it.'
                        : 'This Round is Draft and hidden from learner delivery, even when its Exercises are Published. Use Save to publish the Round.',
                  ),
                if (!widget.readOnly) ...[
                  OutlinedButton(
                    key: const Key('round-save-draft'),
                    style: _compactButtonStyle,
                    onPressed: () => _saveRound(PublicationState.draft),
                    child: const Text('Apply as draft'),
                  ),
                  FilledButton(
                    key: const Key('round-save'),
                    style: _compactButtonStyle,
                    onPressed: () => _saveRound(PublicationState.published),
                    child: const Text('Apply'),
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
                course: shown,
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
              if (_course.useGuidebook) _focusModuleMenu(),
              if (widget.round.roundType == RoundType.test) ...[
                SwitchListTile(
                  key: const Key('test-fixed-order'),
                  title: const Text('Fixed question order'),
                  subtitle: const Text(
                    'Off: questions are randomized for each attempt.',
                  ),
                  value: _testFixedOrder,
                  onChanged: widget.readOnly
                      ? null
                      : (value) => _mutateRound(() => _testFixedOrder = value),
                ),
                SwitchListTile(
                  key: const Key('test-passing-enabled'),
                  title: const Text('Show pass or fail label'),
                  subtitle: const Text(
                    'The threshold changes the results label only; completion and XP stay normal.',
                  ),
                  value: _testPassingPercent != null,
                  onChanged: widget.readOnly
                      ? null
                      : (value) => _mutateRound(
                          () => _testPassingPercent = value ? 70 : null,
                        ),
                ),
                if (_testPassingPercent != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text('Passing threshold: $_testPassingPercent%'),
                        Slider(
                          key: const Key('test-passing-threshold'),
                          value: _testPassingPercent!.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: widget.readOnly
                              ? null
                              : (value) => _mutateRound(
                                  () => _testPassingPercent = value.round(),
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (widget.round.roundType == RoundType.timed) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Time limits unlock in this order. Each first on-time completion earns its own bonus.',
                  ),
                ),
                for (var index = 0; index < _timedLimitsSeconds.length; index++)
                  ListTile(
                    key: Key('timed-stage-$index'),
                    title: Text(
                      'Stage ${index + 1} · ${TimedRoundRules.label(_timedLimitsSeconds[index])}',
                    ),
                    onTap: widget.readOnly
                        ? null
                        : () => _editTimedLimit(index),
                    trailing: widget.readOnly
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('timed-stage-up-$index'),
                                tooltip: 'Move up',
                                onPressed: index == 0
                                    ? null
                                    : () => _moveTimedLimit(index, -1),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                key: Key('timed-stage-down-$index'),
                                tooltip: 'Move down',
                                onPressed:
                                    index == _timedLimitsSeconds.length - 1
                                    ? null
                                    : () => _moveTimedLimit(index, 1),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                key: Key('timed-stage-remove-$index'),
                                tooltip: 'Remove time limit',
                                onPressed: () => _mutateRound(
                                  () => _timedLimitsSeconds.removeAt(index),
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                  ),
                if (!widget.readOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: OutlinedButton.icon(
                      key: const Key('timed-add-limit'),
                      onPressed: () => _editTimedLimit(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add time limit'),
                    ),
                  ),
              ],
              if ((widget.round.roundType == RoundType.story ||
                      widget.round.roundType == RoundType.sequence) &&
                  _flow != null &&
                  _flow!.isLinear) ...[
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
                    // Build 260 Revision 5: the exercise's difficulty.
                    title: Row(
                      children: [
                        Flexible(child: Text(ExerciseLabels.typeLabel(e))),
                        if (ExerciseDifficulty.of(e) case final level?)
                          DifficultyBadge(
                            key: ValueKey('exercise-difficulty-${e.id}'),
                            level: level,
                          ),
                        // Build 267 Revision 8: the author's notes.
                        if (e.editorNotes.trim().isNotEmpty)
                          Tooltip(
                            key: ValueKey('exercise-notes-${e.id}'),
                            message: e.editorNotes.trim(),
                            triggerMode: TooltipTriggerMode.longPress,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.sticky_note_2_outlined,
                                size: 18,
                                semanticLabel: 'Editor notes',
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                      ],
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
                        if (v == 'audit') _auditExercise(i);
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
                        const PopupMenuItem(
                          value: 'audit',
                          child: Text('Audit'),
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
                                ? 'Apply as draft'
                                : 'Apply',
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

Exercise _blankExerciseForPreset(String presetId, AuthoringIdGenerator ids) =>
    PresetRecipes.blankFor(presetId, ids.next('exercise'));

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
                    leading: PresetActionChip(preset.action),
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
        builder: (_) => exerciseEditorFor(
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
            roundType: widget.round.roundType,
            testFixedOrder: widget.round.testFixedOrder,
            testPassingPercent: widget.round.testPassingPercent,
            timedLimitsSeconds: widget.round.timedLimitsSeconds,
            flow: RoundFlowAuthoring.singleExercisePreviewFlow(
              widget.round.roundType,
              exercise,
            ),
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
      const Text('Nothing is created yet: this is only the plan.'),
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
                  : ExercisePresetRegistry.nameOrId(draft.type),
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
              child: const Text('Apply'),
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
      appBar: AppBar(
        title: CoursePreviewTitle(
          course: widget.course,
          title: const Text('Exercise Creation Wizard'),
        ),
      ),
      body: switch (_stage) {
        _ExerciseWizardStage.setup => _setup(),
        _ExerciseWizardStage.plan => _reviewPlan(),
        _ExerciseWizardStage.guided => _guided(),
      },
    ),
  );
}

/// A Lesson's name with its label in the label style (Build 270
/// Revision 12).
Widget _lessonName(Course course, int index) {
  final identity = const LessonPresentationService().identity(course, index);
  return LabelledText(identity.fullText, label: identity.prefix);
}

/// A Round's label line, as on the learner path, above its own title
/// (Build 270 Revision 12, owner report: the label is never the title).
Widget _roundName(Course course, LearningRound round, int number) =>
    LabelledTitle(
      label: RoundTypePresentation.prefix(
        round.roundType,
        number,
        course.roundNumberingMode,
        customPrefix: course.customRoundLabel,
      ),
      title: RoundTypePresentation.authoredTitle(round),
    );

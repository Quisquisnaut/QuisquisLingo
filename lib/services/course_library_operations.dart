import '../models/course_flag_selection.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import 'course_access_policy.dart';
import 'audit_code_registry.dart';
import 'course_audit_service.dart';
import 'course_editor_service.dart';
import 'course_file_store.dart';
import 'course_flag_service.dart';
import 'course_language_resolver.dart';
import 'course_learner_visibility_service.dart';
import 'course_library_service.dart';
import 'course_merge_service.dart';
import 'course_package_import.dart';
import 'course_privacy.dart';
import 'course_service.dart';
import 'course_study.dart';
import 'course_wizard.dart';
import 'course_wizard_memory.dart';
import 'custom_course_transfer_service.dart';
import 'file_dialog_service.dart';
import 'formal_name_policy.dart';
import 'new_course_structure.dart';
import 'profile_service.dart';
import 'progress_service.dart';
import 'publisher_course_export.dart';
import 'publisher_export_memory.dart';
import 'settings_service.dart';
import 'team_service.dart';
import 'stored_course_reader.dart';

/// The Course Manager menu entries, in menu order. [study] and [review]
/// (Build 261 Revision 1) come from [CourseManagerLibrary.studyEntriesFor],
/// shown only where the menu can return to the learner page.
/// [continueCourseWizard] (Build 267) starts the menu of a Course whose
/// Course Wizard is paused.
enum CourseManagerAction {
  study,
  review,
  continueCourseWizard,
  removeFromMyCourses,
  removePublisherFromDevice,
  courseInfo,
  open,
  toggleLearnerVisibility,
  fork,
  copyAsNewCourse,
  merge,
  audit,
  export,
  exportAsPublisherCourse,
  delete,
}

/// One Course Manager menu entry, with the reason it cannot be used, if any.
class CourseManagerEntry {
  const CourseManagerEntry(this.action, [this.unavailableReason]);

  final CourseManagerAction action;

  /// Shown under a greyed-out entry; null when the entry can be used.
  final String? unavailableReason;

  bool get available => unavailableReason == null;
}

/// What an import of an already-used custom Course ID may do, in dialog order.
enum CourseImportChoice { copyAsNewCourse, fork, replace }

/// What Course Manager lists and who is looking, read once per reload.
///
/// Every question the screen asks about it is answered here, so which action
/// is offered for which Course, and which title a copy gets, can be tested
/// without building the screen.
class CourseManagerLibrary {
  const CourseManagerLibrary({
    this.personalCourses = const [],
    this.bundledCourses = const [],
    this.unreadable = const [],
    this.activeProfileId,
    this.activeCourseId,
    this.hiddenCourseIds = const {},
    this.memberTeamIds = const {},
    this.isAdmin = false,
    this.importAuthoringEnabled = false,
    this.reviewableCourseIds = const {},
    this.pausedWizards = const {},
  });

  /// The stored Custom and Publisher Courses in the active personal library.
  final List<Course> personalCourses;

  /// The Bundled Courses in the active personal library.
  final List<Course> bundledCourses;

  /// Stored Course files that could not be read; kept untouched on disk.
  final List<SkippedCourseFile> unreadable;
  final String? activeProfileId;
  final String? activeCourseId;
  final Set<String> hiddenCourseIds;
  final Set<String> memberTeamIds;
  final bool isAdmin;

  /// Copy as New Course and Fork are offered on a matching-ID import.
  final bool importAuthoringEnabled;

  /// The Courses with a completed Round for Review to offer.
  final Set<String> reviewableCourseIds;

  /// The paused Course Wizards, by Course ID (Build 267).
  final Map<String, CourseWizardPause> pausedWizards;

  /// Study and Review for [course], with the reason each cannot be used.
  List<CourseManagerEntry> studyEntriesFor(Course course) => [
    CourseManagerEntry(
      CourseManagerAction.study,
      CourseStudy.studyUnavailableReason(
        course,
        hasLearner: activeProfileId != null,
      ),
    ),
    CourseManagerEntry(
      CourseManagerAction.review,
      CourseStudy.reviewUnavailableReason(
        course,
        hasLearner: activeProfileId != null,
        hasCompletedRounds: reviewableCourseIds.contains(course.courseId),
      ),
    ),
  ];

  CourseAccessCapabilities capabilitiesFor(Course course) =>
      CourseAccessPolicy.evaluate(
        course,
        profileId: activeProfileId,
        memberTeamIds: memberTeamIds,
      );

  /// The actions [course] can use now, in menu order.
  List<CourseManagerAction> actionsFor(Course course) => [
    for (final entry in entriesFor(course))
      if (entry.available) entry.action,
  ];

  /// Every entry the menu shows for [course], in menu order. An entry that
  /// depends on rights, license, verification or admin status is shown with
  /// the reason it cannot be used; an entry that can never apply to this kind
  /// of Course is left out.
  List<CourseManagerEntry> entriesFor(Course course) {
    final access = capabilitiesFor(course);
    final official = course.originType.isOfficial;
    const onlyInside = 'Only the Maintainer or assigned Team can';
    return [
      if (!official && pausedWizards.containsKey(course.courseId))
        CourseManagerEntry(
          CourseManagerAction.continueCourseWizard,
          access.canEditOriginal
              ? null
              : '$onlyInside continue its Course Wizard.',
        ),
      const CourseManagerEntry(CourseManagerAction.removeFromMyCourses),
      if (course.originType == CourseOriginType.externalOfficial)
        CourseManagerEntry(
          CourseManagerAction.removePublisherFromDevice,
          isAdmin
              ? null
              : 'Only an admin can remove a Publisher Course from this device.',
        ),
      const CourseManagerEntry(CourseManagerAction.courseInfo),
      const CourseManagerEntry(CourseManagerAction.open),
      CourseManagerEntry(
        CourseManagerAction.toggleLearnerVisibility,
        _learnerVisibilityUnavailable(course),
      ),
      CourseManagerEntry(CourseManagerAction.fork, _forkUnavailable(course)),
      if (!official)
        CourseManagerEntry(
          CourseManagerAction.copyAsNewCourse,
          access.canCopyAsNewCourse ? null : '$onlyInside copy this Course.',
        ),
      if (!official)
        CourseManagerEntry(
          CourseManagerAction.merge,
          access.hasOperationalAccess ? null : '$onlyInside merge this Course.',
        ),
      const CourseManagerEntry(CourseManagerAction.audit),
      CourseManagerEntry(
        CourseManagerAction.export,
        official || access.hasOperationalAccess
            ? null
            : '$onlyInside export this Course.',
      ),
      // Build 262 Revision 2: the Course itself decides the other reasons,
      // which its export page names (PublisherCourseExport.refusals).
      if (!official)
        CourseManagerEntry(
          CourseManagerAction.exportAsPublisherCourse,
          access.hasOperationalAccess
              ? null
              : PublisherCourseExport.noAccessReason,
        ),
      if (!official)
        CourseManagerEntry(
          CourseManagerAction.delete,
          access.canDelete ? null : '$onlyInside delete this Course.',
        ),
    ];
  }

  /// Only Hide is refused for the Course being studied; Unhide can repair it.
  String? _learnerVisibilityUnavailable(Course course) {
    if (activeProfileId == null) return 'Select a learner profile first.';
    if (activeCourseId == course.courseId &&
        !hiddenCourseIds.contains(course.courseId)) {
      return "You're studying this Course";
    }
    return null;
  }

  /// Why [course] cannot be forked now, or null when it can.
  String? _forkUnavailable(Course course) {
    final access = capabilitiesFor(course);
    if (access.canFork) return null;
    if (activeProfileId == null) return 'Select a learner profile first.';
    if (!course.originType.isOfficial && access.hasOperationalAccess) {
      return 'You maintain this Course: use Copy as New Course instead.';
    }
    if (course.originType == CourseOriginType.externalOfficial &&
        course.publisherVerificationStatus !=
            PublisherVerificationStatus.verified) {
      return 'The Publisher Course must be verified first.';
    }
    return 'The license does not allow derivative works.';
  }

  /// `<title> copy`, then `<title> copy 2`, … among the listed titles only.
  String nextCopyTitle(String sourceTitle) =>
      CourseMergeService.nextAvailableTitle(
        '$sourceTitle copy',
        personalCourses.map((course) => course.title),
      );

  /// `<title>`, then `<title> 2`, … among the listed titles only.
  String nextMergeTitle(String title) => CourseMergeService.nextAvailableTitle(
    title,
    personalCourses.map((course) => course.title),
  );

  /// The New Course duplicate-name warning.
  bool hasCourseTitled(String title) => personalCourses.any(
    (course) =>
        FormalNamePolicy.comparisonKey(course.title) ==
        FormalNamePolicy.comparisonKey(title),
  );

  Course? personalCourse(String courseId) {
    for (final course in personalCourses) {
      if (course.courseId == courseId) return course;
    }
    return null;
  }
}

/// The Audit's view of a read Course package, and what its import may do.
class CourseImportReview {
  const CourseImportReview({
    required this.course,
    required this.errors,
    required this.warnings,
    required this.existing,
    required this.choices,
    this.receivedUpdate = false,
    this.replaceUnavailableReason,
    this.notExecutableCount = 0,
    this.existingUnopenable,
  });

  final Course course;
  final List<CourseAuditIssue> errors;
  final List<CourseAuditIssue> warnings;

  /// How many exercises this version of QQL cannot play (Build 256 Revision
  /// 6, plan A.6): imported and kept unchanged, skipped by learners.
  final int notExecutableCount;

  /// The stored Course already using this Course ID, if any.
  final Course? existing;

  /// The stored Course using this Course ID when this version cannot open
  /// it (Build 266 Revision 2): importing the Course again replaces it.
  final UnopenableStoredCourse? existingUnopenable;

  /// Offered for a matching custom Course ID; Cancel is always offered.
  final List<CourseImportChoice> choices;

  /// True only when an outsider may install a newer received Custom Course.
  final bool receivedUpdate;

  /// Why the matching-ID Custom Course cannot be replaced, when unavailable.
  final String? replaceUnavailableReason;

  bool get blocked => errors.isNotEmpty;
  bool get isPublisherCourse =>
      course.originType == CourseOriginType.externalOfficial;

  /// Installing over an unverified stored version asks to associate them.
  bool get confirmsUnverifiedAssociation =>
      existing != null &&
      existing!.publisherVerificationStatus !=
          PublisherVerificationStatus.verified;
}

/// A merged Course the Audit accepted, waiting for confirmation.
class CourseMergeProposal {
  const CourseMergeProposal({
    required this.left,
    required this.right,
    required this.merged,
    required this.hasAuditWarnings,
  });

  final Course left;
  final Course right;
  final Course merged;
  final bool hasAuditWarnings;
}

/// One credit row of the New Course dialog.
typedef NewCourseCredit = ({
  String name,
  Set<String> roles,
  String customRoles,
});

/// One Rights Holder row of the New Course dialog.
typedef NewCourseRightsHolder = ({CourseRightsHolderType type, String name});

/// Owns the Course Manager workflow around the storage operations: what is
/// listed, which action is offered for which Course, the titles of copies and
/// merges, resolving a Fork's official source, reviewing an import, composing
/// a merge and building a New Course.
///
/// It shows no dialog and holds no widget state. The storage itself stays with
/// its owners — [CourseEditorService], [CoursePackageImport] and
/// [CourseLibraryService] — and every operation here acts on **stored**
/// Courses, never on a Course Editor working copy.
class CourseLibraryOperations {
  CourseLibraryOperations({
    CourseEditorService? editor,
    CustomCourseTransferService? transfer,
    CourseMergeService? merge,
    CourseService? courses,
    CourseLibraryService? library,
    CourseLearnerVisibilityService? learnerVisibility,
    SettingsService? settings,
    ProfileService? profiles,
    TeamService? teams,
    CourseFlagService? flags,
    PublisherExportMemory? publisherMemory,
    CourseWizardMemory? wizardMemory,
    DateTime Function()? clock,
  }) : editor = editor ?? CourseEditorService(),
       transfer = transfer ?? CustomCourseTransferService(),
       _merge = merge ?? CourseMergeService(),
       _courses = courses ?? CourseService(),
       _settings = settings ?? SettingsService(),
       profiles = profiles ?? ProfileService(),
       _flags = flags ?? CourseFlagService(),
       publisherMemory = publisherMemory ?? PublisherExportMemory(),
       wizardMemory = wizardMemory ?? CourseWizardMemory(),
       _clock = clock ?? DateTime.now {
    this.teams = teams ?? TeamService(profileService: this.profiles);
    _membership =
        library ?? CourseLibraryService(profileService: this.profiles);
    visibility =
        learnerVisibility ??
        CourseLearnerVisibilityService(
          profiles: this.profiles,
          settings: _settings,
        );
  }

  final CourseEditorService editor;
  final CustomCourseTransferService transfer;
  final ProfileService profiles;
  late final TeamService teams;
  final CourseMergeService _merge;
  final CourseService _courses;
  late final CourseLibraryService _membership;
  late final CourseLearnerVisibilityService visibility;
  final SettingsService _settings;
  final CourseFlagService _flags;

  /// The publisher each Course was last exported for (owner request of
  /// 4 October 2026).
  final PublisherExportMemory publisherMemory;

  /// Where each paused Course Wizard stands (Build 267).
  final CourseWizardMemory wizardMemory;
  final DateTime Function() _clock;

  /// Everything Course Manager lists. With [importOnly], no Bundled Course is
  /// loaded and matching-ID authoring follows the Course Editor unlock.
  Future<CourseManagerLibrary> load({
    Course? currentCourse,
    bool importOnly = false,
  }) async {
    final personal = await _membership.included(await editor.listUserCourses());
    final bundled = <Course>[
      if (!importOnly)
        for (final code in CourseService.bundledAssets.keys)
          await _courses.loadCourse(code),
    ];
    // Home supplies its learner projection, which omits authored Draft content.
    // Keep the active bundle first without replacing its immutable source.
    final currentBundled = bundled
        .where((course) => course.courseId == currentCourse?.courseId)
        .firstOrNull;
    final includedBundled = await _membership.included([
      if (currentBundled != null) currentBundled,
      ...bundled.where((course) => course.courseId != currentBundled?.courseId),
    ]);
    final importAuthoringEnabled =
        !importOnly || await _settings.isCourseEditorUnlocked();
    final activeProfileId = await profiles.getActiveProfileId();
    final isAdmin =
        activeProfileId != null && await profiles.isAdmin(activeProfileId);
    final memberTeamIds = activeProfileId == null
        ? const <String>{}
        : (await teams.teamsForProfile(
            activeProfileId,
          )).map((team) => team.teamId).toSet();
    final hiddenCourseIds = await visibility.hiddenCourseIds(
      [...personal, ...includedBundled].map((course) => course.courseId),
    );
    final reviewableCourseIds = activeProfileId == null
        ? const <String>{}
        : await CourseStudy.coursesWithCompletedRounds(ProgressService());
    final personalIds = {for (final course in personal) course.courseId};
    final pausedWizards = {
      for (final MapEntry(key: courseId, value: pause)
          in (await wizardMemory.all()).entries)
        if (personalIds.contains(courseId)) courseId: pause,
    };
    return CourseManagerLibrary(
      personalCourses: personal,
      bundledCourses: includedBundled,
      unreadable: editor.unreadableCourseFiles,
      activeProfileId: activeProfileId,
      activeCourseId: currentCourse?.courseId,
      hiddenCourseIds: Set.unmodifiable(hiddenCourseIds),
      memberTeamIds: memberTeamIds,
      isAdmin: isAdmin,
      importAuthoringEnabled: importAuthoringEnabled,
      reviewableCourseIds: Set.unmodifiable(reviewableCourseIds),
      pausedWizards: Map.unmodifiable(pausedWizards),
    );
  }

  /// Copy as New Course of the stored [course], titled by [library].
  Future<CourseConfirmationResult> copyAsNewCourse(
    Course course,
    CourseManagerLibrary library,
  ) => editor.createCopyAsNewCourse(
    source: course,
    title: library.nextCopyTitle(course.title),
  );

  /// Fork of the stored [course]. An official Course is forked from its
  /// immutable official source, and refused when that is unavailable.
  Future<CourseConfirmationResult> fork(Course course) async {
    var source = course;
    if (course.originType.isOfficial) {
      final bundledSource =
          course.originType == CourseOriginType.bundledOfficial
          ? await _courses.loadBundledCourse(
              CourseService.bundledCodeForCourse(course),
            )
          : null;
      final official = await editor.officialSourceFor(
        course,
        bundledSource: bundledSource,
      );
      if (official == null) {
        throw StateError('The immutable official source is unavailable.');
      }
      source = official;
    }
    return editor.createFork(source: source);
  }

  /// The merged Course named by [library], refused when the Audit finds
  /// errors. Confirm it with [confirmMerge].
  Future<CourseMergeProposal> composeMerge({
    required Course left,
    required Course right,
    required List<LessonMergeChoice> choices,
    required CourseMergeOptions options,
    required CourseManagerLibrary library,
  }) async {
    await _refuseHiddenPrivate(right);
    final merged = await _merge.createMergedCourse(
      left: left,
      right: right,
      choices: choices,
      options: CourseMergeOptions(
        title: options.title,
        outputTitle: library.nextMergeTitle('${options.title} merged'),
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
    final audit = CourseAuditService().auditCourse(merged);
    final errors = audit.count(AuditSeverity.error);
    if (errors > 0) {
      throw StateError(
        'Course Audit found $errors error${errors == 1 ? '' : 's'}. Fix the source Course content before merging.',
      );
    }
    return CourseMergeProposal(
      left: left,
      right: right,
      merged: merged,
      hasAuditWarnings: audit.count(AuditSeverity.warning) > 0,
    );
  }

  Future<CourseConfirmationResult> confirmMerge(CourseMergeProposal proposal) =>
      editor.confirmMergedCourse(
        left: proposal.left,
        right: proposal.right,
        merged: proposal.merged,
      );

  /// What the read package in [attempt] may do. A Bundled Course package is
  /// refused; the chosen action still runs through [attempt] itself.
  /// Someone else's Private course is neither imported nor merged (Build 259
  /// Revision 8, owner decision): it would stay hidden for this profile.
  Future<void> _refuseHiddenPrivate(Course course) async {
    if (CoursePrivacy.isPrivate(course) &&
        !await CoursePrivacy(
          accessPolicy: CourseAccessPolicy(profileService: profiles),
        ).isVisible(course)) {
      throw FormatException(CourseLibraryReports.privateCourseRefused(course));
    }
  }

  Future<CourseImportReview> reviewImport(
    CoursePackageImport attempt,
    CourseManagerLibrary library,
  ) async {
    final course = attempt.course;
    if (course.originType == CourseOriginType.bundledOfficial) {
      throw const FormatException(
        'Bundled official courses are installed only with QuisquisLingo application builds.',
      );
    }
    await _refuseHiddenPrivate(course);
    final installed = await editor.listUserCourses();
    final audit = CourseAuditService().auditCourse(course);
    final existing = installed
        .where((candidate) => candidate.courseId == course.courseId)
        .firstOrNull;
    final unopenable =
        existing == null && course.originType == CourseOriginType.custom
        ? await editor.unopenableCourse(course.courseId)
        : null;
    final mayReplaceUnopenable =
        unopenable != null && await editor.mayRemoveUnopenable(unopenable);
    final imported = library.capabilitiesFor(course);
    final ordinaryReplace =
        existing != null &&
        !existing.originType.isOfficial &&
        library.capabilitiesFor(existing).canEditOriginal;
    final receivedDecision =
        existing != null &&
            !existing.originType.isOfficial &&
            course.originType == CourseOriginType.custom &&
            !ordinaryReplace
        ? await editor.receivedCourses.reviewUpdate(
            existing: existing,
            incoming: course,
            profileId: library.activeProfileId,
          )
        : null;
    return CourseImportReview(
      course: course,
      errors: [
        for (final issue in audit.issues)
          if (issue.severity == AuditSeverity.error) issue,
      ],
      warnings: [
        for (final issue in audit.issues)
          if (issue.severity == AuditSeverity.warning) issue,
      ],
      notExecutableCount: audit.issues
          .where((issue) => issue.code == AuditCode.exerciseNotExecutable.code)
          .length,
      existing: existing,
      existingUnopenable: unopenable,
      receivedUpdate: receivedDecision?.allowed ?? false,
      replaceUnavailableReason: unopenable != null
          ? (mayReplaceUnopenable
                ? null
                : 'Only its Maintainer, a member of its Team or an admin can '
                      'replace it.')
          : ordinaryReplace
          ? null
          : receivedDecision?.unavailableReason,
      choices: [
        if ((existing != null || unopenable != null) &&
            course.originType != CourseOriginType.externalOfficial) ...[
          if (library.importAuthoringEnabled && imported.canCopyAsNewCourse)
            CourseImportChoice.copyAsNewCourse,
          if (library.importAuthoringEnabled && imported.canFork)
            CourseImportChoice.fork,
          if (ordinaryReplace ||
              receivedDecision?.allowed == true ||
              mayReplaceUnopenable)
            CourseImportChoice.replace,
        ],
      ],
    );
  }

  /// Writes the stored [course]'s package into the fixed Exports folder.
  Future<({String path, String? notice})> exportCourse(Course course) async {
    final notice = CourseAuditService().auditCourse(course).exportNotice;
    return (path: await transfer.exportCourse(course), notice: notice);
  }

  /// The same package, saved with the system dialog.
  Future<({FileDialogResult result, String? notice})> saveCourseTo(
    Course course,
  ) async {
    final notice = CourseAuditService().auditCourse(course).exportNotice;
    return (result: await transfer.exportCourseTo(course), notice: notice);
  }

  /// Why the active profile cannot export the stored [course] as a Publisher
  /// Course (Build 262 Revision 2); empty when it can.
  Future<List<String>> publisherExportRefusals(Course course) async {
    final activeProfileId = await profiles.getActiveProfileId();
    final memberTeamIds = activeProfileId == null
        ? const <String>{}
        : (await teams.teamsForProfile(
            activeProfileId,
          )).map((team) => team.teamId).toSet();
    return PublisherCourseExport.refusals(
      course,
      hasOperationalAccess: CourseAccessPolicy.evaluate(
        course,
        profileId: activeProfileId,
        memberTeamIds: memberTeamIds,
      ).hasOperationalAccess,
    );
  }

  /// The publisher [course] was last exported for, to fill in the page.
  Future<PublisherIdentity?> rememberedPublisher(Course course) =>
      publisherMemory.recall(course.courseId);

  /// The stored [course] as an unsigned Publisher Course of [publisher],
  /// released now, written into the fixed Exports folder; the publisher is
  /// then remembered for the Course. A refused Course throws a
  /// [FormatException] naming the reasons, and nothing is written.
  Future<String> exportAsPublisherCourse(
    Course course,
    PublisherIdentity publisher,
  ) async {
    final exported = await _publisherCourse(course, publisher);
    final path = await transfer.exportCourse(
      exported,
      publisherVersion: exported.officialCourseVersion,
    );
    await publisherMemory.remember(course.courseId, publisher);
    return path;
  }

  /// The same Publisher Course, saved with the system dialog; the publisher
  /// is remembered once the file is saved.
  Future<FileDialogResult> savePublisherCourseTo(
    Course course,
    PublisherIdentity publisher,
  ) async {
    final exported = await _publisherCourse(course, publisher);
    final result = await transfer.exportCourseTo(
      exported,
      publisherVersion: exported.officialCourseVersion,
    );
    if (result.outcome == FileDialogOutcome.saved) {
      await publisherMemory.remember(course.courseId, publisher);
    }
    return result;
  }

  Future<Course> _publisherCourse(
    Course course,
    PublisherIdentity publisher,
  ) async {
    final refusals = await publisherExportRefusals(course);
    if (refusals.isNotEmpty) throw FormatException(refusals.join(' '));
    return PublisherCourseExport.build(course, publisher, now: _clock());
  }

  /// The World Flag problem, if any, and the Audit of [course].
  Future<({CourseAuditResult result, String? flagProblem})> audit(
    Course course,
  ) async {
    String? flagProblem;
    try {
      await _flags.validateWorldFlag(course);
    } on FormatException catch (error) {
      flagProblem = error.message;
    }
    return (
      result: CourseAuditService().auditCourse(course),
      flagProblem: flagProblem,
    );
  }

  Future<void> deleteCourse(Course course) async {
    await editor.deleteUserCourse(course.courseId);
    await publisherMemory.forget(course.courseId);
    await wizardMemory.forget(course.courseId);
  }

  Future<void> removePublisherCourse(Course course) =>
      editor.removePublisherCourseFromDevice(course);

  /// The unsaved Draft Course the New Course dialog continues to the Editor
  /// with. The dialog validates and normalizes its fields first.
  Course newCourse({
    required LearnerProfile creator,
    required String maintainerProfileId,
    required String title,
    required String sourceLanguage,
    required String targetLanguage,
    // Build 260 Revision 0: the tags of listed languages ('' for a language
    // typed by hand without one).
    String sourceLanguageTag = '',
    String targetLanguageTag = '',
    required List<NewCourseCredit> credits,
    required String license,
    required DerivativeWorksPolicy derivativeWorksPolicy,
    required List<NewCourseRightsHolder> rightsHolders,
    required String languageVariant,
    required String startLevel,
    required String targetLevel,
    required String courseDescription,
    required String buyACoffeeUrl,
    required CourseFlagSelection flag,
    required int lessonCount,
    required int roundsPerLesson,
    String? courseId,
    String coverImage = '',
    List<CourseMediaAttribution> mediaAttributions = const [],
  }) {
    final updatedAt = _clock().toUtc();
    return _draftCourse(
      creator: creator,
      maintainerProfileId: maintainerProfileId,
      title: title,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      sourceLanguageTag: sourceLanguageTag,
      targetLanguageTag: targetLanguageTag,
      credits: credits,
      license: license,
      derivativeWorksPolicy: derivativeWorksPolicy,
      rightsHolders: rightsHolders,
      languageVariant: languageVariant,
      startLevel: startLevel,
      targetLevel: targetLevel,
      courseDescription: courseDescription,
      buyACoffeeUrl: buyACoffeeUrl,
      flag: flag,
      courseId: courseId,
      coverImage: coverImage,
      mediaAttributions: mediaAttributions,
      updatedAt: updatedAt,
      lessons: NewCourseStructure.create(
        sourceLanguage: sourceLanguage,
        learningLanguage: targetLanguage,
        lessonCount: lessonCount,
        roundsPerLesson: roundsPerLesson,
        updatedAt: updatedAt,
      ),
    );
  }

  /// The Draft Course the Course Wizard saves after its first screen (Build
  /// 267): the title, languages and variant typed there, the active profile
  /// as Original Course Creator, Maintainer and Author, New Course's
  /// defaults for everything else (All rights reserved, derivative works
  /// forbidden) and no Lessons yet.
  Course newWizardCourse({
    required LearnerProfile creator,
    required String title,
    required String sourceLanguage,
    required String targetLanguage,
    String sourceLanguageTag = '',
    String targetLanguageTag = '',
    String languageVariant = '',
  }) => _draftCourse(
    creator: creator,
    maintainerProfileId: creator.learnerProfileId,
    title: title,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    sourceLanguageTag: sourceLanguageTag,
    targetLanguageTag: targetLanguageTag,
    credits: [
      (
        name: creator.presentationName,
        roles: const {'Author'},
        customRoles: '',
      ),
    ],
    license: CourseMetadataOptions.standardLicenses.first,
    derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
    rightsHolders: const [],
    languageVariant: languageVariant,
    startLevel: '',
    targetLevel: '',
    courseDescription: '',
    buyACoffeeUrl: '',
    flag: const CourseFlagSelection.automatic(),
    updatedAt: _clock().toUtc(),
    lessons: const [],
  );

  Course _draftCourse({
    required LearnerProfile creator,
    required String maintainerProfileId,
    required String title,
    required String sourceLanguage,
    required String targetLanguage,
    required String sourceLanguageTag,
    required String targetLanguageTag,
    required List<NewCourseCredit> credits,
    required String license,
    required DerivativeWorksPolicy derivativeWorksPolicy,
    required List<NewCourseRightsHolder> rightsHolders,
    required String languageVariant,
    required String startLevel,
    required String targetLevel,
    required String courseDescription,
    required String buyACoffeeUrl,
    required CourseFlagSelection flag,
    required DateTime updatedAt,
    required List<Lesson> lessons,
    String? courseId,
    String coverImage = '',
    List<CourseMediaAttribution> mediaAttributions = const [],
  }) {
    final nowUtc = updatedAt.toIso8601String();
    return Course(
      // Create new course allocates the ID first when it stores a cover
      // before the Course exists (Build 255 Revision 7).
      courseId: courseId ?? Course.newCourseId(),
      originalCourseCreator: CourseProvenanceIdentity.qqlUser(
        profileId: creator.learnerProfileId,
        displayName: creator.presentationName,
      ),
      maintainer: CourseMaintainer(maintainerProfileId),
      originalCreatedAtUtc: nowUtc,
      lastVersionEditorProfileId: creator.learnerProfileId,
      lastVersionEditorDisplayName: creator.presentationName,
      modifiedAtUtc: nowUtc,
      publicationState: PublicationState.draft,
      learningLanguage: targetLanguage,
      interfaceLanguage: sourceLanguage,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      sourceLanguageTag: sourceLanguageTag,
      targetLanguageTag: targetLanguageTag,
      title: title,
      ttsLanguage: targetLanguageTag.isNotEmpty
          ? targetLanguageTag
          : CourseLanguageResolver.codeFromMetadata([targetLanguage]) ?? 'und',
      originType: CourseOriginType.custom,
      courseVersion: '',
      authors: [
        for (final credit in credits)
          if (credit.name.trim().isNotEmpty)
            CourseAuthor(name: credit.name.trim(), roles: _rolesOf(credit)),
      ],
      license: license,
      rightsHolders: [
        for (final holder in rightsHolders)
          if (holder.name.trim().isNotEmpty)
            CourseRightsHolder(type: holder.type, name: holder.name.trim()),
      ],
      derivativeWorksPolicy: derivativeWorksPolicy,
      languageVariant: languageVariant,
      startLevel: startLevel,
      targetLevel: targetLevel,
      courseDescription: courseDescription,
      buyACoffeeUrl: buyACoffeeUrl,
      flagCode: flag.flagCode,
      flagImageBase64: flag.flagImageBase64,
      worldFlagId: flag.selectedWorldFlagId,
      coverImage: coverImage,
      mediaAttributions: mediaAttributions,
      temporarySample: false,
      // Build 267 Revision 6 (owner, 9 October 2026): a Duel adds a
      // complication, so a new Course starts without; Lesson Options turns
      // it on.
      createDuels: false,
      // Build 267 Revision 7 (owner, 9 October 2026): a thin grey line
      // around picture answers, for new Courses only.
      pictureAnswers: PictureAnswerStyle.newCourse,
      lessons: lessons,
    );
  }

  /// Standard roles in their standard order, then custom roles as typed;
  /// `Contributor` when none is given.
  static List<String> _rolesOf(NewCourseCredit credit) {
    final roles = <String>[
      ...CourseMetadataOptions.standardRoles.where(credit.roles.contains),
    ];
    for (final part in credit.customRoles.split(',')) {
      final role = part.trim();
      if (role.isNotEmpty && !roles.contains(role)) roles.add(role);
    }
    if (roles.isEmpty) roles.add('Contributor');
    return roles;
  }
}

/// The result messages Course Manager shows. Nothing here is stored.
abstract final class CourseLibraryReports {
  static String confirmed(CourseConfirmationResult result) {
    final version = 'New course version: ${result.course.courseVersion}';
    final backup = result.backupPath == null
        ? '\nNo previous version existed, so no backup was required.'
        : '\nBackup: ${result.backupPath}';
    return 'Course changes confirmed.\n$version$backup';
  }

  static String imported(
    Course course,
    int warnings, {
    int notExecutable = 0,
  }) =>
      (warnings == 0
          ? 'Imported “${course.title}”.'
          : 'Imported “${course.title}” with $warnings Course Audit warning${warnings == 1 ? '' : 's'}. Review Course Audit.') +
      notExecutableNote(notExecutable);

  /// One line counting the exercises this version cannot play (Build 256
  /// Revision 6, plan A.6), empty when there are none.
  /// Why someone else's Private course is refused (Build 259 Revision 8).
  static String privateCourseRefused(Course course) =>
      '“${course.title}” is a Private course: only its Course Maintainer and the members of its assigned Team can import it or use it in a Merge. Ask its Maintainer for a copy that is not private.';

  static String notExecutableNote(int count) => count == 0
      ? ''
      : ' $count exercise${count == 1 ? '' : 's'} cannot be played by this version of QuisquisLingo and ${count == 1 ? 'is' : 'are'} kept unchanged.';

  static String publisherInstalled(
    Course course,
    OfficialCourseUpdateResult result,
  ) {
    final verification =
        result.officialCourse.publisherVerificationStatus ==
            PublisherVerificationStatus.verified
        ? 'verified publisher signature'
        : 'UNVERIFIED publisher metadata';
    return 'Installed Publisher Course version ${course.officialCourseVersion} from ${course.publisherName} ($verification).'
        '${result.backupPath == null ? '' : '\nBacked up previous official source: ${result.backupPath}'}';
  }

  static String exported(Course course, String path, String? notice) =>
      'Exported “${course.title}” to $path${notice == null ? '' : ' $notice'}';

  static String savedTo(Course course, String? displayName, String? notice) =>
      'Saved “${course.title}” as $displayName.${notice == null ? '' : ' $notice'}';

  /// Export as Publisher Course (Build 262 Revision 2).
  static String publisherExported(
    Course course,
    PublisherIdentity publisher,
    String where,
  ) =>
      'Exported “${course.title}” as a Publisher Course of '
      '${publisher.publisherName} (official version ${course.courseVersion}) '
      'to $where. It is not signed yet: sign it before distributing it.';

  static String importBlocked(int errors) =>
      'Course Audit found $errors error${errors == 1 ? '' : 's'}. Fix these errors before importing the course.';

  /// A failed Delete, with the storage error's own message.
  static String deleteFailed(Course course, Object error) {
    final reason = switch (error) {
      StateError(:final message) => message,
      FormatException(:final message) => message,
      _ => '$error',
    };
    return 'Could not delete “${course.title}”: $reason';
  }
}

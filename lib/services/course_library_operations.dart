import '../models/course_flag_selection.dart';
import '../models/course_metadata_options.dart';
import '../models/course_models.dart';
import 'course_access_policy.dart';
import 'course_audit_service.dart';
import 'course_editor_service.dart';
import 'course_file_store.dart';
import 'course_flag_service.dart';
import 'course_language_resolver.dart';
import 'course_library_service.dart';
import 'course_merge_service.dart';
import 'course_package_import.dart';
import 'course_service.dart';
import 'custom_course_transfer_service.dart';
import 'file_dialog_service.dart';
import 'formal_name_policy.dart';
import 'new_course_structure.dart';
import 'profile_service.dart';
import 'settings_service.dart';
import 'team_service.dart';

/// The Course Manager menu entries, in menu order.
enum CourseManagerAction {
  removeFromMyCourses,
  removePublisherFromDevice,
  open,
  fork,
  copyAsNewCourse,
  merge,
  audit,
  export,
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
    this.memberTeamIds = const {},
    this.isAdmin = false,
    this.importAuthoringEnabled = false,
  });

  /// The stored Custom and Publisher Courses in the active personal library.
  final List<Course> personalCourses;

  /// The Bundled Courses in the active personal library.
  final List<Course> bundledCourses;

  /// Stored Course files that could not be read; kept untouched on disk.
  final List<SkippedCourseFile> unreadable;
  final String? activeProfileId;
  final Set<String> memberTeamIds;
  final bool isAdmin;

  /// Copy as New Course and Fork are offered on a matching-ID import.
  final bool importAuthoringEnabled;

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
      const CourseManagerEntry(CourseManagerAction.removeFromMyCourses),
      if (course.originType == CourseOriginType.externalOfficial)
        CourseManagerEntry(
          CourseManagerAction.removePublisherFromDevice,
          isAdmin
              ? null
              : 'Only an admin can remove a Publisher Course from this device.',
        ),
      const CourseManagerEntry(CourseManagerAction.open),
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
      if (!official)
        CourseManagerEntry(
          CourseManagerAction.delete,
          access.canDelete ? null : '$onlyInside delete this Course.',
        ),
    ];
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
  });

  final Course course;
  final List<CourseAuditIssue> errors;
  final List<CourseAuditIssue> warnings;

  /// The stored Course already using this Course ID, if any.
  final Course? existing;

  /// Offered for a matching custom Course ID; Cancel is always offered.
  final List<CourseImportChoice> choices;

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
    SettingsService? settings,
    ProfileService? profiles,
    TeamService? teams,
    CourseFlagService? flags,
    DateTime Function()? clock,
  }) : editor = editor ?? CourseEditorService(),
       transfer = transfer ?? CustomCourseTransferService(),
       _merge = merge ?? CourseMergeService(),
       _courses = courses ?? CourseService(),
       _settings = settings ?? SettingsService(),
       profiles = profiles ?? ProfileService(),
       _flags = flags ?? CourseFlagService(),
       _clock = clock ?? DateTime.now {
    this.teams = teams ?? TeamService(profileService: this.profiles);
    _membership =
        library ?? CourseLibraryService(profileService: this.profiles);
  }

  final CourseEditorService editor;
  final CustomCourseTransferService transfer;
  final ProfileService profiles;
  late final TeamService teams;
  final CourseMergeService _merge;
  final CourseService _courses;
  late final CourseLibraryService _membership;
  final SettingsService _settings;
  final CourseFlagService _flags;
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
        for (final code in CourseService.courseAssets.keys)
          await _courses.loadCourse(code),
    ];
    final currentIsBundled =
        currentCourse?.originType == CourseOriginType.bundledOfficial;
    final includedBundled = await _membership.included([
      if (currentIsBundled) currentCourse!,
      ...bundled.where(
        (c) => c.courseId != currentCourse?.courseId || !currentIsBundled,
      ),
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
    return CourseManagerLibrary(
      personalCourses: personal,
      bundledCourses: includedBundled,
      unreadable: editor.unreadableCourseFiles,
      activeProfileId: activeProfileId,
      memberTeamIds: memberTeamIds,
      isAdmin: isAdmin,
      importAuthoringEnabled: importAuthoringEnabled,
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
              CourseService.codeForCourse(course),
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
    final installed = await editor.listUserCourses();
    final audit = CourseAuditService().auditCourse(course);
    final existing = installed
        .where((candidate) => candidate.courseId == course.courseId)
        .firstOrNull;
    final imported = library.capabilitiesFor(course);
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
      existing: existing,
      choices: [
        if (existing != null &&
            course.originType != CourseOriginType.externalOfficial) ...[
          if (library.importAuthoringEnabled && imported.canCopyAsNewCourse)
            CourseImportChoice.copyAsNewCourse,
          if (library.importAuthoringEnabled && imported.canFork)
            CourseImportChoice.fork,
          if (!existing.originType.isOfficial &&
              library.capabilitiesFor(existing).canEditOriginal)
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

  Future<void> deleteCourse(Course course) =>
      editor.deleteUserCourse(course.courseId);

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
  }) {
    final updatedAt = _clock().toUtc();
    final nowUtc = updatedAt.toIso8601String();
    return Course(
      courseId: Course.newCourseId(),
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
      title: title,
      ttsLanguage:
          CourseLanguageResolver.codeFromMetadata([targetLanguage]) ?? 'und',
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
      temporarySample: false,
      lessons: NewCourseStructure.create(
        sourceLanguage: sourceLanguage,
        learningLanguage: targetLanguage,
        lessonCount: lessonCount,
        roundsPerLesson: roundsPerLesson,
        updatedAt: updatedAt,
      ),
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

  static String imported(Course course, int warnings) => warnings == 0
      ? 'Imported “${course.title}”.'
      : 'Imported “${course.title}” with $warnings Course Audit warning${warnings == 1 ? '' : 's'}. Review Course Audit.';

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

  static String importBlocked(int errors) =>
      'Course Audit found $errors error${errors == 1 ? '' : 's'}. Fix these errors before importing the course.';
}

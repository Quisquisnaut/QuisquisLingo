import '../services/course_library_service.dart';
import '../services/course_favorite_service.dart';
import '../services/course_learner_visibility_service.dart';
import 'available_courses_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui show Gradient;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../controllers/learner_status_controller.dart';
import '../services/settings_service.dart';
import '../services/update_notice_service.dart';
import '../services/update_service.dart';
import '../models/course_models.dart';
import '../services/course_language_resolver.dart';
import '../services/course_service.dart';
import '../services/course_study.dart';
import '../services/course_editor_service.dart';
import '../services/publication_service.dart';
import '../services/lesson_color_palette.dart';
import '../services/lesson_presentation_service.dart';
import '../services/round_type_presentation.dart';
import '../services/duel_eligibility_service.dart';
import '../services/audio_exercise_availability_service.dart';
import '../services/progress_service.dart';
import '../services/profile_service.dart';
import '../services/lesson_unlock_service.dart';
import '../services/lesson_expansion_policy.dart';
import '../services/learner_status_events.dart';
import '../services/beta_lifecycle_service.dart';
import '../services/app_metadata.dart';
import '../services/app_errors.dart';
import '../services/error_presenter.dart';
import '../services/diagnostic_log_service.dart';
import '../services/crash_log_service.dart';
import '../services/learner_mascots.dart';
import 'settings_screen.dart';
import 'review_screen.dart';
import 'course_info_screen.dart';
import 'course_projects_screen.dart';
import 'courses_screen.dart';
import 'duel_screen.dart';
import 'guidebook_screen.dart';
import 'info_screen.dart';
import 'new_learner_flow_screen.dart';
import 'profile_screen.dart';
import 'round_screen.dart';
import '../widgets/flag_art.dart';
import '../widgets/learner_data_notices.dart';
import '../widgets/shared_device_notice.dart';
import '../widgets/course_artwork.dart';
import '../widgets/course_entry_animation.dart';
import '../widgets/flag_inspired_background.dart';
import '../widgets/lesson_fallback_icon.dart';
import '../widgets/learner_avatar.dart';
import '../widgets/learner_bottom_actions.dart';
import '../widgets/learner_shell.dart';
import '../widgets/unified_learner_top_bar.dart';
import '../widgets/learner_theme_mode_scope.dart';
import '../widgets/welcome_wizard_dialog.dart';
import '../localization/locale_service.dart';
import '../widgets/reported_action.dart';
import '../services/update_reminder.dart';

part 'course_preview_screen.dart';

const _learnerLightPageBackground = Color(0xFFF7F3E8);
const _learnerDarkPageBackground = Color(0xFF080B09);
const _welcomeDialogBackground = Color(0xFFFFE600);
const _welcomeDialogForeground = Color(0xFF0756DF);
const learnerGuidebookWidthFactor = .78;

/// The Lesson and Round rows keep a faint background, 20% opaque and without
/// a border, that partly covers the path line passing under them (Build 261
/// Revision 8, owner decision).
const learnerPathSurfaceOpacity = .20;

/// The Lesson row's padding and number circle (or theme picture) slot.
const learnerLessonRowPadding = 12.0;
const learnerLessonIconSize = 84.0;

/// The Round row's padding, icon slot and icon circle: the path line runs
/// through the circle's centre (Build 261 Revision 8).
const learnerRoundRowPadding = 10.0;
const learnerRoundIconSlotWidth = 60.0;
const learnerRoundIconSize = 52.0;
const learnerRoundIconCenterX =
    learnerRoundRowPadding + learnerRoundIconSlotWidth / 2;

/// The band above the first Round where the line turns from the Lesson
/// circle to the first Round circle, and below the last Round where it turns
/// to the Duel.
const learnerRoundPathLead = 24.0;

/// On a wide window the Round path keeps at most this width, centred.
const learnerRoundPathMaxWidth = 560.0;

/// Where the Lesson number circle's centre sits across a Lesson of [width]:
/// the Lesson row is centred, [learnerGuidebookWidthFactor] of at most 400.
double learnerLessonCircleCenterX(double width) {
  final rowWidth = min(width, 400.0) * learnerGuidebookWidthFactor;
  return (width - rowWidth) / 2 +
      learnerLessonRowPadding +
      learnerLessonIconSize / 2;
}

/// The path's texts and line, drawn without cards since Build 261 Revision 8,
/// get a soft halo in the page colour when a flag picture is behind them
/// (Flag Background Small or Extended).
class LearnerPathHalo extends InheritedWidget {
  const LearnerPathHalo({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LearnerPathHalo>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(LearnerPathHalo oldWidget) =>
      oldWidget.enabled != enabled;
}

Color _learnerPageBackgroundOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? _learnerDarkPageBackground
    : _learnerLightPageBackground;

/// Text shadows forming the halo, or null when no flag picture is behind.
List<Shadow>? learnerPathTextHalo(BuildContext context) {
  if (!LearnerPathHalo.of(context)) return null;
  final color = _learnerPageBackgroundOf(context);
  // Stacked shadows: a close, dense glow that keeps even the small grey and
  // blue lines readable on a saturated flag.
  return [
    for (final blur in const [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 6.0])
      Shadow(color: color, blurRadius: blur),
  ];
}

/// The path's small grey label line ("Lesson 2", "Round 1 · Practice").
TextStyle learnerPathLabelStyle(BuildContext context) => TextStyle(
  fontSize: 12,
  height: 1.3,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
  shadows: learnerPathTextHalo(context),
);
const learnerRoundCardMaxWidth = 244.0;
const learnerMascotSurfaceOpacity = .10;
const learnerPathConnectorOpacity = .55;
const learnerPathConnectorStrokeWidth = 2.0;
const learnerPathConnectorSupportOpacity = .32;
const learnerPathConnectorSupportStrokeWidth = 4.0;
const learnerDarkFlagVeilOpacity = .25;
const learnerLightFlagVeilOpacity = .10;
const _learnerScrollBottomInset = learnerBottomActionsHeight + 44;
const _lockedLessonPreviewTapCount = 3;
const _lockedLessonPreviewTapTimeout = Duration(seconds: 5);

typedef _LockedLessonPreviewKey = ({String courseId, String lessonId});

final Set<_LockedLessonPreviewKey> _sessionPreviewedLockedLessons = {};

@visibleForTesting
void resetLockedLessonPreviewSessionForTesting() =>
    _sessionPreviewedLockedLessons.clear();

@immutable
class LearnerSectionBlock {
  final String label;
  final int firstLessonIndex;
  final int lastLessonIndex;
  final bool synthetic;

  const LearnerSectionBlock({
    required this.label,
    required this.firstLessonIndex,
    required this.lastLessonIndex,
    required this.synthetic,
  });

  bool containsLesson(int index) =>
      index >= firstLessonIndex && index <= lastLessonIndex;
}

/// Consecutive Section metadata forms navigation blocks. Unsectioned runs are
/// represented only in the learner UI and never written back to the Course.
@visibleForTesting
List<LearnerSectionBlock> learnerSectionBlocks(List<Lesson> lessons) {
  if (!lessons.any((lesson) => lesson.section)) return const [];
  final blocks = <LearnerSectionBlock>[];
  for (var index = 0; index < lessons.length; index++) {
    final lesson = lessons[index];
    final synthetic = !lesson.section;
    final label = synthetic ? 'Other lessons' : lesson.sectionName!;
    if (blocks.isNotEmpty &&
        blocks.last.synthetic == synthetic &&
        blocks.last.label == label) {
      final previous = blocks.removeLast();
      blocks.add(
        LearnerSectionBlock(
          label: label,
          firstLessonIndex: previous.firstLessonIndex,
          lastLessonIndex: index,
          synthetic: synthetic,
        ),
      );
    } else {
      blocks.add(
        LearnerSectionBlock(
          label: label,
          firstLessonIndex: index,
          lastLessonIndex: index,
          synthetic: synthetic,
        ),
      );
    }
  }
  return List.unmodifiable(blocks);
}

ThemeData _unifiedLearnerTheme(BuildContext context) {
  if (!_usesDarkLearnerAppearance(context)) {
    return Theme.of(context);
  }
  return ThemeData.dark(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: _learnerDarkPageBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF54D8FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF151A17),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF151A17),
      surfaceTintColor: Colors.transparent,
    ),
  );
}

bool _usesDarkLearnerAppearance(BuildContext context) {
  final mode = LearnerThemeModeScope.maybeModeOf(context);
  return switch (mode) {
    LearnerThemeMode.light => false,
    LearnerThemeMode.dark => true,
    LearnerThemeMode.defaultMode ||
    null => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    LearnerThemeMode.dayNight =>
      Theme.of(context).brightness == Brightness.dark,
  };
}

/// Compact, scroll-safe Home dashboard.
///
/// The Home deliberately avoids fixed-height content blocks. It must remain
/// usable on small phone windows, desktop portrait previews and larger text
/// settings without producing RenderFlex overflows.
class HomeScreen extends StatefulWidget {
  @visibleForTesting
  final ProfileService? profileService;

  const HomeScreen({super.key, this.profileService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _courseService = CourseService();
  final _courseEditorService = CourseEditorService();
  final _publication = const PublicationService();
  final _duelEligibility = const DuelEligibilityService();
  final _audioAvailability = AudioExerciseAvailabilityService();
  final _progress = ProgressService();
  late final ProfileService _profiles;
  final _settings = SettingsService();
  final _lessonUnlocks = const LessonUnlockService();
  final _learnerScrollController = ScrollController();
  LearnerStatusController? _standaloneStatusController;
  final Map<String, GlobalKey> _lessonSectionKeys = {};
  String _appVersion = '';
  static const _welcomePhrases = <String>[
    'Every language starts with a first word.',
    'Your language tree has some growing to do.',
    'New words. New branches.',
    'A little practice. A few more leaves.',
    'Your language tree missed you.',
    'Time to grow another branch.',
    'Somewhere, a verb is waiting to be conjugated.',
    "Your vocabulary isn't going to grow itself.",
    'New words have a habit of taking root.',
    "One more word won't hurt. Probably.",
    'The forest is full of irregular verbs.',
    'Another day, another suspiciously irregular verb.',
    'Just languages. That is our thing.',
    'The trees have been discussing your pronunciation.',
    'A wild adjective appeared.',
    'Mind the false friends. They know what they did.',
    'Some words just need a little watering.',
    'Your next word is hiding somewhere in these branches.',
    "Ready? The words certainly aren't.",
  ];
  String? _activeLearner;
  String? _activeLearnerId;
  bool _addingLearner = false;
  bool _learnerFlowOpen = false;
  List<LearnerProfile> _learners = [];
  Set<String> _adminProfileIds = const {};
  String _deviceDisplayName = 'This device';
  Course? _course;
  bool _libraryEmpty = false;
  bool _emptyLibraryEditorUnlocked = false;
  Set<String> _completedRounds = {};
  Set<String> _completedLessons = {};
  Set<String> _perfectRounds = {};
  Set<String> _ttsSkippedPerfectRounds = {};
  Set<String> _wonDuels = {};
  Map<String, DuelEligibilityResult> _duelEligibilityByLessonId = const {};
  Map<String, EffectiveRoundAudioAvailability> _roundAudioAvailability =
      const {};
  LearnerIddqdMode _iddqdMode = LearnerIddqdMode.off;
  LearnerLessonExpansionMode _lessonExpansionMode =
      LearnerLessonExpansionMode.expanded;
  LearnerFlagBackgroundMode _flagBackgroundMode = LearnerFlagBackgroundMode.off;
  String _selectedLanguage = 'IT';
  String _selectedCourseRef = 'IT';
  List<String> _bundledCourseCodes = List<String>.unmodifiable(
    CourseService.bundledAssets.keys,
  );
  int _activeLessonIndex = 0;
  String? _flowCourseId;
  String? _flowLearner;
  int? _lessonScrollTargetIndex;
  int _lessonScrollTargetAttempts = 0;
  bool _lessonVisibilityCheckScheduled = false;
  String? _lockedLessonTapLessonId;
  int _lockedLessonTapCount = 0;
  Timer? _lockedLessonTapResetTimer;
  StreamSubscription<LearnerStatusInvalidation>? _appearanceSubscription;
  int _flagBackgroundLoadGeneration = 0;
  int _reloadGeneration = 0;
  ({int generation, CourseEntryFlagSource flag})? _courseEntryTransition;
  int _courseEntryTransitionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _appearanceSubscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.flagBackground) {
        _reloadFlagBackgroundMode();
      }
    });
    UpdateNoticeService.changes.addListener(_scheduleUpdateNotice);
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareWelcome());
  }

  bool _updateNoticeBusy = false;

  void _scheduleUpdateNotice() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_maybeShowUpdateNotice()),
    );
  }

  /// Tells the active learner about a newer release, at most once a day.
  Future<void> _maybeShowUpdateNotice() async {
    if (_updateNoticeBusy || !mounted || _activeLearnerId == null) return;
    if (UpdateNoticeService.pending == null) return;
    // Another page or dialog is on top: wait. The Home start-up dialogs ask
    // again when they finish (see _prepareWelcome).
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _updateNoticeBusy = true;
    try {
      final notices = UpdateNoticeService(profiles: _profiles);
      final release = await notices.dueForActiveLearner();
      if (release == null || !mounted) return;
      // Record first so a crash or an outside tap never repeats it today.
      await notices.markShown(release);
      if (!mounted) return;
      await UpdateNoticeService.show(context, release, UpdateService());
    } catch (_) {
      // The notice is optional and must never disturb the Home screen.
    } finally {
      _updateNoticeBusy = false;
    }
  }

  @override
  void dispose() {
    UpdateNoticeService.changes.removeListener(_scheduleUpdateNotice);
    _resetLockedLessonTapSequence();
    _appearanceSubscription?.cancel();
    _learnerScrollController.dispose();
    _standaloneStatusController?.dispose();
    super.dispose();
  }

  LearnerStatusController _topBarController(BuildContext context) =>
      LearnerShell.maybeOf(context)?.controller ??
      (_standaloneStatusController ??= LearnerStatusController());

  Future<void> _prepareWelcome() async {
    _appVersion = AppMetadata.technicalVersion;
    // Build 255 Revision 7: without an active learner (a first run, or Ask
    // who is learning) the learner comes first; the start-up notices follow
    // once one is created or chosen.
    if (await _profiles.getActiveProfileId() == null || !mounted) return;
    await _showStartupNotices();
  }

  bool _startupNoticesShown = false;

  /// A new learner's Welcome Wizard; then, once per session, this version's
  /// Welcome, the Beta notice and the update notice.
  Future<void> _showStartupNotices() async {
    // A damaged learner-data file is told first (Build 270 Revision 0).
    await LearnerDataNotices.showPendingRecovery();
    if (!mounted) return;
    await _showWelcomeWizard();
    if (!mounted) return;
    // What the Access PIN can do on a shared device (Build 270 Revision 8);
    // never on a learner's first access, which shows only the Welcome Wizard
    // (Revision 10 follow-up).
    await SharedDeviceNotice.showIfNeeded(context, profiles: _profiles);
    if (!mounted || _startupNoticesShown) return;
    _startupNoticesShown = true;
    await _showWelcome();
    if (mounted) await _showBetaLifecycleNotice();
    // The start-up dialogs come first; the update notice follows them.
    if (mounted) _scheduleUpdateNotice();
    if (mounted) await _maybeShowUpdateReminder();
  }

  /// Android (Build 270 Revision 10): every two weeks, check for a newer
  /// QuisquisLingo, since QQL does not go online there.
  Future<void> _maybeShowUpdateReminder() async {
    try {
      final reminder = UpdateReminder(profiles: _profiles);
      if (!await reminder.dueForActiveLearner() || !mounted) return;
      // Recorded first so an outside tap never repeats it at once.
      await reminder.markShown();
      if (!mounted) return;
      await UpdateReminder.show(context);
    } catch (_) {
      // The reminder is optional and must never disturb the Home screen.
    }
  }

  Future<void> _showWelcomeWizard() async {
    if (await _profiles.getActiveProfileId() == null || !mounted) return;
    if (await _settings.hasCompletedWelcomeWizard() || !mounted) return;
    final learnerId = await _profiles.getActiveProfileId();
    if (learnerId != null) SharedDeviceNotice.deferForFirstAccess(learnerId);
    if (!mounted) return;
    // In the language chosen in Create Profile (Build 255 Revision 7).
    final locale = await LocaleService().read();
    // The Wizard stands in for this version's Welcome: a new learner never
    // gets both.
    await _settings.markOneTimeNoticeSeen(
      'welcome_${AppMetadata.technicalVersion}',
    );
    if (!mounted) return;
    final completed = await showWelcomeWizard(context, locale: locale);
    if (completed == true) await _settings.completeWelcomeWizard();
  }

  Future<void> _reloadFlagBackgroundMode() async {
    final generation = ++_flagBackgroundLoadGeneration;
    final courseId = _course?.courseId;
    final learnerId = _activeLearnerId;
    var mode = LearnerFlagBackgroundMode.off;
    if (courseId != null && learnerId != null) {
      try {
        mode = await _profiles.getFlagBackgroundModeForProfile(
          learnerId,
          courseId,
        );
      } catch (_) {
        // Appearance loading keeps the learner page available on bad storage.
      }
    }
    if (!mounted ||
        generation != _flagBackgroundLoadGeneration ||
        _course?.courseId != courseId ||
        _activeLearnerId != learnerId ||
        _flagBackgroundMode == mode) {
      return;
    }
    setState(() => _flagBackgroundMode = mode);
  }

  Future<void> _showWelcome() async {
    final id = 'welcome_$_appVersion';
    if (await _settings.hasSeenOneTimeNotice(id) || !mounted) return;
    final phrase = _welcomePhrases[Random().nextInt(_welcomePhrases.length)];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: _unifiedLearnerTheme(context),
        child: AlertDialog(
          backgroundColor: _welcomeDialogBackground,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Welcome to QuisquisLingo',
            style: TextStyle(color: _welcomeDialogForeground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version ${AppMetadata.releaseVersion}',
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                  color: _welcomeDialogForeground,
                ),
              ),
              Text(
                AppMetadata.publicBuildLabel,
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                  color: _welcomeDialogForeground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                phrase,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: _welcomeDialogForeground,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    await _settings.markOneTimeNoticeSeen(id);
  }

  Future<void> _showBetaLifecycleNotice() async {
    if (!BetaLifecycleService.isBetaBuild || !mounted) return;
    if (BetaLifecycleService.isExpired()) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Theme(
          data: _unifiedLearnerTheme(context),
          child: AlertDialog(
            title: const Text('Beta expired'),
            content: Text(
              'This QuisquisLingo beta expired on ${BetaLifecycleService.expiryIsoDate}. Install a newer beta to continue learning. Your local data has not been deleted, and Course Editor remains available.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
      return;
    }
    // Build 255 Revision 7: only in the last seven days before expiry.
    if (BetaLifecycleService.warningStage() == null) return;
    final days = BetaLifecycleService.daysRemaining();
    final message = days == 0
        ? 'This beta expires today.'
        : days == 1
        ? 'This beta expires tomorrow.'
        : 'This beta expires in $days days.';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: _unifiedLearnerTheme(context),
        child: AlertDialog(
          title: const Text('Beta expiry'),
          content: Text(
            '$message Expiry date: ${BetaLifecycleService.expiryIsoDate}. Install a newer QuisquisLingo beta before then to continue learning. Updating does not intentionally delete learner data or course-authoring data.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExpiredLearnerNotice() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Theme(
        data: _unifiedLearnerTheme(context),
        child: AlertDialog(
          title: const Text('Beta expired'),
          content: Text(
            'This beta expired on ${BetaLifecycleService.expiryIsoDate}. Install a newer beta to continue learning. Your local data is kept and Course Editor remains available.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload({
    String? requestedCourseRef,
    ({String courseId, int generation, CourseEntryFlagSource flag})?
    pendingCourseEntryTransition,
    bool replaceCourseEntryTransition = false,
    int? requestedGeneration,
  }) async {
    final reloadGeneration = requestedGeneration ?? ++_reloadGeneration;
    if (reloadGeneration != _reloadGeneration) return;
    _resetLockedLessonTapSequence();
    try {
      final bundledCourseCodes = await _courseService
          .reconcileAvailableBundledCourseCodes();
      final learners = await _profiles.getProfileRecords();
      final adminProfileIds = await _profiles.getAdminProfileIds();
      final deviceDisplayName = await _profiles.getDeviceDisplayName();
      final activeProfile = await _profiles.getActiveProfileRecord();
      final active = activeProfile?.displayName;
      final activeId = activeProfile?.learnerProfileId;
      var selectedRef =
          requestedCourseRef ??
          (active == null
              ? _selectedCourseRef
              : (await _settings.getLastSelectedCourseCode() ?? 'IT'));
      final personalCourses = await CourseLibraryService().included([
        for (final code in bundledCourseCodes)
          await _courseService.loadCourse(code),
        ...await _courseEditorService.listUserCourses(),
      ]);
      final playable = personalCourses
          .where((c) => _publication.learnerCourse(c) != null)
          .toList();
      String reference(Course c) =>
          c.originType == CourseOriginType.bundledOfficial
          ? CourseService.bundledCodeForCourse(c)
          : 'custom:${c.courseId}';
      if (playable.isEmpty) {
        final editorUnlocked = await _settings.isCourseEditorUnlocked();
        if (mounted && reloadGeneration == _reloadGeneration) {
          setState(() {
            _libraryEmpty = true;
            _emptyLibraryEditorUnlocked = editorUnlocked;
            _course = null;
            _learners = learners;
            _activeLearner = active;
            _activeLearnerId = activeId;
            _adminProfileIds = adminProfileIds;
            _deviceDisplayName = deviceDisplayName;
          });
        }
        return;
      }
      _libraryEmpty = false;
      if (!playable.any((c) => reference(c) == selectedRef)) {
        selectedRef = reference(playable.first);
        if (activeId != null) {
          await _settings.setLastSelectedCourseCode(selectedRef);
        }
      }
      final selectedCourse = playable.firstWhere(
        (c) => reference(c) == selectedRef,
      );
      final course = _publication.learnerCourse(selectedCourse)!;
      final selectedLanguage = CourseService.codeForCourse(course);
      final savedLessonId = activeId == null
          ? null
          : await _settings.getLastVisitedLessonId(course.courseId);
      var activeLessonIndex = course.lessons.indexWhere(
        (lesson) => lesson.lessonId == savedLessonId,
      );
      if (activeLessonIndex < 0) activeLessonIndex = 0;
      final rounds = activeId == null
          ? <String>{}
          : await _progress.getCompletedRounds(courseId: course.courseId);
      final lessons = activeId == null
          ? <String>{}
          : await _progress.getCompletedLessons(courseId: course.courseId);
      final perfect = activeId == null
          ? <String>{}
          : await _progress.getPerfectRounds(courseId: course.courseId);
      final skipped = activeId == null
          ? <String>{}
          : await _progress.getTtsSkippedPerfectRounds(
              courseId: course.courseId,
            );
      final wonDuels = activeId == null
          ? <String>{}
          : await _progress.getWonDuels(courseId: course.courseId);
      final audioExercisesEnabled = await _settings.areAudioExercisesEnabled();
      final ttsEnabled =
          audioExercisesEnabled && await _settings.isTtsEnabled();
      final duelEligibilityByLessonId = await _effectiveDuelEligibilityFor(
        course,
        audioExercisesEnabled: audioExercisesEnabled,
        ttsEnabled: ttsEnabled,
      );
      final roundAudioAvailability = await _effectiveRoundAudioAvailabilityFor(
        course,
        audioExercisesEnabled: audioExercisesEnabled,
        ttsEnabled: ttsEnabled,
      );
      final iddqdMode = activeId == null
          ? LearnerIddqdMode.off
          : await _settings.getIddqdMode(course.courseId);
      final lessonExpansionMode = activeId == null
          ? LearnerLessonExpansionMode.expanded
          : await _settings.getLessonExpansionMode(course.courseId);
      var flagBackgroundMode = LearnerFlagBackgroundMode.off;
      if (activeId != null) {
        try {
          flagBackgroundMode = await _profiles.getFlagBackgroundModeForProfile(
            activeId,
            course.courseId,
          );
        } catch (_) {
          // Appearance loading keeps the learner page available on bad storage.
        }
      }
      if (course.lessons.isNotEmpty &&
          !_lessonUnlocks.isLessonUnlocked(
            lessonIndex: activeLessonIndex,
            course: course,
            completedLessons: lessons,
            wonDuels: wonDuels,
          ) &&
          !iddqdMode.bypassesLocks) {
        activeLessonIndex = 0;
      }
      if (!mounted || reloadGeneration != _reloadGeneration) return;
      final resetFlow =
          _flowCourseId != course.courseId || _flowLearner != activeId;
      final pendingTransition = pendingCourseEntryTransition;
      final committedCourseEntryTransition =
          pendingTransition != null &&
              pendingTransition.courseId == course.courseId
          ? (
              generation: pendingTransition.generation,
              flag: pendingTransition.flag,
            )
          : null;
      setState(() {
        _course = course;
        _selectedCourseRef = selectedRef;
        _selectedLanguage = selectedLanguage;
        _bundledCourseCodes = bundledCourseCodes;
        _learners = learners;
        _adminProfileIds = adminProfileIds;
        _deviceDisplayName = deviceDisplayName;
        _activeLearner = active;
        _activeLearnerId = activeId;
        _completedRounds = rounds;
        _completedLessons = lessons;
        _perfectRounds = perfect;
        _ttsSkippedPerfectRounds = skipped;
        _wonDuels = wonDuels;
        _duelEligibilityByLessonId = duelEligibilityByLessonId;
        _roundAudioAvailability = roundAudioAvailability;
        _iddqdMode = iddqdMode;
        _lessonExpansionMode = lessonExpansionMode;
        _flagBackgroundMode = flagBackgroundMode;
        if (replaceCourseEntryTransition) {
          _courseEntryTransition = committedCourseEntryTransition;
        }
        _activeLessonIndex = activeLessonIndex;
        if (resetFlow) {
          _flowCourseId = course.courseId;
          _flowLearner = activeId;
        }
      });
      if (resetFlow && reloadGeneration == _reloadGeneration) {
        _scrollToLesson(course, activeLessonIndex);
      }
      if (activeId != null) _scheduleUpdateNotice();
    } on AppException catch (e) {
      if (mounted && reloadGeneration == _reloadGeneration) {
        await ErrorPresenter.show(context, e.error);
      }
    } catch (e, st) {
      if (!mounted || reloadGeneration != _reloadGeneration) return;
      await DiagnosticLogService().log(
        AppErrorCode.unexpectedError,
        context: 'HomeScreen._reload',
        exception: e,
        stackTrace: st,
      );
      if (mounted && reloadGeneration == _reloadGeneration) {
        await ErrorPresenter.show(context, AppErrorCode.unexpectedError);
      }
    }
  }

  Future<void> _switchCourse(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!CourseService.hasCourse(normalized)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('Course coming soon.'),
          ),
        );
      }
      return;
    }
    final reloadGeneration = ++_reloadGeneration;
    try {
      final course = _publication.learnerCourse(
        await _courseService.loadCourse(normalized),
      );
      if (course == null || !mounted || reloadGeneration != _reloadGeneration) {
        return;
      }
      final entryFlag = await _courseEntryFlagForSwitch(course);
      if (!mounted || reloadGeneration != _reloadGeneration) return;
      final transition = entryFlag == null
          ? null
          : (
              courseId: course.courseId,
              generation: ++_courseEntryTransitionGeneration,
              flag: entryFlag,
            );
      await _settings.setLastSelectedCourseCode(normalized);
      if (!mounted || reloadGeneration != _reloadGeneration) return;
      await _reload(
        requestedCourseRef: normalized,
        pendingCourseEntryTransition: transition,
        replaceCourseEntryTransition: true,
        requestedGeneration: reloadGeneration,
      );
    } on AppException catch (e) {
      if (mounted && reloadGeneration == _reloadGeneration) {
        await ErrorPresenter.show(context, e.error);
      }
    }
  }

  Future<void> _switchCustomCourse(Course course) async {
    final learnerCourse = _publication.learnerCourse(course);
    if (learnerCourse == null || !mounted) return;
    final reloadGeneration = ++_reloadGeneration;
    final ref = 'custom:${course.courseId}';
    final entryFlag = await _courseEntryFlagForSwitch(learnerCourse);
    if (!mounted || reloadGeneration != _reloadGeneration) return;
    final transition = entryFlag == null
        ? null
        : (
            courseId: learnerCourse.courseId,
            generation: ++_courseEntryTransitionGeneration,
            flag: entryFlag,
          );
    await _settings.setLastSelectedCourseCode(ref);
    if (!mounted || reloadGeneration != _reloadGeneration) return;
    await _reload(
      requestedCourseRef: ref,
      pendingCourseEntryTransition: transition,
      replaceCourseEntryTransition: true,
      requestedGeneration: reloadGeneration,
    );
  }

  Future<CourseEntryFlagSource?> _courseEntryFlagForSwitch(
    Course destination,
  ) async {
    final currentCourseId = _course?.courseId;
    try {
      final animationsEnabled = await _settings.areAnimationsEnabled();
      if (!mounted) return null;
      return await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: currentCourseId,
        destination: destination,
        fallbackCode: CourseService.codeForCourse(destination),
        animationsEnabled: animationsEnabled,
        reducedMotion: MediaQuery.maybeOf(context)?.disableAnimations == true,
      );
    } catch (_) {
      // Course selection must remain successful if a configured flag cannot
      // be resolved or rendered for this optional transition.
      return null;
    }
  }

  void _finishCourseEntryTransition(int generation) {
    if (!mounted || _courseEntryTransition?.generation != generation) return;
    setState(() => _courseEntryTransition = null);
  }

  Future<void> _addLearner(BuildContext overlayContext) async {
    if (_addingLearner) return;
    _addingLearner = true;
    try {
      await Navigator.of(overlayContext).push<LearnerProfile>(
        MaterialPageRoute(
          builder: (_) => NewLearnerFlowScreen(
            profileService: _profiles,
            canCancel: _learners.isNotEmpty,
          ),
        ),
      );
      if (mounted) setState(() => _course = null);
      if (!mounted) {
        return;
      }
      await _reload();
      await _showStartupNotices();
    } finally {
      _addingLearner = false;
    }
  }

  Future<void> _switchLearner(String learnerProfileId) async {
    String? pin;
    if (await _profiles.hasAccessPin(learnerProfileId)) {
      if (!mounted) return;
      var enteredPin = '';
      pin = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enter Access PIN'),
          content: TextFormField(
            key: const Key('profile-access-pin-prompt'),
            onChanged: (value) => enteredPin = value,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: '4-digit Access PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, enteredPin),
              child: const Text('Access profile'),
            ),
          ],
        ),
      );
      if (pin == null) return;
    }
    try {
      if (mounted) setState(() => _course = null);
      await _profiles.setActiveProfileById(learnerProfileId, accessPin: pin);
      await _reload();
      await _showStartupNotices();
    } on ProfilePinException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _reload();
    }
  }

  Future<({ProfileAvatarAppearance? appearance, bool hasPin})>
  _learnerSheetData(LearnerProfile profile) async => (
    appearance: await _profiles.getAvatarAppearanceForProfile(
      profile.learnerProfileId,
    ),
    hasPin: await _profiles.hasAccessPin(profile.learnerProfileId),
  );

  Future<void> _changeDeviceDisplayName() async {
    final actor = _activeLearnerId;
    if (actor == null || !_adminProfileIds.contains(actor) || !mounted) return;
    var enteredName = _deviceDisplayName;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QQL device name'),
        content: TextFormField(
          key: const Key('qql-device-name-field'),
          initialValue: _deviceDisplayName,
          onChanged: (name) => enteredName = name,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, enteredName),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      await _profiles.setDeviceDisplayName(
        actorProfileId: actor,
        displayName: value,
      );
      final savedName = await _profiles.getDeviceDisplayName();
      if (mounted) setState(() => _deviceDisplayName = savedName);
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

  Future<void> _promoteAdmin(String targetProfileId) async {
    final actor = _activeLearnerId;
    if (actor == null) return;
    await runReported(
      context,
      'Make admin',
      () => _profiles.promoteToAdmin(
        actorProfileId: actor,
        targetProfileId: targetProfileId,
      ),
    );
    await _reload();
  }

  Future<void> _relinquishAdmin() async {
    final actor = _activeLearnerId;
    if (actor == null) return;
    try {
      await _profiles.relinquishAdmin(actor);
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

  Future<void> _resetLearnerPin(String targetProfileId) async {
    final actor = _activeLearnerId;
    if (actor == null) return;
    try {
      await _profiles.resetAccessPinAsAdmin(
        actorProfileId: actor,
        targetProfileId: targetProfileId,
      );
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

  Future<void> _deleteLearner(
    LearnerProfile profile,
    BuildContext overlayContext,
  ) async {
    final ok = await showDialog<bool>(
      context: overlayContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete learner?'),
        content: Text(
          'Delete ${profile.displayName} and all local progress for this learner?',
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
    );
    if (ok == true) {
      try {
        await _profiles.deleteProfileById(
          profile.learnerProfileId,
          actorProfileId: _activeLearnerId,
        );
        await _reload();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('StateError: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _showLearners(BuildContext overlayContext) async {
    final action = await showModalBottomSheet<String>(
      context: overlayContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .72,
          child: Column(
            children: [
              ListTile(
                title: Text('Learners on $_deviceDisplayName'),
                trailing:
                    _activeLearnerId != null &&
                        _adminProfileIds.contains(_activeLearnerId)
                    ? IconButton(
                        key: const Key('edit-qql-device-name'),
                        tooltip: 'Change QQL device name',
                        onPressed: () => Navigator.pop(ctx, 'device-name'),
                        icon: const Icon(Icons.edit_outlined),
                      )
                    : null,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    ..._learners.map(
                      (
                        profile,
                      ) => FutureBuilder<({ProfileAvatarAppearance? appearance, bool hasPin})>(
                        future: _learnerSheetData(profile),
                        builder: (context, snapshot) {
                          final appearance = snapshot.data?.appearance;
                          final hasPin = snapshot.data?.hasPin == true;
                          final actorId = _activeLearnerId;
                          final actorIsAdmin =
                              actorId != null &&
                              _adminProfileIds.contains(actorId);
                          final targetIsAdmin = _adminProfileIds.contains(
                            profile.learnerProfileId,
                          );
                          final canDelete =
                              actorId != null &&
                              (actorId == profile.learnerProfileId ||
                                  actorIsAdmin);
                          final isSoleAdmin =
                              targetIsAdmin && _adminProfileIds.length == 1;
                          final hasActions =
                              canDelete ||
                              (actorIsAdmin && !targetIsAdmin) ||
                              (actorId == profile.learnerProfileId &&
                                  targetIsAdmin &&
                                  _adminProfileIds.length > 1) ||
                              (actorIsAdmin &&
                                  actorId != profile.learnerProfileId &&
                                  hasPin);
                          return ListTile(
                            leading: SizedBox(
                              width: 42,
                              height: 48,
                              child: appearance == null
                                  ? const Icon(Icons.person_outline)
                                  : LearnerAvatar(
                                      skinTone: appearance.skinTone,
                                      hairTone: appearance.hairTone,
                                    ),
                            ),
                            title: Text(
                              '${profile.displayName}${targetIsAdmin ? ' (admin)' : ''}',
                            ),
                            subtitle: profile.discordHandle == null
                                ? null
                                : Text('${profile.discordHandle} on Discord'),
                            selected:
                                profile.learnerProfileId == _activeLearnerId,
                            onTap: () => Navigator.pop(
                              ctx,
                              'switch:${profile.learnerProfileId}',
                            ),
                            trailing: hasActions
                                ? PopupMenuButton<String>(
                                    tooltip: 'Learner actions',
                                    onSelected: (value) => Navigator.pop(
                                      ctx,
                                      '$value:${profile.learnerProfileId}',
                                    ),
                                    itemBuilder: (context) => [
                                      if (actorIsAdmin && !targetIsAdmin)
                                        const PopupMenuItem(
                                          value: 'promote-admin',
                                          child: Text('Make admin'),
                                        ),
                                      if (actorId == profile.learnerProfileId &&
                                          targetIsAdmin &&
                                          _adminProfileIds.length > 1)
                                        const PopupMenuItem(
                                          value: 'relinquish-admin',
                                          child: Text('Relinquish admin'),
                                        ),
                                      if (actorIsAdmin &&
                                          actorId != profile.learnerProfileId &&
                                          hasPin)
                                        const PopupMenuItem(
                                          value: 'reset-pin',
                                          child: Text('Reset PIN'),
                                        ),
                                      if (canDelete)
                                        PopupMenuItem(
                                          value: 'delete',
                                          enabled: !isSoleAdmin,
                                          child: isSoleAdmin
                                              ? ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 260,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text(
                                                        'Delete learner (only admin)',
                                                      ),
                                                      Text(
                                                        'The only admin cannot be deleted. However, you can make another user admin. As last resort, you can reset QQL.',
                                                        key: const Key(
                                                          'sole-admin-delete-note',
                                                        ),
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const Text('Delete learner'),
                                        ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt),
                      title: const Text('Add learner'),
                      onTap: () => Navigator.pop(ctx, 'add'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || !overlayContext.mounted || action == null) return;
    // Start the next route only after the bottom sheet has completely closed.
    // This avoids disposing inherited dependents while Add profile opens.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || !overlayContext.mounted) return;
    if (action == 'add') {
      await _addLearner(overlayContext);
      return;
    }
    if (action == 'device-name') {
      await _changeDeviceDisplayName();
      return;
    }
    if (action.startsWith('switch:')) {
      await _switchLearner(action.substring(7));
      return;
    }
    if (action.startsWith('delete:')) {
      final learnerProfileId = action.substring(7);
      LearnerProfile? profile;
      for (final candidate in _learners) {
        if (candidate.learnerProfileId == learnerProfileId) {
          profile = candidate;
          break;
        }
      }
      if (profile != null) await _deleteLearner(profile, overlayContext);
      return;
    }
    if (action.startsWith('promote-admin:')) {
      await _promoteAdmin(action.substring('promote-admin:'.length));
      return;
    }
    if (action.startsWith('relinquish-admin:')) {
      await _relinquishAdmin();
      return;
    }
    if (action.startsWith('reset-pin:')) {
      await _resetLearnerPin(action.substring('reset-pin:'.length));
    }
  }

  Future<void> _showInitialLearnerFlow(BuildContext overlayContext) async {
    if (_learnerFlowOpen) return;
    _learnerFlowOpen = true;
    try {
      if (_learners.isEmpty) {
        await _addLearner(overlayContext);
      } else {
        await _showLearners(overlayContext);
      }
    } finally {
      _learnerFlowOpen = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showCoursePicker(BuildContext overlayContext) async {
    Future<void> Function()? selectedCourseSwitch;
    final codes = List<String>.from(_bundledCourseCodes);
    final bundledCourses = Map<String, Course>.fromEntries(
      await Future.wait(
        codes.map(
          (code) async => MapEntry(code, await _courseService.loadCourse(code)),
        ),
      ),
    );
    for (final code in List<String>.from(codes)) {
      if (!await CourseLibraryService().contains(bundledCourses[code]!)) {
        codes.remove(code);
        bundledCourses.remove(code);
      }
    }
    final localCourses = (await CourseLibraryService().included(
      await _courseEditorService.listUserCourses(),
    )).map(_publication.learnerCourse).whereType<Course>().toList();
    final editorUnlocked = await _settings.isCourseEditorUnlocked();
    final allRefs = [
      ...codes,
      for (final course in localCourses) 'custom:${course.courseId}',
    ];
    final courseByRef = <String, Course>{
      for (final code in codes) code: bundledCourses[code]!,
      for (final course in localCourses) 'custom:${course.courseId}': course,
    };
    final courseIds = courseByRef.values.map((course) => course.courseId);
    final favoriteService = CourseFavoriteService();
    final visibilityService = CourseLearnerVisibilityService();
    final favoriteIds = await favoriteService.favoriteCourseIds(courseIds);
    final hiddenIds = await visibilityService.hiddenCourseIds(courseIds);
    final recentHistory = await _settings.getRecentCourseRefs();
    if (!mounted || !overlayContext.mounted) return;
    StateSetter? setPickerState;

    String normalizedRef(String ref) =>
        ref.startsWith('custom:') ? ref : ref.trim().toUpperCase();

    bool visibleInPicker(String ref) =>
        !hiddenIds.contains(courseByRef[ref]!.courseId);

    List<String> recentRefs() => recentHistory
        .map(normalizedRef)
        .where(
          (ref) =>
              ref != _selectedCourseRef &&
              courseByRef.containsKey(ref) &&
              courseByRef[ref]!.courseId != _course?.courseId &&
              visibleInPicker(ref),
        )
        .toSet()
        .take(3)
        .toList();

    List<String> favoriteRefs() => allRefs
        .where(
          (ref) =>
              visibleInPicker(ref) &&
              favoriteIds.contains(courseByRef[ref]!.courseId),
        )
        .toList();

    // The current Course has its own row at the top; Build 255 Revision 7
    // stops repeating it under Other courses (Favorites may still list it).
    List<String> otherRefs(List<String> recent, List<String> favorites) =>
        allRefs
            .where(
              (ref) =>
                  visibleInPicker(ref) &&
                  ref != _selectedCourseRef &&
                  courseByRef[ref]!.courseId != _course?.courseId &&
                  !recent.contains(ref) &&
                  !favorites.contains(ref),
            )
            .toList();

    String originLabel(Course course) {
      if (course.originType == CourseOriginType.bundledOfficial) {
        return 'Bundled official · ${course.publisherName} ${course.officialCourseVersion}';
      }
      if (course.originType == CourseOriginType.externalOfficial) {
        return 'Publisher Course · ${course.publisherName} ${course.officialCourseVersion} · ${course.publisherVerificationStatus.name}';
      }
      return 'Custom course · version ${course.courseVersion.isEmpty ? 'unconfirmed' : course.courseVersion}';
    }

    Future<void> openCourseInfo(BuildContext context, Course course) =>
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => CourseInfoScreen(course: course)),
        );

    Future<void> handleCourseAction(
      BuildContext context,
      Course course,
      String action,
    ) async {
      if (action == 'remove_personal') {
        if (await removeFromMyCourses(context, course)) {
          if (context.mounted) Navigator.of(context).pop();
          await _reload();
        }
        return;
      }
      if (action == 'review') {
        if (course.courseId != _course?.courseId) return;
        selectedCourseSwitch = () => _openReview(course);
        Navigator.of(context).pop();
        return;
      }
      if (action == 'info') {
        await openCourseInfo(context, course);
        return;
      }
      if (action == 'favorite') {
        final favorite = !favoriteIds.contains(course.courseId);
        try {
          await favoriteService.setFavorite(course.courseId, favorite);
          if (!mounted || !context.mounted) return;
          setPickerState?.call(() {
            if (favorite) {
              favoriteIds.add(course.courseId);
            } else {
              favoriteIds.remove(course.courseId);
            }
          });
        } catch (error) {
          if (context.mounted) {
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Could not update Favorite'),
                content: Text('$error'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
        return;
      }
      if (action == 'hide') {
        if (course.courseId == _course?.courseId) return;
        try {
          await visibilityService.setHidden(
            course,
            true,
            activeCourseId: _course?.courseId,
          );
          if (!mounted || !context.mounted) return;
          setPickerState?.call(() => hiddenIds.add(course.courseId));
        } catch (error) {
          if (context.mounted) {
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Could not hide Course'),
                content: Text('$error'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
        return;
      }
    }

    // Build 255 Revision 7: a Course with a cover shows it here, as in
    // Courses; every other Course keeps its flag.
    Widget courseImage(Course course, String fallbackCode) =>
        Course.coverImagePattern.hasMatch(course.coverImage)
        ? CourseArtwork(course: course, size: 44)
        : CourseFlagBadge(course: course, fallbackCode: fallbackCode);

    Widget courseTile({
      Key? key,
      required String rowId,
      required Course course,
      required Widget leading,
      Widget? subtitle,
      bool selected = false,
      bool showReview = false,
      VoidCallback? onTap,
    }) {
      return ListTile(
        key: key,
        leading: leading,
        title: Text(course.title),
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) const Icon(Icons.check),
            PopupMenuButton<String>(
              key: ValueKey('course-selector-actions-$rowId'),
              tooltip: 'Course actions',
              onSelected: (action) =>
                  handleCourseAction(overlayContext, course, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'info',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text('Course Info'),
                  ),
                ),
                if (showReview)
                  const PopupMenuItem(
                    value: 'review',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_edu_outlined),
                      title: Text('Review'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'favorite',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      favoriteIds.contains(course.courseId)
                          ? Icons.star
                          : Icons.star_border,
                    ),
                    title: Text(
                      favoriteIds.contains(course.courseId)
                          ? 'Remove from Favorites'
                          : 'Favorite',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'hide',
                  enabled: course.courseId != _course?.courseId,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Hide in Learner'),
                    subtitle: course.courseId == _course?.courseId
                        ? const Text("You're studying this Course")
                        : null,
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove_personal',
                  child: Text('Remove from my courses'),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      );
    }

    Widget includedCourseTile(BuildContext ctx, String ref, String section) {
      final custom = ref.startsWith('custom:') ? courseByRef[ref] : null;
      final key = section == 'other'
          ? custom == null
                ? ValueKey('bundled-course-$ref')
                : ValueKey('local-course-${custom.courseId}')
          : ValueKey('$section-course-$ref');
      final rowId = section == 'other'
          ? custom == null
                ? 'bundled-$ref'
                : 'local-${custom.courseId}'
          : '$section-$ref';
      if (custom != null) {
        return courseTile(
          key: key,
          rowId: rowId,
          course: custom,
          leading: courseImage(custom, CourseService.codeForCourse(custom)),
          subtitle: Text(
            '${custom.sourceLanguage} → ${custom.targetLanguage}'
            ' · ${originLabel(custom)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          selected: _selectedCourseRef == ref,
          showReview: custom.courseId == _course?.courseId,
          onTap: () {
            if (custom.courseId != _course?.courseId) {
              selectedCourseSwitch = () => _switchCustomCourse(custom);
            }
            Navigator.pop(ctx);
          },
        );
      }
      final code = ref.trim().toUpperCase();
      return courseTile(
        key: key,
        rowId: rowId,
        course: bundledCourses[code]!,
        leading: courseImage(bundledCourses[code]!, code),
        subtitle: Text(
          '${CourseService.sourceLabels[code] ?? bundledCourses[code]!.sourceLanguage} → ${CourseService.targetLabels[code] ?? bundledCourses[code]!.targetLanguage}'
          ' · Bundled official${CourseService.hasCourse(code) ? '' : ' · Coming soon'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        selected: _selectedCourseRef == code,
        showReview: bundledCourses[code]!.courseId == _course?.courseId,
        onTap: CourseService.hasCourse(code)
            ? () {
                if (bundledCourses[code]!.courseId != _course?.courseId) {
                  selectedCourseSwitch = () => _switchCourse(code);
                }
                Navigator.pop(ctx);
              }
            : null,
      );
    }

    Future<void> openCourses(
      BuildContext sheetContext, {
      required CoursesTab tab,
      bool editCurrent = false,
      bool newCourse = false,
    }) async {
      final selectedCourse = _course;
      Navigator.pop(sheetContext);
      if (!overlayContext.mounted) return;
      final request = await Navigator.of(overlayContext)
          .push<CourseStudyRequest>(
            MaterialPageRoute(
              builder: (_) => CoursesScreen(
                initialTab: tab,
                currentCourse: selectedCourse,
                initialCourseIdToOpen: editCurrent
                    ? selectedCourse?.courseId
                    : null,
                startNewCourse: newCourse,
              ),
            ),
          );
      if (mounted) await _studyFromCourses(request);
    }

    Future<void> showCourseManagerLocked(BuildContext sheetContext) =>
        showDialog<void>(
          context: sheetContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Course Studio locked'),
            content: const Text(courseManagerUnlockMessage),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );

    Widget managerLink(
      BuildContext sheetContext, {
      required Key key,
      required IconData icon,
      required String title,
      required VoidCallback onOpen,
    }) {
      final tile = ListTile(
        key: key,
        enabled: editorUnlocked,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: editorUnlocked ? onOpen : null,
      );
      return editorUnlocked
          ? tile
          : InkWell(
              onTap: () => showCourseManagerLocked(sheetContext),
              child: tile,
            );
    }

    await showModalBottomSheet<void>(
      context: overlayContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          setPickerState = setSheetState;
          final recent = recentRefs();
          final favorites = favoriteRefs();
          final other = otherRefs(recent, favorites);
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: .78,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  const ListTile(title: Text('Choose course')),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Text(
                      'Current course',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_course != null)
                    courseTile(
                      key: const Key('current-course'),
                      rowId: 'current',
                      course: _course!,
                      leading: courseImage(_course!, _selectedLanguage),
                      selected: true,
                      showReview: true,
                    ),
                  if (recent.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        'Recently opened',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final ref in recent)
                      includedCourseTile(ctx, ref, 'recent'),
                  ],
                  if (favorites.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        'Favorites',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final ref in favorites)
                      includedCourseTile(ctx, ref, 'favorite'),
                  ],
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: Text(
                      'Other courses',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (final ref in other)
                    includedCourseTile(ctx, ref, 'other'),
                  const Divider(height: 28),
                  ListTile(
                    key: const Key('course-selector-all-courses'),
                    leading: const Icon(Icons.library_add_outlined),
                    title: const Text('All Courses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openCourses(ctx, tab: CoursesTab.allCourses),
                  ),
                  managerLink(
                    ctx,
                    key: const Key('course-selector-course-manager'),
                    icon: Icons.library_books_outlined,
                    title: 'Course Studio',
                    onOpen: () => openCourses(ctx, tab: CoursesTab.manager),
                  ),
                  // Build 267 Revision 6 (owner, 9 October 2026): New Course
                  // from here, greyed like Course Studio while it is locked.
                  managerLink(
                    ctx,
                    key: const Key('course-selector-new-course'),
                    icon: Icons.add_circle_outline,
                    title: 'New Course',
                    onOpen: () => openCourses(
                      ctx,
                      tab: CoursesTab.manager,
                      newCourse: true,
                    ),
                  ),
                  managerLink(
                    ctx,
                    key: const Key('course-selector-edit-current'),
                    icon: Icons.edit_outlined,
                    title: 'Course Editor',
                    onOpen: () => openCourses(
                      ctx,
                      tab: CoursesTab.manager,
                      editCurrent: true,
                    ),
                  ),
                  ListTile(
                    key: const Key('course-selector-import'),
                    leading: const Icon(Icons.file_open_outlined),
                    title: const Text('Import Course'),
                    onTap: () async {
                      final selected = _course;
                      if (selected == null) return;
                      Navigator.pop(ctx);
                      final imported = await Navigator.of(overlayContext)
                          .push<Course>(
                            MaterialPageRoute(
                              builder: (_) => CourseProjectsScreen(
                                currentCourse: selected,
                                importOnly: true,
                              ),
                            ),
                          );
                      if (!mounted) return;
                      await _reload();
                      if (!mounted || imported == null) return;
                      final playable =
                          _publication.learnerCourse(imported) != null;
                      final canStudy =
                          playable &&
                          (imported.originType !=
                                  CourseOriginType.bundledOfficial ||
                              CourseService.hasCourse(
                                CourseService.codeForCourse(imported),
                              ));
                      final reason =
                          PublicationService.requiresPublisherVerification(
                            imported,
                          )
                          ? ' Publisher verification is required before you can study it.'
                          : !imported.publicationState.isPublished
                          ? ' Publish this Course before you can study it.'
                          : canStudy
                          ? ''
                          : ' This Course is not available for study yet.';
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 8),
                          content: Text(
                            'Imported “${imported.title}” and added to your courses.$reason',
                          ),
                          action: canStudy
                              ? SnackBarAction(
                                  label: 'Study now',
                                  onPressed: () {
                                    if (imported.originType ==
                                        CourseOriginType.bundledOfficial) {
                                      unawaited(
                                        _switchCourse(
                                          CourseService.codeForCourse(imported),
                                        ),
                                      );
                                    } else {
                                      unawaited(_switchCustomCourse(imported));
                                    }
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    setPickerState = null;
    if (!mounted || !overlayContext.mounted) return;
    if (selectedCourseSwitch != null) {
      // The sheet's result resolves when reverse animation starts. Wait through
      // that dismissal so its row-menu semantics are disposed before the
      // destination Course rebuild and optional entry overlay begin.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted || !overlayContext.mounted) return;
    }
    await selectedCourseSwitch?.call();
  }

  Future<void> _openAllCourses() async {
    final request = await Navigator.of(context).push<CourseStudyRequest>(
      MaterialPageRoute(
        builder: (_) => const CoursesScreen(initialTab: CoursesTab.allCourses),
      ),
    );
    if (mounted) await _studyFromCourses(request);
  }

  /// After Courses closes: reload, or carry out Study or Review chosen in a
  /// Course menu (Build 261 Revision 1, owner decision of 1 October 2026).
  /// The Course joins the learner's courses when it is missing and becomes
  /// current; Review then opens on it.
  Future<void> _studyFromCourses(CourseStudyRequest? request) async {
    if (request == null) {
      await _reload();
      return;
    }
    final course = request.course;
    try {
      final library = CourseLibraryService();
      if (!await library.contains(course)) await library.add(course);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add “${course.title}”: $error')),
        );
      }
      await _reload();
      return;
    }
    if (!mounted) return;
    if (course.courseId == _course?.courseId) {
      await _reload();
    } else if (course.originType == CourseOriginType.bundledOfficial) {
      await _switchCourse(CourseService.bundledCodeForCourse(course));
    } else {
      await _switchCustomCourse(course);
    }
    final current = _course;
    if (!mounted ||
        request.action != CourseStudyAction.review ||
        current?.courseId != course.courseId) {
      return;
    }
    await _openReview(current!);
  }

  Future<bool> _canOpenLearnerContent() async {
    if (BetaLifecycleService.isExpired()) {
      await _showExpiredLearnerNotice();
      return false;
    }
    return true;
  }

  bool _isLessonUnlocked(Course course, int index) =>
      _lessonUnlocks.isLessonUnlocked(
        lessonIndex: index,
        course: course,
        completedLessons: _completedLessons,
        wonDuels: _wonDuels,
      );

  bool _hasLessonAccess(
    Course course,
    int index, {
    LearnerIddqdMode? iddqdMode,
  }) {
    if (index < 0 || index >= course.lessons.length) return false;
    final lesson = course.lessons[index];
    return _isLessonUnlocked(course, index) ||
        (iddqdMode ?? _iddqdMode).bypassesLocks ||
        _sessionPreviewedLockedLessons.contains((
          courseId: course.courseId,
          lessonId: lesson.lessonId,
        ));
  }

  int _nearestAccessibleLessonIndex(
    Course course, {
    LearnerIddqdMode? iddqdMode,
  }) {
    if (course.lessons.isEmpty) return 0;
    if (_hasLessonAccess(course, _activeLessonIndex, iddqdMode: iddqdMode)) {
      return _activeLessonIndex;
    }
    for (var index = _activeLessonIndex - 1; index >= 0; index--) {
      if (_hasLessonAccess(course, index, iddqdMode: iddqdMode)) return index;
    }
    for (
      var index = _activeLessonIndex + 1;
      index < course.lessons.length;
      index++
    ) {
      if (_hasLessonAccess(course, index, iddqdMode: iddqdMode)) return index;
    }
    return 0;
  }

  void _resetLockedLessonTapSequence() {
    _lockedLessonTapResetTimer?.cancel();
    _lockedLessonTapResetTimer = null;
    _lockedLessonTapLessonId = null;
    _lockedLessonTapCount = 0;
  }

  void _recordLockedLessonTap(String courseId, String lessonId) {
    _lockedLessonTapResetTimer?.cancel();
    _lockedLessonTapResetTimer = null;
    if (_lockedLessonTapLessonId != lessonId) {
      _lockedLessonTapLessonId = lessonId;
      _lockedLessonTapCount = 0;
    }
    _lockedLessonTapCount++;
    if (_lockedLessonTapCount >= _lockedLessonPreviewTapCount) {
      setState(() {
        _sessionPreviewedLockedLessons.add((
          courseId: courseId,
          lessonId: lessonId,
        ));
        _lockedLessonTapLessonId = null;
        _lockedLessonTapCount = 0;
      });
      return;
    }
    _lockedLessonTapResetTimer = Timer(_lockedLessonPreviewTapTimeout, () {
      _resetLockedLessonTapSequence();
    });
  }

  Future<void> _selectLesson(Course course, int index) async {
    if (index < 0 || index >= course.lessons.length) return;
    await _settings.setLastVisitedLessonId(
      course.courseId,
      course.lessons[index].lessonId,
    );
    if (!mounted) return;
    _resetLockedLessonTapSequence();
    setState(() {
      _activeLessonIndex = index;
    });
    _scrollToLesson(course, index);
  }

  void _scrollToLesson(Course course, int index) {
    if (index < 0 || index >= course.lessons.length) return;
    _lessonScrollTargetIndex = index;
    _lessonScrollTargetAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _advanceLessonScrollTarget(course, index),
    );
  }

  void _advanceLessonScrollTarget(Course course, int index) {
    if (!mounted ||
        !identical(_course, course) ||
        _lessonScrollTargetIndex != index) {
      return;
    }
    if (!_learnerScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _advanceLessonScrollTarget(course, index),
      );
      return;
    }
    final sectionContext = _lessonSectionKey(
      course,
      course.lessons[index],
    ).currentContext;
    if (sectionContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          sectionContext,
          alignment: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ).whenComplete(() {
          if (mounted && _lessonScrollTargetIndex == index) {
            _lessonScrollTargetIndex = null;
          }
        }),
      );
      return;
    }

    final position = _learnerScrollController.position;
    final step = position.viewportDimension * .8;
    final builtIndexes = <int>[
      for (var builtIndex = 0; builtIndex < course.lessons.length; builtIndex++)
        if (_lessonSectionKey(
              course,
              course.lessons[builtIndex],
            ).currentContext !=
            null)
          builtIndex,
    ];
    final moveBackward = builtIndexes.isNotEmpty && index < builtIndexes.first;
    final nextOffset = (position.pixels + (moveBackward ? -step : step))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (nextOffset != position.pixels) {
      _learnerScrollController.jumpTo(nextOffset);
    }
    _lessonScrollTargetAttempts++;
    if (_lessonScrollTargetAttempts >= 120) {
      _lessonScrollTargetIndex = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _advanceLessonScrollTarget(course, index),
    );
  }

  GlobalKey _lessonSectionKey(Course course, Lesson lesson) =>
      _lessonSectionKeys.putIfAbsent(
        '${course.courseId}:${lesson.lessonId}',
        () => GlobalKey(),
      );

  void _schedulePrimaryLessonSync(Course course) {
    if (_lessonExpansionMode == LearnerLessonExpansionMode.focused) return;
    if (_lessonVisibilityCheckScheduled) return;
    _lessonVisibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lessonVisibilityCheckScheduled = false;
      if (mounted) _syncPrimaryVisibleLesson(course);
    });
  }

  void _syncPrimaryVisibleLesson(Course course) {
    if (!identical(_course, course) ||
        !_learnerScrollController.hasClients ||
        _lessonScrollTargetIndex != null ||
        course.lessons.isEmpty) {
      return;
    }
    final position = _learnerScrollController.position;
    final viewportStart = position.pixels;
    final viewportEnd = viewportStart + position.viewportDimension;
    var candidateIndex = _activeLessonIndex;
    var candidateVisibleExtent = 0.0;
    var activeVisibleExtent = 0.0;

    for (var index = 0; index < course.lessons.length; index++) {
      final context = _lessonSectionKey(
        course,
        course.lessons[index],
      ).currentContext;
      final renderBox = context?.findRenderObject();
      if (renderBox is! RenderBox || !renderBox.attached) continue;
      final viewport = RenderAbstractViewport.of(renderBox);
      final sectionStart = viewport.getOffsetToReveal(renderBox, 0).offset;
      final sectionEnd = sectionStart + renderBox.size.height;
      final visibleExtent =
          min(sectionEnd, viewportEnd) - max(sectionStart, viewportStart);
      final clampedVisibleExtent = max(0.0, visibleExtent);
      if (index == _activeLessonIndex) {
        activeVisibleExtent = clampedVisibleExtent;
      }
      if (clampedVisibleExtent > candidateVisibleExtent) {
        candidateIndex = index;
        candidateVisibleExtent = clampedVisibleExtent;
      }
    }

    if (candidateIndex == _activeLessonIndex || candidateVisibleExtent <= 0) {
      return;
    }
    // The selector follows the Lesson with the greatest visible extent only
    // after it exceeds the current Lesson by 10% of the viewport. This keeps
    // the derived Section block stable around boundaries while remaining
    // deterministic for the same scroll position.
    final hysteresis = position.viewportDimension * .1;
    if (activeVisibleExtent > 0 &&
        candidateVisibleExtent < activeVisibleExtent + hysteresis) {
      return;
    }
    _resetLockedLessonTapSequence();
    setState(() {
      _activeLessonIndex = candidateIndex;
    });
    unawaited(
      _settings.setLastVisitedLessonId(
        course.courseId,
        course.lessons[candidateIndex].lessonId,
      ),
    );
  }

  Future<void> _showSectionPicker(
    Course course,
    BuildContext overlayContext,
  ) async {
    final blocks = learnerSectionBlocks(course.lessons);
    if (blocks.isEmpty) return;
    final activeBlockIndex = blocks.indexWhere(
      (block) => block.containsLesson(_activeLessonIndex),
    );
    final selected = await showModalBottomSheet<int>(
      context: overlayContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .78,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    return ListTile(
                      leading: Icon(
                        block.synthetic
                            ? Icons.more_horiz
                            : Icons.view_agenda_outlined,
                      ),
                      title: Text(block.label),
                      trailing: index == activeBlockIndex
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(ctx, index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      await _selectLesson(course, blocks[selected].firstLessonIndex);
    }
  }

  Future<void> _openGuidebook(
    Course course,
    Lesson lesson,
    int lessonIndex,
  ) async {
    _resetLockedLessonTapSequence();
    if (!course.useGuidebook ||
        !lesson.guidebook.publicationState.isPublished) {
      return;
    }
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuidebookScreen(
          course: course,
          lesson: lesson,
          lessonIndex: lessonIndex,
        ),
      ),
    );
  }

  Future<void> _openRound(
    Course course,
    Lesson lesson,
    LearningRound round,
  ) async {
    _resetLockedLessonTapSequence();
    if (!await _canOpenLearnerContent() || !mounted) return;
    await CrashLogService.instance.recordDebugEvent(
      'Home: opening Round ${round.id} in Lesson ${lesson.lessonId}',
    );
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: course,
          lesson: lesson,
          round: round,
          roundIndex: lesson.rounds.indexOf(round),
          ttsLanguage: CourseLanguageResolver.learning(course).code ?? '',
          completeLessonOnFinish: true,
          viewOnlyMode: _iddqdMode == LearnerIddqdMode.viewOnly,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openDuel(Course course, Lesson lesson) async {
    if (!course.createDuels) return;
    final eligibility = await _effectiveDuelEligibility(course, lesson);
    if (!mounted) return;
    if (!eligibility.isAvailable) {
      setState(() {
        _duelEligibilityByLessonId = {
          ..._duelEligibilityByLessonId,
          lesson.lessonId: eligibility,
        };
      });
      return;
    }
    _resetLockedLessonTapSequence();
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          course: course,
          lesson: lesson,
          ttsLanguage: CourseLanguageResolver.learning(course).code ?? '',
          viewOnlyMode: _iddqdMode == LearnerIddqdMode.viewOnly,
          settingsService: _settings,
        ),
      ),
    );
    await _reload();
  }

  Future<Map<String, DuelEligibilityResult>> _effectiveDuelEligibilityFor(
    Course course, {
    required bool audioExercisesEnabled,
    required bool ttsEnabled,
  }) async {
    if (!course.createDuels) return const {};
    final results = await Future.wait([
      for (final lesson in course.lessons)
        _duelEligibility.evaluateEffective(
          course,
          lesson,
          audioExercisesEnabled: audioExercisesEnabled,
          ttsEnabled: ttsEnabled,
          audioAvailability: _audioAvailability,
        ),
    ]);
    return {
      for (var index = 0; index < course.lessons.length; index++)
        course.lessons[index].lessonId: results[index],
    };
  }

  Future<Map<String, EffectiveRoundAudioAvailability>>
  _effectiveRoundAudioAvailabilityFor(
    Course course, {
    required bool audioExercisesEnabled,
    required bool ttsEnabled,
  }) async {
    final rounds = [for (final lesson in course.lessons) ...lesson.rounds];
    final results = await Future.wait([
      for (final round in rounds)
        _audioAvailability.evaluateRound(
          course,
          round,
          audioExercisesEnabled: audioExercisesEnabled,
          ttsEnabled: ttsEnabled,
        ),
    ]);
    return {
      for (var index = 0; index < rounds.length; index++)
        rounds[index].id: results[index],
    };
  }

  Future<DuelEligibilityResult> _effectiveDuelEligibility(
    Course course,
    Lesson lesson,
  ) async {
    final audioExercisesEnabled = await _settings.areAudioExercisesEnabled();
    final ttsEnabled = audioExercisesEnabled && await _settings.isTtsEnabled();
    return _duelEligibility.evaluateEffective(
      course,
      lesson,
      audioExercisesEnabled: audioExercisesEnabled,
      ttsEnabled: ttsEnabled,
      audioAvailability: _audioAvailability,
    );
  }

  Future<void> _openReview(Course course) async {
    _resetLockedLessonTapSequence();
    if (BetaLifecycleService.isExpired()) {
      await _showExpiredLearnerNotice();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReviewScreen(course: course, courseCode: _selectedLanguage),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final followsDarkAppearance = _usesDarkLearnerAppearance(context);
    final course = _course;
    if (course == null && _libraryEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My courses'),
          actions: [
            IconButton(
              key: const Key('empty-library-settings'),
              tooltip: 'Settings',
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      course: null,
                      onManageLearners: _showLearners,
                    ),
                  ),
                );
                if (mounted) await _reload();
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No courses available for study in your library.'),
              FilledButton(
                onPressed: _openAllCourses,
                child: const Text('All Courses'),
              ),
              if (_emptyLibraryEditorUnlocked) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('empty-library-course-manager'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Course Studio'),
                  onPressed: () async {
                    final request = await Navigator.of(context)
                        .push<CourseStudyRequest>(
                          MaterialPageRoute(
                            builder: (_) => const CoursesScreen(
                              initialTab: CoursesTab.manager,
                              currentCourse: null,
                            ),
                          ),
                        );
                    if (mounted) await _studyFromCourses(request);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (course == null) {
      return Scaffold(
        key: const Key('unified-learner-loading-page'),
        backgroundColor: followsDarkAppearance
            ? _learnerDarkPageBackground
            : _learnerLightPageBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: followsDarkAppearance ? const Color(0xFF54D8FF) : null,
          ),
        ),
      );
    }
    final pageBackground = followsDarkAppearance
        ? _learnerDarkPageBackground
        : _learnerLightPageBackground;
    final flagBackgroundMode = _flagBackgroundMode;
    final showsFlagArtwork =
        flagBackgroundMode == LearnerFlagBackgroundMode.small ||
        flagBackgroundMode == LearnerFlagBackgroundMode.extended;
    final showsInspiredBackground =
        flagBackgroundMode == LearnerFlagBackgroundMode.tinted ||
        flagBackgroundMode == LearnerFlagBackgroundMode.softInspired;
    final learnerTheme = _unifiedLearnerTheme(context);
    return Theme(
      data: learnerTheme,
      child: Builder(
        builder: (learnerContext) {
          if (_activeLearner == null && !_addingLearner && !_learnerFlowOpen) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  learnerContext.mounted &&
                  _activeLearner == null &&
                  !_addingLearner &&
                  !_learnerFlowOpen) {
                _showInitialLearnerFlow(learnerContext);
              }
            });
          }
          return LearnerStatusPage(
            showStatusBar: false,
            child: Scaffold(
              key: const Key('unified-learner-page'),
              backgroundColor: pageBackground,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  if (showsFlagArtwork) ...[
                    CourseFlagBackdrop(
                      key: const Key('unified-learner-flag-background'),
                      course: course,
                      fallbackCode: _selectedLanguage,
                      opacity: 1,
                      fit:
                          flagBackgroundMode ==
                              LearnerFlagBackgroundMode.extended
                          ? BoxFit.cover
                          : BoxFit.contain,
                    ),
                    ColoredBox(
                      key: followsDarkAppearance
                          ? const Key('unified-learner-dark-veil')
                          : const Key('unified-learner-light-veil'),
                      color: learnerTheme.colorScheme.surface.withValues(
                        alpha: followsDarkAppearance
                            ? learnerDarkFlagVeilOpacity
                            : learnerLightFlagVeilOpacity,
                      ),
                    ),
                  ],
                  if (showsInspiredBackground)
                    CourseFlagInspiredBackground(
                      course: course,
                      fallbackCode: _selectedLanguage,
                      brightness: followsDarkAppearance
                          ? Brightness.dark
                          : Brightness.light,
                      mode: flagBackgroundMode,
                    ),
                  SafeArea(
                    child: Column(
                      children: [
                        Column(
                          key: const Key('unified-learner-header'),
                          children: [
                            UnifiedLearnerTopBar(
                              controller: _topBarController(learnerContext),
                              course: course,
                              courseCode: _selectedLanguage,
                              onCoursePressed: () => runReported(
                                learnerContext,
                                'The Course Selector',
                                () => _showCoursePicker(learnerContext),
                              ),
                              onLogoPressed: () {
                                _resetLockedLessonTapSequence();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const InfoScreen(),
                                  ),
                                );
                              },
                              onSettingsPressed: () async {
                                _resetLockedLessonTapSequence();
                                await CrashLogService.instance.recordDebugEvent(
                                  'Home: opening Settings',
                                );
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SettingsScreen(
                                      course: course,
                                      onManageLearners: _showLearners,
                                    ),
                                  ),
                                );
                                await _reload();
                              },
                            ),
                            if (learnerSectionBlocks(course.lessons).isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final blocks = learnerSectionBlocks(
                                    course.lessons,
                                  );
                                  final activeBlock = blocks.indexWhere(
                                    (block) => block.containsLesson(
                                      _activeLessonIndex,
                                    ),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      10,
                                      20,
                                      10,
                                    ),
                                    child: _SectionNavigation(
                                      label: blocks[activeBlock].label,
                                      onPrevious: activeBlock > 0
                                          ? () => _selectLesson(
                                              course,
                                              blocks[activeBlock - 1]
                                                  .firstLessonIndex,
                                            )
                                          : null,
                                      onNext: activeBlock + 1 < blocks.length
                                          ? () => _selectLesson(
                                              course,
                                              blocks[activeBlock + 1]
                                                  .firstLessonIndex,
                                            )
                                          : null,
                                      onBrowse: () => _showSectionPicker(
                                        course,
                                        learnerContext,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        Expanded(
                          child: LearnerPathHalo(
                            enabled: showsFlagArtwork,
                            child: RefreshIndicator(
                              onRefresh: _reload,
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (_) {
                                  _schedulePrimaryLessonSync(course);
                                  return false;
                                },
                                child: ListView.builder(
                                  key: const Key('unified-learner-scroll'),
                                  controller: _learnerScrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    8,
                                    14,
                                    _learnerScrollBottomInset,
                                  ),
                                  itemCount: course.lessons.isEmpty
                                      ? 1
                                      : course.lessons.length,
                                  itemBuilder: (context, flowIndex) {
                                    if (course.lessons.isEmpty) {
                                      return const _EmptyCourseCard();
                                    }
                                    final lessonIndex = flowIndex;
                                    final sectionLesson =
                                        course.lessons[lessonIndex];
                                    final showSectionHeader =
                                        learnerShowsSectionHeader(
                                          course.lessons,
                                          lessonIndex,
                                        );
                                    final unlocked = _isLessonUnlocked(
                                      course,
                                      lessonIndex,
                                    );
                                    final previewOnly =
                                        !unlocked &&
                                        !_iddqdMode.bypassesLocks &&
                                        _sessionPreviewedLockedLessons
                                            .contains((
                                              courseId: course.courseId,
                                              lessonId: sectionLesson.lessonId,
                                            ));
                                    final hasAccess =
                                        unlocked ||
                                        _iddqdMode.bypassesLocks ||
                                        previewOnly;
                                    final lessonExpanded =
                                        LessonExpansionPolicy.isExpanded(
                                          mode: _lessonExpansionMode,
                                          hasAccess: hasAccess,
                                          isCompleted: _completedLessons
                                              .contains(sectionLesson.lessonId),
                                          isCurrent:
                                              lessonIndex == _activeLessonIndex,
                                        );
                                    return _LessonSection(
                                      key: ValueKey(
                                        'unified-lesson-section-${sectionLesson.lessonId}',
                                      ),
                                      visibilityKey: _lessonSectionKey(
                                        course,
                                        sectionLesson,
                                      ),
                                      lesson: sectionLesson,
                                      course: course,
                                      courseId: course.courseId,
                                      lessonIndex: lessonIndex,
                                      mascotPositionOffset:
                                          learnerMascotPositionOffsetForLesson(
                                            course.lessons,
                                            lessonIndex,
                                            courseId: course.courseId,
                                          ),
                                      roundPositionOffset:
                                          learnerRoundPositionOffsetForLesson(
                                            course.lessons,
                                            lessonIndex,
                                          ),
                                      showBoundary: lessonIndex > 0,
                                      showSectionHeader: showSectionHeader,
                                      unlocked: unlocked,
                                      hasAccess: hasAccess,
                                      isExpanded: lessonExpanded,
                                      iddqdAccessMode:
                                          !unlocked && _iddqdMode.bypassesLocks
                                          ? _iddqdMode
                                          : null,
                                      previewOnly: previewOnly,
                                      completedRounds: _completedRounds,
                                      perfectRounds: _perfectRounds,
                                      ttsSkippedPerfectRounds:
                                          _ttsSkippedPerfectRounds,
                                      roundAudioAvailability:
                                          _roundAudioAvailability,
                                      duelEligibility:
                                          _duelEligibilityByLessonId[sectionLesson
                                              .lessonId] ??
                                          const DuelEligibilityResult(
                                            candidates: [],
                                            requiredCount:
                                                DuelEligibilityService
                                                    .requiredQuestionCount,
                                            structuralEligibleCount: 0,
                                          ),
                                      onOpenGuidebook: () => _openGuidebook(
                                        course,
                                        sectionLesson,
                                        lessonIndex,
                                      ),
                                      onOpenRound: (round) => _openRound(
                                        course,
                                        sectionLesson,
                                        round,
                                      ),
                                      onOpenDuel: () =>
                                          _openDuel(course, sectionLesson),
                                      onExpand:
                                          _lessonExpansionMode ==
                                                  LearnerLessonExpansionMode
                                                      .focused &&
                                              !lessonExpanded &&
                                              hasAccess
                                          ? () => _selectLesson(
                                              course,
                                              lessonIndex,
                                            )
                                          : null,
                                      onLockedTap:
                                          unlocked || _iddqdMode.bypassesLocks
                                          ? null
                                          : () => _recordLockedLessonTap(
                                              course.courseId,
                                              sectionLesson.lessonId,
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: LearnerBottomActions(
                            key: const Key('unified-bottom-controls'),
                            onProfile: () async {
                              _resetLockedLessonTapSequence();
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(
                                    course: course,
                                    onManageLearners: _showLearners,
                                  ),
                                ),
                              );
                              await _reload();
                            },
                            onReview: () => _openReview(course),
                            courseId: course.courseId,
                            courseCode: CourseService.codeForCourse(course),
                            iddqdMode: _iddqdMode,
                            onIddqdChanged: (value) async {
                              final previous = _iddqdMode;
                              final previousLessonIndex = _activeLessonIndex;
                              final nextLessonIndex =
                                  _lessonExpansionMode ==
                                      LearnerLessonExpansionMode.focused
                                  ? _nearestAccessibleLessonIndex(
                                      course,
                                      iddqdMode: value,
                                    )
                                  : _activeLessonIndex;
                              setState(() {
                                _iddqdMode = value;
                                _activeLessonIndex = nextLessonIndex;
                              });
                              try {
                                await _settings.setIddqdMode(
                                  course.courseId,
                                  value,
                                );
                              } catch (_) {
                                if (mounted) {
                                  setState(() {
                                    _iddqdMode = previous;
                                    _activeLessonIndex = previousLessonIndex;
                                  });
                                }
                                return;
                              }
                              if (nextLessonIndex != previousLessonIndex) {
                                await _settings.setLastVisitedLessonId(
                                  course.courseId,
                                  course.lessons[nextLessonIndex].lessonId,
                                );
                                _scrollToLesson(course, nextLessonIndex);
                              }
                            },
                            lessonExpansionMode: _lessonExpansionMode,
                            onLessonExpansionChanged: (value) async {
                              final previous = _lessonExpansionMode;
                              final previousLessonIndex = _activeLessonIndex;
                              final nextLessonIndex =
                                  value == LearnerLessonExpansionMode.focused
                                  ? _nearestAccessibleLessonIndex(course)
                                  : _activeLessonIndex;
                              setState(() {
                                _lessonExpansionMode = value;
                                _activeLessonIndex = nextLessonIndex;
                              });
                              try {
                                await _settings.setLessonExpansionMode(
                                  course.courseId,
                                  value,
                                );
                              } catch (_) {
                                if (mounted) {
                                  setState(() {
                                    _lessonExpansionMode = previous;
                                    _activeLessonIndex = previousLessonIndex;
                                  });
                                }
                                return;
                              }
                              if (nextLessonIndex != previousLessonIndex) {
                                await _settings.setLastVisitedLessonId(
                                  course.courseId,
                                  course.lessons[nextLessonIndex].lessonId,
                                );
                                _scrollToLesson(course, nextLessonIndex);
                              }
                            },
                            onCourseInfo: () {
                              _resetLockedLessonTapSequence();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CourseInfoScreen(course: course),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_courseEntryTransition case final transition?)
                    CourseEntryAnimation(
                      key: ValueKey(
                        'course-entry-animation-${transition.generation}',
                      ),
                      flag: transition.flag,
                      onComplete: () =>
                          _finishCourseEntryTransition(transition.generation),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionNavigation extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBrowse;

  const _SectionNavigation({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('unified-section-selector'),
            onPressed: onBrowse,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface.withValues(alpha: .5)
                  : Colors.white.withValues(alpha: .5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous Section',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Tooltip(
                    message: label,
                    child: Text(
                      label,
                      key: const Key('unified-section-selector-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next Section',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _LessonSection extends StatelessWidget {
  final GlobalKey visibilityKey;
  final Lesson lesson;
  final Course course;
  final String courseId;
  final int lessonIndex;
  final int mascotPositionOffset;
  final int roundPositionOffset;
  final bool showBoundary;
  final bool showSectionHeader;
  final bool unlocked;
  final bool hasAccess;
  final bool isExpanded;
  final LearnerIddqdMode? iddqdAccessMode;
  final bool previewOnly;

  /// The Course preview opens a Draft GuideBook too (Build 261 Revision 2).
  final bool includeDrafts;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final Map<String, EffectiveRoundAudioAvailability> roundAudioAvailability;
  final DuelEligibilityResult duelEligibility;
  final VoidCallback onOpenGuidebook;
  final void Function(LearningRound round) onOpenRound;
  final VoidCallback onOpenDuel;
  final VoidCallback? onExpand;
  final VoidCallback? onLockedTap;

  const _LessonSection({
    super.key,
    required this.visibilityKey,
    required this.lesson,
    required this.course,
    required this.courseId,
    required this.lessonIndex,
    required this.mascotPositionOffset,
    required this.roundPositionOffset,
    required this.showBoundary,
    required this.showSectionHeader,
    required this.unlocked,
    required this.hasAccess,
    required this.isExpanded,
    required this.iddqdAccessMode,
    required this.previewOnly,
    this.includeDrafts = false,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.roundAudioAvailability,
    required this.duelEligibility,
    required this.onOpenGuidebook,
    required this.onOpenRound,
    required this.onOpenDuel,
    required this.onExpand,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    key: visibilityKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showBoundary) ...[
        SizedBox(
          key: ValueKey('unified-lesson-transition-${lesson.lessonId}'),
          height: 32,
        ),
        const Divider(),
      ],
      if (showSectionHeader) LessonSectionHeader(lesson: lesson),
      if (previewOnly && isExpanded)
        Align(
          alignment: Alignment.center,
          child: Container(
            key: ValueKey('unified-lesson-preview-${lesson.lessonId}'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview only',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Lesson still locked',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      _GuidebookNode(
        lesson: lesson,
        course: course,
        lessonIndex: lessonIndex,
        unlocked: unlocked,
        iddqdAccessMode: iddqdAccessMode,
        onLockedTap: onLockedTap,
        onExpandLesson: onExpand,
        onTap:
            hasAccess &&
                !previewOnly &&
                (includeDrafts || lesson.guidebook.publicationState.isPublished)
            ? onOpenGuidebook
            : null,
      ),
      if (iddqdAccessMode != null)
        _IddqdAccessIndicator(
          lessonId: lesson.lessonId,
          mode: iddqdAccessMode!,
        ),
      if (!hasAccess)
        Padding(
          key: ValueKey('unified-lesson-locked-${lesson.lessonId}'),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 12),
              Flexible(
                child: _FlagBackdropText(
                  course.createDuels
                      ? 'Complete the previous Lesson or win its Duel to unlock this Lesson.'
                      : 'Complete the previous Lesson to unlock this Lesson.',
                  key: ValueKey(
                    'flag-backdrop-locked-message-${lesson.lessonId}',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        )
      else if (isExpanded) ...[
        // The line leaves the Lesson circle itself, unless the IDDQD pill
        // stands between them (Build 261 Revision 8).
        if (iddqdAccessMode != null) const _VerticalConnector(),
        LearnerRoundPath(
          courseId: courseId,
          lessonIndex: lessonIndex,
          startsAtLessonCircle: iddqdAccessMode == null,
          leadsToDuel:
              course.createDuels && duelEligibility.isStructurallyAvailable,
          roundNumberingMode: course.roundNumberingMode,
          customRoundLabel: course.customRoundLabel,
          rounds: lesson.rounds,
          completedRounds: completedRounds,
          perfectRounds: perfectRounds,
          ttsSkippedPerfectRounds: ttsSkippedPerfectRounds,
          roundAudioAvailability: roundAudioAvailability,
          mascotPositionOffset: mascotPositionOffset,
          roundPositionOffset: roundPositionOffset,
          interactive: !previewOnly,
          onOpenRound: onOpenRound,
        ),
        if (course.createDuels && duelEligibility.isStructurallyAvailable) ...[
          const _VerticalConnector(),
          _DuelCard(
            key: ValueKey('unified-duel-${lesson.lessonId}'),
            lessonIndex: lessonIndex,
            eligibility: duelEligibility,
            isFinalLesson: lessonIndex == course.lessons.length - 1,
            onTap: previewOnly ? null : onOpenDuel,
          ),
        ],
      ],
      const SizedBox(height: 16),
    ],
  );
}

class _IddqdAccessIndicator extends StatelessWidget {
  final String lessonId;
  final LearnerIddqdMode mode;

  const _IddqdAccessIndicator({required this.lessonId, required this.mode});

  String get _accessLabel => mode == LearnerIddqdMode.viewOnly
      ? 'Preview with IDDQD'
      : 'Accessible with IDDQD';

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: Semantics(
      container: true,
      label: 'Lesson is locked in normal progression. $_accessLabel.',
      child: ExcludeSemantics(
        child: Container(
          key: ValueKey('unified-lesson-iddqd-access-$lessonId'),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_outlined, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _accessLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GuidebookNode extends StatelessWidget {
  final Lesson lesson;
  final Course course;
  final int lessonIndex;
  final bool unlocked;
  final LearnerIddqdMode? iddqdAccessMode;
  final VoidCallback? onLockedTap;
  final VoidCallback? onTap;
  final VoidCallback? onExpandLesson;

  const _GuidebookNode({
    required this.lesson,
    required this.course,
    required this.lessonIndex,
    required this.unlocked,
    required this.iddqdAccessMode,
    required this.onLockedTap,
    required this.onTap,
    required this.onExpandLesson,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bookAction = IconButton(
      key: ValueKey('unified-guidebook-action-${lesson.lessonId}'),
      tooltip: course.useGuidebook ? 'GuideBook' : null,
      onPressed: onTap,
      color: isDark ? Colors.white : Colors.black87,
      icon: const Icon(Icons.menu_book_outlined, size: 24),
    );
    final expandAction = IconButton(
      key: ValueKey('lesson-expansion-action-${lesson.lessonId}'),
      tooltip: 'Open Lesson',
      onPressed: onExpandLesson,
      icon: const Icon(Icons.expand_more),
    );
    final identity = const LessonPresentationService().identity(
      course,
      lessonIndex,
    );
    final managedIconId = lesson.themeIconAsset == null
        ? null
        : CourseLessonIconAsset.assetIdFromReference(lesson.themeIconAsset!);
    CourseLessonIconAsset? managedIcon;
    if (managedIconId != null) {
      for (final asset in course.lessonIconAssets) {
        if (asset.assetId == managedIconId) {
          managedIcon = asset;
          break;
        }
      }
    }
    // Since Build 261 Revision 8 (owner decisions) a faint borderless
    // background instead of the card: the number circle carries the Lesson's
    // colour, the texts are lighter, and the row is still one tap target.
    final halo = learnerPathTextHalo(context);
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FractionallySizedBox(
          widthFactor: learnerGuidebookWidthFactor,
          child: Material(
            key: const Key('unified-guidebook-node'),
            color:
                (isDark
                        ? colorScheme.surfaceContainerHigh
                        : const Color(0xFFFFF7C9))
                    .withValues(alpha: learnerPathSurfaceOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              excludeFromSemantics: !course.useGuidebook,
              onTap: onExpandLesson ?? (course.useGuidebook ? onTap : null),
              child: Padding(
                padding: const EdgeInsets.all(learnerLessonRowPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          key: const Key('guidebook-lesson-icon-slot'),
                          width: learnerLessonIconSize,
                          height: learnerLessonIconSize,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: lesson.themeIconAsset == null
                                    ? LessonFallbackIcon(
                                        number: identity.number,
                                        monochromeKey: const Key(
                                          'guidebook-monochrome-fallback-icon',
                                        ),
                                        coloredKey: const Key(
                                          'guidebook-colored-fallback-icon',
                                        ),
                                      )
                                    : managedIcon != null
                                    ? Image.memory(
                                        base64Decode(managedIcon.base64Png),
                                        key: const Key(
                                          'guidebook-theme-icon-image',
                                        ),
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        lesson.themeIconAsset!,
                                        key: const Key(
                                          'guidebook-theme-icon-image',
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                              if (!unlocked)
                                Positioned(
                                  right: -3,
                                  bottom: -3,
                                  child: Semantics(
                                    button: onLockedTap != null,
                                    label: iddqdAccessMode != null
                                        ? 'Locked ${identity.prefix ?? identity.title}. ${iddqdAccessMode == LearnerIddqdMode.viewOnly ? 'Preview with IDDQD.' : 'Accessible with IDDQD.'}'
                                        : 'Locked ${identity.prefix ?? identity.title}',
                                    child: GestureDetector(
                                      key: ValueKey(
                                        'unified-lesson-preview-lock-${lesson.lessonId}',
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: onLockedTap ?? () {},
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(3),
                                          child: Icon(
                                            Icons.lock_outline,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            // The whole title when three lines cut it (Build
                            // 261 Revision 0, owner decision).
                            child: Tooltip(
                              key: ValueKey(
                                'unified-guidebook-lesson-tooltip-${lesson.lessonId}',
                              ),
                              message: identity.fullText,
                              excludeFromSemantics: true,
                              // A small label line above a lighter title
                              // (Build 261 Revision 8, owner decision).
                              child: MergeSemantics(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (identity.prefix != null)
                                      Text(
                                        identity.prefix!,
                                        key: ValueKey(
                                          'unified-guidebook-lesson-label-${lesson.lessonId}',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: learnerPathLabelStyle(context),
                                      ),
                                    Text(
                                      identity.title,
                                      key: ValueKey(
                                        'unified-guidebook-lesson-title-${lesson.lessonId}',
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        height: 1.25,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                        shadows: halo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (onExpandLesson != null)
                          expandAction
                        else if (course.useGuidebook)
                          bookAction
                        else
                          ExcludeSemantics(
                            // Reuse the original enabled/disabled rendering,
                            // including theme tint, without an input surface.
                            child: ExcludeFocus(
                              child: IgnorePointer(child: bookAction),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      key: const Key('learner-tree-connector'),
      width: learnerPathConnectorStrokeWidth,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
          alpha: learnerPathConnectorOpacity,
        ),
        borderRadius: BorderRadius.circular(
          learnerPathConnectorStrokeWidth / 2,
        ),
        boxShadow: LearnerPathHalo.of(context)
            ? [
                BoxShadow(
                  color: _learnerPageBackgroundOf(context),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    ),
  );
}

enum LearnerRoundPathSide { left, right }

/// Where a Round's circle stands and on which side of it its texts run
/// (Build 261 Revision 8, owner decisions): at the left edge, the centre or
/// the right edge, the texts toward the middle; a centred circle has its
/// texts on the right or on the left.
enum LearnerRoundPlacement { left, centerTextRight, centerTextLeft, right }

/// The circles wander between the centre and the edges, sometimes staying
/// twice on a side or at the centre; they never jump from one edge straight
/// to the other, where a curve across the whole width would cross a text
/// (owner request: more variety). A Lesson enters the pattern at [start]
/// (see [learnerRoundPlacementStart]); the pattern also never jumps from edge
/// to edge where it wraps around.
LearnerRoundPlacement learnerRoundPlacement(int index, {int start = 0}) =>
    const [
      LearnerRoundPlacement.centerTextRight,
      LearnerRoundPlacement.left,
      LearnerRoundPlacement.left,
      LearnerRoundPlacement.centerTextRight,
      LearnerRoundPlacement.right,
      LearnerRoundPlacement.centerTextLeft,
      LearnerRoundPlacement.left,
      LearnerRoundPlacement.centerTextRight,
      LearnerRoundPlacement.centerTextLeft,
      LearnerRoundPlacement.right,
      LearnerRoundPlacement.right,
      LearnerRoundPlacement.centerTextLeft,
      LearnerRoundPlacement.left,
      LearnerRoundPlacement.centerTextRight,
      LearnerRoundPlacement.right,
      LearnerRoundPlacement.centerTextLeft,
    ][(start + index) % 16];

/// Where each Lesson enters [learnerRoundPlacement] (owner request of
/// 3 October 2026, Build 262 Revision 3: not the same path in every Lesson
/// and every Course). Every start puts the first circle at the centre, its
/// texts on the right or on the left, where the line from the Lesson circle
/// or from the IDDQD pill reaches it without crossing a text (a first circle
/// at the left edge would have the line from the pill cross its label). The
/// eight starts give eight different shapes; the Course picks the first
/// Lesson's start and each next Lesson moves three places along this list,
/// so neighbouring Lessons never share a shape and their first texts change
/// side. Nothing is stored: the shape follows the Course ID and the Lesson's
/// position.
const learnerRoundPlacementStarts = <int>[0, 5, 3, 8, 7, 11, 13, 15];

int learnerRoundPlacementStart(String courseId, int lessonIndex) {
  const starts = learnerRoundPlacementStarts;
  final first = _learnerMascotSeed(courseId) % starts.length;
  return starts[(first + 3 * lessonIndex) % starts.length];
}

/// The half of the path a Round's texts take; its mascot stands on the
/// other one.
LearnerRoundPathSide learnerRoundPathSide(int index, {int start = 0}) =>
    switch (learnerRoundPlacement(index, start: start)) {
      LearnerRoundPlacement.left ||
      LearnerRoundPlacement.centerTextLeft => LearnerRoundPathSide.left,
      LearnerRoundPlacement.centerTextRight ||
      LearnerRoundPlacement.right => LearnerRoundPathSide.right,
    };

/// Which Rounds of a Lesson have a mascot, in the free half opposite their
/// texts (Build 261 Revision 8, owner requests): seven slots in ten across
/// the Course (four before: without cards the sides looked empty), but never
/// two Rounds in a row with a mascot on the same side.
List<bool> learnerRoundPathMascotRows(
  int roundCount, {
  int roundPositionOffset = 0,
  int placementStart = 0,
}) {
  const slots = <int>{0, 1, 3, 4, 5, 7, 8};
  final rows = <bool>[];
  for (var index = 0; index < roundCount; index++) {
    final slot = slots.contains((roundPositionOffset + index) % 10);
    final besideAnother =
        index > 0 &&
        rows[index - 1] &&
        learnerRoundPathSide(index, start: placementStart) ==
            learnerRoundPathSide(index - 1, start: placementStart);
    rows.add(slot && !besideAnother);
  }
  return rows;
}

bool learnerRoundPathShowsMascot(
  int index, {
  int roundPositionOffset = 0,
  int placementStart = 0,
}) => learnerRoundPathMascotRows(
  index + 1,
  roundPositionOffset: roundPositionOffset,
  placementStart: placementStart,
)[index];

int learnerRoundPathMascotSlotCount(
  int roundCount, {
  int roundPositionOffset = 0,
  int placementStart = 0,
}) => learnerRoundPathMascotRows(
  roundCount,
  roundPositionOffset: roundPositionOffset,
  placementStart: placementStart,
).where((shown) => shown).length;

int learnerRoundPositionOffsetForLesson(
  List<Lesson> lessons,
  int lessonIndex,
) => lessons
    .take(lessonIndex)
    .fold(0, (total, lesson) => total + lesson.rounds.length);

/// How many mascots the earlier Lessons show, so the mascot order runs on
/// across the Course. Each Lesson counts its own, since whether a Round has
/// one depends on its neighbour in the same Lesson.
int learnerMascotPositionOffsetForLesson(
  List<Lesson> lessons,
  int lessonIndex, {
  required String courseId,
}) {
  var count = 0;
  for (var index = 0; index < lessonIndex; index++) {
    count += learnerRoundPathMascotSlotCount(
      lessons[index].rounds.length,
      roundPositionOffset: learnerRoundPositionOffsetForLesson(lessons, index),
      placementStart: learnerRoundPlacementStart(courseId, index),
    );
  }
  return count;
}

/// One-based position inside the current consecutive Section block.
/// A non-Section Lesson has no Section-relative number and returns zero.
int learnerSectionLessonNumber(List<Lesson> lessons, int lessonIndex) {
  if (lessonIndex < 0 || lessonIndex >= lessons.length) return 0;
  final lesson = lessons[lessonIndex];
  final sectionName = lesson.sectionName?.trim();
  if (!lesson.section || sectionName == null || sectionName.isEmpty) return 0;
  var firstIndex = lessonIndex;
  while (firstIndex > 0) {
    final previous = lessons[firstIndex - 1];
    if (!previous.section || previous.sectionName?.trim() != sectionName) break;
    firstIndex--;
  }
  return lessonIndex - firstIndex + 1;
}

bool learnerShowsSectionHeader(List<Lesson> lessons, int lessonIndex) {
  if (lessonIndex < 0 || lessonIndex >= lessons.length) return false;
  final lesson = lessons[lessonIndex];
  final sectionName = lesson.sectionName?.trim();
  if (!lesson.section || sectionName == null || sectionName.isEmpty) {
    return false;
  }
  if (lessonIndex == 0) return true;
  final previous = lessons[lessonIndex - 1];
  return !previous.section || previous.sectionName?.trim() != sectionName;
}

class LessonSectionHeader extends StatelessWidget {
  final Lesson lesson;

  const LessonSectionHeader({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey('lesson-section-header-${lesson.lessonId}'),
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
    child: Semantics(
      header: true,
      child: Text(
        lesson.sectionName!,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

int _learnerMascotSeed(String courseId) {
  var hash = 0;
  for (final codeUnit in courseId.codeUnits) {
    hash = (hash + codeUnit) & 0x7FFFFFFF;
    hash = (hash + (hash << 10)) & 0x7FFFFFFF;
    hash ^= hash >> 6;
  }
  hash = (hash + (hash << 3)) & 0x7FFFFFFF;
  hash ^= hash >> 11;
  return (hash + (hash << 15)) & 0x7FFFFFFF;
}

List<String> learnerCourseMascotOrder(
  String courseId,
  List<String> mascotAssets,
) {
  final ordered = mascotAssets.toSet().toList(growable: false);
  ordered.sort();
  if (ordered.length < 2) return ordered;
  final random = Random(_learnerMascotSeed(courseId));
  for (var index = ordered.length - 1; index > 0; index--) {
    final swapIndex = random.nextInt(index + 1);
    final value = ordered[index];
    ordered[index] = ordered[swapIndex];
    ordered[swapIndex] = value;
  }
  return ordered;
}

String learnerMascotAssetAtPosition(List<String> orderedAssets, int position) {
  if (orderedAssets.isEmpty) {
    throw ArgumentError.value(orderedAssets, 'orderedAssets', 'is empty');
  }
  final cycleLength = orderedAssets.length;
  final cycle = position ~/ cycleLength;
  final indexInCycle = position % cycleLength;
  final cycleShift = cycleLength == 2 ? 0 : cycle % cycleLength;
  return orderedAssets[(indexInCycle + cycleShift) % cycleLength];
}

class LearnerRoundPath extends StatefulWidget {
  final String courseId;

  /// The Lesson's zero-based position: it picks the circles' colour.
  final int lessonIndex;

  /// The line starts at the Lesson number circle just above the path,
  /// otherwise at the top centre.
  final bool startsAtLessonCircle;

  /// The line continues below the last Round to the Duel circle.
  final bool leadsToDuel;
  final RoundNumberingMode roundNumberingMode;
  final String customRoundLabel;
  final List<LearningRound> rounds;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final Map<String, EffectiveRoundAudioAvailability> roundAudioAvailability;
  final void Function(LearningRound round) onOpenRound;
  final List<String>? mascotAssets;
  final int mascotPositionOffset;
  final int roundPositionOffset;
  final bool interactive;

  const LearnerRoundPath({
    super.key,
    required this.courseId,
    this.lessonIndex = 0,
    this.startsAtLessonCircle = false,
    this.leadsToDuel = false,
    this.roundNumberingMode = RoundNumberingMode.off,
    this.customRoundLabel = '',
    required this.rounds,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.roundAudioAvailability,
    required this.onOpenRound,
    this.mascotAssets,
    this.mascotPositionOffset = 0,
    this.roundPositionOffset = 0,
    this.interactive = true,
  });

  @override
  State<LearnerRoundPath> createState() => _LearnerRoundPathState();
}

class _LearnerRoundPathState extends State<LearnerRoundPath> {
  late Future<List<String>> _mascotAssetsFuture;

  @override
  void initState() {
    super.initState();
    _resolveMascotAssets();
  }

  @override
  void didUpdateWidget(covariant LearnerRoundPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.mascotAssets, widget.mascotAssets)) {
      _resolveMascotAssets();
    }
  }

  void _resolveMascotAssets() {
    if (widget.mascotAssets == null) {
      _mascotAssetsFuture = loadProductionLearnerMascotAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('This Lesson does not contain any Rounds yet.'),
        ),
      );
    }
    final injectedMascots = widget.mascotAssets;
    if (injectedMascots != null) {
      return _buildPath(context, injectedMascots);
    }
    return FutureBuilder<List<String>>(
      future: _mascotAssetsFuture,
      builder: (context, snapshot) =>
          _buildPath(context, snapshot.data ?? const <String>[]),
    );
  }

  Widget _buildPath(BuildContext context, List<String> mascotAssets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On a wide window the path keeps a phone-like column, centred, so
        // the curves between circles stay clear of the texts.
        final width = min(constraints.maxWidth, learnerRoundPathMaxWidth);
        final inset = (constraints.maxWidth - width) / 2;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final cardHeight = 108.0 + (textScale - 1.0).clamp(0.0, 2.0) * 148.0;
        const verticalGap = 28.0;
        final rowExtent = cardHeight + verticalGap;
        final showMascots = width >= 320 && mascotAssets.isNotEmpty;
        final cardWidth = min(
          width,
          max(
            196.0,
            min(learnerRoundCardMaxWidth, width * (showMascots ? .68 : .82)),
          ),
        );
        const lead = learnerRoundPathLead;
        final start = learnerRoundPlacementStart(
          widget.courseId,
          widget.lessonIndex,
        );
        final rows = <({double left, double width, bool mirrored})>[
          for (var index = 0; index < widget.rounds.length; index++)
            switch (learnerRoundPlacement(index, start: start)) {
              LearnerRoundPlacement.left => (
                left: 0,
                width: cardWidth,
                mirrored: false,
              ),
              LearnerRoundPlacement.right => (
                left: width - cardWidth,
                width: cardWidth,
                mirrored: true,
              ),
              LearnerRoundPlacement.centerTextRight => (
                left: width / 2 - learnerRoundIconCenterX,
                width: min(cardWidth, width / 2 + learnerRoundIconCenterX),
                mirrored: false,
              ),
              LearnerRoundPlacement.centerTextLeft => (
                left: max(0.0, width / 2 + learnerRoundIconCenterX - cardWidth),
                width: min(cardWidth, width / 2 + learnerRoundIconCenterX),
                mirrored: true,
              ),
            },
        ];
        final centers = [
          for (var index = 0; index < rows.length; index++)
            Offset(
              rows[index].mirrored
                  ? rows[index].left +
                        rows[index].width -
                        learnerRoundIconCenterX
                  : rows[index].left + learnerRoundIconCenterX,
              lead + index * rowExtent + cardHeight / 2,
            ),
        ];
        final courseMascots = learnerCourseMascotOrder(
          widget.courseId,
          mascotAssets,
        );
        var mascotPosition = widget.mascotPositionOffset;
        final mascotRows = learnerRoundPathMascotRows(
          widget.rounds.length,
          roundPositionOffset: widget.roundPositionOffset,
          placementStart: start,
        );
        final halo = LearnerPathHalo.of(context);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const Key('unified-round-tree'),
            width: width,
            height:
                lead +
                rowExtent * widget.rounds.length -
                verticalGap +
                (widget.leadsToDuel ? lead : 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const Key('learner-round-connector'),
                      painter: _RoundPathPainter(
                        centers: centers,
                        seeds: [
                          for (final round in widget.rounds)
                            _learnerMascotSeed(round.id),
                        ],
                        startX: widget.startsAtLessonCircle
                            ? learnerLessonCircleCenterX(constraints.maxWidth) -
                                  inset
                            : null,
                        // The Lesson row's padding under its circle.
                        startOverhang: widget.startsAtLessonCircle
                            ? learnerLessonRowPadding
                            : 0,
                        leadsToDuel: widget.leadsToDuel,
                        halo: halo,
                        lineColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: learnerPathConnectorOpacity),
                        supportColor: halo
                            ? _learnerPageBackgroundOf(
                                context,
                              ).withValues(alpha: .85)
                            : Theme.of(context).colorScheme.surface.withValues(
                                alpha: learnerPathConnectorSupportOpacity,
                              ),
                      ),
                    ),
                  ),
                ),
                if (showMascots)
                  for (var index = 0; index < widget.rounds.length; index++)
                    if (mascotRows[index])
                      // The mascot stands in the free half, opposite the
                      // Round's texts.
                      () {
                        final textsOnRight =
                            learnerRoundPathSide(index, start: start) ==
                            LearnerRoundPathSide.right;
                        final free = textsOnRight
                            ? rows[index].left
                            : width - rows[index].left - rows[index].width;
                        final extent = max(0.0, min(112.0, free - 12));
                        return Positioned(
                          key: ValueKey('learner-round-mascot-$index'),
                          top:
                              lead +
                              index * rowExtent +
                              (cardHeight - extent) / 2,
                          left: textsOnRight ? 0 : null,
                          right: textsOnRight ? null : 0,
                          width: extent,
                          height: extent,
                          child: _MascotDecoration(
                            asset: learnerMascotAssetAtPosition(
                              courseMascots,
                              mascotPosition++,
                            ),
                          ),
                        );
                      }(),
                for (var index = 0; index < widget.rounds.length; index++)
                  Positioned(
                    key: ValueKey('learner-round-row-$index'),
                    top: lead + index * rowExtent,
                    left: rows[index].left,
                    width: rows[index].width,
                    height: cardHeight,
                    child: _RoundNode(
                      round: widget.rounds[index],
                      mirrored: rows[index].mirrored,
                      lessonColors: LessonColorPalette.of(
                        widget.lessonIndex,
                        Theme.of(context).brightness,
                      ),
                      roundNumber: index + 1,
                      roundNumberingMode: widget.roundNumberingMode,
                      customRoundLabel: widget.customRoundLabel,
                      completed: widget.completedRounds.contains(
                        widget.rounds[index].id,
                      ),
                      perfect: widget.perfectRounds.contains(
                        widget.rounds[index].id,
                      ),
                      ttsSkippedPerfect: widget.ttsSkippedPerfectRounds
                          .contains(widget.rounds[index].id),
                      audioAvailability:
                          widget.roundAudioAvailability[widget
                              .rounds[index]
                              .id] ??
                          EffectiveRoundAudioAvailability.none,
                      onTap: widget.interactive
                          ? () => widget.onOpenRound(widget.rounds[index])
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MascotDecoration extends StatelessWidget {
  final String asset;

  const _MascotDecoration({required this.asset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: ValueKey('learner-round-mascot-surface-$asset'),
          decoration: BoxDecoration(
            color:
                (isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surfaceContainerLowest)
                    .withValues(alpha: learnerMascotSurfaceOpacity),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundNode extends StatelessWidget {
  final LearningRound round;
  final LessonColors lessonColors;
  final int roundNumber;
  final RoundNumberingMode roundNumberingMode;
  final String customRoundLabel;
  final bool completed;
  final bool perfect;
  final bool ttsSkippedPerfect;
  final EffectiveRoundAudioAvailability audioAvailability;
  final VoidCallback? onTap;

  /// A row on the right of the path has its circle on the outer right and
  /// its texts, right-aligned, on the left of it, so the circles reach both
  /// edges (Build 261 Revision 8, owner request).
  final bool mirrored;

  const _RoundNode({
    required this.round,
    required this.lessonColors,
    required this.mirrored,
    required this.roundNumber,
    required this.roundNumberingMode,
    required this.customRoundLabel,
    required this.completed,
    required this.perfect,
    required this.ttsSkippedPerfect,
    required this.audioAvailability,
    required this.onTap,
  });

  IconData get _visualIcon => RoundTypePresentation.icon(round.roundType);

  bool get _hasAudio =>
      audioAvailability != EffectiveRoundAudioAvailability.none;

  bool get _hasAvailableAudio =>
      audioAvailability == EffectiveRoundAudioAvailability.available;

  String get _disabledAudioTooltip => switch (audioAvailability) {
    EffectiveRoundAudioAvailability.audioExercisesDisabled =>
      'Audio exercises are turned off in Audio Settings.',
    EffectiveRoundAudioAvailability.ttsDisabled =>
      'Text-to-speech is turned off in Audio Settings.',
    _ => 'Audio exercises are currently unavailable.',
  };

  /// The Round's label ("Round 2 · Practice", by the Course's numbering) and
  /// its own title, or null when it has none.
  (String, String?) get _titleParts {
    final typeAndNumber = RoundTypePresentation.prefix(
      round.roundType,
      roundNumber,
      roundNumberingMode,
      customPrefix: customRoundLabel,
    );
    final authored = RoundTypePresentation.authoredTitle(round);
    return (typeAndNumber, authored.isEmpty ? null : authored);
  }

  /// A small grey label line above the title in regular weight (Build 261
  /// Revision 8, owner decisions); the label looks the same whether or not
  /// the Round has a title of its own. The tooltip gives the whole name when
  /// it is cut.
  Widget _title(BuildContext context) {
    final (label, title) = _titleParts;
    final titleStyle = TextStyle(
      fontSize: 15,
      height: 1.25,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface,
      shadows: learnerPathTextHalo(context),
    );
    final key = ValueKey('unified-round-title-${round.id}');
    final align = mirrored ? TextAlign.end : TextAlign.start;
    final labelText = Text(
      label,
      key: ValueKey('unified-round-label-${round.id}'),
      maxLines: title == null ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: learnerPathLabelStyle(context),
    );
    if (title == null) return labelText;
    return Tooltip(
      message: '$label · $title',
      excludeFromSemantics: true,
      child: Column(
        crossAxisAlignment: mirrored
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          labelText,
          Text(
            title,
            key: key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: titleStyle,
          ),
        ],
      ),
    );
  }

  String get _status => perfect
      ? 'Perfect'
      : completed || ttsSkippedPerfect
      ? 'Completed'
      : 'Learn';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // "Completed" is written in the Lesson's deeper shade, not the circle's
    // own (owner decision, Build 261 Revision 8).
    final statusColor = perfect
        ? (isDark ? const Color(0xFF72DC86) : const Color(0xFF16862E))
        : completed || ttsSkippedPerfect
        ? lessonColors.onTint
        : (isDark ? const Color(0xFF8DB8FF) : const Color(0xFF1657D9));
    // The circle carries the Lesson's colour: a pale tint ringed with it
    // before completion, the colour itself once completed, green with the
    // laurel when perfect (Build 261 Revision 8, owner decision).
    final circleColor = perfect
        ? (isDark ? const Color(0xFF4CD964) : const Color(0xFF34C759))
        : completed
        ? lessonColors.solid
        : lessonColors.tint;
    final iconColor = perfect
        ? const Color(0xFF082A10)
        : completed
        ? lessonColors.onSolid
        : lessonColors.onTint;
    return Material(
      key: ValueKey('unified-round-${round.id}'),
      color:
          (isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : const Color(0xFFFFF8D6))
              .withValues(alpha: learnerPathSurfaceOpacity),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(learnerRoundRowPadding),
          child: Row(
            children: _ordered([
              SizedBox(
                key: perfect
                    ? ValueKey('unified-round-laurel-${round.id}')
                    : null,
                width: learnerRoundIconSlotWidth,
                height: perfect ? 70 : 58,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // The laurel reaches past the slot so the circle, and
                    // the path line through it, stay in the same place.
                    if (perfect) ...[
                      Positioned(
                        left: -6,
                        child: CustomPaint(
                          key: ValueKey(
                            'unified-round-laurel-branch-left-${round.id}',
                          ),
                          size: const Size(13, 42),
                          painter: _LaurelBranchPainter(
                            color: statusColor,
                            mirror: false,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -6,
                        child: CustomPaint(
                          key: ValueKey(
                            'unified-round-laurel-branch-right-${round.id}',
                          ),
                          size: const Size(13, 42),
                          painter: _LaurelBranchPainter(
                            color: statusColor,
                            mirror: true,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      key: ValueKey('unified-round-icon-${round.id}'),
                      width: learnerRoundIconSize,
                      height: learnerRoundIconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: perfect || completed
                            ? null
                            : Border.all(color: lessonColors.solid, width: 1.5),
                      ),
                      child: Icon(_visualIcon, size: 29, color: iconColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: mirrored
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _title(context),
                    const SizedBox(height: 2),
                    Text(
                      _status,
                      key: ValueKey('unified-round-status-${round.id}'),
                      textAlign: mirrored ? TextAlign.end : TextAlign.start,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        shadows: learnerPathTextHalo(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasAudio)
                _hasAvailableAudio
                    ? Icon(
                        Icons.volume_up_outlined,
                        key: ValueKey('unified-round-audio-${round.id}'),
                        color: isDark
                            ? const Color(0xFF8DB8FF)
                            : const Color(0xFF1657D9),
                      )
                    : Tooltip(
                        message: _disabledAudioTooltip,
                        child: Icon(
                          Icons.volume_up_outlined,
                          key: ValueKey('unified-round-audio-${round.id}'),
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Circle, gap, texts and audio icon from the left, or reversed.
  List<Widget> _ordered(List<Widget> leftToRight) =>
      mirrored ? leftToRight.reversed.toList() : leftToRight;
}

class _LaurelBranchPainter extends CustomPainter {
  final Color color;
  final bool mirror;

  const _LaurelBranchPainter({required this.color, required this.mirror});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final stem = Paint()
      ..color = color.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    final branch = Path()
      ..moveTo(size.width - 1, size.height - 1)
      ..cubicTo(
        size.width * .78,
        size.height * .74,
        size.width * .05,
        size.height * .34,
        size.width * .46,
        1,
      );
    canvas.drawPath(branch, stem);

    final leaf = Paint()
      ..color = color.withValues(alpha: .82)
      ..style = PaintingStyle.fill;
    for (final point in const [
      (Offset(8.7, 32), -.55),
      (Offset(5.7, 24), -.38),
      (Offset(3.5, 16), -.2),
      (Offset(2.0, 8), -.05),
    ]) {
      canvas.save();
      canvas.translate(point.$1.dx, point.$1.dy);
      canvas.rotate(point.$2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 3.6),
        leaf,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaurelBranchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mirror != mirror;
}

/// One curve of the path line and how it is drawn.
class _PathSegment {
  const _PathSegment({
    required this.path,
    required this.from,
    required this.to,
    required this.fadeStart,
    required this.fadeEnd,
    required this.peak,
    required this.thickness,
    required this.strength,
  });

  final Path path;
  final Offset from;
  final Offset to;

  /// The line fades out where it meets a circle; it stays at full strength
  /// where it joins a straight connector.
  final bool fadeStart;
  final bool fadeEnd;

  /// Where along the curve (0–1) it is thickest and strongest.
  final double peak;

  /// The widest band at [peak].
  final double thickness;

  /// The opacity at [peak], as a share of the line colour's own.
  final double strength;
}

/// The line from circle to circle (Build 261 Revision 8, owner decisions):
/// long rounded curves like the earlier path, each a little different,
/// thinner and fainter where they meet a circle, thicker and stronger
/// between circles. Each curve leaves and reaches its circles vertically, so
/// it passes beside the texts, not through them.
class _RoundPathPainter extends CustomPainter {
  /// The centre of each Round's icon circle.
  final List<Offset> centers;

  /// A stable number per Round (from its ID) that varies each curve's shape.
  final List<int> seeds;

  /// Where the line starts across the path (the Lesson circle), or null for
  /// the top centre.
  final double? startX;

  /// How far above the path the line starts: the Lesson row's padding under
  /// its circle.
  final double startOverhang;
  final bool leadsToDuel;

  /// Over a flag picture the support band widens into a halo.
  final bool halo;
  final Color lineColor;
  final Color supportColor;

  const _RoundPathPainter({
    required this.centers,
    required this.seeds,
    required this.startX,
    required this.startOverhang,
    required this.leadsToDuel,
    required this.halo,
    required this.lineColor,
    required this.supportColor,
  });

  static const thinWidth = 1.2;

  List<_PathSegment> _segments(Size size) {
    if (centers.isEmpty) return const [];
    _PathSegment curve(
      Offset from,
      Offset to,
      int seed, {
      bool fadeStart = true,
      bool fadeEnd = true,
    }) {
      final random = Random(seed);
      // The first control point stays above the middle and the second below
      // it, so the curve stays close to its circles' column near them; how
      // late and how sharply it turns varies, and it bows a little to one
      // side. Between two circles in one column it bows outward.
      final first =
          from.dy + (to.dy - from.dy) * (.5 + .22 * random.nextDouble());
      final second =
          from.dy + (to.dy - from.dy) * (.5 - .22 * random.nextDouble());
      final double bow;
      if ((from.dx - to.dx).abs() < 1) {
        final middle = size.width / 2;
        final outward = from.dx < middle - 1
            ? -1.0
            : from.dx > middle + 1
            ? 1.0
            : (random.nextBool() ? 1.0 : -1.0);
        bow = outward * (6 + 8 * random.nextDouble());
      } else {
        bow = (random.nextDouble() * 2 - 1) * 6;
      }
      return _PathSegment(
        path: Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(from.dx + bow, first, to.dx + bow, second, to.dx, to.dy),
        from: from,
        to: to,
        fadeStart: fadeStart,
        fadeEnd: fadeEnd,
        peak: .38 + .24 * random.nextDouble(),
        thickness: 3.0 + 1.3 * random.nextDouble(),
        strength: .75 + .25 * random.nextDouble(),
      );
    }

    final start = Offset(startX ?? size.width / 2, -startOverhang);
    return [
      curve(
        start,
        centers.first,
        seeds.first ^ 0x5bd1e995,
        // From the top centre it continues the IDDQD pill's connector.
        fadeStart: startX != null,
      ),
      for (var index = 1; index < centers.length; index++)
        curve(
          centers[index - 1],
          centers[index],
          seeds[index - 1] * 31 + seeds[index],
        ),
      if (leadsToDuel)
        // Straight down out of the last circle first, below its texts, then
        // into the Duel's connector at the bottom centre.
        () {
          final random = Random(seeds.last ^ 0x27d4eb2d);
          final from = centers.last;
          final to = Offset(size.width / 2, size.height);
          return _PathSegment(
            path: Path()
              ..moveTo(from.dx, from.dy)
              ..cubicTo(
                from.dx,
                to.dy,
                to.dx,
                (from.dy + to.dy) / 2,
                to.dx,
                to.dy,
              ),
            from: from,
            to: to,
            fadeStart: true,
            fadeEnd: false,
            peak: .5,
            thickness: 3.0 + 1.3 * random.nextDouble(),
            strength: .75 + .25 * random.nextDouble(),
          );
        }(),
    ];
  }

  /// The curves' centre lines, for tests.
  List<Path> segments(Size size) => [
    for (final segment in _segments(size)) segment.path,
  ];

  /// The whole centre line, for tests.
  Path pathFor(Size size) {
    final path = Path();
    for (final segment in segments(size)) {
      path.addPath(segment, Offset.zero);
    }
    return path;
  }

  /// A filled band along the segment, [extra] wider than the line, from
  /// [thinWidth] at its ends to the segment's thickness at its peak.
  static Path _band(_PathSegment segment, double extra) {
    final band = Path();
    for (final metric in segment.path.computeMetrics()) {
      final steps = max(2, (metric.length / 3).ceil());
      final left = <Offset>[];
      final right = <Offset>[];
      for (var step = 0; step <= steps; step++) {
        final t = step / steps;
        final tangent = metric.getTangentForOffset(metric.length * t)!;
        // A sine bump whose top sits at the segment's peak.
        final phase = t < segment.peak
            ? t / segment.peak / 2
            : .5 + (t - segment.peak) / (1 - segment.peak) / 2;
        final ends =
            (t == 0 && !segment.fadeStart) || (t == 1 && !segment.fadeEnd)
            ? learnerPathConnectorStrokeWidth
            : thinWidth;
        final width =
            ends + (segment.thickness - ends) * sin(pi * phase) + extra;
        final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
        left.add(tangent.position + normal * (width / 2));
        right.add(tangent.position - normal * (width / 2));
      }
      band.addPolygon([...left, ...right.reversed], true);
    }
    return band;
  }

  /// The colour fades along the segment: faint at a circle, strongest at
  /// the peak, full where a straight connector continues it.
  static Paint _shade(Color color, _PathSegment segment) {
    final alpha = color.a;
    Color at(double share) => color.withValues(alpha: alpha * share);
    final peak = segment.peak;
    return Paint()
      ..shader = ui.Gradient.linear(
        segment.from,
        segment.to,
        [
          at(segment.fadeStart ? .15 : 1),
          at(segment.strength * .7),
          at(segment.strength),
          at(segment.strength * .7),
          at(segment.fadeEnd ? .15 : 1),
        ],
        [0, peak / 2, peak, (1 + peak) / 2, 1],
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty || size.height <= 0) return;
    for (final segment in _segments(size)) {
      canvas.drawPath(
        _band(segment, halo ? 4 : 2),
        _shade(supportColor, segment),
      );
      canvas.drawPath(_band(segment, 0), _shade(lineColor, segment));
    }
  }

  @override
  bool shouldRepaint(covariant _RoundPathPainter oldDelegate) =>
      !listEquals(oldDelegate.centers, centers) ||
      !listEquals(oldDelegate.seeds, seeds) ||
      oldDelegate.startX != startX ||
      oldDelegate.startOverhang != startOverhang ||
      oldDelegate.leadsToDuel != leadsToDuel ||
      oldDelegate.halo != halo ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.supportColor != supportColor;
}

class _DuelCard extends StatelessWidget {
  final int lessonIndex;
  final DuelEligibilityResult eligibility;
  final bool isFinalLesson;
  final VoidCallback? onTap;

  const _DuelCard({
    super.key,
    required this.lessonIndex,
    required this.eligibility,
    required this.isFinalLesson,
    required this.onTap,
  });

  /// Since Build 261 Revision 8 (owner decisions) a circle in the Lesson's
  /// colour, where the path line arrives, with the texts under it, on the
  /// same faint background as the Lessons and Rounds.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = LessonColorPalette.of(
      lessonIndex,
      Theme.of(context).brightness,
    );
    final available = eligibility.isAvailable;
    final halo = learnerPathTextHalo(context);
    final card = Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FractionallySizedBox(
          widthFactor: .88,
          child: Material(
            key: const Key('unified-duel-card'),
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? colorScheme.surfaceContainerHigh
                        : const Color(0xFFFFF8D6))
                    .withValues(alpha: learnerPathSurfaceOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: available ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: const Key('unified-duel-icon'),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: available
                            ? colors.solid
                            : colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        Icons.sports_martial_arts_outlined,
                        size: 32,
                        color: available
                            ? colors.onSolid
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFinalLesson ? 'Final Duel' : 'Duel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: available
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        shadows: halo,
                      ),
                    ),
                    Text(
                      available
                          ? isFinalLesson
                                ? 'Final challenge'
                                : 'Win to skip ahead'
                          : 'Unavailable for this Lesson: not enough suitable exercises.',
                      textAlign: TextAlign.center,
                      style: learnerPathLabelStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return isFinalLesson
        ? Tooltip(message: 'Final challenge for the last Lesson.', child: card)
        : card;
  }
}

class _EmptyCourseCard extends StatelessWidget {
  const _EmptyCourseCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text('This course does not contain any Lessons yet.'),
    ),
  );
}

class _FlagBackdropText extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const _FlagBackdropText(this.data, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final foregroundColor =
        effectiveStyle.foreground?.color ??
        effectiveStyle.color ??
        Theme.of(context).colorScheme.onSurface;
    final outlineColor = foregroundColor.computeLuminance() > .5
        ? Colors.black
        : Colors.white;
    Text textLayer(TextStyle layerStyle) => Text(data, style: layerStyle);

    return Stack(
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.none,
      children: [
        ExcludeSemantics(
          child: textLayer(
            effectiveStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = outlineColor,
            ),
          ),
        ),
        textLayer(effectiveStyle),
      ],
    );
  }
}

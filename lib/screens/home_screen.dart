import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../controllers/learner_status_controller.dart';
import '../services/settings_service.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/course_editor_service.dart';
import '../services/duel_eligibility_service.dart';
import '../services/progress_service.dart';
import '../services/profile_service.dart';
import '../services/lesson_unlock_service.dart';
import '../services/alpha_lifecycle_service.dart';
import '../services/app_errors.dart';
import '../services/error_presenter.dart';
import '../services/diagnostic_log_service.dart';
import '../services/crash_log_service.dart';
import 'settings_screen.dart';
import 'review_screen.dart';
import 'course_info_screen.dart';
import 'duel_screen.dart';
import 'guidebook_screen.dart';
import 'info_screen.dart';
import 'profile_screen.dart';
import 'round_screen.dart';
import '../widgets/flag_art.dart';
import '../widgets/learner_avatar.dart';
import '../widgets/learner_bottom_actions.dart';
import '../widgets/learner_shell.dart';
import '../widgets/unified_learner_top_bar.dart';
import '../widgets/learner_theme_mode_scope.dart';

const _learnerLightPageBackground = Color(0xFFF7F3E8);
const _learnerDarkPageBackground = Color(0xFF080B09);
const _welcomeDialogBackground = Color(0xFFFFE600);
const _welcomeDialogForeground = Color(0xFF0756DF);
const learnerPathSurfaceOpacity = .75;
const learnerGuidebookSurfaceOpacity = .70;
const learnerDuelSurfaceOpacity = .70;
const learnerGuidebookWidthFactor = .78;
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
  };
}

/// Compact, scroll-safe Home dashboard.
///
/// The Home deliberately avoids fixed-height content blocks. It must remain
/// usable on small phone windows, desktop portrait previews and larger text
/// settings without producing RenderFlex overflows.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _courseService = CourseService();
  final _courseEditorService = CourseEditorService();
  final _duelEligibility = const DuelEligibilityService();
  final _progress = ProgressService();
  final _profiles = ProfileService();
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
  Course? _course;
  Set<String> _completedRounds = {};
  Set<String> _completedLessons = {};
  Set<String> _perfectRounds = {};
  Set<String> _ttsSkippedPerfectRounds = {};
  Set<String> _wonDuels = {};
  bool _iddqdMode = false;
  String _selectedLanguage = 'IT';
  String _selectedCourseRef = 'IT';
  int _activeLessonIndex = 0;
  String? _flowCourseId;
  String? _flowLearner;
  int? _lessonScrollTargetIndex;
  int _lessonScrollTargetAttempts = 0;
  bool _lessonVisibilityCheckScheduled = false;
  String? _lockedLessonTapLessonId;
  int _lockedLessonTapCount = 0;
  Timer? _lockedLessonTapResetTimer;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareWelcome());
  }

  @override
  void dispose() {
    _resetLockedLessonTapSequence();
    _learnerScrollController.dispose();
    _standaloneStatusController?.dispose();
    super.dispose();
  }

  LearnerStatusController _topBarController(BuildContext context) =>
      LearnerShell.maybeOf(context)?.controller ??
      (_standaloneStatusController ??= LearnerStatusController());

  Future<void> _prepareWelcome() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    _appVersion = info.version;
    await _showWelcome();
    if (mounted) await _showAlphaLifecycleNotice();
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
                'Version $_appVersion',
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

  Future<void> _showAlphaLifecycleNotice() async {
    if (!AlphaLifecycleService.isAlphaBuild || !mounted) return;
    if (AlphaLifecycleService.isExpired()) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Theme(
          data: _unifiedLearnerTheme(context),
          child: AlertDialog(
            title: const Text('Alpha expired'),
            content: Text(
              'This QuisquisLingo alpha expired on ${AlphaLifecycleService.expiryIsoDate}. Install a newer alpha to continue learning. Your local data has not been deleted, and Course Editor remains available.',
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
    final days = AlphaLifecycleService.daysRemaining();
    final message = days == 0
        ? 'This alpha expires today.'
        : days == 1
        ? 'This alpha expires tomorrow.'
        : 'This alpha expires in $days days.';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Theme(
        data: _unifiedLearnerTheme(context),
        child: AlertDialog(
          title: const Text('Alpha expiry'),
          content: Text(
            '$message Expiry date: ${AlphaLifecycleService.expiryIsoDate}. Install a newer QuisquisLingo alpha before then to continue learning. Updating does not intentionally delete learner data or course-authoring data.',
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
          title: const Text('Alpha expired'),
          content: Text(
            'This alpha expired on ${AlphaLifecycleService.expiryIsoDate}. Install a newer alpha to continue learning. Your local data is kept and Course Editor remains available.',
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

  Future<void> _reload() async {
    _resetLockedLessonTapSequence();
    try {
      final learners = await _profiles.getProfileRecords();
      final activeProfile = await _profiles.getActiveProfileRecord();
      final active = activeProfile?.displayName;
      final activeId = activeProfile?.learnerProfileId;
      var selectedRef = active == null
          ? _selectedCourseRef
          : (await _settings.getLastSelectedCourseCode() ?? 'IT');
      var selectedLanguage = _selectedLanguage;
      late Course course;
      if (selectedRef.startsWith('custom:')) {
        final courseId = selectedRef.substring('custom:'.length);
        final userCourses = await _courseEditorService.listUserCourses();
        final matches = userCourses
            .where((candidate) => candidate.courseId == courseId)
            .toList();
        if (matches.isNotEmpty) {
          course = matches.first;
          selectedRef = 'custom:${course.courseId}';
          selectedLanguage = CourseService.codeForCourse(course);
        } else {
          selectedRef = 'IT';
          selectedLanguage = 'IT';
          course = await _courseService.loadCourse(selectedLanguage);
          await _settings.setLastSelectedCourseCode(selectedRef);
        }
      } else {
        final bundledCode = CourseService.hasCourse(selectedRef)
            ? selectedRef
            : 'IT';
        selectedRef = bundledCode;
        selectedLanguage = bundledCode;
        course = await _courseService.loadCourse(bundledCode);
      }
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
      final iddqdMode = activeId == null
          ? false
          : await _settings.isIddqdModeEnabled(course.courseId);
      if (course.lessons.isNotEmpty &&
          !_lessonUnlocks.isLessonUnlocked(
            lessonIndex: activeLessonIndex,
            course: course,
            completedLessons: lessons,
            wonDuels: wonDuels,
          ) &&
          !iddqdMode) {
        activeLessonIndex = 0;
      }
      if (!mounted) return;
      final resetFlow =
          _flowCourseId != course.courseId || _flowLearner != activeId;
      setState(() {
        _course = course;
        _selectedCourseRef = selectedRef;
        _selectedLanguage = selectedLanguage;
        _learners = learners;
        _activeLearner = active;
        _activeLearnerId = activeId;
        _completedRounds = rounds;
        _completedLessons = lessons;
        _perfectRounds = perfect;
        _ttsSkippedPerfectRounds = skipped;
        _wonDuels = wonDuels;
        _iddqdMode = iddqdMode;
        _activeLessonIndex = activeLessonIndex;
        if (resetFlow) {
          _flowCourseId = course.courseId;
          _flowLearner = activeId;
        }
      });
      if (resetFlow) _scrollToLesson(course, activeLessonIndex);
    } on AppException catch (e) {
      if (mounted) await ErrorPresenter.show(context, e.error);
    } catch (e, st) {
      await DiagnosticLogService().log(
        AppErrorCode.unexpectedError,
        context: 'HomeScreen._reload',
        exception: e,
        stackTrace: st,
      );
      if (mounted) {
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
    try {
      final course = await _courseService.loadCourse(normalized);
      if (!mounted) return;
      setState(() {
        _selectedCourseRef = normalized;
        _selectedLanguage = normalized;
        _course = course;
      });
      await _settings.setLastSelectedCourseCode(normalized);
      await _reload();
    } on AppException catch (e) {
      if (mounted) await ErrorPresenter.show(context, e.error);
    }
  }

  Future<void> _switchCustomCourse(Course course) async {
    final ref = 'custom:${course.courseId}';
    final code = CourseService.codeForCourse(course);
    if (!mounted) return;
    setState(() {
      _selectedCourseRef = ref;
      _selectedLanguage = code;
      _course = course;
    });
    await _settings.setLastSelectedCourseCode(ref);
    await _reload();
  }

  Future<void> _addLearner(BuildContext overlayContext) async {
    if (_addingLearner) return;
    _addingLearner = true;
    final controller = TextEditingController();
    String skin = 'medium';
    String hair = 'dark';
    final result = await showDialog<(String, String, String)>(
      context: overlayContext,
      barrierDismissible: _learners.isNotEmpty,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(
            _learners.isEmpty ? 'Welcome to QuisquisLingo' : 'Create profile',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Avatar skin color'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('light', 'Light'),
                      ('medium', 'Medium'),
                      ('dark', 'Dark'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: skin == item.$1,
                        onSelected: (_) => setLocalState(() => skin = item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Avatar hair color'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('light', 'Light'),
                      ('dark', 'Dark'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: hair == item.$1,
                        onSelected: (_) => setLocalState(() => hair = item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    width: 72,
                    height: 82,
                    child: LearnerAvatar(skinTone: skin, hairTone: hair),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_learners.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) Navigator.pop(ctx, (name, skin, hair));
              },
              child: const Text('Create profile'),
            ),
          ],
        ),
      ),
    );
    // Let the dialog route finish disposing before changing profile-backed
    // inherited state. This avoids lifecycle assertions seen on Android after
    // creating a profile.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    controller.dispose();
    if (result != null) {
      if (mounted) setState(() => _course = null);
      await _profiles.addProfile(
        result.$1,
        skinTone: result.$2,
        hairTone: result.$3,
      );
      if (!mounted) {
        _addingLearner = false;
        return;
      }
      await _reload();
    }
    _addingLearner = false;
  }

  Future<void> _switchLearner(String learnerProfileId) async {
    if (mounted) setState(() => _course = null);
    await _profiles.setActiveProfileById(learnerProfileId);
    await _reload();
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
      await _profiles.deleteProfileById(profile.learnerProfileId);
      await _reload();
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
              const ListTile(title: Text('Learners')),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    ..._learners.map(
                      (profile) => FutureBuilder<ProfileAvatarAppearance?>(
                        future: _profiles.getAvatarAppearanceForProfile(
                          profile.learnerProfileId,
                        ),
                        builder: (context, snapshot) {
                          final appearance = snapshot.data;
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
                            title: Text(profile.displayName),
                            selected:
                                profile.learnerProfileId == _activeLearnerId,
                            onTap: () => Navigator.pop(
                              ctx,
                              'switch:${profile.learnerProfileId}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete learner',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => Navigator.pop(
                                ctx,
                                'delete:${profile.learnerProfileId}',
                              ),
                            ),
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
    final customCourses = await _courseEditorService.listUserCourses();
    final recentRefs = (await _settings.getRecentCourseRefs())
        .where(
          (ref) =>
              ref != _selectedCourseRef &&
              (CourseService.hasCourse(ref.trim().toUpperCase()) ||
                  (ref.startsWith('custom:') &&
                      customCourses.any(
                        (course) =>
                            course.courseId == ref.substring('custom:'.length),
                      ))),
        )
        .take(3)
        .toList();
    if (!mounted || !overlayContext.mounted) return;
    const codes = ['IT', 'DE', 'ES', 'EN', 'CY', 'NL', 'PT', 'FI'];
    Course? customCourseFor(String ref) {
      if (!ref.startsWith('custom:')) return null;
      final id = ref.substring('custom:'.length);
      for (final course in customCourses) {
        if (course.courseId == id) return course;
      }
      return null;
    }

    Widget recentCourseTile(BuildContext ctx, String ref) {
      final custom = customCourseFor(ref);
      if (custom != null) {
        return ListTile(
          leading: CourseFlagBadge(
            course: custom,
            fallbackCode: CourseService.codeForCourse(custom),
          ),
          title: Text(custom.title),
          subtitle: const Text('Custom course'),
          onTap: () {
            Navigator.pop(ctx);
            _switchCustomCourse(custom);
          },
        );
      }
      final code = ref.trim().toUpperCase();
      return ListTile(
        leading: FlagBadge(code),
        title: Text(CourseService.targetLabels[code] ?? code),
        subtitle: Text(
          '${CourseService.sourceLabels[code] ?? 'English'} → ${CourseService.targetLabels[code] ?? code}',
        ),
        onTap: CourseService.hasCourse(code)
            ? () {
                Navigator.pop(ctx);
                _switchCourse(code);
              }
            : null,
      );
    }

    await showModalBottomSheet<void>(
      context: overlayContext,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
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
                ListTile(
                  leading: CourseFlagBadge(
                    course: _course!,
                    fallbackCode: _selectedLanguage,
                  ),
                  title: Text(_course!.title),
                  trailing: const Icon(Icons.check),
                ),
              if (recentRefs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    'Recently opened',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final ref in recentRefs) recentCourseTile(ctx, ref),
              ],
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Text(
                  'All included courses',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              for (final code in codes)
                ListTile(
                  leading: FlagBadge(code),
                  title: Text(CourseService.targetLabels[code] ?? code),
                  subtitle: Text(
                    '${CourseService.sourceLabels[code] ?? 'English'} → ${CourseService.targetLabels[code] ?? code}${CourseService.hasCourse(code) ? '' : ' · Coming soon'}',
                  ),
                  trailing: _selectedCourseRef == code
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _switchCourse(code);
                  },
                ),
              if (customCourses.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    'My custom courses',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final course in customCourses)
                  ListTile(
                    leading: CourseFlagBadge(
                      course: course,
                      fallbackCode: CourseService.codeForCourse(course),
                    ),
                    title: Text(course.title),
                    subtitle: Text(
                      '${course.sourceLanguage} → ${course.targetLanguage} · Custom course',
                    ),
                    trailing: _selectedCourseRef == 'custom:${course.courseId}'
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _switchCustomCourse(course);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _canOpenLearnerContent() async {
    if (AlphaLifecycleService.isExpired()) {
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

  Future<void> _openGuidebook(Lesson lesson) async {
    _resetLockedLessonTapSequence();
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GuidebookScreen(lesson: lesson)));
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
          ttsLanguage: course.ttsLanguage,
          completeLessonOnFinish: true,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openDuel(Course course, Lesson lesson) async {
    final eligibility = _duelEligibility.evaluate(lesson);
    if (!eligibility.isAvailable) return;
    _resetLockedLessonTapSequence();
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          course: course,
          lesson: lesson,
          ttsLanguage: course.ttsLanguage,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openReview(Course course) async {
    _resetLockedLessonTapSequence();
    if (AlphaLifecycleService.isExpired()) {
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
    final flagBackgroundMode =
        LearnerFlagBackgroundModeScope.maybeModeOf(context) ??
        LearnerFlagBackgroundMode.small;
    final showsFlagBackground =
        flagBackgroundMode != LearnerFlagBackgroundMode.off;
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
                  if (showsFlagBackground) ...[
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
                              onCoursePressed: () =>
                                  _showCoursePicker(learnerContext),
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
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                      !_iddqdMode &&
                                      _sessionPreviewedLockedLessons.contains((
                                        courseId: course.courseId,
                                        lessonId: sectionLesson.lessonId,
                                      ));
                                  return _LessonSection(
                                    key: ValueKey(
                                      'unified-lesson-section-${sectionLesson.lessonId}',
                                    ),
                                    visibilityKey: _lessonSectionKey(
                                      course,
                                      sectionLesson,
                                    ),
                                    lesson: sectionLesson,
                                    courseId: course.courseId,
                                    lessonIndex: lessonIndex,
                                    mascotPositionOffset:
                                        learnerMascotPositionOffsetForLesson(
                                          course.lessons,
                                          lessonIndex,
                                        ),
                                    roundPositionOffset:
                                        learnerRoundPositionOffsetForLesson(
                                          course.lessons,
                                          lessonIndex,
                                        ),
                                    showBoundary: lessonIndex > 0,
                                    showSectionHeader: showSectionHeader,
                                    unlocked: unlocked,
                                    hasAccess:
                                        unlocked || _iddqdMode || previewOnly,
                                    previewOnly: previewOnly,
                                    completedRounds: _completedRounds,
                                    perfectRounds: _perfectRounds,
                                    ttsSkippedPerfectRounds:
                                        _ttsSkippedPerfectRounds,
                                    duelEligibility: _duelEligibility.evaluate(
                                      sectionLesson,
                                    ),
                                    onOpenGuidebook: () =>
                                        _openGuidebook(sectionLesson),
                                    onOpenRound: (round) => _openRound(
                                      course,
                                      sectionLesson,
                                      round,
                                    ),
                                    onOpenDuel: () =>
                                        _openDuel(course, sectionLesson),
                                    onLockedTap: unlocked || _iddqdMode
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: LearnerBottomActions(
                            key: const Key('unified-bottom-controls'),
                            onProfile: () async {
                              _resetLockedLessonTapSequence();
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(
                                    onManageLearners: _showLearners,
                                  ),
                                ),
                              );
                              await _reload();
                            },
                            onReview: () => _openReview(course),
                            iddqdEnabled: _iddqdMode,
                            onIddqdChanged: (value) async {
                              setState(() => _iddqdMode = value);
                              try {
                                await _settings.setIddqdModeEnabled(
                                  course.courseId,
                                  value,
                                );
                              } catch (_) {
                                if (mounted) {
                                  setState(() => _iddqdMode = !value);
                                }
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
  final String courseId;
  final int lessonIndex;
  final int mascotPositionOffset;
  final int roundPositionOffset;
  final bool showBoundary;
  final bool showSectionHeader;
  final bool unlocked;
  final bool hasAccess;
  final bool previewOnly;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final DuelEligibilityResult duelEligibility;
  final VoidCallback onOpenGuidebook;
  final void Function(LearningRound round) onOpenRound;
  final VoidCallback onOpenDuel;
  final VoidCallback? onLockedTap;

  const _LessonSection({
    super.key,
    required this.visibilityKey,
    required this.lesson,
    required this.courseId,
    required this.lessonIndex,
    required this.mascotPositionOffset,
    required this.roundPositionOffset,
    required this.showBoundary,
    required this.showSectionHeader,
    required this.unlocked,
    required this.hasAccess,
    required this.previewOnly,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.duelEligibility,
    required this.onOpenGuidebook,
    required this.onOpenRound,
    required this.onOpenDuel,
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
      if (previewOnly)
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
        lessonIndex: lessonIndex,
        unlocked: unlocked,
        onLockedTap: onLockedTap,
        onTap: hasAccess && !previewOnly ? onOpenGuidebook : null,
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
                  'Complete the previous Lesson or win its Duel to unlock this Lesson.',
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
      else ...[
        const _VerticalConnector(),
        LearnerRoundPath(
          courseId: courseId,
          rounds: lesson.rounds,
          completedRounds: completedRounds,
          perfectRounds: perfectRounds,
          ttsSkippedPerfectRounds: ttsSkippedPerfectRounds,
          mascotPositionOffset: mascotPositionOffset,
          roundPositionOffset: roundPositionOffset,
          interactive: !previewOnly,
          onOpenRound: onOpenRound,
        ),
        const _VerticalConnector(),
        _DuelCard(
          key: ValueKey('unified-duel-${lesson.lessonId}'),
          eligibility: duelEligibility,
          onTap: previewOnly ? null : onOpenDuel,
        ),
      ],
      const SizedBox(height: 16),
    ],
  );
}

class _GuidebookNode extends StatelessWidget {
  final Lesson lesson;
  final int lessonIndex;
  final bool unlocked;
  final VoidCallback? onLockedTap;
  final VoidCallback? onTap;

  const _GuidebookNode({
    required this.lesson,
    required this.lessonIndex,
    required this.unlocked,
    required this.onLockedTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FractionallySizedBox(
          widthFactor: learnerGuidebookWidthFactor,
          child: Card(
            key: const Key('unified-guidebook-node'),
            margin: EdgeInsets.zero,
            color:
                (isDark
                        ? colorScheme.surfaceContainerHigh
                        : const Color(0xFFFFF7C9))
                    .withValues(alpha: learnerGuidebookSurfaceOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark
                    ? colorScheme.outlineVariant
                    : const Color(0xFFF1C232),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          key: const Key('guidebook-lesson-icon-slot'),
                          width: 84,
                          height: 84,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: lesson.themeIconAsset == null
                                    ? CircleAvatar(
                                        radius: 42,
                                        backgroundColor: isDark
                                            ? const Color(0xFF30284B)
                                            : const Color(0xFFEDE2FF),
                                        child: const Icon(
                                          Icons.menu_book_outlined,
                                          size: 42,
                                        ),
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
                                    label: 'Locked Lesson ${lessonIndex + 1}',
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
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Lesson ${lessonIndex + 1}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: lesson.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              key: ValueKey(
                                'unified-guidebook-lesson-title-${lesson.lessonId}',
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey(
                            'unified-guidebook-action-${lesson.lessonId}',
                          ),
                          tooltip: 'GuideBook',
                          onPressed: onTap,
                          color: isDark ? Colors.white : Colors.black87,
                          icon: const Icon(Icons.menu_book_outlined, size: 24),
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
      ),
    ),
  );
}

const learnerMascotAssetDirectory = 'assets/mascots/';

List<String> learnerMascotAssetsFromManifest(Iterable<String> assets) {
  final mascots = assets
      .where(
        (asset) =>
            asset.startsWith(learnerMascotAssetDirectory) &&
            asset.toLowerCase().endsWith('.png'),
      )
      .toSet()
      .toList();
  mascots.sort();
  return mascots;
}

Future<List<String>> loadLearnerMascotAssets(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  return loadRenderableLearnerMascotAssets(bundle, manifest.listAssets());
}

Future<List<String>>? _productionLearnerMascotAssetsFuture;

Future<List<String>> loadProductionLearnerMascotAssets() =>
    _productionLearnerMascotAssetsFuture ??= loadLearnerMascotAssets(
      rootBundle,
    );

Future<List<String>> loadRenderableLearnerMascotAssets(
  AssetBundle bundle,
  Iterable<String> assets,
) async {
  final renderable = <String>[];
  for (final asset in learnerMascotAssetsFromManifest(assets)) {
    ui.Codec? codec;
    ui.Image? image;
    try {
      final data = await bundle.load(asset);
      codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 1,
        targetHeight: 1,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      renderable.add(asset);
    } catch (_) {
      // An invalid mascot leaves no slot and never enters the selection cycle.
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
  return renderable;
}

enum LearnerRoundPathSide { left, right }

LearnerRoundPathSide learnerRoundPathSide(int index) {
  const pattern = <LearnerRoundPathSide>[
    LearnerRoundPathSide.right,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.right,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.right,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.right,
    LearnerRoundPathSide.right,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.left,
    LearnerRoundPathSide.right,
  ];
  return pattern[index % pattern.length];
}

bool learnerRoundPathShowsMascot(int index, {int roundPositionOffset = 0}) {
  const positions = <int>{0, 3, 5, 8};
  return positions.contains((roundPositionOffset + index) % 10);
}

int learnerRoundPathMascotSlotCount(
  int roundCount, {
  int roundPositionOffset = 0,
}) {
  var count = 0;
  for (var index = 0; index < roundCount; index++) {
    if (learnerRoundPathShowsMascot(
      index,
      roundPositionOffset: roundPositionOffset,
    )) {
      count++;
    }
  }
  return count;
}

int learnerRoundPositionOffsetForLesson(
  List<Lesson> lessons,
  int lessonIndex,
) => lessons
    .take(lessonIndex)
    .fold(0, (total, lesson) => total + lesson.rounds.length);

int learnerMascotPositionOffsetForLesson(
  List<Lesson> lessons,
  int lessonIndex,
) => learnerRoundPathMascotSlotCount(
  learnerRoundPositionOffsetForLesson(lessons, lessonIndex),
);

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
  final List<LearningRound> rounds;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final void Function(LearningRound round) onOpenRound;
  final List<String>? mascotAssets;
  final int mascotPositionOffset;
  final int roundPositionOffset;
  final bool interactive;

  const LearnerRoundPath({
    super.key,
    required this.courseId,
    required this.rounds,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
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
        final width = constraints.maxWidth;
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
        final mascotExtent = min(112.0, width - cardWidth - 12);
        final sides = List<LearnerRoundPathSide>.generate(
          widget.rounds.length,
          learnerRoundPathSide,
          growable: false,
        );
        final courseMascots = learnerCourseMascotOrder(
          widget.courseId,
          mascotAssets,
        );
        var mascotPosition = widget.mascotPositionOffset;
        return SizedBox(
          key: const Key('unified-round-tree'),
          height: rowExtent * widget.rounds.length - verticalGap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const Key('learner-round-connector'),
                    painter: _RoundPathPainter(
                      sides: sides,
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      rowExtent: rowExtent,
                      lineColor: Theme.of(context).colorScheme.onSurfaceVariant
                          .withValues(alpha: learnerPathConnectorOpacity),
                      supportColor: Theme.of(context).colorScheme.surface
                          .withValues(
                            alpha: learnerPathConnectorSupportOpacity,
                          ),
                    ),
                  ),
                ),
              ),
              if (showMascots)
                for (var index = 0; index < widget.rounds.length; index++)
                  if (learnerRoundPathShowsMascot(
                    index,
                    roundPositionOffset: widget.roundPositionOffset,
                  ))
                    Positioned(
                      key: ValueKey('learner-round-mascot-$index'),
                      top: index * rowExtent + (cardHeight - mascotExtent) / 2,
                      left: sides[index] == LearnerRoundPathSide.right
                          ? 0
                          : null,
                      right: sides[index] == LearnerRoundPathSide.left
                          ? 0
                          : null,
                      width: mascotExtent,
                      height: mascotExtent,
                      child: _MascotDecoration(
                        asset: learnerMascotAssetAtPosition(
                          courseMascots,
                          mascotPosition++,
                        ),
                      ),
                    ),
              for (var index = 0; index < widget.rounds.length; index++)
                Positioned(
                  key: ValueKey('learner-round-row-$index'),
                  top: index * rowExtent,
                  left: sides[index] == LearnerRoundPathSide.left ? 0 : null,
                  right: sides[index] == LearnerRoundPathSide.right ? 0 : null,
                  width: cardWidth,
                  height: cardHeight,
                  child: _RoundNode(
                    round: widget.rounds[index],
                    roundNumber: index + 1,
                    completed: widget.completedRounds.contains(
                      widget.rounds[index].id,
                    ),
                    perfect: widget.perfectRounds.contains(
                      widget.rounds[index].id,
                    ),
                    ttsSkippedPerfect: widget.ttsSkippedPerfectRounds.contains(
                      widget.rounds[index].id,
                    ),
                    onTap: widget.interactive
                        ? () => widget.onOpenRound(widget.rounds[index])
                        : null,
                  ),
                ),
            ],
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
  final int roundNumber;
  final bool completed;
  final bool perfect;
  final bool ttsSkippedPerfect;
  final VoidCallback? onTap;

  const _RoundNode({
    required this.round,
    required this.roundNumber,
    required this.completed,
    required this.perfect,
    required this.ttsSkippedPerfect,
    required this.onTap,
  });

  IconData get _visualIcon => switch (round.visualType) {
    'listening' => Icons.headphones_outlined,
    'story' => Icons.auto_stories_outlined,
    'test' => Icons.fact_check_outlined,
    _ => Icons.school_outlined,
  };

  bool get _needsAudio => round.exercises.any(
    (exercise) =>
        (exercise.tts?.trim().isNotEmpty ?? false) ||
        const {
          'audio_match',
          'listening_choice',
          'listening_comprehension',
          'listening_spelling',
          'missing_word',
        }.contains(exercise.type),
  );

  bool get _hasDescriptiveTitle {
    final title = round.title.trim();
    return title.isNotEmpty &&
        !RegExp(
          r'^(round|ronda)\s+\d+$',
          caseSensitive: false,
        ).hasMatch(title);
  }

  String get _status => perfect
      ? 'Perfect'
      : completed || ttsSkippedPerfect
      ? 'Practice'
      : 'Learn';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = perfect
        ? (isDark ? const Color(0xFF72DC86) : const Color(0xFF16862E))
        : completed || ttsSkippedPerfect
        ? (isDark ? const Color(0xFFFF9B7A) : const Color(0xFFD74B20))
        : (isDark ? const Color(0xFF8DB8FF) : const Color(0xFF1657D9));
    return Card(
      key: ValueKey('unified-round-${round.id}'),
      margin: EdgeInsets.zero,
      color:
          (isDark ? colorScheme.surfaceContainerHigh : const Color(0xFFFFF8D6))
              .withValues(alpha: learnerPathSurfaceOpacity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? colorScheme.outlineVariant : const Color(0xFFF1C232),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                key: perfect
                    ? ValueKey('unified-round-laurel-${round.id}')
                    : null,
                width: perfect ? 72 : 56,
                height: perfect ? 66 : 54,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (perfect) ...[
                      Positioned(
                        left: 3,
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
                        right: 3,
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: perfect
                            ? (isDark
                                  ? const Color(0xFF4CD964)
                                  : const Color(0xFF34C759))
                            : completed
                            ? (isDark
                                  ? const Color(0xFFFFB62E)
                                  : const Color(0xFFFFB000))
                            : isDark
                            ? const Color(0xFF3A3425)
                            : const Color(0xFFFFEBC0),
                      ),
                      child: Icon(
                        _visualIcon,
                        size: 28,
                        color: perfect ? const Color(0xFF082A10) : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round $roundNumber',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (_hasDescriptiveTitle)
                      Text(
                        round.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    Text(
                      _status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (_needsAudio)
                Icon(
                  Icons.volume_up_outlined,
                  color: isDark
                      ? const Color(0xFF8DB8FF)
                      : const Color(0xFF1657D9),
                ),
            ],
          ),
        ),
      ),
    );
  }
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

class _RoundPathPainter extends CustomPainter {
  final List<LearnerRoundPathSide> sides;
  final double cardWidth;
  final double cardHeight;
  final double rowExtent;
  final Color lineColor;
  final Color supportColor;

  const _RoundPathPainter({
    required this.sides,
    required this.cardWidth,
    required this.cardHeight,
    required this.rowExtent,
    required this.lineColor,
    required this.supportColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sides.isEmpty || size.height <= 0) return;
    final supportPaint = Paint()
      ..color = supportColor
      ..strokeWidth = learnerPathConnectorSupportStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = learnerPathConnectorStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final points = <Offset>[
      for (var index = 0; index < sides.length; index++)
        Offset(
          sides[index] == LearnerRoundPathSide.left
              ? cardWidth / 2
              : size.width - cardWidth / 2,
          index * rowExtent + cardHeight / 2,
        ),
    ];
    final path = Path()..moveTo(size.width / 2, 0);
    var previous = Offset(size.width / 2, 0);
    for (final point in points) {
      final middleY = (previous.dy + point.dy) / 2;
      path.cubicTo(previous.dx, middleY, point.dx, middleY, point.dx, point.dy);
      previous = point;
    }
    final middleY = (previous.dy + size.height) / 2;
    path.cubicTo(
      previous.dx,
      middleY,
      size.width / 2,
      middleY,
      size.width / 2,
      size.height,
    );
    canvas.drawPath(path, supportPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundPathPainter oldDelegate) =>
      oldDelegate.sides != sides ||
      oldDelegate.cardWidth != cardWidth ||
      oldDelegate.cardHeight != cardHeight ||
      oldDelegate.rowExtent != rowExtent ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.supportColor != supportColor;
}

class _DuelCard extends StatelessWidget {
  final DuelEligibilityResult eligibility;
  final VoidCallback? onTap;

  const _DuelCard({super.key, required this.eligibility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FractionallySizedBox(
          widthFactor: .88,
          child: Card(
            key: const Key('unified-duel-card'),
            margin: EdgeInsets.zero,
            color:
                (eligibility.isAvailable
                        ? const Color(0xFF0756DF)
                        : colorScheme.surfaceContainerHighest)
                    .withValues(alpha: learnerDuelSurfaceOpacity),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: eligibility.isAvailable ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_martial_arts_outlined,
                      size: 40,
                      color: eligibility.isAvailable ? Colors.white : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duel',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: eligibility.isAvailable
                                      ? Colors.white
                                      : null,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            eligibility.isAvailable
                                ? 'Win to skip ahead'
                                : 'Unavailable for this Lesson: not enough suitable exercises.',
                            style: TextStyle(
                              color: eligibility.isAvailable
                                  ? const Color(0xFFFFE600)
                                  : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (eligibility.isAvailable)
                      const Icon(Icons.chevron_right, color: Colors.white),
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

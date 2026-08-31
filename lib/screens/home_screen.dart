import 'dart:async';
import 'dart:math';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/learner_status_controller.dart';
import '../services/settings_service.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/course_editor_service.dart';
import '../services/duel_eligibility_service.dart';
import '../services/progress_service.dart';
import '../services/profile_service.dart';
import '../services/status_service.dart';
import '../services/topic_unlock_service.dart';
import '../services/alpha_lifecycle_service.dart';
import '../services/app_errors.dart';
import '../services/error_presenter.dart';
import '../services/diagnostic_log_service.dart';
import '../services/crash_log_service.dart';
import 'settings_screen.dart';
import 'review_screen.dart';
import 'course_info_screen.dart';
import 'duel_screen.dart';
import 'gamification_settings_screen.dart';
import 'guidebook_screen.dart';
import 'info_screen.dart';
import 'round_screen.dart';
import '../widgets/flag_art.dart';
import '../widgets/learner_shell.dart';
import '../widgets/unified_learner_top_bar.dart';

const _learnerLightPageBackground = Color(0xFFF7F3E8);
const _learnerDarkPageBackground = Color(0xFF080B09);
const _welcomeDialogBackground = Color(0xFFFFE600);
const _welcomeDialogForeground = Color(0xFF0756DF);
const learnerPathSurfaceOpacity = .75;
const learnerPathConnectorOpacity = .5;
const learnerPathConnectorStrokeWidth = 2.0;
const learnerDarkFlagVeilOpacity = .18;

ThemeData _unifiedLearnerTheme(BuildContext context) {
  if (MediaQuery.platformBrightnessOf(context) != Brightness.dark) {
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
  final _topicUnlocks = const TopicUnlockService();
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
  bool _addingLearner = false;
  List<String> _learners = [];
  Course? _course;
  Set<String> _completedRounds = {};
  Set<String> _completedTopics = {};
  Set<String> _perfectRounds = {};
  Set<String> _ttsSkippedPerfectRounds = {};
  Set<String> _wonDuels = {};
  bool _iddqdMode = false;
  String _selectedLanguage = 'IT';
  String _selectedCourseRef = 'IT';
  int _activeTopicIndex = 0;
  String? _flowCourseId;
  String? _flowLearner;
  int? _lessonScrollTargetIndex;
  int _lessonScrollTargetAttempts = 0;
  bool _lessonVisibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareWelcome());
  }

  @override
  void dispose() {
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
    try {
      var selectedRef = _course == null
          ? (await _settings.getLastSelectedCourseCode() ?? _selectedCourseRef)
          : _selectedCourseRef;
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
      final learners = await _profiles.getProfiles();
      final active = await _profiles.getActiveProfile();
      final savedTopicId = await _settings.getLastVisitedTopicId(
        course.courseId,
      );
      var activeTopicIndex = course.topics.indexWhere(
        (topic) => topic.id == savedTopicId,
      );
      if (activeTopicIndex < 0) activeTopicIndex = 0;
      final rounds = await _progress.getCompletedRounds(
        courseId: course.courseId,
      );
      final topics = await _progress.getCompletedTopics(
        courseId: course.courseId,
      );
      final perfect = await _progress.getPerfectRounds(
        courseId: course.courseId,
      );
      final skipped = await _progress.getTtsSkippedPerfectRounds(
        courseId: course.courseId,
      );
      final wonDuels = await _progress.getWonDuels(courseId: course.courseId);
      final iddqdMode = await _settings.isIddqdModeEnabled(course.courseId);
      if (course.topics.isNotEmpty &&
          !_topicUnlocks.isTopicUnlocked(
            topicIndex: activeTopicIndex,
            course: course,
            completedTopics: topics,
            wonDuels: wonDuels,
          ) &&
          !iddqdMode) {
        activeTopicIndex = 0;
      }
      if (!mounted) return;
      final resetFlow =
          _flowCourseId != course.courseId || _flowLearner != active;
      setState(() {
        _course = course;
        _selectedCourseRef = selectedRef;
        _selectedLanguage = selectedLanguage;
        _learners = learners;
        _activeLearner = active;
        _completedRounds = rounds;
        _completedTopics = topics;
        _perfectRounds = perfect;
        _ttsSkippedPerfectRounds = skipped;
        _wonDuels = wonDuels;
        _iddqdMode = iddqdMode;
        _activeTopicIndex = activeTopicIndex;
        if (resetFlow) {
          _flowCourseId = course.courseId;
          _flowLearner = active;
        }
      });
      if (resetFlow) _scrollToTopic(course, activeTopicIndex);
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
                    child: CustomPaint(
                      painter: _StatusAvatarPainter(0, skin, hair),
                    ),
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

  Future<void> _switchLearner(String name) async {
    await _profiles.setActiveProfile(name);
    await _reload();
  }

  Future<void> _deleteLearner(String name, BuildContext overlayContext) async {
    final ok = await showDialog<bool>(
      context: overlayContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete learner?'),
        content: Text('Delete $name and all local progress for this learner?'),
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
      await _profiles.deleteProfile(name);
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
                      (n) => ListTile(
                        leading: Icon(
                          n == _activeLearner
                              ? Icons.check_circle
                              : Icons.person_outline,
                        ),
                        title: Text(n),
                        onTap: () => Navigator.pop(ctx, 'switch:$n'),
                        trailing: IconButton(
                          tooltip: 'Delete learner',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => Navigator.pop(ctx, 'delete:$n'),
                        ),
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
      await _deleteLearner(action.substring(7), overlayContext);
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

  bool _isTopicUnlocked(Course course, int index) =>
      _topicUnlocks.isTopicUnlocked(
        topicIndex: index,
        course: course,
        completedTopics: _completedTopics,
        wonDuels: _wonDuels,
      );

  Future<void> _selectTopic(Course course, int index) async {
    if (index < 0 || index >= course.topics.length) return;
    await _settings.setLastVisitedTopicId(
      course.courseId,
      course.topics[index].id,
    );
    if (!mounted) return;
    setState(() => _activeTopicIndex = index);
    _scrollToTopic(course, index);
  }

  void _scrollToTopic(Course course, int index) {
    if (index < 0 || index >= course.topics.length) return;
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
      course.topics[index],
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
      for (var builtIndex = 0; builtIndex < course.topics.length; builtIndex++)
        if (_lessonSectionKey(
              course,
              course.topics[builtIndex],
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

  GlobalKey _lessonSectionKey(Course course, Topic topic) => _lessonSectionKeys
      .putIfAbsent('${course.courseId}:${topic.id}', () => GlobalKey());

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
        course.topics.isEmpty) {
      return;
    }
    final position = _learnerScrollController.position;
    final viewportStart = position.pixels;
    final viewportEnd = viewportStart + position.viewportDimension;
    var candidateIndex = _activeTopicIndex;
    var candidateVisibleExtent = 0.0;
    var activeVisibleExtent = 0.0;

    for (var index = 0; index < course.topics.length; index++) {
      final context = _lessonSectionKey(
        course,
        course.topics[index],
      ).currentContext;
      final renderBox = context?.findRenderObject();
      if (renderBox is! RenderBox || !renderBox.attached) continue;
      final viewport = RenderAbstractViewport.of(renderBox);
      final sectionStart = viewport.getOffsetToReveal(renderBox, 0).offset;
      final sectionEnd = sectionStart + renderBox.size.height;
      final visibleExtent =
          min(sectionEnd, viewportEnd) - max(sectionStart, viewportStart);
      final clampedVisibleExtent = max(0.0, visibleExtent);
      if (index == _activeTopicIndex) {
        activeVisibleExtent = clampedVisibleExtent;
      }
      if (clampedVisibleExtent > candidateVisibleExtent) {
        candidateIndex = index;
        candidateVisibleExtent = clampedVisibleExtent;
      }
    }

    if (candidateIndex == _activeTopicIndex || candidateVisibleExtent <= 0) {
      return;
    }
    final hysteresis = position.viewportDimension * .1;
    if (activeVisibleExtent > 0 &&
        candidateVisibleExtent < activeVisibleExtent + hysteresis) {
      return;
    }
    setState(() => _activeTopicIndex = candidateIndex);
    unawaited(
      _settings.setLastVisitedTopicId(
        course.courseId,
        course.topics[candidateIndex].id,
      ),
    );
  }

  Future<void> _showLessonPicker(
    Course course,
    BuildContext overlayContext,
  ) async {
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
                  itemCount: course.topics.length,
                  itemBuilder: (context, index) {
                    final topic = course.topics[index];
                    final unlocked = _isTopicUnlocked(course, index);
                    final completed = _completedTopics.contains(topic.id);
                    return ListTile(
                      leading: Icon(
                        !unlocked
                            ? Icons.lock_outline
                            : completed
                            ? Icons.check_circle_outline
                            : Icons.school_outlined,
                      ),
                      title: Text('Lesson ${index + 1}: ${topic.title}'),
                      subtitle: Text(
                        !unlocked
                            ? _iddqdMode
                                  ? completed
                                        ? 'Completed · Locked · IDDQD access'
                                        : 'Locked · IDDQD access'
                                  : completed
                                  ? 'Completed · Locked'
                                  : 'Locked'
                            : completed
                            ? 'Completed'
                            : '${topic.rounds.length} Rounds',
                      ),
                      trailing: index == _activeTopicIndex
                          ? const Icon(Icons.check)
                          : null,
                      onTap: unlocked || _iddqdMode
                          ? () => Navigator.pop(ctx, index)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) await _selectTopic(course, selected);
  }

  Future<void> _openGuidebook(Topic topic) async {
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GuidebookScreen(topic: topic)));
  }

  Future<void> _openRound(
    Course course,
    Topic topic,
    LearningRound round,
  ) async {
    if (!await _canOpenLearnerContent() || !mounted) return;
    await CrashLogService.instance.recordDebugEvent(
      'Home: opening Round ${round.id} in Topic ${topic.id}',
    );
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: course,
          topic: topic,
          round: round,
          roundIndex: topic.rounds.indexOf(round),
          ttsLanguage: course.ttsLanguage,
          completeTopicOnFinish: true,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openDuel(Course course, Topic topic) async {
    final eligibility = _duelEligibility.evaluate(topic);
    if (!eligibility.isAvailable) return;
    if (!await _canOpenLearnerContent() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          course: course,
          topic: topic,
          ttsLanguage: course.ttsLanguage,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _buyCoffee(Course course) async {
    final uri = Uri.tryParse(course.supportUrl.trim());
    if (uri == null || uri.scheme != 'https') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This course does not provide an author support link.'),
        ),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The author support link could not open.'),
        ),
      );
    }
  }

  Future<void> _openReview(Course course) async {
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
    final followsDarkAppearance =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
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
    final topic = course.topics.isEmpty
        ? null
        : course.topics[_activeTopicIndex.clamp(0, course.topics.length - 1)];
    final pageBackground = followsDarkAppearance
        ? _learnerDarkPageBackground
        : _learnerLightPageBackground;
    final learnerTheme = _unifiedLearnerTheme(context);
    return Theme(
      data: learnerTheme,
      child: Builder(
        builder: (learnerContext) {
          if (_activeLearner == null && !_addingLearner) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  learnerContext.mounted &&
                  _activeLearner == null &&
                  !_addingLearner) {
                _addLearner(learnerContext);
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
                  CourseFlagBackdrop(
                    key: const Key('unified-learner-flag-background'),
                    course: course,
                    fallbackCode: _selectedLanguage,
                    opacity: 1,
                  ),
                  if (followsDarkAppearance)
                    ColoredBox(
                      key: const Key('unified-learner-dark-veil'),
                      color: learnerTheme.colorScheme.surface.withValues(
                        alpha: learnerDarkFlagVeilOpacity,
                      ),
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
                              onCoursePressed: () =>
                                  _showCoursePicker(learnerContext),
                              onLogoPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InfoScreen(),
                                ),
                              ),
                              onSettingsPressed: () async {
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                10,
                              ),
                              child: topic == null
                                  ? const SizedBox.shrink()
                                  : _LessonNavigation(
                                      topic: topic,
                                      topicIndex: _activeTopicIndex,
                                      roundCount: topic.rounds.length,
                                      completedRoundCount: topic.rounds
                                          .where(
                                            (round) => _completedRounds
                                                .contains(round.id),
                                          )
                                          .length,
                                      onPrevious: _activeTopicIndex > 0
                                          ? () => _selectTopic(
                                              course,
                                              _activeTopicIndex - 1,
                                            )
                                          : null,
                                      onNext:
                                          _activeTopicIndex + 1 <
                                              course.topics.length
                                          ? () => _selectTopic(
                                              course,
                                              _activeTopicIndex + 1,
                                            )
                                          : null,
                                      onBrowse: () => _showLessonPicker(
                                        course,
                                        learnerContext,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _reload,
                            child: NotificationListener<ScrollEndNotification>(
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
                                  112,
                                ),
                                itemCount: course.topics.isEmpty
                                    ? 1
                                    : course.topics.length,
                                itemBuilder: (context, flowIndex) {
                                  if (course.topics.isEmpty) {
                                    return const _EmptyCourseCard();
                                  }
                                  final topicIndex = flowIndex;
                                  final sectionTopic =
                                      course.topics[topicIndex];
                                  final unlocked = _isTopicUnlocked(
                                    course,
                                    topicIndex,
                                  );
                                  return _LessonSection(
                                    key: ValueKey(
                                      'unified-lesson-section-${sectionTopic.id}',
                                    ),
                                    visibilityKey: _lessonSectionKey(
                                      course,
                                      sectionTopic,
                                    ),
                                    topic: sectionTopic,
                                    courseId: course.courseId,
                                    topicIndex: topicIndex,
                                    showBoundary: topicIndex > 0,
                                    unlocked: unlocked,
                                    hasAccess: unlocked || _iddqdMode,
                                    completedRounds: _completedRounds,
                                    perfectRounds: _perfectRounds,
                                    ttsSkippedPerfectRounds:
                                        _ttsSkippedPerfectRounds,
                                    duelEligibility: _duelEligibility.evaluate(
                                      sectionTopic,
                                    ),
                                    onOpenGuidebook: () =>
                                        _openGuidebook(sectionTopic),
                                    onOpenRound: (round) =>
                                        _openRound(course, sectionTopic, round),
                                    onOpenDuel: () =>
                                        _openDuel(course, sectionTopic),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: SafeArea(
                      top: false,
                      child: _QuickActions(
                        key: const Key('unified-bottom-controls'),
                        onLeaderboard: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const GamificationSettingsScreen(),
                            ),
                          );
                          await _reload();
                        },
                        onReview: () => _openReview(course),
                        onCoffee: () => _buyCoffee(course),
                        onCourseInfo: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CourseInfoScreen(course: course),
                          ),
                        ),
                      ),
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

class _LessonNavigation extends StatelessWidget {
  final Topic topic;
  final int topicIndex;
  final int roundCount;
  final int completedRoundCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBrowse;

  const _LessonNavigation({
    required this.topic,
    required this.topicIndex,
    required this.roundCount,
    required this.completedRoundCount,
    required this.onPrevious,
    required this.onNext,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          key: const Key('unified-lesson-selector'),
          onPressed: onBrowse,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: .5)
                : Colors.white.withValues(alpha: .5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous Lesson',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson ${topicIndex + 1}: ${topic.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    Text(
                      '$completedRoundCount/$roundCount Rounds completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next Lesson',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _LessonSection extends StatelessWidget {
  final GlobalKey visibilityKey;
  final Topic topic;
  final String courseId;
  final int topicIndex;
  final bool showBoundary;
  final bool unlocked;
  final bool hasAccess;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final DuelEligibilityResult duelEligibility;
  final VoidCallback onOpenGuidebook;
  final void Function(LearningRound round) onOpenRound;
  final VoidCallback onOpenDuel;

  const _LessonSection({
    super.key,
    required this.visibilityKey,
    required this.topic,
    required this.courseId,
    required this.topicIndex,
    required this.showBoundary,
    required this.unlocked,
    required this.hasAccess,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.duelEligibility,
    required this.onOpenGuidebook,
    required this.onOpenRound,
    required this.onOpenDuel,
  });

  @override
  Widget build(BuildContext context) => Column(
    key: visibilityKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showBoundary) ...[
        const SizedBox(height: 20),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
          child: Semantics(
            header: true,
            child: Row(
              children: [
                Icon(unlocked ? Icons.school_outlined : Icons.lock_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: _FlagBackdropText(
                    'Lesson ${topicIndex + 1}: ${topic.title}',
                    key: ValueKey('flag-backdrop-lesson-title-${topic.id}'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      if (!hasAccess)
        Padding(
          key: ValueKey('unified-lesson-locked-${topic.id}'),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 12),
              Flexible(
                child: _FlagBackdropText(
                  'Complete the previous Lesson or win its Duel to unlock this Lesson.',
                  key: ValueKey('flag-backdrop-locked-message-${topic.id}'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        )
      else ...[
        _GuidebookNode(topic: topic, onTap: onOpenGuidebook),
        const _VerticalConnector(),
        LearnerRoundPath(
          courseId: courseId,
          rounds: topic.rounds,
          completedRounds: completedRounds,
          perfectRounds: perfectRounds,
          ttsSkippedPerfectRounds: ttsSkippedPerfectRounds,
          onOpenRound: onOpenRound,
        ),
        const _VerticalConnector(),
        _DuelCard(
          key: ValueKey('unified-duel-${topic.id}'),
          eligibility: duelEligibility,
          onTap: onOpenDuel,
        ),
      ],
      const SizedBox(height: 16),
    ],
  );
}

class _GuidebookNode extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const _GuidebookNode({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FractionallySizedBox(
          widthFactor: .88,
          child: Card(
            key: const Key('unified-guidebook-node'),
            margin: EdgeInsets.zero,
            color:
                (isDark
                        ? colorScheme.surfaceContainerHigh
                        : const Color(0xFFFFF7C9))
                    .withValues(alpha: learnerPathSurfaceOpacity),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isDark
                          ? const Color(0xFF30284B)
                          : const Color(0xFFEDE2FF),
                      child: const Icon(Icons.menu_book_outlined, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GuideBook',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFFC7B8FF)
                                      : const Color(0xFF3920C8),
                                ),
                          ),
                          Text(
                            'Your roadmap to ${topic.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Start here',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8FB0FF)
                                  : const Color(0xFF154FE7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
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
  return learnerMascotAssetsFromManifest(manifest.listAssets());
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

bool learnerRoundPathShowsMascot(int index) {
  const positions = <int>{0, 3, 6, 8};
  return positions.contains(index % 10);
}

List<String> learnerCourseMascotOrder(
  String courseId,
  List<String> mascotAssets,
) {
  final ordered = mascotAssets.toSet().toList(growable: false);
  if (ordered.length < 2) return ordered;
  var state = 0x811C9DC5;
  for (final codeUnit in courseId.codeUnits) {
    state ^= codeUnit;
    state = (state * 0x01000193) & 0x7FFFFFFF;
  }
  for (var index = ordered.length - 1; index > 0; index--) {
    state = (state * 1664525 + 1013904223) & 0x7FFFFFFF;
    final swapIndex = state % (index + 1);
    final value = ordered[index];
    ordered[index] = ordered[swapIndex];
    ordered[swapIndex] = value;
  }
  return ordered;
}

class LearnerRoundPath extends StatefulWidget {
  final String courseId;
  final List<LearningRound> rounds;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final void Function(LearningRound round) onOpenRound;
  final List<String>? mascotAssets;

  const LearnerRoundPath({
    super.key,
    required this.courseId,
    required this.rounds,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.onOpenRound,
    this.mascotAssets,
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
      _mascotAssetsFuture = loadLearnerMascotAssets(rootBundle);
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
        final cardHeight = 108.0 + (textScale - 1.0).clamp(0.0, 2.0) * 72.0;
        const verticalGap = 28.0;
        final rowExtent = cardHeight + verticalGap;
        final showMascots = width >= 280 && mascotAssets.isNotEmpty;
        final cardWidth = min(
          width,
          max(196.0, min(276.0, width * (showMascots ? .68 : .82))),
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
        var mascotPosition = 0;
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
                    ),
                  ),
                ),
              ),
              if (showMascots)
                for (var index = 0; index < widget.rounds.length; index++)
                  if (learnerRoundPathShowsMascot(index))
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
                        asset:
                            courseMascots[mascotPosition++ %
                                courseMascots.length],
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
                    onTap: () => widget.onOpenRound(widget.rounds[index]),
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
                    .withValues(alpha: .5),
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
  final VoidCallback onTap;

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

  bool get _hasDescriptiveTitle => !RegExp(
    r'^(round|ronda)\s+\d+$',
    caseSensitive: false,
  ).hasMatch(round.title.trim());

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
                width: 56,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (perfect) ...[
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Icon(Icons.eco, size: 34, color: statusColor),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Transform.flip(
                          flipX: true,
                          child: Icon(Icons.eco, size: 34, color: statusColor),
                        ),
                      ),
                    ],
                    Container(
                      key: ValueKey('unified-round-icon-${round.id}'),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? (isDark
                                  ? const Color(0xFFFFB62E)
                                  : const Color(0xFFFFB000))
                            : isDark
                            ? const Color(0xFF3A3425)
                            : const Color(0xFFFFEBC0),
                      ),
                      child: Icon(_visualIcon, size: 28),
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

class _RoundPathPainter extends CustomPainter {
  final List<LearnerRoundPathSide> sides;
  final double cardWidth;
  final double cardHeight;
  final double rowExtent;
  final Color lineColor;

  const _RoundPathPainter({
    required this.sides,
    required this.cardWidth,
    required this.cardHeight,
    required this.rowExtent,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sides.isEmpty || size.height <= 0) return;
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundPathPainter oldDelegate) =>
      oldDelegate.sides != sides ||
      oldDelegate.cardWidth != cardWidth ||
      oldDelegate.cardHeight != cardHeight ||
      oldDelegate.rowExtent != rowExtent ||
      oldDelegate.lineColor != lineColor;
}

class _DuelCard extends StatelessWidget {
  final DuelEligibilityResult eligibility;
  final VoidCallback onTap;

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
                    .withValues(alpha: learnerPathSurfaceOpacity),
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
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.none,
      children: [
        ExcludeSemantics(
          child: Text(
            data,
            style: effectiveStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = outlineColor,
            ),
          ),
        ),
        Text(data, style: effectiveStyle),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onLeaderboard, onReview, onCoffee, onCourseInfo;
  const _QuickActions({
    super.key,
    required this.onLeaderboard,
    required this.onReview,
    required this.onCoffee,
    required this.onCourseInfo,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.emoji_events_outlined,
            label: 'Leaderboard',
            onTap: onLeaderboard,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickAction(
            icon: Icons.history_edu_outlined,
            label: 'Review',
            onTap: onReview,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickAction(
            icon: Icons.coffee_outlined,
            label: 'Buy a coffee',
            onTap: onCoffee,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickAction(
            icon: Icons.info_outline,
            label: 'Course Info',
            onTap: onCourseInfo,
          ),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: .72)
          : Colors.white.withValues(alpha: .34),
      borderRadius: BorderRadius.circular(18),
      child: Semantics(
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? const Color(0xFF9AD5B3) : const Color(0xFF3D704F),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small medieval avatar. One painter covers all Status ranks and the six profile
/// appearance combinations, avoiding 60 near-identical bitmap assets.
class _StatusAvatarPainter extends CustomPainter {
  final int level;
  final String skin, hair;
  const _StatusAvatarPainter(this.level, this.skin, this.hair);
  @override
  void paint(Canvas c, Size s) {
    final skinColor =
        {
          'light': const Color(0xFFF2C7A5),
          'medium': const Color(0xFFC98D62),
          'dark': const Color(0xFF7A4A31),
        }[skin] ??
        const Color(0xFFC98D62);
    final hairColor = hair == 'light'
        ? const Color(0xFFD6B56C)
        : const Color(0xFF4A3428);
    final robe = Paint()
      ..color = Color.lerp(
        const Color(0xFF718447),
        const Color(0xFF5B477C),
        level / (StatusService.names.length - 1),
      )!;
    final center = Offset(s.width / 2, s.height * .42);
    c.drawCircle(center, s.width * .22, Paint()..color = skinColor);
    c.drawArc(
      Rect.fromCircle(center: center, radius: s.width * .23),
      3.2,
      3.0,
      false,
      Paint()
        ..color = hairColor
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .22,
          s.height * .58,
          s.width * .56,
          s.height * .34,
        ),
        const Radius.circular(14),
      ),
      robe,
    );
    if (level >= 2) {
      c.drawLine(
        Offset(s.width * .78, s.height * .44),
        Offset(s.width * .84, s.height * .9),
        Paint()
          ..color = const Color(0xFF795548)
          ..strokeWidth = 4,
      );
    }
    if (level >= 4) {
      c.drawPath(
        Path()
          ..moveTo(s.width * .30, s.height * .25)
          ..lineTo(s.width * .50, s.height * .05)
          ..lineTo(s.width * .70, s.height * .25)
          ..close(),
        Paint()
          ..color = level >= 6
              ? const Color(0xFF66528A)
              : const Color(0xFF8B6B45),
      );
    }
    if (level >= 8) {
      c.drawCircle(
        Offset(s.width * .50, s.height * .10),
        5,
        Paint()..color = const Color(0xFFD5A927),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StatusAvatarPainter o) =>
      o.level != level || o.skin != skin || o.hair != hair;
}

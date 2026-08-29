import 'dart:io';
import 'dart:math';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'round_screen.dart';
import '../widgets/flag_art.dart';
import '../widgets/learner_shell.dart';
import '../widgets/learner_status_bar.dart';

const _learnerLightPageBackground = Color(0xFFF7F3E8);
const _learnerDarkPageBackground = Color(0xFF080B09);

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

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareWelcome());
  }

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
          title: const Text('Welcome to QuisquisLingo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version $_appVersion',
                style: Theme.of(ctx).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              Text(
                phrase,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium,
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
      });
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
    if (!_isTopicUnlocked(course, index) && !_iddqdMode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the previous Lesson or win its Duel to unlock this Lesson.',
          ),
        ),
      );
      return;
    }
    await _settings.setLastVisitedTopicId(
      course.courseId,
      course.topics[index].id,
    );
    if (mounted) setState(() => _activeTopicIndex = index);
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
              const ListTile(
                leading: Icon(Icons.menu_book_outlined),
                title: Text('Browse All Lessons'),
              ),
              const Divider(height: 1),
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
    final headerBackground = followsDarkAppearance
        ? _learnerDarkPageBackground
        : const Color(0xFF214D3B);
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
            foreground: LearnerStatusForeground.light,
            child: Scaffold(
              key: const Key('unified-learner-page'),
              backgroundColor: pageBackground,
              appBar: LearnerStatusAppBar(
                key: const Key('unified-learner-status-appbar'),
                backgroundColor: headerBackground,
                appBar: AppBar(
                  toolbarHeight: 58,
                  leadingWidth: 150,
                  leading: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => _showLearners(learnerContext),
                    icon: const Icon(Icons.face_outlined),
                    label: Text(
                      _activeLearner ?? 'Learner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Semantics(
                      label: 'QuisquisLingo',
                      header: true,
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/branding/quisquislingo_logo.png',
                          key: const Key('unified-learner-logo'),
                          width: 156,
                          height: 36,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  centerTitle: true,
                  foregroundColor: Colors.white,
                  backgroundColor: headerBackground,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () async {
                        await CrashLogService.instance.recordDebugEvent(
                          'Home: opening Settings',
                        );
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(course: course),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  ],
                ),
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/olive_tree.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    opacity: AlwaysStoppedAnimation(
                      followsDarkAppearance ? .20 : .62,
                    ),
                  ),
                  ColoredBox(
                    key: const Key('unified-learner-background-tint'),
                    color: followsDarkAppearance
                        ? const Color(0xD9000000)
                        : const Color(0x18FFF9E8),
                  ),
                  SafeArea(
                    top: false,
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                        children: [
                          _CourseSelector(
                            course: course,
                            code: _selectedLanguage,
                            onTap: () => _showCoursePicker(learnerContext),
                          ),
                          const SizedBox(height: 14),
                          if (topic == null)
                            const _EmptyCourseCard()
                          else ...[
                            _LessonNavigation(
                              topic: topic,
                              topicIndex: _activeTopicIndex,
                              roundCount: topic.rounds.length,
                              completedRoundCount: topic.rounds
                                  .where(
                                    (round) =>
                                        _completedRounds.contains(round.id),
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
                                          course.topics.length &&
                                      (_isTopicUnlocked(
                                            course,
                                            _activeTopicIndex + 1,
                                          ) ||
                                          _iddqdMode)
                                  ? () => _selectTopic(
                                      course,
                                      _activeTopicIndex + 1,
                                    )
                                  : null,
                              onBrowse: () =>
                                  _showLessonPicker(course, learnerContext),
                            ),
                            const SizedBox(height: 18),
                            _GuidebookNode(
                              topic: topic,
                              onTap: () => _openGuidebook(topic),
                            ),
                            if (topic.imageAsset.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _TopicImage(imageAsset: topic.imageAsset),
                            ],
                            const _VerticalConnector(),
                            _RoundTree(
                              rounds: topic.rounds,
                              completedRounds: _completedRounds,
                              perfectRounds: _perfectRounds,
                              ttsSkippedPerfectRounds: _ttsSkippedPerfectRounds,
                              onOpenRound: (round) =>
                                  _openRound(course, topic, round),
                            ),
                            const _VerticalConnector(),
                            _DuelCard(
                              eligibility: _duelEligibility.evaluate(topic),
                              onTap: () => _openDuel(course, topic),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _QuickActions(
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
                                builder: (_) =>
                                    CourseInfoScreen(course: course),
                              ),
                            ),
                          ),
                        ],
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

class _CourseSelector extends StatelessWidget {
  final Course course;
  final String code;
  final VoidCallback onTap;

  const _CourseSelector({
    required this.course,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: .92)
        : Colors.white.withValues(alpha: .84),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: InkWell(
      key: const Key('unified-course-selector'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            CourseFlagBadge(course: course, fallbackCode: code),
            const SizedBox(width: 12),
            Text(
              code,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      final selector = Expanded(
        child: OutlinedButton(
          key: const Key('unified-lesson-selector'),
          onPressed: onBrowse,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
                      ),
                    ),
                    Text('$completedRoundCount/$roundCount Rounds completed'),
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
      );
      final browse = OutlinedButton.icon(
        key: const Key('browse-all-lessons'),
        onPressed: onBrowse,
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Browse All Lessons'),
      );
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [selector]),
            const SizedBox(height: 8),
            browse,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [selector, const SizedBox(width: 10), browse],
      );
    },
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          key: const Key('unified-guidebook-node'),
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : const Color(0xFFFFF7C9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? colorScheme.outlineVariant
                  : const Color(0xFFF1C232),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: isDark
                        ? const Color(0xFF30284B)
                        : const Color(0xFFEDE2FF),
                    child: const Icon(Icons.menu_book_outlined, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GuideBook',
                          style: Theme.of(context).textTheme.titleLarge
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
    );
  }
}

class _TopicImage extends StatelessWidget {
  final String imageAsset;

  const _TopicImage({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    final path = imageAsset.trim();
    final missing = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: const [
            Icon(Icons.broken_image_outlined),
            Text('Lesson image is missing.'),
          ],
        ),
      ),
    );
    final image = path.startsWith('assets/')
        ? Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => missing,
          )
        : File(path).existsSync()
        ? Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => missing,
          )
        : missing;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 170, maxWidth: 260),
        child: image,
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
      width: 2,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _RoundTree extends StatelessWidget {
  final List<LearningRound> rounds;
  final Set<String> completedRounds;
  final Set<String> perfectRounds;
  final Set<String> ttsSkippedPerfectRounds;
  final void Function(LearningRound round) onOpenRound;

  const _RoundTree({
    required this.rounds,
    required this.completedRounds,
    required this.perfectRounds,
    required this.ttsSkippedPerfectRounds,
    required this.onOpenRound,
  });

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('This Lesson does not contain any Rounds yet.'),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final roundHeight = 142.0 + (textScale - 1.0).clamp(0.0, 2.0) * 72.0;
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RoundTreePainter(
                    itemCount: rounds.length,
                    columns: columns,
                    lineColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            GridView.builder(
              key: const Key('unified-round-tree'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
                mainAxisExtent: roundHeight,
              ),
              itemCount: rounds.length,
              itemBuilder: (context, index) {
                final round = rounds[index];
                final node = _RoundNode(
                  round: round,
                  roundNumber: index + 1,
                  completed: completedRounds.contains(round.id),
                  perfect: perfectRounds.contains(round.id),
                  ttsSkippedPerfect: ttsSkippedPerfectRounds.contains(round.id),
                  onTap: () => onOpenRound(round),
                );
                if (columns == 2 &&
                    rounds.length.isOdd &&
                    index == rounds.length - 1) {
                  return Transform.translate(
                    offset: Offset((constraints.maxWidth + 16) / 4, 0),
                    child: node,
                  );
                }
                return node;
              },
            ),
          ],
        );
      },
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
      color: isDark
          ? colorScheme.surfaceContainerHigh
          : const Color(0xFFFFF8D6),
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
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (perfect) ...[
                      Positioned(
                        left: 0,
                        bottom: 2,
                        child: Icon(Icons.eco, size: 34, color: statusColor),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Transform.flip(
                          flipX: true,
                          child: Icon(Icons.eco, size: 34, color: statusColor),
                        ),
                      ),
                    ],
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF3A3425)
                            : const Color(0xFFFFEBC0),
                      ),
                      child: Icon(_visualIcon, size: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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

class _RoundTreePainter extends CustomPainter {
  final int itemCount;
  final int columns;
  final Color lineColor;

  const _RoundTreePainter({
    required this.itemCount,
    required this.columns,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount < 2 || size.height <= 0) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rows = (itemCount / columns).ceil();
    final rowHeight = size.height / rows;
    final centerX = size.width / 2;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
    if (columns == 2) {
      for (var row = 0; row < rows; row++) {
        final y = rowHeight * row + rowHeight / 2;
        canvas.drawLine(
          Offset(size.width * .25, y),
          Offset(size.width * .75, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoundTreePainter oldDelegate) =>
      oldDelegate.itemCount != itemCount ||
      oldDelegate.columns != columns ||
      oldDelegate.lineColor != lineColor;
}

class _DuelCard extends StatelessWidget {
  final DuelEligibilityResult eligibility;
  final VoidCallback onTap;

  const _DuelCard({required this.eligibility, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('unified-duel-card'),
    color: eligibility.isAvailable
        ? const Color(0xFF0756DF)
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: eligibility.isAvailable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              Icons.sports_martial_arts_outlined,
              size: 52,
              color: eligibility.isAvailable ? Colors.white : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: eligibility.isAvailable ? Colors.white : null,
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
  );
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onLeaderboard, onReview, onCoffee, onCourseInfo;
  const _QuickActions({
    required this.onLeaderboard,
    required this.onReview,
    required this.onCoffee,
    required this.onCourseInfo,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: .90)
            : const Color(0x78FFFDF7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant
              : Colors.white.withValues(alpha: .70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .30 : .09),
            blurRadius: 17,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isDark
                    ? const Color(0xFF9AD5B3)
                    : const Color(0xFF3D704F),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? colorScheme.onSurface
                        : const Color(0xFF254B3D),
                  ),
                ),
              ),
            ],
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

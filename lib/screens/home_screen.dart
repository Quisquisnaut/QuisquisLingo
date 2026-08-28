import 'dart:math';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/course_editor_service.dart';
import '../services/progress_service.dart';
import '../services/profile_service.dart';
import '../services/status_service.dart';
import '../services/alpha_lifecycle_service.dart';
import '../services/app_errors.dart';
import '../services/error_presenter.dart';
import '../services/diagnostic_log_service.dart';
import '../services/crash_log_service.dart';
import 'settings_screen.dart';
import 'credits_screen.dart';
import 'review_screen.dart';
import 'info_screen.dart';
import 'course_entry_screen.dart';
import 'chapters_screen.dart';
import '../widgets/flag_art.dart';
import '../widgets/learner_shell.dart';
import '../widgets/learner_status_bar.dart';

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
  final _progress = ProgressService();
  final _profiles = ProfileService();
  final _status = StatusService();
  final _settings = SettingsService();
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
  int _xp = 0, _weekXp = 0, _weekXpTarget = 1000, _streak = 0, _daysStudied = 0;
  Set<String> _completedRounds = {};
  Set<String> _perfectRounds = {};
  String _skinTone = 'medium', _hairTone = 'dark';
  String _selectedLanguage = 'IT';
  String _selectedCourseRef = 'IT';
  int _lastChapterNumber = 1;
  String _lastChapterTitle = '';

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
      builder: (ctx) => AlertDialog(
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
    );
    await _settings.markOneTimeNoticeSeen(id);
  }

  Future<void> _showAlphaLifecycleNotice() async {
    if (!AlphaLifecycleService.isAlphaBuild || !mounted) return;
    if (AlphaLifecycleService.isExpired()) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
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
      builder: (ctx) => AlertDialog(
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
    );
  }

  Future<void> _showExpiredLearnerNotice() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    );
  }

  Future<void> _reload() async {
    try {
      Course course;
      if (_course == null) {
        final saved = await _settings.getLastSelectedCourseCode();
        if (saved != null && saved.startsWith('custom:')) {
          final courseId = saved.substring('custom:'.length);
          final userCourses = await _courseEditorService.listUserCourses();
          final matches = userCourses
              .where((c) => c.courseId == courseId)
              .toList();
          if (matches.isNotEmpty) {
            course = matches.first;
            _selectedCourseRef = 'custom:${course.courseId}';
            _selectedLanguage = CourseService.codeForCourse(course);
          } else {
            _selectedCourseRef = 'IT';
            _selectedLanguage = 'IT';
            course = await _courseService.loadCourse(_selectedLanguage);
          }
        } else {
          if (saved != null && CourseService.hasCourse(saved)) {
            _selectedLanguage = saved;
          }
          _selectedCourseRef = _selectedLanguage;
          course = await _courseService.loadCourse(_selectedLanguage);
        }
      } else {
        course = _course!;
      }
      final learners = await _profiles.getProfiles();
      final active = await _profiles.getActiveProfile();
      final savedChapterId = await _settings.getLastVisitedChapterId(
        course.courseId,
      );
      var lastChapterIndex = course.chapters.indexWhere(
        (chapter) => chapter.id == savedChapterId,
      );
      if (lastChapterIndex < 0) lastChapterIndex = 0;
      final lastChapterTitle = course.chapters.isEmpty
          ? 'Start learning'
          : course.chapters[lastChapterIndex].title;
      final lastChapterNumber = course.chapters.isEmpty
          ? 1
          : lastChapterIndex + 1;
      final xp = await _progress.getXp(courseCode: _selectedLanguage);
      final weekXp = await _progress.getWeeklyXp();
      final weekXpTarget = await _settings.getWeeklyXpTarget();
      final streak = await _progress.getStreak(courseCode: _selectedLanguage);
      final days = await _progress.getDaysStudied(
        courseCode: _selectedLanguage,
      );
      final rounds = await _progress.getCompletedRounds(
        courseId: course.courseId,
      );
      final perfect = await _progress.getPerfectRounds(
        courseId: course.courseId,
      );
      final skin = await _profiles.getSkinTone();
      final hair = await _profiles.getHairTone();
      if (!mounted) return;
      setState(() {
        _course = course;
        _learners = learners;
        _activeLearner = active;
        _lastChapterNumber = lastChapterNumber;
        _lastChapterTitle = lastChapterTitle;
        _xp = xp;
        _weekXp = weekXp;
        _weekXpTarget = weekXpTarget;
        _streak = streak;
        _daysStudied = days;
        _completedRounds = rounds;
        _perfectRounds = perfect;
        _skinTone = skin;
        _hairTone = hair;
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

  Future<void> _addLearner() async {
    if (_addingLearner) return;
    _addingLearner = true;
    final controller = TextEditingController();
    String skin = 'medium';
    String hair = 'dark';
    final result = await showDialog<(String, String, String)>(
      context: context,
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

  Future<void> _deleteLearner(String name) async {
    final ok = await showDialog<bool>(
      context: context,
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

  Future<void> _showLearners() async {
    final action = await showModalBottomSheet<String>(
      context: context,
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
    if (!mounted || action == null) return;
    // Start the next route only after the bottom sheet has completely closed.
    // This avoids disposing inherited dependents while Add profile opens.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    if (action == 'add') {
      await _addLearner();
      return;
    }
    if (action.startsWith('switch:')) {
      await _switchLearner(action.substring(7));
      return;
    }
    if (action.startsWith('delete:')) {
      await _deleteLearner(action.substring(7));
    }
  }

  Future<void> _showCoursePicker() async {
    final customCourses = await _courseEditorService.listUserCourses();
    if (!mounted) return;
    const codes = ['IT', 'DE', 'ES', 'EN', 'CY', 'NL', 'PT', 'FI'];
    await showModalBottomSheet<void>(
      context: context,
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
                  'Included courses',
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

  Future<void> _openCourse(Course course) async {
    if (AlphaLifecycleService.isExpired()) {
      await _showExpiredLearnerNotice();
      return;
    }
    await CrashLogService.instance.recordDebugEvent(
      'Home: opening course ${course.courseId}',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseEntryScreen(course: course, resumeChapter: true),
      ),
    );
    await _reload();
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
    final course = _course;
    if (course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_activeLearner == null && !_addingLearner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeLearner == null && !_addingLearner) _addLearner();
      });
    }
    final rank = _status.rank(
      xp: _xp,
      streak: _streak,
      daysStudied: _daysStudied,
      roundsCompleted: _completedRounds.length,
      laurelCrowns: _perfectRounds.length,
    );
    return LearnerStatusPage(
      foreground: LearnerStatusForeground.light,
      child: Scaffold(
        appBar: LearnerStatusAppBar(
          backgroundColor: const Color(0xFF214D3B),
          appBar: AppBar(
            toolbarHeight: 48,
            title: Text(
              _activeLearner == null ? 'QuisquisLingo' : 'Hi, $_activeLearner',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
            centerTitle: false,
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF214D3B),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Switch learner',
                icon: const Icon(Icons.people_outline),
                onPressed: _showLearners,
              ),
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
              opacity: const AlwaysStoppedAnimation(.62),
            ),
            const ColoredBox(color: Color(0x18FFF9E8)),
            SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    _CurrentCourseCard(
                      course: course,
                      code: _selectedLanguage,
                      lastChapterNumber: _lastChapterNumber,
                      lastChapterTitle: _lastChapterTitle,
                      onSelectCourse: _showCoursePicker,
                      onOpenCourse: () => _openCourse(course),
                    ),
                    const SizedBox(height: 10),
                    _StatusCard(
                      rank: rank,
                      course: course,
                      xp: _xp,
                      weekXp: _weekXp,
                      weekXpTarget: _weekXpTarget,
                      streak: _streak,
                      daysStudied: _daysStudied,
                      laurels: _perfectRounds.length,
                      skinTone: _skinTone,
                      hairTone: _hairTone,
                    ),
                    const SizedBox(height: 10),
                    _QuickActions(
                      onChapters: () async {
                        if (AlphaLifecycleService.isExpired()) {
                          await _showExpiredLearnerNotice();
                          return;
                        }
                        if (!mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChaptersScreen(course: course),
                          ),
                        );
                        await _reload();
                      },
                      onReview: () => _openReview(course),
                      onInfo: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InfoScreen()),
                      ),
                      onCredits: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreditsScreen(course: course),
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
  }
}

class _CurrentCourseCard extends StatelessWidget {
  final Course course;
  final String code;
  final int lastChapterNumber;
  final String lastChapterTitle;
  final VoidCallback onSelectCourse, onOpenCourse;
  const _CurrentCourseCard({
    required this.course,
    required this.code,
    required this.lastChapterNumber,
    required this.lastChapterTitle,
    required this.onSelectCourse,
    required this.onOpenCourse,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x82FFFDF7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: .78),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16392D).withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Material(
                color: const Color(0xFF23864C),
                borderRadius: BorderRadius.circular(24),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onSelectCourse,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD64A),
                          size: 20,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'CURRENT COURSE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CourseFlagBadge(course: course, fallbackCode: code),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.targetLanguage,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF173F35),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.sourceLanguage} → ${course.targetLanguage}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5A7069),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Chapter $lastChapterNumber',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF315B4B),
                                ),
                          ),
                          Text(
                            lastChapterTitle,
                            maxLines: 2,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5A7069),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F6A47),
                      backgroundColor: const Color(0x243F8A5B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onSelectCourse,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 21),
                    label: const Text('Change course'),
                  ),
                ),
                const SizedBox(height: 9),
                // The primary learning action is intentionally prominent and
                // remains immediately visible on small desktop windows.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(62),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      backgroundColor: const Color(0xFF159B52),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: const Color(
                        0xFF159B52,
                      ).withValues(alpha: .35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    onPressed: onOpenCourse,
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: const Text('GO TO COURSE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final StatusRank rank;
  final Course course;
  final int xp, weekXp, weekXpTarget, streak, daysStudied, laurels;
  final String skinTone, hairTone;
  const _StatusCard({
    required this.rank,
    required this.course,
    required this.xp,
    required this.weekXp,
    required this.weekXpTarget,
    required this.streak,
    required this.daysStudied,
    required this.laurels,
    required this.skinTone,
    required this.hairTone,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0x82FFFDF7),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.targetLanguage} progress',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 92,
                child: CustomPaint(
                  painter: _StatusAvatarPainter(rank.index, skinTone, hairTone),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rank.name} (lev. ${rank.index})',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank.nextThreshold == null
                          ? 'Maximum Status reached'
                          : 'Progress to ${StatusService.names[rank.index + 1]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: rank.progressToNext,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Keep the four progress metrics in a stable 2x2 grid. A Wrap could
          // place Week XP on a third line on medium-width desktop windows.
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric(value: '$streak', label: 'day streak'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      value: '$daysStudied',
                      label: 'days studying ${course.targetLanguage}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric(value: '$laurels', label: 'laurel crowns'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      value: '$weekXp',
                      label: 'Week XP · All courses / $weekXpTarget',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  final String value, label;
  const _Metric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .34),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onChapters, onReview, onInfo, onCredits;
  const _QuickActions({
    required this.onChapters,
    required this.onReview,
    required this.onInfo,
    required this.onCredits,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x78FFFDF7),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: .70)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .09),
          blurRadius: 17,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.menu_book_outlined,
            label: 'Chapters',
            onTap: onChapters,
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
            icon: Icons.info_outline,
            label: 'Info',
            onTap: onInfo,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _QuickAction(
            icon: Icons.attribution_outlined,
            label: 'Credits',
            onTap: onCredits,
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
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .34),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF3D704F)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF254B3D),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

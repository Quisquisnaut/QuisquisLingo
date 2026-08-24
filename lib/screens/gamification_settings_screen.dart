import 'package:flutter/material.dart';
import '../services/course_editor_service.dart';
import '../services/course_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';

class GamificationSettingsScreen extends StatefulWidget {
  const GamificationSettingsScreen({super.key});

  @override
  State<GamificationSettingsScreen> createState() => _GamificationSettingsScreenState();
}

class _GamificationSettingsScreenState extends State<GamificationSettingsScreen> {
  final _settings = SettingsService();
  final _progress = ProgressService();
  final _profiles = ProfileService();
  final _courseService = CourseService();
  final _courseEditor = CourseEditorService();

  bool _loading = true;
  int _target = 1000;
  int _lastWeekXp = 0;
  Map<String, int> _lastWeekByCourse = const {};
  List<LocalLeaderboardEntry> _leaderboard = const [];
  bool _participates = true;
  String? _activeLearner;
  Map<String, String> _courseNames = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final target = await _settings.getWeeklyXpTarget();
    final lastWeekXp = await _progress.getLastWeekXp();
    final byCourse = await _progress.getLastWeekXpByCourse();
    final leaderboard = await _progress.getLastWeekLocalLeaderboard();
    final participates = await _progress.isLocalLeaderboardParticipationEnabled();
    final active = await _profiles.getActiveProfile();
    final names = <String, String>{};

    for (final code in CourseService.courseAssets.keys) {
      try {
        final course = await _courseService.loadCourse(code);
        names[course.courseId] = course.title;
        names[code] = course.title;
      } catch (_) {
        names[code] = CourseService.targetLabels[code] ?? code;
      }
    }
    for (final course in await _courseEditor.listUserCourses()) {
      names[course.courseId] = course.title;
    }

    if (!mounted) return;
    setState(() {
      _target = target;
      _lastWeekXp = lastWeekXp;
      _lastWeekByCourse = byCourse;
      _leaderboard = leaderboard;
      _participates = participates;
      _activeLearner = active;
      _courseNames = names;
      _loading = false;
    });
  }

  Future<void> _editTarget() async {
    final controller = TextEditingController(text: '$_target');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Weekly XP Target · All courses'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: 'XP',
            helperText: 'The target is based on XP earned across all courses.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 1) return;
    await _settings.setWeeklyXpTarget(value);
    if (mounted) setState(() => _target = value);
  }

  Future<void> _showLastWeekBreakdown() async {
    final entries = _lastWeekByCourse.entries.toList()
      ..sort((a, b) {
        final byXp = b.value.compareTo(a.value);
        if (byXp != 0) return byXp;
        return (_courseNames[a.key] ?? a.key).compareTo(_courseNames[b.key] ?? b.key);
      });
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Last Week XP by course'),
        content: SizedBox(
          width: 420,
          child: entries.isEmpty
              ? const Text('No XP were recorded for the previous completed week.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_courseNames[entry.key] ?? entry.key),
                      trailing: Text('${entry.value} XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _setParticipation(bool value) async {
    await _progress.setLocalLeaderboardParticipationEnabled(value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gamification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Weekly XP Target · All courses'),
                    subtitle: Text('$_target XP · current week · total across every course'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _editTarget,
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Last Week XP · All courses'),
                    subtitle: const Text('Previous completed week. Tap your score to see XP for each course.'),
                    trailing: Text('$_lastWeekXp XP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    onTap: _showLastWeekBreakdown,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local leaderboard · All courses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Previous completed week. Each score is that learner’s total XP earned across all courses.'),
                        const SizedBox(height: 12),
                        if (_leaderboard.isEmpty)
                          const Text('No participating local learners yet.')
                        else
                          ...List.generate(_leaderboard.length, (index) {
                            final entry = _leaderboard[index];
                            final mine = entry.learnerName == _activeLearner;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(child: Text('${index + 1}')),
                              title: Text(entry.learnerName, style: TextStyle(fontWeight: mine ? FontWeight.bold : FontWeight.normal)),
                              trailing: Text('${entry.xp} XP', style: TextStyle(fontWeight: mine ? FontWeight.bold : FontWeight.normal)),
                              onTap: mine ? _showLastWeekBreakdown : null,
                            );
                          }),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Participate in local leaderboard'),
                          subtitle: const Text('Turn this off to keep your profile out of the local ranking. Your XP and Last Week XP are still recorded for you.'),
                          value: _participates,
                          onChanged: _setParticipation,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'The leaderboard is local to this device. It compares only learner profiles stored in this QuisquisLingo installation and uses the previous completed week, not the current week.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
    );
  }
}

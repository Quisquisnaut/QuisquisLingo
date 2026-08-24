import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/learner_backup_service.dart';
import '../services/progress_service.dart';

class UserDataSettingsScreen extends StatefulWidget {
  final Course course;
  const UserDataSettingsScreen({super.key, required this.course});

  @override
  State<UserDataSettingsScreen> createState() => _UserDataSettingsScreenState();
}

class _UserDataSettingsScreenState extends State<UserDataSettingsScreen> {
  final _backup = LearnerBackupService();
  final _progress = ProgressService();

  Future<void> _exportLearner() async {
    try {
      final path = await _backup.saveActiveProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Learner backup exported to $path'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Export failed: $error'),
        ),
      );
    }
  }

  Future<void> _importLearner() async {
    try {
      final name = await _backup.importProfile();
      if (name == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Learner data restored for $name.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Import failed: $error'),
        ),
      );
    }
  }

  Future<void> _resetCurrentCourse() async {
    final courseName = widget.course.title.trim().isEmpty
        ? widget.course.targetLanguage
        : widget.course.title;
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset $courseName progress?'),
        content: const Text(
          'This resets Review history, round results, laurel crowns and Duel progress for the current course only. Language XP, streak, study days and Status are kept because they are shared by courses in that language.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final confirmation'),
        content: Text(
          'Reset all your progress for $courseName? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset current course'),
          ),
        ],
      ),
    );
    if (second != true) return;

    await _progress.resetCourse(widget.course.courseId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('$courseName progress reset.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Data')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ListTile(
            title: Text('Learner data'),
            subtitle: Text(
              'Back up or restore the active learner profile, or reset progress for the currently selected course.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Export my data'),
            subtitle: const Text(
              'Saves directly to Documents/QuisquisLingo/Exports. No Save As dialog.',
            ),
            onTap: _exportLearner,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import my data'),
            subtitle: const Text(
              'Copy the backup to Documents/QuisquisLingo/Exports/learner_import.json, then tap here.',
            ),
            onTap: _importLearner,
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset current course progress'),
            subtitle: Text(
              'Resets only this learner’s progress for ${widget.course.title}. Other courses and Course Editor changes are kept.',
            ),
            onTap: _resetCurrentCourse,
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/learner_backup_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/user_recovery_key_service.dart';

class UserDataSettingsScreen extends StatefulWidget {
  final Course course;
  const UserDataSettingsScreen({super.key, required this.course});

  @override
  State<UserDataSettingsScreen> createState() => _UserDataSettingsScreenState();
}

class _UserDataSettingsScreenState extends State<UserDataSettingsScreen> {
  final _backup = LearnerBackupService();
  final _profiles = ProfileService();
  late final _recovery = UserRecoveryKeyService(profileService: _profiles);
  final _progress = ProgressService();

  Future<void> _exportRecoveryKey() async {
    try {
      final path = await _recovery.exportActiveUserRecoveryKey();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('User Recovery Key exported to $path'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recovery Key export failed: $error')),
      );
    }
  }

  Future<void> _importRecoveryKey() async {
    try {
      final candidates = await _recovery.findImportableUserRecoveryKeys();
      if (!mounted) return;
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No User Recovery Key is available in Imports.'),
          ),
        );
        return;
      }
      UserRecoveryKeyCandidate? selected;
      if (candidates.length == 1) {
        selected = candidates.single;
      } else {
        selected = await showDialog<UserRecoveryKeyCandidate>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Choose User Recovery Key'),
            children: [
              for (final candidate in candidates)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, candidate),
                  child: Text(
                    candidate.path.split(Platform.pathSeparator).last,
                  ),
                ),
            ],
          ),
        );
      }
      if (selected == null || !mounted) return;
      if (await _profiles.getProfileById(selected.document.learnerProfileId) !=
          null) {
        throw UserRecoveryIdentityConflict(selected.document.learnerProfileId);
      }
      final screenName = await _chooseRecoveryScreenName();
      if (screenName == null || !mounted) return;
      final profile = await _recovery.importIdentity(
        selected.document,
        screenNameText: screenName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Recovered the existing QQL identity as ${profile.displayName}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Recovery Key import failed: ${error.toString().replaceFirst('UserRecoveryIdentityConflict: ', '')}',
          ),
        ),
      );
    }
  }

  Future<String?> _chooseRecoveryScreenName() async {
    var screenName = '';
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: const Text('Name the recovered profile'),
          content: TextField(
            key: const Key('recovery-screen-name'),
            autofocus: true,
            maxLength: 32,
            onChanged: (value) => screenName = value,
            decoration: InputDecoration(
              labelText: 'Screen Name',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  Navigator.pop(
                    dialogContext,
                    ProfileService.validateScreenNameText(screenName),
                  );
                } on ArgumentError catch (value) {
                  setLocalState(
                    () =>
                        error = value.message?.toString() ?? 'Check the name.',
                  );
                }
              },
              child: const Text('Recover identity'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecoveryKeyHelp() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('User Recovery Key Help'),
      content: const SingleChildScrollView(
        child: Text(
          'A User Recovery Key preserves the same stable QQL identity after reinstalling QQL, after local data loss, or when using another or multiple devices. Because Course maintainership and other relationships use that identity, they can be recognized wherever the same key is imported.\n\nThe key does not restore or force a Screen Name. Course export alone does not prove or transfer Course maintainership or legal rights.\n\nKeep the key private. Someone who possesses it may be able to claim that QQL identity. The key does not contain your Access PIN.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );

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
      final document = await _backup.readImportFile();
      if (!mounted) return;
      var action = await _chooseImportAction(document.displayName);
      if (action == null || !mounted) return;
      if (action == _LearnerImportAction.restore &&
          await _profileIdExists(document.learnerProfileId)) {
        action = await _chooseCollisionAction(document.displayName);
        if (action == null || !mounted) return;
      }

      late String name;
      if (action == _LearnerImportAction.separateCopy) {
        final chosenName = await _chooseSeparateCopyName(document.displayName);
        if (chosenName == null || !mounted) return;
        final profile = await _backup.importAsSeparateCopy(
          document,
          displayName: chosenName,
        );
        name = profile.displayName;
      } else {
        final profile = await _backup.restorePreservingIdentity(
          document,
          replaceExisting: action == _LearnerImportAction.replace,
        );
        name = profile.displayName;
      }
      if (!mounted) return;
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

  Future<bool> _profileIdExists(String learnerProfileId) async =>
      await _backup.profileExists(learnerProfileId);

  Future<_LearnerImportAction?> _chooseImportAction(
    String displayName,
  ) => showDialog<_LearnerImportAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Import learner data'),
      content: Text(
        'Restore $displayName with the same learner identity, or import an independent copy?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(ctx, _LearnerImportAction.separateCopy),
          child: const Text('Import as separate copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _LearnerImportAction.restore),
          child: const Text('Restore / preserve identity'),
        ),
      ],
    ),
  );

  Future<_LearnerImportAction?> _chooseCollisionAction(
    String displayName,
  ) => showDialog<_LearnerImportAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Learner already exists'),
      content: Text(
        '$displayName has the same learner identity as a profile already on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(ctx, _LearnerImportAction.separateCopy),
          child: const Text('Import as separate copy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _LearnerImportAction.replace),
          child: const Text('Replace existing'),
        ),
      ],
    ),
  );

  Future<String?> _chooseSeparateCopyName(String originalName) async {
    final controller = TextEditingController(text: originalName);
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Name the separate copy'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Learner name',
              border: const OutlineInputBorder(),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final clean = controller.text.trim();
                if (clean.isEmpty) {
                  setLocalState(() => errorText = 'Enter a learner name.');
                  return;
                }
                Navigator.pop(ctx, clean);
              },
              child: const Text('Import copy'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
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
              'Copy the backup to Documents/QuisquisLingo/Imports/learner_import.json, then tap here.',
            ),
            onTap: _importLearner,
          ),
          const Divider(),
          const ListTile(
            title: Text('User Recovery Key'),
            subtitle: Text(
              'A private identity credential for disaster recovery and use on multiple devices.',
            ),
          ),
          ListTile(
            key: const Key('export-user-recovery-key'),
            leading: const Icon(Icons.key_outlined),
            title: const Text('Export User Recovery Key'),
            subtitle: const Text(
              'Saves directly to Documents/QuisquisLingo/Exports.',
            ),
            onTap: _exportRecoveryKey,
          ),
          ListTile(
            key: const Key('import-user-recovery-key'),
            leading: const Icon(Icons.key),
            title: const Text('Import User Recovery Key'),
            subtitle: const Text(
              'Searches Documents/QuisquisLingo/Imports without a file picker.',
            ),
            onTap: _importRecoveryKey,
          ),
          ListTile(
            key: const Key('user-recovery-key-help'),
            leading: const Icon(Icons.help_outline),
            title: const Text('User Recovery Key Help'),
            onTap: _showRecoveryKeyHelp,
          ),
          const Divider(),
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

enum _LearnerImportAction { restore, replace, separateCopy }

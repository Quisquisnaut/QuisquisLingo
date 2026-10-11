import 'dart:async';

import 'package:flutter/material.dart';

import '../services/course_library_operations.dart' show CourseLibraryReports;
import '../services/inventory_action_service.dart';
import '../services/inventory_service.dart';
import '../services/profile_service.dart';
import '../widgets/folder_opener.dart';

/// Admin-only list of everything QQL has stored because of what people did,
/// inside the app or by adding files to QQL's folders from outside it.
///
/// All explanations and paths are plain, selectable text so they are readable
/// and copyable on any device.
///
/// Since Build 266 Revision 2 (owner decisions of 8 October 2026) each item
/// has Delete or Forget where it applies, after the admin's PIN and under
/// the rules the rest of QQL applies, and Open folder where it has one
/// (Windows, macOS and Linux).
class InventoryScreen extends StatefulWidget {
  final InventoryService? service;
  final InventoryActionService? actionService;
  final ProfileService? profileService;

  const InventoryScreen({
    super.key,
    this.service,
    this.actionService,
    this.profileService,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _service = widget.service ?? InventoryService();
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final InventoryActionService _actions =
      widget.actionService ?? InventoryActionService(profiles: _profiles);
  late Future<List<InventorySection>> _future = _service.load();

  Future<void> _openFolder(InventoryItem item) async {
    final folder = item.folder;
    if (folder == null) return;
    var opened = false;
    try {
      opened = await FolderOpener.open(folder);
    } catch (_) {}
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('The folder could not be opened: $folder'),
      ),
    );
  }

  /// Delete, Forget or Reset, in three steps (Build 271 Revision 2 second
  /// follow-up, owner decision of 11 October 2026: 1. the warnings, 2. the
  /// PIN, 3. the word DELETE, everywhere a warning and a PIN meet):
  ///
  /// 1. What the action removes, with its warnings and choices. For a
  ///    Course: who has it, who kept progress on it, and the two options,
  ///    both off (reset everyone's progress, asked once more; delete its
  ///    backups). For a Delete the service refuses otherwise, a second
  ///    confirmation: a Publisher Course others have, another learner's
  ///    Course, a learner who maintains Courses or is the last Team Leader
  ///    of a Team, and a Team.
  /// 2. The admin's PIN.
  /// 3. For those Deletes, the word DELETE, typed after the PIN.
  ///
  /// The service applies the same rules as the rest of QQL and says why it
  /// refuses; nothing is changed before the last step.
  Future<void> _runAction(InventoryItem item) async {
    final action = item.action;
    if (action == null) return;
    final actor = await _profiles.getActiveProfileId();
    if (actor == null || !mounted) return;
    final coursePreview = InventoryActionService.isCourseAction(action)
        ? _coursePreview(action, actor)
        : null;
    final learnerPreview = action.kind == InventoryActionKind.deleteLearner
        ? _learnerPreview(action, item)
        : null;
    final teamPreview = action.kind == InventoryActionKind.deleteTeam
        ? _teamPreview(action, item)
        : null;

    // ---- 1. What it removes, the warnings and the choices.
    var resetProgress = false;
    var deleteBackups = false;
    var checking = false;
    final choices = await showDialog<_ActionChoices>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          key: const Key('inventory-action-dialog'),
          title: Text('${action.label} “${item.name}”?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.explanation),
                if (coursePreview != null)
                  FutureBuilder<InventoryCoursePreview?>(
                    future: coursePreview,
                    builder: (context, snapshot) => _CourseExtras(
                      preview: snapshot.data,
                      resetProgress: resetProgress,
                      deleteBackups: deleteBackups,
                      onResetProgress: checking
                          ? null
                          : (value) => setLocal(() => resetProgress = value),
                      onDeleteBackups: checking
                          ? null
                          : (value) => setLocal(() => deleteBackups = value),
                    ),
                  ),
                if (learnerPreview != null)
                  FutureBuilder<InventoryLearnerPreview?>(
                    future: learnerPreview,
                    builder: (context, snapshot) => _WarningBox(
                      warning: snapshot.data?.overrideWarning,
                      warningKey: const Key(
                        'inventory-learner-override-warning',
                      ),
                      icon: Icons.edit_off_outlined,
                    ),
                  ),
                if (teamPreview != null)
                  FutureBuilder<InventoryTeamPreview?>(
                    future: teamPreview,
                    builder: (context, snapshot) => _WarningBox(
                      warning: snapshot.data?.overrideWarning,
                      warningKey: const Key('inventory-team-override-warning'),
                      icon: Icons.groups_outlined,
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'This cannot be undone. Your admin PIN is asked next.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: checking ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('inventory-action-continue'),
              onPressed: checking
                  ? null
                  : () async {
                      setLocal(() => checking = true);
                      // Never throw: a check that fails gives null, or for
                      // a learner "QQL cannot tell".
                      final course = await coursePreview;
                      final learner = await learnerPreview;
                      final team = await teamPreview;
                      if (!dialogContext.mounted) return;
                      final override = _Override.of(
                        item,
                        course: course,
                        learner: learner,
                        team: team,
                        teamAction:
                            action.kind == InventoryActionKind.deleteTeam,
                        resetProgress: resetProgress,
                        deleteBackups: deleteBackups,
                      );
                      var goOn = true;
                      if (override != null) {
                        goOn = await _confirmOverride(dialogContext, override);
                      }
                      if (goOn && resetProgress && dialogContext.mounted) {
                        goOn = await _confirmReset(
                          dialogContext,
                          item,
                          publisher:
                              action.kind ==
                              InventoryActionKind.deletePublisherCourse,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      if (!goOn) {
                        setLocal(() => checking = false);
                        return;
                      }
                      Navigator.pop(
                        dialogContext,
                        _ActionChoices(
                          resetProgress: resetProgress,
                          deleteBackups: deleteBackups,
                          wordPrompt: override?.wordPrompt,
                        ),
                      );
                    },
              child: Text(action.label),
            ),
          ],
        ),
      ),
    );
    if (choices == null || !mounted) return;

    // ---- 2. The PIN, and 3. the word DELETE where the warning asked.
    final pin = TextEditingController();
    final word = TextEditingController();
    String? error;
    String? note;
    var running = false;
    final override = choices.wordPrompt != null;
    final done =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setLocal) => AlertDialog(
              key: const Key('inventory-action-pin-dialog'),
              title: const Text('Enter your admin PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${override ? 'Last steps' : 'Last step'}: '
                      '${action.label} “${item.name}”. Nothing has been '
                      'changed so far.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inventory-action-pin'),
                      controller: pin,
                      obscureText: true,
                      autofocus: true,
                      enabled: !running,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Admin PIN',
                      ),
                    ),
                    if (override) ...[
                      Text(choices.wordPrompt!),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('inventory-action-word'),
                        controller: word,
                        enabled: !running,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Type DELETE to confirm',
                        ),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          key: const Key('inventory-action-error'),
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: running
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('inventory-action-run'),
                  onPressed: running
                      ? null
                      : () async {
                          if (override &&
                              word.text.trim() !=
                                  InventoryActionService.overrideWord) {
                            setLocal(
                              () => error =
                                  'Type DELETE in capital letters to go '
                                  'ahead.',
                            );
                            return;
                          }
                          setLocal(() {
                            running = true;
                            error = null;
                          });
                          try {
                            note = await _actions.run(
                              action,
                              actorProfileId: actor,
                              pin: pin.text,
                              resetEveryonesProgress: choices.resetProgress,
                              deleteBackups: choices.deleteBackups,
                              adminOverride: override,
                              typedWord: word.text,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setLocal(() {
                              running = false;
                              error = '$e';
                            });
                          }
                        },
                  child: Text(action.label),
                ),
              ],
            ),
          ),
        ).whenComplete(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          pin.dispose();
          word.dispose();
        });
    if (done != true || !mounted) return;
    setState(() {
      _future = _service.load();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: note == null ? 4 : 8),
        content: Text(
          '${action.label}: “${item.name}” done.'
          '${choices.resetProgress ? ' Everyone\'s progress on it was reset.' : ''}'
          '${choices.deleteBackups ? ' Its backups were deleted.' : ''}'
          '${note == null ? '' : ' $note'}',
        ),
      ),
    );
  }

  /// What the Course dialog shows; a check that fails shows nothing extra
  /// and never stops the Delete.
  Future<InventoryCoursePreview?> _coursePreview(
    InventoryAction action,
    String actor,
  ) async {
    try {
      return await _actions.previewCourse(action, actorProfileId: actor);
    } catch (_) {
      return null;
    }
  }

  /// What the learner dialog shows. A check that fails is treated as "QQL
  /// cannot tell", so the admin is still warned and can go ahead.
  Future<InventoryLearnerPreview?> _learnerPreview(
    InventoryAction action,
    InventoryItem item,
  ) async {
    try {
      return await _actions.previewLearner(action);
    } catch (_) {
      return InventoryLearnerPreview(
        name: item.name,
        maintained: const [],
        unknown: true,
      );
    }
  }

  /// What the Team dialog shows. A check that fails still warns, without
  /// the names.
  Future<InventoryTeamPreview?> _teamPreview(
    InventoryAction action,
    InventoryItem item,
  ) async {
    try {
      return await _actions.previewTeam(action) ??
          InventoryTeamPreview(
            name: item.name,
            members: const [],
            courses: const [],
          );
    } catch (_) {
      return InventoryTeamPreview(
        name: item.name,
        members: const [],
        courses: const [],
      );
    }
  }

  /// The second confirmation before a Delete the service refuses otherwise.
  /// It says what goes and what stays, and where the admin decided it (owner
  /// request of 11 October 2026): the boxes in the first dialog.
  Future<bool> _confirmOverride(
    BuildContext context,
    _Override override,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('inventory-override-confirm'),
          title: Text(override.title),
          content: Text(override.question),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(override.keep),
            ),
            FilledButton(
              key: const Key('inventory-override-confirm-run'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(override.button),
            ),
          ],
        ),
      ) ??
      false;

  /// The second confirmation before every learner's progress on a Course is
  /// reset. Learners may want it back when a Publisher Course is installed
  /// again, so that case says so.
  Future<bool> _confirmReset(
    BuildContext context,
    InventoryItem item, {
    required bool publisher,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('inventory-course-reset-confirm'),
          title: const Text('Confirm progress reset'),
          content: Text(
            '${publisher ? 'Learners may want their progress back when this Course is installed again. ' : ''}'
            'Reset the progress of every learner on “${item.name}”: completed '
            'Rounds and Lessons, Laurels, Duels, GuideBooks read and recent '
            'Rounds? XP, Weekly XP, study days and streaks are kept. The '
            'reset cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep their progress'),
            ),
            FilledButton(
              key: const Key('inventory-course-reset-confirm-run'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset everyone\'s progress'),
            ),
          ],
        ),
      ) ??
      false;

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            key: const Key('inventory-refresh'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _future = _service.load();
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: FutureBuilder<List<InventorySection>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'The inventory could not be read: ${snapshot.error}',
                    ),
                  );
                }
                final sections = snapshot.data!;
                return ListView(
                  key: const Key('inventory-list'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _Summary(sections: sections),
                    for (final section in sections)
                      _SectionCard(
                        section: section,
                        onAction: _runAction,
                        onOpenFolder: FolderOpener.available()
                            ? _openFolder
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<InventorySection> sections;

  const _Summary({required this.sections});

  @override
  Widget build(BuildContext context) {
    final files = sections
        .where((s) => s.location != null)
        .fold<int>(0, (sum, s) => sum + s.count);
    final bytes = sections.fold<int>(0, (sum, s) => sum + s.totalBytes);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Everything QQL has stored on this device because of what people did: created inside the app, or added to QQL’s folders from outside it, for example by copying files with the operating system. Paths can be selected and copied. Media and files that come with the app itself are not listed.',
          ),
          const SizedBox(height: 8),
          Text(
            'Files found: $files, using ${_InventoryScreenState.formatBytes(bytes)}. Learners and courses are stored inside QQL’s own settings, not as files, and are listed separately.',
            key: const Key('inventory-summary'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final InventorySection section;
  final ValueChanged<InventoryItem> onAction;
  final ValueChanged<InventoryItem>? onOpenFolder;

  const _SectionCard({
    required this.section,
    required this.onAction,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    final isFolder = section.location != null;
    final count = section.count;
    final size = isFolder
        ? ' · ${_InventoryScreenState.formatBytes(section.totalBytes)}'
        : '';
    return Card(
      key: Key('inventory-section-${section.title}'),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${section.title} ($count)$size',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(section.description),
            if (section.location != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                'Location: ${section.location}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            for (final (index, group) in section.groups.indexed)
              _ItemRow(
                item: group,
                keyPrefix: 'inventory-${section.title}-group-$index',
                onAction: onAction,
                onOpenFolder: onOpenFolder,
              ),
            if (count == 0)
              const Text('Nothing found.')
            else
              for (final (index, item) in section.items.indexed)
                _ItemRow(
                  item: item,
                  keyPrefix: 'inventory-${section.title}-$index',
                  onAction: onAction,
                  onOpenFolder: onOpenFolder,
                ),
            if (section.hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'and ${section.hiddenCount} more not shown here (showing the ${InventoryService.maxListedPerSection} most recent).',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The Course part of the Inventory's Delete dialog (Build 271 Revision 1
/// follow-up): who has the Course, who kept progress on it, and the two
/// options, both off. Until [preview] is read only the options show, the
/// backups one greyed.
class _CourseExtras extends StatelessWidget {
  const _CourseExtras({
    required this.preview,
    required this.resetProgress,
    required this.deleteBackups,
    required this.onResetProgress,
    required this.onDeleteBackups,
  });

  final InventoryCoursePreview? preview;
  final bool resetProgress;
  final bool deleteBackups;
  final ValueChanged<bool>? onResetProgress;
  final ValueChanged<bool>? onDeleteBackups;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = preview;
    final haveIt = data?.haveIt;
    final keptIt = data?.keptIt;
    final held = data?.backups;
    final publisher = data?.publisher ?? false;
    final overrideWarning = data?.overrideWarning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (haveIt != null || keptIt != null || overrideWarning != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.group_outlined, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (haveIt != null)
                        Text(
                          haveIt,
                          key: const Key('inventory-course-learners'),
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      if (keptIt != null)
                        Text(
                          keptIt,
                          key: const Key('inventory-course-kept-progress'),
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      if (overrideWarning != null)
                        Text(
                          overrideWarning,
                          key: const Key('inventory-course-override-warning'),
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          key: const Key('inventory-course-reset-progress'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: resetProgress,
          onChanged: onResetProgress == null
              ? null
              : (value) => onResetProgress!(value ?? false),
          title: const Text('Also reset everyone\'s progress on this Course'),
          subtitle: Text(
            '${publisher ? 'Learners may want to keep their progress for when the Course is installed again. ' : ''}'
            'Completed Rounds and Lessons, Laurels, Duels, GuideBooks read '
            'and recent Rounds, for every learner on this device, also those '
            'who removed the Course from their courses and kept their '
            'progress. XP, Weekly XP, study days and streaks are kept.',
          ),
        ),
        CheckboxListTile(
          key: const Key('inventory-course-delete-backups'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: deleteBackups,
          onChanged: onDeleteBackups == null || held == null || held.isEmpty
              ? null
              : (value) => onDeleteBackups!(value ?? false),
          title: const Text('Also delete all its backups'),
          subtitle: Text(
            held == null
                ? 'Looking for its backups…'
                : held.isEmpty
                ? 'It has no backups.'
                : '${CourseLibraryReports.backupsHeld(held)}, with the '
                      'pictures and recordings only they hold.'
                      '${data!.unopenable ? ' ${CourseLibraryReports.unopenableBackupsCaution}' : ''}',
          ),
        ),
      ],
    );
  }
}

/// What the first dialog of an Inventory action hands to the PIN dialog.
class _ActionChoices {
  const _ActionChoices({
    required this.resetProgress,
    required this.deleteBackups,
    required this.wordPrompt,
  });

  final bool resetProgress;
  final bool deleteBackups;

  /// What asks for the word DELETE after the PIN; null when the action
  /// needs no override.
  final String? wordPrompt;
}

/// The second confirmation of a Delete the service refuses otherwise, and
/// what asks for the word DELETE after the PIN.
class _Override {
  const _Override({
    required this.title,
    required this.question,
    required this.button,
    required this.keep,
    required this.wordPrompt,
  });

  final String title;
  final String question;
  final String button;

  /// The button that goes back: "Keep the Course".
  final String keep;
  final String wordPrompt;

  /// The override [item]'s Delete needs, or null when it needs none.
  static _Override? of(
    InventoryItem item, {
    required InventoryCoursePreview? course,
    required InventoryLearnerPreview? learner,
    required InventoryTeamPreview? team,
    required bool teamAction,
    required bool resetProgress,
    required bool deleteBackups,
  }) {
    if (course != null && course.needsOverride) {
      return _Override(
        title: course.overrideTitle,
        question: course.overrideQuestion(
          item.name,
          resetProgress: resetProgress,
          deleteBackups: deleteBackups,
        ),
        button: course.overrideButton,
        keep: 'Keep the Course',
        wordPrompt: course.othersBlockRemoval
            ? 'Then, to remove it anyway, type DELETE.'
            : 'Then, to delete it anyway, type DELETE.',
      );
    }
    if (learner != null && learner.needsOverride) {
      return _Override(
        title: learner.overrideTitle,
        question: learner.overrideQuestion,
        button: InventoryLearnerPreview.overrideButton,
        keep: 'Keep the learner',
        wordPrompt: 'Then, to delete ${learner.name} anyway, type DELETE.',
      );
    }
    if (teamAction && team != null) {
      return _Override(
        title: team.overrideTitle,
        question: team.overrideQuestion,
        button: InventoryTeamPreview.overrideButton,
        keep: 'Keep the Team',
        wordPrompt: 'Then, to delete the Team, type DELETE.',
      );
    }
    return null;
  }
}

/// A warning in the first dialog of an Inventory action; nothing while
/// there is none.
class _WarningBox extends StatelessWidget {
  const _WarningBox({
    required this.warning,
    required this.warningKey,
    required this.icon,
  });

  final String? warning;
  final Key warningKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = warning;
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                key: warningKey,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InventoryItem item;
  final String keyPrefix;
  final ValueChanged<InventoryItem> onAction;
  final ValueChanged<InventoryItem>? onOpenFolder;

  const _ItemRow({
    required this.item,
    required this.keyPrefix,
    required this.onAction,
    required this.onOpenFolder,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (item.sizeBytes != null)
        _InventoryScreenState.formatBytes(item.sizeBytes!),
      if (item.modified != null)
        'modified ${_InventoryScreenState.formatDate(item.modified!)}',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (item.path != null)
            SelectableText(
              item.path!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (details.isNotEmpty) Text(details.join(' · ')),
          if (item.owner != null) Text('Belongs to: ${item.owner}'),
          if (item.note != null) Text(item.note!),
          if (item.action != null ||
              (item.folder != null && onOpenFolder != null))
            Wrap(
              spacing: 4,
              children: [
                if (item.action case final action?)
                  TextButton.icon(
                    key: Key('$keyPrefix-action'),
                    onPressed: () => onAction(item),
                    icon: Icon(
                      action.kind == InventoryActionKind.forget
                          ? Icons.backspace_outlined
                          : Icons.delete_outline,
                      size: 18,
                    ),
                    label: Text('${action.label}…'),
                  ),
                if (item.folder != null && onOpenFolder != null)
                  TextButton.icon(
                    key: Key('$keyPrefix-open-folder'),
                    onPressed: () => onOpenFolder!(item),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Open folder'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

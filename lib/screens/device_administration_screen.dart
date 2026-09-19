import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/app_reset_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_restart_scope.dart';
import 'flat_image_library_screen.dart';
import 'inventory_screen.dart';
import 'device_administration_help_screen.dart';
import 'user_data_settings_screen.dart';

/// Admin-only page that gathers the device-level administration features.
///
/// All explanatory text is shown inline (never only as a tooltip) so it is
/// readable on touch devices, and every block wraps to the available width.
class DeviceAdministrationScreen extends StatefulWidget {
  final Course course;
  final Future<void> Function(BuildContext context) onManageLearners;
  final ProfileService? profileService;
  final AppResetService? resetService;

  const DeviceAdministrationScreen({
    super.key,
    required this.course,
    required this.onManageLearners,
    this.profileService,
    this.resetService,
  });

  @override
  State<DeviceAdministrationScreen> createState() =>
      _DeviceAdministrationScreenState();
}

class _DeviceAdministrationScreenState
    extends State<DeviceAdministrationScreen> {
  late final ProfileService _profiles =
      widget.profileService ?? ProfileService();
  late final AppResetService _reset =
      widget.resetService ?? AppResetService(profiles: _profiles);

  bool _loading = true;
  String? _actorId;
  bool _isAdmin = false;
  bool _hasPin = false;
  bool _asksAtStartup = false;
  String _deviceName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final actor = await _profiles.getActiveProfileId();
    final admin = actor != null && await _profiles.isAdmin(actor);
    final pin = actor != null && await _profiles.hasAccessPin(actor);
    final asks = await _profiles.asksWhichLearnerAtStartup();
    final name = await _profiles.getDeviceDisplayName();
    if (!mounted) return;
    setState(() {
      _actorId = actor;
      _isAdmin = admin;
      _hasPin = pin;
      _asksAtStartup = asks;
      _deviceName = name;
      _loading = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStartupMode(bool asks) async {
    final actor = _actorId;
    if (actor == null) return;
    try {
      await _profiles.setAsksWhichLearnerAtStartup(
        actorProfileId: actor,
        enabled: asks,
      );
      await _load();
    } catch (error) {
      _snack(error.toString().replaceFirst('StateError: ', ''));
    }
  }

  Future<void> _editDeviceName() async {
    final actor = _actorId;
    if (actor == null) return;
    var entered = _deviceName;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QQL device name'),
        content: TextFormField(
          initialValue: _deviceName,
          onChanged: (name) => entered = name,
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
            onPressed: () => Navigator.pop(dialogContext, entered),
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
      await _load();
    } catch (error) {
      _snack(error.toString().replaceFirst('StateError: ', ''));
    }
  }

  Future<void> _setPin() async {
    final actor = _actorId;
    if (actor == null) return;
    final pin = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Set your PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset options can delete learner data permanently, so they '
                  'are protected by your PIN. The PIN is also asked for every '
                  'time you log in to your profile, and again before every '
                  'reset. Choose 4 digits you will remember. If you forget '
                  'it, another admin can reset it from the Learner Profiles list.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin-set-pin'),
                  controller: pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'New PIN'),
                ),
                TextField(
                  key: const Key('admin-set-pin-confirm'),
                  controller: confirm,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Repeat PIN'),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (pin.text != confirm.text) {
                  setLocal(() => error = 'The two PINs are different.');
                  return;
                }
                try {
                  await _profiles.setOwnAccessPin(
                    actorProfileId: actor,
                    pin: pin.text,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on ArgumentError catch (e) {
                  setLocal(
                    () => error = e.message?.toString() ?? 'Invalid PIN.',
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    pin.dispose();
    confirm.dispose();
    if (saved == true) await _load();
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Administration'),
        actions: [
          IconButton(
            key: const Key('admin-help'),
            tooltip: 'Device Administration Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const DeviceAdministrationHelpScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Device Administration is available only to admins.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      const _Intro(),
                      _sectionTitle('Learners'),
                      ListTile(
                        key: const Key('admin-manage-learners'),
                        leading: const Icon(Icons.people_outline),
                        title: const Text('Manage learners'),
                        subtitle: const Text(
                          'Opens the Learner Profiles list: switch learner, add a learner, make or remove admins, reset a learner PIN, or delete a learner. The only admin cannot be deleted.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onManageLearners(context),
                      ),
                      SwitchListTile(
                        key: const Key('admin-startup-mode'),
                        secondary: const Icon(Icons.login_outlined),
                        title: const Text('Ask who is learning at startup'),
                        subtitle: Text(
                          _asksAtStartup
                              ? 'On: every time QQL starts, the learner list is shown and the learner chooses who they are. Nobody is resumed automatically. This applies only when the device has more than one learner; with a single learner QQL simply opens that learner.'
                              : 'Off: QQL opens directly as the learner who used it last. Turn this on for shared devices, so each learner chooses their own profile at startup. It applies only when the device has more than one learner.',
                        ),
                        value: _asksAtStartup,
                        onChanged: _setStartupMode,
                      ),
                      _sectionTitle('Device'),
                      ListTile(
                        key: const Key('admin-device-name'),
                        leading: const Icon(Icons.computer_outlined),
                        title: const Text('QQL device name'),
                        subtitle: Text(
                          '$_deviceName\nThis descriptive name is shown at the top of the Learner Profiles list.',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: _editDeviceName,
                      ),
                      _sectionTitle('Media'),
                      ListTile(
                        key: const Key('admin-media-library'),
                        leading: const Icon(Icons.perm_media_outlined),
                        title: const Text('Admin Media Library'),
                        subtitle: const Text(
                          'Manage the shared image library and its descriptive metadata. The same library is available from Course Manager.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _push(
                          FlatImageLibraryScreen(
                            selectMode: false,
                            metadataEditingEnabled: true,
                            actorProfileId: _actorId,
                          ),
                        ),
                      ),
                      _sectionTitle('Inventory'),
                      ListTile(
                        key: const Key('admin-inventory'),
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Inventory'),
                        subtitle: const Text(
                          'Lists everything QQL has stored because of what people did, with its location, size, date and the learner it belongs to: learners, custom courses, imported images and audio files, imports, exports, automatic course backups and logs, including files added to the QQL folders from outside the app.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _push(const InventoryScreen()),
                      ),
                      _sectionTitle('Reset'),
                      _ResetSection(
                        hasPin: _hasPin,
                        actorId: _actorId!,
                        course: widget.course,
                        profiles: _profiles,
                        service: _reset,
                        onSetPin: _setPin,
                        onDone: _load,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Text(
      'Device Administration gathers the administrator features of this QQL installation in one place. Every feature here is also still available where it always was. Only admins can see this page.',
    ),
  );
}

class _ResetPlan {
  final AppResetScope scope;
  final String title;
  final String summary;
  final List<String> removes;
  final List<String> keeps;
  final String? warning;
  final String buttonLabel;

  const _ResetPlan({
    required this.scope,
    required this.title,
    required this.summary,
    required this.removes,
    required this.keeps,
    required this.buttonLabel,
    this.warning,
  });
}

const _plans = <_ResetPlan>[
  _ResetPlan(
    scope: AppResetScope.learnerProgress,
    title: 'Reset learner progress',
    buttonLabel: 'Reset progress…',
    summary:
        'Starts every learner on this device again from zero progress, without deleting any learner.',
    removes: [
      'Completed Rounds, Lessons and Duels, and seen GuideBooks',
      'XP, weekly XP, streaks and study days',
      'Vocabulary review memory',
    ],
    keeps: [
      'Learners, names, avatars and PINs',
      'Learner settings such as theme and audio',
      'All courses, media, backups and logs',
    ],
  ),
  _ResetPlan(
    scope: AppResetScope.nonAdminLearners,
    title: 'Remove all learners except admins',
    buttonLabel: 'Remove learners…',
    summary:
        'Deletes every learner who is not an admin, together with everything stored for them.',
    removes: [
      'Each non-admin learner: profile, progress, settings and PIN',
      'The Team registry, if it lists any of the removed learners, which also removes Team memberships and Team ownership records',
    ],
    keeps: [
      'Admin learners and their data',
      'Courses, media, backups and logs',
    ],
    warning:
        'Deleted learners cannot log in again unless you have a learner backup or recovery key for them.',
  ),
  _ResetPlan(
    scope: AppResetScope.importedMedia,
    title: 'Remove imported media',
    buttonLabel: 'Remove media…',
    summary:
        'Deletes the media files QQL copied into its own storage when you imported them. You choose in the first step whether to remove the imported images, the imported audio files, or both.',
    removes: [
      'Imported images, if you tick Images: exercise images and image banks, plus any tag, label or category edits made to the shared image library, which then returns to its built-in defaults',
      'Imported audio files, if you tick Audio files: the recorded MP3 files, with their descriptions',
    ],
    keeps: [
      'The media that comes with QQL itself: the built-in image library, flags, lesson icons, mascots and the recordings of the bundled courses',
      'Learners and progress',
      'Courses (which may then show missing media until it is imported again)',
      'The original files you placed in the Imports folder, backups and logs',
    ],
  ),
  _ResetPlan(
    scope: AppResetScope.customCourses,
    title: 'Remove custom courses',
    buttonLabel: 'Remove courses…',
    summary:
        'Deletes every course created or installed on this device, and the authoring Teams that own them.',
    removes: [
      'All custom and installed external courses, and the course recovery copy',
      'All authoring Teams',
      'All imported media: every imported image (exercise images and image banks) and every imported recorded MP3 audio file',
    ],
    keeps: [
      'Learners, PINs and settings',
      'The bundled official courses',
      'Backups and logs',
    ],
    warning:
        'Learner progress on removed courses stays stored but is no longer shown. Export your courses first if you want to keep them.',
  ),
  _ResetPlan(
    scope: AppResetScope.everything,
    title: 'Wipe out everything (NUKE EVERYTHING!)',
    buttonLabel: 'NUKE EVERYTHING…',
    summary:
        'Returns QQL to the state of a brand-new installation on this device.',
    removes: [
      'All learners, admins, PINs, progress and settings, including yours',
      'All custom courses, Teams and imported media (images and MP3 audio files)',
      'The device name and all other saved preferences',
      'Every other file QQL stored, except what you choose to keep',
    ],
    keeps: [
      'Only the Exports, Logs and Imports folders, unless you untick them in the first step. Imports holds the original files you copied there yourself.',
      'The bundled official courses (part of the app)',
    ],
    warning:
        'This cannot be undone. The next person who opens QQL will see the first-run setup.',
  ),
];

/// What the admin chose in the first dialog. Keep options apply to the full
/// wipe; remove options apply to "Remove imported media".
class _ResetChoices {
  final bool keepExports;
  final bool keepLogs;
  final bool keepImports;
  final bool removeImages;
  final bool removeAudio;

  const _ResetChoices({
    this.keepExports = true,
    this.keepLogs = true,
    this.keepImports = true,
    this.removeImages = true,
    this.removeAudio = true,
  });
}

class _ResetSection extends StatelessWidget {
  final bool hasPin;
  final String actorId;
  final Course course;
  final ProfileService profiles;
  final AppResetService service;
  final Future<void> Function() onSetPin;
  final Future<void> Function() onDone;

  const _ResetSection({
    required this.hasPin,
    required this.actorId,
    required this.course,
    required this.profiles,
    required this.service,
    required this.onSetPin,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!hasPin) {
      return Card(
        key: const Key('admin-reset-locked'),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reset options are locked',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Resets delete data permanently. To prevent accidents, and to stop someone using an unattended device from wiping it, every reset asks for your admin PIN. You have not set a PIN yet, so the reset options are hidden. Set a 4-digit PIN to unlock them.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('admin-reset-set-pin'),
                onPressed: onSetPin,
                icon: const Icon(Icons.pin_outlined),
                label: const Text('Set PIN'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Each reset below explains exactly what it removes and what it keeps, offers a backup, and asks for your PIN before anything is deleted. Nothing happens until you finish every step.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final plan in _plans)
          Card(
            key: Key('admin-reset-${plan.scope.name}'),
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(plan.summary),
                  const SizedBox(height: 8),
                  _Bullets(heading: 'Removes', items: plan.removes),
                  const SizedBox(height: 4),
                  _Bullets(heading: 'Keeps', items: plan.keeps),
                  if (plan.warning != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      plan.warning!,
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: Key('admin-reset-button-${plan.scope.name}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: () => _begin(context, plan),
                    child: Text(plan.buttonLabel),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _begin(BuildContext context, _ResetPlan plan) async {
    final preview = await service.preview();
    final learners = await profiles.getProfileRecords();
    final admins = await profiles.getAdminProfileIds();
    if (!context.mounted) return;
    final others = learners
        .where((l) => l.learnerProfileId != actorId)
        .map((l) => l.displayName)
        .toList();
    final affected = plan.scope == AppResetScope.nonAdminLearners
        ? learners
              .where((l) => !admins.contains(l.learnerProfileId))
              .map((l) => l.displayName)
              .toList()
        : others;

    // Step 1: explanation with the real numbers for this device. For the
    // full wipe it also holds the choice of what to keep, near the top.
    final choices = await _explainDialog(context, plan, preview, affected);
    if (choices == null || !context.mounted) return;

    // Step 2: backup offer.
    final backup = await _backupOffer(context, plan, affected);
    if (backup != true || !context.mounted) return;

    // Step 3 (everything only): a reminder of what is included, and the
    // typed confirmation.
    if (plan.scope == AppResetScope.everything) {
      final typed = await _nukeConfirmation(context, choices);
      if (typed != true || !context.mounted) return;
    }

    // Step 4: PIN, checked by the service itself.
    final done = await _askPinAndRun(context, plan, choices);
    if (done != true || !context.mounted) return;
    if (plan.scope == AppResetScope.everything) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      AppRestartScope.restart(context);
      return;
    }
    await onDone();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${plan.title}: done.')));
  }

  Widget _explanation(
    _ResetPlan plan,
    AppResetPreview preview,
    List<String> affectedLearners, {
    Widget? afterSummary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(plan.summary),
        const SizedBox(height: 8),
        if (afterSummary != null) ...[afterSummary, const SizedBox(height: 8)],
        _Bullets(heading: 'This will remove', items: plan.removes),
        const SizedBox(height: 4),
        _Bullets(heading: 'This will keep', items: plan.keeps),
        const SizedBox(height: 8),
        Text(
          'On this device right now: ${preview.learnerCount} learner(s), '
          '${preview.imageFileCount} imported image file(s), '
          '${preview.audioFileCount} imported audio file(s), '
          '${preview.hasCustomCourses ? 'custom courses or Teams are stored' : 'no custom courses or Teams'}.',
        ),
        if (affectedLearners.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            plan.scope == AppResetScope.everything ||
                    plan.scope == AppResetScope.nonAdminLearners
                ? 'The data of these learners will be deleted too: ${affectedLearners.join(', ')}.'
                : 'This affects every learner, including: ${affectedLearners.join(', ')}.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        if (plan.warning != null) ...[
          const SizedBox(height: 8),
          Text(
            plan.warning!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 8),
        const Text('This cannot be undone.'),
      ],
    );
  }

  Future<_ResetChoices?> _explainDialog(
    BuildContext context,
    _ResetPlan plan,
    AppResetPreview preview,
    List<String> affected,
  ) async {
    var keepExports = true;
    var keepLogs = true;
    var keepImports = true;
    // Removing media asks the admin to opt in: nothing is ticked at first.
    var removeImages = false;
    var removeAudio = false;
    final isMedia = plan.scope == AppResetScope.importedMedia;
    // A kind with nothing stored cannot be ticked. Images also count the
    // settings records that the reset clears even without image files.
    final noImages =
        preview.imageFileCount == 0 && !preview.hasImageLibraryRecords;
    final noAudio = preview.audioFileCount == 0;
    return showDialog<_ResetChoices>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) {
          Widget? choiceBlock;
          if (plan.scope == AppResetScope.everything) {
            choiceBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose what to keep. All three are kept unless you untick them, and the choice is used only if you finish every step.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                CheckboxListTile(
                  key: const Key('admin-nuke-keep-exports'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: keepExports,
                  onChanged: (v) => setLocal(() => keepExports = v ?? true),
                  title: const Text('Keep the Exports folder'),
                  subtitle: const Text(
                    'Your learner and course backups. Untick to delete them permanently.',
                  ),
                ),
                CheckboxListTile(
                  key: const Key('admin-nuke-keep-logs'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: keepLogs,
                  onChanged: (v) => setLocal(() => keepLogs = v ?? true),
                  title: const Text('Keep the Logs folder'),
                  subtitle: const Text(
                    'Crash and diagnostic logs, useful when reporting a problem. Untick to delete them.',
                  ),
                ),
                CheckboxListTile(
                  key: const Key('admin-nuke-keep-imports'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: keepImports,
                  onChanged: (v) => setLocal(() => keepImports = v ?? true),
                  title: const Text('Keep the Imports folder'),
                  subtitle: const Text(
                    'The original images, audio files and course files you copied into QuisquisLingo/Imports yourself. Untick to delete them.',
                  ),
                ),
              ],
            );
          } else if (isMedia) {
            choiceBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose what to remove. Nothing is ticked at first; tick at least one to continue.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (noImages && noAudio)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'There is no imported media to remove.',
                      key: Key('admin-media-nothing'),
                    ),
                  ),
                CheckboxListTile(
                  key: const Key('admin-media-remove-images'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: removeImages,
                  onChanged: noImages
                      ? null
                      : (v) => setLocal(() => removeImages = v ?? false),
                  title: Text(
                    noImages
                        ? 'Images (0 files): nothing to remove'
                        : 'Images (${preview.imageFileCount} file(s)${preview.imageFileCount == 0 ? ', library edits or image-bank list stored' : ''})',
                  ),
                  subtitle: const Text(
                    'Imported exercise images and image banks, and any edits to the shared image library, which returns to its built-in defaults.',
                  ),
                ),
                CheckboxListTile(
                  key: const Key('admin-media-remove-audio'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: removeAudio,
                  onChanged: noAudio
                      ? null
                      : (v) => setLocal(() => removeAudio = v ?? false),
                  title: Text(
                    noAudio
                        ? 'Audio files (0 files): nothing to remove'
                        : 'Audio files (${preview.audioFileCount} file(s))',
                  ),
                  subtitle: const Text(
                    'Imported recorded MP3 files. Exercises that use them will play no recording.',
                  ),
                ),
              ],
            );
          }
          final canContinue = !isMedia || removeImages || removeAudio;
          return AlertDialog(
            title: Text(plan.title),
            content: SingleChildScrollView(
              child: _explanation(
                plan,
                preview,
                affected,
                afterSummary: choiceBlock,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('admin-reset-continue'),
                onPressed: canContinue
                    ? () => Navigator.pop(
                        dialogContext,
                        _ResetChoices(
                          keepExports: keepExports,
                          keepLogs: keepLogs,
                          keepImports: keepImports,
                          removeImages: removeImages,
                          removeAudio: removeAudio,
                        ),
                      )
                    : null,
                child: const Text('I understand, continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The admin's own User Data is affected only by these two resets, so only
  /// they offer the shortcut to it.
  bool _affectsAdminData(_ResetPlan plan) =>
      plan.scope == AppResetScope.learnerProgress ||
      plan.scope == AppResetScope.everything;

  String _backupText(_ResetPlan plan, List<String> affectedOthers) {
    final buffer = StringBuffer(
      'A backup lets you restore what you are about to delete. Backups are saved in the QuisquisLingo/Exports folder, which a full wipe keeps unless you untick it.\n\n',
    );
    final touchesLearners =
        _affectsAdminData(plan) || plan.scope == AppResetScope.nonAdminLearners;
    if (touchesLearners) {
      buffer.write(
        'Learner backups are personal. An admin cannot export another learner’s data.',
      );
      if (_affectsAdminData(plan)) {
        buffer.write(
          ' "Open my User Data" backs up only YOUR OWN data, as the admin who is logged in now.',
        );
      } else {
        buffer.write(' This reset does not delete your own data.');
      }
      if (affectedOthers.isNotEmpty) {
        buffer.write(
          ' To let the other learners keep a backup, ask each of them to log in and use Profile → User Data → Export my data before you continue: ${affectedOthers.join(', ')}.',
        );
      }
      buffer.write('\n\n');
    }
    if (plan.scope == AppResetScope.customCourses ||
        plan.scope == AppResetScope.everything) {
      buffer.write(
        'Courses are exported one at a time from Course Manager.\n\n',
      );
    }
    buffer.write(
      _affectsAdminData(plan)
          ? 'You can open User Data now, make your backup, and then start this reset again.'
          : 'Make any backups first, then start this reset again.',
    );
    return buffer.toString();
  }

  Future<bool?> _backupOffer(
    BuildContext context,
    _ResetPlan plan,
    List<String> others,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Back up first?'),
        content: SingleChildScrollView(child: Text(_backupText(plan, others))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel reset'),
          ),
          if (_affectsAdminData(plan))
            OutlinedButton(
              key: const Key('admin-reset-open-backup'),
              onPressed: () async {
                Navigator.pop(dialogContext, false);
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => UserDataSettingsScreen(course: course),
                  ),
                );
              },
              child: const Text('Open my User Data to back up'),
            ),
          FilledButton(
            key: const Key('admin-reset-skip-backup'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue without a new backup'),
          ),
        ],
      ),
    );
  }

  static const _nukePhrase = 'NUKE EVERYTHING';

  Future<bool?> _nukeConfirmation(BuildContext context, _ResetChoices choices) {
    final typed = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Wipe out everything'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Everything QQL stored on this device will be deleted, including every learner and admin.',
                ),
                const SizedBox(height: 8),
                Text(
                  choices.keepExports
                      ? 'Exports folder: kept.'
                      : 'Exports folder: will be DELETED with everything else.',
                  key: const Key('admin-nuke-reminder-exports'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  choices.keepLogs
                      ? 'Logs folder: kept.'
                      : 'Logs folder: will be DELETED with everything else.',
                  key: const Key('admin-nuke-reminder-logs'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  choices.keepImports
                      ? 'Imports folder: kept.'
                      : 'Imports folder: will be DELETED with everything else.',
                  key: const Key('admin-nuke-reminder-imports'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text('To change this, cancel and start the reset again.'),
                const SizedBox(height: 12),
                Text(
                  'To continue, type $_nukePhrase exactly, in capital letters, with a space between the two words:',
                ),
                TextField(
                  key: const Key('admin-nuke-phrase'),
                  controller: typed,
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(labelText: 'Type $_nukePhrase'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('admin-nuke-continue'),
              onPressed: typed.text == _nukePhrase
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Continue to PIN'),
            ),
          ],
        ),
      ),
    ).whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      typed.dispose();
    });
  }

  Future<bool?> _askPinAndRun(
    BuildContext context,
    _ResetPlan plan,
    _ResetChoices choices,
  ) {
    final pin = TextEditingController();
    String? error;
    var running = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Enter your PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last step. Enter your admin PIN to run "${plan.title}". Nothing has been deleted so far.',
                ),
                if (plan.scope == AppResetScope.importedMedia) ...[
                  const SizedBox(height: 8),
                  Text(
                    choices.removeImages
                        ? 'Images: will be REMOVED.'
                        : 'Images: kept.',
                    key: const Key('admin-pin-reminder-images'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    choices.removeAudio
                        ? 'Audio files: will be REMOVED.'
                        : 'Audio files: kept.',
                    key: const Key('admin-pin-reminder-audio'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'To change this, cancel and start the reset again.',
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  key: const Key('admin-reset-pin'),
                  controller: pin,
                  obscureText: true,
                  autofocus: true,
                  enabled: !running,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                if (running) const LinearProgressIndicator(),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
              key: const Key('admin-reset-run'),
              onPressed: running
                  ? null
                  : () async {
                      setLocal(() {
                        running = true;
                        error = null;
                      });
                      try {
                        await service.reset(
                          plan.scope,
                          actorProfileId: actorId,
                          pin: pin.text,
                          keepExports: choices.keepExports,
                          keepLogs: choices.keepLogs,
                          keepImports: choices.keepImports,
                          removeImages: choices.removeImages,
                          removeAudio: choices.removeAudio,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } on AppResetException catch (e) {
                        setLocal(() {
                          running = false;
                          error = e.message;
                        });
                      } catch (e) {
                        setLocal(() {
                          running = false;
                          error =
                              'The reset could not be completed: $e. Some data may already have been removed; you can run the reset again.';
                        });
                      }
                    },
              child: const Text('Reset now'),
            ),
          ],
        ),
      ),
    ).whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      pin.dispose();
    });
  }
}

class _Bullets extends StatelessWidget {
  final String heading;
  final List<String> items;

  const _Bullets({required this.heading, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(heading, style: const TextStyle(fontWeight: FontWeight.w600)),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(item)),
            ],
          ),
        ),
    ],
  );
}

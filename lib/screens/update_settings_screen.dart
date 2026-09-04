import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_metadata.dart';
import '../services/diagnostic_log_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';

class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({super.key});

  @override
  State<UpdateSettingsScreen> createState() => _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  final _settings = SettingsService();
  final _updates = UpdateService();
  final _diagnosticLog = DiagnosticLogService();

  String _currentVersion = AppMetadata.technicalVersion;
  bool _automatic = false;
  DateTime? _lastChecked;
  bool _checking = false;
  UpdateCheckResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final automatic = await _settings.isAutomaticUpdateCheckEnabled();
      final lastChecked = await _settings.getUpdateLastCheckedAt();
      if (!mounted) return;
      setState(() {
        _currentVersion = AppMetadata.technicalVersion;
        _automatic = automatic;
        _lastChecked = lastChecked;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Update settings could not be read on this platform.';
      });
    }
  }

  Future<void> _setAutomatic(bool value) async {
    await _settings.setAutomaticUpdateCheckEnabled(value);
    if (!mounted) return;
    setState(() => _automatic = value);
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final checkedAt = DateTime.now();
    await _settings.setUpdateLastCheckedAt(checkedAt);
    if (mounted) setState(() => _lastChecked = checkedAt);
    try {
      final result = await _updates.check(_currentVersion);
      await _diagnosticLog.logInfo(
        'Manual GitHub update check completed: ${result.status.name}; '
        'current=$_currentVersion; latest=${result.release?.version ?? 'none'}.',
      );
      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } on UpdateCheckException catch (error) {
      await _diagnosticLog.logInfo(
        'Manual GitHub update check failed: ${error.message}',
      );
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      await _diagnosticLog.logInfo(
        'Manual GitHub update check failed with an unexpected local error.',
      );
      if (!mounted) return;
      setState(
        () => _error =
            'Unable to check for updates. QuisquisLingo remains fully usable offline.',
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openRepository() async {
    final opened = await _updates.openRepository();
    if (!opened && mounted) {
      _message('Could not open the GitHub repository.');
    }
  }

  Future<void> _openRelease(UpdateRelease release) async {
    final opened = await _updates.openRelease(release);
    if (!opened && mounted) {
      _message('Could not open the GitHub release page.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(seconds: 8), content: Text(text)),
    );
  }

  String _formatLastChecked() {
    final value = _lastChecked;
    if (value == null) return 'Never';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final release = result?.release;
    return Scaffold(
      appBar: AppBar(title: const Text('Update')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Current version'),
            subtitle: Text(_currentVersion),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub repository'),
            subtitle: const SelectableText(UpdateService.repositoryUrl),
            trailing: IconButton(
              tooltip: 'Open GitHub repository',
              icon: const Icon(Icons.open_in_new),
              onPressed: _openRepository,
            ),
            onLongPress: () async {
              await Clipboard.setData(
                const ClipboardData(text: UpdateService.repositoryUrl),
              );
              if (mounted) _message('GitHub repository address copied.');
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Check automatically at startup'),
            subtitle: const Text(
              'When enabled, QuisquisLingo contacts only the official GitHub Releases API at startup. '
              'No learner data, course data, credentials or analytics are sent.',
            ),
            value: _automatic,
            onChanged: _setAutomatic,
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Last checked'),
            subtitle: Text(_formatLastChecked()),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _checking ? null : _check,
            icon: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_checking ? 'Checking...' : 'Check for updates'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.cloud_off_outlined,
              title: 'Update check unavailable',
              body: '${_error!}\n\nQuisquisLingo remains fully usable offline.',
            ),
          ],
          if (result?.status == UpdateCheckStatus.noPublishedRelease) ...[
            const SizedBox(height: 12),
            const _StatusCard(
              icon: Icons.inventory_2_outlined,
              title: 'No published release',
              body:
                  'No published QuisquisLingo release is currently available in the GitHub Releases section.',
            ),
          ],
          if (result?.status == UpdateCheckStatus.upToDate &&
              release != null) ...[
            const SizedBox(height: 12),
            _StatusCard(
              icon: Icons.check_circle_outline,
              title: 'QuisquisLingo is up to date',
              body: 'Latest published release: ${release.version}',
            ),
          ],
          if (result?.status == UpdateCheckStatus.updateAvailable &&
              release != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New version available: ${release.version}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (release.title.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(release.title),
                    ],
                    if (release.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        release.notes,
                        maxLines: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _openRelease(release),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open GitHub release page'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Download and installation',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'QuisquisLingo never downloads, installs or executes an update automatically. '
              'Use only files published in the official GitHub release. Keep your existing app data unless the release notes explicitly say otherwise.',
            ),
            const SizedBox(height: 12),
            _PlatformInstructions(
              title: '1. Windows',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.windows,
              ),
              instructions:
                  'Download the Windows asset from the GitHub release. Close QuisquisLingo, then install the new package or replace the previous standalone application as described in that release. Reopen QuisquisLingo after installation.',
            ),
            _PlatformInstructions(
              title: '2. macOS',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.macos,
              ),
              instructions:
                  'Download the macOS asset from the GitHub release. Close QuisquisLingo, install or replace the application, then reopen it. Follow any signing or Gatekeeper instructions stated in the release.',
            ),
            _PlatformInstructions(
              title: '3. Linux antiX',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.linuxAntix,
              ),
              instructions:
                  'Download the antiX package from the GitHub release. Close QuisquisLingo and install the package using the antiX/Debian package tools described in the release. Then start QuisquisLingo again from the menu or the quisquislingo command.',
            ),
            _PlatformInstructions(
              title: '4. Android',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.android,
              ),
              instructions:
                  'Download the Android package from the GitHub release and install it as an update over the existing QuisquisLingo installation. Android may ask you to authorize installation from that source.',
            ),
            _PlatformInstructions(
              title: '5. iOS',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.ios,
              ),
              instructions:
                  'Use the iOS distribution method stated in the GitHub release, such as TestFlight or another explicitly documented installation route. Do not remove the existing app unless the release instructions require it.',
            ),
            _PlatformInstructions(
              title: '6. Web',
              available: _updates.platformAvailable(
                release,
                UpdatePlatform.web,
              ),
              instructions:
                  'No local installation is required. Open or reload the web version at the address stated in the GitHub release.',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Security: update checks are read-only. QuisquisLingo contacts the fixed HTTPS GitHub Releases API for this repository, accepts only bounded release metadata, rejects unexpected redirects and URLs, and never sends learner or course content.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
    ),
  );
}

class _PlatformInstructions extends StatelessWidget {
  final String title;
  final bool available;
  final String instructions;
  const _PlatformInstructions({
    required this.title,
    required this.available,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            available
                ? 'Available in this release.'
                : 'Not currently available in this release.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: available ? Colors.green.shade800 : Colors.black54,
            ),
          ),
          if (available) ...[const SizedBox(height: 6), Text(instructions)],
        ],
      ),
    ),
  );
}

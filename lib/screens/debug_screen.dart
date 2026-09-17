import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/crash_log_service.dart';
import '../services/diagnostic_log_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _logs = DiagnosticLogService();
  bool _loading = true;
  bool _hasDiagnosticLog = false;
  String? _diagnosticExportPath;
  String? _crashLogPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    unawaited(
      CrashLogService.instance.recordDebugEvent('Debug: _load started'),
    );
    try {
      final hasDiagnosticLog = await _logs.hasEntries();
      final diagnosticExportPath = await _logs.exportPath();
      final crashLogPath = CrashLogService.instance.crashLogPath;
      if (!mounted) return;
      setState(() {
        _hasDiagnosticLog = hasDiagnosticLog;
        _diagnosticExportPath = diagnosticExportPath;
        _crashLogPath = crashLogPath;
        _loading = false;
      });
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'DebugScreen._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Debug information could not be loaded. Safe defaults are being used.',
            ),
          ),
        );
      });
    }
  }

  Future<void> _clearLog() async {
    await _logs.clear();
    if (!mounted) return;
    setState(() => _hasDiagnosticLog = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text('Diagnostic log cleared.'),
      ),
    );
  }

  Future<void> _exportDiagnosticLog() async {
    final path = await _logs.exportToFile();
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'The Diagnostic Log is empty or could not be exported.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _hasDiagnosticLog = true;
      _diagnosticExportPath = path;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('Diagnostic Log exported to $path'),
      ),
    );
  }

  Future<void> _shareCrashLog() async {
    final path = _crashLogPath;
    if (path == null || !await File(path).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('The Crash Log is not available to share.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/plain')],
          subject: 'QuisquisLingo Crash Log',
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('The Crash Log could not be shared.'),
        ),
      );
    }
  }

  void _showHelp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DebugHelpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        actions: [
          IconButton(
            key: const Key('debug-help'),
            tooltip: 'Debug Help',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Crash Log'),
                  subtitle: Text(
                    'For cases where QQL crashes or closes unexpectedly. If available after a crash, copy or export this file and provide it with your report. It is primarily useful for startup and runtime crashes.\n'
                    'Saved at: ${_crashLogPath ?? 'Path unavailable on this platform.'}',
                  ),
                  trailing: !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                      ? IconButton(
                          tooltip: 'Share Crash Log',
                          onPressed: _crashLogPath == null
                              ? null
                              : _shareCrashLog,
                          icon: const Icon(Icons.share_outlined),
                        )
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Diagnostic Log'),
                  subtitle: Text(
                    'For problems that do not necessarily crash QQL, including audio, TTS, Recorded MP3, unexpected playback, source-resolution problems, and other runtime anomalies. When possible, reproduce the problem and export this log shortly afterward. To isolate one specific reproducible problem, you may clear it first; clearing is optional. For intermittent or difficult-to-reproduce problems, export the current Diagnostic Log before clearing to preserve existing evidence.\n'
                    'Export location: ${_diagnosticExportPath ?? 'Unavailable on this platform.'}',
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Export Diagnostic Log',
                        onPressed: _hasDiagnosticLog
                            ? _exportDiagnosticLog
                            : null,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      IconButton(
                        tooltip: 'Clear Diagnostic Log',
                        onPressed: _hasDiagnosticLog ? _clearLog : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Privacy: learner audio diagnostics are designed to avoid recording spoken text, answers, course content, or full personal file paths.',
                  ),
                ),
              ],
            ),
    );
  }
}

class DebugHelpScreen extends StatelessWidget {
  const DebugHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Debug Help')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _DebugHelpSection(
          title: 'Crash Log',
          body:
              'This Beta version keeps an automatic local Crash Log to help investigate crashes and other serious technical problems.\n\n'
              'For cases where QQL crashes or closes unexpectedly. If available after a crash, copy or export this file and provide it with your report. It is primarily useful for startup and runtime crashes.\n\n'
              'Please use the app normally and reproduce the crash. After the app closes, reopen it if necessary. When you send the Crash Log, also say what you clicked immediately before the crash. Please send the whole log file, not a screenshot of it.\n\n'
              'The Crash Log contains technical system information, session starts, uncaught errors and stack traces. It does not intentionally record learner names, exercise answers or course content.\n\n'
              'If the Crash Log file is deleted, QuisquisLingo recreates it automatically at the next app start or crash write.',
        ),
        _DebugHelpSection(
          title: 'Diagnostic Log',
          body:
              'For problems that do not necessarily crash QQL, including audio, TTS, Recorded MP3, unexpected playback, source-resolution problems, and other runtime anomalies. When possible, reproduce the problem and export this log shortly afterward. To isolate one specific reproducible problem, you may clear it first; clearing is optional. For intermittent or difficult-to-reproduce problems, export the current Diagnostic Log before clearing to preserve existing evidence.',
        ),
        _DebugHelpSection(
          title: 'Privacy',
          body:
              'Learner audio diagnostics are designed to avoid recording spoken text, answers, course content, or full personal file paths.',
        ),
      ],
    ),
  );
}

class _DebugHelpSection extends StatelessWidget {
  const _DebugHelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}

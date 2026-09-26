import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../services/crash_log_service.dart';
import '../services/diagnostic_log_service.dart';
import '../services/file_dialog_service.dart';
import '../widgets/app_locale_selector.dart';
import '../widgets/file_dialog_feedback.dart';
import '../services/storage/qql_storage.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _logs = DiagnosticLogService();
  final _dialogs = FileDialogService();
  bool _loading = true;
  bool _hasDiagnosticLog = false;
  String? _diagnosticExportPath;
  String? _crashLogPath;
  String? _crashExportPath;

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
      final crashExportPath = await CrashLogService.instance.exportPath();
      if (!mounted) return;
      setState(() {
        _hasDiagnosticLog = hasDiagnosticLog;
        _diagnosticExportPath = diagnosticExportPath;
        _crashLogPath = crashLogPath;
        _crashExportPath = crashExportPath;
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

  Future<void> _saveDiagnosticLogCopyTo() async {
    try {
      final bytes = await _logs.exportBytes();
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('The Diagnostic Log is empty.'),
          ),
        );
        return;
      }
      final result = await _dialogs.saveBytes(
        bytes: bytes,
        suggestedName: DiagnosticLogService.exportFileName,
        extensions: const ['txt'],
        artifact: 'diagnostic-log',
      );
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        result,
        saving: true,
        savedMessage: 'Diagnostic Log copy saved as ${result.displayName}.',
        fallbackHint:
            'You can use Export Diagnostic Log instead; it saves to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.diagnosticLogExports)}.',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('The Diagnostic Log copy could not be saved.'),
        ),
      );
    }
  }

  /// Quick Export: a copy of the live Crash Log in the Logs folder, with no
  /// dialog, replacing the previous copy.
  Future<void> _quickExportCrashLog() async {
    String message;
    try {
      final written = await CrashLogService.instance.exportCopy();
      message = written == null
          ? 'The Crash Log is not available to export.'
          : 'Crash Log copy exported to ${written.location}';
    } catch (_) {
      message = 'The Crash Log copy could not be exported.';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(seconds: 8), content: Text(message)),
    );
  }

  /// Saves a copy of the live Crash Log. The live file is only read: it is
  /// never moved, opened for editing or changed.
  Future<void> _saveCrashLogCopyTo() async {
    final path = _crashLogPath;
    try {
      if (path == null || !await File(path).exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('The Crash Log is not available to save.'),
          ),
        );
        return;
      }
      final bytes = await File(path).readAsBytes();
      final result = await _dialogs.saveBytes(
        bytes: bytes,
        suggestedName: CrashLogService.exportFileName,
        extensions: const ['txt', 'log'],
        artifact: 'crash-log',
      );
      if (!mounted) return;
      showFileDialogFeedback(
        context,
        result,
        saving: true,
        savedMessage: 'Crash Log copy saved as ${result.displayName}.',
        fallbackHint:
            'You can use Quick Export instead; it saves a copy to ${QqlStorageLayout.current.folderLabel(QqlStorageRole.diagnosticLogExports)}.',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('The Crash Log copy could not be saved.'),
        ),
      );
    }
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
                    'Saved at: ${_crashLogPath ?? 'Path unavailable on this platform.'}\n'
                    'Quick Export location: ${_crashExportPath ?? 'Unavailable on this platform.'}',
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        key: const Key('quick-export-crash-log'),
                        tooltip: 'Quick Export Crash Log',
                        onPressed: _crashLogPath == null
                            ? null
                            : _quickExportCrashLog,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      if (_dialogs.isAvailable)
                        IconButton(
                          key: const Key('save-crash-log-copy-to'),
                          tooltip: 'Save log copy as…',
                          onPressed: _crashLogPath == null
                              ? null
                              : _saveCrashLogCopyTo,
                          icon: const Icon(Icons.save_alt_outlined),
                        ),
                      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                        IconButton(
                          tooltip: 'Share Crash Log',
                          onPressed: _crashLogPath == null
                              ? null
                              : _shareCrashLog,
                          icon: const Icon(Icons.share_outlined),
                        ),
                    ],
                  ),
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
                      if (_dialogs.isAvailable)
                        IconButton(
                          key: const Key('save-diagnostic-log-copy-to'),
                          tooltip: 'Save log copy as…',
                          onPressed: _hasDiagnosticLog
                              ? _saveDiagnosticLogCopyTo
                              : null,
                          icon: const Icon(Icons.save_alt_outlined),
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
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(helpText.lookup(locale, 'debugHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('debug-help-locale-selector'),
            locale: locale,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final sectionId in debugHelpSectionIds)
            _DebugHelpSection(
              title: helpText.lookup(locale, 'debugHelp.$sectionId.title'),
              body: helpText.lookup(locale, 'debugHelp.$sectionId.body'),
            ),
        ],
      ),
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

import 'dart:async';

import 'package:flutter/material.dart';

import '../services/file_dialog_service.dart';
import '../services/qql_tools_service.dart';
import '../services/settings_service.dart';

/// Optional external validator controls on the Admin-only device page.
class QqlToolsPanel extends StatefulWidget {
  const QqlToolsPanel({
    super.key,
    required this.actorProfileId,
    this.settings,
    this.tools,
    this.dialogs,
    this.desktopAvailable,
  });

  final String actorProfileId;
  final SettingsService? settings;
  final QqlToolsService? tools;
  final FileDialogService? dialogs;
  final bool? desktopAvailable;

  @override
  State<QqlToolsPanel> createState() => _QqlToolsPanelState();
}

class _QqlToolsPanelState extends State<QqlToolsPanel> {
  late final SettingsService _settings = widget.settings ?? SettingsService();
  late final QqlToolsService _tools =
      widget.tools ??
      QqlToolsService(
        settings: _settings,
        desktopAvailable: widget.desktopAvailable,
      );
  late final FileDialogService _dialogs = widget.dialogs ?? FileDialogService();

  bool get _isDesktop => widget.desktopAvailable ?? _tools.isDesktopAvailable;

  bool _loading = true;
  bool _busy = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) unawaited(_load());
  }

  Future<void> _load() async {
    String? path;
    try {
      path = await _settings.getQqlToolsExecutablePath();
    } catch (_) {
      path = null;
    }
    if (!mounted) return;
    setState(() {
      _path = path;
      _loading = false;
    });
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        await _showMessage('QQL-Tools operation could not be completed.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _browse() async {
    final selected = await _dialogs.pickDesktopPath(
      extensions: const [],
      artifact: 'QQL-Tools executable',
    );
    if (!mounted || selected.outcome == FileDialogOutcome.cancelled) return;
    if (selected.outcome != FileDialogOutcome.opened || selected.path == null) {
      await _showMessage('Could not open the file picker.');
      return;
    }
    try {
      await _settings.setQqlToolsExecutablePath(
        actorProfileId: widget.actorProfileId,
        path: selected.path!,
      );
      if (mounted) setState(() => _path = selected.path);
    } catch (_) {
      if (mounted) {
        await _showMessage(
          'Could not save the QQL-Tools executable. Select a local executable file.',
        );
      }
    }
  }

  Future<void> _clear() async {
    try {
      await _settings.clearQqlToolsExecutablePath(
        actorProfileId: widget.actorProfileId,
      );
      if (mounted) setState(() => _path = null);
    } catch (_) {
      if (mounted) await _showMessage('Could not clear the QQL-Tools path.');
    }
  }

  Future<void> _test() async {
    final result = await _tools.testAvailability(
      actorProfileId: widget.actorProfileId,
    );
    if (!mounted) return;
    await _showMessage(
      result.available
          ? 'QQL-Tools is available on this device.'
          : 'QQL-Tools could not be started. Check the configured path.',
    );
  }

  Future<void> _validate() async {
    final selected = await _dialogs.pickDesktopPath(
      extensions: const ['json', 'zip'],
      artifact: 'QQL Course file for QQL-Tools validation',
    );
    if (!mounted || selected.outcome == FileDialogOutcome.cancelled) return;
    if (selected.outcome != FileDialogOutcome.opened || selected.path == null) {
      await _showMessage('Could not open the file picker.');
      return;
    }
    final result = await _tools.validateCourse(
      actorProfileId: widget.actorProfileId,
      coursePath: selected.path!,
    );
    if (!mounted) return;
    final report = result.report;
    if (report == null) {
      await _showMessage(_failureMessage(result.failure));
      return;
    }
    await _showReport(report);
  }

  String _failureMessage(QqlToolsFailure? failure) => switch (failure) {
    QqlToolsFailure.unsupportedPlatform => 'Not available on mobile devices.',
    QqlToolsFailure.unauthorized => 'Only an Admin can use QQL-Tools.',
    QqlToolsFailure.notConfigured =>
      'Configure QQL-Tools before validating a Course file.',
    QqlToolsFailure.invalidCourseFile =>
      'Select a QQL Course JSON file or package ZIP.',
    QqlToolsFailure.invalidExecutable =>
      'QQL-Tools could not be started. Check the configured path.',
    QqlToolsFailure.emptyOutput || QqlToolsFailure.malformedJson =>
      'QQL-Tools returned an unusable validation result.',
    QqlToolsFailure.unknownExitCode =>
      'QQL-Tools reported an external-tool execution problem.',
    _ => 'QQL-Tools validation could not be completed.',
  };

  Future<void> _showMessage(String message) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('QQL-Tools'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Future<void> _showReport(QqlToolsValidationReport report) {
    final rows = _reportRows(report);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.65;
        return AlertDialog(
          title: const Text('QQL-Tools validation'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
            child: SizedBox(
              width: double.maxFinite,
              height: rows.length > 5 ? maxHeight : rows.length * 48.0,
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      top: row.heading ? 12 : 0,
                      bottom: row.heading ? 4 : 8,
                    ),
                    child: Text(
                      row.text,
                      style: row.status
                          ? Theme.of(context).textTheme.titleMedium
                          : row.heading
                          ? Theme.of(context).textTheme.titleSmall
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<({String text, bool heading, bool status})> _reportRows(
    QqlToolsValidationReport report,
  ) {
    final rows = <({String text, bool heading, bool status})>[
      (
        text: switch (report.status) {
          QqlToolsValidationStatus.fullyValid => 'Fully valid',
          QqlToolsValidationStatus.validForImplementedChecks =>
            'Valid for all currently implemented checks',
          QqlToolsValidationStatus.invalid => 'Invalid',
        },
        heading: false,
        status: true,
      ),
    ];
    if (report.status == QqlToolsValidationStatus.validForImplementedChecks) {
      rows.add((
        text: 'This does not mean complete validation.',
        heading: false,
        status: false,
      ));
    }
    void addSection(String title, List<String> items) {
      if (items.isEmpty) return;
      rows.add((text: title, heading: true, status: false));
      for (final item in items) {
        rows.add((text: '• $item', heading: false, status: false));
      }
    }

    addSection('Errors', [
      for (final error in report.errors)
        error.location == null
            ? error.message
            : '${error.message} (${error.location})',
    ]);
    addSection('Implemented checks', report.implementedChecks);
    addSection('Checks not yet implemented', report.unsupportedChecks);
    addSection('Notes', report.notes);
    return rows;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional external tools for independently validating QQL Course files and packages.',
        ),
        if (!_isDesktop) ...[
          const SizedBox(height: 8),
          const Text('Not available on mobile devices.'),
        ] else ...[
          const SizedBox(height: 12),
          const Text('QQL-Tools executable'),
          const SizedBox(height: 4),
          if (_loading)
            const LinearProgressIndicator()
          else
            SelectableText(_path ?? 'Not configured.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('qql-tools-browse'),
                onPressed: _busy || _loading ? null : () => _withBusy(_browse),
                child: const Text('Browse...'),
              ),
              OutlinedButton(
                key: const Key('qql-tools-test'),
                onPressed: _busy || _loading || _path == null
                    ? null
                    : () => _withBusy(_test),
                child: const Text('Test'),
              ),
              OutlinedButton(
                key: const Key('qql-tools-clear'),
                onPressed: _busy || _loading || _path == null
                    ? null
                    : () => _withBusy(_clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('qql-tools-validate'),
            onPressed: _busy || _loading || _path == null
                ? null
                : () => _withBusy(_validate),
            child: const Text('Validate with QQL-Tools...'),
          ),
          if (_busy) ...[const SizedBox(height: 8), const Text('Working...')],
        ],
      ],
    ),
  );
}

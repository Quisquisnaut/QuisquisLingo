import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_errors.dart';
import '../services/diagnostic_log_service.dart';

/// [error] as people read it: without the Dart type names in front
/// ("Bad state: ", "FormatException: ", "Invalid argument(s): ").
String readableError(Object error) => '$error'.replaceFirst(
  RegExp(
    r'^(Bad state|FormatException|Invalid argument\(s\)|Exception|'
    r'FileSystemException|PathAccessException|PathNotFoundException): ?',
  ),
  '',
);

/// Runs [action] for a button or a screen's first load (Build 266 Revision 2,
/// owner rule of 8 October 2026: no button may fail silently). An error it
/// throws is written to the Diagnostic Log with [what] and shown as a
/// SnackBar ("[what] could not finish: …"); the result is then null.
///
/// For actions that already explain their own errors, keep their messages:
/// this is for the awaited calls that had none.
Future<T?> runReported<T>(
  BuildContext context,
  String what,
  Future<T> Function() action, {
  DiagnosticLogService? diagnostics,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    unawaited(
      (diagnostics ?? DiagnosticLogService()).log(
        AppErrorCode.unexpectedError,
        context: '$what could not finish.',
        exception: error,
        stackTrace: stackTrace,
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          key: const Key('reported-action-error'),
          duration: const Duration(seconds: 10),
          content: Text('$what could not finish: ${readableError(error)}'),
        ),
      );
    }
    return null;
  }
}

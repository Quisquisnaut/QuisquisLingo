import 'package:flutter/material.dart';
import 'app_errors.dart';

class ErrorPresenter {
  static Future<void> show(
    BuildContext context,
    AppErrorCode error,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text('${error.userMessage}\n\nError ${error.code}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

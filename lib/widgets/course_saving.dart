import 'dart:async';

import 'package:flutter/material.dart';

import '../services/course_editor_service.dart';

/// Shows that a Course is being saved, and where the save is (Build 271
/// Revision 3, owner reports of 11 and 12 October 2026: after Save the
/// Editor stayed in use with no sign that it was still writing, and the time
/// a save takes was not signalled).
abstract final class CourseSaving {
  /// Runs [save] behind a small window that nothing can be pressed around,
  /// Back included, and that shows each step [save] reports, with a bar.
  /// The window is on the screen before the work starts and goes when it
  /// ends, whether it succeeds or throws.
  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function(void Function(CourseSaveProgress progress) onProgress)
    save,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = ValueNotifier<CourseSaveProgress>(
      const CourseSaveProgress(CourseSaveStep.checking),
    );
    // No fade: a save starts with work that leaves no time to draw one, and
    // the window has to be there at once.
    final route = RawDialogRoute<void>(
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) =>
          PopScope(canPop: false, child: CourseSavingWindow(progress)),
    );
    unawaited(navigator.push(route));
    try {
      await _drawn();
      return await save((value) => progress.value = value);
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  /// How long the save waits for the window to be drawn. Frames stop while
  /// the app is hidden (a minimized window), and a save must never wait for
  /// one that does not come.
  static const drawnWithin = Duration(milliseconds: 250);

  /// Completes when the frame that draws the window is done, or after
  /// [drawnWithin] when no frame comes.
  static Future<void> _drawn() {
    final drawn = Completer<void>();
    final giveUp = Timer(drawnWithin, () {
      if (!drawn.isCompleted) drawn.complete();
    });
    WidgetsBinding.instance.endOfFrame.then((_) {
      giveUp.cancel();
      if (!drawn.isCompleted) drawn.complete();
    });
    return drawn.future;
  }
}

/// The window [CourseSaving.run] shows: the step in words and a bar that
/// fills as the save goes on.
class CourseSavingWindow extends StatelessWidget {
  const CourseSavingWindow(this.progress, {super.key});

  final ValueNotifier<CourseSaveProgress> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('course-saving'),
      content: SizedBox(
        width: 360,
        child: ValueListenableBuilder<CourseSaveProgress>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.save_outlined),
                  SizedBox(width: 16),
                  Expanded(child: Text('Saving the Course…')),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                key: const Key('course-saving-bar'),
                value: value.fraction,
              ),
              const SizedBox(height: 8),
              Text(
                value.label,
                key: const Key('course-saving-step'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

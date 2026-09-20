import 'package:flutter_test/flutter_test.dart';

/// Waits for a specified UI state while real filesystem futures make progress.
/// Completion is determined by the predicate, never by elapsed time or frames.
extension FileIoPumping on WidgetTester {
  Future<void> pumpUntilFileIoState(bool Function() reached) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    do {
      await runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await pump(const Duration(milliseconds: 100));
      if (DateTime.now().isAfter(deadline)) {
        throw StateError(
          'Expected UI state did not arrive after filesystem work.',
        );
      }
    } while (!reached() || binding.hasScheduledFrame);
  }
}

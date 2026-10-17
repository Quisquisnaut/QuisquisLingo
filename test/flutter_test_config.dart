import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/spoken_line_pace.dart';
import 'package:quisquislingo_app/widgets/course_import_check_dialog.dart';
import 'package:quisquislingo_app/widgets/exercise_editor_intro.dart';
import 'package:quisquislingo_app/widgets/exercise_mascot.dart';
import 'package:quisquislingo_app/widgets/primitive_intro.dart';
import 'package:quisquislingo_app/widgets/shared_device_notice.dart';
import 'package:quisquislingo_app/widgets/word_lookup_view.dart';
import 'support/laboratory_fixture.dart';
import 'support/test_directories.dart';

/// Runs once per test file, before its `main()`.
///
/// Learner screens ask [BetaLifecycleService] whether the Beta has expired
/// without passing a date, so Home, Round, Duel and Review would all render
/// `BetaExpiredView` once the real clock passed the expiry — turning the whole
/// suite red on a fixed calendar day. Pinning the clock relative to the expiry
/// keeps the suite deterministic and survives every expiry refresh, so this
/// file needs no maintenance when the Beta lifetime moves.
///
/// Fifteen days before expiry is deliberately outside every warning milestone
/// (7 / 3 / 1 / 0 days), so tests see the ordinary, unwarned learner state.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Calendar construction avoids shifting the pinned day across autumn DST.
  BetaLifecycleService.clock = () => DateTime(
    BetaLifecycleService.expiryDate.year,
    BetaLifecycleService.expiryDate.month,
    BetaLifecycleService.expiryDate.day - 15,
    12,
  );
  // File-backed course storage is used by both authoring and profile services.
  // Give every test its own real filesystem, including callers created by UI.
  // Individual tests can still override the channel for their own fixtures.
  TestWidgetsFlutterBinding.ensureInitialized();
  // The first-time Exercise Editor introduction is a modal dialog; it would
  // block every editor test on its first open. Its own test turns it on.
  ExerciseEditorIntro.enabled = false;
  // The canonical editor's primitive popups (Build 261 Revision 6) would
  // block every canonical editor test the same way; their test turns them on.
  PrimitiveIntro.enabled = false;
  // A random mascot beside an exercise's sentence (Build 256 Revision 9)
  // would make every Round screen test depend on a picture; the mascot
  // tests turn it on.
  ExerciseMascot.enabled = false;
  // Word Lookup's one-time notice (Build 265) is a dialog over the first
  // Round of a Course with GuideBook vocabulary; its test turns it on.
  WordLookupNotice.enabled = false;
  SharedDeviceNotice.enabled = false;
  // The pop-up of a Course import (Build 272 Revision 13) would stop
  // every import test written before it. Its own tests turn it on.
  CourseImportCheckDialog.enabled = false;
  // Continue with Wizard's question before the languages become fixed
  // (Build 275 Revision 3) would stop every Course Wizard test written
  // before it. Its own test turns it on.
  CourseWizardScreen.confirmsLanguages = false;
  // A Course save flushes its folder through the system's `sync` on Linux
  // and macOS (Build 271 Revision 1): no test starts a process for it; the
  // Course store's own test uses a recording one.
  CourseFileStore.syncDirectory = (_) async {};
  // No Course comes with the app (Build 272 Revision 17). The tests written
  // while the Exercise Laboratory was bundled keep it as a bundled test
  // Course: registered here for a file's setUpAll, and again before every
  // test, because a test of the app as it ships removes it
  // (unregisterLaboratoryFixture).
  registerLaboratoryFixture();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory root;
  var installedHandler = false;
  setUp(() {
    registerLaboratoryFixture();
    // The Round screen's seams and the pace of spoken Story lines are
    // static (Build 271 Revision 5): every test starts from the app's own,
    // so one test's stand-in or measured pace never reaches the next.
    RoundScreen.openLink = RoundScreen.launchLink;
    RoundScreen.lineStopwatch = Stopwatch.new;
    SpokenLinePace.shared.reset();
    // Cached asset futures must not cross widget-test fake-async zones.
    rootBundle.clear();
    root = Directory.systemTemp.createTempSync('qql_test_');
    final support = Directory('${root.path}/support')..createSync();
    testSupportDirectory = support;
    final documents = Directory('${root.path}/documents')..createSync();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    installedHandler = messenger.checkMockMessageHandler(
      pathProvider.name,
      null,
    );
    if (!installedHandler) return;
    messenger.setMockMethodCallHandler(pathProvider, (call) async {
      switch (call.method) {
        case 'getApplicationSupportDirectory':
          return support.path;
        case 'getApplicationDocumentsDirectory':
          return documents.path;
        default:
          throw MissingPluginException('No test directory for ${call.method}');
      }
    });
  });
  tearDown(() async {
    if (installedHandler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, null);
    }
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (await root.exists()) await root.delete(recursive: true);
        break;
      } on FileSystemException {
        if (attempt == 4) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
  });
  await testMain();
}

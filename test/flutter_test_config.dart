import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/beta_lifecycle_service.dart';
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
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory root;
  var installedHandler = false;
  setUp(() {
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

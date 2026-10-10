import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/bounded_log_writer.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/atomic_preferences_store.dart';
import 'package:quisquislingo_app/widgets/learner_data_notices.dart';
import 'package:quisquislingo_app/widgets/learner_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

final _sep = Platform.pathSeparator;

// Build 270 Revision 0: the Diagnostic Log in its own file, the learner's
// notices about the learner-data file, and the safety copies in the
// Inventory and Wipe everything.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearnerDataNotices.debugReset();
    keepCrashLogUnavailable();
  });
  tearDown(() => DiagnosticLogService.debugUseFile(null));

  group('Diagnostic Log file', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('qql_diag_270_');
      addTearDown(() => directory.delete(recursive: true));
    });

    test('entries go to the file, never to the learner-data file', () async {
      final file = File('${directory.path}${_sep}QQL_diagnostic.log');
      DiagnosticLogService.debugUseFile(file);
      final log = DiagnosticLogService();
      await Future.wait([for (var i = 0; i < 20; i++) log.logInfo('event-$i')]);
      final text = await file.readAsString();
      for (var i = 0; i < 20; i++) {
        expect(text, contains('event-$i'));
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_diagnostic_log'), isNull);
      expect(await log.hasEntries(), isTrue);
      expect(String.fromCharCodes((await log.exportBytes())!), text);

      await log.clear();
      expect(await file.exists(), isFalse);
      expect(await log.hasEntries(), isFalse);
      expect(await log.exportBytes(), isNull);
    });

    test('initialise moves the earlier entries over once', () async {
      SharedPreferences.setMockInitialValues({
        'quisquislingo_diagnostic_log': '[earlier] INFO\nfrom 269\n---\n',
      });
      // logsDirectory resolves through the test's app support folder.
      await DiagnosticLogService.initialise();
      final file = DiagnosticLogService.logFile!;
      expect(file.path, endsWith('QQL_Logs${_sep}QQL_diagnostic.log'));
      expect(await file.readAsString(), contains('from 269'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('quisquislingo_diagnostic_log'), isFalse);
      await DiagnosticLogService().logInfo('from 270');
      final text = await file.readAsString();
      expect(text.indexOf('from 269'), lessThan(text.indexOf('from 270')));
      await file.delete();
    });

    test('a full log is trimmed to three quarters, so the next entries are '
        'plain appends', () async {
      final file = File('${directory.path}${_sep}bounded.log');
      await BoundedLogWriter.appendFile(
        file,
        '${List.filled(90, 'a').join()}\n',
        maximumBytes: 100,
      );
      await BoundedLogWriter.appendFile(file, 'new\n', maximumBytes: 100);
      final length = await file.length();
      expect(length, lessThanOrEqualTo(75));
      expect(await file.readAsString(), endsWith('new\n'));
    });
  });

  group('learner notices', () {
    testWidgets('a failed save shows one SnackBar a minute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: learnerNavigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      const failure = LearnerDataProblem(
        LearnerDataProblemKind.writeFailed,
        error: FileSystemException('disk full'),
      );
      LearnerDataNotices.report(failure);
      await tester.pump();
      expect(find.byKey(const Key('learner-data-write-failed')), findsOne);
      LearnerDataNotices.report(failure);
      await tester.pump();
      expect(find.byKey(const Key('learner-data-write-failed')), findsOne);
      expect(LearnerDataNotices.pendingRecovery, isNull);
    });

    testWidgets('QQL tells the learner after start-up when the last good copy '
        'was used', (tester) async {
      LearnerDataNotices.report(
        LearnerDataProblem(
          LearnerDataProblemKind.restoredLastGood,
          damagedCopy: 'C:${_sep}x${_sep}QQL_learner_data_damaged_1.json',
          lastGoodSavedAt: DateTime(2026, 10, 9, 18, 30),
        ),
      );
      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: ProfileService(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();
      await tester.pump();
      final dialog = find.byKey(const Key('learner-data-recovery'));
      expect(dialog, findsOne);
      expect(find.text('Learner data restored'), findsOne);
      expect(
        find.textContaining('2026-10-09 18:30'),
        findsOne,
        reason: 'the time of the copy that was used',
      );
      expect(find.textContaining('QQL_learner_data_damaged_1.json'), findsOne);
      expect(find.textContaining('${_sep}x$_sep'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(LearnerDataNotices.pendingRecovery, isNull);
    });

    testWidgets('the learner page waits for the dialog instead of covering '
        'it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: learnerNavigatorKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      LearnerDataNotices.report(
        const LearnerDataProblem(LearnerDataProblemKind.startedEmpty),
      );
      var appDone = false;
      var pageDone = false;
      LearnerDataNotices.showPendingRecovery().then((_) => appDone = true);
      LearnerDataNotices.showPendingRecovery().then((_) => pageDone = true);
      await tester.pump();
      expect(find.byKey(const Key('learner-data-recovery')), findsOne);
      expect(pageDone, isFalse);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect((appDone, pageDone), (true, true));
      // Shown once.
      await LearnerDataNotices.showPendingRecovery();
      await tester.pump();
      expect(find.byKey(const Key('learner-data-recovery')), findsNothing);
    });

    testWidgets('a start without any readable data says how to restore', (
      tester,
    ) async {
      LearnerDataNotices.report(
        const LearnerDataProblem(LearnerDataProblemKind.startedEmpty),
      );
      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: ProfileService(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Learner data could not be read'), findsOne);
      expect(find.textContaining('Profile › User Data'), findsOne);
    });
  });

  group('safety copies', () {
    late Directory documents;
    late Directory support;

    setUp(() async {
      final root = await Directory.systemTemp.createTemp('qql_270_copies_');
      addTearDown(() => root.delete(recursive: true));
      documents = await Directory('${root.path}${_sep}documents').create();
      support = await Directory('${root.path}${_sep}support').create();
      for (final name in [
        AtomicPreferencesStore.lastGoodFileName,
        '${AtomicPreferencesStore.damagedFilePrefix}20261010_0300.json',
        // Not a safety copy: the learner-data file itself.
        AtomicPreferencesStore.fileName,
      ]) {
        await File('${support.path}$_sep$name').writeAsString('{}');
      }
    });

    test('the Inventory lists them', () async {
      final sections = await InventoryService(
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
        courses: () async => const [],
        teams: () async => const [],
      ).load();
      final section = sections.singleWhere(
        (s) => s.title == 'Learner-data safety copies',
      );
      expect([for (final item in section.items) item.name]..sort(), [
        '${AtomicPreferencesStore.damagedFilePrefix}20261010_0300.json',
        AtomicPreferencesStore.lastGoodFileName,
      ]);
    });

    test('Wipe everything removes them, whatever is kept', () async {
      final profiles = ProfileService();
      final admin = (await profiles.createProfile('Admin')).learnerProfileId;
      await profiles.setOwnAccessPin(actorProfileId: admin, pin: '1234');
      await AppResetService(
        profiles: profiles,
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
      ).reset(AppResetScope.everything, actorProfileId: admin, pin: '1234');
      expect(await AtomicPreferencesStore.safetyCopiesIn(support), isEmpty);
    });
  });
}

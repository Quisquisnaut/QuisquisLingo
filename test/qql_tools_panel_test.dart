import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/device_administration_screen.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/qql_tools_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/qql_tools_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Settings extends SettingsService {
  String? path;
  String? lastActor;
  int reads = 0;

  @override
  Future<String?> getQqlToolsExecutablePath() async {
    reads++;
    return path;
  }

  @override
  Future<void> setQqlToolsExecutablePath({
    required String actorProfileId,
    required String path,
  }) async {
    lastActor = actorProfileId;
    this.path = path;
  }

  @override
  Future<void> clearQqlToolsExecutablePath({
    required String actorProfileId,
  }) async {
    lastActor = actorProfileId;
    path = null;
  }
}

class _Tools extends QqlToolsService {
  _Tools() : super(desktopAvailable: true);

  QqlToolsTestResult testResult = const QqlToolsTestResult.available();
  QqlToolsValidationResult validationResult =
      const QqlToolsValidationResult.failed(QqlToolsFailure.notConfigured);
  int testCalls = 0;
  int validationCalls = 0;
  String? coursePath;

  @override
  Future<QqlToolsTestResult> testAvailability({
    required String actorProfileId,
  }) async {
    testCalls++;
    return testResult;
  }

  @override
  Future<QqlToolsValidationResult> validateCourse({
    required String actorProfileId,
    required String coursePath,
  }) async {
    validationCalls++;
    this.coursePath = coursePath;
    return validationResult;
  }
}

class _Dialogs extends FileDialogService {
  _Dialogs() : super(backend: const UnavailableFileDialogBackend());

  FileDialogPathResult next = const FileDialogPathResult.cancelled();
  final requestedExtensions = <List<String>>[];

  @override
  Future<FileDialogPathResult> pickDesktopPath({
    required List<String> extensions,
    required String artifact,
  }) async {
    requestedExtensions.add(extensions);
    return next;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Device Administration shows QQL-Tools only to an Admin', (
    tester,
  ) async {
    final profiles = ProfileService();
    final admin = await profiles.createProfile('Admin');
    await profiles.setActiveProfileById(admin.learnerProfileId);
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DeviceAdministrationScreen(
          course: null,
          onManageLearners: (_) async {},
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('QQL-Tools'), findsOneWidget);
    expect(
      find.text(
        'Optional external tools for independently validating QQL Course files and packages.',
      ),
      findsOneWidget,
    );

    final learner = await profiles.createProfile('Learner');
    await profiles.setActiveProfileById(learner.learnerProfileId);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceAdministrationScreen(
          course: null,
          onManageLearners: (_) async {},
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('QQL-Tools'), findsNothing);
  });

  testWidgets(
    'Manage learners hides the device path after switching to a learner',
    (tester) async {
      const executablePath = r'C:\Tools\qql-tools.exe';
      SharedPreferences.setMockInitialValues({
        'qql_tools_executable_path_v1': executablePath,
      });
      final profiles = ProfileService();
      final admin = await profiles.createProfile('Admin');
      final learner = await profiles.createProfile('Learner');
      await profiles.setActiveProfileById(admin.learnerProfileId);

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceAdministrationScreen(
            course: null,
            onManageLearners: (_) async {
              await profiles.setActiveProfileById(learner.learnerProfileId);
            },
            profileService: profiles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(executablePath), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin-manage-learners')));
      await tester.pumpAndSettle();

      expect(
        find.text('Device Administration is available only to admins.'),
        findsOneWidget,
      );
      expect(find.text(executablePath), findsNothing);
      expect(find.text('QQL-Tools'), findsNothing);
    },
  );

  Future<void> pumpPanel(
    WidgetTester tester, {
    required _Settings settings,
    required _Tools tools,
    required _Dialogs dialogs,
    bool desktopAvailable = true,
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QqlToolsPanel(
              actorProfileId: 'admin-id',
              settings: settings,
              tools: tools,
              dialogs: dialogs,
              desktopAvailable: desktopAvailable,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile explains unavailability without loading or launching', (
    tester,
  ) async {
    final settings = _Settings();
    final tools = _Tools();
    final dialogs = _Dialogs();
    await pumpPanel(
      tester,
      settings: settings,
      tools: tools,
      dialogs: dialogs,
      desktopAvailable: false,
    );

    expect(find.text('Not available on mobile devices.'), findsOneWidget);
    expect(find.text('Browse...'), findsNothing);
    expect(find.text('Validate with QQL-Tools...'), findsNothing);
    expect(settings.reads, 0);
    expect(tools.testCalls, 0);
    expect(tools.validationCalls, 0);
    expect(dialogs.requestedExtensions, isEmpty);
  });

  testWidgets('Browse saves a file path and Clear removes it', (tester) async {
    final settings = _Settings();
    final tools = _Tools();
    final dialogs = _Dialogs()
      ..next = FileDialogPathResult.picked(r'C:\Tools\qql-tools.exe');
    await pumpPanel(tester, settings: settings, tools: tools, dialogs: dialogs);

    expect(find.text('Not configured.'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Test'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Validate with QQL-Tools...'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Browse...'));
    await tester.pumpAndSettle();
    expect(dialogs.requestedExtensions, [<String>[]]);
    expect(settings.path, r'C:\Tools\qql-tools.exe');
    expect(settings.lastActor, 'admin-id');
    expect(find.text(r'C:\Tools\qql-tools.exe'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(settings.path, isNull);
    expect(find.text('Not configured.'), findsOneWidget);
  });

  testWidgets('Test reports availability and failure with simple messages', (
    tester,
  ) async {
    final settings = _Settings()..path = r'C:\Tools\qql-tools.exe';
    final tools = _Tools();
    await pumpPanel(
      tester,
      settings: settings,
      tools: tools,
      dialogs: _Dialogs(),
    );

    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.text('QQL-Tools is available on this device.'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    tools.testResult = const QqlToolsTestResult.failed(
      QqlToolsFailure.launchFailed,
    );
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(
      find.text('QQL-Tools could not be started. Check the configured path.'),
      findsOneWidget,
    );
    expect(tools.testCalls, 2);
  });

  testWidgets(
    'partial report never says Fully valid and shows missing checks',
    (tester) async {
      final settings = _Settings()..path = r'C:\Tools\qql-tools.exe';
      final tools = _Tools()
        ..validationResult = QqlToolsValidationResult.report(
          const QqlToolsValidationReport(
            isValid: true,
            isFullyValid: false,
            errors: [],
            notes: ['Check coverage is growing.'],
            implementedChecks: ['Structure'],
            unsupportedChecks: ['Media provenance'],
          ),
        );
      final dialogs = _Dialogs()
        ..next = FileDialogPathResult.picked(r'C:\Courses\my course.zip');
      await pumpPanel(
        tester,
        settings: settings,
        tools: tools,
        dialogs: dialogs,
      );

      await tester.tap(find.text('Validate with QQL-Tools...'));
      await tester.pumpAndSettle();

      expect(dialogs.requestedExtensions, [
        <String>['json', 'zip'],
      ]);
      expect(tools.coursePath, r'C:\Courses\my course.zip');
      expect(find.text('QQL-Tools validation'), findsOneWidget);
      expect(
        find.text('Valid for all currently implemented checks'),
        findsOneWidget,
      );
      expect(find.text('Fully valid'), findsNothing);
      expect(
        find.textContaining('does not mean complete validation'),
        findsOneWidget,
      );
      expect(find.textContaining('Media provenance'), findsOneWidget);
      expect(find.textContaining('Structure'), findsOneWidget);
      expect(find.textContaining('Check coverage is growing.'), findsOneWidget);
    },
  );

  testWidgets('invalid report displays external validator errors', (
    tester,
  ) async {
    final settings = _Settings()..path = r'C:\Tools\qql-tools.exe';
    final tools = _Tools()
      ..validationResult = QqlToolsValidationResult.report(
        const QqlToolsValidationReport(
          isValid: false,
          isFullyValid: false,
          errors: [
            QqlToolsValidationError(
              code: 'course.id',
              message: 'Missing Course ID',
              location: 'course.json',
            ),
          ],
          notes: [],
          implementedChecks: [],
          unsupportedChecks: [],
        ),
      );
    final dialogs = _Dialogs()
      ..next = FileDialogPathResult.picked(r'C:\Courses\invalid.json');
    await pumpPanel(tester, settings: settings, tools: tools, dialogs: dialogs);

    await tester.tap(find.text('Validate with QQL-Tools...'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid'), findsOneWidget);
    expect(find.textContaining('Missing Course ID'), findsOneWidget);
    expect(find.text('Course Audit'), findsNothing);
  });

  testWidgets('long QQL-Tools report scrolls on a narrow desktop window', (
    tester,
  ) async {
    final settings = _Settings()..path = r'C:\Tools\qql-tools.exe';
    final tools = _Tools()
      ..validationResult = QqlToolsValidationResult.report(
        QqlToolsValidationReport(
          isValid: true,
          isFullyValid: false,
          errors: const [],
          notes: const [],
          implementedChecks: const [],
          unsupportedChecks: [for (var i = 0; i < 80; i++) 'Missing check $i'],
        ),
      );
    final dialogs = _Dialogs()
      ..next = FileDialogPathResult.picked(r'C:\Courses\many checks.json');
    await pumpPanel(
      tester,
      settings: settings,
      tools: tools,
      dialogs: dialogs,
      size: const Size(320, 700),
    );

    await tester.tap(find.text('Validate with QQL-Tools...'));
    await tester.pumpAndSettle();
    expect(find.byType(Text).evaluate().length, lessThan(40));
    final lastCheck = find.textContaining('Missing check 79');
    await tester.scrollUntilVisible(
      lastCheck,
      300,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getRect(lastCheck).bottom, lessThan(700));
  });
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'services/app_metadata.dart';
import 'services/window_setup.dart';
import 'services/crash_log_service.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/profile_service.dart';
import 'services/learner_status_events.dart';
import 'services/startup_diagnostic_service.dart';
import 'services/diagnostic_log_service.dart';
import 'services/update_service.dart';
import 'widgets/flag_art.dart';
import 'widgets/learner_shell.dart';
import 'widgets/learner_navigation.dart';
import 'widgets/learner_theme_mode_scope.dart';

Future<void> main() async {
  StartupDiagnosticService.checkpoint('DART_MAIN_ENTER');
  // Keep Flutter binding initialization and runApp in the same Dart zone.
  // This preserves global crash capture without triggering Flutter's
  // Zone mismatch warning or zone-dependent state inconsistencies.
  await runZonedGuarded<Future<void>>(
    () async {
      StartupDiagnosticService.verboseCheckpoint('DART_ZONE_ENTER');
      StartupDiagnosticService.verboseCheckpoint('DART_BINDING_BEGIN');
      WidgetsFlutterBinding.ensureInitialized();
      StartupDiagnosticService.checkpoint('DART_BINDING_OK');
      StartupDiagnosticService.verboseCheckpoint('DART_CRASH_LOG_INIT_BEGIN');
      await CrashLogService.instance.initialise();
      StartupDiagnosticService.checkpoint('DART_CRASH_LOG_INIT_RETURNED');
      CrashLogService.instance.installFlutterHandler();
      _installStartupDiagnosticErrorHandlers();
      StartupDiagnosticService.checkpoint('DART_ERROR_HANDLERS_INSTALLED');
      StartupDiagnosticService.checkpoint('DART_WINDOW_SETUP_BEGIN');
      await configureQuisquisLingoWindow();
      StartupDiagnosticService.checkpoint('DART_WINDOW_SETUP_RETURNED');
      StartupDiagnosticService.checkpoint('DART_RUNAPP_BEGIN');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StartupDiagnosticService.checkpointOnce('DART_FIRST_FRAME');
      });
      runApp(const QuisquisLingoApp());
      StartupDiagnosticService.checkpoint('DART_RUNAPP_RETURNED');
    },
    (error, stackTrace) {
      StartupDiagnosticService.recordError(
        'runZonedGuarded',
        error,
        stackTrace,
      );
      unawaited(
        CrashLogService.instance.record(
          error,
          stackTrace,
          source: 'runZonedGuarded',
        ),
      );
    },
  );
}

void _installStartupDiagnosticErrorHandlers() {
  final existingFlutterHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    StartupDiagnosticService.recordError(
      'FlutterError.onError',
      details.exception,
      details.stack ?? StackTrace.current,
    );
    existingFlutterHandler?.call(details);
  };

  final existingPlatformHandler = ui.PlatformDispatcher.instance.onError;
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    StartupDiagnosticService.recordError(
      'PlatformDispatcher.onError',
      error,
      stack,
    );
    return existingPlatformHandler?.call(error, stack) ?? false;
  };
}

class QuisquisLingoApp extends StatefulWidget {
  @visibleForTesting
  final ProfileService? profileService;

  @visibleForTesting
  final Widget? home;

  const QuisquisLingoApp({super.key, this.profileService, this.home});

  @override
  State<QuisquisLingoApp> createState() => _QuisquisLingoAppState();
}

class _QuisquisLingoAppState extends State<QuisquisLingoApp> {
  late final ProfileService _profiles;
  StreamSubscription<LearnerStatusInvalidation>? _appearanceSubscription;
  LearnerThemeMode _themeMode = LearnerThemeMode.defaultMode;
  LearnerFlagBackgroundMode _flagBackgroundMode =
      LearnerFlagBackgroundMode.small;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _appearanceSubscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.activeProfile ||
          event == LearnerStatusInvalidation.theme ||
          event == LearnerStatusInvalidation.flagBackground) {
        _loadAppearance();
      }
    });
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    final generation = ++_loadGeneration;
    var themeMode = LearnerThemeMode.defaultMode;
    var flagBackgroundMode = LearnerFlagBackgroundMode.small;
    try {
      themeMode = await _profiles.getThemeMode();
      flagBackgroundMode = await _profiles.getFlagBackgroundMode();
    } catch (_) {
      // Appearance loading falls back to the application's normal defaults.
    }
    if (!mounted || generation != _loadGeneration) return;
    if (themeMode == _themeMode && flagBackgroundMode == _flagBackgroundMode) {
      return;
    }
    setState(() {
      _themeMode = themeMode;
      _flagBackgroundMode = flagBackgroundMode;
    });
  }

  @override
  void dispose() {
    _appearanceSubscription?.cancel();
    super.dispose();
  }

  ThemeMode get _materialThemeMode => switch (_themeMode) {
    LearnerThemeMode.defaultMode => ThemeMode.system,
    LearnerThemeMode.light => ThemeMode.light,
    LearnerThemeMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    StartupDiagnosticService.verboseCheckpointOnce('DART_APP_BUILD');
    const olive = Color(0xFF4F622D);
    const cream = Color(0xFFF7F3E8);
    return MaterialApp(
      title: 'QuisquisLingo',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: learnerNavigatorKey,
      navigatorObservers: [learnerStatusRouteObserver],
      builder: (context, child) {
        final content = child == null
            ? const SizedBox.shrink()
            : LearnerShell(child: child);
        final scopedContent = LearnerFlagBackgroundModeScope(
          mode: _flagBackgroundMode,
          child: LearnerThemeModeScope(mode: _themeMode, child: content),
        );
        final portraitDesktop =
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS);
        if (!portraitDesktop) {
          return scopedContent;
        }
        return ColoredBox(
          color: const Color(0xFFE7E1CF),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: scopedContent,
            ),
          ),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: olive,
          brightness: Brightness.light,
          surface: cream,
        ),
        // Desktop users should get an unmistakable hover response on every
        // Material button without requiring each screen to define its own
        // MouseRegion or local style. The stronger hover is visual only and
        // does not alter button enabled/disabled behaviour.
        hoverColor: olive.withValues(alpha: .18),
        focusColor: olive.withValues(alpha: .12),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return olive.withValues(alpha: .24);
              }
              if (states.contains(WidgetState.hovered)) {
                return olive.withValues(alpha: .20);
              }
              if (states.contains(WidgetState.focused)) {
                return olive.withValues(alpha: .14);
              }
              return null;
            }),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return olive.withValues(alpha: .24);
              }
              if (states.contains(WidgetState.hovered)) {
                return olive.withValues(alpha: .20);
              }
              if (states.contains(WidgetState.focused)) {
                return olive.withValues(alpha: .14);
              }
              return null;
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return olive.withValues(alpha: .24);
              }
              if (states.contains(WidgetState.hovered)) {
                return olive.withValues(alpha: .20);
              }
              if (states.contains(WidgetState.focused)) {
                return olive.withValues(alpha: .14);
              }
              return null;
            }),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return olive.withValues(alpha: .24);
              }
              if (states.contains(WidgetState.hovered)) {
                return olive.withValues(alpha: .20);
              }
              if (states.contains(WidgetState.focused)) {
                return olive.withValues(alpha: .14);
              }
              return null;
            }),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return olive.withValues(alpha: .24);
              }
              if (states.contains(WidgetState.hovered)) {
                return olive.withValues(alpha: .20);
              }
              if (states.contains(WidgetState.focused)) {
                return olive.withValues(alpha: .14);
              }
              return null;
            }),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0x1F4F622D)),
          ),
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B09),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF54D8FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF151A17),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF151A17),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      themeMode: _materialThemeMode,
      home: widget.home ?? const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _show = true;

  @override
  void initState() {
    super.initState();
    StartupDiagnosticService.checkpointOnce('DART_STARTUP_GATE_INIT');
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _start();
  }

  Future<void> _start() async {
    StartupDiagnosticService.checkpoint('DART_STARTUP_SETTINGS_BEGIN');
    final enabled = await SettingsService().areAnimationsEnabled();
    StartupDiagnosticService.checkpoint(
      'DART_STARTUP_SETTINGS_OK',
      'animations_enabled=$enabled',
    );
    if (!mounted) return;
    if (!enabled || MediaQuery.maybeOf(context)?.disableAnimations == true) {
      setState(() => _show = false);
      return;
    }
    await _c.forward();
    if (mounted) setState(() => _show = false);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) {
      StartupDiagnosticService.checkpointOnce('DART_HOME_GATE_ENTER');
      return const _StartupCrashLogNotice(child: HomeScreen());
    }
    StartupDiagnosticService.verboseCheckpointOnce('DART_SPLASH_BUILD');
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/olive_tree.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(.70),
          ),
          const ColoredBox(color: Color(0x3DF7F3E8)),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _c,
              builder: (context, _) => _StartupFlags(
                progress: Curves.easeOutCubic.transform(_c.value),
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _c,
                curve: const Interval(.05, .72, curve: Curves.easeIn),
              ),
              child: ScaleTransition(
                scale: Tween(begin: .84, end: 1.0).animate(
                  CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x88FFFDF7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'QuisquisLingo',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupFlags extends StatelessWidget {
  final double progress;
  final double width;
  final double height;
  const _StartupFlags({
    required this.progress,
    required this.width,
    required this.height,
  });

  static const _codes = ['IT', 'DE', 'ES', 'PT', 'NL', 'CY', 'EN', 'FI', 'KO'];

  @override
  Widget build(BuildContext context) {
    final center = Offset(width / 2, height / 2);
    final radiusX = (width * .38).clamp(110.0, 180.0).toDouble();
    final radiusY = (height * .30).clamp(150.0, 235.0).toDouble();
    return Stack(
      children: List.generate(_codes.length, (i) {
        final angle = i * 6.28318530718 / _codes.length - 1.5708;
        final target = Offset(
          center.dx + radiusX * _cos(angle),
          center.dy + radiusY * _sin(angle),
        );
        final start = Offset(
          i.isEven ? -60 : width + 60,
          (height * (i + 1) / (_codes.length + 1))
              .clamp(20.0, height - 50)
              .toDouble(),
        );
        final p = ((progress - i * .045) / .72).clamp(0.0, 1.0).toDouble();
        final x = start.dx + (target.dx - start.dx) * p;
        final y = start.dy + (target.dy - start.dy) * p;
        return Positioned(
          left: x - 25,
          top: y - 18,
          child: Opacity(
            opacity: p,
            child: Transform.rotate(
              angle: (1 - p) * (i.isEven ? -.18 : .18),
              child: FlagBadge(_codes[i], width: 50, height: 35),
            ),
          ),
        );
      }),
    );
  }

  // Small polynomial approximations keep this widget dependency-free and are
  // accurate enough for decorative flag placement around the startup olive.
  double _sin(double x) {
    while (x > 3.14159265359) {
      x -= 6.28318530718;
    }
    while (x < -3.14159265359) {
      x += 6.28318530718;
    }
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040);
  }

  double _cos(double x) => _sin(x + 1.57079632679);
}

class _StartupCrashLogNotice extends StatefulWidget {
  final Widget child;

  const _StartupCrashLogNotice({required this.child});

  @override
  State<_StartupCrashLogNotice> createState() => _StartupCrashLogNoticeState();
}

class _StartupCrashLogNoticeState extends State<_StartupCrashLogNotice> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showInstructions());
    });
  }

  Future<void> _showInstructions() async {
    // Show the diagnostic path actually used on the current platform.
    // Windows still points testers to the easy-to-find Documents copy.
    final logPath =
        CrashLogService.instance.crashLogPath ??
        'QuisquisLingo crash log (path unavailable)';
    final media = MediaQuery.of(context);
    await CrashLogService.instance.recordDebugEvent(
      'Startup crash-log instructions displayed. Log path: $logPath; '
      'viewport: ${media.size.width.toStringAsFixed(1)}x${media.size.height.toStringAsFixed(1)}; '
      'devicePixelRatio: ${media.devicePixelRatio.toStringAsFixed(2)}',
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QuisquisLingo Alpha testing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Alpha version keeps an automatic local Crash Log to help investigate crashes and other serious technical problems.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Please use the app normally and reproduce the crash. After the app closes, reopen it if necessary.',
              ),
              const SizedBox(height: 12),
              const Text('Then send this file as an attachment:'),
              const SizedBox(height: 6),
              SelectableText(
                logPath,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'When you send it, also say what you clicked immediately before the crash. Please send the whole log file, not a screenshot of it.',
              ),
              const SizedBox(height: 12),
              const Text(
                'The Crash Log contains technical system information, session starts, uncaught errors and stack traces. It does not intentionally record learner names, exercise answers or course content.',
              ),
              const SizedBox(height: 12),
              const Text(
                'If the Crash Log file is deleted, QuisquisLingo recreates it automatically at the next app start or crash write.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Start testing'),
          ),
        ],
      ),
    );
    if (mounted) await _checkForUpdateAtStartup();
  }

  Future<void> _checkForUpdateAtStartup() async {
    final settings = SettingsService();
    if (!await settings.isAutomaticUpdateCheckEnabled()) return;
    final updates = UpdateService();
    final diagnostics = DiagnosticLogService();
    try {
      final checkedAt = DateTime.now();
      await settings.setUpdateLastCheckedAt(checkedAt);
      final result = await updates.check(AppMetadata.technicalVersion);
      await diagnostics.logInfo(
        'Automatic GitHub update check completed: ${result.status.name}; '
        'current=${AppMetadata.technicalVersion}; latest=${result.release?.version ?? 'none'}.',
      );
      final release = result.release;
      if (!mounted ||
          result.status != UpdateCheckStatus.updateAvailable ||
          release == null) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('QuisquisLingo update available'),
          content: Text(
            'Version ${release.version} is available. '
            'Open Settings > Update for release notes and installation instructions, '
            'or open the official GitHub release page now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await updates.openRelease(release);
              },
              child: const Text('Open GitHub release'),
            ),
          ],
        ),
      );
    } on UpdateCheckException catch (error) {
      // Automatic checks fail silently so offline use is never interrupted.
      await diagnostics.logInfo(
        'Automatic GitHub update check failed: ${error.message}',
      );
    } catch (_) {
      // Update checks are optional and must never interfere with app startup.
      await diagnostics.logInfo(
        'Automatic GitHub update check failed with an unexpected local error.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'startup_diagnostic_backend.dart';

StartupDiagnosticBackend createStartupDiagnosticBackend() {
  const configuredLevel = String.fromEnvironment(
    'QUISQUISLINGO_STARTUP_DIAGNOSTICS',
  );
  return DisabledStartupDiagnosticBackend(
    parseStartupDiagnosticLevel(configuredLevel),
  );
}

abstract final class AppMetadata {
  static const String releaseVersion = '2.0.29';
  static const String buildNumber = '229';
  static const String developmentPhase = buildNumber;
  static const int correctiveRevision = 3;
  static const String build = '229.3';
  static const String platformBuildNumber = '2293';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\nBuild $buildNumber\nRevision $correctiveRevision';
}

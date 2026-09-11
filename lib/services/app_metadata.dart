abstract final class AppMetadata {
  static const String releaseVersion = '2.0.32';
  static const String buildNumber = '232';
  static const String developmentPhase = buildNumber;
  static const int correctiveRevision = 0;
  static const String build = buildNumber;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\nBuild $build\nRevision $correctiveRevision';
}

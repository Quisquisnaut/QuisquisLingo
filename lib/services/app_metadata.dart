abstract final class AppMetadata {
  static const String releaseVersion = '2.0.31';
  static const String buildNumber = '231';
  static const String developmentPhase = buildNumber;
  static const int correctiveRevision = 1;
  static const String build = '$buildNumber.$correctiveRevision';
  static const String platformBuildNumber = '$buildNumber$correctiveRevision';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\nBuild $build\nRevision $correctiveRevision';
}

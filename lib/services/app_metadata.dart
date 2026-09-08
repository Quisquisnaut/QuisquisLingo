abstract final class AppMetadata {
  static const String releaseVersion = '2.0.28';
  static const String developmentPhase = '228';
  static const int correctiveRevision = 1;
  static const String build = '228.1';
  static const String platformBuildNumber = '2281';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\nPhase $developmentPhase, revision $correctiveRevision';
}

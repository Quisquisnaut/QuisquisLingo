abstract final class AppMetadata {
  static const String releaseVersion = '2.0.27';
  static const String developmentPhase = '227.02';
  static const int correctiveRevision = 1;
  static const String build = '227.02';
  static const String platformBuildNumber = '227021';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\nPhase $developmentPhase, revision $correctiveRevision';
}

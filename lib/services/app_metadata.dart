abstract final class AppMetadata {
  static const String releaseVersion = '2.0.26';
  static const String build = '226.02.1';
  static const String platformBuildNumber = '226021';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel = 'Version: $releaseVersion\nBuild: $build';
}

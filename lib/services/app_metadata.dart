abstract final class AppMetadata {
  static const String releaseVersion = '2.0.26';
  static const String build = '226.01';
  static const String platformBuildNumber = '22601';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel = 'Version: $releaseVersion\nBuild: $build';
}

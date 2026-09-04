abstract final class AppMetadata {
  static const String releaseVersion = '2.0.25';
  static const String build = '225.03';
  static const String platformBuildNumber = '22503';
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel = 'Version: $releaseVersion\nBuild: $build';
}

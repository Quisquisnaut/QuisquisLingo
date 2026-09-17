abstract final class AppMetadata {
  static const String releaseVersion = '2.0.37';
  static const String buildNumber = '237004';
  static const String developmentPhase = '237';
  static const int correctiveRevision = 4;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 237, Revision 4';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

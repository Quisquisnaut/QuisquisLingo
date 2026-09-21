abstract final class AppMetadata {
  static const String releaseVersion = '2.0.44';
  static const String buildNumber = '244006';
  static const String developmentPhase = '244';
  static const int correctiveRevision = 6;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 244, Revision 6';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

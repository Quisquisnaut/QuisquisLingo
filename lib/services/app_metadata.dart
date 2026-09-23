abstract final class AppMetadata {
  static const String releaseVersion = '2.0.50';
  static const String buildNumber = '250000';
  static const String developmentPhase = '250';
  static const int correctiveRevision = 0;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 250, Revision 0';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

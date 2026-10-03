abstract final class AppMetadata {
  static const String releaseVersion = '2.0.61';
  static const String buildNumber = '261007';
  static const String developmentPhase = '261';
  static const int correctiveRevision = 7;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 261, Revision 7';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

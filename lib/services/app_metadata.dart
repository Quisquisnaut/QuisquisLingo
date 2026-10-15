abstract final class AppMetadata {
  static const String releaseVersion = '2.0.73';
  static const String buildNumber = '273004';
  static const String developmentPhase = '273';
  static const int correctiveRevision = 4;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 273, Revision 4';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

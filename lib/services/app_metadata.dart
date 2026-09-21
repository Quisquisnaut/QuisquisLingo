abstract final class AppMetadata {
  static const String releaseVersion = '2.0.43';
  static const String buildNumber = '243017';
  static const String developmentPhase = '243';
  static const int correctiveRevision = 17;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 243, Revision 17';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

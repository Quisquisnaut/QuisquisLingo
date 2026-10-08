abstract final class AppMetadata {
  static const String releaseVersion = '2.0.67';
  static const String buildNumber = '267001';
  static const String developmentPhase = '267';
  static const int correctiveRevision = 1;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 267, Revision 1';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

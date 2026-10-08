abstract final class AppMetadata {
  static const String releaseVersion = '2.0.66';
  static const String buildNumber = '266001';
  static const String developmentPhase = '266';
  static const int correctiveRevision = 1;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 266, Revision 1';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

abstract final class AppMetadata {
  static const String releaseVersion = '2.0.65';
  static const String buildNumber = '265011';
  static const String developmentPhase = '265';
  static const int correctiveRevision = 11;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 265, Revision 11';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

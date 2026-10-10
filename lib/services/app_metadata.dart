abstract final class AppMetadata {
  static const String releaseVersion = '2.0.70';
  static const String buildNumber = '270003';
  static const String developmentPhase = '270';
  static const int correctiveRevision = 3;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 270, Revision 3';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

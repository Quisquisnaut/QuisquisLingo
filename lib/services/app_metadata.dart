abstract final class AppMetadata {
  static const String releaseVersion = '2.0.39';
  static const String buildNumber = '239003';
  static const String developmentPhase = '239';
  static const int correctiveRevision = 3;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 239, Revision 3';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

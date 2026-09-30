abstract final class AppMetadata {
  static const String releaseVersion = '2.0.59';
  static const String buildNumber = '259002';
  static const String developmentPhase = '259';
  static const int correctiveRevision = 2;
  static const String build = developmentPhase;
  static const String platformBuildNumber = buildNumber;
  static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
  static const String publicBuildLabel = 'Build 259, Revision 2';

  /// Compatibility name for technical diagnostics and existing report callers.
  static const String version = technicalVersion;

  static const String displayLabel =
      'Version $releaseVersion\n$publicBuildLabel';
}

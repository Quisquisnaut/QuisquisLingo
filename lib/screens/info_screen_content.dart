import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../services/app_metadata.dart';
import '../services/beta_lifecycle_service.dart';
import '../widgets/help_language_toggle.dart';

/// One titled block of the App Info page.
typedef InfoSection = ({String id, String title, String body});

/// The eight Lesson colours of the learner path, light and dark: the owner's
/// picture under App Info's Colour code of the path (Build 261 Revision 8).
const appInfoPathColoursPicture = 'assets/rounds_screenshots/colors.png';
const appInfoPathColoursAspectRatio = 1161 / 466;

List<InfoSection> infoSections(HelpLanguage language) => [
  for (final id in appInfoSectionIds)
    (
      id: id,
      title: helpText.lookup(language, 'appInfo.$id.title'),
      body: switch (id) {
        'versionAndBuild' => helpText.lookup(
          language,
          'appInfo.versionAndBuild.body',
          values: {'version': AppMetadata.displayLabel},
        ),
        'betaExpiry' =>
          BetaLifecycleService.isBetaBuild
              ? helpText.lookup(
                  language,
                  'appInfo.betaExpiry.active',
                  values: {'expiryDate': BetaLifecycleService.expiryIsoDate},
                )
              : helpText.lookup(language, 'appInfo.betaExpiry.inactive'),
        _ => helpText.lookup(language, 'appInfo.$id.body'),
      },
    ),
];

String infoCreditsButtonLabel(HelpLanguage language) =>
    helpText.lookup(language, 'appInfo.creditsButton');

import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../widgets/help_language_toggle.dart';

/// One titled block of Course Editor or Course Studio Help.
typedef EditorHelpSection = ({String title, String body});

EditorHelpSection _section(HelpLanguage language, String prefix, String id) => (
  title: helpText.lookup(language, '$prefix.$id.title'),
  body: helpText.lookup(language, '$prefix.$id.body'),
);

List<EditorHelpSection> editorHelpSections(HelpLanguage language) => [
  for (final id in editorHelpSectionIds) _section(language, 'editorHelp', id),
];

List<EditorHelpSection> courseManagerHelpSections(HelpLanguage language) => [
  for (final id in courseStudioHelpSectionIds)
    _section(language, 'editorHelp', id),
  _section(language, 'courseStudioHelp', 'findingCourses'),
  _section(language, 'courseStudioHelp', 'courseOperations'),
];

({String title, String body, String note}) editorHelpTechnicalIntro(
  HelpLanguage language,
) => (
  title: helpText.lookup(language, 'editorHelp.technicalReference.title'),
  body: helpText.lookup(language, 'editorHelp.technicalReference.body'),
  note: '',
);

({
  String title,
  String intro,
  List<String> types,
  List<List<String>> rows,
  List<String> notes,
  String contact,
})
editorHelpCourseTypes(HelpLanguage language) {
  String text(String suffix) =>
      helpText.lookup(language, 'courseStudioHelp.courseTypes.$suffix');
  return (
    title: text('title'),
    intro: text('intro'),
    types: [for (var i = 1; i <= 3; i++) text('type$i')],
    rows: [
      for (var row = 1; row <= 11; row++)
        [for (var col = 1; col <= 4; col++) text('row$row.col$col')],
    ],
    notes: [for (var i = 1; i <= 4; i++) text('note$i')],
    contact: text('contact'),
  );
}

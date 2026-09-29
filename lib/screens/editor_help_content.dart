import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../widgets/help_language_toggle.dart';

/// One titled block of Course Editor or Course Studio Help.
typedef EditorHelpSection = ({String title, String body});

EditorHelpSection _section(HelpLanguage language, String prefix, String id) => (
  title: helpText.lookup(language, '$prefix.$id.title'),
  body: helpText.lookup(language, '$prefix.$id.body'),
);

/// One question of Editor Help and its answer (Build 256 Revision 8).
typedef EditorHelpQuestion = ({String id, String question, String answer});

/// One topic of Editor Help with its questions, in reading order.
typedef EditorHelpTopic = ({
  String id,
  String title,
  List<EditorHelpQuestion> questions,
});

/// Editor Help as questions and answers: the topics in reading order, their
/// questions and answers in [language], folders filled in.
List<EditorHelpTopic> editorHelpTopics(HelpLanguage language) => [
  for (final entry in editorHelpQuestionsByTopic.entries)
    (
      id: entry.key,
      title: helpText.lookup(language, 'editorHelp.qa.${entry.key}.title'),
      questions: [
        for (final id in entry.value)
          (
            id: id,
            question: helpText.lookup(language, 'editorHelp.qa.$id.q'),
            answer: helpText.lookup(language, 'editorHelp.qa.$id.a'),
          ),
      ],
    ),
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

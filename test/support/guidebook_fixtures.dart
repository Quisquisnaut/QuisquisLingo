import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/guidebook_vocabulary.dart';

/// Build 266 (GuideBook Modules): test GuideBooks. Before Build 266 tests
/// built `Guidebook(content: …)` or the legacy named arguments; a GuideBook
/// is now a list of modules.

/// An entry from a `target = source` line ([line] without a separator is
/// its own translation, as an example sentence of a test).
GuidebookEntry testEntry(
  String id,
  String line, {
  String context = '',
  GuidebookPicture? picture,
}) {
  final pair = GuidebookVocabulary.parse(line);
  return GuidebookEntry(
    id: id,
    target: pair?.target ?? line.trim(),
    source: pair?.source ?? line.trim(),
    context: context,
    picture: picture,
  );
}

/// A GuideBook of one module ([moduleId], [title]) holding [words],
/// [sentences] and [overview]. [wordLines] are `target = source` lines with
/// IDs `<moduleId>_w<n>`; [sentenceLines] likewise with `<moduleId>_s<n>`.
Guidebook testGuidebook({
  PublicationState publicationState = PublicationState.published,
  String moduleId = 'test_module',
  String title = 'Test module',
  String overview = '',
  List<String> wordLines = const [],
  List<String> sentenceLines = const [],
  List<GuidebookEntry> words = const [],
  List<GuidebookEntry> sentences = const [],
}) => Guidebook(
  publicationState: publicationState,
  modules: [
    GuidebookModule(
      id: moduleId,
      title: title,
      overview: overview,
      sentences: [
        for (var i = 0; i < sentenceLines.length; i++)
          testEntry('${moduleId}_s${i + 1}', sentenceLines[i]),
        ...sentences,
      ],
      words: [
        for (var i = 0; i < wordLines.length; i++)
          testEntry('${moduleId}_w${i + 1}', wordLines[i]),
        ...words,
      ],
    ),
  ],
);

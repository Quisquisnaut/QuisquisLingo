import '../models/course_models.dart';
import 'authoring_duplication_service.dart';

/// The module Fill with an example writes on the GuideBook module page
/// (Build 266 Revision 1; like the exercise forms' examples, in Italian and
/// English whatever the Course's languages). It shows every feature: a
/// short Overview, Sentences with a Context, an understood subject `{io}`,
/// one word with two senses (*il conto*), a fixed expression, a word with a
/// QQL picture (*il caffè*) and a plural word with its picture marked Plural
/// (*i gatti*).
abstract final class GuidebookModuleSample {
  static const coffeePicture = 'assets/exercise_images/coffee.webp';
  static const catPicture = 'assets/exercise_images/cat.webp';

  /// The sample as module [id], every entry with a fresh ID from [ids].
  static GuidebookModule module({
    required String id,
    required AuthoringIdGenerator ids,
  }) {
    GuidebookEntry entry(
      String target,
      String source, {
      String context = '',
      GuidebookPicture? picture,
    }) => GuidebookEntry(
      id: ids.next('entry'),
      target: target,
      source: source,
      context: context,
      picture: picture,
    );
    return GuidebookModule(
      id: id,
      title: 'Al bar',
      sentences: [
        entry(
          '{Io} vorrei un caffè, per favore.',
          'I would like a coffee, please.',
        ),
        entry('Il conto, per favore.', 'The bill, please.'),
        entry('Lei è stanca?', 'Are you tired?', context: 'formal, to a woman'),
        entry(
          'Ci sono due gatti sotto il tavolo.',
          'There are two cats under the table.',
        ),
      ],
      words: [
        entry(
          'il caffè',
          'coffee',
          picture: const GuidebookPicture(asset: coffeePicture),
        ),
        entry('il conto', 'the bill', context: 'restaurant'),
        entry('il conto', 'the account', context: 'bank'),
        entry('per favore', 'please'),
        entry('{io} sono stanco', 'I am tired'),
        entry(
          'i gatti',
          'the cats',
          picture: const GuidebookPicture(asset: catPicture, plural: true),
        ),
      ],
      overview:
          'At the bar Italians usually drink their coffee standing at the '
          'counter. Il conto is the bill here; at the bank the same word '
          'means the account.',
    );
  }
}

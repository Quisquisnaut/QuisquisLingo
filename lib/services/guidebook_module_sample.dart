import '../models/course_models.dart';
import 'authoring_duplication_service.dart';

/// The module Fill with an example writes on the GuideBook module page
/// (Build 266 Revision 1; like the exercise forms' examples, in Italian and
/// English whatever the Course's languages). It shows every feature: a
/// short Overview, Sentences with a Context, an understood subject `{io}`,
/// one word with two senses (*il conto*), fixed expressions (*buongiorno*,
/// *come stai?*; Build 267 Revision 9: a sentence is never a word), a word with a
/// QQL picture (*il caffè*) and a plural word with its picture marked Plural
/// (*i gatti*).
abstract final class GuidebookModuleSample {
  static const espressoPicture = 'assets/exercise_images/espresso.webp';
  static const catPicture = 'assets/exercise_images/cat.webp';
  static const billPicture = 'assets/exercise_images/bill.webp';
  static const beakPicture = 'assets/exercise_images/beak.webp';

  /// The sample as module [id], every entry with a fresh ID from [ids]. In
  /// a Course in the same language ([sameLanguage], Build 275 Revision 4),
  /// the English to English module [sameLanguageModule].
  static GuidebookModule module({
    required String id,
    required AuthoringIdGenerator ids,
    bool sameLanguage = false,
  }) {
    if (sameLanguage) return sameLanguageModule(id: id, ids: ids);
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
          'I would like an espresso, please.',
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
          'espresso',
          picture: const GuidebookPicture(asset: espressoPicture),
        ),
        entry('il conto', 'the bill', context: 'restaurant'),
        entry('il conto', 'the account', context: 'bank'),
        entry('per favore', 'please'),
        entry('buongiorno', 'good morning'),
        entry('come stai?', 'how are you?'),
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

  /// The same features in English explained in English: words and their
  /// meanings, one word with two senses (*the bill*, each with its picture),
  /// words that may be left out `{just}`, a picture and a plural picture.
  /// English never leaves out its subject, so the optional word is another
  /// one (Build 275 Revision 4, review).
  static GuidebookModule sameLanguageModule({
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
      title: 'At the café',
      sentences: [
        entry(
          'I would like {just} an espresso, please.',
          'I am asking politely for one small, strong coffee.',
        ),
        entry('Could I have the bill, please?', 'I want to pay now.'),
        entry('Are you tired?', 'Do you need to rest?', context: 'to a friend'),
        entry(
          'There are two cats under the table.',
          'Two cats are sitting below the table.',
        ),
      ],
      words: [
        entry(
          'espresso',
          'a small, strong coffee',
          picture: const GuidebookPicture(asset: espressoPicture),
        ),
        entry(
          'the bill',
          'the paper that says what you must pay',
          context: 'restaurant',
          picture: const GuidebookPicture(asset: billPicture),
        ),
        entry(
          'the bill',
          'the beak of a bird',
          context: 'birds',
          picture: const GuidebookPicture(asset: beakPicture),
        ),
        entry('please', 'a polite word when you ask for something'),
        entry('good morning', 'hello, said before midday'),
        entry('how are you?', 'a friendly question about someone\'s health'),
        entry(
          'the cats',
          'more than one cat',
          picture: const GuidebookPicture(asset: catPicture, plural: true),
        ),
      ],
      overview:
          'At the café many people drink a quick espresso at the counter. '
          'The bill is what you pay there; a bird\'s bill is its beak.',
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/guidebook_vocabulary.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_sources.dart';

/// Build 265 Revision 3: QQL Demo: Italian Exercise Lab's GuideBook
/// vocabulary (approved by the owner on 6 October 2026), and the Word Lookup
/// cases it was chosen to show, on the Lab's own sentences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Course load(String file) => Course.fromJson(
    jsonDecode(File('assets/courses/$file').readAsStringSync())
        as Map<String, dynamic>,
  );

  final lab = load('exercise_laboratory_en_it.json');
  final index = WordLookupSources.indexFor(lab);

  int lessonOf(String title) =>
      lab.lessons.indexWhere((lesson) => lesson.title == title);

  List<String> tap(String lesson, String text, String word, {int shift = 0}) {
    final at = text.indexOf(word);
    expect(at, greaterThanOrEqualTo(0), reason: '"$word" in "$text"');
    final result = index.resultAt(
      text,
      at + shift,
      currentLessonIndex: lessonOf(lesson),
    );
    return [
      for (final entry in result?.entries ?? const <WordLookupEntry>[])
        '${entry.target} = ${entry.source}',
    ];
  }

  test('every Lesson has 10 to 15 entries, all target = source', () {
    expect(lab.title, 'QQL Demo: Italian Exercise Lab');
    expect(lab.lessons.map((lesson) => lesson.title), [
      'Select',
      'Input',
      'Arrange',
      'Match',
      'Presentation',
      'Story',
      'Assign',
      'Page',
    ]);
    for (final lesson in lab.lessons) {
      final words = lesson.guidebook.vocabulary;
      expect(words.length, inInclusiveRange(10, 15), reason: lesson.title);
      for (final word in words) {
        expect(GuidebookVocabulary.parse(word), isNotNull, reason: word);
      }
      final review = VocabularyReviewService().resolveEntries(lab, lesson);
      expect(review, hasLength(words.length), reason: lesson.title);
    }
    expect(index.length, 98);
  });

  test('the Round Wizard can plan from every Lesson', () {
    for (final lesson in lab.lessons) {
      final plan = GuidebookRoundGenerator(
        randomSeed: 1,
      ).plan(lesson.guidebook, roundCount: 1, exercisesPerRound: 3);
      expect(plan.rounds, hasLength(1), reason: lesson.title);
    }
  });

  test('a whole apostrophe expression', () {
    expect(tap('Select', "Dov'è la stazione?", 'Dov'), ["dov'è = where is"]);
    expect(tap('Select', "Dov'è la stazione?", 'stazione'), [
      'la stazione = the station',
    ]);
    expect(tap('Input', "l'acqua è fredda.", 'acqua'), ["l'acqua = water"]);
    expect(tap('Input', "l'acqua è fredda.", 'fredda'), ['fredda = cold']);
  });

  test('a word found only inside an expression', () {
    expect(tap('Arrange', 'Bevo acqua.', 'acqua'), ["l'acqua = water"]);
    expect(tap('Arrange', 'Bevo acqua.', 'Bevo'), ['bevo = I drink']);
    expect(tap('Arrange', 'Vado a scuola in treno.', 'treno'), [
      'il treno = the train',
    ]);
    expect(tap('Arrange', 'Vado a scuola in treno.', 'scuola'), [
      'a scuola = to school',
    ]);
    expect(tap('Select', 'Il gatto ___ sul divano.', 'divano'), [
      'il divano = the sofa',
    ]);
  });

  test('the same words in two Lessons with different translations', () {
    expect(tap('Page', 'Un caffè, per favore.', 'caffè'), [
      'un caffè = an espresso',
    ]);
    expect(tap('Select', 'Anna ___ un caffè. Luca ___ un tè.', 'caffè'), [
      'un caffè = a coffee',
      'un caffè = an espresso',
    ]);
    expect(tap('Select', 'Il caffè di Luca è dolce?', 'caffè'), [
      'il caffè = coffee',
    ]);
    expect(tap('Page', 'Il caffè in Italia', 'caffè'), ['il caffè = espresso']);
  });

  test('a common word alone finds nothing; with its noun it does', () {
    expect(tap('Input', 'il maestro è stanco', 'il'), isEmpty);
    expect(tap('Select', 'Il gatto è un frutto.', 'Il'), [
      'il gatto = the cat',
    ]);
  });

  test("the pieces of an apostrophe word without an entry of its own", () {
    expect(tap('Select', "Roma è la capitale d'Italia.", 'Italia'), [
      'Italia = Italy',
    ]);
    expect(tap('Select', "Roma è la capitale d'Italia.", "d'"), [
      'Italia = Italy',
    ]);
  });

  test('English from Italian: mass nouns without "the"', () {
    final english = load('english_from_italian_it_en.json');
    final words = english.lessons.single.guidebook.vocabulary;
    expect(
      words,
      containsAll([
        'bread = il pane',
        "water = l'acqua",
        'milk = il latte',
        'coffee = il caffè',
        'tea = il tè',
        'the apple = la mela',
      ]),
    );
    final lookup = WordLookupSources.indexFor(english);
    final result = lookup.resultAt(
      'I like the bread.',
      'I like the bread.'.indexOf('bread'),
      currentLessonIndex: 0,
    );
    expect(result!.entries.single.source, 'il pane');
  });
}

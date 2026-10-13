import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/guidebook_vocabulary.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';

/// Build 265 Revision 0: one vocabulary parser, read as target = source.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (String, String)? parse(String line) {
    final pair = GuidebookVocabulary.parse(line);
    return pair == null ? null : (pair.target, pair.source);
  }

  test('reads target = source with the four separators in order', () {
    expect(parse('casa = house'), ('casa', 'house'));
    expect(parse('pane → bread'), ('pane', 'bread'));
    expect(parse('acqua - water'), ('acqua', 'water'));
    expect(parse('grazie:thank you'), ('grazie', 'thank you'));
    expect(parse('  il gatto =  the cat  '), ('il gatto', 'the cat'));
    // The first separator found wins, in the listed order.
    expect(parse('a = b = c'), ('a', 'b = c'));
    expect(parse('a: b - c'), ('a: b', 'c'));
    expect(parse('what time is it? = che ore sono?'), (
      'what time is it?',
      'che ore sono?',
    ));
    expect(GuidebookVocabulary.separators, [' = ', ' → ', ' - ', ':']);
  });

  test('a line without two sides is not an entry', () {
    expect(parse(''), isNull);
    expect(parse('no answer here'), isNull);
    expect(parse('= house'), isNull);
    expect(parse('casa = '), isNull);
    expect(parse(':house'), isNull);
  });

  // A Course from Italian to English: its entries put English, the learning
  // language, first. QQL Demo: English from Italian was the Course read here
  // until it left the app and the repository in Build 272 Revision 15 (owner
  // decision of 13 October 2026); the Edge Case fixture teaches the same way
  // round. The case that counted the removed Course's own 36 entries left
  // with it.
  group('the Edge Case fixture, Italian to English', () {
    final course = Course.fromJson(
      jsonDecode(
            File('test/fixtures/v12/edge_case_it_en.json').readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final lesson = course.lessons.first;
    // The first Lesson's seven Words & Expressions, English side first
    // («hello = ciao» is there twice, on purpose).
    const english = {'yes', 'a window', 'red', 'blue', 'hello', 'café'};

    test('Review vocabulary shows the English side as the prompt', () {
      expect(
        lesson.guidebook.words.map((word) => word.target).toSet(),
        english,
      );
      final entries = VocabularyReviewService().resolveEntries(course, lesson);
      expect(entries, hasLength(7));
      final yes = entries.singleWhere((entry) => entry.prompt == 'yes');
      expect(yes.answer, 'sì');
    });

    test('the Round Wizard takes English as the target', () {
      final generator = GuidebookRoundGenerator(randomSeed: 3);
      final plan = generator.plan(
        lesson.guidebook,
        roundCount: 2,
        exercisesPerRound: 3,
      );
      // Build 266 Revision 3: a Round is titled after its module; the words
      // it practises are the English side.
      final module = lesson.guidebook.modules.single.title;
      expect(plan.rounds.first.title, 'Foundations: $module');
      expect(plan.rounds.last.title, 'Use in context: $module');
      // "Focus: <module> — <word>, <word>, …".
      final words = generator.wordsOf(lesson.guidebook, plan.rounds.first);
      expect(words, startsWith('Focus: $module — '));
      final listed = words.substring('Focus: $module — '.length).split(', ');
      expect(listed, isNotEmpty);
      expect(english, containsAll(listed));
    });
  });
}

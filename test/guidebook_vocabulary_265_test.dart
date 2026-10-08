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

  group('QQL Demo: English from Italian', () {
    final course = Course.fromJson(
      jsonDecode(
            File(
              'assets/courses/english_from_italian_it_en.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final lesson = course.lessons.single;

    test('its 36 entries put English, the learning language, first', () {
      // Build 266: the entries' own fields.
      final pairs = lesson.guidebook.words.toList();
      expect(pairs, hasLength(36));
      expect(pairs.first.target, 'hello, hi');
      expect(pairs.first.source, 'ciao');
      expect(
        pairs.map((pair) => pair.target),
        containsAll(['water', 'bread', 'what time is it?']),
      );
      expect(
        pairs.map((pair) => pair.source),
        containsAll(["l'acqua", 'il pane', 'che ore sono?']),
      );
    });

    test('Review vocabulary shows the English side as the prompt', () {
      final entries = VocabularyReviewService().resolveEntries(course, lesson);
      expect(entries, hasLength(36));
      final thanks = entries.singleWhere(
        (entry) => entry.prompt == 'thank you',
      );
      expect(thanks.answer, 'grazie');
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
      expect(
        generator.wordsOf(lesson.guidebook, plan.rounds.first),
        contains('hello'),
      );
    });
  });
}

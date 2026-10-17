import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audio_segmenter.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audio_texts.dart';
import 'package:quisquislingo_app/services/course_audio_usage.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';

// Build 276 Revision 0 (owner brief and decisions of 17 October 2026): the
// text a recording says keeps an apostrophe beside a letter at either end
// (L' and L, un' and un are two texts), and ' ’ ʼ are one apostrophe,
// inside words too. A word quoted at both ends loses both marks. The
// Audit's duplicate recordings keep their own rule (capitals and the
// spaces around a text) with the three apostrophes as one.

/// The Laboratory's dialogue line "Dov'è la stazione?" said as [line].
const _line = "Dov'è la stazione?";

Course _course(List<(String id, String text)> clips, {String? line}) {
  var raw = File(
    'assets/courses/exercise_laboratory_en_it.json',
  ).readAsStringSync();
  if (line != null) raw = raw.replaceAll(jsonEncode(_line), jsonEncode(line));
  return Course.fromJson({
    ...jsonDecode(raw) as Map<String, dynamic>,
    'audioMode': 'recorded',
    'audioLibrary': [
      for (final (id, text) in clips)
        {
          'id': id,
          'text': text,
          'filePath': 'assets/apostrophe_key_276_test/$id.mp3',
        },
    ],
  });
}

List<CourseAudioClip> _library(List<(String id, String text)> clips) => [
  for (final (id, text) in clips)
    CourseAudioClip(
      id: id,
      text: text,
      filePath: 'assets/apostrophe_key_276_test/$id.mp3',
    ),
];

List<String>? _ids(String text, List<CourseAudioClip> library) =>
    AudioSegmenter.segment(text, library)?.map((clip) => clip.id).toList();

void main() {
  group('the key of a text', () {
    String key(String text) => AudioSegmenter.key(text);

    test("L' / L’ / Lʼ are one text, L another", () {
      expect(key("L'"), "l'");
      expect(key('L’'), "l'");
      expect(key('Lʼ'), "l'");
      expect(key('l’'), "l'");
      expect(key('L'), 'l');
      expect(key("L'"), isNot(key('L')));
    });

    test("un / un' / un’: the elision is its own text", () {
      expect(key("un'"), key('un’'));
      expect(key("un'"), key('UNʼ'));
      expect(key("un'"), isNot(key('un')));
      expect(key("dell'"), "dell'");
      expect(key('Dell’!'), "dell'", reason: 'the mark after it still goes');
      expect(key("«L'»"), "l'", reason: 'guillemets close with their own mark');
      expect(key("(un')"), "un'");
    });

    test('an apostrophe before a letter starts a word', () {
      expect(key("'n"), "'n");
      expect(key('’n'), "'n");
      expect(key("'O"), "'o");
      expect(key("'o"), isNot(key('o')));
    });

    test('inside a word the three apostrophes are one', () {
      expect(key("Dov'è"), key('dov’è'));
      expect(key("Dov'è"), key('dovʼè'));
      expect(key("Dov'è la stazione?"), "dov'è la stazione");
    });

    test('a word quoted at both ends loses both marks', () {
      for (final text in [
        "'ciao'",
        '‘ciao’',
        '“ciao”',
        '"ciao"',
        '«ciao»',
        'Ciao!',
        '  ciao  ',
      ]) {
        expect(key(text), 'ciao', reason: text);
      }
    });

    test('an apostrophe beside a digit is punctuation, as before', () {
      expect(key("80'"), '80');
      expect(key("'80"), '80');
    });

    test('punctuation alone is no text', () {
      expect(key("'"), '');
      expect(key('ʼ'), '');
      expect(key('…!'), '');
    });

    test('ʼ is an apostrophe at the edges too, not a letter', () {
      expect(key('80ʼ'), '80');
      expect(key('ʼciaoʼ'), 'ciao');
      expect(key('ʼn'), "'n");
    });

    test('single quotes around a phrase are quote marks', () {
      expect(key("She said 'come here'."), 'she said come here');
      expect(key('She said ‘come here’.'), 'she said come here');
      expect(key('‚ciao‘'), 'ciao', reason: 'German quotes');
      expect(key("'Dov'è?'"), "dov'è");
      expect(key("Un' amica, 'davvero'"), "un' amica, davvero");
    });

    test("around a single letter they are apostrophes: rock 'n' roll", () {
      expect(key("'n'"), "'n'");
      expect(key("rock 'n' roll"), "rock 'n' roll");
      expect(key("rock 'n' roll"), isNot(key('rock n roll')));
    });

    test("the key of a whole text pairs an opening elision with a later "
        "one ('O … dell'): playback tries the words as written first", () {
      expect(key("'O sole, dell' anno"), 'o sole, dell anno');
      expect(key("'O sole mio"), "'o sole mio");
    });
  });

  group('playback finds the recording of the text itself', () {
    final library = _library([
      ('letter', 'L'),
      ('article', "L'"),
      ('un', 'un'),
      ('amico', 'amico'),
      ('station', _line),
    ]);

    test('a phrase in single quotes finds the recordings of its words', () {
      final words = _library([
        ('she', 'She'),
        ('said', 'said'),
        ('come', 'come'),
        ('here', 'here'),
      ]);
      for (final text in ["She said 'come here'.", 'She said ‘come here’.']) {
        expect(_ids(text, words), ['she', 'said', 'come', 'here']);
        final coverage = AudioSegmenter.coverage(text, words);
        expect(coverage.complete, isTrue, reason: text);
      }
      final missing = AudioSegmenter.coverage(
        "She said 'come here'.",
        _library([('she', 'She'), ('said', 'said')]),
      );
      expect(missing.missing, ['come here']);
    });

    test("'O … pe': the elisions' own recordings first, then the words "
        "without them, as before Build 276", () {
      const line = "'O sole, pe' te";
      expect(
        _ids(
          line,
          _library([
            ('o', "'O"),
            ('sole', 'sole'),
            ('pe', "pe'"),
            ('te', 'te'),
          ]),
        ),
        ['o', 'sole', 'pe', 'te'],
      );
      expect(
        _ids(
          "'Na tazza pe' te",
          _library([
            ('na', '’na'),
            ('tazza', 'tazza'),
            ('pe', 'pe’'),
            ('te', 'te'),
          ]),
        ),
        ['na', 'tazza', 'pe', 'te'],
      );
      // Without them: the recordings of the words without their apostrophes,
      // as before Build 276 (the two marks could be a quotation).
      expect(
        _ids(
          line,
          _library([('o', 'o'), ('sole', 'sole'), ('pe', 'pe'), ('te', 'te')]),
        ),
        ['o', 'sole', 'pe', 'te'],
      );
      // A single elision is never read as a quotation.
      expect(_ids("'O sole", _library([('o', 'o'), ('sole', 'sole')])), isNull);
    });

    test("rock 'n' roll borrows no recording of the letter n", () {
      final letters = _library([
        ('rock', 'rock'),
        ('letter', 'n'),
        ('roll', 'roll'),
      ]);
      expect(_ids("rock 'n' roll", letters), isNull);
      expect(
        _ids(
          "rock 'n' roll",
          _library([('rock', 'rock'), ('n', "'n'"), ('roll', 'roll')]),
        ),
        ['rock', 'n', 'roll'],
      );
      expect(_ids("Rock ’n’ roll!", _library([('all', "rock 'n' roll")])), [
        'all',
      ]);
    });

    test("L' is not the letter L, whichever apostrophe it is written with", () {
      expect(_ids("L'", library), ['article']);
      expect(_ids('L’', library), ['article']);
      expect(_ids('L', library), ['letter']);
      expect(_ids("L'", _library([('letter', 'L')])), isNull);
      expect(_ids('l’', _library([('letter', 'L')])), isNull);
    });

    test("un' borrows no recording of un", () {
      expect(_ids('Un amico', library), ['un', 'amico']);
      expect(_ids('un’', library), isNull);
      expect(
        RecordedAudioService().segment("un'", library),
        isNull,
        reason: 'the service is the same rule',
      );
    });

    test('a curly apostrophe finds a recording with a straight one', () {
      expect(_ids('Dov’è la stazione?', library), ['station']);
      expect(_ids('dovʼè la stazione', library), ['station']);
    });

    test('what is missing is written as the author wrote it', () {
      final coverage = AudioSegmenter.coverage('L’ amico', library);
      expect(coverage.clips.map((clip) => clip.id), ['article', 'amico']);
      final missing = AudioSegmenter.coverage(
        'Un’ amico',
        _library([('amico', 'amico'), ('un', 'un')]),
      );
      expect(missing.complete, isFalse);
      expect(missing.missing, ['Un’']);
      expect(AudioSegmenter.coverage('‘ciao’', const []).missing, ['ciao']);
    });
  });

  test('Associate recording finds the other recording of one text', () {
    final library = _library([('a', "L'"), ('b', 'L')]);
    expect(
      CourseAudioTexts.ownRecordingOf('L’', library, except: 'x')?.id,
      'a',
    );
    expect(CourseAudioTexts.ownRecordingOf('L', library, except: 'x')?.id, 'b');
    expect(CourseAudioTexts.ownRecordingOf('L’', library, except: 'a'), isNull);
    expect(
      CourseAudioTexts.ownRecordingOf(
        "un'",
        _library([('u', 'un')]),
        except: '',
      ),
      isNull,
    );
  });

  group('Texts in this Course', () {
    CourseSpokenText text(Course course, String text) =>
        CourseAudioTexts.of(course).singleWhere((entry) => entry.text == text);

    test('a text that borrowed a recording without its apostrophe now shows '
        'it missing', () {
      const neapolitan = "'O sole mio";
      final borrowed = text(
        _course([('o', 'o'), ('sole', 'sole mio')], line: neapolitan),
        neapolitan,
      );
      expect(borrowed.state, AudioTextState.someParts);
      expect(borrowed.missing, ["'O"]);
      expect(
        CourseAudioTexts.stateLabel(borrowed),
        "Some parts recorded, still missing: 'O",
      );

      final own = text(
        _course([('o', '’o'), ('sole', 'sole mio')], line: neapolitan),
        neapolitan,
      );
      expect(own.state, AudioTextState.allParts);
    });

    test('a recording with a curly apostrophe is the text’s own', () {
      expect(
        text(_course([('s', 'Dov’è la stazione')]), _line).state,
        AudioTextState.ownRecording,
      );
    });
  });

  group('the Audit’s duplicate recordings', () {
    int duplicates(List<(String id, String text)> clips) => [
      for (final issue
          in CourseAuditService().auditCourse(_course(clips)).issues)
        if (issue.code == AuditCode.audioMappingDuplicate.code) issue,
    ].length;

    test("L' and L’ are one text twice; L and L' two texts", () {
      expect(duplicates([('a', "L'"), ('b', 'L’')]), 1);
      expect(duplicates([('a', "dov'è"), ('b', 'Dovʼè')]), 1);
      expect(duplicates([('a', 'L'), ('b', "L'")]), 0);
      expect(duplicates([('a', 'un'), ('b', 'un’')]), 0);
    });

    test('otherwise today’s rule: capitals and the spaces around a text', () {
      expect(duplicates([('a', 'Ciao'), ('b', ' ciao ')]), 1);
      expect(duplicates([('a', 'ciao!'), ('b', 'ciao')]), 0);
    });
  });

  test('Used in N exercises and Check unused MP3 files follow the key', () {
    const neapolitan = "'O sole mio";
    Map<String, List<AudioClipUse>> uses(Course course) =>
        CourseAudioUsage.usesByClip(
          course,
          (text) => AudioSegmenter.segment(text, course.audioLibrary),
        );
    final borrowed = _course([
      ('o', 'o'),
      ('sole', 'sole mio'),
    ], line: neapolitan);
    final borrowedUses = uses(borrowed);
    expect(borrowedUses.containsKey('o'), isFalse);
    expect(
      CourseAudioUsage.unused(borrowed, borrowedUses).map((clip) => clip.id),
      contains('o'),
    );
    final own = _course([('o', '’O'), ('sole', 'sole mio')], line: neapolitan);
    expect(uses(own)['o'], isNotEmpty);
  });

  test('a text without an apostrophe at a word’s edge keys as before', () {
    // The rule before Build 276, ' ’ ʼ then written as one.
    final earlier = RegExp(
      r'^[^\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+$',
      unicode: true,
    );
    String earlierKey(String text) => AudioSegmenter.unifyApostrophes(
      text
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(earlier, '')
          .toLowerCase(),
    );
    final edge = RegExp(
      r"(^|[^\p{L}\p{M}\p{N}'’ʼ])['’ʼ‘‚]|['’ʼ‘](?=$|[^\p{L}\p{M}\p{N}'’ʼ])",
      unicode: true,
    );
    final texts = <String>{};
    for (final file in [
      'assets/courses/exercise_laboratory_en_it.json',
      'test_courses/edge_case_it_en.json',
      'test_courses/exercise_lab_en_en.json',
      'test_courses/exercise_laboratory_en_it.json',
      'test/fixtures/v12/edge_case_it_en.json',
      'test/fixtures/v12/korean_en.json',
      'test/fixtures/v12/laboratory_future_en_it.json',
    ]) {
      final course = Course.fromJson(
        jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>,
      );
      for (final clip in course.audioLibrary) {
        texts.add(clip.text);
      }
      for (final lesson in course.lessons) {
        for (final round in lesson.rounds) {
          for (final exercise in round.exercises) {
            texts.addAll(CourseAudioUsage.spokenTexts(exercise));
            texts.addAll(
              CourseAudioUsage.spokenTexts(exercise, sameLanguage: true),
            );
          }
        }
      }
    }
    var compared = 0;
    for (final text in texts) {
      if (edge.hasMatch(text)) continue;
      compared++;
      expect(AudioSegmenter.key(text), earlierKey(text), reason: text);
    }
    expect(compared, greaterThan(200));
  });
}

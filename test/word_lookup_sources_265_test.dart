import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_sources.dart';
import 'support/guidebook_fixtures.dart';

/// Build 265 Revision 0: where Word Lookup reads its entries.
void main() {
  // Build 266: entries are a module's Words & Expressions; Sentences are
  // never read.
  GuidebookEntry vocabulary(String id, String text) => testEntry(id, text);

  Lesson lesson(
    String id,
    List<GuidebookEntry> words, {
    List<GuidebookEntry> sentences = const [],
    PublicationState state = PublicationState.published,
    PublicationState guidebookState = PublicationState.published,
  }) => Lesson(
    lessonId: id,
    publicationState: state,
    title: id,
    guidebook: testGuidebook(
      moduleId: '$id-module',
      publicationState: guidebookState,
      words: words,
      sentences: sentences,
    ),
    rounds: [
      LearningRound(id: '$id-round', title: 'Round', exercises: const []),
    ],
  );

  Course course({bool useGuidebook = true}) => Course(
    courseId: 'course-word-lookup',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Word Lookup',
    ttsLanguage: 'it-IT',
    useGuidebook: useGuidebook,
    lessons: [
      lesson(
        'first',
        [vocabulary('pane', 'il pane = the bread')],
        sentences: [
          vocabulary('sentence', 'il pane è buono = the bread is good'),
        ],
      ),
      lesson('draft-lesson', [
        vocabulary('acqua', "l'acqua = the water"),
      ], state: PublicationState.draft),
      lesson('draft-guidebook', [
        vocabulary('gatto', 'il gatto = the cat'),
      ], guidebookState: PublicationState.draft),
      lesson('locked-later', [vocabulary('cane', 'il cane = the dog')]),
    ],
  );

  List<String> describe(List<WordLookupSourceEntry> entries) => [
    for (final entry in entries) '${entry.id}@${entry.lessonIndex}',
  ];

  test('the learner reads Published entries of every Lesson', () {
    expect(describe(WordLookupSources.forCourse(course())), [
      'pane@0',
      'cane@3',
    ]);
  });

  test('Preview reads Draft Lessons and GuideBooks too', () {
    expect(
      describe(WordLookupSources.forCourse(course(), includeDrafts: true)),
      ['pane@0', 'acqua@1', 'gatto@2', 'cane@3'],
    );
  });

  test('an entry brings its fields: Context, picture, optional words', () {
    const picture = GuidebookPicture(
      asset: 'assets/exercise_images/cat.webp',
      plural: true,
    );
    final words = Course(
      courseId: 'course-word-lookup-fields',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Word Lookup fields',
      ttsLanguage: 'it-IT',
      lessons: [
        lesson('fields', [
          testEntry('conto', 'il conto = the bill', context: 'restaurant'),
          testEntry('gatti', 'i gatti = the cats', picture: picture),
          testEntry('stanco', '{io} sono stanco = I am tired'),
        ]),
      ],
    );
    final source = WordLookupSources.forCourse(words);
    expect(source.first.context, 'restaurant');
    expect(source[1].picture, picture);
    final index = WordLookupSources.indexFor(words);
    WordLookupEntry? found(String text, String word) => index
        .resultAt(text, text.indexOf(word), currentLessonIndex: 0)
        ?.entries
        .single;
    expect(found('Ecco il conto.', 'conto')?.context, 'restaurant');
    expect(found('Vedo i gatti.', 'gatti')?.picture, picture);
    // Both forms of `{io} sono stanco`, shown as learners read it.
    expect(found('Io sono stanco.', 'stanco')?.target, '(io) sono stanco');
    expect(found('Sono stanco.', 'stanco')?.target, '(io) sono stanco');
  });

  test('nothing while Use GuideBook is off', () {
    expect(WordLookupSources.forCourse(course(useGuidebook: false)), isEmpty);
    expect(
      WordLookupSources.forCourse(
        course(useGuidebook: false),
        includeDrafts: true,
      ),
      isEmpty,
    );
    expect(
      WordLookupSources.indexFor(course(useGuidebook: false)).isEmpty,
      isTrue,
    );
  });

  // A whole Course from Italian to English: only its English side is
  // searched. QQL Demo: English from Italian was the Course read here until
  // it left the app and the repository in Build 272 Revision 15 (owner
  // decision of 13 October 2026); the Edge Case fixture teaches the same way
  // round.
  group('the Edge Case fixture, Italian to English', () {
    final demo = Course.fromJson(
      jsonDecode(
            File('test/fixtures/v12/edge_case_it_en.json').readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final index = WordLookupSources.indexFor(demo);

    List<String> tap(String text, String word) {
      final result = index.resultAt(
        text,
        text.indexOf(word),
        currentLessonIndex: 0,
      );
      return [
        for (final entry in result?.entries ?? const <WordLookupEntry>[])
          '${entry.target} = ${entry.source}',
      ];
    }

    test('its English lines find their entries', () {
      // The Published Lessons with a Published GuideBook: 7 + 4 + 4 + 1
      // entries. Lesson 4's Draft GuideBook and the Draft Lesson 5 are not
      // read.
      expect(index.length, 16);
      const line = 'Good morning! A coffee, please.';
      expect(tap(line, 'coffee'), ['a coffee = un caffè']);
      // "a" alone is an article, but "a coffee" is an entry.
      expect(tap(line, 'A'), ['a coffee = un caffè']);
      expect(tap(line, 'morning'), isEmpty);
      // "coffee" alone is no entry; it is found inside "a coffee", whose
      // other word is an English article.
      expect(tap('Coffee or tea?', 'Coffee'), ['a coffee = un caffè']);
      expect(tap('Coffee or tea?', 'tea'), ['tea = tè']);
      const passage = 'The little cat is sitting beside the open window.';
      expect(tap(passage, 'cat'), ['cat = gatto']);
      expect(tap(passage, 'window'), ['window = finestra']);
      // A word in the middle of an entry of several words, with the
      // punctuation that follows it.
      expect(tap('A cup of tea, please!', 'cup'), [
        'a cup of tea = una tazza di tè',
      ]);
      expect(tap('A cup of tea, please!', 'of'), [
        'a cup of tea = una tazza di tè',
      ]);
    });

    test('Italian words are never the searched side', () {
      expect(tap('una finestra', 'finestra'), isEmpty);
      expect(tap('Un caffè, per favore.', 'caffè'), isEmpty);
    });
  });
}

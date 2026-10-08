import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_sources.dart';

/// Build 265 Revision 0: where Word Lookup reads its entries.
void main() {
  LearningContent vocabulary(
    String id,
    String text, {
    PublicationState state = PublicationState.published,
  }) => LearningContent(
    id: id,
    publicationState: state,
    kind: 'vocabulary',
    role: 'vocabulary',
    text: text,
  );

  Lesson lesson(
    String id,
    List<LearningContent> content, {
    PublicationState state = PublicationState.published,
    PublicationState guidebookState = PublicationState.published,
  }) => Lesson(
    lessonId: id,
    publicationState: state,
    title: id,
    guidebook: Guidebook(publicationState: guidebookState, content: content),
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
      lesson('first', [
        vocabulary('pane', 'il pane = the bread'),
        vocabulary(
          'draft-word',
          'la bozza = the draft',
          state: PublicationState.draft,
        ),
        const LearningContent(
          id: 'note',
          kind: 'explanation',
          role: 'grammar',
          text: 'il = the',
        ),
      ]),
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

  test('Preview reads Draft Lessons, GuideBooks and entries too', () {
    expect(
      describe(WordLookupSources.forCourse(course(), includeDrafts: true)),
      ['pane@0', 'draft-word@0', 'acqua@1', 'gatto@2', 'cane@3'],
    );
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

  group('QQL Demo: English from Italian', () {
    final demo = Course.fromJson(
      jsonDecode(
            File(
              'assets/courses/english_from_italian_it_en.json',
            ).readAsStringSync(),
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
      expect(index.length, 36);
      const line = 'Excuse me, where is the train to Oxford?';
      expect(tap(line, 'train'), ['the train = il treno']);
      // "the" is in too many entries alone, but "the train" is an entry.
      expect(tap(line, 'the'), ['the train = il treno']);
      expect(tap(line, 'Oxford'), isEmpty);
      expect(tap("It's on platform two.", 'platform'), [
        'the platform = il binario',
      ]);
      expect(tap('Thank you. What time is it?', 'Thank'), [
        'thank you = grazie',
      ]);
      expect(tap('Thank you. What time is it?', 'time'), [
        'what time is it? = che ore sono?',
      ]);
    });

    test('Italian words are never the searched side', () {
      expect(tap('Anna sale sul treno.', 'treno'), isEmpty);
      expect(tap('Un caffè, per favore.', 'caffè'), isEmpty);
    });
  });
}

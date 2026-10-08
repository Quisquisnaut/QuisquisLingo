import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/guidebook_text.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/guidebook_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/course_image_removal.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/course_model_v12_converter.dart';
import 'package:quisquislingo_app/services/guidebook_round_links.dart';
import 'package:quisquislingo_app/services/import/json_limits.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/widgets/word_lookup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 266 Revision 0 (GuideBook Modules, `docs/266_GUIDEBOOK_MODULES_PLAN.md`):
/// a GuideBook is a list of modules; Rounds may name their focus module.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const cat = 'assets/exercise_images/cat.webp';

  Map<String, dynamic> moduleJson({
    String id = 'm1',
    String title = 'Al bar',
    List<Map<String, dynamic>> sentences = const [],
    List<Map<String, dynamic>> words = const [],
    String overview = '',
  }) => {
    'id': id,
    'title': title,
    'sentences': sentences,
    'words': words,
    'overview': overview,
  };

  Guidebook parse(Map<String, dynamic> module) => Guidebook.fromJson({
    'modules': [module],
  });

  group('model and JSON', () {
    test('a module round-trips in the owner\'s field order', () {
      final json = {
        'publicationState': 'draft',
        'modules': [
          moduleJson(
            sentences: [
              {
                'id': 's1',
                'target': 'Lei è stanca?',
                'source': 'Are you tired?',
                'context': 'formal, to a woman',
              },
              {
                'id': 's2',
                'target': '{io} prendo un tè.',
                'source': 'I\'ll have a tea.',
              },
            ],
            words: [
              {
                'id': 'w1',
                'target': 'il conto',
                'source': 'the bill',
                'context': 'restaurant',
              },
              {
                'id': 'w2',
                'target': 'i gatti',
                'source': 'the cats',
                'picture': {'asset': cat, 'plural': true},
              },
            ],
            overview: 'Ordering and paying.',
          ),
        ],
      };
      final guidebook = Guidebook.fromJson(json);
      expect(guidebook.publicationState, PublicationState.draft);
      expect(guidebook.toJson(), json);
      final module = guidebook.modules.single;
      expect(module.toJson().keys, [
        'id',
        'title',
        'sentences',
        'words',
        'overview',
      ]);
      expect(module.words.last.picture!.plural, isTrue);
      expect(guidebook.ids, {'m1', 's1', 's2', 'w1', 'w2'});
      expect(guidebook.words.map((w) => w.id), ['w1', 'w2']);
      expect(guidebook.hasNoEntries, isFalse);
    });

    test('the earlier shape is refused with a clear message', () {
      for (final earlier in [
        {'content': <Object>[]},
        {'insights': <Object>[]},
        {'content': <Object>[], 'modules': <Object>[]},
      ]) {
        expect(
          () => Guidebook.fromJson(earlier),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              Guidebook.earlierShapeMessage,
            ),
          ),
        );
      }
      expect(
        Guidebook.earlierShapeMessage,
        contains('Since build 266 a GuideBook is a list of modules'),
      );
    });

    test('strict parsing refuses what a module cannot hold', () {
      Map<String, dynamic> word(Map<String, dynamic> changes) => {
        'id': 'w',
        'target': 'gatto',
        'source': 'cat',
        ...changes,
      };
      final refused = <Map<String, dynamic>>[
        {...moduleJson(), 'extra': 1},
        moduleJson(title: '  '),
        moduleJson(
          words: [
            word({'target': ' '}),
          ],
        ),
        moduleJson(
          words: [
            word({'source': ''}),
          ],
        ),
        moduleJson(
          words: [
            word({'context': 'x' * 41}),
          ],
        ),
        moduleJson(
          words: [
            word({'colour': 'red'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': '{io sono'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': '{}a'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': '{{io}} sono'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': 'a [b|c]'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': 'a <> b'}),
          ],
        ),
        moduleJson(
          words: [
            word({'target': '{io}'}),
          ],
        ),
        moduleJson(
          sentences: [
            word({
              'picture': {'asset': cat},
            }),
          ],
        ),
        moduleJson(
          words: [
            word({
              'picture': {'asset': 'C:/Users/me/cat.png'},
            }),
          ],
        ),
        moduleJson(
          words: [
            word({
              'picture': {'asset': cat, 'plural': 'yes'},
            }),
          ],
        ),
        moduleJson(
          words: [
            word({
              'picture': {'asset': cat, 'size': 'large'},
            }),
          ],
        ),
      ];
      for (final module in refused) {
        expect(() => parse(module), throwsFormatException, reason: '$module');
      }
      expect(
        () => Guidebook.fromJson({'modules': <Object>[], 'goals': <Object>[]}),
        throwsFormatException,
      );
      // At 40 characters a Context is fine.
      expect(
        parse(
          moduleJson(
            words: [
              word({'context': 'x' * 40}),
            ],
          ),
        ).words.single.context,
        hasLength(40),
      );
    });

    test('a Round may name its focus and supporting modules', () {
      final round = LearningRound(
        id: 'r',
        title: '',
        focusModuleId: 'm2',
        supportingModuleIds: const ['m1'],
      );
      final json = round.toJson();
      expect(json['focusModuleId'], 'm2');
      expect(json['supportingModuleIds'], ['m1']);
      final back = LearningRound.fromJson(json);
      expect(back.focusModuleId, 'm2');
      expect(back.supportingModuleIds, ['m1']);
      // Not stored when unset.
      final plain = LearningRound(id: 'p', title: '').toJson();
      expect(plain.containsKey('focusModuleId'), isFalse);
      expect(plain.containsKey('supportingModuleIds'), isFalse);
      for (final bad in [
        {...json, 'focusModuleId': ''},
        {...json, 'focusModuleId': 3},
        {
          ...json,
          'supportingModuleIds': ['m1', 'm1'],
        },
        {
          ...json,
          'supportingModuleIds': ['m2'],
        },
        {...json, 'supportingModuleIds': 'm1'},
      ]) {
        expect(() => LearningRound.fromJson(bad), throwsFormatException);
      }
    });

    test('optional words: two forms, displayed in brackets', () {
      expect(GuidebookText.targetProblem('{io} sono stanco'), isNull);
      expect(GuidebookText.forms('{io} sono stanco'), [
        'io sono stanco',
        'sono stanco',
      ]);
      expect(GuidebookText.forms('sono stanco'), ['sono stanco']);
      expect(
        GuidebookText.withoutOptionalWords('Sono stanco {io}.'),
        'Sono stanco.',
      );
      expect(GuidebookText.display('{io} sono stanco'), '(io) sono stanco');
      expect(
        GuidebookText.runs('{io} sono stanco').map((r) => (r.text, r.optional)),
        [('io', true), (' sono stanco', false)],
      );
    });

    test('limits: 100 modules and 1,000 entries per GuideBook', () {
      Map<String, dynamic> course(List<Map<String, dynamic>> modules) => {
        'lessons': [
          {
            'lessonId': 'l',
            'guidebook': {'modules': modules},
            'rounds': <Object>[],
          },
        ],
      };
      CourseShapeLimits.check(
        course([for (var i = 0; i < 100; i++) moduleJson(id: 'm$i')]),
      );
      expect(
        () => CourseShapeLimits.check(
          course([for (var i = 0; i < 101; i++) moduleJson(id: 'm$i')]),
        ),
        throwsFormatException,
      );
      final entries = [
        for (var i = 0; i < 1001; i++)
          {'id': 'w$i', 'target': 'a', 'source': 'b'},
      ];
      expect(
        () => CourseShapeLimits.check(course([moduleJson(words: entries)])),
        throwsFormatException,
      );
    });
  });

  group('Rounds follow their GuideBook', () {
    final before = Guidebook(
      modules: [
        GuidebookModule(
          id: 'm1',
          title: 'Saluti',
          words: [testEntry('ciao', 'ciao = hello')],
        ),
        GuidebookModule(
          id: 'm2',
          title: 'Al bar',
          words: [testEntry('conto', 'il conto = the bill')],
        ),
      ],
    );

    test('a removed module and removed entries leave their Rounds', () {
      final after = Guidebook(modules: [before.modules.first]);
      final round = LearningRound(
        id: 'r',
        title: '',
        focusModuleId: 'm2',
        supportingModuleIds: const ['m1'],
        content: const [
          LearningContent(
            id: 'c',
            kind: 'explanation',
            text: 'x',
            sourceRefs: ['conto', 'ciao', 'elsewhere'],
          ),
        ],
      );
      final untouched = LearningRound(id: 'u', title: '', focusModuleId: 'm1');
      final rounds = GuidebookRoundLinks.afterGuidebookSave(before, after, [
        round,
        untouched,
      ]);
      expect(rounds.first.focusModuleId, isNull);
      expect(rounds.first.supportingModuleIds, ['m1']);
      expect(rounds.first.content.single.sourceRefs, ['ciao', 'elsewhere']);
      expect(identical(rounds.last, untouched), isTrue);
      expect(GuidebookRoundLinks.focusCount(rounds, 'm1'), 1);
    });

    test('a Round moved to another Lesson loses its module links', () {
      final course = Course(
        courseId: 'links',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Links',
        ttsLanguage: 'it-IT',
        lessons: [
          Lesson(
            lessonId: 'l1',
            title: 'One',
            guidebook: before,
            rounds: [
              LearningRound(
                id: 'r1',
                title: 'R',
                focusModuleId: 'm2',
                supportingModuleIds: const ['m1'],
              ),
            ],
          ),
          Lesson(lessonId: 'l2', title: 'Two', rounds: const []),
        ],
      );
      final transfer = CourseAuthoringTransferService(
        clock: () => DateTime.utc(2026, 10, 8),
      );
      final moved = transfer.moveRound(
        course,
        sourceLessonId: 'l1',
        roundId: 'r1',
        destinationLessonId: 'l2',
      );
      final round = moved.lessons.last.rounds.single;
      expect(round.focusModuleId, isNull);
      expect(round.supportingModuleIds, isEmpty);
      // Duplicated in its own Lesson, a Round keeps its links.
      final copy = AuthoringDuplicationService(
        ids: TimestampAuthoringIdGenerator(seed: 266),
      ).duplicateRound(course.lessons.first.rounds.single);
      expect(copy.focusModuleId, 'm2');
      expect(copy.supportingModuleIds, ['m1']);
    });
  });

  group('Audit', () {
    Course course({
      required Guidebook guidebook,
      bool useGuidebook = true,
      String? focus,
    }) => Course(
      courseId: 'audit-modules',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Audit modules',
      ttsLanguage: 'it-IT',
      useGuidebook: useGuidebook,
      lessons: [
        Lesson(
          lessonId: 'l1',
          title: 'Lesson',
          guidebook: guidebook,
          rounds: [LearningRound(id: 'r1', title: 'R', focusModuleId: focus)],
        ),
      ],
    );
    Set<String> codes(Course c) =>
        CourseAuditService().auditCourse(c).issues.map((i) => i.code).toSet();

    final good = GuidebookModule(
      id: 'm1',
      title: 'Saluti',
      words: [testEntry('ciao', 'ciao = hello')],
    );

    test('an empty module is a Warning, a long Overview an Info', () {
      final found = codes(
        course(
          guidebook: Guidebook(
            modules: [
              good,
              GuidebookModule(id: 'm2', title: 'Empty'),
              GuidebookModule(
                id: 'm3',
                title: 'Long',
                words: [testEntry('pane', 'pane = bread')],
                overview: 'x' * 500,
              ),
            ],
          ),
        ),
      );
      expect(
        found,
        containsAll([
          'GUIDEBOOK_MODULE_EMPTY',
          'GUIDEBOOK_MODULE_OVERVIEW_LONG',
        ]),
      );
      expect(found, isNot(contains('LESSON_GUIDEBOOK_EMPTY')));
      final issues = CourseAuditService()
          .auditCourse(
            course(
              guidebook: Guidebook(
                modules: [
                  good,
                  GuidebookModule(id: 'm2', title: 'Empty'),
                ],
              ),
            ),
          )
          .issues;
      expect(
        issues.singleWhere((i) => i.code == 'GUIDEBOOK_MODULE_EMPTY').location,
        'Lesson 1 · Lesson · Guidebook · Module 2',
      );
    });

    test('an Overview of 499 characters is no Info', () {
      expect(
        codes(
          course(
            guidebook: Guidebook(modules: [good.copyWith(overview: 'x' * 499)]),
          ),
        ),
        isNot(contains('GUIDEBOOK_MODULE_OVERVIEW_LONG')),
      );
    });

    test('a GuideBook without entries is LESSON_GUIDEBOOK_EMPTY', () {
      expect(
        codes(course(guidebook: Guidebook())),
        contains('LESSON_GUIDEBOOK_EMPTY'),
      );
      expect(
        codes(
          course(
            guidebook: Guidebook(
              modules: [GuidebookModule(id: 'm', title: 'Only a title')],
            ),
          ),
        ),
        containsAll(['LESSON_GUIDEBOOK_EMPTY', 'GUIDEBOOK_MODULE_EMPTY']),
      );
    });

    test('module rules wait while Use GuideBook is off; IDs never', () {
      final off = codes(
        course(
          useGuidebook: false,
          guidebook: Guidebook(
            modules: [
              GuidebookModule(id: 'm2', title: 'Empty', overview: 'x' * 600),
              GuidebookModule(
                id: 'dup',
                title: 'Dup',
                words: [testEntry('same', 'a = b'), testEntry('same', 'c = d')],
              ),
            ],
          ),
        ),
      );
      expect(off, isNot(contains('GUIDEBOOK_MODULE_EMPTY')));
      expect(off, isNot(contains('GUIDEBOOK_MODULE_OVERVIEW_LONG')));
      expect(off, contains('ID_DUPLICATE'));
    });

    test('a Round pointing to a missing module is a Warning', () {
      final guidebook = Guidebook(modules: [good]);
      expect(
        codes(course(guidebook: guidebook, focus: 'm1')),
        isNot(contains('ROUND_FOCUS_MODULE_MISSING')),
      );
      final issue = CourseAuditService()
          .auditCourse(course(guidebook: guidebook, focus: 'gone'))
          .issues
          .singleWhere((i) => i.code == 'ROUND_FOCUS_MODULE_MISSING');
      expect(issue.severity, AuditSeverity.warning);
      expect(issue.roundId, 'r1');
      expect(issue.message, contains('gone'));
    });
  });

  group('the v11 converter', () {
    Map<String, dynamic> v11({
      List<Map<String, dynamic>> content = const [],
      List<Map<String, dynamic>>? insights,
      String? state,
    }) => {
      'formatVersion': 11,
      'courseId': 'v11-guidebook',
      'publicationState': 'published',
      'lessonNumberingMode': 'lesson',
      'defaultLessonIconStyle': 'monochrome',
      'originType': 'custom',
      'originalCourseCreator': {
        'type': 'qqlUser',
        'id': '12345678-1234-4234-9234-123456789abc',
        'displayName': 'Author',
      },
      'maintainer': {'profileId': '12345678-1234-4234-9234-123456789abc'},
      'originalCreatedAtUtc': '2026-10-01T00:00:00.000Z',
      'courseVersion': '1',
      'lastVersionEditorProfileId': '12345678-1234-4234-9234-123456789abc',
      'lastVersionEditorDisplayName': 'Author',
      'modifiedAtUtc': '2026-10-01T00:00:00.000Z',
      'learningLanguage': 'Italian',
      'interfaceLanguage': 'English',
      'sourceLanguage': 'English',
      'targetLanguage': 'Italian',
      'title': 'v11',
      'ttsLanguage': 'it-IT',
      'lessons': [
        {
          'lessonId': 'l1',
          'publicationState': 'published',
          'updatedAt': '2026-10-01T00:00:00.000Z',
          'title': 'Lesson',
          'section': false,
          'guidebook': {
            'publicationState': ?state,
            'content': content,
            'insights': ?insights,
          },
          'rounds': <Object>[],
          'duel': {'id': 'l1_duel', 'title': 'Duel'},
        },
      ],
    };
    Map<String, dynamic> item(
      String id,
      String kind,
      String text, {
      String? role,
      String state = 'published',
    }) => {
      'id': id,
      'publicationState': state,
      'kind': kind,
      'required': false,
      'role': ?role,
      'text': text,
    };

    test('a GuideBook becomes one module named "Module 1"', () {
      final result = convertCourseJsonToV12(
        v11(
          content: [
            item('g1', 'explanation', 'Overview.', role: 'overview'),
            item('g2', 'text', 'A goal.', role: 'goal'),
            item('g3', 'explanation', 'A grammar note.', role: 'grammar'),
            item('g4', 'vocabulary', 'casa = house', role: 'vocabulary'),
            item('g5', 'vocabulary', 'not a pair', role: 'vocabulary'),
            item('g6', 'example', 'La casa è grande.', role: 'example'),
          ],
          insights: [
            {'title': 'Insight', 'text': 'Its text.'},
          ],
        ),
      );
      final guidebook = Course.fromJson(result.json).lessons.single.guidebook;
      final module = guidebook.modules.single;
      expect(module.id, 'l1_module_1');
      expect(module.title, 'Module 1');
      expect(module.words.single.id, 'g4');
      expect(module.words.single.target, 'casa');
      expect(module.sentences, isEmpty);
      // Nothing is lost: the example and the line that is no pair are in
      // the Overview (owner decision of 8 October 2026).
      expect(
        module.overview,
        'Overview.\n\nA goal.\n\nA grammar note.\n\nInsight\nIts text.'
        '\n\nnot a pair\nLa casa è grande.',
      );
      expect(result.notes, hasLength(3));
      expect(result.notes[0], contains('“Module 1”: rename it'));
      expect(
        result.notes[1],
        contains('1 example sentence has no translation'),
      );
      expect(result.notes[2], contains('1 vocabulary line could not be read'));
    });

    test('an empty GuideBook stays empty; Draft entries make it Draft', () {
      final empty = convertCourseJsonToV12(v11());
      expect(empty.json['lessons'][0]['guidebook'], {'modules': <Object>[]});
      expect(empty.notes, isEmpty);
      final draft = convertCourseJsonToV12(
        v11(
          content: [item('g1', 'vocabulary', 'casa = house', state: 'draft')],
        ),
      );
      expect(
        draft.json['lessons'][0]['guidebook']['publicationState'],
        'draft',
      );
      expect(draft.notes.last, contains('it is now a Draft'));
    });
  });

  group('pictures of words are Course pictures', () {
    final media = 'media:${'a' * 64}.png';
    Course course() => Course(
      courseId: 'pictures',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Pictures',
      ttsLanguage: 'it-IT',
      lessons: [
        Lesson(
          lessonId: 'l1',
          title: 'Lesson',
          guidebook: testGuidebook(
            title: 'Animali',
            words: [
              testEntry(
                'gatti',
                'i gatti = the cats',
                picture: GuidebookPicture(
                  asset: media,
                  plural: true,
                  sharedImageSource: SharedImageSource(
                    id: 'device-cat',
                    label: 'Cat',
                    category: 'animals',
                    tags: ['cat'],
                    origin: 'local',
                  ),
                ),
              ),
            ],
          ),
          rounds: const [],
        ),
      ],
    );

    test('IN USE, its Shared Image Library source, and removal', () {
      final c = course();
      expect(CourseImageUsage.usedAssets(c), contains(media));
      expect(CourseImageUsage.sharedSourceOf(c, media)?.id, 'device-cat');
      final use = CourseImageUsage.uses(c).single;
      expect(use.location, 'Lesson 1 › GuideBook › Animali › i gatti');
      final removed = CourseImageRemoval.remove(c, {
        media,
      }, now: DateTime.utc(2026, 10, 8));
      expect(removed.clearedUses, 1);
      expect(
        removed.course.lessons.single.guidebook.words.single.picture,
        isNull,
      );
    });
  });

  group('screens', () {
    void viewport(WidgetTester tester, {double width = 1000}) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }

    Future<Guidebook?> openEditor(
      WidgetTester tester,
      Guidebook guidebook, {
      List<LearningRound> rounds = const [],
      void Function(Guidebook?)? onSaved,
    }) async {
      Guidebook? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  saved = await Navigator.of(context).push<Guidebook>(
                    MaterialPageRoute(
                      builder: (_) => GuidebookEditorScreen(
                        guidebook: guidebook,
                        rounds: rounds,
                        ids: TimestampAuthoringIdGenerator(seed: 266),
                      ),
                    ),
                  );
                  onSaved?.call(saved);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return saved;
    }

    testWidgets('Add module, write rows, Done, Save', (tester) async {
      viewport(tester);
      Guidebook? saved;
      await openEditor(tester, Guidebook(), onSaved: (g) => saved = g);
      expect(find.byKey(const Key('guidebook-modules-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('guidebook-add-module')));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('guidebook-module-title')),
        'Al bar',
      );
      await tester.tap(find.byKey(const ValueKey('guidebook-module-add-word')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('guidebook-module-word-0-target')),
        'il conto',
      );
      // A Target without a Source is refused and pointed to.
      await tester.tap(find.byKey(const Key('guidebook-module-done')));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsOneWidget);
      expect(find.text('Write the Source, or clear the row.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('guidebook-module-word-0-source')),
        'the bill',
      );
      await tester.enterText(
        find.byKey(const ValueKey('guidebook-module-word-0-context')),
        'restaurant',
      );
      // An empty row is dropped.
      await tester.tap(
        find.byKey(const ValueKey('guidebook-module-add-sentence')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guidebook-module-done')));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsNothing);
      expect(find.text('Al bar'), findsOneWidget);
      expect(find.text('0 sentences · 1 word'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guidebook-save')));
      await tester.pumpAndSettle();
      final module = saved!.modules.single;
      expect(module.title, 'Al bar');
      expect(module.sentences, isEmpty);
      expect(module.words.single.target, 'il conto');
      expect(module.words.single.context, 'restaurant');
      expect(saved!.publicationState, PublicationState.published);
    });

    testWidgets('Remove says how many Rounds focus on the module', (
      tester,
    ) async {
      viewport(tester);
      Guidebook? saved;
      await openEditor(
        tester,
        testGuidebook(
          moduleId: 'm1',
          title: 'Saluti',
          wordLines: const ['ciao = hello'],
        ),
        rounds: [
          LearningRound(id: 'a', title: '', focusModuleId: 'm1'),
          LearningRound(id: 'b', title: '', focusModuleId: 'm1'),
        ],
        onSaved: (g) => saved = g,
      );
      await tester.tap(find.byKey(const ValueKey('guidebook-module-remove-0')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2 Rounds focus on this module'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('guidebook-module-remove-confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guidebook-save-draft')));
      await tester.pumpAndSettle();
      expect(saved!.modules, isEmpty);
      expect(saved!.publicationState, PublicationState.draft);
    });

    testWidgets('the module page fits 360 pixels with a picture and Plural', (
      tester,
    ) async {
      viewport(tester, width: 360);
      await openEditor(
        tester,
        testGuidebook(
          words: [
            testEntry(
              'gatti',
              'i gatti = the cats',
              picture: const GuidebookPicture(asset: cat, plural: true),
            ),
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('guidebook-module-0')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final plural = find.byKey(
        const ValueKey('guidebook-module-word-0-picture-plural'),
      );
      expect(plural, findsOneWidget);
      expect(tester.widget<FilterChip>(plural).selected, isTrue);
      expect(find.byKey(const Key('plural-picture')), findsWidgets);
      // Removing the picture removes its mark.
      await tester.tap(
        find.byKey(const ValueKey('guidebook-module-word-0-picture-remove')),
      );
      await tester.pumpAndSettle();
      expect(plural, findsNothing);
    });

    testWidgets('learners read each module; optional words in grey', (
      tester,
    ) async {
      viewport(tester);
      final guidebook = Guidebook(
        modules: [
          for (var m = 1; m <= 6; m++)
            GuidebookModule(
              id: 'm$m',
              title: 'Module title $m',
              sentences: [testEntry('s$m', '{io} sono stanco = I am tired')],
              words: [
                testEntry(
                  'w$m',
                  'il conto = the bill',
                  context: 'restaurant',
                  picture: m == 1
                      ? const GuidebookPicture(asset: cat, plural: true)
                      : null,
                ),
              ],
              overview: 'Overview $m. ${'Long text. ' * 30}',
            ),
        ],
      );
      final course = Course(
        courseId: 'learner-modules',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Learner modules',
        ttsLanguage: 'it-IT',
        lessons: [
          Lesson(
            lessonId: 'l1',
            title: 'Lesson',
            guidebook: guidebook,
            rounds: const [],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookScreen(
            course: course,
            lesson: course.lessons.single,
            lessonIndex: 0,
            focusModuleId: 'm6',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('guidebook-module-m1')), findsOneWidget);
      expect(find.text('(io) sono stanco — I am tired'), findsNWidgets(6));
      expect(find.text('il conto — the bill  restaurant'), findsNWidgets(6));
      expect(
        find.byKey(const ValueKey('guidebook-entry-picture-w1')),
        findsOneWidget,
      );
      // Opened at the focus module: its title is on the screen.
      final title = find.byKey(const ValueKey('guidebook-module-title-m6'));
      expect(title.hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guidebook-module-title-m1')).hitTestable(),
        findsNothing,
      );
    });

    testWidgets('the Word Lookup card shows the Context and the picture', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordLookupCard(
              entries: const [
                WordLookupEntry(
                  id: 'w',
                  target: 'i gatti',
                  source: 'the cats',
                  context: 'animals',
                  picture: GuidebookPicture(asset: cat, plural: true),
                  lessonIndex: 0,
                ),
              ],
              lessonName: (_) => '',
              currentLessonIndex: 0,
              note: 'One possible translation.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('word-lookup-picture-0')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('plural-picture')), findsOneWidget);
      expect(find.text('the cats  animals'), findsOneWidget);
    });

    testWidgets('the Round editor names the focus module', (tester) async {
      viewport(tester, width: 1200);
      final course = Course(
        courseId: 'focus-menu',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Focus menu',
        ttsLanguage: 'it-IT',
        lessons: [
          Lesson(
            lessonId: 'l1',
            title: 'Lesson',
            guidebook: Guidebook(
              modules: [
                GuidebookModule(
                  id: 'm1',
                  title: 'Saluti',
                  words: [testEntry('ciao', 'ciao = hello')],
                ),
                GuidebookModule(
                  id: 'm2',
                  title: 'Al bar',
                  words: [testEntry('conto', 'il conto = the bill')],
                ),
              ],
            ),
            rounds: [
              LearningRound(
                id: 'r1',
                title: 'R',
                focusModuleId: 'm1',
                supportingModuleIds: const ['m2'],
              ),
            ],
          ),
        ],
      );
      Course? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: course.lessons.single,
            round: course.lessons.single.rounds.single,
            roundIndex: 0,
            onCourseChanged: (value) => changed = value,
            clock: () => DateTime.utc(2026, 10, 8),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('round-focus-module')), findsOneWidget);
      expect(find.text('Also reviews: Al bar'), findsOneWidget);
      await tester.tap(find.byKey(const Key('round-focus-module')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al bar').last);
      await tester.pumpAndSettle();
      final round = changed!.lessons.single.rounds.single;
      expect(round.focusModuleId, 'm2');
      // The new focus leaves the supporting modules.
      expect(round.supportingModuleIds, isEmpty);
      expect(find.byKey(const Key('round-supporting-modules')), findsNothing);
    });

    testWidgets('Editor Help opens at the GuideBook question', (tester) async {
      viewport(tester);
      await tester.pumpWidget(
        const MaterialApp(home: EditorHelpScreen(question: 'guidebook')),
      );
      await tester.pumpAndSettle();
      final answer = find.byKey(const ValueKey('editor-help-answer-guidebook'));
      expect(answer.hitTestable(), findsOneWidget);
    });
  });
}

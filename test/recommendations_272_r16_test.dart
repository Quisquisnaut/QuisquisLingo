import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/authoring_hierarchy_status.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 272 Revision 16 (owner decisions of 13 October 2026, brought
/// forward from the Build 274 plan): two recommendations stop being
/// Warnings. The number of pairs of Listen and match and Match by meaning
/// is advice, said only for one pair or for six and more; a Flashcard's
/// missing usage sentence and missing read-aloud are advice too, and the
/// usage sentence is also recommended for a Picture flashcard.
const _profile = '00000000-0000-4000-8000-000000272016';
const _created = '2026-10-13T00:00:00.000Z';

const _words = [
  ['caldo', 'freddo'],
  ['grande', 'piccolo'],
  ['aperto', 'chiuso'],
  ['alto', 'basso'],
  ['lungo', 'corto'],
  ['nuovo', 'vecchio'],
  ['facile', 'difficile'],
];

/// The exercise the preset's own form builds from [values].
Exercise _built(String preset, ExerciseDraftValues Function(Exercise) values) {
  final built = ExerciseDraftBuilder.build(
    values(PresetRecipes.blankFor(preset, 'r16_$preset')),
  );
  expect(built.error, isNull, reason: preset);
  return built.candidate!;
}

Exercise _match(String preset, int pairs) => _built(
  preset,
  (blank) => ExerciseDraftValues(
    original: blank,
    type: preset,
    publicationState: PublicationState.published,
    // Not "opposite": the Audit has a rule of its own about opposites in
    // a Lesson's first Rounds, which is not what this file is about.
    prompt: preset == 'super_match' ? 'Match the words that go together.' : '',
    pairs: [
      for (final pair in _words.take(pairs)) '${pair[0]} = ${pair[1]}',
    ].join('\n'),
  ),
);

Exercise _card(
  String preset, {
  String usage = '',
  String readAloud = 'manual',
  String image = '',
}) => _built(
  preset,
  (blank) => ExerciseDraftValues(
    original: blank,
    type: preset,
    publicationState: PublicationState.published,
    prompt: 'il pane',
    question: 'bread',
    answers: usage,
    cardReadAloud: readAloud,
    imageAsset: image,
  ),
);

List<CourseAuditIssue> _issues(Exercise exercise) =>
    CourseAuditService().auditExercise(exercise);

List<CourseAuditIssue> _concerns(Exercise exercise) => [
  for (final issue in _issues(exercise))
    if (issue.severity != AuditSeverity.info) issue,
];

Course _course(List<Exercise> exercises) => Course(
  courseId: 'recommendations-272-r16',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profile,
    displayName: 'Author',
  ),
  originalCreatedAtUtc: _created,
  maintainer: const CourseMaintainer(_profile),
  lastVersionEditorProfileId: _profile,
  lastVersionEditorDisplayName: 'Author',
  modifiedAtUtc: _created,
  title: 'Recommendations',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  authors: const [
    CourseAuthor(name: 'Test Author', roles: ['Author']),
  ],
  rightsHolders: const [
    CourseRightsHolder(
      type: CourseRightsHolderType.person,
      name: 'Test Author',
    ),
  ],
  useGuidebook: false,
  createDuels: false,
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Words that go together',
      rounds: [
        LearningRound(id: 'round', title: 'Words', exercises: exercises),
      ],
    ),
  ],
);

class _Speech extends TtsCacheService {
  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async => true;

  @override
  Future<void> stop() async {}
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the number of pairs', () {
    for (final (preset, code, name) in const [
      ('super_match', 'MATCH_PAIR_COUNT', 'Match by meaning'),
      ('audio_match', 'AUDIO_MATCH_PAIR_COUNT', 'Listen and match'),
    ]) {
      test('$name: a note only for one pair, or for six and more', () {
        for (var pairs = 1; pairs <= 7; pairs++) {
          final found = [
            for (final issue in _issues(_match(preset, pairs)))
              if (issue.code == code) issue,
          ];
          final advised = pairs == 1 || pairs >= 6;
          expect(found, hasLength(advised ? 1 : 0), reason: '$pairs pairs');
          if (advised) {
            expect(found.single.severity, AuditSeverity.info);
            expect(
              found.single.message,
              '$name has $pairs ${pairs == 1 ? 'pair' : 'pairs'}: 2 to 5 are '
              'recommended.',
            );
          }
        }
      });

      test('$name: two to five pairs raise no Error and no Warning', () {
        for (var pairs = 2; pairs <= 5; pairs++) {
          expect(
            _concerns(_match(preset, pairs)).map((issue) => issue.code),
            isEmpty,
            reason: '$pairs pairs',
          );
        }
      });

      test('$name: one pair, or seven, is never an Error or a Warning for '
          'its number', () {
        for (final pairs in [1, 7]) {
          expect(
            _concerns(_match(preset, pairs)).map((issue) => issue.code),
            isNot(contains(code)),
            reason: '$pairs pairs',
          );
        }
      });
    }

    test('the rule: fewer than two, or more than five', () {
      expect(CourseAuditService.recommendedPairs, (min: 2, max: 5));
      expect(
        [
          for (var pairs = 0; pairs <= 7; pairs++)
            CourseAuditService.pairCountOutsideAdvice(pairs),
        ],
        // No pair at all is said by other rules.
        [false, true, false, false, false, false, true, true],
      );
    });
  });

  group('Flashcards', () {
    List<String> codes(Exercise exercise) => [
      for (final issue in _issues(exercise)) issue.code,
    ];

    test('a Flashcard without a usage sentence gets a note, not a '
        'Warning', () {
      final card = _card('flashcard');
      final found = _issues(
        card,
      ).singleWhere((issue) => issue.code == 'FLASHCARD_EXAMPLE_EMPTY');
      expect(found.severity, AuditSeverity.info);
      expect(found.message, 'Flashcard has no usage sentence.');
      expect(_concerns(card), isEmpty);
      expect(
        codes(
          _card('flashcard', usage: 'Il pane è buono.\nThe bread is good.'),
        ),
        isNot(contains('FLASHCARD_EXAMPLE_EMPTY')),
      );
    });

    test('a Picture flashcard gets the same note', () {
      const picture = 'assets/exercise_images/bread.webp';
      final card = _card('picture_flashcard', image: picture);
      final found = _issues(
        card,
      ).singleWhere((issue) => issue.code == 'FLASHCARD_EXAMPLE_EMPTY');
      expect(found.severity, AuditSeverity.info);
      // One wording for both kinds: a Flashcard may carry a picture too.
      expect(found.message, 'Flashcard has no usage sentence.');
      expect(_concerns(card), isEmpty);
      expect(
        codes(
          _card('picture_flashcard', image: picture, usage: 'Il pane è buono.'),
        ),
        isNot(contains('FLASHCARD_EXAMPLE_EMPTY')),
      );
    });

    test('a Flashcard without read-aloud gets a note; a Picture flashcard '
        'none', () {
      final silent = _card(
        'flashcard',
        usage: 'Il pane è buono.',
        readAloud: 'none',
      );
      final found = _issues(
        silent,
      ).singleWhere((issue) => issue.code == 'FLASHCARD_AUDIO_EMPTY');
      expect(found.severity, AuditSeverity.info);
      expect(found.message, 'Flashcard has no read-aloud.');
      expect(_concerns(silent), isEmpty);
      expect(
        codes(_card('flashcard', usage: 'Il pane è buono.')),
        isNot(contains('FLASHCARD_AUDIO_EMPTY')),
      );
      expect(
        codes(
          _card(
            'picture_flashcard',
            image: 'assets/exercise_images/bread.webp',
            usage: 'Il pane è buono.',
            readAloud: 'none',
          ),
        ),
        isNot(contains('FLASHCARD_AUDIO_EMPTY')),
      );
    });

    test('a Note card gets neither', () {
      final note = _built(
        'note_card',
        (blank) => ExerciseDraftValues(
          original: blank,
          type: 'note_card',
          publicationState: PublicationState.published,
          prompt: 'Remember',
          question: 'Bread is masculine in Italian.',
        ),
      );
      expect(codes(note), isNot(contains('FLASHCARD_EXAMPLE_EMPTY')));
      expect(codes(note), isNot(contains('FLASHCARD_AUDIO_EMPTY')));
    });
  });

  // Build 274 Revision 3 added the five SOUND_ANSWER rules (four Errors,
  // one Info).
  test('the four messages are Infos of the registry: 136 rules, 70 Errors, '
      '44 Warnings, 22 Infos', () {
    for (final code in const [
      AuditCode.matchPairCount,
      AuditCode.audioMatchPairCount,
      AuditCode.flashcardExampleEmpty,
      AuditCode.flashcardAudioEmpty,
    ]) {
      expect(code.severity, AuditSeverity.info, reason: code.code);
    }
    int count(AuditSeverity severity) =>
        AuditCode.values.where((code) => code.severity == severity).length;
    expect(AuditCode.values, hasLength(136));
    expect(count(AuditSeverity.error), 70);
    expect(count(AuditSeverity.warning), 44);
    expect(count(AuditSeverity.info), 22);
  });

  test('nothing turns red for them: no Audit concern on the exercise, its '
      'Round, its Lesson or the Course', () {
    final exercises = [
      _match('super_match', 1),
      _match('audio_match', 6),
      _card('flashcard', readAloud: 'none'),
      _card('picture_flashcard', image: 'assets/exercise_images/bread.webp'),
    ];
    final course = _course(exercises);
    final audit = CourseAuditService().auditCourse(course);
    expect([
      for (final issue in audit.issues)
        if (issue.severity != AuditSeverity.info)
          '${issue.code}: ${issue.message}',
    ], isEmpty);
    // The notes are there.
    expect(
      audit.issues.map((issue) => issue.code),
      containsAll(const [
        'MATCH_PAIR_COUNT',
        'AUDIO_MATCH_PAIR_COUNT',
        'FLASHCARD_EXAMPLE_EMPTY',
        'FLASHCARD_AUDIO_EMPTY',
      ]),
    );
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(status.hasCourseAuditConcern, isFalse);
    expect(status.hasLessonsAuditConcern, isFalse);
    expect(status.exerciseAuditConcernIds, isEmpty);
    expect(status.roundAuditConcernIds, isEmpty);
    expect(status.lessonAuditConcernIds, isEmpty);
  });

  group('the learner\'s page lays out five pairs in a narrow window', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      keepCrashLogUnavailable();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => testSupportDirectory.path,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (_) async => null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (_) async => null,
      );
    });

    for (final preset in const ['super_match', 'audio_match']) {
      testWidgets('$preset with five pairs', (tester) async {
        // Narrow, and tall enough for the whole exercise to be built.
        tester.view.physicalSize = const Size(360, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final exercise = _match(preset, 5);
        final course = _course([exercise]);
        final lesson = course.lessons.single;
        final round = lesson.rounds.single;
        await tester.pumpWidget(
          MaterialApp(
            home: RoundScreen(
              key: ValueKey(preset),
              course: course,
              lesson: lesson,
              round: round,
              ttsLanguage: course.ttsLanguage,
              roundIndex: 0,
              previewMode: true,
              ttsCacheService: _Speech(),
            ),
          ),
        );
        await _until(tester, find.byKey(const Key('exercise-renderer-match')));
        await tester.pump(const Duration(milliseconds: 300));
        // All five pairs are there, and nothing overflows.
        if (preset == 'super_match') {
          expect(
            find.byType(DropdownButtonFormField<String>),
            findsNWidgets(5),
          );
          for (final pair in _words.take(5)) {
            expect(find.text(pair[0]), findsOneWidget, reason: pair[0]);
          }
        } else {
          expect(find.byTooltip('Play sound'), findsNWidgets(5));
          for (final pair in _words.take(5)) {
            // Each sound offers every visible text.
            expect(
              find.widgetWithText(ChoiceChip, pair[1]),
              findsNWidgets(5),
              reason: pair[1],
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}

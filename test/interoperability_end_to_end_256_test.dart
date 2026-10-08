import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/canonical_course_256.dart';
import 'support/fake_file_dialog_backend.dart';
import 'support/publisher_fixtures.dart';
import 'support/test_directories.dart';

/// Build 256 Revision 6, the plan's final acceptance scenario: a v12 Course
/// written without QQL (no preset metadata) with a Story, playable
/// exercises of every shape and exercises this version cannot play. QQL
/// reads it, validates it, plays what it can, keeps the rest, inspects and
/// edits it, duplicates, searches, merges, signs and exports it, and reads
/// it back with the same semantics.
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

Iterable<Exercise> _exercisesOf(Course course) =>
    course.lessons.expand((lesson) => lesson.rounds).expand((r) => r.exercises);

LearningRound _roundOf(Course course, String id) =>
    course.lessons.single.rounds.singleWhere((round) => round.id == id);

void _expectSameSemantics(Course actual, Course expected) {
  final left = _exercisesOf(actual).toList();
  final right = _exercisesOf(expected).toList();
  expect(left.length, right.length);
  for (var i = 0; i < left.length; i++) {
    expect(left[i].id, right[i].id);
    expect(
      left[i].semanticallyEquals(right[i]),
      isTrue,
      reason: '${left[i].id} changed meaning',
    );
    expect(left[i].authoringMetadata, isEmpty, reason: left[i].id);
  }
  for (final round in expected.lessons.single.rounds) {
    expect(
      jsonEncode(_roundOf(actual, round.id).flow?.toJson()),
      jsonEncode(round.flow?.toJson()),
      reason: '${round.id} flow',
    );
  }
}

void _platforms() {
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
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpRound(
  WidgetTester tester,
  Course course,
  LearningRound round, {
  bool preview = false,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: course.lessons.single.rounds.indexOf(round),
        previewMode: preview,
        ttsCacheService: _Speech(),
      ),
    ),
  );
}

void main() {
  final course = canonicalCourse256();

  test('the file carries canonical data only and reads back unchanged', () {
    final json = course.toJson();
    final text = jsonEncode(json);
    expect(text, isNot(contains('authoringMetadata')));
    expect(text, isNot(contains('presetId')));
    expect(json['formatVersion'], 12);
    _expectSameSemantics(Course.fromJson(json), course);
    expect(
      CourseChecksums.whole(Course.fromJson(json)),
      CourseChecksums.whole(course),
    );
  });

  test(
    'import from a JSON file and from a package keeps the semantics',
    () async {
      final transfer = CustomCourseTransferService();
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode(course.toJson())),
      );
      final imported = await transfer.courseFromBytes(bytes, 'external.json');
      _expectSameSemantics(imported, course);

      final packages = CoursePackageService(stager: testImportStager());
      final zip = await packages.build(course, bytes);
      final package = await packages.parse(zip, transfer.courseFromBytes);
      try {
        _expectSameSemantics(package.course, course);
      } finally {
        await package.discard();
      }
    },
  );

  test(
    'the Audit accepts it: information for the unplayable, warnings where learners cannot finish',
    () {
      final issues = CourseAuditService().auditCourse(course).issues;
      expect(
        issues.where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
        reason: issues
            .where((issue) => issue.severity == AuditSeverity.error)
            .map((issue) => '${issue.code} ${issue.message}')
            .join('\n'),
      );
      final later = canonicalNotExecutable256();
      expect(
        issues
            .where((issue) => issue.code == 'EXERCISE_NOT_EXECUTABLE')
            .map((issue) => issue.exerciseId)
            .toSet(),
        {...later.map((exercise) => exercise.id), 'sel_later_2'},
      );
      expect(
        issues
            .where((issue) => issue.code == 'ROUND_NOT_COMPLETABLE')
            .map((issue) => issue.roundId)
            .toSet(),
        {
          CanonicalRounds256.later,
          CanonicalRounds256.endsLater,
          CanonicalRounds256.branch,
        },
      );
    },
  );

  test(
    'playability, Laurel eligibility and the Duel follow the support state',
    () {
      final playability = RoundPlayabilityService();
      final play = _roundOf(course, CanonicalRounds256.play);
      expect(
        playability.playableExerciseIndices(play),
        List.generate(play.exercises.length, (index) => index),
      );
      for (final exercise in play.exercises) {
        expect(exercise.isExecutable, isTrue, reason: exercise.id);
      }
      final later = _roundOf(course, CanonicalRounds256.later);
      expect(playability.playableExerciseIndices(later), isEmpty);
      expect(
        playability.notExecutableIndices(later).length,
        later.exercises.length,
      );
      for (final exercise in later.exercises) {
        expect(exercise.isExecutable, isFalse, reason: exercise.id);
        expect(
          exercise.runtimeSupport.state,
          ExerciseSupportState.readableButNotExecutable,
          reason: exercise.id,
        );
      }
      expect(
        playability.playableExerciseIndices(
          _roundOf(course, CanonicalRounds256.branch),
        ),
        isEmpty,
      );
      expect(playability.laurelEligibleRoundIds(course), {
        CanonicalRounds256.play,
        CanonicalRounds256.story,
      });
      final duel = const DuelEligibilityService().evaluate(
        course.lessons.single,
      );
      expect(
        duel.candidates.map((candidate) => candidate.exercise.id).toSet(),
        {'sel_one'},
        reason: 'one playable single choice outside the Stories',
      );
    },
  );

  test(
    'duplication, search, recognition and the editor draft keep every primitive',
    () {
      final later = _roundOf(course, CanonicalRounds256.later);
      final copy = AuthoringDuplicationService(
        clock: () => canonicalCourse256Stamp,
      ).duplicateRound(later);
      expect(copy.id, isNot(later.id));
      expect(copy.exercises.length, later.exercises.length);
      for (var i = 0; i < later.exercises.length; i++) {
        final source = later.exercises[i];
        final duplicate = copy.exercises[i];
        expect(duplicate.id, isNot(source.id));
        expect(duplicate.primitive, source.primitive, reason: source.id);
        expect(
          duplicate.effectiveOptions.toJson(),
          source.effectiveOptions.toJson(),
          reason: source.id,
        );
        expect(
          duplicate.canonicalEvaluation.mode,
          source.canonicalEvaluation.mode,
        );
        expect(duplicate.items.length, source.items.length);
        expect(duplicate.targets.length, source.targets.length);
      }

      final results = const ExerciseSearchService().search(
        course,
        query: 'gatto',
      );
      expect(results, isNotEmpty);

      for (final exercise in _exercisesOf(course)) {
        final draft = CanonicalExerciseDraft.fromExercise(exercise);
        expect(draft.violations, isEmpty, reason: exercise.id);
        final rebuilt = draft.toExercise(
          publicationState: exercise.publicationState,
          updatedAt: exercise.updatedAt,
        );
        expect(
          rebuilt.semanticallyEquals(exercise),
          isTrue,
          reason: '${exercise.id} through the editor draft',
        );
      }

      // Recognition is a hint the editor derives; it never wrote anything.
      expect(PresetRecipes.recognize(_exercisesOf(course).first), isNotNull);
      final story = _roundOf(course, CanonicalRounds256.story);
      expect(PresetRecipes.recognize(story.exercises.first), 'story_cover');
      expect(PresetRecipes.recognize(story.exercises[1]), 'dialogue_line');
      expect(
        PresetRecipes.recognize(
          later.exercises.singleWhere(
            (exercise) => exercise.id == 'speak_repeat',
          ),
        ),
        isNull,
      );
    },
  );

  test('signing and checksums treat every primitive as data', () async {
    // The same content as a Publisher Course: the constructor derives the
    // publisher lineage an official Course must carry.
    final official = Course(
      courseId: 'external_v12_official',
      originType: CourseOriginType.externalOfficial,
      publisherId: 'publisher',
      publisherName: 'Publisher',
      officialCourseVersion: '1',
      officialReleaseDateUtc: '2026-09-29T00:00:00.000Z',
      officialChecksum: '0' * 64,
      distributionChannel: 'package',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'External converter course',
      ttsLanguage: 'it-IT',
      storyNarrator: course.storyNarrator,
      storyCharacters: course.storyCharacters,
      lessons: course.lessons,
    );
    final signed = await signFixture(official);
    final verified = await fixtureVerifier(
      'publisher',
      'Publisher',
    ).requireVerified(signed);
    expect(
      verified.publisherVerificationStatus,
      PublisherVerificationStatus.verified,
    );
    expect(verified.officialChecksum, CourseChecksums.official(official));
    _expectSameSemantics(verified, official);
  });

  group('merge', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: canonicalCourse256ProfileId,
            displayName: 'External converter',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: canonicalCourse256ProfileId,
      });
    });

    test('a merge carries the exercises of the chosen side', () async {
      final right = Course.fromJson({
        ...course.toJson(),
        'courseId': 'external_v12_other',
      });
      final merged =
          await CourseMergeService(
            clock: () => canonicalCourse256Stamp,
          ).createMergedCourse(
            left: course,
            right: right,
            choices: const [LessonMergeChoice.left],
            options: CourseMergeOptions.fromCourse(course),
          );
      final rounds = merged.lessons.single.rounds;
      expect(rounds.length, course.lessons.single.rounds.length);
      expect(
        _exercisesOf(merged).map((exercise) => exercise.primitive).toSet(),
        ExercisePrimitive.values.toSet(),
      );
      for (final exercise in _exercisesOf(merged)) {
        expect(exercise.authoringMetadata, isEmpty, reason: exercise.id);
      }
      expect(
        rounds.singleWhere((round) => round.title == 'Al bar').flow,
        isNotNull,
      );
    });
  });

  group('runtime and editor', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('External learner');
      _platforms();
      keepCrashLogUnavailable();
    });

    testWidgets('the Story plays without any preset metadata', (tester) async {
      await _pumpRound(
        tester,
        course,
        _roundOf(course, CanonicalRounds256.story),
      );
      await _until(tester, find.byKey(const Key('story-cover-continue')));
      expect(find.text('A morning in Turin'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('story-cover-continue')));
      await _until(tester, find.text('Anna walks into the café.'));
      await _tap(tester, find.byKey(const Key('story-line-continue')));
      await _until(tester, find.text('Buongiorno! Un caffè, per favore.'));
      expect(find.text('Anna'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('story-line-continue')));
      await _until(tester, find.text('What did Anna order?'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Un caffè'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      await _until(tester, find.text('The barista smiles.'));
      await _tap(tester, find.byKey(const Key('story-line-continue')));
      await _until(tester, find.text('Where is Anna?'));
      await _tap(tester, find.widgetWithText(FilledButton, 'In a café'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish story'));
      await _until(tester, find.text('Story completed'));
      expect(find.textContaining('Correct answers: 2/2'), findsOneWidget);
    });

    testWidgets('the Preview shows the unplayable exercises as cards', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        course,
        _roundOf(course, CanonicalRounds256.later),
        preview: true,
      );
      await _until(tester, find.byKey(const Key('not-executable-card')));
      expect(find.byKey(const Key('exercise-instruction')), findsNothing);
      await _tap(tester, find.byKey(const Key('not-executable-continue')));
      await tester.tap(find.widgetWithText(FilledButton, 'Continue').last);
      await tester.pumpAndSettle();
      await _until(tester, find.byKey(const Key('not-executable-card')));
    });

    testWidgets('the Generic Primitive Editor inspects a Speak exercise', (
      tester,
    ) async {
      final speak = _roundOf(
        course,
        CanonicalRounds256.later,
      ).exercises.singleWhere((exercise) => exercise.id == 'speak_repeat');
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: speak,
            title: 'Edit exercise',
            isNew: false,
            course: course,
            lesson: course.lessons.single,
            round: _roundOf(course, CanonicalRounds256.later),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primitive-editor')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('primitive-support-state')),
          matching: find.textContaining('cannot play'),
        ),
        findsOneWidget,
      );
    });
  });
}

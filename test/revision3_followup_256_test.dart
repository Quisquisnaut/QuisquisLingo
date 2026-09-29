import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/exercise_editor_intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 3 follow-up: the owner's ten points of 27 September
/// 2026 (scrolling Stories, discard prompts only for real changes, required
/// options for Assign and Submit, the two New exercise buttons, the Draft
/// Exercises message, the first-time introduction, the Help names).
Course _laboratory() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise _laboratoryExercise(Course course, String presetId) {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final content in round.content) {
        if (content.editorTemplate == presetId) return content.exercise!;
      }
    }
  }
  throw StateError(presetId);
}

/// The Laboratory as a custom Course (a licensed Fork: its content is
/// Draft), for the Round editor tests.
Course _customLaboratory() {
  final source = _laboratory();
  const profileId = '11111111-1111-4111-8111-111111111111';
  return AuthoringDuplicationService(
    clock: () => DateTime.utc(2026, 9, 27),
  ).forkOfficialCourse(
    source,
    provenance: CourseForkProvenance(
      sourceCourseId: source.courseId,
      sourceCourseTitle: source.title,
      sourceCourseVersion: source.officialCourseVersion,
      sourceOriginType: source.originType,
      sourcePublisherId: source.publisherId,
      sourcePublisherName: source.publisherName,
      sourceOfficialChecksum: source.officialChecksum,
      sourceAuthors: source.authors,
      forkCreatedByProfileId: profileId,
      forkCreatedByDisplayName: 'Follow-up tester',
      forkCreatedAtUtc: '2026-09-27T00:00:00.000Z',
    ),
    maintainer: const CourseMaintainer(profileId),
  );
}

Exercise _choice(String id, String question) => Exercise(
  id: id,
  type: 'choice',
  prompt: '',
  question: question,
  answers: ['Right $id', 'Wrong $id'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
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

/// Pumps a home page and pushes [page] above it, so a Back that pops the
/// page lands on the home page instead of emptying the Navigator.
Future<void> _open(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => page)),
              child: const Text('Open page'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open page'));
  await tester.pumpAndSettle();
}

void _bigWindow(WidgetTester tester, {double height = 2400}) {
  tester.view.physicalSize = Size(1200, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
  });

  group('flow presentation', () {
    final nodes = [
      for (final id in ['a', 'b'])
        FlowNode(id: id, kind: FlowNodeKind.exercise, contentId: id),
    ];

    test('scroll is stored, step is the omitted default', () {
      final scroll = ContentFlow.linear(
        nodes,
        presentation: FlowPresentation.scroll,
      );
      expect(scroll.toJson()['presentation'], 'scroll');
      expect(
        ContentFlow.linear(nodes).toJson().containsKey('presentation'),
        isFalse,
      );
      final parsed = ContentFlow.fromJson(scroll.toJson());
      expect(parsed.presentation, FlowPresentation.scroll);
      expect(
        ContentFlow.fromJson(ContentFlow.linear(nodes).toJson()).presentation,
        FlowPresentation.step,
      );
      expect(
        () => ContentFlow.fromJson({
          ...scroll.toJson(),
          'presentation': 'sideways',
        }),
        throwsFormatException,
      );
    });

    test('authoring keeps the presentation through rebuilds and copies', () {
      final content = [
        for (final id in ['a', 'b'])
          LearningContent.fromExercise(_choice(id, 'Q $id')),
      ];
      final scroll = RoundFlowAuthoring.linearFor(
        content,
        presentation: FlowPresentation.scroll,
      );
      expect(
        RoundFlowAuthoring.forContent(
          scroll,
          content.reversed.toList(),
        )!.presentation,
        FlowPresentation.scroll,
      );
      expect(
        RoundFlowAuthoring.remapped(scroll, {'a': 'x'})!.presentation,
        FlowPresentation.scroll,
      );
      expect(
        RoundFlowAuthoring.withPresentation(
          scroll,
          FlowPresentation.step,
        ).presentation,
        FlowPresentation.step,
      );
    });
  });

  group('required options', () {
    test('a blank Assign or Submit draft is legal from the start', () {
      for (final primitive in [
        ExercisePrimitive.assign,
        ExercisePrimitive.submit,
        ExercisePrimitive.speak,
        ExercisePrimitive.ink,
      ]) {
        final draft = CanonicalExerciseDraft.blank(primitive, id: 'ex');
        expect(draft.violations, isEmpty, reason: primitive.name);
      }
      expect(
        CanonicalExerciseDraft.requiredOptionDefaults(
          ExercisePrimitive.assign,
        ).keys,
        contains(OptionKey.targetMode),
      );
      final changed = CanonicalExerciseDraft.blank(
        ExercisePrimitive.select,
        id: 'ex',
      )..changePrimitive(ExercisePrimitive.submit);
      expect(changed.violations, isEmpty);
      expect(changed.options.keys, contains(OptionKey.submissionType));
    });
  });

  group('canonical editor', () {
    Exercise blank() => CanonicalExerciseDraft.blankExercise(
      ExercisePrimitive.select,
      id: 'ex_new',
      updatedAt: DateTime.utc(2026, 9, 27),
    );

    testWidgets('leaving without a change never asks', (tester) async {
      _bigWindow(tester);
      await _open(
        tester,
        PrimitiveEditorScreen(
          exercise: blank(),
          title: 'Canonical',
          isNew: true,
        ),
      );
      // Re-selecting the same evaluation mode touches a control only.
      await tester.tap(find.byKey(const Key('primitive-evaluation-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('exactItem').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
      expect(find.text('Open page'), findsOneWidget);
    });

    testWidgets('choosing Assign shows no registry refusal', (tester) async {
      _bigWindow(tester);
      await _open(
        tester,
        PrimitiveEditorScreen(
          exercise: blank(),
          title: 'Canonical',
          isNew: true,
        ),
      );
      await tester.tap(find.byKey(const Key('primitive-editor-primitive')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primitive-violations')), findsNothing);
      // Build 256 Revision 7: a blank Assign (groups in columns) plays.
      expect(find.text('Not playable in this version'), findsNothing);
      await tester.tap(find.byKey(const Key('primitive-editor-primitive')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primitive-violations')), findsNothing);
      expect(find.text('Not playable in this version'), findsOneWidget);
      // A new exercise still blank for its primitive: leaving does not ask.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
      expect(find.text('Open page'), findsOneWidget);
      // Content added: leaving asks.
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primitive-item-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
    });
  });

  group('preset form', () {
    testWidgets('Match the pairs: focusing a field does not ask to discard', (
      tester,
    ) async {
      _bigWindow(tester);
      final course = _laboratory();
      final exercise = _laboratoryExercise(course, 'word_match');
      Widget editor() => ExerciseEditorScreen(
        exercise: exercise,
        title: 'Edit',
        isNew: false,
        course: course,
        lesson: course.lessons.first,
        round: course.lessons.first.rounds.first,
      );
      await _open(tester, editor());
      final pairs = find.byKey(const ValueKey('exercise-field-pairs'));
      await tester.tap(pairs);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
      expect(find.text('Open page'), findsOneWidget);
      // A real change asks.
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-pairs')),
        'uno = one',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
    });
  });

  group('Round editor', () {
    testWidgets('the two New exercise buttons and the Draft message', (
      tester,
    ) async {
      _bigWindow(tester);
      final course = _customLaboratory();
      final lesson = course.lessons.first;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: lesson,
            round: lesson.rounds.first,
            roundIndex: 0,
            onCourseChanged: (_) {},
            clock: () => DateTime.utc(2026, 9, 27, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('New Exercise'), findsOneWidget);
      expect(find.text('New Canonical'), findsOneWidget);
      // The fork's Exercises are Draft: Save says so instead of counting
      // Audit errors.
      await tester.tap(find.byKey(const Key('round-save')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('round-draft-exercises-notice')),
        findsOneWidget,
      );
      expect(find.textContaining('still Draft'), findsOneWidget);
      expect(find.textContaining('blocking error'), findsNothing);
    });

    testWidgets('the Story switch offers Step by step or Scrolling', (
      tester,
    ) async {
      _bigWindow(tester);
      final course = _customLaboratory();
      final lesson = course.lessons.first;
      Course? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: lesson,
            round: lesson.rounds.first,
            roundIndex: 0,
            onCourseChanged: (value) => changed = value,
            clock: () => DateTime.utc(2026, 9, 27, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('round-story-presentation')), findsNothing);
      await tester.tap(find.byKey(const Key('round-story-switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('round-story-presentation')), findsOneWidget);
      await tester.tap(find.text('Scrolling'));
      await tester.pumpAndSettle();
      final flow = changed!.lessons.first.rounds.first.flow!;
      expect(flow.presentation, FlowPresentation.scroll);
      expect(flow.isLinear, isTrue);
      expect(find.textContaining('scrolling'), findsOneWidget);
    });
  });

  group('scrolling Story', () {
    setUp(_platforms);

    testWidgets('finished items stay on the page with the answer', (
      tester,
    ) async {
      _bigWindow(tester, height: 1800);
      final exercises = [
        _choice('e1', 'Question 1'),
        _choice('e2', 'Question 2'),
      ];
      final round = LearningRound(
        id: 'story',
        title: 'Story',
        visualType: LearningRound.storyVisualType,
        exercises: exercises,
        flow: ContentFlow.linear([
          for (final id in ['e1', 'e2'])
            FlowNode(id: id, kind: FlowNodeKind.exercise, contentId: id),
        ], presentation: FlowPresentation.scroll),
      );
      final course = Course(
        courseId: 'followup-story-course',
        title: 'Story course',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        ttsLanguage: 'it-IT',
        lessons: [
          Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.single,
            round: round,
            ttsLanguage: course.ttsLanguage,
            roundIndex: 0,
            previewMode: true,
            ttsCacheService: _Speech(),
          ),
        ),
      );
      await _until(tester, find.text('Question 1'));
      expect(find.byKey(const Key('story-scroll')), findsOneWidget);
      expect(find.text('Story · 2 steps'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Right e1'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      expect(find.byKey(const ValueKey('story-entry-0')), findsOneWidget);
      expect(find.text('Now · step 2 of 2'), findsOneWidget);
      expect(find.byKey(const Key('story-spacer')), findsOneWidget);
      expect(find.text('Right e1'), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Question 2'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Wrong e2'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish story'));
      await _until(tester, find.text('Preview complete'));
    });
  });

  group('first-time introduction', () {
    testWidgets('shown once per Course, then remembered', (tester) async {
      ExerciseEditorIntro.enabled = true;
      addTearDown(() => ExerciseEditorIntro.enabled = false);
      _bigWindow(tester);
      final course = _laboratory();
      final exercise = _laboratoryExercise(course, 'choice_target');
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: exercise,
              title: 'Edit',
              isNew: false,
              course: course,
              lesson: course.lessons.first,
              round: course.lessons.first.rounds.first,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await open();
      expect(find.byKey(const Key('exercise-editor-intro')), findsOneWidget);
      expect(find.text(ExerciseEditorIntro.title), findsOneWidget);
      await tester.tap(find.byKey(const Key('exercise-editor-intro-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-editor-intro')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await open();
      expect(find.byKey(const Key('exercise-editor-intro')), findsNothing);
    });
  });

  group('second follow-up (visual inspection)', () {
    testWidgets('choosing a type on an untouched new exercise never asks', (
      tester,
    ) async {
      _bigWindow(tester);
      final course = _laboratory();
      final blank = Exercise(
        id: 'ex_new_type',
        publicationState: PublicationState.draft,
        type: 'translation_choice_to_target',
        prompt: '',
        question: '',
        answers: const [],
        correct: null,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      );
      await _open(
        tester,
        ExerciseEditorScreen(
          exercise: blank,
          title: 'New exercise',
          isNew: true,
          course: course,
          lesson: course.lessons.first,
          round: course.lessons.first.rounds.first,
        ),
      );
      await tester.tap(find.byKey(const Key('exercise-preset-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type the translation (to target)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
      expect(find.text('Open page'), findsOneWidget);
    });

    testWidgets('the Round Wizard is greyed out while Use GuideBook is off', (
      tester,
    ) async {
      _bigWindow(tester);
      final json = _customLaboratory().toJson();
      json['useGuidebook'] = false;
      final course = Course.fromJson(json);
      expect(course.useGuidebook, isFalse);
      // The Round Wizard sits on the Rounds page (Revision 5, third
      // follow-up).
      await tester.pumpWidget(
        MaterialApp(
          home: LessonRoundsScreen(
            course: course,
            lesson: course.lessons.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final wizard = tester.widget<FilledButton>(
        find.byKey(const Key('rounds-round-wizard')),
      );
      expect(wizard.onPressed, isNull);
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('rounds-round-wizard')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, contains('Use GuideBook'));
    });
  });

  test('Select the image without icons says what is missing', () {
    final withoutIcons = Exercise(
      id: 'ex_icons',
      type: 'icon_choice',
      prompt: '',
      question: 'Which one is the cat?',
      answers: const ['gatto', 'cane'],
      correct: 0,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    final issues = CourseAuditService().auditExercise(withoutIcons);
    final mismatch = issues.where(
      (issue) => issue.code == 'PRESET_CANONICAL_MISMATCH',
    );
    expect(mismatch, hasLength(1));
    expect(mismatch.single.message, contains('Icons / image keys'));
  });

  test('Help names the wizards and the two buttons in every language', () {
    for (final catalog in [helpEn, helpIt, helpEs]) {
      // Build 256 Revision 8: Editor Help is questions and answers.
      expect(catalog['editorHelp.qa.roundWizard.q'], contains('Round Wizard'));
      expect(catalog['editorHelp.qa.roundWizard.a'], contains('Round Wizard'));
      expect(
        catalog['editorHelp.qa.exerciseWizard.q'],
        contains('Exercise Wizard'),
      );
      expect(catalog['editorHelp.qa.newExercise.a'], contains('New Canonical'));
      expect(
        catalog['exerciseHelp.supplement.canonicalEditor.body'],
        contains('New Exercise'),
      );
      expect(
        catalog['technical.exercisePrimitives.stories.body'],
        contains('Scrolling'),
      );
    }
  });
}

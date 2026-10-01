import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 7: the Assign runtime. Groups (categories), slots and
/// gaps play by tapping an item and then its destination; capacity and
/// reuse are honoured; exactAssignments grades every target; regions,
/// cells and drag placement stay readable but not executable; the Audit
/// asks for items, targets and an answer.
final _stamp = DateTime.utc(2026, 9, 28, 23, 30);

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

PromptElement _text(String text, {String role = 'primary'}) =>
    PromptElement(type: 'text', text: text, role: role);

ExerciseItem _item(String id, String text) =>
    ExerciseItem(id: id, content: [_text(text)]);

Exercise _assign(
  String id, {
  required AssignTargetMode mode,
  Map<OptionKey, OptionValue> options = const {},
  required List<ExerciseItem> items,
  required List<ExerciseTarget> targets,
  required List<LayoutElement> layout,
  required List<TargetAssignment> assignments,
  String question = 'Sort the words',
}) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.assign,
  options: PrimitiveOptions({
    OptionKey.targetMode: EnumOptionValue(mode),
    OptionKey.shuffleItems: const BoolOptionValue(false),
    ...options,
  }),
  promptElements: [_text(question, role: 'question')],
  items: items,
  targets: targets,
  layout: layout,
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactAssignments,
    assignments: assignments,
  ),
  updatedAt: _stamp,
);

/// Two groups, three words, one of them a distractor that belongs nowhere.
Exercise _groups({Map<OptionKey, OptionValue> options = const {}}) => _assign(
  'groups',
  mode: AssignTargetMode.categories,
  options: {
    OptionKey.targetCapacity: const EnumOptionValue(TargetCapacity.multiple),
    ...options,
  },
  items: [
    _item('gatto', 'gatto'),
    _item('cane', 'cane'),
    _item('mela', 'mela'),
  ],
  targets: const [
    ExerciseTarget(id: 'animals'),
    ExerciseTarget(id: 'food'),
  ],
  layout: const [
    LayoutElement.text('Animals:'),
    LayoutElement.target('animals'),
    LayoutElement.text('Food'),
    LayoutElement.target('food'),
  ],
  assignments: const [
    TargetAssignment(targetId: 'animals', itemIds: ['gatto', 'cane']),
    TargetAssignment(targetId: 'food', itemIds: ['mela']),
  ],
);

Exercise _slots({Map<OptionKey, OptionValue> options = const {}}) => _assign(
  'slots',
  mode: AssignTargetMode.slots,
  options: options,
  items: [_item('il', 'il'), _item('la', 'la')],
  targets: const [
    ExerciseTarget(id: 's1'),
    ExerciseTarget(id: 's2'),
  ],
  layout: const [
    LayoutElement.text('… gatto'),
    LayoutElement.target('s1'),
    LayoutElement.text('… casa'),
    LayoutElement.target('s2'),
  ],
  assignments: const [
    TargetAssignment(targetId: 's1', itemIds: ['il']),
    TargetAssignment(targetId: 's2', itemIds: ['la']),
  ],
  question: 'Which article?',
);

Exercise _gaps() => _assign(
  'gaps',
  mode: AssignTargetMode.gaps,
  options: {OptionKey.layout: const EnumOptionValue(LayoutValue.inline)},
  items: [_item('dorme', 'dorme'), _item('mangia', 'mangia')],
  targets: const [ExerciseTarget(id: 'g1')],
  layout: const [
    LayoutElement.text('Il gatto'),
    LayoutElement.target('g1'),
    LayoutElement.text('sul divano.'),
  ],
  assignments: const [
    TargetAssignment(targetId: 'g1', itemIds: ['dorme']),
  ],
  question: 'Fill the gap',
);

Course _course(Exercise exercise) => Course(
  courseId: 'assign-runtime-course',
  title: 'Assign course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          updatedAt: _stamp,
          content: [LearningContent.fromExercise(exercise)],
        ),
      ],
    ),
  ],
);

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

Future<void> _pump(WidgetTester tester, Exercise exercise) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final course = _course(exercise);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
        ttsCacheService: _Speech(),
      ),
    ),
  );
  await _until(tester, find.byKey(const Key('assign-check')));
}

Future<void> _place(WidgetTester tester, String item, String target) async {
  await _tap(tester, find.byKey(Key('assign-tile-$item')));
  await _tap(tester, find.byKey(Key('assign-target-$target')));
}

void main() {
  group('model', () {
    test(
      'groups, slots and gaps are executable; regions, cells and drag wait',
      () {
        expect(_groups().isExecutable, isTrue);
        expect(_slots().isExecutable, isTrue);
        expect(_gaps().isExecutable, isTrue);
        expect(
          _groups(
            options: {
              OptionKey.placementMode: const EnumOptionValue(
                PlacementMode.drag,
              ),
            },
          ).isExecutable,
          isFalse,
        );
        final regions = _assign(
          'regions',
          mode: AssignTargetMode.regions,
          options: {
            OptionKey.layout: const EnumOptionValue(LayoutValue.overlay),
          },
          items: [_item('a', 'a')],
          targets: const [ExerciseTarget(id: 'r1')],
          layout: const [LayoutElement.target('r1')],
          assignments: const [
            TargetAssignment(targetId: 'r1', itemIds: ['a']),
          ],
        );
        expect(regions.runtimeSupport.violations, isEmpty);
        expect(regions.isExecutable, isFalse);
        expect(
          ExercisePrimitive.executableToday,
          contains(ExercisePrimitive.assign),
        );
      },
    );

    test('the features name the kind, the labels and the answer', () {
      final groups = ExerciseFeatures(_groups());
      expect(groups.kind, LearnerExerciseKind.assignGroups);
      expect(groups.targetLabel('animals'), 'Animals');
      expect(groups.targetLabel('food'), 'Food');
      expect(groups.assignmentsByTarget, {
        'animals': {'gatto', 'cane'},
        'food': {'mela'},
      });
      expect(groups.targetCapacity, TargetCapacity.multiple);
      expect(groups.assignItemReuse, isFalse);
      expect(groups.shuffleItems, isFalse);
      expect(ExerciseFeatures(_slots()).kind, LearnerExerciseKind.assignSlots);
      final gaps = ExerciseFeatures(_gaps());
      expect(gaps.kind, LearnerExerciseKind.assignGaps);
      expect(gaps.targetLabel('g1'), 'Il gatto');
    });

    test('headings and instructions exist in every language', () {
      final course = _course(_groups());
      expect(
        ExerciseCopyService.typeLabel(course, LearnerExerciseKind.assignGroups),
        'SORT INTO GROUPS',
      );
      expect(
        ExerciseCopyService.instructionForExercise(course, _slots()),
        'Tap an item, then its slot.',
      );
      expect(
        ExerciseCopyService.instructionForExercise(course, _gaps()),
        'Tap a word, then the gap it fills.',
      );
      for (final language in [
        'Spanish',
        'Italian',
        'German',
        'Portuguese',
        'Dutch',
        // Build 260 Revision 0: Finnish and Welsh left, French joined.
        'French',
      ]) {
        final localized = Course.fromJson({
          ...course.toJson(),
          'interfaceLanguage': language,
        });
        for (final kind in [
          LearnerExerciseKind.assignGroups,
          LearnerExerciseKind.assignSlots,
          LearnerExerciseKind.assignGaps,
        ]) {
          expect(
            ExerciseCopyService.typeLabel(localized, kind),
            isNot(
              ExerciseCopyService.typeLabel(
                localized,
                LearnerExerciseKind.other,
              ),
            ),
            reason: '$language $kind',
          );
          expect(
            ExerciseCopyService.instruction(localized, kind),
            isNot(
              ExerciseCopyService.instruction(
                localized,
                LearnerExerciseKind.other,
              ),
            ),
            reason: '$language $kind',
          );
        }
      }
    });

    test(
      'the Audit accepts a labelled layout and asks for items, targets and an answer',
      () {
        final audit = CourseAuditService();
        for (final exercise in [_groups(), _slots(), _gaps()]) {
          final errors = audit
              .auditExercise(exercise)
              .where((issue) => issue.severity == AuditSeverity.error);
          expect(
            errors,
            isEmpty,
            reason:
                '${exercise.id}: ${errors.map((issue) => issue.code).join(',')}',
          );
          expect(
            audit
                .auditExercise(exercise)
                .where((issue) => issue.code == 'EXERCISE_NOT_EXECUTABLE'),
            isEmpty,
            reason: exercise.id,
          );
        }
        final noTargets = _assign(
          'empty',
          mode: AssignTargetMode.categories,
          items: [_item('a', 'a')],
          targets: const [],
          layout: const [],
          assignments: const [],
        );
        expect(
          audit.auditExercise(noTargets).map((issue) => issue.code),
          contains('ASSIGN_STRUCTURE_REQUIRED'),
        );
        final noAnswer = _assign(
          'unanswered',
          mode: AssignTargetMode.categories,
          items: [_item('a', 'a')],
          targets: const [ExerciseTarget(id: 't')],
          layout: const [LayoutElement.target('t')],
          assignments: const [TargetAssignment(targetId: 't', itemIds: [])],
        );
        expect(
          audit.auditExercise(noAnswer).map((issue) => issue.code),
          contains('ASSIGN_STRUCTURE_REQUIRED'),
        );
      },
    );
  });

  group('the Round screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Assign learner');
      _platforms();
      keepCrashLogUnavailable();
    });

    testWidgets('groups: tap an item, then its group; a distractor stays out', (
      tester,
    ) async {
      await _pump(tester, _groups());
      expect(find.text('SORT INTO GROUPS'), findsOneWidget);
      expect(
        find.text('Tap an item, then the group it belongs to.'),
        findsOneWidget,
      );
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('assign-check')))
            .onPressed,
        isNull,
      );
      await _place(tester, 'gatto', 'animals');
      // A placed item leaves the bank when reuse is forbidden.
      expect(find.byKey(const Key('assign-tile-gatto')), findsNothing);
      expect(
        find.byKey(const Key('assign-placed-animals-gatto')),
        findsOneWidget,
      );
      await _place(tester, 'cane', 'animals');
      await _place(tester, 'mela', 'food');
      await _tap(tester, find.byKey(const Key('assign-check')));
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a wrong sorting is marked and the answer is shown', (
      tester,
    ) async {
      await _pump(tester, _groups());
      await _place(tester, 'gatto', 'food');
      await _place(tester, 'mela', 'animals');
      await _tap(tester, find.byKey(const Key('assign-check')));
      expect(find.text('Incorrect'), findsOneWidget);
      expect(
        find.textContaining('Animals: gatto, cane · Food: mela'),
        findsOneWidget,
      );
    });

    testWidgets('a placed item can be taken back and placed elsewhere', (
      tester,
    ) async {
      await _pump(tester, _groups());
      await _place(tester, 'gatto', 'food');
      expect(find.byKey(const Key('assign-tile-gatto')), findsNothing);
      // The chip's delete returns the item to the bank.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('assign-placed-food-gatto')),
          matching: find.byTooltip('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assign-placed-food-gatto')), findsNothing);
      expect(find.byKey(const Key('assign-tile-gatto')), findsOneWidget);
      await _place(tester, 'gatto', 'animals');
      expect(
        find.byKey(const Key('assign-placed-animals-gatto')),
        findsOneWidget,
      );
      // Arming a tile and tapping it again disarms it.
      await _tap(tester, find.byKey(const Key('assign-tile-cane')));
      await _tap(tester, find.byKey(const Key('assign-tile-cane')));
      await _tap(tester, find.byKey(const Key('assign-target-food')));
      expect(find.byKey(const Key('assign-placed-food-cane')), findsNothing);
    });

    testWidgets('slots hold one item; a second placement replaces it', (
      tester,
    ) async {
      await _pump(tester, _slots());
      expect(find.text('FILL THE SLOTS'), findsOneWidget);
      await _place(tester, 'la', 's1');
      await _place(tester, 'il', 's1');
      expect(find.byKey(const Key('assign-placed-s1-il')), findsOneWidget);
      expect(find.byKey(const Key('assign-placed-s1-la')), findsNothing);
      expect(find.byKey(const Key('assign-tile-la')), findsOneWidget);
      await _place(tester, 'la', 's2');
      await _tap(tester, find.byKey(const Key('assign-check')));
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a reusable item stays in the bank', (tester) async {
      await _pump(
        tester,
        _slots(
          options: {
            OptionKey.itemReuse: const EnumOptionValue(ItemReuse.allowed),
          },
        ),
      );
      await _place(tester, 'il', 's1');
      expect(find.byKey(const Key('assign-tile-il')), findsOneWidget);
      await _place(tester, 'il', 's2');
      await _tap(tester, find.byKey(const Key('assign-check')));
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('gaps: the slot sits inside the text', (tester) async {
      await _pump(tester, _gaps());
      expect(find.text('FILL THE GAPS'), findsOneWidget);
      expect(find.text('Il gatto'), findsOneWidget);
      expect(find.text('sul divano.'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('assign-tile-dorme')));
      await _tap(tester, find.byKey(const Key('assign-slot-g1')));
      await _tap(tester, find.byKey(const Key('assign-check')));
      expect(find.text('Correct'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
      await _until(tester, find.text('Preview complete'));
    });
  });
}

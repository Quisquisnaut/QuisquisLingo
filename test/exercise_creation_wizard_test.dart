import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Round editor keeps New exercise beside Creation Wizard', (
    tester,
  ) async {
    final fixture = _fixture();
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: fixture.course,
          lesson: fixture.lesson,
          round: fixture.round,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-exercise')), findsOneWidget);
    expect(find.byKey(const Key('exercise-creation-wizard')), findsOneWidget);
  });

  testWidgets(
    'Wizard plan creates nothing and Save, Preview and Next stay deterministic',
    (tester) async {
      final results = <List<Exercise>?>[];
      final fixture = _fixture();
      await _openWizard(tester, fixture, results);
      await _configureTypeTranslation(tester, count: 2);

      expect(find.byKey(const Key('wizard-plan')), findsOneWidget);
      expect(find.text('2 planned Exercises'), findsOneWidget);
      expect(
        find.text('No Exercise objects have been created yet.'),
        findsOneWidget,
      );
      expect(results, isEmpty);

      await tester.tap(find.byKey(const Key('wizard-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Exercise 1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wizard-next')));
      await tester.pump();
      expect(
        find.text('Edit and validate this Exercise before saving it.'),
        findsOneWidget,
      );
      expect(find.text('Exercise 1 of 2'), findsOneWidget);

      await _editTranslation(tester, source: 'Coffee', answer: 'Caffè');

      await tester.tap(find.byKey(const Key('wizard-save')));
      await tester.pump();
      expect(find.text('Exercise 1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wizard-preview')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(RoundScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Exercise 1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wizard-next')));
      await tester.pumpAndSettle();
      expect(find.text('Exercise 2 of 2'), findsOneWidget);
      expect(find.byKey(const Key('wizard-finish')), findsOneWidget);

      await tester.tap(find.byKey(const Key('wizard-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Leave Creation Wizard?'), findsOneWidget);
      await tester.tap(find.text('Leave and keep saved'));
      await tester.pumpAndSettle();

      expect(results, hasLength(1));
      expect(results.single, hasLength(1));
      expect(results.single!.single.id, isNotEmpty);
      expect(results.single!.single.type, 'type_translation');
    },
  );

  testWidgets('Wizard Finish returns valid Exercises in planned order', (
    tester,
  ) async {
    final results = <List<Exercise>?>[];
    final fixture = _fixture();
    await _openWizard(tester, fixture, results);
    await _configureTypeTranslation(tester, count: 1);
    await tester.tap(find.byKey(const Key('wizard-confirm')));
    await tester.pumpAndSettle();
    await _editTranslation(tester, source: 'House', answer: 'Casa');
    await tester.tap(find.byKey(const Key('wizard-finish')));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single, hasLength(1));
    expect(results.single!.single.type, 'type_translation');
    expect(results.single!.single.prompt, 'House');
    expect(results.single!.single.accepted, ['Casa']);
  });
}

Future<void> _configureTypeTranslation(
  WidgetTester tester, {
  required int count,
}) async {
  await tester.enterText(find.byKey(const Key('wizard-count')), '$count');
  await tester.tap(find.byKey(const Key('wizard-criterion')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Selected exercise types').last);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilterChip, 'Type the translation'));
  await tester.pump();
  await tester.drag(
    find.byKey(const Key('wizard-setup')),
    const Offset(0, -1400),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('wizard-continue')), findsOneWidget);
  await tester.tap(find.byKey(const Key('wizard-continue')));
  await tester.pumpAndSettle();
}

Future<void> _editTranslation(
  WidgetTester tester, {
  required String source,
  required String answer,
}) async {
  await tester.tap(find.byKey(const Key('wizard-edit')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('type-translation-answer-help')), findsOneWidget);
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), source);
  await tester.enterText(fields.at(1), answer);
  final saveDraft = find.byKey(const Key('exercise-save-draft'));
  await tester.scrollUntilVisible(
    saveDraft,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(saveDraft);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('wizard-guided')), findsOneWidget);
}

Future<void> _openWizard(
  WidgetTester tester,
  _Fixture fixture,
  List<List<Exercise>?> results,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<List<Exercise>>(
                  MaterialPageRoute(
                    builder: (_) => ExerciseCreationWizardScreen(
                      course: fixture.course,
                      lesson: fixture.lesson,
                      round: fixture.round,
                      roundIndex: 0,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open Wizard'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Wizard'));
  await tester.pumpAndSettle();
}

class _Fixture {
  const _Fixture(this.course, this.lesson, this.round);
  final Course course;
  final Lesson lesson;
  final LearningRound round;
}

_Fixture _fixture() {
  final round = LearningRound(id: 'round', title: 'Round', exercises: const []);
  final lesson = Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]);
  final course = Course(
    courseId: 'course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
  return _Fixture(course, lesson, round);
}

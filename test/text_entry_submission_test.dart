import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPathProviderMock();
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile('Text Entry Learner');
  });

  for (final type in [
    'fill_blank',
    'listening_spelling',
    'missing_word',
    'type_translation',
  ]) {
    testWidgets('$type ignores empty Enter and enables one submit path', (
      tester,
    ) async {
      await _openTextRound(tester, type);
      final check = find.widgetWithText(FilledButton, 'Check');
      expect(tester.widget<FilledButton>(check).onPressed, isNull);

      await tester.showKeyboard(find.byType(TextField).last);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
      expect(find.byType(RoundScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'correct');
      await tester.pump();
      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('$type submits non-empty input through Check', (tester) async {
      await _openTextRound(tester, type);
      await tester.enterText(find.byType(TextField).last, 'correct');
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });
  }

  testWidgets('wrong text remains usable and refocuses for review', (
    tester,
  ) async {
    await _openTextRound(tester, 'fill_blank');
    await tester.enterText(find.byType(TextField).last, 'wrong');
    await tester.pump();
    final check = find.widgetWithText(FilledButton, 'Check');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(find.text('Incorrect'), findsOneWidget);

    await tester.tap(find.text('Review mistakes'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets(
    'Type the translation accepts variants and shows closest correction',
    (tester) async {
      await _openTextRound(
        tester,
        'type_translation',
        accepted: const [
          'Io prendo un cappuccino',
          '{Io} [vorrei|desidero] un cappuccino',
        ],
      );
      expect(find.text('Translate from English into Italian:'), findsOneWidget);
      expect(find.text('Translate this source text.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).last,
        'vorrei un cappuccino',
      );
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);

      await tester.tap(find.text('Finish round'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('wrong translation displays the nearest valid answer', (
    tester,
  ) async {
    await _openTextRound(
      tester,
      'type_translation',
      accepted: const ['Io prendo un cappuccino', 'Io vorrei un cappuccino'],
    );
    await tester.enterText(find.byType(TextField).last, 'Io vorrei un tè');
    await tester.pump();
    final check = find.widgetWithText(FilledButton, 'Check');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(
      find.text('Correct answer: Io vorrei un cappuccino'),
      findsOneWidget,
    );
  });
}

Future<void> _openTextRound(
  WidgetTester tester,
  String type, {
  List<String>? accepted,
}) async {
  final exercise = _textExercise(type, accepted: accepted);
  final round = LearningRound(
    id: '${type}_round',
    title: 'Text Entry Round',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: '${type}_lesson',
    title: 'Text Entry Lesson',
    guidebook: Guidebook.empty(),
    rounds: [round],
  );
  final course = Course(
    courseId: 'text_entry_course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Text Entry Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    lessons: [lesson],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
      ),
    ),
  );
  for (var frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(TextField).evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for the $type text field.');
}

Exercise _textExercise(String type, {List<String>? accepted}) => Exercise(
  id: '${type}_exercise',
  type: type,
  prompt: type == 'missing_word'
      ? 'The correct answer.'
      : type == 'type_translation'
      ? 'Translate this source text.'
      : '',
  question: 'Type the answer.',
  answers: const [],
  correct: null,
  tts: type == 'listening_spelling' || type == 'missing_word'
      ? 'correct'
      : null,
  accepted: type == 'missing_word' ? const [] : accepted ?? const ['correct'],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
  missingWords: type == 'missing_word' ? const ['correct'] : const [],
);

void _installPathProviderMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => throw PlatformException(
          code: 'test_storage_unavailable',
          message: 'Persistent logging is unavailable in widget tests.',
        ),
      );
}

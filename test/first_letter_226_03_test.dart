import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/first_letter_answer_service.dart';

Exercise exercise({
  List<String> answers = const ['cappuccino', 'coffee'],
  String sentence = 'I would like a ___.',
}) => Exercise(
  id: 'word-identity',
  type: 'type_missing_word',
  prompt: sentence,
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: answers,
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => throw PlatformException(code: 'unavailable'),
        );
  });
  test(
    'complete word stays intact and authoritative typo tolerance survives',
    () {
      expect(
        FirstLetterAnswerService.display('I would like a ___.', [
          'cappuccino',
          'coffee',
        ]),
        'I would like a c______.',
      );
      expect(
        FirstLetterAnswerService.response(' cappuccino ', ['cappuccino']),
        'cappuccino',
      );
      expect(
        const AnswerEngine().accepts(
          FirstLetterAnswerService.response('capuccino', ['cappuccino']),
          ['cappuccino'],
        ),
        isTrue,
      );
      expect(
        const AnswerEngine().accepts(
          FirstLetterAnswerService.response('appuccino', ['cappuccino']),
          ['cappuccino'],
        ),
        isFalse,
      );
    },
  );
  test(
    'combined Unicode first grapheme stays whole, including a one-grapheme word',
    () {
      for (final word in ['e\u0301cole', '👩🏽‍💻code', '가나다']) {
        final initial = FirstLetterAnswerService.initial([word]);
        expect(
          initial,
          word == 'e\u0301cole'
              ? 'e\u0301'
              : word == '가나다'
              ? '가'
              : '👩🏽‍💻',
        );
      }
      expect(FirstLetterAnswerService.response('', ['a']), '');
      for (final word in ['e\u0301cole', '👩🏽‍💻code', '가나다', 'a']) {
        expect(FirstLetterAnswerService.response(word, [word]), word);
        expect(const AnswerEngine().accepts(word, [word]), isTrue);
      }
    },
  );
  test(
    'incompatible initials, zero answers, phrases and ambiguous gaps reject',
    () {
      for (final answers in [
        <String>[],
        ['coffee', 'tea'],
        ['Coffee', 'coffee'],
        ['two words'],
      ]) {
        expect(
          () => FirstLetterAnswerService.initial(answers),
          throwsA(isA<AnswerExpressionException>()),
        );
      }
      for (final sentence in ['No gap', '___ and ___']) {
        expect(
          () => FirstLetterAnswerService.display(sentence, ['coffee']),
          throwsA(isA<AnswerExpressionException>()),
        );
      }
    },
  );
  test(
    'Input preset roundtrip and Audit preserve complete words and reject malformed state',
    () {
      final valid = exercise();
      final reloaded = Exercise.fromV2Json(
        jsonDecode(jsonEncode(valid.toJson())),
        contentId: valid.id,
        editorTemplate: valid.editorTemplate,
        publicationState: valid.publicationState,
      );
      expect(reloaded.toJson(), valid.toJson());
      expect(reloaded.interaction.kind, 'input');
      expect(reloaded.accepted, ['cappuccino', 'coffee']);
      expect(
        CourseAuditService()
            .auditExercise(reloaded)
            .where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
      );
      expect(
        CourseAuditService()
            .auditExercise(exercise(answers: ['coffee', 'tea']))
            .any((issue) => issue.severity == AuditSeverity.error),
        isTrue,
      );
      expect(exercise().missingWords, isEmpty);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'first letter learner and no-write Preview at 320px dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final ex = exercise();
        final round = LearningRound(id: 'round', title: '', exercises: [ex]);
        final lesson = Lesson(
          lessonId: 'lesson',
          title: 'Words',
          rounds: [round],
        );
        final course = Course(
          courseId: 'course',
          learningLanguage: 'Italian',
          interfaceLanguage: 'English',
          sourceLanguage: 'English',
          targetLanguage: 'Italian',
          title: 'Words',
          ttsLanguage: 'it-IT',
          version: '1',
          lessons: [lesson],
        );
        final before = jsonEncode(course.toJson());
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: RoundScreen(
              course: course,
              lesson: lesson,
              round: round,
              ttsLanguage: 'it-IT',
              roundIndex: 0,
              previewMode: true,
            ),
          ),
        );
        for (
          var i = 0;
          i < 100 &&
              find.byKey(const Key('first-letter-sentence')).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('I would like a c______.'), findsOneWidget);
        expect(find.text('I would like a ___.'), findsNothing);
        expect(
          find.text(
            'Enter the complete missing word. The first letter shown is a hint.',
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.byType(TextField),
          dark ? 'capuccino' : 'cappuccino',
        );
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'))
              .onPressed,
          isNotNull,
        );
        await tester.ensureVisible(find.text('Check'));
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();
        expect(find.text('Correct'), findsOneWidget);
        expect(find.text('Correct answer: cappuccino'), findsOneWidget);
        expect(find.text('I would like a cappuccino.'), findsOneWidget);
        expect(find.text('I would like a c______.'), findsNothing);
        expect(jsonEncode(course.toJson()), before);
        expect(prefs.getKeys(), keys);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final entry in [
    ('école', 'école', true),
    ('école', 'cole', false),
    ('e\u0301cole', 'e\u0301cole', true),
  ]) {
    testWidgets(
      'complete-word Preview ${entry.$1} response ${entry.$2} is ${entry.$3}',
      (tester) async {
        final ex = exercise(answers: [entry.$1], sentence: 'Une ___.');
        final before = jsonEncode(ex.toJson());
        await _showWordPreview(tester, ex);
        await tester.enterText(find.byType(TextField), entry.$2);
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'))
              .onPressed,
          isNotNull,
        );
        await tester.ensureVisible(find.text('Check'));
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();
        expect(find.text('Correct'), entry.$3 ? findsOneWidget : findsNothing);
        expect(find.text('Correct answer: ${entry.$1}'), findsOneWidget);
        expect(find.text('Une ${entry.$1}.'), findsOneWidget);
        expect(jsonEncode(ex.toJson()), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'one-letter answer requires nonblank input despite its visible hint',
    (tester) async {
      await _showWordPreview(
        tester,
        exercise(answers: ['a'], sentence: 'Choose ___.'),
      );
      final check = find.widgetWithText(FilledButton, 'Check');
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      expect(find.text('Correct'), findsNothing);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Choose a.'), findsOneWidget);
    },
  );
  for (final draft in [true, false]) {
    testWidgets(
      'real Editor preserves full answer on ${draft ? 'Draft' : 'Published'} Save',
      (tester) async {
        Exercise? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: exercise(answers: ['cappuccino']),
              title: 'Word',
              isNew: false,
              onExerciseSaved: (value) => saved = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Complete accepted words',
        );
        await tester.enterText(field, 'cappuccino\ncoffee');
        final save = find.byKey(
          Key(draft ? 'exercise-save-draft' : 'exercise-save'),
        );
        await tester.scrollUntilVisible(
          save,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        if (find.text('Save Exercise as draft?').evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(TextButton, 'Save as draft'));
          await tester.pumpAndSettle();
        }
        if (find.text('Use anyway').evaluate().isNotEmpty) {
          await tester.tap(find.text('Use anyway'));
          await tester.pumpAndSettle();
        }
        expect(saved, isNotNull);
        expect(saved!.accepted, ['cappuccino', 'coffee']);
        expect(saved!.id, 'word-identity');
        expect(
          saved!.publicationState,
          draft ? PublicationState.draft : PublicationState.published,
        );
      },
    );
  }
}

Future<void> _showWordPreview(WidgetTester tester, Exercise ex) async {
  final round = LearningRound(id: 'round', title: '', exercises: [ex]);
  final lesson = Lesson(lessonId: 'lesson', title: 'Words', rounds: [round]);
  final course = Course(
    courseId: 'course',
    learningLanguage: 'French',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'French',
    title: 'Words',
    ttsLanguage: 'fr-FR',
    version: '1',
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
        previewMode: true,
      ),
    ),
  );
  for (
    var i = 0;
    i < 100 &&
        find.byKey(const Key('first-letter-sentence')).evaluate().isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byKey(const Key('first-letter-sentence')), findsOneWidget);
}

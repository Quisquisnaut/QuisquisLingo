import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/screens/editor_help_content.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 256 Revision 8 (owner decisions, 29 September 2026): Editor Help
/// as questions and answers in seven topics, tap to open, with a search
/// that ignores capitals and accents; English, Italian and Spanish
/// complete; the Technical reference card first.
/// A tall window, so the topics below the Technical reference card are built.
void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Help Reader');
  });

  test('every topic and question has its text in the three languages', () {
    expect(editorHelpQuestionsByTopic.keys, [
      'gettingStarted',
      'savingAndVersions',
      'courseSettings',
      'lessonsAndRounds',
      'exercises',
      'picturesAndSound',
      'checkingTheCourse',
    ]);
    final ids = [for (final list in editorHelpQuestionsByTopic.values) ...list];
    // Build 257: How do I write the Before you start note of a Round?
    expect(ids, hasLength(67));
    expect(ids.toSet(), hasLength(ids.length));
    for (final catalog in [helpEn, helpIt, helpEs]) {
      for (final topic in editorHelpQuestionsByTopic.keys) {
        expect(catalog['editorHelp.qa.$topic.title'], isNotEmpty);
      }
      for (final id in ids) {
        final question = catalog['editorHelp.qa.$id.q'];
        expect(question, isNotEmpty, reason: id);
        expect(question!.trim(), endsWith('?'), reason: id);
        expect(catalog['editorHelp.qa.$id.a'], isNotEmpty, reason: id);
      }
      // The retired Editor-only sections are gone; the ones Course Studio
      // Help shares stay.
      expect(catalog.containsKey('editorHelp.audioLibrary.body'), isFalse);
      expect(catalog.containsKey('editorHelp.courseAudit.body'), isTrue);
    }
    for (final language in HelpLanguage.values) {
      for (final topic in editorHelpTopics(language)) {
        for (final question in topic.questions) {
          expect(
            question.answer,
            isNot(contains('{folder')),
            reason: question.id,
          );
        }
      }
    }
  });

  testWidgets('a question opens its answer', (tester) async {
    _bigWindow(tester);
    await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Technical reference'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editor-help-topic-gettingStarted')),
      findsOneWidget,
    );
    final answer = find.byKey(const ValueKey('editor-help-answer-accessModes'));
    expect(answer, findsNothing);
    await tester.tap(
      find.text('What do Locked, View only, Inspection mode and Edit do?'),
    );
    await tester.pumpAndSettle();
    expect(answer, findsOneWidget);
    expect(
      tester.widget<Text>(answer).data,
      contains('View only, the default'),
    );
  });

  testWidgets('the search filters questions and answers', (tester) async {
    _bigWindow(tester);
    await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('editor-help-search'));
    await tester.enterText(search, 'optional SEQUENCE title');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-help-question-sequence')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('editor-help-question-accessModes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('editor-help-topic-gettingStarted')),
      findsNothing,
    );
    // Matched in the answer, not only in the question.
    await tester.enterText(search, 'ARRANGE_ANSWER_CASE_DIFFERS');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-help-question-capitals')),
      findsOneWidget,
    );
    await tester.enterText(search, 'zzzz nothing here');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editor-help-no-results')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-help-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editor-help-no-results')), findsNothing);
    expect(
      find.byKey(const ValueKey('editor-help-question-accessModes')),
      findsOneWidget,
    );
  });

  testWidgets('the search ignores accents in Italian', (tester) async {
    _bigWindow(tester);
    await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor-help-language-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();
    expect(find.text('Riferimento tecnico'), findsOneWidget);
    // "perché" typed without its accent still finds the questions using it.
    final italianWithAccent = [
      for (final topic in editorHelpTopics(HelpLanguage.italian))
        for (final question in topic.questions)
          if (question.question.contains('perché') ||
              question.answer.contains('perché'))
            question.id,
    ];
    expect(italianWithAccent, isNotEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('editor-help-search')),
      'perche',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('editor-help-question-${italianWithAccent.first}')),
      findsOneWidget,
    );
  });
}

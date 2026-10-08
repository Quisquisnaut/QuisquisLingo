import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';

void main() {
  test('Insights are optional v6 data with ordered round-trip persistence', () {
    final legacy = Guidebook.fromJson({'content': <Object>[]});
    expect(legacy.insights, isEmpty);
    expect(legacy.toJson().containsKey('insights'), isFalse);

    const sections = [
      GuidebookInsight(title: 'First', text: 'First text'),
      GuidebookInsight(title: 'Second', text: 'Second text'),
    ];
    final encoded = Guidebook(content: const [], insights: sections).toJson();
    final decoded = Guidebook.fromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );
    expect(decoded.insights.map((section) => section.title), [
      'First',
      'Second',
    ]);
    expect(decoded.insights.map((section) => section.text), [
      'First text',
      'Second text',
    ]);

    final lesson = Lesson(
      lessonId: 'insight-lesson',
      title: 'Insight Lesson',
      rounds: const [],
      guidebook: decoded,
    );
    expect(
      AuthoringDuplicationService()
          .duplicateLesson(lesson)
          .guidebook
          .insights
          .map((section) => section.title),
      ['First', 'Second'],
    );
    expect(
      const PublicationService()
          .learnerGuidebook(decoded)
          .insights
          .map((section) => section.title),
      ['First', 'Second'],
    );
    expect(
      const PublicationService()
          .learnerGuidebook(
            Guidebook(
              publicationState: PublicationState.draft,
              content: const [],
              insights: sections,
            ),
          )
          .insights,
      isEmpty,
    );
    expect(
      () => Guidebook.fromJson({
        'content': <Object>[],
        'insights': [
          {'title': '', 'text': 'Missing title'},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => Guidebook.fromJson({
        'content': <Object>[],
        'insights': [
          {'title': 'Missing text'},
        ],
      }),
      throwsFormatException,
    );
  });

  testWidgets(
    'Guidebook fields and Insights edit, reorder, remove, Draft-save and reload',
    (tester) async {
      Guidebook? saved;
      final guidebook = Guidebook(
        overview: 'Overview text',
        goals: const ['Preserved legacy goal'],
        vocabulary: const ['casa = house'],
        grammar: const ['Grammar text'],
        expressions: const ['Come stai?'],
        examples: const ['Sto bene.'],
        insights: const [
          GuidebookInsight(title: 'First', text: 'First text'),
          GuidebookInsight(title: 'Second', text: 'Second text'),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  saved = await Navigator.of(context).push<Guidebook>(
                    MaterialPageRoute(
                      builder: (_) => GuidebookEditorScreen(
                        guidebook: saved ?? guidebook,
                        guidebookId: 'guidebook-stable-id',
                      ),
                    ),
                  );
                },
                child: const Text('Open Guidebook'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Guidebook'));
      await tester.pumpAndSettle();

      final fieldLabels = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.decoration?.labelText)
          .whereType<String>()
          .toList();
      expect(fieldLabels, ['Overview', 'Usage examples', 'Vocabulary']);
      expect(find.text('Goals'), findsNothing);
      expect(find.text('Useful expressions'), findsNothing);
      expect(find.text('Examples'), findsNothing);
      expect(
        tester.getRect(find.text('Overview')).top,
        lessThan(tester.getRect(find.text('Usage examples')).top),
      );
      expect(
        tester.getRect(find.text('Usage examples')).top,
        lessThan(tester.getRect(find.text('Vocabulary')).top),
      );
      final grammarField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Grammar',
      );
      await tester.scrollUntilVisible(
        grammarField,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(grammarField, findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('guidebook-insights-link')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('guidebook-insights-link')));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookInsightsEditorScreen), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);

      await tester.tap(find.byKey(const Key('guidebook-add-insight')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('guidebook-insight-title')),
        'Third',
      );
      await tester.enterText(
        find.byKey(const Key('guidebook-insight-text')),
        'Third text',
      );
      await tester.tap(find.byKey(const Key('guidebook-insight-confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('guidebook-insight-title')),
        'Second edited',
      );
      await tester.enterText(
        find.byKey(const Key('guidebook-insight-text')),
        'Second edited text',
      );
      await tester.tap(find.byKey(const Key('guidebook-insight-confirm')));
      await tester.pumpAndSettle();

      final drag = await tester.startGesture(
        tester.getCenter(find.text('Third')),
      );
      await tester.pump(const Duration(seconds: 1));
      await drag.moveBy(const Offset(0, -220));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Third')).top,
        lessThan(tester.getRect(find.text('Second edited')).top),
      );

      final firstCard = find.ancestor(
        of: find.text('First'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(of: firstCard, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove Insight section?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('guidebook-insight-remove-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookEditorScreen), findsOneWidget);
      expect(find.text('2 sections'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('guidebook-save-draft')));
      await tester.tap(find.byKey(const Key('guidebook-save-draft')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.publicationState, PublicationState.draft);
      expect(saved!.insights.map((section) => section.title), [
        'Third',
        'Second edited',
      ]);
      expect(saved!.goals, ['Preserved legacy goal']);
      expect(saved!.expressions, ['Come stai?']);
      final reopened = Guidebook.fromJson(
        jsonDecode(jsonEncode(saved!.toJson())) as Map<String, dynamic>,
      );
      expect(reopened.insights.map((section) => section.title), [
        'Third',
        'Second edited',
      ]);
      expect(reopened.insights.last.text, 'Second edited text');

      await tester.tap(find.text('Open Guidebook'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('guidebook-insights-link')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 sections'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('guidebook-save')));
      await tester.tap(find.byKey(const Key('guidebook-save')));
      await tester.pumpAndSettle();
      expect(saved!.publicationState, PublicationState.published);
      expect(saved!.insights.map((section) => section.title), [
        'Third',
        'Second edited',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

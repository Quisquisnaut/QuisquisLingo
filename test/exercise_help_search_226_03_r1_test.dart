import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';

void main() {
  test('search field inventory resolves current fields for every preset', () {
    for (final preset in ExercisePresetRegistry.presets) {
      final fields = ExerciseFieldHelpRegistry.editorFieldKeys(preset.id);
      expect(fields, isNotEmpty, reason: preset.id);
      for (final field in fields) {
        expect(
          ExerciseFieldHelpRegistry.forEditorField(preset.id, field).text,
          isNotEmpty,
          reason: '${preset.id}/$field',
        );
      }
    }
  });

  for (final example in [
    ('exercise name', 'Recognize characters', 'script_recognition'),
    (
      'field name',
      'Character image options',
      'script_recognition-scriptImageOptions',
    ),
    ('description', 'Learner chooses the image corresponding', 'icon_choice'),
    (
      'example',
      'Choose the character pronounced ga.',
      'script_recognition-scriptPrompt',
    ),
    ('case insensitive', 'rEcOgNiZe ChArAcTeRs', 'script_recognition'),
    ('new missing word preset', 'Type the missing word', 'type_missing_word'),
  ]) {
    testWidgets('Exercise Help filters immediately by ${example.$1}', (
      tester,
    ) async {
      await _mount(tester);
      await tester.enterText(_search, example.$2);
      await tester.pump();
      expect(
        find.byKey(ValueKey('exercise-help-result-${example.$3}')),
        findsOneWidget,
      );
      expect(
        find.text('No Exercise Help results match your search.'),
        findsNothing,
      );
      expect(find.text('Search Exercise Help'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'no results are clear and clearing restores the prior scroll position',
    (tester) async {
      await _mount(tester);
      final scroll = tester
          .widget<ListView>(find.byKey(const Key('exercise-help-list')))
          .controller!;
      scroll.jumpTo(450);
      await tester.pump();
      final previous = scroll.offset;
      await tester.enterText(_search, 'no-such-exercise-884027');
      await tester.pump();
      expect(
        find.text('No Exercise Help results match your search.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('exercise-help-list')), findsNothing);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
      expect(
        find.text('No Exercise Help results match your search.'),
        findsNothing,
      );
      expect(scroll.offset, previous);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard submit focuses results and supports scrolling and clear',
    (tester) async {
      await _mount(tester);
      await tester.tap(_search);
      await tester.enterText(_search, 'answer');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      final scroll = tester
          .widget<ListView>(find.byKey(const Key('exercise-help-list')))
          .controller!;
      expect(scroll.offset, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(scroll.offset, 0);
      await tester.tap(_search);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tester.widget<TextField>(_search).controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Exercise Help search fits 320px in $brightness and navigation is reversible',
      (tester) async {
        await _mount(tester, width: 320, brightness: brightness);
        final searchBounds = tester.getRect(_search);
        expect(searchBounds.left, greaterThanOrEqualTo(0));
        expect(searchBounds.right, lessThanOrEqualTo(320));
        await tester.enterText(_search, 'character');
        await tester.pump();
        final list = find.byKey(const Key('exercise-help-list'));
        await tester.drag(list, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(_search.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Open Exercise Help'), findsOneWidget);
        expect(find.byType(ExerciseHelpScreen), findsNothing);
      },
    );
  }
}

Finder get _search => find.byKey(const ValueKey('exercise-help-search'));

Future<void> _mount(
  WidgetTester tester, {
  double width = 900,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 850);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const ExerciseHelpScreen()),
              ),
              child: const Text('Open Exercise Help'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Exercise Help'));
  await tester.pumpAndSettle();
}

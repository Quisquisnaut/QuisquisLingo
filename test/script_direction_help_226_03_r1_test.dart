import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';

const _description =
    'Each item pairs a character image with its corresponding text.\n\n'
    'Image to text: learners see a character image and choose the matching text.\n\n'
    'Text to image: learners see the text and choose the matching character image.\n\n'
    'The text can be the character’s name, sound, pronunciation, transliteration or another identifying label.';

void main() {
  test(
    'Exercise Help explains image and corresponding text roles explicitly',
    () {
      final help = ExercisePresetRegistry.helpByPreset['script_recognition']!;
      for (final paragraph in _description.split('\n\n')) {
        expect(help, contains(paragraph));
      }
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'direction explanation changes immediately at 320px in $brightness',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final original = Exercise.v2(
          id: 'character-draft',
          editorTemplate: 'script_recognition',
          updatedAt: DateTime.utc(2026, 9, 8),
          publicationState: PublicationState.draft,
          promptElements: const [],
          interaction: const ExerciseInteraction(
            kind: 'select',
            items: [
              ExerciseItem(
                id: 'reading-a',
                content: [PromptElement(type: 'text', text: 'ga')],
              ),
              ExerciseItem(
                id: 'reading-b',
                content: [PromptElement(type: 'text', text: 'na')],
              ),
            ],
          ),
          evaluation: const ExerciseEvaluation(
            kind: 'selected_items',
            correctItemIds: ['reading-a'],
          ),
        );
        final controller = ScriptRecognitionController(original);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ScriptRecognitionEditor(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(_description), findsOneWidget);
        expect(
          find.text('Learners see an image and choose the matching text.'),
          findsOneWidget,
        );
        final selector = find.byKey(const ValueKey('script-mode'));
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Text to image').last);
        await tester.pump();
        expect(controller.mode, ScriptRecognitionMode.textToImage);
        expect(
          find.text('Learners see text and choose the matching image.'),
          findsOneWidget,
        );
        expect(
          find.text('Learners see an image and choose the matching text.'),
          findsNothing,
        );
        await tester.pumpAndSettle();
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Image to text').last);
        await tester.pumpAndSettle();
        expect(controller.optionId(0), 'reading-a');
        expect(controller.optionText(0).text, 'ga');
        expect(controller.isCorrect(0), isTrue);
        expect(
          controller.build(PublicationState.draft).toJson(),
          original.toJson(),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

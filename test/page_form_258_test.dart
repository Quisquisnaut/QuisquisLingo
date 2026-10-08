import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/widgets/page_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 258 Revision 2: the Page preset and its form (owner decisions of 29
/// September 2026, `docs/258_PAGE_CARD_PLAN.md`): blocks added, moved and
/// removed, bold and italic from a toolbar, alignment, palette colour,
/// video links checked as https, and a live preview.
final _stamp = DateTime.utc(2026, 9, 29);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  updatedAt: _stamp,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  authoringMetadata: const {'presetId': 'page'},
);

Exercise _built(List<PromptElement> blocks) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank('page'),
    type: 'page',
    publicationState: PublicationState.draft,
    pageBlocks: blocks,
  ),
).candidate!;

const _blocks = [
  PromptElement(
    role: 'block',
    type: 'text',
    text: 'Greetings',
    textStyle: BlockTextStyle.heading1,
  ),
  PromptElement(
    role: 'block',
    type: 'text',
    text: 'Say **buongiorno**.',
    align: BlockAlign.justify,
    color: BlockColor.green,
    readAloud: true,
  ),
  PromptElement(
    role: 'block',
    type: 'image',
    asset: 'assets/avatars/robot.png',
    text: 'A robot',
    size: BlockSize.large,
  ),
  PromptElement(
    role: 'block',
    type: 'link',
    text: 'Watch',
    url: 'https://example.org/v',
  ),
];

void main() {
  group('the Page preset', () {
    test('is registered in Cards and notes with its Help and Search', () {
      final preset = ExercisePresetRegistry.byId('page')!;
      expect(preset.name, 'Page');
      expect(preset.category, ExerciseCategory.cardsAndNotes);
      expect(preset.primitive, ExercisePrimitive.presentation);
      expect(ExercisePresetRegistry.helpByPreset['page'], contains('**bold**'));
      expect(PresetRecipes.canonicalOnly, contains('page'));
      expect(
        ExerciseSearchRegistry.definitions.map((d) => d.presetId),
        contains('page'),
      );
    });

    test('represents, decomposes and rebuilds a Page exactly', () {
      final page = _built(_blocks);
      expect(ExerciseFeatures(page).kind, LearnerExerciseKind.page);
      expect(PresetRecipes.represents(page, 'page'), isTrue);
      expect(PresetRecipes.recognize(page), 'page');
      expect(PresetRecipes.represents(page, 'note_card'), isFalse);
      final draft = PresetRecipes.decompose(page, 'page');
      expect(draft.pageBlocks, hasLength(4));
      expect(draft.pageBlocks[1].color, BlockColor.green);
      expect(
        PresetRecipes.rebuild(page, 'page')!.semanticallyEquals(page),
        isTrue,
      );
    });

    test('a new Page starts with an empty heading and paragraph', () {
      final page = _built(const []);
      expect(ExerciseFeatures(page).kind, LearnerExerciseKind.page);
      expect(page.promptElements.map((e) => e.textStyle), [
        BlockTextStyle.heading1,
        null,
      ]);
      expect(page.promptElements.every((e) => e.role == 'block'), isTrue);
    });
  });

  group('the Page form', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('blocks, marks, alignment, colour, links and the preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _built(const []),
            title: 'New Page',
            isNew: true,
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('page-block-editor-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('page-block-editor-1')), findsOneWidget);
      expect(find.byKey(const Key('page-live-preview')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exercise-field-help-image')),
        findsNothing,
        reason: 'a Page has no single picture field',
      );

      await tester.enterText(
        find.byKey(const ValueKey('page-block-text-0')),
        'Greetings',
      );
      final paragraph = find.byKey(const ValueKey('page-block-text-1'));
      await tester.enterText(paragraph, 'Say buongiorno.');
      await tester.pump();
      final controller = tester.widget<TextField>(paragraph).controller!;
      controller.selection = const TextSelection(
        baseOffset: 4,
        extentOffset: 14,
      );
      await tester.tap(find.byKey(const ValueKey('page-block-bold-1')));
      await tester.pump();
      expect(controller.text, 'Say **buongiorno**.');

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('page-block-align-1')),
          matching: find.byIcon(Icons.format_align_center),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('page-block-color-1-red')));
      await tester.pump();

      // The preview draws the Page as the learner sees it.
      expect(
        find.descendant(
          of: find.byKey(const Key('page-live-preview')),
          matching: find.text('Greetings'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('page-add-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Video link').last);
      await tester.pumpAndSettle();
      final address = find.byKey(const ValueKey('page-block-url-2'));
      await tester.enterText(address, 'http://example.org');
      await tester.pump();
      expect(
        find.text('Enter a full address starting with https://'),
        findsOneWidget,
      );
      await tester.enterText(address, 'https://example.org/v');
      await tester.pump();
      expect(
        find.text('Enter a full address starting with https://'),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('page-block-up-2')));
      await tester.pump();

      final save = find.byKey(const Key('exercise-save-draft'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.editorTemplate, 'page');
      final blocks = ExerciseFeatures(saved!).pageBlocks;
      expect(blocks.map((b) => b.type), ['text', 'link', 'text']);
      expect(blocks[0].text, 'Greetings');
      expect(blocks[0].textStyle, BlockTextStyle.heading1);
      expect(blocks[1].url, 'https://example.org/v');
      expect(blocks[2].text, 'Say **buongiorno**.');
      expect(blocks[2].align, BlockAlign.center);
      expect(blocks[2].color, BlockColor.red);
    });

    testWidgets('a stored Page opens its blocks; read-only adds nothing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _built(_blocks),
            title: 'Page',
            isNew: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(ValueKey('page-block-editor-$i')), findsOneWidget);
      }
      expect(
        tester
            .widget<PopupMenuButton<Object?>>(
              find.byKey(const Key('page-add-block')),
            )
            .enabled,
        isFalse,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('page-live-preview')),
          matching: find.byType(PageCardView),
        ),
        findsNothing,
        reason: 'the preview is the PageCardView itself',
      );
      expect(
        tester
            .widget<PageCardView>(find.byKey(const Key('page-live-preview')))
            .blocks,
        hasLength(4),
      );
    });
  });
}

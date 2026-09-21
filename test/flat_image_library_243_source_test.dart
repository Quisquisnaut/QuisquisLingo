import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';

class _Catalog extends ExerciseImageMetadataService {
  _Catalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'library distinguishes sources and returns device image identity',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('qql_library_source_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final deviceFile = File('${temp.path}${Platform.pathSeparator}cat.webp');
      await tester.runAsync(
        () async => deviceFile.writeAsBytes(
          await File('assets/exercise_images/apple.webp').readAsBytes(),
        ),
      );
      final device = ExerciseImageMetadata(
        id: 'cat-01',
        label: 'Cat',
        category: 'animals',
        tags: const ['cat'],
        assetPath: deviceFile.path,
        origin: 'local',
        attribution: const ImageAttribution(
          author: 'A. Artist',
          license: 'CC BY 4.0',
        ),
      );
      final bundled = ExerciseImageMetadata(
        id: 'apple',
        label: 'Apple',
        category: 'food_drinks',
        tags: const ['apple'],
        assetPath: 'assets/exercise_images/apple.webp',
        origin: 'bundled',
      );
      ExerciseImageMetadata? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  selected = await Navigator.of(context)
                      .push<ExerciseImageMetadata>(
                        MaterialPageRoute(
                          builder: (_) => FlatImageLibraryScreen(
                            readOnly: true,
                            metadataService: _Catalog([bundled, device]),
                          ),
                        ),
                      );
                },
                child: const Text('Open library'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open library'));
      await tester.pumpAndSettle();
      expect(find.text('QQL'), findsOneWidget);
      expect(find.text('DEVICE'), findsOneWidget);
      expect(find.text('COURSE'), findsNothing);
      expect(find.text('USED'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exercise-image-cat-01')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use image'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'cat-01');
      expect(selected?.origin, 'local');
      expect(selected?.attribution?.author, 'A. Artist');
    },
  );

  testWidgets('Course editor shows image source alongside Course use', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Exercise exercise(String asset, {SharedImageSource? source}) {
      final base = Exercise(
        id: 'image-label-test',
        type: 'choice',
        prompt: 'Choose the image.',
        question: '',
        answers: const ['Cat', 'Dog'],
        correct: 0,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
        imageAsset: asset,
      );
      if (source == null) return base;
      return Exercise.v2(
        id: base.id,
        editorTemplate: base.editorTemplate,
        promptElements: [
          for (final element in base.promptElements)
            if (element.type == 'image')
              PromptElement(
                role: element.role,
                type: element.type,
                asset: element.asset,
                sharedImageSource: source,
              )
            else
              element,
        ],
        interaction: base.interaction,
        evaluation: base.evaluation,
      );
    }

    Future<void> show(Exercise imageExercise) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            key: ValueKey(
              imageExercise.promptElements
                      .firstWhere((element) => element.type == 'image')
                      .sharedImageSource
                      ?.id ??
                  imageExercise.imageAsset,
            ),
            exercise: imageExercise,
            title: 'Image labels',
            isNew: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pump();
    }

    await show(exercise('assets/exercise_images/apple.webp'));
    expect(find.text('QQL'), findsOneWidget);
    expect(find.text('COURSE'), findsNothing);
    expect(find.text('USED'), findsOneWidget);
    expect(find.text('DEVICE'), findsNothing);

    final reference = 'media:${'a' * 64}.webp';
    await show(
      exercise(
        reference,
        source: const SharedImageSource(
          id: 'cat-01',
          label: 'Cat',
          category: 'animals',
          tags: ['cat'],
          origin: 'local',
        ),
      ),
    );
    expect(find.text('DEVICE'), findsOneWidget);
    expect(find.text('COURSE'), findsOneWidget);
    expect(find.text('USED'), findsOneWidget);
    expect(find.text('QQL'), findsNothing);

    await show(exercise(reference));
    expect(find.text('COURSE'), findsOneWidget);
    expect(find.text('USED'), findsOneWidget);
    expect(find.text('DEVICE'), findsNothing);
    expect(find.text('QQL'), findsNothing);
  });
}

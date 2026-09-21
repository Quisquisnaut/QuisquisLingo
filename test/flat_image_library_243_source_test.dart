import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/widgets/course_media_image.dart';

import 'support/pump_file_io.dart';

class _Catalog extends ExerciseImageMetadataService {
  _Catalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

/// Badges now sit over each image, so count them inside the grid only: the
/// badge filter above the grid uses the same labels.
Finder _inGrid(String text) => find.descendant(
  of: find.byKey(const Key('exercise-image-grid')),
  matching: find.text(text),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Course Image Library lists owned images beside shared images', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_course_image_library_'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    final media = CourseMediaStore(supportDirectory: () async => temp);
    final base = Course.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
    final bytes = (await tester.runAsync(
      () => File('assets/exercise_images/apple.webp').readAsBytes(),
    ))!;
    final reference = (await tester.runAsync(
      () => media.addBytes(base.courseId, bytes, 'webp'),
    ))!;
    final course = Course.fromJson({...base.toJson(), 'coverImage': reference});
    const bundled = ExerciseImageMetadata(
      id: 'apple',
      label: 'Apple',
      category: 'food_drinks',
      tags: ['apple'],
      assetPath: 'assets/exercise_images/apple.webp',
      origin: 'bundled',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          course: course,
          mediaStore: media,
          readOnly: true,
          selectMode: false,
          metadataService: _Catalog(const [bundled]),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () =>
          find.textContaining('Image Library · 2 images').evaluate().isNotEmpty,
    );
    expect(find.textContaining('Image Library · 2 images'), findsOneWidget);
    expect(_inGrid('COURSE'), findsOneWidget);
    expect(_inGrid('QQL'), findsOneWidget);
    expect(_inGrid('IN USE'), findsNWidgets(2));
    expect(find.text('DEVICE'), findsNothing);
    // The badge filter narrows the grid to images carrying that badge.
    await tester.tap(find.byKey(const ValueKey('exercise-image-badge-QQL')));
    await tester.pump();
    expect(_inGrid('QQL'), findsOneWidget);
    expect(_inGrid('COURSE'), findsNothing);
    await tester.tap(find.text('All badges'));
    await tester.pump();
    expect(_inGrid('COURSE'), findsOneWidget);
    await tester.pumpUntilFileIoState(
      () => find
          .descendant(
            of: find.byType(CourseMediaImage),
            matching: find.byType(Image),
          )
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Course Image Library adds IN USE to QQL and DEVICE entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final courseJson =
        jsonDecode(
              File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final lessons = courseJson['lessons'] as List;
    final rounds = (lessons.first as Map)['rounds'] as List;
    final content = (rounds.first as Map)['content'] as List;
    final bundledExercise = (content.first as Map)['exercise'] as Map;
    final interaction = bundledExercise['interaction'] as Map;
    final items = interaction['items'] as List;
    final choiceContent = (items.first as Map)['content'] as List;
    choiceContent.add({
      'role': 'clue',
      'type': 'image',
      'asset': 'assets/exercise_images/banana.webp',
    });
    final deviceExercise = (content[1] as Map)['exercise'] as Map;
    final prompt = deviceExercise['prompt'] as List;
    final image = prompt.cast<Map>().firstWhere(
      (element) => element['type'] == 'image',
    );
    image['asset'] = 'media:${'a' * 64}.webp';
    image['sharedImageSource'] = const SharedImageSource(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: ['cat'],
      origin: 'local',
    ).toJson();
    final course = Course.fromJson(courseJson);
    final records = [
      const ExerciseImageMetadata(
        id: 'apple',
        label: 'Apple',
        category: 'food_drinks',
        tags: ['apple'],
        assetPath: 'assets/exercise_images/apple.webp',
        origin: 'bundled',
      ),
      const ExerciseImageMetadata(
        id: 'banana',
        label: 'Banana',
        category: 'food_drinks',
        tags: ['banana'],
        assetPath: 'assets/exercise_images/banana.webp',
        origin: 'bundled',
      ),
      const ExerciseImageMetadata(
        id: 'cat-01',
        label: 'Cat',
        category: 'animals',
        tags: ['cat'],
        assetPath: 'C:/missing/cat.webp',
        origin: 'local',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          course: course,
          mediaStore: CourseMediaStore(
            supportDirectory: () async => Directory.systemTemp,
          ),
          readOnly: true,
          metadataService: _Catalog(records),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () =>
          find.textContaining('Image Library · 3 images').evaluate().isNotEmpty,
    );
    expect(_inGrid('QQL'), findsNWidgets(2));
    expect(_inGrid('DEVICE'), findsOneWidget);
    expect(_inGrid('IN USE'), findsNWidgets(3));
    expect(find.textContaining('COURSE'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Course Image Library shows a device image and its copy once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_course_image_merge_'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    final media = CourseMediaStore(supportDirectory: () async => temp);
    final courseJson =
        jsonDecode(
              File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final bytes = (await tester.runAsync(
      () => File('assets/exercise_images/apple.webp').readAsBytes(),
    ))!;
    final reference = (await tester.runAsync(
      () => media.addBytes(courseJson['courseId'] as String, bytes, 'webp'),
    ))!;
    final lessons = courseJson['lessons'] as List;
    final rounds = (lessons.first as Map)['rounds'] as List;
    final content = (rounds.first as Map)['content'] as List;
    final exercise = (content[1] as Map)['exercise'] as Map;
    final image = (exercise['prompt'] as List).cast<Map>().firstWhere(
      (element) => element['type'] == 'image',
    );
    image['asset'] = reference;
    image['sharedImageSource'] = const SharedImageSource(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: ['cat'],
      origin: 'local',
    ).toJson();
    final course = Course.fromJson(courseJson);
    final originalFile = File('${temp.path}${Platform.pathSeparator}cat.webp');
    await tester.runAsync(() => originalFile.writeAsBytes(bytes));
    final original = ExerciseImageMetadata(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: const ['cat'],
      assetPath: originalFile.path,
      origin: 'local',
    );
    final missingOriginal = ExerciseImageMetadata(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: const ['cat'],
      assetPath: '${temp.path}${Platform.pathSeparator}gone.webp',
      origin: 'local',
    );

    Future<void> show(
      List<ExerciseImageMetadata> records, {
      int count = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlatImageLibraryScreen(
            key: UniqueKey(),
            course: course,
            mediaStore: media,
            readOnly: true,
            metadataService: _Catalog(records),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find
            .textContaining('Image Library \u00b7 $count images')
            .evaluate()
            .isNotEmpty,
      );
    }

    // The original is on the device: one tile carries all three badges.
    await show([original]);
    expect(_inGrid('cat'), findsOneWidget);
    expect(_inGrid('DEVICE'), findsOneWidget);
    expect(_inGrid('COURSE'), findsOneWidget);
    expect(_inGrid('IN USE'), findsOneWidget);

    // The original was deleted: the Course copy stands alone.
    await show(const []);
    expect(_inGrid('DEVICE'), findsNothing);
    expect(_inGrid('COURSE'), findsOneWidget);

    // A record whose file is gone does not hide the working Course copy.
    await show([missingOriginal], count: 2);
    expect(_inGrid('cat'), findsNWidgets(2));
    expect(_inGrid('COURSE'), findsOneWidget);
    expect(_inGrid('DEVICE'), findsOneWidget);
    expect(_inGrid('IN USE'), findsNWidgets(2));
    // Let the Course file finish loading so Windows releases it before the
    // temporary folder is deleted.
    await tester.pumpUntilFileIoState(
      () => find
          .descendant(
            of: find.byType(CourseMediaImage),
            matching: find.byType(Image),
          )
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
      expect(_inGrid('QQL'), findsOneWidget);
      expect(_inGrid('DEVICE'), findsOneWidget);
      expect(find.text('COURSE'), findsNothing);
      expect(find.text('IN USE'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('exercise-image-badge-DEVICE')),
      );
      await tester.pumpAndSettle();
      expect(_inGrid('QQL'), findsNothing);
      expect(_inGrid('DEVICE'), findsOneWidget);
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
    expect(find.text('IN USE'), findsOneWidget);
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
    expect(find.text('IN USE'), findsOneWidget);
    expect(find.text('QQL'), findsNothing);

    await show(exercise(reference));
    expect(find.text('COURSE'), findsOneWidget);
    expect(find.text('IN USE'), findsOneWidget);
    expect(find.text('DEVICE'), findsNothing);
    expect(find.text('QQL'), findsNothing);
  });
}

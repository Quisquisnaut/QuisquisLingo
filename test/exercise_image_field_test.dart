import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/widgets/exercise_image_field.dart';

void main() {
  Future<List<ExerciseImageChange>> pump(
    WidgetTester tester, {
    required String asset,
    SharedImageSource? source,
    bool readOnly = false,
  }) async {
    final changes = <ExerciseImageChange>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseImageField(
              course: null,
              asset: asset,
              sharedSource: source,
              readOnly: readOnly,
              help: const Icon(Icons.help_outline, key: Key('image-help')),
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('shows the badges its inputs describe and the help', (
    tester,
  ) async {
    await pump(tester, asset: 'assets/exercise_images/apple.webp');
    expect(find.text('QQL'), findsOneWidget);
    expect(find.text('IN USE'), findsOneWidget);
    expect(find.text('DEVICE'), findsNothing);
    expect(find.byKey(const Key('image-help')), findsOneWidget);

    await pump(
      tester,
      asset: 'media:${'a' * 64}.webp',
      source: const SharedImageSource(
        id: 'cat-01',
        label: 'Cat',
        category: 'animals',
        tags: ['cat'],
        origin: 'local',
      ),
    );
    expect(find.text('DEVICE'), findsOneWidget);
    expect(find.text('COURSE'), findsOneWidget);
    expect(find.text('IN USE'), findsOneWidget);
  });

  testWidgets('Remove image reports an empty image to the editor', (
    tester,
  ) async {
    final changes = await pump(
      tester,
      asset: 'assets/exercise_images/apple.webp',
    );
    await tester.tap(find.text('Remove image'));
    expect(changes, hasLength(1));
    expect(changes.single.asset, '');
    expect(changes.single.source, isNull);
  });

  testWidgets('no image: no badges and no Remove image', (tester) async {
    await pump(tester, asset: '');
    expect(find.text('No image selected'), findsOneWidget);
    expect(find.text('Remove image'), findsNothing);
    expect(find.text('IN USE'), findsNothing);
  });

  testWidgets('read-only disables every action', (tester) async {
    final changes = await pump(
      tester,
      asset: 'assets/exercise_images/apple.webp',
      readOnly: true,
    );
    for (final label in [
      'Choose flat image',
      'Import custom image',
      'Remove image',
    ]) {
      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(button.onPressed, isNull, reason: label);
    }
    await tester.tap(find.text('Remove image'), warnIfMissed: false);
    expect(changes, isEmpty);
  });
}

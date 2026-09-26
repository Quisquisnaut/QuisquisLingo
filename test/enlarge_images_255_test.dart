import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/flag_game_screen.dart';
import 'package:quisquislingo_app/screens/world_flag_reference_screen.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/flag_game_engine.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/sound_effect_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/course_artwork.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

class _Sounds extends SoundEffectService {
  @override
  Future<void> playSuspense() async {}

  @override
  Future<void> playVictory() async {}

  @override
  Future<void> playDefeat() async {}

  @override
  Future<void> dispose() async {}
}

class _Repository extends WorldFlagRepository {
  _Repository(this.values);

  final List<WorldFlagEntity> values;

  @override
  Future<List<WorldFlagEntity>> load() async => values;
}

class _FixedEngine extends FlagGameEngine {
  _FixedEngine(this.questions);

  final List<FlagGameQuestion> questions;

  @override
  List<FlagGameQuestion> createGame({
    required List<WorldFlagEntity> entities,
    required FlagGameMode mode,
    List<String> previousTargetOrder = const [],
  }) => questions;
}

Course _course(String id, {String cover = ''}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  courseVersion: '1',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Enlarge $id',
  ttsLanguage: 'it-IT',
  flagCode: 'IT',
  coverImage: cover,
  originalCreatedAtUtc: '2026-09-10T12:00:00Z',
  modifiedAtUtc: '2026-09-10T12:00:00Z',
  lessons: const [],
);

/// Build 255 Revision 6: Flag Game flags and the Course Info image open
/// enlarged.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<WorldFlagEntity> entities;

  setUpAll(() {
    entities = WorldFlagRepository.parseManifest(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final preview = find.byKey(const ValueKey('world-flag-preview'));

  testWidgets('a question flag enlarges without giving the answer away', (
    tester,
  ) async {
    final questions = [
      for (var index = 0; index < 12; index++)
        FlagGameQuestion(
          target: entities[index],
          options: [
            entities[index],
            entities[12 + index * 4],
            entities[13 + index * 4],
            entities[14 + index * 4],
          ],
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(questions),
          soundEffectService: _Sounds(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('flag-game-start')));
    await tester.pumpAndSettle();

    final target = questions.first.target;
    await tester.tap(find.byKey(const Key('flag-game-flag-enlarge')));
    await tester.pumpAndSettle();
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.byType(WorldFlagArt)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<WorldFlagArt>(
            find.descendant(of: preview, matching: find.byType(WorldFlagArt)),
          )
          .entity
          .id,
      target.id,
    );
    expect(
      find.descendant(of: preview, matching: find.text(target.displayNameEn)),
      findsNothing,
    );
    expect(
      tester.getSize(
        find.descendant(of: preview, matching: find.byType(WorldFlagArt)),
      ),
      isNot(
        tester.getSize(
          find.descendant(
            of: find.byKey(const Key('flag-game-flag-enlarge')),
            matching: find.byType(WorldFlagArt),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('world-flag-preview-close')));
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
    // The question goes on as before.
    await tester.tap(find.byKey(ValueKey('flag-game-answer-${target.id}')));
    await tester.pump();
    expect(find.text('Correct'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a reference flag enlarges with its name', (tester) async {
    const category = WorldFlagReferenceCategory.languageRelatedFlags;
    final shown = WorldFlagRepository.referenceFor(entities, category);
    await tester.pumpWidget(
      MaterialApp(
        home: WorldFlagReferenceScreen(category: category, entities: shown),
      ),
    );
    await tester.pumpAndSettle();
    final first = shown.first;
    await tester.tap(
      find.byKey(ValueKey('flag-reference-enlarge-${first.id}')),
    );
    await tester.pumpAndSettle();
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.text(first.displayNameEn)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('world-flag-preview-close')));
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
  });

  group('Course Info', () {
    Future<void> showInfo(WidgetTester tester, Course course) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await ProfileService().addProfile('Alice');
      await tester.pumpWidget(
        MaterialApp(home: CourseInfoScreen(course: course)),
      );
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('course-info-image')).evaluate().isNotEmpty,
      );
    }

    testWidgets('the flag opens enlarged', (tester) async {
      const id = 'info_flag';
      await showInfo(tester, _course(id));
      final image = find.byKey(const Key('course-info-image'));
      expect(
        find.descendant(of: image, matching: find.byType(CourseArtwork)),
        findsNothing,
      );
      expect(find.byTooltip('Enlarge Course image'), findsOneWidget);

      await tester.tap(image);
      await tester.pumpAndSettle();
      final dialog = find.byKey(const ValueKey('course-artwork-preview-$id'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const ValueKey('course-artwork-flag-$id')),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('course-artwork-preview-close')),
      );
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });

    testWidgets('a cover is shown instead of the flag and opens enlarged', (
      tester,
    ) async {
      const id = 'info_cover';
      final bytes = await tester.runAsync(
        () => File('test/fixtures/import/valid_cover.png').readAsBytes(),
      );
      final cover = (await tester.runAsync(
        () => CourseMediaStore().addBytes(id, bytes!, 'png', cover: true),
      ))!;
      await showInfo(tester, _course(id, cover: cover));
      final image = find.byKey(const Key('course-info-image'));
      expect(
        find.descendant(
          of: image,
          matching: find.byKey(const ValueKey('course-artwork-cover-$id')),
        ),
        findsOneWidget,
      );

      await tester.tap(image);
      await tester.pumpAndSettle();
      final dialog = find.byKey(const ValueKey('course-artwork-preview-$id'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const ValueKey('course-artwork-cover-$id')),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.descendant(of: dialog, matching: find.byType(CourseArtwork)),
            )
            .width,
        greaterThan(96),
      );
    });
  });
}

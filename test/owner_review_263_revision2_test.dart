import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_cover_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/picture_answers.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 263 Revision 2 (owner decisions of 4 October 2026): picture
/// answers can be large, square (a cropped copy chosen with a crop and zoom
/// editor) and a set number per row; the Course's defaults are in Lesson
/// Options and an exercise may override them.

const _profileId = '00000000-0000-4000-8000-000000000263';
const _created = '2026-10-04T00:00:00.000Z';
final _stamp = DateTime.utc(2026, 10, 4);

PromptElement _text(String text, [String role = 'primary']) =>
    PromptElement(type: 'text', text: text, role: role);

/// A Select the image with four Course pictures.
Exercise _pictures({PrimitiveOptions? options, int count = 4}) =>
    Exercise.canonical(
      id: 'pictures-263',
      updatedAt: _stamp,
      primitive: ExercisePrimitive.select,
      options: options,
      promptElements: [_text('Select ‘mela’.', 'question')],
      items: [
        for (final (index, word) in [
          'mela',
          'pera',
          'uva',
          'fico',
        ].take(count).indexed)
          ExerciseItem(
            id: 'item-$index',
            content: [
              _text(word),
              PromptElement(type: 'image', asset: 'media:${'$index' * 64}.png'),
            ],
          ),
      ],
      canonicalEvaluation: const CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['item-0'],
      ),
      authoringMetadata: const {'presetId': 'icon_choice'},
    );

Course _course({
  PictureAnswerStyle pictureAnswers = PictureAnswerStyle.standard,
  List<Exercise>? exercises,
}) {
  final round = LearningRound(
    id: 'round-263',
    updatedAt: _stamp,
    title: '',
    exercises: exercises ?? [_pictures()],
  );
  return Course(
    courseId: 'pictures-263-course',
    originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
      profileId: _profileId,
      displayName: 'Pictures author',
    ),
    originalCreatedAtUtc: _created,
    maintainer: const CourseMaintainer(_profileId),
    lastVersionEditorProfileId: _profileId,
    lastVersionEditorDisplayName: 'Pictures author',
    modifiedAtUtc: _created,
    title: 'Pictures 263',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    ttsLanguage: 'it-IT',
    pictureAnswers: pictureAnswers,
    lessons: [
      Lesson(
        lessonId: 'lesson-263',
        updatedAt: _stamp,
        title: 'Pictures',
        rounds: [round],
      ),
    ],
  );
}

PrimitiveOptions _look({
  PictureSize? size,
  PictureShape? shape,
  PicturesPerRow? perRow,
}) => PrimitiveOptions({
  if (size != null) OptionKey.pictureSize: EnumOptionValue(size),
  if (shape != null) OptionKey.pictureShape: EnumOptionValue(shape),
  if (perRow != null) OptionKey.picturesPerRow: EnumOptionValue(perRow),
});

void _installStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return testSupportDirectory.path;
          }
          throw PlatformException(code: 'test-storage');
        },
      );
  keepCrashLogUnavailable();
}

Future<void> _pumpRound(WidgetTester tester, Course course) async {
  final lesson = course.lessons.single;
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: lesson,
        round: lesson.rounds.single,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
      ),
    ),
  );
  for (var frame = 0; frame < 80; frame++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (find
        .byKey(const Key('exercise-renderer-select'))
        .evaluate()
        .isNotEmpty) {
      break;
    }
  }
}

/// A plain 600 × 400 PNG.
Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 600, 400),
    ui.Paint()..color = const ui.Color(0xff3366cc),
  );
  final image = await recorder.endRecording().toImage(600, 400);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the model', () {
    test('the registry offers the three options, following the Course', () {
      final effective = PrimitiveCapabilityRegistry.effectiveOptions(
        ExercisePrimitive.select,
        PrimitiveOptions.empty,
      );
      expect(
        effective.enumValue<PictureSize>(OptionKey.pictureSize),
        PictureSize.course,
      );
      expect(
        effective.enumValue<PictureShape>(OptionKey.pictureShape),
        PictureShape.course,
      );
      expect(
        effective.enumValue<PicturesPerRow>(OptionKey.picturesPerRow),
        PicturesPerRow.course,
      );
    });

    test('the standard look is not stored; another one is', () {
      expect(_course().toJson().containsKey('pictureAnswers'), isFalse);
      // Without a choice: large squares, two per row (owner decision, same
      // day); only what differs is stored.
      expect(PictureAnswerStyle.standard.size, PictureSize.large);
      expect(PictureAnswerStyle.standard.shape, PictureShape.square);
      expect(PictureAnswerStyle.standard.perRowCount, 2);
      const style = PictureAnswerStyle(
        size: PictureSize.normal,
        shape: PictureShape.round,
        perRow: PicturesPerRow.three,
      );
      final json = _course(pictureAnswers: style).toJson();
      expect(json['pictureAnswers'], {
        'size': 'normal',
        'shape': 'round',
        'perRow': 'three',
      });
      expect(
        _course(
          pictureAnswers: const PictureAnswerStyle(
            perRow: PicturesPerRow.automatic,
          ),
        ).toJson()['pictureAnswers'],
        {'perRow': 'automatic'},
      );
      expect(Course.fromJson(json).pictureAnswers, style);
    });

    test('a Course look is never `course` and never unknown', () {
      final json = _course().toJson();
      for (final wrong in [
        {'shape': 'course'},
        {'shape': 'oval'},
        {'colour': 'red'},
      ]) {
        expect(
          () => Course.fromJson({...json, 'pictureAnswers': wrong}),
          throwsFormatException,
          reason: '$wrong',
        );
      }
    });

    test('an exercise overrides the Course where it names a value', () {
      const course = PictureAnswerStyle(
        size: PictureSize.large,
        perRow: PicturesPerRow.three,
      );
      final own = course.overriddenBy(
        _look(shape: PictureShape.square, size: PictureSize.course),
      );
      expect(own.size, PictureSize.large);
      expect(own.shape, PictureShape.square);
      expect(own.perRowCount, 3);
      expect(PictureAnswerStyle.overrides(_look()), isFalse);
      expect(
        PictureAnswerStyle.overrides(_look(size: PictureSize.course)),
        isFalse,
      );
      expect(
        PictureAnswerStyle.overrides(_look(perRow: PicturesPerRow.one)),
        isTrue,
      );
    });

    test('a Course that asks for another look needs this build', () {
      expect(
        PictureAnswers.withMinimumAppBuild(_course()).minimumAppBuild,
        isNull,
      );
      final byCourse = PictureAnswers.withMinimumAppBuild(
        _course(pictureAnswers: PictureAnswerStyle.earlier),
      );
      expect(byCourse.minimumAppBuild, PictureAnswerStyle.minimumAppBuild);
      final byExercise = PictureAnswers.withMinimumAppBuild(
        _course(
          exercises: [_pictures(options: _look(size: PictureSize.large))],
        ),
      );
      expect(byExercise.minimumAppBuild, PictureAnswerStyle.minimumAppBuild);
      expect(
        PictureAnswerStyle.minimumAppBuild,
        lessThanOrEqualTo(int.parse(AppMetadata.buildNumber)),
      );
    });
  });

  group('the preset form', () {
    ExerciseDraftValues values({
      String size = 'course',
      String shape = 'course',
      String perRow = 'course',
    }) => ExerciseDraftValues(
      original: _pictures(),
      type: 'icon_choice',
      publicationState: PublicationState.draft,
      question: 'Select ‘mela’.',
      answers: 'mela\npera\nuva\nfico',
      correct: '1',
      icons: [for (var i = 0; i < 4; i++) 'media:${'$i' * 64}.png'].join('\n'),
      pictureSize: size,
      pictureShape: shape,
      picturesPerRow: perRow,
    );

    test('Select the image stores the look it chose and reads it back', () {
      final built = ExerciseDraftBuilder.build(
        values(size: 'large', shape: 'square', perRow: 'two'),
      ).candidate!;
      expect(
        built.options.enumValue<PictureSize>(OptionKey.pictureSize),
        PictureSize.large,
      );
      expect(
        built.options.enumValue<PictureShape>(OptionKey.pictureShape),
        PictureShape.square,
      );
      expect(
        built.options.enumValue<PicturesPerRow>(OptionKey.picturesPerRow),
        PicturesPerRow.two,
      );
      final draft = PresetRecipes.decompose(built, 'icon_choice');
      expect(
        (draft.pictureSize, draft.pictureShape, draft.picturesPerRow),
        ('large', 'square', 'two'),
      );
      expect(PresetRecipes.represents(built, 'icon_choice'), isTrue);
    });

    test('As in Lesson Options stores no option', () {
      final built = ExerciseDraftBuilder.build(values()).candidate!;
      expect(PictureAnswerStyle.overrides(built.options), isFalse);
      expect(built.options.values.containsKey(OptionKey.pictureSize), isFalse);
    });

    test('a preset without picture answers does not take the look', () {
      final choose = _pictures(
        options: _look(shape: PictureShape.square),
      ).copyWith(authoringMetadata: const {'presetId': 'choice_target'});
      expect(PresetRecipes.represents(choose, 'choice_target'), isFalse);
    });

    test('the fields have their Help', () {
      for (final preset in ['icon_choice', 'listening_image_choice']) {
        final keys = ExerciseFieldHelpRegistry.editorFieldKeys(preset);
        for (final key in ['pictureSize', 'pictureShape', 'picturesPerRow']) {
          expect(keys, contains(key));
          expect(
            ExerciseFieldHelpRegistry.forEditorField(preset, key).title,
            'Picture answers',
          );
        }
      }
    });

    testWidgets('the form offers the look and Crop square', (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Pictures author');
      _installStorage();
      tester.view.physicalSize = const Size(2400, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final exercise = _pictures().copyWith(
        items: [
          ExerciseItem(
            id: 'item-0',
            content: [
              _text('mela'),
              const PromptElement(
                type: 'image',
                asset: 'assets/exercise_images/apple.webp',
              ),
            ],
          ),
          ExerciseItem(id: 'item-1', content: [_text('pera')]),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Pictures',
            isNew: false,
            course: _course(
              pictureAnswers: const PictureAnswerStyle(size: PictureSize.large),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-choice-pictureSize-course')),
        findsOneWidget,
      );
      // The Course's own choice is named.
      expect(find.text('As in Lesson Options (Large)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exercise-choice-pictureShape-course')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-choice-picturesPerRow-course')),
        findsOneWidget,
      );
      // A picture can be cropped; an answer without one cannot.
      expect(
        find.byKey(const ValueKey('answer-picture-crop-0')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('answer-picture-crop-1')), findsNothing);
    });
  });

  group('the learner sees the look', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Pictures learner');
      _installStorage();
    });

    Finder rowsOf() => find.descendant(
      of: find.byKey(const Key('picture-answer-rows')),
      matching: find.byType(Row),
    );

    Rect tile(WidgetTester tester, int index) =>
        tester.getRect(find.byKey(ValueKey('picture-answer-square-$index')));

    testWidgets('without a choice: large squares, two per row', (tester) async {
      await _pumpRound(tester, _course());
      expect(rowsOf(), findsNWidgets(2));
      for (var i = 0; i < 4; i++) {
        expect(tile(tester, i).size, const Size(176, 176));
      }
      // No word under a picture.
      expect(find.text('mela'), findsNothing);
    });

    testWidgets('the spare picture stands in the middle of its row', (
      tester,
    ) async {
      // Three pictures, two per row: the third in the middle of row two.
      await _pumpRound(tester, _course(exercises: [_pictures(count: 3)]));
      expect(rowsOf(), findsNWidgets(2));
      final middle = tester.getCenter(rowsOf().first).dx;
      final three = [for (var i = 0; i < 3; i++) tile(tester, i)];
      final last = three.reduce((a, b) => a.top > b.top ? a : b);
      expect(three.where((rect) => rect.top == last.top), hasLength(1));
      expect(last.center.dx, closeTo(middle, 0.5));
    });

    testWidgets('four pictures, three per row: the fourth in the middle', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(
          pictureAnswers: const PictureAnswerStyle(
            perRow: PicturesPerRow.three,
          ),
        ),
      );
      final four = [for (var i = 0; i < 4; i++) tile(tester, i)];
      final bottom = four.reduce((a, b) => a.top > b.top ? a : b);
      expect(four.where((rect) => rect.top == bottom.top), hasLength(1));
      expect(
        bottom.center.dx,
        closeTo(tester.getCenter(rowsOf().first).dx, 0.5),
      );
    });

    testWidgets('the earlier look keeps its tiles, rows centred', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(pictureAnswers: PictureAnswerStyle.earlier),
      );
      expect(find.byKey(const Key('picture-answer-rows')), findsNothing);
      expect(
        find.byKey(const ValueKey('picture-answer-square-0')),
        findsNothing,
      );
      final wrap = tester.widget<Wrap>(
        find
            .descendant(
              of: find.byKey(const Key('exercise-renderer-select')),
              matching: find.byType(Wrap),
            )
            .first,
      );
      expect(wrap.alignment, WrapAlignment.center);
    });

    testWidgets('an exercise overrides the Course', (tester) async {
      await _pumpRound(
        tester,
        _course(
          pictureAnswers: PictureAnswerStyle.earlier,
          exercises: [
            _pictures(
              options: _look(
                shape: PictureShape.square,
                perRow: PicturesPerRow.three,
              ),
            ),
          ],
        ),
      );
      expect(rowsOf(), findsNWidgets(2));
      // Normal size from the Course, square from the exercise.
      expect(tile(tester, 3).size, const Size(112, 112));
    });

    testWidgets('a narrow screen shrinks the tiles to keep the row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpRound(
        tester,
        _course(
          pictureAnswers: const PictureAnswerStyle(
            perRow: PicturesPerRow.three,
          ),
          exercises: [_pictures(count: 3)],
        ),
      );
      final first = tile(tester, 0);
      final third = tile(tester, 2);
      expect(first.width, lessThan(176));
      expect(first.top, third.top);
      expect(tester.takeException(), isNull);
    });
  });

  group('Crop square', () {
    test('stores a square copy within the Course picture limit', () async {
      final temp = await Directory.systemTemp.createTemp('qql_crop_square_');
      addTearDown(() => temp.delete(recursive: true));
      final media = CourseMediaStore(supportDirectory: () async => temp);
      final source = await _png();
      final reference = await CourseCoverService(mediaStore: media).storeSquare(
        'crop-course',
        source,
        crop: const ui.Rect.fromLTWH(100, 50, 300, 300),
      );
      expect(CourseMediaStore.isImageReference(reference), isTrue);
      final file = await media.existingFile('crop-course', reference);
      final bytes = await file!.readAsBytes();
      expect(bytes.length, lessThanOrEqualTo(CourseMediaStore.maxImageBytes));
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, frame.image.height);
      frame.image.dispose();
      codec.dispose();
    });
  });

  group('Lesson Options', () {
    testWidgets('the Course defaults are chosen there, after Timed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'sound_effects_enabled': false,
        'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
      });
      await ProfileService().createProfile(
        'Pictures author',
        learnerProfileId: _profileId,
        generateScreenNameSuffix: false,
      );
      await SettingsService().completeWelcomeWizard();
      _installStorage();
      await tester.binding.setSurfaceSize(const Size(700, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: _course(), userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-lesson-options')));
      await tester.pumpAndSettle();
      // GuideBook, Duel, Timed, Picture answers (owner decision).
      final order = [
        find.byKey(const Key('course-use-guidebook')),
        find.byKey(const Key('course-create-duels')),
        find.text('Default Timed limits'),
        find.text('Picture answers'),
      ].map((finder) => tester.getTopLeft(finder).dy).toList();
      expect(order, [...order]..sort());
      expect(
        find.byKey(const ValueKey('course-picture-size-large')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('course-pictures-per-row-two')),
        findsOneWidget,
      );
      final perRow = find.byKey(const ValueKey('course-pictures-per-row-two'));
      await tester.ensureVisible(perRow);
      await tester.tap(perRow);
      await tester.pumpAndSettle();
      // At most three per row (owner decision).
      expect(find.text('3'), findsWidgets);
      expect(find.text('4'), findsNothing);
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();
      final shape = find.byKey(const ValueKey('course-picture-shape-square'));
      await tester.ensureVisible(shape);
      await tester.tap(shape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Round').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('course-picture-shape-round')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('course-pictures-per-row-three')),
        findsOneWidget,
      );
    });
  });
}

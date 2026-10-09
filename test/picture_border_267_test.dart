import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/picture_answers.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 267 Revision 7 (owner decisions of 9 October 2026): a thin grey
/// line around each picture answer, following its round or square shape;
/// on for new Courses only; a Course choice in Lesson Options that an
/// exercise can override.

const _profileId = '00000000-0000-4000-8000-000000000267';
const _created = '2026-10-09T00:00:00.000Z';
final _stamp = DateTime.utc(2026, 10, 9);

PromptElement _text(String text, [String role = 'primary']) =>
    PromptElement(type: 'text', text: text, role: role);

/// A Select the image with four Course pictures.
Exercise _pictures({PrimitiveOptions? options}) => Exercise.canonical(
  id: 'pictures-267',
  updatedAt: _stamp,
  primitive: ExercisePrimitive.select,
  options: options,
  promptElements: [_text('Select ‘mela’.', 'question')],
  items: [
    for (final (index, word) in ['mela', 'pera', 'uva', 'fico'].indexed)
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
  Exercise? exercise,
}) => Course(
  courseId: 'pictures-267-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Pictures author',
  ),
  originalCreatedAtUtc: _created,
  maintainer: const CourseMaintainer(_profileId),
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Pictures author',
  modifiedAtUtc: _created,
  title: 'Pictures 267',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  pictureAnswers: pictureAnswers,
  lessons: [
    Lesson(
      lessonId: 'lesson-267',
      updatedAt: _stamp,
      title: 'Pictures',
      rounds: [
        LearningRound(
          id: 'round-267',
          updatedAt: _stamp,
          title: '',
          exercises: [exercise ?? _pictures()],
        ),
      ],
    ),
  ],
);

PrimitiveOptions _border(PictureBorder border, {PictureShape? shape}) =>
    PrimitiveOptions({
      OptionKey.pictureBorder: EnumOptionValue(border),
      if (shape != null) OptionKey.pictureShape: EnumOptionValue(shape),
    });

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the model', () {
    test('a Course stores the line; absent means none', () {
      expect(PictureAnswerStyle.standard.border, PictureBorder.none);
      expect(PictureAnswerStyle.newCourse.border, PictureBorder.thin);
      expect(PictureAnswerStyle.newCourse.toJson(), {'border': 'thin'});
      expect(
        PictureAnswerStyle.fromJson(const {'border': 'thin'}),
        PictureAnswerStyle.newCourse,
      );
      expect(PictureAnswerStyle.fromJson(null).border, PictureBorder.none);
      for (final invalid in ['course', 'thick', 3]) {
        expect(
          () => PictureAnswerStyle.fromJson({'border': invalid}),
          throwsFormatException,
          reason: '$invalid',
        );
      }
      // Changing another choice keeps the line.
      expect(
        PictureAnswerStyle.newCourse
            .copyWith(size: PictureSize.normal)
            .bordered,
        isTrue,
      );
    });

    test('an exercise overrides the Course', () {
      expect(
        PictureAnswerStyle.newCourse
            .overriddenBy(_border(PictureBorder.none))
            .bordered,
        isFalse,
      );
      expect(
        PictureAnswerStyle.standard
            .overriddenBy(_border(PictureBorder.thin))
            .bordered,
        isTrue,
      );
      expect(
        PictureAnswerStyle.newCourse
            .overriddenBy(_border(PictureBorder.course))
            .bordered,
        isTrue,
      );
      expect(
        PictureAnswerStyle.overridesBorder(_border(PictureBorder.course)),
        isFalse,
      );
      expect(
        PictureAnswerStyle.overridesBorder(_border(PictureBorder.none)),
        isTrue,
      );
    });

    test('a Course that asks for the line needs this build', () {
      expect(PictureAnswers.requiredBuild(_course()), isNull);
      expect(
        PictureAnswers.requiredBuild(
          _course(
            pictureAnswers: const PictureAnswerStyle(size: PictureSize.normal),
          ),
        ),
        PictureAnswerStyle.minimumAppBuild,
      );
      expect(
        PictureAnswers.withMinimumAppBuild(
          _course(pictureAnswers: PictureAnswerStyle.newCourse),
        ).minimumAppBuild,
        PictureAnswerStyle.borderMinimumAppBuild,
      );
      expect(
        PictureAnswers.withMinimumAppBuild(
          _course(exercise: _pictures(options: _border(PictureBorder.none))),
        ).minimumAppBuild,
        PictureAnswerStyle.borderMinimumAppBuild,
      );
      expect(
        PictureAnswerStyle.borderMinimumAppBuild,
        lessThanOrEqualTo(int.parse(AppMetadata.buildNumber)),
      );
    });

    test('new Courses have the line, by New Course and by the Wizard', () {
      final operations = CourseLibraryOperations(clock: () => _stamp);
      const creator = LearnerProfile(
        learnerProfileId: _profileId,
        displayName: 'Author',
      );
      final wizard = operations.newWizardCourse(
        creator: creator,
        title: 'Lines',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
      );
      expect(wizard.pictureAnswers, PictureAnswerStyle.newCourse);
      expect(
        CourseWizardOptions.defaults.pictureAnswers,
        PictureAnswerStyle.newCourse,
      );
      // A Course made before keeps no line.
      expect(_course().pictureAnswers.bordered, isFalse);
    });
  });

  group('the preset form', () {
    ExerciseDraftValues values(String border) => ExerciseDraftValues(
      original: _pictures(),
      type: 'icon_choice',
      publicationState: PublicationState.draft,
      question: 'Select ‘mela’.',
      answers: 'mela\npera\nuva\nfico',
      correct: '1',
      icons: [for (var i = 0; i < 4; i++) 'media:${'$i' * 64}.png'].join('\n'),
      pictureBorder: border,
    );

    test('Select the image stores the border it chose and reads it back', () {
      final built = ExerciseDraftBuilder.build(values('none')).candidate!;
      expect(
        built.options.enumValue<PictureBorder>(OptionKey.pictureBorder),
        PictureBorder.none,
      );
      expect(
        PresetRecipes.decompose(built, 'icon_choice').pictureBorder,
        'none',
      );
      expect(PresetRecipes.represents(built, 'icon_choice'), isTrue);
      final course = ExerciseDraftBuilder.build(values('course')).candidate!;
      expect(
        course.options.enumValue<PictureBorder>(OptionKey.pictureBorder),
        isNull,
      );
    });
  });

  group('the learner sees the line', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Pictures learner');
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
    });

    BorderSide squareSide(WidgetTester tester, int index) {
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(ValueKey('picture-answer-square-$index')),
          matching: find.byType(FilledButton),
        ),
      );
      final shape =
          button.style!.shape!.resolve(const <WidgetState>{})
              as RoundedRectangleBorder;
      return shape.side;
    }

    testWidgets('a square tile has the thin line in a new Course', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(pictureAnswers: PictureAnswerStyle.newCourse),
      );
      for (var i = 0; i < 4; i++) {
        expect(squareSide(tester, i).width, 1.5);
      }
    });

    testWidgets('a Course made before draws no line', (tester) async {
      await _pumpRound(tester, _course());
      expect(squareSide(tester, 0), BorderSide.none);
    });

    testWidgets('a round tile follows its shape; an exercise overrides', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _course(
          exercise: _pictures(
            options: _border(PictureBorder.thin, shape: PictureShape.round),
          ),
        ),
      );
      final key = find.byKey(const ValueKey('picture-answer-border-0'));
      expect(key, findsOneWidget);
      final side = tester
          .widget<FilledButton>(key)
          .style!
          .side!
          .resolve(const <WidgetState>{})!;
      expect(side.width, 1.5);
    });
  });
}

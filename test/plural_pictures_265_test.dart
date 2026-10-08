import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/canonical/capability_description.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/plural_pictures.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/plural_picture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 265 Revision 11 (owner decision of 7 October 2026, look A): a
/// picture in an exercise can stand for several things. The author ticks
/// Plural on it; the learner sees it as stacked copies.

const _profileId = '00000000-0000-4000-8000-000000000265';
const _created = '2026-10-07T00:00:00.000Z';
final _stamp = DateTime.utc(2026, 10, 7);
const _cat = 'assets/exercise_images/cat.webp';
final _dog = 'media:${'1' * 64}.png';

/// The cats as a Course picture (an image element); [_cat] is the QQL
/// picture, which the form stores as an icon key.
final _catMedia = 'media:${'2' * 64}.png';

PromptElement _text(String text, [String role = 'primary']) =>
    PromptElement(type: 'text', text: text, role: role);

/// A Select the image: "gatti" (cats, plural) and "cane" (a dog).
Exercise _pictures({bool catsPlural = true, bool iconKey = false}) =>
    Exercise.canonical(
      id: 'plural-265',
      updatedAt: _stamp,
      primitive: ExercisePrimitive.select,
      promptElements: [_text('Select ‘gatti’.', 'question')],
      items: [
        ExerciseItem(
          id: 'item-0',
          content: [
            _text('gatti'),
            iconKey
                ? PromptElement(
                    type: 'text',
                    role: 'icon',
                    text: _cat,
                    plural: catsPlural ? true : null,
                  )
                : PromptElement(
                    type: 'image',
                    asset: _catMedia,
                    plural: catsPlural ? true : null,
                  ),
          ],
        ),
        ExerciseItem(
          id: 'item-1',
          content: [
            _text('cane'),
            PromptElement(type: 'image', asset: _dog),
          ],
        ),
      ],
      canonicalEvaluation: const CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['item-0'],
      ),
      authoringMetadata: const {'presetId': 'icon_choice'},
    );

Course _course({List<Exercise>? exercises, int? minimumAppBuild}) => Course(
  courseId: 'plural-265-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Plural author',
  ),
  originalCreatedAtUtc: _created,
  maintainer: const CourseMaintainer(_profileId),
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Plural author',
  modifiedAtUtc: _created,
  title: 'Plural 265',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  minimumAppBuild: minimumAppBuild,
  lessons: [
    Lesson(
      lessonId: 'lesson-265',
      updatedAt: _stamp,
      title: 'Plurals',
      rounds: [
        LearningRound(
          id: 'round-265',
          updatedAt: _stamp,
          title: '',
          exercises: exercises ?? [_pictures()],
        ),
      ],
    ),
  ],
);

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the model', () {
    test('a picture carries the mark and keeps it through JSON', () {
      final image = PromptElement.fromJson({
        'type': 'image',
        'asset': _cat,
        'plural': true,
      });
      expect(image.isPlural, isTrue);
      expect(image.toJson()['plural'], isTrue);
      final icon = PromptElement.fromJson({
        'role': 'icon',
        'type': 'text',
        'text': _cat,
        'plural': true,
      });
      expect(icon.isPlural, isTrue);
      // Absent means one; withPlural(false) removes the mark.
      expect(image.withPlural(false).toJson().containsKey('plural'), isFalse);
      expect(
        const PromptElement(type: 'image', asset: _cat).toJson(),
        isNot(contains('plural')),
      );
    });

    test('only a picture may carry it, and only as true or false', () {
      for (final element in [
        {'type': 'text', 'text': 'gatti', 'plural': true},
        {'type': 'audio', 'text': 'gatti', 'plural': true},
        {'type': 'image', 'asset': _cat, 'plural': 'yes'},
      ]) {
        expect(
          () => PromptElement.fromJson(element),
          throwsFormatException,
          reason: '$element',
        );
      }
    });

    test('the exercise picture and the items read the mark', () {
      final exercise = _pictures();
      expect(exercise.items.first.pictureIsPlural, isTrue);
      expect(exercise.items.last.pictureIsPlural, isFalse);
      final illustrated = Exercise.canonical(
        id: 'illustrated-265',
        updatedAt: _stamp,
        primitive: ExercisePrimitive.input,
        promptElements: [
          _text('What are they?', 'question'),
          const PromptElement(
            role: 'picture',
            type: 'image',
            asset: _cat,
            plural: true,
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.expression,
          answers: ['gatti'],
        ),
      );
      expect(ExerciseFeatures(illustrated).illustrationPlural, isTrue);
    });

    test('a Course that marks a picture needs this build', () {
      expect(
        PluralPictures.withMinimumAppBuild(
          _course(exercises: [_pictures(catsPlural: false)]),
        ).minimumAppBuild,
        isNull,
      );
      expect(
        PluralPictures.withMinimumAppBuild(_course()).minimumAppBuild,
        PluralPictures.minimumAppBuild,
      );
      // Raised from an earlier build, kept when already enough.
      expect(
        PluralPictures.withMinimumAppBuild(
          _course(minimumAppBuild: 264008),
        ).minimumAppBuild,
        PluralPictures.minimumAppBuild,
      );
      expect(
        PluralPictures.withMinimumAppBuild(
          _course(minimumAppBuild: PluralPictures.minimumAppBuild),
        ).minimumAppBuild,
        PluralPictures.minimumAppBuild,
      );
    });

    test('the capability description names the mark', () {
      final attributes =
          capabilityDescription()['elementAttributes']! as List<Object?>;
      final plural = attributes.cast<Map<String, Object?>>().singleWhere(
        (attribute) => attribute['key'] == 'plural',
      );
      expect(plural['elementTypes'], containsAll(['image', 'text']));
      expect(plural['textRoles'], ['icon']);
      expect(plural['type'], 'boolean');
    });
  });

  group('the form', () {
    test('marks exactly the pictures it is given', () {
      final marked = PluralPictures.withMarks(_pictures(catsPlural: false), {
        _dog,
      });
      expect(marked.items.first.pictureIsPlural, isFalse);
      expect(marked.items.last.pictureIsPlural, isTrue);
      expect(PluralPictures.markedIn(marked), {_dog});
      expect(
        PluralPictures.markedIn(PluralPictures.withMarks(marked, const {})),
        isEmpty,
      );
    });

    for (final iconKey in [false, true]) {
      test('Select the image represents a plural answer '
          '(${iconKey ? 'a QQL icon key' : 'an image'})', () {
        final exercise = _pictures(iconKey: iconKey);
        expect(PresetRecipes.represents(exercise, 'icon_choice'), isTrue);
        final draft = PresetRecipes.decompose(exercise, 'icon_choice');
        expect(draft.pluralPictures, {iconKey ? _cat : _catMedia});
        // Unticked, the rebuilt exercise has no mark.
        final unmarked = ExerciseDraftBuilder.build(
          ExerciseDraftValues(
            original: exercise,
            type: 'icon_choice',
            publicationState: exercise.publicationState,
            question: draft.question,
            answers: draft.answers,
            correct: draft.correct,
            icons: draft.icons,
          ),
        ).candidate!;
        expect(PluralPictures.markedIn(unmarked), isEmpty);
      });
    }

    testWidgets('each answer picture has its Plural switch', (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Plural author');
      _installStorage();
      tester.view.physicalSize = const Size(2400, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _pictures(),
            title: 'Plurals',
            isNew: false,
            course: _course(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FilterChip chip(int i) => tester.widget<FilterChip>(
        find.byKey(ValueKey('answer-picture-plural-$i')),
      );
      expect(chip(0).selected, isTrue);
      expect(chip(1).selected, isFalse);
      await tester.tap(find.byKey(const ValueKey('answer-picture-plural-1')));
      await tester.pump();
      expect(chip(1).selected, isTrue);
      await tester.tap(find.byKey(const ValueKey('answer-picture-plural-0')));
      await tester.pump();
      expect(chip(0).selected, isFalse);
    });
  });

  group('the learner', () {
    testWidgets('a plural picture is drawn three times in its own box', (
      tester,
    ) async {
      Widget box() => Container(width: 100, height: 80, color: Colors.red);
      await tester.pumpWidget(
        Center(child: PluralPicture(plural: true, child: box())),
      );
      expect(find.byType(Container), findsNWidgets(3));
      expect(
        tester.getSize(find.byKey(const Key('plural-picture'))),
        const Size(100, 80),
      );
      await tester.pumpWidget(
        Center(child: PluralPicture(plural: false, child: box())),
      );
      expect(find.byType(Container), findsOneWidget);
      expect(find.byKey(const Key('plural-picture')), findsNothing);
    });

    testWidgets('the Round shows the plural answer as several', (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Plural learner');
      _installStorage();
      final course = _course();
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
      // One of the two answers is plural, wherever the shuffle put it.
      expect(find.byKey(const Key('plural-picture')), findsOneWidget);
    });
  });
}

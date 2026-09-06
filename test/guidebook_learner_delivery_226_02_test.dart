import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/guidebook_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _overview = 'Published Guidebook overview.';
const _draftVocabulary = 'Never deliver this Draft vocabulary.';
const _intro = 'Published Round introduction.';
const _exercisePrompt = 'Choose the matching answer.';
const _exerciseQuestion = 'uno';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Round fixture remains independently playable', () {
    final round = _course().lessons.single.rounds.single;
    final issues = CourseAuditService().auditExercise(round.exercises.single);
    expect(
      RoundPlayabilityService().playableExerciseIndices(round),
      [0],
      reason: issues
          .map((issue) => '${issue.code}: ${issue.message}')
          .join('\n'),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
    });
    await ProfileService().addProfile('Guidebook learner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  for (final state in PublicationState.values) {
    for (final inspect in [false, true]) {
      testWidgets(
        '${state.name} Guidebook respects includeDraftContent=$inspect',
        (tester) async {
          final course = _course(guidebookState: state);
          final source = jsonEncode(course.toJson());
          await tester.pumpWidget(
            MaterialApp(
              home: GuidebookScreen(
                course: course,
                lesson: course.lessons.single,
                lessonIndex: 0,
                includeDraftContent: inspect,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(_overview),
            inspect || state.isPublished ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('• $_draftVocabulary'),
            inspect ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('This Lesson Guidebook is not available.'),
            !inspect && !state.isPublished ? findsOneWidget : findsNothing,
          );
          expect(jsonEncode(course.toJson()), source);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '${state.name} Guidebook access from Round intro in preview=$inspect',
        (tester) async {
          final course = _course(guidebookState: state);
          await _openRound(tester, course, preview: inspect);
          expect(find.text(_intro), findsOneWidget);
          expect(find.text('Continue to Round'), findsOneWidget);
          final canOpenGuidebook = inspect || state.isPublished;
          expect(
            find.text('Open Guidebook'),
            canOpenGuidebook ? findsOneWidget : findsNothing,
          );

          if (canOpenGuidebook) {
            await tester.tap(find.text('Open Guidebook'));
            await tester.pumpAndSettle();
            expect(find.byType(GuidebookScreen), findsOneWidget);
            expect(
              tester
                  .widget<GuidebookScreen>(find.byType(GuidebookScreen))
                  .includeDraftContent,
              inspect,
            );
            expect(find.text(_overview), findsOneWidget);
            expect(
              find.text('• $_draftVocabulary'),
              inspect ? findsOneWidget : findsNothing,
            );
            await tester.pageBack();
            await tester.pumpAndSettle();
          }

          await tester.tap(find.text('Continue to Round'));
          await _pumpFrames(tester);
          expect(find.text(_intro), findsNothing);
          expect(find.text(_exerciseQuestion), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Home keeps Lesson identity and gates ${state.name} Guidebook access',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final course = _course(guidebookState: state);
        await CourseEditorService().saveUserCourse(course);
        await SettingsService().setLastSelectedCourseCode(
          'custom:${course.courseId}',
        );
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await _pumpFrames(tester);
        if (find.text('Alpha expiry').evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(FilledButton, 'OK'));
          await _pumpFrames(tester);
        }

        final title = find.byKey(
          const ValueKey('unified-guidebook-lesson-title-delivery-lesson'),
        );
        final action = find.byKey(
          const ValueKey('unified-guidebook-action-delivery-lesson'),
        );
        expect(title, findsOneWidget);
        expect(
          find.byKey(const Key('guidebook-lesson-icon-slot')),
          findsOneWidget,
        );
        expect(
          tester.widget<IconButton>(action).onPressed,
          state.isPublished ? isNotNull : isNull,
        );
        final node = find.ancestor(of: title, matching: find.byType(InkWell));
        expect(node, findsOneWidget);
        expect(
          tester.widget<InkWell>(node).onTap,
          state.isPublished ? isNotNull : isNull,
        );
        await tester.tap(title);
        await _pumpFrames(tester);
        expect(
          find.byType(GuidebookScreen),
          state.isPublished ? findsOneWidget : findsNothing,
        );
        expect(find.text('• $_draftVocabulary'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final preview in [false, true]) {
    testWidgets('Draft Round intro is visible only in preview=$preview', (
      tester,
    ) async {
      final course = _course(introState: PublicationState.draft);
      await _openRound(tester, course, preview: preview);
      expect(find.text(_intro), preview ? findsOneWidget : findsNothing);
      expect(
        find.text('Continue to Round'),
        preview ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(_exerciseQuestion),
        preview ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _openRound(
  WidgetTester tester,
  Course course, {
  required bool preview,
}) async {
  final lesson = course.lessons.single;
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: lesson,
        round: lesson.rounds.single,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
      ),
    ),
  );
  await _pumpFrames(tester);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Course _course({
  PublicationState guidebookState = PublicationState.published,
  PublicationState introState = PublicationState.published,
}) => Course(
  courseId: 'guidebook-delivery',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Guidebook delivery',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'delivery-lesson',
      title: 'Lesson identity remains visible',
      guidebook: Guidebook(
        publicationState: guidebookState,
        content: const [
          LearningContent(
            id: 'published-overview',
            kind: 'explanation',
            role: 'overview',
            text: _overview,
          ),
          LearningContent(
            id: 'draft-vocabulary',
            publicationState: PublicationState.draft,
            kind: 'vocabulary',
            role: 'vocabulary',
            text: _draftVocabulary,
          ),
        ],
      ),
      rounds: [
        LearningRound(
          id: 'delivery-round',
          title: 'Independent Round',
          content: [
            LearningContent(
              id: 'round-introduction',
              publicationState: introState,
              kind: 'explanation',
              role: 'lesson_intro',
              text: _intro,
            ),
            LearningContent.fromExercise(
              Exercise(
                id: 'delivery-exercise',
                type: 'choice',
                editorTemplate: 'choice',
                prompt: _exercisePrompt,
                question: _exerciseQuestion,
                answers: const ['one', 'two'],
                correct: 0,
                tts: null,
                accepted: const [],
                tokens: const [],
                orderAnswer: const [],
                pairs: const [],
                hint: '',
                icons: const [],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Read-only reviewer');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  for (final origin in [
    CourseOriginType.bundledOfficial,
    CourseOriginType.externalOfficial,
  ]) {
    for (final preset in [
      'script_recognition',
      'type_missing_word',
      'type_translation',
    ]) {
      testWidgets(
        '$origin $preset remains read-only from the real Course Editor entry',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(1200, 1500);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final course = _official(origin, preset);
          final profileId = await ProfileService().getActiveProfileId();
          if (origin == CourseOriginType.externalOfficial) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              CourseEditorService.externalOfficialStorageKey,
              jsonEncode({
                course.courseId: {'source': course.toJson()},
              }),
            );
          }
          final beforePrefs = await workflow.preferences();
          final beforeCourse = jsonEncode(course.toJson());
          final service = CourseEditorService(
            backupService: _ReadOnlyBackups(),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CourseEditorScreen(
                        course: course,
                        access: CourseAccessPolicy.evaluate(
                          course,
                          profileId: profileId,
                        ),
                        editorService: service,
                        courseService: _OfficialSource(course),
                      ),
                    ),
                  ),
                  child: const Text('Open official'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open official'));
          await workflow.settle(tester);
          expect(find.byType(CourseEditorScreen), findsOneWidget);
          expect(find.text('Read-only course'), findsOneWidget);
          _expectNoAuthorControls();

          await tester.tap(
            find.byKey(const Key('course-editor-lessons-navigation')),
          );
          await workflow.settle(tester);
          await tester.tap(find.byKey(const ValueKey('lesson-entry-lesson')));
          await workflow.settle(tester);
          _expectNoAuthorControls();
          await tester.tap(find.byKey(const ValueKey('official-round-round')));
          await workflow.settle(tester);
          await tester.tap(
            find.byKey(const ValueKey('official-exercise-exercise')),
          );
          await workflow.settle(tester);
          expect(find.text('Exercise inspection'), findsOneWidget);
          _expectNoAuthorControls();
          await tester.tap(find.text('Preview Exercise'));
          await workflow.settle(tester);
          expect(find.byType(RoundScreen), findsOneWidget);
          expect(
            tester.widget<RoundScreen>(find.byType(RoundScreen)).previewMode,
            isTrue,
          );
          expect(find.byType(ExerciseEditorScreen), findsNothing);
          expect(find.byType(ScriptRecognitionEditor), findsNothing);
          expect(find.byKey(const ValueKey('exercise-save')), findsNothing);
          expect(await workflow.preferences(), beforePrefs);
          expect(jsonEncode(course.toJson()), beforeCourse);
          expect(
            await service.listUserCourses(),
            origin == CourseOriginType.externalOfficial
                ? hasLength(1)
                : isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

void _expectNoAuthorControls() {
  expect(find.byType(ExerciseEditorScreen), findsNothing);
  expect(find.byType(ScriptRecognitionEditor), findsNothing);
  expect(find.byType(TextField), findsNothing);
  expect(find.byType(TextFormField), findsNothing);
  for (final key in [
    'script-mode',
    'script-add-option',
    'script-add-prompt-image',
    'exercise-save',
    'exercise-save-draft',
    'exercise-preset-selector',
  ]) {
    expect(find.byKey(ValueKey(key)), findsNothing);
  }
  for (final label in [
    'Expand answers',
    'Use expanded answers',
    'Add answer option',
    'Save',
    'Save as draft',
  ]) {
    expect(find.text(label), findsNothing);
  }
}

Course _official(CourseOriginType origin, String preset) {
  final exercise = Exercise.v2(
    id: 'exercise',
    editorTemplate: preset,
    updatedAt: DateTime.utc(2026, 9, 6),
    promptElements: preset == 'script_recognition'
        ? const [
            PromptElement(
              type: 'image',
              asset: 'assets/exercise_images/apple.webp',
            ),
          ]
        : [
            PromptElement(
              type: 'text',
              text: preset == 'type_missing_word'
                  ? 'Eat an ____.'
                  : 'Translate: apple',
            ),
          ],
    interaction: preset == 'script_recognition'
        ? const ExerciseInteraction(
            kind: 'select',
            items: [
              ExerciseItem(
                id: 'apple',
                content: [PromptElement(type: 'text', text: 'apple')],
              ),
              ExerciseItem(
                id: 'bread',
                content: [PromptElement(type: 'text', text: 'bread')],
              ),
            ],
          )
        : const ExerciseInteraction(kind: 'input'),
    evaluation: preset == 'script_recognition'
        ? const ExerciseEvaluation(
            kind: 'selected_items',
            correctItemIds: ['apple'],
          )
        : ExerciseEvaluation(
            kind: 'text_match',
            accepted: preset == 'type_translation'
                ? const ['(an) apple', 'fruit']
                : const ['apple'],
          ),
  );
  final course = Course(
    courseId: 'official-$preset',
    originType: origin,
    publisherId: 'original-publisher',
    publisherName: 'Original Publisher',
    officialCourseVersion: '1',
    officialReleaseDateUtc: '2026-09-06T00:00:00.000Z',
    officialChecksum: '0' * 64,
    distributionChannel: origin == CourseOriginType.bundledOfficial
        ? 'app'
        : 'package',
    learningLanguage: 'English',
    interfaceLanguage: 'Italian',
    sourceLanguage: 'Italian',
    targetLanguage: 'English',
    title: 'Official $preset',
    ttsLanguage: 'en-US',
    version: '1',
    authors: const [
      CourseAuthor(name: 'Original Author', roles: ['Course Creator']),
    ],
    license: 'Publisher content license',
    derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
    lessons: [
      Lesson(
        lessonId: 'lesson',
        title: 'Publisher Lesson',
        updatedAt: DateTime.utc(2026, 9, 6),
        rounds: [
          LearningRound(
            id: 'round',
            title: 'Publisher Round',
            updatedAt: DateTime.utc(2026, 9, 6),
            exercises: [exercise],
          ),
        ],
      ),
    ],
  );
  return Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(course),
  });
}

class _OfficialSource extends CourseService {
  _OfficialSource(this.course);
  final Course course;
  @override
  Future<Course> loadBundledCourse(String languageCode) async => course;
}

class _ReadOnlyBackups extends CourseBackupService {
  @override
  Future<Directory> courseBackupDirectory(
    String courseId, {
    bool create = false,
  }) async =>
      Directory('${Directory.systemTemp.path}/qql_22603_readonly_ui/$courseId');
  @override
  Future<List<CourseBackupRecord>> listOfficialBackups(String courseId) async =>
      [];
  @override
  Future<List<CourseBackupRecord>> listBackups(String courseId) async => [];
}

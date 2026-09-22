import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';

class _PackageMergeService extends CourseMergeService {
  _PackageMergeService(this.package);

  final CoursePackage package;

  @override
  Future<CoursePackage> readMergePackage() async => package;

  @override
  bool get fileDialogsAvailable => false;
}

Course _course(String id) => Course(
  courseId: id,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'English for Italian speakers',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: '$id-lesson',
      updatedAt: DateTime.utc(2026, 9, 22),
      title: 'Greetings',
      rounds: const [],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Merge keeps one submission active until right-package cleanup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final right = _course('right');
    final package = CoursePackage(right, Uint8List(0), const {});
    final firstEntered = Completer<void>();
    final finishMerge = Completer<void>();
    var submissions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: CourseMergeScreen(
          leftCourse: _course('left'),
          mergeService: _PackageMergeService(package),
          onMerge: (right, choices, options) async {
            submissions++;
            if (!firstEntered.isCompleted) firstEntered.complete();
            await finishMerge.future;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('merge-course-json-primary')));
    await tester.pump();
    await tester.tap(find.text('Select all Right'));
    await tester.pump();

    final mergeButton = find.widgetWithText(FilledButton, 'DO MERGE!');
    await tester.ensureVisible(mergeButton);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(mergeButton).onPressed, isNotNull);
    await tester.tap(mergeButton);
    await tester.tap(mergeButton);
    await tester.pump();
    await tester.pump();
    expect(submissions, 1);
    expect(tester.widget<FilledButton>(mergeButton).onPressed, isNull);

    await tester.tap(mergeButton);
    await tester.pump();
    expect(submissions, 1);

    finishMerge.complete();
    await tester.pump();
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home owns the Lesson, Round-tree, and Duel learner flow directly', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(source, contains('class _SectionNavigation'));
    expect(source, isNot(contains('class _LessonNavigation')));
    expect(source, contains('class LearnerRoundPath'));
    expect(source, contains('class _DuelCard'));
    expect(source, contains('course.lessons'));
    expect(source, contains('RoundScreen('));
    expect(source, contains('DuelScreen('));
    expect(source, isNot(contains('ChaptersScreen')));
    expect(source, isNot(contains('ChapterScreen')));
    expect(source, isNot(contains('LessonScreen')));
  });

  test(
    'old between-Round Lesson imagery and removed hello asset stay retired',
    () {
      final source = File('lib/screens/home_screen.dart').readAsStringSync();

      expect(source, isNot(contains('class _LessonImage')));
      expect(source, isNot(contains('lesson.imageAsset')));
      expect(File('assets/exercise_images/hello.webp').existsSync(), isFalse);
      expect(File('assets/exercize_images/hello.welp').existsSync(), isFalse);

      for (final path in ['lib/screens/home_screen.dart', 'pubspec.yaml']) {
        final contents = File(path).readAsStringSync();
        expect(contents, isNot(contains('hello.webp')), reason: path);
        expect(contents, isNot(contains('hello.welp')), reason: path);
      }

      final pubspec = File(
        'pubspec.yaml',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(pubspec, contains('    - assets/mascots/\n'));
      final mascotFiles =
          Directory('assets/mascots')
              .listSync()
              .whereType<File>()
              .map((file) => file.uri.pathSegments.last)
              .toList()
            ..sort();
      expect(mascotFiles, isNotEmpty);
      expect(mascotFiles, everyElement(endsWith('.png')));
    },
  );

  test('obsolete Lesson image and Settings IDDQD controls stay removed', () {
    final model = File('lib/models/course_models.dart').readAsStringSync();
    final editor = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/screens/settings_screen.dart',
    ).readAsStringSync();

    final lessonModel = model.substring(
      model.indexOf('class Lesson {'),
      model.indexOf('class LearningRound {'),
    );
    expect(lessonModel, isNot(contains('final String? imageAsset;')));
    expect(lessonModel, isNot(contains("if (imageAsset != null) 'imageAsset'")));
    expect(lessonModel, contains("j.containsKey('imageAsset')"));
    expect(model, contains('String get imageAsset =>'));
    expect(editor, isNot(contains("title: const Text('Lesson image')")));
    expect(
      settings,
      isNot(contains('IDDQD Mode (you can walk through locks)')),
    );
  });

  test('removed hierarchy screens are not retained as learner fallbacks', () {
    for (final path in [
      'lib/screens/course_entry_screen.dart',
      'lib/screens/chapters_screen.dart',
      'lib/screens/chapter_screen.dart',
      'lib/screens/lesson_screen.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}

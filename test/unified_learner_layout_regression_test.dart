import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home owns the Lesson, Round-tree, and Duel learner flow directly', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(source, contains('class _LessonNavigation'));
    expect(source, contains('class LearnerRoundPath'));
    expect(source, contains('class _DuelCard'));
    expect(source, contains('course.topics'));
    expect(source, contains('RoundScreen('));
    expect(source, contains('DuelScreen('));
    expect(source, isNot(contains('ChaptersScreen')));
    expect(source, isNot(contains('ChapterScreen')));
    expect(source, isNot(contains('TopicScreen')));
  });

  test(
    'old between-Round Lesson imagery and removed hello asset stay retired',
    () {
      final source = File('lib/screens/home_screen.dart').readAsStringSync();

      expect(source, isNot(contains('class _TopicImage')));
      expect(source, isNot(contains('topic.imageAsset')));
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

  test('removed hierarchy screens are not retained as learner fallbacks', () {
    for (final path in [
      'lib/screens/course_entry_screen.dart',
      'lib/screens/chapters_screen.dart',
      'lib/screens/chapter_screen.dart',
      'lib/screens/topic_screen.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}

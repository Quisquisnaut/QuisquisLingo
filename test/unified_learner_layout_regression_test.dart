import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home owns the Lesson, Round-tree, and Duel learner flow directly', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();

    expect(source, contains('class _LessonNavigation'));
    expect(source, contains('class _RoundTree'));
    expect(source, contains('class _DuelCard'));
    expect(source, contains('course.topics'));
    expect(source, contains('RoundScreen('));
    expect(source, contains('DuelScreen('));
    expect(source, isNot(contains('ChaptersScreen')));
    expect(source, isNot(contains('ChapterScreen')));
    expect(source, isNot(contains('TopicScreen')));
  });

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

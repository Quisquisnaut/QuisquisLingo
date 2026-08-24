import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Course Info avoids intrinsic LayoutBuilder conflict', () {
    final source = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), '');
    final start = source.indexOf(
      "finalnarrowCourseInfo=MediaQuery.sizeOf(context).width<560;",
    );
    final end = source.indexOf('Future<void>_addChapter()', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final courseInfo = source.substring(start, end);
    expect(courseInfo.contains('LayoutBuilder('), isFalse);
    expect(courseInfo.contains('for(finalcinnames){'), isTrue);
    expect(courseInfo.contains('for(finalcincustomRoles){'), isTrue);
  });
}

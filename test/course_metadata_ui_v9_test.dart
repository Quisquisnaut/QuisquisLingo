import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Create Course exposes structured Rights Holder editing', () {
    final source = File(
      'lib/screens/course_projects_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'License / Rights'"));
    expect(
      RegExp(r"ValueKey\(\s*'new-course-rights-holder-name-").hasMatch(source),
      isTrue,
    );
    expect(source, contains('CourseRightsHolder('));
    expect(source, contains('rightsHolders: rightsHolders'));
  });

  test('Course Info Editor edits structured Rights Holders', () {
    final source = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'License / Rights'"));
    expect(
      RegExp(r"ValueKey\(\s*'course-info-rights-holder-name-").hasMatch(source),
      isTrue,
    );
    expect(source, contains('List<CourseRightsHolder> rightsHolders'));
    expect(
      RegExp(
        r"'rightsHolders': result\.rightsHolders\s*\.map\(\(holder\) => holder\.toJson\(\)\)",
      ).hasMatch(source),
      isTrue,
    );
  });
}

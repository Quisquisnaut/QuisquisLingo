import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_draft_status.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';

import 'support/course_library_fixtures.dart';

const _draft = PublicationState.draft;

void main() {
  test('a fully published hierarchy has no Draft', () {
    expect(CourseDraftStatus.courseHasDraft(draftStatusCourse()), isFalse);
  });

  test('Draft at any level marks the Course', () {
    for (final course in [
      draftStatusCourse(lesson: _draft),
      draftStatusCourse(round: _draft),
      draftStatusCourse(exercise: _draft),
      draftStatusCourse(guidebook: _draft),
    ]) {
      expect(CourseDraftStatus.courseHasDraft(course), isTrue);
    }
  });

  test('a Draft GuideBook does not count while GuideBook is off', () {
    final course = draftStatusCourse(guidebook: _draft, useGuidebook: false);
    expect(CourseDraftStatus.courseHasDraft(course), isFalse);
  });

  test('the Editor hierarchy status delegates to the same rule', () {
    for (final course in [
      draftStatusCourse(),
      draftStatusCourse(exercise: _draft),
      draftStatusCourse(guidebook: _draft, useGuidebook: false),
    ]) {
      expect(
        AuthoringHierarchyStatus.fromCourse(course).courseHasDraft,
        CourseDraftStatus.courseHasDraft(course),
      );
    }
  });
}

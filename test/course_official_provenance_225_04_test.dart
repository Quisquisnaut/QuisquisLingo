import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled sources have verified immutable provenance', () async {
    // No Course comes with the app since Build 272 Revision 17 (owner
    // decision of 13 October 2026). The Laboratory's file keeps its
    // bundled shape: it is the source of Fill with an example and, for the
    // tests, the bundled test Course the test configuration registers.
    expect(CourseService.courseAssets, isEmpty);
    expect(CourseService.bundledAssets, hasLength(1));
    final mismatches = <String, String>{};
    final titles = <String>{};
    for (final entry in CourseService.bundledAssets.entries) {
      final raw = jsonDecode(await rootBundle.loadString(entry.value));
      final course = Course.fromJson(Map<String, dynamic>.from(raw as Map));
      expect(course.originType, CourseOriginType.bundledOfficial);
      // Not a Private course (Build 259 Revision 8).
      expect(course.temporarySample, isFalse);
      // Build 272 Revision 17 (owner decision): QQL Test: ….
      expect(course.title, startsWith('QQL Test: '));
      titles.add(course.title);
      expect(course.publisherId, 'org.quisquislingo');
      expect(
        course.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      final calculated = CourseBackupService.officialContentChecksum(course);
      if (course.officialChecksum != calculated) {
        mismatches[entry.key] = calculated;
      }
    }
    expect(mismatches, isEmpty, reason: 'bundled checksum mismatches');
    expect(titles, {'QQL Test: En-It Exercise Lab'});
    for (final entry in CourseService.bundledAssets.entries) {
      expect(
        (await CourseService().loadBundledCourse(entry.key)).courseId,
        isNotEmpty,
      );
    }
  });

  // Build 255 Revision 6: every demo is All rights reserved. Only the test
  // demos keep derivative works allowed, so they can still be forked (the
  // Edge Case, imported since Build 259 Revision 5, too).
  test(
    'bundled demos are All rights reserved; only test demos allow Fork',
    () async {
      const derivatives = {'IT': DerivativeWorksPolicy.allowed};
      expect(
        CourseService.bundledAssets.keys,
        unorderedEquals(derivatives.keys),
      );
      for (final entry in derivatives.entries) {
        final course = await CourseService().loadBundledCourse(entry.key);
        expect(course.license, 'All rights reserved', reason: entry.key);
        expect(course.derivativeWorksPolicy, entry.value, reason: entry.key);
      }
    },
  );
}

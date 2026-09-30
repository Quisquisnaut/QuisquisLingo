import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both bundled sources have verified immutable provenance', () async {
    // The Edge Case left the bundle in Build 259 Revision 5.
    expect(CourseService.courseAssets, hasLength(2));
    final mismatches = <String, String>{};
    final titles = <String>{};
    for (final entry in CourseService.courseAssets.entries) {
      final raw = jsonDecode(await rootBundle.loadString(entry.value));
      final course = Course.fromJson(Map<String, dynamic>.from(raw as Map));
      expect(course.originType, CourseOriginType.bundledOfficial);
      expect(course.temporarySample, isTrue);
      expect(course.title, startsWith('Temporary Demo: '));
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
    expect(titles, {
      'Temporary Demo: Piedmontese',
      'Temporary Demo: Exercise Laboratory',
    });
    for (final entry in CourseService.courseAssets.entries) {
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
      const derivatives = {
        'IT': DerivativeWorksPolicy.allowed,
        'PMS': DerivativeWorksPolicy.forbidden,
      };
      expect(
        CourseService.courseAssets.keys,
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

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all nine bundled sources have verified immutable provenance', () async {
    expect(CourseService.courseAssets, hasLength(9));
    final mismatches = <String, String>{};
    for (final entry in CourseService.courseAssets.entries) {
      final raw = jsonDecode(await rootBundle.loadString(entry.value));
      final course = Course.fromJson(Map<String, dynamic>.from(raw as Map));
      expect(course.originType, CourseOriginType.bundledOfficial);
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
    for (final entry in CourseService.courseAssets.entries) {
      expect(
        (await CourseService().loadBundledCourse(entry.key)).courseId,
        isNotEmpty,
      );
    }
  });
}

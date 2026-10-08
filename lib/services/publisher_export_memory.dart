import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'publisher_course_export.dart';

/// The publisher a Course was last exported for with Export as Publisher
/// Course (owner request of 4 October 2026: remember it, so an update goes
/// out with the same publisher ID and name). One device-level key per Course
/// ID, written after a successful export and never into the Course file;
/// removed when the Course is deleted, by the custom-course reset and by
/// Wipe everything.
class PublisherExportMemory {
  static const keyPrefix = 'qql_publisher_export_';

  static String keyForCourseId(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  /// The publisher [courseId] was last exported for, or null when there is
  /// none or the stored value is not usable.
  Future<PublisherIdentity?> recall(String courseId) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      keyForCourseId(courseId),
    );
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final id = json['publisherId'];
      final name = json['publisherName'];
      if (id is! String || name is! String) return null;
      return PublisherCourseExport.identity(id, name);
    } on FormatException {
      return null;
    }
  }

  Future<void> remember(String courseId, PublisherIdentity publisher) async {
    await (await SharedPreferences.getInstance()).setString(
      keyForCourseId(courseId),
      jsonEncode({
        'publisherId': publisher.publisherId,
        'publisherName': publisher.publisherName,
      }),
    );
  }

  Future<void> forget(String courseId) async {
    await (await SharedPreferences.getInstance()).remove(
      keyForCourseId(courseId),
    );
  }
}

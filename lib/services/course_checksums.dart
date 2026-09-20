import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/course_models.dart';

/// QQL model-normalized JSON, not RFC 8785/JCS.
class CourseChecksums {
  static String whole(Course course) => _digest(course.toJson());

  static String official(Course course) => _digest(
    Map<String, dynamic>.from(course.toJson())
      ..remove('officialChecksum')
      ..remove('publisherVerificationStatus')
      ..remove('publisherSignature'),
  );

  static String _digest(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

  static Object? _canonical(Object? value) => switch (value) {
    Map() => SplayTreeMap<String, Object?>.from({
      for (final entry in value.entries)
        entry.key.toString(): _canonical(entry.value),
    }),
    List() => value.map(_canonical).toList(growable: false),
    _ => value,
  };
}

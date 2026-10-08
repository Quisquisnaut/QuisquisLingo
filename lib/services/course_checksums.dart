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

  /// Older official Courses were signed before Round types and numbering
  /// were serialized. Accept that exact older shape only when the synthesized
  /// values still equal the values migration would assign.
  static bool officialMatches(Course course) {
    if (official(course) == course.officialChecksum) return true;
    if (course.roundNumberingMode != RoundNumberingMode.off) return false;
    final legacy = Map<String, dynamic>.from(course.toJson())
      ..remove('officialChecksum')
      ..remove('publisherVerificationStatus')
      ..remove('publisherSignature')
      ..remove('roundNumberingMode');
    for (final lesson in legacy['lessons'] as List) {
      for (final round in (lesson as Map<String, dynamic>)['rounds'] as List) {
        final value = round as Map<String, dynamic>;
        final migrated = Map<String, dynamic>.from(value)
          ..remove('roundType')
          ..remove('testFixedOrder')
          ..remove('testPassingPercent');
        if (LearningRound.fromJson(migrated).roundType.name !=
            value['roundType']) {
          return false;
        }
        value.remove('roundType');
      }
    }
    return _digest(legacy) == course.officialChecksum;
  }

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

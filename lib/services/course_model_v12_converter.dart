import 'dart:convert';

import '../models/course_models.dart';
import 'course_checksums.dart';

/// Converts a Course Model v11 JSON object to Course Model v12 (Build 256).
///
/// The application never converts: v11 files are refused and stay
/// untouched. This library is used by `tools/convert_course_to_v12.dart`
/// and `tools/convert_stored_courses_256.dart`, and it must stay free of
/// Flutter imports so `dart run` can load it. The exercise mapping itself
/// is `Exercise.convertV11`, the same one the in-memory `Exercise.v2`
/// constructor uses, so a converted file and an exercise the Course Editor
/// still builds through the v11 shape agree exactly.
///
/// The input is never modified. Everything the mapping cannot carry over
/// exactly is listed in [CourseConversionResult.notes]. A Publisher Course
/// loses its signature (sign the result again with `tools/sign_course.dart`)
/// and an official Course gets a new `officialChecksum`.
class CourseConversionResult {
  const CourseConversionResult({required this.json, required this.notes});

  /// The v12 Course, proven to load with `Course.fromJson`.
  final Map<String, dynamic> json;

  /// Plain-language notes about anything that was not converted exactly.
  final List<String> notes;
}

CourseConversionResult convertCourseJsonToV12(Map<String, dynamic> source) {
  final json = Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
  final version = json['formatVersion'];
  if (version == Course.currentFormatVersion) {
    throw const FormatException('The Course is already Course Model v12.');
  }
  if (version != 11) {
    throw FormatException(
      'Only Course Model v11 can be converted to v12, not formatVersion '
      '${version ?? 'missing'}. Convert an older file to v11 first with '
      'tools/convert_course_to_v11.dart.',
    );
  }
  final notes = <String>[];
  json['formatVersion'] = Course.currentFormatVersion;

  final lessons = json['lessons'];
  if (lessons is! List) {
    throw const FormatException('course.lessons must be a list.');
  }
  for (var l = 0; l < lessons.length; l++) {
    final lesson = lessons[l];
    if (lesson is! Map) continue;
    final where = 'lesson ${lesson['lessonId'] ?? l + 1}';
    final guidebook = lesson['guidebook'];
    if (guidebook is Map && guidebook['content'] is List) {
      guidebook['content'] = [
        for (final content in guidebook['content'] as List)
          if (content is Map)
            _convertContent(
              Map<String, dynamic>.from(content),
              '$where GuideBook',
              notes,
            )
          else
            content,
      ];
    }
    final rounds = lesson['rounds'];
    if (rounds is! List) continue;
    for (var r = 0; r < rounds.length; r++) {
      final round = rounds[r];
      if (round is! Map || round['content'] is! List) continue;
      round['content'] = [
        for (final content in round['content'] as List)
          if (content is Map)
            _convertContent(
              Map<String, dynamic>.from(content),
              '$where Round ${round['id'] ?? r + 1}',
              notes,
              fallbackUpdatedAt: round['updatedAt'],
            )
          else
            content,
      ];
    }
  }

  final origin = json['originType'];
  final official =
      origin == CourseOriginType.bundledOfficial.name ||
      origin == CourseOriginType.externalOfficial.name;
  if (origin == CourseOriginType.externalOfficial.name) {
    if (json.remove('publisherSignature') != null) {
      notes.add(
        'The Publisher signature was removed: sign the result again with tools/sign_course.dart.',
      );
    }
    json['publisherVerificationStatus'] =
        PublisherVerificationStatus.unverified.name;
  }
  if (official) {
    json['officialChecksum'] = CourseChecksums.official(Course.fromJson(json));
  }
  // Final proof that the result is a valid v12 Course.
  Course.fromJson(json);
  return CourseConversionResult(json: json, notes: notes);
}

Map<String, dynamic> _convertContent(
  Map<String, dynamic> content,
  String where,
  List<String> notes, {
  Object? fallbackUpdatedAt,
}) {
  final out = Map<String, dynamic>.from(content);
  final id = '${out['id'] ?? '?'}';
  final template = out.remove('editorTemplate');
  final preset = template is String ? template.trim() : '';
  if (template != null && template is! String) {
    notes.add('$where $id: editorTemplate was not a string and was dropped.');
  }
  final existing = out['authoringMetadata'];
  final metadata = <String, Object?>{
    if (existing is Map)
      for (final entry in existing.entries) entry.key.toString(): entry.value,
    if (preset.isNotEmpty) 'presetId': preset,
  };
  out.remove('authoringMetadata');
  if (metadata.isNotEmpty) out['authoringMetadata'] = metadata;

  final publicationState = PublicationState.parseRequired(out, 'content');
  final rawPresentation = out['presentation'];
  if (out['kind'] == 'presentation' || rawPresentation != null) {
    if (rawPresentation is! Map) {
      throw FormatException(
        '$where $id: presentation Content needs a presentation object.',
      );
    }
    final presentation = Presentation.fromJson(
      Map<String, dynamic>.from(rawPresentation),
    );
    final exerciseMetadata = <String, Object?>{
      if (metadata.isEmpty) 'presetId': 'flashcard',
      ...metadata,
    };
    // A v11 presentation has no timestamp of its own; its Round's serves.
    final exercise = presentation.toExercise(
      id: id,
      publicationState: publicationState,
      updatedAt: fallbackUpdatedAt is String
          ? DateTime.tryParse(fallbackUpdatedAt)?.toUtc()
          : null,
      authoringMetadata: exerciseMetadata,
    );
    if (presentation.completionMode != CompletionMode.understoodReview) {
      notes.add(
        '$where $id: presentation actions ${presentation.actions} became completionMode ${presentation.completionMode.serialized}.',
      );
    }
    out.remove('presentation');
    out['kind'] = 'exercise';
    out['authoringMetadata'] = exerciseMetadata;
    out['exercise'] = exercise.toJson();
    return out;
  }

  final rawExercise = out['exercise'];
  if (rawExercise is! Map) return out;
  final ex = Map<String, dynamic>.from(rawExercise);
  final p = ex['prompt'];
  final i = ex['interaction'];
  final e = ex['evaluation'];
  if (p is! List || i is! Map || e is! Map) {
    throw FormatException(
      '$where $id: a v11 exercise needs prompt[], interaction and evaluation.',
    );
  }
  final rawUpdated = ex['updatedAt'];
  if (rawUpdated is! String) {
    throw FormatException('$where $id: exercise.updatedAt is missing.');
  }
  final updatedAt = DateTime.tryParse(rawUpdated);
  if (updatedAt == null) {
    throw FormatException('$where $id: exercise.updatedAt is not a timestamp.');
  }
  final rawFeedback = ex['feedback'];
  var feedback = ExerciseFeedback.empty;
  if (rawFeedback is Map) {
    final unknown = rawFeedback.keys
        .where((key) => key != 'correct' && key != 'incorrect')
        .toList();
    if (unknown.isNotEmpty) {
      notes.add(
        '$where $id: feedback keys ${unknown.join(', ')} have no v12 form and were dropped.',
      );
    }
    feedback = ExerciseFeedback(
      correct: '${rawFeedback['correct'] ?? ''}',
      incorrect: '${rawFeedback['incorrect'] ?? ''}',
    );
  }
  final conversion = Exercise.convertV11(
    id: id,
    publicationState: publicationState,
    updatedAt: updatedAt.toUtc(),
    editorTemplate: preset,
    promptElements: [
      for (final element in p)
        if (element is Map)
          PromptElement.fromJson(Map<String, dynamic>.from(element))
        else
          throw FormatException('$where $id: prompt contains a non-object.'),
    ],
    interaction: ExerciseInteraction.fromJson(Map<String, dynamic>.from(i)),
    evaluation: ExerciseEvaluation.fromJson(Map<String, dynamic>.from(e)),
    hint: '${ex['hint'] ?? ''}',
    feedback: feedback,
    missingWords: [
      if (ex['missingWords'] is List)
        for (final word in ex['missingWords'] as List) '$word',
    ],
    authoringMetadata: metadata,
  );
  for (final note in conversion.notes) {
    notes.add('$where $note');
  }
  final unknown = ex.keys
      .where(
        (key) => !const {
          'updatedAt',
          'prompt',
          'interaction',
          'evaluation',
          'hint',
          'feedback',
          'missingWords',
        }.contains(key),
      )
      .toList();
  if (unknown.isNotEmpty) {
    notes.add(
      '$where $id: exercise fields ${unknown.join(', ')} have no v12 form and were dropped.',
    );
  }
  final converted = conversion.exercise;
  if (converted.authoringMetadata.isNotEmpty) {
    out['authoringMetadata'] = converted.authoringMetadata;
  }
  out['exercise'] = converted.toJson();
  return out;
}

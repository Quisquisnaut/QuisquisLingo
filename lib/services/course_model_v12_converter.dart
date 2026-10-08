import 'dart:convert';

import '../models/course_models.dart';
import '../models/guidebook_text.dart';
import 'course_checksums.dart';
import 'guidebook_vocabulary.dart';
import '../models/preset_successors.dart';

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
    if (guidebook is Map) {
      lesson['guidebook'] = _convertGuidebook(
        Map<String, dynamic>.from(guidebook),
        '${lesson['lessonId'] ?? 'lesson_${l + 1}'}',
        '$where GuideBook',
        notes,
      );
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

/// Build 266 (GuideBook Modules): a v11 GuideBook becomes one module titled
/// "Module 1", listed in the notes so the author renames it. The overview,
/// then goals, grammar notes and Insights become paragraphs of its
/// Overview; vocabulary lines are split into Words & Expressions. Examples
/// and expressions have no translation, and a Sentence needs one, so they
/// become lines of the Overview, as does a vocabulary line that cannot be
/// split (owner decision of 8 October 2026: nothing is lost).
Map<String, dynamic> _convertGuidebook(
  Map<String, dynamic> guidebook,
  String lessonId,
  String where,
  List<String> notes,
) {
  var draft = guidebook['publicationState'] == 'draft';
  final overviews = <String>[];
  final goals = <String>[];
  final explanations = <String>[];
  final lines = <String>[];
  final words = <Map<String, dynamic>>[];
  final ids = <String>{};
  var examples = 0;
  var unsplit = 0;
  var dropped = 0;
  var draftItems = 0;
  var refs = 0;
  final content = guidebook['content'];
  for (final item
      in content is List ? content.whereType<Map>() : const <Map>[]) {
    final kind = item['kind'];
    final role = item['role'];
    final rawText = item['text'];
    final text = rawText is String ? rawText.trim() : '';
    if (item['publicationState'] == 'draft') draftItems++;
    final sourceRefs = item['sourceRefs'];
    if (sourceRefs is List && sourceRefs.isNotEmpty) refs++;
    if (text.isEmpty && kind != 'exercise' && kind != 'presentation') continue;
    switch (kind) {
      case 'explanation' when role == 'overview':
        overviews.add(text);
      case 'text' when role == 'goal':
        goals.add(text);
      case 'explanation' || 'text':
        explanations.add(text);
      case 'vocabulary':
        final pair = GuidebookVocabulary.parse(text);
        final id = '${item['id'] ?? ''}'.trim();
        if (pair == null ||
            GuidebookText.targetProblem(pair.target) != null ||
            id.isEmpty ||
            !ids.add(id)) {
          lines.add(text);
          unsplit++;
        } else {
          words.add({'id': id, 'target': pair.target, 'source': pair.source});
        }
      case 'example':
        lines.add(text);
        examples++;
      default:
        dropped++;
    }
  }
  final insights = guidebook['insights'];
  final insightParagraphs = [
    for (final insight
        in insights is List ? insights.whereType<Map>() : const <Map>[])
      [
        '${insight['title'] ?? ''}'.trim(),
        '${insight['text'] ?? ''}'.trim(),
      ].where((part) => part.isNotEmpty).join('\n'),
  ].where((paragraph) => paragraph.isNotEmpty);
  final overview = [
    ...overviews,
    ...goals,
    ...explanations,
    ...insightParagraphs,
    if (lines.isNotEmpty) lines.join('\n'),
  ].join('\n\n');
  final modules = <Map<String, dynamic>>[
    if (overview.isNotEmpty || words.isNotEmpty)
      {
        'id': '${lessonId}_module_1',
        'title': 'Module 1',
        'sentences': <Map<String, dynamic>>[],
        'words': words,
        'overview': overview,
      },
  ];
  if (modules.isNotEmpty) {
    notes.add(
      '$where became one module titled “Module 1”: rename it, and split it '
      'into shorter modules if it holds several topics.',
    );
  }
  if (examples > 0) {
    notes.add(
      '$where: $examples example ${examples == 1 ? 'sentence has' : 'sentences have'} '
      'no translation, so ${examples == 1 ? 'it is' : 'they are'} in the '
      'Overview of “Module 1”: move each to Sentences with its translation.',
    );
  }
  if (unsplit > 0) {
    notes.add(
      '$where: $unsplit vocabulary ${unsplit == 1 ? 'line' : 'lines'} could '
      'not be read as “target = source” and ${unsplit == 1 ? 'is' : 'are'} '
      'in the Overview of “Module 1”: add ${unsplit == 1 ? 'it' : 'them'} '
      'to Words & Expressions.',
    );
  }
  if (dropped > 0) {
    notes.add(
      '$where: $dropped ${dropped == 1 ? 'item' : 'items'} (exercises or '
      'cards) cannot be part of a GuideBook and ${dropped == 1 ? 'was' : 'were'} '
      'not converted.',
    );
  }
  if (refs > 0) {
    notes.add(
      '$where: GuideBook entries have no sourceRefs; $refs '
      '${refs == 1 ? 'reference was' : 'references were'} dropped.',
    );
  }
  if (draftItems > 0 && !draft) {
    draft = true;
    notes.add(
      '$where had Draft entries; a GuideBook is Draft or Published as a '
      'whole, so it is now a Draft: publish it once it is ready.',
    );
  }
  return {if (draft) 'publicationState': 'draft', 'modules': modules};
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
    if (preset.isNotEmpty) 'presetId': presetSuccessorOf[preset] ?? preset,
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
    // A `["continue"]` card is the proceed mode itself: nothing to report.
    final lossless =
        presentation.actions.join(',') ==
        Presentation.fromExercise(exercise).actions.join(',');
    if (presentation.completionMode != CompletionMode.understoodReview &&
        !lossless) {
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

  // Build 257: a v11 Lesson introduction (text Content with role
  // lesson_intro) becomes a Before you start card offering the GuideBook,
  // as the note did; v12 shows no other introduction.
  final introText = out['text'];
  if (out['role'] == 'lesson_intro' &&
      out['exercise'] == null &&
      introText is String) {
    final cardMetadata = <String, Object?>{
      ...metadata,
      'presetId': 'before_you_start',
    };
    final card = Exercise.beforeYouStart(
      id: id,
      publicationState: publicationState,
      updatedAt: fallbackUpdatedAt is String
          ? DateTime.tryParse(fallbackUpdatedAt)?.toUtc()
          : null,
      text: introText,
      guidebookButton: true,
      authoringMetadata: cardMetadata,
    );
    out
      ..remove('role')
      ..remove('text')
      ..['kind'] = 'exercise'
      ..['authoringMetadata'] = cardMetadata
      ..['exercise'] = card.toJson();
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

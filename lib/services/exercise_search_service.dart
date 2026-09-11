import '../models/course_models.dart';
import '../models/exercise_authoring.dart';

enum ExerciseSearchScope { course, lesson, round }

enum ExerciseSearchField {
  promptText('Prompt text'),
  promptAudio('Audio text'),
  promptSpeaker('Speaker'),
  interactionText('Answers and blocks'),
  acceptedAnswers('Accepted answers'),
  correctOrderText('Correct ordered answers'),
  hint('Hint'),
  missingWords('Missing words');

  const ExerciseSearchField(this.label);

  final String label;
}

class ExerciseTypeSearchDefinition {
  const ExerciseTypeSearchDefinition({
    required this.presetId,
    required this.fields,
  });

  final String presetId;
  final List<ExerciseSearchField> fields;

  String get displayName =>
      ExercisePresetRegistry.byId(presetId)?.name ?? presetId;
}

/// Authoritative searchable authored-text inventory for every supported preset.
///
/// Stable IDs are handled separately by [ExerciseSearchService]. Asset paths,
/// item IDs, correct indexes, publication state, normalization flags and other
/// internal configuration are intentionally absent from this registry.
abstract final class ExerciseSearchRegistry {
  static const _prompt = ExerciseSearchField.promptText;
  static const _audio = ExerciseSearchField.promptAudio;
  static const _speaker = ExerciseSearchField.promptSpeaker;
  static const _items = ExerciseSearchField.interactionText;
  static const _accepted = ExerciseSearchField.acceptedAnswers;
  static const _orders = ExerciseSearchField.correctOrderText;
  static const _hint = ExerciseSearchField.hint;
  static const _missing = ExerciseSearchField.missingWords;

  static const definitions = <ExerciseTypeSearchDefinition>[
    ExerciseTypeSearchDefinition(presetId: 'choice', fields: [_prompt, _items]),
    ExerciseTypeSearchDefinition(
      presetId: 'gap_choice',
      fields: [_prompt, _items, _hint],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'icon_choice',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'script_recognition',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'listening_choice',
      fields: [_audio, _prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'listening_comprehension',
      fields: [_audio, _prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'reading_comprehension',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'dialogue_response',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'contextual_comprehension',
      fields: [_prompt, _audio, _speaker, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'type_translation',
      fields: [_prompt, _accepted, _hint],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'build_translation',
      fields: [_prompt, _items, _orders],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'fill_blank',
      fields: [_prompt, _audio, _accepted, _hint],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'type_missing_word',
      fields: [_prompt, _accepted, _hint],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'listening_spelling',
      fields: [_prompt, _audio, _accepted],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'missing_word',
      fields: [_prompt, _audio, _missing],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'matching',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'word_match',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'super_match',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'audio_match',
      fields: [_prompt, _items],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'word_order',
      fields: [_prompt, _items, _orders],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'image_word',
      fields: [_prompt, _items, _orders],
    ),
    ExerciseTypeSearchDefinition(
      presetId: 'flashcard',
      fields: [_prompt, _audio],
    ),
  ];

  static ExerciseTypeSearchDefinition? forExercise(Exercise exercise) {
    final presetId =
        ExercisePresetRegistry.byId(exercise.editorTemplate) != null
        ? exercise.editorTemplate
        : exercise.type;
    return definitions
        .where((definition) => definition.presetId == presetId)
        .firstOrNull;
  }

  static List<ExerciseSearchText> searchableText(Exercise exercise) {
    final definition = forExercise(exercise);
    if (definition == null) return const [];
    final values = <ExerciseSearchText>[];
    for (final field in definition.fields) {
      final candidates = switch (field) {
        ExerciseSearchField.promptText =>
          exercise.promptElements
              .where((element) => element.type == 'text')
              .map((element) => element.text),
        ExerciseSearchField.promptAudio =>
          exercise.promptElements
              .where((element) => element.type == 'audio')
              .map((element) => element.text),
        ExerciseSearchField.promptSpeaker =>
          exercise.promptElements
              .where((element) => element.speaker.trim().isNotEmpty)
              .map((element) => element.speaker),
        ExerciseSearchField.interactionText =>
          exercise.interaction.items
              .expand((item) => item.content)
              .where((element) => element.text.trim().isNotEmpty)
              .map((element) => element.text),
        ExerciseSearchField.acceptedAnswers => exercise.evaluation.accepted,
        ExerciseSearchField.correctOrderText =>
          exercise.evaluation.correctOrders.map((answer) => answer.text),
        ExerciseSearchField.hint => [exercise.hint],
        ExerciseSearchField.missingWords => exercise.missingWords,
      };
      for (final candidate in candidates) {
        final text = candidate.trim();
        if (text.isEmpty ||
            values.any((value) => value.field == field && value.text == text)) {
          continue;
        }
        values.add(ExerciseSearchText(field: field, text: text));
      }
    }
    return List.unmodifiable(values);
  }
}

class ExerciseSearchText {
  const ExerciseSearchText({required this.field, required this.text});

  final ExerciseSearchField field;
  final String text;
}

class ExerciseSearchResult {
  const ExerciseSearchResult({
    required this.lessonIndex,
    required this.roundIndex,
    required this.exerciseIndex,
    required this.lessonId,
    required this.roundId,
    required this.exerciseId,
    required this.exerciseType,
    required this.exerciseDisplayName,
    required this.matchingExcerpt,
    required this.matchedFieldLabel,
    required this.idMatch,
  });

  final int lessonIndex;
  final int roundIndex;
  final int exerciseIndex;
  final String lessonId;
  final String roundId;
  final String exerciseId;
  final String exerciseType;
  final String exerciseDisplayName;
  final String matchingExcerpt;
  final String matchedFieldLabel;
  final bool idMatch;
}

class ExerciseSearchService {
  const ExerciseSearchService();

  List<ExerciseSearchResult> search(
    Course course, {
    required String query,
    ExerciseSearchScope scope = ExerciseSearchScope.course,
    String? lessonId,
    String? roundId,
    String? exerciseType,
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return const [];
    final results = <ExerciseSearchResult>[];
    for (
      var lessonIndex = 0;
      lessonIndex < course.lessons.length;
      lessonIndex++
    ) {
      final lesson = course.lessons[lessonIndex];
      if (scope != ExerciseSearchScope.course && lesson.lessonId != lessonId) {
        continue;
      }
      for (
        var roundIndex = 0;
        roundIndex < lesson.rounds.length;
        roundIndex++
      ) {
        final round = lesson.rounds[roundIndex];
        if (scope == ExerciseSearchScope.round && round.id != roundId) continue;
        for (
          var exerciseIndex = 0;
          exerciseIndex < round.exercises.length;
          exerciseIndex++
        ) {
          final exercise = round.exercises[exerciseIndex];
          final definition = ExerciseSearchRegistry.forExercise(exercise);
          if (definition == null ||
              (exerciseType != null &&
                  exerciseType.isNotEmpty &&
                  definition.presetId != exerciseType)) {
            continue;
          }
          final rawIdQuery = query.trim().toLowerCase();
          final idMatch =
              exercise.id.toLowerCase().contains(rawIdQuery) ||
              normalize(exercise.id)
                  .replaceAll(' ', '')
                  .contains(normalizedQuery.replaceAll(' ', ''));
          ExerciseSearchText? textMatch;
          if (!idMatch) {
            for (final authored in ExerciseSearchRegistry.searchableText(
              exercise,
            )) {
              if (_containsContiguousWords(authored.text, normalizedQuery)) {
                textMatch = authored;
                break;
              }
            }
          }
          if (!idMatch && textMatch == null) continue;
          results.add(
            ExerciseSearchResult(
              lessonIndex: lessonIndex,
              roundIndex: roundIndex,
              exerciseIndex: exerciseIndex,
              lessonId: lesson.lessonId,
              roundId: round.id,
              exerciseId: exercise.id,
              exerciseType: definition.presetId,
              exerciseDisplayName: definition.displayName,
              matchingExcerpt: idMatch
                  ? exercise.id
                  : _excerpt(textMatch!.text),
              matchedFieldLabel: idMatch
                  ? 'Exercise ID'
                  : textMatch!.field.label,
              idMatch: idMatch,
            ),
          );
        }
      }
    }
    return List.unmodifiable(results);
  }

  static bool _containsContiguousWords(String text, String normalizedQuery) {
    final haystack = normalize(text).split(' ');
    final needle = normalizedQuery.split(' ');
    if (needle.length > haystack.length) return false;
    for (var start = 0; start <= haystack.length - needle.length; start++) {
      var matches = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (haystack[start + offset] != needle[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  static String normalize(String value) {
    var normalized = value.toLowerCase();
    const folds = <String, String>{
      'a': 'àáâãäåāăąǎǟǡǻȁȃȧạảấầẩẫậắằẳẵặ',
      'c': 'çćĉċč',
      'd': 'ďđð',
      'e': 'èéêëēĕėęěȅȇẹẻẽếềểễệ',
      'f': 'ƒ',
      'g': 'ĝğġģǧǵ',
      'h': 'ĥħȟ',
      'i': 'ìíîïĩīĭįıǐȉȋịỉ',
      'j': 'ĵ',
      'k': 'ķǩ',
      'l': 'ĺļľŀł',
      'n': 'ñńņňŉŋǹ',
      'o': 'òóôõöøōŏőǒǫǭǿȍȏȯọỏốồổỗộớờởỡợ',
      'r': 'ŕŗřȑȓ',
      's': 'śŝşšș',
      't': 'ţťŧț',
      'u': 'ùúûüũūŭůűųǔǖǘǚǜȕȗụủứừửữự',
      'w': 'ŵẁẃẅ',
      'y': 'ýÿŷȳỳỵỷỹ',
      'z': 'źżž',
    };
    final buffer = StringBuffer();
    for (final rune in normalized.runes) {
      if (rune >= 0x0300 && rune <= 0x036f) continue;
      final character = String.fromCharCode(rune);
      if (const {'æ', 'ǽ', 'ǣ'}.contains(character)) {
        buffer.write('ae');
        continue;
      }
      if (character == 'œ') {
        buffer.write('oe');
        continue;
      }
      if (character == 'ß') {
        buffer.write('ss');
        continue;
      }
      var folded = character;
      for (final entry in folds.entries) {
        if (entry.value.contains(character)) {
          folded = entry.key;
          break;
        }
      }
      buffer.write(folded);
    }
    normalized = buffer.toString();
    return normalized
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _excerpt(String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return text.length <= 180 ? text : '${text.substring(0, 177)}…';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';

const _stamp = '2026-09-11T10:00:00.000Z';

Exercise _exercise(String type, String id) => Exercise.v2(
  id: id,
  updatedAt: DateTime.parse(_stamp),
  editorTemplate: type,
  promptElements: [
    PromptElement(type: 'text', text: '$type Prompt Marker'),
    PromptElement(type: 'audio', text: '$type Audio Marker'),
    PromptElement(
      role: 'dialogue_turn',
      type: 'text',
      text: '$type Dialogue Marker',
      speaker: '$type Speaker Marker',
    ),
    const PromptElement(type: 'image', asset: 'asset_internal_marker.png'),
  ],
  interaction: ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'item_internal_marker',
        content: [PromptElement(type: 'text', text: '$type Item Marker')],
      ),
    ],
  ),
  evaluation: ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: const ['correct_internal_marker'],
    accepted: ['$type Accepted Marker'],
    correctOrders: [
      OrderedAnswer(
        text: '$type Order Marker',
        itemIds: const ['item_internal_marker'],
      ),
    ],
    normalization: const {'private_internal_marker': true},
  ),
  hint: '$type Hint Marker',
  feedback: const {'incorrect': 'Feedback Internal Marker'},
  missingWords: ['$type Missing Marker'],
);

Course _inventoryCourse() {
  final source = _course();
  return Course.fromJson({
    ...source.toJson(),
    'lessons': [
      {
        ...source.lessons.first.toJson(),
        'rounds': [
          LearningRound(
            id: 'inventory_round',
            updatedAt: DateTime.parse(_stamp),
            title: 'Inventory',
            exercises: [
              for (final preset in ExercisePresetRegistry.presets)
                _exercise(preset.id, 'inventory_${preset.id}'),
            ],
          ).toJson(),
        ],
      },
    ],
  });
}

Course _course() => Course(
  courseId: 'search_course',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: '00000000-0000-4000-8000-000000000001',
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer('00000000-0000-4000-8000-000000000001'),
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Search course',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      updatedAt: DateTime.parse(_stamp),
      title: 'First',
      rounds: [
        LearningRound(
          id: 'round_one',
          updatedAt: DateTime.parse(_stamp),
          title: 'First round',
          exercises: [
            Exercise(
              id: 'EX-Àccent-123',
              updatedAt: DateTime.parse(_stamp),
              type: 'choice',
              prompt: 'Come stai oggi?',
              question: '',
              answers: const ['Bène davvero', 'Male'],
              correct: 0,
              tts: null,
              accepted: const [],
              tokens: const [],
              orderAnswer: const [],
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          ],
        ),
      ],
    ),
    Lesson(
      lessonId: 'lesson_two',
      updatedAt: DateTime.parse(_stamp),
      title: 'Second',
      rounds: [
        LearningRound(
          id: 'round_two',
          updatedAt: DateTime.parse(_stamp),
          title: 'Second round',
          exercises: [
            Exercise(
              id: 'other-456',
              updatedAt: DateTime.parse(_stamp),
              type: 'type_translation',
              prompt: 'Come non stai?',
              question: '',
              answers: const [],
              correct: null,
              tts: null,
              accepted: const ['Sto bene'],
              tokens: const [],
              orderAnswer: const [],
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  group('QQL 231 exercise type inventory', () {
    test('covers every supported preset and every preset has Help', () {
      expect(
        ExerciseSearchRegistry.definitions
            .map((entry) => entry.presetId)
            .toSet(),
        ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
      );
      expect(
        ExercisePresetRegistry.helpByPreset.keys.toSet(),
        ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
      );
    });

    test('each preset exposes only its declared authored text fields', () {
      for (final definition in ExerciseSearchRegistry.definitions) {
        final searchable = ExerciseSearchRegistry.searchableText(
          _exercise(definition.presetId, 'exercise_${definition.presetId}'),
        );
        final actual = searchable.map((entry) => entry.field).toSet();
        expect(actual, definition.fields.toSet(), reason: definition.presetId);
        expect(
          searchable.map((entry) => entry.text),
          isNot(contains('asset_internal_marker.png')),
          reason: definition.presetId,
        );
      }
    });

    test('Search reaches every intended field for every exercise type', () {
      final course = _inventoryCourse();
      const querySuffix = {
        ExerciseSearchField.promptText: 'prompt marker',
        ExerciseSearchField.promptAudio: 'audio marker',
        ExerciseSearchField.promptSpeaker: 'speaker marker',
        ExerciseSearchField.interactionText: 'item marker',
        ExerciseSearchField.acceptedAnswers: 'accepted marker',
        ExerciseSearchField.correctOrderText: 'order marker',
        ExerciseSearchField.hint: 'hint marker',
        ExerciseSearchField.missingWords: 'missing marker',
      };
      for (final definition in ExerciseSearchRegistry.definitions) {
        for (final field in definition.fields) {
          final matches = const ExerciseSearchService().search(
            course,
            query: '${definition.presetId} ${querySuffix[field]}',
            exerciseType: definition.presetId,
          );
          expect(
            matches,
            hasLength(1),
            reason: '${definition.presetId} $field',
          );
          expect(matches.single.exerciseId, 'inventory_${definition.presetId}');
        }
      }
    });

    test('internal configuration is never searchable', () {
      final course = Course.fromJson({
        ..._course().toJson(),
        'lessons': [
          {
            ..._course().lessons.first.toJson(),
            'rounds': [
              LearningRound(
                id: 'round_inventory',
                updatedAt: DateTime.parse(_stamp),
                title: 'Inventory',
                exercises: [_exercise('choice', 'inventory_exercise')],
              ).toJson(),
            ],
          },
        ],
      });
      for (final query in [
        'asset internal marker',
        'item internal marker',
        'correct internal marker',
        'private internal marker',
        'feedback internal marker',
      ]) {
        expect(
          const ExerciseSearchService().search(course, query: query),
          isEmpty,
          reason: query,
        );
      }
    });
  });

  group('QQL 231 matching and scope', () {
    const service = ExerciseSearchService();

    test('word and contiguous phrase matching ignore case and diacritics', () {
      expect(service.search(_course(), query: 'STAI'), hasLength(2));
      expect(service.search(_course(), query: 'come stai'), hasLength(1));
      expect(service.search(_course(), query: 'come non stai'), hasLength(1));
      expect(service.search(_course(), query: 'BENE DAVVERO'), hasLength(1));
    });

    test('exact and partial Exercise IDs match case-insensitively', () {
      expect(service.search(_course(), query: 'EX-Àccent-123'), hasLength(1));
      expect(service.search(_course(), query: 'àCCENT'), hasLength(1));
      expect(service.search(_course(), query: 'accent'), hasLength(1));
      expect(service.search(_course(), query: '456'), hasLength(1));
    });

    test('type and structural scope filters are authoritative', () {
      expect(
        service.search(_course(), query: 'come', exerciseType: 'choice'),
        hasLength(1),
      );
      expect(
        service
            .search(
              _course(),
              query: 'come',
              scope: ExerciseSearchScope.lesson,
              lessonId: 'lesson_two',
            )
            .single
            .exerciseId,
        'other-456',
      );
      expect(
        service
            .search(
              _course(),
              query: 'come',
              scope: ExerciseSearchScope.round,
              lessonId: 'lesson_one',
              roundId: 'round_one',
            )
            .single
            .exerciseId,
        'EX-Àccent-123',
      );
    });
  });
}

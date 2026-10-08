import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/round_type_compatibility.dart';

void main() {
  final lab = Course.fromJson(
    jsonDecode(
          File(
            'assets/courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final exercises = [
    for (final lesson in lab.lessons)
      for (final round in lesson.rounds) ...round.exercises,
  ];
  Exercise preset(String id) =>
      exercises.firstWhere((e) => e.authoringMetadata['presetId'] == id);

  test('preset suggestions are scoped by type', () {
    final listen = ExercisePresetRegistry.presets
        .where(
          (p) => RoundTypeCompatibility.canOfferPreset(RoundType.listening, p),
        )
        .toList();
    final read = ExercisePresetRegistry.presets
        .where(
          (p) => RoundTypeCompatibility.canOfferPreset(RoundType.reading, p),
        )
        .toList();
    final cards = ExercisePresetRegistry.presets
        .where(
          (p) => RoundTypeCompatibility.canOfferPreset(RoundType.flashcard, p),
        )
        .toList();
    expect(listen, isNotEmpty);
    expect(read.map((p) => p.id), contains('reading_answer_target'));
    expect(cards.map((p) => p.id).toSet(), {'flashcard', 'picture_flashcard'});
    expect(
      RoundTypeCompatibility.canOfferPreset(
        RoundType.test,
        ExercisePresetRegistry.byId('note_card')!,
      ),
      isFalse,
    );
    final timed = ExercisePresetRegistry.presets
        .where((p) => RoundTypeCompatibility.canOfferPreset(RoundType.timed, p))
        .toList();
    expect(timed, isNotEmpty);
    expect(
      timed.every((p) => p.evaluatableCandidate && !p.audioEssentialCandidate),
      isTrue,
    );
    expect(timed.map((p) => p.id), isNot(contains('listening_spelling')));
  });

  test(
    'canonical content controls compatibility even after preset selection',
    () {
      expect(
        RoundTypeCompatibility.audioEssential(preset('listening_spelling')),
        isTrue,
      );
      expect(
        RoundTypeCompatibility.audioEssential(
          preset('translation_choice_to_target'),
        ),
        isFalse,
      );
      expect(
        RoundTypeCompatibility.readingEssential(
          preset('reading_answer_target'),
        ),
        isTrue,
      );
      expect(
        RoundTypeCompatibility.flashcardCompatible(preset('flashcard')),
        isTrue,
      );
      expect(RoundTypeCompatibility.evaluatable(preset('flashcard')), isFalse);
      expect(
        RoundTypeCompatibility.issuesForExercise(
          RoundType.timed,
          preset('listening_spelling'),
        ),
        contains(RoundTypeIssue.timedRequiresAudio),
      );
      expect(
        RoundTypeCompatibility.issuesForExercise(
          RoundType.timed,
          preset('flashcard'),
        ),
        contains(RoundTypeIssue.timedEvaluatableOnly),
      );
    },
  );

  test('published incompatible Round content is blocking', () {
    final ex = preset('translation_choice_to_target');
    final round = LearningRound(
      id: 'bad-listen',
      title: 'Bad',
      updatedAt: DateTime.utc(2026, 10, 3),
      roundType: RoundType.listening,
      exercises: [ex],
    );
    final course = Course(
      courseId: 'audit-round-type',
      title: 'Audit',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      ttsLanguage: 'it-IT',
      lessons: [
        Lesson.fromJson({
          ...lab.lessons.first.toJson(),
          'rounds': [round.toJson()],
        }),
      ],
    );
    final result = CourseAuditService().auditRound(course, round.id);
    expect(
      result.issues.map((i) => i.code),
      contains('ROUND_TYPE_AUDIO_REQUIRED'),
    );
  });
}

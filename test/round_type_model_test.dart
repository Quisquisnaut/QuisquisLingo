import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3);

  test('an explicit Round type survives v12 JSON', () {
    final round = LearningRound(
      id: 'round-1',
      title: 'Greetings',
      updatedAt: now,
      roundType: RoundType.discover,
    );
    expect(round.toJson()['roundType'], 'discover');
    expect(
      LearningRound.fromJson(round.toJson()).roundType,
      RoundType.discover,
    );
  });

  test('legacy flow establishes Story or Sequence, not the old icon alone', () {
    final base = LearningRound(id: 'legacy', title: 'Old', updatedAt: now);
    final legacyJson = Map<String, dynamic>.of(base.toJson())
      ..remove('roundType');
    final flow = ContentFlow.linear(const [
      FlowNode(id: 'node', kind: FlowNodeKind.content, contentId: 'card'),
    ]);
    final story = LearningRound.fromJson({
      ...legacyJson,
      'visualType': 'story',
      'flow': flow.toJson(),
    });
    final sequence = LearningRound.fromJson({
      ...legacyJson,
      'visualType': 'generic',
      'flow': flow.toJson(),
    });
    final oldTest = LearningRound.fromJson({
      ...legacyJson,
      'visualType': 'test',
    });
    expect(story.roundType, RoundType.story);
    expect(sequence.roundType, RoundType.sequence);
    expect(oldTest.roundType, RoundType.practice);
  });

  test('an unknown explicit Round type is refused', () {
    final base = LearningRound(id: 'legacy', title: 'Old', updatedAt: now);
    expect(
      () => LearningRound.fromJson({...base.toJson(), 'roundType': 'quiz'}),
      throwsFormatException,
    );
  });

  test('Test settings persist and validate their range', () {
    final round = LearningRound(
      id: 'test',
      title: 'Check',
      updatedAt: now,
      roundType: RoundType.test,
      testFixedOrder: true,
      testPassingPercent: 75,
    );
    final restored = LearningRound.fromJson(round.toJson());
    expect(restored.testFixedOrder, isTrue);
    expect(restored.testPassingPercent, 75);
    expect(
      () => LearningRound.fromJson({
        ...round.toJson(),
        'testPassingPercent': 101,
      }),
      throwsFormatException,
    );
  });

  test('older official checksum accepts only migrated Round metadata', () {
    final json =
        jsonDecode(
              File('test/fixtures/v12/edge_case_it_en.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final course = Course.fromJson(json);
    expect(CourseChecksums.officialMatches(course), isTrue);

    final changedType = Map<String, dynamic>.from(course.toJson());
    final firstLesson =
        (changedType['lessons'] as List).first as Map<String, dynamic>;
    final firstRound =
        (firstLesson['rounds'] as List).first as Map<String, dynamic>;
    firstRound['roundType'] = 'discover';
    expect(
      CourseChecksums.officialMatches(Course.fromJson(changedType)),
      isFalse,
    );

    final changedNumbering = Map<String, dynamic>.from(course.toJson())
      ..['roundNumberingMode'] = 'numberOnly';
    expect(
      CourseChecksums.officialMatches(Course.fromJson(changedNumbering)),
      isFalse,
    );
  });

  test(
    'single-exercise Story and Sequence previews retain a runnable flow',
    () {
      final lab = Course.fromJson(
        jsonDecode(
              File(
                'assets/courses/exercise_laboratory_en_it.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final card = lab.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises)
          .firstWhere(
            (exercise) => exercise.authoringMetadata['presetId'] == 'flashcard',
          );
      for (final type in [RoundType.story, RoundType.sequence]) {
        final preview = LearningRound(
          id: 'preview',
          title: 'Preview',
          roundType: type,
          exercises: [card],
          flow: RoundFlowAuthoring.singleExercisePreviewFlow(type, card),
        );
        expect(preview.flow!.linearNodeIds(), isNotNull);
        expect(
          RoundPlayabilityService().playableExerciseIndices(
            preview,
            includeDrafts: true,
            keepNotExecutable: true,
          ),
          [0],
        );
      }
    },
  );
}

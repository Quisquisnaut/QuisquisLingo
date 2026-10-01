import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/learner_panel_text.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 260 Revision 2 (owner request of 1 October 2026): QQL Demo:
/// English from Italian, one Lesson with a GuideBook: three ordinary Rounds
/// of six exercises mixed at random, the Story "Al bar", three more Rounds,
/// the Story "Alla stazione".

const _asset = 'assets/courses/english_from_italian_it_en.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final raw =
      jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;
  final course = Course.fromJson(raw);
  final lesson = course.lessons.single;

  test('is a bundled Course counted as English', () async {
    expect(CourseService.courseAssets['EN_IT'], _asset);
    final loaded = await CourseService().loadBundledCourse('EN_IT');
    expect(loaded.title, 'QQL Demo: English from Italian');
    expect(loaded.originType, CourseOriginType.bundledOfficial);
    expect(CourseService.bundledCodeForCourse(loaded), 'EN_IT');
    // Language XP and streaks count it as English.
    expect(CourseService.codeForCourse(loaded), 'EN');
    expect(course.toJson(), raw);
    expect(CourseChecksums.official(course), course.officialChecksum);
  });

  test('one Lesson: three Rounds, a Story, three Rounds, a Story', () {
    expect(course.useGuidebook, isTrue);
    expect(lesson.rounds.map((round) => round.isStory), [
      false,
      false,
      false,
      true,
      false,
      false,
      false,
      true,
    ]);
    expect(lesson.rounds[3].storyTitle, 'Al bar');
    expect(lesson.rounds.last.storyTitle, 'Alla stazione');
  });

  test('six ordinary Rounds of six exercises of different types', () {
    final practice = lesson.rounds.where((round) => !round.isStory).toList();
    expect(practice, hasLength(6));
    final presets = <String>[];
    for (final round in practice) {
      expect(round.flow, isNull);
      final card = ExerciseFeatures(round.exercises.first);
      expect(card.kind, LearnerExerciseKind.roundIntro);
      expect(card.guidebookButton, isTrue);
      final exercises = round.content.skip(1).toList();
      expect(exercises, hasLength(6), reason: round.id);
      final types = exercises.map((content) => content.editorTemplate);
      // Mixed: never two of a type in a Round.
      expect(types.toSet(), hasLength(6), reason: round.id);
      presets.addAll(types.whereType<String>());
      // One exercise needs audio, so with Audio Exercises off five remain.
      expect(
        exercises
            .where(
              (content) => ExerciseFeatures(content.exercise!).requiresAudio,
            )
            .length,
        1,
        reason: round.id,
      );
    }
    // 36 exercises of 36 types, not in the catalogue's order.
    expect(presets.toSet(), hasLength(36));
    final catalogue = [
      for (final preset in ExercisePresetRegistry.presets) preset.id,
    ];
    final positions = [for (final id in presets) catalogue.indexOf(id)];
    expect(positions, isNot(orderedEquals([...positions]..sort())));
    // Every exercise is still represented by its preset.
    for (final round in practice) {
      for (final content in round.content.skip(1)) {
        expect(
          PresetRecipes.represents(content.exercise!, content.editorTemplate),
          isTrue,
          reason: content.id,
        );
      }
    }
  });

  test('the Stories alternate dialogue lines and questions', () {
    for (final story in [lesson.rounds[3], lesson.rounds.last]) {
      final kinds = [
        for (final exercise in story.exercises.skip(1))
          ExerciseFeatures(exercise).kind,
      ];
      expect(kinds.first, LearnerExerciseKind.storyCover);
      expect(
        kinds.where((kind) => kind == LearnerExerciseKind.dialogueLine),
        hasLength(6),
      );
      expect(
        story.exercises.where(
          (exercise) =>
              exercise.canonicalEvaluation.mode != EvaluationMode.none,
        ),
        hasLength(2),
      );
    }
    expect(course.storyCharacters.map((speaker) => speaker.name), [
      'Tom',
      'Emma',
      'Anna',
      'Ben',
    ]);
  });

  test('the GuideBook has notes and vocabulary', () {
    final content = lesson.guidebook.content;
    expect(content.first.role, 'overview');
    expect(content.where((c) => c.role == 'grammar'), hasLength(4));
    final words = VocabularyReviewService().resolveEntries(course, lesson);
    expect(words, hasLength(35));
    expect(
      words.singleWhere((entry) => entry.prompt == 'grazie').answer,
      'thank you',
    );
  });

  test('the learner panel is in Italian', () {
    expect(ExerciseCopyService.instructionLanguage(course), 'it');
    expect(LearnerPanelText.of(course, 'check'), 'Controlla');
  });

  test('passes the Audit with no error or warning', () {
    final audit = CourseAuditService().auditCourse(course);
    expect(audit.count(AuditSeverity.error), 0);
    expect(
      audit.issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .map((issue) => '${issue.code}:${issue.exerciseId}'),
      isEmpty,
    );
  });
}

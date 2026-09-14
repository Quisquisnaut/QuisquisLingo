import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/learning_language_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Course> loadCourse() async {
    final raw = await rootBundle.loadString(
      'assets/courses/neapolitan_it.json',
    );
    return Course.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  test('QQL 234 resolves the three-letter Neapolitan identity', () async {
    final course = await loadCourse();

    expect(LearningLanguageIdentity.canonicalId('Neapolitan'), 'nap');
    expect(LearningLanguageIdentity.canonicalId('Napoletano'), 'nap');
    expect(LearningLanguageIdentity.displayName('nap-IT'), 'Neapolitan');
    expect(CourseService.codeForCourse(course), 'NAP');
  });

  test('QQL 234 ships a verified full Italian to Neapolitan demo', () async {
    final course = await loadCourse();

    expect(course.formatVersion, 9);
    expect(course.courseId, 'sample_nap_it_nap');
    expect(course.originType, CourseOriginType.bundledOfficial);
    expect(course.publisherId, 'org.quisquislingo');
    expect(course.title, 'AI-Slop Demo: Napoletano per italofoni');
    expect(course.interfaceLanguage, 'Italian');
    expect(course.sourceLanguage, 'Italian');
    expect(course.learningLanguage, 'Neapolitan');
    expect(course.targetLanguage, 'Neapolitan');
    expect(course.sourceLanguageTag, 'it-IT');
    expect(course.targetLanguageTag, 'nap-IT');
    expect(course.ttsLanguage, 'nap-IT');
    expect(course.worldFlagId, 'neapolitan');
    expect(course.temporarySample, isTrue);
    expect(course.lessons, hasLength(9));
    expect(course.lessons.expand((lesson) => lesson.rounds), hasLength(36));
    expect(
      course.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises),
      hasLength(279),
    );
    expect(
      course.officialChecksum,
      CourseBackupService.officialContentChecksum(course),
    );
  });

  test(
    'QQL 234 image exercises use every approved asset with text fallbacks',
    () async {
      final course = await loadCourse();
      const expectedAssets = {
        'assets/exercise_images/airplane.webp',
        'assets/exercise_images/carrot.webp',
        'assets/exercise_images/horse.webp',
        'assets/exercise_images/man.webp',
        'assets/exercise_images/jump.webp',
        'assets/exercise_images/table.webp',
      };
      final imagePrompts = course.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises)
          .expand((exercise) => exercise.promptElements)
          .where((element) => element.type == 'image')
          .toList(growable: false);

      expect(
        imagePrompts.map((element) => element.asset).toSet(),
        expectedAssets,
      );
      expect(imagePrompts, hasLength(expectedAssets.length));
      expect(
        imagePrompts.every((element) => element.text.trim().isNotEmpty),
        isTrue,
      );
      for (final asset in expectedAssets) {
        expect(await rootBundle.load(asset), isA<ByteData>());
      }
    },
  );

  test('QQL 234 Neapolitan Duels remain available without TTS', () async {
    final course = await loadCourse();
    const eligibility = DuelEligibilityService();
    final audio = AudioExerciseAvailabilityService();

    for (final lesson in course.lessons) {
      final structural = eligibility.evaluate(lesson);
      final nonAudio = structural.candidates.where(
        (candidate) => !audio.isAudioExercise(candidate.exercise),
      );
      expect(
        nonAudio.length,
        greaterThanOrEqualTo(DuelEligibilityService.requiredQuestionCount),
        reason: lesson.lessonId,
      );
      final effective = await eligibility.evaluateEffective(
        course,
        lesson,
        audioExercisesEnabled: false,
        ttsEnabled: false,
      );
      expect(effective.isAvailable, isTrue, reason: lesson.lessonId);
    }
  });
}

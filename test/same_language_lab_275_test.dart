import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_language_pair.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_sources.dart';

// Build 275 Revision 5 (docs/SAME_LANGUAGE_COURSES_PLAN.md): QQL Test:
// En-En Exercise Lab, a Course in the same language to import, written by
// tools/generate_same_language_lab_275.py into test_courses/ (where the
// test Courses moved in this revision). It must import, play every
// exercise, read in words and meanings and give Word Lookup meanings.

const _file = 'test_courses/exercise_lab_en_en.json';

void main() {
  late Course course;

  setUpAll(() async {
    course = await CustomCourseTransferService().courseFromBytes(
      await File(_file).readAsBytes(),
      'exercise_lab_en_en.json',
    );
  });

  Iterable<Exercise> exercises() sync* {
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        yield* round.exercises;
      }
    }
  }

  test('it imports as a custom Course in the same language', () {
    expect(course.title, 'QQL Test: En-En Exercise Lab');
    expect(course.originType, CourseOriginType.custom);
    expect(course.courseVersion, '1');
    expect(course.sameLanguage, isTrue);
    expect(CourseLanguagePair.isSameLanguage(course), isTrue);
    expect(course.minimumAppBuild, 275002);
    expect(course.sourceLanguage, course.targetLanguage);
    expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
    // No Course comes with the app: the test Courses are imported.
    expect(
      Directory('test_courses').listSync().map((f) => f.uri.pathSegments.last),
      containsAll([
        'exercise_lab_en_en.json',
        'exercise_laboratory_en_it.json',
        'edge_case_it_en.json',
      ]),
    );
  });

  test('the Audit finds no error; the one warning is the Rights Holder', () {
    final audit = CourseAuditService().auditCourse(course);
    expect(
      audit.issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .map((issue) => '${issue.code}: ${issue.message}'),
      isEmpty,
    );
    // The test Courses name no Rights Holder (owner decision of 14 October
    // 2026).
    expect(
      audit.issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .map((issue) => issue.code),
      ['LICENSE_RIGHTS_HOLDER_MISSING'],
    );
  });

  test('the identical-languages warning is for a translation Course only', () {
    List<String> codes(Course value) => [
      for (final issue in CourseAuditService().auditCourse(value).issues)
        issue.code,
    ];
    expect(codes(course), isNot(contains('COURSE_LANGUAGES_IDENTICAL')));
    // The same file read as a translation Course (an English to English
    // Course made before Build 275 Revision 2) still gets it.
    final translation = Course.fromJson(
      course.toJson()..remove('sameLanguage'),
    );
    expect(CourseLanguagePair.isSameLanguage(translation), isFalse);
    expect(codes(translation), contains('COURSE_LANGUAGES_IDENTICAL'));
  });

  test('one exercise or more for every preset the Course offers, none for '
      'the twins, each represented by its preset', () {
    final stored = <String>{};
    for (final exercise in exercises()) {
      final preset = exercise.editorTemplate;
      stored.add(preset);
      expect(
        PresetRecipes.represents(exercise, preset),
        isTrue,
        reason: '${exercise.id} $preset',
      );
    }
    final offered = {
      for (final preset in ExercisePresetRegistry.presets)
        if (ExercisePresetRegistry.offeredIn(preset.id, sameLanguage: true))
          preset.id,
    };
    expect(offered, hasLength(44));
    expect(stored, offered);
    expect(
      stored.intersection(ExercisePresetRegistry.notInSameLanguage),
      isEmpty,
    );
  });

  test('every exercise plays', () {
    final playability = RoundPlayabilityService();
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          expect(exercise.isExecutable, isTrue, reason: exercise.id);
        }
        final cards = round.exercises
            .where((e) => e.editorTemplate == 'before_you_start')
            .length;
        // A Before you start card is shown before the Round, never a step.
        expect(
          playability.playableExerciseIndices(round),
          hasLength(round.exercises.length - cards),
          reason: round.id,
        );
        expect(cards, 1, reason: round.id);
      }
    }
  });

  test('the titles and lines speak of words and meanings', () {
    final titles = {
      for (final exercise in exercises())
        exercise.editorTemplate: ExerciseCopyService.title(course, exercise),
    };
    expect(titles['translation_choice_to_target'], 'PICK THE WORD');
    expect(titles['translation_choice_to_source'], 'PICK THE MEANING');
    expect(titles['type_translation_to_target'], 'TYPE THE WORD');
    expect(titles['type_translation_to_source'], 'TYPE THE MEANING');
    expect(titles['build_translation_to_target'], 'BUILD THE SENTENCE');
    expect(titles['build_translation_to_source'], 'BUILD THE MEANING');
    expect(titles['word_match'], 'MATCH WORDS AND MEANINGS');
    for (final exercise in exercises()) {
      final title = ExerciseCopyService.title(course, exercise);
      final line = ExerciseCopyService.instructionForExercise(course, exercise);
      for (final text in [title, line]) {
        expect(
          text.toLowerCase(),
          isNot(contains('translat')),
          reason: exercise.id,
        );
        expect(text, isNot(contains('English')), reason: exercise.id);
      }
    }
  });

  test('a Flashcard shown meaning first names no language', () {
    final card = exercises().firstWhere(
      (exercise) => exercise.editorTemplate == 'flashcard',
    );
    expect(
      ExerciseCopyService.instructionForExercise(
        course,
        card,
        meaningFirst: true,
      ),
      'Think of the word, then turn the card.',
    );
    // In every catalog, without the language and (Build 263's rule)
    // not opening with its title's first word.
    String firstWord(String text) => RegExp(
      r'[\p{L}\p{N}]+',
      unicode: true,
    ).firstMatch(text)!.group(0)!.toLowerCase();
    for (final MapEntry(key: language, value: catalog)
        in exerciseCopyCatalogs.entries) {
      final line = catalog['instruction.sameLanguage.flashcardMeaningFirst'];
      expect(line, isNotNull, reason: language);
      expect(line, isNot(contains('{language}')), reason: language);
      for (final title in ['title.flashcard', 'title.picture_flashcard']) {
        expect(
          firstWord(line!),
          isNot(firstWord(catalog[title]!)),
          reason: '$language $title',
        );
      }
    }
    // A translation Course still names the language.
    final translation = Course.fromJson(
      course.toJson()..remove('sameLanguage'),
    );
    expect(
      ExerciseCopyService.instructionForExercise(
        translation,
        card,
        meaningFirst: true,
      ),
      'Think of the English word, then turn the card.',
    );
  });

  test('every Lesson has a GuideBook module of words and meanings, which '
      'Word Lookup reads', () {
    for (final lesson in course.lessons) {
      expect(
        lesson.guidebook.publicationState.isPublished,
        isTrue,
        reason: lesson.title,
      );
      final module = lesson.guidebook.modules.single;
      expect(module.words, isNotEmpty, reason: lesson.title);
      expect(module.overview.trim(), isNotEmpty, reason: lesson.title);
    }
    final entries = WordLookupSources.forCourse(course);
    final espresso = entries.firstWhere((entry) => entry.target == 'espresso');
    expect(espresso.source, 'a small, strong coffee');
    expect(
      WordLookupSources.indexFor(course)
          .analyze('An espresso, please.', currentLessonIndex: 0)
          .allEntries
          .map((entry) => entry.source),
      contains('a small, strong coffee'),
    );
  });
}

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Course> loadCourse() async => Course.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(
            await rootBundle.loadString('assets/courses/piedmontais_en.json'),
          )
          as Map,
    ),
  );

  test(
    'Piedmontese demo is an independent published v11 bundled identity',
    () async {
      final course = await loadCourse();
      expect(course.formatVersion, 12);
      expect(course.courseId, 'course_e5f5585a-7762-43a0-a6b2-62754e02d17b');
      expect(course.originType, CourseOriginType.bundledOfficial);
      // Build 255 Revision 6 renamed it from Piedmontais, keeping its ID.
      expect(course.title, 'Temporary Demo: Piedmontese');
      expect(course.learningLanguage, 'Piedmontese');
      expect(course.sourceLanguage, 'English');
      expect(course.targetLanguage, 'Piedmontese');
      expect(jsonEncode(course.toJson()), isNot(contains('Piedmontais')));
      expect(course.license, 'All rights reserved');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
      expect(course.sourceLanguageTag, 'en-GB');
      expect(course.targetLanguageTag, 'pms-IT');
      expect(course.worldFlagId, 'piedmontese');
      expect(course.temporarySample, isTrue);
      expect(course.courseDescription, contains('UNREVIEWED AI-GENERATED'));
      expect(course.courseDescription, contains('no recorded'));
      expect(course.audioMode, 'tts');
      expect(course.ttsLanguage, 'pms-IT');
      expect(course.audioLibrary, isEmpty);
      expect(course.createDuels, isFalse);
      expect(course.publicationState, PublicationState.published);
      expect(course.officialChecksum, CourseChecksums.official(course));
      expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
    },
  );

  test(
    'every current named preset has exactly one titled Piedmontese Lesson',
    () async {
      final course = await loadCourse();
      final presets = ExercisePresetRegistry.presets;
      // One Lesson per preset, except Story cover (a Story of covers alone
      // belongs to the Edge Case demo; owner decision, 28 September 2026)
      // and the two Assign presets (the Laboratory's Assign Lesson shows
      // them; owner decision, 29 September 2026). Before you start has no
      // Lesson either: its card opens every Lesson (Build 257). Page has
      // none: the Laboratory shows it (Build 258). Listen and choose adds two
      // presets and two Lessons (Build 259 Revision 2).
      expect(course.lessons, hasLength(presets.length - 5));
      expect(presets, hasLength(46));
      final seenTypes = <String>{};
      for (final lesson in course.lessons) {
        expect(lesson.publicationState, PublicationState.published);
        expect(lesson.rounds, hasLength(1));
        final round = lesson.rounds.single;
        expect(round.publicationState, PublicationState.published);
        expect(round.exercises, hasLength(4));
        expect(
          RoundPlayabilityService.isRoundIntro(round.exercises.first),
          isTrue,
          reason: lesson.title,
        );
        final types = round.exercises
            .skip(1)
            .map((exercise) => exercise.editorTemplate)
            .toSet();
        expect(types, hasLength(1), reason: lesson.title);
        final type = types.single;
        expect(seenTypes.add(type), isTrue, reason: lesson.title);
        expect(
          lesson.title,
          startsWith('${ExercisePresetRegistry.byId(type)!.name} — '),
        );
        expect(lesson.guidebook.content, isNotEmpty);
        expect(
          lesson.guidebook.content.every(
            (content) => content.publicationState.isPublished,
          ),
          isTrue,
        );
      }
      expect(
        seenTypes,
        presets.map((preset) => preset.id).toSet()..removeAll([
          'story_cover',
          'sort_into_groups',
          'fill_the_slots',
          'before_you_start',
          'page',
        ]),
      );
    },
  );

  test(
    'all 123 Piedmontese examples pass Audit and enter the runnable queue',
    () async {
      final course = await loadCourse();
      final audit = CourseAuditService().auditCourse(course);
      expect(
        audit.issues.where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
        reason: audit.issues
            .map((issue) => '${issue.code}: ${issue.message}')
            .join('\n'),
      );
      expect(
        audit.issues
            .where((issue) => issue.severity == AuditSeverity.warning)
            .map((issue) => issue.code),
        ['OPPOSITE_TOO_EARLY'],
      );
      final playable = RoundPlayabilityService();
      final ids = <String>{course.courseId};
      void unique(String id) => expect(ids.add(id), isTrue, reason: id);
      for (final lesson in course.lessons) {
        unique(lesson.lessonId);
        unique(lesson.duel.id);
        for (final content in lesson.guidebook.content) {
          unique(content.id);
        }
        final round = lesson.rounds.single;
        unique(round.id);
        for (final content in round.content) {
          unique(content.id);
        }
        // The Before you start card (index 0) is never a step (Build 257).
        expect(playable.playableExerciseIndices(round), [
          1,
          2,
          3,
        ], reason: lesson.title);
        for (final exercise in round.exercises) {
          expect(exercise.publicationState, PublicationState.published);
          // Flashcards have no persisted interaction items: their runtime view
          // synthesizes presentation fields, and completion uses explicit actions.
          if (exercise.type != 'flashcard') {
            for (final item in exercise.interaction.items) {
              unique(item.id);
            }
          }
        }
      }
      // Rounds of cards or lines only (Flashcard, Picture flashcard, Note
      // card, Dialogue line) can be completed but never earn a Laurel.
      expect(playable.laurelEligibleRoundIds(course), hasLength(37));
    },
  );

  test(
    'answers, repeated letters and optional translations remain usable',
    () async {
      final course = await loadCourse();
      final all = course.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises);
      const engine = AnswerEngine();
      for (final exercise in all.where((item) => item.type != 'flashcard')) {
        final items = {
          for (final item in exercise.interaction.items) item.id: item,
        };
        final evaluation = exercise.evaluation;
        if (exercise.type == 'missing_word') {
          expect(exercise.missingWords, isNotEmpty);
          for (final word in exercise.missingWords) {
            expect(exercise.prompt, contains(word));
            // Complete the text and Missing letters may have no audio.
            if (exercise.editorTemplate == 'missing_word') {
              expect(exercise.tts, contains(word));
            }
          }
        } else if (exercise.interaction.kind == 'input') {
          // Type what you hear accepts its Audio text as a literal answer,
          // without another line (Build 259 Revision 3).
          if (exercise.accepted.isEmpty) {
            expect(
              exercise.canonicalEvaluation.literalAnswers,
              isNotEmpty,
              reason: exercise.id,
            );
            continue;
          }
          final answers = engine.validAnswers(exercise.accepted);
          expect(answers, isNotEmpty, reason: exercise.id);
          for (final answer in answers) {
            expect(
              engine.accepts(
                answer,
                exercise.accepted,
                normalization: evaluation.normalization,
              ),
              isTrue,
              reason: exercise.id,
            );
          }
          expect(
            engine.accepts('not a valid answer', exercise.accepted),
            isFalse,
          );
        } else if (exercise.interaction.kind == 'arrange') {
          for (final answer in evaluation.correctOrders) {
            expect(answer.itemIds.toSet(), hasLength(answer.itemIds.length));
            final result = answer.itemIds
                .map((id) => items[id]!.text)
                .join(exercise.type == 'image_word' ? '' : ' ');
            expect(result, answer.text, reason: exercise.id);
          }
          if (exercise.type == 'image_word') {
            expect(
              evaluation.correctOrders.single.itemIds,
              hasLength(items.length),
            );
          }
        } else if (exercise.interaction.kind == 'select' &&
            exercise.hasSelectGaps) {
          // Pick the words for the gaps: one option per gap, reusable.
          expect(evaluation.gapAssignments, isNotEmpty);
          for (final id in evaluation.gapAssignments.values) {
            expect(items.keys, contains(id));
          }
        } else if (exercise.interaction.kind == 'select') {
          expect(evaluation.correctItemIds, hasLength(1));
          expect(items.keys, contains(evaluation.correctItemIds.single));
          expect(items.length, greaterThanOrEqualTo(2));
        } else if (exercise.interaction.kind == 'match') {
          expect(evaluation.pairs, hasLength(3));
          expect(
            evaluation.pairs.expand((pair) => pair).toSet(),
            items.keys.toSet(),
          );
        }
      }
      final translations = all
          .where(
            (exercise) =>
                exercise.editorTemplate == 'type_translation_to_target',
          )
          .toList();
      expect(engine.validAnswers(translations.first.accepted), [
        'grassie',
        'mersì',
      ]);
      expect(engine.validAnswers(translations[1].accepted).toSet(), {
        'I son content',
        'Mi i son content',
      });
      final horse = all
          .where((exercise) => exercise.editorTemplate == 'image_word')
          .last;
      expect(horse.evaluation.correctOrders.single.text, 'caval');
      expect(
        horse.interaction.items.where((item) => item.text == 'a'),
        hasLength(2),
      );
    },
  );

  test(
    'image prompts and choices resolve; character glyphs are portable PNGs',
    () async {
      final course = await loadCourse();
      final assets = <String>{};
      final glyphs = <String>{};
      for (final lesson in course.lessons) {
        for (final exercise in lesson.rounds.single.exercises) {
          for (final element in [
            ...exercise.promptElements,
            ...exercise.interaction.items.expand((item) => item.content),
          ].where((element) => element.type == 'image')) {
            expect(element.text, isNotEmpty);
            expect(
              PortableExerciseImageService.isPortable(element.asset),
              isTrue,
            );
            if (element.asset.startsWith('data:')) {
              final bytes = PortableExerciseImageService.decode(element.asset);
              expect(bytes, isNotNull);
              expect(bytes!.length, lessThan(50 * 1024));
              expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
              glyphs.add(element.asset);
            } else {
              assets.add(element.asset);
            }
          }
        }
      }
      expect(glyphs, hasLength(3));
      expect(
        assets,
        containsAll({
          'assets/exercise_images/cat.webp',
          'assets/exercise_images/dog.webp',
          'assets/exercise_images/horse.webp',
          'assets/exercise_images/bread.webp',
          'assets/exercise_images/water.webp',
          'assets/exercise_images/apple.webp',
        }),
      );
      for (final asset in assets) {
        expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      }
    },
  );
}

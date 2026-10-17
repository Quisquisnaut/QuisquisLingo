import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/audio_library_screen.dart';
import 'package:quisquislingo_app/screens/exercise_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/correct_answer_text.dart';
import 'package:quisquislingo_app/services/course_audio_usage.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_minimum_build.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/round_type_compatibility.dart';
import 'package:quisquislingo_app/services/sound_answers.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 274 Revision 3: Listen and pick the missing word, the owner's point
/// 7 of 13 October 2026 and the format decisions of 16 October 2026 (an
/// answer's sound is a text or an Audio Library recording named by its id;
/// its own text waits for the answer; On-Device TTS plays no recordings).
const _preset = 'listening_pick_missing_word';
const _exampleId = 'qql_lab254_listening_pick_word';

/// A learner who copies and forks (a stable UUIDv4, as a Maintainer needs).
const _alice = '4f6c2a1e-8b3d-4c5e-9a7f-1b2c3d4e5f60';

/// The Laboratory as the app keeps it, or with [custom] its importable copy
/// (a custom Course: an official one can only be forked).
Map<String, dynamic> _laboratoryJson({bool custom = false}) =>
    jsonDecode(
          File(
            custom
                ? 'test_courses/exercise_laboratory_en_it.json'
                : 'assets/courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

/// The Laboratory with an Audio Library of three recordings, in
/// [audioMode]; with [recordingAnswer] the example's second answer is the
/// recording `clip_dormono` (no text) and keeps its own text; with
/// [allRecordings] every answer is a recording.
Course _course({
  String audioMode = 'hybrid',
  bool recordingAnswer = false,
  bool allRecordings = false,
  bool custom = false,
}) {
  final json = _laboratoryJson(custom: custom);
  json['audioMode'] = audioMode;
  json['audioLibrary'] = [
    {
      'id': 'clip_dormono',
      'text': '',
      'filePath': 'assets/audio_274/dormono.mp3',
    },
    {
      'id': 'clip_dorme',
      'text': 'dorme',
      'filePath': 'assets/audio_274/dorme.mp3',
    },
    {
      'id': 'clip_dormire',
      'text': 'dormire',
      'filePath': 'assets/audio_274/dormire.mp3',
    },
  ];
  if (recordingAnswer || allRecordings) {
    for (final lesson in json['lessons'] as List) {
      for (final round in (lesson as Map)['rounds'] as List) {
        for (final content in (round as Map)['content'] as List) {
          if ((content as Map)['id'] != _exampleId) continue;
          final items = (content['exercise'] as Map)['items'] as List;
          for (final (index, clip) in [
            (1, 'clip_dormono'),
            if (allRecordings) ...[(0, 'clip_dorme'), (2, 'clip_dormire')],
          ]) {
            ((items[index] as Map)['content'] as List)[0] = {
              'role': 'primary',
              'type': 'audio',
              'recording': clip,
            };
          }
        }
      }
    }
  }
  return Course.fromJson(json);
}

Exercise _exampleOf(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds) ...round.exercises,
].firstWhere((exercise) => exercise.id == _exampleId);

Exercise _example() => _exampleOf(_course());

Map<String, dynamic> _exerciseJson(Exercise exercise) =>
    Map<String, dynamic>.from(exercise.toJson());

Exercise _read(Map<String, dynamic> json) => Exercise.fromJson(
  json,
  contentId: 'r274_3',
  publicationState: PublicationState.published,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _platforms();
    keepCrashLogUnavailable();
  });

  group('the format', () {
    test('an answer names a recording by its id, and reads back', () {
      final exercise = _exampleOf(_course(recordingAnswer: true));
      final sound = ExerciseFeatures(exercise).soundOf(exercise.items[1])!;
      expect(sound.recording, 'clip_dormono');
      expect(sound.text, isEmpty);
      final again = _read(_exerciseJson(exercise));
      expect(again.toJson(), exercise.toJson());
      expect(
        (((again.toJson()['items'] as List)[1] as Map)['content'] as List)[0],
        {'role': 'primary', 'type': 'audio', 'recording': 'clip_dormono'},
      );
    });

    test('a recording is refused where it cannot play', () {
      Map<String, dynamic> withElement(
        Map<String, dynamic> element, {
        bool inPrompt = false,
      }) {
        final json = _exerciseJson(_example());
        if (inPrompt) {
          json['prompt'] = [...json['prompt'] as List, element];
        } else {
          final items = [...json['items'] as List];
          items[0] = {
            ...(items[0] as Map),
            'content': [element],
          };
          json['items'] = items;
        }
        return json;
      }

      // On a text element, with a text, empty, or in the prompt.
      for (final (element, inPrompt) in [
        ({'type': 'text', 'text': 'x', 'recording': 'clip_dorme'}, false),
        ({'type': 'audio', 'text': 'dorme', 'recording': 'clip_dorme'}, false),
        ({'type': 'audio', 'recording': ''}, false),
        ({'type': 'audio', 'recording': 'clip_dorme'}, true),
      ]) {
        expect(
          () => _read(withElement(element, inPrompt: inPrompt)),
          throwsFormatException,
          reason: '$element in prompt: $inPrompt',
        );
      }
    });

    test('an after_answer text is not the answer\'s text', () {
      final item = _example().items[1];
      expect(item.text, isEmpty);
      expect(item.value, 'dormono');
      expect(item.label, 'dormono');
      expect(
        ExerciseFeatures(_example()).afterAnswerTextOf(item),
        'dormono (they sleep)',
      );
    });

    test('a sound answer is its own kind, played and graded on Check', () {
      final exercise = _example();
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectSounds);
      expect(f.hasSoundItems, isTrue);
      expect(f.checkedOnCheck, isTrue);
      expect(exercise.isExecutable, isTrue);
      expect(f.requiresAudio, isTrue);
    });

    test('what an answer shows once answered', () {
      final course = _course(recordingAnswer: true);
      final exercise = _exampleOf(course);
      final f = ExerciseFeatures(exercise);
      String shown(int i, [List<CourseAudioClip>? library]) =>
          SoundAnswers.shownText(
            f,
            exercise.items[i],
            library ?? course.audioLibrary,
          );
      // Its sound's text; its own text; a recording's own text.
      expect(shown(0), 'dorme');
      expect(shown(1), 'dormono (they sleep)');
      final bare = exercise.copyWith(
        items: [
          exercise.items[0],
          ExerciseItem(
            id: exercise.items[1].id,
            content: const [
              PromptElement(type: 'audio', recording: 'clip_dorme'),
            ],
          ),
          ExerciseItem(
            id: exercise.items[2].id,
            content: const [
              PromptElement(type: 'audio', recording: 'clip_dormono'),
            ],
          ),
        ],
      );
      final g = ExerciseFeatures(bare);
      expect(
        SoundAnswers.shownText(g, bare.items[1], course.audioLibrary),
        'dorme',
      );
      expect(
        SoundAnswers.shownText(g, bare.items[2], course.audioLibrary),
        isEmpty,
      );
    });

    test('answers are sounds only when one is chosen and Check grades', () {
      final exercise = _example();
      expect(ExerciseFeatures(exercise).hasSoundItems, isTrue);
      for (final (name, changed) in [
        (
          'graded on the tap',
          exercise.copyWith(
            options: exercise.options.withEnum(
              OptionKey.evaluationTiming,
              EvaluationTiming.immediate,
            ),
          ),
        ),
        (
          'several answers',
          exercise.copyWith(
            options: exercise.options.withEnum(
              OptionKey.selectionMode,
              SelectionMode.multiple,
            ),
          ),
        ),
      ]) {
        final f = ExerciseFeatures(changed);
        expect(f.hasSoundItems, isFalse, reason: name);
        expect(f.kind, isNot(LearnerExerciseKind.selectSounds), reason: name);
      }
    });

    test('a recording plays only as the answer of a Select', () {
      final match = [
        for (final lesson in _course().lessons)
          for (final round in lesson.rounds) ...round.exercises,
      ].firstWhere((exercise) => exercise.id == 'qql_lab254_match_sounds');
      final json = _exerciseJson(match);
      final sound = (json['items'] as List)
          .cast<Map>()
          .map((item) => item['content'] as List)
          .firstWhere(
            (content) => content.any((e) => (e as Map)['type'] == 'audio'),
          );
      final index = sound.indexWhere((e) => (e as Map)['type'] == 'audio');
      sound[index] = {
        ...Map<String, dynamic>.from(sound[index] as Map)..remove('text'),
        'recording': 'clip_dorme',
      };
      expect(
        () => _read(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('the answer of a Select'),
          ),
        ),
      );
    });

    test('a Course with sound answers needs build 274003', () {
      final course = _course();
      final json = course.toJson()..remove('minimumAppBuild');
      final stamped = CourseMinimumBuild.stamp(Course.fromJson(json));
      expect(stamped.minimumAppBuild, SoundAnswers.minimumAppBuild);
      expect(SoundAnswers.minimumAppBuild, 274003);
      expect(SoundAnswers.needsThisBuild(_example()), isTrue);
    });

    test('Fork and Copy as New Course follow the recording\'s new id', () {
      final source = _course(recordingAnswer: true, custom: true);
      final service = AuthoringDuplicationService();
      final copy = service.copyCourseAsNew(
        source,
        title: 'A copy',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: _alice,
          displayName: 'Alice',
        ),
        maintainer: const CourseMaintainer(_alice),
      );
      final fork = service.forkCustomCourse(
        source,
        provenance: CourseForkProvenance(
          sourceCourseId: source.courseId,
          sourceCourseTitle: source.title,
          sourceCourseVersion: source.courseVersion,
          sourceOriginType: source.originType,
          sourceAuthors: source.authors,
          forkCreatedByProfileId: _alice,
          forkCreatedByDisplayName: 'Alice',
          forkCreatedAtUtc: '2026-10-16T09:00:00.000Z',
        ),
        maintainer: const CourseMaintainer(_alice),
      );
      for (final made in [copy, fork]) {
        final clip = made.audioLibrary.firstWhere((c) => c.text.isEmpty);
        expect(clip.id, isNot('clip_dormono'));
        final named =
            [
              for (final lesson in made.lessons)
                for (final round in lesson.rounds) ...round.exercises,
            ].firstWhere(
              (exercise) => SoundAnswers.recordingIds(exercise).isNotEmpty,
            );
        expect(SoundAnswers.recordingIds(named), {clip.id});
      }
    });

    test('the learner\'s words: title, heading and line', () {
      final course = _course();
      final exercise = _example();
      expect(
        ExerciseCopyService.title(course, exercise),
        'LISTEN AND PICK THE MISSING WORD',
      );
      expect(
        ExerciseCopyService.instructionForExercise(course, exercise),
        'Play each sound, then choose the one that fills the gap.',
      );
    });
  });

  group('the form\'s recipe', () {
    test('the Laboratory example is represented by its preset', () {
      final exercise = _example();
      expect(PresetRecipes.recognize(exercise), _preset);
      expect(PresetRecipes.represents(exercise, _preset), isTrue);
      final recording = _exampleOf(_course(recordingAnswer: true));
      expect(PresetRecipes.represents(recording, _preset), isTrue);
      final draft = PresetRecipes.decompose(recording, _preset);
      expect(draft.soundAnswers, const [
        SoundAnswerDraft(word: 'dorme'),
        SoundAnswerDraft(
          recording: 'clip_dormono',
          afterAnswer: 'dormono (they sleep)',
        ),
        SoundAnswerDraft(word: 'dormire'),
      ]);
      expect(draft.tts, 'Il gatto dorme sul divano.');
      expect(draft.question, 'Il gatto ___ sul divano.');
      expect(draft.correct, '1');
    });

    ExerciseDraftBuildResult build({
      String tts = 'Il gatto dorme sul divano.',
      String question = 'Il gatto ___ sul divano.',
      List<SoundAnswerDraft> answers = const [
        SoundAnswerDraft(word: 'dorme'),
        SoundAnswerDraft(recording: 'clip_dormono', afterAnswer: 'dormono'),
      ],
      String correct = '1',
      PublicationState state = PublicationState.published,
    }) => ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: PresetRecipes.blankFor(_preset, 'r274_3_new'),
        type: _preset,
        publicationState: state,
        tts: tts,
        question: question,
        soundAnswers: answers,
        correct: correct,
      ),
    );

    test('a Published save refuses what cannot be played or graded', () {
      for (final (name, result, code) in [
        (
          'no spoken sentence',
          build(tts: ''),
          ExerciseDraftErrorCode.textRequired,
        ),
        (
          'no gap',
          build(question: 'Il gatto sul divano.'),
          ExerciseDraftErrorCode.oneGapRequired,
        ),
        (
          'two gaps',
          build(question: 'Il ___ ___ sul divano.'),
          ExerciseDraftErrorCode.oneGapRequired,
        ),
        (
          'one answer',
          build(answers: const [SoundAnswerDraft(word: 'dorme')]),
          ExerciseDraftErrorCode.soundAnswersTooFew,
        ),
        (
          'an answer without a sound',
          build(
            answers: const [
              SoundAnswerDraft(word: 'dorme'),
              SoundAnswerDraft(afterAnswer: 'dormono'),
            ],
          ),
          ExerciseDraftErrorCode.soundAnswerEmpty,
        ),
        (
          'a correct number outside the answers',
          build(correct: '3'),
          ExerciseDraftErrorCode.correctAnswerNumber,
        ),
      ]) {
        expect(result.error?.code, code, reason: name);
      }
      // A Draft keeps what it has.
      expect(
        build(tts: '', state: PublicationState.draft).candidate,
        isNotNull,
      );
    });

    test('a built exercise: sounds, own texts, Check, one correct', () {
      final exercise = build().candidate!;
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectSounds);
      expect(f.checkedOnCheck, isTrue);
      expect(f.primaryAudioText, 'Il gatto dorme sul divano.');
      expect(f.automaticAudio?.text, 'Il gatto dorme sul divano.');
      expect(f.soundOf(exercise.items[0])?.text, 'dorme');
      expect(f.soundOf(exercise.items[1])?.recording, 'clip_dormono');
      expect(f.afterAnswerTextOf(exercise.items[1]), 'dormono');
      expect(exercise.canonicalEvaluation.correctItemIds, [
        exercise.items[0].id,
      ]);
      expect(PresetRecipes.represents(exercise, _preset), isTrue);
      // Rebuilt from its form, the answers keep their IDs by place.
      final again = ExerciseDraftBuilder.build(
        PresetRecipes.decompose(
          exercise,
          _preset,
          publicationState: PublicationState.published,
        ),
      ).candidate!;
      expect(
        again.items.map((item) => item.id),
        exercise.items.map((item) => item.id),
      );
    });
  });

  group('the form\'s rows', () {
    ExerciseDraftBuildResult build(
      List<SoundAnswerDraft> answers, {
      String correct = '1',
    }) => ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: PresetRecipes.blankFor(_preset, 'r274_3_rows'),
        type: _preset,
        publicationState: PublicationState.published,
        tts: 'Il gatto dorme sul divano.',
        question: 'Il gatto ___ sul divano.',
        soundAnswers: answers,
        correct: correct,
      ),
    );

    test('the correct number counts the rows as the form shows them', () {
      // The correct row switched to Recording with none chosen: refused,
      // never another row taking its place.
      final blankCorrect = build(const [
        SoundAnswerDraft(),
        SoundAnswerDraft(word: 'dormono'),
        SoundAnswerDraft(word: 'dormire'),
      ]);
      expect(blankCorrect.error?.code, ExerciseDraftErrorCode.soundAnswerEmpty);
      expect(blankCorrect.error?.line, 1);
      // A blank row is left out; the correct answer stays the row it names.
      final kept = build(const [
        SoundAnswerDraft(word: 'dorme'),
        SoundAnswerDraft(),
        SoundAnswerDraft(word: 'dormire'),
      ], correct: '3').candidate!;
      expect(kept.items, hasLength(2));
      final correct = kept.items.singleWhere(
        (item) => kept.canonicalEvaluation.correctItemIds.contains(item.id),
      );
      expect(ExerciseFeatures(kept).soundOf(correct)?.text, 'dormire');
      // A refusal names the row as the form numbers it.
      final third = build(const [
        SoundAnswerDraft(word: 'dorme'),
        SoundAnswerDraft(),
        SoundAnswerDraft(afterAnswer: 'dormire'),
      ]);
      expect(third.error?.code, ExerciseDraftErrorCode.soundAnswerEmpty);
      expect(third.error?.line, 3);
    });
  });

  group('around the exercise', () {
    test('it fits a Listen Round', () {
      expect(RoundTypeCompatibility.audioEssential(_example()), isTrue);
      expect(
        RoundTypeCompatibility.issuesForExercise(
          RoundType.listening,
          _example(),
        ),
        isEmpty,
      );
    });

    test('never in the Duel', () {
      expect(DuelEligibilityService.isEligible(_example()), isFalse);
    });

    test(
      'a recording plays in Recorded MP3 and Hybrid, never in TTS',
      () async {
        final service = AudioExerciseAvailabilityService(
          recordedAudio: _Files({'clip_dormono', 'clip_dorme', 'clip_dormire'}),
        );
        Future<bool> available(String mode, {required bool tts}) =>
            service.isAvailable(
              _course(audioMode: mode, recordingAnswer: true),
              _exampleOf(_course(audioMode: mode, recordingAnswer: true)),
              ttsEnabled: tts,
            );
        expect(await available('tts', tts: true), isFalse);
        expect(await available('hybrid', tts: true), isTrue);
        // Recorded MP3: the sentence and the word answers need recordings
        // too; this Library has only "dorme".
        expect(await available('recorded', tts: true), isFalse);
        // Word answers only: the device voice.
        expect(
          await service.isAvailable(
            _course(audioMode: 'tts'),
            _example(),
            ttsEnabled: true,
          ),
          isTrue,
        );
        // A recording whose file is missing.
        final missing = AudioExerciseAvailabilityService(
          recordedAudio: _Files(const {}),
        );
        expect(
          await missing.isAvailable(
            _course(recordingAnswer: true),
            _exampleOf(_course(recordingAnswer: true)),
            ttsEnabled: true,
          ),
          isFalse,
        );
      },
    );

    test('the Audio Library counts and lists a named recording', () {
      final course = _course(recordingAnswer: true);
      final uses = CourseAudioUsage.usesByClip(course, (_) => null);
      expect(uses['clip_dormono'], hasLength(1));
      expect(
        CourseAudioUsage.answersNaming(course, 'clip_dormono'),
        hasLength(1),
      );
      expect(CourseAudioUsage.answersNaming(course, 'clip_dorme'), isEmpty);
    });

    test('the right answer\'s text, as shown once answered', () {
      final course = _course(recordingAnswer: true);
      final exercise = _exampleOf(course);
      final f = ExerciseFeatures(exercise);
      expect(
        CorrectAnswerText(
          (key, [values = const {}]) => key,
        ).of(exercise, f, audioLibrary: course.audioLibrary),
        'dorme',
      );
    });
  });

  group('the Audit', () {
    List<String> codes(Course course) => [
      for (final issue in CourseAuditService().auditCourse(course).issues)
        if (issue.exerciseId == _exampleId) issue.code,
    ];

    test('a clean example has no finding', () {
      expect(codes(_course()), isEmpty);
      expect(codes(_course(recordingAnswer: true)), isEmpty);
    });

    test('a recording the Audio Library does not have', () {
      final json = _course(recordingAnswer: true).toJson();
      json['audioLibrary'] = [
        for (final clip in json['audioLibrary'] as List)
          if ((clip as Map)['id'] != 'clip_dormono') clip,
      ];
      expect(
        codes(Course.fromJson(json)),
        contains(AuditCode.soundAnswerRecordingMissing.code),
      );
    });

    test('On-Device TTS plays no recordings', () {
      expect(
        codes(_course(audioMode: 'tts', recordingAnswer: true)),
        contains(AuditCode.soundAnswerRecordingNotPlayed.code),
      );
    });

    test('an answer that shows nothing, and one with no sound', () {
      final json = _course(recordingAnswer: true).toJson();
      for (final lesson in json['lessons'] as List) {
        for (final round in (lesson as Map)['rounds'] as List) {
          for (final content in (round as Map)['content'] as List) {
            if ((content as Map)['id'] != _exampleId) continue;
            final items = (content['exercise'] as Map)['items'] as List;
            // The recording without a text, and no own text.
            (items[1] as Map)['content'] = [
              {'role': 'primary', 'type': 'audio', 'recording': 'clip_dormono'},
            ];
            // An answer with no sound at all.
            (items[2] as Map)['content'] = [
              {'role': 'primary', 'type': 'audio'},
            ];
          }
        }
      }
      final found = codes(Course.fromJson(json));
      expect(found, contains(AuditCode.soundAnswerTextMissing.code));
      expect(found, contains(AuditCode.soundAnswerEmpty.code));
      expect(AuditCode.soundAnswerTextMissing.severity, AuditSeverity.info);
    });

    test('a recording an answer names is no orphan MP3', () {
      final course = _course(recordingAnswer: true);
      final orphans = CourseAuditService()
          .auditCourse(course)
          .issues
          .where((issue) => issue.code == AuditCode.audioMappingTextEmpty.code);
      expect(orphans, isEmpty);
      // Not named: the text-less recording is an orphan again.
      expect(
        CourseAuditService()
            .auditCourse(_course())
            .issues
            .where(
              (issue) => issue.code == AuditCode.audioMappingTextEmpty.code,
            ),
        hasLength(1),
      );
    });
  });

  group('the Audit, after the review', () {
    List<String> codes(Exercise exercise) => [
      for (final issue in CourseAuditService().auditExercise(exercise))
        issue.code,
    ];

    test('a recording in answers that are not sounds is an Error', () {
      final exercise = _exampleOf(_course(recordingAnswer: true));
      expect(
        codes(exercise),
        isNot(contains(AuditCode.soundAnswersNotPlayable.code)),
      );
      final tapped = exercise.copyWith(
        options: exercise.options.withEnum(
          OptionKey.evaluationTiming,
          EvaluationTiming.immediate,
        ),
      );
      expect(codes(tapped), contains(AuditCode.soundAnswersNotPlayable.code));
      // Inline gaps are never sounds either.
      final inline = exercise.copyWith(
        targets: [ExerciseTarget(id: 'gap')],
        layout: [
          LayoutElement.text('Il gatto'),
          LayoutElement.target('gap'),
          LayoutElement.text('sul divano.'),
        ],
      );
      expect(ExerciseFeatures(inline).selectInline, isTrue);
      expect(codes(inline), contains(AuditCode.soundAnswersNotPlayable.code));
      expect(AuditCode.soundAnswersNotPlayable.severity, AuditSeverity.error);
    });

    test('the spoken sentence and the gap the form asks for', () {
      final exercise = _example();
      expect(
        codes(exercise),
        isNot(
          anyOf(
            contains(AuditCode.listeningAudioRequired.code),
            contains(AuditCode.gapMarkerMissing.code),
          ),
        ),
      );
      final bare = exercise.copyWith(
        promptElements: [
          for (final element in exercise.promptElements)
            if (!element.isAudio)
              element.role == 'question'
                  ? PromptElement(
                      role: 'question',
                      type: 'text',
                      text: 'Il gatto sul divano.',
                    )
                  : element,
        ],
      );
      expect(
        codes(bare),
        containsAll([
          AuditCode.listeningAudioRequired.code,
          AuditCode.gapMarkerMissing.code,
        ]),
      );
    });

    test('an answer with no sound is one Error, not two', () {
      final exercise = _example();
      final silent = exercise.copyWith(
        items: [
          for (final (index, item) in exercise.items.indexed)
            index == 1
                ? ExerciseItem(
                    id: item.id,
                    content: [
                      PromptElement(type: 'audio', text: ''),
                      PromptElement(
                        role: 'after_answer',
                        type: 'text',
                        text: 'dormono',
                      ),
                    ],
                  )
                : item,
        ],
      );
      final found = codes(silent);
      expect(found, contains(AuditCode.soundAnswerEmpty.code));
      expect(found, isNot(contains(AuditCode.promptMediaUnsupported.code)));
    });
  });

  group('the Round screen', () {
    testWidgets('a Test Round marks nothing before its results', (
      tester,
    ) async {
      final course = _course(audioMode: 'tts');
      await _show(
        tester,
        course,
        _exampleOf(course),
        roundType: RoundType.test,
      );
      await tester.tap(find.byKey(const ValueKey('sound-answer-0')));
      await tester.pumpAndSettle();
      final check = find.byKey(const Key('sound-answers-check'));
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('sound-answer-text-$i')), findsOneWidget);
        expect(find.byKey(ValueKey('sound-answer-mark-$i')), findsNothing);
      }
    });

    testWidgets('picture answers graded on Check stay pictures', (
      tester,
    ) async {
      final lab = _course();
      final pictures = [
        for (final lesson in lab.lessons)
          for (final round in lesson.rounds) ...round.exercises,
      ].firstWhere((e) => e.id == 'qql_lab254_select_asset_options');
      final checked = pictures.copyWith(
        options: pictures.options.withEnum(
          OptionKey.evaluationTiming,
          EvaluationTiming.explicit,
        ),
      );
      await _show(tester, lab, checked);
      // The picture grid, not the list of words.
      expect(find.byKey(const ValueKey('single-check-option-0')), findsNothing);
      final tile = find.byKey(const ValueKey('picture-answer-square-0'));
      expect(tile, findsOneWidget);
      final submit = find.byKey(const Key('single-check-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      // A tap chooses; nothing is graded until Check.
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Correct').evaluate().isNotEmpty ||
            find.text('Incorrect').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('answers show their place, play on a tap, grade on Check', (
      tester,
    ) async {
      // On-Device TTS: every word is the voice's (in Hybrid a word with a
      // recording plays it, which this test does not watch).
      final course = _course(audioMode: 'tts');
      final speech = await _show(tester, course, _exampleOf(course));
      // The sentence plays by itself: nothing else yet.
      final before = [...speech.spoken];
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('sound-answer-$i')), findsOneWidget);
        expect(find.byKey(ValueKey('sound-answer-text-$i')), findsNothing);
        expect(find.text('Sound ${i + 1}'), findsOneWidget);
      }
      for (final word in ['dorme', 'dormono', 'dormire']) {
        expect(find.text(word), findsNothing);
      }
      final check = find.byKey(const Key('sound-answers-check'));
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      // A tap plays the answer and chooses it.
      await tester.tap(find.byKey(const ValueKey('sound-answer-0')));
      await tester.pumpAndSettle();
      expect(speech.spoken.skip(before.length), hasLength(1));
      final heard = speech.spoken.last;
      expect(['dorme', 'dormono', 'dormire'], contains(heard));
      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      expect(find.text('Correct'), findsNothing);
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      // Each answer now shows its text; one of them has its own.
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('sound-answer-text-$i')), findsOneWidget);
      }
      expect(find.text('dormono (they sleep)'), findsOneWidget);
      expect(find.text('dormono'), findsNothing);
      // The right answer is marked, and a wrong choice too.
      final marks = [
        for (var i = 0; i < 3; i++)
          if (find
              .byKey(ValueKey('sound-answer-mark-$i'))
              .evaluate()
              .isNotEmpty)
            i,
      ];
      expect(marks, hasLength(heard == 'dorme' ? 1 : 2));
      expect(
        heard == 'dorme' ? find.text('Correct') : find.text('Incorrect'),
        findsWidgets,
      );
    });

    testWidgets('a recording answer plays its recording, not a voice', (
      tester,
    ) async {
      final course = _course(allRecordings: true);
      final exercise = _exampleOf(course);
      final recorded = _Files({'clip_dormono', 'clip_dorme', 'clip_dormire'});
      final speech = await _show(
        tester,
        course,
        exercise,
        recordedAudio: recorded,
      );
      speech.spoken.clear();
      await tester.tap(find.byKey(const ValueKey('sound-answer-0')));
      await tester.pumpAndSettle();
      expect(recorded.played, hasLength(1));
      expect({
        'clip_dormono',
        'clip_dorme',
        'clip_dormire',
      }, contains(recorded.played.single));
      expect(speech.spoken, isEmpty);
    });

    testWidgets('in On-Device TTS a recording answer does not play', (
      tester,
    ) async {
      final course = _course(audioMode: 'tts', allRecordings: true);
      final exercise = _exampleOf(course);
      final recorded = _Files({'clip_dormono', 'clip_dorme', 'clip_dormire'});
      await _show(tester, course, exercise, recordedAudio: recorded);
      await tester.tap(find.byKey(const ValueKey('sound-answer-0')));
      await tester.pumpAndSettle();
      expect(recorded.played, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('plays no recordings'), findsOneWidget);
    });

    testWidgets('another single choice graded on Check', (tester) async {
      final lab = _course();
      final choose = [
        for (final lesson in lab.lessons)
          for (final round in lesson.rounds) ...round.exercises,
      ].firstWhere((exercise) => exercise.id == 'qql_lab254_select_single');
      final checked = choose.copyWith(
        options: choose.options.withEnum(
          OptionKey.evaluationTiming,
          EvaluationTiming.explicit,
        ),
      );
      expect(checked.isExecutable, isTrue);
      await _show(tester, lab, checked);
      expect(
        find.byKey(const ValueKey('single-check-option-0')),
        findsOneWidget,
      );
      final submit = find.byKey(const Key('single-check-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('single-check-option-0')));
      await tester.pumpAndSettle();
      // Chosen, not graded.
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Correct').evaluate().isNotEmpty ||
            find.text('Incorrect').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('the form', () {
    testWidgets('a new exercise from its fields, a recording among them', (
      tester,
    ) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: PresetRecipes.blankFor(
              _preset,
              'r274_3_form',
            ).withAuthoringMetadata({'presetId': _preset}),
            title: 'Listen and pick the missing word',
            isNew: true,
            course: _course(),
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-tts')),
        'Il gatto dorme sul divano.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'Il gatto ___ sul divano.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('sound-answer-word-0')),
        'dorme',
      );
      // The second answer is a recording of the Audio Library.
      await tester.tap(find.text('Recording').at(1));
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('sound-answer-recording-1'));
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      // Its text is empty: its place names it.
      await tester.tap(find.text('Recording 1').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('sound-answer-after-1')),
        'dormono',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-correct')),
        '1',
      );
      await tester.pump();
      final save = find.byKey(const Key('exercise-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      final f = ExerciseFeatures(saved!);
      expect(f.kind, LearnerExerciseKind.selectSounds);
      expect(f.soundOf(saved!.items[0])?.text, 'dorme');
      expect(f.soundOf(saved!.items[1])?.recording, 'clip_dormono');
      expect(f.afterAnswerTextOf(saved!.items[1]), 'dormono');
      expect(saved!.editorTemplate, _preset);
    });

    testWidgets('a new exercise typed in and cleared has no changes', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ExerciseEditorScreen(
                    exercise: PresetRecipes.blankFor(
                      _preset,
                      'r274_3_untouched',
                    ).withAuthoringMetadata({'presetId': _preset}),
                    title: 'Listen and pick the missing word',
                    isNew: true,
                    course: _course(),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final word = find.byKey(const ValueKey('sound-answer-word-0'));
      await tester.enterText(word, 'dorme');
      await tester.pump();
      await tester.enterText(word, '');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Exercise changes not applied'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('On-Device TTS offers words only', (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: PresetRecipes.blankFor(
              _preset,
              'r274_3_tts',
            ).withAuthoringMetadata({'presetId': _preset}),
            title: 'Listen and pick the missing word',
            isNew: true,
            course: _course(audioMode: 'tts'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sound-answer-word-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('sound-answer-kind-0')), findsNothing);
    });
  });

  group('the Audio Library', () {
    testWidgets('Delete asks first when answers play the recording', (
      tester,
    ) async {
      final course = _course(recordingAnswer: true);
      Course? left;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => left = await Navigator.push<Course>(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioLibraryScreen(course: course),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('audio-clip-row-clip_dormono'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      // Without a text, a recording answers name says where it is used.
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const Key('audio-clip-uses-clip_dormono')),
        ),
        findsOneWidget,
      );
      final delete = find.descendant(
        of: row,
        matching: find.byTooltip('Delete this recording'),
      );
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('audio-delete-named-dialog')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('audio-delete-named-0')), findsOneWidget);
      expect(
        find.textContaining('1 exercise plays this recording'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('audio-delete-named-cancel')));
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('audio-delete-named-confirm')));
      await tester.pumpAndSettle();
      expect(row, findsNothing);
      // A recording no answer names goes at once, as before.
      final other = find.byKey(const Key('audio-clip-row-clip_dorme'));
      await tester.ensureVisible(other);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: other,
          matching: find.byTooltip('Delete this recording'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('audio-delete-named-dialog')), findsNothing);
      expect(other, findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        [for (final clip in left!.audioLibrary) clip.id],
        ['clip_dormire'],
      );
    });

    testWidgets('switching to On-Device TTS warns first', (tester) async {
      final course = _course(recordingAnswer: true);
      Course? left;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => left = await Navigator.push<Course>(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioLibraryScreen(course: course),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      Future<void> chooseTts() async {
        await tester.tap(find.byKey(const Key('audio-source')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('On-Device TTS').last);
        await tester.pumpAndSettle();
      }

      await chooseTts();
      expect(find.byKey(const Key('audio-tts-named-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('audio-tts-named-keep')));
      await tester.pumpAndSettle();
      // The menu shows the source the Course keeps.
      expect(
        find.descendant(
          of: find.byKey(const Key('audio-source')),
          matching: find.text('Hybrid: MP3 + TTS fallback'),
        ),
        findsOneWidget,
      );
      await chooseTts();
      await tester.tap(find.byKey(const Key('audio-tts-named-switch')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(left?.audioMode, 'tts');
    });
  });
}

class _Speech extends TtsCacheService {
  final spoken = <String>[];

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
}

/// Recordings whose files are [present]; playing one records its id.
class _Files extends RecordedAudioService {
  _Files(this.present);
  final Set<String> present;
  final played = <String>[];

  @override
  Future<Source?> resolveSourceForClip(
    CourseAudioClip clip, {
    required String courseId,
  }) async => present.contains(clip.id)
      ? DeviceFileSource('/tmp/${clip.id}.mp3')
      : null;

  @override
  Future<bool> playClips(
    List<CourseAudioClip>? clips, {
    required String courseId,
    Duration gap = const Duration(milliseconds: 90),
    bool enableDiagnostics = true,
  }) async {
    if (clips == null || clips.isEmpty) return false;
    played.addAll(clips.map((clip) => clip.id));
    return true;
  }
}

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<_Speech> _show(
  WidgetTester tester,
  Course course,
  Exercise exercise, {
  RecordedAudioService? recordedAudio,
  RoundType? roundType,
}) async {
  _bigWindow(tester);
  final round = LearningRound(
    id: 'r274_3_${exercise.id}',
    title: 'Sounds',
    roundType: roundType,
    exercises: [exercise],
  );
  final lesson = Lesson(lessonId: 'r274_3', title: 'Sounds', rounds: [round]);
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: ValueKey(exercise.id),
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
        ttsCacheService: speech,
        recordedAudioService: recordedAudio ?? _Files(const {}),
      ),
    ),
  );
  await _until(
    tester,
    find.byKey(Key('exercise-renderer-${exercise.primitive.serialized}')),
  );
  await tester.pumpAndSettle();
  return speech;
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

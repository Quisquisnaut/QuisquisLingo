import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';

/// Build 256 Revision 5, Stage 1b: the presets Dialogue line and Story
/// cover are recipes over canonical data (built, decomposed, represented,
/// recognized), have their learner kinds, copy, field help and Audit rules.
final _stamp = DateTime.utc(2026, 9, 28);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _line(
  String id,
  String text, {
  String speakerId = '',
  String mode = 'both',
  String readAloud = 'story',
  String reveal = 'immediate',
  String language = '',
}) {
  final result = ExerciseDraftBuilder.build(
    ExerciseDraftValues(
      original: _blank(id),
      type: 'dialogue_line',
      publicationState: PublicationState.published,
      prompt: text,
      speakerId: speakerId,
      lineMode: mode,
      lineReadAloud: readAloud,
      lineTextReveal: reveal,
      lineLanguage: language,
    ),
  );
  expect(result.error, isNull, reason: id);
  return result.candidate!;
}

Exercise _cover(String id, {String title = '', String picture = ''}) {
  final result = ExerciseDraftBuilder.build(
    ExerciseDraftValues(
      original: _blank(id),
      type: 'story_cover',
      publicationState: PublicationState.published,
      prompt: title,
      imageAsset: picture,
    ),
  );
  expect(result.error, isNull, reason: id);
  return result.candidate!;
}

Exercise _select(String id) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: const [PromptElement(type: 'text', text: 'Vero?')],
  items: [
    ExerciseItem(
      id: '${id}_a',
      content: const [PromptElement(type: 'text', text: 'sì')],
    ),
    ExerciseItem(
      id: '${id}_b',
      content: const [PromptElement(type: 'text', text: 'no')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_a'],
  ),
  updatedAt: _stamp,
);

Map<String, dynamic> _demoJson() =>
    jsonDecode(
          File(
            'demo_courses/italian_demo_2_pick_the_translation.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Map<String, dynamic> _round(
  String id,
  List<Exercise> exercises, {
  String? storyTitle,
}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: id,
    updatedAt: _stamp,
    title: storyTitle == null ? id : 'Story: $storyTitle',
    visualType: storyTitle == null ? 'generic' : 'story',
    content: content,
    flow: storyTitle == null
        ? null
        : RoundFlowAuthoring.linearFor(content, title: storyTitle),
  ).toJson();
}

void main() {
  group('Dialogue line recipe', () {
    test('text and audio, the Story default read-aloud, text after audio', () {
      final line = _line(
        'l1',
        'Buongiorno!',
        speakerId: 'character_anna',
        reveal: 'afterAudio',
      );
      expect(line.primitive, ExercisePrimitive.presentation);
      final f = ExerciseFeatures(line);
      expect(f.kind, LearnerExerciseKind.dialogueLine);
      expect(f.lineMode, 'both');
      expect(f.lineText, 'Buongiorno!');
      expect(f.lineAudio!.text, 'Buongiorno!');
      expect(f.lineAudio!.isRequired, isFalse, reason: 'optional next to text');
      expect(f.lineAudio!.playback, isNull, reason: 'follows the Story');
      expect(f.lineReadAloud, 'story');
      expect(f.speakerId, 'character_anna');
      expect(f.textReveal, TextReveal.afterAudio);
      expect(f.lineLanguage, '', reason: "the speaker's language");
      expect(f.requiresAudio, isFalse, reason: 'readable without audio');
      expect(f.completionMode, CompletionMode.proceed);
    });

    test('audio only is a listening step; text only has no audio', () {
      final audio = _line('l2', 'Ciao!', mode: 'audio', readAloud: 'manual');
      final fa = ExerciseFeatures(audio);
      expect(fa.kind, LearnerExerciseKind.dialogueLine);
      expect(fa.lineMode, 'audio');
      expect(fa.lineText, '');
      expect(fa.lineAudio!.text, 'Ciao!');
      expect(fa.lineAudio!.isRequired, isTrue);
      expect(fa.lineAudio!.playback, AudioPlayback.manual);
      expect(fa.lineReadAloud, 'manual');
      expect(fa.requiresAudio, isTrue);
      expect(fa.textReveal, TextReveal.immediate, reason: 'nothing to hide');
      final text = _line(
        'l3',
        'Grazie.',
        mode: 'text',
        readAloud: 'automatic',
        language: 'source',
      );
      final ft = ExerciseFeatures(text);
      expect(ft.lineMode, 'text');
      expect(ft.lineAudio, isNull);
      expect(ft.lineLanguage, 'source');
      expect(ft.requiresAudio, isFalse);
    });

    test('is represented, decomposed and recognized as its own preset', () {
      for (final line in [
        _line('a', 'Buongiorno!', speakerId: 'character_anna'),
        _line('b', 'Ciao!', mode: 'audio', readAloud: 'automatic'),
        _line('c', 'Grazie.', mode: 'text', language: 'target'),
        _line('d', 'Prego.', readAloud: 'manual', reveal: 'afterAudio'),
      ]) {
        expect(PresetRecipes.represents(line, 'dialogue_line'), isTrue);
        expect(PresetRecipes.represents(line, 'note_card'), isFalse);
        expect(PresetRecipes.represents(line, 'flashcard'), isFalse);
        final stripped = line.withAuthoringMetadata(const {});
        expect(PresetRecipes.recognize(stripped), 'dialogue_line');
        expect(PresetRecipes.presetToEdit(stripped), 'dialogue_line');
        expect(PresetVariants.fits('dialogue_line', line), isTrue);
        expect(PresetVariants.fits('story_cover', line), isFalse);
      }
      final draft = PresetRecipes.decompose(
        _line(
          'e',
          'Un caffè, per favore.',
          speakerId: 'character_marco',
          mode: 'both',
          readAloud: 'manual',
          reveal: 'afterAudio',
          language: 'target',
        ),
        'dialogue_line',
      );
      expect(draft.prompt, 'Un caffè, per favore.');
      expect(draft.speakerId, 'character_marco');
      expect(draft.lineMode, 'both');
      expect(draft.lineReadAloud, 'manual');
      expect(draft.lineTextReveal, 'afterAudio');
      expect(draft.lineLanguage, 'target');
      expect(draft.question, '');
      expect(draft.tts, '');
    });
  });

  group('Story cover recipe', () {
    test('picture and optional title; represented and recognized', () {
      final cover = _cover(
        'c1',
        title: 'Al bar',
        picture: 'assets/avatars/cat.png',
      );
      final f = ExerciseFeatures(cover);
      expect(f.kind, LearnerExerciseKind.storyCover);
      expect(f.coverTitle, 'Al bar');
      expect(f.illustrationAsset, 'assets/avatars/cat.png');
      expect(PresetRecipes.represents(cover, 'story_cover'), isTrue);
      expect(PresetRecipes.represents(cover, 'picture_flashcard'), isFalse);
      expect(
        PresetRecipes.recognize(cover.withAuthoringMetadata(const {})),
        'story_cover',
      );
      final onlyPicture = _cover('c2', picture: 'assets/avatars/dog.png');
      expect(
        ExerciseFeatures(onlyPicture).kind,
        LearnerExerciseKind.storyCover,
      );
      final onlyTitle = _cover('c3', title: 'Al bar');
      expect(ExerciseFeatures(onlyTitle).kind, LearnerExerciseKind.storyCover);
      expect(PresetRecipes.decompose(cover, 'story_cover').prompt, 'Al bar');
      expect(
        PresetRecipes.decompose(cover, 'story_cover').imageAsset,
        'assets/avatars/cat.png',
      );
    });

    test('a flashcard and a note card keep the presentation kind', () {
      final card = Exercise.canonical(
        id: 'card',
        primitive: ExercisePrimitive.presentation,
        promptElements: const [
          PromptElement(role: 'term', type: 'text', text: 'gatto'),
          PromptElement(role: 'meaning', type: 'text', text: 'cat'),
          PromptElement(
            role: 'picture',
            type: 'image',
            asset: 'assets/avatars/cat.png',
          ),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
        updatedAt: _stamp,
      );
      expect(ExerciseFeatures(card).kind, LearnerExerciseKind.presentation);
      expect(PresetVariants.fits('story_cover', card), isFalse);
      expect(PresetVariants.fits('dialogue_line', card), isFalse);
    });
  });

  test('registry, copy, field help and Search know the two presets', () {
    final line = ExercisePresetRegistry.byId('dialogue_line')!;
    expect(line.category, ExerciseCategory.cardsAndNotes);
    expect(line.primitive, ExercisePrimitive.presentation);
    expect(line.base, 'dialogue_line');
    expect(ExercisePresetRegistry.byId('story_cover')!.base, 'story_cover');
    // 43 since Build 257 added Before you start.
    expect(ExercisePresetRegistry.presets, hasLength(43));
    expect(
      ExercisePresetRegistry.helpByPreset['dialogue_line'],
      contains('narrator'),
    );
    expect(PresetRecipes.kinds['dialogue_line'], {
      LearnerExerciseKind.dialogueLine,
    });
    expect(PresetRecipes.kinds['story_cover'], {
      LearnerExerciseKind.storyCover,
    });
    expect(PresetVariants.formFor('dialogue_line'), 'dialogue_line');
    expect(PresetVariants.formFor('story_cover'), 'story_cover');
    final course = Course.fromJson(_demoJson());
    final fallback = ExerciseCopyService.typeLabel(
      course,
      LearnerExerciseKind.other,
    );
    expect(
      ExerciseCopyService.typeLabel(course, LearnerExerciseKind.dialogueLine),
      isNot(fallback),
    );
    expect(
      ExerciseCopyService.typeLabel(course, LearnerExerciseKind.storyCover),
      isNot(fallback),
    );
    expect(ExerciseFieldHelpRegistry.editorFieldKeys('dialogue_line').take(6), [
      'speaker',
      'prompt',
      'lineMode',
      'readAloud',
      'textReveal',
      'language',
    ]);
    expect(ExerciseFieldHelpRegistry.editorFieldKeys('story_cover').take(2), [
      'prompt',
      'image',
    ]);
    expect(
      ExerciseFieldHelpRegistry.forEditorField(
        'dialogue_line',
        'speaker',
      ).title,
      'Speaker',
    );
    expect(
      ExerciseFieldHelpRegistry.forEditorField('story_cover', 'image').title,
      'Cover picture',
    );
    expect(
      ExerciseFieldHelpRegistry.forEditorField('story_cover', 'prompt').title,
      'Title line',
    );
  });

  test('the Audit checks Stories, speakers and lines', () {
    final json = _demoJson();
    json['storyCharacters'] = [
      {'id': 'character_anna', 'name': 'Anna', 'language': 'target'},
    ];
    final lesson = (json['lessons'] as List).first as Map;
    final rounds = lesson['rounds'] as List;
    rounds.addAll([
      _round('untitled', [
        _cover('cov', title: 'Al bar'),
        _line('ok', 'Buongiorno!', speakerId: 'character_anna'),
        _line('ghost', 'Chi sei?', speakerId: 'character_ghost'),
        _line('empty', '   '),
        _select('q1'),
      ], storyTitle: ''),
      _round('silent', [_select('q2')], storyTitle: 'Silent'),
      _round('plain', [_line('stray', 'Ciao!')]),
    ]);
    // Round IDs and flow titles: an empty Story title is the missing one.
    final course = Course.fromJson(json);
    final issues = CourseAuditService().auditCourse(course).issues;
    String codes(String roundId) => issues
        .where((issue) => issue.roundId == roundId)
        .map(
          (issue) =>
              '${issue.code}${issue.exerciseId == null ? '' : ':${issue.exerciseId}'}',
        )
        .join(' ');
    expect(codes('untitled'), contains('STORY_TITLE_MISSING'));
    expect(codes('untitled'), contains('STORY_SPEAKER_UNKNOWN:ghost'));
    expect(codes('untitled'), contains('DIALOGUE_LINE_EMPTY:empty'));
    expect(codes('untitled'), isNot(contains('STORY_WITHOUT_DIALOGUE')));
    expect(codes('untitled'), isNot(contains('FLASHCARD')));
    expect(codes('silent'), contains('STORY_WITHOUT_DIALOGUE'));
    expect(codes('silent'), isNot(contains('STORY_TITLE_MISSING')));
    expect(codes('plain'), contains('DIALOGUE_LINE_OUTSIDE_STORY:stray'));
    expect(codes('plain'), isNot(contains('STORY_')));
    final severities = {for (final issue in issues) issue.code: issue.severity};
    expect(severities['STORY_SPEAKER_UNKNOWN'], AuditSeverity.error);
    expect(severities['DIALOGUE_LINE_EMPTY'], AuditSeverity.error);
    expect(severities['STORY_TITLE_MISSING'], AuditSeverity.warning);
    expect(severities['STORY_WITHOUT_DIALOGUE'], AuditSeverity.warning);
    expect(severities['DIALOGUE_LINE_OUTSIDE_STORY'], AuditSeverity.warning);
  });
}

import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';

/// A Course an external converter could write (Build 256 Revision 6, the
/// plan's final acceptance scenario): Course Model v12 with no authoring
/// metadata anywhere, every primitive, a Story whose cover and lines carry
/// no preset, a practice Round of exercises this version cannot play, a
/// Story that ends on one, and a Round whose flow branches.
const canonicalCourse256ProfileId = '12345678-1234-4234-9234-123456789abc';
final canonicalCourse256Stamp = DateTime.utc(2026, 9, 29, 8);

/// Round IDs of [canonicalCourse256].
abstract final class CanonicalRounds256 {
  static const play = 'r_play';
  static const later = 'r_later';
  static const story = 'r_story';
  static const endsLater = 'r_ends_later';
  static const branch = 'r_branch';
}

PromptElement _text(String text, {String role = 'primary'}) =>
    PromptElement(type: 'text', text: text, role: role);

ExerciseItem _item(String id, String text, {MatchSide? side}) =>
    ExerciseItem(id: id, content: [_text(text)], side: side);

Exercise _exercise(
  String id,
  ExercisePrimitive primitive, {
  Map<OptionKey, OptionValue> options = const {},
  List<PromptElement> prompt = const [],
  List<ExerciseItem> items = const [],
  List<ExerciseTarget> targets = const [],
  List<LayoutElement> layout = const [],
  required CanonicalEvaluation evaluation,
}) => Exercise.canonical(
  id: id,
  primitive: primitive,
  options: PrimitiveOptions(options),
  promptElements: prompt,
  items: items,
  targets: targets,
  layout: layout,
  canonicalEvaluation: evaluation,
  updatedAt: canonicalCourse256Stamp,
);

Exercise _blankPresentation(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: canonicalCourse256Stamp,
);

/// A Dialogue line as an external tool would write it: the canonical shape
/// QQL's recipe builds, without the preset.
Exercise canonicalLine256(
  String id,
  String text, {
  String speakerId = '',
  String mode = 'text',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blankPresentation(id),
    type: 'dialogue_line',
    publicationState: PublicationState.published,
    prompt: text,
    speakerId: speakerId,
    lineMode: mode,
  ),
).candidate!.copyWith(authoringMetadata: const {});

/// A Story cover without its preset.
Exercise canonicalCover256(String id, String titleLine) =>
    ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _blankPresentation(id),
        type: 'story_cover',
        publicationState: PublicationState.published,
        prompt: titleLine,
      ),
    ).candidate!.copyWith(authoringMetadata: const {});

Exercise canonicalSelect256(
  String id,
  String question,
  List<String> choices, {
  Map<OptionKey, OptionValue> options = const {},
}) => _exercise(
  id,
  ExercisePrimitive.select,
  options: options,
  prompt: [_text(question, role: 'question')],
  items: [
    for (var i = 0; i < choices.length; i++) _item('${id}_$i', choices[i]),
  ],
  evaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_0'],
  ),
);

/// The exercises this version plays, one per playable shape.
List<Exercise> canonicalPlayable256() => [
  canonicalSelect256('sel_one', 'Which is a cat?', ['gatto', 'cane']),
  _exercise(
    'sel_many',
    ExercisePrimitive.select,
    options: {
      OptionKey.selectionMode: const EnumOptionValue(SelectionMode.multiple),
      OptionKey.evaluationTiming: const EnumOptionValue(
        EvaluationTiming.explicit,
      ),
    },
    prompt: [_text('Which are animals?', role: 'question')],
    items: [
      _item('sel_many_0', 'gatto'),
      _item('sel_many_1', 'cane'),
      _item('sel_many_2', 'casa'),
    ],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.exactSet,
      correctItemIds: ['sel_many_0', 'sel_many_1'],
    ),
  ),
  _exercise(
    'inp_text',
    ExercisePrimitive.input,
    prompt: [_text('Translate: the cat', role: 'question')],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.acceptedTexts,
      answers: ['il gatto', 'gatto'],
    ),
  ),
  _exercise(
    'arr_order',
    ExercisePrimitive.arrange,
    prompt: [_text('The cat sleeps', role: 'clue')],
    items: [
      _item('arr_order_0', 'Il'),
      _item('arr_order_1', 'gatto'),
      _item('arr_order_2', 'dorme'),
    ],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.acceptedOrders,
      correctOrders: [
        OrderedAnswer(
          text: 'Il gatto dorme',
          itemIds: ['arr_order_0', 'arr_order_1', 'arr_order_2'],
        ),
      ],
    ),
  ),
  _exercise(
    'match_pairs',
    ExercisePrimitive.match,
    prompt: [_text('Match the words', role: 'question')],
    items: [
      _item('match_l0', 'gatto', side: MatchSide.left),
      _item('match_l1', 'cane', side: MatchSide.left),
      _item('match_r0', 'cat', side: MatchSide.right),
      _item('match_r1', 'dog', side: MatchSide.right),
    ],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.exactRelations,
      relations: [
        ['match_l0', 'match_r0'],
        ['match_l1', 'match_r1'],
      ],
    ),
  ),
  _exercise(
    'note',
    ExercisePrimitive.presentation,
    prompt: [
      _text('Buongiorno', role: 'term'),
      _text('Good morning, said until early afternoon.', role: 'meaning'),
    ],
    evaluation: CanonicalEvaluation.none,
  ),
];

/// Legal exercises this version cannot play: one per primitive that has no
/// runtime yet, plus playable primitives in configurations outside the
/// runtime-support table.
List<Exercise> canonicalNotExecutable256() => [
  canonicalSelect256(
    'sel_later',
    'Which is a dog?',
    ['cane', 'gatto'],
    options: {
      OptionKey.evaluationTiming: const EnumOptionValue(
        EvaluationTiming.onCompletion,
      ),
    },
  ),
  _exercise(
    'inp_number',
    ExercisePrimitive.input,
    options: {OptionKey.inputMode: const EnumOptionValue(InputMode.number)},
    prompt: [_text('How many legs has a cat?', role: 'question')],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.numericExact,
      numeric: NumericAnswer(value: 4),
    ),
  ),
  _exercise(
    'match_connect',
    ExercisePrimitive.match,
    options: {
      OptionKey.interactionStyle: const EnumOptionValue(
        MatchInteractionStyle.connect,
      ),
    },
    prompt: [_text('Connect the pairs', role: 'question')],
    items: [
      _item('con_l0', 'uno', side: MatchSide.left),
      _item('con_r0', 'one', side: MatchSide.right),
    ],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.exactRelations,
      relations: [
        ['con_l0', 'con_r0'],
      ],
    ),
  ),
  // Groups play since Build 256 Revision 7; drag placement still waits, so
  // this one stays an exercise this version cannot play.
  _exercise(
    'assign_groups',
    ExercisePrimitive.assign,
    options: {
      OptionKey.targetMode: const EnumOptionValue(AssignTargetMode.categories),
      OptionKey.placementMode: const EnumOptionValue(PlacementMode.drag),
    },
    prompt: [_text('Sort the words', role: 'question')],
    items: [_item('as_0', 'gatto'), _item('as_1', 'mela')],
    targets: const [
      ExerciseTarget(id: 'animals'),
      ExerciseTarget(id: 'food'),
    ],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.exactAssignments,
      assignments: [
        TargetAssignment(targetId: 'animals', itemIds: ['as_0']),
        TargetAssignment(targetId: 'food', itemIds: ['as_1']),
      ],
    ),
  ),
  _exercise(
    'speak_repeat',
    ExercisePrimitive.speak,
    options: {OptionKey.speechMode: const EnumOptionValue(SpeechMode.repeat)},
    prompt: [_text('Buongiorno')],
    evaluation: const CanonicalEvaluation(
      mode: EvaluationMode.transcriptionMatch,
      answers: ['Buongiorno'],
    ),
  ),
  _exercise(
    'ink_trace',
    ExercisePrimitive.ink,
    options: {OptionKey.inkMode: const EnumOptionValue(InkMode.trace)},
    prompt: [_text('Trace the letter à')],
    evaluation: const CanonicalEvaluation(mode: EvaluationMode.none),
  ),
  _exercise(
    'submit_audio',
    ExercisePrimitive.submit,
    options: {
      OptionKey.submissionType: const EnumOptionValue(SubmissionType.audio),
    },
    prompt: [_text('Record yourself greeting a friend')],
    evaluation: const CanonicalEvaluation(mode: EvaluationMode.presence),
  ),
];

LearningRound _round(
  String id,
  String title,
  List<Exercise> exercises, {
  bool story = false,
  ContentFlow? flow,
}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: id,
    title: title,
    updatedAt: canonicalCourse256Stamp,
    content: content,
    flow:
        flow ??
        (story
            ? RoundFlowAuthoring.linearFor(
                content,
                presentation: FlowPresentation.scroll,
                title: title,
                log: FlowLog.dialogue,
                readAloud: FlowReadAloud.manual,
              )
            : null),
  );
}

/// The Story: a cover, lines and questions without any preset metadata.
LearningRound canonicalStory256() => _round('r_story', 'Al bar', [
  canonicalCover256('cover', 'A morning in Turin'),
  canonicalLine256('line_1', 'Anna walks into the café.'),
  canonicalLine256(
    'line_2',
    'Buongiorno! Un caffè, per favore.',
    speakerId: 'anna',
  ),
  canonicalSelect256('story_q1', 'What did Anna order?', ['Un caffè', 'Un tè']),
  canonicalLine256('line_3', 'The barista smiles.'),
  canonicalSelect256('story_q2', 'Where is Anna?', ['In a café', 'At home']),
], story: true);

Course canonicalCourse256() => Course(
  courseId: 'external_v12_course',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: canonicalCourse256ProfileId,
    displayName: 'External converter',
  ),
  maintainer: const CourseMaintainer(canonicalCourse256ProfileId),
  courseVersion: '1',
  title: 'External converter course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyNarrator: const StorySpeaker(
    name: 'Narrator',
    language: TextLanguage.source,
  ),
  storyCharacters: const [
    StorySpeaker(id: 'anna', name: 'Anna', language: TextLanguage.target),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson_external',
      title: 'Imported lesson',
      updatedAt: canonicalCourse256Stamp,
      rounds: [
        _round(CanonicalRounds256.play, 'Playable', canonicalPlayable256()),
        _round(
          CanonicalRounds256.later,
          'For a later version',
          canonicalNotExecutable256(),
        ),
        canonicalStory256(),
        _round(CanonicalRounds256.endsLater, 'Ends later', [
          canonicalCover256('cover_2', 'An unfinished morning'),
          canonicalLine256('line_4', 'Anna leaves.'),
          canonicalSelect256(
            'sel_later_2',
            'Who leaves?',
            ['Anna', 'The barista'],
            options: {
              OptionKey.evaluationTiming: const EnumOptionValue(
                EvaluationTiming.onCompletion,
              ),
            },
          ),
        ], story: true),
        _round(
          CanonicalRounds256.branch,
          'Branching',
          [
            canonicalSelect256('br_q1', 'Coffee or tea?', ['Coffee', 'Tea']),
            canonicalSelect256('br_q2', 'Sugar?', ['Yes', 'No']),
            canonicalSelect256('br_q3', 'Milk?', ['Yes', 'No']),
          ],
          flow: ContentFlow(
            startNodeId: 'n1',
            nodes: const [
              FlowNode(
                id: 'n1',
                kind: FlowNodeKind.exercise,
                contentId: 'br_q1',
                transitions: [
                  FlowTransition(
                    trigger: FlowTrigger.onCorrect,
                    targetNodeId: 'n2',
                  ),
                  FlowTransition.next('n3'),
                ],
              ),
              FlowNode(
                id: 'n2',
                kind: FlowNodeKind.exercise,
                contentId: 'br_q2',
              ),
              FlowNode(
                id: 'n3',
                kind: FlowNodeKind.exercise,
                contentId: 'br_q3',
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);

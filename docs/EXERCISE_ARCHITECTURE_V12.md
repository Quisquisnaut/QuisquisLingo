# Exercise architecture, Course Model v12 (Build 256)

This is the engineering reference for the exercise architecture QQL adopts
in Build 256. It replaces `EXERCISE_ARCHITECTURE_224.md`, which stays as the
historical record of the Build 224 design (five canonical models, presets as
the unit of behavior). The plan and the owner's decisions are in
`256_EXERCISE_ARCHITECTURE_PLAN.md`; this document is updated by every
Build 256 session and states, at each point, what is implemented and what is
still planned.

## The four layers

QQL keeps four concepts apart and never conflates them:

| Layer | Question it answers | Where it lives |
| --- | --- | --- |
| **Primitive** | What fundamental action does the learner perform? | `ExercisePrimitive` (`lib/models/canonical/exercise_primitive.dart`) |
| **Options** | How does that primitive behave? | `PrimitiveOptions` and the registry (`primitive_options.dart`, `primitive_capability_registry.dart`) |
| **Preset** | Which common canonical configuration does the Course Editor make easy to author? | `ExercisePresetRegistry` (`lib/models/exercise_authoring.dart`), authoring metadata only |
| **Content flow** | How are content and exercises ordered or branched? | `ContentFlow` (`content_flow.dart`) |

An exercise is fully described by: primitive, options, prompt/content/media,
items and/or targets, layout, evaluation, feedback. A preset may be recorded
as authoring metadata, but nothing that learners see, and nothing that grades,
validates, imports or exports, reads it. Removing the preset metadata changes
nothing; unknown preset metadata invalidates nothing; two exercises that differ
only in preset or editor metadata are semantically equal.

## Status by session

| Session | Delivered |
| --- | --- |
| 1 (Revision 0) | The canonical definitions below: nine primitives, typed options, evaluation modes, the capability registry with rules and the runtime-support table, the content-flow model with structural checks. No Course JSON or learner behavior changed; `ExercisePreset.primitive` replaced the five-value `CanonicalExerciseModel`. |
| 2 (Revision 1) | Done: Course Model v12 serialization (the "Course Model v12 JSON" section below), converter and tools, storage cut, semantic equality. The runtime, Audit and editor still read v11-shaped views until Sessions 3–4. |
| 3 (Revision 2) | Done: learner runtime, Duel and Course Audit on canonical data (`ExerciseFeatures`, `LearnerExerciseKind`); linear Stories play; capability-based Duel; content-based gap grading. The editor still reads the v11 views until Session 4. |
| 4 (Revision 3) | Done: presets as recipes (`PresetRecipes`: decompose, rebuild, represent, recognize), exact recognition and metadata clearing on save (`CanonicalExerciseDraft`), the Generic Primitive Editor (`PrimitiveEditorScreen`, controls and values from the registry, runtime-support line, Preview, Inspection), Stories kept through every Round rebuild and the Round editor's Play as a Story switch (`RoundFlowAuthoring`), canonical reads in Search, hierarchy update, Recognize characters and the Course Editor, Help in EN/IT/ES. Follow-up: `flow.presentation` (step or scroll) with the scrolling Story in `RoundScreen`, discard prompts by comparison, required options for Assign/Submit drafts, the two New exercise buttons, the Draft Exercises message, the first-time introduction. |
| 5 (Revision 4) | Done: the preset catalogue (`docs/256_PRESET_CATALOGUE_PLAN.md`): 38 presets in six skill groups, to-target/to-source twins, seven greyed presets, successors for the ten retired IDs, `PresetVariants` over the older recipes with shape hints, the picker's groups, chips and filter, pictures on answers, `arrangeLines`, within-word gaps, the source voice; the Laboratory and the Piedmontese demo regenerated. Not done: the save guard on example content (no form prefills examples). |
| 6 (Revision 5) | Done: Stories (`docs/256_STORY_PLAN.md`): narrator and reusable characters as Course data (`storyNarrator`, `storyCharacters`, avatars, voice preference), the Dialogue line and Story cover presets (canonical only; `speakerId` on elements, the `textReveal` option), the flow's `title`, `log`, `readAloud` and per-node `requiresAudio`, the Story options in the Round editor, the Story Wizard, lines never skipped and audio-dependent exercises skipped, Story exercises out of the Duel, a Story Lesson in each bundled demo. |
| 7 (Revision 6) | Done: support states at runtime (A.6: `Exercise.runtimeSupport`, practice Rounds skip, Stories and the Preview show a card, the Duel excludes, `EXERCISE_NOT_EXECUTABLE` and `ROUND_NOT_COMPLETABLE`, the import review count), the stand-alone `FlowEngine` (A.7; not wired to playback), interoperability on canonical semantics (`CanonicalConfiguration`, presets as hints, `NormalizedImportExercise`, `CanonicalExerciseImport`), the capability description (`docs/capabilities_v12.json`, `tools/export_capabilities.dart`, the Python tools reading it), the end-to-end acceptance scenario. Adventures and spoken exercises are parked. |
| 8 (Revision 7) | Done: the Assign runtime (groups, slots, gaps by tapping; `ASSIGN_STRUCTURE_REQUIRED`; the presets Sort into groups and Fill the slots since the same-version follow-up), the Laboratory's Assign Lesson (126 examples after the follow-up) and the test-only future fixture written by the same generator (Speak, Ink, Submit, a Story ending on speech, a branching Story), the negative and semantic-equality tests, the final verification. The redesign is complete. |
| Build 257 (Revision 0) | Done: interactive presentation cards, first slice: the presentation option `guidebookButton` and the **Before you start** card (a presentation whose text element has role `intro`; preset `before_you_start`; `LearnerExerciseKind.roundIntro`), shown on its own page before the Round starts, never a step and never in Review; the v11 converter turns `lesson_intro` notes into cards and v12 shows no other introduction. |
| Build 258 (Revision 0) | Done: Page cards, model and learner display (`docs/258_PAGE_CARD_PLAN.md`): a presentation whose elements have role `block`; element attributes `textStyle`, `align`, `color`, `size`, `readAloud` and the element type `link` with `url` (`pageElementAttributeTypes`, `elementAttributes` in `docs/capabilities_v12.json`); inline marks `**bold**` and `*italic*`; the Page renderer; `PAGE_EMPTY`, `PAGE_MARK_UNMATCHED`, `PAGE_LINK_INVALID`; a Course with a Page records `minimumAppBuild` 258000. |
| Build 265 (Revision 11) | Done: plural pictures: the element attribute `plural` on an `image` element or an `icon` text element (`pluralTextRoles`), the learner sees stacked copies (`PluralPicture`); a Course that marks one records `minimumAppBuild` 265011. |

## The nine primitives

Serialized identifiers are lowercase and parsed strictly (`Select` is not
`select`; an unknown value is a `FormatException`, never a default).

| Primitive | Learner action | Items | Targets | Runtime today |
| --- | --- | --- | --- | --- |
| `select` | Selects one or more selectable entities. | yes | inline gaps, regions, cells | yes |
| `input` | Enters textual, symbolic or numeric information. | no | inline gaps become fields | yes |
| `arrange` | Orders or places item occurrences into an ordered result. | yes (occurrences) | inline gaps | yes |
| `match` | Establishes relationships between peer items. | yes (with a side) | no | yes |
| `assign` | Places items into explicit targets, categories, gaps, regions or cells. | yes | always | Session 6 |
| `speak` | Produces speech. | no | no | no |
| `ink` | Produces spatial strokes. | no | no | no |
| `submit` | Supplies an artifact QQL does not necessarily interpret. | no | no | no |
| `presentation` | Consumes instructional material without a scored response. | no | no | yes |

Not primitives: translation, cloze, multiple choice, true/false, reading and
listening comprehension, hotspot, word search, crossword, dialogue, Story,
interactive video, branching scenario. Each is a primitive plus options,
media, layout, evaluation or a content flow.

## Options

Every option is an `OptionKey` with a stable JSON name and a value kind
(enumeration, boolean, integer, language tag). Enumerated values come from
closed Dart enums that implement `OptionEnumValue`; the JSON value is the
enum's `serialized` string. `OptionValue.parse` never coerces: `"true"` is
not a boolean, `2.0` is not an integer, `"Single"` is not `single`, and a
value outside the vocabulary is dropped and reported rather than defaulted.

`PrimitiveOptions` is the immutable, order-independent map an exercise
carries. It stores only what was given; the registry resolves an omitted
option to the primitive's default (`effectiveOptions`).

### Per primitive (legal values · default; **required** where marked)

**Select** — `selectionMode` single|multiple · single; `selectionTarget`
items|textSpans|regions|cells · items; `minimumSelections` integer ≥ 1 · 1;
`maximumSelections` integer ≥ 1 · absent (all items); `itemReuse`
forbidden|allowed|unlimited · forbidden; `layout` list|grid|inline|overlay ·
list; `evaluationTiming` immediate|explicit|onCompletion · immediate;
`shuffleItems` boolean · true.

**Input** — `inputMode` text|number|date|formula|code · text; `cardinality`
single|multiple · single; `layout` field|inlineGaps|grid|multiline · field;
`caseHandling` exact|ignore · ignore; `punctuationHandling` exact|ignore ·
ignore; `whitespaceHandling` exact|normalize · normalize; `accentHandling`
exact|missingAccentsAccepted|ignore · missingAccentsAccepted; `typoTolerance`
none|conservative · none; `evaluationTiming` explicit|onCompletion · explicit.

**Arrange** — `placementMode` sequence|inlineGaps|grid · sequence; `itemReuse`
forbidden · forbidden (Arrange consumes occurrences; a word used twice needs
two blocks); `unusedItems` forbidden|allowed · allowed; `layout`
horizontal|vertical|wrapped|inline|grid · wrapped; `shuffleItems` boolean ·
true; `joiner` space|none · space; `evaluationTiming` explicit|onCompletion ·
explicit.

**Match** — `relationship` oneToOne|oneToMany|manyToOne|manyToMany ·
oneToOne; `interactionStyle` pair|dropdown|connect|memory · dropdown;
`itemReuse` forbidden|allowed · forbidden; `layout` columns|cards|free ·
columns; `shuffleLeft` boolean · true; `shuffleRight` boolean · true;
`evaluationTiming` explicit|onCompletion · explicit.

**Assign** — **`targetMode`** categories|slots|gaps|regions|cells (required);
`targetCapacity` single|multiple|unlimited · single; `itemReuse`
forbidden|allowed|unlimited · forbidden; `placementMode`
drag|selectTarget|tapTarget · tapTarget; `layout`
inline|columns|overlay|grid|free · columns; `shuffleItems` boolean · true;
`evaluationTiming` explicit|onCompletion · explicit.

**Speak** — `speechMode` repeat|readAloud|freeResponse · repeat;
`captureMode` microphone · microphone; `language` language tag · absent (the
Course target language); `transcription` none|optional|required · optional;
`playback` none|allowed|requiredBeforeSubmit · allowed; `evaluationTiming`
explicit|onCompletion · explicit; `maxDurationSeconds` integer ≥ 1 · absent
(no limit).

**Ink** — `inkMode` freehand|trace|character|diagram · freehand;
`inputDevice` pointer|touch|stylus|any · any; `strokeOrder` ignored|checked ·
ignored; `templateVisible` boolean · false; `eraseAllowed` boolean · true;
`evaluationTiming` explicit|onCompletion · explicit.

**Submit** — **`submissionType`** audio|video|image|file|textDocument
(required); `cardinality` single|multiple · single; `captureSource`
device|file|either · either; `reviewMode` self|manual|external · self;
`evaluationTiming` none|onCompletion · onCompletion.

**Presentation** — `completionMode` continue|acknowledge|understoodReview|
automatic · continue; `navigation` singlePage|paged · singlePage;
`mediaPlayback` manual|automatic|none · manual; `scoring` none · none;
`evaluationTiming` none · none.

`layout` and `placementMode` are shared keys whose vocabulary is the union
over primitives; the registry allows each primitive its own subset. The
`overlay` layout (Select regions, Assign regions) and the Arrange `grid`
layout are additions to the plan's A.4 list, needed so that every legal
`selectionTarget`/`placementMode` has a layout to live in.

## Evaluation modes

| Primitive | Modes (default first) |
| --- | --- |
| Select | exactItem, exactSet, subset, orderedSelections, perSelection |
| Input | expression, exactText, acceptedTexts, numericExact, numericRange, numericTolerance, regex, manual |
| Arrange | exactOrder, acceptedOrders, gapAssignments |
| Match | exactRelations, requiredRelations, partialRelations |
| Assign | exactAssignments, acceptedTargets, categoryMembership, partialAssignments |
| Speak | transcriptionMatch, acceptedTranscriptions, pronunciation, combined, manual, none |
| Ink | recognition, strokeMatch, shapeSimilarity, manual, none |
| Submit | presence, manual, none |
| Presentation | none |

`expression` is QQL's answer-expression capability (`{optional}`, `[a|b]`,
`[*:a|b]`, `<>` reorders, 128 variants) applied to text; `exactText` and
`acceptedTexts` are literal. Every mode a primitive may use is registered
here and nowhere else; the Audit, editor and import ask the registry.

## Rules (illegal combinations and evaluation implications)

Each rule has a stable id, a description and a coded violation. The registry
checks them on the effective options (defaults filled in, illegal values
dropped). Violation codes: `unknownPrimitive`, `unknownOption`,
`optionNotApplicable`, `illegalOptionValue`, `missingRequiredOption`,
`illegalCombination`, `missingEvaluationMode`, `illegalEvaluationMode`,
`evaluationRequiresOption`, `selectionLimitsImpossible`.

- Select: `select.single.minimum`, `select.single.maximum` (a single
  selection allows limits of 1 only); `select.limits.order` (minimum ≤
  maximum); `select.items.layout` (items → list|grid|inline),
  `select.textSpans.layout` (→ inline), `select.regions.layout` (→ overlay),
  `select.cells.layout` (→ grid); `select.reuse.inline` and
  `select.reuse.items` (reuse only for items in inline gaps);
  `select.exactItem.single`; `select.set.multiple` (exactSet, subset,
  orderedSelections, perSelection need multiple); `select.set.timing` (set
  grading is explicit or onCompletion); `select.perSelection.timing`
  (immediate). With the items known, `checkSelectionLimits` enforces exactSet:
  minimumSelections ≤ correctCount ≤ maximumSelections ≤ itemCount, one
  correct item for exactItem, and never more required selections than items.
- Input: `input.multiple.layout` (several answers → inlineGaps|grid);
  `input.grid.multiple`; `input.typo.text`; `input.numeric.mode` (numeric*
  → number); `input.expression.text`; `input.regex.mode` (text|code);
  `input.texts.mode` (exactText, acceptedTexts → text|date|formula|code).
- Arrange: `arrange.inlineGaps.layout` (→ inline), `arrange.grid.layout`
  (→ grid), `arrange.sequence.layout` (→ horizontal|vertical|wrapped);
  `arrange.gapAssignments.placement` (→ inlineGaps);
  `arrange.order.placement` (exactOrder, acceptedOrders → sequence|grid).
- Match: `match.memory.layout` (→ cards), `match.dropdown.layout` (→
  columns), `match.pair.layout` (→ columns|cards), `match.connect.layout` (→
  columns|free); `match.oneToOne.reuse` (→ forbidden), `match.many.reuse`
  (→ allowed).
- Assign: `assign.gaps.layout` (→ inline), `assign.regions.layout` (→
  overlay), `assign.cells.layout` (→ grid), `assign.categories.layout` (→
  columns|free), `assign.slots.layout` (never overlay);
  `assign.gaps.capacity` (a gap holds one item);
  `assign.categoryMembership.mode` (→ categories).
- Speak: `speak.transcription.needed` (transcriptionMatch,
  acceptedTranscriptions, combined need a transcription);
  `speak.freeResponse.evaluation` (manual or none only).
- Ink: `ink.strokeOrder.mode` (checked → trace|character);
  `ink.strokeMatch.mode`; `ink.recognition.mode` (not diagram).
- Submit: `submit.noTiming.evaluation` (timing none → evaluation none);
  `submit.evaluated.timing` (presence, manual → onCompletion);
  `submit.device.type` (a device captures no `file`).
- Presentation: everything is enforced by the single-value vocabularies.

## Runtime-support table

Executability is computed per exercise from primitive, options and
evaluation mode; it is never stored in Course data. A legal configuration
that no entry covers is `readableButNotExecutable`: kept, editable and
exported unchanged. A configuration with violations is `invalid`. (The fourth
state, `unsupportedModelVersion`, is a Course-level state for a file whose
`formatVersion` is not 12.) Every entry lists every enumeration option of its
primitive, so a value the runtime does not handle can never be executable by
omission (a test enforces this).

| Primitive | Executable today (Part A.2 of the plan) |
| --- | --- |
| Select | single · items · list|grid · reuse forbidden · immediate · exactItem; multiple · items · list|grid · forbidden · explicit · exactSet; single · items · inline · any reuse · explicit · exactItem (one item per gap) |
| Input | text · single · field|inlineGaps · any handling · explicit · exactText|acceptedTexts|expression; text · multiple · inlineGaps · explicit · the same modes |
| Arrange | sequence · wrapped · any unusedItems · any joiner · explicit · exactOrder|acceptedOrders; inlineGaps · inline · explicit · gapAssignments |
| Match | oneToOne · dropdown · forbidden · columns · explicit · exactRelations |
| Presentation | continue|acknowledge|understoodReview · singlePage · any mediaPlayback · none |
| Assign | categories · capacity any · reuse any · tapTarget|selectTarget · columns · explicit · exactAssignments; slots · single · reuse any · tapTarget|selectTarget · columns · explicit · exactAssignments; gaps · single · reuse any · tapTarget|selectTarget · inline · explicit · exactAssignments (Session 8) |
| Speak, Ink, Submit | none yet |

## Content flow

`ContentFlow` holds a `startNodeId` and `FlowNode`s. A node is `content`
(shows the referenced Round Content: dialogue, narration, a Presentation) or
`exercise` (runs the referenced Content's exercise) and carries
`FlowTransition`s with a trigger: `next` (at most one per node), `onCorrect`,
`onIncorrect`, `onChoice` (with `choiceItemId`) or `conditional` (with a
`FlowCondition` of kind answeredCorrectly, answeredIncorrectly, chose or
visited, referring to another node). A node with no applicable transition
ends the flow. `ContentFlow.linear(nodes)` chains nodes with `next`.

Structural checks (`check()`): empty flow, blank or duplicate node IDs,
blank content reference, missing start node, unknown target, more than one
`next`, a content node that branches, `onChoice` without an item,
`conditional` without a condition, a condition naming an unknown node, a
`next` self-loop, a chosen item or a condition on the wrong trigger, and
unreachable nodes. `isLinear` and `linearNodeIds()` recognize the flows this
build will play first: valid, no branching, every node visited once along
`next`. Serialization, Round integration and playback follow in Sessions 2
and 3; conditional evaluation and the stand-alone flow engine in Sessions 5
and 6.

Session 6 (Revision 5) gives a Story its options on the flow: `title`
(shown on the cover; the Round is called `Story: <title>`), `presentation`
(`step` or `scroll`), `log` (`all` keeps every finished item on the
scrolling page, `dialogue` keeps only the lines and the cover) and
`readAloud` (`automatic` plays a line's audio when the line appears,
`manual` waits for the play button; a line's own `playback` overrides it).
A node of a scorable exercise may carry `requiresAudio: true`: the exercise
only makes sense with the Story's audio and is skipped, like the listening
exercises, when the learner has Audio Exercises off. Lines and covers
(presentation nodes) are never skipped. Defaults (`step`, empty title,
`all`, `automatic`, `requiresAudio` false) are omitted in JSON.

## Assign runtime (Session 8)

An executable Assign is played by tapping: the learner taps a bank tile,
then the destination that takes it; a placed item's chip gives it back.
The destinations come from the exercise's targets and its neutral layout:
for groups and slots, a text run before a target is the destination's
label (a bare target is "Group N" or "Slot N"); for gaps the layout is the
sentence with its targets. `targetCapacity` single replaces what a
destination held, multiple and unlimited add to it; `itemReuse` forbidden
takes the item out of the bank and out of any other destination, allowed
or unlimited keeps it in the bank. Check grades `exactAssignments`: every
target holds exactly the items authored for it, order ignored; a target
without authored items must stay empty; an item that belongs nowhere stays
in the bank. `LearnerExerciseKind.assignGroups`, `assignSlots` and
`assignGaps` key the headings and instructions. The Audit's
`ASSIGN_STRUCTURE_REQUIRED` asks for items, targets and, with
exactAssignments, at least one target with items; an Assign's layout may
carry elements whatever its layout value. The presets Sort into groups
(categories, capacity unlimited) and Fill the slots (slots, optional item
reuse) author groups and slots since the Revision 7 follow-up; gaps are
authored in the Generic Primitive Editor (no gap preset by owner decision:
the inline gap presets cover that need). Regions, cells, drag placement and
the other Assign evaluation modes are readable but not executable.

## Support states at runtime (Session 7)

`Exercise.runtimeSupport` asks the registry's runtime-support table for the
exercise's primitive, explicitly set options and evaluation mode; it is
never stored. `isExecutable` is true for `executable` only. What happens to
a readable-but-not-executable exercise (plan A.6):

- `RoundPlayabilityService.playableExerciseIndices` leaves it out of a
  practice Round at the same step as invalid and unpublished exercises,
  before the audio filter, so it is not in the queue, the mistake review,
  the answer count or the XP; `notExecutableIndices` lists what was left
  out; `keepNotExecutable` keeps it for a Story and for the editor Preview.
- `RoundScreen` counts the skipped exercises in the completion dialog
  (`round-completed-version-skipped`), gives a zero-error attempt the
  "skipped perfect" mark instead of the Laurel (the audio-skip rule, one
  stored key) and explains a Round with nothing playable. In a Story and in
  the Preview it draws a card (`not-executable-card`: the prompt read-only
  above, one sentence, Continue; no heading, no instruction) and follows
  the node's `next`; a Story ending on such a step leaves without
  recording (`story-ends-unplayable`, the button reads Leave story).
- `DuelEligibilityService.isEligible` requires an executable exercise.
- The Audit reports `EXERCISE_NOT_EXECUTABLE` (Info, the registry's reason)
  per exercise and `ROUND_NOT_COMPLETABLE` (Warning) when learners of this
  version cannot complete a Round: a practice Round with nothing playable, a
  Story whose flow branches or is not a straight sequence, a Story ending on
  an unplayable step (`CourseAuditService.notCompletableReason`).
- The import review carries `notExecutableCount` into the Matching Course
  ID and Publisher dialogs and the result message.

## Flow engine (Session 7)

`FlowEngine` (`lib/services/flow_engine.dart`) is stand-alone: given a
flow, the node just finished and a `FlowOutcome` (seen, correct, incorrect,
chose an item), `nextAfter` names the next node. The node's transitions are
read in declared order; the first `onChoice` (matching item), `onCorrect`,
`onIncorrect` or `conditional` (its `FlowCondition` evaluated on a
`FlowState` that already holds this node's outcome) that applies wins;
`next` is the fallback wherever it stands; an unknown target or no
applicable transition ends the flow. `walk` runs a whole flow with an
outcome callback and a step bound, for tests. The learner runtime still
plays linear flows directly; a branching flow counts as "cannot run yet" at
Round level until a Round kind uses the engine (Adventures, parked).

## Interoperability (Session 7)

`ExerciseInteroperabilityCatalog.mappings` maps every surveyed external
type to a `CanonicalConfiguration` (primitive, explicitly set options,
evaluation mode, the layout shape in words) or to a content flow (a Story),
with `presetHint` naming the catalogue preset whose form could represent
the result; `unsupported` patterns carry no configuration. A test checks
that every configuration validates in the registry and that its
executability matches its status (the Speak mappings are readable but not
executable). `NormalizedImportExercise` is the import boundary in canonical
terms, with no preset required; `CanonicalExerciseImport.adopt` builds the
exercise, validates it, computes its support and records the hint as
`authoringMetadata.presetId` only when `PresetRecipes.represents` confirms
it. Nothing from the source label reaches the exercise.

## Capability description (Session 7)

`capabilityDescription()` (`lib/models/canonical/capability_description.dart`)
turns the registry into JSON: the option keys in declaration order and, per
primitive, its options (type, legal values, default, required, minimum,
description), evaluation modes, default mode, rules (kind, id, the values
they relate) and runtime-support entries. `dart run
tools/export_capabilities.dart` writes `docs/capabilities_v12.json`;
`test/capability_description_256_test.dart` fails when the file is stale;
`tools/qql_capabilities.py` loads it into the PRIMITIVES, EVALUATION_MODES,
OPTIONS, DEFAULTS and OPTION_ORDER tables that `tools/qql_course_v12.py`,
the generators and `tools/validate_courses.py` use.

## Course Model v12 JSON (Session 2)

The Course root, Lessons, GuideBooks, media, provenance and every other
field keep their v11 shape; only `formatVersion` (12), Rounds, Content and
exercises change.

### Round

Unchanged fields plus an optional `flow`:

```json
"flow": {
  "start": "node_1",
  "nodes": [
    {"id": "node_1", "kind": "content", "contentId": "dialogue_1",
     "transitions": [{"trigger": "next", "target": "node_2"}]},
    {"id": "node_2", "kind": "exercise", "contentId": "question_1",
     "transitions": [
       {"trigger": "onCorrect", "target": "node_3"},
       {"trigger": "onIncorrect", "target": "node_hint"},
       {"trigger": "onChoice", "target": "node_a", "choiceItemId": "item_a"},
       {"trigger": "conditional", "target": "node_b",
        "condition": {"kind": "answeredCorrectly", "nodeId": "node_2"}}]}
  ]
}
```

A linear Story as the Story Wizard writes it (Revision 5):

```json
"flow": {
  "start": "cover_1",
  "nodes": [
    {"id": "cover_1", "kind": "exercise", "contentId": "cover_1",
     "transitions": [{"trigger": "next", "target": "line_1"}]},
    {"id": "line_1", "kind": "exercise", "contentId": "line_1",
     "transitions": [{"trigger": "next", "target": "question_1"}]},
    {"id": "question_1", "kind": "exercise", "contentId": "question_1",
     "requiresAudio": true}
  ],
  "presentation": "scroll",
  "title": "Al bar",
  "log": "dialogue"
}
```

A Round without `flow` is today's practice Round (its Before you start card
first, then shuffled exercises, then the mistake review; Build 257: the card
is a presentation exercise, never a step, and not shown in Review). `visualType` stays a visual
hint and does not decide delivery.

### Content

`id`, `publicationState`, `kind`, `required`, `role`, `sourceRefs` and
`text` are unchanged for textual kinds (explanation, example, vocabulary,
text, image, audio, dialogue). Every exercise, Presentation included, is
`kind: exercise` with an `exercise` object; v11's `kind: presentation` with
a `presentation` object is converted into a `presentation`-primitive
exercise. `editorTemplate` becomes `authoringMetadata`, an optional object
whose `presetId` names the preset that authored the exercise; other keys
are preserved verbatim and never read.

### Exercise

```json
{
  "updatedAt": "2026-09-27T00:00:00.000Z",
  "primitive": "select",
  "options": {"selectionMode": "multiple", "minimumSelections": 2,
              "maximumSelections": 3, "evaluationTiming": "explicit"},
  "prompt": [{"role": "primary", "type": "text", "text": "…"}],
  "items": [{"id": "item_0", "content": [{"role": "primary", "type": "text", "text": "…"}]}],
  "targets": [{"id": "gap_1", "reveal": "firstGrapheme"}],
  "layout": [{"type": "text", "text": "I "}, {"type": "target", "targetId": "gap_1"}],
  "evaluation": {"mode": "exactSet", "correctItemIds": ["item_0", "item_2"]},
  "feedback": {"showAlternatives": "ranked"},
  "hint": "…"
}
```

- `options` holds explicitly set values only; an omitted option means the
  registry default, and semantic equality compares effective options.
- Elements (prompt and item content) keep `role`, `type` (text, audio,
  image), `text`, `asset`, `speaker` and `sharedImageSource`, and gain
  `language` (`source` | `target`, text), `playback` (`automatic` | `manual`,
  audio, default manual) and `required` (boolean, audio, default true).
  Defaults are omitted. Build 258 (Page blocks, role `block`): `textStyle`
  (`heading1` | `heading2` | `paragraph` | `quote` | `bulleted` | `numbered`,
  text), `align` (`start` | `center` | `end`, text, image and link;
  `justify`, text only), `color` (`default` | `accent` | `red` | `green` |
  `blue` | `grey`, text), `size` (`small` | `medium` | `large` | `full`,
  image), `readAloud` (boolean, text) and the element type `link` with
  `url` (an https address; the label is `text`). An attribute on the wrong
  element type or an unknown value is a format error.
- `items` carry `id`, `content` and, for Match, `side` (`left` | `right`).
- `targets` carry `id` and optional `reveal` (`firstGrapheme`) or `region`
  (`{x, y, width, height}`, fractions of the exercise's image).
- `layout` is the neutral inline sequence of text runs and targets, present
  only for inline layouts (Select inline, Input inlineGaps, Arrange
  inlineGaps, Assign gaps).
- `evaluation.mode` is required; the other keys depend on the mode:
  `correctItemIds` (Select item modes), `assignments` `[{targetId,
  itemIds}]` (Select inline, Arrange gapAssignments, Assign),
  `answers` and `literalAnswers` (Input, one field), `targetAnswers`
  `[{targetId, answers, literalAnswers}]` (Input inline gaps), `numeric`
  `{value, minimum, maximum, tolerance}` and `pattern` (Input numeric and
  regex modes), `correctOrders` `[{text, itemIds}]` (Arrange order modes),
  `relations` `[[leftId, rightId]]` (Match), `acceptedTargets` `[{itemId,
  targetIds}]` (Assign). Speak, Ink and Submit carry `mode` and optional
  `answers` until Session 5 defines more. Unknown evaluation keys are a
  format error. The v11 `normalization` map is gone: the Input options
  `caseHandling`, `punctuationHandling`, `whitespaceHandling` and
  `accentHandling` replace it; Arrange text comparison keeps the answer
  engine's defaults.
- `feedback` has optional `correct`, `incorrect` and `showAlternatives`
  (`none` | `ranked` | `all`); it is omitted when empty.

### Semantic equality

Two exercises are semantically equal when their canonical JSON is equal
after filling in every default option and dropping `authoringMetadata`,
`updatedAt` and `publicationState`. IDs and item order count.

### v11 → v12 conversion rules

The converter (`lib/services/course_model_v12_converter.dart`, no Flutter
imports) and the in-memory `Exercise.v2(...)` constructor share one
mapping, keyed by the preset (`editorTemplate`) with the interaction kind
as fallback:

- **Select:** `selectionMode` from `maxSelections`; multiple → explicit
  timing, explicit limits, `exactSet`; gap layouts → `layout: inline`,
  targets from the gap elements, `itemReuse: unlimited`, `exactItem` with
  `assignments`. Prompt audio of What do you hear, Listen and choose and the
  context audio of Contextual comprehension → `playback: automatic`. Pick the
  translation (to target): question text `language: source`, items
  `target`; (to source): question `target`, items `source`.
- **Input:** options from the normalization map (`preserve` → `exact`;
  accents `preserve` → `missingAccentsAccepted`, `ignore` → `ignore`; absent
  → defaults); mode `expression`; `literalAnswers` = the spoken prompt text
  for Type a missing word, Type what you hear and Type the translation;
  `typoTolerance: conservative` for Type the translation and Type the
  missing word; Type the translation: prompt text `language: source`,
  `showAlternatives: ranked`; Type the missing word: `inlineGaps`, one
  target with `reveal: firstGrapheme`, the sentence split at its `___`;
  Listen for missing words: `cardinality: multiple`, `inlineGaps`, the
  transcript split at the first case-insensitive occurrence of each missing
  word, one `targetAnswers` entry per gap, audio `playback: automatic`; Type
  what you hear: audio `playback: automatic`. `___` in Fill in the blank
  and Type a missing word stays text.
- **Arrange:** one order → `exactOrder`, several → `acceptedOrders`;
  Image-prompt ordering: `joiner: none`, `unusedItems: forbidden`; gap
  layouts → `inlineGaps`, `layout: inline`, targets, `gapAssignments` with
  `assignments`; Build the translation: prompt text `language: source`,
  `showAlternatives: all`.
- **Match:** `side` from pair position (first = left); `relations` = pairs.
- **Presentation:** the presentation elements become the prompt;
  `completionMode: understoodReview` (actions understood/review_later);
  evaluation `none`.
- The v11 `feedback` map keeps `correct` and `incorrect`; any other key is
  reported and dropped. Everything the converter cannot map exactly is
  listed in its notes.

## Final names for the plan's A.4 fields

Decided in Session 1; serialized in Session 2.

| Need | Final form |
| --- | --- |
| Automatic vs manual audio | media element attribute `playback`: `automatic` \| `manual` (default manual) |
| Audio the exercise cannot do without | media element attribute `required`: boolean (default true for audio; Pick the translation converts with false) |
| Which language a text is in | text element attribute `language`: `source` \| `target` (absent means unspecified, treated as target) |
| Accent handling | Input option `accentHandling`: `exact` \| `missingAccentsAccepted` \| `ignore` |
| Extra literal answers | Input evaluation field `literalAnswers` (never parsed as expressions) |
| First-grapheme reveal | target attribute `reveal`: `firstGrapheme` (Input, inline gaps) |
| Typo tolerance | Input option `typoTolerance`: `none` \| `conservative` |
| Ranked alternatives, all accepted answers | `feedback.showAlternatives`: `none` \| `ranked` (3 when wrong, 2 when right) \| `all` |
| Completed-sentence display | implied by an inline layout: after checking, gaps show their correct values |
| Joining blocks | Arrange option `joiner`: `space` \| `none`; order modes compare content sequences |
| Match item side | item attribute `side`: `left` \| `right` |
| Select layouts | `list` \| `grid` \| `inline` (plus `overlay` for regions) |
| Regions | target attribute `region`: `{x, y, width, height}` normalized to 0–1 on the exercise's image |

## Behaviors that did not map cleanly (resolved by the Session 2 converter)

1. **Listen for missing words** blanks the first case-insensitive occurrence
   of each missing word at runtime and duplicates the answers in
   `missingWords`; v12 needs an explicit inline layout with one target and
   one answer list per gap.
2. **`___` in text** is display text in Fill in the blank and Type a missing
   word (no target), but the gap of Type the missing word becomes a target
   with `reveal: firstGrapheme`.
3. **Spoken prompt text accepted literally** (Type a missing word, Type what
   you hear, Type the translation) becomes `literalAnswers`.
4. A `text_match` without a normalization map (four in the Edge Case Course)
   means ignore/ignore/normalize/missingAccentsAccepted, which are the v12
   defaults.
5. **Whole-sentence Arrange** grades joined text; inline-gap Arrange grades
   block IDs today and block content from Session 3 (plan A.11).
6. **Match sides** come from pair order; v12 states `side` on each item.

Session 2 resolved all six in the conversion rules above; item 5's grading
change (block content instead of block IDs) is Session 3's, plan §A.11.
7. **Select the image** items carry a legacy icon key in a text element with
   role `icon`, drawn through a fixed Material icon table; v12 keeps the
   element and the table until a media form replaces it.
8. **Flashcards** are Presentations with content roles term, meaning, usage,
   usage_translation and audio and the actions understood/review_later; v12
   is `completionMode: understoodReview`.
9. **Textual Round Content** (explanation, example, vocabulary, text, image,
   audio, dialogue with roles lesson_intro and round_note, and GuideBook
   material) stays Content and is shown by content nodes (Build 257: a v11
   `lesson_intro` converts to a Before you start card instead); the projection of
   such Content into flashcard-shaped exercises goes in Session 3.
10. **Pick the translation** derives its direction, instruction and
    after-answer audio from the preset; v12 derives them from `language` on
    the text and items and `required: false` on audio.
11. **Context mode** (text, audio, textAndAudio) and dialogue turns with a
    speaker are derived from context elements, as today.
12. **Hints** are shown differently by preset (Fill in the blank shows
    `Hint:` above the options; Input shows a box); Session 3 adopts one rule.
13. **Duel eligibility** is a preset list; Session 3 makes it every
    single-answer Select with items as choices and exactItem.
14. **Learner headings and instructions** (`ExerciseCopyService`, eight
    languages) are keyed by preset; Session 3 derives them from features.
15. An unknown v11 interaction kind silently became `choice`; v12 refuses
    unknown primitives.
16. **Recognize characters** (image to text, text to image) is Select with
    image items or an image prompt; nothing special remains.

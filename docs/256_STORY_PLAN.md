# Build 256 Revision 5: Stories — plan

Written 28 September 2026 from the owner's request and answers of the same
day. Waits for the owner's go before any code changes. Version
`2.0.56+256005`; the earlier Revision 5 (Interoperability) becomes Revision
6 and Laboratory / Assign / final verification becomes Revision 7
(`docs/256_EXERCISE_ARCHITECTURE_PLAN.md` Part B renumbered).

**Status: delivered as Build 256 Revision 5 (`2.0.56+256005`, 28 September
2026); what was built is in `docs/256_CHANGE_SUMMARY.md`, the evidence in
`docs/256_VALIDATION.md`.** Differences from this plan: the avatars are made
by `tools/make_avatars.ps1` (.NET, no Pillow on the machine); the Laboratory's
Story is a sixth Lesson beside the five primitive Lessons; the Piedmontese
demo gets one Lesson per new preset (a Story of three lines and a Round of
three covers); the Wizard adds and edits characters but leaves removal to
the Course Editor; a custom avatar is a PNG of at most 50 KB.

## 0. Owner decisions (28 September 2026)

1. A dedicated revision, not a Revision 4 follow-up.
2. Narrator and characters are reusable Course data referenced by the
   lines, not copied into each line.
3. A character's voice is a preference (any, male, female) matched against
   the voices installed on the device, never a voice name; matching is best
   effort and never blocks speech.
4. Read-aloud is a Story option (automatic or on request) that every line
   may override.
5. A dialogue line is never skipped: with Audio Exercises off, TTS off or
   the language's voice missing, the Story stays readable. An exercise
   whose audio is indispensable is skipped as today, and inside a Story any
   exercise can be marked as needing the Story's audio (it depends on
   having heard the dialogue), which skips it in the same cases.
6. When a line has both text and audio, the author chooses whether the
   text shows immediately or only after listening.
7. The exercise presets allowed in a Story are my choice (section 5).
8. The Story Wizard's exercise step opens the normal preset form and must
   return to the Story flow afterwards.
9. Story exercises never enter the Duel pool.
10. One bundled avatar per mascot, whole figure for now: cat (the
    celebrating cat), dog, kid, monkey, robot; custom avatars can be
    uploaded.
11. Title prefix and cover are my choice (sections 2.3 and 2.4).
12. Existing Stories keep their stored presentation; Scrolling and the
    filtered log are defaults for new Stories only.

XP, perfect completion, Laurels and Review are unchanged: lines award
nothing and count as neither correct nor wrong; only the Story's exercises
count, exactly as flashcards and notes today.

## 1. What the learner gets

A Story is a Round played in authored order. It opens with a cover (title
and picture), then dialogue lines follow: each line shows the speaker's
avatar and name, the text and, when audio is present, plays it (by itself
or on a tap) in the speaker's language with a voice matching the speaker's
preference. The learner presses Continue after each line. Exercises checking
comprehension sit between lines with immediate feedback. In the scrolling
presentation the finished lines stay on the page as a readable dialogue;
finished exercises and used buttons disappear. With audio off or a voice
missing, every line still shows its text, so the Story can be read.

## 2. Data model (Course Model v12, additive)

### 2.1 Course: narrator and characters

- `storyNarrator` (optional object): `name` (optional), `avatar` (optional
  asset), `language` (`source` default), `voice` (`any` default, `male`,
  `female`). Absent means the default narrator: no name, no avatar, source
  language, any voice.
- `storyCharacters` (optional list): `id` (stable, `character_…` from
  `AuthoringIdGenerator`), `name` (optional), `avatar` (optional asset),
  `language` (`target` default), `voice` (`any` default).
- An avatar asset is a bundled `assets/avatars/<mascot>.png` or a Course
  medium `media:<sha256>.png` (256 × 256). `CourseImageUsage` (the one
  usage walker) covers avatars, so Copy as New Course, Fork, Merge, export,
  import, backups, `deleteUnreferenced`, Remove from this Course and the
  Audit's attribution rule all see them.
- Semantic equality of a Course includes both fields; the Course Editor's
  working copy carries them; `CourseInfoOperation` is untouched.

### 2.2 Flow

- `ContentFlow` gains `title` (string; the Story's title), `log` (`all` |
  `dialogue`; absent = `all`, today's behavior) and `readAloud`
  (`automatic` | `manual`; absent = `automatic`).
- `FlowNode` gains `requiresAudio` (bool, exercise nodes only; absent =
  false): the exercise needs the Story's audio (owner decision 5).
- `RoundFlowAuthoring` carries the new fields through `forContent`,
  `withPresentation`, `remapped` and a new `withStoryOptions`; every
  `LearningRound(...)` rebuild keeps them (the Revision 3 invariant).
- Structural checks: `title` non-empty for a Story is an Audit rule, not a
  parse error; unknown values are format errors as for every option.

### 2.3 Round title

While a Round has a flow with a title, the Round's `title` is `Story: ` +
the flow title (literal English prefix, as the owner wrote; QQL's canonical
UI words are English). The Round editor derives it and Rename edits the
Story title. Stored JSON keeps the plain `title` field, so nothing else
changes for readers of the file.

### 2.4 Two presets on the presentation primitive

Both complete with `proceed` (Continue), both in the group Cards and notes,
both recognized by `PresetRecipes` (`kinds`, decompose, rebuild,
`represents`, `fits`), both with Help, field help, Search definitions and
`LearnerExerciseKind` copy in the eight languages.

- **Dialogue line** (`dialogue_line`; kind `dialogueLine`): a text element
  with role `line` and/or an audio element with role `line` (its `text` is
  the spoken transcript), the `speakerId` attribute on the line elements
  (absent = narrator; a new optional `PromptElement` attribute next to
  `speaker`), `language` from the speaker unless overridden, `playback`
  absent = the Story's read-aloud, else the line's override, `required`
  `true` for an audio-only line (indispensable), `false` when text is
  present too. Modes: text only (no audio element), audio only (audio
  element only), text and audio. A new presentation option `textReveal`
  (`immediate` default | `afterAudio`; legal only with an audio element,
  registry rule) hides the text until the audio has played once.
- **Story cover** (`story_cover`; kind `storyCover`): an image element with
  role `picture` and an optional `title` text; the runtime draws the Story
  title from the flow above it. The Wizard creates it first.
- `ExerciseFeatures`: `illustrationImages` excludes role `avatar`;
  `speakerIdOf`, `lineText`, `lineAudio`, `textReveal`; the kinds above.
- Executability: both presets are executable in the runtime-support table.

### 2.5 Compatibility

- v11 has no Stories: the converters and `tools/qql_course_v12.py` do not
  change; the v11 fixtures and the converter parity test stay as they are
  (the generators' `course_v11()`/`build_course_v11()` omit Story Lessons).
- Existing v12 Courses parse unchanged: every new field is optional.

## 3. Runtime

- **Queue.** A Story visits its nodes in order. Presentation nodes are
  never skipped. An exercise node is skipped when audio is unavailable
  (Audio Exercises off, TTS off, no voice for its language) and either the
  exercise has a required audio element (today's rule) or its node has
  `requiresAudio`.
- **Line card** (`_dialogueLineExercise`): avatar (40 px circle) and name
  on the left, the text in a bubble; a narrator line has no avatar, its
  name only when set, and a quieter style. Play button for `manual`
  read-aloud; automatic playback through the existing activation path
  (`automaticAudio` resolved with the Story's default when the element has
  no `playback`). `textReveal: afterAudio` keeps the text hidden until the
  audio finished once; when audio is unavailable the text shows at once
  with the line "Audio not available on this device". An audio-only line
  shows the transcript only in those fallback cases and, after Continue, in
  the scroll log. Continue completes the line.
- **Voice.** The line speaks in the speaker's language (`_voiceFor`,
  Revision 4) with the speaker's voice preference: `TtsCacheService.speak`
  gains an optional gender preference, applied with the existing
  voice-matching code (`_gender`, `getVoices`); the character's preference
  wins when it is not `any`, else the learner's preference; no match never
  blocks speech.
- **Scroll log.** `flow.log == dialogue`: `_logStoryItem` records only the
  cover and the lines, drawn as the same bubbles without buttons;
  exercises are not logged. `all` keeps today's cards. The `story-now`
  marker, the spacer and the auto-scroll stay.
- **Availability.** `RoundPlayabilityService` is unchanged: a Story with
  audio off is playable; its lines show their text; a manual play button
  whose audio cannot play is greyed with a tooltip instead of the failure
  snackbar.
- **Duel.** `DuelEligibilityService.evaluate` skips every Round with a
  flow, so Story exercises never reach the Duel pool; Home and Duel entry
  share the result as today (fewer eligible exercises may make a Duel
  unavailable: owner decision 9).
- **Step by step** Stories get the same line card and the same fallbacks.

## 4. Editor

- **Round editor.** Play as a Story on shows: Story title (required),
  Presentation (Scrolling default, Step by step), Scroll log (Filtered
  default, All), Read-aloud (Automatic default, On request) and, in the
  item list, "Needs the Story's audio" per exercise; off hides them all. A
  new Story is written with scroll, dialogue, automatic; an existing Story
  keeps its stored values (decision 12). Lesson path and Home show the
  derived title.
- **Course editor.** A collapsed "Story characters" section under the
  Lessons tile (like Lesson Options): the narrator row (name, avatar,
  language, voice) and the characters list (add, edit, remove). Removing a
  character that lines still reference is refused with the count.
- **Avatar picker.** Bundled avatars (cat, dog, kid, monkey, robot), Upload
  (any picture up to 10 MB, centre-cropped through the existing crop dialog
  at 256 × 256, `ImageValidator`, stored in the Course media folder, the
  image credit reminder as for covers) and None.
- **Forms.** Dialogue line: Speaker (Narrator and the characters), Line,
  Mode (Text and audio / Text only / Audio only), Read-aloud (Story
  default / Automatic / On request), Show text (Immediately / After
  listening), Language (Speaker's / Target / Source). Story cover: Cover
  image, Title (optional). Both presets appear in the picker; a Dialogue
  line outside a Story is allowed and gets an Audit Warning.
- **Duplication, Move/Copy, Search** carry `speakerId` and the new flow
  fields (`remapped`).

## 5. Story Wizard

- Button **Story Wizard** (`lesson-story-wizard`) in the Lesson editor's
  bottom bar next to Round Wizard; it needs no GuideBook.
- Step A: title, cover image, read-aloud default. Step B: narrator,
  prefilled from the Course (name, avatar, language, voice). Step C: one or
  more characters, prefilled from the Course, add or edit. Then the builder:
  a list of steps with **Add line** (D), **Add exercise** (E), reorder and
  remove, and **Finish** enabled once at least one line exists. D is an
  inline form (speaker, line, mode, read-aloud override, show text). E opens
  the preset picker limited to the allowed presets, then the normal
  exercise form pushed on top of the Wizard route; Save or Cancel returns
  to the builder (decision 8). Finish creates the Round (visual type
  story, title `Story: …`, flow linear with scroll, dialogue log and the
  read-aloud default, the cover node first, `requiresAudio` from a per-E
  checkbox) through the authoring session; the Course confirmation still
  decides persistence. Narrator and characters edited in B and C are
  written to the Course's `storyNarrator`/`storyCharacters`.
- Allowed E presets (decision 7, mine): True or false, Choose the answer
  (to target, to source), Pick the translation (to target, to source),
  Listen and answer (to target, to source), Word order (with an optional
  spoken prompt: the owner's "listen and arrange words"), Listen and fill
  the gaps, Type the missing word, Complete the text.

## 6. Audit

New codes (registry 98 → 103; pinned counts updated):
`STORY_TITLE_REQUIRED` (Error), `STORY_WITHOUT_DIALOGUE` (Error: a Story
Round with no dialogue line), `STORY_SPEAKER_UNKNOWN` (Error: a line
references a character the Course does not have), `DIALOGUE_LINE_EMPTY`
(Error: neither text nor audio), `DIALOGUE_LINE_OUTSIDE_STORY` (Warning).
Missing avatar files use the existing media integrity checks. The
presentation content rules (`FLASHCARD_*`) apply to vocabulary flashcards
and notes only, not to lines and covers. Preset rules for the two presets
follow the catalogue pattern (`PRESET_CANONICAL_MISMATCH` with a hint).

## 7. Assets and tools

- `assets/avatars/{cat,dog,kid,monkey,robot}.png`: whole figures fitted into
  256 × 256 with transparent margins, generated deterministically from
  `assets/mascots/cat-celebrating_tr.png`, `dog-laughing-pencil_tr.png`,
  `kid_reading.png`, `monkey-yawning_tr.png`, `robot_speaking.png` by a
  new `tools/make_avatars.py` (Pillow); registered in `pubspec.yaml`; QQL
  images, so the Image credits page is unchanged.
- Generators: the Laboratory gains a Story Lesson (cover, a narrator line
  in the source language with audio, two character lines, a text-only
  line, an audio-only line, an audio-dependent True or false, a Choose the
  answer, a Word order), the Piedmontese demo a Story Lesson, the Edge Case
  demo a Story with an audio-only line and a `requiresAudio` exercise;
  `tools/validate_courses.py` expects the new Lesson counts; the Laboratory
  presentation baseline gains the new records.

## 8. Help (EN/IT/ES)

Story Wizard Help page; Round editor Help (the Story options); Course
editor Help (Story characters, avatars); Exercise Help for Dialogue line
and Story cover; field help for the new fields; the Exercise primitives
page's stories section; `localization_catalog_test` parity.

## 9. Tests

- Model: flow fields and `requiresAudio` round trip, semantic equality,
  `RoundFlowAuthoring` carrying them, Course narrator/characters round trip
  and usage walker, `speakerId` on elements, `textReveal` registry rule.
- Recipes: represents/recognize/fits for both presets, the Laboratory
  examples represented by their own presets.
- Runtime: line rendering (avatar, name, text, play), automatic and manual
  read-aloud, `afterAudio` reveal, audio-only fallback text, no line ever
  skipped with audio off, audio-dependent exercise skipped, filtered versus
  full log, voice preference passed to TTS, Duel pool without Story
  exercises, XP unchanged for a Story with lines and exercises.
- Editor: Story options visibility and defaults, derived title, characters
  section, avatar picker (bundled and upload), forms, picker.
- Wizard: A → B → C → builder, at least one line, E returns to the builder,
  Finish creates the Round through the session, Cancel creates nothing.
- Audit: the five codes and the exemptions; registry pins.
- Bundled Courses, presentation baseline, Help parity, version pins.

## 10. Documents and version

CHANGELOG, `docs/256_CHANGE_SUMMARY.md`, `docs/256_VALIDATION.md`, AGENTS
boundary entry, README, `docs/EXERCISE_ARCHITECTURE_V12.md` status table and
its Stories section, this plan's status line; version `2.0.56+256005` with
the Beta expiry 30 days from the release day; the process of Revision 4
(format on changed files, analyze, focused batches including the bundled
Course and card tests, the complete suite once, six-part report, one
commit, handoff). No APK unless the owner asks; sound at the end.

## 11. Stages (handoff after each)

1. Model, registry, flow, characters, avatars, `CourseImageUsage`, tests.
2. Runtime: queue, line card, voice, scroll log, Duel exclusion, tests.
3. Editor: Round options, characters section, avatar picker, forms,
   picker, Search and duplication, tests.
4. Story Wizard, tests.
5. Bundled Courses, Help, Audit codes, docs, version, suite, commit.

## 12. Decisions taken by me (say if you want them changed)

- Allowed exercise presets in a Story: the list in section 5.
- The Round title prefix is the literal `Story: `; the cover is a separate
  first node drawn with the flow's title.
- A Dialogue line outside a Story is allowed with a Warning.
- Removing a referenced character is refused (no silent fallback to the
  narrator).
- Voice precedence: the character's preference when set, else the
  learner's; matching never blocks speech.
- An audio-only line shows its transcript only when audio is unavailable
  and in the scroll log after Continue.

## 13. Out of scope

Branching flows and the flow engine (Revision 6), voice names per
character, avatars on exercises outside Stories, converting v11 content
into Stories, the save guard on example content (still open from the
catalogue plan).

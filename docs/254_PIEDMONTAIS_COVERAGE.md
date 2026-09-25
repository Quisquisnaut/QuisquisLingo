# Build 254 Piedmontais demo coverage

`assets/courses/piedmontais_en.json` is **AI-Slop Demo: Piedmontais**, a temporary,
unreviewed English → Piedmontais (Piedmontese) sample. It uses Course Model v11
and the existing bundled publisher metadata. The new identity,
`course_e5f5585a-7762-43a0-a6b2-62754e02d17b`, was allocated with
`Course.newCourseId()`; the generator retains it on subsequent runs. This is a
new Course, with no shared identity or progress keys from another Course.

There are **24 Lessons, 24 Rounds, 69 scored Exercises and 3 Flashcards**. Every
Lesson contains one Round with three examples of exactly one current named
Exercise type. The title starts with the exact name from
`ExercisePresetRegistry`, followed by the teaching topic. GuideBooks, Lessons,
Rounds and authored Content are Published. Duels are explicitly turned off:
these small focused Lessons do not have a 25-question Duel pool.

## Lesson matrix

The Lesson IDs use `pms_e5f5585a_lNN`; the Round is `_r01`, with examples `_e01`
through `_e03`. Content and Item IDs are unique and stable.

| Lesson | Exact named type / `editorTemplate` | Topic and examples |
| --- | --- | --- |
| 1 | Choose / `choice` | First words: bread, cat, water |
| 2 | Fill in the blank / `gap_choice` | Small phrases: ël can, la ca, bon-a matin |
| 3 | Select the image / `icon_choice` | Words in pictures: gat, pan, eva |
| 4 | Recognize characters / `script_recognition` | Original printed glyphs ë, é, ò; text alternatives |
| 5 | What do you hear / `listening_choice` | Hear a greeting: bondì, mersì, ciàu |
| 6 | Listen and choose / `listening_comprehension` | Listen for meaning: a book, two animals, three apples |
| 7 | Reading comprehension / `reading_comprehension` | Read a short note: shopping, animals, being at home |
| 8 | Dialogue response / `dialogue_response` | Reply politely: morning, thanks, bedtime; exactly two replies |
| 9 | Contextual comprehension / `contextual_comprehension` | Who said it: two named speakers, objects and thanks |
| 10 | Type the translation / `type_translation` | Write in Piedmontais: thanks, a happy speaker, the house |
| 11 | Build the translation / `build_translation` | Translate with blocks: the book, I am happy, bread and water |
| 12 | Pick the translation (to target) / `translation_choice_to_target` | English to Piedmontais: the dog, red, three |
| 13 | Pick the translation (to source) / `translation_choice_to_source` | Piedmontais to English: good night, the bread, I am happy |
| 14 | Type a missing word / `fill_blank` | Complete a phrase: lìber, ca, eva |
| 15 | Type the missing word / `type_missing_word` | First-letter help: whole gat, ca, lìber answers |
| 16 | Type what you hear / `listening_spelling` | Hear and spell: pan, eva, pom |
| 17 | Listen for missing words / `missing_word` | Listen for gaps: two missing foods, two animals, one book |
| 18 | Match the pairs / `matching` | Everyday pairs: greetings, phrases, colours |
| 19 | Match the words / `word_match` | Three translations per example: food, animals, household words |
| 20 | Match related words / `super_match` | Related Piedmontais words: opposites, singular/plural, nouns/articles |
| 21 | Listen and match / `audio_match` | Three unique audio/text pairs per example: foods, animals, colours |
| 22 | Word order / `word_order` | Put words in order: pronoun and verb, food/drink, repeated ël blocks |
| 23 | Image-prompt ordering / `image_word` | Build pictured words: pan, gat, caval; every letter is used |
| 24 | Flashcard / `flashcard` | Remember useful words: lìber, grassie, eva; Understood / Review later |

## Answer and media details

- Type the translation accepts both `grassie` and `mersì` for thank you. Its
  `{mi} i son content` expression permits the explicit subject or its omission;
  the prompt identifies a masculine speaker. Other responses use complete
  literal answers with the existing normalization behavior.
- Build the translation accepts both `mi i son content` and `i son content` as
  separately authored literal block orders. It does not use typed-answer
  syntax. Every order references distinct available Item occurrences.
- The repeated `ël` in Word order and the repeated `a` in `caval` each have
  separate Item IDs. Image-prompt ordering joins letters without spaces and
  contains no unused distractor blocks.
- Listen for missing words stores a complete transcript and ordered
  `missingWords`; its answer checking uses that current preset contract rather
  than ordinary `acceptedAnswers`.
- Select the image and Image-prompt ordering reuse existing `cat`, `dog`,
  `horse`, `bread`, `water` and `apple` WebP assets. Every image has a text
  alternative. The existing `piedmontese` world flag and `speech_bubbles`
  Lesson icon are reused.
- The three character diagrams are small original PNGs embedded in the Course,
  drawn by the generator without a font dependency. They distinguish accent
  shapes and do not claim to teach pronunciation. `mediaAttributions` credits
  these diagrams. Their dimensions are 110 × 166 pixels, well below the
  portable-image limits.
- Flashcards use canonical Presentation Content with term, meaning, usage,
  usage translation, optional audio and both completion actions. They are
  presentations, not ordinary scored answers.

## Language and audio limits

Basic words, spelling and selected grammatical patterns were checked against
[Claudio Panero's English–Piedmontese dictionary, 2017](https://giannidavico.it/2021/gopiedmont/files/2020/04/Free-English_Piedmontese-dictionary_A5.pdf),
including its article, pronoun and plural tables. The course sentences and
exercises are newly authored, not copied lessons. This check does not substitute
for a native-speaker review. The displayed title follows the requested
**Piedmontais** label; language tags use `pms-IT`.

The course uses On-Device TTS (`audioMode: tts`, `ttsLanguage: pms-IT`) and has no
recorded audio library. No suitable installed Piedmontais voice or accurate
device pronunciation is guaranteed. Five Lessons depend on listening
(5, 6, 16, 17 and 21); their actual device availability follows the existing
Audio Exercises and TTS rules. Flashcard pronunciation is optional. No Italian
recording or synthetic substitute is falsely presented as Piedmontais audio.

## Verification and known findings

- `python tools/generate_piedmontais_demo_254.py --check` passes: the UTF-8 JSON
  reproduces exactly and its Lesson sequence equals all 24 current named
  presets. The generator refuses to silently ignore a changed preset registry.
- The root-owned Python Course validator accepts the generated course after
  the Build 254 manifest and supported-representation integration.
- All three embedded PNGs were decoded to local previews and visually inspected:
  black character and accent shapes are legible on white backgrounds.
- `test/piedmontais_course_254_test.dart` covers metadata and model checksum,
  round-trip stability, exact type/title coverage, Audit errors, structural
  runnable queues, explicit and optional answers, repeated block occurrences,
  portable glyphs and bundled image resolution. Root integration owns the
  serialized Flutter runs and final evidence in `254_VALIDATION.md`.

The first related-word example intentionally introduces opposites in its first
Round (`pms_e5f5585a_l20_r01_e01`), because one Lesson is dedicated to each named
type. Its GuideBook teaches the relationship first. The existing pedagogical
Audit can report `OPPOSITE_TOO_EARLY`; this is not a malformed exercise.

During integration, the three Flashcards exposed an existing runtime projection
issue: `Presentation.asLegacyExercise` passed the stored usage fields to the
friendly Exercise constructor, whose Flashcard interaction dropped the answer
items read by `Exercise.answers`. The owner explicitly authorized its narrow
correction: Flashcard now uses the existing answers-to-items construction branch
in `course_models.dart`. This keeps both usage fields in the runnable view and
through an Editor save, without changing Course Model v11 or the Presentation
JSON schema. `test/flashcard_usage_254_test.dart` first reproduced the loss in
all three cases (with translation, without translation, and newly authored
Draft/Published content). The root-run regression then passed all three cases;
the Exercise Laboratory Flashcard preservation check passed too. Final
integrated-suite evidence is recorded in `254_VALIDATION.md`.

The Piedmontais Audit regression now permits exactly the intentional
`OPPOSITE_TOO_EARLY` warning, with no Flashcard-usage warning. The three authored
Flashcards retain their existing IDs and canonical usage fields; no workaround
duplicates the examples into their meanings.

# QQL 254 — Edge Case Course coverage

`assets/courses/edge_case_it_en.json` is an Italian → English bundled, temporary
AI-generated testing Course. It contains 5 Lessons, 10 Rounds and 31 Exercises.
Its immutable identity is `course_6f6a1fa3-b834-4936-b324-92fb57f73502`, allocated
once with `Course.newCourseId()`. Regeneration preserves all identities.

The original Course is Published and immutable. It intentionally contains valid
Draft descendants. Keep **Show unavailable** enabled in Courses to find it:
turning that filter off hides Courses with any authored Draft descendant. Add it to the active
learner's Personal Library, then use the Learner or authoring Preview. The Learner
omits Draft Lessons, Rounds, Exercises and GuideBook content, with ancestor Draft
state taking precedence over Published children. Later Lessons still follow the
ordinary progression rules; Preview is convenient for isolated cases.

This is a manual boundary-testing fixture, not a reviewed language curriculum.
The MP3 cases are playback checks with self-reported answers, not comprehension
or transcription exercises. Audio Exercises and Text-to-speech are initially Off
for learners: enable both to run the complete Hybrid sequence. Create Duels is Off;
the deliberately small Lessons do not promise 25 eligible Duel questions.

## Case matrix and answer keys

Every ID below is prefixed with `qql_edge_254_`. IDs identify authored content;
option order may be shuffled at runtime, so answer keys use text or Item IDs.

| Case ID | Lesson / Round | Boundary | Correct answer / expected result |
| --- | --- | --- | --- |
| `e01_min` | 1 / 1 | Minimum ordinary Select options (2) | `yes` |
| `e02_max_translation` | 1 / 1 | Maximum Pick the translation options (5) | `a window` |
| `e03_many` | 1 / 1 | Large ordinary Select list (12) | `twelve` |
| `e04_duplicate` | 1 / 1 | Two identical wrong options with separate stable IDs | `red`; either `blue` is wrong; one intentional Audit Warning |
| `e05_unicode` | 1 / 1 | Accents, composed/decomposed characters, CJK, Korean, Greek, Arabic, emoji; Unicode source reference | `hello` |
| `e06_multi` | 1 / 1 | Multiple-selection Select | Select both `cat` and `dog` |
| `e07_long` | 1 / 2 | Reading passage over 1,200 characters, paragraph-width stress, mixed scripts | `blue`; one intentional Audit Warning |
| `e08_long_answer` | 1 / 2 | Long source and accepted answer | Exact authored English paragraph below |
| `e09_accents` | 1 / 2 | Composed and decomposed accepted answers | `café` (U+00E9) or `café` (U+0065 U+0301) |
| `e10_names` | 1 / 2 | Non-Latin text input | `東京 서울 Αθήνα القاهرة` |
| `e11_repeat` | 1 / 3 | Same Arrange word twice, distinct Item occurrences | `I really really like this book`; Items 1–6 |
| `e12_alternatives` | 1 / 3 | Two literal accepted Arrange orders | `I study at home today` (1,2,3,4,5) or `today I study at home` (5,1,2,3,4) |
| `e13_many_blocks` | 1 / 3 | 19 blocks, repeated `the`, 2 distractors | `the small black cat always sleeps quietly beside the open window in our warm kitchen every afternoon`; Items 1–17 |
| `e14_arrange_min` | 2 / 1 | One Arrange gap, one block, zero distractors | `I drink tea.` |
| `e15_arrange_repeat` | 2 / 1 | Two Arrange gaps; identical text on two distinct tiles | `It is very, very cold.`; first gap Item 1, second gap Item 2 |
| `e16_arrange_phrases` | 2 / 1 | Multiword gap blocks, 2 distractors | `I would like a cup of tea, please.` |
| `e17_select_min` | 2 / 2 | One Select gap and its single option | `a cat` |
| `e18_select_linked` | 2 / 2 | Reuse one Select option in two gaps | Choose `Was` for both gaps; `Was she happy? Was he late?` |
| `e19_select_distinct` | 2 / 2 | Two Select gaps with different answers, 2 distractors | `I am going to London.` |
| `e20_image_letters` | 3 / 1 | Image Word, zero extra letter blocks | `cat`; letters c,a,t |
| `e21_image` | 3 / 1 | Prompt image and multiword answer; underscore asset basename | `ice cream` |
| `e22_no_image` | 3 / 1 | Same concept without an image | `ice cream` |
| `e23_two_images` | 3 / 1 | Multiple prompt images and order | `cat and dog` |
| `e24_mp3` | 3 / 2 | One bundled MP3 resolved through Audio Library | If playback succeeds, choose `audio riprodotto`; report a failure if silent |
| `e25_mp3_sequence` | 3 / 2 | Longest-expression matching and sequential MP3 resolution | If both clips play, choose `due campioni riprodotti` |
| `e26_tts` | 3 / 2 | Unmapped English sentence in Hybrid uses TTS | `cat` |
| `e27_tts_spelling` | 3 / 2 | Unmapped TTS sentence with typed answer | `We are ready to leave.` |
| `e28_published` | 4 / 1 | Published item; Round has no optional custom title | `ready`; Learner sees this item |
| `e29_draft_exercise` | 4 / 1 | Valid Draft Exercise under Published Round | `late`; omitted from Learner |
| `e30_under_draft_round` | 4 / 2 | Published Exercise under Draft Round | `early`; ancestor hides it from Learner |
| `e31_under_draft_lesson` | 5 / 1 | Published Round/Exercise under Draft Lesson | `a copy`; ancestor hides both from Learner |

`e08_long_answer` accepts:

> Today I am writing a careful message to my friend because the train is late,
> the station is crowded, and I would like to explain that I will arrive after dinner
> with a small blue suitcase and a book about the history of our town.

In the stored answer this is one paragraph, with ordinary spaces between words.

## GuideBook and optional fields

Lesson 1 contains vocabulary using all four supported separators: ` = `, ` → `,
` - ` and `:`. It includes two authored `hello = ciao` entries with distinct IDs,
so they remain separate review occurrences. Content ID `qql_edge_254_v_caffè_日本語`
is referenced by `e05_unicode` and `e09_accents`; the reference is valid and must
survive export and be remapped when its containing Course is copied or forked.

Lesson 4's GuideBook is Draft and includes a Draft vocabulary entry alongside
Published entries. The Learner exposes none of that GuideBook's content.
Lesson 5 demonstrates a Draft ancestor above otherwise Published descendants.
No malformed or empty required field is used to represent a Draft.

Optional fields use their canonical empty/absent representation: no custom title
on `r08`, no Section or Lesson icon on Lessons 2, 4 and 5, no hint/feedback on
Exercises, no cover, age, study duration, custom flag, publisher contact, external
link or custom `courseVersion` field. The model omits empty optional fields during
serialization; the JSON does not insert redundant empty strings that would change
the official checksum after model normalization.

## Media and valid filename boundaries

The Course reuses these shipped assets without changing their bytes:

- `assets/exercise_images/cat.webp`, `dog.webp`, `ice_cream.webp`.
- `assets/lesson_icons/school.png`, `speech_bubbles.png`.
- `assets/audio/en_sample/sample_1.mp3` and `sample_2.mp3`.

There is no verified transcript for the shipped English sample recordings in the
current repository. `recorded sample one` and `recorded sample two` are explicit
lookup labels for playback tests, not claims about words spoken in those files.
The test does not invent a transcript or relabel an unknown recording as a known
English sentence. TTS comprehension cases use authored English sentences with
known answers. Shipped images and audio need no invented media-attribution record.

These references exercise nested directories, underscores, Unicode content IDs
and exact source references. Custom media filenames in Course Model v11 are always
`media:<lowercase SHA-256>.<extension>`; arbitrary paths, traversal and renamed
hashes are invalid. The test must not weaken this contract to accommodate unusual
names. To exercise unusual *external filenames*, export a personal fork using
Save to… with `Caffè_日本語 edge-case (1).zip`, then import it from that file.
An optional ZIP wrapper must exactly match the ZIP's basename; its internal
Course-owned media still retain their canonical content names. This file-picker
case requires an owner smoke test and is not claimed by the bundled asset alone.

## Audio mode matrix

Audio mode is Course-wide. The bundled value is `hybrid`. Fork the Course, then
change Audio Library mode and confirm the Course to test the other modes. Keep
the original bundled Course unchanged. With Enable Audio Exercises On:

| Mode | Text-to-speech | `e24_mp3`, `e25_mp3_sequence` | `e26_tts`, `e27_tts_spelling` |
| --- | --- | --- | --- |
| Hybrid | On | Bundled MP3s | TTS fallback |
| Hybrid | Off | Bundled MP3s | Audio unavailable |
| Recorded MP3 | On or Off | Bundled MP3s | Audio unavailable: no complete recording mapping |
| On-Device TTS | On | Speaks the fixture labels; does not test MP3 playback | Speaks authored English text |
| On-Device TTS | Off | Audio unavailable | Audio unavailable |

With Enable Audio Exercises Off, the Learner omits all four audio cases in every
mode. Authoring Preview ignores learner Audio Settings. Automated availability
checks establish source resolution and selection; audible output and installed
voice pronunciation still require a device smoke test.

## Exact Audit expectations

The full authored Course must have zero Errors and exactly these two Warnings:

| Code | Exercise ID | Why retained |
| --- | --- | --- |
| `CHOICE_ANSWER_DUPLICATE` | `qql_edge_254_e04_duplicate` | Two intentionally equal wrong options |
| `EXERCISE_TEXT_LONG` | `qql_edge_254_e07_long` | Reading passage deliberately exceeds 1,200 characters |

Informational findings such as Lesson Round guidance, missing Lesson introduction
or single-word capitalization are normal. They do not permit any additional
Warning or Error. Draft content uses the same Audit rules as Published content.
The seven retained bundles keep their existing zero-Warning, zero-Error gate.

## Fork, copy, merge and import scenarios

The fixture explicitly permits derivatives. Official originals cannot be edited,
copied with Copy as New Course, or merged. A valid path is:

1. Unlock Course Studio authoring, select the demo and **Fork** it. Verify new
   Course identity, preserved original provenance, immediate source identity and
   checksum, active learner as Maintainer, fresh child IDs, valid remapped
   `sourceRefs`, and separate Draft authoring state.
2. Use **Copy as New Course** on that personal fork. Verify another independent
   Course identity, fresh child IDs, reset original lineage, no fork provenance,
   and intact content/media references. This copy is a copy candidate; a fork and
   its independent copy are not automatically Merge-compatible because lineage
   metadata differs.
3. For Merge, export the personal fork, edit an Exercise in that same personal
   Course and confirm to create a newer Course version, then merge the stored
   Course with its exported earlier version. Same Course ID is permitted when
   version or Modified differs. Keep governance, language, audio mode/library,
   rights and remaining compatibility metadata unchanged. Choose source Lessons
   deliberately; confirm the new merged Course and check its provenance.
4. Export the bundled original and check JSON v11, package format 1 and official
   checksum. Ordinary Import must refuse to reinstall this bundled original:
   bundled Courses arrive only with app builds. Export/import a personal fork to
   exercise the accepted path, preserving publication state, IDs and media refs.
   The two intentional Warnings are reportable; any Error must still block import.
5. Open a personal fork in the Editor, inspect each gap case and the empty Round
   title, use Preview, make a harmless edit and Cancel; reopen to confirm no
   stored change. Repeat on the fork with Save and the top-level Course confirmation.

Use disposable learner-owned forks for mutation tests. Nothing in this fixture
resets learner progress or alters ordinary rights, scoring, progression or storage.

## Reproducibility and verification boundaries

`python tools/generate_edge_case_demo_254.py` writes only the fixture JSON.
`python tools/generate_edge_case_demo_254.py --check` compares it without writing.
The generator uses the current v11 structure and existing assets, never older
archives or sample-regeneration scripts. The course registry and release
validators include this separate fixture without replacing the Spanish→English
bundled Course.

Executable checks should cover full model round-trip and checksum, exact Audit
Warnings, learner Draft exclusion, gap and repeated-Item references, vocabulary
occurrences, real bundled asset resolution, all Course audio modes, package
export/parse/import, Fork/Copy identity remapping and compatible Merge. Their
fresh results belong in `254_VALIDATION.md`; this coverage specification alone
does not claim those commands passed. Owner smoke coverage remains narrow/wide
layout, scrolling, actual audio, voice quality, file-picker names and interactive
editor save/cancel workflows.

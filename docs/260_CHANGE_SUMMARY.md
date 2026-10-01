# Build 260 change summary

## Revision 0 (2.0.60+260000, 1 October 2026): Course languages

Plan and owner decisions: `docs/260_LANGUAGES_PLAN.md`.

**The language list.** `LanguageCatalog` (`lib/services/language_catalog.dart`,
entries in `language_catalog_entries.dart`) holds 227 languages: every
two-letter ISO 639-1 language and a curated set of three-letter regional
and minority languages. Each has a tag, an English name and other names
(native names, earlier English names). `resolve` recognizes a tag, an
English name, another name or a name in an instruction language, ignoring
capitals and accents; an English name wins a clash.

**New Course.** Source language and Target language are `LanguageField`s
(`lib/widgets/language_field.dart`): typing a listed language (in English,
natively or by tag) shows "Italian · it"; the list button opens a
searchable picker; a language not in the list is kept as typed, with an
optional tag checked for shape (`nap`, `pt-BR`, `zh-Hant`). The Course
stores the English name and the tag (`sourceLanguageTag`,
`targetLanguageTag`); the voice and the automatic flag follow the tag.

**Course Info.** The languages stay read-only and show whether they have a
tag. "Add the language tags from the list" adds the tags an earlier Course
lacks: a name QQL recognizes gives its own tag, otherwise the author picks
the language; a learning language tag that would move XP and streaks to
another language code is refused. `CourseInfoUpdateService` enforces the
same rules. "Learning language name for learners" stores the new Course
field `targetLanguageNameForLearners` (only when set; carried by Fork, Copy
and the transfer copy; a Merge keeps the left Course's).

**Instruction languages.** The learner panel's headings and lines are one
catalog per language in `lib/localization/exercise_copy/`: English,
Spanish, Italian, German, Portuguese, Dutch and the new French (AI-written,
pending review); Finnish and Welsh are removed. The catalog follows the
base language's tag, else the language its name or interface language
names; a key a catalog lacks falls back to English.

**Language names in the lines.** "Translate into {language}" names the
language in the instruction language: the Course's own name for learners,
else the table of about 60 common languages in the seven languages
(`lib/localization/language_names.dart`, AI-written, pending review), else
the English name, else the name the Course writes. Examples: a Spanish-base
Course reads "Traduce al italiano.", an Italian-base Course teaching
Neapolitan "Traduci in napoletano.".

**Three independent language settings** (owner clarification): QQL's own
interface is in English; Help and Course Info follow each learner's Help
Language (English, Spanish or Italian); a Course's learner panel follows
the Course's source language when it is one of the seven, otherwise
English. The QQL Guide's Help Language line says so.

**Help EN/IT/ES.** "How do I choose the Course languages?" (69 Editor Help
questions; it opens with the three independent settings) and the Course
Info answer.

Scoring, progression, Review, the Course format (one optional field) and
learner data are unchanged.

## Revision 1 (2.0.60+260001, 1 October 2026): the learner panel's buttons and messages

Plan point 6 (`docs/260_LANGUAGES_PLAN.md`).

**One catalog per language.** `lib/localization/learner_panel/` holds the
learner panel's buttons and messages in English, Spanish, Italian, German,
Portuguese, Dutch and French (107 keys each; the six translations are
AI-written, pending native review). `LearnerPanelText.of(course, key,
values)` (`lib/services/learner_panel_text.dart`) reads them in the same
instruction language as the exercise lines
(`ExerciseCopyService.instructionLanguage`, now public), English for a key
a catalog lacks, and fills `{name}` placeholders.

**What follows the Course's language.** In the Round: Check, Check matches,
Continue, Correct / Incorrect, Hint, Your answer, Missing word / Missing
letters, Correct answer, the translation lists, accepted differences, Play
audio and the audio notes, Listen to the answer, the flashcard buttons and
notes, the dialogue placeholders, the Assign labels, the link message,
Before you start with Open Guidebook and Continue to Round, Review your
mistakes, Reviewing exercises you missed, Finish / Leave / Finishing round,
story or sequence, "Story · N steps", the header line, and the end-of-Round
summary (Round completed, Correct answers, Perfect bonus, First Laurel,
Lesson completed, Total, Nothing to score, Weekly goal reached). In the
Duel: its title, the question counter, Listen and choose the meaning,
Correct / Incorrect, Correct answer, Finish duel, Continue, the result
titles and texts, Back to course. On the Review page: its title, Before /
After the Round, Lesson and Round, Word i of n, Show answer, I know it /
Now I know it / I still don't know it / Show it to me again, Review
completed!, Ready for Review, the word count, Next Review, Back to Course,
the empty message.

**What stays in English** (QQL's own interface): messages about errors and
App bugs, audio set-up instructions that name Settings, messages about what
this version of QuisquisLingo cannot play, the author's Preview and View
Only results, Report a problem, and the Review page's Reset Word List and
Review Help.

**Help EN/IT/ES** ("How do I choose the Course languages?") and the QQL
Guide line say the learner panel's buttons and messages follow the Course.

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 2 (2.0.60+260002, 1 October 2026): QQL Demo: English from Italian

Owner request of 1 October 2026.

**A fourth bundled Course**, `assets/courses/english_from_italian_it_en.json`
(`CourseService.courseAssets` code `EN_IT`, `_additionalBundledCodes` for
`course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05`, reserved in
`CourseEditorService`; `codeForCourse` is `EN`, so language XP and streaks
count it as English), written by `tools/generate_english_from_italian_260.py`
(`--check` verifies it). Italian to English, Beginner, All rights reserved,
derivative works forbidden, AI-written and awaiting review.

**One Lesson, "Primi passi", with a GuideBook**: an overview, four notes (a
or an, to be, the adjective before the noun, greetings) and 35 vocabulary
entries (Italian = English). Its eight Rounds: Pratica 1–3, the Story **Al
bar**, Pratica 4–6, the Story **Alla stazione**.

**The ordinary Rounds** hold 36 exercises of 36 different types, mixed at
random with a fixed seed, six to a Round, each Round opening with a Before
you start card that offers the GuideBook. The mix gives every Round one
exercise that needs audio and at most one card (Flashcard, Picture
flashcard, Note card), so each Round still plays with Audio Exercises off.

**The Stories** (scrolling, dialogue log): a card, a cover (the coffee and
train pictures), six Dialogue lines and two questions each. A narrator
speaks Italian; Tom, Emma, Anna and Ben speak English (bundled avatars).

The Course is Italian-based, so its learner panel shows the Italian lines
and buttons of Revisions 0 and 1. `tools/validate_courses.py` expects the
fourth file (en-GB, one Lesson).

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 3 (2.0.60+260003, 1 October 2026): Piedmontese showcase and Before you start

Owner review of 1 October 2026 (decisions: the mixed fix, the first Round's
card only).

**Pick the missing word and One word fills all** have an optional
**Instruction or context** (`_instructionField()`, first in the form;
`ExerciseFieldHelpRegistry.editorFieldKeys` starts with `prompt`; the
draft builder writes it as a `primary` text for the `gap_choice` recipe,
and `decompose` already read it back). The Round already drew such a text
in place of the standard line; until now the form could not keep it, so an
exercise with one opened in the canonical editor. Help EN/IT/ES name the
field in both presets; `exerciseHelpFieldKeyByPresetAndField` maps
`gap_choice.prompt` and `one_word_fills_all.prompt` to the shared
`exerciseHelp.field.instruction.body`.

**The Piedmontese demo showcases every preset again.** Nine of its
exercises were not represented by their preset and opened in the canonical
editor:
- Lesson 13, Pick the missing word: their instructions ("Complete the
  phrase meaning the dog.") are now a field of the preset (above);
- Lesson 25, Listen and answer (to source): the English answers are now
  marked source, as the preset writes them and the Laboratory has them;
- Lesson 34, Spell the word in the picture: the blocks are stored in the
  word's order, as the preset writes them (the Round shuffles them).
The same nine exercises in QQL Demo: Piedmontese follow. The v11 converter
fixture of the Piedmontese demo is rewritten from `build_course_v11()`.

**Before you start on the first Round only.** In QQL Demo: Piedmontese and
QQL Demo: English from Italian only the first Round of each Lesson opens
with a Before you start card (Open GuideBook), with a text that says what
the Lesson holds; the other Rounds and the Stories inside a Lesson start at
once. QQL Demo: English from Italian gets back the instruction of its Pick
the missing word ("Scegli la forma giusta di to be.").

Scoring, progression, Review, the Course format and learner data are
unchanged.

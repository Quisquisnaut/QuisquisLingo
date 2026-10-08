# Build 263 change summary

Owner review of 4 October 2026. The plan was discussed in chat and
approved the same morning ("ok a tutto, confermo"), with these decisions:

- Change only the standard lines whose first word repeats the first word
  of the title above them; nothing else (not a verb repeated further on,
  not the title's second verb, not the same verb in another form).
- Fill with an example takes the Exercise Laboratory's example of the
  preset, whatever the Course's languages.
- Square picture answers are cropped squares, with an editor that crops and
  zooms; the crop is stored as a cropped copy of the picture in the Course
  (owner choice over a crop stored as data). The picture defaults (size,
  shape, pictures per row) live in the Course Editor's Lesson Options, and
  each exercise may override them.

Revisions:

- Revision 0: the instruction lines, the word under picture answers, no
  Exercise image for Select the image and Listen and pick the image.
- Revision 1: Fill with an example, Clear all and the type-change notice in
  the preset form.
- Revision 2: picture answers: size, shape (with the square crop), pictures
  per row; Course defaults in Lesson Options with per-exercise override.

## Revision 2 (2.0.63+263002, 4 October 2026): picture answers: size, square crop, per row

**Why.** The owner asked that the pictures a learner chooses from could be
larger, square as well as round, and a chosen number per row. Asked, they
said: square means cropped to a square, with an editor that crops and
zooms; the crop is a cropped copy of the picture in the Course (chosen over
a crop stored as data); the defaults belong to Lesson Options, and the
single exercise may override them.

**Format.** Three Select options in the capability registry:

| Option | Values | Meaning |
|---|---|---|
| `pictureSize` | `course`, `normal`, `large` | 112 or 176 pixels wide |
| `pictureShape` | `course`, `round`, `square` | the round tile as before, or a square filled by the picture |
| `picturesPerRow` | `course`, `automatic`, `one` … `four` | as many as fit, or rows of that many |

The registry default of each is `course`: an omitted option means the
registry default, as Course Model v12 requires, and that default follows
the Course. Every existing exercise therefore keeps its look, and only a
value other than `course` is stored. The three options are listed with all
their values in every Select runtime-support configuration (the learner
draws every value), and `docs/capabilities_v12.json` is regenerated, so the
Python tools know them.

The Course's defaults are the Course field `pictureAnswers`
(`PictureAnswerStyle`: size, shape, perRow; never `course`), written only
when it differs from the standard look (normal, round, automatic). A value
that is unknown or `course` is a format error, never a default. Fork, Copy
as New Course and the transfer copy keep it; Merge keeps the left Course's,
like every Course field.

A Course that asks for another look, in Lesson Options or in an exercise,
records `minimumAppBuild` 263002 when it is confirmed (as Pages do with
258000): an earlier build then refuses it with a clear reason, where it
would otherwise refuse the exercises' unknown options.

**Lesson Options.** A Picture answers group after Create Duels: Picture
size (Normal, Large), Picture shape (Round, Square, cropped), Pictures per
row (As many as fit, 1–4).

**The preset forms.** Select the image and Listen and pick the image show,
under their pictures, the same three choices, each starting with "As in
Lesson Options (…)" that names the Course's current choice. The form's
values (`ExerciseDraftValues.pictureSize`, `pictureShape`,
`picturesPerRow`) become options in `ExerciseDraftBuilder._withPictureLook`
and are read back by `PresetRecipes.decompose`, so the preset still
represents its exercise. Another Select preset never writes them: an
exercise of such a preset that has them (set in the canonical editor) opens
in the canonical editor, which shows the options of any Select.

**Crop square.** Each picture of an answer (in those two forms and in Match
pictures to words) has Crop square (`answer-picture-crop-<i>`): the cover's
crop editor opens, titled Crop square (`showCoverCropDialog` takes a title
and a guidance line; the cover and the Story avatar keep theirs); the
square is drawn at 512 pixels, halved until it is at most 300 KB, stored as
a new picture of the Course (`CourseCoverService.storeSquare`) and takes
the answer's place. The original picture is untouched; a QQL picture that
is cropped becomes a Course picture. A cancelled editing session removes
the copy with the session's other new media (Build 248).

**What the learner sees** (`RoundScreen._iconChoiceExercise`): the
exercise's own choices, else the Course's. The standard look is drawn
exactly as before (the Laboratory presentation baseline is unchanged). A
large tile is 176 pixels; a round tile scales the standard one; a square
tile is filled by its picture (cover fit, a named icon in the middle with
its word); with a number per row the tiles stand in centred rows and
shrink on a narrow screen so that a row stays whole. The Duel is unchanged.

**Tests.** `test/owner_review_263_revision2_test.dart` (16): the options
and their default, the Course field stored only when needed and parsed
strictly, override rules, `minimumAppBuild`, the form's values written and
read back (and represented), As in Lesson Options storing nothing, another
preset not taking the look, the fields' Help, the form showing the three
choices and Crop square only for a picture, the learner's standard look,
large squares two per row, an exercise overriding the Course, a 360-pixel
screen keeping four per row, Crop square storing a square copy within
300 KB, and Lesson Options changing the Course. Updated: the Select
defaults in `capability_registry_256_test`, the field inventory in
`exercise_field_help_226_02_test`, and a taller window in one
`optional_learning_paths_226_04_test` (Lesson Options grew).

Course scoring, progression and learner data are unchanged. Beta expiry
`2026-11-03 23:59:59` local time.

## Revision 2 follow-up (same version, 4 October 2026): the standard look, at most three per row

The owner's review the same morning, with the recommendations accepted:

- **The standard look is large squares, two per row.** `PictureAnswerStyle.standard`
  is now large, square, two per row: what every Course that has not chosen
  shows, the two bundled demos included, and what the Course field
  `pictureAnswers` is compared with (only a difference is stored). Two per
  row because "as many as fit" puts one large picture per row on a
  360-pixel phone; with two per row they shrink to 155 pixels there. The
  earlier look (`PictureAnswerStyle.earlier`: normal, round, as many as
  fit) remains a choice. Nothing had left the owner's PC, so no Course
  needed converting.
- **At most three per row**: `PicturesPerRow.four` is removed (four tiles
  would be about 72 pixels on a phone, smaller than the earlier 112).
- **A short last row stands in the middle**: rows were already centred with
  a number per row (four pictures, three per row: the fourth in the middle
  of the second row; three pictures, two per row: the third); "as many as
  fit" now centres its rows too (`WrapAlignment.center`).
- **Lesson Options order**: Lesson and Round label and numbering, then Use
  GuideBook, Create Duels, Default Timed limits, Picture answers. In the
  dropdowns the standard choice comes first (Large, Square, cropped, 2).
- Help EN/IT/ES name the standard look and the three-per-row limit.
- Laboratory presentation baseline: the two picture-answer examples
  (Select the image with QQL pictures, Listen and pick the image) now hold
  their picture in each button (`<Image>` instead of `<Column>`).

## Revision 1 (2.0.63+263001, 4 October 2026): Fill with an example and Clear all in the preset forms

**Why.** The canonical editor has had Fill with an example and Clear all
since Build 261 Revisions 5 and 6, and a message when the primitive changes
over a filled form. The owner asked for the same in the preset forms.

**Fill with an example.** Under the preset selector of a new exercise
(`exercise-fill-example`). The example is the Exercise Laboratory's exercise
for that preset (`PresetExamples.exampleIds`, `lib/services/preset_examples.dart`),
chosen to show the preset's fields well (for example Select the image with
QQL pictures, not named icons; Dialogue line with the narrator, so no
speaker is needed). It is read from the bundled Laboratory
(`CourseService.loadBundledCourse('IT')`), given the new exercise's ID and
fresh item IDs (`AuthoringDuplicationService.duplicateExercise`), and loaded
into the form through `PresetRecipes.decompose`; for Recognize characters
the character editor is rebuilt from it. When the form has unsaved changes a
dialog asks first (`exercise-fill-example-confirm`). The example stays in
English and Italian whatever the Course's languages (owner decision). If the
Laboratory cannot be read, a message says so (`exercise-fill-example-missing`).

**Clear all** (`exercise-clear-all`). The form returns to how its type
starts: what `_blankExerciseWithId` (the Round editor's new exercise, now
with a given ID) decomposes to, plus what choosing the type in the picker
adds (`_applyPresetStart`: Pick the translation's first option correct,
True or false's two answers in the source language; a single-answer Choose
starts with answer 1 as before). A form with unsaved changes asks first
(`exercise-clear-all-confirm`); afterwards leaving asks nothing.

**Changing the type** of a new exercise over a form that differs from its
start shows the SnackBar "You changed exercise type. Please check all
fields." (`exercise-preset-changed-notice`), as the canonical editor does.

**One loader.** The form's opening and Previous/Next each copied the
decomposed draft into some thirty fields; `_loadDraft` is now the one
loader, also used by the two buttons. `_formGeneration` gives the Page
block editor, which keeps its blocks as its own state, a new key after a
fill or a clear.

**Tests.** `test/owner_review_263_revision1_test.dart` (11): every preset
has a Laboratory example that it represents and that uses no other Course's
picture; Fill on a blank form, Fill asking over a filled one, Clear all back
to the start (and leaving asks nothing), True or false starting again with
its answers, the type-change message, no buttons on an existing exercise,
and for every one of the 46 presets: Fill, Save as draft, the saved exercise
is represented by its preset, has the example's items and no Laboratory ID.

Course files, scoring, progression and learner data are unchanged. Beta
expiry `2026-11-03 23:59:59` local time.

## Revision 0 (2.0.63+263000, 4 October 2026): titles and lines, picture answers

**Why.** Under the title PICK THE TRANSLATION the learner read "Pick the
correct Italian translation": the same verb twice in a row. The owner asked
for a check of every preset. Since Build 261 Revision 3 the title is the
preset's name, and many standard lines (written in Build 259 Revision 7 to
avoid the older kind headings) began with the same word as the new title.

**The check.** For every preset, every standard line its exercises can show
(with the variants: one gap or several, letters inside a word, a question
heard, a picture, a clue) was compared with its title in the seven learner
languages. Lines that open with the title's first word:

| Language | Presets |
|---|---|
| English | 11: Pick the translation, Pick the missing word, Pick the words for the gaps, Type the missing word, Listen and answer, Type what you hear, Listen and fill the gaps, Spell what you hear, Spell the word in the picture, Type what you see, Spell the word; and Put the sentences in order when its lines are single words |
| Italian | 8: Scegli la traduzione, Scegli la parola mancante, Scegli le parole per gli spazi, Scrivi la parola mancante, Ascolta e rispondi, Scrivi ciò che senti, Ascolta e riempi gli spazi, Scrivi ciò che vedi |
| Spanish | 12 |
| French | 14 (also Associe les mots, Associe par le sens, Associe images et mots) |
| Dutch | 10 |
| German | 3 (Buchstabiere …) |
| Portuguese | none (its titles are infinitives) |

**What changed.** Only those lines, in `lib/localization/exercise_copy/`.
A shared line changes for every preset that uses it (Complete the text
shares Type the missing word's lines). English:

| Key | Was | Now |
|---|---|---|
| `selectTranslation` | Pick the correct {language} translation | Choose the correct {language} translation |
| `selectComplete` | Pick the block that fits the gap. | Choose the block that fits the gap. |
| `arrangeGaps` | Pick a word for each gap. | Choose a word for each gap. |
| `inputCompleteOne` | Type the word that completes the sentence. | Write the word that fills the gap. |
| `inputComplete` | Type the words that complete the sentence. | Write the words that fill the gaps. |
| `inputCompleteLetters` | Type the missing letters. | Write the missing letters. |
| `inputPictureName` | Type the name of the picture. | Write the name of the picture. |
| `inputListenWrite` | Type every word you hear. | Transcribe every word you hear. |
| `selectListenQuestion` | Listen and answer the question. | Answer the question about what you hear. |
| `inputListenGaps` | Listen and complete the missing word. | Fill in the missing word you hear. |
| `arrangeWordHeard` | Spell the word you hear. | Form the word you hear. |
| `arrangeWord` | Spell what the picture shows. | Form the word the picture shows. |
| `arrangeWordClue` | Spell the word the clue describes. | Form the word the clue describes. |
| `arrangeSentence` | Put the words in the correct order. | Arrange the words in the correct order. |

The plan proposed "Write every word you hear.", "Complete the missing word
you hear." and "Build the word …". Those would open with the heading that
an exercise no preset represents shows (WRITE WHAT YOU HEAR, COMPLETE,
BUILD THE WORD), so the lines use Transcribe, Fill in and Form instead.

Italian: Seleziona (traduzione, blocco), Metti una parola in ogni spazio,
Inserisci (la parola che manca / le parole che mancano nella frase, le
lettere mancanti, il nome dell'immagine, la parola mancante che senti),
Rispondi alla domanda su ciò che senti, Trascrivi ogni parola che senti.
Spanish: Selecciona, Introduce, Pon, Responde a la pregunta sobre lo que
oyes, Transcribe, Compón. French: Sélectionne, Relie (also "Relie chaque son
à son mot", whose ASSOCIE LES SONS heading repeated it), Saisis, Place,
Réponds à la question sur ce que tu entends, Transcris, Forme, Range les
mots. German: Bilde das Wort … Dutch: Selecteer, Zet een woord in elk gat,
Breng, Beantwoord de vraag over wat je hoort, Maak het ontbrekende woord af,
Bouw, Schrijf de naam.

Not changed, by owner decision: a title's verb repeated further on in the
line (Type the missing word's first-letter line, One word fills all, Name
what you see, Complete the text), a line opening with the title's second
verb (French ÉCOUTE ET CHOISIS → "Choisis la phrase…", Dutch LUISTER EN
KIES → "Kies de zin…"), and the same verb in another form (German and
Portuguese infinitive titles, imperative lines).

The Help quotes "Choose the correct [Target language] translation" (EN, IT,
ES: Exercise Help of both Pick the translation presets and of their text
field; the Exercise editor's note; `docs/COURSE_EDITOR.md`).
`TranslationChoice.instruction` says the same.

**A picture answer shows no word.** `RoundScreen._iconChoiceExercise` drew
the item's word under every option except a QQL picture (an `assets/` icon
key). Since Build 256 Revision 4 a Course picture is a picture element on
the item, so a Course picture of an apple showed "mela" under it, and in
Listen and pick the image the word gave the answer away. Now no picture,
QQL or Course, shows its word; a named icon (such as `sun`, drawn as a
symbol) keeps its word, as before Build 256 Revision 4.

**No Exercise image for Select the image and Listen and pick the image.**
Their answers are pictures; an Exercise image above them only confused.
The form, `ExerciseFieldHelpRegistry.editorFieldKeys` and the field Help
map drop it, as for Match pictures to words in Build 259 Revision 5; Editor
Help's "Which exercises use a picture?" says so (EN, IT, ES). An exercise
stored with such a picture keeps it; none of the six bundled ones has one.

**Tests.** `test/owner_review_263_revision0_test.dart`: in the seven
languages, no line any preset can show opens with its title's first word,
and no line of a kind opens with that kind's heading; Pick the translation
chooses; a Course picture answer hides its word while a named icon keeps
it (the test fails without the fix); the two presets have no `image`
field. Updated pins in eight test files. The Laboratory presentation
baseline re-records 19 records (38 values, before and after answering):
only their standard lines.

Course files, scoring, progression, Review, the Duel and learner data are
unchanged. Beta expiry `2026-11-03 23:59:59` local time.

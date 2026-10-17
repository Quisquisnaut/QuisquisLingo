# Same-language Courses plan

Owner's idea and decisions of 16 October 2026: Courses that teach a language
in that language (English to English, Spanish to Spanish, any language to
itself). Planned while Build 274 was running (read only: this document is the
only thing written). **Build 275**, after Build 274's remaining revisions
(owner decision of 16 October 2026; the modularization left over from
Build 273, its Revisions 10–12, becomes Build 276). Several correct
translations in the GuideBook joined the plan the same day (Revision 6 since
the owner's decisions of 17 October 2026 added Revisions 2 and 3).

Every revision, as in the earlier Builds: version `2.0.75+275RRR`, Beta
expiry 30 days from its release day, `CHANGELOG.md`, `README.md`, the
`AGENTS.md` release entry, `docs/275_CHANGE_SUMMARY.md`,
`docs/275_VALIDATION.md`, `docs/275_HANDOFF.md`; focused tests while working
(a new widget test file is run six times or more before the suite), an
independent read-only review, `flutter analyze` and the complete suite once
on the final tree; one commit, the branch pushed. Help EN/IT/ES wherever a
screen or a rule an author reads changes. When a learner catalog changes,
`docs/LOCALIZATION_CURRENT_STATE.md` follows it.

## The owner's decisions (16 October 2026)

1. **Any language to itself**: English to English, Spanish to Spanish, and
   so on, not only English.
2. **The second side is called Meaning**: in a same-language Course, today's
   "source" side (the translation) holds a meaning: a definition, a synonym
   or a short explanation, in the same language.
3. **Variants**: a Course between two variants of one language (English (UK)
   to English (US)) is **not** same-language: it translates between the
   variants (lift → elevator). *Since Revision 2 (decision 13) the creator
   decides: two variants written as two languages make a translation
   Course.*
4. **Languages without a learner catalog** (Korean to Korean, …) are
   allowed: their buttons and instructions are in English, as today for
   every language outside the seven catalogs.
5. **Names change for learners and in the Course Editor**: in a
   same-language Course the exercise titles, the instruction lines and the
   preset names say "word" and "meaning", never "translation". The stored
   preset IDs never change.
6. **The Course Wizard's Basics step asks clearly what kind of Course it
   is** (owner's words: "what type of course").
7. **A direct link** from that question to a new FAQ in the Course Editor
   Help: how each kind works, and its didactic pros and cons, to help the
   author choose (draft at the end of this document).
8. **The plan's defaults a to e** (accepted as proposed):
   - a. *Type the meaning* stays: typing a short meaning such as a synonym is
     graded against the accepted answers like a translation; the Help says a
     whole definition cannot be typed word for word.
   - b. A region (or script) on one side only (English and English (US))
     counts as same-language; two different regions or scripts (en-GB and
     en-US, sr-Latn and sr-Cyrl) make it a translation Course. *Replaced by
     decision 13 in Revision 2: nothing is derived from the tags.*
   - c. The names in the table of Revision 4, and "Through another
     language" / "In the same language" on the Basics cards.
   - d. The test Course to import is English to English only.
   - e. Fill with an example follows the kind: with "In the same language"
     chosen it fills an English to English example, and the later steps'
     examples (Lessons, GuideBook module) follow it.

### Several correct translations (owner, 16 October 2026; Revision 6)

9. **Repeated rows**: two GuideBook rows, Sentences as well as Words &
   Expressions, with the same Source (and the same Context) are
   alternatives: each one's Target is a correct answer for the other.
   The other way round too: rows with the same Target (and Context) are
   alternative translations of it.
10. **The exercise editor's syntax in the GuideBook as well**, not only
    repeated rows: `{…}`, `[a|b]` (with linked `[*:a|b]` groups) and `<>`
    are accepted in the GuideBook and explained in its Help as the exercise
    forms' Help explains them.
11. **Type the translation from Sentences**, as a Round Wizard option, and
    only into the language being learned.
12. **Advice to the author**: the Round Wizard's typed exercises accept only
    the answers the GuideBook gives, so every correct translation must be
    written in the GuideBook.
17. **How the learner's GuideBook shows them** (owner, 17 October 2026,
    option E of the mockup https://claude.ai/artifact/YJLEZmTbXeHPY4hPmCoCnS):
    every form in full, in bold, one per line, the translation once after
    the last; rows with the same Source **and** the same Context are shown
    together as one entry, and rows whose Contexts differ stay separate,
    each with its Context.

### The creator chooses (owner, 17 October 2026; Revision 2)

13. **The creator's choice decides, and it is stored.** Owner's words: "The
    creator chooses whether the course is "same language" kind or "through
    another language" kind. In the former case, the course will not use
    translations but meanings. Therefore, it's up to creators to decide
    which pairs are "same language"." The kind chosen when the Course is
    made is written in the Course file and never derived from the language
    tags (the derived rule confused authors: variants against dialects,
    Viterbese typed beside Italian). Agreed with the owner the same day:
    - In the same language keeps one Language field (both sides are that
      language) and the optional Language variant;
    - Through another language takes any two languages, two variants of one
      language too (English (UK) and English (US)); it refuses only one
      language written twice, the same name and the same tag.

### Meanings and the Wizard's first step (owner, 17 October 2026; Revision 3)

14. **In a same-language Course a meaning is the language being learned**:
    Word Lookup looks up the words of a meaning, and a meaning gets the
    speaker on request wherever a word would (a Course with recorded MP3s
    lists the meanings among its texts to record).
15. **Four lines become neutral**, right for a word, a phrase or a sentence;
    the titles stay as named: Pick the word "Choose the answer that fits
    this meaning.", Type the word "Write the answer that fits this
    meaning.", Type the meaning "Write what this means.", Match words and
    meanings "Pair each item with its meaning."
16. **The Course Wizard's first step stays read-only** once Continue with
    Wizard has made the Course (as in manual creation, the languages are
    fixed once the Course is made), and **Continue with Wizard asks
    first**: "Are you sure? After this step the kind of Course and its
    languages cannot be changed, unless you leave the Wizard without saving
    and start a new one."

### What authors read (owner, 17 October 2026; Revision 4)

18. **New Course asks too**: its Continue to Editor asks the Wizard's
    question before the kind and the languages become fixed.
19. **New Course's sample exercise** in a same-language Course reads
    "Meaning in English" and "Word in English" (kept as proposed).
20. **The Help texts that still named languages are fixed in Revision 4**:
    Listen and answer's Question and the GuideBook picture's Help.
21. **Two earlier dialogs that show raw preset IDs** (the reading-derived
    exercises, the Round Wizard's findings), in both kinds of Course, are
    fixed in a later revision of their own.
22. **Word Lookup in a Course of synonyms paired both ways** (glad = happy,
    happy = glad), which can show the answer in Pick the word or Type the
    word, is left as it is: authors can avoid pairing both ways or turn
    Word Lookup off in Lesson Options.

## The rule: one owner, the creator's choice stored

- **`CourseLanguagePair`** (`lib/services/course_language_pair.dart`, pure
  Dart): `isSameLanguage(course)` and `kindOf(course)`.
- **Stored, never derived** (Revision 2, decision 13): `Course.sameLanguage`,
  written as `"sameLanguage": true` only for a Course made In the same
  language. A Course's kind and languages never change after it is created
  (Build 260 Revision 0). A Course in the same language asks for
  `minimumAppBuild` 275002 (`CourseLanguagePair.withMinimumAppBuild`, the
  last rule of `CourseMinimumBuild.stamp`): an earlier app would drop the
  field on its first save.
  - *Revision 0 and 1 derived the kind from the two languages (the primary
    subtags, a region or script on one side only, a name typed by hand).
    No Course was stored with that rule outside the owner's tests.*
- **Never test "same-language" anywhere else**: screens, services and
  catalogs ask `CourseLanguagePair`. (A study format, such as the card decks
  discussed the same day, would be a separate choice: a deck can be
  same-language too.)

## Revision 0: choosing the kind of Course

Delivered as `2.0.75+275000`.

### Course Wizard, Basics step

- **Today**: Basics asks for the title, the learners' language (Source), the
  language to learn (Target) and an optional variant. Explanation: "Set a
  title for your Course and insert the learner's language (Source) and the
  language to be studied (Target)…".
- **Change**: before the title and the languages, the question **What kind
  of Course?** with two cards, neither chosen at first:
  - **Through another language** (`course-wizard-kind-other`): "For example
    Italian for English speakers. Learners read instructions and
    translations in the language they already speak." The two language
    fields follow, as today.
  - **In the same language** (`course-wizard-kind-same`): "For example
    English explained in English, for intermediate and advanced learners or
    native speakers. Everything is in the language being learned." One
    field follows, **Language** (`course-wizard-language`), written on both
    sides (name and tag).
  - Under the cards, the link **Which should I choose?**
    (`course-wizard-kind-help`) opens `EditorHelpScreen(question:
    'courseKind')`, the new FAQ, as the Wizard already opens its own
    (`EditorHelpScreen(question: 'courseWizard')`).
  - The kind is required like the languages: Continue with Wizard says
    what is missing; Continue by hand opens New Course's form, whose
    Continue to Editor says it (as built: Continue by hand never refused
    anything).
  - The variant field stays (optional).
- **After the Course exists**, Basics shows the kind read-only
  (`course-wizard-kind-shown`: "In the same language: English"), next to
  the title and the variant, as the languages are today.
- Explanation and Tell me more are rewritten for the two kinds.
- **Fill with an example** (default e): with a kind chosen, it fills that
  kind's example (In the same language: an English to English Course and
  title); with none chosen, it chooses Through another language and today's
  example.
- Where: `lib/screens/course_wizard_screen.dart` (Basics, `_explanationText`),
  `CourseWizardBasics` and `CourseWizardSample` in
  `lib/services/course_wizard.dart` (the kind is form state only, never
  stored).

### New Course's form (Continue by hand)

- The same two choices (`new-course-kind-other`, `new-course-kind-same`),
  prefilled from the Wizard; In the same language shows one Language field;
  the same link (`new-course-kind-help`).
- Where: `lib/controllers/new_course_form.dart` (the kind; `submit` writes
  both languages), `lib/screens/new_course_dialog.dart`.
  `CourseLibraryOperations.newCourse` is unchanged: it receives equal
  languages.

### Course Info

- The learner's Course Info, Languages card: a line **Same-language
  Course** under the languages (`course-info-same-language`; EN/IT/ES key
  `courseInfo.sameLanguage`, beside `courseInfo.learningLanguage`).
- The Course Info Editor shows the same line by the languages, read-only.

### The FAQ

- New Editor Help question **`courseKind`** in the topic that holds
  `courseLanguages` (`lib/localization/help/help_structure.dart`), EN/IT/ES
  (`editorHelp.qa.courseKind.q` / `.a`). Text: the draft at the end of this
  document, as the owner corrects it.
- The answers of `courseLanguages` and `courseWizard` point to it.

### Tests

`test/same_language_courses_275_test.dart`: the rule's table (`es`/`es`,
`en`/`en-US`, `en-GB`/`en-US`, `sr-Latn`/`sr-Cyrl`, two names typed by hand,
`en`/`it`); the Wizard refuses to go on without a kind; In the same language
writes both languages; Continue by hand is prefilled; Fill with an example
follows the kind; the Course Info line; the link opens the FAQ; the FAQ in
the three catalogs.

## Revision 1: what learners read

Delivered as `2.0.75+275001`. The lines follow the rule of Build 263
Revision 0 (no line opens with the first word of its title): "Write the
word for this meaning." under TYPE THE WORD, "Form the sentence…" under
BUILD THE SENTENCE.

- **Today** (`lib/localization/exercise_copy/exercise_copy_en.dart` and the
  six others; `lib/localization/learner_panel/`):
  - titles `title.pick_the_translation`, `title.type_the_translation`,
    `title.build_the_translation`; kind headings `type.inputTranslation`
    (TYPE THE TRANSLATION), `type.arrangeTranslation`,
    `type.matchTranslation`;
  - lines `instruction.selectTranslation` ("Choose the correct {language}
    translation", also in the Duel), `instruction.inputTranslation`
    ("Translate into {language}."), `instruction.arrangeTranslation`,
    `instruction.matchTranslation` ("Pair each word with its
    translation.");
  - learner panel `correctTranslations`, `otherCorrectTranslations`,
    `somePossibleTranslations` (the answer feedback in `RoundScreen`),
    `wordLookup.note`, `wordLookup.notes`, `wordLookup.notice` ("…see a
    translation from this Course's GuideBook…").
- **Change**: in a same-language Course these read "word" and "meaning":
  - titles PICK THE WORD, PICK THE MEANING, TYPE THE WORD, TYPE THE MEANING,
    BUILD THE SENTENCE, BUILD THE MEANING, MATCH WORDS AND MEANINGS (the
    names of Revision 4's table, so `ExerciseTitle.slugOfName` keeps working
    from the name);
  - lines such as "Choose the word for this meaning.", "Choose the correct
    meaning.", "Type the word for this meaning.", "Type the meaning of this
    word.", "Build the sentence with the word blocks.", "Build the meaning
    with the word blocks.", "Pair each word with its meaning."; the
    direction (word or meaning asked) comes from
    `ExerciseFeatures.promptLanguage`, as "Translate into {language}" does
    today; no language is named;
  - "Correct answers:", "Other correct answers:", "Some possible answers:";
  - Word Lookup: "One possible meaning from this Course's GuideBook.",
    "Some possible meanings…", and the notice "…see its meaning…".
- New keys in the seven catalogs (six AI-written, as before); a missing key
  falls back to English per key, as today.
- **One switch**: `ExerciseCopyService` (`title`, `instruction`,
  `instructionForExercise`) and `LearnerPanelText.of` ask
  `CourseLanguagePair`; `RoundScreen` and `DuelScreen` only call them as
  today.
- A translation Course is unchanged: the Laboratory presentation baseline
  stays as it is (a test checks it).
- **To confirm when the revision starts** (left as they are in Revision 1
  and put to the owner; decided on 17 October 2026 and delivered in
  Revision 3, decision 14):
  - Word Lookup skips text marked as the Course's source language; in a
    same-language Course a meaning is in the language being learned, so
    Word Lookup could look its words up too.
  - Playback on request (Build 274 Revision 2) offers a speaker only for
    target-language text; a meaning could be offered one too.
- Tests: every new key in the seven catalogs; a same-language Course's
  exercises show the new titles, lines and feedback (Round, Review, Duel,
  Preview); a translation Course shows today's.

## Revision 2: the creator's choice is stored

Delivered as `2.0.75+275002` (owner decision 13, 17 October 2026).

- **The Course file**: `sameLanguage` (a boolean, written only when true;
  any other value is a format error; `tools/validate_courses.py` checks it).
  `docs/COURSE_JSON_FORMAT.md` documents it.
- **Made by the two forms**: the Course Wizard's Continue with Wizard and
  New Course's Continue to Editor write the kind chosen
  (`CourseLibraryOperations.newCourse` / `newWizardCourse(sameLanguage:)`).
  Continue by hand carries it to New Course's form, as before.
- **Kept by the copies**: Fork and Copy as New Course
  (`AuthoringDuplicationService`), Move/Copy to another Lesson
  (`CourseAuthoringTransferService`), the Publisher export (the JSON). A
  Merge refuses two Courses of different kinds, in either order
  (`CourseMergeService.sameLanguageMismatch`; its comparison of the Course
  fields saw the field from one side only, because it is written only
  when true: found by the independent review).
- **`minimumAppBuild` 275002** for a Course in the same language.
- **Through another language**: refused only for one language written
  twice (`CourseLanguagePair.identicalChoices`: the same name and the same
  tag, capitals and accents ignored); the message says to choose In the same
  language or write two different languages.
- **Removed**: the derivation (`sameTags`, `sameLanguages`, `sameChoices`,
  the cache), the advice to type variants by hand with their tags, and
  Course Info's check that a tag never changes the kind
  (`CourseInfoUpdateService.keepsKind`, `kindChangeRefusal`): a tag no
  longer decides anything.
- **Unsaved course changes** names a difference of the field as "Kind of
  Course" under Course Info (it never changes, but a list must name every
  field).
- **New Course's form never picks a kind** for languages it receives
  without one (`_kindOfLanguages` removed): the creator chooses.
- `tools/validate_courses.py` refuses `sameLanguage: true` with two
  different language names (QQL's own files).
- Help EN/IT/ES: the FAQ `courseKind` says QQL keeps the choice, that two
  variants fit either kind (Through another language translates between
  them, each with its tag in Language tag, en-GB and en-US, for the
  device's voice and the flag; In the same language teaches one of them),
  and that In the same language writes the language once.
- Tests: `test/same_language_courses_275_test.dart` (the stored kind, a
  strict field, the same languages without the choice translate, the
  refusal and two variants accepted, the minimum build, a real save
  through `CourseEditorService`, a Merge of two kinds refused both ways,
  the copies); `test/same_language_learner_275_test.dart` makes its
  Courses In the same language; `new_course_form_272_test` expects no
  kind for prefilled languages without one.

## Revision 3: meanings, and the Wizard's first step

Delivered as `2.0.75+275003` (decisions 14 to 16, 17 October 2026).

- **Word Lookup**: `WordLookupScope(sameLanguage:)` (the Round screen gives
  `CourseLanguagePair.isSameLanguage`); `LookupText` skips text marked as
  the source language only outside a same-language Course. Pick the
  translation's question is a `LookupText` when it is a meaning (marked
  source); a question in the language being learned stays plain text, as
  before, because its GuideBook entry would show the answer.
- **The speakers**: `PlaybackOnRequest.promptText`, `answerText`,
  `optionWord` and `texts` take `sameLanguage`: text marked as the source
  language is heard like target-language text (Pick the word's meaning,
  Pick the meaning's right meaning after the answer, the meaning Type the
  word and Build the sentence show, the meaning Type the meaning and Build
  the meaning accept). `CourseAudioUsage.spokenTexts(sameLanguage:)`,
  `usesByClip` and `CourseAudioTexts.of` ask the Course, so the Audio
  Library's Texts in this Course and Used in N exercises know the
  meanings; `ExerciseMascotRoom.of(sameLanguage:)` keeps the speaker's
  room beside the prompt. The voice is the text's language, which in a
  same-language Course is the one language.
- **The lines**: `instruction.sameLanguage.selectWord`, `inputWord`,
  `inputMeaning`, `matchTranslation` in the seven catalogs (six
  AI-written); Build 263's first-word rule kept.
- **The Wizard**: `CourseWizardScreen.confirmsLanguages` (off in the tests
  written before it), a dialog (`languagesFixedTitle`,
  `languagesFixedMessage`) whose Continue is
  `course-wizard-languages-fixed-confirm`; Cancel stays on the first step;
  Continue by hand never asks.
- When both the sentence and the answer can be heard (same-language
  Courses only), the answer's speaker is `translation-choice-answer-audio`
  and the note that audio is off is shown once.
- Help EN/IT/ES: Word Lookup (Editor Help and App Info), Texts to record,
  the Course kind answer (meanings looked up and heard; the Wizard's
  question).
- Tests: `test/same_language_meanings_275_test.dart`; a Wizard case in
  `test/same_language_courses_275_test.dart`; the new lines in
  `test/same_language_learner_275_test.dart`.

## Revision 4: what authors read

### Preset names

| Today | In a same-language Course | The learner |
|---|---|---|
| Pick the translation (to target) | **Pick the word** | reads a meaning, picks the word |
| Pick the translation (to source) | **Pick the meaning** | reads a word, picks its meaning |
| Type the translation (to target) | **Type the word** | reads a meaning, types the word |
| Type the translation (to source) | **Type the meaning** | reads a word, types a short meaning such as a synonym |
| Build the translation (to target) | **Build the sentence** | reads a meaning, builds the sentence from blocks |
| Build the translation (to source) | **Build the meaning** | reads a sentence, builds its meaning from blocks |
| Match the words | **Match words and meanings** | |
| Choose the answer, Listen and choose, Listen and answer, Read and answer (to target) | the same names without "(to target)" | |
| Choose the answer, Listen and choose, Listen and answer (to source) | **not offered for new exercises** | they would do exactly what the "to target" ones do |
| every other preset | unchanged | |

- **One owner** for the name an author reads:
  `ExercisePresetRegistry.nameIn(course, presetId)` (beside `nameOrId`).
  Its callers today read `nameOrId` or a preset's `name`: the preset list
  and the form header (`exercise_editor_screen.dart`), the Course Editor's
  pages (`course_editor_screen.dart`), Search
  (`course_editor_search_screen.dart`, `exercise_search_service.dart`), the
  Round editor's rows (`exercise_labels.dart`), the Audit's messages
  (`course_audit_service.dart`), the Exercise Wizard
  (`exercise_creation_planner.dart`) and the learner title
  (`exercise_title.dart`). The Exercise Help lists every preset under its
  usual name and says what it is called in a same-language Course.
- **Not offered**: the three "to source" twins leave the preset list, the
  Exercise Wizard and the Story step sheet in a same-language Course (an
  action impossible for this Course is not shown, the rule of Build 272
  Revision 17's follow-up). An existing exercise made with one still opens
  and plays.
- The Round Wizard creates only "to target" presets (its Build prompt,
  "Build the translation of …", was changed in Revision 1 to "Build the
  sentence for …" in a same-language Course),
  which all make sense here.

### Forms, GuideBook and Wizard texts

- The forms of the six translation presets and Match the words: every label
  or helper that says source, target or translation reads word, sentence or
  meaning (the exact list is made when the revision starts).
- GuideBook module page: `_sideLabel('Target', …)` / `_sideLabel('Source',
  …)` read "Word: English" / "Meaning: English" in Words & Expressions and
  "Sentence: English" / "Meaning: English" in Sentences; the field Help
  ("Source: its translation in the learners' language.") has a
  same-language text (EN/IT/ES `guidebookHelp.field.*`); the paste list's
  help says "word = meaning".
- GuideBook module example (default e): `GuidebookModuleSample` and
  `GuidebookPasteList.exampleLines` give an English to English example in a
  same-language Course.
- Course Wizard texts that speak of translations (the GuideBook step, the
  About step's examples) have same-language wording.

### Tests

The names from `nameIn` in each caller; the three twins absent from the
preset list and present in a stored exercise; the GuideBook labels and Help;
the module example; a translation Course unchanged.

### As built (`2.0.75+275004`)

- `ExercisePresetRegistry.nameIn(id, sameLanguage:)`, `offeredIn`,
  `notInSameLanguage`, `directionIn` ("To the word", "To the meaning"),
  `descriptionIn` (the eleven renamed presets described in words and
  meanings) and `directionOfIn` (the four that lose "(to target)" belong
  to both directions there) take the flag, not the Course: the models file
  imports no service, and the callers ask `CourseLanguagePair`. In a
  same-language Course `nameIn` reads a retired ID as its successor when
  that successor is renamed there; `descriptionIn` always reads it as its
  successor. Callers: the
  form's header and its preset list (search, direction filter, cards), the
  Exercise Wizard (its chips, its plan, its guided steps and its planner's
  pools, `ExerciseCreationPlanner.create(sameLanguage:)`), the Story sheet
  (`_chooseStoryPreset(sameLanguage:)`) and the Story Wizard's step cards,
  the Round Wizard's plan, the Round editor's rows
  (`ExerciseLabels.typeLabel(sameLanguage:)`), Search (its type menu and
  its results) and the Audit (`auditExercise(sameLanguage:)`, given by the
  Course's audit, the Previews, the Round Wizard's approval and the
  reading-derived exercises, and `PublishGate.exerciseIssues(sameLanguage:)`
  on Apply): the two "no longer matches" messages, the kind they name
  (`kindLabelIn`) and their hint, and the messages that name Pick, Type or
  Build the translation. The Audit's sorting by type and the learner titles
  (Revision 1) are as they were.
- Field Help (`ExerciseFieldHelpRegistry.forEditorField(sameLanguage:)`):
  the fields of the seven presets and of Read and answer in words and
  meanings, titled as the form labels them; every preset's Instruction or
  context without "translation". Read and answer's form speaks of no source
  or target language.
- New Course's sample exercise in a same-language Course: "Meaning in
  English", "Word in English" (`NewCourseStructure.sampleExercise(
  sameLanguage:)`; the AI's choice, for the owner to confirm).
- The forms' texts are English, as the editor's interface is.
- GuideBook page: `Word` / `Sentence` / `Meaning` labels and the
  messages about a half-filled row, the lists' descriptions, the tooltips,
  the braces line and the title example, the paste dialog's help and
  examples and Paste list's refusals
  (`GuidebookPasteList.read(sameLanguage:, sentences:)`); the field Help
  reads `guidebookHelp.field.<field>.sameLanguage.title|body` (title,
  sentences, words, target, source, context, pasteList; EN/IT/ES); the
  Course Wizard's empty GuideBook line says "At the café". English never
  leaves out its subject, so the example of `{…}` is "I would like {just}
  an espresso".
- Exercise Help adds `exerciseHelp.sameLanguageName` under a preset with a
  same-language name and `exerciseHelp.sameLanguageNotOffered` under a
  twin not offered (EN/IT/ES); its search finds those lines.
- `GuidebookModuleSample.module(sameLanguage:)` ("At the café"; the
  two senses of "the bill" with their pictures),
  `GuidebookPasteList.sameLanguageExampleLines`,
  `CourseWizardSample.guidebook(sameLanguage:)`; the Course Wizard's Word
  Lookup line has a same-language example.
- The owner's answers (decisions 19 to 22): Listen and answer's
  Question Help and the GuideBook picture's Help
  (`guidebookHelp.field.picture.sameLanguage.*`, EN/IT/ES) have
  same-language versions; Choose the answer and Listen and choose name no
  language in their Help. Known and left: two earlier dialogs show a
  preset's raw ID in both kinds of Course (decision 21: a later
  revision); the Pick helpers quote the learner line in English, as the
  translation helpers do; "· To the word" stands beside every "to target"
  preset, as "To target" did.
- **New Course's question** (owner decision of 17 October 2026, after
  Revision 3): `NewCourseDialog.confirmsLanguages` (off in the tests
  written before it), asked after the form accepts its values ("Are you
  sure? After this step the kind of Course and its languages cannot be
  changed, unless you leave the Course Editor with Discard changes
  before its first save and create the Course again."; Cancel
  `new-course-languages-fixed-cancel`, Continue
  `new-course-languages-fixed-confirm`).

## Revision 5: a test Course to import

- **QQL Test: En-En Exercise Lab** (title in the style of the other test
  Courses), `demo_courses/exercise_lab_en_en.json`, written by a generator
  `tools/generate_same_language_lab_275.py` as the Exercise Lab is.
- Custom, the made-up QQL-user Maintainer of the other test Courses
  (`afb065f8-701c-48d2-85f7-c80d44abecb9`), Course version 1, derivative
  works allowed, no Rights Holder (owner decision of 14 October 2026 for the
  test Courses), not bundled (no Course comes with the app),
  `"sameLanguage": true` and `"minimumAppBuild": 275002` (Revision 2:
  an import does not stamp the build, only a save does).
- One Lesson per group of presets, one exercise for each preset offered in a
  same-language Course, a GuideBook module of words and meanings; written by
  AI and not reviewed, as App Info says of the test Courses.
- Tests: the file imports; every exercise plays; every title and line comes
  from the same-language keys; the GuideBook and Word Lookup read meanings.

## Revision 6: several correct translations in the GuideBook

The owner's example: English *I am a teacher* is German *Ich bin Lehrer.* or
*Ich bin Lehrerin.* (and Italian *Sono un insegnante.*, *Sono
insegnante.*);
both are right, and a typed exercise the Round Wizard made should accept
both. The other way round, one sentence may have more than one English
translation.

### Today

- Words & Expressions: rows with the same Source and Context already count
  as one meaning (`_Item.meaningKey`, `_Material.synonymsOf` in
  `lib/services/guidebook_round_generator.dart`): the Round Wizard's Type
  the translation (to target) accepts every Target of that meaning, and its
  choice exercises never offer one of them as a wrong answer. A different
  Context makes two meanings (*teacher (man)*, *teacher (woman)*): the other
  teaching choice, where the exercise removes the ambiguity.
- Sentences have no such rule: Build the translation, Word order and Pick
  the missing word accept only the row's own Target, and Type the
  translation is made from Words only.
- Only one direction: nothing treats rows with the same Target as
  alternatives of the Source.
- The GuideBook accepts only `{…}`: `GuidebookText.targetProblem` refuses
  `[`, `]`, `|` and `<>`, and the field Help says so. The answer engine
  (`AnswerExpressionParser` in `lib/services/answer_engine.dart`) already
  understands all of them in the exercise forms.

### Change

- **Repeated rows, both directions, Words and Sentences** (decision 9): one
  owner of "the alternatives of an entry" (the rows of the Lesson's
  GuideBook, every module, with the same Source and Context; and with the
  same Target and Context for the other direction), replacing
  `synonymsOf`; the Round Wizard, Word Lookup and Review read it.
- **The syntax** (decision 10): Target and Source accept the exercise forms'
  syntax, parsed by `AnswerExpressionParser` (one parser: never a second),
  refused with its messages, at most 128 forms. `GuidebookText` keeps its
  `{…}` display and gains the rest:
  - the learner's GuideBook shows every form in full (decision 17): each
    form a bold line, the translation once after the last
    ("**Ich bin Lehrer.** / **Ich bin Lehrerin.** — I am a teacher.");
    rows that are alternatives of each other (same Source and same
    Context) are drawn as one such entry, in the author's order; rows with
    different Contexts stay separate entries with their Context;
  - Word Lookup indexes every form (today both `{…}` forms);
  - Review shows the first form, and accepts any.
- **What the Round Wizard does with alternatives** (rows and forms alike):
  - Type the translation (to target): every alternative's Target is an
    accepted answer (the engine expands each expression);
  - **new option "Type whole sentences"** (decision 11;
    `generator-type-sentences`, off by default): Type the translation (to
    target) is also made from Sentences, mixed with Build the translation;
    never into the learners' language;
  - Build the translation and Word order: the blocks come from the first
    form; every other form that the same blocks build is also correct
    (*Domani vado a Roma* / *Vado a Roma domani*); extra blocks are never
    words of an alternative;
  - Pick the translation, Pick the missing word, Match: an alternative is
    never a wrong option, and two alternatives are never in one Match.
- **Advice to the author** (decision 12), in plain words wherever it
  matters:
  - beside "Type whole sentences" and on the Round Wizard's plan when it
    holds typed exercises: "Typed answers are checked against the GuideBook:
    write every correct translation there, as another row with the same
    English, or with {…}, [a|b] and <>.";
  - on the GuideBook module page, under Sentences (where today's `{…}` line
    is, `guidebook-module-sentences-braces`);
  - in the Help: the GuideBook field Help (`guidebookHelp.field.*`), Editor
    Help `guidebookEntries` and `roundWizard`, EN/IT/ES, with the exercise
    forms' examples.
- **In a same-language Course** the Source is the Meaning: several meanings
  of one word (synonyms) work the same way.
- **Format**: no new field. A GuideBook that uses `[`, `|` or `<>` would be
  refused or shown wrong by an earlier app, so a new `CourseMinimumBuild`
  rule raises `minimumAppBuild` to this revision's build on a confirmed save
  when one does. `AGENTS.md`'s Course Model rule ("`{…}` marks optional
  words in a target, no other answer syntax") changes with it.
- Hand-made exercises are unchanged: their forms already take several
  answers.

### Tests

The alternatives of an entry in both directions, across modules, with and
without Context; the syntax accepted and refused as in the exercise forms;
the GuideBook display and Word Lookup for every form; the Round Wizard's
Type the translation accepting every alternative, Type whole sentences off
and on, Build and Word order accepting another buildable form, no
alternative as a wrong option or a distractor block; the advice shown; the
minimum build; a translation Course without alternatives generates as
today.

## Not part of this plan

- Card decks with spaced repetition, and the brand tagline (discussed the
  same day, planned separately).
- Changing a Course's kind after it is created (its languages never change).
- Translating anything outside the existing scope (the seven learner
  catalogs; Help EN/IT/ES).
- New presets made for same-language teaching (synonyms, opposites,
  register): the existing presets come first.

## FAQ draft: "Same language or another language: which Course should I make?"

English draft for the owner to correct before Italian and Spanish are
written. The levels (A1–A2, B1) are a rule of thumb; without them the text
says "beginners" and "intermediate and advanced learners".

> **How it works.** You choose once, on the first step of the Course Wizard:
> a Course's languages never change afterwards.
>
> - *Through another language*: learners read instructions and translations
>   in the language they already speak, and exercises go between the two
>   languages.
> - *In the same language*: everything is in the language being learned.
>   Instead of a translation, each word or sentence has a *meaning*: a
>   definition, a synonym or a short explanation. Exercises ask for the word
>   that fits a meaning, or for the meaning of a word. Buttons and
>   instructions are in that language when QQL has them (English, Spanish,
>   Italian, German, Portuguese, Dutch, French), otherwise in English. Either
>   way, learners' XP and streak count for that language.
>
> **Through another language is good for:**
>
> - beginners (A1–A2), who understand every task from the first exercise;
> - a quick, sure grasp of meaning, with Word Lookup giving a translation at
>   a tap;
> - showing where the two languages differ: false friends, word order,
>   grammar.
>
> **Watch out for:**
>
> - learners translating everything in their head instead of thinking in
>   the language;
> - one-to-one translations that mislead, because many words and idioms have
>   no exact match;
> - a Course that only speakers of one language can use.
>
> **In the same language is good for:**
>
> - more contact with the language, since every meaning and instruction is
>   practice too;
> - saying things in other words, a skill learners need whenever a word
>   escapes them;
> - building vocabulary, because a definition brings related words with it;
> - one Course for learners of any mother tongue;
> - learners from B1 up, exam preparation, native speakers improving
>   spelling, grammar and vocabulary, and heritage speakers.
>
> **Watch out for:**
>
> - beginners: a meaning written in the language they're learning can be as
>   hard as the word itself. For them, lean on pictures and sound (Select the
>   image, Name what you see, Listen and pick the image) and keep meanings
>   very simple;
> - meanings take care to write: use words easier than the one being
>   explained;
> - Type the meaning works only for short meanings such as synonyms, because
>   nobody can type a definition word for word.
>
> **Not sure?** For beginners who share one language, choose *Through
> another language*. For learners from many countries, or from intermediate
> level up, choose *In the same language*.

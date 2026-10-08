# Build 266: GuideBook Modules (plan)

These are the owner's decisions of 5 and 6 October 2026. They come from a
read-only discussion of an outside proposal: "make Modules the canonical
authoring structure and make the Round Wizard the orchestration layer".

The plan is confirmed. **Implementation starts only after Build 265 (Word
Lookup, `docs/265_WORD_LOOKUP_PLAN.md`) is finished and pushed, and on the
owner's go.** It was written while Build 265 was being implemented in the
working tree (last commit `072dd74`, the merge of Build 264).

The core rule: **modules define the curriculum, Rounds define the practice,
and the Round Wizard connects the two.**

On-screen names:

- **GuideBook:** the Lesson's whole reference.
- **Module:** one short, coherent topic in it.
- **Sentences** and **Words & Expressions:** a module's two lists.
- **Round:** a practice session.
- **Round Wizard:** turns modules into Rounds.

A module is never called a Round, and nothing implies one Round per module.
Everything new must be made clear to authors through Help (EN/IT/ES),
tooltips, examples, Fill with an example and Clear all (§5).

**Addition of 6 October 2026:** a Words & Expressions entry may have an
optional **picture** (§3, §5, §9). It first came up in the Build 267 Course
Wizard discussion, which planned to store it in Build 266 and leave the rest
to Build 267. Later the same day the owner moved all of it into Build 266:

- Build 266 stores the picture, lets authors choose it and walks it like any
  Course picture.
- It **prefills** the picture from an English word (§5).
- Learners see it in the GuideBook, on Review vocabulary cards and in the
  Word Lookup card (§4, §6).
- The Round Wizard makes **picture exercises** from it (§7).

The Build 267 Course Wizard plan must no longer count these as its own.

**Addition of 7 October 2026 (owner: "Agree"):** an entry's picture may be
marked **Plural**, as an exercise picture can since Build 265 Revision 11
(`plural`, `PluralPicture.wrap`). "i gatti = the cats" then shows stacked
cats, never one cat (§3, §4, §5, §6, §7, §10).

**Decisions of 8 October 2026 (owner, at the start of implementation):**

- The picture prefill (§5) skips Lesson icons and one-letter names, and
  when no name equals the word it tries the name before a bracket.
- The v11 converter puts an example sentence, which has no translation,
  into the module's Overview (§2): Source stays required.
- Revision 0 is split in two (§12): 266000 is the format, the readers and a
  working module page; 266001 the authoring aids. The complete suite runs
  once, at the end of 266001.

## 1. What exists today

### The GuideBook

- A Lesson owns one `Guidebook` (`lib/models/course_models.dart`). It holds:
  - `publicationState`;
  - `content`: Content items told apart by kind and role:
    - explanation/overview;
    - text/goal;
    - vocabulary;
    - explanation/grammar;
    - example/expression;
    - example/example;
  - `insights`: titled text sections.
- The editor (`GuidebookEditorScreen`) has Overview, Usage examples,
  Vocabulary and Grammar fields, plus an Insights page
  (`GuidebookInsightsEditorScreen`).
- **Learners never see Insights.** They are stored, copied and sent in the
  learner projection, but `GuidebookScreen` never reads them.
- `GuidebookScreen` shows "Learning goals" and "Useful expressions", which no
  editor field can write.
- A vocabulary entry is one text line. When a line changes, the editor gives
  it a new ID, so its Review memory is lost.

### The Round Wizard

- `GuidebookRoundGenerator` builds 1–12 Rounds of 1–15 exercises in one run
  from the whole Lesson GuideBook, Draft entries included.
- It reads the overview (for the first Round's Before you start card), the
  vocabulary pairs (at least 3) and the examples and expressions.
- It ignores grammar, goals and Insights.
- Difficulty rises across the run: Foundations, then Practice, then Use in
  context.
- Every generated item gets the **first 6 GuideBook IDs** as its
  `sourceRefs`, not the entries it actually used.

### Build 265 (in progress when this plan was written)

- `GuidebookVocabulary.parse` (`lib/services/guidebook_vocabulary.dart`)
  reads one `target = source` line (separators ` = `, ` → `, ` - `, `:`).
  Review vocabulary, the Round Wizard and Word Lookup share it.
- Word Lookup reads its entries through one adapter,
  `WordLookupSources.forCourse`
  (`lib/services/word_lookup/word_lookup_sources.dart`), which says "Build 266
  (GuideBook modules) changes only this adapter".

### Other readers of the GuideBook

- Review vocabulary (`VocabularyReviewService`): identity by entry ID plus a
  fingerprint.
- The Audit:
  - `LESSON_GUIDEBOOK_EMPTY`;
  - `LESSON_INTRO_MISSING`;
  - `SOURCE_REF_MISSING`;
  - the ID checks.
- Draft status and publication:
  - `CourseDraftStatus`;
  - `ProvisionalPublicationService`;
  - `PublicationService.learnerGuidebook`;
  - `asDraftAuthoringTree`.
- Image handling: `CourseImageUsage` and `CourseImageRemoval`. No file has a
  GuideBook picture.
- Copies:
  - `AuthoringDuplicationService`;
  - `CourseAuthoringTransferService`;
  - `CourseMergeService`.
- Import and integrity:
  - `json_limits.dart`;
  - the v11 → v12 converters;
  - `CourseChecksums`.
- Tools: the generators and `tools/validate_courses.py`.
- Help EN/IT/ES, and about 76 test files.

### Departures from the outside proposal

- Its Phase 4, learner history in the Round Wizard, is dropped. Wizard Rounds
  are written once for every learner. Learner-aware selection belongs to
  Review, as a separate build.
- Its Phase 5, migrating existing GuideBooks, is not needed (§2).

## 2. Format: a clean cut inside Course Model v12

Owner decision: the app is new and no learner uses Courses yet.

- `formatVersion` stays **12**: no new storage folder, backup format or
  converter.
- A GuideBook is **only** `modules[]`. A file whose GuideBook has `content` or
  `insights` is refused with a message such as: "This Course's GuideBooks use
  the earlier shape. Since build 266 a GuideBook is a list of modules:
  regenerate the Course."
- **No old-shape support:**
  - no reading of the old shape;
  - no `minimumAppBuild` stamp;
  - no special checksum handling.
- **Regenerated:**
  - the bundled Courses and the fixtures, with the dummy Publisher fixtures
    re-signed;
  - the v11 originals in `test/fixtures/v11/` stay as converter input.
- **The v11 → v12 converters** (`lib/services/course_model_v12_converter.dart`,
  `tools/convert_course_to_v12.dart`, `tools/qql_course_v12.py`, kept equal by
  their parity test) write **one module titled "Module 1"** per Lesson, and
  list it among the details to review so the author renames it:
  - the v11 overview, then goals, grammar notes and Insights as paragraphs,
    go to the module's Overview;
  - examples and expressions have no translation in v11, and a Sentence
    needs its Source, so each becomes a line of the module's Overview, with
    a detail asking the author to move it to Sentences with its translation
    (owner decision of 8 October 2026; nothing is lost);
  - vocabulary is split by `GuidebookVocabulary.parse` into Words &
    Expressions;
  - a line it cannot split is listed as a detail.
- **Owner's side:**
  - Test Courses stored on the owner's devices with GuideBooks show as
    unreadable in Course Studio. Nothing is deleted.
  - The private Course generators in `D:\QQL_plus\Corsi_Privati` must write
    the new shape.
- **AGENTS.md:** the Course Model v12 invariants gain this GuideBook rule.

## 3. Model

Fields in the owner's order, used everywhere: in JSON, the editor and the
learner screen.

```json
"guidebook": {
  "publicationState": "draft",
  "modules": [
    {
      "id": "module_…",
      "title": "Al bar",
      "sentences": [
        { "id": "…", "target": "Lei è stanca?", "source": "Are you tired?", "context": "formal, to a woman" },
        { "id": "…", "target": "{io} prendo un tè.", "source": "I'll have a tea." }
      ],
      "words": [
        { "id": "…", "target": "il conto", "source": "the bill", "context": "restaurant" },
        { "id": "…", "target": "il conto", "source": "the account", "context": "bank" },
        { "id": "…", "target": "buongiorno", "source": "good morning" },
        { "id": "…", "target": "il caffè", "source": "the coffee", "picture": { "asset": "assets/exercise_images/coffee.webp" } },
        { "id": "…", "target": "i gatti", "source": "the cats", "picture": { "asset": "assets/exercise_images/cat.webp", "plural": true } }
      ],
      "overview": "Short description and explanation."
    }
  ]
}
```

### The GuideBook

- `publicationState` stays at GuideBook level and is omitted when Published.
  The whole GuideBook is Draft or Published; there is no module-level Draft.
- `modules` is an ordered list in teaching order. It may be empty only while
  the Course's Use GuideBook is off; the Audit and the validator check this.

### A module

- **`id`:** stable, unique in the Course, and covered by the ID checks.
  Rounds refer to it.
- **`title`:** the module's own name, never the Lesson title. Required; a
  blank title is a format error.
- **`sentences`:** example sentences in use, each with its translation.
- **`words`** (on screen **Words & Expressions**): single words and fixed
  expressions ("Good morning", "How do you do?", "In the long run").
- **`overview`:** a short description and explanation, may be empty. A topic
  that needs more should be split into shorter modules (§5, §7).

### An entry (both lists)

Each entry is `{id, target, source, context}`, and a Words & Expressions
entry may also have a `picture`.

- **`id`:** stable. It is kept when the entry is edited, because the editor
  works by rows. Unique in the Course, so Review vocabulary memory and
  `sourceRefs` survive edits.
- **`target`:** the text in the language being learned. Required.
- **`source`:** its translation in the learners' language. Required.
- **`context`:** optional, at most 40 characters, in the learners' language.
  It names the sense, subject area, formality, gender or who speaks:
  "informatica" or "scarpe" for *string*, "formal", "said by a woman".
  - Many words change meaning with context: a *string* in information
    technology is not a shoe string.
  - It is never matched, never read aloud and never part of an answer.
- **`picture`** (Words & Expressions only; added 6 October 2026): optional.
  It is the picture the word stands for, stored like an exercise picture:
  - `asset`: a QQL picture (`assets/exercise_images/<name>.webp`, a World
    Flag `assets/world_flags/flags/<id>.svg`) or the Course's own picture
    (`media:<sha256>.<ext>`);
  - `sharedImageSource`: optional, when it was copied from the Shared Image
    Library, as for exercise pictures.
  - `plural` (added 7 October 2026): optional, `true` when the word stands
    for several things ("i gatti = the cats"). Stored only when true and
    only with an `asset`. The picture is then drawn as stacked copies
    wherever it appears, as an exercise picture marked Plural (Build 265
    Revision 11, `PluralPicture.wrap`). Never set by itself, except by the
    singular prefill (§5), and never matched by Word Lookup.
  - Word Lookup never matches it, and it is never part of a typed answer.
  - Learners see it in the GuideBook, on Review vocabulary cards and in the
    Word Lookup card (§4, §6).
  - The Round Wizard uses it for picture exercises (§7).
  - It is walked like any Course picture (§9).
  - It may be prefilled from the English word (§5). The "Suggested" mark is
    never stored.
  - A Sentence with a picture is a format error.

### The understood subject `{…}`

A target may mark words that can be left out, such as an understood subject,
with QQL's optional-word braces: `{io} sono stanco`.

- **Allowed syntax:** only `{…}`, not nested. No other answer syntax
  (`[…|…]`, `<>`) is allowed in GuideBook text.
- **Learners see:** "(io) sono stanco", with *io* in grey.
- **Word Lookup** finds both "sono stanco" and "io sono stanco".
- **Typed answers** in generated exercises accept both, through
  `AnswerExpressionParser`.
- **Word blocks** use the form without the optional words.

### Several meanings

Several meanings are several entries, each with its own context. Word Lookup
already shows every different entry of the same Lesson together.

### Removed

- Grammar, Insights (`GuidebookInsight`, `GuidebookInsightsEditorScreen`),
  goals, expressions as a role, and the compatibility getters (`overview`,
  `goals`, `vocabulary`, `grammar`, `expressions`, `examples`).
- The seven test files that use the legacy `Guidebook(...)` named arguments
  move to a one-module test helper.

### A Round

These fields are optional, stored only when set, and strictly typed:

- `focusModuleId`: the module the Round is about.
- `supportingModuleIds`: the earlier modules whose material it also uses;
  unique, never containing the focus.

Only Open GuideBook reads them (§6). They change no scoring, progression,
order, Review or Duel.

### Strict parsing and limits

- **Format errors** (strict parsing):
  - unknown keys;
  - a blank title, target or source;
  - a context over 40 characters;
  - a malformed or disallowed brace in a target;
  - a `picture` on a Sentence, or a picture whose `asset` is not a QQL
    picture or `media:` reference (the rules of exercise pictures);
  - a `picture.plural` that is not a boolean.
- **Limits** (`json_limits.dart`): at most 100 modules per GuideBook, and
  today's 1,000 entries per GuideBook.

## 4. Readers

### Review vocabulary

- It reads Words & Expressions only, not Sentences.
- Cards show the target and the source with the context, and keep their
  identity by entry ID.
- The context joins the fingerprint, so changing it restarts that entry's
  memory, as changing its text does.
- Key and rules are unchanged.
- A card shows the entry's picture, when it has one, as a small thumbnail,
  drawn as stacked copies when it is marked Plural. The picture and its mark
  do not join the fingerprint, so adding or changing them keeps the entry's
  memory.

### Word Lookup

- It reads Words & Expressions only, never Sentences (a sentence's
  translation could give answers away).
- Only `WordLookupSources` changes: it reads the entry fields, expands `{…}`
  into both forms and passes the context.
- The card shows the context as a small grey label after the source.
- Matching is on the target only. Build 265's other rules are unchanged:
  expressions first, the current Lesson first, nothing when nothing is found.
- The card shows the entry's picture, when it has one, as a small thumbnail
  beside the target, stacked when it is marked Plural. `WordLookupSources`
  passes the picture and its mark, and Build 265's card
  (`lib/widgets/word_lookup_view.dart`) gains the slot. A picture never
  changes which entries are found.

### Line parsing

`GuidebookVocabulary.parse` becomes the reader of **Paste list** lines
(`target = source [context]`, §5) and of the v11 converter's vocabulary. It
is no longer used to read stored entries.

## 5. Authoring

### The GuideBook page (`GuidebookEditorScreen`)

- A reorderable list of module cards (`guidebook-modules-list`), each with
  its title and counts ("4 sentences · 12 words"). A tooltip on the counts
  explains them.
- Buttons and actions:
  - Add module (`guidebook-add-module`);
  - drag to reorder;
  - Remove, which asks first (`guidebook-module-remove-confirm`) and says how
    many Rounds focus on the module ("2 Rounds focus on this module; they keep
    their exercises and lose the link");
  - Save Guidebook and Save Guidebook as draft, unchanged (keys
    `guidebook-save`, `guidebook-save-draft`, `guidebook-save-appbar`).
- **Empty state:** it explains what a module is, with an example ("Al bar:
  ordering and paying"), and points to Add module and Fill with an example.
- Help in the app bar opens the GuideBook question in Editor Help.
- It fits a 360-pixel window. The GuideBook's internal ID is shown, as today.

### The module page (fields in the owner's order)

- **Title** (`guidebook-module-title`): required. Example: "Al bar".
- **Sentences** (`guidebook-module-sentences`): one row per entry
  (`…-sentence-<i>`).
  - Each row has **Target**, **Source** and **Context** boxes, a delete
    button and drag to reorder.
  - Add sentence adds a row.
  - Example in the helper: `Lei è stanca? = Are you tired? [formal, to a
    woman]`.
- **Words & Expressions** (`guidebook-module-words`): the same rows.
  - Examples in the helper: `il conto = the bill [restaurant]`,
    `il conto = the account [bank]`, `buongiorno = good morning`, and the
    *string* example (computing vs shoes) in the Help.
  - **Picture** (added 6 October 2026), Words & Expressions rows only:
    - a small picture button on each row (`…-word-<i>-picture`) opens the
      same choice as an exercise picture: the image library, the Course's own
      pictures or a file (`ExerciseImageField`, compact);
    - the row then shows a thumbnail and a remove control;
    - tooltip: "Picture (optional): what this word looks like. Learners see
      it in the GuideBook, in Review and in Word Lookup; the Round Wizard uses
      it for picture exercises.";
    - a **Plural** chip beside a chosen picture (`…-word-<i>-picture-plural`,
      added 7 October 2026), off by default, as on an exercise picture:
      tooltip "Plural: the word means several things (i gatti, the cats);
      learners see stacked copies of the picture."; removing the picture
      removes the mark, and the thumbnail shows the plural look;
    - a picture of unknown origin brings the usual credit reminder
      (`imageCreditReminder`);
    - it fits a 360-pixel window: the picture slot sits at the left of the
      row.
  - **Picture prefill** (owner decisions of 6 October 2026), done by a pure
    Dart matcher (`GuidebookPictureMatch`) over the QQL image catalog
    (`ExerciseImageMetadataService`):
    - **Which Courses:** a Course whose **target** language is English
      (`en…`) matches the entry's Target. A Course whose **source** language
      (the learners') is English matches its Source, so `mela = apple` finds
      Apple.
    - **What matches:** the picture's name equals the word, ignoring capitals
      and a leading *a*, *an* or *the* ("an apple" finds Apple).
      - **The singular** (added 7 October 2026): when no picture's name
        equals the word, its singular is tried with the library's own rule
        (`imageTagKey`: "cats" → "cat", "boxes" → "box"). A match fills the
        picture **marked Plural**, with the mark **Suggested, plural**
        (tooltip: "Chosen because its name matches the word's singular, and
        marked Plural. Change or remove it."). An exact name always comes
        first, so "glasses" finds Glasses, not a plural Glass. Several
        singular matches show "N matching pictures", as below.
      - **The name before a bracket** (added 8 October 2026): when no
        picture's name equals the word (or its singular), the part of a
        name before its bracket is compared: "baker" offers Baker (man) and
        Baker (woman) as "2 matching pictures", "Africa" fills Africa (map).
        Exact names still come first, so "father" finds the Father scene,
        not Father (family tree). 151 names exist only with a bracket.
      - Context never takes part.
      - Character pictures (the `characters` group: letters, digits,
        symbols) never match, so the article *a* does not find the letter A.
      - Never matched either (8 October 2026): **Lesson icons** (five repeat
        ordinary names: Train, School, Hotel, Family, Shopping) and pictures
        whose name is **one letter** (the Roman numerals I, V, X and the
        units g, l, m: "io = I" must not suggest the numeral one).
    - **Which library:** only the **QQL catalog**, whose names are English.
      Device library pictures never prefill.
    - **One picture or none:**
      - When exactly one picture matches, it fills the row with a
        **Suggested** mark (`…-word-<i>-picture-suggested`). The tooltip
        says: "Chosen because its name matches the word. Change or remove
        it."
      - When several match (243 catalog names belong to more than one
        picture: *orange*, *train*, *nail*, *present*…), nothing is filled
        in. The row shows "N matching pictures"
        (`…-word-<i>-picture-matches`), which opens the library already
        searched for the word.
      - When none matches, nothing happens.
    - **When it runs:**
      - Only when a word is typed (on leaving the box), added by Paste list
        or added by Fill with an example, and only while the row has no
        picture.
      - Never when a GuideBook is reopened, and never over a picture the
        author chose.
      - A picture the author removes stays removed until that row's word
        changes.
      - The Suggested mark lasts for the editing session only; it disappears
        when the author touches the picture.
- **Overview** (`guidebook-module-overview`):
  - A character counter.
  - From **500 characters**, a hint that never blocks saving: "Long overview.
    Consider splitting this topic into shorter modules." The helper says
    "Two or three sentences. A longer topic is better split into shorter
    modules."
- **Paste list** (`guidebook-module-paste-sentences`,
  `guidebook-module-paste-words`):
  - It reads one entry per line, `target = source [context]`, with example
    lines in the dialog.
  - It appends rows with fresh IDs and names every line it cannot read.
- **Fill with an example** (`guidebook-module-fill-example`):
  - It fills every field with a built-in sample module (`GuidebookModuleSample`,
    pure Dart, like `CanonicalExerciseSamples`). It asks first when the form
    holds something (`guidebook-module-fill-example-confirm`), and every entry
    gets a fresh ID.
  - The sample shows every feature: a short Overview, Sentences with a
    context, one word with two senses (*il conto*), a fixed expression, an
    understood subject `{io}`, a word with a QQL picture (*il caffè*,
    `assets/exercise_images/coffee.webp`) and a plural word with its picture
    marked Plural (*i gatti*, `assets/exercise_images/cat.webp`).
  - Like the exercise forms' examples, it is in Italian and English whatever
    the Course's languages.
- **Clear all** (`guidebook-module-clear-all`): empties the module, pictures
  included, asking first (`guidebook-module-clear-all-confirm`) unless it is
  already empty.
- **Tooltips:**
  - on the Target, Source and Context headings (for example, "Context: a
    short note in the learners' language: the sense, the subject area, formal
    or informal, who is speaking");
  - on `{…}` ("Words that may be left out, like an understood subject: shown
    in grey, accepted with or without");
  - on Paste list;
  - on the counter.
- **Field Help:** every field has the Help control the exercise forms have,
  with EN/IT/ES text.
- **Validation:**
  - Save refuses a row with a target but no source (or the reverse) and
    points to it.
  - An empty row is dropped.
  - A context over 40 characters is refused at the box.
- **Internal IDs:** the module's (`EditorInternalIdText`, "Module") and each
  row's when internal IDs are shown.
- **Read-only mode:** opens `GuidebookScreen`, as today.

### After the GuideBook is saved

- Rounds that pointed at a removed module lose their `focusModuleId` or
  `supportingModuleIds` entry.
- `sourceRefs` to removed entries are pruned (the existing pruning,
  extended).

### Other places

- **Lesson editor's GuideBook card** (`lesson-guidebook-navigation`): the
  subtitle names the number of modules.
- **Round editor:** a **Focus module** menu (`round-focus-module`, None plus
  the modules of the Round's Lesson, with a tooltip), for hand-made Rounds
  too, shown while Use GuideBook is on. A read-only line names the supporting
  modules ("Also reviews: Saluti"). Changing the focus keeps the supporting
  list, minus the new focus.
- **Move or Copy a Round to another Lesson:** clears its focus and supporting
  modules, because modules belong to their own Lesson.

## 6. What learners see

- **`GuidebookScreen`:** the Lesson title, then each module in order
  (`guidebook-module-<id>`): its **title**, **Sentences**, **Words &
  Expressions** and **Overview**.
  - Each entry reads *target — source* with the context as a small grey label
    after it. Optional words appear as "(io)" in grey.
  - The headings stay English as today; the Draft and empty messages and the
    footer note are as today.
  - A word with a picture shows it as a small thumbnail beside the entry
    (owner decision of 6 October 2026, which settles the question left open
    earlier that day), as stacked copies when it is marked Plural. Review
    vocabulary cards and the Word Lookup card show it too (§4).
- **Open GuideBook** on a Before you start card (learner and Preview) opens
  the GuideBook scrolled to the Round's focus module when it has one that
  exists. Otherwise it opens at the top. The learner path's book icon opens at
  the top.
- **No change** to scoring, XP, progression, Review order, Laurels or the
  Duel. No new persisted learner key, so `AppResetService`, `InventoryService`
  and `docs/239_RESET_STORAGE_INVENTORY.md` are unchanged.

## 7. Round Wizard

### Configure

- **Focus module** (`generator-focus-module`, with a tooltip: "The module
  these Rounds practise. About a third of each Round reviews earlier
  modules.") offers each module, plus **All modules, in order**.
- A module with fewer than 3 Words & Expressions entries is greyed out with
  its reason. With All modules, modules below 3 entries are skipped, and the
  plan names them.
- Entry pictures add picture exercises; see Pictures below.

### Counts

| Mode | Count field | Range | Default |
|---|---|---|---|
| One module | Number of Rounds | 1–12 | 6 |
| All modules | Rounds per module | 1–12 | 3 |

- 3 is the smallest count that gives each module all three phases.
- At most **24 Rounds per run**. Over that, the field explains it, for
  example "At most 24 Rounds per run. With 5 modules, choose up to 4 Rounds
  per module."
- Exercises per Round stay 1–15, default 8.

### Difficulty curve

- One module: the curve runs across the run, as today.
- All modules: **each module gets its own curve** (Foundations, then
  Practice, then Use in context), in module order. That way no module's words
  first appear in production exercises.

### Plan

- Each planned Round shows its focus module and can change it
  (`generator-round-focus-<i>`), beside its Round type.
- It lists the entries it will use (`generator-round-words-<i>`), for example
  "Focus: Al bar — il conto, buongiorno · Review: Saluti — ciao".

### Mix

The mix is seeded and reproducible, and not shown to authors.

- **Review slots:** in a Round of M exercises, round(0.3 × M) slots use
  supporting material when the focus module has earlier modules (8 exercises:
  2). A first module gets none.
- **Supporting material:** only the **modules before the focus module in the
  same Lesson**, nearest first. Earlier Lessons are not used.
- **Where the slots go:** spread evenly, never the first exercise.
- **Preset pool:** computed from the focus module's material.
- **Fallback:** a supporting slot whose preset needs a sentence its module
  lacks stays a focus slot. Match exercises in a supporting slot take their
  three entries from the earlier modules together.

### Context and synonyms

- **The context is always shown** with the learners'-language text: the
  prompt of Pick, Type and Build the translation, the Match side, and the
  flashcard meaning. Each exercise then has one right answer.
- **Wrong answers:**
  - An entry that differs from the answer only by its context makes a good
    wrong answer ("you eat [formal]" with the choices *mangia* and *mangi*).
  - Two entries with the same target are never offered against each other,
    and never share a Match.
  - Entries with the same source and the same context are synonyms: a typed
    answer accepts every one of their targets, and they are never offered
    against each other.
  - Wrong answers come from the slot's own module first, then from the
    Lesson's other modules.
- **`{…}`:** typed answers accept a target with or without its optional
  words; blocks and displayed text use the form without them.

### Sentences

Build the translation and Word order work on whole sentences, with the
sentence's source (and context) as the clue. Pick the missing word uses
sentences as today. No new exercise types.

### Pictures

Owner decision of 6 October 2026: this belongs to the Round Wizard's
revision (delivered as Revision 3, §12), moved here from the Build 267
plan.

- **When:** a module with **at least three** Words & Expressions entries that
  have pictures adds three picture presets to its pool:
  - **Select the image** (`icon_choice`): the word, choose its picture.
  - **Match pictures to words** (`picture_word_match`).
  - **Picture flashcard** (`picture_flashcard`).
  The first two join the Foundations and Practice phases; Picture flashcard
  joins FlashCard Rounds.
- **Wrong answers:**
  - Picture choices come from other entries with pictures.
  - Two entries with the same picture are never offered together or share a
    Match; the same picture with and without Plural counts as the same
    picture (*il gatto* and *i gatti* are never choices of one exercise).
- **How pictures are stored in the exercise:** as exercise pictures always
  are. A QQL picture is an `assets/…` icon key. A Course picture
  (`media:…`) is an image element, already in the Course's folder.
- **Plural carries over** (7 October 2026): an entry picture marked Plural
  gives its exercise picture the `plural` mark (on the image element or the
  `icon` element), so a plural word is never practised with one object.
- **Supporting slots** may use earlier modules' pictured entries under the
  same three-picture rule.
- **Round types:** `RoundTypeCompatibility` still decides which Round types
  accept them.

### Generated Rounds

- **Titles:** "<phase>: <module title>".
- **Before you start card:** the first Round of a run, or with All modules
  the first Round of each module, gets a Draft card. The card holds a **copy**
  of the focus module's Overview (or "Review the "<title>" module of the
  GuideBook before you start.") and has Open GuideBook on.
  - It stays editable, and later GuideBook edits do not change it.
  - It has no `sourceRefs`. FlashCard and Test Rounds get no card, as today.
- **Each Round records** `focusModuleId` and, as `supportingModuleIds`, the
  earlier modules its supporting slots actually used, in module order.
- **Each exercise's `sourceRefs`** are the IDs of the entries that supplied
  its question and answer, not its wrong answers. This replaces the first-6
  stamp.
- **The Round Wizard's own Help dialog** ("GuideBook Round Generator")
  describes focus, All modules, review, context and the limits.

## 8. Audit

- **`LESSON_GUIDEBOOK_EMPTY`** (Warning): Use GuideBook is on and no module
  has an entry (or there is no module).
- **New `GUIDEBOOK_MODULE_EMPTY`** (Warning): a module with no sentence and no
  Words & Expressions entry. Location `Lesson N · Title · Guidebook · Module m`.
- **New `GUIDEBOOK_MODULE_OVERVIEW_LONG`** (Info): an Overview of 500
  characters or more; the fix says to split the topic into shorter modules.
- **New `ROUND_FOCUS_MODULE_MISSING`** (Warning): a Round's focus or
  supporting module is not a module of its own Lesson's GuideBook.
- **ID checks** cover module IDs and entry IDs. `SOURCE_REF_MISSING` resolves
  against entry IDs.
- **`AuthoringHierarchyStatus`** matches GuideBook locations by text: check
  that module locations still count as GuideBook concerns.
- **The registry grows by three rules.** Update the pinned count and the
  Audit Codes page.

## 9. Draft status, publication, copies, images

- **`CourseDraftStatus.lessonGuidebookHasDraft`:** Use GuideBook is on and the
  GuideBook is Draft. Entries have no state of their own.
- **`ProvisionalPublicationService.guidebookReady`:** Use GuideBook is off, or
  the GuideBook is Published and not empty.
- **`PublicationService.learnerGuidebook`:** a Draft GuideBook becomes empty
  modules; a Published one is delivered whole. `asDraftAuthoringTree` sets the
  GuideBook to Draft.
- **Duplicate Lesson and Fork** (`AuthoringDuplicationService`): new module
  and entry IDs, remapped in the Lesson's Rounds (focus, supporting,
  `sourceRefs`).
- **Copies of a Round:** Copy within the same Lesson keeps its references.
  Move or Copy to another Lesson clears focus and supporting.
- **Transfer and Merge:** `CourseAuthoringTransferService` includes module and
  entry IDs in its identity checks. Merge carries modules with their Lessons.
- **Pictures** (changed 6 October 2026): the only GuideBook pictures are
  the entry pictures of Words & Expressions (§3). `CourseImageUsage` walks
  them instead of the old GuideBook content, so everything built on it treats
  them as Course pictures:
  - IN USE in the Image Library;
  - the media kept by a confirmed save;
  - package export and import;
  - Fork, Copy as New Course and Merge;
  - the `MEDIA_ATTRIBUTION_MISSING` count.
  `CourseImageRemoval` clears an entry's picture. Help says a picture used
  only by a GuideBook word shows IN USE.

## 10. Help (EN/IT/ES)

- **Rewritten:**
  - `editorHelp.qa.guidebook`: modules, the field order, what each list
    holds, short Overviews as the reason to split;
  - `editorHelp.qa.roundWizard`: focus module, All modules, review from
    earlier modules, context, limits;
  - `editorHelp.qa.beforeYouStart`: the card copies the module's Overview;
  - other Editor Help mentions: `editorHelp.qa.structure`,
    `editorHelp.qa.provisionalDraft`, `editorHelp.auditSeverityAndCodes`;
  - App Info: `appInfo.guidebooks`;
  - technical reference: `technical.courseModel.hierarchy`,
    `technical.courseModel.content`, `technical.courseModel.guidebook`,
    `technical.jsonStructure.guidebook` and
    `technical.jsonStructure.lessonAndRound` (remove the Insights sentence;
    add the Round fields and the entry fields).
- **New Editor Help questions:**
  - "How do I write GuideBook entries?": Target, Source, Context with the
    *string* example (computing vs shoes), several meanings as several
    entries, `{…}`, a word's optional picture and its prefill in Courses to
    or from English (one match fills it, several offer a choice), the Plural
    mark and the singular prefill that sets it ("cats" finds Cat, marked
    Plural), Paste list, Fill with an example and Clear all;
  - "How long should a module be?"
- **Field Help** for every module field.
- **Codes:** the three new Audit codes in `audit_code_registry.dart`.
- **Build 265's Help:** Word Lookup Help and Review Help mention the context
  and the picture.
- **Round Wizard Help:** `editorHelp.qa.roundWizard` and the Round Wizard's
  own dialog name the picture exercises and their three-picture rule.

## 11. Content

**Status (8 October 2026):** only the part that the format change required
was done, in Revision 0. The demo content planned here (English from Italian
in modules, the Lab's two-module Lesson, the Edge Case module cases) was not
done in Build 266 (owner decision of 8 October 2026). The bundled Courses
and fixtures have one module per Lesson.

Done in Revision 0:

- **Every generator, the validator and every fixture write modules**, one
  module per Lesson: the Lab (`MODULE_TITLES`, Build 265's entries), the
  Edge Case demo and fixture, English from Italian ("Le prime parole"), the
  Laboratory-of-the-future fixture; the Korean fixture and the Italian demo
  package rewritten; the dummy Publisher fixtures rewritten and re-signed.
- **`tools/qql_course_v12.py`** has the module and entry helpers
  (`guidebook_entry`, `guidebook_module`, `guidebook`, `vocabulary_pair`,
  `target_problem`) and `convert_guidebook_v11`.
- **`tools/validate_courses.py`** checks:
  - the GuideBook, module and entry keys;
  - non-empty modules while Use GuideBook is on;
  - IDs, required texts, context length and braces;
  - entry pictures: Words & Expressions only, and a QQL picture's file
    exists;
  - `sourceRefs`;
  - that Round focus and supporting IDs exist in their Lesson.

Planned and not done (no revision holds it now):

- **QQL Demo: English from Italian**
  (`tools/generate_english_from_italian_260.py`): its GuideBook split into
  modules that match its topics (for example Saluti, Al bar and Alla
  stazione); the 4 grammar notes as short module Overviews; Sentences with
  translations and Contexts where a word or sentence needs one; word
  pictures by the perfect-match rule (its target is English); its Rounds'
  `focusModuleId`.
- **QQL Demo: Italian Exercise Lab** (`tools/generate_exercise_laboratory_254.py`):
  one Lesson with two modules, so the review mix can be seen; a word with
  two senses and an understood subject `{…}`; at least three words with QQL
  pictures in one module, so the picture exercises can be seen.
- **Edge Case** (`tools/generate_edge_case_demo_254.py`, the demo and the
  fixture): two modules; an empty module and a long Overview (the Warning
  and the Info, on purpose); a Draft GuideBook; `sourceRefs` to entries; a
  Round whose focus is missing (the Warning, on purpose).

## 12. Revisions (one local commit each)

Every revision bumps the version (`2.0.66+266000` …) and, when the release
day changes, the Beta expiry, and updates CHANGELOG, the AGENTS.md release
boundary, `docs/266_CHANGE_SUMMARY.md`, `docs/266_HANDOFF.md` and
`docs/266_VALIDATION.md`.

How the revisions came to be (owner decisions of 8 October 2026):

- The plan's Revision 0 was split in two: 266000 (the core) and 266001 (the
  authoring aids). The complete suite first ran at the end of 266001;
  266000 was checked with the analyzer and focused tests.
- The owner inserted a resilience revision (266002) after the reset buttons
  of Advanced (Admin) did nothing, so the Round Wizard became Revision 3.
- The content (planned as the last revision) was not done: Revision 4 does
  not exist. Revision 3 is Build 266's last revision.

As delivered, all committed locally on `claude/266-guidebook-modules` (from
main `5cfb227`), not pushed:

- **Revision 0 (2.0.66+266000, `50512d2`): modules.**
  - The model and its JSON (entries with context, `{…}`, the optional word
    picture), the refusal of the old shape, the converters' new output and
    the Round fields (stored, edited, pruned, remapped).
  - Entry pictures walked as Course pictures (§9) and chosen on the module
    page (§5), with Plural. The thumbnail in the learner GuideBook, on
    Review vocabulary cards and in the Word Lookup card (§4, §6).
  - Every reader in §1 and §4, including Review vocabulary and Word Lookup
    (its engine's entries gain the context and the picture).
  - The GuideBook page and a working module page with rows (§5), Save's row
    validation and the context limit.
  - The learner GuideBook screen, the Audit rules and the Round editor's
    Focus module menu; Open GuideBook at the focus module.
  - Generators, validator and fixtures (one module per Lesson) and the
    bundled Courses regenerated.
  - Help for the GuideBook model (the rewritten keys of §10).
- **Revision 1 (2.0.66+266001, `f6891bf`): authoring aids; the reset
  buttons fixed.**
  - The prefill from the English word with its Suggested mark and "N
    matching pictures" (§5); the library opened from a word is searched for
    its English side, only in Courses to or from English.
  - Paste list, Fill with an example, Clear all, the Overview counter and
    hint, tooltips, examples in helpers and field Help (EN/IT/ES).
  - The two new Editor Help questions (§10).
  - Fix: a stored Course in the earlier GuideBook shape blocked every reset
    button (and the reset that removes it); the reset service skips such a
    Course and a reset that cannot start says why.
- **Revision 2 (2.0.66+266002, `16bc9ff`): resilience.**
  - One reader for stored Courses this version cannot open
    (`StoredCourseReader`): never stops a feature, named by its file,
    logged; removable in Course Studio and replaceable by import (its
    Maintainer, Team or an admin); the Publisher update replaces such a
    source; learner deletion and the resets read its Maintainer.
  - No silent buttons (`runReported`); every unhandled error also in the
    Diagnostic Log; Save&Open for both logs.
  - The Inventory's Delete, Forget and Open folder (admin PIN, the existing
    rules); edge-case tests over seven kinds of bad stored files.
- **Revision 3 (2.0.66+266003, `3801369`): the Round Wizard over modules.**
  - Focus module and All modules, Rounds per module and the per-module
    curve, at most 24 Rounds per run.
  - The review of earlier modules (about a third, never first), the context
    and synonym rules, and sentences in Build the translation and Word
    order.
  - Real `sourceRefs`, the recorded focus and supporting modules, and the
    Before you start cards per module.
  - Picture exercises from entry pictures (Select the image, Match pictures
    to words, Picture flashcard; at least three pictured entries), Plural
    carried over.
  - The plan preview with each Round's focus and words, tooltips and Help.

## 13. Out of scope

- Learner history in the Wizard (the outside proposal's Phase 4).
- Module-level Draft.
- Module priority in Word Lookup.
- Review from earlier Lessons.
- Review cards for Sentences.
- A fixed list of context tags.
- Showing the focus module on the learner path.
- Course Editor Search over GuideBooks.
- Inflected forms.
- The unused seen-GuideBook APIs in `ProgressService`.
- Pictures on Sentences.
- Prefill from device library pictures or from words in languages other than
  English.
- Picture exercises beyond the three presets of §7 (What is in the picture,
  Name what you see, Type what you see).

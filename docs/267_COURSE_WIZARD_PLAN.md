# Build 267: the Course Wizard (plan)

These are the owner's decisions of 6 October 2026, from a read-only
discussion. It began as a request for a new Italian demo Course, built from
GuideBook modules and led by pictures. The owner then asked whether QQL
should have a Course creation Wizard first, and chose to build it as Build
267. The demo is built with the Wizard afterwards (§9).

**Implementation starts only after Build 266 (GuideBook Modules,
`docs/266_GUIDEBOOK_MODULES_PLAN.md`) is finished, and on the owner's go.**
Build 266 also gains, by the same discussion, an optional picture on each
Words & Expressions entry (its §3, §5, §9). The Wizard builds on that.

The core rule: **the Wizard guides an author through creating a whole
Course, step by step. It can stop at any step and continue later, and every
screen says, in simple words with examples, what to do and why.**

QQL is offline and has no AI: the Wizard never writes content. The author
writes the modules; the Wizard arranges everything around them and turns
them into Rounds through the Round Wizard.

## After Build 266 (8 October 2026)

Build 266 delivered parts of this plan before Build 267 started:

- **§5, the picture prefill:** done in 266 Revision 1 with the owner's later
  rules (266 plan §5): the picture's name equals the word, then its
  singular (marked Plural), then the name before a bracket; never a tag;
  only on typing, Paste list or Fill, never on reopening. Not done: a
  **Suggest pictures** button for rows that already exist (asked on
  8 October 2026).
- **§6, picture exercises:** 266 Revision 3 added Select the image, Match
  pictures to words and Picture flashcard. Not done: the five other presets
  of the table below and **Prefer picture exercises** (asked on 8 October
  2026).
- **§10:** learners see a word's picture in the GuideBook, on Review cards
  and in Word Lookup (266 Revision 0).

Revision 0 (2.0.67+267000) shows only the steps that exist: steps 1–5, with
**Finish** on step 5 (it saves, ends the Wizard and opens the Course
Editor). Each later revision adds its step to the bar.

## 1. What exists today

- **New Course** (`CourseProjectsScreen`, "Create new course") is one long
  dialog:
  - title and languages (`LanguageField`), Maintainer;
  - contributors and roles, license, derivative works, Rights Holders;
  - language variant, starting and target level, description, Buy a Coffee;
  - Number of Lessons (1–100, default 3) and Rounds per Lesson (1–20,
    default 1), each Round with one sample exercise;
  - the cover (`CourseCoverField`).
- **Course Info** adds study hours, minimum age, keywords and publisher
  contact.
- **Lesson Options** (`course-lesson-options`) holds:
  - Lesson and Round label and numbering;
  - Use GuideBook (`course-use-guidebook`), Word Lookup, Create Duels;
  - Default Timed limits;
  - Picture answers.
- **Building a Course** takes five separate tools: the GuideBook editor
  (modules from Build 266), the Round Wizard (one Lesson at a time),
  Exercise Wizard (one Round at a time), New Story, and the Course Editor
  forms.
- **What nothing does yet:**
  - plan the Course as a whole;
  - say what must be done now and what can wait;
  - check that every Lesson has the 25 questions a Duel needs;
  - lead the author to a published Course.
- **The Round Wizard and pictures:** it makes no picture exercises
  (`icons: const []`). Its presets are Choose the answer, Pick the missing
  word, Listen and choose, the Match presets, Build and Type the translation,
  Word order and Flashcard.
- **A Course with no Lessons is valid** while it is being authored (the
  Audit's `courseLessonsEmpty` says so), so the Wizard can save a Course
  right after its first step.

## 2. Starting

- **New Course** opens the Wizard's first screen, **Basics**: title,
  languages and language variant. Every Course needs these.
- Then the author chooses:
  - **Continue with the Course Wizard** (`course-wizard-continue`): QQL
    creates and saves the Course (Draft, no Lessons) and goes on to step 2.
  - **Create it myself** (`course-wizard-manual`): today's New Course dialog,
    unchanged, with title, languages and variant already filled in. It still
    asks Number of Lessons and Rounds per Lesson with their sample exercises,
    then opens the Course Editor as today.
- The first screen explains both ways in two short paragraphs. For example:
  "The Course Wizard takes you through every step and explains it. You can
  stop and continue later. Creating it yourself opens the Course Editor at
  once: quicker if you know QQL."
- Cancel on the first screen creates nothing (and removes the cover media
  folder, as New Course does today).

## 3. Steps (Wizard path)

A step bar shows the eight steps (`course-wizard-step-<n>`), done ones
ticked. Back and Next move between them; a step that is not done yet cannot
be skipped when a later step needs it (Lessons before GuideBook, GuideBook
before Rounds).

1. **Basics:** title, languages, variant (§2).
2. **About the Course:** description, starting and target level, cover,
   study hours, minimum age, keywords.
3. **Credits and rights:** contributors and roles, license, derivative works,
   Rights Holders, Buy a Coffee, publisher contact. Each explains why it
   matters, for example: "Allowing derivative works lets other people Fork
   your Course: they get their own copy to change, with your name kept as
   the original creator."
4. **Course options:** the Lesson Options settings, each with an example of
   what learners see.
   - Use GuideBook is **on and not offered** here. The line says why: "The
     Course Wizard builds your Rounds from the GuideBook, so it stays on. You
     can turn it off later in Lesson Options, but it is recommended."
   - Create Duels, Word Lookup, Lesson and Round labels and numbering,
     Picture answers, Default Timed limits.
5. **Lessons:** the Lessons in order, each with its title, icon and section
   name. Explanation: "A Lesson is one topic, like 'At the market'. Learners
   open Lessons in order: the next one opens when they finish this one or
   win its Duel. A Duel needs 25 questions, so a Lesson usually has about
   six Rounds."
6. **GuideBook, Lesson by Lesson:** the Lesson's modules, opened on Build
   266's module page (Sentences, Words & Expressions with pictures,
   Overview, Paste list).
   - A Lesson is done when it has at least one module with 3 or more Words &
     Expressions entries (the Round Wizard's minimum). The author approves it
     with **This Lesson's GuideBook is ready**, which saves the GuideBook as
     Published.
   - The English picture prefill (§5) works here.
7. **Rounds, Lesson by Lesson:** the Round Wizard with All modules, its plan
   shown before anything is created (§6). **Create these Rounds** makes them
   (Draft, as the Round Wizard does).
8. **Check and publish** (§7).

## 4. On every screen

### Explanations (owner: English only)

- An **explanation panel** at the top (`course-wizard-explanation`), in
  simple English with an example. It says:
  - what the step does;
  - why it matters;
  - what learners will see;
  - **what is needed now and what can wait**, and where to change it later.
- Fields that can wait carry a small **Can wait** label with a tooltip
  naming the place, for example "Can wait: Course Info in the Course
  Editor".
  - Needed now:
    - title and languages (step 1);
    - **Lesson titles** (step 5): a Lesson title is required, never left for
      later;
    - at least one module per Lesson (step 6).
  - Everything else can wait: description, levels, cover, credits, license
    (New Course's defaults apply until changed: All rights reserved,
    derivative works forbidden), options, icons, section names.
- Helper texts carry examples ("At the market", "il conto = the bill
  [restaurant]"); headings have tooltips.
- The panels are English only. Editor Help gains a question, "How does the
  Course Wizard work?", in EN/IT/ES like every Help text.

### Fill with an example and Clear all

- **Fill with an example** (`course-wizard-fill-example`) on steps 1–7. It
  fills the step from one built-in sample Course (`CourseWizardSample`, pure
  Dart, like `CanonicalExerciseSamples`), so filling every step gives one
  coherent Course:
  - step 1: a title and English → Italian;
  - step 2: a description, levels, keywords;
  - step 3: a common license, derivative works allowed, the active profile
    as Rights Holder;
  - step 4: the recommended options;
  - step 5: three Lessons with titles and icons;
  - step 6: the sample Lesson's modules, in Italian and English whatever the
    Course's languages, as Build 266's module sample;
  - step 7: the recommended Round Wizard settings.
  - Every sample word with a picture uses a QQL picture that exists (a test
    checks it).
  - It asks first when the step already holds something
    (`course-wizard-fill-example-confirm`).
- **Clear all** (`course-wizard-clear-all`) clears only the current step,
  asking first (`course-wizard-clear-all-confirm`) unless it is empty.
  - When later steps were built on it, the question says what goes too, for
    example: "Lesson 2 has 6 Rounds. Clearing its modules does not remove
    them, but they lose their focus module." Or: "Removing Lesson 3 removes
    its GuideBook and 6 Rounds."
  - Version History can bring back any earlier save (§4, Saving).
- Step 8 has neither: nothing to fill.

### Saving: Save for now and resume

- **Every save is an ordinary confirmed save** (owner decision): the same
  path as the Course Editor's confirmation (`confirmCourseTransaction`), so
  the Course version goes up by 1, a backup is made and Version History can
  go back to any step. The version notes name the step ("Course Wizard:
  Lessons"). There is no second persistence path. A new Course may reach
  version 10 or so before its first Publish; that is accepted.
- **When it saves:**
  - when the author leaves step 1 for the Wizard (the Course is created);
  - on **Next** after a step that changed the Course;
  - on **Save for now** (`course-wizard-save-for-now`), on every step: it
    saves and closes the Wizard. A SnackBar says where to continue: "Saved.
    Continue it from the Course's ⋮ menu in Course Studio."
- **Unfinished rows:** a GuideBook row with a target and no source (or the
  reverse) cannot be stored. Save for now names those rows and offers "Save
  without them" or "Go back".
- **What it remembers:** one device-level key per Course,
  `qql_course_wizard_<URI-encoded Course ID>`, like the publisher memory
  (`PublisherExportMemory`). It holds JSON: `step`, `lessonId` (steps 6
  and 7), `savedAtUtc`. Never in the Course file.
  - Removed when the Wizard finishes, when the author chooses **Continue by
    hand**, when the Course is deleted, and by the custom-course reset and
    Wipe everything.
  - Listed in Inventory ("Paused Course Wizards").
  - Added to `AppResetService`, `InventoryService` and
    `docs/239_RESET_STORAGE_INVENTORY.md`.
- **Resuming:**
  - Course Studio: the row reads "Course Wizard paused: step 6 of 8
    (GuideBook, Lesson 2)" (`course-wizard-paused-<id>`), and its ⋮ menu
    starts with **Continue Course Wizard**
    (`CourseManagerAction.continueCourseWizard`). It is greyed, with the
    reason, for someone who cannot edit the Course (`CourseAccessPolicy`).
  - The Course Editor's main page shows the same line with a Continue
    button.
  - The Wizard re-reads the stored Course on resume, so changes made by hand
    in the meantime are kept, and the step bar ticks what is done.
- **Continue by hand** (`course-wizard-by-hand`, every step): saves, forgets
  the Wizard and opens the Course Editor.
- A Course exported in the middle of the Wizard carries no Wizard state: on
  another device it is continued by hand.

## 5. Pictures for words

Build 266 gives each Words & Expressions entry an optional picture, chosen by
hand. Build 267 adds the prefill (owner: "In a Course to or from English, the
app could prepopulate some images chosen according to the word that is going
to be translated, while the user can change it").

- **When:** the Course's source or target language is English (base tag
  `en`). The English side of the entry is read: the source in a Course from
  English, the target in a Course to English.
- **Where:** on the module page, in the Wizard and in the Course Editor
  alike:
  - when a row gets both its texts and has no picture;
  - after Paste list;
  - with **Suggest pictures** (`guidebook-module-suggest-pictures`), which
    fills only empty rows.
  It never replaces a picture already there.
- **Matching** (`PictureSuggestions`, pure Dart, over the QQL catalog only):
  1. The English text is prepared:
     - capitals ignored;
     - optional words `{…}` and the context ignored;
     - a leading "the", "a", "an", "some" or "to" dropped ("to eat" → eat).
  2. Then it looks in this order, singular and plural alike
     (`imageTagKey`):
     - a picture whose name is the word (the part before a bracket, so
       "Doctor (man)" and "Doctor (woman)" both match "doctor");
     - else a picture with the word as a tag.
     A multi-word expression matches only as a whole.
  3. Exactly one picture found: it is filled in. Two or more equally good:
     nothing is filled, and the row offers "3 possible pictures", which opens
     the library on them. None: nothing.
  4. Never suggested: character pictures, Lesson icons. Flags may be
     suggested ("Italy").
- After a prefill a SnackBar says how many: "QQL suggested 9 pictures. Tap
  one to change it." Nothing marks them in the file.
- Device pictures (the Shared Image Library) are chosen by hand, as
  today.

## 6. Rounds (step 7) and the Round Wizard

The Round Wizard gains three things in Build 267, for the Wizard and the
Rounds page alike.

### Picture exercises from entry pictures

When the focus module has at least 3 words with pictures:

| Phase | Presets |
|---|---|
| Foundations | Picture flashcard (`picture_flashcard`), What is in the picture (`picture_choice`), Select the image (`icon_choice`) |
| Practice | Match pictures to words (`picture_word_match`), Spell the word in the picture (`image_word`), Name what you see (`picture_blocks`) |
| Use in context | Type what you see (`picture_name`), Listen and pick the image (`listening_image_choice`) |

- **Prefer picture exercises** (`generator-prefer-pictures`): on by default
  when the module has pictured words. It makes about half of each Round's
  focus slots picture exercises.
- **Wrong answers:** pictures and words of other pictured entries:
  - the slot's module first, then the Lesson;
  - never two entries with the same picture or the same target;
  - with the context rules of the 266 plan, §7.
- Spelling blocks only for single words of at most 10 letters.
- Every picture exercise follows the Course's Picture answers style.

### Round titles

**Round titles** (`generator-round-titles`): on gives Build 266's "<phase>:
<module title>", off gives untitled Rounds (the learner path then shows
"Round N"). Default on.

### The Duel count

The plan shows, per Lesson, the Duel questions it will make
(`generator-duel-count`): for example "27 Duel questions (25 needed)". It is
counted with `DuelEligibilityService.isEligible` on the planned exercises.
- Listening ones are counted apart: "3 more need audio".
- Below 25, the line says what to raise: Rounds per module or exercises per
  Round.
- It is shown only while Create Duels is on.

## 7. Check and publish (step 8)

- **Per Lesson:** modules, Rounds, exercises, Duel questions, Drafts, and
  Audit errors and warnings.
  - **Open the Audit** opens the Course Editor's Audit.
  - **Preview** opens `CoursePreviewScreen` (nothing recorded).
- **Publish** (`course-wizard-publish`):
  - GuideBooks, Rounds, exercises and Lessons without an Audit error are
    saved as Published, then the Course is published, by the existing
    publication rules;
  - anything with an Audit error stays Draft and is listed;
  - one confirmed save.
- **Finish** ends the Wizard (the key is removed) and opens the Course
  Editor. **Finish without publishing** does the same and leaves the
  Drafts.

## 8. Elsewhere

- **Lesson Options, Use GuideBook off** (owner: "explain that the GuideBook
  is recommended if someone turns it off"): switching it off asks first
  (`course-use-guidebook-off-notice`):
  - "The GuideBook is recommended. Without it there is no Round Wizard, no
    Word Lookup, no Open GuideBook on Before you start cards and no
    vocabulary in Review."
  - It also says what happens to the GuideBooks already written (the
    implementation confirms what is kept).
  - Buttons: **Turn it off** and **Keep it on**.
- **Help (EN/IT/ES):**
  - the new Editor Help question;
  - Course Studio Help (New Course, Continue Course Wizard);
  - the Round Wizard's Help (pictures, Round titles, Duel count);
  - the GuideBook entries question (Suggest pictures).
- **Fits a 360-pixel window**, like the canonical editor.
- **Unchanged:**
  - the Course format (no new Course field; the picture field is Build
    266's);
  - scoring, progression, learner data;
  - the Course Editor's single confirmation.

## 9. Revisions (one local commit each)

Every revision bumps the version (`2.0.67+267000` …) and the Beta expiry, and
updates CHANGELOG, the AGENTS.md release boundary, `docs/267_HANDOFF.md` and
`docs/267_VALIDATION.md`.

- **Revision 0, the frame:**
  - New Course → Basics and the choice;
  - steps 2–5;
  - explanation panels, Can wait labels, Fill with an example and Clear all;
  - Save for now, resume and Continue by hand (the key, Course Studio,
    reset and Inventory);
  - the Use GuideBook notice;
  - Help.
- **Revision 1, the GuideBook step:** step 6 and the English picture prefill
  on the module page.
- **Revision 2, the Rounds step:** step 7, picture exercises in the Round
  Wizard, Round titles, the Duel count.
- **Revision 3, the end:** step 8, Publish and Finish.
- **Then the Italian demo** (the original request), outside the repository
  until the owner says otherwise:
  - a short Italian Course built with the Wizard, led by the new pictures;
  - clear progression and variety, visual and "funny" exercise types
    preferred;
  - GuideBook and Duel on, no Round titles;
  - **the owner approves each module and each Round before it is created**;
  - to be settled then: the learners' language, the folder, the number of
    Lessons.

## 10. Open

- Whether learners see a word's picture in the GuideBook (266 plan §6;
  owner undecided).

## 11. Out of scope

- Starting the Wizard on an existing Course (only New Course and resume).
- Translated explanation panels (English only).
- Picture prefill for Courses neither to nor from English, or from device
  pictures and Local words.
- Pictures on Word Lookup and Review cards; pictures on Sentences.
- Stories and Timed Rounds in the Wizard (the Course Editor makes them).
- Writing content: QQL has no AI.

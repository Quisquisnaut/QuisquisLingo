# Build 261 validation

## Revision 7 Lesson and Round labels (3 October 2026)

- Lesson Options presents four Lesson label and numbering choices: Off, Lesson + number, Number only and Custom + number, alongside Round label and numbering. Stored Unit, Topic, Module, Skill, Chapter, Stage, Step and Part modes remain readable and display as the selected existing option until changed.
- Lesson titles remain required. Presentation tests verify that Off, numbered and custom labels all retain authored Lesson titles; Round presentation tests cover a numbered authored title under Off. Editor Help has a dedicated bilingual-selector FAQ in English, Italian and Spanish.
- Focused and complete suite results are recorded below after verification.

## Revision 7 Timed Rounds (3 October 2026)

- New Round offers Timed with a stopwatch icon. Limits are distinct and ordered, each 30–600 seconds; Lesson Options holds Course defaults that are copied into new Timed Rounds. The Canonical Editor and Audit use the same compatibility rules.
- The timer starts with actual Round play. Timeout locks input, leaves progress incomplete, and credits first-pass correct-answer XP. Timely completion awards the usual XP and a separate 10 XP On Time bonus on the first completion of each limit. Completed limits are stored per learner, Course and Round.
- `test/timed_round_261_test.dart` covers model persistence, icon, limits, default copy, Audit, countdown timing, timeout, retry, and once-per-limit bonus. Full verification results follow after the suite.

## Revision 0 (2.0.61+261000, 2 October 2026): learner polish

**Generators and validator**
- No Course file changes: the five generators' `--check` reproduce their
  Courses; `tools/validate_courses.py`: the four bundled Courses pass.

**Tests**
- New in `learner_round_path_test`: "Round, Story and sequence names":
  "Round 1: " / "Story: " / "Sequence: " in normal weight and the title in
  w800 in one `Text.rich`, the tooltips "Round 1: Pratica 1", "Story: Al
  bar", "Sequence: Numbers", none for an untitled "Round 2" (alone, w800),
  15 points with line height 1.4.
- New in `round_xp_completion_regression_test`: no confetti with
  Animations off, none with reduced motion (the dialog still shows); the
  weekly-goal test now finds `weekly-goal-confetti` (under an
  `IgnorePointer`) and none on the repeat.
- Updated: `learner_round_path_test` (the long title is one `Text.rich`
  "Round 1: …" of at most three lines; the Laurel overlap and opacity checks
  find the title by key), `leaderboard_navigation_test` (the Lesson title's
  tooltip is the whole "Lesson 1: …"; a Round is opened by its title key),
  the version pins (`app_metadata_225_04`, `qql_229_revision3`,
  `qql_233_revision_platform_contract`, `course_audit_report_225`, three
  pins there) and `beta_lifecycle_test` (every date one day later).
- While authoring: a three-line title at line height 1.5 overflowed the
  card by one pixel with the test font (69 + 20 > 88), so the line height
  is 1.4 (63 + 20).
- Focused runs: the learner path, the two XP regression files and the
  fifteen files that build the Home screen (one failure, the Round opened
  by its old title text, fixed and re-run), the version, Beta and Help
  tests.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 26 min 52 s):
  **3521 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.61+261001, 2 October 2026): Study and Review from Courses, the Course Editor opening mode

**Generators and validator**
- No Course file changes (the four bundled Courses unchanged).

**Tests**
- New: `test/courses_study_review_261_test.dart` (9 tests): the Study and
  Review reasons (a published bundled Course can be studied, none without a
  learner, "Publish this Course before you can study it." for a Draft
  Course, Review needs a completed Round); completed Rounds read from the
  Review records; Course Studio's `studyEntriesFor` apart from
  `entriesFor`; the opening mode (View only until chosen, a first opening
  remembers it, a later default leaves opened Courses alone, a mode chosen
  in the editor wins, Edit opens as View only without rights, a legacy lock
  keeps its meaning, the key under the learner prefix); Do Not Disturb sets
  it; from the empty library, All Courses → Study adds the Laboratory, makes
  it current (`IT`) and returns to the learner page, with Review greyed
  ("Complete a Round of this Course first."); Review on QQL Demo: English
  from Italian (a recorded Round) makes `EN_IT` current and opens Review on
  it; Course Studio closes Courses with the request.
- Updated: `app_reset_service_239_test` (the learner-progress reset keeps
  `course_editor_opening_mode`); the version pins.
- Focused run: the new file, then the 52 files that build Courses, Course
  Studio, the Course Editor modes, Do Not Disturb or the resets: 532
  passed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 27 min 13 s):
  **3530 passed, 1 skipped, 0 failed**.

## Revision 2 (2.0.61+261002, 2 October 2026): the Course preview from the Course Editor

**Generators and validator**
- No Course file changes (the four bundled Courses unchanged).

**Tests**
- New: `test/course_preview_261_test.dart` (6 tests): the Duel counts Draft
  content only with `includeDrafts`; the preview of QQL Demo: English from
  Italian with its Lesson, GuideBook and second Round as Drafts shows the
  Lesson open and nothing completed (no Practice or Perfect), the Draft
  Round on the path, Profile, Review and Settings disabled and no learner
  Course Selector, opens the Draft GuideBook with `includeDraftContent`, a
  Round in `previewMode`, and Preview · Exit returns, with every
  SharedPreferences value unchanged; a Duel opened from the preview is
  titled PREVIEW; the Course Editor's flag opens the preview and comes back
  to the editor; the Round editor has the flag in its AppBar; from an
  exercise form with an unsaved edit the preview shows the exercise as
  stored, and the edit is still in the form after Exit.
- While authoring: the preview's first frames wait for the Course flag's
  file reads like the learner page, so the test pumps with
  `pumpUntilFileIoState`; a Round left loading in fake time is closed
  through the Navigator.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 29 min 5 s):
  **3536 passed, 1 skipped, 0 failed**.

## Revision 3 (2.0.61+261003, 2 October 2026): exercise titles

**Generators and validator**
- No Course file changes (the four bundled Courses unchanged).

**Laboratory presentation baseline**
- Re-recorded with `QQL_RECORD_PRESENTATION`: 124 records, 70 changed,
  only in their `heading` (no instruction, prompt, panel, audio or control
  changed). The changes, by count: Word order and Pick the words for the
  gaps (12, from BUILD THE SENTENCE), Choose the answer (8) and True or
  false (3, from CHOOSE), the three spelling presets (7, from BUILD THE
  WORD), Type the missing word, Complete the text, Missing letters and
  Listen and fill the gaps (9, from COMPLETE), Read and answer (4, from
  CONTEXT), the three Match presets and Listen and match (7), Note card and
  Picture flashcard (4, from FLASHCARD), Pick the translation (4, from no
  title), and Select the image, Listen and pick the image, Pick the missing
  word, Listen and answer, Type what you hear, Type what you see and Story
  cover. The Laboratory test plays every example outside a Story, so the
  Story lesson's examples are recorded with titles.

**Tests**
- New: `test/exercise_titles_261_test.dart` (5 tests): 40 titles, the
  English one equal to the preset's name without its direction, all seven
  catalogs complete, `instruction.selectTranslation` with `{language}`;
  every exercise of the four bundled Courses titled by its preset in its
  Course's language; "the dog" of QQL Demo: Piedmontese titled PICK THE
  TRANSLATION with "Pick the correct Piedmontese translation"; in QQL Demo:
  English from Italian a Pick the translation shows SCEGLI LA TRADUZIONE and
  "Scegli la traduzione corretta in inglese"; its Story "Al bar" shows no
  title on the cover nor on its first question.
- Updated: `translation_choice_239_test` (the title is shown).
- While authoring: in a Story's scrolling log an authored instruction was
  shown twice (heading and text); the entry now shows it once
  (`story_runtime_256_test`). A focused run was disturbed by an
  interrupted earlier run still alive (stopped; its one failure passed
  alone).
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 29 min 2 s):
  **3541 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.61+261004, 2 October 2026): the preview made evident

**Generators and validator**
- No Course file changes (the four bundled Courses unchanged).

**Tests**
- `test/course_preview_261_test.dart` (7 tests): the clean-slate test now
  finds the PREVIEW bar and Course Info and no Course Selector, Settings,
  Profile or Review; new: the bar has the amber colour, Theme starts
  Light and turns Dark, Flag background starts Off and the next mode draws
  the flag behind the page, Exit returns, and every SharedPreferences value
  is as before.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 30 min 33 s):
  **3542 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.61+261005, 2 October 2026): owner review points 1, 2, 4 and 5

**Generators and validator**
- English from Italian, the Laboratory and the Piedmontese generators
  edited; the four bundled Courses, the two v11 converter fixtures and the
  future Laboratory fixture regenerated; all five generators' `--check`
  reproduce their Courses; `tools/validate_courses.py`: the four bundled
  Courses pass. An untitled Round first carried `"title": ""`, which the
  app does not write, so the bundled checksum check refused the Course;
  the generator now omits the key.
- Before the change, a scan of the bundled Courses found the correct
  answer inside the text in 18 Select exercises; the owner exempted
  listening, leaving the 7 reading questions (10 with QQL Demo:
  Piedmontese's copies), all rewritten.

**Laboratory presentation baseline**
- 3 records re-recorded (the Read and answer dialogues): only their
  answer buttons changed.

**Tests**
- New: `test/owner_review_261_revision5_test.dart` (8 tests): a reading
  answer copied from its text is `READING_ANSWER_IN_TEXT`, a reworded one
  is not, a listening one never is; no bundled Course has the finding;
  English from Italian's ordinary Rounds have no title and its Stories
  keep theirs; every primitive's example is legal, has no Audit error and
  plays where its primitive plays; a blank new exercise fills at once, a
  filled form asks before replacing, an existing exercise offers no
  example.
- Updated: the Audit rule counts (`audit_branch_ownership_226_02_revision4`,
  `audit_code_registry_226_02`: 114 rules, 45 Warnings), the New Canonical
  button gone (`sequence_round_256`, `story_add_step_256`,
  `revision3_followup_256`, which also checks Help names Canonical editor
  and Fill with an example), the version pins.
- Focused run (63 files): 5 failures, the baseline records and the two
  Build 256 expectations above, fixed and re-run.
- `flutter analyze --no-pub`: no issues.
- First complete suite (30 min 18 s): 3549 passed, 1 skipped, 1 failed
  (`audit_code_registry_226_02_test` still counted 113 rules), fixed and
  re-run alone.
- **Complete suite** (`--concurrency=1`, keep-awake, 31 min 43 s):
  **3550 passed, 1 skipped, 0 failed**.

## Revision 6 (2.0.61+261006, 2 October 2026): the canonical editor explains its primitives

- `dart format` on the changed Dart files; `flutter analyze --no-pub`: no
  issues.
- `python tools/validate_courses.py`: the 4 bundled Course Model v12 files
  valid; the five generators `--check`: reproducible (unchanged).
- `python tools/validate_media_assets.py`: 457 files (the nine new
  screenshots in `assets/primitives_screenshots/`), 0 issues.
- New `test/owner_review_261_revision6_test.dart` (22 tests): every role of
  the bundled Courses' and the fixtures' exercises (and the Fill with an
  example samples) is in `ElementRoles`, each menu offers a role once, the
  roles the runtime reads are listed; the Role menu changes only the role,
  keeps and marks a stored unknown role, covers item rows and fits a
  480-pixel window; the primitive popup once per primitive, learner and
  Course, again after Show one-time notices again, not in View only, after
  the two-ways introduction; Clear all with and without content, none on
  an existing exercise; the type-change message only over filled fields;
  nine Help sections in three languages, the nine screenshots present as
  PNG files, an image only where it exists, the editor's Help opening at
  its primitive.
- Focused runs: the new test, plus the primitive editor, Revision 5,
  interoperability, Page, Course Editor UI, QQL Guide, Help localization,
  settings, editor diagnostics and Lesson controls tests: all passed.
- Noticed, outside this revision: at 360 pixels the canonical editor's
  option menus (not the Role menu) overflow to the right; reported to the
  owner.
- **Complete suite** (`--concurrency=1`, keep-awake, 34 min 11 s):
  **3572 passed, 1 skipped, 0 failed**.

### Revision 6 follow-up (same version, 2 October 2026): the canonical editor fits a phone

- New `test/primitive_editor_narrow_261_test.dart` (10 tests): every
  primitive's form, blank (new) and with its example (existing), and every
  exercise of the Exercise Laboratory, at 360 pixels without an exception.
  Before the fix it failed on all nine primitives and on the Laboratory
  (overflows of 10–91 pixels from the option and evaluation menus, 17 from
  a Match item's header, 187 from a gap's Reveal menu).
- `test/owner_review_261_revision6_test.dart`: the Role menu test now runs
  at 360 pixels.
- Focused runs (the two tests above, the primitive editor, Revision 5,
  interoperability and Page tests): all passed. `dart format`, `flutter
  analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 30 min 29 s):
  **3582 passed, 1 skipped, 0 failed**.

## Revision 7 (2.0.61+261007, 3 October 2026): Round Types redesign

- The Round-type model, four Round-number formats, authoring selector,
  GuideBook Wizard replanning, canonical compatibility and blocking Audit,
  Story/Sequence preview flow, Test's deferred feedback, and learner-path
  Completed status have focused Flutter tests. Copy and transfer retain the
  Round type and Course numbering choice.
- Older official Course fixtures keep their original checksum when the new
  fields are synthesized during migration. A changed type or numbering
  setting cannot validate against that legacy checksum. The normal checksum
  applies to new official Courses.
- Editor Help has a Round Types section in English, Italian and Spanish;
  Exercise Primitives Help no longer contains Stories. Test result copy is
  complete in the seven learner-panel language catalogs.
- The four bundled generators' `--check` runs and
  `python -X utf8 tools/validate_courses.py` pass. Existing Course IDs,
  exercise content, and progress identities are unchanged.
- Codex's complete runs before the last changes: 3,602 passed, 1 skipped,
  3 failed (three older tests whose expectations the requested behaviour
  changed: an untitled Round, Number only keeping a Lesson title, a GuideBook
  card scrolled out of view); each was corrected and passes on its own.
- Final working tree (Beta expiry 2 November, release texts):
  `flutter analyze --no-pub`: no issues. All five generators' `--check`
  (Laboratory, Edge Case, Piedmontese sorted, Piedmontese mixed, English
  from Italian) and `tools/validate_courses.py` pass. Focused batch (Beta,
  version pins, Timed): 34 passed.
- **Complete suite** (`--concurrency=1`, keep-awake, `TEMP`/`TMP` on D:
  because C: lacked room for the 300 MB Image Library fixture, 45 min 30 s):
  **3605 passed, 1 skipped, 0 failed**.
- Not covered by a test: a Timed timeout during the mistake review or while
  the Review your mistakes message is open; the owner kept that behaviour
  unchanged (3 October 2026).
- After the suite `dart format` reformatted six changed files (no code
  change); `flutter analyze` (no issues) and those files' tests plus the
  source-reading Audit registry test (101 passed) were rerun.

## Revision 8 (2.0.61+261008, 3 October 2026): the learner path in Lesson colours

- Focused tests during the work: `learner_round_path_test.dart` (the
  palette, circle states, label and title styles, the 20% backgrounds,
  the halo, the placement pattern, the mascot rule, and a check that the
  line passes through every circle and never crosses a label, title or
  status at 292, 347, 402, 560 and 900 pixels), `leaderboard_navigation_test`,
  `lesson_fallback_number_icon_226_02_test`, `optional_learning_paths_226_04_test`,
  `app_info_path_colours_261_test` (new), the App Info translation and
  catalog tests, Course Info and enlarge tests.
- Visual check: eleven renders of the real path, preview, Duel and App Info
  with the Roboto font, sent to the owner; the render test was deleted.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, `TEMP`/`TMP` on
  `D:\QQL_test_temp`, 32 min 9 s): **3612 passed, 1 skipped, 0 failed**.

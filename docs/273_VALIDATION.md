# Build 273 validation

## Revision 0 (2.0.73+273000), the Story cast owner

15 October 2026, owner's Windows 10 PC, `build-273` from `main` `38016ab8`.

- Characterization: the Course Editor's Story characters were already
  driven by `test/story_editor_256_test.dart` (the narrator and the
  characters listed with their summary; a character still speaking is not
  removed and the message counts its lines; an unused one is removed and
  the tile's count follows; Add character; the narrator renamed; the
  default narrator saved unchanged changes nothing, a renamed one is a
  change) and `test/story_add_step_256_test.dart`; both files pass after
  the change.
- New tests: `test/story_cast_273_test.dart`, **12 passed**: `describe`;
  `summaryOf` (named and unnamed narrator, one and several characters);
  `linesSpokenBy` across Lessons and Rounds, the narrator's lines; the
  refusal in the singular and the plural; `replacing` and `without` keep
  the order; `withSpeakers`: the default narrator saved unchanged is not
  stored, a stored narrator stays stored (also equal to the default), a
  stored narrator of its own saved unchanged changes nothing, a changed one
  is stored, characters in order and none leaves no key, each credit once
  after the Course's own, everything else of the Course kept.
- Independent review (a fresh read-only agent, before the suite): no
  behaviour difference; the moved bodies compared with the old ones
  (whitespace-insensitive diff, bytes of the middle dot and quotes), every
  call site reads the same Course object as before, no removed name still
  used, the version bump and every date of `test/beta_lifecycle_test.dart`
  checked. Acted on: one sentence of the change summary made exact, one
  test case added (a stored narrator of its own saved unchanged).
- `flutter analyze`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`): **4,691
  passed, 1 skipped, 0 failed**, 61 minutes (the PC was slow with two
  browsers open).

## Revision 1 (2.0.73+273001), one publish gate

15 October 2026, same PC, `build-273` after `cf4c0c44`.

- Characterization, on the code **before** the change:
  `test/publish_gate_screens_273_test.dart`, 12 cases written first and
  **passed** on the old screens (the Course's Publish refused and applied;
  a Lesson from the Lessons page's menu and from the Lesson editor's Apply;
  a Round from the Rounds page's menu; the Round editor's Apply with Draft
  exercises (the notice) and without (the count); an exercise from the
  Round editor's list, refused and applied). After the review, 6 cases for
  the two exercise forms (an error listed with Keep editing; a warning
  answered Keep editing or Use anyway; preset form and canonical editor):
  they also **passed** on the old code, checked by setting the four screen
  files aside with `git stash` and running the file. All 18 pass after.
- Owner tests: `test/publish_gate_273_test.dart`, **8 passed**: a Round's
  errors with the Course and the Lesson taken as Published, a Draft
  exercise not counted, only the named Lesson taken as Published (two
  Lessons sharing a Round ID; checked by mutation: a gate that forces every
  Lesson fails it), a Lesson with only the Course taken as Published,
  another Lesson's errors not counted, the Course audited as given, the
  exercise audited alone with its errors and warnings, the refusals.
- The new files ran six times in a row before the suite (26 cases each
  time, all passed). The existing gate tests (`primitive_editor_256`,
  `owner_review_261_revision6`, `revision3_followup_256`,
  `guidebook_status_workflow_226_02`, `draft_promotion_239`,
  `provisional_parent_save_ui`, `exercise_workflow_226_02`,
  `audit_issue_save_propagation_226_02_revision4`,
  `authoring_hierarchy_indicators_226_02`, `first_letter_226_03`,
  `script_recognition_226_03`) and the 20 files that read screen source as
  text passed.
- Independent review (before the suite): no behaviour difference at any of
  the eight places (the audited Course, the audit method, the count, the
  texts, the dialogs, the `mounted` checks and the await order compared
  one by one; the double JSON round trip checked against the models).
  Acted on: the two exercise forms were not tested (6 cases added); the
  named-Lesson owner test was weak (rewritten); the docs said every copy
  projected the Course with its parents Published (corrected: the Course is
  projected as it is, an exercise audited alone); the Round type
  difference had an incomplete reason (corrected: a Round already
  Published takes an exercise that does not fit, and the runtime then
  plays none of the Round; recommendation changed). The corrections
  touched only tests, comments and documents, so no second review.
- `flutter analyze`: no issues.
- Complete suite: **4,717 passed, 1 skipped, 0 failed**, 40 minutes.

## Revision 2 (2.0.73+273002), answer grading out of the Round screen

15 October 2026, same PC, `build-273` after `fbe17052`.

- Characterization: the Round screen's grading was already driven by its
  own tests (among them `match_repeated_values_265_test`,
  `select_gap_fill_238_test`, `arrange_gap_fill_238_test`,
  `first_letter_226_03_test`, `runtime_canonical_256_test`,
  `test_round_attempt_test`, `translation_choice_239_test`,
  `owner_review_259_revision3_test`). After the change every test file that
  drives the Round, Review or Home screen (79 files) ran: **1,259 passed**.
- New tests: `test/answer_grader_273_test.dart`, **16 passed**: a typed
  answer (an accepted expression with its ranked alternatives, two after a
  right answer and three after a wrong one, more left unshown; a doubled
  letter forgiven by the exercise's tolerance and another typo not; a
  literal answer, no alternatives); blocks in order; missing words (every
  gap, as many fields as gaps, no typo forgiven, not even a doubled
  letter); gaps with blocks (two identical blocks interchangeable) and by
  choosing (by ID); several answers; groups; Match (repeated values
  interchangeable, the same answer twice wrong, a missing pair wrong, a
  plural picture apart, no rows); the right answer of each kind on the
  Laboratory's exercises, `firstVariant`, the fallback label.
- Independent review (before the suite): no behaviour change (every moved
  body compared with the old one: inputs, the fields assigned and when,
  guards, the order of operations, every remaining caller). Acted on: the
  ranked alternatives and the no-typo rule pinned exactly; two quoted texts
  corrected; the first difference reworded and widened with a fourth point
  it found (gaps ignore the exercise's normalization options). The
  corrections touched only tests and documents.
- `flutter analyze`: no issues.
- Complete suite: **4,733 passed, 1 skipped, 0 failed**, 37 minutes.

## Revision 3 (2.0.73+273003), the owner's decisions

15 October 2026, same PC, `build-273` after `ebda10ae`. A behaviour change
(owner decisions of the same day); the commit description was shown to the
owner before the commit ("Go").

- New tests: `test/owner_decisions_273_r3_test.dart`, **15 passed**, six
  runs in a row: `PublishGate.roundTypeIssues` (no Round; a choice in a
  Listen Round, also one the Round does not hold yet; not when the Content
  is not required; a Before you start card exempt in a Listen Round, not
  in a FlashCard or a Test Round) and the list's refusal text; gaps
  (capitals ignored by default and counted when exact; a wrong accent
  refused by default and accepted when accents are ignored; a gap trimmed
  first under "Spaces: exact"; a doubled letter never forgiven); the preset
  form (Apply refused with "Round type compatibility", also for a new
  exercise; Apply as draft not checked; a Before you start card in a
  Listen Round applied; a refused Preview listing "PAGE_LINK_INVALID: …");
  the canonical editor (no notice and Apply for such a card); the Round
  editor's list (the one-line refusal).
- Focused: 21 files of the changed areas (publish gate, grading, both
  editors, Round types, Timed Rounds, missing words, Complete the text,
  Before you start, the exercise editor, first letter): 181 passed.
- Independent review (before the suite): no blocking fault; the gate is the
  Audit's rule. Acted on: a gap's text trimmed (with "Spaces: exact" a
  trailing space would have made a gap wrong where one typed answer
  forgives it); the Test Round case and a new exercise tested; the docs
  made exact (Speak Rounds, the Exercise Wizard's form is checked too,
  Copy/Move/Duplicate are not, the current preset names, imported files);
  a stale comment. The one-word `.trim()` was not reviewed again: with the
  default options the engine trims anyway. Reported to the owner: a Before
  you start card in a FlashCard or Test Round breaks the Audit's rule
  though learners are shown it; "Accents: exact" has no effect.
- `flutter analyze`: no issues.
- Complete suite: **4,748 passed, 1 skipped, 0 failed**, 38 minutes.

## Revision 4 (2.0.73+273004), the held Story line has an owner

15 October 2026, same PC, `build-273` after `718d3e12`.

- Characterization: the held line on the Round screen was already driven
  by `test/spoken_lines_269_test.dart` (Continue greyed while the line
  reads itself aloud and released at its end, an early end left to the
  estimate, the watchdog and the ceiling, a tap on Play) and
  `labels_in_english_271_test` (the pace reset); with
  `story_runtime_256_test` they pass after the change (44 cases with the
  new file).
- New tests: `test/spoken_line_hold_273_test.dart`, **12 passed**, six runs
  in a row: nothing held without a spoken text; the estimate; a real end
  reads the line and teaches the pace; an early end waits for the
  estimate; a failed voice reads at once and teaches nothing; the watchdog
  (and, behind Before you start, only after its Continue); a started voice
  stops the watchdog; the ceiling, and a late end after it teaches nothing;
  an earlier line's voice and reading ignored; Play's flag; nothing after
  dispose. Two cases end with no timer pending, which fails a
  `testWidgets` case if a timer was not cancelled: checked by mutation
  (with the cancellations removed four cases fail).
- The 79 test files that drive the Round, Review or Home screen: 1,253
  passed and 2 failed in `timed_round_261_test` (the countdown not found);
  the same file failed once more alone right after, then passed five times
  in a row on the new code and five times on the old one: an intermittent
  failure under load, not this change (it passed in the complete suite).
- Independent review (before the suite): no behaviour change (every path
  compared: conditions and their order, state changes and redraws, the
  Crash Log lines, the timers, the shared pace, the line counter against
  `_preparedExerciseGeneration`, the tokens of `_speak`, `_lineBubble` and
  `_playLine`). Acted on: the version bump (done after the focused run),
  the test count, the method count, a test comment, two weak tests.
- A slip during the suite: a dry run of Revision 5's edit script edited
  the real `round_screen.dart` for about 20 seconds; the file was restored
  from a copy taken just before (`git diff --stat` unchanged) and no test
  file compiled meanwhile failed. See the handoff.
- `flutter analyze`: no issues.
- Complete suite: **4,760 passed, 1 skipped, 0 failed**, 47 minutes.

## Revision 5 (2.0.73+273005), one attempt at a Round has an owner

15 October 2026, same PC, `build-273` after `8f8aea4a`.

- Characterization: the Round screen's attempt was already driven by its
  tests (`test_round_attempt_test`, `round_xp_completion_regression_test`,
  `timed_round_261_test`, `timed_round_screen_272_test`,
  `celebrations_264_test`, `difficulty_bonus_260_test`,
  `match_repeated_values_265_test` and the Laboratory's learner cases).
  After the change the 79 test files that drive the Round, Review or Home
  screen ran: **1,256 passed**.
- New tests: `test/round_attempt_273_test.dart`, **12 passed**: the order
  given, start again, the shuffle drawn from the given Random exactly as
  the screen's `values.shuffle(_random)`, clear; the first pass's counts;
  the review of mistakes (its counts, the last answer, no second review);
  no review in a Round played in order or a Test (a Timed Round reviews);
  the last answer without mistakes; a card seen again; a Test's results and
  score (with and without a threshold, no answer). A Preview case in
  `test_round_attempt_test`: one mistake reviewed, "Temporary result: 1
  error. No learner progress was recorded."
- Independent review (before the suite): one real fault, fixed before the
  suite: the Preview and View Only result's count was written
  `'$_attempt.errors error…'` after the rename of `_errorsThisAttempt`
  (no braces inside the text: it would have printed "Instance of
  'RoundAttempt'.errors errors"); the new Preview case catches it (checked
  by putting the fault back). Everything else equivalent (all 67 old
  references, the random draws, the Test score, the labels). Also acted on:
  an unnecessary cast in the test, the AGENTS wording, the shuffle test
  pinned. The one-line fix was not reviewed again (the test pins it).
- `flutter analyze`: no issues.
- Complete suite: **4,773 passed, 1 skipped, 0 failed**, 46 minutes.

## Revision 6 (2.0.73+273006), the Access PIN has an owner

15 October 2026, same PC, `build-273` after `2113f3ff`.

- Characterization: the Access PIN was already driven through
  `ProfileService` by 20 test files (among them
  `qql_233_revision_profile_security_test`, `course_trust_270_test` with
  the wait, `learner_separation_270_test` with the session); after the
  change, with the new file, the 21 files ran: **321 passed**.
- New tests: `test/access_pins_273_test.dart`, **8 passed**: four digits
  and the verifier `v1:<salt>:<digest>` checked exactly (no PIN stored); a
  learner without a PIN; right and wrong; ten wrong PINs and the minute's
  wait (even the right PIN waits; after the wait the count starts again);
  a right PIN clears the count; a removed PIN is no PIN; the session; the
  profile service's names and the order of the credential keys.
- Independent review (before the suite): no behaviour difference (keys and
  stored formats, the order inside `verify`, the exception and every catch
  site through the re-export, the static session set at every call site,
  the constants and the credential keys' order, no cyclic import). Acted
  on: the verifier pinned exactly, a note on the session statics, the
  CHANGELOG's file count. Its two findings for the owner were confirmed in
  the code and decided by him (Revision 7).
- `flutter analyze`: no issues.
- Complete suite: **4,781 passed, 1 skipped, 0 failed**, 44 minutes.

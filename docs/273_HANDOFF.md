# Build 273 handoff

Build 273 is the second half of the modularization plan
(`docs/272_MODULARIZATION_PLAN.md`): the medium-risk owners, which the owner
moved out of Build 272 on 12 October 2026 ("after the owner has used this
Build"). Started on 15 October 2026 ("QQL 273") on branch `build-273` from
`main` `38016ab8` (Build 272 merged).

Rules (unchanged from Build 272, see `docs/272_HANDOFF.md`):

- An extracted, testable owner before any file split; one owner per
  revision; characterization tests that pass before the change.
- No behaviour change. A difference found between copies is kept, pinned
  by a test and reported to the owner with one recommendation; a change he
  decides is a revision of its own (and he wants to read the commit
  description of a behaviour-change revision before the commit).
- Every revision that creates an owner gets an independent read-only review
  (a fresh agent) before its complete suite, and its own complete suite;
  pure file moves go two or three per suite.
- Version bump, CHANGELOG, README, AGENTS.md, this handoff, the change
  summary and the validation file in every revision; commit on
  `build-273`, then push the branch (standing permission). `main` only on
  the owner's go.

## Revision order (proposed 15 October 2026; the owner may reorder)

| Rev | Owner | State |
|---|---|---|
| 0 | `StoryCast`: the Story cast rules of the Course Editor and the Story Wizard | done |
| 1 | One publish gate (eight copies, A–H below) | done; four differences put to the owner |
| 2 | `AnswerGrader`: the Round screen's grading, pure | done |
| 3 | The owner's decisions (below): the Round type check before Apply in the preset form and the exercise list (Revision 1, point 2); the canonical editor's Preview refusal list in both forms (Revision 1, point 3); gaps follow the exercise's normalization options, never typo tolerance (Revision 2, point 1). A behaviour change | done |
| 4 | `SpokenLineHold`: the held Story line | done |
| 5 | `RoundAttempt`: the queue, mistake review, Test results, completion | done |
| 6 | The Access PIN and its lock out of `ProfileService` | done |
| 7 | The owner's decisions on Revision 6 (below): removing a PIN clears its count and wait; "Wait 1 second". A behaviour change | planned |
| 8 | The Team registry's read and verified write: one owner for `TeamService` and the profile deletion | planned |
| 9 | The Course save sequence: one verified-commit step, the minimum-build policy | planned |
| 10 | The Audit's language tables and rule sets | planned |
| 11 | Home's lesson access and data loading; free moves `LearnerRoundPath` and the Course preview (left over from Build 272) | planned |
| 12 | The earlier exercise shapes (v11 layer), after the draft builder's older recipes build canonically | planned |
| later | The Duel's copies of the Round's voice, recorded-to-TTS fallback and Report sheet | to propose |

## Survey of 15 October 2026 (main at `38016ab8`)

A read-only agent mapped the items; line numbers are those of `38016ab8`.
Sizes: `course_editor_screen.dart` 7,927, `round_screen.dart` 5,794,
`home_screen.dart` 4,818, `course_models.dart` 5,787,
`course_audit_service.dart` 2,722, `course_editor_service.dart` 1,643,
`profile_service.dart` 1,136.

Differences between copies found (each to be reported to the owner in its
revision, never unified silently):

- **Publish gate** (Course Editor A `_toggleCourseDraftStatus` 847, B
  `LessonManagementScreen._setLessonPublication` 1841, C
  `LessonEditorScreen._saveLesson` 2463, D
  `LessonRoundsScreen._setRoundPublication` 5203, E
  `RoundEditorScreen._saveRound` 5833, F `_setExercisePublication` 5922; G
  the exercise editor's `_save` 2495; H the canonical editor's `_save` 315):
  B, D and F have their own "Move … to Draft?" wording, C, E, G, H use
  `confirmMoveToDraft`; C shows its SnackBar without a `mounted` check; E
  shows the Draft exercises notice instead of counting errors; F audits the
  exercise alone (no learner projection); G skips the Audit for a draft and
  asks about warnings; H blocks even a draft on registry violations and
  alone checks `RoundTypeCompatibility.issuesForExercise`. The GuideBook
  page has no gate (the Lesson save gates it).
- **Grading** (`round_screen.dart`): `_submitMissingWords` 3445 has no typo
  tolerance and no literal answers (`_submitFill` 1757 has both);
  `_submitSelectGaps` 2824 compares item IDs, `_submitArrangeGaps` 3153
  compares item values; Listen and match's button 4635 calls
  `_mark(_matchingReadsAsExpected())` without `_submitMatching`'s guard for
  no relations; `_correctAnswerText(ex)` 1440 reads `_features` of the
  current exercise, not of `ex`.
- **Access PIN**: `resetAccessPinAsAdmin` does not clear the lock key;
  `team_service.dart` imports `profile_service.dart`, so the Team-registry
  rewrite cannot simply move into `TeamService` (an import cycle): it needs
  a lower store both use. The rewrite duplicates `TeamService._save`.
- **Course save sequence** (`course_editor_service.dart`): eight copies of
  write / read back / align names / add to library / delete unreferenced
  media / event; some verify the write and some do not, some delete
  unreferenced media and some do not, `_confirmCourseTransactionLocked`
  adds to the library before verifying; the received-update path does not
  add to the library. The minimum app build is stamped only at confirmation
  (five chained `withMinimumAppBuild`).
- **Audit**: `_courseSourceCode` / `_courseTargetCode` are the same map
  written twice; `auditLesson` filters again by the "Lesson N ·" prefix
  after `onlyLessons`.
- **Duel**: `_speakText` checks `text.isEmpty` (the Round `trim()`), no
  diagnostics, no voice preference, services created directly, its own
  failure wording; the Report sheet differs only in its words.
- **Home**: `course_preview_screen.dart` is a `part` because it uses six
  Home privates (`_LessonSection`, `_usesDarkLearnerAppearance`,
  `_unifiedLearnerTheme`, the two page backgrounds, `_EmptyCourseCard`);
  `LearnerRoundPath` needs `_learnerPageBackgroundOf` and
  `_learnerMascotSeed` made public first.

## Revision 0 (2.0.73+273000): the Story cast owner

Done (15 October 2026, committed about 11:00, see `git log`): `StoryCast`
(`lib/services/story_cast.dart`): `describe`, `summaryOf`,
`linesSpokenBy`, `stillSpeaksMessage`, `replacing`, `without`,
`withSpeakers`. The Course Editor's Story characters, the Story Wizard and
the Rounds page's New Story result call it; `_courseWithSpeakers`,
`_speakerSummary` (twice) and `_linesSpokenBy` are gone. Kept as they are
(two presentations, not one rule): the Story Wizard's "Unknown character"
fallback for a speaker it does not know, the Round screen's fallback to the
narrator. Independent review: no behaviour difference. Complete suite 4,691
passed, 1 skipped (`docs/273_VALIDATION.md`).

## Revision 1 (2.0.73+273001): one publish gate

In the working tree (15 October 2026, about 11:15): `PublishGate`
(`lib/services/publish_gate.dart`) and its eight callers (A–H above);
`showEditorList` and `confirmUseAnyway` in `lib/widgets/editor_dialogs.dart`
for the two exercise forms. Characterization first: the 12 cases of
`test/publish_gate_screens_273_test.dart` passed on the code before the
change (the Course's Publish, the Lessons page's menu, the Lesson editor's
Apply, the Rounds page's menu, the Round editor's Apply with and without
Draft exercises, the exercise list's Apply; refused and applied) and pass
after; the review asked for the two exercise forms too: 6 more cases (the
errors listed, a warning answered Keep editing or Use anyway, in each
form), which also pass on the old screen code (checked with the four
screen files set aside by `git stash`); `test/publish_gate_273_test.dart`
(8) on the owner, its named-Lesson case strengthened after the review
(checked by mutation: forcing every Lesson fails it). Both files ran
six times; the existing gate tests and every source-text test file pass;
analyzer clean. Independent review: no behaviour difference; its points
acted on (see `docs/273_VALIDATION.md`). Complete suite 4,717 passed, 1
skipped. Committed about 12:10 and pushed. Open: the owner's answers to the
four differences (`docs/273_CHANGE_SUMMARY.md`, Revision 1, "Differences
kept"; recommendations: 1 one wording, `confirmMoveToDraft`'s; 2 the preset
form and the exercise list check the Round type before Apply; 3 the
canonical editor's Preview list in both forms; 4 leave the list's one-line
refusal). A decided change is a revision of its own.

**Owner decisions of 15 October 2026 (about 12:30) on the four differences:**
1. "Move X to Draft?" in the three menus and "Apply X as draft?" elsewhere:
   **keep both** (no change).
2. The Round type check: **check everywhere**: the preset form and the
   Round editor's exercise list refuse to Apply an exercise that does not
   fit its Round's type, as the canonical editor does.
3. The Preview refusal: **the canonical editor's list** ("CODE: message"
   lines) in both forms.
4. The exercise list's one-line refusal: **leave it**.
Points 2 and 3 are Revision 3 (a behaviour change, its own suite; show the
owner its commit description before the commit).

## Revision 2 (2.0.73+273002): answer grading

In the working tree (15 October 2026, about 12:45): `AnswerGrader`
(`lib/services/answer_grader.dart`) and `CorrectAnswerText`
(`lib/services/correct_answer_text.dart`); the Round screen delegates
(5,496 lines). Every test file that drives the Round, Review or Home
screen (79 files, 1,259 cases) passed; `test/answer_grader_273_test.dart`
(16). Independent review: no behaviour change; acted on: tests pinned
exactly (ranked alternatives, a doubled letter in a gap), two quoted texts
corrected, the first difference reworded and widened (gaps also ignore the
exercise's normalization options; found by the review). Next: the complete
suite, the commit, the branch push; then put Revision 2's differences to
the owner (`docs/273_CHANGE_SUMMARY.md`, Revision 2, "Differences kept").

Complete suite 4,733 passed, 1 skipped; committed about 13:45 and pushed.
**Owner answers of 15 October 2026 (about 13:40–13:50):** point 2 (gaps
by option ID vs blocks by text) and point 3 (no pairs; asked twice) **leave
them**; point 1 (gaps stricter than one typed answer), after the pros and
cons: **the middle way**: gaps follow the exercise's capitals,
punctuation, spaces and accents options, and never forgive typos (Missing
letters tests spelling; no per-gap "accepted with differences" note
needed). Revision 3 carries it with Revision 1's points 2 and 3.

## Revision 3 (2.0.73+273003): the owner's decisions

In the working tree (15 October 2026, about 14:00): `PublishGate.roundTypeIssues`
(the Audit's ROUND_TYPE_* rule for one exercise, Before you start card
exempt except in FlashCard and Test Rounds) and `roundTypeRefusal`; the
preset form checks before its Audit (Apply only), the Round editor's list
refuses in one line, the canonical editor's check and notice follow the
gate (the card exemption is new there); the preset form's Preview refusal
is `showEditorList` with "CODE: message"; `AnswerGrader.missingWords`
passes `f.normalization`. Tests `test/owner_decisions_273_r3_test.dart`
(13, six runs), the focused batch (21 files, 181) pass; analyzer clean on
`lib`. Version 273003, docs written. Found and left for the owner:
"Accents: exact" has no effect (same normalization as "missing accents
accepted"); a Before you start card in a FlashCard or Test Round breaks the
Audit's rule though `RoundPlayabilityService` shows it in every Round type.
Independent review: no blocking fault; acted on: `missingWords` trims each
gap (with "Spaces: exact" a trailing space would have made a gap wrong),
two more tests (Test Round card, a new exercise refused), docs (Speak
Rounds, the Exercise Wizard's form is checked too, Copy/Move/Duplicate not
checked, preset names, imported files). The one-word `.trim()` correction
was not reviewed again (default options give the same result: the engine
trims under "Spaces: normalize"). Tests 15, six runs; analyzer clean.
Complete suite 4,748 passed, 1 skipped. The owner said "Go" on the commit
description; committed about 14:55 and pushed.

## Revision 4 (2.0.73+273004): the held Story line

In the working tree (15 October 2026, about 15:15): `SpokenLineHold`
(`lib/services/spoken_line_hold.dart`) and the Round screen's calls
(5,380 lines). Tests `test/spoken_line_hold_273_test.dart` (12; its two
cancellation cases end with no timer pending, checked by mutation: with
the cancellations removed four cases fail). The 79 Round/Review/Home test
files: 1,253 passed, 2 failed in `timed_round_261_test` (the countdown not
found), and the same 2 failed once more alone right after; then the file
passed 5 times in a row on the new code and 5 times on the old one: an
intermittent failure under load (the review agent had just run). Watch
it in the complete suite. Independent review: no behaviour change; acted
on: the version bump (done after the focused run), the test count (12),
the method count (five), a test comment, the two weak tests. Analyzer
clean. Complete suite 4,760 passed, 1 skipped; committed about 16:05 and
pushed.

## Revision 5 (2.0.73+273005): the Round attempt

In the working tree (15 October 2026, about 16:15): `RoundAttempt`
(`lib/services/round_attempt.dart`) and the Round screen's calls (5,342
lines). Tests `test/round_attempt_273_test.dart` (12; the shuffle pinned
against `List.of(source)..shuffle(Random(7))`) and a Preview with a mistake
in `test_round_attempt_test` ("Temporary result: 1 error."). Independent
review: one real fault, fixed: the Preview result's count was written
`'$_attempt.errors error…'` (the regex rename of `_errorsThisAttempt`
inside a text, without braces: it would have printed "Instance of
'RoundAttempt'.errors"); the new test catches it (checked by putting the
fault back). Also acted on: an unnecessary cast in the test, the AGENTS
wording. The one-line fix was not reviewed again (the test pins it). The
first run of the 79 Round files was stopped for the fix (its processes
ended by hand); the second passed (1,256). Complete suite 4,773 passed, 1
skipped; committed about 17:20 and pushed.

Revision 6 is prepared in the session scratchpad `r6/` (`access_pins.dart`
with `ProfilePinException` moved there and re-exported by
`profile_service.dart`; `apply_r6.py <profile_service.dart>`, dry run on a
copy passed; `access_pins_273_test.dart`). Found for the owner: the wait
message says "Wait 1 seconds" when one second is left.

Next revisions: 6 the Access PIN and its lock (`AccessPins` out of
`ProfileService`: verifier, lock, session unlocks; report to the owner:
`resetAccessPinAsAdmin` does not clear the lock key), 7 the Team registry
read and verified write (one owner for `TeamService` and the profile
deletion's rewrite, which cannot simply call `TeamService`: it imports
`ProfileService`).

## Revision 6 (2.0.73+273006): the Access PIN has an owner

In the working tree (15 October 2026, about 17:40): `AccessPins`
(`lib/services/access_pins.dart`, with `ProfilePinException` re-exported by
`profile_service.dart`); `ProfileService` delegates (1,017 lines). Tests
`test/access_pins_273_test.dart` (8); the 20 earlier PIN test files pass.
Independent review: no behaviour difference; acted on: the verifier format
pinned exactly in the test, a note that only `ProfileService` calls the
session statics, the CHANGELOG's file count. Complete suite 4,781 passed, 1 skipped;
committed about 18:15 and pushed.

**Owner decisions of 15 October 2026 (about 17:45) on Revision 6's two
findings:** clear it (removing a PIN, by an admin reset or the learner's
own, also clears its count of wrong PINs and a wait in progress); fix it
("Wait 1 second" for one second). Revision 7, a behaviour change; show the
owner its commit description before the commit.

Gotcha (15 October 2026, 15:19): a dry run of Revision 5's edit script
meant for a copy edited the real `round_screen.dart` for about 20 seconds
while Revision 4's complete suite ran (a `sed` meant to rewrite the
script's target path matched nothing and the unchanged script ran). The
file was restored from the copy taken just before (`git diff --stat`
unchanged: 45 insertions, 161 deletions against `718d3e12`); the test files
compiled around that moment passed. Edit scripts now take their target as
an argument and refuse to run without one: never derive a dry-run script
by rewriting a path inside it.

Tools in the session scratchpad: `bump.py OLD NEW [--shift-day]` (every
version pin, the Beta comment and dates), `r0/apply_r0.py`,
`r0/docs_r0.py`.

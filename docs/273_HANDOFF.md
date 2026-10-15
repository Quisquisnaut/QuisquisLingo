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
| 1 | One publish gate (eight copies, A–H below) | planned |
| 2 | `AnswerGrader`: the Round screen's grading, pure | planned |
| 3 | `SpokenLineHold`: the held Story line | planned |
| 4 | `RoundAttempt`: the queue, mistake review, Test results, completion | planned |
| 5 | Access PIN and lock owner; the Team-registry rewrite out of `ProfileService` | planned |
| 6 | The Course save sequence: one verified-commit step, the minimum-build policy | planned |
| 7 | The Audit's language tables and rule sets | planned |
| 8 | Home's lesson access and data loading; free moves `LearnerRoundPath` and the Course preview (left over from Build 272) | planned |
| 9 | The earlier exercise shapes (v11 layer), after the draft builder's older recipes build canonically | planned |
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

## Revision 1 (next): one publish gate

Prepared in the session scratchpad `r1/` (15 October 2026): the owner
`PublishGate` (`publish_gate.dart`: `courseErrors`, `lessonErrors` (the
Course taken as Published), `roundErrors` (the Course and the Lesson taken
as Published), `exerciseIssues`, `errorsIn`, `warningCount`, the three
refusal texts), `apply_r1.py` (copies A–F of the Course Editor),
`apply_r1_forms.py` (G and H: `showEditorList` and `confirmUseAnyway` in
`editor_dialogs.dart`), the screen tests `publish_gate_screens_273_test.dart`
(to run on the code before the change first) and the owner tests
`publish_gate_273_test.dart`, and `owner_report.md`: four differences to
put to the owner (two wordings of "move to Draft"; the Round type check in
the canonical editor only; two Preview refusal lists; the exercise menu's
SnackBar). Not covered, on purpose: `ProvisionalPublicationService`, the
Course Wizard's publish, the Preview gates, the Round Wizard's approval.

Tools in the session scratchpad: `bump.py OLD NEW [--shift-day]` (every
version pin, the Beta comment and dates), `r0/apply_r0.py`,
`r0/docs_r0.py`.

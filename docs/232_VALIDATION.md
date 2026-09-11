# QQL 232 validation

## Release identity

- Version/build: `2.0.32+232`
- Display: Version `2.0.32`, Build `232`, Revision `0`
- Course Model: v7 (`formatVersion: 7`)
- Alpha expiry: `2026-10-13 23:59:59` local time, unchanged from QQL 231.1
- Baseline: committed `2.0.31+2311`

## Implemented boundaries

Before QQL 232, Review loaded up to 50 recent records into a selectable card list, wrapped that list in the learner status shell, and forwarded IDDQD View Only to the selected `RoundScreen`. QQL 232 replaces that coordinator UI with a dedicated page that automatically resolves the active Course's first valid candidate. `ProgressService` remains the ordering source: descending latest-attempt errors, then oldest latest-attempt timestamp; the ordinary Round completion path replaces the record with its new result and current timestamp.

`ReviewRoundResolver` requests the existing 50-record Course slice, skips stale Lesson/Round references and the current page's session-local completed-Round ID set, and returns the first resolvable Course/Lesson/Round location. `Next Review` recalculates through that resolver. Exhaustion leaves the learner on congratulations with a notice; leaving the page discards only the session exclusion set.

Review is reachable from the fixed Learner Panel Review action and the three-dot menu of the Current course row. No inactive, recent, included, local or hidden Course row receives Review. Both paths push a route above the existing Home state; Back and `Back to course` return to that retained Course and scroll state. Review has no learner status bar. Its own app bar exposes Reset Word List followed by Review Help. Vocabulary cards and the Review-only Round presentation show Course, target language, Lesson and Round context with wrapping text and progress.

## GuideBook Vocabulary and state

The Course Model v7 GuideBook schema found in the baseline stores vocabulary as ordered `LearningContent` records with stable `id`, `publicationState`, `kind: vocabulary`, normally `role: vocabulary`, and one authored `text` string. The established pair separators are ` = `, ` → `, ` - ` and `:`. There are no structured gender, pronunciation, example, note, alternative-meaning or part-of-speech fields, so QQL 232 renders the parsed prompt and answer only and fabricates no supplementary data.

`VocabularyReviewService` consumes `PublicationService.learnerGuidebook`, enabled by `Course.useGuidebook`, and preserves every valid authored occurrence and relative order. Draft/disabled/empty/malformed vocabulary skips directly to the Round.

The service persists one version-1 JSON document per active opaque learner and immutable Course ID under:

`learner_<profile UUID>_v1_vocabulary_review_course_<lowercase SHA-256 of trimmed courseId>`

The document contains Lesson-ID maps and entry-identity records with only `fingerprint`, `encountered`, and `needsReinforcement`. A stable non-empty Content ID is primary identity; deterministic occurrence suffixes separate repeated malformed IDs. Empty in-memory IDs use the content fingerprint plus authored duplicate occurrence index. The fingerprint is lowercase SHA-256 of `jsonEncode(['qql232-v1', prompt, answer, supplementary])`. Course/Lesson/Round titles and positions are excluded, so title-only changes preserve state while changed presented content is new. Missing, obsolete, malformed, deleted and stale values behave as absent.

Before a Round, never-encountered and reinforcement-marked entries appear in authored order. The answer must be revealed before `I know it` or `Show it to me again`; each decision persists before advancing. Only words requested again in that exact preparation appear once after normal Round completion. They again require reveal, followed by `Now I know it` or `I still don't know it`. Known words remain skipped in later Rounds from the same Lesson and in later visits; changed/new and still-difficult words remain eligible. Abandoning the Round returns to the Learner Panel while already persisted vocabulary decisions remain authoritative.

Reset Word List is confirmation-gated and removes only the active learner's current-Course vocabulary document. During preparation it restarts with every usable word; during post-Round reinforcement it discards the remaining post list so old decisions cannot recreate reset state. It does not touch the session Round exclusions, Review history, completion, XP, Weekly XP, activity, streak, Laurels, Duel state, unlocking, authored Course data or other preferences.

IDDQD Off, On and View Only have no effect on Review. Review candidates are genuine completed records, and the central Round runs through ordinary writable Review completion. Vocabulary actions themselves add no XP or separate progression. QQL 232 adds no Word Review page, independent vocabulary queue, SRS, due dates, confidence, mastery, word XP, word streak, Course Model field, migration, bundled content or checksum change.

## Verification evidence

| Check | Result |
|---|---|
| Focused QQL 232 service/widget/navigation suites | PASS — 140 tests |
| Affected GuideBook and learner regression suites | PASS — included in the 140-test focused boundary and complete suite |
| `flutter analyze --no-pub` | PASS — No issues found |
| Complete `flutter test --no-pub --reporter compact --timeout 60s` | PASS — 1,401 tests |
| `test/sample_courses_test.dart` | PASS — 19 tests |
| `tools/regenerate_bundled_courses_225_02.py --check` | PASS — all 9 bundled checksums verified |
| `tools/validate_courses.py` | PASS — 9 Course Model v7 files |
| `git diff --check` | PASS |
| Alpha expiry source and test | PASS — source unchanged; build-232 assertion retains `2026-10-13 23:59:59` |
| Final scope/status inspection | PASS — no asset, Course JSON or checksum changes; release actions not performed |

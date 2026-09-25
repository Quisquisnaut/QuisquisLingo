# Build 254 validation

Version `2.0.54+254000`, Build 254 Revision 0, dated 2026-09-25. Beta expiry:
`2026-10-25 23:59:59` local time.

## Scope and checks

The validation covers three replacement bundled demos, separate selection of
two English-target bundles, immutable-source preservation for active Draft
content, the owner-approved Flashcard usage fix, and release metadata.
Course Model v11, package format 1, learner storage keys, rights enforcement,
scoring and progression remain unchanged.

Fresh focused evidence collected during implementation:

- The initial registry regression failed on the old Italian asset path.
- All three Flashcard regression tests failed with empty usage answers before
  the correction, then passed. Laboratory's Flashcard authoring preservation
  assertion also passed.
- All three full-source regressions failed with four Lessons instead of five,
  then passed after Studio loading, export and opening used the immutable bundle.
- Laboratory's 165 tests passed: all 80 examples pass the actual authoring
  builder, model round trip and learner completion controls. Alternate translation
  order and Presentation Review again are also exercised. Native speech is stubbed;
  grading and progression in the widget are real.
- All seven Edge Case workflow tests passed: strict model/checksum round trip
  and exact warnings; Draft filtering and vocabulary; repeated/gap boundaries;
  real MP3 validation and all three audio modes; official package export and
  deliberate ordinary-import refusal; persisted Fork/Copy/Merge; and a personal
  fork's package import/re-export using actual image and MP3 bytes.
- Laboratory and Piedmontais original packages preserve every canonical Content
  payload; saved personal forks survive real export, receiver Import and re-export.
  All three new bundled identities reject custom impersonation. The initial
  package test incorrectly required usage on every Flashcard; its corrected oracle
  checks both intentional omissions and supplied usage text.
- The real Selector test switches between the two English bundles and restarts
  on Edge Case Course. Its test now waits for the existing Course entry animation
  before reopening the Selector. No animation behavior changed.
- Piedmontais's five focused checks passed for identity, all 24 titled types,
  all 72 examples, answers and portable image content.
- The structural Course validator passed for all ten bundled files.
- The media integrity validator passed: 443 files, including all 19 locked
  audio files and 281 world flags, with zero issues.

## Final release checks

`flutter pub get` succeeded without changing dependency constraints. The first
analyzer run identified one unnecessary test import; it was removed before the
complete suite started. The final `flutter analyze --no-pub` reports **0 issues**
(40.6 seconds).

The final `flutter test --no-pub --concurrency=1 --reporter expanded` completed
in **28 minutes 24 seconds: 2,685 passed, 1 existing platform skip, 0 failed**.
This includes the complete 165-test Laboratory matrix and all corrected legacy
fixtures. No production or test file changed after that successful run.

`flutter build windows --release --no-pub` passed in **28.2 seconds**. The built
`build/windows/x64/runner/Release/quisquislingo_app.exe` reports
`2.0.54+254000` in both FileVersion and ProductVersion. Its bundled Course folder
contains exactly ten JSON files, all SHA-256-identical to the source assets;
the removed Italian, Finnish and Dutch files are absent. This validates the
Windows Release output; no release ZIP was published or pushed.

All three `tools/generate_*254.py --check` commands pass. `validate_courses.py`
accepts all ten bundled Courses. `validate_images.py` checks 111 Image Bank assets,
`validate_lesson_icons.py` checks 14 icons, and `validate_media_assets.py` checks
443 files (19 locked audio files and 281 world flags): **0 issues** throughout.

Independent source and content review found no material production-code defect.
Its optional-usage test correction and inaccurate Piedmontais button labels were
fixed before final verification. The course matrices document the accepted input
coverage and the explicit native-device limits.

The initial serial suite was stopped after three stale fixture assertions failed:
two assumed every bundle lacked Draft content, and one used the former Italian
demo as its derivatives-disallowed example. The corrected tests assert exact
9-of-10/default and 10-of-10/revealed counts, Drafts only in `EN_EDGE`, and use the
retained German bundle for the original rights check. All three focused
regressions pass. The complete suite was restarted after these test-only changes.

That full discovery run exposed further legacy fixture assumptions: mutable
bundled-source substitution, the removed Italian Course's Sections/Duels and
Finnish recent-selection entry, the old derivatives-disallowed default, and
unregistered fake bundles used for badge tests. Navigation now explicitly uses
the retained German fixture where that structure is required; source checks
require immutable JSON; badge tests use the existing local-course listing seam.
The explicit Italian/German selection tests and all original behavior assertions
remain. Independent review found no weakened assertions in those adaptations.

Preserved Flashcard usage makes the mixed-content fixture taller. Its completion
helper initially looked for an unbuilt Next button below the lazy list's visible
content. A diagnostic confirmed all 12 items remained queued and Card reviewed
feedback was correct. The helper now scrolls the actual Round list to reveal the
expected advance button; the 8/8 evaluated-item and XP assertions are unchanged.

All discovered failures passed focused verification before the final rerun.
The five affected files passed 80 tests with two remaining failures initially;
the corrected German flag ratio and mixed-content scroll interaction then passed
the combined four-test XP/phone-width check. The suite's existing POSIX symlink
test in `qql_tools_settings_test.dart` is skipped on Windows; no task test is
skipped.

## Intentional Audit warnings

The release gate matches exact Course reference, Exercise ID and code; it does
not suppress a warning category globally. The expected total is eight:

| Course | Exercise | Code |
| --- | --- | --- |
| Laboratory | `qql_lab254_card_minimal` | `FLASHCARD_EXAMPLE_EMPTY` |
| Laboratory | `qql_lab254_card_minimal` | `FLASHCARD_AUDIO_EMPTY` |
| Laboratory | `qql_lab254_card_usage` | `FLASHCARD_AUDIO_EMPTY` |
| Laboratory | `qql_lab254_card_usage_translation` | `FLASHCARD_AUDIO_EMPTY` |
| Laboratory | `qql_lab254_card_audio` | `FLASHCARD_EXAMPLE_EMPTY` |
| Edge Case | `qql_edge_254_e04_duplicate` | `CHOICE_ANSWER_DUPLICATE` |
| Edge Case | `qql_edge_254_e07_long` | `EXERCISE_TEXT_LONG` |
| Piedmontais | `pms_e5f5585a_l20_r01_e01` | `OPPOSITE_TOO_EARLY` |

These exercise optional-field omissions and deliberately difficult but valid
content. The seven retained bundles continue to require zero Audit warnings.

## Windows and device limits

A temporary `ES_CONTINUOUS | ES_SYSTEM_REQUIRED` request prevents Windows
suspension during the task. Long validation/build supervisors also hold and
clear their own request in `finally`; persistent power settings are unchanged.
All Flutter commands use the consistently spelled `C:\QQL\QuisquisLingo` path.

Automated audio tests inspect source selection and real MP3 bytes. They do not
certify audible output, native voice pronunciation, or availability of a
Piedmontais voice. Native-speaker review of the AI-generated Piedmontais content
and owner device playback remain manual checks.

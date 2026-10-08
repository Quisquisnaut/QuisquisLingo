# Build 252 validation

## Revision 0 — Exercise Authoring

The isolated checkout started from merged `main` at `7de16ea`, with the
original checkout's pre-existing untracked `devtools_options.yaml` left
untouched. The actual release date is 2026-09-24 (Europe/Rome); the 30-day
local Beta expiry is `2026-10-24 23:59:59`. This is a source release
without a Windows package.

During validation, `main` advanced to `0bedcb3` with documentation-only
changes to `AGENTS.md` and `docs/251_CHANGE_SUMMARY.md`. The final commit
uses that newer parent and retains both changes. They alter no Flutter
runtime or test input, so the completed test gate was not repeated.

### Before extraction

The existing affected editor tests passed **146/146** on the old
`_buildCandidate` implementation:

```text
flutter test --no-pub --concurrency=1
  test/exercise_workflow_226_02_test.dart
  test/arrange_gap_fill_editor_238_test.dart
  test/select_gap_fill_238_test.dart
  test/translation_choice_239_test.dart
  test/translation_ui_226_03_test.dart
  test/script_recognition_226_03_test.dart --reporter compact
```

The new `test/exercise_authoring_252_characterization_test.dart` passed
**14/14** against the old implementation. It checks v11
`LearningContent` and Course round trips, existing IDs and assignments,
Draft/Published outcomes, image provenance, and Preview/Save/Cancel
through the widget. The pure-owner contract test then failed to load
because `ExerciseDraftBuilder` did not yet exist, establishing the
pre-extraction red step.

### Extraction and focused evidence

`ExerciseDraftBuilder` now receives a detached snapshot of the Exercise
draft and returns a candidate or typed field error. The screen translates
errors into its existing inline or SnackBar feedback. The existing
`ScriptRecognitionController` still constructs script candidates and
retains their stable option identities. Save attaches the selected
shared-image provenance; Preview uses the raw candidate. The Course
session remains the final Course update owner.

The integrated new builder and characterization tests passed **20/20**
after the extraction. A follow-up builder test for a missing script
snapshot failed before the error was typed, then the seven direct builder
tests passed **7/7**. An independent read-only comparison found no
concrete behavior difference in the old and new candidate paths,
validation order, messages, IDs, publication rules or image provenance.

### Release gate

The four asset validators passed with exit code 0:

| Command | Result |
| --- | --- |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files |
| `python tools/validate_images.py` | 111 assets, 0 issues |
| `python tools/validate_lesson_icons.py` | 14 assets, 0 issues |
| `python tools/validate_media_assets.py` | 443 media files, 0 issues |

The integrated focused command covered the two new tests, the affected
Exercise Editor, script, image, Course route and version tests. It passed
**218/218** with exit code 0. Analyzer initially reported one style issue
in the new characterization test. After changing only that string
expression, the affected test passed **14/14** and
`flutter analyze --no-pub` reported **No issues found**. The new builder
and characterization files pass `dart format --output=none
--set-exit-if-changed`; running that formatter check against older files
edited only for version expectations also reported their pre-existing
formatting differences, which were left untouched to keep the diff narrow.

The complete Flutter suite passed **2452/2452** with exit code 0 in
26 minutes 25 seconds:

```text
flutter test --no-pub --concurrency=1 --reporter expanded
26:25 +2452: All tests passed!
```

For this long run, the supervising PowerShell process acquired
`ES_CONTINUOUS | ES_SYSTEM_REQUIRED` with `SetThreadExecutionState`
before invoking Flutter and released the request with `ES_CONTINUOUS`
in `finally`. The request changed no persistent Windows power setting.
`git diff --check` passed after the release notes and handoff were written.

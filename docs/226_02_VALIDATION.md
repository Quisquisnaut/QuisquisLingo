# QQL 226.02 pre-commit validation report

Status: **226.02 corrective revision 4 implementation is complete. All affected focused tests and validators pass; the one complete-suite run passed 851 tests and had one non-reproduced failure whose full 28-test file then passed in isolation.** The analyzer retains only the 72 revision-3 findings. The Windows visual checks listed below remain manual.

## 226.02 corrective revision 4 closure

Revision 4 continues directly from committed revision 3, `2bff7e88cbd3f0099e8333d2838eb3371baae8d7`, in the existing checkout. No worktree, reset, revert, clean, discard or unrelated roadmap work was used. The final metadata is **Version 2.0.26 / Phase 226.02 / revision 4 / technical build 226024 / `2.0.26+226024`**. The first-run popup renders `Version 2.0.26` and `Phase 226.02, revision 4` on separate lines and retains the technical-version show-once key. Alpha expiry remains **2026-10-06 23:59:59 local time**.

### Implemented behavior and Audit root cause

- Every selected, recent and unselected learner course-selector row now receives the loaded `Course` and renders its actual `Course.title`. Bundled and custom courses use the same tile path; language and origin remain separate metadata. Narrow layouts may wrap or ellipsize the real title, but never substitute a target-language-only label. Coverage includes selected/unselected bundled and custom Courses, the exact `AI-Slop Demo: Inglés para hispanohablantes` title, and a narrow long-title row.
- Inspection proved that the persisted fallback values do not mean stable blue and black circles. The existing `monochrome` value uses the active theme's container/foreground colors in light and dark themes, while `coloredLessonNumbers` renders the existing fixed four-color circle. The user-facing control is therefore **Fallback lesson number icons**, with **Theme-colored circle** and **Four-color circle**, in **Lesson appearance** on the Lessons page. It is absent from Course Info. Stored enum values and Course JSON remain compatible, the preview updates immediately, confirmation/reload preserves the choice, Editor and learner fallbacks render the selected behavior, and explicit custom Lesson icons remain unchanged.
- The canonical Audit service was recomputing correctly when invoked, but each nested authoring route owned a separate Course snapshot. Exercise saves first changed only the Round editor's local list; Round and Lesson routes returned their copies only while unwinding navigation. Open ancestors therefore continued painting an older canonical result until a later pop, reopen or unrelated refresh. Revision 4 adds one immutable `onCourseChanged` propagation chain through Course Editor, Lessons, Lesson, Rounds and Round/Exercises and applies accepted Exercise saves immediately to that chain. Create, delete, reorder, Move, Copy and publication mutations use the same course-level adoption path rather than widget-specific border overrides.
- Canonical branch ownership is now carried by structured Lesson/Round/Exercise IDs, with Guidebook findings matched to the Guidebook location. Guidebook findings reach the Lesson, Lessons link and Course ancestors without contaminating an otherwise clean Rounds branch. Course-only metadata findings likewise do not color the Lessons link. Stale or unavailable results remain neutral; Info alone remains green; any current Error or Warning in the represented branch is red.
- The reported visual combination can be canonical rather than stale: an empty Guidebook emits genuine Warning **`LESSON_GUIDEBOOK_EMPTY`**. A regression fixture with one Round and three valid, Published Exercises proves that every Exercise and the Round are green while the empty Guidebook, Lesson and Lessons link are red. The exact historical manual Course snapshot was not retained, so its red Lesson cannot be assigned conclusively; if that Guidebook was empty, the red state was correct. The independent stale-snapshot defect above was also real and is covered in both directions by saving an Exercise that introduces the last Warning and then correcting it without leaving the route.
- A Guidebook can now be saved normally or as Draft. Its own Error/Warning state gives its navigation card a red Audit border, and its Draft state gives the same card the independent blue Draft badge. Both states inherit through Lesson, Lessons and Course; they do not color or mark the separate Rounds branch. An empty Draft Guidebook is therefore red and blue. Normal Save publishes the Guidebook and its content; Save as Draft marks both container and content Draft. Draft Guidebook content is excluded from learner delivery while remaining visible in authoring/inspection preview. Missing serialized state defaults to Published, and Published Guidebooks keep the previous JSON shape; only Draft writes the optional `publicationState`, so Course Model v6 remains the format.
- Publication Audit resolves a Published Round's valid provenance against authored Guidebook IDs even when that Guidebook is Draft and absent from the learner projection. Deleting the referenced authored content still produces the canonical missing-reference finding.
- Passive selectable Internal IDs now follow both existing actionable lines in Lesson, Round and Exercise entries on custom and official screens. They remain non-clickable, monospaced, complete through tooltip/copy, and responsive at 320 and 430 px. Revision-3 direct toggle behavior and exact tooltips remain unchanged: **`Internal IDs shown. Tap to hide`** and **`Internal IDs hidden. Tap to show`**.
- Revision-3 Help coverage, one blue Draft indicator, empty-Round `ROUND_CONTENT_EMPTY`, empty-Lesson `LESSON_ROUNDS_EMPTY`, Course Manager naming, all nine AI-Slop Demo titles, ID identity rules and red/green/neutral semantics remain covered. The canonical Audit Registry remains **103 rules**; no rule or severity was added, removed or changed to manipulate a border.

The nine sample titles remain exactly:

- `AI-Slop Demo: Dutch for English Speakers`
- `AI-Slop Demo: Inglés para hispanohablantes`
- `AI-Slop Demo: Finnish for English Speakers`
- `AI-Slop Demo: German for English Speakers`
- `AI-Slop Demo: Italian for English Speakers`
- `AI-Slop Demo: Korean for English Speakers`
- `AI-Slop Demo: Portuguese for English Speakers`
- `AI-Slop Demo: Spanish for English Speakers`
- `AI-Slop Demo: Welsh for English Speakers`

The user's revision-3 classification remains authoritative: these nine are AI-generated, unreviewed demonstrations, not reliable learning courses. Their files, IDs, language metadata, content, attribution, licensing and provenance are unchanged in revision 4.

### Revision 4 fresh validation

Commands were run from the repository root with bounded yields, one Flutter process at a time, and `--no-pub`:

```text
dart format <all changed Dart files>
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s <33-file implementation-focused set>
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/alpha_lifecycle_test.dart test/app_metadata_225_04_test.dart test/authoring_audit_ui_224_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/audit_branch_ownership_226_02_revision4_test.dart test/audit_issue_save_propagation_226_02_revision4_test.dart test/course_audit_report_225_test.dart test/custom_hierarchy_id_order_226_02_revision4_test.dart test/editor_diagnostics_226_02_revision3_test.dart test/guidebook_learner_delivery_226_02_test.dart test/guidebook_publication_226_02_revision4_test.dart test/guidebook_status_workflow_226_02_test.dart test/korean_production_discovery_225_03_test.dart test/leaderboard_navigation_test.dart test/learner_round_path_test.dart test/lesson_fallback_number_icon_226_02_test.dart test/lesson_metadata_and_icon_test.dart test/official_hierarchy_id_order_226_02_test.dart
flutter test --no-pub --reporter expanded --timeout 60s --plain-name "Lessons owns the live fallback number preview and preserves its selection" test/lesson_metadata_and_icon_test.dart
flutter test --no-pub --reporter expanded --timeout 60s test/course_editor_224_test.dart
flutter test --no-pub --reporter expanded --timeout 60s --plain-name "Copy Round to lesson-one survives every parent return" test/authoring_transfer_ui_226_02_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
flutter test --no-pub --reporter expanded --timeout 60s test/exercise_workflow_226_02_test.dart
python tools/validate_courses.py
python tools/regenerate_bundled_courses_225_02.py --check
python tools/validate_lesson_icons.py
python tools/validate_images.py
git diff --check
```

Exact fresh results:

- Formatting completed before final source/test validation. The initial implementation-focused run was **356 passed / 2 failed**: one real 320 px Lessons-panel overflow and one selector fixture that did not wait for asynchronously loaded Course records. The panel help was made concise and the fixture now waits for the loaded picker; the two exact reruns each passed.
- Final 19-file affected set: **185 passed / 1 failed**. The sole failure was a stale wording expectation after the concise narrow-layout Help correction. Updating only that fixture produced **1 passed, exit 0**, so all **186 distinct affected tests** are green. After removing two analyzer-reported brace-style findings, `course_editor_224_test.dart` passed **6/6** and the affected Round-copy UI test passed **1/1**.
- Analyzer first reported the 72 revision-3 findings plus two new `curly_braces_in_flow_control_structures` infos in changed Course Editor callbacks. Those two statements were braced and retested. Final analyzer: **exit 1, 72 findings**; revision-3 baseline **72**, final revision 4 **72**; **inherited 72, new 0, resolved 0**. The inherited set is 71 brace-style infos and one `unused_element` warning at `test/guidebook_sentence_generator_test.dart:255`. No analyzer suppression or policy change is included.
- Complete Flutter suite, executed once after the last production/test change: **851 passed / 1 failed, exit 1, 10m29s**. The failed parameter was `unsaved listening_spelling Preview preserves PublicationState.published, timestamps, JSON and preferences` in `exercise_workflow_226_02_test.dart`. It had passed in the affected run; the entire file immediately passed **28/28, exit 0** in isolation, including that parameter. No reproducible product failure or repository change followed. This non-reproduced full-run result is reported as a remaining validation risk rather than rewritten as a passing suite.
- Bundled-course validator: **9 bundled Course Model v6 files validated, exit 0**.
- Deterministic generator/checksum validation: **all 9 generated files and hashes verified, exit 0**. The generator correctly retains revision-3 release metadata because no bundled JSON changed in revision 4.
- Lesson-icon validator: **14 assets, 0 issues, exit 0**.
- Image Bank validator: **112 assets, 0 issues, exit 0**.
- `git diff --check`: **exit 0, no whitespace errors**; output contained only working-copy LF/CRLF notices.

### Revision 4 changed files

```text
AGENTS.md
CHANGELOG.md
README.md
docs/226_02_VALIDATION.md
docs/COURSE_EDITOR.md
docs/COURSE_JSON_FORMAT.md
docs/SAMPLE_COURSE.md
lib/models/course_models.dart
lib/screens/course_editor_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/guidebook_screen.dart
lib/screens/home_screen.dart
lib/screens/official_course_inspection_screen.dart
lib/screens/round_screen.dart
lib/services/alpha_lifecycle_service.dart
lib/services/app_metadata.dart
lib/services/authoring_duplication_service.dart
lib/services/course_audit_service.dart
lib/services/publication_service.dart
lib/widgets/editor_app_bar_actions.dart
pubspec.yaml
test/alpha_lifecycle_test.dart
test/app_metadata_225_04_test.dart
test/authoring_hierarchy_indicators_226_02_test.dart
test/course_audit_report_225_test.dart
test/korean_production_discovery_225_03_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/lesson_metadata_and_icon_test.dart
test/audit_branch_ownership_226_02_revision4_test.dart
test/audit_issue_save_propagation_226_02_revision4_test.dart
test/custom_hierarchy_id_order_226_02_revision4_test.dart
test/guidebook_learner_delivery_226_02_test.dart
test/guidebook_publication_226_02_revision4_test.dart
test/guidebook_status_workflow_226_02_test.dart
test/lesson_fallback_number_icon_226_02_test.dart
test/official_hierarchy_id_order_226_02_test.dart
```

`analysis_options.yaml`, `pubspec.lock` and `test/course_editor_224_test.dart` appeared modified by timestamp/line-ending normalization during tooling, but their working-tree blob hashes match revision 3 and they have no textual diff. They are not revision-4 changes and are excluded from the commit.

### Revision 4 remaining manual Windows checks and risks

No manual Windows visual check was claimed. Still check: selected and unselected bundled/custom selector entries; long AI-Slop titles at narrow widths; **Fallback lesson number icons** on Lessons; Theme-colored and Four-color circles in both themes; preference confirmation/reload; explicit custom Lesson icons; Lesson and Lessons-link red → green after correcting the last real Error/Warning and green → red after introducing one; an empty/Error/Warning Guidebook's red border; Guidebook Draft blue-badge inheritance and simultaneous red plus blue; isolation from a clean Rounds branch; Draft badge independence; Info-only Lesson green; empty Lesson and first-valid-Round transition; passive ID ordering/copying at narrow widths; and the revision-4 first-run popup/show-once behavior.

The remaining automated risk is the one non-reproduced full-suite failure documented above plus the inherited 72 analyzer findings. No 226.03, future Guidebook roadmap, Custom Exercise Template or Napoletano work was started, and nothing was pushed.

## 226.02 corrective revision 3 closure

Revision 3 was recovered from an interrupted working tree rooted at immutable parent `e2479d9600e407227e68a020fe920f21a9137280`. Recovery retained 38 modified tracked files and four intentional untracked implementation files, inspected the complete parent diff, and found no concurrent writer. The interrupted run's 109 focused, 197 combined and 785 full-suite results are historical context only; none is counted as fresh final-tree evidence below. A later ordinary `flutter test` launcher invocation also produced no output for 76 seconds and was interrupted; subsequent Flutter validation used the same SDK through its direct `flutter_tools.snapshot` entry point, with bounded output polling.

The final metadata is **Version 2.0.26 / Phase 226.02 / revision 3 / technical build 226023 / `2.0.26+226023`**. The first-run popup renders `Version 2.0.26` and `Phase 226.02, revision 3` on separate lines and retains its existing show-once persistence. The technical integer is not used as a human-readable phase label. Revision 3 does not extend the Alpha period: expiry remains **2026-10-06 23:59:59 local time**, the revision-2 value.

The completed revision-3 behavior is:

- The shared upper-right question-mark action, with tooltip exactly **`Editor Help`**, is present at Course Manager, Course Editor, Lessons, Lesson, the shared Round/Exercises screen, and Exercise Editor. All routes use the same Help destination. Opening and returning from Help does not save, draft, discard, weaken dirty-state decisions or lose an unsaved Exercise edit.
- The adjacent two-state internal-ID icon changes the shared device-local Editor preference immediately. Exact tooltips are **`Internal IDs shown. Tap to hide`** and **`Internal IDs hidden. Tap to show`**. The preference defaults off, persists outside Course JSON, and propagates across navigation and a reconstructed application service. Existing Lesson, Round and Exercise IDs are displayed read-only as secondary selectable monospaced text, with complete-ID tooltip/copy support and narrow-width protection; breadcrumbs do not gain IDs.
- A newly created Exercise displays its already-assigned ID before it has a nonnegative list index. Rename and Move retain the ID, Copy displays a fresh ID, and duplicate-title Exercises remain distinguishable by their different IDs.
- The reusable blue **Draft** badge is the sole visible Draft-state indicator. The prior `Draft · hidden from learner delivery` line is removed; the delivery explanation is in the badge semantics/tooltip. Zero Draft descendants produce no badge and no visible Draft wording. Audit border state remains independent, including simultaneous red plus blue.
- Error or Warning in an element or descendant produces a red border; absence of either produces luminous green; Info alone stays green; unavailable or stale Audit stays neutral. Sibling results remain isolated, and current candidate changes refresh ancestors live. The shared Audit Registry remains exactly **103 rules** with existing codes and severities.
- An empty Round shows exactly **`0 Exercises`**, no Draft state, and canonical Error `ROUND_CONTENT_EMPTY`, which propagates through its ancestors. Adding the first valid Exercise removes that empty state when no other Error or Warning remains. Round count text uses `0 Exercises`, `1 Exercise`, and plural counts.
- A zero-Round Lesson shows exactly **`0 Rounds`**, has no Draft state, and receives a red Audit border from canonical Warning `LESSON_ROUNDS_EMPTY`. Its red-bordered Rounds link remains usable. A behavioral UI test creates the first valid Round through that link, returns through the real route stack, and verifies live Lesson, Lessons-link and Course ancestor refresh. Existing one/two-Round Info guidance and severities remain unchanged.
- The top-level management page is consistently named **Course Manager**; the page for one course remains **Course Editor**. User-facing Settings, unlock, Credits, Help, Info, breadcrumb, button, tooltip, accessibility and documentation references were reconciled without renaming internal classes or routes.
- The deterministic temporary sample titles are exactly:
  - `AI-Slop Demo: Dutch for English Speakers`
  - `AI-Slop Demo: Inglés para hispanohablantes`
  - `AI-Slop Demo: Finnish for English Speakers`
  - `AI-Slop Demo: German for English Speakers`
  - `AI-Slop Demo: Italian for English Speakers`
  - `AI-Slop Demo: Korean for English Speakers`
  - `AI-Slop Demo: Portuguese for English Speakers`
  - `AI-Slop Demo: Spanish for English Speakers`
  - `AI-Slop Demo: Welsh for English Speakers`
- Per the user's authoritative classification, only these nine are described as AI-generated, unreviewed demonstrations rather than reliable learning courses. Info, Credits and sample documentation state that real QQL course content is intended to be authored and reviewed by humans; other bundled, official and custom courses are not generalized into this classification. Course IDs, filenames, language metadata, hierarchy, exercises, attribution, licensing and provenance remain intact.
- **Fallback lesson icon style** affects only the automatic fallback used when a Lesson has no explicit icon. Monochrome applies the current theme tint; Colored preserves the fallback's original multicolored presentation. The preview updates immediately, the saved choice reloads, actual Editor and learner fallback rendering follows the setting, and explicitly selected custom icons remain unchanged. No model field, JSON format or imported image byte changed.
- Rename Round retains **`Title, or Enter to skip`** and Enter without replacement text preserves an existing title. Intentional untitled Rounds remain supported.

Course Model v6, importer and persistence formats, course identity/provenance, official read-only/licensed-fork behavior, unsaved Preview, dirty navigation, Move/Copy transactions, publication rules, learner state and learner behavior remain unchanged. No Guidebook change, 226.03 feature, Custom Exercise Template or Napoletano sample was started.

### Revision 3 fresh verification

Commands were run from the repository root. Flutter commands used `--no-pub`, one process at a time, through the installed SDK's direct `flutter_tools.snapshot` entry point after the wrapper stall:

```text
dart format <27 changed Dart files>
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/alpha_lifecycle_test.dart test/app_metadata_225_04_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/course_audit_report_225_test.dart test/course_editor_224_test.dart test/course_editor_layout_regression_test.dart test/course_official_provenance_225_04_test.dart test/editor_diagnostics_226_02_revision3_test.dart test/exercise_workflow_226_02_test.dart test/korean_production_discovery_225_03_test.dart test/leaderboard_navigation_test.dart test/learner_round_path_test.dart test/lesson_metadata_and_icon_test.dart
flutter test --no-pub --reporter expanded --timeout 60s --plain-name "all nine bundled sources have verified immutable provenance" test/course_official_provenance_225_04_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
python tools/validate_courses.py
python tools/regenerate_bundled_courses_225_02.py --check
python tools/validate_lesson_icons.py
python tools/validate_images.py
git diff --check
```

Exact fresh results:

- Dart formatting completed successfully for all 27 changed Dart files before final validation.
- Combined affected focused run: **157 passed / 1 failed**. The sole failure was the stale pre-rename nine-title fixture, not application behavior. After correcting only that expected title set, the exact failed test rerun was **1 passed, exit 0**. All **158 distinct affected focused tests** are therefore green on the final code/test tree.
- Analyzer: **exit 1, 72 findings**. Baseline `e2479d9600e407227e68a020fe920f21a9137280` has **72 findings**; final revision 3 has **72**; **inherited 72, new 0, resolved 0**. The current findings are 71 inherited `curly_braces_in_flow_control_structures` infos in unchanged files and one inherited `unused_element` warning at `test/guidebook_sentence_generator_test.dart:255`. No finding is in a revision-3 changed file, and the analyzer is not described as passing.
- Complete Flutter suite, executed exactly once after the final production/test edit: **789 passed, exit 0, 8m43s**.
- Bundled-course validator: **9 bundled Course Model v6 files validated, exit 0**, including official checksum verification.
- Deterministic generator/checksum validation: **all 9 generated files and hashes verified, exit 0**.
- Lesson-icon validator: **14 assets, 0 issues, exit 0**.
- Image Bank validator: **112 assets, 0 issues, exit 0**.
- `git diff --check`: **exit 0, no whitespace errors**; Git emitted only working-copy LF/CRLF notices.

### Revision 3 changed files

```text
AGENTS.md
CHANGELOG.md
README.md
assets/courses/dutch_en.json
assets/courses/english_es.json
assets/courses/finnish_en.json
assets/courses/german_en.json
assets/courses/italian_en.json
assets/courses/korean_en.json
assets/courses/portuguese_en.json
assets/courses/spanish_en.json
assets/courses/welsh_en.json
docs/226_02_VALIDATION.md
docs/COURSE_EDITOR.md
docs/LICENSING.md
docs/SAMPLE_COURSE.md
lib/screens/course_editor_screen.dart
lib/screens/course_projects_screen.dart
lib/screens/credits_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/home_screen.dart
lib/screens/info_screen.dart
lib/screens/official_course_inspection_screen.dart
lib/screens/settings_screen.dart
lib/services/alpha_lifecycle_service.dart
lib/services/app_metadata.dart
lib/services/editor_display_preferences.dart
lib/widgets/editor_app_bar_actions.dart
lib/widgets/lesson_fallback_icon.dart
pubspec.yaml
test/alpha_lifecycle_test.dart
test/app_metadata_225_04_test.dart
test/authoring_hierarchy_indicators_226_02_test.dart
test/authoring_transfer_ui_226_02_test.dart
test/course_audit_report_225_test.dart
test/course_editor_224_test.dart
test/course_editor_layout_regression_test.dart
test/course_official_provenance_225_04_test.dart
test/editor_diagnostics_226_02_revision3_test.dart
test/exercise_workflow_226_02_test.dart
test/korean_production_discovery_225_03_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/lesson_metadata_and_icon_test.dart
tools/regenerate_bundled_courses_225_02.py
```

### Remaining manual Windows checks

No manual visual verification is claimed. Check the Help icon at every Editor level; returning from Help with unsaved edits preserved; immediate ID toggling at every level; exact tooltips `Internal IDs shown. Tap to hide` and `Internal IDs hidden. Tap to show`; ID readability/copying; duplicate-title identification; narrow layouts; Course Manager versus Course Editor wording; all nine exact AI-Slop Demo titles; absence of zero-Draft wording; red and green border visibility; blue Draft-badge readability; simultaneous red border and blue badge; last-descendant propagation removal; empty-Round presentation; empty-Lesson Rounds-link use and live transition; Monochrome versus Colored fallback icons; light and dark themes; and first-run popup appearance/show-once behavior.

## 226.02 corrective revision 2 closure

This revision uses commit `eb74144c1897f34912449cef86938816c87e21e8` as its immutable parent and advances only the technical platform build from `2.0.26+226021` to **`2.0.26+226022`**. User-facing metadata is represented explicitly as **Version 2.0.26 / Phase 226.02 / revision 2**; the integer `226022` remains a monotonic platform build number. The correction date is still 2026-09-06, so the checked thirty-day Alpha policy expires at **2026-10-06 23:59:59 local time**. Course Model v6, persistence formats, course identity, importer formats, learner progress and publishing rules remain unchanged.

The final 226.02 status behavior is:

- A current authoring branch receives a **red border** when its shared Audit result contains an Error or Warning at that element or any descendant. Error and Warning severities remain unchanged; only Error remains blocking for publication.
- A current branch receives a **luminous green border** when it contains neither Error nor Warning. Info alone permits green. A missing or unavailable Audit result uses the existing neutral presentation rather than claiming green.
- One reusable blue **Draft** badge marks a Draft Exercise and propagates independently through its Round, Lesson, Course and hierarchy links. Red or green Audit borders and the Draft badge remain simultaneously visible.
- An empty Round uses the canonical Error-level `ROUND_CONTENT_EMPTY` Audit finding, shows exactly `0 Exercises`, and has no zero-Draft label or Draft badge. Adding valid Content removes that state after the shared candidate Audit refresh when no other Error or Warning remains.
- Rename Round uses exactly **`Title, or Enter to skip`**. Enter retains a titled Round's current title when no replacement is supplied, and leaves a new or existing untitled Round untitled.
- The first-run popup displays **`Version 2.0.26`** and **`Phase 226.02, revision 2`** on separate lines. Its existing `technicalVersion`-keyed one-time persistence remains intact; `226022` is not shown as a human-readable phase label.

The hierarchy derives both Audit and Draft state from the current candidate and the shared `CourseAuditService` result. No persistent UI flags, duplicate Audit rules or element-specific status calculation were introduced. The canonical 103-rule registry and all existing rule severities remain unchanged.

### Revision 2 verification

Commands were run from the repository root with the installed Flutter SDK and `--no-pub` for tests and analysis:

```text
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/authoring_hierarchy_indicators_226_02_test.dart test/authoring_audit_ui_224_test.dart test/authoring_transfer_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/app_metadata_225_04_test.dart test/alpha_lifecycle_test.dart
flutter test --no-pub --reporter expanded --timeout 60s --plain-name "Welcome popup keeps its yellow and blue palette in dark mode" test/leaderboard_navigation_test.dart
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/audit_code_registry_226_02_test.dart test/audit_codes_screen_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/course_authoring_transfer_226_02_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/exercise_creation_wizard_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/course_editor_export_226_02_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
python tools/validate_courses.py
python tools/validate_lesson_icons.py
python tools/validate_images.py
dart format <all changed Dart files>
git diff --check
```

Exact final results:

- Revision-2 correction set: **66 passed, exit 0, 1m50s**. This includes the full red/green/blue status matrix, Warning inheritance, sibling isolation, empty-Round Error/transition, Rename Round Enter behavior, explicit metadata and Alpha-expiry policy.
- Focused first-run popup: **1 passed, exit 0, 4s**. It verifies the two human-readable lines, excludes malformed `22621` and the platform integer `226022`, and confirms the Welcome notice does not reappear after rebuilding Home with its seen key set.
- Complete established 226.02 focused set: **168 passed, exit 0, 3m49s**.
- Analyzer: **exit 1, 72 findings**. Parent `eb74144c1897f34912449cef86938816c87e21e8` has **72 findings**; current has **72**; **new 0, resolved 0, inherited 72**. None is in a file changed by revision 2. The result is not described as passing.
- Complete Flutter suite: **778 passed, exit 0, 8m39s**.
- Course validator: **9 bundled Course Model v6 files validated, exit 0**.
- Lesson icon validator: **14 assets, 0 issues, exit 0**.
- Image validator: **112 assets, 0 issues, exit 0**.
- Dart formatting: **14 files formatted, 0 changed, exit 0** on the final formatting run.
- `git diff --check`: **exit 0, no whitespace errors**.

Manual Windows checks remain: red and luminous-green visibility in both light and dark themes; blue Draft-badge readability; simultaneous red border plus blue Draft badge at every hierarchy level; ancestor propagation and removal after the last descendant issue or Draft is resolved, moved or deleted; empty-Round presentation and transition after adding the first valid Exercise; and first-run popup appearance and show-once behavior. These visual/device checks were not represented as passed by widget tests. Audio behavior was outside this correction and no new audio risk is introduced.

No Guidebook work or 226.03 feature was started.

## 226.02.1 corrective follow-up closure (historical; superseded by revision 2 status presentation)

The corrective follow-up uses local `main` commit `718bbb3856e88d8780c4b52b91d479ac431f71bb` as its immutable parent. Metadata advances within tranche 226.02 to **Version 2.0.26 / Build 226.02.1 / `2.0.26+226021`**. The correction date is 2026-09-06, so the existing thirty-day Alpha policy expires at **2026-10-06 23:59:59 local time**. Course Model v6 and every persistence format remain unchanged.

The follow-up closes these six requested areas:

- **Audit Codes:** the Technical Reference link has no subtitle. The unchanged shared 103-rule registry is displayed in Errors, Warnings, Info order. Three independent filters start selected, support every one/two/three-category combination, and constrain text search without copying definitions into the UI.
- **Hierarchy indicators:** this follow-up introduced candidate-derived hierarchy propagation. Revision 2 above replaces its original color mapping with the final red/green Audit border and independent blue Draft badge.
- **Round and hierarchy presentation:** this follow-up introduced compact Rename Round field guidance and shared Rounds/Lessons link typography. Revision 2 above supplies the final field text and Enter behavior.
- **Course page and export:** the Course-specific three-dot menu and its Audio Library, Image Bank, temporary-sample and export branches are removed. Audio Library and Image Bank remain page entries. Export Course JSON is the final entry for a custom course opened through the existing local-course authoring path, including a licensed custom fork; it is absent for bundled/external official sources and custom courses outside that path. The model has no separate export-permission or team-source field, so the correction does not infer one from licence text: imported team-supplied custom JSON is indistinguishable from other local custom JSON. Export reuses `CustomCourseTransferService.exportCourse`, preserves all v6 provenance/authorship/lineage/licence data, includes course media metadata/references, and does not embed MP3 bytes. Verified backup recording-copy behavior is unchanged.
- **Field Help:** the existing centralized mechanism now gives Prompt and Question distinct meanings and examples and adds concise field-specific examples for line formats, paired values, accepted answers and relative image paths. Audio fields remain spoken text fields rather than invented file-path inputs. All 20 current presets still resolve their mounted fields through the one registry.
- **Scope:** unsaved Preview, dirty navigation, Move/Copy transaction semantics, official read-only/fork policy, matching-pair input rejection, learner behavior, Audit severities/codes and removal of missing-Reading guidance are unchanged. No Guidebook goal/further-reading/link scaffold and no 226.03 feature was started.

### Corrective verification

Commands were run from the repository root with the installed Flutter SDK and `--no-pub` for analysis/tests:

```text
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/audit_codes_screen_226_02_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/course_editor_export_226_02_test.dart test/exercise_workflow_226_02_test.dart test/course_editor_224_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s test/audit_code_registry_226_02_test.dart test/audit_codes_screen_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/course_authoring_transfer_226_02_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/exercise_creation_wizard_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/course_editor_export_226_02_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
python tools/validate_courses.py
python tools/validate_lesson_icons.py
python tools/validate_images.py
dart format <all changed Dart files>
git diff --check
```

Exact results:

- Corrective focused set: **104 passed, exit 0, 1m33s**.
- Established 226.02 focused set plus the two new suites: **163 passed, exit 0, 1m48s**.
- Analyzer: **exit 1, 72 findings**. Parent `718bbb3` has **72 findings**; current has **72**; **new 0, resolved 0**. No finding is in a file changed by this corrective follow-up. The result is not described as passing.
- First full-suite attempt: **768 passed / 5 failed, exit 1, 7m18s**. All failures were test/layout assumptions exposed by the new hierarchy wrappers: three direct `ListTile` casts and two eagerly-built Lesson metadata controls. Stable-key assertions and zero-margin hierarchy-link Cards corrected those assumptions without changing the requested behavior.
- Final complete Flutter suite: **773 passed, exit 0, 7m25s**.
- Course validator: **9 bundled Course Model v6 files validated, exit 0**.
- Lesson icon validator: **14 assets, 0 issues, exit 0**.
- Image validator: **112 assets, 0 issues, exit 0**.
- Dart formatting: all changed Dart files formatted; final verification reported no formatting change.
- `git diff --check`: **exit 0, no whitespace errors**.

Automated narrow-width coverage exercises Audit filters, Rename Round, Course/Lesson hierarchy links, Prompt/Question tooltips and existing responsive authoring screens at 320 px. The authoritative revision-2 manual list is above. The prior export and layout smoke checks remain recommended before release. No package or release was created.

## Original 226.02 tranche validation (historical)

The sections below preserve the validation record for the original 226.02 tranche as it stood immediately before commit `718bbb3856e88d8780c4b52b91d479ac431f71bb`. Current corrective-follow-up metadata, results and residual manual checks are authoritative in the closure section above.

### Contract and immutable baseline

Only **226.02: Editor workflow, navigation, field help and Audit UX** is implemented, under the complete controlling `qql_226_prompt.txt` and the user's explicit 226.02 instructions. The clean baseline was checked before editing:

```text
git status --short       (no output)
git rev-parse HEAD       45cf258d707c89d512f7663d9f2fa317adbe5ef0
git rev-parse origin/main 45cf258d707c89d512f7663d9f2fa317adbe5ef0
git diff --check         (no output; exit 0)
```

No baseline reset, stash, amend or reconstruction occurred during the original tranche. At that pre-commit point, HEAD and origin/main remained that parent and the index contained no staged content. No push, package, Windows release build or release was created. **226.03 remained unstarted.**

The original candidate metadata was **Version 2.0.26 / Build 226.02 / `2.0.26+22602`**. Alpha expiry was **2026-10-05 at 23:59:59 local time**, following the existing thirty-day policy from the same September 5 candidate date. The Alpha implementation's date was unchanged; its comment and test label identified that tranche.

### Final independent-review corrections

All four low-severity findings from the independent read-only review were corrected before commit:

- **Lesson breadcrumb after Rename:** the Lesson editor replaces the corresponding Course snapshot Lesson by stable `lessonId` before building breadcrumbs. The renamed title now appears immediately. The regression uses duplicate Lesson titles and verifies the intended Lesson by ID, without weakening the dirty-state guard.
- **Singular Draft wording:** one shared label helper now renders `1 Draft Exercise` and pluralizes every other count. All five newly introduced Course/Lesson/Round count presentations use it; their calculations, live refresh, colors and placement are unchanged.
- **MP3 importer documentation:** Help and Course Editor documentation now state that physical MP3 files are grouped by `learningLanguage`; metadata and references belong to the Course; verified backups copy referenced recordings; and Course JSON stores metadata/local paths rather than MP3 bytes. Import and storage code are unchanged.
- **Audit pair trigger descriptions:** `AUDIO_MATCH_PAIR_EMPTY` and `MATCH_PAIR_EMPTY` now document exactly what their predicates see: a blank value in a surviving two-entry pair. Their predicates, model getters, codes and severities are unchanged, and Help consumes the corrected registry text.

## Implementation by requirement

| Requirement | Result and boundary |
|---|---|
| Unsaved Exercise Preview | One `_buildCandidate` path supplies Save, Draft and Preview for every preset. Preview reads current controllers, contextual mode, correct-translation entries and image selection without calling Save. It retains the original publication state/timestamp, audits runtime validity and pushes detached Course/Lesson/Round objects to `RoundScreen(previewMode: true)`. New, Draft, Published, Wizard and generated normal-editor entry points provide the same runtime context. |
| Previous / Next | IDs locate the active Exercise in the current Round's ordered snapshot. End buttons are disabled; new unsaved or not-yet-in-Round candidates have no misleading destination. Save updates sibling values in the same parent working copy. Back and navigation share Keep editing / Discard changes / Save as draft / Save protection. Cursor selection changes alone are not edits. |
| Breadcrumbs | `EditorBreadcrumbs` derives labels and ordinals from current Course data and stable IDs. A renamed Lesson is merged into the supplied Course snapshot by `lessonId`, so its label refreshes immediately and duplicate titles remain safe. Wrap handles narrow layouts. A parent link is enabled only when that route actually returns to the labelled parent; other levels remain readable context. Exercise links use the unsaved guard. |
| Move / Copy | Explicit destinations select Course > Lesson > Round for Exercises and Course > Lesson for Rounds, within the current custom course. Move preserves identity, content, metadata and state. Copy delegates to the existing duplication/remapping implementation and creates fresh Draft subtrees. No destination is applied until confirmation in the chooser. |
| Field Help | A central 38-meaning registry covers all 20 current presets. Every applicable field, including contextual mode, dynamic correct-translation rows and image controls, has a tooltip and direct Help action. Shared text explains purpose, entry shape, syntax, limits and examples. Broad Help and the existing Type the translation syntax page remain. |
| Validation clarity | Known Audit messages identify the field and action without changing their existing conditions or severities. Correct-answer indices and duplicate literal translations have actionable messages. A malformed matching-pair line is identified and retained in the form, rather than silently omitted from Preview/Save. |
| Importer instructions | Documentation was checked against LessonIconService, FlagService, ExerciseImageService, ImageBankService, RecordedAudioService, CourseEditorService and course backups. It distinguishes portable embedded flags/Lesson icons from local exercise image/audio paths and explains actual formats, limits, transformation and errors. Physical MP3 storage is correctly described as grouped by learning language, while Course metadata/references and verified backup copying remain Course-specific. No import behavior changed. |
| Untitled Rounds | Create and Rename accept an empty title, show “Press Enter to keep this Round untitled.”, and submit that empty value on Enter. Round N remains a display fallback; no fake stored title is introduced. |
| Draft indicators | This original implementation was superseded by revision 2's shared blue Draft badge and independent red/green Audit border. |
| Draft counts | Course total and Lesson counts are calculated from the same working-copy content; they are not persisted or independently cached. A shared formatter renders `1 Draft Exercise` and pluralizes zero and all other values across all five presentations. Add, delete, Save/Draft, publish, duplicate, Move and Copy flow through the existing state updates. |
| Audit Codes | Searchable Course Help technical reference uses the same immutable 103-rule registry as CourseAuditService. Each definition includes code, severity, scope, meaning, trigger, creator action and blocking status. Known findings cannot routinely use GENERAL. |
| Missing Reading guidance | The entire `readingCount == 0` finding block is deleted. There is no downgraded Info equivalent. Actual malformed Reading and Listening findings remain, and missing Listening guidance remains absent. |

The all-preset Preview contract exposed two narrowly related existing problems: Listening Spelling's saved accepted answers were loaded into the wrong field, and the shared Preview runtime applied learner TTS skipping / read learner completion. Hydration now uses accepted answers for that preset on initial entry and sibling navigation. Preview bypasses learner skipping and completion reads; normal learner paths retain their existing behavior.

## Architecture, persistence and clean-cut implications

`CourseAuthoringTransferService` is a synchronous, testable authoring transformation returning a replacement Course. It rejects official courses, missing or ambiguous source/destination IDs, same-source moves and copy ID collisions. It imports no storage, preferences, learner-progress or UI service. `AuthoringDuplicationService.duplicateContent` reuses the existing allocation/remapping implementation and retains v6 wrapper metadata. Nested normalization data are detached so editing a copy cannot mutate its source.

The existing nested editor route stack carries an updated Course callback solely to propagate destination changes across Lesson boundaries. Top-level `CourseEditorTransaction` remains the only persistence/confirmation boundary. Cancelling the course discards all pending transfers; successful confirmation retains the existing single version increment and verified backup semantics. Imported Lesson icon assets and other destination changes survive every parent return. Unchanged text, lesson-intro and Presentation content retain original order, metadata and media; source Round timestamps survive transfer return.

The obsolete pending Exercise clipboard UI and its now-unreferenced `exercise_transfer_service.dart` are removed. No cross-course clipboard or learner movement state replaces them. Shared immutable artwork/audio references remain references.

**No Course Model change:** formatVersion remains 6; no new JSON fields, persistence keys, migrations, storage namespaces, backup formats or dependencies are introduced. Learner backup remains v2. No XP, streak, Weekly XP, Laurel, Review, completion, Duel, progression or learner-identity write is added. Course-level Cancel does not erase existing learner state.

The 226.01 official read-only/licensed-fork clean cut is unchanged. No official override loader, migration, conversion or local editing route is reintroduced. Transfer service guards also reject official sources. Original fork authorship/provenance, explicit derivative policy and official-update independence retain their existing implementation and regression coverage. The two accepted 226.01 low-severity observations remain untouched: duplicate current official release presentation in Version History and the unreachable obsolete official conditional in `Course.fork()`.

No 226.03 answer-expansion UI/feedback, new presets, optional Duels, Section management, Lesson style change, scaffolding, World Flag selector, templates, Course Issues or Neapolitan sample is included.

## Focused coverage and automated evidence

| Tests | High-risk coverage |
|---|---|
| `exercise_workflow_226_02_test.dart` | New unsaved Preview; Draft/Published and every canonical model; contextual/Build translation/listening; unsaved values and publication; exact Course JSON and all preferences unchanged; no authoring clock/save callback; completion with zero learner writes; no-active-profile audio Preview despite TTS skipping; navigation order/boundaries/save/discard; breadcrumb guard; immediate renamed-Lesson refresh with duplicate-title stable-ID resolution; malformed pair diagnostics; empty Round Enter. |
| `course_authoring_transfer_226_02_test.dart` | Move/copy for canonical models and Presentation/text; IDs, references, metadata, nested copy independence, custom-only guard, collisions, source immutability; real transaction Cancel and one final Confirm with version/backup. |
| `authoring_transfer_ui_226_02_test.dart` | Actual destination menus within/across Lessons; cancelled chooser; destination reset; multiple transfers through nested return stack; text/intro/Presentation metadata/order; returned timestamp; Round Move/Copy; live singular/plural counts and simultaneous independent Audit/Draft status. |
| `exercise_field_help_226_02_test.dart` | All semantic definitions, shared canonical meanings, accepted-answer parser examples and distinctions from literal Arrange/missing-word lists; importer documentation contract for language-grouped MP3 files, Course-owned references, verified backup copying and non-embedded bytes. |
| `exercise_field_help_ui_226_02_test.dart` | All 20 actual preset forms and every mounted field; context conditional fields; dynamic translation rows; syntax Help; Light/Dark at 320/375/430/1100 px. |
| `audit_code_registry_226_02_test.dart` | Complete known rule inventory, specific identities/severities, no routine GENERAL, exact matching-pair trigger descriptions, search, missing Reading/Listening absence and malformed existing comprehension validation. |
| `audit_codes_screen_226_02_test.dart` | Every definition rendered from the registry, search by code/text and Light/Dark reference layouts at 320/375/430/1280 px. |
| Existing regressions | Custom course transactions, confirm/cancel/backups, Course Model v6, duplication, official storage/forks/UI, Wizard/generator/editor, Lesson icons, responsive learner rendering, XP/progress, metadata and Alpha policy. |

The new seven test files contain **141 cases**. Existing test changes follow deliberate UI contracts: the guarded Exercise Back decision, singular/plural Draft counts, independent nested borders, lazy list scrolling, shared syntax Help and current tranche metadata. They do not weaken validation or alter working production behavior to satisfy tests.

Final correction-focused results: **67 cases passed (exit 0, 41s)** across the workflow, transfer UI, Audit registry and field Help/documentation suites. The complete 226.02 focused set then passed **144 cases (exit 0, 2m00s)**, and the complete Flutter suite passed **753 cases (exit 0, 6m56s)**. The complete focused run includes every new 226.02 test plus the existing Wizard suite. Formatting reports all 31 touched Dart files clean (exit 0); dependency resolution exits 0. **No test failure remains.**

Final focused command:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/audit_code_registry_226_02_test.dart test/audit_codes_screen_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/course_authoring_transfer_226_02_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/exercise_creation_wizard_test.dart
```

Required command forms:

```text
dart --suppress-analytics format <all 31 touched existing/new Dart files>
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
python tools/validate_courses.py
python tools/validate_lesson_icons.py
python tools/validate_images.py
git diff --check
git status --short
```

Executables: `C:\Users\ansa\flutter\bin\flutter.bat`, `C:\Users\ansa\flutter\bin\cache\dart-sdk\bin\dart.exe`, and the environment's Python 3.14. Direct Dart formatting uses `--suppress-analytics` so validation does not require a telemetry timestamp write outside the workspace.

## Analyzer comparison against the actual clean parent

The untouched repository's initial analyzer produced 73 findings (exit 1). For an independent same-environment comparison, every tracked blob of parent `45cf258d707c89d512f7663d9f2fa317adbe5ef0` was copied to a separate temporary directory and verified against its Git blob SHA-1. Only ignored package configuration was supplied, matching current resolved dependencies. Running `flutter analyze --no-pub` there again produced **73 findings, exit 1**. No parent commit or original workspace file was changed by this comparison.

Current analyzer: **72 findings, exit 1**. It is **not passing**.

| Category/file | Parent | Current |
|---|---:|---:|
| `lib/services/course_audit_service.dart` / curly braces Info | 68 | 67 |
| `lib/screens/flat_image_library_screen.dart` / curly braces Info | 3 | 3 |
| `lib/services/settings_service.dart` / curly braces Info | 1 | 1 |
| `test/guidebook_sentence_generator_test.dart` / unused `_tapAndSettle` Warning | 1 | 1 |
| Total | **73** | **72** |

**New: 0. Resolved: 1.** The resolved Info is the unbraced missing-Reading finding at parent `course_audit_service.dart:571`, removed with the obsolete rule. Findings were compared by severity/message/file/code with line shifts accounted for, not by remembering a prior count. Of the current findings, 67 are in a changed file (the Audit service); all 67 are inherited findings. No analyzer exclusions or lint suppressions are delivered.

`flutter pub get` completed successfully. The installed SDK automatically changed `matcher`, `meta`, `test_api` and `vector_math` lock entries and added analyzer exclusions. Those verified automatic tracked changes were removed as out of scope; `pubspec.lock` and `analysis_options.yaml` match the parent. The ignored resolution used for both the fresh parent analysis and final validation contains matcher 0.12.20, meta 1.19.0, test_api 0.7.12 and vector_math 2.4.2. This environment/reproducibility detail is disclosed; no dependency upgrade is proposed by this tranche.

## Validators and Audit evidence

- Course validator: **9 bundled Course Model v6 files, all OK, exit 0**.
- Lesson icon validator: **14 assets, 0 issues, exit 0**.
- Image validator: **112 assets, 0 issues, exit 0**. No asset or manifest changed; `hello.webp` remains absent.
- Real bundled Course Audit: **9 courses, aggregate 0 Errors / 0 Warnings / 0 Info** through the existing production bundled-course regression.
- Registry: **103 rules: 70 Error / 27 Warning / 6 Info**; baseline comparison confirms unchanged severities and conditions except deletion of missing Reading coverage. Each known emission references its registry definition; Help renders those same definitions. GENERAL remains only a defensive constructor default/copy fallback.
- No production `Round has no Reading comprehension exercise`, `readingCount` absence branch or replacement missing-Reading finding remains. Tests explicitly cover absence and malformed actual Reading/Listening.
- `git diff --check`: **exit 0; no whitespace errors**.

Ignored `build/22602/` retains the earlier implementation-run logs: initial and repeated parent analyzer logs, analyzer/JSON comparison, focused logs, the earlier 750-case full-suite log, formatting, dependency resolution, validators and repository-state capture. The post-review correction runs and exact 67/144/753-case results are recorded directly in this closure report and task output; the earlier full-suite log is not presented as the final correction run. Intermediate failures remain transparent: expected initial missing-Preview characterization, integration/test-scrolling fixes, and the first full run (**741 passed / 9 failed**) with stale structure/count/title/scroll assumptions. Only the latest successful results above establish completion.

## Complete changed-file list and file-by-file summary

**38 files: 23 modified tracked files, 1 deleted tracked file and 14 new files.**

| Status | File | Change |
|---|---|---|
| M | `AGENTS.md` | Records the 226.02 boundary and immutable parent; later tranches remain deferred. |
| M | `CHANGELOG.md` | 226.02 candidate entry, workflow/Audit changes, metadata and unchanged thirty-day expiry date. |
| M | `README.md` | Current Build 226.02 metadata and concise workflow scope; preserves the official-fork explanation. |
| ?? | `docs/226_02_VALIDATION.md` | This complete pre-commit report, command evidence, scope review and remaining manual risks. |
| M | `docs/COURSE_EDITOR.md` | Unsaved Preview/navigation, transactional transfers, Draft indicators/counts, Audit reference and verified artwork/import instructions. |
| ?? | `lib/screens/audit_codes_screen.dart` | Searchable responsive reference rendering every registry definition. |
| M | `lib/screens/course_editor_screen.dart` | Shared unsaved candidate/Preview, guarded sibling navigation and breadcrumbs; atomic destination integration; full content/timestamp propagation; contextual field Help, clear validation, untitled Round guidance and live Draft visuals/counts. |
| M | `lib/screens/editor_help_screen.dart` | Actual importer/portability guidance, current workflow and Draft-copy policy, existing broad syntax Help plus Audit Codes navigation. |
| M | `lib/screens/round_screen.dart` | Preview-only bypass of learner TTS skipping and completion reads; normal learner initialization/completion remains unchanged. |
| M | `lib/services/alpha_lifecycle_service.dart` | Updates only the candidate-build comment; actual expiry DateTime is unchanged. |
| M | `lib/services/app_metadata.dart` | Build label 226.02 and technical build 22602; release version remains 2.0.26. |
| ?? | `lib/services/audit_code_registry.dart` | Authoritative immutable 103-rule code/severity/scope/trigger/action/blocking registry and shared search. |
| M | `lib/services/authoring_duplication_service.dart` | Adds canonical Content-wrapper duplication using existing remapping; detaches nested normalization metadata. |
| M | `lib/services/course_audit_service.dart` | Definition-backed known rule identities and unchanged severities; removes Reading absence; eleven existing messages are actionable. |
| ?? | `lib/services/course_authoring_transfer_service.dart` | Pure custom-course Move/Copy transformations with stable/fresh IDs, canonical metadata, lookup/collision guards and no persistence. |
| ?? | `lib/services/exercise_field_help.dart` | Shared 38 field meanings and exact syntax/entry/validation examples for all current presets. |
| D | `lib/services/exercise_transfer_service.dart` | Deleted the unreferenced pending transfer clipboard implementation after replacing its editor paths. |
| ?? | `lib/widgets/authoring_destination_dialog.dart` | Explicit current-course destination selection; Cancel returns no mutation, and changing Lesson clears the Round selection. |
| ?? | `lib/widgets/editor_breadcrumbs.dart` | One ID-derived responsive hierarchy presentation with optional safe immediate-parent link. |
| M | `pubspec.yaml` | Technical version advances to 2.0.26+22602; no dependency constraints change. |
| M | `test/alpha_lifecycle_test.dart` | Updates the tranche label while preserving actual expiry boundary tests. |
| M | `test/app_metadata_225_04_test.dart` | Checks release/build/technical labels for 226.02. |
| ?? | `test/audit_code_registry_226_02_test.dart` | 9 new registry, exact pair-trigger, known emission, search and comprehension presence/malformed-content regressions. |
| ?? | `test/audit_codes_screen_226_02_test.dart` | 10 new full reference, search and responsive Light/Dark regressions. |
| M | `test/authoring_audit_ui_224_test.dart` | Preserves scoped Audit presentation coverage; revision 2 updates the assertion to the final Error-or-Warning red / clear green semantics. |
| ?? | `test/authoring_transfer_ui_226_02_test.dart` | 20 new real destination, cancellation, nested propagation, v6 preservation and Draft visual/count regressions. |
| M | `test/course_audit_report_225_test.dart` | Checks current build labels in Audit reports. |
| ?? | `test/course_authoring_transfer_226_02_test.dart` | 33 new pure transfer, all-model IDs/metadata, deep copy, guards and real transaction/version/backup regressions. |
| M | `test/course_editor_224_test.dart` | Checks the compact Course Lessons row including its current Draft Exercise count. |
| M | `test/course_editor_225_test.dart` | Checks the clearer duplicate-translation error without weakening duplicate validation. |
| M | `test/exercise_creation_wizard_test.dart` | Preserves Wizard Save/Preview/Finish checks using labelled fields and settled lazy-list scrolling. |
| ?? | `test/exercise_field_help_226_02_test.dart` | 12 new central semantics, accepted-answer syntax and MP3 documentation-contract regressions. |
| ?? | `test/exercise_field_help_ui_226_02_test.dart` | 31 new all-preset field-control and responsive Help regressions. |
| ?? | `test/exercise_workflow_226_02_test.dart` | 26 new unsaved Preview/no-write, navigation/guards, renamed-Lesson/stable-ID breadcrumb, empty Round and validation regressions. |
| M | `test/leaderboard_navigation_test.dart` | Updates the already-seen Welcome notice fixture for the new technical version. |
| M | `test/learner_round_path_test.dart` | Updates the already-seen Welcome notice fixture for the new technical version. |
| M | `test/lesson_metadata_and_icon_test.dart` | Uses the actual icon-field destination instead of a fixed scroll offset after breadcrumb/count insertion. |
| M | `test/production_course_transaction_225_04_test.dart` | Requires an explicit discard decision on Exercise Back while retaining the full transaction/save/backup assertions. |

## Exact diff stat

The following is literal `git diff --stat` output. Git excludes untracked additions from this command; every new file is included in the complete table and status below, and is part of the reviewed tranche.

```text
 AGENTS.md                                          |    1 +
 CHANGELOG.md                                       |    9 +
 README.md                                          |    6 +-
 docs/COURSE_EDITOR.md                              |   37 +-
 lib/screens/course_editor_screen.dart              | 1013 ++++++++++++++++----
 lib/screens/editor_help_screen.dart                |   43 +-
 lib/screens/round_screen.dart                      |   13 +-
 lib/services/alpha_lifecycle_service.dart          |    2 +-
 lib/services/app_metadata.dart                     |    4 +-
 lib/services/authoring_duplication_service.dart    |   11 +-
 lib/services/course_audit_service.dart             |  425 ++++-----
 lib/services/exercise_transfer_service.dart        |   42 -
 pubspec.yaml                                       |    2 +-
 test/alpha_lifecycle_test.dart                     |    2 +-
 test/app_metadata_225_04_test.dart                 |    8 +-
 test/authoring_audit_ui_224_test.dart              |   14 +-
 test/course_audit_report_225_test.dart             |    4 +-
 test/course_editor_224_test.dart                   |    2 +-
 test/course_editor_225_test.dart                   |    2 +-
 test/exercise_creation_wizard_test.dart            |   36 +-
 test/leaderboard_navigation_test.dart              |    2 +-
 test/learner_round_path_test.dart                  |    2 +-
 test/lesson_metadata_and_icon_test.dart            |    7 +-
 .../production_course_transaction_225_04_test.dart |    6 +-
 24 files changed, 1176 insertions(+), 517 deletions(-)
```

## Manual checks, review and risks

The complete production/documentation/test diff was inspected for requirement scope, obsolete branches, comments, metadata and generated/debug artifacts. Transfer order, wrapper/media preservation, nested destination propagation, Preview and unsaved guards received independent read-only reviews. The four reported low-severity findings were corrected and covered as listed above. New registries and helpers remain bounded to the authoring workflow. No generated files, temporary logs, baseline copies, debug code, broad reformatting, analyzer-policy edits or unrelated assets are included. The two automatically changed tracked Flutter files were content-verified and restored; no content was staged.

**Native manual checks actually performed: none.** Automated widget/layout interactions are not described as manual device testing. Still recommended before release: Windows keyboard/Back and 320 px/light/dark review with long real course titles; actual TTS/recorded-audio/image Preview and return; real importer error/portability paths; and a device course-confirm/cancel/restart/export smoke check after cross-Lesson transfers. No Windows executable was built in this tranche.

Known remaining risks are the inherited 72 analyzer findings, platform/media behavior not manually exercised, and the installed SDK's dependency-resolution drift described above. The explicitly accepted 226.01 low-severity observations remain. Native media coverage is partly mocked; automated structural and no-write evidence does not substitute for listening to actual recordings. There is no known unresolved 226.02 implementation defect or design question at delivery.

## Exact repository state before local commit

```text
 M AGENTS.md
 M CHANGELOG.md
 M README.md
 M docs/COURSE_EDITOR.md
 M lib/screens/course_editor_screen.dart
 M lib/screens/editor_help_screen.dart
 M lib/screens/round_screen.dart
 M lib/services/alpha_lifecycle_service.dart
 M lib/services/app_metadata.dart
 M lib/services/authoring_duplication_service.dart
 M lib/services/course_audit_service.dart
 D lib/services/exercise_transfer_service.dart
 M pubspec.yaml
 M test/alpha_lifecycle_test.dart
 M test/app_metadata_225_04_test.dart
 M test/authoring_audit_ui_224_test.dart
 M test/course_audit_report_225_test.dart
 M test/course_editor_224_test.dart
 M test/course_editor_225_test.dart
 M test/exercise_creation_wizard_test.dart
 M test/leaderboard_navigation_test.dart
 M test/learner_round_path_test.dart
 M test/lesson_metadata_and_icon_test.dart
 M test/production_course_transaction_225_04_test.dart
?? docs/226_02_VALIDATION.md
?? lib/screens/audit_codes_screen.dart
?? lib/services/audit_code_registry.dart
?? lib/services/course_authoring_transfer_service.dart
?? lib/services/exercise_field_help.dart
?? lib/widgets/authoring_destination_dialog.dart
?? lib/widgets/editor_breadcrumbs.dart
?? test/audit_code_registry_226_02_test.dart
?? test/audit_codes_screen_226_02_test.dart
?? test/authoring_transfer_ui_226_02_test.dart
?? test/course_authoring_transfer_226_02_test.dart
?? test/exercise_field_help_226_02_test.dart
?? test/exercise_field_help_ui_226_02_test.dart
?? test/exercise_workflow_226_02_test.dart
```

HEAD and origin/main: `45cf258d707c89d512f7663d9f2fa317adbe5ef0`.

The working tree intentionally contains this approved uncommitted tranche. The index is empty before the authorized staging step. Nothing has been pushed, packaged or released. **226.03 remains unstarted.**

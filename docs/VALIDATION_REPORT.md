# QuisquisLingo 2.0.19+219 release validation report

Date: 31 August 2026

## Baseline and release boundary

- Build 219 work began from commit `74e054d` (`2.0.18+218`).
- The target package version is `2.0.19+219`.
- The mandatory 30-day Alpha lifecycle expires at the end of 30 September 2026.
- Scope is limited to the Unified Learner Page's central Round path, its decorative mascot presentation, the persisted completed-Round icon accent, focused regression coverage and normal release metadata.
- The surrounding Top Bar, Lesson selector, continuous Lesson flow, bottom controls, progression, scoring, persistence formats, Duel rules, course model, editor behavior and desktop resize policy remain unchanged.
- The intentionally removed `assets/exercise_images/hello.webp` remains deleted. Production course image data and editor support are unchanged.

## Learner path implementation

- Round cards use a responsive maximum width of 276 px, a 108 px base height and a 28 px inter-row gap. Existing Round number, title, visual icon, audio indicator and status remain present.
- Round placement follows the deterministic repeating side pattern `R,L,R,L,L,R,L,R,R,L,L,R`, which uses both sides and includes balanced same-side pairs without changing Round order.
- A 2 px cubic path with rounded caps is painted behind the interactive content through the center of each Round card, including left/right transitions and same-side pairs. Its theme-derived `onSurfaceVariant` color is 50% opaque.
- Round surfaces are 75% opaque while text, icons, Laurel and interaction remain fully opaque.
- The old between-Round Lesson image widget is no longer constructed by the learner path.
- The existing course-scoped completed-Round ID set drives the yellow-orange icon background. Completion with errors, later repeats and page rebuilds retain the same accent without requiring a Laurel.
- Existing perfect-Round state still draws the established two-leaf Laurel around the icon. The leaves increase from 28 px to 34 px for clearer visibility; no Laurel, XP or completion logic changed.
- Genuine access locks remain Lesson-scoped under Course Model v4. A locked Lesson keeps its GuideBook, Rounds and Duel inaccessible unless existing genuine progress or IDDQD access permits them; no unsupported Round-level lock was added for validation.

## Mascot implementation

- The current mascot directory contains `cat-celebrating_tr.png`, `dog-laughing-pencil_tr.png`, `monkey-yawning_tr.png`, `qql-dog-tambourine.png` and `qql-monkey-sleeping.png`.
- `pubspec.yaml` registers the `assets/mascots/` directory. Production loads Flutter's `AssetManifest`, filters PNG paths under that directory, removes duplicates and sorts the complete asset set before applying the course-specific shuffle.
- Decorative slots are selected independently from Round sides. Each mascot is positioned on the free side opposite its nearby Round, and early slots demonstrate both left and right placement.
- Mascot selection uses a deterministic shuffle derived from the immutable `courseId`. The same course retains the same order, different course IDs normally produce different orders, and no separate preference is persisted.
- The shuffled list exhausts the unique available set before cycling, avoiding consecutive reuse when at least two distinct assets exist and continuing to support later list additions.
- Mascots use `BoxFit.contain`, 10 px internal padding, external separation from Round cards, `IgnorePointer` and `ExcludeSemantics`.
- The image remains fully opaque. Only the theme-derived surrounding surface uses 50% alpha in light and dark modes.
- Invalid assets collapse to an empty decoration without a broken-image placeholder. Mascots are omitted below the supported 280 px path width so the Round path retains priority.

## Supporting nodes and dark theme

- GuideBook and Duel remain centered and use 88% of the available width up to a 400 px constraint, with reduced padding and icon sizes. Their content, tap behavior and availability logic are unchanged.
- Round, GuideBook and Duel background surfaces use 75% opacity; foreground text and icons remain fully opaque.
- Dark mode inserts one continuous `colorScheme.surface` veil at 18% opacity above the course flag and below the complete learner foreground. Light mode has no equivalent veil.

## Automated validation

- Focused learner-path and source-layout coverage passed **18 tests**, including AssetManifest discovery of every current mascot PNG, deterministic sides, same-side spacing, stable course shuffling, full-set reuse, opposite-side placement on both sides, completion with errors, perfect Laurel presentation, rebuild persistence, missing assets, interaction, narrow widths and light/dark surface alpha.
- Post-correction `flutter test --no-pub --reporter compact` passed **308 tests** in approximately **1 minute 30 seconds**.
- `flutter analyze --no-pub` reported no errors or warnings and the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` diagnostics in untouched service files.
- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- Final `git diff --check` passed. LF/CRLF working-copy notices are non-functional and do not represent content changes.

## Actual Flutter web visual validation

- A disposable Flutter web entry used existing services and browser-local storage to select a long 13-Round Lesson. It did not modify production code, bundled course content, persistence formats or repository data, and was deleted after capture.
- Actual app captures were inspected at **320 x 568**, **375 x 667** and **390 x 844** logical px in both light and dark modes. The captures are stored outside the repository validation diff.
- The captures demonstrate Rounds on both sides, consecutive same-side Rounds, clear vertical separation, a behind-content connector and mascots on both free sides. Scrolling the same Lesson confirmed all five current mascot PNGs appear before any reuse.
- Round 1 uses existing persisted completion plus an error record, showing the yellow-orange icon, `Practice` and no Laurel. Round 4 uses existing completed and perfect state, showing the same completed accent, `Perfect` and the established Laurel leaves without overlap or conflict.
- Available never-completed Rounds retain their pale icon treatment. The end of the flow was separately inspected to confirm the compact centered Duel, the genuine next-Lesson lock boundary and unchanged locked content gating.
- Mascot artwork remains fully visible while its padded surface is 50% transparent and theme-derived. No previous decorative Lesson imagery appears.
- No horizontal overflow, content overlap or lost Round interaction was observed at any requested width.

## Remaining release checks

- Produce and inspect platform release packages separately; packaging is outside this implementation task.
- Retain the normal desktop/mobile platform smoke checks for TTS, import/export paths, external links and window resizing before distribution.

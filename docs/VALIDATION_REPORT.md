# QuisquisLingo 2.0.19+219 release validation report

Date: 1 September 2026

## Baseline and release boundary

- The final build-219 corrective pass began from commit `ef09982` (the existing `2.0.19+219` learner-path implementation).
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
- The existing course-scoped completed-Round ID set drives the yellow-orange icon background (`#FFB000` light, `#FFB62E` dark). Completion with errors, later repeats and page rebuilds retain the same accent without requiring a Laurel. Never-completed Rounds keep the existing pale theme treatment (`#FFEBC0` light, `#3A3425` dark).
- The authoritative existing perfect/Laurel set now makes the Round icon bright green (`#34C759` light, `#4CD964` dark). The Laurel frame grows from the normal 56 x 54 px icon reservation to 72 x 66 px, and both leaves grow from 34 px to 44 px with a wider -2 px left/right spread and -1 px lower placement. No Laurel, XP, scoring, completion or persistence logic changed.
- Genuine access locks remain Lesson-scoped under Course Model v4. A locked Lesson keeps its GuideBook, Rounds and Duel inaccessible unless existing genuine progress or IDDQD access permits them; no unsupported Round-level lock was added for validation.

## Mascot implementation

- The current release manifest contains ten renderable PNGs: `cat-celebrating_tr.png`, `cat_reading.png`, `cat_speaking.png`, `dog-laughing-pencil_tr.png`, `kid_reading.png`, `monkey-yawning_tr.png`, `qql-dog-tambourine.png`, `qql-monkey-sleeping.png`, `robot_running.png` and `robot_speaking.png`.
- `pubspec.yaml` registers the `assets/mascots/` directory. Production loads Flutter's `AssetManifest`, filters every PNG path under that directory, removes duplicates, sorts the complete set and decodes each candidate before it can enter the pool. Adding another valid PNG therefore requires only an app rebuild, with no filename list or asset-count change.
- The released repetition was caused by a Lesson-local `mascotPosition = 0` reset. Every bundled Lesson has two Rounds, so only its local slot zero was reached and every Lesson repeatedly selected the first shuffled asset. Six of the eight original five-asset course shuffles put the cat first; Finnish put the sleeping monkey first. Rendering errors never fell back to the cat.
- Decorative slots are selected independently from Round sides. Each mascot is positioned on the free side opposite its nearby Round, and early slots demonstrate both left and right placement.
- Mascot selection uses a stable integer seed derived from immutable `courseId` and a seeded Fisher-Yates shuffle over the complete sorted valid pool. The same course retains the same order across rebuilds, navigation and app restarts; different course IDs receive independently shuffled orders; no separate preference is persisted.
- Home passes cumulative Round and mascot-slot offsets into every lazy Lesson path. The shuffled list is consumed sequentially across Lessons, so its first N rendered positions are N distinct assets. Later cycles rotate the list (with a two-asset boundary special case), guaranteeing no adjacent duplicate whenever at least two valid assets exist.
- Mascots use `BoxFit.contain`, 10 px internal padding, external separation from Round cards, `IgnorePointer` and `ExcludeSemantics`.
- The image remains fully opaque. Only the theme-derived surrounding surface uses 50% alpha in light and dark modes.
- Decode failures are removed before shuffling and never fall back to another mascot. A later image-render failure collapses to an empty decoration without a broken-image placeholder. Mascots are omitted below a 320 px path width, including the 292 px content width of a 320 px learner page, so the Round path retains priority.

## Title behavior

- Round titles are `Text` widgets in `home_screen.dart` using Material 3 `titleMedium` (nominally 16 px/24 px), weight 800, `maxLines: 2` and `TextOverflow.ellipsis`. The Round card has a fixed 108 px base height with text-scale growth rather than title-driven height. A long perfect-Round title at a 320 px page width remains within the card without horizontal overflow.
- The fixed Lesson selector title uses `titleMedium`, weight 900, `maxLines: 2` and ellipsis in a content-driven button. Subsequent in-flow Lesson headings use `titleLarge`, weight 900, with content-driven height and no explicit line or overflow limit. A blanket new two-line Lesson-heading rule was therefore not applied.

## Supporting nodes and dark theme

- GuideBook and Duel remain centered and use 88% of the available width up to a 400 px constraint, with reduced padding and icon sizes. Their content, tap behavior and availability logic are unchanged.
- Round, GuideBook and Duel background surfaces use 75% opacity; foreground text and icons remain fully opaque.
- Dark mode inserts one continuous `colorScheme.surface` veil at 18% opacity above the course flag and below the complete learner foreground. Light mode has no equivalent veil.

## Automated validation

- Focused learner-path and source-layout coverage passed **25 tests**, including actual Home lazy-Lesson wiring through production discovery, AssetManifest decoding of every current PNG, one/two/larger pool boundaries, deterministic sides, same-side spacing, stable course shuffling, exhaustion-before-reuse, opposite-side placement on both sides, completion colors, larger Laurel geometry, missing assets, interaction, light/dark treatment and 320/375/390 px layout.
- Post-correction `flutter test --no-pub --reporter compact` passed **315 tests** in approximately **1 minute 43 seconds**.
- `flutter analyze --no-pub` reported no errors or warnings and the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` diagnostics in untouched service files.
- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- The optional Image Bank validator still reports only the intentionally deleted `assets/exercise_images/hello.webp`, which remains referenced by the pre-existing Image Bank/course metadata. That unrelated metadata was not changed and the deleted decoration was not restored.
- `tools\package_windows_release.ps1` built the Windows release, staged all runtime dependencies, created and extracted the ZIP, and passed its package-content verification. The staged and encoded release AssetManifest contain exactly the ten current source PNGs with matching SHA-256 hashes and no stale removed asset.
- Final `git diff --check` passed. LF/CRLF working-copy notices are non-functional and do not represent content changes.

## Runtime and responsive validation

- No preview entry point, custom preview course or new screenshot suite was created for this correction. Production runtime tracing, actual rootBundle/AssetManifest decoding, a Home-level lazy-ListView regression and the release AssetManifest were used instead.
- Tests confirm Round cards stay within the learner path at 320, 375 and 390 logical px. Mascots yield at the narrowest effective content width and remain available at the wider requested widths.
- Round placement still uses both sides with valid same-side spacing. The connector remains behind all foreground nodes, while GuideBook and Duel remain centered and outside the Round side pattern.

## Release artifact

- Staged Windows directory: `build/packages/quisquislingo_alpha_219_dev_windows_x64/`
- Windows ZIP: `build/packages/quisquislingo_alpha_219_dev_windows_x64.zip`
- Final learner-page visual inspection remains a manual check on this actual release build, as requested.

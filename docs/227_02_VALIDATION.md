# QQL 227.02 Inspired learner backgrounds and validation

## Revision 1 release boundary

Current metadata is Version `2.0.27`, Phase `227.02`, revision `1`, technical build `227021`, and pubspec `2.0.27+227021`. The QQL 227 Alpha expiry remains exactly `2026-10-07 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`) and the Audit Registry remains at 102 rules.

Revision 1 starts from committed `384b9b65bfe9d39ae14465e22b3963f604cc4007`, `Complete QQL 227.02 adaptive flag backgrounds`. That commit is the completed revision-0 implementation with a clean checkout. This correction retains its resolver, source precedence, automatic readability protection, user × Course persistence, Off default and obsolete-key clean cut.

## Revision 1 product correction

The revision-0 `Soft Inspired` treatment was too close to Tinted because both colors were heavily blended toward the same learner-page base and the surface used only one quiet two-color gradient. Revision 1 renames the learner-facing option to `Inspired` and gives it a distinct role. The final ordered choices are Small → Off → Extended → Tinted → Inspired → Small.

Tinted is intentionally unchanged in role and parameters: one representative chromatic color is adapted into one quiet, uniform Light or Dark surface. Inspired now selects up to three meaningfully separated colors from the same deterministic buckets. It adapts those colors with stronger bounded chroma, then renders a static three-stop top-left-to-bottom-right field with broad transitions. Three useful colors are used directly. Two useful colors receive a midpoint derived only from those colors. A single useful color receives lighter and darker tonal variants of the same hue. No unrelated hue is invented to force variety.

The resulting distinction is structural and measurable. Tinted has a solid `BoxDecoration.color` and no gradient. Inspired has no solid color and uses three gradient stops. For normal multicolor input, its output contains three distinct source-hue colors, has materially greater color spread, and has stronger maximum saturation than Tinted. Neither path renders flag artwork, flag geometry, blur, opacity wrappers, animations or transitions.

## Persistence decision

The Dart enum case remains `softInspired` and its stored value remains `soft_inspired`; only its visible `label` changes to `Inspired`. This preserves every selection written by revision 0 without a migration, fallback alias or reset. A focused test installs raw `soft_inspired` data under the existing hashed Course key and verifies that it restores as the visible Inspired mode.

All other persistence behavior is unchanged. The active opaque learner namespace still stores:

```text
flag_background_mode_course_<sha256(courseId.trim())>
```

Missing and unknown values still resolve to Off. The obsolete shared `flag_background_mode` value remains untouched and unread. No preference is written to Course Model or Course JSON, and the selector has no progress, XP, streak, Laurel, unlock or checksum effect.

## Difficult flags and readability

Revision 1 reuses the revision-0 World Flag SVG, custom raster and built-in color pipeline. Chromatic colors remain preferred over dominant white, black or gray fields. Representative colors must have a minimum source-space separation before they become separate Inspired zones. White and dark neutrals use supporting Light/Dark targets so they remain visibly distinct without taking over the palette. Near-monochrome input falls back to related tonal variation. Saturated colors are capped, hue is preserved across adaptation, and every final stop passes the existing foreground contrast bounds.

Automated cases cover bicolor, tricolor, highly saturated, predominantly white, predominantly dark, multicolor, neutral-heavy and near-monochrome samples in both Light and Dark themes. They also retain the real World Flag SVG, custom raster and malformed/unavailable source checks from revision 0.

Temporary ignored reference sheets rendered the actual revision-1 palette and learner-like heading, Round card, lock, mascot and connector surfaces for all seven representative flag classes in Light and Dark. Direct visual inspection confirmed that Tinted remains quiet and uniform while Inspired exposes broad, recognizable multiple colors where the source supports them; cards, text and indicators remain separated in both themes. The sheets are `build/227021_visual_reference_light.png` and `build/227021_visual_reference_dark.png` and are validation evidence rather than tracked product assets.

## Revision 1 validation results

| Check | Result |
| --- | --- |
| Palette, composition, difficult flags, fallback and persistence | **8 passed / 0 failed**, exit 0 |
| Existing learner-control and profile-navigation regressions | **22 passed / 0 failed**, exit 0 |
| Real Home all-mode rendering and immediate replacement | **2 passed / 0 failed**, exit 0 |
| Light/Dark visual reference render | **2 passed / 0 failed**, exit 0; manually inspected |
| Metadata, audit-report and Alpha lifecycle | **12 passed / 0 failed**, exit 0; Welcome/Alpha display metadata **1 passed / 0 failed**, exit 0 |
| Final analyzer delta | **71 inherited / 0 new / 0 resolved** against the committed revision-0 log: 70 Infos, 1 Warning, 0 errors; exit 1 solely for inherited findings |
| Complete Flutter suite | **1,199 passed / 0 failed**, exit 0, **13:32**; one serialized final-tree run |
| Bundled Course validator | **9 Course Model v6 files valid**, exit 0 |
| Bundled checksum check | **all 9 generated Courses and SHA-256 values matched**, exit 0 |
| Image validator | **112 assets / 0 issues**, exit 0 |
| Lesson-icon validator | **14 assets / 0 issues**, exit 0 |
| Final source snapshot | All **253 source/test/pubspec SHA-256 values** matched the pre-suite snapshot; 0 changed and 0 added |
| `git diff --check` | **Passed**, exit 0; no staged diff; no Course Model or asset diff |

The temporary reference-sheet Dart harness was removed after it generated the ignored PNG evidence. An analyzer run made before that removal contained one harness-only filename Info; it is not reported as final evidence. The subsequent final-tree analyzer exactly matches the committed revision-0 diagnostics. No source or test file changed after that analyzer or the complete suite.

## Revision 1 remaining visual limitations

The broad static gradient is deterministic but subjective appearance still depends on the display. Automated and direct reference-sheet validation covers the specified representative classes and responsive widget widths, not all 266 flags on every physical display. SVG extraction remains intentionally limited to explicit color forms used by current assets rather than general SVG geometry or rendered-area analysis; custom raster palette extraction remains a low-resolution deterministic sample.

Revision 1 stops at this naming and visual differentiation correction. It does not begin 227.03 or change IDDQD, Theme, Settings, Stats, Study Days, logging, Course Editor or Course Model behavior.

## Historical revision 0 record

The remainder of this document preserves the completed `2.0.27+227020` validation record as historical evidence. Its former visible name and measured results describe revision 0 rather than the current product state.

### Release boundary

Target metadata is Version `2.0.27`, Phase `227.02`, revision `0`, technical build `227020`, and pubspec `2.0.27+227020`. The QQL 227 Alpha expiry remains `2026-10-07 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`) and the Audit Registry remains at 102 rules.

Implementation started from committed `91c1254efe96bdc1fdba4120ef1be322221eb1a1`, whose subject is `Complete QQL 227.01 learner panel control baseline`. The checkout was clean at inspection. That parent already made Flag Background an Off-by-default opaque learner ID × immutable Course ID preference, ignored the obsolete shared preference, kept Theme per learner with Default following live system brightness, and kept IDDQD Off/On per learner × Course. Phase 227.02 does not recreate or reinterpret those boundaries.

### Implementation

`LearnerFlagBackgroundMode` retains `Small`, `Off`, and `Extended` in their existing order and appends `Tinted` and `Soft Inspired`. The cycle is now Small → Off → Extended → Tinted → Soft Inspired → Small. Existing Small `BoxFit.contain`, Off hidden, and Extended `BoxFit.cover` rendering is unchanged.

Tinted and Soft Inspired use `FlagBackgroundPaletteService` and `CourseFlagPaletteResolver`. Tinted renders one uniform adapted color. Soft Inspired renders a static top-left-to-bottom-right two-color gradient. These surfaces contain no flag image, opacity layer, blur, animation or transition. The mounted learner page replaces the mode immediately through the existing bottom-control callback and appearance event.

The existing content stack stays above the background. Lesson headings, Round cards and titles, connectors, locks, mascots, GuideBook, Duel and fixed bottom controls retain their established theme-aware surfaces and contrast treatments. The new palette independently bounds the background: Light output stays bright enough for dark foreground separation, Dark output stays dark enough for light foreground separation, and chroma is restrained before it reaches the learner page.

### Persistence and isolation

The storage implementation is unchanged from 227.01. Each value uses the active opaque learner namespace and a key of the form:

```text
flag_background_mode_course_<sha256(courseId.trim())>
```

Missing and unknown values still resolve to Off. The obsolete shared `flag_background_mode` value is neither read, migrated nor deleted. Tinted stores `tinted`; Soft Inspired stores `soft_inspired`. Tests cover same learner/same Course restoration, same learner/different Course independence, different learner/same Course independence, service recreation, and an untouched obsolete shared value.

Flag Background remains profile preference data. No field was added to Course Model or Course JSON, and changing modes does not alter learner progress, XP, streak, Laurels or course selection. Course checksums therefore remain independent of this preference.

### Deterministic color derivation

The resolver follows the existing flag-source precedence:

1. an explicit World Flag ID resolves its manifest SVG;
2. otherwise a portable custom Base64 raster flag is decoded and sampled;
3. otherwise the existing built-in flag code supplies representative colors.

SVG extraction recognizes the color forms used by the current assets. Each explicit SVG color contributes once at its strongest use so a detailed crest cannot dominate merely because it contains many small paths. Raster inputs are decoded to at most 48 pixels wide and sampled with alpha weighting. Color samples are grouped into fixed neutral or HSL buckets and ranked deterministically; input order and random state do not affect the result.

If any chromatic bucket exists, the primary color comes from a chromatic bucket. This prevents a large white, black or gray region from automatically becoming the course identity. Extreme lightness and neutral colors receive explicit penalties. The selected colors then receive shared Light/Dark lightness targets, saturation bounds and restrained blending. Hue is retained after blending so quiet blue and purple flags do not drift toward the learner page's warm light base. Soft Inspired chooses a stable, meaningfully separated second representative color when available and falls back to a small neutral variation for near-monochrome input.

The deterministic matrix covers predominantly white, predominantly black, highly saturated, bicolor, tricolor, multicolor, neutral-heavy and near-monochrome samples in Light and Dark themes. A portable predominantly white custom raster with a small purple field verifies that the chromatic identity is retained. A current World Flag SVG verifies the manifest/asset path.

### Failure behavior

Missing, unreadable, malformed or colorless preferred flag input cannot remove the learner background or crash the page. A failed World Flag or custom-raster derivation first uses the existing built-in flag colors selected by the Course/fallback code. If that source is also unknown, the resolver returns a quiet neutral Light or Dark learner-page palette. The widget installs that safe palette synchronously and retains it if an unexpected asynchronous decoder or asset error escapes the resolver.

This fallback is local to the two derived background modes. It does not change the existing flag badge/backdrop pipeline, imported assets, Course JSON, validation or asset management.

### Test coverage

Focused behavior covers:

- exact five-option values and cycle while retaining Small, Off and Extended;
- deterministic derivation, order independence, Light/Dark adaptation, luminance/contrast bounds and restrained saturation;
- difficult synthetic colors, current SVG forms, a real World Flag asset and a portable custom raster;
- malformed raster, missing World Flag and unknown built-in safe fallbacks;
- Tinted uniform rendering and Soft Inspired static gradient rendering without flag artwork or animated containers;
- 320, 375, 430 and 1100 logical-pixel widths in Light and Dark themes;
- learner × Course persistence, service recreation and obsolete-key isolation;
- immediate Home-screen replacement through the real learner control;
- unchanged progress, XP and serialized Course data.

### Validation results

| Check | Result |
| --- | --- |
| New palette/rendering/persistence file | **8 passed / 0 failed**, exit 0; `build/227020-palette-focused-final.log` |
| Existing learner-control and profile-navigation regressions | **22 passed / 0 failed**, exit 0; `build/227020-controls-existing-focused.log` |
| Home all-five-mode rendering in Light/Dark | **1 passed / 0 failed**, exit 0; `build/227020-home-modes-focused.log` |
| Home immediate Tinted/Soft Inspired replacement | **1 passed / 0 failed**, exit 0; `build/227020-home-immediate-focused.log` |
| Metadata, audit-report and Alpha lifecycle | **12 passed / 0 failed**, exit 0; `build/227020-metadata-focused.log` |
| Welcome/Alpha display metadata | **1 passed / 0 failed**, exit 0; `build/227020-welcome-focused.log` |
| Final analyzer delta | **71 inherited / 0 new / 0 resolved**, exit 1 solely for the inherited findings: 70 Infos, 1 Warning, 0 errors. Exact diagnostic comparison against `build/227010-analyze-verified.log`; current log `build/227020-analyze-initial.log` |
| Complete Flutter suite | **1,199 passed / 0 failed**, exit 0, **15:32**; one serialized final-tree run, `build/227020-full-suite.log` |
| Bundled Course validator | **9 Course Model v6 files valid**, exit 0 |
| Bundled checksum check | **all 9 generated Courses and SHA-256 values matched**, exit 0 |
| Image validator | **112 assets / 0 issues**, exit 0 |
| Lesson-icon validator | **14 assets / 0 issues**, exit 0 |
| `git diff --check` and final source snapshot | `git diff --check`: exit 0. All **253 source/test/pubspec SHA-256 values** matched the pre-suite snapshot; 0 changed and 0 added. Nothing is staged. |

The first four-file test attempt compiled after correcting a `dart:ui` namespace reference, then exposed one palette calibration assertion and later stopped making progress in a custom-image test. The palette bound was tightened. The custom-image setup was moved into Flutter's real asynchronous test zone; its image codec had been waiting under fake async. Isolated reruns passed. The interrupted aggregate attempt is retained only as diagnostic evidence in `build/227020-controls-focused-rerun.log` and is not counted as a passing run.

### Remaining limitations

SVG color extraction intentionally handles the explicit attributes and color forms used by the bundled World Flags; it is not a general SVG renderer or geometric area estimator. Raster sampling is intentionally low resolution because the output is a background palette, not a reproduced image. Automated tests cover the specified responsive dimensions and representative difficult inputs; they do not manually inspect all 266 flags on every platform display.

Phase 227.02 ends at these two modes. IDDQD communication or modes, Theme modes/scheduling, Lesson-number controls, animations, sliders, custom background editing, Stats, Study Days, Settings/log reorganization, Course Editor changes and Course Model changes remain deferred.

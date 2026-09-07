# QQL 227.02 Flag-inspired learner backgrounds and validation

## Release boundary

Target metadata is Version `2.0.27`, Phase `227.02`, revision `0`, technical build `227020`, and pubspec `2.0.27+227020`. The QQL 227 Alpha expiry remains `2026-10-07 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`) and the Audit Registry remains at 102 rules.

Implementation started from committed `91c1254efe96bdc1fdba4120ef1be322221eb1a1`, whose subject is `Complete QQL 227.01 learner panel control baseline`. The checkout was clean at inspection. That parent already made Flag Background an Off-by-default opaque learner ID × immutable Course ID preference, ignored the obsolete shared preference, kept Theme per learner with Default following live system brightness, and kept IDDQD Off/On per learner × Course. Phase 227.02 does not recreate or reinterpret those boundaries.

## Implementation

`LearnerFlagBackgroundMode` retains `Small`, `Off`, and `Extended` in their existing order and appends `Tinted` and `Soft Inspired`. The cycle is now Small → Off → Extended → Tinted → Soft Inspired → Small. Existing Small `BoxFit.contain`, Off hidden, and Extended `BoxFit.cover` rendering is unchanged.

Tinted and Soft Inspired use `FlagBackgroundPaletteService` and `CourseFlagPaletteResolver`. Tinted renders one uniform adapted color. Soft Inspired renders a static top-left-to-bottom-right two-color gradient. These surfaces contain no flag image, opacity layer, blur, animation or transition. The mounted learner page replaces the mode immediately through the existing bottom-control callback and appearance event.

The existing content stack stays above the background. Lesson headings, Round cards and titles, connectors, locks, mascots, GuideBook, Duel and fixed bottom controls retain their established theme-aware surfaces and contrast treatments. The new palette independently bounds the background: Light output stays bright enough for dark foreground separation, Dark output stays dark enough for light foreground separation, and chroma is restrained before it reaches the learner page.

## Persistence and isolation

The storage implementation is unchanged from 227.01. Each value uses the active opaque learner namespace and a key of the form:

```text
flag_background_mode_course_<sha256(courseId.trim())>
```

Missing and unknown values still resolve to Off. The obsolete shared `flag_background_mode` value is neither read, migrated nor deleted. Tinted stores `tinted`; Soft Inspired stores `soft_inspired`. Tests cover same learner/same Course restoration, same learner/different Course independence, different learner/same Course independence, service recreation, and an untouched obsolete shared value.

Flag Background remains profile preference data. No field was added to Course Model or Course JSON, and changing modes does not alter learner progress, XP, streak, Laurels or course selection. Course checksums therefore remain independent of this preference.

## Deterministic color derivation

The resolver follows the existing flag-source precedence:

1. an explicit World Flag ID resolves its manifest SVG;
2. otherwise a portable custom Base64 raster flag is decoded and sampled;
3. otherwise the existing built-in flag code supplies representative colors.

SVG extraction recognizes the color forms used by the current assets. Each explicit SVG color contributes once at its strongest use so a detailed crest cannot dominate merely because it contains many small paths. Raster inputs are decoded to at most 48 pixels wide and sampled with alpha weighting. Color samples are grouped into fixed neutral or HSL buckets and ranked deterministically; input order and random state do not affect the result.

If any chromatic bucket exists, the primary color comes from a chromatic bucket. This prevents a large white, black or gray region from automatically becoming the course identity. Extreme lightness and neutral colors receive explicit penalties. The selected colors then receive shared Light/Dark lightness targets, saturation bounds and restrained blending. Hue is retained after blending so quiet blue and purple flags do not drift toward the learner page's warm light base. Soft Inspired chooses a stable, meaningfully separated second representative color when available and falls back to a small neutral variation for near-monochrome input.

The deterministic matrix covers predominantly white, predominantly black, highly saturated, bicolor, tricolor, multicolor, neutral-heavy and near-monochrome samples in Light and Dark themes. A portable predominantly white custom raster with a small purple field verifies that the chromatic identity is retained. A current World Flag SVG verifies the manifest/asset path.

## Failure behavior

Missing, unreadable, malformed or colorless preferred flag input cannot remove the learner background or crash the page. A failed World Flag or custom-raster derivation first uses the existing built-in flag colors selected by the Course/fallback code. If that source is also unknown, the resolver returns a quiet neutral Light or Dark learner-page palette. The widget installs that safe palette synchronously and retains it if an unexpected asynchronous decoder or asset error escapes the resolver.

This fallback is local to the two derived background modes. It does not change the existing flag badge/backdrop pipeline, imported assets, Course JSON, validation or asset management.

## Test coverage

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

## Validation results

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

## Remaining limitations

SVG color extraction intentionally handles the explicit attributes and color forms used by the bundled World Flags; it is not a general SVG renderer or geometric area estimator. Raster sampling is intentionally low resolution because the output is a background palette, not a reproduced image. Automated tests cover the specified responsive dimensions and representative difficult inputs; they do not manually inspect all 266 flags on every platform display.

Phase 227.02 ends at these two modes. IDDQD communication or modes, Theme modes/scheduling, Lesson-number controls, animations, sliders, custom background editing, Stats, Study Days, Settings/log reorganization, Course Editor changes and Course Model changes remain deferred.

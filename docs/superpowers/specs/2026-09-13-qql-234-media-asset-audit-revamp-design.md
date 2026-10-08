# QQL 234 Media Asset Audit and Final Alpha Cleanup — Design

## Status and controlling requirements

This design implements QQL `2.0.34+234000`, Build 234, Revision 0, on the
committed QQL `2.0.33+233030` baseline. It incorporates the attached QQL 234
specification and the user's subsequent approvals: all 92 contaminated
exercise-bank images are in scope; the language-related flag tranche contains
the approved original seven plus West Frisian, Piedmontese and Neapolitan; and
QQL 234 ships a real bundled Italian-to-Neapolitan course titled as an
`AI-Slop Demo` and using approved replacement images.

QQL 234 remains Alpha. It does not declare Beta readiness merely because the
implementation completes. Beta is a later release decision based on the final
audit, tests, analyzer and validation evidence.

Work remains in the current checkout. No worktree, staging, commit, push,
package, tag, publication, reset, revert, clean, discard, broad refactor, or
unrelated feature is authorized. The Course Model remains v9 and existing v9
persistence namespaces remain unchanged.

## Audited baseline

The clean baseline contains 429 tracked media files totaling approximately
12.15 MiB: 112 exercise WebPs, 266 World Flag SVGs, 32 PNGs and 19 audio files.
No byte-identical media duplicates were found.

All exercise-bank images are 256 by 256 lossless WebP files with transparency.
Visual inspection found foreign sprite fragments or split-image contamination
in 92 of 112 files; the remaining 20 are clean. The bank is loaded through
`assets/exercise_images/manifest.json`; bundled courses did not reference the
bank at baseline. Replacing affected files in place preserves every stable
path, manifest ID and category. QQL 234 intentionally improves labels and tags
as described below.

The World Flag manifest contains 266 entities, including nine
language-associated community or regional flags. Search by ID, English name,
aliases, ISO codes and subdivision codes already exists inside the World Flag
dialog. Course creation nevertheless exposes a fixed legacy flag-code list
under the misleading `Existing QQL course flags` label, and neither creation
nor Course Info can suggest flags by language or reuse actual flags from
installed courses.

Startup uses `assets/olive_tree.png`, independently animated flag widgets and
separate QuisquisLingo text. The canonical transparent brand asset is
`assets/branding/quisquislingo_logo.png`.

The rare Android Extended-background flash has a concrete state-order cause:
course-switch paths commit the destination Course while retaining the origin
Course's `_flagBackgroundMode` until asynchronous reload completes. A source
Course in Extended mode can therefore paint the destination with stale
Extended artwork before the Course Entry Animation is installed.

Audio consists of three WAV Duel effects and sixteen MP3 examples in eight
language subdirectories. The files are to remain byte-for-byte unchanged.
`pubspec.yaml` declares only `assets/audio/`; Flutter directory declarations
are non-recursive, so the nested MP3 examples are not bundled by that entry.

Fresh baseline `flutter analyze` reports no issues. The configuration still
excludes every platform directory and three release-gate test diagnostics use
local `avoid_print` suppressions. The historical curly-brace analyzer backlog
was already corrected in QQL 230 and does not reproduce.

After the initial audit and artwork approval, the user explicitly removed
`bicycle.webp` because its otherwise clean artwork was not a clear bicycle.
That follow-up changes the final bank from 112 to 111 entries without changing
the baseline finding: 92 semantic replacements and 19 retained assets remain.

## Exercise image replacement

Exactly the 92 visually contaminated assets are replaced in place. Every
replacement must keep its current exact filename and path, be exactly 256 by
256 pixels, be lossless VP8L WebP with a genuinely transparent background, and
remain within the established 50 KiB image-bank cap.

The approved direction is a coherent flat educational vocabulary style:
exactly one complete centered semantic subject, generous transparent padding,
solid fills, restrained palette, no gradients, texture, shadows, text, logos,
background, decorative props, edge-touching pixels or foreign fragments. The
subject must remain immediately legible at 64 by 64 pixels.

Artwork approval is staged. The first pilot contains exactly
`airplane.webp`, `carrot.webp`, `horse.webp`, `man.webp`, `jump.webp` and
`table.webp`. Each is generated independently, normalized to the exact bank
format, inspected on transparent/light/dark backgrounds at multiple sizes and
presented to the user. The other 86 replacements are not generated until the
user approves or revises the pilot style. A rejected pilot file is regenerated
rather than patched with hidden fragments.

## Media Library labels, tags and search

All final 111 built-in exercise images receive a reviewed bilingual Italian/English
tag set. Existing useful English terms are retained; every record has at least
two normalized, lowercase, trimmed and unique tags. The three equivalent
manifests remain semantically synchronized (`label`/`tags` in the runtime
manifest and `primary_term`/`keywords` in the two audit/export manifests).

The stable asset IDs and filenames do not change. `people_family_man` remains
`man.webp` but its editor-facing label becomes `Uomo`, with tags including
`uomo` and `amico`. `actions_jump` remains `jump.webp` but its editor-facing
label becomes `Saltare`, with tags including `saltare` and `salto`. The current
repository has no other `Uomo`/`Saltare` label or filename, so no numeric suffix
is needed; if a real collision is encountered while materializing a library,
the later duplicate receives the next deterministic numeric suffix.

The Course Editor Media Library shows the tags below every image label and in
the preview. Its normalized search matches label, tags, stable ID and category.
This metadata is authoring-only: tags never appear on learner exercise cards,
feedback, prompts or any other learner-facing surface.

## Expanded World Flags data

The language-related tranche adds ten entities to the existing nine, for a
target of 276 World Flag entities and 19 language-associated flags:

1. Esperanto;
2. Amazigh;
3. Ladin;
4. Asturian;
5. Sicilian;
6. Aragonese;
7. Livonian;
8. West Frisian, using the Friesland flag and suggestions for `fy`/`fy-NL`;
9. Piedmontese, using the Piedmont flag and suggestions for `pms`/`pms-IT`;
10. Neapolitan, using the Naples flag and suggestions for `nap`/`nap-IT`.

Every asset is sourced from a specific Wikimedia Commons file page. The
generator pins the canonical direct SVG URL and SHA-1 and records the source
page, author and license in the manifest and the language-related license
notice. The implementation rechecks those facts at acquisition time and does
not describe regional artwork as an official universal language flag.

Language suggestions are explicit ordered metadata, not guesses from country
codes or filenames. Matching normalizes case, underscores, BCP-47 subtags and
known language names. A complete tag wins over its base language; a base tag
then supplies the same ordered suggestions. Unknown languages receive no
fabricated suggestion.

## Shared Course flag chooser and portable reuse

Course creation and editable Course Info use one shared visual chooser. The
dialog provides a current-selection preview, immediate search and responsive
visual results grouped as applicable into:

- `Suggested for <language>`;
- `Flags from installed QQL courses`;
- `Built-in QQL collection`;
- the complete World Flags collection;
- `Automatic` and `Upload custom flag` actions.

Search covers the existing World Flag fields plus built-in labels and installed
Course titles/languages. A flag shown in an earlier section is not repeated in
a later section. Opening, searching, filtering or cancelling never changes the
Course; only selecting a result changes the dialog's working selection, and
the surrounding Course transaction remains the authoritative save boundary.

Portable values use the existing Course Model v9 fields. World Flags copy the
stable `worldFlagId`; built-ins copy the supported `flagCode`; custom raster
flags are decoded, revalidated through `CourseFlagService.prepareFlag`,
normalized and copied into `flagImageBase64`. The destination never stores a
source Course ID or filesystem path, so deleting or updating the source cannot
break it. Invalid installed raster data is skipped safely.

World and built-in references may be reused from any installed Course. To avoid
turning the picker into an unauthorized artwork extractor, custom raster flags
are offered only from Courses for which the active profile has Copy-as-new
authority under the existing access policy. Results are deduplicated by World
Flag ID, built-in code, or SHA-256 of normalized raster bytes.

No flag selection changes ownership, derivative policy, authorization,
Course IDs, persistence keys or the World Flag Game's four established pools.

## Startup artwork and atomic Course entry

Startup removes the olive, flying flags and separately rendered word mark. It
shows only the canonical QuisquisLingo logo with a 600 ms fade and scale from
96 to 100 percent. The established startup-gate lifetime remains unchanged;
after the entrance the logo is static. When animations are disabled or reduced
motion is requested, the final static logo is shown without interpolation for
the same gate lifetime. The olive asset and its obsolete credit are removed
because startup is its only consumer.

Course switching keeps the source Course fully coherent while the destination
state loads. `_reload` receives an optional pending Course-entry transition and
commits the destination Course, destination flag-background mode and entry
overlay in one final state update. The existing Course Selector dismissal,
animation-enabled policy, reduced-motion policy and Course Entry Animation
duration remain unchanged. No delay, placeholder background or Android-only
branch is introduced.

Regression coverage holds an Extended source Course and an Off destination in
the asynchronous transition gap and proves that the destination is never
painted with the stale Extended mode.

## Bundled Italian-to-Neapolitan AI-Slop Demo

QQL 234 explicitly lifts the earlier deferral of a Neapolitan sample. A tenth
immutable bundled Course is added with registry code `NAP`, canonical learning
language `Neapolitan`, BCP-47 language identity `nap-IT`, Italian interface and
source language `it-IT`, and stable Course ID `sample_nap_it_nap`. Its title is
`AI-Slop Demo: Napoletano per italofoni`, it is clearly marked
`temporarySample: true`, and the existing learner-facing AI-generated,
unreviewed warning is updated from nine to ten courses.

The Course follows the established demo depth: nine published Lessons, four
published Rounds per Lesson, at least four GuideBook vocabulary entries per
Lesson and the same approximate exercise density as the other bundled demos.
All IDs are new, deterministic and `qql_nap_`-prefixed; all Lesson, Round and
Exercise timestamps are deterministic UTC values. Official provenance,
publisher metadata and checksum use the existing bundled-course rules.

The course uses a consistent documented written Neapolitan sample register and
Italian glosses. Because no Neapolitan system TTS voice is assumed, the course
does not masquerade Italian TTS as Neapolitan. It remains playable through
text/image exercises; audio availability continues to follow the existing
runtime policy. At least the six approved pilot image paths appear in genuine
published exercises, with text alternatives and valid choices, so the Course
is an integration test of both minority-language flag selection and the
repaired image bank.

Three-letter learner identities are supported narrowly: `nap` and the known
Neapolitan names resolve to one canonical language identity, and
`CourseService.codeForCourse` retains a valid two- or three-letter language
code instead of truncating it. Existing two-letter identities and storage
remain unchanged.

The authoritative bundled registry, immutable-official ID set, discovery
tests, provenance tests, sample-course tests, Course credits and validation
tooling are updated from nine to ten. No existing bundled Course content or ID
is rewritten merely to add the new Course.

## Audio integrity

All nineteen existing audio files remain byte-for-byte unchanged. The eight
sample subdirectories are declared explicitly in `pubspec.yaml`. A focused
asset-bundle test loads every expected WAV and MP3 logical path. This is an
asset packaging correction only: no sample browser, recording, generated
audio, playback architecture or new audio setting is added.

## Analyzer and automated integrity gates

The broad analyzer `exclude` block is removed. The three `avoid_print`
comments and their prints are replaced with assertion reasons that preserve
failure diagnostics. Any finding exposed by the unsuppressed full analyzer is
fixed at its source; no replacement lint disable or exclusion is permitted.

`tools/validate_images.py` becomes an integrity validator for the complete
exercise bank: exact physical/manifest set equality, unique IDs and paths,
case-correct paths, 256-by-256 dimensions, lossless VP8L encoding,
transparency, transparent border/padding invariants and the 50 KiB cap. World
Flag tests continue to enforce safe renderable SVG, manifest counts and exact
asset coverage. Media tests cover startup logo decode, removal of startup olive
references, audio bundle coverage, Course image references, and the new
Neapolitan Course's assets.

The release validator invokes the deterministic media and Course validators.
`docs/234_MEDIA_AUDIT.md` records inventory, classifications, retained assets,
removed assets, sources, licensing and final status. `docs/234_VALIDATION.md`
records commands only after they actually run.

## Release metadata and verification

The release version is `2.0.34+234000`, display Build 234, Revision 0. The
30-day Alpha expiry is refreshed to `2026-10-13 23:59:59` local time in source,
tests and current documentation. Historical release records and Course Model
v9 storage namespaces remain historical and unchanged.

Implementation proceeds in test-first slices. Focused verification covers
flag parsing/suggestions/deduplication/portability, both flag-selection entry
points, startup motion/reduced motion, the stale Extended-frame regression,
audio bundle coverage, image-bank structure, Neapolitan language identity,
bundled discovery/provenance/audit/playability and image rendering.

After focused checks are green, changed Dart files are formatted and the full
unsuppressed analyzer runs. The complete Flutter suite runs exactly once on the
final production/test tree using `flutter test --no-pub --concurrency=1`; the
repository's known process-global platform-channel and SharedPreferences mocks
make higher concurrency an unsuitable release gate. Non-Flutter validators may
run independently. Final evidence also includes deterministic generator
checks, `git diff --check`, status/scope inspection and a documented Alpha-to-
Beta readiness assessment. No code, tests or assets change after final-suite
evidence except recording that evidence in documentation and re-running
non-suite textual checks.

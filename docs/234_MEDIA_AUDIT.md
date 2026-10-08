# QQL 234 media asset audit

QQL 234 Revision 1 (`2.0.34+234001`) is the final planned Alpha cleanup
correction. This
audit covers repository media, its runtime/editor consumers, provenance and
automatic integrity boundaries. It does not declare QQL 234 to be Beta.

## Inspection scope

The read-only baseline pass inspected `assets/audio/`, `assets/branding/`,
`assets/courses/`, `assets/exercise_images/`, `assets/lesson_icons/`,
`assets/lesson_plants/`, `assets/mascots/` and `assets/world_flags/`, together
with asset consumers and declarations under `lib/`, `test/`, `tools/`,
`pubspec.yaml` and the Android, Linux and Windows project directories. Literal
references were checked alongside manifests, generated registries, Course JSON,
dynamic flag/image resolvers and naming conventions; absence from a text search
was never treated by itself as proof that an asset was unused.

## Inventory

The audited baseline is commit
`0da59725f32589015bb68dea407c592653fc876e`. Counts include media below
`assets/` with PNG, WebP, SVG, MP3 or WAV extensions.

| Format | Baseline | QQL 234 | QQL 234 bytes | Result |
| --- | ---: | ---: | ---: | --- |
| WebP | 112 | 111 | 1,741,364 | Image Bank rebuilt; unclear `bicycle.webp` removed |
| SVG | 266 | 276 | 2,086,110 | Ten language-related flags added; renderer normalization limited to five new files |
| PNG | 32 | 31 | 7,624,809 | Obsolete startup olive removed |
| MP3 | 16 | 16 | 80,727 | Byte-for-byte retained |
| WAV | 3 | 3 | 199,896 | Byte-for-byte retained |
| **Total** | **429** | **437** | **11,732,906** | **Eight net new files; 993,307 fewer bytes** |

The current media tree contains no byte-identical file pair. Manifest-driven
libraries are not classified as unused merely because their individual paths
are resolved dynamically rather than appearing as Dart string literals.

## Exercise Image Bank

Visual inspection of the 112-file baseline found 92 erroneous split/composite
images and 20 already-correct images. QQL 234 replaces the 92 affected files
in place with one-subject flat artwork. The already-correct `bicycle.webp` was
later removed at the user's request because it did not represent a bicycle
clearly enough, leaving the final partition at **92 replaced + 19 retained =
111 assets**. Five retained files received padding-only normalization.

Every final Image Bank file is:

- exactly 256 × 256 pixels;
- lossless VP8L WebP with alpha;
- transparent at every outer-border pixel;
- below the established 50 KiB limit;
- present exactly once in each of the three synchronized manifests.

Every affected original was 256 × 256 pixels and every in-place replacement
is exactly 256 × 256 pixels, so neither aspect ratio nor any Course reference
changed.

The 92 semantic replacements total 1,544,634 bytes. Their mean size is
16,789.5 bytes (16.7895 decimal kB; 16.396 KiB), with a minimum of 6,904 bytes
for `fork.webp` and a maximum of 25,494 bytes for `salad.webp`. Resolution is
uniform, so the minimum, mean and maximum are all 256 × 256 pixels.

Stable filenames, asset paths, IDs and categories remain unchanged for every
retained entry. The editor-facing label for `man.webp` is **Man**, with tags
including `uomo` and `amico`; `jump.webp` is **Saltare**, with tags including
`saltare` and `salto`. Every image has reviewed normalized bilingual search
tags. The Course Editor Media Library displays and searches those tags; learner
exercise cards do not display them.

The exact 19 retained baseline artworks are `apple.webp`, `backpack.webp`,
`book.webp`, `boy.webp`, `bread.webp`, `car.webp`, `cat.webp`, `chair.webp`,
`coffee.webp`, `eye.webp`, `grandfather.webp`, `hat.webp`, `hospital.webp`,
`house.webp`, `train.webp`, `tree.webp`, `wallet.webp`, `water.webp` and
`woman.webp`. The padding-only subset is `boy.webp`, `eye.webp`,
`grandfather.webp`, `hat.webp` and `hospital.webp`.

The exact 92 split/contaminated files replaced in place are:

`airplane.webp`, `angry.webp`, `baby.webp`, `bananas.webp`, `bathtub.webp`,
`bed.webp`, `bird.webp`, `broccoli.webp`, `broom.webp`, `brush_teeth.webp`,
`burger.webp`, `bus.webp`, `cake.webp`, `camera.webp`, `carrot.webp`,
`cheese.webp`, `chocolate.webp`, `cow.webp`, `croissant.webp`, `dog.webp`,
`door.webp`, `dress.webp`, `duck.webp`, `ear.webp`, `egg.webp`, `fish.webp`,
`foot.webp`, `fork.webp`, `frying_pan.webp`, `girl.webp`, `glasses.webp`,
`gloves.webp`, `grandmother.webp`, `hand.webp`, `happy.webp`, `horse.webp`,
`ice_cream.webp`, `jacket.webp`, `juice.webp`, `jump.webp`, `knife.webp`,
`lamp.webp`, `laptop.webp`, `laugh.webp`, `man.webp`, `milk.webp`,
`mountain.webp`, `mouth.webp`, `necklace.webp`, `nose.webp`, `orange.webp`,
`oven.webp`, `pants.webp`, `pig.webp`, `pizza.webp`, `pot.webp`, `potato.webp`,
`rabbit.webp`, `refrigerator.webp`, `rice.webp`, `ring.webp`, `run.webp`,
`sad.webp`, `salad.webp`, `scarf.webp`, `sheep.webp`, `shoes.webp`, `shop.webp`,
`shorts.webp`, `shower.webp`, `sink.webp`, `sit.webp`, `sleep.webp`,
`socks.webp`, `sofa.webp`, `soup.webp`, `spoon.webp`, `stand.webp`,
`strawberry.webp`, `surprised.webp`, `t_shirt.webp`, `table.webp`, `tea.webp`,
`toilet.webp`, `tomato.webp`, `trash_can.webp`, `umbrella.webp`,
`vacuum_cleaner.webp`, `walk.webp`, `watch.webp`, `window.webp` and
`write.webp`.

Only the new bundled Neapolitan demo currently references Image Bank files in
bundled Course JSON. Its six references are `airplane.webp`, `carrot.webp`,
`horse.webp`, `jump.webp`, `man.webp` and `table.webp`. No Course references
the removed bicycle asset.

## World and language-related flags

The World Flag manifest grows from 266 to 276 entities. The existing nine
language-related entries are joined by Esperanto, Amazigh, Ladin, Asturian,
Sicilian, Aragonese, Livonian, West Frisian, Piedmontese and Neapolitan. The
Frisian, Piedmontese and Neapolitan choices use the approved Friesland,
Piedmont and Naples artwork.

The flag inventory has three deliberately distinct representations:

| Source | Inventory/format | Size rule and storage |
| --- | --- | --- |
| Legacy built-ins | 11 supported codes rendered by `FlagPainter` | Resolution-independent runtime painting; no duplicate raster files |
| World Flags | 276 manifest-owned SVG files | 257 use the shared `0 0 640 480` view box; the 19 language-related sources retain their meaningful vector geometry and are fitted by the shared renderer |
| Custom Course flags | PNG/JPEG import normalized to embedded PNG | 64 × 40 minimum input, 2 MiB input cap and 256 px maximum output dimension; Course-owned Base64 rather than a filesystem or cross-Course link |

The legacy built-in namespace is intentionally not treated as ISO: `EN` and
`UK`, `KO` and `KR`, and `CY` remain supported aliases with established
rendering/fallback semantics. World Flags resolve by stable manifest ID, and
language suggestions resolve by explicit BCP-47/name metadata rather than by
filename guessing.

All nineteen language-related SVGs have an explicit Commons source page,
author, license and pinned SHA-1. Aragonese, Friulian and Sardinian are CC
BY-SA 3.0 with named attribution; Corsican is CC0; the remaining files are
declared public domain on their recorded Commons pages. Renderer-compatible
markup normalization is limited to the five new QQL 234 assets that require
it: Aragonese, Livonian, Piedmontese, Sicilian and West Frisian. The historical
Cornish, Corsican and Sardinian SVGs remain byte-for-byte at their baseline,
including harmless legacy editor metadata. Where normalized bytes differ, the
manifest and license notice retain both the source SHA-1 and exact bundled SHA-1.

The shared Course flag picker consumes explicit ordered language suggestions.
It covers the bundled standard languages (Welsh, German, English, Spanish,
Finnish, Italian, Korean, Dutch and Portuguese) as well as the approved
minority/regional languages. Search covers names, aliases, codes, language
metadata and installed Course titles. World/built-in flags can be safely reused
from installed Courses. A custom raster is offered only when existing
Copy-as-new authorization permits it; it is decoded, normalized and copied as
a portable value rather than retaining a source-Course or filesystem link.

The legacy built-in `flagCode` namespace remains compatible and distinct from
ISO codes. The World Flag Game keeps its four established pools; its canonical
records and near-identical distractor exclusions now include the expanded
dataset and corrected painted-color tags.

## Startup artwork and Android entry frame

The former `assets/olive_tree.png` startup consumer was unique, so the file and
its obsolete credit were removed. Startup now uses the existing canonical
`assets/branding/quisquislingo_logo.png` (2,172 × 724 RGBA PNG, 365,882 bytes)
with a short fade/scale entrance. Reduced-motion and disabled-animation paths
show the final static artwork while preserving the startup gate lifetime.

The rare Android flash was traced to state ordering, not to the SVG renderer:
a Course switch could commit the destination Course while retaining the source
Course's Extended flag-background mode during asynchronous reload. The reload
now uses a latest-wins generation and commits destination Course state,
destination flag-background mode and the optional Course Entry overlay
together. No Android-only delay or masking frame was added.

## Audio

All nineteen pre-existing audio files are unchanged:

- sixteen language-sample MP3 files in eight two-file directories;
- three synthesized Duel-result WAV tones.

Their exact SHA-256 allowlist is `tools/media_asset_hashes.json`. The eight
nested MP3 directories are declared explicitly in `pubspec.yaml`, and Flutter
bundle tests load all nineteen logical paths. QQL 234 adds no Neapolitan audio
and makes no playback or audio-setting change.

The three Duel tones are documented as original QQL synthesis. The tracked
repository contains no per-file author/source record for the sixteen legacy
sample MP3s; their provenance therefore remains explicitly **uncertain** rather
than receiving an invented attribution.

## Reference, naming and case-sensitivity findings

- The three exercise-image manifests, physical WebP filenames and all Course
  image references now have exact case-sensitive set equality. No backslash or
  case-only reference survives that Windows could conceal from Android/Linux.
- The World Flag manifest and physical SVG tree have exact one-to-one coverage;
  all aliases, ISO/subdivision fields, language suggestions and symmetric
  near-identical distractor exclusions point to existing stable IDs.
- The concrete packaging defect found was the non-recursive
  `assets/audio/` declaration: it covered the three root WAV files but not the
  sixteen MP3s in eight subdirectories. Those existing directories are now
  declared explicitly without changing audio bytes or playback architecture.
- `assets/olive_tree.png` had one production consumer and became obsolete when
  startup moved to the canonical logo, so it and its declaration were removed.
  `bicycle.webp` was removed later by explicit user request, with all three
  manifests updated. Neither removed path has a production or Course consumer.
- The misleading learner meaning of `man.webp` and `jump.webp` was corrected at
  the editor-metadata layer (`Man` and `Saltare`) while stable filenames and
  IDs were deliberately retained to avoid reference churn. No mass aesthetic
  rename or directory move was performed.

## Other media and reachability

| Collection | Files | Bytes | Audit result |
| --- | ---: | ---: | --- |
| Branding | 1 | 365,882 | Canonical startup logo, active |
| Lesson icons | 14 | 169,968 | Controlled manifest/resolver library, active |
| Mascots | 10 | 7,060,272 | Deterministic learner-path library, active |
| Lesson plants | 6 | 28,687 | No production resolver or source reference found |

The six `assets/lesson_plants/plant_1.png` through `plant_6.png` files are the
only high-confidence unused media set. They are retained and reported rather
than deleted because removal was not authorized. No other duplicate, orphaned
manifest entry, missing referenced file or case-mismatched path was found.

No byte-identical media duplicates remain, and visual inspection found no
obvious unintended duplicate in the standardized Image Bank or language-flag
additions. The largest current media files are active mascot PNGs:
`qql-dog-tambourine.png` (1,117,438 bytes), `cat_reading.png` (1,005,098 bytes)
and `kid_reading.png` (786,824 bytes). They dominate package media size but are
not accidental copies and were not recompressed merely to improve totals.

## Bundled Neapolitan media exercise

`assets/courses/neapolitan_it.json` is a real immutable bundled Italian →
Neapolitan Course titled **AI-Slop Demo: Napoletano per italofoni**. It uses
Course ID `sample_nap_it_nap`, language tag `nap-IT`, the Neapolitan World Flag,
nine Lessons, 36 Rounds and 279 exercises. The six image references listed
above exercise the regenerated bank. The Course adds no audio and does not
pretend that Italian TTS is Neapolitan speech.

## Automatic integrity boundaries

- `python tools/validate_images.py` checks exact manifest/file equality,
  unique/case-correct paths and IDs, synchronized metadata, VP8L losslessness,
  dimensions, alpha, transparent border, size cap and the 92/19 partition.
- `python -X utf8 tools/validate_media_assets.py` checks media references,
  duplicate hashes, startup artwork, World Flag counts/renderability/
  provenance, exact audio hashes and explicit bundle directories.
- Flutter tests decode the complete image bank, load every audio asset and
  startup logo from the asset bundle, validate World Flag metadata and exercise
  Course flag selection, startup motion and the Android state-order regression.
- `tools/validate_courses.py` and the deterministic bundled-Course generator
  validate canonical v9 Course content and official checksums.

## Analyzer and final-Alpha hygiene

The baseline `flutter analyze` reported no issue, but that apparent result hid
the carried debt: `analysis_options.yaml` broadly excluded every Android,
Windows, macOS and Linux directory, while two release-gate test files used
three local `avoid_print` suppressions solely to print failure diagnostics.
The older curly-brace analyzer issue documented before QQL 230 did not
reproduce on this baseline.

QQL 234 removes the broad platform exclusions. The three prints and ignores
were replaced with assertion `reason` reports, preserving actionable audit
output without suppressing the lint. The fully unsuppressed analyzer then
reported `No issues found`; there are no remaining Dart `ignore` or
`ignore_for_file` directives to justify. No lint was disabled or downgraded.

## Retained uncertainties and unresolved audit findings

- The six high-confidence unused legacy lesson-plant PNGs remain intentionally
  retained and documented because deletion was not authorized and they are
  small (28,687 bytes total).
- The sixteen intentional sample MP3 files remain byte-locked and usable, but
  their original per-file authorship/source records are absent from the
  repository; this provenance uncertainty is unresolved.

  Re-examined during the Build 242 media audit: they are declared in
  `pubspec.yaml`, hash-locked in `tools/media_asset_hashes.json` and validated
  on every release, yet **no bundled course and no code references them** — all
  ten bundled courses are `audioMode: tts` with an empty Audio Library. The
  owner decided to **keep** them (78.8 KB in total) rather than remove them,
  because they are the only ready material for a future bundled-recordings or
  shared Audio Library feature, and removing them would have to be undone to
  build it. They are retained deliberately, not by oversight. Their unresolved
  provenance must be settled before they are ever presented to a learner or
  offered to course authors.
- No duplicate, broken media reference, case mismatch, schema change,
  persistence-key change or severe media blocker remains identified. QQL 234
  nevertheless remains Alpha until the complete release gate is recorded.

Final analyzer and complete-suite evidence is recorded separately in
`docs/234_VALIDATION.md`. QQL 234 remains Alpha regardless of that result; only
a later release can make the Beta transition.

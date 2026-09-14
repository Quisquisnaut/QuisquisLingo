# QQL 234 validation

Validation target: QuisquisLingo `2.0.34+234000`, displayed as **Build 234,
Revision 0**, on baseline commit
`0da59725f32589015bb68dea407c592653fc876e`. Course Model remains v9 and QQL
234 remains Alpha.

This document records only checks that actually ran. The final analyzer and
complete-suite sections remain pending until the production/test tree is
frozen.

## Inspection baseline

- Baseline media inventory: 429 files, 12,726,213 bytes; 112 WebPs, 266 SVGs,
  32 PNGs and 19 audio files.
- Baseline media duplicate scan: no byte-identical pair.
- Baseline `flutter analyze`: no issues, but the configuration excluded broad
  platform paths and three tests retained local `avoid_print` suppressions.
- Root cause of the Android Extended-frame flash: destination Course state was
  visible before its asynchronous destination flag-background mode replaced
  the origin mode.
- Audio baseline: 16 MP3s plus three WAVs. Their pre-change SHA-256 values are
  locked in `tools/media_asset_hashes.json`.

## Deterministic validators and generators

| Command | Result |
| --- | --- |
| `python tools/validate_images.py` | PASS — 111 assets; 92 semantic replacements; five padding-only normalizations; 0 issues |
| `python -X utf8 tools/validate_media_assets.py` | PRE-PRUNING PASS — 437 media files; 19 locked audio; 276 World Flags; 21 static references; 0 issues; scoped post-pruning rerun pending |
| `python -X utf8 tools/generate_world_flags.py --flag-icons <pinned-v7.5.0> --output <temporary> --iso-html <snapshot> --language-flags <verified-cache>` | PASS — 276 entities, 249 ISO, 193 UN Members, 56 ISO extras, eight shortlist, 19 language-related; generated manifest SHA-256 `93003ae48b6a590b72878ddf4b47a1eafa99d1119726285cf5dd3ef92824e8aa` |

The regenerated World Flag tree is text-equivalent to the repository asset
tree after normalizing checkout line endings; only the intended manifest and
language-license notice content changed. Every language-related source file
was validated against its pinned source SHA-1. Renderer normalization is
limited to the new Aragonese, Livonian, Piedmontese, Sicilian and West Frisian
assets; the historical Cornish, Corsican and Sardinian SVG bytes and hashes
remain at baseline.

## Pre-pruning focused Flutter evidence

Flutter checks are serialized. On this Windows host the `flutter.bat` wrapper
stalled before starting Dart, so checks use the same installed Flutter tool
snapshot directly with analytics disabled; this also avoids concurrent SDK
lock contention.

Passed focused coverage includes:

- `test/exercise_image_manifest_234_test.dart` and
  `test/media_asset_integrity_234_test.dart`: synchronized 111-entry manifests,
  tags/labels, image decoding/borders, startup logo and all 19 bundled audio
  files;
- `test/flat_image_library_234_test.dart`: author-visible tags, normalized tag/
  ID/category search and bounded preview text;
- `test/world_flag_dataset_test.dart`: 276/19 counts, suggestions, source and
  bundled hashes, the five new renderer-normalized SVGs, representative painted-color tags and
  symmetric near-identical exclusions;
- `test/course_flag_catalog_234_test.dart`: four tests passed for Italian and
  Neapolitan suggestions, ranking/deduplication, authorization-safe raster
  reuse and portable Model v9 values;
- `test/course_flag_picker_234_test.dart`: four tests passed for search,
  cancel/selection semantics, installed-Course reuse and a 640 × 360 Android
  keyboard-inset layout;
- `test/statistics_world_flag_234_test.dart`: language statistics resolve the
  canonical Neapolitan World Flag instead of the neutral fallback;
- `test/media_credits_234_test.dart`: required Aragonese/Friulian/Sardinian
  authors and CC BY-SA 3.0 attribution are visible in Image credits;
- startup/profile-gate and Course-entry animation regressions: canonical logo,
  reduced motion and latest-wins destination state passed;
- Neapolitan bundled-Course, discovery, provenance, audit and sample-course
  focused tests passed.

One focused catalog run initially failed because an older assertion assumed a
multi-section search could have only one matching section. The valid search
also matched metadata from the Neapolitan installed Course. The assertion now
checks the intended portable `builtin:IT` result without rejecting other valid
matches; the complete four-test file then passed.

## Release gate still to run

- changed-Dart formatting check;
- deterministic bundled-Course `--check` and full Course validator;
- full unsuppressed `flutter analyze --no-pub`;
- affected grouped Flutter regression set after formatting;
- exactly one complete final suite:
  `flutter test --no-pub --concurrency=1`;
- `git diff --check`, final status/scope and persistence-key inspection.

No package, archive, commit, stage, tag, push or publication is part of this
validation. Beta readiness will be assessed only after the pending release
gate, and any positive assessment applies to the *next* release rather than
renaming QQL 234.

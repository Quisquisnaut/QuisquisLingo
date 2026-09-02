# QuisquisLingo 2.0.22+222 release validation report

Date: 2 September 2026

## Release boundary

- Version: `2.0.22+222`.
- Mandatory 30-day Alpha expiry: end of 2 October 2026.
- Scope: opaque learner identity, learner-backup v2, separate `Imports`/`Exports` transfer folders, additive world flags, renderer-compatible US/UM stars, hidden Flag Game, local scorecards, focused release tests and metadata.
- Existing Course Model v4, course-flag meanings/rendering, XP, streak, Review, Duel, progression, TTS and learner-path behavior remain outside the feature change.

## Learner identity and backup

- New learners receive UUIDv4 identifiers generated with `Random.secure`; display names are presentation-only and duplicates are permitted.
- The authoritative registry/active keys are `learner_profiles_v2` and `active_learner_profile_id`. Learner values use the centralized `learner_<learnerProfileId>_<key>` namespace.
- Build 222 intentionally does not migrate or read the former name-based registry, active-name reference or name-derived namespaces. No synthetic default learner is written.
- Deletion and backup collection use the exact UUID namespace. Backup schema v2 supports preserve-ID restore, explicit replace on collision, and an independent separate copy with a new UUID and validated user-selected name.
- Import reads only `Documents/QuisquisLingo/Imports/learner_import.json`. Export remains in `Documents/QuisquisLingo/Exports` with its existing automatic learner-based filenames and numeric collision suffixes.

## World flags and Flag Game

- `assets/world_flags/manifest.json` contains 266 canonical entities: 249 ISO entries, of which 193 are UN Members and 56 are ISO extras; the eight-entry Shortlist; and nine Language-related flags for Sámi, Roma, Sorbian, Breton, Corsican, Occitan, Cornish, Friulian and Sardinian communities.
- The manifest SHA-256 is `61C9221A5736453B5DD68DD6A91C7ADADF5AE4A6F7CA1D6095BE82E242E08BF9`.
- Exactly 266 SVG files are referenced and packaged. ISO/Shortlist artwork remains from pinned `lipis/flag-icons` v7.5.0 commit `7aa5b2bdddd570ece62c812c0cb588ccdc099e2e`; the nine new Wikimedia Commons sources carry per-asset author, source-page, license and SHA-1 metadata. Both license notices are included in the Windows package.
- The United States (`US`) and United States Minor Outlying Islands (`UM`) assets retain the pinned source's 4:3 artwork and 50-star layout, with only its unsupported `marker-mid` construction expanded into explicit star paths. A scan of every world-flag SVG found no other active `<marker>`, `marker-mid`, `marker-start` or `marker-end` constructs. Friulian contains only inert CSS declarations whose values are `none`.
- Gameplay and the four non-overlapping reference categories derive from the same manifest. The categories are UN Members, ISO extras, Shortlist and Language-related flags; live category-scoped search matches trimmed, case-insensitive canonical names and aliases. Legacy course `CY` and `EN`, `flagCode`, custom Base64 precedence and `FlagPainter` are unchanged.
- The Settings flag retains the five-tap/click trigger and now exposes the `Flag Game` tooltip. The setup copy and stable-ID pool labels describe 12 flags with five choices. Seeded tests cover pool membership, option randomization, similarity-guided distractors and explicit near-identical exclusions.
- The timer begins after question one is rendered. Existing victory/defeat sounds accompany immediate correct/wrong feedback directly below the flag and automatic progression. Correct feedback reads `Correct` and advances after 800 ms (formerly 700 ms); wrong feedback reveals the canonical English answer and retains its 700 ms delay. A 12/12 result receives the perfect-result state.
- All four ID-keyed local Top 5 sections remain visible. Each existing compact score line now includes the achieved-at date. Ranking is score descending, elapsed time ascending, achieved-at ascending; duplicate names remain separate avatar entries and existing stable-ID history remains readable. Only best game records persist, with no XP, Weekly XP, streak, Laurel, Round/Lesson, Review, Duel or course-progress changes.

## Automated validation

- Ordered learner-profile identity gate: **9 tests passed** before any Flag Game micro-fix implementation began.
- Focused final-micro-fix gate: **35 tests passed**, covering exact `Imports`/`Exports` behavior, learner identity/backup semantics, both normalized 50-star assets, the complete active-marker scan, and US/UM rendering in Flag Game and reference views at 320 logical px.
- Exact world-flag asset-set gate: **9 tests passed**, including exact Shortlist and Language-related membership, provenance, uniqueness, canonical pool sizes, unchanged course flags, both 50-star normalizations and the complete active-marker scan.
- Final full suite: `flutter test --no-pub --reporter compact --timeout 60s` passed **385 tests** in **3 minutes 10 seconds**.
- `flutter analyze --no-pub`: no errors or warnings; the same two pre-existing info-only `curly_braces_in_flow_control_structures` diagnostics remain at `course_editor_service.dart:71` and `settings_service.dart:258`.
- `python tools\validate_courses.py`: all eight bundled Course Model v4 files passed.
- `python tools\validate_images.py`: reports only the pre-existing missing `assets/exercise_images/hello.webp` among 113 Image Bank assets. It remains deliberately unchanged.
- Responsive widget checks cover 320, 375 and 430 logical px under Default/system, Light and Dark modes without layout exceptions. No screenshots or screenshot harnesses were created.

## Windows release artifact

- `tools\package_windows_release.ps1` completed the Windows release build, added the VC runtime, validated staged contents, extracted the ZIP and matched extracted files against staging.
- Staged directory: `build/packages/quisquislingo_alpha_222_dev_windows_x64/`.
- ZIP: `build/packages/quisquislingo_alpha_222_dev_windows_x64.zip`.
- ZIP size: **25,682,064 bytes**.
- ZIP SHA-256: `22CDCAD1E9BCB5F474A2E34E032EDEEAA9D0DB7E6C59B94D911A68B107FF18E8`.
- Packaged world flags: exactly 266 SVGs and 266 manifest entities; the packaged US and UM files each contain 50 explicit stars and no marker element. The 193-entry UN pool, 249-entry UN + ISO pool, 257-entry UN + ISO + Shortlist pool and 266-entry All Flags pool are canonical. The MIT and Language-related asset license notices are present.

## Remaining release checks

The source diff, `git diff --check`, final status and authorized local release commit were audited after recording this report. The target-machine/manual checks in `docs/WINDOWS_RELEASE_TEST.md` remain the user's final visual and hardware validation boundary.

# QQL 242 validation status

Target: `2.0.42+242000`, **Build 242, Revision 0**.
Beta expiry: **2026-10-20 23:59:59 local time**.

The expiry is the 30-day policy recalculated from this release's own date,
20 September 2026. It coincides with Build 241's expiry because both releases
fall on 20 September. It is **not** the previous expiry carried forward, which
`AGENTS.md` warns against. `test/beta_lifecycle_test.dart` continues to pin
`2026-10-20` and was not modified.

## Scope validated

The media audit corrections and additions described in
`docs/242_CHANGE_SUMMARY.md`, derived from the findings in
`docs/MEDIA_LIBRARIES_PLAN.md`:

- The missing-recording backup fix and the Audio Library **File missing** state.
- The structured `mediaAttributions` field, its editor, its read-only surfaces
  and its propagation through Fork and Copy as New Course.
- The new `MEDIA_ATTRIBUTION_MISSING` Audit rule (registry 103 → 104).
- The corrected application flag credits and the test that derives them.
- The Publisher recorded-audio import rule.
- Removal of three obsolete image manifests and the new importable example bank.
- Shared-image deletion usage notice, bounded image decoding,
  `audio_orphan_check_last_*` reset coverage, Editor Help corrections and the
  documentation fixes.

## Course Model and compatibility

Course Model remains **v9/v10**; `formatVersion` is unchanged. `mediaAttributions`
is optional and omitted from JSON when empty, and `CourseChecksums` sorts keys
recursively, so a Course that records no credit produces byte-identical JSON and
byte-identical checksums.

This is asserted, not assumed: `test/media_attribution_test.dart` compares
`CourseChecksums.whole` and `.official` against the same Course with the key
removed, and re-verifies **both signed Dummy publisher fixtures** against their
original signatures.

Deliberate compatibility decision, recorded because `AGENTS.md` forbids silently
discarding course data: the Course root ignores unknown keys, so a Course
carrying credits that is opened and re-saved by an **older** build loses them.
Every previous optional field behaved this way, and a `formatVersion` bump would
be worse — an older build would reject the entire Course rather than drop one
field.

## Focused evidence during implementation

| Check | Result |
|---|---|
| `course_backup_missing_asset_test.dart` (new) + `course_backup_v9_clean_cut_test.dart` + `editor_help_translation_test.dart` | 16 passed |
| `media_attribution_test.dart` (new) | 10 passed |
| `media_attribution_test.dart` + `media_credits_234_test.dart` | 13 passed |
| `publisher_recorded_audio_test.dart` (new) | 4 passed |
| `example_image_bank_test.dart` (new) | 2 passed |

Counts overlap between runs and must not be summed into a unique total.

Two defects were found in my own test code during these runs and corrected
before proceeding: an `acceptedAnswers` constructor argument that does not exist
(the field is `accepted`), and a comparison of `CourseAuditIssue.code`, which is
a `String`, against an `AuditCode` enum value, which silently never matched.
Both were test-side errors, not implementation errors.

## Non-Flutter validators

Run separately because they are not part of the Flutter suite:

| Validator | Result |
|---|---|
| `tools/validate_courses.py` | 10 bundled Course Model v9 files valid |
| `tools/validate_images.py` | 111 assets, 92 semantic replacements, 5 padding-only normalizations, **0 issues** |
| `tools/validate_lesson_icons.py` | 14 assets, **0 issues** |
| `tools/validate_media_assets.py` | 443 files, 19 locked audio, 281 world flags, 22 static references, **0 issues** |

These are unchanged from Build 241, which confirms that deleting the three
obsolete `assets/exercise_images/` manifests disturbed nothing: neither
`validate_images.py` nor `validate_media_assets.py` reads them, and the
`manifest.json` the latter does read is `assets/world_flags/manifest.json`.

## Static analysis

`flutter analyze --no-pub` on the final tree: **No issues found.**

`git diff --check`: no whitespace errors. The LF/CRLF notices Git prints are
line-ending normalization only, which `AGENTS.md` records as not evidence of a
functional change.

## Complete test suite

Results recorded below once the run completes.

## Empirical check of the media-portability claim

The owner asked for the portability finding to be re-verified rather than taken
on trust. Re-checked against real artefacts rather than by reading code alone:

- A Course file stores media **paths**, never media bytes, except for embedded
  Lesson icons, an embedded custom flag and embedded Recognize-characters
  images. `ZipEncoder` appears nowhere in `lib/`, so no course package or audio
  pack exists.
- **The limitation is latent, not active.** Every artefact QQL ships uses only
  bundled `assets/` media and text-to-speech: all ten bundled courses are
  `audioMode: tts` with an empty Audio Library; `demo_courses/` uses 50 image
  references, all bundled paths; the publisher fixtures carry no media at all.
  A Course built that way is fully portable today.
- The gap therefore affects only a Course whose author imported their own
  pictures or recordings — which is why it has never surfaced in shipped
  content, and why it becomes decisive the moment shared media libraries or
  publisher media are built.

## Delivery limits

- No platform release executable, installer or package was generated.
- Manual device checks are a checklist, not a claim of execution; see
  `docs/242_VISUAL_CHECKLIST_IT.md`.
- No commit and no push were made. The working tree holds the change.
- The Dummy publisher configuration was not separately re-run for this release;
  the Publisher recorded-audio rule is covered by
  `publisher_recorded_audio_test.dart`, which signs its own fixture with the
  checked-in test key.

# Build 242 Revision 0 — change summary

Version: **2.0.42+242000**. Beta expiry: **2026-10-20 23:59:59 local**.

The expiry is the 30-day policy applied to this release's own date, 20 September
2026. It lands on the same day as Build 241 because both were released on 20
September; it is not the previous expiry carried forward.

This release is the outcome of a read-only audit of QQL's image and audio media,
requested by the owner and recorded with its full findings and reasoning in
[docs/MEDIA_LIBRARIES_PLAN.md](MEDIA_LIBRARIES_PLAN.md). It fixes one genuine
defect, closes a licence-compliance gap in the application's own credits, gives
course authors somewhere to record third-party media credits, and clears a
number of stale or misleading artefacts the audit uncovered.

Course Model stays **v9/v10**. No migration, no new storage, no persistence-key
change.

## The defect: a missing recording made a course unsaveable

`CourseBackupService.createBackup` threw when a referenced MP3 was absent, and
`confirmCourseChanges` calls it on the **persisted** course before applying a
change. So once a referenced recording disappeared, every later save failed —
including the edit that would have removed the broken reference. There was no
way out from inside the application.

It was reachable from a documented procedure: Device Administration → **Remove
imported media → Audio files**, which the Build 241 visual checklist instructs
the tester to run.

- The backup now records the gap in its manifest (`missing: true`, no path, no
  checksum) and continues, because a file that is already gone cannot be lost by
  the change the backup precedes.
- Records that **do** name a copied file keep their strict existence and
  SHA-256 checks, unchanged. A record cannot claim to be a gap while still
  naming a file, so the marker cannot smuggle an unvalidated asset through.
- Restore leaves a gapped clip's stored path alone and remaps the rest as before.
- Audio Library marks such rows **File missing** and says how to repair them.
  The orphan check still means "no word associated" and is unchanged — a clip
  with a word but no file was never an orphan, which is why nothing reported it.
- The imported-media reset now warns that courses using removed recordings will
  need repairing.

The existing transaction regression in
`test/course_editor_transaction_225_04_test.dart` asserted the old throw. It now
checks that removing a missing recording succeeds, increments the Course version
once, and preserves the original Course and the recorded gap in a verified
pre-change backup. Real backup-write and persistence failures remain blocking.

## Media credits

Course Info Editor gains a structured list under **License / Rights**: author
and licence required, optional title, source and scope. It records credit for
images and recordings made by someone else — an imported picture, a recording
another person performed, a custom Lesson icon or course flag.

- Shown read-only in **Course Info** and in **Credits**, with the same caveat
  already used for Rights Holder: descriptive, never controlling QQL permissions.
- Carried by **Fork** and **Copy as New Course**, because the derivative
  contains the same media.
- The credits travel inside the Course file even though, for recordings and
  ordinary exercise images, the media bytes do not.
- `formatVersion` stays **9**. The field is omitted from JSON when empty and the
  canonical digest sorts keys, so every existing course, backup and publisher
  signature is byte-identical. Proven rather than argued: the test suite
  re-verifies both signed Dummy fixtures against their original signatures.
- Deliberate compatibility decision: the Course root ignores unknown keys, so a
  course carrying credits that is opened and re-saved by an **older** build
  loses them. Every previous optional field behaved this way. A version bump
  would be worse — an old build would reject the whole course rather than drop
  one field.

Course Audit adds **`MEDIA_ATTRIBUTION_MISSING`** (Warning), taking the registry
from 103 to **104 rules**, approved by the owner. It fires when a course carries
media of its own — an embedded Lesson icon, an embedded flag, a `data:` image,
an imported recording or an imported exercise image — and records no credit.
Media shipped with QuisquisLingo does not trigger it, and the warning never
blocks export or import.

## The application's own flag credits were incomplete

`assets/world_flags/LICENSE-language-related-flags.md` records **24**
community or regional language flags, **five** of which require attribution.
The Image credits page claimed nineteen flags, listed three attributions, and
closed by saying the remainder were public domain or CC0.

**Mirandese (ItsGandaM1ke, CC BY 4.0)** and **Venetian (F l a n k e r,
CC BY-SA 3.0)** were therefore shipped uncredited, and the closing sentence was
false. The history is legible: originally 19 flags = 16 public domain + 3
attributed; five were added, `docs/MEDIA_CREDITS.md` was partly updated and the
application was not.

Both are now corrected, along with the two stale numerals in `MEDIA_CREDITS.md`.
The real fix is in the test: it now **derives** the expected attribution set
from the licence file instead of naming three authors, so adding a flag cannot
leave the credits page behind again.

## Publisher Courses and recorded audio

A Course file carries clip paths, never MP3 bytes. A custom author can repair a
broken path; a publisher cannot, because the path is inside the signed payload.
Such a course would install silently broken and stay that way.

A Publisher Course whose Audio Library points anywhere outside `assets/` is now
refused, at import and again at installation, before the signature is checked.
Custom courses are unaffected. The signing guide documents what a Publisher
Course can and cannot carry.

## Stale and misleading artefacts removed

- **Three obsolete manifests** deleted from `assets/exercise_images/`:
  `manifest.json`, `manifest_external.json` and `image_bank_manifest.json`,
  about 92 KB shipped in every build. Runtime code did not read them, two were
  byte-identical, and all three carried a superseded bilingual tag set that no
  longer matched the live catalogue. A test added in QQL 234 already forbade
  runtime code from reading them; the files themselves were never removed.
  Two image-integrity tests still read `manifest.json`; the Build 242 follow-up
  points them at the authoritative `metadata_v2.json` catalogue while retaining
  the asset-count, dimensions and transparent-border checks.
- One of them was also the **only Image Bank example in the repository**, and it
  could never be imported: every ID in it belongs to the bundled catalogue, and
  the importer refuses IDs the application already has. A genuine importable
  example now lives in **`demo_image_banks/example_image_bank.zip`** — outside
  `assets/`, so it is not shipped inside the application — with a test that
  imports it through the real importer.
- `RecordedAudioService.deleteFiles` removed: zero callers, superseded by
  `ManagedAudioCleanup`.
- `ImageBankService.fixedImportDirectory` was a byte-identical copy of
  `ExerciseImageService.fixedImportDirectory`; there is now one definition.

## Smaller corrections

- Deleting a shared image or an Image Bank now names the courses that still
  reference it, using the existing `MediaReferenceIndex`. Deletion still
  proceeds — an admin needs a way out — but it is no longer invisible. If the
  stored courses cannot be read, the dialog says so rather than implying nothing
  uses the image.
- Image decoding is bounded at every render site. Nothing limited the pixel
  dimensions of a path-based exercise image, so a 50 KB file declaring
  30,000 × 30,000 could be rasterized in full. The portable path already
  enforced 4096.
- `audio_orphan_check_last_*` is now declared in `AppResetService` and the
  storage inventory, as the change-discipline rule requires, and the audio media
  reset clears it.
- Editor Help, English and Italian, no longer claims images and Image Bank ZIPs
  have no file picker; both routes are documented, and a test asserts it.
- `docs/AUDIO_LIBRARY.md` described MP3 storage as grouped by learning language;
  it is grouped per Course. Corrected, along with its stale version references.
- `AGENTS.md` stated the Audit registry as 102 rules in one place and 103 in two
  others. Corrected.
- Recorded why the sixteen unreferenced bundled sample MP3s are deliberately
  kept, with the caveat that their provenance is still unresolved.

## Known limits, unchanged by this release

**Media does not travel with a course.** Export produces exactly one JSON file;
there is no course package and no audio pack. Embedded media — Lesson icons, a
custom flag, Recognize characters images — travels. Recorded MP3s and ordinary
exercise images do not, on **any** course type. Shipping an Image Bank alongside
does not repair a course, because importing one mints fresh timestamped paths.

The credit field records **credit**, not bytes, and does not change this. A
portable media package remains the open structural gap; see
`docs/MEDIA_LIBRARIES_PLAN.md` §7.

Also unchanged: the shared Image Library remains device-wide and admin-managed,
the Audio Library remains per-course and maintainer-managed, and no permission
gate was relaxed.

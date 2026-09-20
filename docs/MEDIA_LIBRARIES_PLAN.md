# Media libraries — audit findings and implementation plan

Written 2026-09-20 against a clean tree at `4009528` (Build 241 Revision 2,
`2.0.41+241002`). It records a read-only audit of QQL's image and audio media,
the owner's decisions, and the work those decisions imply.

**Status: Tranches A, B and C and the Image Bank example were implemented the
same day and delivered as Build 242 Revision 0 (`2.0.42+242000`).** See
`docs/242_CHANGE_SUMMARY.md` and `docs/242_VALIDATION.md`. What remains open is
listed in §7 Deferred, and the audit sections below are kept as the record of
why each change was made.

One correction to §2.2, established empirically after the audit: the
non-portability of imported media is real but **latent**. Every artefact QQL
actually ships — all ten bundled courses, the demo course and the publisher
fixtures — uses only bundled `assets/` images and text-to-speech, with zero
audio clips. A course built that way is fully portable today. The limitation
bites only a course that imports its own pictures or recordings, which is why it
has never surfaced in shipped content.

Read `AGENTS.md` first: its rules bind this work (smallest change, no unrelated
refactors, never commit or push unless asked, focused tests while iterating then
the analyzer and the full suite once at the end, `rg`/git rather than PowerShell
`Get-Content`, and any new persistent key or folder must also be added to
`AppResetService`, `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md`).

Every delivered tranche needs its own version bump in `pubspec.yaml` and a
refreshed Beta expiry in `lib/services/beta_lifecycle_service.dart`, its tests,
`README.md` and current documentation. The tranche-to-version mapping is not
decided here.

## 1. Owner decisions (settled — do not re-open)

| Topic | Decision |
|---|---|
| Publisher courses declaring recorded MP3 clips | **Reject at import.** The signature makes the path immutable, so it can never resolve on a learner's device. |
| The 16 unreferenced bundled sample MP3s | **Keep**, and document why they are retained. |
| Media attribution metadata | **Structured list**, not a single free-text block. |
| Audit registry 103 → 104 | **Approved** for one new rule, `MEDIA_ATTRIBUTION_MISSING`. |
| The three obsolete image manifests | **Delete all three** (option A). |
| An Image Bank example for authors | **Yes, as its own small job**, placed outside `assets/`. |

## 2. What the audit established

### 2.1 Six media families, not two

| Family | Bytes live in | Scope | In exported Course JSON |
|---|---|---|---|
| Shared Image Library (bundled) | `assets/exercise_images/` — 111 WebP | app build | reference only, resolves anywhere |
| Shared Image Library (local + banks) | `<AppSupport>/exercise_images/`, `<AppSupport>/image_banks/<bankId>/images/` | **device-global** | **absolute path only** |
| Course Audio Library (recorded MP3) | `<AppSupport>/quisquislingo_audio/course_<sha256(courseId)>/` | per course | **absolute path only** |
| Portable exercise images | embedded `data:image/…;base64` | per course | **bytes** |
| Custom Lesson icons | embedded `lessonIconAssets[].base64Png` | per course | **bytes** |
| Course flags | `assets/world_flags/` (281 SVG) or `flagImageBase64` | app build / per course | **bytes** when custom |

Non-authorable bundled media: `assets/audio/` (3 duel WAV + 16 sample MP3),
`assets/lesson_icons/` (14 PNG), `assets/mascots/` (10), `assets/lesson_plants/`
(6), `assets/branding/` (2), hash-locked by `tools/media_asset_hashes.json`.

### 2.2 Distribution boundary

Course export produces **exactly one JSON file**
(`CustomCourseTransferService.buildCourseExport`). `ZipEncoder` is never used in
`lib/`; `ZipDecoder` exists only to read Image Bank ZIPs on import. There is no
course package format, and the Audio Pack described in `docs/AUDIO_PACKS.md`,
in Editor Help and in a `RecordedAudioService` comment does not exist.

The embedded/not-embedded split is **by media family, not by course type**.
Publisher and Custom courses behave identically; the only difference is that a
Publisher course's signature freezes the dead references permanently.

Shipping the Image Bank ZIP alongside a course **does not repair it**:
`importBankZip` mints `bank_${DateTime.now().microsecondsSinceEpoch}` and stores
the resulting absolute path, so the recipient's paths encode an import timestamp
and are unreproducible. Single images (`<microseconds>_<name>`) and MP3 clips
(`audio_<batchStamp>_<index>`) are the same. **For ordinary exercise images and
recorded audio there is currently no procedure — automatic or manual — that
makes a course portable.** The only portable image route is the Recognize
characters preset, which embeds bytes.

### 2.3 Two independent authorities

| Surface | Authority |
|---|---|
| Shared Image Library: import, metadata edit, delete, bank removal | **Admin** (`ExerciseImageMetadataService._requireAdmin`) |
| Audio Library, exercise images, Lesson icons | **Course Maintainer or assigned Team** (`CourseAccessPolicy.canEditOriginal`) |
| Publisher Course uninstall | **Admin**, blocked while any other profile includes it |
| Any media on Bundled or Publisher courses | nobody — `canEditOriginal` is false for all official courses |

These never intersect: a device admin who is not the Maintainer cannot touch a
course's audio, and a Maintainer who is not an admin cannot touch the shared
library. `settings_admin_media_library_234_revision_test.dart` pins all four
cells.

### 2.4 Two image contracts, correctly partitioned

`script_recognition` (Recognize characters / Image to text / Text to image) is
portable-only: the editor converts a picked library image into course-owned
bytes, `course_audit_service.dart` enforces it, and `PortableExerciseImage`
renders it. Every other exercise type is path-based via `_exerciseImage`.
Verified: a non-portable path cannot reach the portable renderer. This partition
is consistent and is **not** a defect.

## 3. Findings

### F1 — A missing MP3 permanently blocks saving a custom course

`CourseBackupService.createBackup` throws `StateError('Course-owned backup asset
is missing: …')` (`lib/services/course_backup_service.dart:173`).
`confirmCourseChanges` calls it unguarded on the **persisted** course
(`lib/services/course_editor_service.dart:702`). Once a referenced MP3
disappears, every confirm fails — including the one that would remove the broken
reference, because the backup is taken from the stored version, not the working
copy. The Audio Library's orphan tool only finds clips with empty `text`, so a
clip *with* text and no file is not repairable in-app.

Realistic trigger: **Remove imported media → Audio files**, which
`241_REVISION_2_VISUAL_CHECKLIST_IT.md` §8 instructs the tester to run. The reset
dialog warns that courses "may then show missing media" but not that they can no
longer be saved.

No test asserts this throw. Severity: highest — it is data-loss-adjacent and
reachable from a documented test procedure.

### F2 — Publisher Courses cannot ship recorded audio

Same throw at `lib/services/course_editor_service.dart:870` on the signed-update
path. A publisher's `audioLibrary[].filePath` is an absolute path on their own
machine, covered by the signature and therefore immutable. The three Dummy
fixtures are all `audioMode: tts` with zero clips, so nothing exercises it.
`tools/sign_course.dart` warns about neither audio nor image references.

### F3 — Editor Help is stale for media file dialogs

`lib/screens/editor_help_content.dart:165` (EN) and `:354` (IT) state that images
and Image Bank ZIPs use the Imports folder *"without a file picker"* /
*"senza finestra di selezione file"*. Build 240 added `Open Image Bank ZIP from…`,
`Open single image from…` and Audio Library `Open from…`. The string "Open from"
appears **zero** times in the whole Editor Help. The Audio Library entries at
`:160` and `:349` have the same omission.

### F4 — Shared Image Library deletion leaves dangling references

`_deleteLocal` and `_removeBank` delete their files correctly, but neither checks
whether a stored Course still references the path. Both dialogs say "Existing
exercise references must be changed separately", so the behaviour is disclosed —
but one admin can silently break another Maintainer's course, and no audit rule
will report it.

### F5 — 16 bundled sample MP3s are referenced by nothing

`assets/audio/{cy,de,en,es,fi,it,nl,pt}_sample/sample_{1,2}.mp3`, 78.8 KB total,
declared in `pubspec.yaml`, hash-locked, validated on every release, and
referenced by no bundled course (all ten are `audioMode: tts`, zero clips) and no
code. **Owner decision: keep them, and record the reason.**

### F6 — Unbounded imported-image storage (already planned, never built)

`<AppSupport>/exercise_images/` has no quota, no reference counting and no
cleanup. This is **not a new finding**: it is specified in full, with the owner's
decisions already locked, in `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`, and was
never implemented because the agent launched for it had no model credits. Treat
it as a deferred deliverable against that plan, not as a fresh proposal.

`RecordedAudioService.deleteFiles` has **zero callers** in `lib/` and `test/` —
superseded by `ManagedAudioCleanup` and already noted as dead in the 240 plan.

### F7 — Licence attribution is incomplete in the shipped app

The authoritative record is `assets/world_flags/LICENSE-language-related-flags.md`:
**24** community/regional language flags, of which **five** require attribution —
Aragonese (Willtron, CC BY-SA 3.0), Friulian (Ipankonin, CC BY-SA 3.0), Sardinian
(Angelus, CC BY-SA 3.0), **Mirandese (ItsGandaM1ke, CC BY 4.0)** and **Venetian
(F l a n k e r, CC BY-SA 3.0)**. `world_flag_dataset_test.dart:60` pins the 24.

The history is legible: originally 19 flags = 16 public domain/CC0 + 3
attribution-required. Five were later added, giving 24 = 19 + 5.

Two artefacts did not keep up:

1. **`lib/screens/credits_screen.dart:120`** — the user-visible Credits screen.
   Says *"Nineteen community or regional flags"* (the old total), lists only the
   original three attributions, and closes with *"The remaining language-related
   files are public domain or CC0"*, which is now **false**. Two
   attribution-required works are therefore uncredited in the shipped Beta.
   `media_credits_234_test.dart` asserts only the three old names, so the test
   actively locks the incomplete list in place.

2. **`docs/MEDIA_CREDITS.md:25-39`** — partially updated. The total ("twenty-four")
   and the list (all five) are correct, but two numerals were missed: it says
   *"Sixteen are public domain or CC0"* (should be nineteen) and *"the **three**
   attribution-required files are:"* immediately before listing five. It also
   claims *"The same five attributions are presented in the in-app Image credits
   page"* — which is not true today.

This is a licence obligation, not cosmetics. It should rank above F4 and F6.

### F8 — Three obsolete image manifests still ship, one of them a trap

`assets/exercise_images/` contains the live `metadata_v2.json` plus
`manifest.json`, `manifest_external.json` and `image_bank_manifest.json`. The
latter two are **byte-identical** (32,177 bytes each).
`exercise_image_manifest_234_test.dart:64` exists specifically to forbid runtime
code reading any of the three — they were superseded but never deleted, and the
whole directory is declared in `pubspec.yaml`, so roughly 92 KB of dead payload
ships in every build.

They have also **drifted**: all three still carry the bilingual EN+IT tag set from
QQL 234 (`bread` → `bread, pane, loaf, filone`) while the live catalog is
English-only (`bread, loaf`). All 111 records differ.

Worse, `image_bank_manifest.json` is the only example of a bank manifest anywhere
in the repository, so it is the natural template for an author — yet a bank built
from it would be rejected outright, because `importBankZip` refuses IDs that
already exist in the app and every ID in it is a bundled ID.

### F9 — Path-based exercise images have no dimension bound

Build 241 added header-only inspection precisely to avoid rasterizing untrusted
images (`ExerciseImageService.inspect`, with a comment about a 50 KB PNG
declaring 30,000 × 30,000). But `_importCustomImage`
(`lib/screens/course_editor_screen.dart:8983`) never calls `inspect`, the library
import only *warns* above 512 px, and `_exerciseImage` renders with `Image.file`
and no `cacheWidth`/`cacheHeight` — there is no `cacheWidth` anywhere in `lib/`.
The portable path enforces 1–4096; the path-based path enforces nothing.

Blast radius is mostly the authoring device, since an imported course's absolute
paths will not resolve elsewhere.

### F10 — An undeclared preference key

`audio_orphan_check_last_<COURSECODE>` (`lib/services/settings_service.dart:82`)
is device-level and unprefixed, and appears in neither `AppResetService`, nor
`InventoryService`, nor `docs/239_RESET_STORAGE_INVENTORY.md` — which `AGENTS.md`
requires for every new persisted key. Harmless in content (a timestamp), but it
survives every reset except `everything`, and being device-level means one
learner's orphan check suppresses the prompt for all learners for seven days.

### F11 — Historical duplication

- `ImageBankService.fixedImportDirectory()` and
  `ExerciseImageService.fixedImportDirectory()` are byte-identical method bodies
  computing the same path, with no test pinning their equivalence.
- The same literal paths are re-spelled in four strings in
  `lib/widgets/file_dialog_feedback.dart` and about eight Help strings.
- Two different files are both named `portable_exercise_image.dart` (a service
  and a widget).
- `RecordedAudioService.deleteFiles` is dead code (see F6).

### F12 — `docs/AUDIO_LIBRARY.md` describes a superseded storage layout

It states *"Physical MP3 storage is grouped by learning language"*, which matched
`docs/226_03_VALIDATION.md:61` at the time. Storage is now grouped by
`course_<sha256(courseId)>` (`RecordedAudioService.storageDirectoryForCourseId`).
The file also still refers to "QuisquisLingo 0.5.5" and the "226.03 revision-1
workflow".

### 3.1 Prior intent worth honouring

`docs/AUDIO_PACKS.md` already records two owner positions that the plan below
follows rather than invents:

- *"Recorded files and their performers must have explicit rights documentation."*
- *"The Course Audit should eventually verify missing files, orphaned files,
  duplicates, unsupported formats and declared fallback behavior."*

Note the unresolved tension: that document describes a **network downloader** for
audio packs, while `AGENTS.md` requires QQL to stay offline-first and to avoid
network dependencies for learner/course functionality. Not addressed here.

## 4. Tranche A — corrections (no open decisions)

### A1. Unblock saving when a referenced MP3 is gone (F1, and F2's crash)

The pre-change backup's purpose is to snapshot what exists. A file that is
already gone cannot be lost by the change, so aborting protects nothing.

1. `lib/services/course_backup_service.dart:173` — replace the `throw StateError`
   with a recorded gap: append `{'originalPath': …, 'missing': 'true'}` and
   `continue`, writing no file and no hash.
2. `lib/services/course_backup_service.dart:277` (`loadBackup`) — accept a record
   whose `missing` is `'true'` and which declares no `backupRelativePath` or
   `sha256`, and skip it for path remapping. Any record that **does** claim a
   relative path keeps today's strict existence-plus-SHA-256 check, unchanged.
   Restore already falls back via `restoredAssetPaths[clip.filePath] ?? clip.filePath`.
3. `lib/screens/course_editor_screen.dart:10751` — mark missing rows in the Audio
   Library list, resolved through the existing `resolveSourceForClip`. Each row
   already has a delete button that removes the reference from the working copy,
   so once the save is unblocked, repair is a two-tap operation that already
   exists.
4. `lib/screens/device_administration_screen.dart:437` — extend the
   `importedMedia` reset plan text to say that affected courses need their
   recording references repaired in Audio Library.

**Deliberately not done:** wrapping the `createBackup` call in a try/catch at
`course_editor_service.dart:702`. That would silently discard the pre-change
backup and void the rollback guarantee the 225.04 transaction boundary exists to
provide.

Tests: backup succeeds with a missing asset and records the gap; restore leaves
that clip's path alone; a tampered **present** asset is still rejected; the Audio
Library row shows the missing state.

### A2. Editor Help catches up with Build 240 (F3)

Narrow string edits at `editor_help_content.dart:160/165` (EN) and `:349/354`
(IT): replace the "without a file picker" claim with both routes — fixed folder
**and** `Open from…` — using the phrasing already established for the Build 240
dialogs (cancel is silent; failures name the file only and explain the
fixed-folder route). Extend `editor_help_translation_test.dart` to assert that
both languages mention the dialog route, so this cannot drift again.

### A3. Documentation corrections (F12, and the `AGENTS.md` registry numeral)

- `docs/AUDIO_LIBRARY.md`: correct the MP3 storage layout to
  `course_<sha256(courseId)>`; drop the stale version references.
- `AGENTS.md:53` says *"the Audit Registry remains at 102 rules"*. The code, the
  in-app Audit Codes screen and both pinning tests all say 103. One-word fix.

## 5. Tranche B — media attribution (F7 + the structured field)

### B1. Model

New `CourseMediaAttribution` in `lib/models/course_models.dart`, sited next to
`CourseRightsHolder`:

| Field | Required | Notes |
|---|---|---|
| `author` | yes | who must be credited |
| `license` | yes | e.g. `CC BY-SA 3.0` |
| `title` | no | the work's name |
| `source` | no | page reference or URL, stored and rendered as plain text |
| `appliesTo` | no | which media in this course it covers |

`Course` gains `final List<CourseMediaAttribution> mediaAttributions` defaulting
to `const []`, serialised with the existing optional-list pattern already used by
`rightsHolders` and `lessonIconAssets`:

```dart
if (mediaAttributions.isNotEmpty)
  'mediaAttributions': mediaAttributions.map((e) => e.toJson()).toList(),
```

`fromJson` mirrors `rightsHolders` exactly — list-or-throw, entries-must-be-
objects-or-throw. Validation follows the house style (`CourseAuthor`,
`_normalizeTags`): trim, collapse internal whitespace, reject empty required
fields, reject exact duplicate entries. Caps: 200 characters for `author`,
`license`, `title` and `appliesTo`; 500 for `source`; 200 entries maximum.

`source` is **not** rendered as a tappable link — it can arrive in an imported
course, and QQL is offline-first. Plain text also keeps
`"Wikimedia Commons, File:Foo.svg"` valid alongside a URL.

### B2. Why this needs no format version bump

`CourseChecksums._canonical` sorts keys recursively before hashing
(`lib/services/course_checksums.dart:22`), and the field is omitted when empty.
Therefore every existing course file parses unchanged, every existing checksum is
**byte-identical** (including every signed Publisher `officialChecksum`), and the
Dummy v1/v2 fixtures keep verifying without regeneration. No `formatVersion`
bump, no migration, no v11.

**Lock this with an explicit test**, not with an argument: pin a fixture's
`CourseChecksums.whole()` and `.official()` digests, and re-verify both Dummy
fixtures.

### B3. Audit rule (registry 103 → 104, approved)

```
MEDIA_ATTRIBUTION_MISSING · Warning · Course Info
meaning:       The course carries media that did not ship with the app, but
               records no media attribution.
trigger:       lessonIconAssets, flagImageBase64, a data: image, a non-assets/
               audio clip or a non-assets/ exercise image is present while
               mediaAttributions is empty.
creatorAction: Add the author and licence of each third-party image or recording
               in Course Info Editor, under License / Rights.
```

Courses using only bundled app images do **not** fire it — those are QQL's own
credits, not the author's. Warning rather than error, so it never blocks Publish
or Export, consistent with the existing "export remains possible for work in
progress" rule.

Update the two pinned counts: `test/audit_code_registry_226_02_test.dart:15` and
`test/audit_branch_ownership_226_02_revision4_test.dart:212`.

### B4. UI

1. **Course Info Editor**, inside the existing `License / Rights` block
   (`course_editor_screen.dart:1322`) — add/edit/remove list with the same
   interaction shape as Authors/Contributors, gated by `_canModify`.
2. **Course Info** (read-only) after `course_info_screen.dart:211`, carrying the
   same caveat already used for Rights Holder: descriptive, does not control QQL
   permissions.
3. **Credits screen** course card (`credits_screen.dart:87`), which already prints
   course authors and licence.

### B5. Fix the app's own attributions (F7)

- `lib/screens/credits_screen.dart:120` — 24 rather than "Nineteen"; add
  **Mirandese — ItsGandaM1ke, CC BY 4.0** and **Venetian — F l a n k e r,
  CC BY-SA 3.0**; remove the now-false "the remaining … are public domain or CC0"
  sentence. Mirror the wording already in `docs/MEDIA_CREDITS.md`.
- `docs/MEDIA_CREDITS.md` — "Sixteen" → nineteen; "the three attribution-required
  files" → five.
- `test/media_credits_234_test.dart` — **derive** the expected attribution set
  from `assets/world_flags/LICENSE-language-related-flags.md` instead of
  hard-coding three names, so adding a flag can never again leave the Credits
  screen behind. This is the part that actually prevents recurrence.

### B6. Publisher guide

`PUBLISHER_SIGNING_GUIDE.md` §7 gains the expectation; §6's owner checklist gains
a line to check media attributions before approval. Worth stating: because the
field sits inside the signed payload, a publisher's attributions are
tamper-evident.

### B7. Reset and Inventory

No new preference key and no new folder — the field lives inside the Course
record. `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md` therefore need **no** change. Recorded here
because `AGENTS.md` requires the check to be made explicitly.

## 6. Tranche C — remaining corrections

- **C1 (F2).** Reject `externalOfficial` imports whose `audioLibrary` contains any
  entry with a `filePath` not starting with `assets/`, in
  `CustomCourseTransferService.courseFromBytes`, with a plain message. Add a
  fourth Dummy fixture carrying a recorded clip so the rule is locked by a test
  rather than by the accident that all three current fixtures are TTS-only.
  Document the limitation in `PUBLISHER_SIGNING_GUIDE.md` §7.
  *Consider*, and decide separately: whether the same rule should extend to
  non-bundled `imageAsset` paths, which are equally dead and equally immutable
  once signed.
- **C2 (F4).** Before `_deleteLocal` and `_removeBank` in
  `flat_image_library_screen.dart:231`, build a `MediaReferenceIndex` from the
  stored courses and put the count and affected course titles in the confirmation
  dialog. Do **not** block the delete — an admin needs a way out.
- **C3 (F9).** Bound the decode: pass `cacheWidth`/`cacheHeight` at the two
  path-based render sites, and warn (not reject) at import when dimensions are
  large. Rejecting at import would invalidate already-authored content.
- **C4 (F10).** Add `audio_orphan_check_last_` to `AppResetService`,
  `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md`. Whether it should
  also become per-learner is a separate behavioural question.
- **C5 (F11).** Collapse the duplicated `fixedImportDirectory` to one
  implementation with a test pinning the shared path; delete the dead
  `RecordedAudioService.deleteFiles`.
- **C6 (F5).** Record in `docs/234_MEDIA_AUDIT.md` why the 16 sample MP3s are
  retained despite being unreferenced.

- **C7 (F8).** Delete `assets/exercise_images/manifest.json`,
  `manifest_external.json` and `image_bank_manifest.json`.

  **Cost: three file deletions and updating two image-integrity tests.** Neither
  `tools/validate_images.py` nor `tools/validate_media_assets.py` reads them —
  the `manifest.json` the latter loads is `assets/world_flags/manifest.json`, a
  different file. `exercise_image_manifest_234_test.dart` asserts on source-code
  text, not file existence, so it is unaffected. The subsequent full-suite
  diagnosis found two tests in `media_asset_integrity_234_test.dart` still reading
  `manifest.json`; they must use the authoritative `metadata_v2.json` catalogue.
  Git history keeps the files if
  they are ever wanted back.

  Rationale: anything under `assets/` is packed into the app and shipped to every
  learner's device, so an author-facing template does not belong there; the files
  are unread; two are byte-identical; and all three carry a superseded bilingual
  tag taxonomy that no longer matches the live catalog.

## 6a. Separate small job — a real Image Bank example

Approved as its own task, **not** part of any tranche above, and explicitly
**outside `assets/`** so it is never shipped inside the app.

Deliverable: a small importable `.zip` containing a valid
`image_bank_manifest.json` plus two or three tiny original images.

Requirements:

- **IDs must not collide with the 111 bundled images.** `importBankZip` rejects
  any ID already present in the app, which is precisely why the old file could
  never be imported. Use an obvious prefix such as `example_`.
- Images must be original and licence-clean — simple generated shapes are
  honest and sufficient. Do not copy bundled WebP files into it.
- Must satisfy the real importer: unique IDs, `primary_term` or `label`, safe
  filenames, supported extensions, and the documented limits.
- **Mark it binary in `.gitattributes`** (`-text -diff`, as
  `test/fixtures/publishers/*.bin` already is), or Windows newline conversion
  will corrupt the archive. This is the same trap Build 241 hit with the
  publisher fixtures.
- Must **not** be added to `pubspec.yaml` assets.
- A test should import it through `ImageBankService` so the example is proven to
  work rather than assumed to.

Open minor point: location. `demo_courses/` is the established folder for example
material that ships in the repository but not in the app, though its name implies
courses. A sibling `demo_image_banks/` reads better. Either is fine; pick one at
implementation time.

## 6b. Owner direction recorded after implementation

A shared/categorised media library was proposed once Build 242 was under way.
The owner's settled points, for whoever builds it:

- The Audio Library **stays inside each Course**. No move to device-level clip
  storage, so `audioLibrary` keeps its current meaning.
- **No relaxation of the current permission gates**: the shared Image Library
  stays admin-managed, Course media stays Maintainer/Team-managed.
- Media that may not be reusable for licensing reasons must not be offered for
  reuse in another Course. Agreed, with one refinement: prefer **not listing it
  in the reuse picker at all** over listing it disabled, and make the cut by
  *who imported it* rather than by course type — bundled is reusable, Publisher
  never is, custom is reusable to the profile or Team that imported it and not
  to others.
- **Custom TTS-generated MP3** is a planned next feature. It does not exist
  today: there is no TTS-to-file path anywhere in `lib/`. When built, generated
  clips should default to **non-distributable**, because many system voices
  forbid redistributing synthesized audio, and the voice vendor belongs in
  `mediaAttributions`.
- Publisher media remains an empty category until a media package exists, and
  the package should then carry an explicit publisher-set reuse flag rather than
  QQL inferring permission from a licence string.
- Before bundled audio is offered to authors, the unresolved provenance of the
  sixteen sample MP3s (§F5, `docs/234_MEDIA_AUDIT.md`) must be settled.

## 7. Deferred

- **Remove unused media** (F6) — build against
  `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md` unchanged; its decisions are already the
  owner's.
- **Per-asset attribution linkage.** `lessonIconAssets` have stable `assetId`s and
  `audioLibrary` clips have `id`s, but embedded `data:` images and the course flag
  have no identity at all, so no uniform reference scheme exists. `appliesTo` as
  free text covers the need until a real media package format arrives.
- **A portable media package.** The single largest structural gap (§2.2): without
  it, ordinary exercise images and recorded audio cannot travel with a course at
  all. `docs/AUDIO_PACKS.md` sketches one, but its network-download model
  conflicts with the offline-first rule in `AGENTS.md`.

## 8. Validation

Per `AGENTS.md`: focused tests while iterating, then `flutter analyze` and the
complete suite **once** on the final tree of each tranche. Re-run the
non-Flutter validators that media touches — `tools/validate_images.py`,
`validate_lesson_icons.py`, `validate_media_assets.py`, `validate_courses.py` —
because none of them are part of the Flutter suite. `git diff --check` for
whitespace. Tranche B additionally requires proving checksum invariance and
re-verifying both signed Dummy fixtures.

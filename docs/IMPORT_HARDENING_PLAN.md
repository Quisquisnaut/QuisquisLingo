# Import security hardening and import architecture — audit and plan

Status: **in progress.** Written 2026-09-21 against QQL Build 243 Revision 4
(`2.0.43+243004`, commit `b0db270`). Done so far: Tranche 0 (Revision 6), the
image library tidy-up (Revision 7) and badge order plus removal (Revision 8).
Current state and next steps: [IMPORT_HARDENING_HANDOFF.md](IMPORT_HARDENING_HANDOFF.md).

Read `AGENTS.md` first. Its rules apply to all of this work: smallest correct
change, no unrelated refactors, no commit or push without a request, focused
tests during work and analyzer plus the full suite once at the end, `rg`/git and
never `Get-Content`, and every new preference key or folder added to
`AppResetService`, `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md`.

This is a security and architecture revision, not a multifile picker change.
The multifile dialogs are the last user-visible step of each tranche, built on
a common staging and validation layer. `file_selector 1.1.0` already provides
`openFiles`, so no new picker package is needed.

**The architectural rule:** picker, fixed-folder import, TTS generation and
Course-package extraction never have separate trust rules. They are different
sources feeding the same validators and the same commit pipeline.

---

## 1. Audit results

The owner's audit was written against Build 242. Every finding was re-checked
against Build 243 Revision 4. Findings are marked **Confirmed**, **Changed**
(still true, but Build 243 changed the facts), or **New** (not in the owner's
audit).

### 1.1 Findings confirmed

| # | Finding | Where |
|---|---|---|
| C1 | `openBytes` is single-file, trusts `length()`, then `readAsBytes()` loads the whole file. Bytes are not counted while reading. | `lib/services/file_dialog_service.dart:141-157` |
| C2 | Per-caller "dialog read caps" sit above the real limits: MP3 128 MB, Image Bank 128 MB, exercise image 8 MB, Lesson icon 16 MB, Course package 300 MB. The whole file is in RAM before the real limit applies. | each service's `_dialogReadCap` |
| C3 | Audio `Open from…` imports one MP3. | `recorded_audio_service.dart:95` |
| C4 | MP3 accepted by filename plus 50 MB only. No content check on either route. | `recorded_audio_service.dart:57-122` |
| C5 | Shared/exercise image import checks extension and size, then writes the file. The strong validator is not called. `inspect()` runs only after the write. | `exercise_image_service.dart:39-98`, `flat_image_library_screen.dart:172-230` |
| C6 | `PortableExerciseImageService` is the strongest validator: byte-sniffing, structural parse, 50 KB, 4096 px, real decode. It accepts WebP `ANMF` (animation) and does not look for PNG `acTL` (APNG). | `portable_exercise_image.dart:243` |
| C7 | Lesson icon and custom flag allow 8192 px sources. The Lesson icon decodes the source at full size (`instantiateCodec()` with no target size), so an 8192² input allocates about 256 MB. The flag decodes at target size, which is safer but still relies on the codec. | `lesson_icon_service.dart:29,139-150`, `course_flag_service.dart:48,260` |
| C8 | Image Bank reads the whole ZIP into RAM, calls `ZipDecoder().decodeBytes`, and counts 50 MB only over referenced images. Image content is not validated. | `image_bank_service.dart:149-330` |
| C9 | Course JSON 10 MB, learner backup 10 MB, Recovery Key 64 KB: present and enforced before decoding. | `custom_course_transfer_service.dart:46`, `learner_backup_service.dart:51`, `user_recovery_key_service.dart:42` |
| C10 | Fixed-folder enumeration uses `followLinks: false` and filters `is File`. A symlink appears as `Link` and is skipped. Exact-name lookups such as `flag.png` or `import.json` do not use enumeration and have no explicit regular-file check. | `course_flag_service.dart:169`, `custom_course_transfer_service.dart:76`, `learner_backup_service.dart:52`, `user_recovery_key_service.dart:152` |
| C11 | Shared-Library image duplicates are not detected. Each import creates a new `<micros>_<name>` file and a new `local_<micros>` record. | `exercise_image_service.dart:100-110` |

### 1.2 Findings changed by Build 243

| # | Brief said | Build 243 reality | Consequence for the plan |
|---|---|---|---|
| X1 | Course ZIP is "future". | The Course ZIP **exists** for both Publisher and custom Courses (`CoursePackageService`, `custom_course_transfer_service.dart:140,291`). | Phase 14 becomes a **retrofit** of a shipped importer, not a new design. |
| X2 | Audio dedup is filename-based; storage names come from external names. | Course media is already **content-addressed**: `media:<sha256>.<ext>` in `<AppSupport>/quisquislingo_course_media/course_<hash>/` (`course_media_store.dart`). Same bytes → one file. Only the **clip record** is duplicated. | Course media names are already generated and must not change. The name is part of the signed Course JSON. Changing it would invalidate every Publisher signature. Hash dedup for audio affects clip records only. |
| X3 | Publisher signature may be bypassable by duplicate JSON keys. | The signature covers `signingBytes(course)`, a canonical re-serialization of the **parsed** Course (`publisher_verification_service.dart:20`, `course_checksums.dart:20`). Verification and installation use the same decoded tree, so a duplicate key cannot make them disagree. | Not a bypass. Rejecting duplicate keys is optional hygiene (Tranche 4). |
| X4 | MP3 Generator output must pass the validator. | There is no MP3 Generator or TTS-to-file route in the code. | Define the validator entry point now. There is nothing to migrate yet. |
| X5 | Pixel cap 16,777,216 and dimension cap 4096 are separate controls. | 4096 × 4096 = 16,777,216 exactly, so the pixel cap adds nothing while the dimension cap is 4096. | Keep both in code as independent invariants, so raising one later cannot silently lift the other. |

### 1.3 New findings

Ordered by severity. N1–N3 are memory-exhaustion defects reachable from a
small file. Fix them first (Tranche 0).

| # | Severity | Finding | Where |
|---|---|---|---|
| **N1** | High | **Course cover bomb.** `_checkCover` calls `ui.instantiateImageCodec(bytes)` and decodes a full frame **before** checking 512 × 512. A ≤100 KB PNG that declares 30,000 × 30,000 allocates about 3.6 GB. Reachable from any custom Course ZIP. | `course_package_service.dart:365` |
| **N2** | High | **Image Bank per-entry bomb.** `source.readBytes()` inflates the whole entry **before** the 50 KB check (`:314`). The manifest has the same problem: the declared-size check at `:176` is followed by a full inflate at `:181`. A small entry that falsely declares a small size can inflate without limit. Course packages already avoid this with `_LimitedOutputStream(entry.size)`. | `image_bank_service.dart:181,314` |
| **N3** | Medium | **Course package peak RAM.** The whole ZIP (≤300 MB) stays in memory, plus every media entry inflated into a `Map<String, Uint8List>` (≤300 MB). Peak is about 600 MB, which is a problem on the low-memory Linux target and on Android. | `course_package_service.dart:164-290` |
| N4 | Medium | **Course package media is checked for size and hash only.** An unsigned custom package can carry any bytes named `media/<hash>.mp3` or `.png`. The hash proves integrity, not type. Only the cover is decoded. | `course_package_service.dart:310-325` |
| N5 | Medium | **`CourseMediaStore.addBytes` / `addFile` trust the caller-supplied extension** and accept any bytes. They are the single choke point for Course media, so this is the right place for the validator gate. | `course_media_store.dart:137,174` |
| N6 | Medium | **Orphan in the shared folder from the Course Editor.** Course-specific image import calls `ExerciseImageService`, which writes into the **shared** `exercise_images/` folder. `_asCourseMedia` then copies it into Course media (`course_editor_screen.dart:9399`). The shared copy is never registered or removed, and a non-Admin can trigger this write. | `course_editor_screen.dart:9463-9490` |
| N7 | Medium | **Shared Library writes before authorization.** `ExerciseImageService` writes the file without checking Admin. `_requireAdmin` runs only at metadata commit (`exercise_image_metadata_service.dart:195`). If `inspect()` or the metadata write fails, the file stays as an orphan. | `flat_image_library_screen.dart:172-230` |
| N8 | Low | `ScriptRecognitionEditor` calls `FileDialogService.openBytes` directly from a widget with its own 8 MB cap. It must migrate with the services. | `script_recognition_editor.dart:338` |
| N9 | Low | Image Bank manifest `id`, `label`, `tags` and `category` have no length or charset bounds. `category` is not allowlisted. QQL correctly assigns `origin: 'bank:<id>'` itself (`:351`); keep that. | `image_bank_service.dart:205-350` |
| N10 | Low | `CourseMediaStore._matches` and `copyReferences` read whole files (up to 50 MB) into RAM to hash them. | `course_media_store.dart` |
| N11 | Low | Custom flag accepts PNG/JPEG only, while other routes accept PNG/JPEG/WebP. Deliberate or not, the shared validator must not silently widen it. | `course_flag_service.dart:196-218` |
| N12 | Info | Image Bank ZIPs may contain any unreferenced files; they are simply ignored. The shipped example contains only the manifest and images. | `demo_image_banks/example_image_bank.zip` |

Out of scope, reported only: `saveBytes` writes `<target>.qqltmp` beside the
user's chosen file (`file_dialog_service.dart:127`), and `prepareFlag` does not
dispose its codec if `getNextFrame` throws.

---

## 2. Limits (decided)

The owner's table is adopted unchanged. Rows marked ★ were missing from the
brief and are proposed here because the Course ZIP already exists.

| Limit | Value |
|---|---:|
| Files per multifile operation | 100 |
| Actual source bytes per multifile batch | 250 MB |
| MP3 per file | 50 MB |
| MP3 tags/metadata combined | 2 MB |
| General imported image ceiling (Lesson icon, custom flag) | 2 MB |
| Shared Library / exercise / Image Bank / portable image | 50 KB |
| Maximum source dimension, **every** raster route | 4096 × 4096 |
| Maximum decoded pixels | 16,777,216 |
| Image ancillary metadata combined / single ICC profile | 256 KB / 128 KB |
| Image Bank ZIP / manifest / entries / images | 50 MB / 2 MB / 5,000 / 2,500 |
| Image Bank total **actual** inflated bytes, **all** entries | 50 MB |
| Course/Learner JSON / Recovery Key | 10 MB / 64 KB |
| ★ Course package ZIP, compressed and total inflated | keep 300 MB / 300 MB |
| ★ Course package manifest / cover | keep 1 MB / 100 KB, cover exactly 512 × 512 |
| ★ Course package peak RAM target | one entry at a time; no whole-archive buffer |
| MP3 validation watchdog | 30 s per file (failsafe only) |

---

## 3. Target architecture

New code goes in `lib/services/import/`. The existing services keep their
public entry points and delegate, so screens change only where the UI changes.

```text
source                      staging                    validation           commit
─────────────────────       ──────────────────         ──────────────       ─────────────────────
SelectedExternalFile ─┐                                ImageValidator ──┐
fixed-folder File ────┼──▶  ImportStager  ──▶ Staged ─▶ Mp3Validator ───┼─▶ Validated<T> ─▶ CourseMediaStore
BoundedZipReader entry┤     (count, SHA-256,  File      JSON limits  ───┘                  SharedImageStore
TTS output (future) ──┘      cancel, limit)                                                 (authorize again)
```

| Module | Responsibility |
|---|---|
| `selected_external_file.dart` | `SelectedExternalFile { displayName, reportedSize?, openRead(), sourceKind }`. `FileDialogBackend.openFile` / `openFiles(maxFiles: 100)`. No path crosses this interface. On desktop, `FileSystemEntity.type(path, followLinks: false)` must be `file` before opening. Directories, links, pipes, sockets and devices are rejected. |
| `import_stager.dart` | Streams into `<AppSupport>/qql_import_staging/<random>.part` (same volume as the destinations). Counts actual bytes against per-file and batch budgets, computes SHA-256 incrementally, rejects zero bytes, checks `CancellationToken` between chunks, and deletes the file in `finally`. Wipes stale `.part` files at startup. |
| `safe_file_name.dart` | One sanitizer for display names: NFC, strip C0/C1 and NUL, strip separators, `.`/`..`, trailing dots and spaces, Windows reserved names, 120-character cap. **Never used to choose a storage path.** |
| `image_validator.dart` | Pure-Dart structural pass (isolate-safe): sniff, parse, dimensions, pixels, metadata budget, animation rejection, trailing data. Then a bounded root-isolate decode through `ImageDescriptor` with a dimension check **before** `instantiateCodec`. Returns `ValidatedImage`. |
| `mp3_validator.dart` | Streaming frame walker (isolate-safe). Returns `ValidatedMp3 { durationMs, frameCount, metadataBytes }`. |
| `bounded_zip_reader.dart` | Wraps `archive 4.0.9`: `ZipDirectory` pre-scan, then per-entry `decompress(OutputStream)` into a counting stream that throws at the per-entry **and** archive-wide cap. Reads through `InputFileStream`, never the whole ZIP in RAM. |
| `import_result.dart` | `ImportItemOutcome` enum (brief Phase 19), `ImportBatchResult`, `CancellationToken`. |

**Type-level enforcement.** `ValidatedImage` and `ValidatedMp3` have private
constructors reachable only from the validators. `CourseMediaStore` gains
`addValidated(courseId, Validated…)`. `addBytes` / `addFile` become private, or
keep only the `copyReferences` use, where the source is already stored Course
media. This makes "unvalidated bytes reach storage" a compile error rather than
a review item. It is the single most valuable structural change in this plan.

**Isolates.** Hashing, MP3 walking, ZIP inflation and structural image parsing
run in `Isolate.run`. Only the final bounded `dart:ui` decode runs on the root
isolate. Expensive validations run one at a time.

---

## 4. Tranches

Each tranche is one revision, committed separately after owner approval, with
the full suite run once at the end of each.

### Tranche 0 — Memory-bomb hotfixes (small, ship first)

**Status: implemented in the working tree after Revision 5 (`86ae4d2`); not
yet committed.** No new architecture; minimal targeted fixes:

1. **N1, Course cover:** `_checkCover` reads the dimensions with
   `ImageDescriptor.encoded` and rejects anything other than 512 × 512
   **before** `instantiateCodec`.
2. **N2, Image Bank:**
   - The central directory is read with `ZipDirectory` **before**
     `ZipDecoder`. This matters because `ZipDecoder.decodeBytes` in
     `archive` 4.0.9 eagerly inflates any entry whose Unix mode marks it as a
     symlink.
   - The pre-scan rejects, before anything is inflated: an empty or
     unreadable directory, more than 5,000 entries, any symlink entry, and a
     declared total above 50 MB across **all** entries, referenced or not
     (`maxInflatedArchiveBytes`).
   - The manifest and each image are then inflated through
     `readBoundedEntry` (`lib/services/bounded_archive_entry.dart`), which
     stops at the entry's declared size. The result must match that size
     exactly, so the declared total also bounds the real output.
   - The limited output stream was **moved** from `CoursePackageService`, not
     copied. Both importers now share one implementation.
3. **C7:** Lesson icon and custom flag `maxSourceDimension` 8192 → 4096.
   The error text, English and Italian Help, `docs/COURSE_EDITOR.md` and tests
   are updated.
4. **C6, animation:** APNG `acTL`, WebP `ANIM`/`ANMF` and the VP8X animation
   flag are rejected by `PortableExerciseImageService.fromBytes` (and
   therefore `fromFile`), which covers **new imports only**. `decode` and
   `validate` also run when a Course renders, is audited, or saves an
   exercise, so they are unchanged: an image already stored in a Course keeps
   working (§6 Q1).

Tests: `test/import_hardening_tranche0_test.dart` covers:

- a limited stream that never grows past its limit;
- an entry that understates its size;
- a declared total above 50 MB from an unreferenced entry;
- a symlink entry;
- 5,001 entries;
- non-ZIP bytes;
- a cover declaring 30,000²;
- a 4,097-pixel icon and flag;
- an APNG;
- an animated WebP, both by its flag and by an `ANIM` chunk.

`image_bank_service_test.dart`'s understated-entry test now expects inflation
to stop at the declared size.

### Tranche 0b — QQL image metadata read-only, Local search words (owner decision 2026-09-21)

**Problem.** `ExerciseImageMetadataService` persists a snapshot of the
**whole** catalog, including bundled records, in
`quisquislingo_exercise_image_metadata_v2`. This happens on any Admin edit and
on any Shared Library or Image Bank import (`_persist`, `:203`). From then on,
`loadCatalog()` reads the snapshot instead of the app asset, which causes three
problems:

- an app update that **adds** a bundled image throws
  `Current exercise-image metadata is missing …`, and the image library stops
  loading;
- an update that relabels a bundled image, or moves its file, throws
  `identity fields changed`;
- improved QQL tags and categories never reach devices that have a snapshot.

This has not triggered yet only because `metadata_v2.json` is unchanged since
Build 234.

**Decision.** QQL (bundled) image metadata is **read-only** and always comes
from the app asset, identical on every installation. Admins can no longer
change a QQL image's category or tags.

**Local.** Admins can add device-local search words to a QQL image, shown
and edited under the label **Local**. They:

- never replace or hide QQL's tags or category;
- are shown after QQL's tags on the same tile line, in lowercase
  (`Tags: … · Local: …`), and separately in the preview. Each label appears
  only when that list is non-empty;
- are matched by the Image Library search exactly like QQL tags;
- are never exported to a Course, a Course ZIP or a Shared Image Source;
- are cleared by the existing reset paths.

Admin-added (DEVICE) images keep full metadata editing as today.

**Storage.**

- The persisted document holds only device-owned records (`local`,
  `bank:<id>`) plus a `localTags` map keyed by bundled image ID.
- `loadCatalog()` = bundled asset + device records + Local overlay,
  merged on every load. It never stores a copy of a bundled record.
- A Local entry for an ID that the asset no longer contains is ignored,
  not an error.

**One-time conversion (clean cut, on first load).**

- Bundled records are removed from the stored document.
- Tags an Admin **added** to a QQL image (present in the snapshot, absent from
  the asset) become that image's Local words.
- Tags an Admin removed come back, because QQL's tags are authoritative again.
- Category changes to QQL images are dropped.
- Admin-added (`local`) and bank records are unchanged.

**Device categories (owner decision, §6 Q6).**

- QQL's 14 categories stay fixed and read-only; only an app release changes
  them.
- Admins may add **device categories**: device-local, Admin-owned, stored in
  the same persisted metadata document (no new preference key), and cleared by
  the existing reset paths.
- Name rules: `^[a-z][a-z0-9_]{1,39}$`. A name that is a QQL category, an
  existing alias (`food` → `food_drinks`, `home` → `home_household`) or an
  existing device category is refused.
- Limit: 64 device categories per device.
- Admins create and rename device categories in Edit metadata. Renaming
  updates every record that uses the category. A device category can be
  deleted only when no image uses it.
- Device categories are never exported as a list. A Course already carries
  each image's category as text inside `sharedImageSource`, so an imported
  Course's images keep their label even where that category does not exist.
- `_normalizeCategory` accepts QQL categories plus the device's categories,
  enforced in the service layer.

**UI.** Edit metadata on a QQL image shows its category and tags read-only and
offers only its Local words. Help and `docs/COURSE_EDITOR.md` say so.

**Tests.**

- A snapshot missing a newly bundled ID loads, and shows the new image.
- A changed bundled label or path no longer throws.
- Admin-added tags on a QQL image are converted to Local words; removed tags
  are restored; the category reverts.
- Local words are searchable and never appear in `SharedImageSource` or the
  Course ZIP manifest.
- A non-Admin cannot edit Local words.
- A tile shows `Tags:` and `Local:` only when that list is non-empty.
- Device categories: name rules and the 64 limit are enforced in the service;
  a category in use cannot be deleted; renaming updates every record; a
  non-Admin cannot create, rename or delete one.
- `updateMetadata` refuses category or tag changes to a bundled record at the
  service layer, not only in the UI.

### Tranche 1 — Safe import foundation

- `SelectedExternalFile`, `openFile`/`openFiles` on the backend, and a desktop
  `lstat` gate. Keep `openBytes` temporarily as a thin wrapper over
  `openFile` + stager + `readAsBytes` of the staged file (bounded by the real
  limit, not a "dialog cap") so every existing caller keeps working. Remove the
  per-service `_dialogReadCap` constants.
- `ImportStager`, `CancellationToken`, `ImportBatchResult`, `safe_file_name`.
- Explicit regular-file check on fixed-name lookups (C10).
- Streaming SHA-256 in `CourseMediaStore._matches` (N10).
- New folder `qql_import_staging` → `AppResetService`, `InventoryService`,
  `docs/239_RESET_STORAGE_INVENTORY.md`.

Tests: false and unknown reported size, source truncated mid-read, zero bytes,
symlink and directory named `.mp3`, FIFO (Linux/macOS only), file removed
between enumeration and read, temp-creation failure, disk-full simulation
through an injected sink, and cancellation mid-stream leaving no `.part` file.

### Tranche 2 — Images

1. `ImageValidator` extracted **from** `PortableExerciseImageService` by moving
   the parser, not copying it. `PortableExerciseImageService` delegates. Add:
   PNG CRC check, IHDR field sanity, metadata chunk budget (`iCCP`/`eXIf`/
   `iTXt`/`zTXt`/`tEXt`), JPEG `APPn`/`COM` budget, SOF components, `DNL`
   handling (height 0 → reject), WebP `ICCP`/`EXIF`/`XMP ` budget and VP8X
   flag consistency. Per-profile `allowedFormats` (flag: PNG/JPEG only, N11)
   and `maxBytes`.
2. Route **every** image importer through it: Shared Library, Course Editor
   image, Recognize Characters, Lesson icon, custom flag, Image Bank entries,
   Course package image media and cover (N4).
3. Fix N6: Course Editor image import goes staging → validator →
   `CourseMediaStore.addValidated`, with no write into `exercise_images/`.
4. Fix N7: `SharedImageStore.importValidated(actorProfileId, …)` checks Admin
   before selection (UI) and again at commit (service). It writes the file and
   the metadata record together, and removes the file if the record fails.
5. Shared Library `Open image files from…` (≤100), with a batch summary sheet.
   Single-image fields stay single.
6. Generated storage names for new Shared Library imports:
   `image_<assetId>.<detected ext>`. Existing records keep their paths (clean
   cut, no migration).

### Tranche 2b — Course Image Library imports (owner decision 2026-09-21)

**Status note:** the `imageLibrary` model below (entries with `asset` and
optional `sharedImageSource`, carried by Fork, transfer and Merge, kept by
`referencesOf`), together with removal and Keep in library, shipped early in
Revision 8. Label, category, tags and attribution fields on entries, and all
import routes, remain for this tranche.

**Goal.** Anyone who can edit a Course can add images to that Course's own
Image Library in the Course Editor:

- single images or a multiple selection (**Import images** from the fixed
  folder, **Open image files from…** with up to 100 files);
- a whole Image Bank ZIP (**Import Image Bank ZIP**, **Open Image Bank
  from…**).

The images become part of the Course without being used by any exercise yet.
No Admin rights are needed, and nothing is added to the device's Shared Image
Library.

**Why the model must change.** A Course keeps only media it references. On
every confirmed save, `deleteUnreferenced` removes any other file from the
Course folder (`course_editor_service.dart:779,971`), and the Course ZIP and
backups include only referenced media. An unused library image therefore
needs a reference inside the Course.

**Model (Course v11, additive).**

- New optional field `imageLibrary`: a list of entries, each with:
  - `asset`: `media:<sha256>.<ext>`;
  - `label`;
  - `category`;
  - `tags`;
  - optional `attribution`, same shape as `ImageAttribution`;
  - optional `sharedImageSource` provenance.
- Omitted when empty, so existing Courses, backups, checksums and Publisher
  signatures are byte-identical.
- `CourseMediaStore.referencesOf` includes these assets. Cleanup therefore
  keeps them, and the Course ZIP and backups carry them. **Owner decision:**
  unused library images travel in the Course ZIP and backups. This
  deliberately widens the Build 243 "referenced media only" rule to include
  the Course's own library.
- The **IN USE** state is still computed only from exercises and the cover,
  never from `imageLibrary`.
- One entry per asset: re-importing the same bytes is `DuplicateSkipped`
  (Tranche 5 policy).
- Validation on load and import:
  - label 1–200 characters;
  - at most 32 tags, each at most 80 characters;
  - category: a QQL category, or any name matching the device-category name
    rules. It is Course-scoped free text, so no Admin confirmation is needed
    and nothing device-wide changes;
  - no control characters.
- Update `docs/COURSE_JSON_FORMAT.md`, the v11 invariants in `AGENTS.md`, the
  Publisher signing guide, and `tools/convert_course_to_v11.dart` if it
  enumerates fields.

**Authorization.**

- Allowed: the Course Maintainer and members of the assigned Team, as for
  every other Course edit.
- Not allowed: View mode, official or Publisher Courses (read-only; Fork
  first), and learners.
- Enforced in the service layer, not only by hiding buttons.

**Limits.**

- No separate image-count limit (owner decision).
- Every image must pass `ImageValidator` with the 50 KB exercise-image
  profile.
- Each operation keeps the Tranche 1 bounds: 100 files and 250 MB per
  selection; Image Bank limits per bank.
- An import that would push the Course's stored media (images plus recordings)
  past the 300 MB Course package limit is refused **before anything is
  written**. The message says how much room is left. Otherwise a Course could
  be saved and then fail to export.

**Pipeline.**

Each file goes through: selection → staging → `ImageValidator` →
`CourseMediaStore.addValidated` → `imageLibrary` entry. Files are committed
only with the Course's normal confirmed save. An unsaved or cancelled edit is
cleaned up by the existing `deleteUnreferenced`, so it leaves nothing behind.

Image Bank into a Course:

- uses `BoundedZipReader` and the manifest rules of Tranche 4, including the
  bank-wide default attribution;
- stores images as Course media, not in `image_banks/`;
- keeps the bank's categories as Course-scoped text;
- is available only once Tranche 4 has landed. Until then the Course
  Editor offers individual images only.

**UI.**

- An unused library image shows **COURSE**; once used, **COURSE · IN USE**.
- Its bin removes it from the Course, and appears only while no exercise or
  the cover uses it. An image in use shows no bin.
- Label, category, tags and attribution are editable by the same editors,
  in the same Edit metadata dialog.
- The badge filter, sorting and search apply unchanged. Search also matches
  `imageLibrary` tags.

**Tests.**

- An unused library image survives a confirmed save, export/import
  round-trip, backup/restore, Fork and Copy as New Course.
- Removing an entry lets `deleteUnreferenced` delete its file on the next
  confirmed save.
- An image in use cannot be removed.
- A non-editor or View mode cannot add images, including by calling the
  service directly.
- The 300 MB pre-check refuses before writing.
- A duplicate is skipped.
- A Course without the field is byte-identical after load and save.
- A Publisher signature over a Course with `imageLibrary` verifies, and
  tampering with an entry fails verification.

### Tranche 3 — Audio

1. `Mp3Validator`:
   - ID3v2.2/2.3/2.4 at start: synchsafe sizes, footer flag, unsynchronisation,
     frame sizes that stay inside the tag. Extended header bounded.
   - MPEG-1/2/2.5 Layer III only. Reject reserved version, layer, bitrate
     index 15, free-format bitrate 0 and sample-rate index 3.
   - Require ≥ N consecutive sync-valid frames at the start (proposal: 4), each
     starting exactly where the previous one ends. This defeats a single fake
     sync marker.
   - Xing/Info/VBRI header accepted but never trusted for allocation. Duration
     is summed from frames walked.
   - Trailer: ID3v1 (128 B) and APEv2 accepted within the 2 MB metadata budget
     (see §6 Q3). Anything else after the last frame is rejected.
   - Embedded artwork (`APIC`, or `PIC` in ID3v2.2) is rejected (§6 Q4).
   - No field is copied into Course metadata. URL frames are ignored.
   - A 30 s watchdog enforced through the isolate.
2. Both Audio Library routes, Course package `.mp3` media (N4) and the future
   generator all go through `addValidated`.
3. Audio `Open from…` becomes multifile (≤100 files, ≤250 MB), with a
   cancellable progress sheet and a batch summary.
4. Duplicate clip rule: same SHA-256 already in this Course's Audio Library →
   `DuplicateSkipped`, and no new clip record.

Fixtures: build them in `test/fixtures/import/` with a small generator script in
`tools/`. Do **not** commit third-party MP3s. A valid CBR frame sequence and a
VBR sequence can be synthesized (silent frames).

### Tranche 4 — Archives and structured imports

1. `BoundedZipReader` becomes the only ZIP reader. Image Bank and Course package
   both use it. It checks:
   - duplicate names after `\`→`/` and case folding;
   - absolute paths, drive letters and `..`;
   - symlink, hardlink and device modes;
   - encrypted entries;
   - compression methods other than stored and deflate;
   - nested archive extensions;
   - `uncompressedSize < 0`;
   - entry count before any inflate;
   - allowlisted names only. For Image Banks: the manifest plus referenced
     images, nothing else (§6 Q5). The error explains that credits belong in
     the manifest's `attribution` field.
2. Course package: stream entries one at a time into staging and hash while
   staging. Keep media on disk, not in a `Map<String, Uint8List>` (N3).
   `CoursePackage` holds staged file handles. Install moves them atomically.
3. Image Bank manifest bounds (N9): id `^[A-Za-z0-9._-]{1,128}$`, label 1–200,
   ≤32 tags × ≤80, display name ≤120. No control characters.
   - **Categories (§6 Q6).** Every category is validated **before anything is
     written**. Unknown categories that pass the device-category name rules
     are listed to the Admin: "This bank adds N new categories: …". The Admin
     chooses **Add them**, **Put these images under Other**, or **Cancel**.
     At most 16 new categories per bank, within the device limit of 64. An
     invalid name rejects the bank.
   - **Bank-wide default attribution (§6 Q5).** An optional manifest object
     applies to every entry without its own `attribution`. It uses the same
     fields and rules (author and license together; title and source
     optional). An entry's own attribution always wins.
   - The bank is committed (folder, images, records, new categories) only
     after all validation and the Admin's choice. A failure or Cancel leaves
     nothing behind.
   - Update `docs/IMAGE_BANK_PACKAGES.md` and the example bank documentation.
4. JSON structural pre-check before `jsonDecode` for Course, learner backup and
   Recovery Key: maximum nesting depth (proposal: 64), maximum string length
   (1 MB), maximum array length (proposal: 100,000), maximum Course element
   counts checked after decode (Lessons, Rounds, Exercises, items). Reject
   malformed UTF-8 (`utf8.decode` default already throws) and NUL in identity
   and name fields. Duplicate-key rejection is optional (X3).

### Tranche 5 — Duplicates, provenance, final adversarial suite

- SHA-256 index for the Shared Library, built lazily on first import by hashing
  existing files once and cached in the metadata record.
- Duplicate policy exactly as the brief (Skip / Replace-with-authority / Keep
  both, plus Apply to all). Replace is enforced in the service layer. Bundled
  and Publisher media are immutable. Incoming metadata never grants rights.
- The Image Library's date sort currently derives the added date from QQL-generated
  ID stamps and Course file write times. Once `importedAtUtc` is recorded,
  the sort uses it instead, and images imported before then keep the derived date.
- Provenance fields as in the brief. The metadata record gains
  `sha256`, `detectedFormat`, `byteLength`, `sourceName` (sanitized),
  `source`, `importedBy`, `importedAtUtc`. No external paths or URIs.
- Full brief Phase 20 fixture set. Every fixture is asserted against **every**
  route that accepts that artifact (a parameterized test over the route
  matrix in §5).

---

## 5. Route matrix (current → target)

| # | Route | Fixed folder | Open from… | Package | Current validator | Target |
|---|---|---|---|---|---|---|
| 1 | Course JSON | ✓ | ✓ | inside ZIP | size + schema | + JSON structural limits |
| 2 | Course Merge source | ✓ | ✓ | — | same as 1 | same as 1 |
| 3 | Learner backup | ✓ | ✓ | — | 10 MB + schema | + JSON structural limits |
| 4 | Recovery Key | ✓ | ✓ | — | 64 KB + strict | + JSON structural limits |
| 5 | Image Bank ZIP | ✓ | ✓ | — | partial, **N2** | `BoundedZipReader` + `ImageValidator` |
| 6 | Shared Library image | ✓ | ✓ (→ multi) | — | ext + size, **C5/N7** | `ImageValidator` + authorized commit |
| 7 | Course Editor image | ✓ | ✓ | — | ext + size, **N6** | `ImageValidator` → `addValidated` |
| 8 | Recognize Characters | ✓ | ✓ (widget, **N8**) | inside JSON | Portable (strong) | `ImageValidator` |
| 9 | Lesson icon | ✓ | ✓ | inside JSON | decode, 8192 | `ImageValidator` (2 MB, 4096) |
| 10 | Custom flag | ✓ (fixed name) | — | inside JSON | decode, 8192 | `ImageValidator` (PNG/JPEG, 2 MB, 4096) |
| 11 | Recorded MP3 | ✓ | ✓ (→ multi) | ✓ | size only | `Mp3Validator` |
| 12 | Generated MP3 | — | — | — | not built | `Mp3Validator` (hook only) |
| 13 | Course ZIP | ✓ | ✓ | — | strong structure, **N1/N3/N4** | `BoundedZipReader` + both validators |
| 14 | Course cover | — | — | inside ZIP | decode first, **N1** | `ImageValidator` (512², 100 KB) |

Route 14 is new relative to the brief.

---

## 6. Owner decisions (2026-09-21)

1. **Existing stored media:** validators apply to **new imports and new
   package installs only.** Nothing already installed is deleted or blocked.
   An Audit rule could come later.
2. **Shared Library storage names:** generated names for **new imports only**.
   Existing files and records keep their paths. No migration.
3. **MP3 trailers:** accept **ID3v1 and APEv2** within the 2 MB metadata
   budget. Reject Lyrics3 and anything else after the last frame.
4. **ID3 artwork:** **reject** any MP3 that embeds artwork (an ID3 `APIC` or
   ID3v2.2 `PIC` frame). QQL never shows it, so it is not structurally
   validated or stripped. The error names the cause, so the author can remove
   the artwork and retry. Tranche 3 fixtures gain "valid MP3 with `APIC`",
   which must be rejected.
5. **Image Bank extra files (README, LICENSE):** **rejected.** A bank ZIP
   may contain only its manifest and the images the manifest references.
   Attribution already has structured homes: per-image `attribution` in the
   manifest, Admin-editable in Edit metadata and carried into Courses, plus the
   Course's own `mediaAttributions`. A loose text file would never reach a
   Course. The rejection message points authors to the manifest `attribution`
   field. **Addition:** the manifest may declare an optional bank-wide default
   attribution, applied to every entry without its own (Tranche 4).
6. **Unknown Image Bank category:** **device categories, added with Admin
   confirmation.** Correction to the audit: the current behavior is **not**
   "map to `other`". The manifest category is passed through unchanged, and
   `ExerciseImageMetadataService._normalizeCategory` throws
   `Unsupported exercise-image category` when the records are committed. That
   happens after the bank folder and its images have already been written.
   The new behavior is specified in Tranche 0b (model) and Tranche 4 (import).
7. **Course package limit:** **keep 300 MB** compressed and 300 MB expanded.
   Streaming removes the memory problem, not the size limit.
8. **Android SAF backend:** **out of scope.** Desktop only in this revision;
   the file-selection abstraction is designed for a later Android backend.
9. **Course Image Library imports (Tranche 2b):** anyone who can edit a
   Course may add single images, multiple images, or an Image Bank to that
   Course's Image Library, unused until an exercise uses them. Unused
   library images **travel in the Course ZIP and backups**, and there is
   **no separate image-count limit**. The 300 MB Course package limit
   applies and is checked before writing.

---

## 6a. Revision order (owner decision 2026-09-21)

1. **Revision 6:** Tranche 0 (memory-bomb fixes).
2. **Revision 7:** image library tidy-up (§6c). No visible change.
3. **Revision 8:** Image Library badge order and removing an image from a
   Course (§6b).
4. Then Tranches 0b, 1, 2, 2b, 3, 4 and 5, all built on the Revision 7
   structure.

Splitting `course_editor_screen.dart` into separate screens (the Exercise
editor, Round, Lesson and Course editors, and the rest) is **deferred** to a
later, separate job, done one screen at a time.

## 6b. Revision 8 — badge order and removal (owner decisions 2026-09-21)

**Status: implemented as Revision 8 (`2.0.43+243008`).** Owner additions in
the same revision:

- the `imageLibrary` model, brought forward from Tranche 2b;
- a second question after removing a Course-stored image's uses (Remove from
  Course, or Keep in library);
- a bin on every Course-stored image, used or not.

A leftover file that neither the saved nor the edited Course uses is deleted
at once. Anything else leaves through the confirmed save.

Not part of the import hardening, but it touches the same screens. Built on
the Revision 7 structure.

**Badge order.** On every image and in the badge filter, the order is
**IN USE, QQL, DEVICE, COURSE**, with IN USE first. Today's order is QQL,
DEVICE, COURSE, IN USE (`_badgesOf`, `_badgeOrder` in
`flat_image_library_screen.dart`, and the exercise image preview in
`course_editor_screen.dart`).

**Remove an image from a Course (Course Editor's Image Library).**

- **Who:** anyone who can edit the Course (Maintainer or assigned Team). Not
  in View mode, and not on official or Publisher Courses. Enforced in the
  service layer as well as the UI.
- **How:** a working-copy edit through `CourseEditorTransaction`, confirmed
  with the Course's normal Confirm like any other structural edit. It can be
  discarded before confirmation. Files leave the Course folder only through
  the existing `deleteUnreferenced` after a confirmed save, and the
  pre-change backup keeps its own copies.
- **Where:** a bin over the image's bottom-right corner (tooltip "Remove from
  this Course") and the same action in the preview dialog. A confirmation
  lists every use, for example "Used in 3 exercises: Lesson 2 › Round 1 › …,
  and as the Course cover".
- **What it removes:**

  | Image | Removal | Stays |
  |---|---|---|
  | COURSE only | cleared from every exercise and the cover; `imageLibrary` entry removed (Tranche 2b); file deleted on the next confirmed save | nothing |
  | DEVICE (+ Course copy) | cleared from the Course; the copy's file deleted on save | the Shared Image Library original (DEVICE) |
  | QQL | its uses cleared from exercises and the cover | the bundled image (QQL) |

  A DEVICE or QQL image that the Course does not use shows no bin, because
  there is nothing to remove from the Course.
- **Exercises left invalid (owner decision):** the image is cleared
  everywhere. Every affected exercise that the canonical Audit then reports
  as invalid (an Error) becomes **Draft**, so learners never meet a broken
  exercise. Exercises where the image was optional keep their publication
  state. Parent Draft badges and counts update through the existing
  reconciliation.
- **Tests:** removal of each kind; cover use; Draft only for exercises made
  invalid; discard restores everything; the file is gone only after the
  confirmed save; the Shared original and QQL image are untouched; a
  non-editor and View mode are refused at the service; the badge order
  holds everywhere.

## 6c. Revision 7 — image library tidy-up (owner decision 2026-09-21)

**Status: implemented as Revision 7 (`2.0.43+243007`).** The owner also
decided that the single usage rule counts images **everywhere in the
Course**, presentations and GuideBooks included. Actual sizes: the editor
went from 11,383 to 11,150 lines and the Image Library screen from 1,219 to
1,081. The new files are 115 (usage), 161 (rules) and 277 (field) lines.

**Purpose.** Six planned changes touch the image library (Revision 8,
Tranches 0b, 2, 2b and 5, and the badge order). Before them, give its logic
one home each and make it testable without opening a screen. **No visible
change:** the existing widget tests must pass unchanged.

**Why.**

- "Where does this Course use this image?" is answered in three slightly
  different places:
  - `_courseImageElements` and the used sets in
    `flat_image_library_screen.dart`;
  - `CourseMediaStore.referencesOf`;
  - `_courseImageSource` in the Exercise editor.

  Revision 8's removal depends on one correct answer.
- Badge rules, the merging of a device original with its Course copy,
  filtering, sorting and the derived added date all live in the screen's
  state. They can only be tested by opening the whole screen with real files.
- The exercise image section (choose, import, `_asCourseMedia`, preview with
  badges, remove; `course_editor_screen.dart` about lines 9390–9631) can read
  and change anything in the 2,800-line Exercise editor.

**Scope (the slim version, owner-approved).**

1. **`CourseImageUsage`** (pure Dart): the single answer to where a Course
   uses an image (exercise prompt, items, layout, and the cover), with
   readable locations for confirmation dialogs. The three existing places
   delegate to it.
2. **Image library rules** (pure Dart), moved out of the screen state. They
   cover badges and their order, the device original / Course copy merge,
   the category, badge and text filters, sorting and the derived added date.
   The screen stays an ordinary StatefulWidget that calls them.
3. **`ExerciseImageField`**: a public widget the Exercise editor uses through
   explicit inputs (Course, current image, its Shared Library source,
   read-only) and a change callback.

**Explicitly not included.**

- No new controller, catalog or actions layers, and no new pattern that the
  rest of QQL does not use.
- Authorization stays in the services.
- No split of `course_editor_screen.dart` beyond the image section (see §6a).

**Method (per `AGENTS.md`).**

1. Characterize first: add tests that pin today's badges, the merged tile,
   filters, each sort order, which images count as used (prompt, items,
   layout, cover) and the permission gates, before moving anything.
2. Move, don't copy: one implementation per responsibility, with old call
   sites delegating to it.
3. `FlatImageLibraryScreen` keeps its constructor, so Course Editor, Course
   Manager, Device Administration and Recognize Characters are unchanged.
4. New unit tests for the pure rules; existing widget tests unchanged.

**Expected size effect (small by design).**

| File | Before | After (approx.) |
|---|---:|---:|
| `course_editor_screen.dart` | 11,383 | about 11,140 |
| `flat_image_library_screen.dart` | 1,219 | about 970 |
| New files together | 0 | about 650 |

The gain is one source of truth and fast tests, not file size.

---

## 7. What this work does not do

- No SVG import, ever. Bundled World Flag SVGs are trusted assets.
- No resizing or recompression of Shared/exercise images. The Lesson icon
  (256² PNG) and custom flag keep their existing normalizing contracts.
- No change to `media:<sha256>.<ext>` naming, the Course JSON format or
  Publisher signatures.
- No change to `saveBytes` beyond sharing the backend.
- No Android/iOS dialog backend.
- No ID3 title, artist or comments imported into Course data.

---

## 8. Verification per tranche

- Focused tests during work. `flutter analyze` and the full `flutter test` once
  at the end of the tranche.
- Every new fixture is small and synthetic (generator under `tools/`). No
  multi-megabyte binaries in git. Large-size cases (50 MB + 1, 250 MB batch)
  are produced at test time into a temp folder, or by an injected reported-size
  stream.
- Memory-bomb tests assert rejection **and** that no allocation above a bound
  occurred (injected counting sink / limited stream), not only that an error
  appeared.
- Manual checklist on Windows and Linux: multifile Audio and Shared Library
  imports with mixed valid and invalid files, Cancel halfway, and a batch
  summary with expandable reasons.

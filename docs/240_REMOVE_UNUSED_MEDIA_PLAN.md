# QQL 240 follow-up: "Remove unused media" tool

Status: **PLAN ONLY. Not started. Do not implement until the owner says so.**
Written 2026-09-20. Parent document: `docs/240_FILE_DIALOGS_PLAN.md` (section 8.3
lists the orphan cases, section 8.4 holds the decisions and findings this plan is
built on). Read `AGENTS.md` first: its rules bind this work (smallest change, no
unrelated refactors, never commit or push unless asked, run focused tests while
iterating and the analyzer plus the full test suite once at the end, use `rg`/git
and never PowerShell `Get-Content`, new persistent keys or folders must also go
into `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md`).

A Fable agent was started for this on 2026-09-20 and failed immediately because
the account has no usage credits for that model; it changed nothing. Whoever
implements this (Opus agent, Fable with credits, or the main session) should use
this document as the brief.

## 1. Goal

Let an admin find media files that QQL copied into its own storage and that no
Course uses any more, review them, and delete the ones they choose, safely.

Why it is needed (verified in code, see parent plan 8.3): removing an MP3 clip,
abandoning an import, deleting a Course, or changing an exercise image never
deletes the copied file. The smaller fix already shipped for MP3 (delete on
confirmed Save and on Course deletion, when no other Course shares the file).
It does not cover images, older orphans, or clips imported and dropped before a
first Save. This tool covers those.

## 2. Decisions already made by the owner (do not re-open)

| Topic | Decision |
|---|---|
| References | **Audio**: referenced by any current stored Course (custom and external official). Backups do **not** count, because each backup holds its own copy of its clips. **Images**: referenced by any current Course **or any Course Backup manifest**, plus shared-library records. |
| Recently created files | Never offered for deletion if created or modified in the last **30 days** (protects unsaved work; an open editor's unsaved imports are not referenced yet). |
| Choice | The admin chooses **per file and per course** what to delete. Nothing is all-or-nothing. |
| Access | Admin only, **PIN-gated like the existing resets**, checked in the service. |
| Confirmation | Explicit confirmation naming count and total size, saying it cannot be undone. |
| Order of work | The smaller MP3 fix first (done), then this tool. |

## 3. Scope

**Candidate roots (only these):**
- `<AppSupport>/exercise_images/` (single images imported in editors or the admin library)
- `<AppSupport>/quisquislingo_audio/course_<hash>/` (recorded MP3 copies)

**Never touched:** `<AppSupport>/image_banks` (removed by bank removal or the media
reset), bundled `assets/`, anything under `Documents/QuisquisLingo` (Exports,
Imports, Logs, Merges), files the user saved with `Save to…`, and lesson theme
icons / portable images (embedded in the Course record, not files).

## 4. What counts as a reference

Build one index from raw stored JSON, reusing `MediaReferenceIndex`
(`lib/services/managed_media_cleanup.dart`, already implemented and tested).
Do not depend on field names: a file is referenced when its path appears as any
short string value.

1. **Current Courses:** decoded maps of `CourseEditorStorage.userCoursesKey` and
   `externalOfficialCoursesKey`. Courses are device-wide, so other learners'
   and hidden Courses (hiding is a per-learner display preference) are already
   included.
2. **Backups (images only):** every manifest `*.json` under
   `Documents/QuisquisLingo/Exports/Course Backups v9/<courseId>/`. The
   manifest holds the full Course JSON.
3. **Shared image library (images only):** `quisquislingo_exercise_image_metadata_v2`
   (each record's `assetPath`) via `ExerciseImageMetadataService.loadCatalog()`
   or a raw read; local records only. `image_banks` are out of scope (section 3).
4. **Matching:** full path first, then file name, both case- and slash-insensitive.
   The file-name fallback protects against a moved app-data folder (e.g. Windows
   user rename). It errs on the side of keeping a file.
5. **Audio folder ownership:** a folder `course_<hash>` belongs to a Course when
   `RecordedAudioService.storageDirectoryForCourseId(courseId)` equals the folder
   name for any current Course. Use this only to show the owner in the report and
   to group by course; a file is still judged by reference, not by folder.

**Fail-safe rule:** if any store, manifest or the metadata cannot be read or
parsed, the scan **refuses to produce a deletable list** (report the problem;
delete nothing). Partial knowledge must never lead to deletion.

## 5. Behaviour

### Step 1: scan (read-only)
`scan()` returns a report; it changes nothing.
For each candidate file that is unreferenced **and** older than 30 days (use the
later of created/modified time; injectable clock):
- file name (never the full path in logs), size, modified date, kind (image / audio)
- owner course title and Maintainer if the audio folder maps to a known Course
  (existing `InventoryService` already resolves owner text; reuse its approach),
  otherwise "A course no longer on this device" or "No known Course"
- reason: "No Course uses this file"

Also report, without offering them: the number of unreferenced files skipped
because they are newer than 30 days, and the number of files kept because a
Course, backup or library record references them.

### Step 2: choose and confirm
UI groups the list by course (audio) and by "Images" (images). The admin can:
- tick individual files
- tick a whole group ("select all in this course")
- see running totals (count and size of the selection)

Confirmation dialog: "Delete N files (X MB)? This cannot be undone. Your original
files, Course backups and exports are not touched." Buttons: Cancel / Delete.
Then PIN entry (same widget/pattern as the reset wizards in
`device_administration_screen.dart`).

### Step 3: delete
`remove(selection, actorProfileId, pin)`:
1. authorize: admin, has a PIN, PIN correct (copy the checks in
   `AppResetService._authorize`; ideally call a shared helper rather than
   duplicating, without changing reset behaviour);
2. **re-scan** and delete only files that are *still* unreferenced, old enough and
   inside the candidate roots (the selection is a request, not trust; state may
   have changed since the report);
3. per file: refuse `..` escapes, refuse anything that is not a regular file,
   do not follow links, catch and count failures, never throw for one file;
4. remove a `course_<hash>` folder only if it is empty afterwards;
5. return `{deleted, failed, skippedNoLongerUnused, bytesFreed}`;
6. log counts and file names (never full paths or contents) to
   `DiagnosticLogService`.

Idempotent and resumable: running it again after a crash is safe.

## 6. Code shape

New files
- `lib/services/unused_media_service.dart`
  - `UnusedMediaService({supportDirectory, documentsDirectory, courseStores,
    metadataRecords, clock, profileService})`, all injectable like `AppResetService`
  - `Future<UnusedMediaReport> scan()`
  - `Future<UnusedMediaResult> remove(Set<String> selectedFileKeys, {required String actorProfileId, required String pin})`
  - data classes `UnusedMediaFile` (kind, courseGroup, name, sizeBytes, modified,
    owner), `UnusedMediaReport` (files, keptCount, tooNewCount, problems),
    `UnusedMediaResult`
  - reuse `MediaReferenceIndex` for matching; extend it (or add a sibling) with
    backup-manifest reading; keep the existing MP3 cleanup tests passing
- `lib/screens/unused_media_screen.dart` (report, selection, confirm, PIN)
- tests: `test/unused_media_240_test.dart`

Changed files (small)
- `lib/screens/inventory_screen.dart`: an admin-only button "Remove unused media…"
  opening `UnusedMediaScreen` (hidden for non-admins)
- `lib/screens/device_administration_help_screen.dart`: one paragraph explaining
  the tool, the 30-day rule and that it is not undoable
- `docs/239_RESET_STORAGE_INVENTORY.md`: note that this tool deletes only files
  already listed under "Imported images" and "Imported audio files"
- `docs/240_FILE_DIALOGS_PLAN.md`: tracker line (section 12)
- `CHANGELOG.md` and the validation doc at the revision's wrap-up

No new preference keys or folders are expected; if one appears, follow AGENTS.md.

## 7. Tests (behaviour-level, temporary directories, no real dialogs)

Scan
1. referenced audio kept; unreferenced audio older than 30 days listed
2. unreferenced file **newer than 30 days is never listed** (boundary: exactly
   30 days old, 29 d 23 h, 30 d 1 h; injectable clock)
3. audio referenced **only by a backup manifest is listed** (backups ignored for audio)
4. image referenced only by a backup manifest **kept**
5. image referenced only by shared-library metadata **kept**
6. file shared by two Courses kept when either references it
7. another Course's file kept (including a hidden or other-learner Course)
8. external-official Course reference kept
9. `image_banks` never listed; bundled `assets/` paths ignored
10. path match survives slash style, letter case and a moved app-data root (name fallback)
11. an unreadable store, manifest or metadata blob makes the scan refuse (no list)
12. owner shown for a known audio folder; "no longer on this device" otherwise

Remove
13. PIN required; wrong PIN deletes nothing; non-admin refused; admin without PIN refused
14. only the selected files are deleted; unselected stay
15. a selected file that became referenced after the scan is **not** deleted
16. a selected file that became newer than 30 days is not deleted (clock/touch)
17. `..` escape and a path outside both roots refused
18. links (symlink/junction) not followed or deleted
19. one failing delete is counted and does not stop the rest
20. empty `course_<hash>` folder removed; non-empty one kept
21. second run after a partial run finishes the job (idempotent)
22. Diagnostic Log gets counts and file names, no full paths

UI (widget)
23. the Inventory shows the action only to an admin
24. selecting a group selects its files; totals update; confirm names count and size;
    Cancel deletes nothing

Regression: `test/managed_audio_cleanup_240_test.dart`, `test/inventory_239_test.dart`,
`test/app_reset_service_239_test.dart`, `test/device_administration_239_test.dart`
must still pass.

## 8. Risks and how the plan answers them

| Risk | Answer |
|---|---|
| Deleting a file that a Course still uses | Reference index over every stored Course + backups (images) + library records; re-scan at delete time; fail-safe refusal on any read problem |
| Deleting unsaved work | 30-day guard; the selection is re-checked at delete time |
| Deleting outside QQL's folders | Two candidate roots, canonical-path prefix check, `..` refused, links never followed, regular files only |
| A restored old version pointing at a deleted image | Images referenced by any backup are kept (audio is safe: backups hold their own copy) |
| Accidental use | Admin + PIN, explicit count/size confirmation, wording that it cannot be undone |
| Privacy in logs | Counts and file names only |

## 9. Open questions (small, none blocking the design)

1. Should "kept because an old version (backup) still needs this image" be shown
   to the admin as an informational count, so they understand why space is not
   freed? (Recommended: yes, included in the "kept" count with a short note.)
2. Should the report also be exportable (`Save to…`) for support? (Recommended: no, not now.)

## 10. Suggested order when work starts

1. Extend the reference reading: backup manifests and library records (service + tests 3-12)
2. `scan()` and its tests
3. `remove()` with authorization, re-scan and guards (tests 13-22)
4. Screen and Inventory entry (tests 23-24)
5. Docs, help text, CHANGELOG; then analyzer and the full suite once

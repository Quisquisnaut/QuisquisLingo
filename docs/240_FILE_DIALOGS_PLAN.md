# QQL 240 — Native file dialogs (Save to… / Open from…)

Status: **PLAN ONLY. No production code has been written.** Baseline: QQL 239
Revision 5 (`2.0.39+239005`, commit `db6e20b` on `main`). Written 2026-09-19.

This document is the hand-off file for any agent (or person) continuing the
work. Read it top to bottom, then read `AGENTS.md` (its rules bind this work),
then check the **Progress tracker** at the end and continue from the first
unchecked item. Update the tracker and the **Decision log** as you go.

---

## 1. Goal

Add operating-system file dialogs, **in addition to** the existing fixed-folder
system, wherever QQL exports or imports a file:

- `Save to…` (native Save As) next to today's default export.
- `Open from…` (native Open) next to today's default import.

Requirements (from the product owner):

1. The fixed-folder system (`Documents/QuisquisLingo/{Exports,Imports,Merges,Logs}`)
   is **not replaced**. Every existing button, path, filename and message keeps
   working exactly as before.
2. Dialog paths must behave **exactly like** the existing procedures: same data
   written, same validation on import, same limits, same collision handling.
   Only the source/destination of the bytes changes.
3. Helpful especially on Android, where some folders are hard for users to reach.
   Also useful on desktop. Remote locations (Google Drive etc.) work **only
   through what the OS picker already exposes**, using authorization the user
   already has. QQL adds **no** OAuth, Drive/Dropbox/OneDrive API, tokens or
   account handling.
4. Failures of the system dialog must be handled gracefully and must explain how
   to fall back to the simple fixed-folder route. Failures are written to the
   Diagnostic Log.

Non-goals: changing any file format; touching automatic Course Backups;
moving live logs; adding network dependencies; iOS support (see §4).

## 2. Repository rules that apply (from `AGENTS.md`)

- Smallest change that satisfies the task; no unrelated refactors or cleanup.
  Separate structural refactoring from behavior changes where practical.
- Do **not** commit or push unless the user explicitly asks.
- Use `rg`/`git`; **never** PowerShell `Get-Content` in this repo (it hangs).
  Read-only commands hanging >15 s: interrupt and use another method.
- Every delivered update increments the version/build in `pubspec.yaml` and
  refreshes the Beta expiry in `lib/services/beta_lifecycle_service.dart`, its
  tests, README and current docs. Do not carry forward the previous expiry.
  Update `CHANGELOG.md` and the validation doc (`docs/240_VALIDATION.md`).
- Any new persisted preference key or **persistent** user-file folder must also
  go into `AppResetService`, `InventoryService` and
  `docs/239_RESET_STORAGE_INVENTORY.md`. (Planned design uses only the system
  temp directory, which needs none of that — see §6.4.)
- Prefer behavior-level tests over source-text tests. Use injectable seams.
- Validation: run the smallest focused tests while iterating; run
  `flutter analyze` and the full `flutter test` **once** on the final tree.
  Do not run several Flutter commands concurrently.
- Preserve existing comments unless they become factually wrong. Note:
  `custom_course_transfer_service.dart:143` says exports are "independent from
  desktop file-picker/portal support". That stays true for the default path but
  the comment must be amended to mention the new additive dialog path.
- Data-only import, size limits and Course Audit gates must not be weakened.

## 3. Inventory (Step 0 result)

Stack: single-package Flutter app; platform folders `android`, `windows`,
`linux`, `macos` exist. **No `ios` folder.** `pubspec.yaml` already has
`path_provider` and `share_plus`; there is **no file-picker dependency**.
All fixed folders live under `getApplicationDocumentsDirectory()/QuisquisLingo/`.

### 3.1 Export side (bytes are built first, then written to a path)

| # | Artifact | Entry point | Fixed target | Called from |
|---|---|---|---|---|
| E1 | Course export | `CustomCourseTransferService.exportCourse(Course)` (`lib/services/custom_course_transfer_service.dart:128`) | `Exports/quisquislingo_<title>.json`, suffix `_2`,`_3` if it exists | `course_projects_screen.dart:1970`, `course_editor_screen.dart:2188`, `course_version_history_screen.dart:98` |
| E2 | Learner (user-data) backup | `LearnerBackupService.saveActiveProfile()` (`learner_backup_service.dart:117`) | `Exports/quisquislingo_<name>_backup.json` (+ suffix) | `user_data_settings_screen.dart:172` |
| E3 | User Recovery Key | `UserRecoveryKeyService.exportActiveUserRecoveryKey()` (`user_recovery_key_service.dart:72`) | `Exports/quisquislingo_<id>.user-recovery-key.json` (+ suffix) | `user_data_settings_screen.dart:26` |
| E4 | Diagnostic Log copy | `DiagnosticLogService.exportToFile()` (`diagnostic_log_service.dart:101`) | `Logs/quisquislingo_diagnostic_log.txt` | `debug_screen.dart:80` |
| E5 | Crash Log | live file at `CrashLogService.instance.crashLogPath`; currently only `SharePlus` (`debug_screen.dart:106`) | canonical, never moved | `debug_screen.dart` |
| E6 | Automatic Course Backups | `CourseBackupService.createBackup` | `Exports/Course Backups v9/...` | Course Editor saves. **Must stay unchanged.** |

### 3.2 Import side (path-bound today)

| # | Artifact | Entry point | Fixed source | Validation location |
|---|---|---|---|---|
| I1 | Course import | `importCourse()` → `_readCourse(path, name)` (`custom_course_transfer_service.dart:71,77`) | `Imports/import.json` | Inside `_readCourse` after the read: exists, 10 MB (`maxJsonBytes`), UTF-8, JSON, root object, `Course.fromJson`, `CourseFlagService.validateWorldFlag`, 1 MB flag limit, Base64 check |
| I2 | Course merge source | `mergeCourse()` (same `_readCourse`), used by `CourseMergeService.readMergeCourse` (`course_merge_service.dart:78`) | `Merges/merge.json` | same as I1 |
| I3 | Learner backup | `LearnerBackupService.readImportFile()` (`learner_backup_service.dart:146`) → `decodeDocument(List<int>)` | `Imports/learner_import.json` | `decodeDocument` (**already bytes-based**); 10 MB length check is in `readImportFile` |
| I4 | User Recovery Key | `findImportableUserRecoveryKeys()` (`user_recovery_key_service.dart:108`) → `decodeDocument(List<int>)` | scans `Imports/*.user-recovery-key.json` | `decodeDocument` (**bytes-based**); size limit `_maximumKeyBytes` is in the scan loop |
| I5 | Image Bank ZIP | `ImageBankService.pickAndImportBank` → `importBankZip(File)` (`image_bank_service.dart:74,100`) | exactly one ZIP in `Imports/Images` | in `importBankZip`; **path/File-bound**; despite the name it is not a dialog |
| I6 | Other folder-based importers (**out of scope, owner: no**) | `RecordedAudioService` (`Imports/Audio`), `ExerciseImageService.importImage` (`Imports/Images`, exactly one file), `LessonIconService.importPreparedIcon` (`Imports/Lesson Icons`) | folder scans | not part of QQL 240 |

### 3.3 Findings that shape the design

- The **decoders for I3/I4 already accept bytes**; only the file read and length
  check are path-bound. I1/I2 need `_readCourse` split into
  *read-file* + *validate-bytes*.
- Exports E1–E3 build their payload bytes **before** touching the file system,
  so `Save to…` can reuse the identical payload. Unique-name suffixing
  (`_2`…) belongs only to the default path; a dialog supplies its own name and
  the OS handles overwrite confirmation.
- Visible text that becomes wrong/incomplete and must be updated:
  `user_data_settings_screen.dart:409` ("No Save As dialog"), `:442`
  ("without a file picker"); Course import help text
  `course_projects_screen.dart:75-78`; Device Administration help mentions of
  the fixed folders remain true (they describe the default path).
- No separate "report" generator exists; the owner confirmed "reports" means the
  Crash Log (Q2), already covered by E5 in the Logs revision.
- Not yet inspected in depth (do this before the revision that needs it):
  `CrashLogService` internals, `CourseBackupService.loadBackup` and its restore
  UI, `CourseVersionHistoryScreen`, the I6 importers.

### 3.4 Existing tests to extend or mirror

`course_transfer_v6_225_02_test.dart`, `course_authoring_transfer_226_02_test.dart`,
`course_editor_export_226_02_test.dart`, `authoring_transfer_ui_226_02_test.dart`,
`imported_course_v6_regression_test.dart`, `course_backup_v9_clean_cut_test.dart`,
`qql_233_user_recovery_key_test.dart`, `debug_logs_228_03_test.dart`,
`startup_diagnostic_service_test.dart`. Services already expose injectable
directory/writer providers; follow that pattern.

## 4. Platform scope

| Platform | Target? | Dialog backend | Validation possible here |
|---|---|---|---|
| Windows | Yes | native Save/Open via desktop package | Yes (the owner's PC) |
| Linux | Yes — start with default Debian/Ubuntu/antiX installs | GTK dialog (see §5) | Owner to test on a Debian-family install |
| Android | Yes | Storage Access Framework via picker package | Emulator only (no device); install Android Studio, **Google Play** system image; owner signs in to a test Google account themselves |
| macOS | Code path exists, backend automatic with the desktop package | same desktop package | **Not testable here** — document as unverified |
| iOS | **Deferred.** No `ios` project exists; no Mac. Interface stays platform-neutral so a backend can be added later | — | Would need a cloud Mac / CI macOS runner; document as unsupported |

`docs/PLATFORM_COMPATIBILITY.md` already says not to claim macOS/iOS validated
until built and smoke-tested on macOS. Keep that rule.

## 5. Package decision (verified against pub.dev, 2026-09-19)

Findings:

- `file_selector` 1.1.0: supports Android/iOS/Linux/macOS/Web/Windows, but
  **`getSaveLocation` is not supported on Android/iOS/Web** (Linux/macOS/Windows
  only). It runs the GTK dialog in-process on Linux — and Flutter Linux already
  requires GTK3 — so it needs no extra executables.
- `file_picker` 13.1.0: Android, iOS, Linux, macOS, Windows, Web. `saveFile`
  **returns a path (`Uri?`) on desktop and writes the given `bytes` itself on
  Android/iOS/Web**. Cloud files (Google Drive, Dropbox, iCloud) are supported
  for picking; read via `PlatformFile.readAsBytes()`/`readAsByteStream()`.
  **Unverified:** whether its Linux backend shells out to `zenity`/`kdialog`
  (could not confirm from pub.dev/the wiki). If it does, that is a poor fit for
  minimal desktops such as antiX.
- `file_selector_android` 0.5.2+11 is the endorsed Android implementation of
  `file_selector`; it does not add a save dialog.

**Decision (provisional, confirm in the Android spike):**

- Desktop (Windows, macOS, Linux): **`file_selector`** (`getSaveLocation`,
  `openFile`). It returns a path; QQL writes/reads it through the same stream
  interface.
- Android: **`file_picker`** (`saveFile(bytes:)`, open + `readAsBytes()`), because
  `file_selector` cannot save on Android.
- Both are hidden behind one QQL interface (§6.1); no screen or service imports
  either package directly. If the spike shows `file_picker` alone is fine on
  every target (including Linux without zenity), collapse to one package and
  record it in the Decision log.

Adding dependencies changes `pubspec.yaml`/`pubspec.lock`; run `flutter pub get`
once, and check the Linux and Windows builds still generate their plugin
registrants (verify actual content of generated files before treating them as
changes; see `AGENTS.md`).

## 6. Architecture

### 6.1 New service: `FileDialogService` (new file, e.g.
`lib/services/file_dialog_service.dart`)

Small, injectable, **no** course/backup/serialization knowledge.

```
enum FileDialogOutcome { saved, opened, cancelled, failed, unavailable }

class FileDialogResult<T> {
  outcome, displayName (file name only), value (bytes for open), failureReason
}

abstract class FileDialogBackend {          // faked in tests
  Future<bool> get isAvailable;
  Future<FileDialogResult<void>> saveBytes({
    required Uint8List bytes, required String suggestedName,
    required List<String> extensions, String? mimeType });
  Future<FileDialogResult<Uint8List>> openBytes({
    required List<String> extensions, required int maxBytes });
}
```

- One production implementation per package (desktop / Android) chosen by
  `Platform`, plus an `UnavailableBackend` for anything else.
- **Bytes in, bytes out.** No file paths cross the interface, because Android
  and cloud providers return document URIs, not paths. On desktop the backend
  writes/reads the chosen path itself.
- `maxBytes` is enforced on open **before/while** reading where the backend
  allows it; the caller's authoritative validator still re-checks the size.
- Extension filters are **hints only** (Android providers may ignore them or
  rename files). Never trust the extension; the validator decides.
- **Cancel is `cancelled`, not an error.** It shows nothing and logs nothing.
- Never throws to callers: catches, returns `failed`/`unavailable` and logs
  (§7). Injected `DiagnosticLogService` and an injected clock/platform seam for
  tests.
- Writes on desktop go to a temp file in the destination directory then rename
  (or write whole file with flush) so a failure cannot leave a truncated file
  where the user expects a good one. On Android the backend hands the full byte
  array to the picker in one call.

### 6.2 Export pattern (E1–E3 first; identical for later artifacts)

Refactor each exporter into two steps **without changing default behavior**:

1. `buildXxxExport(...)` → `{Uint8List bytes, String suggestedFileName}` — the
   exact payload and base name the fixed-folder path already produces (including
   size-limit exceptions, e.g. 10 MB `FormatException`).
2. Destination: existing `exportXxx()` = build + fixed-folder write with
   unique-name suffixing (**unchanged output**); new `saveXxxTo(...)` = build +
   `FileDialogService.saveBytes`.

The default and dialog paths must call the same build function. A test must
prove byte-for-byte identical payloads.

### 6.3 Import pattern (I1/I2 first; I3/I4 next)

- I1/I2: split `_readCourse(path, fileName)` into `_readCourseFile` (exists +
  length + read bytes) and `courseFromBytes(Uint8List bytes, String label)`
  (UTF-8 → JSON → `Course.fromJson` → flag/Base64 validation). Both the fixed
  path and `Open from…` end in `courseFromBytes`. The 10 MB check must apply to
  both (length before read on the file path; `maxBytes` + post-read length check
  for the dialog path). Error messages stay unchanged where the source is the
  fixed folder; the dialog path may name the chosen file instead of `import.json`.
- Add `importCourseFromDialog()` / `mergeCourseFromDialog()` (name TBD) that
  call `openBytes` then `courseFromBytes`. The result feeds the **existing**
  same-`courseId` collision flow (Replace/update, Separate copy, Cancel) in
  `course_projects_screen.dart` — do not duplicate that logic.
- I5 (ZIP) and other path-bound importers, if ever added: copy the picked bytes
  to a file in `getTemporaryDirectory()`, run the existing path-based importer,
  delete the temp file in `finally`. Not in rev 0.

### 6.4 Temp files and reset inventory

Staging copies use `getTemporaryDirectory()` only and are deleted in `finally`.
That is not a persistent user-file folder, so `AppResetService`/`InventoryService`
need no change. **If a future revision persists anything new, follow the
AGENTS.md Change-discipline rule.**

### 6.5 UI convention (consistent everywhere)

- Export side: `Export` (existing) and `Save to…`
- Import side: `Import` (existing) and `Open from…`
- Manual backup copies (later): `Save backup copy to…`, `Open backup from…`
- Logs: `Save log copy to…` (keep existing Share)
- Recovery Key: `Save Recovery Key to…`, `Open Recovery Key from…`

Buttons that are unavailable (`FileDialogOutcome.unavailable` at startup probe)
are hidden or disabled with a one-line explanation; the default buttons stay
fully functional. New labels/messages must be added for every UI language QQL
localizes for these screens (check how the surrounding screens localize; most
current settings/help text is plain English, so match the neighbours).

## 7. Errors, fallback and logging

Outcomes and user-visible behavior:

| Outcome | User sees | Diagnostic Log |
|---|---|---|
| `saved` / `opened` | Same success message as the default path, naming the file name (and, on desktop, the chosen folder) | no |
| `cancelled` | nothing | **no** |
| `failed` (write error, provider offline, access denied, unreadable file) | Plain message + fallback hint | yes |
| `unavailable` (no backend, picker cannot launch, missing component) | Buttons hidden/disabled with short explanation; default buttons unchanged | yes, once per session |

Fallback wording (adapt per artifact; always **offer**, never do silently):

- Save failed: "Couldn't save to that location. You can use **Export** instead;
  it saves to QQL's Exports folder: `<path>`."
- Open failed: "Couldn't open that file. Copy it to QQL's Imports folder
  (`<path>`, named `import.json`) and use **Import**."
- The messages must use the real fixed-folder path already shown elsewhere (the
  services expose `transferDirectory()` / `importFilePath()`).
- An **invalid file** picked through `Open from…` is *not* a dialog failure: it is
  reported through the same validator error a fixed-folder import would show.
- Never fall back silently to the fixed folder; the user must know where the file
  went.

Diagnostic Log entry (use the existing `DiagnosticLogService`; it currently has
`log(AppErrorCode, {context, exception, stackTrace})` and `logInfo(message)`;
add an `AppErrorCode` in `lib/services/app_errors.dart` if the existing style
requires one — check how other codes are declared):

- platform, direction (save/open), artifact type, outcome, exception type and
  message.
- **File name only, never the full path** (the log can be sent to the
  developer; paths often contain the user name). No file contents, ever
  (Recovery Key contains a secret).
- Logging must never throw or block (the existing `log` already swallows errors).

## 8. Revision plan

QQL 240 is split so each revision is reviewable. **Revision 0** is the first
delivery.

### Revision 0 — Steps 0–6 of the owner's plan

Deliver:

1. Android **spike first** (see §9): prove Save + Open (including a Drive-backed
   document) through the picker in the emulator with a throwaway button/test
   before building on the interface. Record the result in the Decision log. If
   the spike changes the package decision, update §5 first.
2. `FileDialogService` + backends + fakes (§6.1) and unit tests.
3. **E1 Course export `Save to…`** in all three UI locations (Course Manager,
   Course Editor, Version History) — see §3.1. Reuse one helper so the three
   screens do not each reimplement outcome handling.
4. **I1 Course import `Open from…`** on the Course Import screen
   (`CourseImportScreen`, opened from `course_projects_screen.dart:652`), feeding
   the existing collision flow.
5. Update the stale help/visible text (§3.3) for the screens touched in this
   revision only.
6. Windows validation, then Android emulator validation (checklists in §9).
7. Version/build bump, Beta expiry refresh, `CHANGELOG.md`,
   `docs/240_VALIDATION.md`, `README`, `docs/PLATFORM_COMPATIBILITY.md` note,
   `AGENTS.md` release-boundary line for 240.0 (follow how 239 was recorded).

Version: `2.0.40+240000` (owner-confirmed). Beta expiry: **unchanged at
`2026-10-19 23:59:59`** (owner-confirmed exception, §10 Q5); leave the expiry
code, its tests and the docs that state it untouched, and note the exception in
`docs/240_VALIDATION.md` and the CHANGELOG.

Out of scope for rev 0: merge source, user data, Recovery Key, logs, manual
backups, reports.

### Later revisions (each needs its own short plan + validation pass)

| Rev | Content | Notes |
|---|---|---|
| 1 | User Data (E2 + I3): `Save to…` / `Open from…` | Same split as §6.2/6.3; `decodeDocument` already bytes-based; format unchanged |
| 2 | Recovery Key (E3 + I4): `Save Recovery Key to…` / `Open Recovery Key from…` | Warn once before saving: the key is a secret and a chosen folder (Downloads, Drive) may sync or be shared. Keep visibly distinct from user-data backup. `Open` reads one file (no folder scan) then `decodeDocument` |
| 3 | Logs (E4 Diagnostic Log + E5 Crash Log — the only "reports"): `Save log copy to…` | Snapshot copy only. Do not move the live Crash/Diagnostic Log. Keep Share. No `Open from…`. Inspect `CrashLogService` first |
| 4 | Image Bank ZIP (I5): `Open from…` for the single `.zip` | Owner-approved. Copy picked bytes to a temp file, run existing `importBankZip(File)` (50 MB limit, entry-count and manifest checks unchanged), delete temp in `finally`. Keep `pickAndImportBank` fixed-folder behavior. Sits on the Flat Image Library screen (`flat_image_library_screen.dart:159`) |
| 5 | Manual backup copy/restore | `Save backup copy to…` / `Open backup from…`; **inspect `CourseBackupService.loadBackup` and Version History first**. Automatic backups unchanged |
| 6 | Optional external merge source (I2) | Validate on staged/in-memory bytes without permanent import |
| Not planned | MP3 / single-image / lesson-icon folder importers (owner: no); iOS | Only on owner request |

### 8.1 Owner additions (2026-09-19, after the Windows side of rev 0)

The owner listed what is still missing. Mapping to the plan:

| Requested | Plan item | Status |
|---|---|---|
| Open Image Bank ZIP | I5, rev 4 | Planned |
| Open MP3 **zip** | none | **New and unclear**: today's MP3 import scans `Imports/Audio` for loose `.mp3` files; there is no ZIP format. Needs an owner decision (Q6) |
| Merge From (open a second course file to merge with the selected one) | I2, rev 6 ("optional external merge source") | **Promoted from optional to requested**; reuses `courseFromBytes`, so it is small |
| Crash Log: get it out to another place | E5, rev 3 | Planned as `Save log copy to…` (a copy of the live file; the live file is never moved or opened for editing) |
| Diagnostic Log: save to any folder | E4, rev 3 | Planned |
| User Data save / open | E2 + I3, rev 1 | Planned |
| User Recovery Key save / open | E3 + I4, rev 2 | Planned |

Suggested order after rev 0 (small, reuse-heavy first): **rev 1** Merge From +
Image Bank ZIP (reuse rev-0 machinery); **rev 2** User Data; **rev 3** Recovery
Key; **rev 4** Crash and Diagnostic Log copies; MP3 after Q6. (Supersedes the
rev numbers in the §8 table where they differ.)

**Unrelated, wording-only fix done (2026-09-19), broader revision deferred:**
the shared image library (admin-only) and course-level custom images (any course
editor) were confusingly both called "images". Renamed "Admin Media Library" /
"Media Library" / "Image Bank" tile to **Shared Image Library (admin)** and
explained the two tiers in the Course Editor, Device Administration, its Help
and the exercise-image field help. Widget keys and the button labels
`Choose flat image` / `Import custom image` are unchanged. **Deferred for a
later revision:** importing several custom images at once (MP3 import takes a
whole folder, image import exactly one file), and any course-owned image bank.
Note: an ordinary exercise image is stored as a local path on the device (course
JSON does not carry it); only Recognize characters images are embedded.

Open question: **Q6** what "Open MP3 zip" means (see above).
**Q7 answered by the owner:** the first dialog ever opened starts in Downloads
(desktop only; Android's picker chooses its own start); afterwards QQL passes no
folder so the OS remembers the last one. Implemented in `FileDialogService`
with the device-wide flag `qql_file_dialog_downloads_offered_v1` (listed in
`docs/239_RESET_STORAGE_INVENTORY.md`, cleared by "everything").

### 8.2 Dialogs created so far (17), with what each one stores

All go through `FileDialogService` (`lib/services/file_dialog_service.dart`) and reuse
the fixed-folder builder/validator; the fixed-folder button stays next to each.

| # | Where in the app | Button | Direction | What it stores / where |
|---|---|---|---|---|
| 1 | Course Manager → course actions menu | Save to… | Save | Chosen location (outside QQL) |
| 2 | Course Editor → Course page | Save Course JSON to… | Save | Chosen location |
| 3 | Version History | Save historical version to… | Save | Chosen location |
| 4 | Profile → User Data | Save my data to… | Save | Chosen location |
| 5 | Profile → User Data | Save Recovery Key to… (privacy warning first) | Save | Chosen location |
| 6 | Debug → Crash Log | Save log copy to… | Save | Chosen location; live log only read |
| 7 | Debug → Diagnostic Log | Save log copy to… | Save | Chosen location; internal log untouched |
| 8 | Course Import screen | Open from… | Open | New/updated custom Course in settings (preferences) |
| 9 | Course Merge screen | Merge From… | Open | Nothing stored; result is a new custom Course |
| 10 | Media Library menu (admin) | Open Image Bank ZIP from… | Open | `<AppSupport>/image_banks` + preference keys; temp copy deleted |
| 11 | Media Library menu (admin) | Open single image from… | Open | `<AppSupport>/exercise_images` + shared-library record |
| 12 | Exercise image editor | Open image from… (icon) | Open | `<AppSupport>/exercise_images` (path saved in the exercise) |
| 13 | Recognize characters editor | Open portable image from… | Open | Embedded in the Course JSON (no file) |
| 14 | Lesson theme icon sheet | Open custom icon from… (icon) | Open | Embedded in the Course JSON as base64 PNG (no file) |
| 15 | Audio Library | Open MP3 from… (icon) | Open | `<AppSupport>/quisquislingo_audio/course_<hash>/` (one file per import) |
| 16 | Profile → User Data | Open my data from… | Open | Learner profile records in preferences |
| 17 | Profile → User Data | Open Recovery Key from… | Open | New learner profile in preferences |

### 8.3 Reset coverage and orphaned media (verified in code 2026-09-19)

The dialogs add **no new persistent storage** beyond the device-wide flag
`qql_file_dialog_downloads_offered_v1`, because every imported item uses exactly
the folder or record its fixed-folder import already used. So the admin reset
wizard and the Inventory cover everything the dialogs import. Files chosen with
**Save to…** are outside QQL: it neither tracks nor deletes them.

| Item | Stored in | Inventory | Admin reset that removes it |
|---|---|---|---|
| Imported single images (editor, admin library) | `<AppSupport>/exercise_images` | "Imported images" | Remove imported media → images; Custom courses; Everything |
| Image banks | `<AppSupport>/image_banks` + 2 preference keys | "Image banks" | same |
| Recorded MP3s | `<AppSupport>/quisquislingo_audio/course_<hash>` | "Imported audio files" (owner shown; "A course no longer on this device" if orphaned) | Remove imported media → audio; Custom courses; Everything |
| Custom lesson theme icons | inside the Course record (preferences), base64 PNG | (part of the course) | with the Course: Custom courses; Everything; deleting the course |
| Portable (embedded) images | inside the Course record | (part of the course) | with the Course |
| Courses, User Data, Recovery Key profiles | preferences | not files | Custom courses / Learner removal / Everything |
| Temp copy (Image Bank ZIP only) | OS temp folder | no | deleted by QQL right after import |

**Orphan gaps found (existing behavior, unchanged by 240):**
- Removing a clip in the Audio Library, leaving it without saving, or deleting a
  Course does **not** delete the MP3 file (`RecordedAudioService.deleteFiles`
  exists but nothing calls it). Only the bulk "Remove imported media → audio"
  reset removes it.
- Images imported into an exercise are never deleted when the exercise changes or
  the Course is deleted; only the bulk images reset removes them. The admin
  library's per-image delete and bank removal do delete their files.
- Both are visible in Device Administration → Inventory (audio shows the owner).
- Possible later revision: a "Remove unused media" action that deletes files no
  Course references (must check every Course, including hidden/other learners'
  custom Courses, and ask for confirmation).

### 8.4 Later revision (plan only, NOT started): "Remove unused media"

Goal: let an admin find and delete managed media files that no Course references,
after review and confirmation. Not part of rev 0; separate from the dialogs.

**Candidates (files QQL itself copied):** everything under
`<AppSupport>/exercise_images` and `<AppSupport>/quisquislingo_audio/course_<hash>/`.
Never touched: `image_banks` (removed only by bank removal or the media reset),
bundled `assets/`, anything under Documents (Exports, Imports, Logs, Merges),
and files the user saved with `Save to…`.

**What counts as a reference (a file is kept if ANY of these mentions it):**
1. Every Course in `CourseEditorStorage.userCoursesKey` and
   `externalOfficialCoursesKey` — courses are device-wide, so "other learners'"
   and hidden courses are already in this one store (hiding is a per-learner
   display preference only). Detect references by scanning the whole Course JSON
   for any string equal to the managed path, so it does not depend on field
   names (`audioLibrary[].filePath`, exercise/prompt/item image fields).
2. Automatic Course Backups (`Exports/Course Backups v9/<courseId>/…`): an old
   version restored into a working copy would otherwise point at a deleted
   file. Conservative default: backups count as references.
3. Shared image-library records (`quisquislingo_exercise_image_metadata_v2`,
   `assetPath`) and the image-bank index.
4. Match by full path first, then by file name, so a moved app-data folder
   cannot make a used file look unused. When in doubt, keep the file.
   An audio folder `course_<hash>` is "owned" when the hash matches any known
   Course ID, including deleted-course backups.

**Safety rules**
- Admin-only and PIN-gated exactly like the existing resets (check in the
  service, not only the UI); reachable from Device Administration → Inventory.
- Two steps: (1) a read-only report listing each file, size, owner course and
  why it looks unused, plus totals; (2) confirmation naming the count and size,
  saying it cannot be undone and suggesting a backup/export first. Nothing is
  deleted without step 2.
- **Never delete a file that may belong to unsaved work.** A clip or image
  imported in an open editor is not referenced until the Course is saved. So:
  skip files created in the current app session and files newer than a
  threshold (proposal: 24 h), and refuse to run while any Course Editor is open.
- Do not follow links; delete only regular files inside the two candidate
  roots; remove a `course_<hash>` folder only if empty afterwards.
- Write only counts and file names (no paths, no contents) to the Diagnostic Log.
- Idempotent and resumable; a failed delete is reported, never fatal.

**Smaller alternative or complement (prevents most orphans at the source):**
delete an MP3/image file when its removal is *confirmed* by the Course Editor's
top-level save (not when the working copy changes, because Cancel must restore
it), and delete a Course's audio folder in `deleteUserCourse`. This touches Course
Editor persistence, so it needs its own characterization tests.

**Code shape:** new `UnusedMediaService` (`scan()` → report, `remove(report)`),
injectable directories/clock like `AppResetService`; a section in the Inventory
screen; tests with temporary directories covering: referenced file kept,
unreferenced old file listed, fresh file skipped, file referenced only by a
backup kept, other course's file kept, hash-owned audio folder kept, bank folder
never touched, PIN required, cancel deletes nothing. Docs to update:
`docs/239_RESET_STORAGE_INVENTORY.md`, Device Administration Help, CHANGELOG.
No new preference keys expected.

**Owner answers (2026-09-19):** backups count as references; the 24 h guard
needed explaining (it protects files imported in an open editor that are not yet
saved, see above); deletion is chosen per file / per course; do the smaller
prevent-at-source fix first.

**Findings that change the "smaller fix" (verified in code, 2026-09-19):**
1. **Courses can share one MP3 file.** `AuthoringDuplicationService`
   (Duplicate / Fork / Copy as New Course) copies `audioLibrary` clips with the
   **same `filePath`**, i.e. pointing at the original course's managed file.
   Deleting a file when one course removes the clip, or deleting a course's audio
   folder with the course, would break every copy that still uses it. So any
   deletion, at save, at course deletion or in the cleanup tool, must first
   check that no other Course references the path.
2. **Backups already hold their own copy of MP3s** (`CourseBackupService` copies
   every managed clip into `<manifest>_assets/` and restores from that copy), so
   for audio a backup does not need the original managed file. **Images are
   different:** backups store only the path, so a deleted image would break an
   old version restored from a backup.
3. **The pre-change backup always references the file being removed.** Every
   confirmed change first archives the previously persisted Course, which still
   contains the clip/image. If "backups count as references" is applied
   literally, nothing removed by a normal edit would ever become unreferenced,
   and the cleanup would only find never-saved or deleted-course files.

**Proposed refinement (needs owner confirmation):**
- Reference rule per media type: **audio** = referenced by any current Course
  (backups do not count, because they carry their own copy); **images** =
  referenced by any current Course *or any backup manifest*.
- Build one shared `MediaReferenceIndex` (all current Courses, plus backup
  manifests for images) first. It is the foundation for everything below.
- Smaller fix on top of it: after a **confirmed** Course save, delete an MP3 the
  save removed only if the index says no other Course uses it; on
  `deleteUserCourse`, delete the course's audio files that no other Course
  uses. Images are not auto-deleted at save (backups still point at them); they
  are left to the cleanup tool.
- Then the cleanup tool (per-file / per-course choice) on the same index.

**Owner confirmed (2026-09-19):** the per-type rule above, and the "recently
created" guard of the cleanup tool is **30 days** (not 24 h): files created in the
last 30 days are never offered for deletion.

**The cleanup tool now has its own implementation-ready plan:
`docs/240_REMOVE_UNUSED_MEDIA_PLAN.md` (2026-09-20). Implementation is
deliberately postponed by the owner.**

**Status of the smaller fix: IMPLEMENTED (audio only), tested.**
- `lib/services/managed_media_cleanup.dart`: `MediaReferenceIndex` (all short
  text values in the stored custom + external-official Courses; path match is
  case- and slash-insensitive; embedded `data:` and long values ignored) and
  `ManagedAudioCleanup` (deletes only regular, non-link files inside
  `<AppSupport>/quisquislingo_audio`, refuses `..` escapes, does nothing when
  the index is incomplete, removes a course folder once empty, never throws).
- `CourseEditorService`: after `confirmCourseTransaction` has persisted **and
  verified** the Course, MP3 files that the previous version used and the new one
  does not are removed if no other stored Course uses them; `deleteUserCourse`
  does the same for the deleted Course's files. Best effort: a failure never
  fails a save or delete.
- Tests: `test/managed_audio_cleanup_240_test.dart` (10): removed clip deleted,
  kept clip kept, file shared with another Course kept, unrelated change keeps
  all, bundled `assets/` and files outside the audio folder untouched, old
  version still restores from the backup's own copy, Course deletion (shared
  files stay, empty folder removed), incomplete index deletes nothing, path
  matching, `..` escape refused. The 417 existing tests that use the editor
  service or backups still pass.
- **Not covered (by design, for later):** images (backups only store their
  paths, so they wait for the cleanup tool); `installImportedCustomCourse`
  "Replace / update"; clips imported and dropped before the first Save (never
  referenced, so the 30-day-guarded cleanup tool will find them); the cleanup
  tool itself.
- **User-visible behaviour change to document at wrap-up (CHANGELOG, Audio
  Library help):** removing a clip and saving the Course, or deleting a Course,
  now also deletes the copy QQL made of the MP3. The user's original file and
  the backups' own copies are untouched.

## 9. Validation

### 9.1 Automated tests (rev 0; per artifact type thereafter)

Use fakes for `FileDialogBackend`; do not depend on real dialogs in tests.

- Default export path unchanged (same directory, filename, suffixing, bytes).
- Dialog export: same bytes as default export; suggested filename correct.
- `cancelled` does nothing: no file, no message, no log line.
- `failed` shows the fallback message and writes a Diagnostic Log entry with
  file name only.
- `unavailable` hides/disables the new buttons; default buttons still work.
- Import via dialog: valid file accepted; invalid JSON, wrong UTF-8, oversize,
  bad flag data rejected with the **same errors** as the fixed-folder path
  (parametrize one test table across both sources).
- Same-`courseId` collision flow reached from the dialog path.
- No duplicate serialization/validation logic (a single builder / single
  `courseFromBytes` used by both; assert via behavior, not source text).
- Automatic Course Backups unchanged (existing `course_backup_v9_clean_cut_test`
  must still pass untouched).
- Later revisions: logs remain canonical internally; Recovery Key stays distinct
  from user-data backup.
- Beta-expiry tests updated for the new version.

### 9.2 Manual checklists (record results in `docs/240_VALIDATION.md`)

Windows: native Save opens; native Open opens; cancel is harmless; suggested
filename appears; overwrite prompt behaves; invalid file rejected with the
standard message; Unicode path and filename; long path (>260) where supported;
default Export/Import unchanged.

Linux (Debian/Ubuntu/antiX): same list; also a machine/session where the dialog
cannot open (to exercise `unavailable`/`failed` fallback text).

Android emulator (Android Studio, **Google Play** image; owner signs in to a test
Google account): Downloads; Documents; Google Drive if exposed; another provider;
cancel; export/import work without any access to app-private folders; a
Drive-backed file opens (download-on-demand); offline/denied Drive produces the
fallback message. Mark real-device flakiness (slow/offline/revoked) as
**"emulator-verified, device pending"**; do not claim full coverage.

macOS/iOS: document as **unverified**.

Final gate (once, on the final tree): `flutter analyze`, full `flutter test`,
`git diff --check`, `tools/validate_courses.py` if course assets were touched,
`git status --short` review; confirm every changed line is required.

## 10. Open questions for the product owner

Answered by the product owner on 2026-09-19:

- **Q1** Package split: **confirmed** — `file_selector` (desktop) + `file_picker`
  (Android); collapse to `file_picker` only if the spike shows it works
  everywhere (then log it in §11).
- **Q2** "Reports" = the **Crash Log** (there is no other report generator).
  So there are no separate report steps: the Crash Log is handled in the Logs
  revision (E5, rev 3). Plan steps 9/13 are merged into it.
- **Q3** Folder-based importers (MP3, single exercise image, lesson icons): **no
  `Open from…`**. The **single-file Image Bank `.zip` (I5): yes** — added as its
  own revision (rev 4 in §8) using the staging-copy pattern in §6.3.
- **Q4** Localization: **English only**; match neighbouring plain-English text.
- **Q5** Version for rev 0 is **`2.0.40+240000`**. Owner: "update version, not
  date"; **confirmed on re-asking ("Do as I told you")**: bump the version but
  **leave the Beta expiry at `2026-10-19 23:59:59`**. This is a deliberate,
  owner-approved exception to the AGENTS.md rule that a version update
  refreshes the expiry. Do **not** touch `beta_lifecycle_service.dart` or the
  expiry assertions in tests/README/docs; record the exception in the CHANGELOG
  and `docs/240_VALIDATION.md`.

## 11. Decision log

| Date | Decision | Reason |
|---|---|---|
| 2026-09-19 | Dialogs are additive; fixed folders and automatic backups unchanged | Owner requirement |
| 2026-09-19 | Bytes/stream interface, no paths across the service boundary | Android/iOS return document URIs; cloud providers |
| 2026-09-19 | Cancel is not an error and not logged | UX; avoids log noise |
| 2026-09-19 | Failures logged to Diagnostic Log with file name only | Owner request; logs may be sent to the developer |
| 2026-09-19 | Never fall back silently to the fixed folder; only offer it with instructions | Users must know where their file went |
| 2026-09-19 | iOS deferred; macOS unverified | No iOS project, no Mac |
| 2026-09-19 | Provisional package split: `file_selector` desktop + `file_picker` Android | `file_selector` lacks Android save; GTK dialog on Linux needs no zenity; confirm in spike |
| 2026-09-19 | Owner confirmed the package split (Q1) | — |
| 2026-09-19 | "Reports" means the Crash Log; handled in the Logs revision | Owner answer Q2 |
| 2026-09-19 | Image Bank ZIP gets `Open from…`; folder-based importers do not | Owner answer Q3 |
| 2026-09-19 | UI text is English only | Owner answer Q4 |
| 2026-09-19 | Rev 0 version `2.0.40+240000`; Beta expiry stays `2026-10-19 23:59:59` | Owner answer Q5, confirmed on re-asking; exception to the AGENTS.md refresh rule |
| 2026-09-19 | Windows side implemented first; Android backend deferred (`UnavailableFileDialogBackend` there, so the buttons are hidden) | Owner: "start with Windows"; no Android device/emulator yet |
| 2026-09-19 | Oversize files opened via the dialog are read up to a 64 MB memory guard and rejected by the ordinary 10 MB validator | Gives the same error text as the fixed-folder import |
| 2026-09-19 | `course_editor_export_226_02_test` relaxed: Export must be the last existing entry; only the additive `Save Course JSON to…` tile may follow | The test guarded ordering, not the new feature |

## 12. Progress tracker

- [x] Step 0: Inventory (this document, §3)
- [x] Plan written (this document)
- [x] Owner answers Q1–Q5 (Q5b, Beta expiry handling, still open)
- [ ] Android Studio + Play emulator available (owner)
- [ ] Rev 0.1 Android spike; package decision confirmed (§5). **Windows/desktop half done** (`file_selector` 1.1.0 added to `pubspec.yaml`); Android `file_picker` half **not started**
- [x] Rev 0.2 `FileDialogService` + desktop/unavailable backends + tests — `lib/services/file_dialog_service.dart`, `AppErrorCode.fileDialogFailed/Unavailable` (FILE-001/002). **No Android backend yet**: extend `FileDialogService._defaultBackend()` with a `file_picker`-based `FileDialogBackend` for `Platform.isAndroid`
- [x] Rev 0.3 E1 Course export `Save to…` (Course Manager menu, Course Editor tile, Version History button) + tests — shared `CustomCourseTransferService.buildCourseExport` / `exportCourseTo`; messages via `lib/widgets/file_dialog_feedback.dart`
- [x] Rev 0.4 I1 Course import `Open from…` + shared `courseFromBytes` + tests — `importCourseFromDialog`, `CourseImportScreen.onOpenFrom`, `_importCourse(fromDialog: true)` reuses the audit/collision flow
- [x] **Owner asked (2026-09-19) to implement the missing features before Windows testing.** Done, all through `FileDialogService`, each reusing its fixed-folder validator/builder, with tests in `test/file_dialogs_240_features_test.dart` (shared fakes in `test/support/`):
  - Merge From… (`CustomCourseTransferService.mergeCourseFromDialog`, `CourseMergeService.readMergeCourseFromDialog`, button on `CourseMergeScreen`)
  - Open Image Bank ZIP from… (`ImageBankService.importBankZipFromDialog`, staged temp copy keeps the ZIP name and is always deleted; menu item in the Media Library)
  - Save my data to… / Open my data from… (`LearnerBackupService.saveActiveProfileTo` / `readImportFromDialog`)
  - Save Recovery Key to… (warning dialog first) / Open Recovery Key from… (`UserRecoveryKeyService.exportActiveUserRecoveryKeyTo` / `openUserRecoveryKeyFromDialog`)
  - Debug screen: Save log copy to… for the Crash Log (copy of the live file, read only) and the Diagnostic Log (`DiagnosticLogService.exportBytes`)
  - Custom lesson theme icon: Open custom icon from… (owner request 2026-09-19; single file, like the folder import). `LessonIconService.importPreparedIconFromDialog` → the same `prepareIcon` (2 MB, decode, 256×256 PNG). UI: icon button in the Lesson theme icon sheet (icon-only, because a text button made the sheet header wrap and broke `lesson_metadata_and_icon_test`). The recorded-MP3 and single exercise-image importers remain fixed-folder only.
  - **Delete custom lesson icon (owner request 2026-09-20, unrelated to dialogs):** a delete button on each custom icon in the Lesson theme icon sheet (`_deleteCustomIcon` in `course_editor_screen.dart`). Refused while any Lesson uses the icon (this Lesson's saved or unsaved choice, or another Lesson's saved icon) so no Lesson can point at a missing icon; asks for confirmation; it is a working-copy change kept on Lesson Save + Course confirm, and Cancel restores it. Icons are embedded in the Course record, so no file is deleted. Tests: `test/delete_custom_lesson_icon_test.dart` (4).
  - **Lesson theme icon sheet redesign (owner request 2026-09-20):** `Import custom icon` is now an icon-only button with a tooltip (key unchanged); the "None" tile is renamed **Numbers** (its key `lesson-theme-icon-option-none` is unchanged); the Preinstalled section is an `ExpansionTile` (`lesson-theme-icon-preinstalled-toggle`) that shows only the current choice (the selected preinstalled icon, or Numbers when nothing is chosen, or a plain "Preinstalled icons" row when a custom icon is chosen) and expands to the full grid; the sheet no longer has a fixed 76 % height, it sizes to its content and scrolls. Existing tests that assumed an always-visible grid now expand it first; new tests in `test/lesson_theme_icon_sheet_240_test.dart` (6).
  - Stale subtitles "No Save As dialog" / "without a file picker" removed
  - **Not done: MP3** (Q6 still unanswered).
- [ ] Rev 0.5 Help/visible text updates for touched screens (mostly done above) (Import screen instructions still describe only the fixed-folder route; acceptable but review)
- [ ] Rev 0.6 Windows validation recorded — automated tests done; **manual native-dialog checklist (§9.2) not yet run by a person**
- [ ] Rev 0.7 Android emulator validation recorded
- [ ] Rev 0.8 Version, Beta expiry, CHANGELOG, `docs/240_VALIDATION.md`, README, platform doc, AGENTS.md line
- [ ] Final gate (analyze, full tests, diff check, status review)
- [ ] Revisions 1–6 (see §8), each planned separately

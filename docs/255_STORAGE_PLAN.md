# Build 255 plan: logical QQL storage, Quick folders and Android storage

Owner plan of 25 September 2026 (Europe/Rome), with the owner's answers:

1. Course Quick folders move on **every desktop** (Windows, Linux, macOS), not
   only Windows.
2. No hint or fallback for files left in the old places (clean cut).
3. Android 7–9 may show the one-time storage permission prompt before the
   first Quick Export.
4. Android Quick Import uses one persisted folder permission for
   `Download/QuisquisLingo/Imports`; **Open from…** is offered as an
   alternative whenever that permission is missing.
5. Wipe everything and Inventory cover the Android public folders.
6. Buttons are renamed: **Quick Import**, **Quick Export**, **Save as…**
   (every dialog save label: Save as…, Save my data as…, Save Recovery Key
   as…, Save log copy as…, Save historical version as…). **Open from…** keeps
   its name. Merge keeps "Merge Course package or JSON" and "Merge From…".
7. Older-Android emulator images: pending the owner's decision on disk space.

## Revisions

| Revision | Version | Content |
| --- | --- | --- |
| 0 | `2.0.55+255000` | Audit; logical storage roles and layout; every Quick route goes through them; Course folders `Imports/Courses` and `Exports/Courses` on every desktop; Help and screens name folders through the layout; renames. |
| 1 | `2.0.55+255001` | Android native storage bridge: Storage Access Framework **Save as…** and **Open from…** (document URIs streamed into the existing bounded staging). |
| 2 | `2.0.55+255002` | Android public Quick folders: dialog-free Quick Export to `Download/QuisquisLingo/Exports/...`, Quick Import from `Download/QuisquisLingo/Imports/...` with one persisted folder permission, the other user outputs, Inventory and Reset. |

One local commit per revision, handoff in `docs/255_HANDOFF.md`, no push.

## Architecture

```
                 Logical QQL storage (QqlStorageRole)
                        |
        +---------------+---------------+
        |                               |
      Imports                         Exports
        |                               |
   Courses, Merges, Audio,        Courses, Learner data,
   Images, Lesson icons, Flags,   Recovery keys, Audit
   Learner data, Recovery keys    reports, Diagnostic logs
        |                               |
  platform layout + backend      platform layout + backend
```

- `lib/services/storage/qql_storage_role.dart`: `QqlTransferDirection`
  (imports, exports) and `QqlFileCategory` (courses, merges, ...). A
  `QqlStorageRole` is one used combination, e.g. `courseImports`.
- `lib/services/storage/qql_storage_layout.dart`: pure data. Maps a role to
  folder names below a platform's QQL root and to labels for messages and
  Help. `QqlStorageLayout.documents` serves Windows, macOS, Linux and iOS;
  Revision 2 adds the Android public layout.
- `lib/services/storage/qql_storage.dart`: `QqlStorage`, the one door from
  feature code. `QuickImportFolder` lists files and finds a file by name;
  each `QuickImportFile` is read as a stream (like a file chosen with
  Open from…), so no feature code depends on a path. `QuickExportFolder`
  writes `name.ext`, then `name_2.ext`, `name_3.ext`, or replaces.
  `readQuickImportFile` reads with a byte limit.
- `lib/services/storage/file_system_storage.dart`: desktop and iOS backend,
  folders below `<Documents>/QuisquisLingo`.

Feature code never builds a Windows, Android or iOS path for a user folder.
An iOS backend can later resolve the same roles to Files/document locations
without changing any feature code.

Help catalogs name folders with placeholders (`{folderCourseImports}`, ...),
filled from the current platform's layout by `helpText.lookup`.

## Audit of user files (Revision 0)

"User" files are ones a person puts in or takes out of QQL. "Internal" files
are QQL's own and stay private on every platform.

| Operation | Owner | Role | Desktop folder before → after | Android before | Android after (Rev 2) | Dialog route |
| --- | --- | --- | --- | --- | --- | --- |
| Course Quick Export (Export Course, Version History export) | user | `courseExports` | `Exports` → `Exports/Courses` | app-private | `Download/QuisquisLingo/Exports/Courses` | Save as… |
| Course Quick Import (`import.zip` / `import.json`) | user | `courseImports` | `Imports` → `Imports/Courses` | app-private | `Download/QuisquisLingo/Imports/Courses` | Open from… |
| Course Merge (`merge.zip` / `merge.json`) | user | `mergeImports` | `Merges` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Merges` | Merge From… |
| Export my data | user | `learnerDataExports` | `Exports` (unchanged) | app-private | `Download/QuisquisLingo/Exports` | Save my data as… |
| Import my data (`learner_import.json`) | user | `learnerDataImports` | `Imports` (unchanged) | app-private | `Download/QuisquisLingo/Imports` | Open my data from… |
| Export User Recovery Key | user (secret) | `recoveryKeyExports` | `Exports` (unchanged) | app-private | `Download/QuisquisLingo/Exports` | Save Recovery Key as… |
| Import User Recovery Key (`*.user-recovery-key.json`) | user | `recoveryKeyImports` | `Imports` (unchanged) | app-private | `Download/QuisquisLingo/Imports` | Open Recovery Key from… |
| Import MP3 (every `*.mp3`) | user | `audioImports` | `Imports/Audio` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Audio` | Open MP3 from… |
| Import custom / single image (exactly one) | user | `imageImports` | `Imports/Images` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Images` | Open image from… |
| Import Image Bank ZIP (exactly one) | user | `imageImports` | `Imports/Images` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Images` | Open Image Bank ZIP from… |
| Import portable image (Recognize characters) | user | `imageImports` | `Imports/Images` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Images` | Open portable image from… |
| Import custom Lesson icon (exactly one) | user | `lessonIconImports` | `Imports/Lesson Icons` (unchanged) | app-private | `Download/QuisquisLingo/Imports/Lesson Icons` | Open icon from… |
| Upload custom flag (`flag.png/.jpg/.jpeg`) | user | `courseFlagImports` | `Exports` (unchanged, historical) | app-private | `Download/QuisquisLingo/Imports` | none |
| Export Audit report | user | `auditReportExports` | `Exports` (unchanged) | app-private | `Download/QuisquisLingo/Exports` | Copy report |
| Export Diagnostic Log | user | `diagnosticLogExports` | `Logs` (unchanged) | app-private | `Download/QuisquisLingo/Exports/Logs` | Save log copy as… |
| Crash Log and session marker | internal (crash state) | none | `Logs` (unchanged) | app-private + Share | app-private (unchanged) + Share | Save log copy as… |
| Course Backups v11 (Version History) | internal (recovery) | none | `Exports/Course Backups v11` (unchanged) | app-private | app-private (unchanged) | — |
| Stored Courses, Course media, image banks, imported images, staging, TTS cache, preferences | internal | none | AppSupport (unchanged) | app-private | app-private (unchanged) | — |

Desktop folders are below `Documents/QuisquisLingo`. On Android, "app-private"
means the app's own documents directory, which a person cannot reach without
developer tools: every user file there moves in Revision 2.

## Behaviour notes (Revision 0)

- Quick Import of a Course package now reads through the same bounded
  private staging as Open from…, for every folder kind, before the package is
  parsed. Limits and messages are unchanged; an empty `import.zip` reports
  "import.zip is empty." like the dialog route.
- The Image Bank folder route copies the ZIP into a temporary file with its
  own name before checking it, exactly as Open Image Bank ZIP from… already
  did. A too-large folder ZIP now gives the dialog route's message.
- Every Quick folder is still created when it is asked for, so people can see
  where to put files.
- Old Course files in `Imports` or `Exports` stay where they are and are not
  read (clean cut, no hint).

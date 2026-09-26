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
| 3 | `2.0.55+255003` | One folder pattern on every system (see [Revision 3](#revision-3-one-folder-pattern-on-every-system)): `Import`, `Export`, `Logs`, `ToBeMerged`; flag import fixed; Crash Log Quick Export; `QQL_` export names; Crash Log and Course Backups private everywhere. |
| 4 | `2.0.55+255004` | Private folders (see [Revision 4](#revision-4-private-folders-and-language-pairs)): `QQL_` names, the language pair in every per-Course name (`QQL_EN_IT_<ID>`, backups `QQL_bkp_…`), exports `QQL_EN_IT_<title>.zip`; clean cut plus a one-off tool. |

One local commit per revision, handoff in `docs/255_HANDOFF.md`, no push.
Revisions 0–4 are implemented; Android was checked on the Android 16
emulator, and the Android 10 and Android 7–9 paths by mocked tests only (the
owner chose not to download older emulator images).

## Revision 3: one folder pattern on every system

Owner decisions of 26 September 2026: desktop and mobile behave the same
wherever possible, with one universal pattern. The QuisquisLingo folder is
`Documents/QuisquisLingo` on Windows, Linux, macOS (and iOS later) and
`Download/QuisquisLingo` on Android; below it everything is identical:

```
QuisquisLingo/
├── Import/
│   ├── Courses/        import.zip or import.json
│   ├── Audio/          MP3s
│   ├── Images/         one image, Image Bank ZIP or portable image
│   ├── LessonIcons/    one icon
│   ├── Flags/          flag.png, .jpg or .jpeg
│   ├── UserData/       learner_import.json
│   └── RecoveryKeys/   *.user-recovery-key.json
├── Export/
│   ├── Courses/        QQL_<title>.zip
│   ├── UserData/       QQL_<profile>_backup.json
│   ├── RecoveryKeys/   QQL_<id>.user-recovery-key.json
│   └── AuditReports/   QQL_audit_….txt
├── Logs/               QQL_crash_log.txt, QQL_diagnostic_log.txt
└── ToBeMerged/
    └── Courses/        merge.zip or merge.json
```

1. `Import` and `Export` (singular), `Logs`, and `ToBeMerged` (not `Merges`,
   not inside `Import`) with a `Courses` subfolder. Every kind of file has its
   own subfolder. Folder names have no spaces (`LessonIcons`, `UserData`,
   `RecoveryKeys`, `AuditReports`).
2. Upload custom flag reads `Import/Flags` (it read `Exports` on desktop and
   the `Imports` root on Android).
3. Android asks once for the whole `Download/QuisquisLingo` folder, so one
   permission covers `Import` and `ToBeMerged`.
4. The live Crash Log (and the Windows/Linux session marker) is private on
   every system; `Logs` holds only copies. A new Quick Export button for the
   Crash Log in Settings › Debug writes `Logs/QQL_crash_log.txt`, replacing
   the previous copy like Export Diagnostic Log does. The one-time Beta
   testing message points testers to that copy.
5. Course Backups (Version History) are private on every system. Desktop
   backups made before this revision stay in
   `Documents/QuisquisLingo/Exports/Course Backups v11`, untouched and no
   longer listed.
6. Every exported file starts with `QQL_` instead of `quisquislingo_`,
   including the names Save as… suggests. Recovery Keys are still recognised
   by their `.user-recovery-key.json` ending.
7. Old files are not moved, read or hinted at: `Imports`, `Exports` and
   `Merges` (and Android's `Imports`/`Exports`) are left alone. Inventory
   lists them honestly as folders from earlier versions, and Wipe everything
   treats them like their new counterparts.

Files read by name stay the same (`import.zip`, `merge.zip`,
`learner_import.json`, `flag.png`). Internal data stays private as before.

## Revision 4: private folders and language pairs

Owner decisions of 26 September 2026, `2.0.55+255004`. QQL's private storage
(the platform's application-support directory) gets `QQL_` names in the same
no-space style as the public folders, and every per-Course name carries the
Course's language pair, source then target (`EN_IT`). There are no language
folder levels: sorting by name groups each pair, paths stay short on
Windows, and a language change is a rename in place.

```
QQL_Courses/Custom/QQL_EN_IT_<ID>.json
QQL_Courses/Publisher/QQL_EN_IT_<ID>.json
QQL_CourseMedia/QQL_EN_IT_<sha256 of the ID>/<sha256>.<ext>    images and recordings
QQL_CourseBackups/QQL_bkp_EN_IT_<ID>/
    QQL_bkp_EN_IT_<ID>_v<version>_<date-time>.json (+ …_assets/)  one per saved version
QQL_SharedImages/        Shared Image Library device images
QQL_ImageBanks/
QQL_ImportStaging/
QQL_Logs/                QQL_crash.log, QQL_session.marker
```

Exported Course packages carry the same pair in the flat `Export/Courses`
folder: `QQL_EN_IT_<title>.zip`. An earlier version exported from Version
History (Export historical version, Save historical version as…) is marked
as a backup and carries its version: `QQL_bkp_EN_IT_<title>_v3.zip`.

1. **Language codes.** One owner turns a Course into its pair. A code is the
   primary subtag of the Course's language tag in capitals when there is one
   (`it-IT` → `IT`, `nap-IT` → `NAP`), otherwise it comes from the language
   name (English → `EN`, Neapolitan → `NAP`), otherwise the name itself in
   capitals with letters and digits only; empty gives `UNKNOWN`. Exercise
   Laboratory (English → Italian) is `EN_IT`; Italian → Neapolitan is
   `IT_NAP`. The naming owner is plain Dart, so the one-off tool uses the
   same code.
2. **Finding a Course.** Most callers know only the Course ID. A stored name
   ends with the ID (or its hash for media), so the stores find it whatever
   the pair; new names use the Course's current pair.
3. **Changing languages.** When a confirmed save changes a Course's source or
   target language, its file, media folder and backup folder are renamed in
   place under the same per-Course lock. Versions saved earlier keep their
   own names, which record the languages they had. A rename that fails
   part-way leaves the Course readable under its old name.
4. **IDs in names.** A QQL-made ID's own `course_` prefix is not repeated;
   bundled and Publisher IDs are used as they are. The store keeps refusing
   to replace a file that holds another Course, so even an unlikely name
   clash cannot overwrite anything.
5. **Clean cut.** The app reads only the new names; `qql_courses_v2`,
   `quisquislingo_course_media`, `qql_course_backups_v11`,
   `qql_import_staging` and `qql_logs` are left untouched. Shared Image
   Library images and Image Banks keep working from `exercise_images` and
   `image_banks`, because their records hold full paths; new ones go to
   `QQL_SharedImages` and `QQL_ImageBanks`. Inventory lists the earlier
   private folders; Wipe everything removes them with the rest of QQL's
   private data (earlier logs follow the Logs choice).
6. **One-off tool.** A desktop tool, like `tools/convert_course_to_v11.dart`,
   that the owner runs once with QQL closed: it moves each stored Course, its
   media and its backups (also those a desktop kept in
   `Documents/QuisquisLingo/Exports/Course Backups v11` before Revision 3)
   to the new names, never deletes or overwrites, and reports what it moved.
7. Preference keys keep their names (renaming them would reset settings).
   Course JSON is unchanged: media references stay `media:<sha256>.<ext>`.
   A backup is a complete earlier version of a Course with copies of its
   media; `bkp` marks it as earlier, not partial.

What the implementation added, found while building it:

8. **Case.** `qql_logs` and `QQL_Logs` differ only in case, so on
   Windows and macOS they are one folder. At startup
   (`DiagnosticLogService.logsDirectory(create: true)`)
   `QqlEarlierPrivateFolders.giveCurrentCase` gives such a folder its new
   name; a direct case-only rename was checked to work on Windows. Inventory
   and Wipe everything find earlier folders by their exact names
   (`QqlEarlierPrivateFolders.presentIn`) and skip one that is the same
   folder as a current one. On Linux and Android the earlier folder stays
   untouched.
9. **Taken names.** The Course store finds a file by the ID inside it; a
   readable file holding another Course is now simply not this one,
   instead of blocking the save (IDs such as `course_ab` and `ab` share
   the name part `ab`). A name that is taken is still never replaced:
   create, write and the rename on a language change refuse it.
10. **Android backup.** The Auto Backup exclusions follow the renames:
    `QQL_ImageBanks`, `QQL_SharedImages` and `QQL_CourseMedia` are
    excluded in both XML files beside the earlier names, and a test ties
    the files to the code's constants.
11. Temporary folders in the system's temp directory start with `QQL_`
    too (`QQL_ImageBank_…`, `QQL_TTS_…`).
12. **The tool.** `dart run tools/move_private_storage_255.dart
    [--support DIR] [--documents DIR] [--dry-run]`; on Windows the
    defaults are `%APPDATA%\QuisquisLingo\quisquislingo_app` and
    `%USERPROFILE%\Documents`. A Course already stored under the new
    names is left alone; media and backup files are merged into an
    existing folder file by file, never replacing one; a file on another
    drive is copied and its earlier copy stays. A dry run on the
    development PC showed 6 Courses and 6 media folders to move.

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

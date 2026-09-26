# Security and robustness notes

Updated for the current alpha

QuisquisLingo is an offline-first prototype. It does not implement remote accounts, HTTP course downloads, WebViews, cloud synchronization, analytics, advertising or remote code execution. The only application network feature is the optional read-only update check against the fixed official GitHub Releases API for `Quisquisnaut/QuisquisLingo`.

## Android device backup

This is a deliberate product decision, recorded here so it is not "corrected" later by someone reading `allowBackup="true"` as an oversight.

`android:allowBackup` is **true**. QuisquisLingo has no account and no server, so the platform's own Auto Backup is the only mechanism by which a learner survives a lost, broken or replaced phone. Turning it off would mean that losing the device always means losing every streak, every completed Lesson and every locally authored Course. That trade is not worth making for an offline learning app.

What is backed up, on purpose:

- learner profiles and the active learner
- progress, XP, streaks, study days, Review history, Duel state
- local course edits, authoring Teams and the image/media index
- device settings and one-time notice state
- the Access PIN verifier and the User Recovery Key credential

The Access PIN is in that list knowingly. It is a casual-access guard for a shared family device — it stops a sibling opening the wrong learner profile — and it is **not** a security boundary. It is a salted single-pass SHA-256 hash of four digits, so it does not resist anyone with file access, and the project has never claimed otherwise. Excluding it from backup would not make it stronger; it would only mean a restored learner silently loses their PIN. The same reasoning applies to the User Recovery Key credential: it is the learner's stable identity, and restoring it is the point of the backup.

What is excluded, and why:

| Excluded from cloud backup | Reason |
| --- | --- |
| `image_banks/` | Android's Auto Backup quota is 25 MB per app. One Image Bank import alone is capped at 50 MB. |
| `exercise_images/` | Same quota. |
| `quisquislingo_course_media/` | Same quota; each Course's own images and recorded MP3s (Build 243; formerly `quisquislingo_audio/`), which grow without a practical bound. A restored device gets the Courses back without these files; importing the Course package again restores them. |
| `quisquislingo_audio/` | Retired by Build 243 and no longer written or read, but still excluded because a device may keep the old folder. |

The reason is the **quota, not privacy**. An app whose data exceeds 25 MB does not get a partial backup — the platform silently stops backing that app up at all. One media import would therefore cost the learner every backup of their progress, without any warning. Bulk media is re-importable from the user's own files; progress is not. This is the same set of folders `AppResetService` treats as bulk media (`_imageFolders`, `_courseMediaFolder`), and it lives under `getApplicationSupportDirectory()`, which is `getFilesDir()` on Android, hence `domain="file"`.

Direct **device-to-device transfer is deliberately not restricted**. It has no 25 MB quota, so a phone-to-phone migration carries the media across as well. `<device-transfer>` is therefore omitted from the rules file rather than left empty.

Two files express this, and they must be changed together:

- `android/app/src/main/res/xml/data_extraction_rules.xml` — API 31 and above
- `android/app/src/main/res/xml/backup_rules.xml` — API 30 and below, because `android:dataExtractionRules` is ignored there

**Public Quick folders (Build 255).** Quick Export and Quick Import use `Download/QuisquisLingo` (its `Export` and `Logs` folders, and its `Import` and `ToBeMerged` folders), outside the app's data, so Auto Backup never includes them and other apps can read them. On Android 10 and later QQL holds no storage permission: it writes through MediaStore and reads only the one folder the person grants, and only if that folder is exactly `Download/QuisquisLingo`. `WRITE_EXTERNAL_STORAGE` is declared for Android 9 and older only (`maxSdkVersion 28`). Files read from these folders pass the same bounded staging and validation as every other import; private data (Crash Log, Course Backups, stored Courses, media, preferences) never moves there.

Whether Auto Backup runs at all is an Android setting owned by the device owner, not by QuisquisLingo. The app neither enables nor disables it, and still uploads nothing itself: Export, `Save to…` and the User Recovery Key remain the only deliberate ways a user moves their own data.

## Local data

Learner profiles, progress, Status, streaks, Review history and local course edits use SharedPreferences. These values are not encrypted and must not be used for passwords, authentication tokens, private documents or other secrets.

Bundled/external official courses are locally read-only in both UI and storage. Only custom courses open a working-copy transaction. A licensed fork receives a new custom identity and retains immutable original authorship/provenance; official updates affect only the publisher source. Old local overrides are ignored without conversion or deletion. Custom authoring changes live storage only at the top-level confirmation boundary. The editor:

- validates the complete serialized course before confirmation
- rejects authoring payloads above 8 MB
- preserves and copies corrupt editor JSON before failing clearly rather than replacing it
- leaves bundled course assets unchanged
- creates and verifies a complete pre-change backup before replacing an existing course
- verifies atomic SharedPreferences writes and restores the prior value on failure
- validates course-specific backup paths and SHA-256 integrity before restore
- refuses custom/official origin collisions and different-publisher replacements
- runs author-facing Course Audit checks

Learner Round screens independently skip exercises that still contain structural audit Errors, so a temporarily incomplete authoring draft is less likely to crash learner mode.

## Process execution

Linux TTS discovers only known executable names (`espeak-ng`, `espeak`, `aplay`) on PATH. It invokes them with `Process.run` argument arrays. User/course text is an argument and is not concatenated into a shell command. The implementation does not use `sh -c`.

## Input boundaries

Profile names are trimmed and limited to 60 characters. Course titles are author-controlled local data. XP increments reject negative values and clamp pathological totals. Course IDs created by the editor are generated internally rather than accepted from arbitrary text fields.

## Failure behavior

- invalid/missing course files produce controlled application errors and diagnostic logging
- invalid active profile names are rejected
- malformed recent-round history entries are ignored
- invalid TTS language/voice selection returns `false` and shows feedback instead of silently changing to an unrelated language
- on Windows, regional voice fallback stays within the requested language family
- a missing preferred voice gender falls back to another voice in the same language


## GitHub update checking

The Update screen uses a fixed HTTPS endpoint for the official public repository: `https://api.github.com/repos/Quisquisnaut/QuisquisLingo/releases/latest`. Automatic checks are enabled by default and can be disabled explicitly in Settings > Update. They are scheduled asynchronously after the startup notice is dismissed, so they never delay `runApp` or the first interactive UI. Manual checks are always user initiated.

The update checker is intentionally metadata-only:

- it sends no learner profile, course content, progress, identifiers, credentials or analytics
- it uses no GitHub token and stores no authentication secret
- it rejects HTTP redirects and non-200/non-404 responses
- it bounds the release response to 256 KiB before JSON parsing
- it validates release URLs before opening them externally
- it treats GitHub release text as plain display text
- it never downloads, installs, extracts or executes a release asset
- platform availability is inferred conservatively from published release asset names; absence of a matching asset is shown as not currently available
- network failure never blocks startup or offline use

This feature changes the earlier "no HTTP client" security assumption. It does not create a remote course/content path and must remain isolated from learner/course storage.

## Remaining limitations

This review is static and cannot prove absence of vulnerabilities. Before public release run at least:

```text
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

and equivalent builds for other supported targets. Review dependency advisories and plugin changelogs regularly. Test local-storage corruption, very long authoring text, rapid profile/language switching, and interrupted writes.

## Flutter analyzer compatibility (0.4.24)

The Course Editor uses `ReorderableListView.onReorderItem` on current Flutter releases. This callback already supplies an insertion index adjusted for the removed item, so editor reorder handlers must not decrement `newIndex` again. Async UI actions check that their `BuildContext` is still mounted after awaited work before showing UI or navigating. These rules prevent stale-context crashes and off-by-one reorder behavior.

## 0.5.0 additional checks

- Windows TTS no longer routes speech through the flutter_tts Windows platform
  channel. System.Speech is launched without a shell and course text is passed
  as a process argument, reducing command-injection exposure.
- Course Editor remains local and hidden until deliberately unlocked. Unlocking
  does not grant network publication rights and does not automatically publish
  user-authored content.
- Learner mode skips structurally invalid exercises reported as audit errors
  instead of indexing malformed answer data.
- Word Blocks enable Check when the selected block count equals the correct
  sentence length, not the full pool length, so the required distractor can be
  left unused.
- Per-language reset removes only active-learner keys for the selected language
  and filters that language from Review history. Other learner languages,
  avatar appearance, global device settings and Course Editor overrides remain.
- Empty course shells are valid authoring states and do not cause null/index
  access in Chapters or Course Editor.
- Chapter/Lesson/Round/Exercise lists use scrollable or reorderable lists and
  flexible/wrapping layouts rather than fixed-height columns where content can
  grow. Lesson decorations are below the Round list and cannot cover controls.
- Flag and animation graphics are drawn locally and do not load remote content.
- Image-credit letter pages are scrollable, including empty-letter states.

Production release checks should still include `flutter analyze`, `flutter
test`, Windows/Linux/mobile smoke tests, dependency-license review, and manual
small-window/large-text overflow testing.


## 0.7.0 hardening

Image Bank ZIP imports are bounded before extraction: compressed ZIP size, manifest size, archive-entry count, imported-image count, per-image size and total decompressed image bytes all have limits. Unsafe archive paths, traversal components, unsafe manifest filenames and duplicate basenames are rejected. Files are written only into an app-owned Image Bank directory.

Learner backup imports retain the 10 MB file limit and now also bound profile-name length and entry count. Preference suffixes with unexpected characters or excessive length are ignored rather than being written. Imported learner data remains namespaced under that learner profile.

Course metadata is audited for unusually large author lists, empty/very long author fields, descriptions above 5,000 characters and invalid `YYYY-MM-DD` last-updated dates. These are authoring warnings rather than security claims.

Small-screen robustness was reviewed for narrow phone layouts. Course Info author rows and paired metadata fields stack vertically when space is limited; Duel question/lives indicators wrap; temporary-sample labels no longer compete horizontally with long Chapter titles; missing-image notices wrap. Release testing should still include 320 logical-pixel width and enlarged system text because static review cannot prove the absence of every RenderFlex overflow.

Platform scope is intentionally explicit. Android, Windows and Linux are the primary build/test targets. iOS/macOS require macOS/Xcode and should receive device/build smoke tests before release. Web is experimental because authoring and local import features currently depend on native file APIs; do not claim production web compatibility until a web build and those feature boundaries are validated.


## 0.7.3 changed-path review

The alpha-expiry mechanism is a transparent lifecycle control, not an authentication or DRM boundary. It trusts the local device clock and must not be described as tamper-resistant. Expiry does not delete learner profiles, progress, course edits, imported courses, Image Banks, Audio Packs or preferences. Learner entry routes and non-preview Round/Duel/Review screens independently refuse learning after expiry; Course Editor and editor preview remain available.

Course author roles are stored as a bounded list of strings while retaining a legacy `role` string in serialized JSON for compatibility. Course Audit warns about empty or excessive role metadata and unusually long role values. Chapter Editor notes are bounded in the UI to 10,000 characters and are never displayed by learner screens.

Source and Target language fields in Course Info are display-only in 0.7.3, preventing accidental changes that could desynchronize TTS, instructions and course content. Responsive author-role controls use wrapping chips and scrollable dialogs rather than fixed horizontal rows.

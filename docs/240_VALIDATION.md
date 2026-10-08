# QQL 240 validation

Validation target: `2.0.40+240000`, **Build 240, Revision 0**.
The Beta expiry is deliberately **unchanged** at `2026-10-19 23:59:59` local time
(owner decision, 2026-09-19/20: "update version, not date"). This is an exception
to the `AGENTS.md` rule that a version change refreshes the expiry; the expiry
code, its tests and the docs that state it were left untouched. Course Model
v9/v10 is unchanged.

Detailed design, decisions and hand-off notes: `docs/240_FILE_DIALOGS_PLAN.md`.
Planned follow-up (not implemented): `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`.

## Scope

- Native Save / Open dialogs (`FileDialogService`), additive to the fixed-folder
  system, with graceful fallback and Diagnostic Log entries.
- 17 dialog entry points (Save: Course JSON x3, my data, Recovery Key, Crash Log
  copy, Diagnostic Log copy. Open: Course import, Merge From, Image Bank ZIP,
  single image in the admin library, exercise image, Recognize-characters portable
  image, custom Lesson icon, one MP3, my data, Recovery Key). Table:
  `docs/240_FILE_DIALOGS_PLAN.md` section 8.2.
- First dialog starts in Downloads (device-wide flag
  `qql_file_dialog_downloads_offered_v1`, listed in
  `docs/239_RESET_STORAGE_INVENTORY.md`).
- Recorded-MP3 copies are deleted on a confirmed Course save and on Course
  deletion when no stored Course uses them (`managed_media_cleanup.dart`).
- Custom Lesson icon delete button; Lesson theme icon sheet redesign
  (icon-only import, "Numbers", collapsed Preinstalled section).
- Wording: Shared Image Library (admin) versus a course's own custom images.
- New dependency: `file_selector ^1.1.0`.

## Results (final tree)

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test --no-pub --concurrency=1` (full suite, run twice: the first run found two version-metadata tests I had not updated, fixed, then re-run) | **1809 tests, all passed** |
| `git diff --check` | No whitespace errors |
| `flutter build windows --debug` (after adding `file_selector`, before later UI work) | Built `quisquislingo_app.exe` |
| New automated tests | `file_dialogs_240_test`, `file_dialogs_240_features_test`, `file_dialog_feedback_240_test`, `managed_audio_cleanup_240_test`, `delete_custom_lesson_icon_test`, `lesson_theme_icon_sheet_240_test` (+ `test/support/`) |

Existing tests changed on purpose: `course_editor_export_226_02_test` (Export must
remain the last existing entry; only the additive `Save Course JSON to…` tile may
follow it), `lesson_metadata_and_icon_test` (expand the collapsed Preinstalled
section first; "None" is now "Numbers"), and the version-metadata tests.

## Not run / not verified

- `tools/validate_courses.py`, `tools/validate_images.py`,
  `tools/validate_media_assets.py`: **not run**, Python is not installed on this
  machine. No course, image or media asset files were changed by this revision.
- **The native dialogs themselves were not clicked through by an automated test.**
  Automated tests use a fake backend. The Windows checklist below is for a person.
- **Android: no backend yet** (`file_picker` is not added); the new buttons are
  hidden there and the fixed-folder actions are the only route. No Android device
  or emulator check has been done.
- **iOS: not supported** (no iOS project). **macOS: unverified** (no Mac).
  **Linux: unverified** (GTK dialog through `file_selector`; not run on a Debian,
  Ubuntu or antiX machine).
- `flutter build windows --release` and the packaged bootstrap were not re-run.
- The recorded-MP3 deletion was verified with temporary directories only, not
  with real learner data.

## Manual Windows checklist (to be run by a person)

For each of Course export, Course import, Merge From, Image Bank ZIP, single
image, lesson icon, MP3, my data, Recovery Key, and both log copies:

1. The native dialog opens; the first ever dialog starts in Downloads.
2. A suggested file name appears (Save).
3. Overwriting an existing file asks first (Save).
4. Cancel does nothing and shows nothing.
5. A wrong or invalid file is rejected with the same message the fixed-folder
   import gives.
6. A folder or file name with accented or non-Latin characters works.
7. Recovery Key: the privacy warning appears before the dialog.
8. Crash Log copy: the original file is unchanged.
9. Lesson theme icon sheet: small when collapsed; "Numbers"; delete refuses an
   icon a Lesson uses; Cancel of the Lesson restores a deleted icon.
10. Remove a clip in the Audio Library, save the Course: the MP3 copy is gone from
    `<AppSupport>/quisquislingo_audio/...`, the original file is untouched, and an
    old version still restores from Version History.

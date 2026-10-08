# Handoff: Build 243 portable Course packages

Updated 2026-09-21 after Revision 4. This replaces the Revision 2 handoff:
Tranches 2 and 3 are complete. The next agent should treat the current
repository as the source of truth and read `AGENTS.md` before changing code.

## Current state

- The last Build 243 implementation commit is
  `54bafb80705fed60f2230f5b304dd0041588e7dc`. It and the four preceding
  Build 243 commits were pushed to `origin/main`, starting after `efdf784`.
- Current version is `2.0.43+243004` in `pubspec.yaml`; the Beta expiry remains
  2026-10-21 23:59:59 local time.
- No Course package implementation work is pending from the approved plan.
  Do not restart Tranches 2 or 3 from this historical handoff.
- `devtools_options.yaml` is a pre-existing untracked local file. It was not
  staged or pushed. Preserve it unless the owner explicitly asks otherwise.

| Revision | Commit | Delivered |
|---|---|---|
| 0 | `35090c7` | Clean Course Model v11; optional merge provenance and descriptive fields; v11 conversion tool; converted bundled/demo/Publisher fixtures; new Course and backup namespaces. |
| 1 | `6bbd69a` | Readable stored Courses remain listed when another file is unreadable, unsupported or a duplicate; safe writes and Manager/Inventory notices. |
| 2 | `764554c` | Content-addressed per-Course images and recordings, media copy for Copy/Fork/Merge, backup/Restore, cleanup, reset and Inventory integration. |
| 3 | `60c27ba` | Dependency-only Course ZIP export/import/merge; shared-image provenance and attribution; QQL/DEVICE/COURSE/USED labels. |
| 4 | `54bafb8` | Signed Publisher ZIPs with media; verified install/update and media cleanup; Course Editor Image Library includes Course-stored images and adds USED to exercise images. |

Full behavior and rationale are in `docs/243_CHANGE_SUMMARY.md`; exact test
evidence is in `docs/243_VALIDATION.md`; the approved decisions are in
`docs/COURSE_PACKAGE_PLAN.md`.

## Decisions that must remain intact

- Export a Course as a ZIP with `qql-course-package.json`, `course.json` and
  only the `media/<sha256>.<ext>` dependencies it uses. Import also accepts a
  media-free v11 JSON. Bundled `assets/` media remain supplied by QQL; there is
  no "include bundled images" export option in this release.
- An Admin-added shared image selected for a Course is copied into that
  Course's media folder. The Course and ZIP manifest retain the original
  library ID, SHA-256, label, category, tags, origin and available per-image
  attribution. Import keeps it with the Course and does **not** add it to the
  destination device's Shared Image Library. Other local shared images do not
  enter the ZIP. Filename or label alone never establishes image identity.
- The **Shared Image Library** management entry is Admin-only in Course Manager
  and Device Administration. People choosing an image in the Course Editor can
  browse shared images. Admins edit per-image attribution in **Edit metadata**;
  Image Banks may supply attribution per entry.
- The Course Editor's **Image Library** includes the shared catalogue and
  images stored in that Course. `QQL` means app-bundled, `DEVICE` means
  Admin-added on the source device, `COURSE` means bytes in the Course folder,
  and `USED` means the Course references the image. An exercise image gets
  `USED` whether it appears in the prompt or an answer option. Thus a shared
  entry can show `QQL · USED` or `DEVICE · USED`, while its copied Course entry
  can show `DEVICE · COURSE · USED`. The separate Shared Image Library keeps
  only `QQL` or `DEVICE` even when a Course uses the image.
- Course Model v11 rejects device paths for Course media. Older v9/v10 Course
  files remain physically untouched and unsupported by the app; the external
  conversion tool is explicit. Keep bundled Course IDs and signed Publisher
  provenance stable.
- Signed Publisher Courses may distribute referenced recordings and images
  in their ZIP. Verify the signature and each media digest before installation.
  An update backs up the previous official Course with its media, then removes
  media the update no longer uses. Uninstall retains media.

## Implementation map

- `lib/services/course_media_store.dart` alone owns per-Course media. A
  reference is `media:<lowercase sha256>.<ext>` (`mp3`, `png`, `jpg`, `jpeg`,
  `webp`), stored under
  `<AppSupport>/quisquislingo_course_media/course_<sha256(courseId)>/`.
  Courses do not share these files. Use `CourseMediaImage` to render one and
  `RecordedAudioService.resolveSourceForClip(clip, courseId:)` for recordings.
- `lib/services/course_package_service.dart` builds, parses and validates ZIP
  packages, including safe names, sizes, media hashes, cover constraints and
  shared-image provenance. Stage media only after the import decision, with
  rollback on failure.
- `lib/services/custom_course_transfer_service.dart` reuses the Course
  validator and export/import routes. `lib/screens/course_projects_screen.dart`
  owns the existing import choice and Publisher install/update dialogs.
- `lib/services/course_editor_service.dart` enforces Publisher verification
  again at installation, even for direct service calls, and handles update
  backup and media cleanup.
- `lib/screens/flat_image_library_screen.dart` presents the shared catalogue
  plus Course-owned images when given a Course. The Course Editor passes its
  working Course and media store into that screen.
- `tools/sign_course.dart package SIGNED.json MEDIA_DIR PUBLIC.der OUTPUT.zip`
  creates a signed Publisher package from the files actually referenced by
  the signed JSON. Keep this developer tool pure Dart: importing a service
  that depends on Flutter `dart:ui` breaks `dart run`.
- Checked-in examples: `demo_courses/italian_demo_2_pick_the_translation.zip`
  and `test/fixtures/publishers/dummy-signed-media.zip` with its signed JSON.
  The Dummy key is test material only.

## Verification at the pushed commit

- Full `flutter test --no-pub --reporter expanded`: **1,960 passed, 0 failed**.
- Final Revision 4 focused set: **101 passed, 0 failed**. After a formatting
  adjustment, the three Image Library suites were rerun: **7 passed**.
- `flutter analyze --no-pub`: no issues.
- `python tools/validate_images.py`: 111 assets, 0 issues;
  `validate_lesson_icons.py`: 14 assets, 0 issues;
  `validate_media_assets.py`: 443 files, 0 issues;
  `validate_courses.py`: all 10 bundled v11 Courses OK.
- `git diff --check` was clean. At the Revision 4 push, `HEAD` and
  `origin/main` both resolved to `54bafb80705fed60f2230f5b304dd0041588e7dc`.

## For the next task

There is no owner-requested next tranche. Ask about new behavior only when a
new request leaves a consequential ambiguity; do not infer an implementation
from roadmap text. Possible future choices discussed, but **not approved as
work**, are optional inclusion of bundled images in a ZIP and an explicit
Admin action to promote an imported Course image to the Shared Image Library.
No manual device check is recorded in `docs/243_VALIDATION.md`.

Keep the signing guide (`docs/PUBLISHER_SIGNING_GUIDE.md`) and in-app
Publisher Help (`lib/screens/publisher_signing_help_content.dart`) word-for-word
aligned; `test/publisher_signing_help_test.dart` checks this. Prefer focused
tests while editing, then verify the final requested scope. Avoid formatting
whole legacy Dart files: unrelated lines are not uniformly formatter-clean.

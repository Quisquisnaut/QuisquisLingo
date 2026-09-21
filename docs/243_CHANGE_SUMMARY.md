# Build 243 — change summary

Revision 0 (`2.0.43+243000`) introduces Course Model v11; Revision 1
(`2.0.43+243001`) stops one unreadable stored Course from hiding the others.

## Revision 0 — Course Model v11

Version: **2.0.43+243000**. Beta expiry: **2026-10-21 23:59:59 local**, the
30-day policy applied to this release's own date, 21 September 2026.

This is Tranche 0 of the portable course package described in
[docs/COURSE_PACKAGE_PLAN.md](COURSE_PACKAGE_PLAN.md): it introduces the Course
Model that the package will carry. Media handling, the ZIP package and the
Publisher changes are Tranches 1–3 (Revisions 2–4); Revision 1 makes an
unreadable stored Course stop hiding the readable ones.

## Course Model v11, a clean cut

`Course.currentFormatVersion` is 11 and is the only accepted value.
`formatVersion` 9 and 10 are refused with
`Unsupported course formatVersion … supports Course Model format 11 only …
convert them with tools/convert_course_to_v11.dart`. The application contains no
conversion code.

v11 = v9, plus:

- `mergeProvenance` as an optional field of any custom Course. v10 existed only
  to carry it; `Course.mergedFormatVersion` is removed and a merge now produces
  an ordinary v11 Course. It remains custom-only.
- The Build 242 `mediaAttributions` list, unchanged.
- Six optional descriptive fields (below).

Owner decision: a single model rather than more format numbers, and a clean cut
because there are no existing Courses to preserve. The version number now tells
an older build the truth: it refuses a v11 Course instead of re-saving it and
silently dropping fields it does not know, the compatibility gap Build 242
documented for media credits.

## New optional fields

All omitted from JSON when unset, all descriptive, none granting permissions.
One validator, `Course.validateDescriptiveMetadata`, serves the constructor and
the Course Info Editor.

| Field | Rule |
|---|---|
| `minimumAppBuild` | Positive integer; a value above `AppMetadata.buildNumber` is refused with "Update QuisquisLingo". |
| `publisherContact` | `websiteUrl` (HTTPS, ≤ 500) and/or `email` (≤ 254), at least one. Plain text only. |
| `estimatedStudyHours` | Integer 1–1000. |
| `minimumAge` | 4, 9, 13, 16 or 18 — the App Store age classes (owner's choice over audience bands). |
| `keywords` | ≤ 20 trimmed, non-empty, ≤ 32 characters, no case-insensitive duplicates. No search yet. |
| `coverImage` | `media:<lowercase sha256>.<png\|jpg\|jpeg\|webp>`. Stored and validated only. |

`minimumAppBuild` is the mechanism for later additions: a Course that needs a
newer feature can say so without another format number.

Course Info Editor adds the five editable fields after Buy a Coffee URL, with
inline guidance, and refuses invalid values with a message while keeping the
dialog open. Cleared fields are removed, never stored as `null`. Course Info
shows them under Course details and a separate Publisher contact card.

Fork, Copy as New Course and in-Course transfers carry the fields. A merge keeps
the left Course's values except `minimumAppBuild`, which takes the higher
value, and the fields are excluded from the merge compatibility check so they
never block a merge.

A defect this exposed: `CourseAuthoringTransferService._withLessons` rebuilt the
Course without `mergeProvenance`. Under v10 that failed loudly; under v11 it
would have dropped the provenance silently. It now keeps it.

## Storage clean cut

Found during implementation: `CourseEditorService.listUserCourses` throws when
any stored Course cannot be parsed, so a single leftover v9 Course would have
blocked Course Manager, the Course Selector and import — including importing
its converted replacement. Version History behaves the same way for backups.

Owner decision: new folders, following the established clean-cut pattern.

- `CourseFileStore.rootDirectoryName`: `qql_courses_v1` → `qql_courses_v2`.
- Course backups: `Exports/Course Backups v9` → `Exports/Course Backups v11`,
  manifest format `QuisquisLingo Course Backup v11`.

The old folders stay on disk, untouched, unread and outside resets; the
Inventory still labels files in any `Course Backups v<n>` folder as backups.
Storage preference keys that contain `v9` keep their names.

## Conversion tool and converted content

`tools/convert_course_to_v11.dart INPUT OUTPUT [--overwrite]
[--official-version V]` changes only `formatVersion`, recomputes
`officialChecksum` for official Courses, removes a Publisher signature (the
result must be signed again) and preserves key order and layout. It refuses a
Course that names media outside `assets/`, listing each location.

- The ten bundled Courses: three lines each change — format, official version
  one minor step up (1.6.1 → 1.7.0; Korean 1.0.1 → 1.1.0; Neapolitan
  1.0.0 → 1.1.0) and checksum. Course IDs are unchanged, so learner progress
  is kept. `tools/validate_courses.py` now requires format 11.
- `demo_courses/italian_demo_2_pick_the_translation.json`: only the format
  number changes. Its ZIP version comes with the package in Tranche 2.
- Dummy publisher fixtures: `dummy-unsigned.json` converted; `dummy-signed-v1`
  and `-v2` converted and signed again through the documented route
  (`sign_course.dart prepare` → `openssl pkeyutl -sign -rawin` →
  `sign_course.dart attach`, which verifies before writing).
  `dummy-payload.bin` and `dummy-signature.bin` are the new v1 payload and
  signature. Publisher signatures necessarily change: the format number is
  part of the signed checksum.

## Not in this revision

Course media references (`media:` for images and MP3s), the ZIP package,
Publisher media, cover display and keyword search. See the plan.

## Revision 1 — an unreadable stored Course no longer hides the others

Version **2.0.43+243001**, same Beta expiry (same release date).

Found while planning Revision 0 and made its own revision by the owner.
`CourseFileStore.readAll` and `CourseEditorService.listUserCourses` stopped at
the first file they could not load, so one damaged, unsupported or duplicated
Course file blocked Course Manager, the Course Selector, import and every save.
The store's own comment and the test `one unreadable Course does not hide the
others` claimed the opposite; the test in fact asserted the failure.

- `CourseFileStore.readReadable` returns the readable records and a list of
  `SkippedCourseFile` (file name and reason). When two files claim one Course
  ID, both are skipped.
- `readAll` stays strict and keeps its messages. It is now used only where an
  unreadable Course must not be mistaken for a missing one: the unused-MP3
  cleanup (which then deletes nothing) and the profile-deletion guard (which
  then refuses, naming the file).
- `CourseEditorService` lists and saves through `readReadable`. Files that are
  readable JSON but not a valid Course are skipped as well.
  `unreadableCourseFiles` exposes the result of the last listing.
- `CourseFileStore.write` refuses to replace a file that cannot be read or that
  holds another Course ID, so a skipped file is never lost by saving or
  importing; the message names the file to move.
- Course Manager shows a notice card listing each skipped file and its reason
  above the Course lists, instead of the whole-page load error. The Inventory
  names the skipped files in its course section.
- Three tests that asserted the old failure now assert the notice, keeping
  their intent (the file is preserved, the problem is reported): the Build 230
  Course Manager test, the Build 225 unsupported-course and corrupt-file tests;
  the file-store test was renamed to what it actually checks.

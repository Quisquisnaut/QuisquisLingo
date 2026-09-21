# Build 243 — change summary

Revision 0 (`2.0.43+243000`) introduces Course Model v11; Revision 1
(`2.0.43+243001`) stops one unreadable stored Course from hiding the others;
Revision 2 (`2.0.43+243002`) gives every Course its own content-addressed
media.

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

## Revision 2 — course media

Version **2.0.43+243002**, same Beta expiry. Tranche 1 of the plan.

### The reference

`CourseMediaStore` (`lib/services/course_media_store.dart`) is the single
authority. A Course's own image or recording is `media:<sha256>.<ext>`
(`mp3`, `png`, `jpg`, `jpeg`, `webp`), the lowercase SHA-256 of its bytes. The
file lives in `<AppSupport>/quisquislingo_course_media/course_<sha256(courseId)>/<sha256>.<ext>`.
The same Course JSON is therefore valid on every device, and a signature over
it pins the media bytes too.

`Course.fromJson` refuses any Audio Library `filePath` that is not empty,
`assets/…` or `media:<sha256>.mp3`, and any `image` element `asset` that is not
empty, `assets/…`, `data:image/…` or an image `media:` reference. Portable
`data:` images (Recognize characters) and Lesson icons are unchanged.

### Where media is created, shown and removed

- `RecordedAudioService` imports (fixed folder and Open from…) store through
  the media store; clip IDs gain a random suffix because identical recordings
  now share a file. Playback, availability and preview resolve with the
  Course ID (`resolveSourceForClip(clip, courseId:)`,
  `playConcatenated(…, courseId:)`); the synchronous `sourceForClip` is gone.
- The Exercise editor copies an imported image or a library/bank choice into
  course media. `CourseMediaImage` shows any Course image (bundled, embedded or
  course media) in study, Duel and the editor; it reads bytes rather than
  using `Image.file`, which memory-maps the file and on Windows keeps it from
  being deleted.
- `CourseEditorService`: Copy as New Course and Fork copy the referenced media
  into the new Course folder before creation and remove it if creation fails;
  a confirmed save deletes files the saved Course does not reference
  (including files added and then dropped while editing); deleting a Course
  deletes its folder. `CourseMergeService.copyMedia` copies from the left and
  then the right source, called by Course Manager just before saving a merge.
- `CourseBackupService` copies every referenced file as `<sha256>.<ext>`,
  verifies it, and records `reference` + `sha256` (or a gap:
  `reference` + `missing`). Loading requires the checksum to equal the
  reference's digest. `reinstateMedia` puts files back; Version History calls
  it before Restore. No path remapping remains. Images are now backed up too.

### Retired

`ManagedAudioCleanup` and `MediaReferenceIndex` are removed. Their job was to
avoid deleting an MP3 another Course shared; with one folder per Course nothing
is shared. The Revision 1 note that the MP3 cleanup stays strict about
unreadable stored Courses no longer applies: cleanup reads only the Course
being saved. The Shared Image Library delete dialog, which listed Courses
"still using" an image (Build 242), now states that Courses keep their own
copy.

### Storage, reset and backup

- Reset → imported media: images removes the library, banks and course-media
  images; audio removes course-media MP3s; both removes the whole
  course-media folder. Custom-course and full resets remove it too.
- Inventory: section "Course media", owner by Course, note by type.
- Android Auto Backup excludes `quisquislingo_course_media/` and still
  excludes the retired `quisquislingo_audio/`, which is no longer read.
- `docs/239_RESET_STORAGE_INVENTORY.md`, `docs/SECURITY_AND_ROBUSTNESS.md`,
  `docs/AUDIO_LIBRARY.md`, `docs/COURSE_EDITOR.md` and Editor Help (English and
  Italian) describe the new storage.

### Also fixed

Revision 0 had left the in-app Publisher Help and `docs/PUBLISHER_SIGNING_GUIDE.md`
with different wording for the Course Model line; the test that keeps them
identical was not in Revision 0's focused set. They are identical again.

## Revision 3 — portable Course ZIP

Version **2.0.43+243003**, same Beta expiry. Tranche 2 of the plan.

- Fixed-folder Export and Save to… produce a Course ZIP containing
  `qql-course-package.json`, the canonical `course.json`, and only the
  Course-owned `media:` files the Course actually references. Bundled QQL
  assets and unreferenced Shared Image Library images are not copied.
- Fixed-folder Import, Open from… and Merge From… accept the Course ZIP or a
  media-free v11 JSON. Import checks ZIP names, links, compressed and expanded
  size, media digests, the Course, and the optional 512 × 512 cover before
  writing. Collision choices and Merge carry the media; a failed save removes
  newly copied files.
- Choosing an Admin-added Shared Image Library image records a snapshot of its
  library ID, label, category, tags and origin on the Course image. The ZIP
  manifest lists that provenance with the media SHA-256. Import keeps the
  image in the Course folder and does not add it to the destination Shared
  Image Library. The library screen gives app-bundled entries the fixed `QQL`
  label and Admin-added entries the fixed `DEVICE` label for every viewer.
  Using an image in a Course does not change its Shared Image Library label.
  In the Course Editor, a used bundled image shows `QQL` and `USED`;
  a used Admin-added library image shows `DEVICE`, `COURSE` and `USED`;
  and a directly imported image shows `COURSE` and `USED`. `COURSE` means
  the bytes are in the Course folder; `USED` means the Course references
  the image, regardless of storage.
  Admins may enter optional per-image attribution (author, license, work title
  and source) in the Shared Image Library's Edit metadata dialog; Image Banks
  may supply the same optional attribution per entry. The Course and ZIP
  manifest retain the attribution snapshot when the image is selected.
  Existing Course-level media credits remain in `course.json`.
- The demo Course now has a `.zip` beside its media-free `.json`. Publisher
  recordings remain subject to the Revision 2 import restriction until
  Revision 4 adds signed publisher packages with media.
## Revision 4 — signed Publisher Course media

Version **2.0.43+243004**, same Beta expiry. Tranche 3 of the plan.

- Publisher Courses can distribute recordings and ordinary images as verified
  `media:` files inside a signed Course ZIP. The signed JSON pins each file by
  SHA-256; package import checks its actual bytes before changing storage.
- `CourseEditorService.installExternalOfficialUpdate` installs package media
  into the Course folder and refuses missing or damaged media when called
  without a package. A newer signed update backs up the previous Course and
  media, then removes files no longer referenced. Uninstall keeps media.
- `tools/sign_course.dart package` takes signed JSON, a media directory and
  the Publisher public key; it verifies the signature and referenced files,
  then writes a ZIP containing only those dependencies. The signed Dummy
  media ZIP exercises import and update. Publisher Help, the signing guide
  and the historical audio-pack notes reflect the portable package.
- Course Editor calls its browser **Image Library** and shows the Course's
  stored images beside the shared catalogue. In that browser, images used by
  an exercise add `USED` to their source label: `QQL · USED` for bundled assets,
  `DEVICE · USED` for an Admin-added image, and `DEVICE · COURSE · USED` for
  its Course-stored copy. Direct Course images show `COURSE` and add `USED`
  when referenced. The separate **Shared Image Library** management entry
  remains Admin-only in Course Manager and Device Administration; its entries
  show `QQL` or `DEVICE` without Course-use badges.

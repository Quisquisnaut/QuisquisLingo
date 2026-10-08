# Build 248 change summary

`2.0.48+248000` — Build 248, Revision 0, Course Model v11.
Plan: [248_AUDIO_LIBRARY_PLAN.md](248_AUDIO_LIBRARY_PLAN.md).
Evidence: [248_VALIDATION.md](248_VALIDATION.md).

## What changed

One owner now holds the lifetime of the media a Course editing session creates.

`RecordedAudioService` copies an imported MP3 into the Course's own media
folder the moment it is imported — long before the single top-level Course
confirmation. Between those two moments nothing knew whether the file would
end up being used, and nothing removed it if it was not:

* **Cancel course changes** reverted the working copy in memory only.
* **Backing out of the Audio Library** without Save dropped the clips but kept
  the files, and left the Editor so unchanged that it closed without asking.
* **A batch that failed part way through** (`importMp3Files` stores files one
  at a time after validating all of them) lost the whole returned clip list
  while the already-stored files stayed.

For a Course that exists on disk the leftovers survived until its next
successful save. For a **new Course that was never confirmed** they survived
permanently, because `CourseMediaStore.deleteUnreferenced` only ever runs for
a Course that was actually stored.

`CourseAuthoringMedia` records what the Course's media folder held when the
editing session opened. That snapshot is what separates a file the session
created from one that was already there. When the session ends **without** a
confirmed Course, it removes exactly the `.mp3` files that appeared during the
session and the persisted custom Course does not use.

It removes nothing when the opening listing or the persisted Course cannot be
read: a failed read cannot prove that saving failed, so the media stay for
recovery. This is the Build 245/246/247 rule, unchanged. No stored Course
under that ID means nothing persisted uses the files, which is the
never-confirmed new Course.

## Files

| File | Change |
| --- | --- |
| `lib/services/course_authoring_media.dart` | New. The owner: opening snapshot, the single sweep, the recovery rule, and the `.mp3`-only scope. |
| `lib/services/course_authoring_session.dart` | Creates the owner with the session and exposes `discardUnconfirmedMedia()`. |
| `lib/services/course_editor_service.dart` | New `persistedCustomCourseReferences(courseId)`: the references the stored custom Course uses, `null` when none is stored, throws when a record cannot be read. |
| `lib/services/course_media_store.dart` | New `storedReferences(courseId)`: lists a Course's own media files without deleting any. An unreadable folder throws rather than looking empty. |
| `lib/screens/course_editor_screen.dart` | `_popEditor` ends the media lifetime when it pops with no confirmation result. `PopScope.canPop` is `_routeMayPop` only, so an unchanged exit reaches that one place too. |

## Deliberate behaviour changes

* A session that ends without confirming a Course removes the recordings it
  imported. The author's own files are never touched: fixed-folder sources
  stay in `Documents/QuisquisLingo/Imports/Audio` and Open from… never moves
  the picked file, so any recording can be imported again.
* Restoring a historical version inside the Editor copies that version's media
  back into the Course folder (`CourseBackupService.reinstateMedia`). Those
  recordings are now the session's: confirming keeps the ones the Course uses,
  and cancelling removes them. Nothing is lost, because the backup keeps its
  own copies and a later restore re-copies them.
* Closing an **unchanged** Course Editor now completes after a folder check
  rather than within the same frames. Three tests in
  `production_course_transaction_225_04_test.dart` and one in
  `course_ownership_team_229_r1_test.dart` waited with `pumpAndSettle`, which
  does not advance real file IO; they now use the repository's existing
  `pumpUntilFileIoState`, the same way the confirmation path already did. The
  common case costs one directory listing: the stored Course is read only when
  the folder actually gained a recording.

## Unchanged

MP3 validation and storage stay in `RecordedAudioService`, including the order
that checks every file in a folder import before storing any. The widget keeps
the preview player, controls, dialogs, sorting, the letter jump list and the
missing-file notice. `RecordedAudioService.orphaned` remains a
clips-without-a-word check, not a disk-cleanup contract, and the Course Editor
dialog that uses it still says the files remain on disk. A confirmed Course
still tidies up through `CourseMediaStore.deleteUnreferenced` inside
`confirmCourseTransaction`. No second Course copy and no second persistence
path. Course Model v11, stored formats and keys, package format 1 and
signatures, authoring rights, scoring, progression and the single top-level
confirmed Course save are unchanged. No new persisted preference key and no
new user-file folder, so `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md` are unaffected.

## Known limits

* **Pictures added while editing leak in the same way** and are deliberately
  out of scope. The Course Editor's Image Library and the Exercise image field
  also write into the Course folder before confirmation. Owner decision on
  2026-09-22: recordings in this build, pictures in a later one.
  `CourseAuthoringMedia.ownedExtensions` is the single place that widens.
* A session ended by process death rather than through the Editor still leaves
  its files; the next successful save of that Course removes them.
* An emptied Course media folder may remain as an empty directory until the
  next confirmed save removes it.
* The in-isolate per-Course lock does not coordinate external writers; this
  remains the documented Build 245 storage limit.

---

# Build 248 Revision 1 — Course Editor layout and media notices

`2.0.48+248001`. Plan: [248_EDITOR_LAYOUT_PLAN.md](248_EDITOR_LAYOUT_PLAN.md).

**Recorded deliberately:** this revision is a scope extension the owner asked
for, not a correction proven by Build 248's tests, and it was added to the open
Build 248 pull request at the owner's choice. The recommendation was a separate
build after Build 248 merged, so Revision 0's manual smoke test stayed valid.
Because item 4 changes the Audio Library screen that smoke test exercised, that
smoke test must be repeated.

| # | Change |
| --- | --- |
| 1 | Lesson numbering, Use GuideBook and Create Duels move from the **Lessons** screen to a collapsed **Lesson Options** section (`course-lesson-options`) under the Course Editor's Lessons tile. All three are Course properties, so this puts them on the Course screen. `askAuthoringName` becomes the one shared title prompt instead of two copies. |
| 2 | The Lesson editor drops `lesson-title-control` and `lesson-audit-action`. |
| 3 | The Round editor drops `round-rename-action` and `round-audit-action`. |
| 4 | The Audio Library has no Save button; leaving the screen returns its draft, and `audio-library-save-notice` explains what that means. |
| 5 | A Course's Image Library gains `course-image-save-notice`. Its save-on-exit and discard-on-cancel behaviour already worked through `onCourseChanged: _updateDraft`, so **only the notice is new**. |
| 6 | `CourseAuthoringMedia.ownedExtensions` widens from MP3s to every kind of Course media, so images added during a cancelled session are removed too — the known limit Revision 0 recorded. |

## Nothing is lost by items 2 and 3

Rename and Audit remain in the Lessons and Rounds pages' 3-dot menus. The
surviving rename dialog was checked rather than assumed: `_name(...,
allowEmpty: true)` carries the same `Title, or Enter to skip` label **and** the
same `onFieldSubmitted` rule that keeps the existing title when Enter is
pressed on an empty field, which was the one behaviour the removed Round-editor
dialog had.

One visible consequence: the Lesson editor no longer shows the plain Lesson
title, because `lesson-title-control` was the only widget that displayed it.
The numbered title remains in the AppBar and breadcrumbs.

## Test work

Twenty existing assertions across nine suites reached the moved or removed
controls; that they failed is the evidence the changes landed. They now reach
Lesson Options on the Course screen, or rename through the list pages' menus.
`lesson_controls_226_04` and `optional_learning_paths_226_04` needed
restructuring because a toggle and the Lesson rows are no longer on one screen;
the live-recompute intent is preserved against the Course screen's own Lessons
status card. New tests cover Lesson Options being collapsed by default and
absent from the Lessons screen, the Audio Library having no Save button and
applying on exit, and both notices.

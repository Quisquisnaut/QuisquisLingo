# Build 248 — Audio Library media lifetime plan

Status: approved by the owner on 2026-09-22 in the Build 248 Audio Library
session, under the approved
[architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md) row 2. The owner
asked for one local commit per revision, no separate contract checkpoint, and
a new revision only for a substantial fix proven by its own failing test.
Baseline: `main` `f4de191`, `2.0.47+247001` (Build 247, Revision 1),
Course Model v11.

## What happens today

`AudioLibraryScreen` (`lib/screens/course_editor_screen.dart`) keeps a local
Course draft and returns it to `_CourseEditorScreenState._openAudioLibrary`,
which stages it into the Build 245 `CourseAuthoringSession`. Only the single
top-level Course confirmation persists anything.

The MP3 files do not wait for that confirmation. `RecordedAudioService`
writes each imported recording into the Course's own media folder through
`CourseMediaStore.addBytes` **at import time**, and hands back clips that only
then reach the draft. Three routes do this: `importMp3Files` (fixed folder),
`importMp3FromDialog` and `importMp3sFromDialog` (Open from…).

Nothing owns those files afterwards.

| Route out of the editor | Today |
| --- | --- |
| Audio Library "Save", then Confirm course changes | `confirmCourseTransaction` runs `CourseMediaStore.deleteUnreferenced`, so the confirmed Course keeps exactly what it uses. Correct. |
| Audio Library "Save", then **Cancel course changes** | `CourseAuthoringSession.cancel()` reverts the in-memory working copy only. Every imported file stays on disk, referenced by nothing. |
| Audio Library **back** instead of "Save" | The draft never receives the clips, so the editor is not even dirty and leaves without a prompt. Every imported file stays on disk. |
| **Partial batch write** in `importMp3Files` | Files are stored one at a time after all have passed validation. A failure on file 3 of 5 propagates out of the method, so the whole returned clip list is lost while files 1 and 2 are already on disk. |
| Confirm fails | The editor stays open on the working copy. Files stay, which is the correct recovery state — until the author then cancels. |

For a Course that already exists on disk the leftovers survive until the next
successful save of that Course. For a **new Course that is never confirmed**
they survive permanently, because `deleteUnreferenced` is only ever called for
a Course that was actually stored.

`RecordedAudioService.orphaned` is not a cleanup contract: it lists clips with
no associated word, and the Course Editor dialog that uses it says so —
"The files remain on disk."

## Owner decisions taken for this build

Asked and answered on 2026-09-22, in plain terms:

1. **When to delete.** The owner sweeps **once, when the editing session ends
   without confirming a Course**. Backing out of the Audio Library alone
   deletes nothing; those files simply stay unreferenced until the one sweep.
   One decision point, and nothing is removed while the author is still working.
2. **Scope.** Recordings only in Build 248, as the roadmap row says. Pictures
   added during a session leak in exactly the same way (the Course Editor's
   Image Library and the Exercise image field also write into the Course folder
   before confirmation). That is recorded as an observed finding for a later
   build, not changed here.
3. **Safety.** Deleting QQL's own copies is acceptable. The author's files are
   never touched: fixed-folder sources stay in
   `Documents/QuisquisLingo/Imports/Audio` (the screen says so) and Open from…
   never moves the picked file, so any recording can be imported again.

## Owner and contract

A new `CourseAuthoringMedia` (`lib/services/course_authoring_media.dart`) owns
the lifetime of media created while one Course is being edited. It is held by
`CourseAuthoringSession`, the existing top-level authoring owner, and created
with it.

* On construction it starts recording **which media files the Course's folder
  already held**. That snapshot is what separates "this session made this
  file" from "this file was already here".
* `discardUnconfirmedRecordings()` removes the Course's own `.mp3` files that
  are present now, were **not** present at session start, and the **persisted**
  Course does not use. It runs at most once and returns how many files it
  removed.
* It removes nothing when the starting snapshot or the persisted Course cannot
  be read. A failed read cannot prove that saving failed, so the media stay for
  recovery — the Build 245/246/247 rule, unchanged.
* No stored Course under that ID means nothing persisted uses the files, so
  everything the session created goes. That is the never-confirmed new Course.
* The `.mp3` filter is the single line that scope decision 2 narrows; images
  are deliberately left alone.

`CourseEditorService` gains one narrow read for this:
`persistedCustomCourseReferences(courseId)` returns the `media:` references the
stored custom Course uses, `null` when none is stored, and throws when a record
exists but cannot be read. This mirrors the `persistedCustomCourseReferencesAny`
helper Build 247 removed, and this time it has a caller.

`CourseMediaStore` gains `storedReferences(courseId)`, a listing of the Course's
own media files. `deleteUnreferenced` already walks that folder privately; the
owner needs the same listing without the deletion, and deletes one file at a
time through the existing `deleteStored`.

The screen calls the owner at one place: `_popEditor` already runs on every way
out of the Course Editor and receives the confirmation result. A pop with no
result means the session ended without confirming, and that is when the sweep
runs. Both leave paths — "Cancel course changes" and the not-dirty exit that a
back-out from the Audio Library produces — go through it.

**Unchanged:** `RecordedAudioService` keeps MP3 validation and storage,
including the staging order that checks every file before storing any. The
widget keeps the player, preview controls, dialogs, sorting, the letter jump
list and the missing-file notice. No second Course copy and no second
persistence path is created. `deleteUnreferenced` after a confirmed save keeps
working exactly as it does now.

## Proof

1. **Characterization first**, at the real boundary, against unchanged code:
   real temporary support and Documents folders (the suite's
   `flutter_test_config.dart` already gives every test its own), the real
   Course store, the real `CourseMediaStore`, real synthetic MP3s, and the real
   Course Editor and Audio Library screens. Injected failure for the partial
   batch is a real one: a directory placed where the third recording's file
   must be written, so its rename fails while the first two are already stored.
   Record which assertions fail before any source change.
2. **Implement one owner** and wire the single call site. Keep every public
   route and facade compatible.
3. Focused tests, `flutter analyze --no-pub`, the four asset validators, one
   complete suite at `--concurrency=1`, version and release records, handoff,
   `git diff --check`, and one local commit.

### Expected characterization results

| Test | Before |
| --- | --- |
| Cancel after importing recordings leaves no unreferenced MP3 | **fails** — files remain |
| Leaving the Audio Library without Save leaves no unreferenced MP3 | **fails** — files remain |
| A partial batch write leaves no unreferenced MP3 after the session ends | **fails** — the stored files remain with no clip |
| An unreadable stored Course retains the recordings | passes — a guard for the recovery rule |
| Files already in the folder before the session are kept | passes — a guard for the snapshot boundary |
| A confirmed Course keeps every imported recording | passes — a guard for `deleteUnreferenced` |
| Re-importing a recording the stored Course already uses keeps its file | passes — a guard for deduplicated writes |

## Revisions

* **Revision 0**: the owner, the starting snapshot, the single sweep point and
  the recovery rule. A confirmed Course ends with exactly the same stored
  record and the same media folder as today.
* **Revision 1, only if a test proves a substantial fix necessary**: kept
  separate from this extraction, as the working rules require.

## Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, the Audit, and the single top-level
confirmed Course save all remain unchanged. No format or compatibility change
is proposed; the owner will be asked before any is.

## Known limits recorded by this build

* Pictures added during an editing session leak in the same way and are out of
  scope here (owner decision 2 above).
* A session that ends by process death, rather than through the editor, still
  leaves its files; the next successful save of that Course removes them.
* An emptied Course media folder may remain as an empty directory until the
  next confirmed save, which is when `deleteUnreferenced` removes it.
* The in-isolate per-Course lock does not coordinate external writers; this
  remains the documented Build 245 storage limit.

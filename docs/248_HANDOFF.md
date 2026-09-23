# Build 248 handoff

## Revision 0 current state

Build 248 Revision 0 is `2.0.48+248000`, Course Model v11, on branch
`claude/248-audio-library` from `main` `f4de191` (`2.0.47+247001`). The Beta
expiry recalculated from this release's own date (22 September 2026) is
`2026-10-22 23:59:59` local time — the same day as Build 247, so it does not
move. The untracked `devtools_options.yaml` is the owner's and stays untouched.

`CourseAuthoringMedia` (`lib/services/course_authoring_media.dart`), created
with `CourseAuthoringSession`, owns the lifetime of the media a Course editing
session creates. It records what the Course's media folder held when the
session opened, and when the session ends **without** a confirmed Course it
removes exactly the `.mp3` files that appeared during the session and the
persisted custom Course does not use. It removes nothing when the opening
listing or the stored Course cannot be read, so media stay for recovery.
`CourseEditorService.persistedCustomCourseReferences` is its one read;
`CourseMediaStore.storedReferences` lists a Course's files without deleting
any. Every Course Editor exit now reaches `_popEditor`, because an unchanged
working copy can still have imported recordings to disk.

MP3 validation and storage stay in `RecordedAudioService`; the preview player,
controls and dialogs stay in the widget; a confirmed Course still tidies up
through `CourseMediaStore.deleteUnreferenced` inside `confirmCourseTransaction`.

## Owner decisions taken on 2026-09-22

Asked before implementation and answered by the owner:

1. The sweep runs **once**, when the editing session ends without confirming.
   Backing out of the Audio Library alone deletes nothing.
2. **Recordings only** in this build. Pictures leak the same way and are
   recorded as a known limit for a later build.
3. Deleting QQL's own copies is acceptable, because the author's own files are
   never touched and any recording can be imported again.

## What the characterization proved first

`test/audio_library_media_248_test.dart` was written and run against unchanged
code. Three assertions failed and two passed, exactly as the plan predicted:

| Test | Before |
| --- | --- |
| Cancel after importing recordings leaves none behind | **failed** — 2 files remained |
| Leaving the Audio Library without Save | **failed** — 3 files where 2 were expected |
| A partial batch write leaves no unreferenced recording | **failed** — 2 files remained |
| An unreadable stored Course retains the recordings | passed (recovery guard) |
| A confirmed Course keeps every imported recording | passed (`deleteUnreferenced` guard) |

The partial-batch failure is injected at the real boundary: a directory
occupies the third recording's target file name, so its rename fails after the
first two are already stored.

Implementing the owner exposed one thing the plan had wrong: `PopScope.canPop`
was `_routeMayPop || !_dirty`, so an **unchanged** editor popped directly and
never reached `_popEditor`. That is exactly the back-out-after-import path, so
`canPop` is now `_routeMayPop` only and every exit runs through one place.

## One interaction worth knowing

Restoring a historical version inside the Editor copies that version's media
back into the Course folder (`CourseBackupService.reinstateMedia`), so those
recordings are created by the session. Confirming keeps the ones the Course
uses; cancelling removes them. Nothing is lost: the backup keeps its own
copies and a later restore re-copies them. Restored **images** are untouched,
because this build owns recordings only.

## Changed files

Source: `lib/services/course_authoring_media.dart` (new),
`lib/services/course_authoring_session.dart`,
`lib/services/course_editor_service.dart`,
`lib/services/course_media_store.dart`,
`lib/screens/course_editor_screen.dart`.

Tests: `test/audio_library_media_248_test.dart` (new, 9 tests),
`test/production_course_transaction_225_04_test.dart` and
`test/course_ownership_team_229_r1_test.dart` (four unchanged-exit assertions
now wait with the repository's existing `pumpUntilFileIoState`, because closing
an unchanged editor now completes after a real folder check).

Release: `pubspec.yaml`, `lib/services/app_metadata.dart` and its four version
tests (`test/app_metadata_225_04_test.dart`,
`test/course_audit_report_225_test.dart`, `test/qql_229_revision3_test.dart`,
`test/qql_233_revision_platform_contract_test.dart`), `AGENTS.md`,
`README.md`, `CHANGELOG.md`, `docs/248_AUDIO_LIBRARY_PLAN.md`,
`docs/248_CHANGE_SUMMARY.md`, `docs/248_VALIDATION.md` and this handoff.
`lib/services/beta_lifecycle_service.dart` is unchanged because the
recalculated expiry is the same date.

## Validation

`flutter analyze --no-pub` found no issues and the four asset validators
passed. The complete suite ran 2,302 tests at `--concurrency=1` in 32 min 22 s:
**2,301 passed, 1 failed**. The single failure,
`guidebook_status_workflow_226_02_test.dart` "empty Guidebook saved as Draft is
red and blue…", **passes in isolation** and sits on the confirmed-save path,
which this build leaves a no-op; it is recorded as a load-induced flake with
its reasoning in [248_VALIDATION.md](248_VALIDATION.md). `git diff --check`
is clean. `tools/validate_release.ps1` reruns the complete suite at the release
gate, which re-checks this on an idle machine.

**Follow-up on that failure.** Running the file 13 times on unchanged `main`
and 19 times on this branch produced 0 and 2 failures respectively — but both
failures came from one heavily loaded session and all 32 clean runs from a
rested machine, so the experiment neither convicts nor clears this build. The
first claim that the failure was definitely unrelated was withdrawn as
overconfident. Both affected tests waited for the confirmed save with a
hand-rolled ~3 s budget; they now use the shared `pumpUntilFileIoState`, which
allows 10 s, as every other Course Editor test does. That is a test-only
robustness fix worth making regardless of cause, and it does not touch the
application or the behaviour the owner smoke tested. The app is byte-identical,
so the build number is deliberately **not** bumped for it.

## Known limits

* **Pictures added while editing leak the same way** and are deliberately out
  of scope (owner decision 2). The Course Editor's Image Library and the
  Exercise image field write into the Course folder before confirmation.
  `CourseAuthoringMedia.ownedExtensions` is the single place that widens.
* A session ended by process death rather than through the Editor still leaves
  its files; the next successful save of that Course removes them.
* An emptied Course media folder may remain as an empty directory until the
  next confirmed save removes it.
* Course Editor and Course Manager widget tests time out waiting for file IO
  when run in parallel; run them with `--concurrency=1`, as the release gate
  does.
* An in-isolate per-Course lock does not coordinate external writers; this
  remains the documented Build 245 storage limit.
* Manual device smoke testing and a platform release artifact remain outside
  this source revision.

## Next boundary

Build 248 is complete unless its tests prove another correction necessary; a
Revision 1 would be a separately reviewable fix with its own failing test,
version, validation, handoff and commit. Push, PR and merge follow the owner's
direction.

Merge Build 248 before starting **Build 249 (Exercise Authoring)** in a new
session from the then-current `main`. Read `AGENTS.md`, `pubspec.yaml`, this
handoff and the [approved architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md)
first, then write the Build 249 contract and characterization tests before
giving `ExerciseEditorScreen._buildCandidate` a pure draft-builder contract.

The image half of this build's problem is the obvious candidate for its own
revision or build whenever the owner wants it; the owner asked to be told
about it rather than have it folded in here.

---

# Revision 1 current state

Build 248 Revision 1 is `2.0.48+248001`, Course Model v11, on branch
`claude/248-audio-library`, following Revision 0 commit `c7c9712` and the
test-robustness commit `ddb67a3`. Beta expiry remains `2026-10-22 23:59:59`
local time. The untracked `devtools_options.yaml` is the owner's and stays
untouched.

**Why this revision exists.** It is a Course Editor layout scope extension the
owner asked for on 2026-09-23, not a correction proven by Build 248's tests.
The recommendation was a separate build after Build 248 merged, so Revision 0's
manual smoke test stayed valid; the owner chose to add it to the open pull
request. Recorded so the history says why.

Six changes: the Course-level Lesson settings (Lesson numbering, Use GuideBook,
Create Duels) move from the Lessons screen to a collapsed **Lesson Options**
section under the Course Editor's Lessons tile; the Lesson editor drops
`lesson-title-control` and `lesson-audit-action`; the Round editor drops
`round-rename-action` and `round-audit-action`; the Audio Library loses its
Save button and applies its draft on exit with an explaining notice; a Course's
Image Library gains the same notice (its behaviour already matched); and
`CourseAuthoringMedia.ownedExtensions` widens from MP3s to every kind of Course
media, closing the image limit Revision 0 recorded.

`askAuthoringName` is now the one shared authoring title prompt.

Validation: analyzer clean, four validators pass, **2,305 / 2,305** tests
passed at `--concurrency=1` in 27 min 35 s, `git diff --check` clean. See
[248_VALIDATION.md](248_VALIDATION.md).

## Known limits after Revision 1

* The Lesson editor no longer shows the plain Lesson title, because
  `lesson-title-control` was the only widget displaying it. The numbered title
  remains in the AppBar and breadcrumbs.
* A session ended by process death still leaves its media; the next successful
  save of that Course removes it.
* An emptied Course media folder may remain as an empty directory until the
  next confirmed save.
* The in-isolate per-Course lock does not coordinate external writers (Build
  245 limit).

## Next boundary

**The owner must repeat the manual Audio Library smoke test**, because
Revision 1 changed that screen after Revision 0 was tested by hand.

A Revision 2 was requested on 2026-09-23 and is **not** implemented here:
a dedicated Course Export screen mirroring `CourseImportScreen`; one Export
command in the Course Manager menu replacing `Export Course ZIP` and
`Save to…`; removal of the Course Editor's two export tiles
(`course-editor-export-json`, `course-editor-save-json-to`, which today export
the **unconfirmed working copy** — a real defect, since a cancelled session
would leave an exported Course that exists nowhere); a bottom-area Preview and
Round Wizard in the Lesson editor replacing `lesson-preview-action` and
`guidebook-round-generator`; renaming the Round editor's `Creation Wizard` to
`Exercise Wizard`; and moving the Lesson editor's `EditorBreadcrumbs` to the
top. Write its plan before any source change.

---

# Revision 2 current state

Build 248 Revision 2 is `2.0.48+248002`, Course Model v11, on branch
`claude/248-audio-library`, following `ecee745`. Beta expiry remains
`2026-10-22 23:59:59` local time. The untracked `devtools_options.yaml` is the
owner's and stays untouched.

**Why this revision exists.** A Course Editor scope extension the owner asked
for on 2026-09-23, added to the open pull request at the owner's choice. It
also fixes a real defect: the Editor's export and Copy as New Course ran on the
unconfirmed working copy.

Eight changes: a `CourseExportScreen` mirroring `CourseImportScreen` with the
fixed-folder route and **Save to…**; one **Export Course** entry in the Course
Manager menu opening it, for official Courses too; removal of
`course-editor-export-json`, `course-editor-save-json-to` and
`course-editor-copy-as-new-course`; `lesson-preview-action` and
`guidebook-round-generator` replaced by bottom-bar `lesson-preview` and
`lesson-round-wizard`; the Round editor's wizard relabelled **Exercise
Wizard**; and the Lesson editor's `EditorBreadcrumbs` moved to the top of its
body.

`CourseEditorScreen.transferService` is now inert: nothing in the Editor
transfers Courses any more. The parameter is kept so its seven callers,
including several tests, keep compiling.

Validation: analyzer clean, four validators pass, **2,306 / 2,306** tests
passed at `--concurrency=1` in 24 min 21 s, `git diff --check` clean.

## Deliberately not done

Version History stays in the Course Editor. It writes into the working copy and
respects the single confirmation, unlike export and copy; moving it would have
created a second persistence path and left restored media with no owner. The
owner cancelled that change after the analysis.

## Next boundary

**Smoke tests the owner still owes before release:** the Audio Library
(Revision 1 changed it), exporting from Course Manager through the new screen,
and the Lesson bottom bar.

Three commits are local and unpushed: `c7c9712` (Revision 0, already pushed),
`ddb67a3` (test robustness) and `ecee745` (Revision 1), plus this one. The pull
request description still describes Revision 0 only and needs rewriting before
merge.

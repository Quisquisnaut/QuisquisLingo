# Build 248 Revision 2 — Course Export screen and Lesson actions plan

Status: requested by the owner on 2026-09-23, to be added to the **open Build
248 pull request**. Version `2.0.48+248002`. Owner answers recorded below.

**Scope note.** Like Revision 1, this is a scope extension the owner asked for,
not a correction proven by Build 248's tests. Recorded so the history says why.

## Owner answers

* The Export screen **mirrors the Import screen exactly**: a fixed-folder route
  and a **Save to…** route through the system file dialog.
* The Course Manager's single Export command routes **official Courses through
  the same screen**, not only custom ones.

## The seven changes

### 1. A Course Export screen

New `CourseExportScreen` beside `CourseImportScreen` in
`lib/screens/course_projects_screen.dart`, built the same way: a primary
`FilledButton.icon` for the fixed-folder export, an `OutlinedButton.icon` for
**Save to…** shown only when `fileDialogsAvailable`, the shared
`cloudFolderHelpText()`, and instructions. It takes the two callbacks and owns
no export logic of its own.

### 2. One Export command in the Course Manager menu

The `export` (`Export Course ZIP`) and `save_to` (`Save to…`) entries become a
single `export` entry that opens the Export screen. The screen then calls the
existing `_exportCourse` and save-to handlers unchanged, so the export itself
and its Audit notice keep their current behaviour. The entry stays available
for official Courses and for operational access, exactly as the two entries
were.

### 3. The Course Editor stops exporting

Remove `course-editor-export-json` and `course-editor-save-json-to`, and their
handlers once unreferenced.

**This fixes a real defect, not only duplication.** `_exportCustomCourse` calls
`_transfer.exportCourse(_course)`, where `_course` is the **working copy**. A
Course could be exported with changes that are not saved and may never be
saved, producing a ZIP of a Course that exists nowhere. Export belongs to the
Course Manager, which works from stored Courses.

### 4. Lesson Preview moves to the bottom bar

Remove the `lesson-preview-action` tile. Add an `OutlinedButton.icon` keyed
`lesson-preview` to the Lesson editor's bottom `Wrap`, mirroring the Round
editor's `round-preview`: same icon, same `Preview` label, same position first
in the bar.

### 5. Round Wizard moves to the bottom bar

Remove the `guidebook-round-generator` tile and its explanatory subtitle. Add a
`FilledButton.icon` keyed `lesson-round-wizard` labelled **Round Wizard** to
the same bottom bar, mirroring the Round editor's wizard button, opening the
unchanged `_openGuidebookRoundGenerator`. Like the Round editor's wizard it
appears only when not read-only.

### 6. Creation Wizard becomes Exercise Wizard

The Round editor's `exercise-creation-wizard` button label changes from
`Creation Wizard` to `Exercise Wizard`. The key, the handler and the
`Exercise Creation Wizard` screen title are unchanged.

### 7. Lesson breadcrumbs move to the top

`EditorBreadcrumbs` moves out of the Lesson editor's bottom `Wrap` into the top
of its `ListView` body, matching the Lesson**s**, Rounds, Round and Exercise
levels, which all render breadcrumbs at the top.

## Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring, progression, the Audit and the single top-level
confirmed Course save. No export path, file name, folder or Audit notice
changes: the same handlers run, reached from one place instead of several. No
new persisted key and no new user-file folder.

## Proof

Existing tests that reach the removed Editor export tiles, the Lesson tiles and
the `Creation Wizard` label will fail until repointed; that failure is the
evidence. New tests cover: the Export screen offering both routes and hiding
**Save to…** when dialogs are unavailable; the Course Manager menu offering one
Export entry that opens it, for an official Course as well; the Course Editor
offering no export; Preview and Round Wizard in the Lesson bottom bar with the
tiles gone; the `Exercise Wizard` label; and breadcrumbs above the Lesson body.

Then `flutter analyze --no-pub`, the four validators, one complete suite at
`--concurrency=1`, version and release records, handoff, `git diff --check`,
and one local commit.

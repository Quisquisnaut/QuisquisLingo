# Build 248 Revision 1 — Course Editor layout and save-notice plan

Status: requested by the owner on 2026-09-23, during the Build 248 session,
to be added to the **open Build 248 pull request** rather than to a separate
build. Version `2.0.48+248001`.

**Scope note, recorded deliberately.** The approved
[roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md) says a Revision 1 exists "only for
a separately reviewable correction or follow-up proven necessary by that
build's tests". This revision is neither: it is a scope extension the owner
asked for. The recommendation was to make it its own build after Build 248
merged, so the Revision 0 smoke test stayed valid; the owner chose the combined
pull request. It is recorded here so the history says why this revision exists.

**Consequence the owner accepted:** item 4 changes the Audio Library screen
that Revision 0's manual smoke test exercised, so that smoke test must be
repeated before release.

## The five changes

### 1. Course-level Lesson settings move to the Course Editor

Three controls sit at the top of the **Lessons** screen today but are
**Course** properties, not Lesson properties:

| Control | Key | Field |
| --- | --- | --- |
| Lesson appearance / Lesson numbering | `lesson-appearance-settings`, `lesson-numbering-…` | `course.lessonNumberingMode`, `course.customLessonLabel` |
| Use GuideBook | `course-use-guidebook` | `course.useGuidebook` |
| Create Duels | `course-create-duels` | `course.createDuels` |

They move to the **Course Editor** screen as a collapsed **Lesson Options**
section directly under the existing `course-editor-lessons-navigation`
("Lessons") tile, expanding only when tapped. This puts Course-level settings
on the Course screen; nothing per-Lesson is lost, because none of them was
per-Lesson.

The Lessons screen keeps its breadcrumbs, list, reordering and New lesson
action. Its `lesson-course-settings-scroll` wrapper goes with the settings.

Expansion is page-session only and starts collapsed; it is presentation state
and is not persisted.

### 2. Lesson editor drops its duplicate Rename and Audit

Remove `lesson-title-control` ("Lesson title", opens Rename lesson) and
`lesson-audit-action` ("Audit Lesson"). Both already exist in the Lessons
page's 3-dot menu as **Rename** and **Audit**, verified in the source.

### 3. Round editor drops its duplicate Rename and Audit

Remove `round-rename-action` ("Rename Round") and `round-audit-action`
("Audit Round"). Both already exist in the Rounds page's 3-dot menu as
**Rename** and **Audit**, verified in the source.

### 4. Audio Library saves on leaving the screen

Remove the AppBar **Save** button. Leaving the screen by any route returns the
local draft to the Course Editor, which stages it in the working copy exactly
as **Save** does today. The Course Editor's single top-level confirmation
remains the only thing that writes a Course, so cancelling the Course still
discards these changes — and Build 248 Revision 0 removes the recordings that
attempt created.

The screen uses this file's established exit idiom (`_routeMayPop` plus
`PopScope`), so one pop returns one result.

A notice on the screen explains the behaviour.

### 5. Image Library gains the same notice

**No behaviour change is needed.** `FlatImageLibraryScreen` already reports
through `onCourseChanged: _updateDraft`, so its changes already enter the
working copy and are already discarded when the Course is cancelled. The
owner's request to "add a discard on Editor exit" is already satisfied; only
the notice is missing, and only the notice is added.

## Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring, progression, the Audit, and the single top-level
confirmed Course save. No control is removed without an existing equivalent,
and no Course field changes meaning. This revision moves and relabels UI and
adds two notices; it introduces no new persisted key, no new user-file folder
and no second persistence path.

## Proof

Existing tests reach the three moved controls through the **Lessons** screen
and will fail until they navigate to the Course Editor and expand Lesson
Options; that failure is the evidence the move happened. Affected suites:
`lesson_controls_226_04`, `optional_learning_paths_226_04`,
`lesson_naming_226_04`, `qql_231_revision1`, `editor_help_translation`,
`provisional_publication_service`, plus `authoring_hierarchy_indicators_226_02`,
`exercise_workflow_226_02`, `qql_231_course_editor_ui` and
`media_messages_revision17` for items 2–4.

New tests cover: Lesson Options collapsed by default and revealing all three
controls when tapped; the three controls absent from the Lessons screen; the
four removed links absent while the 3-dot menu equivalents still work; the
Audio Library returning its draft with no Save button; and both notices.

Then `flutter analyze --no-pub`, the four validators, one complete suite at
`--concurrency=1`, version and release records, handoff, `git diff --check`,
and one local commit.

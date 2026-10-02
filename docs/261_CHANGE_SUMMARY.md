# Build 261 change summary

Owner requests 1–6 of 1 October 2026, discussed with questions the same
evening. Three revisions: 0 learner polish, 1 Study and Review from
Courses and the Course Editor's opening mode, 2 the Course preview from the
Course Editor.

## Revision 0 (2.0.61+261000, 2 October 2026): learner polish

**Round names on one line.** In the learner path a Round card showed
"Round 2" in bold on its own line and the title in bold below it. Now the
name is one line (`_RoundNode._title` in `lib/screens/home_screen.dart`,
key `unified-round-title-<id>`): "Round 2: " in normal weight before the
title in bold, in a slightly smaller type (15 instead of 16 points, line
height 1.4), wrapping up to three lines, so that with the status line it
still fits the card's 88 pixels. A Story shows "Story: " and its title the
same way, a sequence "Sequence: " (the label `LearningRound.displayTitle`
derives); a Round without a title of its own shows "Round 2" alone, in
bold. "Round", "Story" and "Sequence" stay English (owner decision: not
translated with the learner panel's buttons).

**Tooltips.** The Round name and the Lesson title (`identity.fullText`,
key `unified-guidebook-lesson-tooltip-<id>`) show their whole text as a
tooltip on hover or long press, for when three lines cut them. The
tooltips are left out of the semantics tree, which already reads the text.

**Confetti for the weekly goal.** When a Round's completion reaches the
Weekly XP Target, the "Weekly goal reached!" dialog now has a short burst
of confetti over it (`ConfettiBurst`, `lib/widgets/confetti_burst.dart`):
about two seconds, 90 pieces fired from the two lower corners, falling and
fading, drawn by its own painter (no new package), never taking a tap and
hidden from screen readers. It shows only when `ConfettiBurst.allowed`:
Animations on in Do Not Disturb (whose subtitle now names it) and no
reduced motion asked by the system. Only the weekly goal celebrates this
way (owner decision: not a first Laurel, a Duel or a Lesson). Help
EN/IT/ES say so in the progress paragraph.

Scoring, progression, Course files and learner data are unchanged.

## Revision 1 (2.0.61+261001, 2 October 2026): Study and Review from Courses, the Course Editor opening mode

**Study and Review in the Course menus.** The ⋮ menu of every Course in
All Courses and in Course Studio starts with **Study** and **Review**.
Study closes Courses and goes back to the learner page with that Course
current; a Course not yet in the learner's personal library is added first
(owner decision: both tabs, and Study adds). Review does the same and then
opens the Review page on the Course. Courses closes with a
`CourseStudyRequest` (`lib/services/course_study.dart`) that
`HomeScreen._studyFromCourses` carries out after the Course Selector's
Courses entry, the empty library's All Courses button and its Course
Studio button; a bundled Course is switched by
`CourseService.bundledCodeForCourse`, so QQL Demo: Piedmontese and QQL Demo:
English from Italian are told apart from the Courses that share their
language. Entries that cannot be used are greyed with the reason
(`CourseStudy.studyUnavailableReason`, the reasons the Study now offer after
an import already gave: no learner, Publisher verification required, not
published, not available for study; Review also "Complete a Round of this
Course first." when the learner has no Review record for it,
`CourseStudy.coursesWithCompletedRounds`). In Course Studio they are
`CourseManagerAction.study` / `review` from
`CourseManagerLibrary.studyEntriesFor` (`reviewableCourseIds` read by
`load`), kept apart from `entriesFor`, whose authoring entries are
unchanged. The menus offer them only where they can return to the learner
page (`onStudy`); the import-only Course Studio leaves them out. A Course
hidden in Learner stays hidden when it is studied.

**Course Editor opening mode.** Do Not Disturb has a per-learner **Course
Editor opening mode** (`course-editor-opening-mode`: Locked, View only,
Inspection mode, Edit; View only until chosen), stored as
`learner_<id>_course_editor_opening_mode`
(`SettingsService.getCourseEditorOpeningMode` /
`setCourseEditorOpeningMode`). It is the mode a Course opens in the first
time this learner opens it in the Course Editor: `getCourseEditorMode`
falls back to it after the Course's own mode and the legacy lock value, and
`CourseEditorDeviceState.openingMode` stores it as the Course's own mode on
that first opening, so a later change of the default leaves Courses
already opened alone (owner decision: "only Courses never opened"). Edit
still opens as View only without editing rights. The key is a learner
setting: the learner-progress reset keeps it, removing the learner or
Wipe everything removes it, learner backups carry it, Inventory counts it
among the learner's settings (`docs/239_RESET_STORAGE_INVENTORY.md`).

Help EN/IT/ES: All Courses Help and Course Studio Help describe Study and
Review; the Editor Help answer on Locked, View only, Inspection mode and
Edit names the opening mode. Scoring, progression, Course files and
learner progress are unchanged.

## Revision 2 (2.0.61+261002, 2 October 2026): the Course preview from the Course Editor

**The flag.** Every Course Editor screen shows the Course's cover, or its
flag, left of its title (`CoursePreviewFlag` / `CoursePreviewTitle` in
`lib/widgets/course_preview_flag.dart`, key `course-preview-flag`, tooltip
"Preview as a learner"): the main page (its existing flag, now tappable),
Lessons, the Lesson editor, Rounds, the Round editor, the exercise forms
and the Generic Primitive Editor, the GuideBook editor and its Insights
(which now receive the working copy for this), the Round Wizard, the Story
Wizard, the Exercise Creation Wizard, Course Audit, the Audio Library, the
Image Library when it edits the Course (not when it picks an image),
Search, Version History and the Lesson preview list.

**The preview.** A tap opens `CoursePreviewScreen` (`lib/screens/course_preview_screen.dart`,
a part of `home_screen.dart` so it draws the learner page's own Lesson
sections) on the working copy as that screen holds it: Draft Lessons,
Rounds, exercises and GuideBooks included, every Lesson open, no Round
completed, no Laurel (owner decisions: Drafts included, a clean slate).
Rounds and Stories play in the Round Preview (`RoundScreen` with
`previewMode`), the GuideBook opens with its Draft content, and the Duel in
a new `DuelScreen.previewMode` (Draft content counted through
`DuelEligibilityService.evaluate(includeDrafts:)` / `evaluateEffective`,
the learner's Audio Settings bypassed as in a Round Preview, title "PREVIEW
· …", nothing recorded). The Course Selector, Settings, Profile and Review
are shown greyed with "Not available in the Course preview."; Course Info
opens. The screen reads and writes no learner state, so the stored current
Course and the learner's progress are unchanged. **Preview · Exit**
(`course-preview-exit`) pops back to the screen that opened it, whose
editing session is untouched, changes still waiting for the Course
confirmation. From an exercise form the preview shows the working copy with
what the form saved in this session (`_savedInSession`), never its unsaved
edits (owner decision); the other forms (a Lesson's section and icon
fields, the GuideBook form, the wizards' drafts) likewise show what is in
the working copy.

Help EN/IT/ES: the Editor Help question on trying the Course, a Lesson or
a Round as a learner. Scoring, progression, Course files and learner data
are unchanged.

## Revision 3 (2.0.61+261003, 2 October 2026): exercise titles

Owner report and decisions of 2 October 2026: in QQL Demo: Piedmontese,
Mixed practice 6, the "the dog" exercise had no title. Pick the
translation never had one (a Build 239 choice: one instruction line only),
and the other titles named an interaction kind shared by several presets
(CHOOSE for Choose the answer and True or false, BUILD THE SENTENCE for
Word order and Pick the words for the gaps, MATCH, COMPLETE, …). The owner
decided that every exercise has a title, the name of its preset, and an
instruction.

**The title.** `ExerciseTitle` (`lib/services/exercise_title.dart`) finds
the preset that represents an exercise from its canonical content with the
Course Editor's own recognition (`PresetRecipes.recognize`, cached per
exercise), never from the stored preset ID (owner decision), and drops "(to
target)" / "(to source)": 40 titles for the 46 presets. An exercise no
preset represents keeps the title of its kind.
`ExerciseCopyService.title(course, exercise)` reads `title.<slug>` from the
learner-panel catalog of the Course's instruction language: the seven
catalogs (`lib/localization/exercise_copy/`) gain the 40 titles (the six
translations AI-written, reusing the existing headings where they already
said the same, e.g. SCEGLI L’IMMAGINE).

**Where.** Rounds, Review and every Preview show the title above the
instruction; Pick the translation has the title and its line in the
ordinary instruction style. Inside a Story no title is shown, only the
instruction, the Story cover included (its STORY heading is gone: the
Round is already called "Story: …"), and the scrolling log heads each
exercise with its instruction (a sequence keeps the title); Dialogue lines
and Pages keep no title and no instruction, and the Duel shows no titles,
as before.

**The Pick the translation line** ("Pick the correct Italian translation")
is in the instruction language too (`instruction.selectTranslation`, e.g.
"Scegli la traduzione corretta in inglese" in QQL Demo: English from
Italian), in the Round and the Duel; `TranslationChoice.instructionFor` is
removed.

AGENTS.md records the one preset-dependent thing learners see. Help
EN/IT/ES (the primitives page's status). Scoring, progression, Course
files and learner data are unchanged.

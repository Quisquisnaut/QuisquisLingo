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

## Revision 4 (2.0.61+261004, 2 October 2026): the preview made evident

Owner request and decisions of 2 October 2026: entering the preview from
the Course Editor's flag must be evident; the preview should not show
buttons that do not work, and should offer Theme and Flag background.

**The PREVIEW bar.** `CoursePreviewScreen` opens with a full-width amber
bar (`course-preview-bar`, `CoursePreviewScreen.barColor`): an eye,
"**PREVIEW** · As a learner sees it · nothing is recorded" and the **Exit**
button (`course-preview-exit`), in place of the Revision 2 chip. Below it,
the Course's flag or cover (now only a picture) and its title.

**Only the controls that work.** The greyed Course Selector look,
Settings, Profile and Review are gone. The bottom bar holds Course Info,
**Theme** (`course-preview-theme`, Light / Dark) and **Flag background**
(`course-preview-flag-background`, the learner page's five modes, drawn
behind the page as there: the flag with its veil, or the Tinted /
Inspired colours). Both start from the active learner's choice (the
app's appearance; the learner's Flag background for this Course, read
once) and change for this preview only: the screen is a StatefulWidget
whose Theme and LearnerThemeModeScope wrap the page, nothing is written,
and Rounds, Stories and Duels opened from it keep the app's own
appearance.

Help EN/IT/ES (the Editor Help answer on trying the Course as a
learner). Scoring, progression, Course files and learner data are
unchanged.

## Revision 5 (2.0.61+261005, 2 October 2026): owner review points 1, 2, 4 and 5

Owner review of 2 October 2026 (point 3, authoring the bundled Courses
inside the app, is Build 262).

**1. Reading answers no longer copy the text.** In QQL Demo: English from
Italian, "What does Tom ask?" was answered by "How are you?", the very
words of the dialogue. The owner's rule: in a reading exercise the correct
answer must not repeat the text word for word; listening exercises are
exempt (hearing is harder than reading). The seven reading questions of
the bundled Courses that broke it are rewritten in their generators:
English from Italian "What does Tom want to know?" → "If Anna is well";
the Laboratory "Che cosa accetta Luca?" → "Un frutto.", "Il caffè di Luca
è dolce?" → "No, è amaro.", "La stazione è lontana?" → "No, non è
lontana."; the Piedmontese demo (and so QQL Demo: Piedmontese)
"Quand ch'as treuvo?" → "La matin.", "Còs ch'a fa Anna?" → "A ringrassia
Gioann.", "Quand ch'as saludo?" → "La sèira." (Piedmontese AI-written, to
be reviewed; the Lesson card lists ringrassié, la matin and la sèira).
The Audit gains `READING_ANSWER_IN_TEXT` (Warning, 114 rules): the correct
answer of a reading kind (Read and answer, reading, dialogue) appears word
for word in its passage, situation, context or dialogue lines, compared
as words in small letters; listening is not checked. AGENTS.md records the
rule among the exercise-content rules.

**2. Untitled practice Rounds.** QQL Demo: English from Italian's ordinary
Rounds lose their titles "Pratica 1–6" (the generator writes no title, as
the app stores an untitled Round); learners see "Round 1"… The two
Stories keep theirs.

**4. New Canonical folded into New Exercise.** The Round editor's New
Canonical button is gone; the canonical editor is the last choice of New
Exercise's preset sheet (Canonical editor). Help EN/IT/ES updated.

**5. Fill with an example.** A new exercise in the canonical editor has
**Fill with an example** (`primitive-fill-example`) under the primitive:
it fills the form with a working example of the chosen primitive
(`CanonicalExerciseSamples.forPrimitive`, `lib/services/canonical_exercise_samples.dart`:
a Select "Which animal barks?", an Input, an Arrange with one distractor,
a Match of opposites, an Assign built by the Sort into groups recipe
without its preset, Speak, Ink and Submit definitions, a Presentation
card), English placeholders that state no language. When the form already
holds something it asks first ("Replace with an example?"). The example
is loaded by `CanonicalExerciseDraft.fillFrom`; the form's cards are
rebuilt so every field shows it. An existing exercise offers no example.

Scoring, progression and learner data are unchanged.

## Revision 6 (2.0.61+261006, 2 October 2026): the canonical editor explains its primitives

Owner request and decisions of 2 October 2026; plan
`docs/261_REVISION6_PLAN.md`.

**1. A popup for each primitive.** The first time the canonical editor
shows a primitive in a Course, a popup ("Select: how it works") says what
the learner does, which fields to fill and a tip (`PrimitiveIntro`,
`lib/widgets/primitive_intro.dart`). Once per primitive, per learner and
per Course: opening a Select exercise shows the Select popup, choosing
Match in the selector shows the Match one, the same primitive in another
Course shows it again. English only, like every editor popup (owner
decision). It follows the Course's "Two ways to create an exercise"
introduction when both are due, and never appears while the form is read
only. Stored as a learner one-time notice
(`learner_<id>_one_time_notice_seen_primitive_intro_<primitive>_<course>`),
so Show one-time notices again brings it back; resets and the Inventory
cover it through the learner prefix (`docs/239_RESET_STORAGE_INVENTORY.md`).

**2. Clear all.** Beside Fill with an example, for new exercises: the form
returns to the blank defaults of its primitive, after "Clear all fields?"
when it holds something.

**3. Changing the primitive.** When a new exercise's primitive changes and
the form was not blank, a message says "You changed exercise type. Please
check all fields." The change itself works as before.

**4. Help for each primitive.** Editor Help › Exercise primitives has a
section for each of the nine primitives (English, Italian, Spanish): what
the learner does, the fields that matter, and the owner's screenshot of
the exercise Fill with an example writes, as the learner sees it
(`assets/primitives_screenshots/`, a new asset folder; Speak, Ink and
Submit show the "Not playable in this version" card). The page reads each
picture's size from its PNG header before it is laid out, so it can open
at a section; a missing picture leaves the text alone.

**5. Help at the primitive.** The canonical editor's Help button
("Help: Select") opens the Exercise primitives reference at the section of
the primitive being edited; elsewhere Help is unchanged.

**6. Role is a menu.** The owner asked why Role was free text; it was a
shortcut, and a mistyped role left an element QQL silently ignored. The
owner chose a menu of the roles QQL reads only (no free entry): one
catalog, `ElementRoles` (`lib/models/canonical/element_roles.dart`), gives
each role its element types, its place (prompt or item content), whether
only a Presentation reads it, and a description shown in the menu and
under the field. Item content rows get the menu too. A stored role outside
the list (an imported Course, or a role another primitive uses) stays
selected and is marked "not a QQL role" or "not used by this primitive";
nothing is rewritten unless the author picks another role. A test checks
that every role in the bundled Courses' exercises is in the catalog. The
Help's exercise anatomy and canonical editor sections say so.

Also: the "Two ways to create an exercise" popup named the New canonical
button, removed in Revision 5; it now says New Exercise › Canonical
editor.

Scoring, progression and learner data are unchanged.

### Revision 6 follow-up (same version, 2 October 2026): the canonical editor fits a phone

Owner request after Revision 6 reported it. At 360 pixels the canonical
editor's menus ran off the right edge (up to about 90 pixels for the
options, 187 for a gap's Reveal menu): a menu without `isExpanded` takes
the width of its longest entry, and the Match item and target rows put a
menu and buttons on one line. Every menu of the form now takes the width
it is given and cuts a long entry with an ellipsis; a Match item's Side
and a gap's Reveal are full-width fields under the row's title (labelled
Side and Reveal; same values). Nothing else changes.

## Revision 7 (2.0.61+261007, 3 October 2026): Round Types

Owner proposal `docs/QQL_Round_Types_Redesign_Plan.md` and decisions of
3 October 2026; implementation plan
`docs/superpowers/plans/2026-10-03-round-types-redesign.md`.

**1. A type for every Round.** `LearningRound.roundType` (`RoundType`:
discover, practice, sequence, listening, reading, story, flashcard, test,
timed, speak) is stored with the Round (`roundType` in JSON, unknown values
refused) and is what the editor, the Audit, the player and the learner path
read; `visualType` stays in the file but decides nothing new. Labels and
icons come from one place (`RoundTypePresentation`,
`lib/services/round_type_presentation.dart`). Speak is listed, disabled,
as coming later; an imported Speak Round is not playable.

**2. Existing Rounds.** A Round without `roundType` is a Story or a
Sequence when its flow says so; a Round marked Listening becomes Listen
only when every required exercise structurally depends on its audio; every
other Round is Practice (an old Test icon could not prove deferred
feedback). Official Courses signed before this version keep their checksum
(`CourseChecksums.officialMatches` accepts the older shape while the
synthesized values equal what migration assigns).

**3. Creating Rounds.** New Round opens a type selector
(`new-round-type-<type>`); Story opens the Story Wizard; New Story and the
Play as a sequence switch are gone. The Round Wizard shows a type for each
proposed Round and replans its exercises from the same GuideBook when the
type changes (`GuidebookRoundGenerator.changeType`); Read, Story and Timed
cannot be generated from vocabulary and say why.

**4. Compatibility and the Audit.** `RoundTypeCompatibility`
(`lib/services/round_type_compatibility.dart`) answers both which presets
the exercise list offers and whether an actual exercise fits: Listen needs
audio the learner cannot read elsewhere, Read a question on a passage whose
correct answer is not copied from it, FlashCard canonical Flashcards, Test
and Timed automatically evaluatable exercises (Timed also no required
audio). The Canonical editor warns and refuses to publish an exercise that
does not fit; a Draft may hold anything. The Audit's new Round-type rules
block publication.

**5. Playback.** Practice, Discover, Listen and Read keep immediate
feedback and the mistake review; Sequence and Story keep their authored
flow; FlashCard goes card by card. **Test** collects the answers without
feedback and shows every result at the end; it can keep a fixed order, and
an optional passing threshold changes only the result's label (completion,
XP and unlocks as usual). The result texts are in the seven learner-panel
catalogs.

**6. Timed.** One or more distinct limits, in order, each 30 seconds to
10 minutes (presets 30 s, 60 s, 90 s, 2, 3 and 5 min, or Custom;
`TimedRoundRules`, `lib/services/timed_round_rules.dart`); Lesson Options
holds the Course's default limits (`Course.defaultTimedLimitsSeconds`),
copied into each new Timed Round. The countdown starts with the first
exercise, after any Before you start card. Finishing in time completes the
Round normally and, the first time each limit is beaten, adds a 10 XP On
Time bonus (`XpCalculator`, `RoundXpResult.onTimeBonusXp`, its own line in
the completion dialog) and unlocks the next limit
(`ProgressService.claimTimedLimit`, key `v4_completed_timed_limits`, reset
with learner progress). When time runs out, input stops at once, the
first-pass correct answers earn their XP
(`XpCalculator.calculateTimedTimeoutAward`), and the Round stays incomplete
until retried. Preview and View Only record nothing. Icon
`Icons.timer_outlined`.

**7. Label and numbering.** Lesson Options has **Lesson label and
numbering** (Off, Lesson + number, Number only, Custom + number; the older
Unit, Topic, Module… choices still display) and **Round label and
numbering** (`Course.roundNumberingMode`: Off by default, Round + number,
Number only, Custom + number). Numbers come from the Round's position, never
stored. Authored titles stay visible in every mode; Lesson titles remain
required, Round titles optional. The learner path says Completed for a
completed Round that was not perfect, so Practice is not both a type and a
status.

**8. Help.** Editor Help has a Round Types topic (English, Italian,
Spanish) that now holds the Story and Sequence questions, and a question on
the two label and numbering selectors; the Stories section leaves the
Exercise primitives page.

Bundled Courses and the Laboratory-of-the-future fixture are regenerated
with explicit types (`tools/validate_courses.py` checks them). Scoring and
progression are unchanged except for Timed.

## Revision 8 (2.0.61+261008, 3 October 2026): the learner path in Lesson colours

Owner request and decisions of 3 October 2026, refined over six renders of
the real path drawn with the Roboto font (tinted cards and coloured label
pills were offered and declined: colour on the circles only).

**1. A colour for each Lesson.** `LessonColorPalette`
(`lib/services/lesson_color_palette.dart`) holds eight colours (indigo,
purple, magenta, coral, gold, cyan, brown, slate), each as `LessonColors`
with a solid colour, the number or icon on it, a pale tint and the deeper
shade drawn on the tint, in a light and a dark version; numbers, icons and
the word Completed have at least 4.4:1 contrast. A Lesson's colour comes
from its position (the ninth starts again) and is never stored. There is no
green: green means Perfect.

**2. The circles.** The Lesson number circle (`LessonFallbackIcon`, on the
path and in the Lesson editor's previews) is the solid colour; the stored
fallback style still changes nothing, and a Lesson's own theme picture is
unchanged. A Round's circle, now 52 pixels, is the pale tint ringed with
the colour before completion (on the cream page a tint alone was almost
invisible), the solid colour once completed (replacing orange) and green
with the laurel when perfect; the laurel reaches past the icon slot so the
circle never moves. Completed is written in the Lesson's deeper shade. The
Duel is a circle in the Lesson colour, centred, with its texts underneath.

**3. Faint backgrounds, lighter texts.** The Lesson, Round and Duel rows
lose the 70–75% cards and their border; they keep the old card colour at
20%, rounded, so the path line shows through them a little dimmed, and stay
one tap target. A small grey label line ("Lesson 2", "Round 1 · Practice",
following the numbering settings, and the same whether or not the Round has
a title) sits above the title: Lesson titles 17 points medium, Round titles
15 regular, the status line 12.

**4. The zigzag.** A Round's circle stands at the left edge, the centre or
the right edge, with its texts toward the middle (`LearnerRoundPlacement`);
a 16-step pattern sometimes keeps a place twice and never jumps from one
edge straight to the other, where a curve across the whole width would cross
a text. The mascots take the half the texts leave free, now in seven slots
in ten (four before: without cards the sides looked empty), never on two
Rounds in a row on the same side (`learnerRoundPathMascotRows`), so about
six Rounds in ten have one; the mascot order still runs on across the
Course, each Lesson counting its own (`learnerMascotPositionOffsetForLesson`). On a wide window the path keeps a centred column
of at most 560 pixels.

**5. The line.** Long rounded curves from circle to circle, as the earlier
path had, from the Lesson's circle or picture (except when the IDDQD pill
stands between them, where the short centred connector stays) to the Duel's
circle, or ending at the last Round. Each curve stays in its circles' column
near them and turns between them; how late and how sharply it turns, a
slight bow, its thickness and its strength vary from curve to curve, from
the Rounds' IDs, so a Course always draws the same path. The line is a
filled band, thin and faint where it meets a circle, thick and strong
between circles; two circles in one column are joined by an outward bow.

**6. Over a flag picture.** With Flag Background Small or Extended, on the
learner page and in the Course preview, `LearnerPathHalo` gives the texts
stacked shadows in the page colour and the line a wider page-colour band.

**7. Colour code of the path in App Info.** A section after Laurel crowns
(`appInfoSectionIds` `pathColours`, keys `appInfo.pathColours.*` in English,
Italian and Spanish; status words stay English) explains the eight Lesson
colours and the pale, solid and green circles, with the owner's picture
`assets/rounds_screenshots/colors.png`
(a new asset folder; the chat's "⋯" button captured over the Lesson 4
swatch was painted out by copying the clean corner of the Lesson 3 card).
The picture keeps its proportions while it loads; a tap opens it enlarged
(`showEnlargedImage`) inside an `InteractiveViewer`, so it zooms with a
pinch on a phone.

Help (EN/IT/ES): the Lesson icon answer, and the JSON structure in English
and Italian, name the Lesson colour. Scoring, progression, Course files and
learner data are unchanged.

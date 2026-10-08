# Build 261 Revision 6 plan: the canonical editor explains its primitives

Status: **implemented** (Revision 6 commit). Owner request and decisions of
2 October 2026. Version 2.0.61+261006 on branch
`claude/261-learner-polish`, after Revision 5 (`9190715`, handoff
`9b87036`). Build 262 (`docs/262_BUNDLED_AUTHORING_PLAN.md`) waits until
this revision is done.

## 1. A popup that explains each primitive

- The first time the canonical editor (`PrimitiveEditorScreen`) shows a
  primitive in a Course, a popup explains in a few lines how to use that
  primitive: what the learner does, which fields matter, a tip.
- **Once per primitive, per user, per Course** (owner decision): opening a
  Select exercise shows the Select explanation; choosing Match in the
  selector later shows the Match one; the same primitive in another Course
  shows it again.
- **English only** (owner decision of 2 October 2026), like every editor
  popup (the interface of QQL is English).
- Stored as a learner-scoped one-time notice (`learner_<id>_one_time_notice_seen_…`
  with the primitive and the Course ID), so "Show one-time notices again"
  in Do Not Disturb brings the popups back. The learner prefix covers
  resets and backups; `docs/239_RESET_STORAGE_INVENTORY.md` names the key.
- A test seam turns the popups off in `test/flutter_test_config.dart`, as
  `ExerciseEditorIntro.enabled` does, so editor tests are not blocked; the
  revision's own test turns them on.
- It does not replace the existing "Two ways to create an exercise"
  introduction (once per Course); when both are due, that one comes first.

## 2. Clear all

- A **Clear all** button to the right of **Fill with an example**, for new
  exercises only: it restores the blank defaults of the current primitive
  (`CanonicalExerciseDraft.blankExercise`: no content, the registry's
  default evaluation mode and required options).
- When the form holds something it asks first, like Fill with an example.

## 3. Changing the primitive

- When the primitive is changed in the selector and the other fields are
  not empty or default, a message says: "You changed exercise type.
  Please check all fields." (a SnackBar, non-blocking; the change itself
  keeps working as today: content that still applies stays, the rest is
  cleared).

## 4. Editor Help: a section for each primitive

- **Editor Help › Exercise Primitives reference** gains one section per
  primitive: Select, Input, Arrange, Match, Assign, Speak, Ink, Submit,
  Presentation. Each section: what the learner does, the main fields, and
  a screenshot.
- The text is in **English, Italian and Spanish**, like all Help.
- **Screenshots provided by the owner** (2 October 2026): the learner
  Preview of the exercise made with Fill with an example (Speak, Ink and
  Submit show the "Not playable in this version" card). PNG, about 645
  pixels wide, in the folder the owner chose,
  `assets/primitives_screenshots/<primitive>.png`: `select.png`,
  `input.png`, `arrange.png`, `match.png`, `assign.png`, `speak.png`,
  `ink.png`, `submit.png`, `presentation.png`.

  Until a file exists, its section shows the text alone (no broken
  image). The folder is added to the app's assets.

## 5. Help opens at the current primitive

- The Help icon on the canonical editor's page opens Editor Help directly
  at the section of the primitive being edited (the Exercise Primitives
  reference, scrolled to that section). Elsewhere the Help icon is
  unchanged.

## 6. Role is a menu

Owner question and decision of 2 October 2026 (option 1 of the two
proposed): in the canonical editor an element's **Role** is a dropdown, no
longer free text, so a mistyped role can no longer leave an element that
QQL silently ignores.

- The menu offers only the roles QQL uses, for the element's type (text,
  audio, image, link) and place (prompt or item content), and for the
  primitive: Flashcard, Before you start, Story line, Story cover and Page
  roles only in a Presentation; the others only outside it. Each role has
  a short description (menu and helper line).
- One catalog owns the list (`ElementRoles`); a test checks that every
  role of the bundled Courses' exercises is in it.
- A stored role outside the list (an imported Course, or a role another
  primitive uses) stays selected and is shown as "(not a QQL role)" or
  "(not used by this primitive)"; nothing is rewritten unless the author
  picks another role. No free "Other…" entry.
- Item content rows get the menu too (they had no Role field).

## 7. Release work

- Version 2.0.61+261006 (same Beta expiry, `2026-11-01 23:59:59`).
- Help EN/IT/ES; CHANGELOG, README, AGENTS, `docs/261_CHANGE_SUMMARY.md`,
  `docs/261_VALIDATION.md`, `docs/261_HANDOFF.md`.
- Tests: popup once per primitive, user and Course, and again after "Show
  one-time notices again"; Clear all with and without content; the
  type-change message only when fields were filled; nine Help sections in
  three languages, image shown when present and absent without error; the
  Help icon lands on the right section.
- Analyzer, complete suite, one local commit and a handoff commit; push
  only when asked. `docs/262_BUNDLED_AUTHORING_PLAN.md` stays out of this
  commit.

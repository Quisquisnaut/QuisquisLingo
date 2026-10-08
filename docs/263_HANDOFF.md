# Build 263 handoff

Branch `claude/263-preset-forms` from `main` (`a15d0cf`, Build 262 merged
through PR #34). Local commits only, not pushed. Changes:
`docs/263_CHANGE_SUMMARY.md`; evidence: `docs/263_VALIDATION.md`.

Owner review of 4 October 2026, plan approved in chat ("ok a tutto,
confermo"). Decisions:

- Revision 0: change **only** the standard lines whose first word repeats
  the title's first word (no other repetition kinds). Picture answers show
  no word; Select the image and Listen and pick the image lose the Exercise
  image.
- Revision 1: the preset form (`ExerciseEditorScreen`) gets **Fill with an
  example** (the Exercise Laboratory's example of the preset, decomposed
  into the form; English → Italian whatever the Course), **Clear all** (the
  preset's starting values; asks unless blank) and the SnackBar "You changed
  exercise type. Please check all fields." when the preset changes over a
  touched form; new exercises only, as in the canonical editor. First,
  as its own step, one method replaces the draft→controllers block that
  `initState` and `_navigate` duplicate. A Dialogue line example leaves the
  speaker empty (the Laboratory's characters are not in the Course).
- Revision 2: picture answers of a Select: size (normal / large), shape
  (round / square), pictures per row (automatic / 1–4). **Square means a
  cropped square**, with an editor that crops and zooms (reuse
  `showCoverCropDialog`); the crop is saved as a **cropped copy** in the
  Course's media (`media:`, at most 300 KB; a cropped QQL picture becomes a
  Course copy), owner choice over a crop stored as data. **Defaults in the
  Course Editor's Lesson Options** (Course-wide), each exercise may
  override: plan to make the registry default of each new Select option a
  value meaning "as the Course" so an omitted option follows the Course
  (the v12 rule "omitted = registry default" holds). A Course that sets a
  non-default value needs `minimumAppBuild` (older builds refuse unknown
  options). Presets: Select the image and Listen and pick the image; the
  canonical editor shows the options from the registry. Duel unchanged.

## Revision 0 (2.0.63+263000, 4 October 2026)

Done in the working tree (05:37): the seven `exercise_copy` catalogs
(EN 14 keys, IT 10, ES 14, FR 17, DE 3, NL 11, PT none), Help EN/IT/ES and
editor quotes of "Choose the correct … translation",
`TranslationChoice.instruction`, `docs/COURSE_EDITOR.md`; the caption rule
in `RoundScreen._iconChoiceExercise`; no `image` field for `icon_choice`
and `listening_image_choice` (form, `editorFieldKeys`, `help_structure`,
Editor Help pictures answer EN/IT/ES); new
`test/owner_review_263_revision0_test.dart`; pins in eight tests; the
Laboratory baseline (19 records, patched from a recording with
`patch_baseline.py`-style replacement of the instruction values only);
version 2.0.63+263000, expiry 2026-11-03; README, CHANGELOG, AGENTS.md.

Gotcha: the first draft of new lines ("Write every word you hear",
"Complete the missing word you hear", "Build the word …") opened with the
kind headings shown by exercises no preset represents (WRITE WHAT YOU
HEAR, COMPLETE, BUILD THE WORD); the test checks both titles and headings.

Analyzer clean; complete suite 3639 passed, 1 skipped, 0 failed (05:38–06:07).
Committed `92e56cf` "Build 263 Revision 0: titles and lines, picture
answers". Next: Revision 1, prepared in the scratchpad
(`rev1/preset_examples.dart`, `rev1/owner_review_263_revision1_test.dart`).

## Revision 1 (2.0.63+263001, 4 October 2026)

Done in the working tree: `lib/services/preset_examples.dart`;
`ExerciseEditorScreen`: `_loadDraft` (one loader), `_loadScriptController`
takes an exercise, `_applyPresetStart`, `_confirmReplace`,
`_fillWithExample`, `_clearAll`, the two buttons, the type-change SnackBar,
`_formGeneration` on the Page editor key; top-level `_blankExerciseWithId`.
Help EN/IT/ES `editorHelp.qa.newExercise.a`. Test
`test/owner_review_263_revision1_test.dart` 11 passed. Version 2.0.63+263001
(expiry unchanged). Gotchas: the form must be pushed over a host page in a
test (Save pops it); Recognize characters' save decodes its pictures, so
the test lets real time pass; the Page example needs a tall test window.

Focused 281 passed; analyzer clean; complete suite 3650 passed, 1 skipped,
0 failed (06:22–06:50). Committed `0242185` "Build 263 Revision 1: Fill
with an example and Clear all in the preset forms".

## Revision 2 (2.0.63+263002, 4 October 2026)

Done in the working tree (07:20): options and registry, Course field
`pictureAnswers` (`lib/models/picture_answer_style.dart`, exported by
`course_models.dart`), `lib/services/picture_answers.dart`
(`withMinimumAppBuild`, called by `CourseEditorService` on confirmation),
Lesson Options group, preset form fields and builder/decompose, field Help
EN/IT/ES, Editor Help pictures answer, Crop square
(`ExerciseImageField.cropSquare`, `CourseCoverService.storeSquare`,
`showCoverCropDialog(title:, guidance:)`), runtime tiles, capabilities JSON
regenerated, test `owner_review_263_revision2_test.dart` (16), three test
updates. Focused batch (36 files): 690 passed, 2 failed then fixed (field
inventory, a taller window), rerun 40 passed. Version 2.0.63+263002.

Analyzer clean; complete suite 3666 passed, 1 skipped, 0 failed
(07:22–07:44). Committed as "Build 263 Revision 2: picture answers: size,
square crop, per row".

Committed `565fe00`.

## Revision 2 follow-up (same version, 4 October 2026)

Owner review: standard look large squares (recommended two per row), no
four per row (max three), a short last row centred (also in "as many as
fit"), Lesson Options order numberings, GuideBook, Duel, Timed, Picture
answers. Done in the working tree: `PictureAnswerStyle.standard` /
`earlier`, `PicturesPerRow.four` removed, `WrapAlignment.center`, Lesson
Options reordered, Help EN/IT/ES, capabilities JSON regenerated, test
`owner_review_263_revision2_test.dart` rewritten for the new rules (18
passed), Laboratory baseline 2 records. Focused 285 passed; analyzer
clean; complete suite 3668 passed, 1 skipped, 0 failed (14:31–15:01).
Committed as "Build 263 Revision 2 follow-up: the standard look, at most
three per row". Nothing pushed; no PR.

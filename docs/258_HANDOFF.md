# Build 258 handoff — Page cards

Resume from this file alone. Plan (approved by the owner on 29 September
2026): `docs/258_PAGE_CARD_PLAN.md`. Process rules: `docs/256_HANDOFF.md`
("Requirements and process"). Previous build: `docs/257_HANDOFF.md`.

## State (29 September 2026, 17:51)

- Branch `claude/258-page-cards` from `21a47e4` (the approved plan, on top
  of Build 257 Revision 0 `5e0074b`). **Revision 0 in progress**, nothing
  committed yet. Target version `2.0.58+258000`.

## Revisions (re-sequenced from the plan's section 4)

0. **Model and learner display** (this revision): Page element attributes
   and the `link` type, the inline-mark parser, the palette, the Page
   renderer in the Round, the Audit codes, `minimumAppBuild` on save.
1. **300 KB Course pictures** (moved out of Revision 0: it touches the
   media store, the image validator profiles, the Shared Image Library,
   Image Banks, packages and about a dozen tests; `data:` pictures inside
   `course.json` keep 50 KB).
2. **The Page preset form** (block list, marks toolbar, palette, live
   preview, Search, Help).
3. **Video links in the form, the Laboratory Page example** and the
   presentation baseline.
4. **Share, save, email, print** once Q10 (the `pdf` / `printing`
   dependencies) is answered; Q11 (rights) is decided: a Course setting,
   on by default, credits footer.

## Revision 0: done in the working tree

- `lib/models/exercise_canonical.dart`: `BlockTextStyle`, `BlockAlign`,
  `BlockColor`, `BlockSize`, and `pageElementAttributeTypes` (the one table
  of which element types each attribute applies to).
- `PromptElement` (`course_models.dart`): `textStyle`, `align`, `color`,
  `size`, `readAloud`, `url`, `isLink`; strict parsing (an attribute on the
  wrong element type or an unknown value is a `FormatException`; justify
  on text only); `copyWith`, `toJson` (omitted when absent).
- `Exercise.beforeYouStart` unchanged; `ExerciseFeatures.pageBlocks`
  (role `block`), `LearnerExerciseKind.page`; `illustrationImages` skips
  `block` pictures.
- `lib/services/inline_marks.dart`: `**bold**`, `*italic*`, `\*`; a mark
  opens before a non-space and closes after one; unmatched marks show as
  typed (`hasUnmatched`).
- `lib/services/page_blocks.dart`: `PageBlocks.minimumAppBuild` (258000),
  `isAcceptableLink` (https with a host), `hasContent`, `courseHasPages`,
  `withMinimumAppBuild` (applied in
  `CourseEditorService._confirmCourseTransactionLocked`).
- `lib/widgets/page_card.dart`: `PageCardView` (keys `page-card`,
  `page-block-N`, `page-read-aloud-N`, `page-audio-N`, `page-link-N`,
  `page-picture-N`), the palette `colorOf`, `textAlignOf`, `widthShareOf`.
- `RoundScreen`: `_pageExercise` (Continue `page-continue`), `_speakBlock`
  (marks removed, the block's language), `_openPageLink` through the test
  seam `RoundScreen.openLink`; a Page is never skipped and shows no heading
  or instruction.
- Audit (113 rules): `PAGE_EMPTY` (Error), `PAGE_MARK_UNMATCHED` (Warning),
  `PAGE_LINK_INVALID` (Error); `kindLabel` "a Page".
- The Generic Primitive Editor's element rows keep attributes they have no
  field for (Page attributes, and `speakerId`, which they dropped before).
- `docs/capabilities_v12.json` has `elementAttributes`;
  `tools/qql_capabilities.py` `ELEMENT_ATTRIBUTES`; `tools/validate_courses.py`
  checks them and https links.

- `PROMPT_MEDIA_UNSUPPORTED` accepts a `link` only as a Page block.
- Tests: `test/page_card_258_test.dart` (11, green); Audit pins 113;
  version `2.0.58+258000` (all pins); CHANGELOG, README, AGENTS entry,
  `docs/258_CHANGE_SUMMARY.md`, `docs/258_VALIDATION.md`,
  `docs/COURSE_JSON_FORMAT.md`, `docs/EXERCISE_ARCHITECTURE_V12.md`; plan
  notes the re-sequencing. Analyze clean; generators and validator pass
  (the validator's new checks were tried on a sample Page).

## Remaining for Revision 0

- The complete suite (started 17:52), results in the validation doc, the
  commit "Build 258 Revision 0: Page cards, model and learner display",
  this handoff with the hash, the sound. Then Revision 1 (300 KB pictures).

## Open questions for the owner

- **Q10** (plan 2.9): add `pdf`, skip `printing`, print in two steps?

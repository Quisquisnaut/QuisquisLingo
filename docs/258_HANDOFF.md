# Build 258 handoff — Page cards

Resume from this file alone. Plan (approved by the owner on 29 September
2026): `docs/258_PAGE_CARD_PLAN.md`. Process rules: `docs/256_HANDOFF.md`
("Requirements and process"). Previous build: `docs/257_HANDOFF.md`.

## State (30 September 2026, 00:34)

- Committed (not pushed): Revision 0 `19de25b`, 1 `1323eb7`, 2 `3224523`,
  3 `fa368cc`.
- **Revision 4 (`2.0.58+258004`, share, save and print a Page) in the
  working tree**: `Course.allowPageSharing` and the Course Info switch,
  `PageActionsBar`/`PageCapture`, `PageExport`, the `pdf` dependency
  (Q10 approved 30 September), `Export/Pages`, Help, tests, version, Beta
  expiry 30 October (release 30 September) and docs done; analyze clean;
  new tests green. The complete suite runs next (started 00:34).
- After the commit, Build 258's plan is complete; the owner reviews a
  Windows build. Known limit: a page taller than A4 is cut at a fixed
  height in the PDF.
- Do not run `dart format` on files that predate the formatter: in
  Revision 1 it added unrelated whitespace churn to seven files
  (`custom_course_transfer_service.dart`, `exercise_image_service.dart`,
  `image_bank_service.dart`, `course_media_store.dart`,
  `import/image_validator.dart`, `course_cover_255_test.dart`,
  `file_dialogs_240_features_test.dart`), which was reverted; format new
  files and the Build 256+ files only. `docs/CONTEXT_AND_HINT_PLAN.md`
  belongs to another (stopped) session and stays untracked.

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

## Revision 1 plan (300 KB pictures, researched)

- `ImageProfile.exerciseImage` (50 KB) is used for Course media pictures,
  the Shared Image Library, Image Banks and portable `data:` pictures. Split
  it: Course pictures, the Shared Image Library and Image Banks move to
  300 KB (`CourseMediaStore.maxImageBytes`,
  `ExerciseImageService.maxImageBytes`, `ImageBankService.maxImageBytes`,
  the package checks that read `CourseMediaStore.maxImageBytes`); portable
  `data:` pictures inside `course.json` keep 50 KB
  (`PortableExerciseImageService`, the embedded-image check in
  `custom_course_transfer_service.dart`, Recognize characters' editor and
  Audit texts).
- Help to update: the image field's "Maximum 50 KB (51,200 bytes)"
  (`exercise_field_help.dart` and the EN/IT/ES catalogs), the Shared Image
  Library's too-large message, the `CourseMediaImage` comment.
- Tests that pin 50 KB: `course_media_243_test`, `image_bank_service_test`,
  `image_validator_tranche2_test`, `import_hardening_tranche0_test`,
  `import_route_matrix_revision19_test`, `media_messages_revision17_test`,
  `file_dialogs_240_features_test`, `course_cover_255_test`,
  `exercise_field_help_226_02_test`, `media_attribution_test`,
  `course_model_v11_243_test`, `portable_exercise_image_226_03_test`,
  `piedmontais_course_254_test` (to be read one by one).

## Open questions for the owner

- **Q10** (plan 2.9): add `pdf`, skip `printing`, print in two steps?

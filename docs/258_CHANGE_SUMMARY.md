# Build 258 change summary

Build 258 delivers textbook-like **Page** cards, planned and approved on 29
September 2026 in `258_PAGE_CARD_PLAN.md` (owner decisions in its section
3). Evidence: `258_VALIDATION.md`; handoff: `258_HANDOFF.md`.

## Revision 2 (2.0.58+258002, 29 September 2026): the Page form

- Preset **Page** (`page`, Cards and notes, canonical-only recipe): the
  learner reads it and continues. `ExerciseDraftValues.pageBlocks`,
  `ExerciseDraftBuilder._buildPage` (every block gets role `block`; a new
  Page starts with an empty heading and paragraph,
  `ExerciseDraftBuilder.pageStarterBlocks`), `PresetRecipes` (`kinds`,
  decompose, rebuild, represents), `PresetVariants` (`ownForms`, `fits`).
- `lib/widgets/page_block_editor.dart`, `PageBlockEditor`: Add block
  (Heading, Paragraph, Quote or example, List, Picture, Audio, Video link),
  move up and down, remove; per text block the style, a Bold and an Italic
  button that wrap the selection in `**` or `*`, the alignment (justify for
  paragraphs and quotes), the palette swatches, Read aloud and its
  language; per picture the compact `ExerciseImageField` (copied into the
  Course's media, with its Shared Image Library source), size, alignment
  and caption; the spoken text of an audio block (never required); the
  label and address of a video link, flagged until it is an https
  address; a live preview drawn by `PageCardView`. Keys `page-block-*`,
  `page-add-block`, `page-live-preview`.
- The exercise editor shows it for `page` (no single picture field), keeps
  the blocks in `_pageBlocks` (snapshot, navigation, candidate) and names a
  Page in the Round's list by its first text block.
- Field Help: every block field has the `blocks` Help control
  (`ExerciseAuthoringField.pageBlocks`). Search: text and audio blocks.
  Help EN/IT/ES: the preset, the field and the Editor Help question
  `pageCards` in Exercises (68 questions).
- Tests: new `test/page_form_258_test.dart`; pins for 44 presets, 68 Help
  questions, the Piedmontese Lesson count, the mascot and kind tables, the
  field Help tables; the Laboratory's preset coverage excludes `page` until
  its example arrives in Revision 3.

## Revision 1 (2.0.58+258001, 29 September 2026): Course pictures up to 300 KB

Owner decision Q3 (plan 2.6): larger pictures, with a limit, for every
Course picture.

- `lib/services/import/image_validator.dart`: `ImageProfile.courseImageMaxBytes`
  (300 KB) behind `ImageProfile.exerciseImage` (Course media, the Shared
  Image Library, Image Banks); the new `ImageProfile.portableImage` (50 KB)
  for pictures embedded in `course.json` as `data:` URIs.
- `CourseMediaStore.maxImageBytes`, `ExerciseImageService.maxImageBytes` and
  `ImageBankService.maxImageBytes` read the one constant, so every path that
  shares them follows: adding a Course picture, the Shared Image Library,
  Image Bank import, package export and import, backups, Fork, Copy and
  Merge, and the avatar pictures `CourseCoverService.storeAvatar` shrinks.
- `PortableExerciseImageService.fromBytes` and the embedded-image check of
  `CustomCourseTransferService.courseFromBytes` validate with
  `portableImage`: Recognize characters' pictures keep 50 KB. The cover
  keeps its 1 MB (`ImageProfile.courseCover`).
- Help EN/IT/ES (the picture field, picture import, Image Bank limits), the
  field Help and the Shared Image Library's too-large message say 300 KB;
  Recognize characters' Help keeps 50 KB.
- Tests: new `test/picture_limit_258_test.dart`; four tests updated for the
  new number (`course_cover_255_test`'s large test picture now has 220
  noisy rows so it still exceeds the ordinary limit;
  `exercise_field_help_226_02_test`, `file_dialogs_240_features_test`,
  `image_bank_service_test`).

## Revision 0 (2.0.58+258000, 29 September 2026): the Page model and its learner display

No new primitive: a Page is a `presentation` exercise whose prompt elements
have role `block`, drawn block by block, never scored (plan 2.1).

### Model

- Element vocabularies in `lib/models/exercise_canonical.dart`:
  `BlockTextStyle` (heading1, heading2, paragraph, quote, bulleted,
  numbered), `BlockAlign` (start, center, end, justify), `BlockColor`
  (default, accent, red, green, blue, grey) and `BlockSize` (small, medium,
  large, full); `pageElementAttributeTypes` is the one table of which
  element types each attribute applies to.
- `PromptElement` gains `textStyle`, `align`, `color`, `size`, `readAloud`
  and `url`, and the element type `link` (`isLink`). Parsing is strict: an
  attribute on the wrong element type, `justify` on a picture or a link, or
  a value outside the vocabulary is a `FormatException`. Absent attributes
  are omitted from JSON.
- `ExerciseFeatures.pageBlocks` and `LearnerExerciseKind.page`;
  `illustrationImages` no longer counts a Page's pictures (the Page draws
  them among its blocks).
- `docs/capabilities_v12.json` gains `elementAttributes`; the Python tools
  read it (`tools/qql_capabilities.py` `ELEMENT_ATTRIBUTES`) and
  `tools/validate_courses.py` checks the attributes and that links are
  https addresses.

### Rules

- `lib/services/inline_marks.dart`: `**bold**` and `*italic*` in body text
  (paragraphs, quotes, lists; headings are drawn as typed). A mark opens
  before a non-space and closes after one, so `2 * 3` stays as typed; an
  unmatched mark shows as typed; `\*` always shows a star. No Markdown or
  HTML dependency.
- `lib/services/page_blocks.dart`: `PageBlocks.minimumAppBuild` (258000),
  `isAcceptableLink` (an https address with a host), `hasContent`,
  `courseHasPages` and `withMinimumAppBuild`, which the Course confirmation
  (`CourseEditorService._confirmCourseTransactionLocked`) applies: a Course
  that contains a Page records `minimumAppBuild: 258000` when saved (never
  lowered), so an earlier build refuses it instead of losing its formatting
  (owner decision Q9).

### Learner display

- `lib/widgets/page_card.dart`, `PageCardView`: headings, paragraphs,
  quotes (a side rule, italic) and bulleted or numbered lists with inline
  marks, alignment (start and end follow the text direction; justify for
  body text) and the named palette (`colorOf`: each name has a light and a
  dark shade with enough contrast); pictures at a share of the width
  (small 35 %, medium 60 %, large 85 %, full) with alignment and caption;
  audio blocks as Listen buttons; links as buttons that are enabled only
  for https addresses; a read-aloud button on text blocks that ask for it.
- `RoundScreen`: `_pageExercise` (Continue `page-continue`), no heading and
  no instruction line, never skipped when audio is off (read-aloud and
  audio buttons then hidden), `_speakBlock` (the block's text without its
  marks, in the block's language, recordings or TTS as the Course's audio
  mode says), `_openPageLink` through the test seam `RoundScreen.openLink`
  (the browser; the app never downloads or plays video itself).

### Audit (113 rules)

- `PAGE_EMPTY` (Error): no block shows anything.
- `PAGE_MARK_UNMATCHED` (Warning): a bold or italic mark without its
  partner.
- `PAGE_LINK_INVALID` (Error): a link that is not an https address.
- `PROMPT_MEDIA_UNSUPPORTED` accepts a `link` only as a Page block.
- `kindLabel` "a Page".

### Found in passing

- The Generic Primitive Editor rebuilt prompt elements field by field and
  dropped every attribute its rows have no field for: the Page attributes
  and, already before this build, a Dialogue line's `speakerId`. Its rows
  now keep them (`_ElementRow._with`); a test proves both.

### Re-sequenced

The 300 KB Course picture limit (plan 2.6) moves to Revision 1: it touches
the media store, the image validator profiles, the Shared Image Library,
Image Banks, packages and about a dozen tests, independently of Pages.

### Not yet

The Page preset form (Revision 2), video links in the form and the
Laboratory Page example (Revision 3), share, save, email and print
(Revision 4, after Q10). Until Revision 2 a Page is authored in the Generic
Primitive Editor or in Course JSON.

### Unchanged

Scoring, progression, Review, the Duel, learner data, Course Model v12 and
package format 1.

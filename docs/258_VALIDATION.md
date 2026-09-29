# Build 258 validation

Evidence for each Build 258 revision. Process: `docs/256_HANDOFF.md`
("Requirements and process").

## Revision 2 (2.0.58+258002, 29 September 2026): the Page form

- New: `test/page_form_258_test.dart` (5): the preset's registration,
  Help and Search; represent, decompose and rebuild; the starter heading
  and paragraph; the form (text, the Bold button wrapping a selection,
  center alignment, the red swatch, the live preview, a video link refused
  as http and accepted as https, moving a block, saving); a stored Page
  opening all its blocks read-only.
- Focused batch (24 files incl. the Laboratory, the field-Help tables,
  preset and Help pins): 631 passed, 1 failed (the field-Help UI test found
  two block fields both labelled Text); headings are labelled Heading text
  and lists Items, one per line; rerun 59 passed.
- `flutter analyze --no-pub`: no issues.
- Complete suite (20:37–21:06, `--concurrency=1`, keep-awake wrapper):
  **3328 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.58+258001, 29 September 2026): Course pictures up to 300 KB

- New: `test/picture_limit_258_test.dart` (4): the one 300 KB constant and
  the 50 KB `data:` profile; a 180 KB PNG stored as Course media; a 400 KB
  PNG refused by the store and the validator; the 180 KB PNG refused as an
  embedded `data:` picture.
- The 13 test files that name the old limit ran first: 190 passed, 4
  failed on the old number (a test cover no longer over the limit, the
  field Help text, the too-large message, the Image Bank constant); updated
  and rerun: 69 passed.
- `flutter analyze --no-pub`: no issues; focused 121 passed.
- Complete suite (19:53–20:21, `--concurrency=1`, keep-awake wrapper):
  **3322 passed, 1 skipped, 0 failed**.

## Revision 0 (2.0.58+258000, 29 September 2026): Page model and learner display

### Generated data and tools

- `dart run tools/export_capabilities.dart`: `docs/capabilities_v12.json`
  gains `elementAttributes` (pinned by `capability_description_256_test`).
- `python tools/validate_courses.py` (now checking element attributes and
  https links) and the three generators' `--check`: see Results.

### Tests

- New: `test/page_card_258_test.dart` (11 tests): element attributes
  through JSON and strict refusals; inline marks (bold, italic, both,
  escapes, stars that mark nothing, unmatched marks); the three Audit codes
  and headings without marks; a Page is playable, never Laurel-eligible;
  `minimumAppBuild` raised, never lowered, untouched without a Page;
  `PageCardView` (styles, marks, justify, palette colour, numbered list,
  picture width share, read-aloud, enabled and disabled links; palette
  shades differ between themes); the Round screen in Preview (no heading
  or instruction, link through the seam, Continue, Finish round) and with
  Audio Exercises off (still shown, buttons hidden); the Generic Primitive
  Editor keeping Page attributes and a Dialogue line's `speakerId`.
- Updated: Audit rule counts 110 → 113 (`audit_code_registry_226_02_test`:
  62 Errors, 44 Warnings; `audit_branch_ownership_226_02_revision4_test`);
  version pins 2.0.58+258000 / Build 258, Revision 0.

### Results

- Focused: `page_card_258_test` 11 passed; with the Audit, capability and
  version-pin tests 57 passed after the fixes (a `link` block was refused
  by `PROMPT_MEDIA_UNSUPPORTED`; the version bump made build 258000 valid;
  the last card waits for Finish round).
- `flutter analyze --no-pub`: no issues. Generators' `--check` and
  `tools/validate_courses.py` pass; the validator's new checks reported
  exactly the four bad attributes of a sample Page and nothing else.
- Complete suite (17:51–18:22, `--concurrency=1`, keep-awake wrapper):
  **3318 passed, 1 skipped, 0 failed**.

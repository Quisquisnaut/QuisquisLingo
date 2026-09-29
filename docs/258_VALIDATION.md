# Build 258 validation

Evidence for each Build 258 revision. Process: `docs/256_HANDOFF.md`
("Requirements and process").

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

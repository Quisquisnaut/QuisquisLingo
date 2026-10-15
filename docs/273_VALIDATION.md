# Build 273 validation

## Revision 0 (2.0.73+273000), the Story cast owner

15 October 2026, owner's Windows 10 PC, `build-273` from `main` `38016ab8`.

- Characterization: the Course Editor's Story characters were already
  driven by `test/story_editor_256_test.dart` (the narrator and the
  characters listed with their summary; a character still speaking is not
  removed and the message counts its lines; an unused one is removed and
  the tile's count follows; Add character; the narrator renamed; the
  default narrator saved unchanged changes nothing, a renamed one is a
  change) and `test/story_add_step_256_test.dart`; both files pass after
  the change.
- New tests: `test/story_cast_273_test.dart`, **12 passed**: `describe`;
  `summaryOf` (named and unnamed narrator, one and several characters);
  `linesSpokenBy` across Lessons and Rounds, the narrator's lines; the
  refusal in the singular and the plural; `replacing` and `without` keep
  the order; `withSpeakers`: the default narrator saved unchanged is not
  stored, a stored narrator stays stored (also equal to the default), a
  stored narrator of its own saved unchanged changes nothing, a changed one
  is stored, characters in order and none leaves no key, each credit once
  after the Course's own, everything else of the Course kept.
- Independent review (a fresh read-only agent, before the suite): no
  behaviour difference; the moved bodies compared with the old ones
  (whitespace-insensitive diff, bytes of the middle dot and quotes), every
  call site reads the same Course object as before, no removed name still
  used, the version bump and every date of `test/beta_lifecycle_test.dart`
  checked. Acted on: one sentence of the change summary made exact, one
  test case added (a stored narrator of its own saved unchanged).
- `flutter analyze`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`): **4,691
  passed, 1 skipped, 0 failed**, 61 minutes (the PC was slow with two
  browsers open).

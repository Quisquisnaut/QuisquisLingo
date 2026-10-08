# Build 266 handoff

Saved 8 October 2026, 02:34. **Revision 0 (2.0.66+266000) is complete in
the worktree `C:\QQL\QuisquisLingo\.claude\worktrees\dazzling-hawking-a3ca2e`,
branch `claude/266-guidebook-modules` (from main `5cfb227`), and waits for
the owner's word to be committed locally. Never push or open a pull request
without the owner's word.** About 115 paths change (103 tracked files, the
rest new).

Plan: `docs/266_GUIDEBOOK_MODULES_PLAN.md` (copied from the main checkout,
where it is untracked, and amended with the decisions of 8 October; it is
committed with Revision 0). Build 267's plan (`docs/267_COURSE_WIZARD_PLAN.md`)
is context only. Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`,
`docs/COLLOCATION_PICTURES_PROPOSAL.*`, `docs/267_COURSE_WIZARD_PLAN.md`;
after `flutter pub get` the four generated plugin registrant files (and
`docs/254_LABORATORY_COVERAGE.md` after the Lab generator) may show as
modified with line endings only: `git diff --quiet` proves it, restore them.

Summary: `docs/266_CHANGE_SUMMARY.md`; evidence: `docs/266_VALIDATION.md`.

## Owner decisions of 8 October 2026

- Prefill (Revision 1): skip Lesson icons; skip one-letter names (Roman
  numerals I, V, X; units g, l, m); when no name equals the word, try the
  name before a bracket ("baker" → Baker (man)/(woman), 2 matching). Exact
  names first: "father" = the Father scene. Catalogue facts checked on
  4,334 records: 23 non-character names have two pictures (5 of them with a
  Lesson icon: Train, School, Hotel, Family, Shopping); 151 names exist only
  with a bracket.
- v11 converter: an example sentence (no translation) becomes a line of
  the module's Overview, with a note; Source stays required.
- Revision 0 is split: 266000 core (done), 266001 authoring aids, 266002
  Round Wizard, 266003 content. **The complete suite runs once, at the
  end of 266001**; 266000 had the analyzer and focused tests.

## Revision 0 (done, uncommitted)

See the change summary. Key files: `lib/models/course_models.dart`
(GuideBook classes, Round fields), `lib/models/guidebook_text.dart`,
`lib/screens/guidebook_editor_screen.dart`, `lib/screens/guidebook_screen.dart`,
`lib/services/guidebook_round_links.dart`,
`lib/widgets/guidebook_picture_thumbnail.dart`, the readers listed in the
summary, `tools/qql_course_v12.py`, `tools/validate_courses.py`, the three
generators, `test/guidebook_modules_266_test.dart`,
`test/support/guidebook_fixtures.dart`, `test/support/guidebook_editor_driver.dart`.

One-off scripts kept in the session scratchpad (not in the repo):
`rewrite_fixtures_266.py` (Korean, Italian demo JSON + ZIP, unsigned
Publisher copies), `sign_dummies.sh` (prepare, OpenSSL, attach). To sign the
dummy fixtures again: remove `publisherSignature`, `dart run
tools/sign_course.dart prepare IN dummy-1 payload.bin`, `openssl pkeyutl
-sign -rawin -inkey test/fixtures/publishers/dummy-private.pem -in
payload.bin -out sig.bin`, `attach IN dummy-1 sig.bin
test/fixtures/publishers/dummy-public.der OUT`; the media ZIP with
`package OUT MEDIA_DIR dummy-public.der OUT.zip` (MEDIA_DIR holds the MP3
from the old ZIP). `dummy-unsigned.json` = v1 without the signature.

## Next: Revision 1 (2.0.66+266001), the authoring aids

- `GuidebookPictureMatch` (pure Dart) over `ExerciseImageMetadataService`'s
  QQL catalog: exact name (capitals and a leading a/an/the ignored), else
  the singular (`imageTagKey`, marked Plural, "Suggested, plural"), else
  the name before a bracket; skip `characters` group, `lesson_icons`,
  one-letter names. Target side when the target is English, Source side when
  the source is English. One match fills with "Suggested"
  (`…-word-<i>-picture-suggested`), several show "N matching pictures"
  (`…-word-<i>-picture-matches`, opens the library searched: add
  `initialSearch` to `FlatImageLibraryScreen`). Only on typing (leaving the
  box), Paste list or Fill, only into an empty row; a removed picture stays
  removed until the word changes; the mark lasts for the session.
- Paste list (`guidebook-module-paste-sentences`/`-words`, `target = source
  [context]` lines via `GuidebookVocabulary.parse`, names unread lines),
  Fill with an example (`GuidebookModuleSample`, Italian/English, with
  il conto twice, {io}, il caffè with coffee.webp, i gatti Plural with
  cat.webp; `guidebook-module-fill-example(-confirm)`), Clear all
  (`guidebook-module-clear-all(-confirm)`), the Overview counter and the
  500-character hint, tooltips on Target/Source/Context/{…}/Paste list/the
  counter, examples in the helpers, field Help (EN/IT/ES, in the Help
  Language: the exercise forms' dialogs are English only), the two new
  Editor Help questions ("How do I write GuideBook entries?", "How long
  should a module be?": the count pin in `test/editor_help_qa_256_test.dart`
  and `test/editor_help_translation_test.dart` goes 84 → 86).
- Then the complete suite (`--concurrency=1`, ~40 minutes; check 3 GB of
  free memory first; empty `D:\QQL_test_temp`).

## Open, not this session's

- The owner's Windows Narrator check of Word Lookup (Build 265).
- The owner's stored test Courses with GuideBooks show as unreadable in
  Course Studio since this revision; the private generators in
  `D:\QQL_plus\Corsi_Privati` must write the module shape.

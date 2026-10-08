# Build 266 handoff

Saved 8 October 2026. **Build 266 is complete and committed locally**:
Revisions 0 (`50512d2`), 1 (`f6891bf`), 2 (`16bc9ff`) and 3 in the worktree
`C:\QQL\QuisquisLingo\.claude\worktrees\dazzling-hawking-a3ca2e`, branch
`claude/266-guidebook-modules` (from main `5cfb227`). Revision 4 (content)
moved to Build 267 (owner, 8 October 2026). Never push or open a pull
request without the owner's word. After the merge to main, the owner's
private generators in `D:\QQL_plus\Corsi_Privati` must be run again: their
four Course files still have the GuideBook shape before Build 266
(`make_short_courses.py` converts through the main checkout's
`tools/qql_course_v12.py`).

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

## Revision 0 (committed, `50512d2`)

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

## Revision 1 (2.0.66+266001, committed)

Every file and key is in the change summary's Revision 1 section; the
evidence in the validation's. In short: `GuidebookPictureIndex`
(`lib/services/guidebook_picture_match.dart`) and the prefill on the module
page, `chooseLibraryPicture` and `FlatImageLibraryScreen(initialSearch:)`,
`GuidebookPasteList`, `GuidebookModuleSample`, Clear all, the Overview
counter (`GuidebookText.longOverviewLength`, shared with the Audit),
tooltips, field Help (`guidebookHelp.field.*` EN/IT/ES), Editor Help
`guidebookEntries` and `moduleLength` (86 questions). Folded in on
8 October (owner's yes): the library opened from a word is searched for its
English side (only in Courses to or from English), and the fix of the reset
buttons (`AppResetService._storedCustomCourses`, `admin-reset-preview-error`;
`test/reset_unreadable_course_266_test.dart`). Version 2.0.66+266001.

Checks: the complete suite twice (3,902 passed, then 3,910 passed after
the two additions; 1 skipped, POSIX only), the analyzer clean. Committed
on the owner's word ("yes to all"; "at the end, commit and start next
revision immediately", 8 October).

## Revision 2 (2.0.66+266002), resilience: committed

Everything planned is in (see the change summary's Revision 2 section):
`StoredCourseReader`, removal and replacement of a Course this version cannot
open (Course Studio's Remove…, the import's Replace, the Publisher update),
the Maintainer rule from the JSON in learner deletion and the resets,
`runReported` on the silent buttons, `CrashLogService.recordUnhandled`,
Save&Open (`FolderOpener`), the Inventory's Delete / Forget / Open folder
(`InventoryActionService`, `AdminPinGate`), Help EN/IT/ES, the edge-case
tests. Version 2.0.66+266002, docs updated. Complete suite 3,924 passed,
1 skipped (POSIX only); committed, then Revision 3 started at once (owner:
"at the end, commit and start next revision immediately").

Not done, noted for later: Android's public Quick folders have no Inventory
actions (their files have no path); a Publisher update over an unopenable
source has no test (it needs a signed package).

## Revision 3 (2.0.66+266003), the Round Wizard: committed

See the change summary's Revision 3 section. The generator is rewritten on
modules (`plan(focusModuleId:)`, `changeFocus`, `wordsOf`, `_Material`,
`_Slot`), the screen has the Focus module menu and the per-Round focus and
words, Help EN/IT/ES. Version 2.0.66+266003. Complete suite 3,939 passed,
1 skipped (POSIX only); committed. Build 266 is complete: nothing is pushed
and no pull request is open until the owner says so.

## Revision 4: moved to Build 267 (owner, 8 October 2026)

The owner asked why Revision 4 was needed (it is demo and test content,
not a feature) and chose option 3: skip it for now and do the demo content
in Build 267, whose plan builds a new Italian demo with the Course Wizard.
Build 266 ends with Revision 3. For Build 267, the content planned here
(plan §11):

- QQL Demo: English from Italian in modules matching its topics (for
  example Saluti e cortesia, Al bar: cibo e bevande, Animali, Colori e
  aggettivi, Alla stazione), the four grammar notes as short module
  Overviews, Sentences with translations and Contexts, word pictures by the
  prefill rule (a Python matcher mirroring `GuidebookPictureIndex` is
  drafted in this session's scratchpad: exact name, singular marked
  Plural, name before a bracket; never characters, Lesson icons, one-letter
  names), each Round's `focusModuleId` (the mixed Rounds take the module
  whose words they use most; the two Stories their topic). Its Review
  vocabulary memory restarts when the entries change.
- The Lab: one Lesson with two modules, a word with two senses, `{…}`, at
  least three pictured words in one module.
- The Edge Case: two modules, an empty module and a long Overview (the
  Warning and the Info on purpose), a Draft GuideBook, `sourceRefs` to
  entries, a Round whose focus is missing (the Warning on purpose).

## Open, not this session's

- The owner's Windows Narrator check of Word Lookup (Build 265).
- The owner's stored test Courses with GuideBooks show as unreadable in
  Course Studio since this revision; the private generators in
  `D:\QQL_plus\Corsi_Privati` must write the module shape.

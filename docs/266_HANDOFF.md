# Build 266 handoff

Saved 8 October 2026. **Revisions 0 and 1 are committed locally**
(`50512d2`, then Revision 1) in the worktree
`C:\QQL\QuisquisLingo\.claude\worktrees\dazzling-hawking-a3ca2e`, branch
`claude/266-guidebook-modules` (from main `5cfb227`). **Revision 2
(2.0.66+266002), resilience, is in progress** (owner: "at the end, commit
and start next revision immediately"). Never push or open a pull request
without the owner's word.

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

## Next: Revision 2 (2.0.66+266002), resilience (owner decisions of 8 October 2026)

Owner, 8 October: "Fix same class"; "test extensively edge cases"; the
Diagnostic Log must record what happened; Save&Open for both logs; Inventory
Delete / Forget / Open folder ("yes to all": confirm + admin PIN, the same
rules as elsewhere, its own revision); "go on with what we already decided
and make it a revision".

1. One reader for stored Courses that cannot be opened.
   - `StoredCourseReader` (pure): opens a stored entry; any parse failure
     (FormatException, TypeError, ArgumentError, StateError), not only
     FormatException, means unopenable, with the reason; reads the raw
     Maintainer, title and Course ID from the JSON when the Course cannot be
     opened. Used by `CourseEditorService.listUserCourses`,
     `AppResetService._storedCustomCourses`, `CourseMaintainerGuard`.
   - CourseMaintainerGuard (audit 1): an earlier-shape Course no longer
     blocks deleting every learner; a learner who maintains one (raw
     Maintainer) is refused with its title, as the bulk reset now refuses
     too (the reset reads the raw Maintainer the same way). Error text without
     "FormatException:".
   - Same-ID import over an unopenable stored Course (audit 2): offered as
     Replace when the importer is its raw Maintainer (or an admin); the
     stored file is replaced, the media of the failed attempt are not left
     behind. Publisher update over an unopenable stored source: replace.
   - Course Studio's unreadable-Courses card names the file (not the ID) and
     says where to remove it (Inventory).
2. Buttons that fail silently (audit 3–11): a shared guard
   (`runReported`: catch, Diagnostic Log entry, SnackBar) on Version History
   Open backup folder, Course Info open/save, the Home Course picker, Team
   Manager reloads, Export as Publisher Course, the Audit buttons, Manage
   learners / Learner Profiles / promote admin, Shared Images delete and
   remove bank, User Data reset, Gamification load. Version History wording
   for pre-266 backups ("made by an earlier version in a shape this version
   cannot open").
3. Logs.
   - Every unhandled error (zone, FlutterError, PlatformDispatcher) also gets
     a short Diagnostic Log entry (APP-001, where, the error, "full stack in
     the Crash Log").
   - An unopenable stored Course is logged once per session per file
     (COURSE-002: file name, Course ID/title when readable, the reason).
   - The guarded buttons log what they caught.
   - Debug screen: **Save&Open** (owner's name) under each log's Quick Export
     and Save icons, Windows/macOS/Linux only: writes a fresh copy to
     `Documents/QuisquisLingo/Logs` (Quick Export) and opens that folder.
     Test seam for the folder opener.
4. Inventory actions (confirm + admin PIN; existing rules):
   - Learners: Delete (ProfileService.deleteProfileById rules).
   - Course Favorites, Received Custom Courses, Remembered publishers:
     Forget (the one preference key).
   - Custom and installed courses: Delete (CourseEditorService delete /
     Publisher remove; an unopenable file: delete the file, raw Maintainer or
     admin) + Open folder.
   - Crash Log: Open folder (no delete of the live file; the Debug screen
     has Save&Open).
   - Export, Import, ToBeMerged, Logs, Backups, earlier folders, private
     earlier folders, Import staging, Other files: Delete file + Open folder.
   - Imported images: Delete through the Shared Image Library rule (record
     and file) + Open folder.
   - Image banks: Remove bank (ImageBankService.removeBank) + Open folder.
   - Course media: Delete only in a folder no stored Course uses; Open folder.
   - Android: no Open folder; public files deleted through the storage
     bridge where it allows.
   - Every new key and folder is already in AppResetService and the reset
     inventory doc; nothing new is persisted.
5. Edge-case tests: stored Course files in the earlier GuideBook shape,
   broken JSON, empty, no Course ID, two files with one ID, an unsupported
   formatVersion, a field of the wrong type; every reader (Course Studio,
   All Courses, Home picker, Inventory, each reset, delete learner, import
   with the same ID, Version History) keeps working, names the problem and
   lets an admin remove the file.

Version 2.0.66+266002 (same day: expiry unchanged unless the release day
changes); complete suite at the end.

## Then: Revision 3 (2.0.66+266003), the Round Wizard; Revision 4 (266004), content

Plan §7 and §11. The Course Wizard stays Build 267
(`docs/267_COURSE_WIZARD_PLAN.md`, owner: leave it as it is).

## Open, not this session's

- The owner's Windows Narrator check of Word Lookup (Build 265).
- The owner's stored test Courses with GuideBooks show as unreadable in
  Course Studio since this revision; the private generators in
  `D:\QQL_plus\Corsi_Privati` must write the module shape.

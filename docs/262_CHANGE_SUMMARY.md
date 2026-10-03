# Build 262 change summary

Owner decisions of 2 October 2026 in `docs/PUBLISHER_COURSES_PLAN.md`,
which sets aside the Build 262 draft `docs/262_BUNDLED_AUTHORING_PLAN.md`
(editing bundled Courses as author). On 3 October 2026 the owner chose
three parts of it for Build 262:

- Revision 0: 4.1, the Piedmontese Courses leave the app and the public
  repository; their material goes to the owner's private folder
  `D:\QQL_plus\Corsi_Privati`.
- Revision 1: 4.2, the publisher QuisquisLingo Courses in the trusted
  publisher registry, prepared with a test key only (the owner has not
  created the real key yet).
- Revision 2: 4.3, Export as Publisher Course in Course Studio.

Not in Build 262: 4.4 signing in the app, 4.5 Publisher ZIPs shipped in the
app, the documents of 4.6 beyond what each part needs, and the owner's
tasks outside the code.

## Revision 2 (2.0.62+262002, 3 October 2026): Export as Publisher Course

**The action.** Course Studio's menu of a custom Course gains **Export as
Publisher Course** (`CourseManagerAction.exportAsPublisherCourse`, after
Export Course), greyed for a profile that neither maintains the Course nor
belongs to its assigned Team ("Only the Maintainer or assigned Team can
publish this Course."). It never appears on an official Course.

**The page** (`PublisherCourseExportScreen`,
`lib/screens/publisher_course_export_screen.dart`): the publisher to export
for (`publisher-export-publisher`; `PublisherCourseExport.publishers()`:
one entry per publisher of the app's registry, revoked keys left out, plus
QuisquisLingo Courses even while its key is pending, with a line saying so),
the official version, Quick Export (`publisher-export-quick`, into
`Export/Courses`) and Save as… (`publisher-export-save-as`), and four notes:
the file is not signed (sign it with `tools/sign_course.dart`, guide §7);
what changes; how to update; the same Course ID cannot be installed beside
the author's own Course. When something stands in the way, a card
(`publisher-export-refusals`) names every reason and the buttons stay off.

**The rules** (`PublisherCourseExport`, `lib/services/publisher_course_export.dart`):
- Refused (`refusals`): not a custom Course; no Maintainer or Team access;
  a Fork or a merged Course (their lineage cannot be carried by a Publisher
  Course); no Course version yet; not published; Draft content; no License;
  Audit errors.
- Built (`build`): `externalOfficial`, every ID kept (Course, Lessons,
  Rounds, content, items); the chosen publisher's ID and name, and the
  publisher as Original Course Creator; **the official version is the Course
  version** (owner decision of 3 October 2026: it rises at every confirmed
  save, so every export after a change is a valid update); release date now,
  release notes from the Course's version notes, distribution channel
  `publisher`; no Maintainer, Team, Course version, version notes or Last
  Version Editor; not private; unverified, unsigned, with its official
  checksum. Authors, Rights Holders, License and all content stay. The
  stored Course is never changed.
- Written (`CourseLibraryOperations.exportAsPublisherCourse` /
  `savePublisherCourseTo`): the ordinary Course package (format 1:
  `course.json`, manifest, the Course's own media), so unzipping it gives
  exactly what `tools/sign_course.dart prepare` and `package` take. File name
  `QQL_<pair>_<title>_publisher_v<version>.zip`
  (`CourseStorageNames.exportBaseName(publisherVersion:)`). A refused Course
  throws and writes nothing.

**Help** EN/IT/ES: Course Studio Help section **Export as Publisher Course**
(`exportAsPublisherCourse`, after Export a custom course). Publisher
signing Help (EN/IT/ES) and `docs/PUBLISHER_SIGNING_GUIDE.md`, which must
equal the English Help: the status names the QuisquisLingo Courses entry of
Revision 1, section 7 says where the starting JSON comes from, and signing
inside QQL is not implemented yet.

Signing in the app (4.4) and Publisher ZIPs shipped with the app (4.5) are
not in Build 262. Learners, scoring and stored data are unchanged.

## Revision 1 (2.0.62+262001, 3 October 2026): the publisher QuisquisLingo Courses

**The registry entry.** `TrustedPublishers.quisquisLingoCourses`
(`lib/services/trusted_publishers.dart`) describes the publisher of the
owner's own Courses, separate from the app (whose bundled Courses keep
`org.quisquislingo`): publisher ID `com.quisquislingo`, name
**QuisquisLingo Courses**, key ID `qqlc-2026-1`. Its public key,
`quisquisLingoCoursesPublicKeyBase64`, is empty: the owner has not created
the key yet (plan §5.1, guide §2). `TrustedPublishers.application()` adds
the entry only once that value is set, so until then the app trusts no key
for this publisher and refuses its Courses as signed by an unknown key.
Adding the real key is one line: the Base64 of its 32 public-key bytes
(guide §6).

**Tests with a TEST ONLY key.** `test/quisquislingo_courses_publisher_262_test.dart`
trusts a deterministic Ed25519 test key under the same publisher, name and
key ID, as guide §6 asks for an approved key: a Course signed by it
verifies, imports and installs as a Publisher Course; an altered Course
(even with a recalculated checksum), an unsigned one, one signed by another
key or under another key ID, and one naming another publisher name or ID
are refused. While the key is pending, the app's own registry refuses the
signed Course; the test adapts by itself once the real key is in.
`test/support/publisher_fixtures.dart` gains `signWithKey` and
`dummyKeyPair`, with `signFixture` unchanged on top of them.

Nothing else changes: no new publisher can be chosen anywhere yet (that is
Revision 2), learners, scoring and stored data are unchanged.

## Revision 0 (2.0.62+262000, 3 October 2026): the Piedmontese Courses leave

**Two bundled Courses.** `CourseService.courseAssets` keeps `IT` (QQL Demo:
Exercise Laboratory) and `EN_IT` (QQL Demo: English from Italian). `PMS`
(QQL Demo: Piedmontese (sorted by exercise type)) and `PMS_MIX` (QQL Demo:
Piedmontese) are gone, with their `targetLabels`, `sourceLabels` and the
`PMS_MIX` entry of `_additionalBundledCodes`. Their Course IDs stay reserved
in `CourseEditorService` (`course_e5f5585a-…`, `course_69ff369e-…`), as for
the demos removed in Builds 254–259: a custom Course can never take them. A
learner's progress on these Courses stays on the device without a Course,
as before for the other removed demos.

**Out of the repository** (to `D:\QQL_plus\Corsi_Privati`, never
committed): `assets/courses/piedmontais_en.json`,
`assets/courses/piedmontese_mixed_en.json`,
`tools/generate_piedmontais_demo_254.py`,
`tools/generate_piedmontese_mixed_259.py`,
`test/piedmontais_course_254_test.dart`,
`test/piedmontese_mixed_259_test.dart`,
`test/fixtures/v11/piedmontais_en.json` (the v11 original used by two
conversion tests) and `docs/254_PIEDMONTAIS_COVERAGE.md`. The git history
is not rewritten: the old commits keep them.

**For the owner, outside the repository:** the two Courses as custom
Courses ready to import (`custom/` there), made by
`make_custom_courses.py` from the last bundled files: a new Course ID each
(the bundled ones are reserved), every Lesson, Round and exercise ID kept,
no publisher provenance, Course version 1, title, content, license and
rights unchanged. Their Maintainer and Original Course Creator is the
owner's profile Tempesta 35932 (owner's choice of 3 October 2026), so the
owner can edit them and, after Revision 2, export them as Publisher
Courses; `--maintainer <Internal ID> --name <name>` regenerates them for
another profile. Both import through the
app's own custom import with no Audit error (one expected warning in the
first). `LEGGIMI.txt` there explains the folder.

**The English from Italian generator** imported twelve Content builders
(`text`, `audio`, `turn`, `image`, `choose`, `enter`, `arrange`, `gaps`,
`match`, `flashcard`, `picture_card`, `note`) from the Piedmontese
generator. They moved unchanged to `tools/qql_v11_builders.py`; the
generator's `--check` reproduces its Course byte for byte.

**Kept on purpose:** the Piedmontese language (language catalog, language
names, the World Flag and its language association, storage name codes) and
`readme/readme-pms.txt`, the Windows guide translated into Piedmontese
(not Course content). Historical documents (CHANGELOG, earlier
`docs/25x`–`261` files, the AGENTS.md release boundary) still describe
what those builds shipped.

**Other references cleaned:** `tools/validate_courses.py` (two bundled
files), the README's current description, the credits card "English from
Italian / Edge Case courses" (it named Korean and Piedmontese, neither
shipped now), `test/fixtures/v11/README.md`.

**Tests** that used a Piedmontese Course as an example of a bundled Course
(a World Flag, derivative works forbidden, a second Course to switch to, a
Favorite to hide) now use QQL Demo: English from Italian or the Exercise
Laboratory; tests of Piedmontese content alone left with the Courses.

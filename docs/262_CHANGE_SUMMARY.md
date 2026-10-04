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

Revision 3 answers an owner request of the same evening about the learner
path.

## Revision 3 (2.0.62+262003, 3 October 2026): a path shape for each Lesson

**Why.** The owner noticed that the path had the same course in every
Lesson and every Course. The Round circles follow one 16-step pattern of
places (left edge, centre with texts right, centre with texts left, right
edge; Build 261 Revision 8), and every Lesson entered it at its first step,
so every Lesson of six Rounds drew the same zigzag, whatever the Course.
The owner first asked to fix the private Courses' generator; asked which
course was meant, they chose the zigzag of the circles, which the app
draws: no Course content decides it.

**The change.** Each Lesson enters the pattern at its own place:
`learnerRoundPlacement(index, start:)` and
`learnerRoundPlacementStart(courseId, lessonIndex)` in
`lib/screens/home_screen.dart`. `learnerRoundPlacementStarts` holds eight
starts, giving eight different shapes of six Rounds. The Course ID (the seed
the mascot order already uses) picks the first Lesson's start and each next
Lesson moves three places along the list: neighbouring Lessons never share a
shape, their first texts change side, and the first Lesson's shape differs
from Course to Course. Nothing is stored; reordering Lessons reorders the
shapes.

**Which starts.** Every start opens at the centre, its texts on the right or
on the left. A scan of all candidate starts found that a first circle at the
left edge is reached cleanly from the Lesson circle but not from the IDDQD
pill, whose line comes down at the centre and crossed the first Round's
label; those four starts are left out. The pattern also wraps around
without an edge-to-edge jump, so long Lessons stay clear.

**Mascots.** Whether a Round has a mascot depends on its neighbour's side,
so `learnerRoundPathSide`, `learnerRoundPathMascotRows`,
`learnerRoundPathShowsMascot` and `learnerRoundPathMascotSlotCount` take the
Lesson's start, and `learnerMascotPositionOffsetForLesson` takes the Course
ID to count each earlier Lesson's mascots with its own start; the mascot
order still runs on across the Course. `LearnerRoundPath` computes the start
from the `courseId` and `lessonIndex` it already had, on the learner page
and in the Course preview.

**Tests.** `test/learner_round_path_test.dart`: every start against line and
text crossings from the Lesson circle and from the IDDQD pill at five
widths; eight starts, eight shapes, each opening at the centre; a Course's
first eight Lessons all different, neighbours opening on opposite sides,
the first Lesson not the same in every Course; the mascot side rule for
every start; the mascot, placement and production-mascot tests follow the
Lesson's start instead of assuming the first one.

Course files, scoring, progression and learner data are unchanged. Beta
expiry `2026-11-02 23:59:59` local time.

## Revision 3 follow-up (same version, 4 October 2026): any publisher

**Why.** The owner asked that Export as Publisher Course work for any
publisher, and that the page not even mention com.quisquislingo. Revision 2
offered a list built from the app's trusted publishers plus QuisquisLingo
Courses while its key is pending. In a release build that list held only
QuisquisLingo Courses, so no other publisher could be named.

**The change.** `PublisherCourseExportScreen` replaces the list with two
fields:

- **Publisher ID** (`publisher-export-publisher-id`), with an error when the
  ID has spaces or characters other than letters, digits, dots, hyphens and
  underscores.
- **Publisher name** (`publisher-export-publisher-name`), exactly as
  approved.

No publisher is suggested. A note (`publisher-export-trust-note`) says that
QuisquisLingo installs a Publisher Course only when it trusts the publisher's
signing key (guide §§3–6). The key-pending note is gone. Point 3 of the notes
asks for the same publisher ID and name for an update.

In code, `PublisherIdentity` (ID and name) replaces `TrustedPublisherKey`
throughout the export: `PublisherCourseExport.build`,
`CourseLibraryOperations.exportAsPublisherCourse` / `savePublisherCourseTo`
and `CourseLibraryReports.publisherExported`. `PublisherCourseExport.identity`
trims the two fields and returns null while either is empty or the ID is not
usable. `publisherIdProblem` explains a bad ID. `build` refuses an unusable
publisher. `PublisherCourseExport.publishers()` is removed. The trusted
publisher registry is unchanged: it decides at import, not at export.

Help EN/IT/ES (the export section and the signing section's paragraph) and
`docs/PUBLISHER_SIGNING_GUIDE.md` §7 say that the approved publisherId and
publisherName are typed.

**Remembered publisher** (owner choice, same day). `PublisherExportMemory`
(`lib/services/publisher_export_memory.dart`) keeps the publisher each Course
was last exported for:

- **Storage:** one device-level SharedPreferences key per Course,
  `qql_publisher_export_<URI-encoded Course ID>`, holding JSON
  `{publisherId, publisherName}`. It is never written into the Course file or
  the package.
- **Writing:** `CourseLibraryOperations.exportAsPublisherCourse` writes it
  after the ZIP is written; `savePublisherCourseTo` writes it only once the
  dialog saved. A refused export writes nothing.
- **Filling in:** `rememberedPublisher` reads it, and Course Studio passes it
  to the page as `initialPublisher`. The page fills both fields and says so
  (`publisher-export-remembered`). A stored value that is not usable is
  ignored.
- **Removal:** `CourseLibraryOperations.deleteCourse`, the custom-course reset
  (`AppResetService`, which also counts the key for `hasCustomCourses`) and
  Wipe everything remove it.
- **Inventory:** the section **Remembered publishers** lists each Course with
  its publisher. `docs/239_RESET_STORAGE_INVENTORY.md` has the key.

**Warning against the accepted publishers** (owner choice, same day).
`PublisherCourseExport.trustWarning(publisher, [registry])` compares the typed
publisher with the publishers the registry accepts at installation (by
default `TrustedPublishers.application()`):

- an ID it does not know gives "does not accept this publisher yet: the
  Course can be exported and signed, but not installed until a version of
  the app has its signing key";
- an ID whose keys are all revoked gives "QuisquisLingo has revoked this
  publisher's signing key: the Course cannot be installed until the publisher
  has a new approved key" (owner review: a revoked publisher is not "not
  yet"); a publisher with one active key among revoked ones is accepted;
- an accepted ID with another name gives "knows this publisher as “<approved
  name>”: write the name exactly so, or the Course will be refused at
  installation" (the import checks the name exactly);
- otherwise nothing.

The page shows it under the fields (`publisher-export-trust-warning`, amber
icon) and never disables the buttons for it. It names only the publisher the
author typed. The screen's optional `registry` serves the tests.

**Tests.** In `test/publisher_course_export_262_test.dart`, the example
publisher is `org.example.courses`. New tests cover:

- any typed ID and name, trimmed;
- a publisher the app does not know is exported too;
- an unusable publisher is refused.

The screen test types a bad ID (error shown, buttons off), then a good one,
and exports with the typed identity. It also checks that the page shows
neither com.quisquislingo nor QuisquisLingo Courses.

For the remembered publisher:

- `publisher_course_export_262_test.dart` covers one value per Course read
  back and forgotten, unusable stored values ignored, Quick Export
  remembering and a refused export not remembering, and the page filling in
  a remembered publisher.
- `course_library_operations_249_test.dart`: Delete forgets it.
- `app_reset_service_239_test.dart`: only the custom-course reset removes it.
- `inventory_239_test.dart`: Inventory lists it.

For the warning: `trustWarning` checks an accepted publisher, a wrong name,
an unknown ID, an ID with only revoked keys (its own message), an ID with a
revoked and an active key, and the app's own registry. The page warns for an
unknown ID and for a wrong name, still exports, and drops the warning once
the name is right.

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

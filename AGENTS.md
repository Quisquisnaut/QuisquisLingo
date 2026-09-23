# QuisquisLingo agent instructions

## Purpose

These are persistent instructions for Codex when working on QuisquisLingo.

- Treat the current repository tree as the source of truth unless the user explicitly supplies a newer baseline.
- Do not rebuild work from older LingoGrow archives.
- Read `pubspec.yaml` for the current app version/build. Do not hardcode a permanent version assumption in this file.
- Preserve existing behavior outside the requested change.
- Everything not required by the current task is out of scope. Treat the requested scope as the permitted scope.
- Do not replace working features with stubs, simplified rewrites, broad refactors, or unrelated cleanup.
- Make the smallest change that correctly satisfies the request.
- If a requirement is ambiguous and the ambiguity could change behavior, persistence, compatibility, scoring, or user data, ask before choosing a design.
- Separate structural refactoring from behavior changes whenever practical.
- Do not implement future roadmap items merely because they are mentioned in documentation or architectural notes. Follow the user's explicit current task.

## Current release boundary

- `2.0.49+249002` is QQL Build 249, Revision 2: a **failed Course deletion is reported**. `CourseProjectsScreen._delete` used to start `deleteCourse` from the menu without catching its error, so a storage failure escaped uncaught and nothing was shown. It now shows `CourseLibraryReports.deleteFailed` ("Could not delete “…”: reason") and reloads, so the list reflects storage. Proven by the Build 249 characterization test that was skipped in Revisions 0 and 1 and now passes. The double confirmation, `CourseEditorService.deleteUserCourse` and its rights check are unchanged. Beta expiry remains `2026-10-23 23:59:59` local time.
- `2.0.49+249001` is QQL Build 249, Revision 1: **greyed-out Course Manager actions**, an owner-requested behaviour change. `CourseManagerLibrary.entriesFor` returns every `CourseManagerEntry` the Course Manager menu shows, each with an `unavailableReason` when it depends on rights, license, Publisher verification or admin status; the screen draws those disabled with the reason as their subtitle (`course-manager-unavailable-<action>`). Entries that can never apply to a kind of Course stay out: Copy as New Course, Merge and Delete for official Courses, and Remove Publisher Course from device for anything but a Publisher Course. `actionsFor` keeps returning only the usable actions. `CourseAccessPolicy` and every rights decision are unchanged. Beta expiry remains `2026-10-23 23:59:59` local time.
- `2.0.49+249000` is QQL Build 249, Revision 0: **Course library operations owner**, step 2 of the roadmap's Course library screen track. `CourseLibraryOperations` (`lib/services/course_library_operations.dart`) owns Course Manager's workflow around the existing storage owners: `load` returns an immutable `CourseManagerLibrary` snapshot (the personal-library Courses, the included Bundled Courses with the current one substituted, unreadable files, active profile, Teams, admin status and import-time authoring unlock) whose `actionsFor` decides the ordered `CourseManagerAction` menu, `nextCopyTitle`/`nextMergeTitle` the titles and `hasCourseTitled` the New Course warning; `copyAsNewCourse`, `fork` (official source resolution), `composeMerge`/`confirmMerge`, `reviewImport` (`CourseImportReview`: Audit errors/warnings, the existing same-ID Course, Publisher association, offered `CourseImportChoice`s), `exportCourse`/`saveCourseTo`, `audit`, `deleteCourse`, `removePublisherCourse` and `newCourse` (injected clock) are reachable without the screen, and `CourseLibraryReports` holds the result texts. `CourseProjectsScreen` keeps layout, every dialog, file pickers and navigation, and still calls `CoursePackageImport` for the chosen import action. Behaviour is identical: a characterization test proves a failed Delete is silently lost, kept unchanged here and fixed in Revision 2. Course Model v11, stored formats and keys, package format 1 and signatures, authoring rights, scoring, progression, the top-level save boundary and the Course Editor working-copy invariant stay unchanged. Plan, evidence and handoff: `docs/249_LIBRARY_OPERATIONS_PLAN.md`, `docs/249_VALIDATION.md` and `docs/249_HANDOFF.md`. Beta expiry is `2026-10-23 23:59:59` local time (30 days from 23 September 2026).
- `2.0.48+248003` is QQL Build 248, Revision 3: **Fork leaves the Course Editor**, completing Revision 2. `_forkCourse` called `createFork(source: _course)` on the unconfirmed working copy, the same defect Revision 2 removed from export and Copy as New Course and missed here, and Fork **persists** a new Course, so a fork could be built from edits that were then cancelled and carry `forkProvenance` naming a source version that never existed. `course-editor-fork-course` and its handler are removed. Course Manager is the only route and is the more correct one: it passes the **stored** Course, and for an official Course first resolves the immutable official source (`officialSourceFor`, `loadBundledCourse` for a bundled Course), refusing when unavailable. `CourseAccessPolicy.canFork`, `CourseEditorService.createFork`, fork lineage and provenance are untouched, so who may fork and what a fork inherits are unchanged. Course Model v11, stored formats and keys, package format 1 and signatures, authoring rights, scoring, progression and the top-level save boundary stay unchanged. Plan, evidence and handoff: `docs/248_FORK_FIX_PLAN.md`, `docs/248_VALIDATION.md` and `docs/248_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.48+248002` is QQL Build 248, Revision 2: export and Copy as New Course leave the Course Editor. Both ran on the **unconfirmed working copy**, so a cancelled session could produce a package, or persist a new Course, built from changes that were never saved. A new `CourseExportScreen` mirrors `CourseImportScreen` with the fixed-folder route and **Save to…**, and the Course Manager's `Export Course ZIP` and `Save to…` entries become one **Export Course** entry that opens it, for official Courses as well. `course-editor-export-json`, `course-editor-save-json-to` and `course-editor-copy-as-new-course` are removed; Course Manager keeps all three actions and works from the stored Course. In the Lesson editor, `lesson-preview-action` and `guidebook-round-generator` become bottom-bar buttons `lesson-preview` (Preview) and `lesson-round-wizard` (Round Wizard), mirroring the Round editor, and `EditorBreadcrumbs` moves to the top of the body like every other level. The Round editor's wizard button reads **Exercise Wizard**. Version History deliberately stays in the Editor: it loads into the working copy and respects the confirmation, unlike export and copy. Course Model v11, stored formats and keys, package format 1 and signatures, authoring rights, scoring, progression and the top-level save boundary stay unchanged. Plan, evidence and handoff: `docs/248_EXPORT_AND_LESSON_ACTIONS_PLAN.md`, `docs/248_VALIDATION.md` and `docs/248_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.48+248001` is QQL Build 248, Revision 1: Course Editor layout, plus `CourseAuthoringMedia.ownedExtensions` widened from MP3s to **every** kind of Course media, so images added while editing are removed on a cancelled session too. The Course-level Lesson settings (Lesson numbering, Use GuideBook, Create Duels) move from the **Lessons** screen to a collapsed **Lesson Options** section (`course-lesson-options`) under the Course Editor's Lessons tile; `askAuthoringName` is the one shared title prompt. The Lesson editor drops `lesson-title-control` and `lesson-audit-action`, and the Round editor drops `round-rename-action` and `round-audit-action`; Rename and Audit remain in the Lessons and Rounds pages' 3-dot menus, whose rename dialog keeps the same 'Title, or Enter to skip' preservation. The Audio Library has no Save button: leaving the screen returns its draft to the working copy, and a notice (`audio-library-save-notice`) explains that the Course confirmation still decides. A Course's Image Library gains the same notice (`course-image-save-notice`); its save-on-exit and discard-on-cancel behaviour was already in place and is unchanged. This revision is a scope extension the owner asked for, not a correction proven by Build 248's tests. Course Model v11, stored formats and keys, package format 1 and signatures, authoring rights, scoring, progression and the top-level save boundary stay unchanged. Plan, evidence and handoff: `docs/248_EDITOR_LAYOUT_PLAN.md`, `docs/248_VALIDATION.md` and `docs/248_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.48+248000` is QQL Build 248, Revision 0: `CourseAuthoringMedia` (`lib/services/course_authoring_media.dart`), held by `CourseAuthoringSession`, owns the lifetime of the media a Course editing session creates. It records the Course media folder's contents when the session opens, and when the session ends **without** a confirmed Course it removes exactly the `.mp3` files that appeared during the session and the persisted custom Course does not use. It removes nothing when that opening listing or the stored Course cannot be read, so media stay for recovery. `CourseEditorService.persistedCustomCourseReferences` is the one read it uses, and `CourseMediaStore.storedReferences` lists a Course's own files without deleting any. Every Course Editor exit now runs through `_attemptLeave`/`_popEditor` (`PopScope.canPop` is `_routeMayPop` only), because an unchanged working copy can still have imported recordings to disk; closing an unchanged Editor therefore completes after that check rather than within the same frames. MP3 validation and storage remain in `RecordedAudioService`, playback/preview/dialogs remain in the widget, and a confirmed Course still tidies up through `CourseMediaStore.deleteUnreferenced` inside `confirmCourseTransaction`. `RecordedAudioService.orphaned` remains a clips-without-a-word check, not a disk contract. Known limit, deliberately unchanged: images added while editing leak the same way and belong to a later build. Course Model v11, stored formats and keys, package format 1 and signatures, authoring rights, scoring, progression and the top-level save boundary stay unchanged. Plan, evidence and handoff: `docs/248_AUDIO_LIBRARY_PLAN.md`, `docs/248_VALIDATION.md` and `docs/248_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.47+247001` is QQL Build 247, Revision 1: a failed custom package import keeps the media it created only when the stored Course uses **every** package medium, which is what a committed import leaves behind, or when storage cannot be read. A Replace rejected before it commits now removes the files that attempt added and leaves the previous Course's own media untouched. The old `CourseEditorService.persistedCustomCourseReferencesAny` retention test is replaced by this rule and removed; `CoursePackageImport` remains the only import owner. Course Model v11, stored formats, keys, rights, scoring, package format 1 and the top-level save boundary stay unchanged. Evidence and handoff: `docs/247_VALIDATION.md` and `docs/247_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.47+247000` is QQL Build 247, Revision 0: `CoursePackageImport` (`lib/services/course_package_import.dart`) owns one read Course package from reading until the import ends. Course Manager keeps file choice, Audit, dialogs and results, and calls one action: custom install (new or Replace / update), Copy as New Course, Fork, Publisher install, or close. Each action runs once and discards staging before returning, so a Copy/Fork Editor opens with no staged files. `CourseEditorService.installImportedCustomCourse`, `createCopyAsNewCourse` and `createFork` accept the package and write its media only into the destination Course's own folder under that Course's lock; nothing is written into a same-ID installed Course's folder. The custom-import failure retention rule and Merge's own right-package staging are unchanged. The package manifest lists shared-image provenance only for Exercise prompt images; provenance elsewhere travels in `course.json`, and this is a recorded known limit (package format 1 unchanged). Course Model v11, stored formats, keys, rights, scoring and the top-level save boundary stay unchanged. Plan, evidence and handoff: `docs/247_PACKAGE_IMPORT_PLAN.md`, `docs/247_VALIDATION.md` and `docs/247_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.46+246001` is QQL Build 246, Revision 1: Course package Import and Merge accept one enclosing ZIP folder only when its name exactly matches the ZIP filename without `.zip`; root-level packages remain accepted, and all other unexpected or unsafe ZIP layouts remain rejected. Import and Merge show a nonblocking warning for the accepted wrapper, and their Help explains the folder rule. Merge Help also states that same-ID sources may differ by Course version or Modified date and time. Course Model v11, stored formats, keys, rights, scoring and the top-level save boundary stay unchanged. Evidence and handoff: `docs/246_VALIDATION.md` and `docs/246_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.46+246000` is QQL Build 246, Revision 0: `CourseEditorService.confirmMergedCourse` owns the Merge destination's left-then-right media copy, one top-level Course confirmation, and recovery cleanup under the per-Course lock. It removes only media created by the attempt when absence of a saved Course is proven; committed or unreadable Course state retains media. `CourseMergeService` keeps composition and compatibility; the right package's temporary input media remains staged through confirmation, and the screen accepts one submission at a time through package cleanup. Course Model v11, stored formats, keys, rights, scoring and the successful Merge result are unchanged. Evidence and handoff: `docs/246_VALIDATION.md` and `docs/246_HANDOFF.md`; approved sequence: `docs/ARCHITECTURE_ROADMAP_246_PLUS.md`. Beta expiry is `2026-10-22 23:59:59` local time.
- `2.0.45+245004` is QQL Build 245, Revision 4: Course storage mutations use intent-specific per-Course create, update and delete commands below the existing `CourseEditorService` facade, replacing its whole-store map bridge. Authorization, stale-edit rejection, backup-before-write, readback and media cleanup ordering remain intact; unreadable and duplicate-ID files stay protected and failed writes retain recovery paths. Course Model v11, storage formats, keys and user-visible behavior stay unchanged. Evidence and handoff: `docs/245_VALIDATION.md` and `docs/245_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.45+245003` is QQL Build 245, Revision 3: integrated Course → Lesson → Round → Exercise editor routes propagate accepted updates through the Course authoring session with one authoritative callback path. Publication reconciliation receives the exact previous Course where the existing route provides one; standalone editor routes retain their public callbacks. The final Course confirmation remains the only persistence point. Course Model v11, stored data and user-visible behavior stay unchanged. Route evidence is in `docs/245_VALIDATION.md` and `docs/245_HANDOFF.md`. Build 245 plan: `docs/245_ARCHITECTURE_PLAN.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.45+245002` is QQL Build 245, Revision 2: typed Lesson, Round and Exercise update commands own hierarchy reconstruction and Content-wrapper preservation. The Course authoring session remains the sole top-level working copy and final confirmation remains the only persistence point. Existing nested reconciliation and route callbacks remain until Revision 3. Route coverage is recorded in `docs/245_VALIDATION.md` and `docs/245_HANDOFF.md`. Course Model v11, stored data and user-visible behavior stay unchanged. Build 245 plan: `docs/245_ARCHITECTURE_PLAN.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.45+245001` is QQL Build 245, Revision 1: one Course authoring session coordinates the existing working-copy transaction, top-level provisional publication reconciliation and draft adoption, dirty state, Audit freshness and final confirm/cancel. It does not create another Course copy or persistence path. Nested reconciliation remains until the canonical route propagation step in Revision 3. Course Model v11, stored data and user-visible behavior stay unchanged. Build 245 plan: `docs/245_ARCHITECTURE_PLAN.md`; handoff: `docs/245_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.45+245000` is QQL Build 245, Revision 0: Course Info metadata and governance changes are applied through one typed operation before entering the existing Course Editor working-copy transaction. The dialog retains presentation state; final confirmation remains the sole persistence point. Course Model v11, stored data and user-visible behavior stay unchanged. Build 245 plan: `docs/245_ARCHITECTURE_PLAN.md`; handoff: `docs/245_HANDOFF.md`. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.44+244007` is QQL Build 244, Revision 7: Course Library Help (`availableCoursesHelp`) opens with the device-vs-personal-library distinction and the friend/publisher import examples ("a publisher may distribute or sell you a Publisher Course"; QQL does not sell or license Courses), then Categories, Course details, Availability, Sorting and compact view, Personal library, Importing and Publisher removal. It does not mention the hidden web section. EN/IT Editor Help describe the switch, Sort by and Expanded / Compact. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.44+244006` is QQL Build 244, Revision 6: Each Course Library section header has an Expanded/Compact toggle (`course-section-view-N`, page-session, all Expanded by default, independent per section). Compact rows use a 40 px `CourseArtwork` and hide Version, Last edited, Maintainer and Duration; title, languages, status labels and Add/Remove stay. Beta expiry remains `2026-10-22 23:59:59` local time.
- `2.0.44+244005` is QQL Build 244, Revision 5: Course Library **Sort by** (`course-library-sort`, page-session, default Title) uses `CourseLibraryPresentation.sorted` with `CourseLibrarySort` {title, language (target, source), maintainer, mostRecent (newest first, unparsable last), duration (shortest first, unknown last)}; every ordering then compares title and courseId. Text comparison is `CourseLibraryPresentation.compareText` (trimmed, case-insensitive). Sorting is per section only. Beta expiry is `2026-10-22 23:59:59` local time (30 days from this release, 22 September 2026).
- `2.0.44+244004` is QQL Build 244, Revision 4: Course Library rows (key `device-course-<id>`, title key `device-course-title-<id>`) are a custom Row, not `ListTile`: `CourseArtwork` (`lib/widgets/course_artwork.dart`, fixed square slot, default 64) shows `coverImage` through `CourseMediaImage` with `cacheWidth` bounded to the slot and falls back to `CourseFlagBadge` on absent, missing or undecodable covers. Display values come from `CourseLibraryPresentation` (`lib/services/course_library_presentation.dart`): `version` (Custom `courseVersion`, official `officialCourseVersion`, omitted when empty), `lastEdited` (`modifiedAtUtc`, shown with `formatShortDate`, `Unknown` if unparsable), `duration` (`estimatedStudyHours`, omitted when null). Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.44+244003` is QQL Build 244, Revision 3: Course Library sections are bordered `_Band`s keyed `course-section-0..3` (Bundled, Publisher, My Local, Other Local Courses) with count text `course-section-count-N` (` · N` or ` · S shown · H hidden`). The Find Courses on the web band (`course-library-web-band`) renders only when `AvailableCoursesScreen.courseWebSite` is set; its default `courseLibraryWebSite` is `null` until the site exists (owner decision: hidden, not disabled). `launchWebSite` is a test seam. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.44+244002` is QQL Build 244, Revision 2: Available on this device is renamed **Course Library** everywhere visible (class `AvailableCoursesScreen` and key `available-on-device` unchanged). Page-session switch `show-unavailable-courses` (default off) hides Courses that are unpublished, `PublicationService.requiresPublisherVerification`, or `CourseDraftStatus.courseHasDraft`; presentation only. The old `Not published · Draft` badge is split into `Draft`, `Unpublished`, `Verification required`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.44+244001` is QQL Build 244, Revision 1: structural only. `CourseDraftStatus` (`lib/models/course_draft_status.dart`) is the single authored-Draft rule (Lesson, GuideBook only while `useGuidebook`, Round, Round content, Exercise); `AuthoringHierarchyStatus` delegates to it. It never runs the Audit, so list screens may call it per Course. Build 244 plan: `docs/COURSE_LIBRARY_244_PLAN.md`; handoff: `docs/COURSE_LIBRARY_244_HANDOFF.md`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243019` is QQL Build 243, Revision 19: the Phase 20 route-matrix suite uses small generated synthetic fixtures to exercise fixed-folder, Open from…, Course ZIP and embedded Course JSON import paths. It exposed embedded image bytes that passed Course JSON import without `ImageValidator`; `CustomCourseTransferService.courseFromBytes` now checks embedded exercise images, custom Lesson icons and custom flags on import through the existing image validator and `CourseImageUsage` walker. Stored Courses are not revalidated. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243018` is QQL Build 243, Revision 18: the full-size preview in Shared Images and the Course Editor's Image Library has an English details tooltip on hover or long-press. It shows source filename (or content-named Course file), approximate size, pixel dimensions, format, added date, Image Bank name, attribution, missing-file state, and whether a merged device image is also stored in the Course. Tiles have no details tooltip; stored images are read only for details, never revalidated. English Editor Help explains the gesture. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243017` is QQL Build 243, Revision 17: media import errors identify common files saved under the wrong extension and explain how to correct them. A missing Image Bank manifest message explains how to create `image_bank_manifest.json` and points to Editor Help. Audio Library calls its default mode On-Device TTS, explains all three modes, and offers MP3 import/check actions only in Recorded MP3 and Hybrid modes. Stored audio mode values and playback stay unchanged. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243016` is QQL Build 243, Revision 16: Tranche 5 part 1. `ImageProvenance` on device image records; `contentIndex` (SHA-256 of QQL and device images) decides duplicates by content; Image Bank ID conflicts → Skip / Replace (device images only) / Keep both with Apply to all; `applyLocalRecords` adds and replaces in one write. The screen is titled Shared Images. `web_page_detector.dart` explains web pages saved as `.mp3`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243015` is QQL Build 243, Revision 15: Tranche 4 part 2. Course packages are parsed from disk (`CoursePackageService.parseFile`, `FileDialogService.openStaged`); only referenced media are read, one at a time, into `qql_import_staging` `.part` files. `CoursePackage` exposes `mediaReferences`/`mediaBytes`/`discard()` (no `media` map); callers discard packages when done. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243014` is QQL Build 243, Revision 14: Tranche 4 part 1. `BoundedZipReader` is the only import ZIP reader (Image Banks, Course packages); never use `ZipDecoder` on imports. Image Banks: manifest + listed images only, optional object manifest (`images`, bank-wide `attribution`, `name`), bounded fields, category names checked in `readBank`; `importToSharedLibrary` asks the Admin about new categories before writing and rolls back on failure. `JsonLimits`/`CourseShapeLimits` run before `jsonDecode` for Course, learner backup and Recovery Key. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243013` is QQL Build 243, Revision 13: Tranche 3. `Mp3Validator` (MPEG Layer III frames only, at least 4 contiguous, ID3v2/ID3v1/APEv2 tags within 2 MB, `APIC`/`PIC` artwork refused, 50 MB, 30 s isolate watchdog) runs on every MP3 route: fixed folder (all checked before any stored), Open from… (single and new multi-file `importMp3sFromDialog` with per-file results and duplicate skipping), and `.mp3` media in `CoursePackageService.parse` (import only). Test MP3s come from `test/support/synthetic_mp3.dart`; the Dummy signed media fixture was re-signed. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243012` is QQL Build 243, Revision 12: Tranche 2b. The Course Editor's Image Library offers **Add images to this Course** (single, multiple, Image Bank ZIP) into the Course's `imageLibrary`: images pass `ImageValidator`, duplicates are skipped, a 300 MB pre-check runs before writing, and nothing enters the Shared Image Library. `ImageBankService.readBank` checks without writing (`importBankZip` = read + write). `CourseImageLibraryEntry` gains optional `label`/`category`/`tags`/`attribution` (`checked` enforces limits). Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243011` is QQL Build 243, Revision 11: Tranche 2. `ImageValidator` (`lib/services/import/image_validator.dart`) is the one image check: `inspect` (pure Dart, strict structure, no animation, metadata ≤256 KB, ≤4096 px, ≤16,777,216 px) and `validate` (plus one bounded decode) → `ValidatedImage`. Every image import uses it (Shared Library, Course Editor via `CourseMediaStore.addValidated`, portable, Lesson icon, flag, Image Bank entries, Course ZIP image media on import). `ExerciseImageService.read*` never write; `addToSharedLibrary` checks Admin first and stores `image_local_<µs>.<ext>`. Stored images are never re-checked. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243010` is QQL Build 243, Revision 10: Tranche 1, the safe import foundation (`lib/services/import/`). `FileDialogBackend.pickFiles` returns `SelectedExternalFile`s (ordinary files only, no link following); `FileDialogService.openBytes` streams through `ImportStager` into `<AppSupport>/qql_import_staging` under the caller's **real** limit (new `FileDialogOutcome.tooLarge`, which callers map to their own message); `openFiles` stages a multiple selection (100 files, 250 MB) into an `ImportBatchResult`. Never reintroduce per-service dialog read caps. Fixed-name imports check `isOrdinaryFile`. Tests pass `testImportStager()` from `test/support/fake_file_dialog_backend.dart`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243009` is QQL Build 243, Revision 9: Tranche 0b. QQL (bundled) image metadata is read-only and always comes from the app asset; `ExerciseImageMetadataService` stores schema 2 in the same key (device records only, `localWords` by QQL ID, `deviceCategories`) and converts a schema-1 whole-catalog snapshot once (Admin-added QQL tags become Local words). Local words (`updateLocalWords`, tile `Tags: … · Local: …`, searchable, never exported) and device categories (add/rename/remove, 2–40 `[a-z0-9_]`, max 64). `updateMetadata` refuses QQL images. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243008` is QQL Build 243, Revision 8: badge order `IN USE`, `QQL`, `DEVICE`, `COURSE`; **Remove from this Course** in the Course Editor's Image Library (`FlatImageLibraryScreen.onCourseChanged`, applied through the editor's `_updateDraft`). `CourseImageRemoval` (`lib/services/course_image_removal.dart`) clears every use found by the `CourseImageUsage` rule (exercises, presentations, GuideBooks, cover), stamps `updatedAt`, and makes Draft whatever then has an Audit error. Courses gain the optional `imageLibrary` (`CourseImageLibraryEntry`: `media:` asset plus optional `sharedImageSource`, omitted when empty, included in `referencesOf`, carried by Fork/transfer/Merge). Every Course-stored image has the bin, and after its uses are cleared it can be kept in or removed from that library. Files leave via `deleteUnreferenced` after the confirmed save, or at once only when neither the saved nor the edited Course references them. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243007` is QQL Build 243, Revision 7: image library tidy-up (`docs/IMPORT_HARDENING_PLAN.md` §6c). `CourseImageUsage` (`lib/services/course_image_usage.dart`) is the single rule for where a Course uses an image: every image element in Round and GuideBook content (exercise prompt/items/layout and presentation content) plus the cover. `CourseMediaStore.referencesOf`, the Image Library's IN USE and the Exercise editor all delegate to it; presentation- and GuideBook-only images now show IN USE (owner decision). Image Library rules live in `lib/services/image_library_rules.dart`; the Exercise editor's image section is `ExerciseImageField` (`lib/widgets/exercise_image_field.dart`). Never add a second usage walker. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243006` is QQL Build 243, Revision 6: Tranche 0 of `docs/IMPORT_HARDENING_PLAN.md`. Course ZIP cover dimensions are checked from the header before decoding; Image Bank ZIPs are pre-scanned from the central directory (≤5,000 entries, no symlinks, ≤50 MB declared across all entries) and every entry is inflated through `readBoundedEntry` (`lib/services/bounded_archive_entry.dart`, shared with `CoursePackageService`) up to its exact declared size; Lesson icon and custom flag sources are limited to 4096 px; animated PNG/WebP are refused by `PortableExerciseImageService.fromBytes` only (stored images keep working). Resume from `docs/IMPORT_HARDENING_HANDOFF.md`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243005` is QQL Build 243, Revision 5: Image Library usability. `USED` is renamed `IN USE`; badges are small overlays at the image's bottom-left (`lib/widgets/image_badges.dart`); the library adds a badge filter and a sort menu (Name, Newest/Oldest added, Largest/Smallest file — the added date is derived from QQL-generated ID stamps or Course file write times, since no record stores it); a Shared Image Library image and its Course copy show once as `DEVICE`/`COURSE`/`IN USE`; tiles show only image, lowercase name and lowercase tags when present; Admin delete sits at the image's bottom-right. No Course, storage or import change. The import hardening work is planned in `docs/IMPORT_HARDENING_PLAN.md`. Beta expiry remains `2026-10-21 23:59:59` local time.
- `2.0.43+243004` is QQL Build 243, Revision 4 (Tranche 3): signed Publisher Course ZIPs deliver referenced images and recordings. Import verifies the Publisher signature and every packaged media digest before installation; `CourseEditorService.installExternalOfficialUpdate` stages media and refuses missing or damaged files even when called directly. An update archives the previous official Course with its media, then removes unreferenced files from that Course's folder. Uninstall keeps media for reinstallation. `tools/sign_course.dart package` verifies a signed JSON and builds the ZIP from only its referenced media. The Course Editor's Image Library lists shared and Course-stored images, adds `USED` to QQL/DEVICE images referenced by an exercise, and retains `COURSE` for bytes in the Course folder. Course Manager and Device Administration expose the Admin-only management entry named Shared Image Library; its shared entries remain labelled QQL/DEVICE. The Publisher guide and in-app Help match. Beta expiry remains `2026-10-21 23:59:59` local time. See `docs/243_CHANGE_SUMMARY.md` and `docs/243_VALIDATION.md`.
- `2.0.43+243003` is QQL Build 243, Revision 3 (Tranche 2): Course Export writes a ZIP with `course.json`, a format-1 manifest and only referenced Course-owned media; Import and Merge accept that ZIP or media-free v11 JSON. Admin-added Shared Image Library images selected for a Course are copied into its folder and retain descriptive library ID, label, category, tags, origin and optional per-image attribution in the Course and ZIP manifest. Admins edit attribution in Shared Image Library metadata; Image Banks may supply it, and all users can read it. Import keeps images Course-owned and never changes the destination Shared Image Library. The Shared Image Library labels app-bundled images `QQL` and Admin-added images `DEVICE`, unchanged when a Course uses them. The Course Editor labels every used image `USED` and an image physically stored in its Course folder `COURSE`, beside `QQL` or `DEVICE` where applicable. App-bundled images remain supplied by QQL and are not included in the ZIP. Publisher recordings are still restricted until Revision 4. Beta expiry stays `2026-10-21 23:59:59` local time. See `docs/243_CHANGE_SUMMARY.md`.
- `2.0.43+243002` is QQL Build 243, Revision 2 (Tranche 1): course media. A Course's own image or recording is `media:<sha256>.<ext>` in `<AppSupport>/quisquislingo_course_media/course_<sha256(courseId)>/`, managed only by `CourseMediaStore`; Course Model v11 refuses device paths. Importing or choosing media copies it into the Course folder; Copy as New Course, Fork and Merge copy what they use; a confirmed save deletes unreferenced files; deleting a Course deletes its folder; backups copy and Restore reinstates media. Nothing is shared between Courses, so `ManagedAudioCleanup`/`MediaReferenceIndex` are gone and the Revision 1 strict-cleanup note no longer applies. Show Course images with `CourseMediaImage`; resolve recordings with the Course ID. See `docs/243_CHANGE_SUMMARY.md`.
- `2.0.43+243001` is QQL Build 243, Revision 1: one unreadable stored Course no longer hides the others. `CourseFileStore.readReadable` (listing, saving) skips unreadable, unsupported and duplicate-ID files and reports them; strict `readAll` remains for callers that must see every Course (unused-MP3 cleanup deletes nothing, profile deletion refuses). `write` never replaces an unreadable or foreign file. Course Manager and Inventory name skipped files. Same Beta expiry `2026-10-21 23:59:59`. See `docs/243_CHANGE_SUMMARY.md`.
- `2.0.43+243000` is QQL Build 243, Revision 0: Tranche 0 of the portable course package (`docs/COURSE_PACKAGE_PLAN.md`; Revision 1 lists every readable stored Course when one cannot be read; Tranches 1–3 are Revisions 2–4, each committed separately, with the full suite run only after owner approval). Course Model **v11** is the single accepted format as a clean cut: v9/v10 are refused and never converted in-app; `tools/convert_course_to_v11.dart` converts outside the app. v11 = v9 + optional custom-only `mergeProvenance` (v10 and `Course.mergedFormatVersion` are gone) + Build 242 `mediaAttributions` + optional `minimumAppBuild`, `publisherContact`, `estimatedStudyHours`, `minimumAge` (App Store classes 4/9/13/16/18), `keywords`, `coverImage` (stored only). Courses are stored under `qql_courses_v2` and backups under `Course Backups v11`; the old `qql_courses_v1` and `Course Backups v9` folders are left untouched and unread. Bundled Courses keep their IDs; the Dummy fixtures were re-signed. Beta expiry `2026-10-21 23:59:59` local time. See `docs/243_CHANGE_SUMMARY.md` and `docs/243_VALIDATION.md`.
- `2.0.42+242000` is QQL Build 242, Revision 0: the media audit and the corrections it produced. A missing recorded MP3 no longer makes a Course permanently unsaveable — the pre-change backup records the gap instead of refusing to run, while records naming a copied file keep their strict existence/SHA-256 checks. Courses gain an optional structured `mediaAttributions` list for third-party image and recording credits; `formatVersion` stays 9 and the field is omitted when empty, so existing courses, backups and publisher signatures are byte-identical. The Audit registry grows to **104 rules** with `MEDIA_ATTRIBUTION_MISSING` (Warning, never blocking). The application's own Image credits page now credits all five attribution-required language flags, including the previously missing Mirandese and Venetian. Publisher Courses declaring recorded MP3s outside `assets/` are refused at import and installation. Three obsolete `assets/exercise_images/` manifests were deleted and replaced by an importable example in `demo_image_banks/`, outside `assets/`. The 30-day Beta expiry is recalculated from this release's own date and is `2026-10-20 23:59:59` local time, the same day as Build 241 because both were released on 20 September 2026. See `docs/MEDIA_LIBRARIES_PLAN.md`, `docs/242_CHANGE_SUMMARY.md` and `docs/242_VALIDATION.md`.
- Media distribution remains the known structural gap: a Course exports as one JSON file, so embedded media (Lesson icons, custom flag, Recognize characters images) travels while recorded MP3s and ordinary exercise images do not, on any course type. Importing an Image Bank cannot repair a course, because it mints fresh timestamped paths. A portable media package is not implemented and is not implied by the credit field.
- `2.0.41+241002` is QQL Build 241, Revision 2: course file-store integration, reset/inventory alignment, deterministic filesystem-aware tests, publisher signature verification and the three-type Editor Help comparison. The refreshed 30-day Beta expiry is `2026-10-20 23:59:59` local time. Final validation passed (1,879 full-suite tests and 8 final focused tests; the owner waived repeating the full suite for the final Publisher color-only change); see `docs/241_VALIDATION.md`.

- `2.0.6+206` is the completed Phase 1 characterization-test release. It strengthens behavior-level coverage for Round completion/XP and Course Editor Guidebook generation without changing production behavior.
- `2.0.7+207` is the conservative display-rebranding release from LingoGrow to QuisquisLingo.
- Build 207 changes user-visible branding, user-facing filesystem paths and filenames, display-only window and descriptive metadata, and current documentation while preserving repository URLs, application/package/bundle IDs, executable names, SharedPreferences keys, serialization tokens, course namespaces, environment variables and internal symbols.
- `2.0.8+208` completes the technical rebrand of application-owned identifiers and update infrastructure without legacy LingoGrow compatibility machinery.
- `2.0.9+209` completes Phase 2A modularization by extracting Round completion orchestration into `LearningCompletionService`.
- `2.0.10+210` completes Modularization Phase 2B by extracting learning activity, streak, and study-day logic into `LearningActivityService` behind the existing `ProgressService` public facade.
- `2.0.11+211` adds the learner status bar while consuming the existing service boundaries rather than moving responsibilities back into `ProgressService` or UI screens.
- `2.0.12+212` extracts the existing XP formulas into a pure `XpCalculator` without changing behavior.
- `2.0.13+213` stabilizes the authoritative Round, Review, Topic and Duel XP rules and makes displayed and persisted awards share one calculation result.
- `2.0.14+214` communicates first Topic completion in the Round XP breakdown, unifies guarded text-entry submission, promotes Leaderboard navigation to Home, and applies narrow status-bar and desktop-resize refinements.
- `2.0.15+215` removes Chapter through a clean Course Model v4 cut, introduces the unified Course → Lesson → Round learner page, and makes Duel Topic-scoped with actual-pool availability.
- `2.0.16+216` corrects the Welcome-dialog contrast, uses the selected-course flag as the learner background, places the protected learner strip above the unchanged status bar, removes the redundant Browse All Lessons button while retaining the Lesson selector, and preserves the established recent-course presentation.
- `2.0.17+217` keeps the approved fixed Learner Header and bottom controls while making the central learner content a continuous lazy flow from the selected Lesson through the remaining Lessons in course order, with direct selector jumps, stable scroll-driven selector synchronization and unchanged lock/Duel rules.
- `2.0.18+218` replaces the separate learner User Bar and Status Bar with one theme-aware unified Top Bar ordered as compact Language/Course flag selector, one-line Streak, vertical Laurel progress, vertical Weekly XP, clickable cat mark and Settings; learner-profile management moves to Settings, the cat opens App Info, and the Lesson selector, full-size course picker, continuous Lesson flow and bottom controls remain preserved.
- `2.0.19+219` redesigns the central learner Round path with smaller deterministic left/right cards, intermittent opposite-side QuisquisLingo mascots in a stable course-specific order, a following connector and persisted completed-Round icon accents while preserving surrounding learner behavior.
- `2.0.20+220` centralizes local learner identity, avatar, profile management and Gamification behind Profile, simplifies the learner bottom area to Profile, Review and Course Info, moves Buy a coffee into Course Info, and adds non-destructive local logout.
- `2.0.21+221` refines contained course-flag backgrounds, light/dark veils, Guidebook-integrated mixed-weight Lesson identities, 244 px maximum Round cards, a narrower 70%-opaque GuideBook, 70%-opaque Duel, roomier Duel-to-next-Lesson transitions, a 55%-opaque main connector with subtle theme-aware contrast support, 10%-opaque mascot containers and subtly arched Laurel artwork; keeps fixed learner-bottom controls with a persisted per-profile Default/Light/Dark utility; and adds session-long view-only three-tap previews for specifically activated locked Lessons without altering progression or persistence.
- `2.0.22+222` makes opaque UUIDv4 learner IDs authoritative through a clean persistence cut and backup-v2 restore/copy workflow; adds a separately licensed 266-entity world-flags manifest; and adds the five-tap Settings Flag Game with four cumulative pools, searchable read-only references and ID-keyed device-local scorecards with best-result dates, without changing course flags or learner progression.
- `2.0.23+223` makes Lesson canonical through a clean Course Model v5 cut; adds consecutive-order Section navigation and a controlled 14-icon 256 px Lesson theme library; moves Round management to a draft-preserving editor subpage; standardizes the GuideBook icon/action layout; and moves learner/course-scoped IDDQD into the fixed learner controls while preserving progression, scoring, Duel, Review, learner identity and backup-v2 behavior.
- `2.0.24+224` rationalizes exercises behind Select, Input, Arrange, Match and Presentation models; adds grouped presets, Type the translation, contextual comprehension, linked answer variants and diagnostic Correct feedback; expands scoped Audit with Info guidance; adds explicit Draft/Published authoring, unsaved-change guards, Course-level Lesson numbering/fallback styles and portable managed custom Lesson icons; completes custom-Course duplication/audit and Buy a Coffee metadata; retains Course Model v5, progression, XP, Review, Duel, identity and existing stable IDs.
- `2.0.25+22503` is the Build 225.03 correction candidate. It preserves Build 225.02 while making the authoritative nine-course bundled registry drive and reconcile real UI discovery, and preserving full v6 Content metadata when successful Exercise saves reconcile Round, Lesson and Course baselines. Unrelated planned features remain deferred.
- `2.0.25+22504` replaces nested Course Editor persistence with one course-level working-copy transaction, verified version backups, explicit origin/provenance and a single top-level confirm-or-cancel boundary. Build 225.03 remains its immutable parent.

- `2.0.26+22601` makes bundled/external official courses locally read-only and introduces explicitly licensed independent custom forks with permanent original authorship/provenance and a separate fork creator. The pushed `ede21f813a235e8455d2691da4cf3bb43162a39a` Build 225.04 plus 226.00 documentation correction is its immutable parent. Later Build 226 tranches remain deferred.
- `2.0.26+22602` adds unsaved Exercise Preview, guarded Previous/Next navigation, breadcrumbs, working-copy Move/Copy destinations, shared field help, Draft indicators/counts and the shared Audit Code Registry. Missing Reading-comprehension guidance is removed without changing remaining severities. The pushed `45cf258d707c89d512f7663d9f2fa317adbe5ef0` is its immutable parent; 226.03 and later remain deferred.
- `2.0.26+226023` completes the 226.02 workflow and diagnostics corrections: shared Help and device-local internal-ID controls throughout Course Manager and its editor hierarchy, hierarchy-wide red/green Audit status with one independent blue Draft badge, explicit AI-generated sample labels, observable Lesson fallback-icon selection and explicit Version/Phase/revision display. Course Model v6, persistence and 226.01 boundaries remain unchanged, and 226.03 remains deferred.
- `2.0.36+236000` is QQL Build 236, Revision 0. Startup uses a 1,000 ms opacity/60%-to-100% scale entrance and 800 ms static hold; Course entry accepts automatic or explicit FlagPainter and World Flags through the shared resolver; Course Manager omits only its internal-ID toggle. Static disabled/reduced-motion startup, other Editor ID controls, Course Model v9, persistence, scoring, progression, Review and Duel remain unchanged. The 30-day Beta expiry is `2026-10-16 23:59:59` local time; see `docs/236_VALIDATION.md`.
- `2.0.35+235000` is QQL Build 235, Revision 0 and the first Beta release. It records a clean static-analysis baseline without disabled lint rules or source-level suppressions, retains the existing time-limited learner-route expiry behavior through `2026-10-15 23:59:59` local time, and changes active release-channel wording, diagnostics and artifact names from Alpha to Beta. Course Model v9, persistence, scoring, progression, Review and Duel remain unchanged; see `docs/235_VALIDATION.md`.
- `2.0.26+226024` is Phase 226.02 revision 4: actual Course titles throughout the learner selector; Lessons-page fallback lesson number icons labeled Theme-colored circle and Four-color circle with unchanged stored behaviors; current canonical Audit findings and shared live ancestor refresh; passive Lesson/Round/Exercise IDs after actionable lines; and explicit GuideBook Draft/Audit status inherited by Lesson and Lessons independently of Rounds. The Audit registry remains at 103 rules, Alpha expiry remains `2026-10-06 23:59:59` local time, and 226.03, GuideBook roadmap, Custom Exercise Templates and Napoletano remain deferred.
- `2.0.26+226030` is Phase 226.03 revision 0: authoritative 128-variant answer expansion and independent materialization, deterministic similarity-ranked translation feedback, Unicode-first-grapheme Type the missing word, and portable Image to text/Text to image Recognize characters on the existing Input/Select models. Course Model v6 and existing normalization/correctness remain unchanged. Alpha expiry remains `2026-10-06 23:59:59` local time. The known revision-4 Lock-row and GuideBook-ID omissions remain outside this tranche; 226.04, Custom Exercise Templates, future GuideBook work and Napoletano remain deferred.
- `2.0.26+226040` is Phase 226.04 revision 0: one-time new-course Lesson/Round scaffolding, reusable Section names, consistent Lesson naming, optional Duel and GuideBook paths, authoritative World Flags selection, the upper Lessons Lock icon and passive GuideBook Internal IDs. Course Model remains v6 with explicit backward-compatible defaults; the Audit registry remains at 103 rules. Alpha expiry remains `2026-10-06 23:59:59` local time. Custom Exercise Templates, Napoletano, future GuideBook content and release 227 remain deferred.
- `2.0.26+226042` is Phase 226.04 revision 2: one theme-colored fallback Lesson-number icon, dedicated Course Import navigation and learner-selector Editor actions, shared single-sample Round scaffolding, Final Duel presentation, ordered optional GuideBook Insights, emphasized Publish actions and explicit locked-Lesson guidance. Course Model remains v6 and the Audit Registry remains at 103 rules.
- `2.0.27+227010` is Phase 227.01 revision 0: Learner Panel controls audit and characterization, plus the explicitly requested clean cut to per-learner × Course Flag Background initialized Off. Old shared Flag Background values remain untouched and unread. Small / Off / Extended rendering, Default / Light / Dark Theme, Off / On IDDQD, progression and Course Model v6 remain preserved. The new-version 30-day Alpha expiry is `2026-10-07 23:59:59` local time. Later 227 features remain deferred; see `docs/227_01_VALIDATION.md`.
- `2.0.27+227020` is Phase 227.02 revision 0: Flag Background adds Tinted and Soft Inspired after Small / Off / Extended through one deterministic, theme-adaptive color derivation path for World Flag SVGs, portable custom raster flags and built-in flag colors. Persistence remains per learner × Course, defaults Off and ignores the untouched obsolete shared value. Theme, IDDQD, progression, XP, Course Model v6, course JSON and checksums remain unchanged. Alpha expiry remains `2026-10-07 23:59:59` local time; see `docs/227_02_VALIDATION.md`.
- `2.0.27+227021` is Phase 227.02 revision 1: the learner-facing Soft Inspired name becomes Inspired while its `soft_inspired` persisted value remains compatible, and its static surface now exposes up to three broader, stronger flag-derived color zones. Tinted retains its restrained single-color treatment. Persistence, Theme, IDDQD, progression, XP, Course Model v6, course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_02_VALIDATION.md`.
- `2.0.27+227030` is Phase 227.03 revision 0: the existing learner IDDQD control explains Off as normal progression locks and On as access through locks with genuine progression preserved. Genuinely locked Lesson sections keep their lock state and show `Accessible with IDDQD` while the established Lesson gate exposes only the published GuideBook, Rounds and eligible Duel. IDDQD remains Off / On per learner × Course and initialized Off; toggling alone changes no progression or XP, while actual study records normal results. Flag Background, Theme, Course Model v6, course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_03_VALIDATION.md`.
- `2.0.27+227040` is Phase 227.04 revision 0 and closes QQL 227. IDDQD adds View Only after the unchanged Off/On modes: it bypasses the established Lesson lock gate while Round, Review and Duel interaction writes no learner progress, XP, activity, Laurel, Review or Duel state; the selected mode persists per learner × Course. Theme is Light / Dark / System / Day/Night per learner, with compatible `default` System storage and local 07:00/19:00 live Day/Night boundaries. The bottom controls remain compact without permanent IDDQD helper text. Flag Background, Course Model v6, Course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_04_VALIDATION.md`.
- `2.0.28+2281` is QQL 228 revision 1. It retains the completed Settings/Profile, Statistics, Debug/logging and clean per-learner Audio Settings release. Test Voice speaks only nonblank user-entered text while retaining selected-Course language resolution, and listening audio prepared behind `Before you start` remains silent until Continue makes it active. Actual switches to a different Course show a restrained two-second entry fade, started only after the Course Selector closes and the destination learner state reloads, when Animations are enabled and reduced motion is absent: an explicit valid Course JSON flag remains authoritative, while a Course with no declared flag uses the established course-code fallback; invalid declared flag data still produces no entry overlay. Show one-time notices again is an action rather than a switch. Update checking continues to use GitHub Releases for packaged applications and accurately distinguishes the published source repository from the absence of a packaged GitHub Release. Authoring Preview remains setting-independent and no-write. Course Model v6, course JSON, persistence, checksums, XP and progression remain unchanged. The QQL 228 Alpha expiry remains `2026-10-08 23:59:59` local time; see `docs/228_VALIDATION.md`.
- `2.0.29+229` is QQL Build 229, Revision 0. Course Manager consistently exposes read-only inspection, licensed Fork, Audit and supported Export for official Courses, and Edit, independent Duplicate, Audit, Export and manager-only Delete for custom Courses. Eligible official inspection retains Fork; custom Course Editor adds Duplicate without Delete or another top-area Audit. Every Course Selector row provides Course Info and per-learner × Course Hide, with active-course protection and reversible `Hidden courses (n)` management. The Learner Panel adds Expanded / Collapse completed / Focused Lesson display per learner × Course, using authoritative completion, Lesson unlock, IDDQD access and existing last-visited behavior without Section collapsing. Course Model v6, Course JSON, checksums, identity, provenance, progression, XP, activity and authoring data remain unchanged. The Alpha expiry is `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2291` is QQL Build 229, Revision 1. It retains revision-0 action consistency, learner-specific Hide/Unhide and Expanded / Collapse completed / Focused Lesson display. Course Model v7 requires explicit stable Creator and individual/Team Owner identities for every custom course. The centralized access policy grants full authoring and Duplicate rights to an individual Owner or every member of an owning Team regardless of license; outsiders remain read-only and can Fork only when derivatives are allowed. Credits never grant authorization. Team Manager provides offline stable-ID membership and multiple Leads with a mandatory last-Lead invariant. Bundled, owned custom, Team-owned and outsider custom courses use the same capability-driven Editor hierarchy while official originals remain immutable. The Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2292` is QQL 229 Build 229 revision 2. It corrects version wording, custom-course language/TTS resolution, Course Info language/date/Team/model presentation, shared Course flag selection, duplicate Manager/Editor controls, Team/User Internal IDs and the final-Lead wording while making the developer unlock an ordinary per-profile setting. Revision-1 ownership, Team authorization and Duplicate/Fork clean-state behavior remain authoritative. Course Model stays v7 and the Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2293` is QQL Build 229, Revision 3. Ordinary Team members may leave their Team through a confirmed self-service action without altering Team-owned courses or learner data; authorization updates through current membership while Team Leads remain governed by the last-Lead invariant. Temporary Sample guidance lives in Course Info rather than the main Course Editor, with metadata/export preservation. Course Manager adds an independent blue Unpublished badge alongside the existing Draft badge. Revision-2 language, flag, metadata, Internal-ID and per-user unlock corrections remain authoritative. Course Model stays v7 and the Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.30+230` is QQL Build 230, Revision 0. It is a robustness release with targeted, evidence-driven modularization and no new feature family: learner completion rejects duplicate dispatch, Audio Exercises Off is authoritative through one effective Duel-eligibility calculation shared by Home and Duel entry, learner and Course replacement persistence gains verified rollback boundaries, Course identity/ownership deletion invariants are protected, diagnostic logs are bounded, update and multilingual audio boundaries are corrected, and the analyzer baseline is clean. Course Model stays v7; course JSON, checksums, scoring, progression, Review and QQL 229 behavior remain compatible. The Alpha expiry is `2026-10-11 23:59:59` local time; see `docs/230_VALIDATION.md`.
- `2.0.31+231` is QQL Build 231, Revision 0. It adds the authoritative 22-preset searchable-text inventory and scoped Course Editor Search; centralizes Locked / View unlocked / Edit unlocked at the Course Editor root without granting authorization; adds the per-user × Course View notice; and normalizes Lesson/Round top icons, Rename and Preview placement. View remains no-write while preserving Search, Help, IDs, Preview and Audit. Course Model stays v7; course JSON/checksums, ownership, progression, XP, Review, Duel and QQL 230 robustness behavior remain compatible. The Alpha expiry is `2026-10-12 23:59:59` local time; see `docs/231_VALIDATION.md`.
- `2.0.31+2311` is QQL Build 231.1, Revision 1. It replaces the root access modes with Locked / View only / Inspection mode / Edit; makes View only the ordinary 22-preset Exercise form with all mutation paths disabled; makes the former technical representation explicit Inspection mode; and adds the local Exercise Inspection presentation toggle without changing authorization or dirty state. Search opens the state-appropriate presentation and remains unavailable while Locked. The Create Duels wording is corrected without behavior change. Course Model stays v7; the Alpha expiry is `2026-10-13 23:59:59` local time; see `docs/231_VALIDATION.md`.
- `2.0.32+232` is QQL Build 232, Revision 0. Review is a dedicated automatic page for the active Course, reachable from the Learner Panel bottom action and only the Current course row menu. It selects genuine completed-Round records by descending errors and oldest latest attempt on ties, refreshes the reviewed record through ordinary completion, excludes completed Round IDs only for the current Review visit, and ends with Next Review or Back to course. Published GuideBook Vocabulary is integrated before the Round and requested reinforcement once after it, with immediate versioned learner × Course × Lesson × entry memory and an isolated Reset Word List action. Review ignores IDDQD View Only; vocabulary adds no independent XP or progression. Course Model stays v7, course JSON/checksums are unchanged, and the Alpha expiry remains `2026-10-13 23:59:59` local time; see `docs/232_VALIDATION.md`.
- `2.0.33+233030` is QQL Phase 233.3, revision 0, and closes the three planned QQL 233 phases. Phase 233.1 fixes generic Linux release-package selection while preserving Windows and GitHub Releases policy. Phase 233.2 adds the two-step Learner profile/avatar flow, optional display-only Discord handle, new-profile-only random skin/hair initialization and the authoritative ten-level Status-derived vivid T-shirt presentation. Phase 233.3 separates optional Team assignment and Team governance from an individual Course responsibility role, adds warning-gated controls and experimental-model Help, corrects identity/Internal-ID presentation, and confines the learner status bar to the Learner Panel. The same-version QQL 233.03 correction introduces the clean Course Model v9 provenance, Maintainer, Rights Holder, Fork and Copy-as-new model without changing `2.0.33+233030` or the `2026-10-14 23:59:59` local Alpha expiry; see `docs/233_VALIDATION.md`.
- `2.0.34+234001` is QQL Build 234, Revision 1, the final planned Alpha cleanup correction. It preserves the QQL 234 repository media audit, Image Bank replacements and tags, World Flags expansion, shared Course flag picker, Italian-to-Neapolitan `AI-Slop Demo`, canonical startup logo, atomic Course-entry flag-background loading, locked audio assets, media integrity validation and Course Model v9 learner persistence. The Alpha expiry is `2026-10-14 23:59:59` local time. A Beta transition belongs only to a later release and remains contingent on QQL 234 validation; see `docs/234_MEDIA_AUDIT.md` and `docs/234_VALIDATION.md`.
- Do not read, apply, migrate or automatically convert Build 225 official local overrides. Leave stored remnants untouched. Official history contains publisher sources only. QQL 233.03 uses clean Course Model v9 custom-course, external-official and bundled-discovery namespaces; v8 and older course data remain physically untouched, unread and unsupported. An explicit derivatives-allowed policy is required for any outsider or official fork.
- `2.0.39+239005` is QQL Build 239, Revision 5 (Revisions 3 and 4 were internal checkpoints). It adds the Pick the translation (Select) exercise types (Revision 2), hardens the Course Manager unlock and Flag Game triggers, detects abnormal termination with a session marker and a `session ended cleanly` Crash Log entry, and adds the admin-only Device Administration page: Update shortcut, the startup `Ask who is learning` setting, an Inventory of user-created and user-added files, and PIN-gated, explained resets (`AppResetService`, see `docs/239_RESET_STORAGE_INVENTORY.md`). The startup update check now runs on every launch and each learner is told about a newer release at most once a day (`UpdateNoticeService`). Course Model v9/v10 is unchanged. The 30-day Beta expiry is `2026-10-19 23:59:59` local time; see `docs/239_VALIDATION.md`.
- `2.0.40+240000` is QQL Build 240, Revision 0. It adds the operating system's native Save and Open dialogs next to, never replacing, the fixed-folder Export/Import (`FileDialogService` in `lib/services/file_dialog_service.dart`, bytes in and bytes out, `file_selector` on Windows/macOS/Linux; no Android or iOS backend yet, so the buttons stay hidden there): Save to… for Course JSON, user data, User Recovery Key and log copies; Open from… for Course import, Merge From…, Image Bank ZIP, single images, custom Lesson icons, recorded MP3s, user data and User Recovery Key. Every dialog route must reuse the fixed-folder builder/validator (no duplicate serialization or validation); cancel is silent, failures are logged to the Diagnostic Log with file names only and explain the fixed-folder route; the first dialog starts in Downloads (`qql_file_dialog_downloads_offered_v1`). Confirmed Course saves and Course deletion now delete recorded-MP3 copies that no stored Course uses (`managed_media_cleanup.dart`; Duplicate/Fork copies share file paths, so always check every stored Course first). Custom Lesson icons can be deleted when no Lesson uses them; the theme icon sheet shows Numbers (formerly None) and a collapsed Preinstalled section. The Beta expiry is deliberately unchanged at `2026-10-19 23:59:59` local time (owner-approved exception to the usual refresh); see `docs/240_FILE_DIALOGS_PLAN.md`, `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md` and `docs/240_VALIDATION.md`.

## Architecture and service boundaries

QuisquisLingo is a single-package Flutter application. Prefer incremental internal modularization rather than package-level fragmentation unless explicitly requested.

UI screens should primarily handle presentation and interaction. Business rules, persistence, scoring, and completion logic should remain independently testable outside the UI where practical.

### ProgressService

`ProgressService` remains the compatibility-facing progress service and currently owns or coordinates non-XP learner progress concerns, including where applicable:

- completed Rounds
- completed Lessons
- laurels and perfect-completion state
- TTS-skipped perfect state
- Review history
- Duel state
- course reset behavior
- local leaderboard participation preference

`ProgressService` retains the public learning-activity facade and delegates its activity, streak, and study-day APIs to `LearningActivityService`.

Do not move unrelated responsibilities into or out of `ProgressService` during a narrowly scoped change.

Existing public `ProgressService` APIs may temporarily delegate to more specialized services to preserve screen and caller compatibility.

### Review vocabulary reinforcement

`ProgressService.getRecentRounds` is authoritative for Review ordering: descending latest-attempt errors, then oldest latest-attempt timestamp. `ReviewRoundResolver` resolves those records against the active Course and applies only the current Review page's excluded Round IDs. Do not duplicate sorting in widgets.

`VocabularyReviewService` owns learner-safe GuideBook vocabulary parsing and learner × Course × Lesson × entry state. It consumes only published `kind: vocabulary` Content from enabled GuideBooks, preserves authored occurrences/order, uses stable Content IDs plus deterministic duplicate occurrence identity and fingerprints the displayed prompt/answer. State stores only fingerprint, `encountered` and `needsReinforcement`; reset removes only the active learner's selected-Course vocabulary document. Keep this state out of authored Course JSON, `ProgressService`, `LearningActivityService` and `XpService`.

Vocabulary cards never independently award XP or alter completion, activity, streak, Laurel, Duel, unlocking or Review ordering. Review must remain independent of learner IDDQD mode and must operate through ordinary Round completion for genuinely completed Review records.

### LearningActivityService

`LearningActivityService` owns learning activity, streak, and study-day implementation, including:

- the activity-specific injected clock
- activity persistence key handling
- activity-specific language normalization
- date formatting and parsing
- language-scoped study-day reads
- profile-global study-day reads
- days-studied and streak calculations
- read-only total/per-language Statistics projections, including historical maximum streak
- learning-activity registration

Preserve the existing `ProgressService` public facade, persistence keys and formats, clock semantics, and activity ordering unless an explicit behavior or migration request says otherwise. Keep completed Rounds, completed Lessons, won Duels, Review history and timestamps, course reset, Guidebook state, leaderboard participation, completion orchestration, and XP outside `LearningActivityService`.

### XpService

`XpService` owns XP persistence and XP accounting, including where applicable:

- language XP totals
- learner-global Weekly XP
- per-course Weekly XP breakdowns
- current-week and previous-week XP state
- Sunday weekly rollover
- skipped-week handling
- last-week XP
- XP data used to derive the local leaderboard
- weekly-goal celebration state
- XP persistence validation and integer clamping

Weekly XP remains learner-global across all courses and languages.

A per-course Weekly XP breakdown is keyed by `courseId`.

Local leaderboard participation is not an XP-accounting concern. Keep the participation preference outside `XpService` unless a future explicit architectural change says otherwise.

Preserve exact existing `SharedPreferences` keys and stored formats during structural refactors unless an explicit migration is requested and reviewed.

### XP calculation

XP reward formulas are business logic and should not remain permanently embedded in UI screens.

When XP calculation is extracted or changed:

- Prefer a small pure `XpCalculator` or equivalent testable component.
- The calculator must not read or write `SharedPreferences`.
- The calculator must not depend on Flutter UI state.
- `XpService` persists/accounts for XP; it should not become a container for unrelated Round-completion orchestration.
- Screens should not duplicate XP formulas implemented elsewhere.
- Keep calculation, persistence, and completion orchestration as separate concerns.
- Add direct behavior-level tests for scoring formulas.

Do not introduce new XP rules during a structural extraction unless the user explicitly asks for scoring changes.

### Time-dependent behavior

Weekly rollover, streaks, activity timestamps, Review timestamps, and other time-sensitive logic must remain deterministically testable.

- Preserve injectable clock seams where they exist.
- Production defaults may use local `DateTime.now`.
- Tests should use controlled clocks rather than depending on the actual current date.
- Do not introduce direct `DateTime.now()` calls into logic that already has an injectable clock.

## Versioning and release hygiene

- Every delivered app update must increment the app version/build in `pubspec.yaml`.
- Every app-version update must also refresh the Beta expiry date in `lib/services/beta_lifecycle_service.dart`, its tests, README, and current documentation where the current expiry/version is stated.
- Do not accidentally carry forward the previous release's Beta expiry.
- Unless the user explicitly changes the policy, preserve the project's current Beta lifetime policy.
- Update `CHANGELOG.md` and current validation/release documentation for each delivered version when those files are part of the release process.
- Preserve existing source comments unless a comment has become factually wrong because of the requested change.
- Source ZIPs must contain `pubspec.yaml`, `lib/`, `assets/`, `test/`, `tools/`, and other project files directly at archive root. Never add an extra wrapper directory.
- Package naming:
  - Windows release/package: `quisquislingo_windows_beta_<buildnumber>`
  - Linux release/package: `quisquislingo_linux_beta_<buildnumber>`
  - source folder/archive: `quisquislingo_beta_<buildnumber>_source`
- Use the numeric build number without dots in package names.
- Keep the previous packaged release as a rollback copy until the new release has been tested successfully.

## Course Model v11 invariants

- Canonical course format is `formatVersion: 11`, the only accepted value. A merged Course is an ordinary v11 Course carrying `mergeProvenance`.
- Hierarchy: Course > Lesson > GuideBook + Rounds + Duel > Content/Exercise.
- Chapter is not part of the production model, learner navigation, editor or persistence. Chapter-based course formats are unsupported and are not read, migrated or converted.
- Lesson is canonical in the model, JSON, services, persistence, editor and learner UI. Do not add Topic compatibility aliases or v4 parsing fallbacks.
- GuideBooks and Duels belong to Lessons.
- Lesson Guidebook content may be used to propose or generate exercises or Rounds, but generated content requires preview/review and explicit approval before creation.
- New Course asks for `Number of Lessons` (default 3, whole numbers 1–100) and `Rounds per Lesson` (default 1, whole numbers 1–20). It atomically creates the requested Lessons and Rounds with fresh stable IDs and exactly one Draft Pick the translation (to target) (`translation_choice_to_target`) sample Exercise in each scaffolded Round. Samples use source/learning-language-labelled placeholders and the literal Wrong Answer distractor. These limits apply only to initial scaffolding; the counts are not settings, and they impose no Course Model, import or later-editing limits.
- A manually created Round starts with the same single Draft Pick the translation (to target) sample Exercise used by New Course scaffolding.
- New Lessons and manually created Rounds may carry the optional `provisionalDraft` marker retained from v6. Ready marked parents reconcile to non-Draft through canonical authoring changes without redundant parent saves. Explicit Save Draft clears this eligibility; unmarked Drafts and intentional copies/forks remain Draft until explicitly saved, or until their last Draft child (Exercise for a Round, Round for a Lesson) is saved as Published, which promotes them. Import keeps the publication states stored in the file. A turned-off GuideBook shows no Draft badge and does not count in the Lesson or Course badge. Course delivery stays an independent explicit choice.
- Round `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.
- A Lesson should normally contain at least 6 Rounds, often roughly 48 exercises, but this is guidance only and never a validity or Duel-availability rule.
- Duel availability is calculated at runtime from the actual Lesson-local pool after applying the established structural rules, the active learner's Audio Exercises setting, and runtime audio availability. Audio Exercises Off is authoritative. Home and Duel entry must consume the same `DuelEligibilityService` effective result; fewer than 25 effective eligible exercises makes the Duel unavailable without duplicating questions or changing gameplay rules.
- Preserve stable Item IDs and valid references.
- Optional `section` and `sectionName` are presentational Lesson metadata only. Section has no ID, progress, unlock, XP, Duel, Guidebook, Review or navigation state, and consecutive grouping/relative numbering derive from Lesson order.
- Optional `themeIconAsset` must reference an approved 256 × 256 transparent PNG under `assets/lesson_icons/`; JSON stores only the asset path.
- Canonical v9 text-match exports use `acceptedAnswers`; the legacy `accepted` field is rejected.
- Lesson, Round and Exercise JSON requires a canonical UTC `updatedAt` timestamp. Bundled timestamps are deterministic; authoring timestamps come from the injected/current authoring clock.
- Build the translation serializes one or more literal answers as `evaluation.correctOrders`, each with answer text and stable ordered Item IDs. The legacy single `correctOrder` field is rejected without adaptation.
- Imported/custom courses remain custom even when selected. Do not infer bundled/custom origin from title alone.

## Course provenance, maintenance, rights, license and Teams

- Every v9 Course records immutable `originalCourseCreator` and `originalCreatedAtUtc` lineage metadata. A custom Course additionally requires one individual `maintainer`; optional `assignedTeamId` separately grants Team management access. Official courses must not declare a local Maintainer or Team assignment.
- Original Course Creator is historical provenance, not permission. Course Maintainer is the operational individual role that controls Maintainer transfer and Team assignment. Assigned Team remains separate from both. All authorization uses stable internal IDs.
- Structured `authors[]`/`roles[]` are attribution metadata. `rightsHolders[]` records one or more descriptive person/organization rights holders. License, Rights Holder, attribution, Original Course Creator, Fork Created By and Last Version Editor never grant QQL authorization by themselves.
- The individual Maintainer and every member of an assigned Team can edit and **Copy as New Course** regardless of license. Only the Maintainer may transfer maintenance or assign/revoke a Team. Team Leader status governs Team administration only.
- An outsider cannot edit or Copy as New Course from another Maintainer's original. They may **Fork** only when derivative works are allowed. A permissive license never grants mutation of the source.
- Teams are device-local user-management data keyed by stable Team and opaque profile IDs. A Team has one or more Team Leaders; no operation may leave it with zero Team Leaders. Renaming a Team does not change a Course assignment. Team governance is independent from Course maintenance.
- Fork creates a derivative in the same provenance lineage: it inherits Original Course Creator, Original Course Created, structured attribution, Rights Holder and applicable License; records the immediate source in `forkProvenance`; records Fork Created By/Date; assigns the active user as Maintainer; and does not inherit Assigned Team.
- Copy as New Course creates an independent lineage: it allocates a new Course identity, resets Original Course Creator/Created, Maintainer, Last Version Editor and Modified to the active user/current creation, omits all fork metadata and does not inherit Assigned Team. Structured attribution, Rights Holder, License and course content are copied.
- No v8 custom-course metadata, ownership, Team-assignment inference or migration is permitted. Active v9 paths never read v8 namespaces. Do not use visible names, Discord handles, credits, legal metadata, filenames or titles as fallback identity.

## Course identity and collision handling

- Every course has an immutable, globally unique `courseId`.
- New courses must receive their ID through the centralized course-ID generator, currently `Course.newCourseId()`.
- Never derive course identity only from language code, title, timestamp text, filename, or display name.
- A derived/forked course must receive a new `courseId`.
- A forked course preserves its immediate source through `forkProvenance.sourceCourseId` and receives a new `courseId`. Copy as New Course receives a new `courseId` without fork ancestry.
- Importing a course with the same `courseId` means it represents the same course identity.
- Same-ID import handling must offer the established choices:
  - Replace/update
  - Separate copy
  - Cancel
- Separate copy must create a genuinely new `courseId`.
- A separate copy must not silently share course-owned progress with the original.
- Do not change course-ID collision behavior without updating the relevant technical Help/documentation and tests.

## Progress and access invariants

Course-owned state is keyed by `courseId`, including where applicable:

- completed Rounds
- Review state/history
- laurels
- Lesson completion
- Duels
- Guidebook learner state
- course-specific progression
- course reset state

Language-scoped state remains language-scoped:

- language XP
- streak
- study days

Weekly XP rules:

- Weekly XP is learner-global across all courses and all languages.
- If a per-course Weekly XP breakdown is stored or displayed, key that breakdown by `courseId`.
- Do not redefine global Weekly XP as a per-language or per-course total.

Reset rules:

- `resetCourse(courseId)` clears only that course's course-owned progress.
- It must not erase language-wide XP already earned.
- It must not erase Weekly XP already earned.
- It must not erase another course's state.
- It must not reset unrelated learner data.
- After course progress is reset, a Round may again qualify for the normal first-completion XP rules if that is the established scoring behavior.

Lesson access rules:

- The first Lesson is unlocked. Each later Lesson unlocks when the immediately preceding Lesson is completed or its Lesson-scoped Duel is won.
- `IDDQD Mode (you can walk through locks)` is stored per user and per course.
- IDDQD On and View Only grant temporary access without changing genuine unlock state.
- IDDQD On records genuine study progress and unlocks normally. View Only records no learner progress, rewards, activity, Review or Duel state.
- Lock icons always show genuine lock state.
- Never reset learner progress, XP, streaks, laurels, course selection, or user data as a side effect of an unrelated feature.

## Round XP compatibility rules

Until the user explicitly replaces the scoring system, preserve the build-213 scoring behavior.

- A completed Round awards 5 XP per first-attempt-correct evaluable exercise on first completion, or 2 XP on repeats and in Review.
- Every zero-error completed Round receives a repeatable 5 XP perfect bonus.
- The first Laurel for a Round receives a one-time 25 XP bonus, including when first earned on a repeat or in Review.
- Flashcard and informational/guide content awards no base XP, counts as neither correct nor erroneous, and does not block perfect completion or Laurel eligibility.
- An incomplete or abandoned Round awards no XP or completion bonuses.
- First Lesson completion awards 25 XP once; Lesson completion is independent of Duel victory.
- A Duel awards 50 XP on its first victory and 10 XP on every later victory; Duel victory does not complete the Lesson.
- Preserve reset-related scoring eligibility.
- Do not introduce new completion bonuses, multipliers, penalties, or reward types implicitly.
- The completion UI must show the actual persisted XP breakdown, never theoretical potential XP.
- Do not alter XP semantics during structural refactoring.
- Any deliberate scoring-system change must update direct scoring tests and relevant regression tests.

When a new XP system is explicitly introduced, update this section to describe the new authoritative rules rather than leaving obsolete scoring rules in `AGENTS.md`.

## Course Editor invariants

- The Course Editor holds an **unconfirmed working copy**. It must not produce or persist anything derived from that copy outside the single top-level Course confirmation: no export or package, no new Course identity (Copy as New Course, Fork), no install, no delete. Those act on **stored** Courses and belong to Course Manager. Reading library facts to validate what is being edited, such as warning that a Course name is already taken, is not a library operation and is allowed.
- Build 248 Revisions 2 and 3 removed three violations of this rule that had accumulated in the Editor: `course-editor-export-json`, `course-editor-save-json-to`, `course-editor-copy-as-new-course` and `course-editor-fork-course`. Each passed the working copy where the stored Course was meant, so a cancelled session could leave an exported package, or a persisted Course, built from changes that existed nowhere. A regression test had been pinning the Copy behaviour in place. Version History stays in the Editor because it works the other way: it loads **into** the working copy and still defers to the confirmation.
- Keep exercise type names friendly and concrete in the editor. Do not replace them with abstract/internal taxonomy.
- GuideBooks belong to Lessons.
- Lesson Guidebook content may be used to generate draft exercises/Rounds.
- Guidebook-generated exercises/Rounds must still be reviewed and explicitly approved before creation.
- Course Info contributor roles include `Illustrator`.
- Preserve existing contributor roles unless explicitly changed.
- User-created courses may be deleted only through the established double-confirmation flow.
- Remember the last selected course across app restarts.
- The Course Editor main page should retain access to Help.

## Exercise-content rules

- Word/letter block exercises may have 0, 1, or at most 2 distractor blocks.
- Prefer fewer distractors in early Rounds of a Lesson and more in later Rounds.
- A hint must not simply reveal the solution.
- Do not change content-generation rules unless explicitly requested.

## Settings invariants

- Learner Flag Background is Small / Off / Extended / Tinted / Inspired, per opaque learner ID × immutable Course ID, initialized Off. Inspired retains the `soft_inspired` storage value introduced in 227.02 revision 0. Preserve the clean cut: do not read, migrate or convert the old shared per-learner value. IDDQD is Off / On / View Only per learner × Course, initialized Off. Its compact control uses tooltip and accessibility explanations without permanent helper text. A genuinely locked Lesson keeps its lock and shows `Accessible with IDDQD` for On or `Preview with IDDQD` for View Only. Theme is Light / Dark / System / Day/Night per learner across Courses; compatible `default` storage displays as System, and Day/Night uses local 07:00/19:00 boundaries.
- Course membership is per opaque learner ID × immutable Course ID. Add/Remove from my courses controls both Selector and Manager without deleting shared files. The Available on this device page exposes four alphabetically sorted groups, Maintainer and Add/Remove controls. Hide/Unhide was removed in Build 241 Revision 2; retired course_hidden_ values are ignored, never converted into personal removals. Selector Import Course returns directly to study without activating Course Manager. Lesson display is Expanded / Collapse completed / Focused per learner × Course and initializes Expanded. It operates only on Lesson path visibility, uses authoritative completion/unlock plus IDDQD access, preserves current/last-visited Lesson behavior and never collapses Sections.
- Settings order is Profile, App Info, Audio Settings, Do Not Disturb, Debug, Version and Build, Update. Profile order is Avatar, Learner profiles, Gamification, Statistics, User Data, then Log out. Course Manager is opened from the learner Course Selector.
- Audio Settings is a clean per-learner boundary across Courses. Enable Audio Exercises uses `audio_exercises_enabled` and initializes Off; Off removes audio exercises from effective Round and Duel pools and cannot be bypassed by Duel. Text-to-speech uses `tts_enabled` and initializes Off; TTS voice uses `tts_voice_preference` and initializes System. All three keys live only below the active opaque learner prefix. Do not read, migrate, convert or delete the previous device-level `tts_enabled` / `tts_voice_preference`, device-level `skip_tts_exercises`, or per-profile negative `skip_all_audio_exercises` values. Audio Settings contains Enable Audio Exercises, Text-to-speech and the TTS voice selector with Test Voice in that order. Authoring Preview ignores learner Audio Settings and remains no-write.
- Preparing the first learner exercise may resolve its audio eligibility while `Before you start` remains visible, but TTS or recorded playback must not start until Continue makes the exercise active. Rounds without an introduction, Duel audio and Editor Preview retain their established timing.

- Keep the switch label exactly:
  `IDDQD Mode (you can walk through locks)`
- Keep its existing descriptive text unchanged unless the user explicitly asks to edit it.

## Security and robustness

- Course import is data-only. Never execute imported course content.
- Keep existing import size/format validation and Course Audit gates unless a deliberate migration requires a reviewed change.
- The GitHub update checker may check official releases, but must not automatically download, install, or execute software.
- Avoid adding network dependencies for learner/course functionality. QuisquisLingo remains offline-first.
- Do not weaken validation merely to make an import pass.
- Do not silently discard unknown or unsupported course data without a deliberate compatibility decision.

## Change discipline

- Any new persisted preference key or user-file folder must also be added to `AppResetService` (progress key prefixes, media folders, course keys), to `InventoryService`, and to `docs/239_RESET_STORAGE_INVENTORY.md`, so resets stay complete and the Inventory stays honest.
- Inspect the relevant code, call sites, tests, persistence keys, and documentation before editing.
- Before removing a symbol that appears unused, search for indirect, semantic, compatibility, or UI dependencies.
- Do not add unrelated refactors, renames, UI changes, formatting changes, or cleanup.
- Discovering an unrelated issue does not expand the task scope. Report it separately instead of fixing it unless the user explicitly adds it to the task.
- Do not replace or rewrite an entire file when a smaller targeted change is sufficient.
- Never suppress analyzer findings merely to obtain a clean result.
- Do not perform broad legacy lint cleanup unless explicitly requested.
- Do not change working app behavior merely to make a brittle regression test pass.
- If app behavior is correct and a test is coupled to source formatting, fix the test so it checks behavior or structure robustly.
- Prefer behavior-level tests over source-text tests.
- If a source-structure regression test is necessary, make it tolerant of LF/CRLF and harmless Dart formatting while preserving what it actually verifies.
- Avoid waits or test patterns that can hang indefinitely.
- Characterize important existing behavior before moving or rewriting it.
- When extracting an existing responsibility, move one authoritative implementation rather than creating two independent copies.
- Preserve compatibility through temporary delegation when that reduces the risk of a large caller migration.

## Git and repository discipline

- Do not commit unless the user explicitly asks for a commit.
- Do not push unless the user explicitly asks for a push.
- Do not stage unrelated files.
- Do not include unrelated generated files in a commit.
- Do not delete untracked user files merely because they are outside the requested scope.
- Do not use destructive Git commands such as broad `reset`, `clean`, `checkout`, or `restore` against user work without explicit approval and a clear reason.
- Before reverting a suspicious file, determine whether it contains genuine user changes.
- After Flutter commands, generated platform registrant files may appear modified because of metadata or line-ending normalization. Verify their actual content before treating them as code changes.
- LF/CRLF warnings alone are not evidence of a functional code change.
- If a generated file is byte-identical to `HEAD`, do not include it as a meaningful project change.
- Review `git status --short` and the final diff before reporting completion.
- Verify that every changed line is necessary for the requested task. If a changed line cannot be justified by the task, revert that change before reporting completion.

Do not modify Codex's global approval policy, sandbox policy, or user-level command rules as part of normal repository work unless the user explicitly requests that configuration change.

## Test execution efficiency

- During implementation, run the smallest relevant focused tests for rapid feedback.
- Once the implementation is final, run the analyzer and the complete Flutter test suite exactly once on the final working tree.
- Do not rerun focused test groups solely for reporting when they have already passed and are included in the complete suite.
- Continue running validators or checks not included in the Flutter suite.
- If source or test files change after the complete suite, rerun the affected focused tests and then rerun the complete suite before committing.
- A failed full-suite test may be rerun in isolation for diagnosis.

## Workflow efficiency

### Repository text inspection on Windows

- Use `rg` as the primary tool for locating files, searching text and reading relevant sections of repository text files.
- Do not use PowerShell `Get-Content` in this repository. It has repeatedly hung even on small regular Markdown files.
- Do not use `Get-Content -Wait`.
- Use targeted `rg -n` searches instead of dumping entire large files.
- When comparison with Git is sufficient, prefer `git diff`, `git show`, `git status` and `git ls-files`.
- If `rg` is unexpectedly unavailable, open a fresh shell once to refresh `PATH`. If it remains unavailable, use `Select-String` or `[System.IO.File]::ReadLines(...)`. Do not fall back to `Get-Content`.
- Do not install or reinstall command-line tools during a task unless the user explicitly requests it.

### Bounded command waiting

- Match the waiting period to the command type.
- Repository metadata and text-inspection commands such as `git status`, `git diff`, `rg`, `Select-String` and file metadata reads should normally respond quickly.
- If a read-only inspection command produces no output or completion for 15 seconds, interrupt it and use a different inspection method.
- Do not retry the identical command after it hangs.
- Do not wait silently for several minutes on a normally immediate command.
- Long-running analyzers, builds, validators and test suites may continue while they are producing progress or consuming resources normally.
- Run long commands with bounded output-yield intervals so control returns at least every 30 to 60 seconds.
- When a long command remains active, poll the existing process instead of starting duplicate commands.
- Provide a concise progress update at least once per minute during a long-running command.
- If a long command produces no progress, inspect its process state and distinguish a normal quiet phase from a real hang before terminating it.
- Never classify a generic terminal read failure as a Flutter SDK lock, repository deadlock or test deadlock without direct evidence.
- After interrupting a hung command, report the exact command, elapsed time and replacement method, then continue the task.

### Worktree policy

- For ordinary QQL work, continue in the user's existing local checkout.
- Do not create, switch to or spend time evaluating a Git worktree unless the user explicitly requests one or the task demonstrably requires isolation that cannot be achieved safely in the current checkout.
- If isolation would materially change the workflow, ask the user before creating a worktree.
- Do not create a worktree solely to inspect a parent commit, compare documentation or calculate analyzer deltas.
- Use `git diff`, `git show` and recorded validated baselines for those comparisons.
- Never allow worktree evaluation to block the task or prevent queued user messages from being processed.

### Efficient Flutter validation

- During implementation, run the smallest relevant focused tests for rapid feedback.
- After a failure, rerun only the affected focused tests until the correction is stable.
- Once implementation is final, run `flutter analyze` and the complete Flutter test suite exactly once on the final working tree.
- Do not rerun overlapping focused groups solely to produce separate final-report totals when those tests have already passed and are included in the complete suite.
- Continue to run validators and checks that are not included in the Flutter suite.
- If any production or test file changes after the complete suite, rerun the affected focused tests and then rerun the complete suite before committing.
- A failing test from the complete suite may be rerun in isolation for diagnosis.
- Do not start the complete suite while known focused failures or newly introduced analyzer findings remain.
- Do not run multiple Flutter commands concurrently when they share the same SDK lock, build directory or cache.

### Recovery and user control

- Keep tool calls bounded so the agent can receive queued user instructions between operations.
- Do not remain inside an unresponsive tool call indefinitely.
- If the user asks to stop or redirect work, yield control at the next safe command boundary.
- Preserve all already-written working-tree changes after an interruption.
- Resume by inspecting the existing status and diff. Do not restart the implementation from scratch.
- Never run destructive Git recovery commands unless the user explicitly authorizes them.

## Validation before delivery

Run, when the environment provides Flutter/Dart:

```bash
flutter pub get
flutter analyze
flutter test

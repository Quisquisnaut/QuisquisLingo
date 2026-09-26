// English source text for the localized Help, Course Info and Locale slice.
// Keys are stable and ordered by surface; keep UI command names in English.
const Map<String, String> helpEn = <String, String>{
  'editorHelp.coursesInLearnerMode.title': r'''Courses in learner mode''',
  'editorHelp.coursesInLearnerMode.body':
      r'''Course Library, at the bottom of Course Selector, lists every Course on this device in Bundled Courses, Publisher Courses, My Local Courses and Other Local Courses. By default it hides unavailable or Draft Courses; a switch shows them. Sort by and each section's Expanded / Compact button change only the view. Add to my courses adds a shared course to your Selector and Course Studio without granting editing rights. Remove from my courses removes it from both for your profile only; progress is kept unless you explicitly choose Reset my progress. Even with reset selected, all XP (including Weekly XP), total and per-language study days and streak remain; XP earned from this course is not subtracted. Only an admin can Remove Publisher Course from device, and only if no other profile includes it. Progress and version backups survive uninstall. With no playable courses, Home keeps Settings and Course Studio when activated; no course flag is displayed. The page has its own Help, Course covers or flags, Version, Last edited, Maintainer and Duration details, and an Added · Remove action. Import Course in the Selector returns directly to study; it does not activate Course Studio. Continue to Editor prepares a new course; it is saved only with Confirm course changes. Change course lists Published courses in your personal library: the bundled official courses included with QuisquisLingo and Published courses under Local courses. Courses that are Not published stay available for authoring but cannot become the active learner Course. Selecting a Published course makes it current. The learner page resumes the active Published Lesson for that learner and course. When a course has real Sections, the fixed Section selector opens its ordered consecutive Published Section blocks and jumps to each block's first Lesson.''',
  'editorHelp.courseOrigin.title': r'''Course origin''',
  'editorHelp.courseOrigin.body':
      r'''Bundled official courses are verified immutable source copies supplied with QuisquisLingo. Publisher Course imports require a valid Ed25519 signature from an approved publisher. Stored external courses that cannot be verified are preserved with Verification required and are excluded from learner delivery. Custom courses are created locally or imported without official provenance. Both official origins open Official course - read only: inspect Course Info, Audit, Preview, Version History and Lessons/Rounds/Exercises without an authoring transaction. Course Info shows publisher, official version, verification status and checksum. Only an explicit derivativeWorksPolicy of allowed enables Fork; forbidden or unspecified permission explains why it is unavailable. A Fork has fresh IDs and independent custom history while preserving its source lineage. Copy as New Course is a separate action that begins a new independent lineage.''',
  'editorHelp.temporarySampleContent.title': r'''Temporary sample content''',
  'editorHelp.temporarySampleContent.body':
      r'''Course Editor starts in View only for a course with no saved access choice. Choose Edit only for the course you intend to change. A course may be marked TEMPORARY SAMPLE while it contains development or demonstration material. View Course Info retains that description; the main Course Editor does not repeat it. Replace sample material with reviewed educational content before distribution.''',
  'editorHelp.courseEditorLockAndStructure.title':
      r'''Course Editor lock and structure''',
  'editorHelp.courseEditorLockAndStructure.body':
      r'''The single access control is on the Course Editor root. Locked uses a closed lock, keeps that root visible and blocks entry into Lessons. View only uses an eye, is the default and opens the ordinary Exercise form read-only while allowing Search, Help, Show/Hide IDs, Preview and Audit. Inspection mode uses the code icon and opens Exercises in their read-only technical presentation by default; their local Inspection toggle can show the ordinary form, which remains read-only. Edit uses the pencil and enables authoring only when the current user already has effective Course Maintainer or assigned-Team permission; the control never grants authorization. Official courses and outsiders offer Locked, View only and Inspection mode, with the Edit authorization reason shown in the Editor. The first View-only entry notice is dismissed per user and Course; Show one-time notices again resets it without changing the access state. For custom courses, Lessons is the first content section. Each Lesson page puts Rounds first, followed by Round / Exercises. A duplicate Lesson, Round or Exercise is inserted after its source with fresh IDs throughout its owned subtree and starts as Draft. Exercise type cannot be changed after creation. Each Lesson retains its GuideBook and stable Lesson-scoped Duel identity.''',
  'editorHelp.courseEditorSearch.title': r'''Course Editor Search''',
  'editorHelp.courseEditorSearch.body':
      r'''The Search icon appears on Lessons, Lesson, Rounds and Round while the Course Editor is unlocked. Lessons searches the whole Course; Lesson and Rounds search their current Lesson; Round searches only that Round. Search accepts complete words, contiguous multi-word phrases and exact or partial Exercise IDs. Text matching ignores case and diacritics. An optional Exercise Type filter defaults to All exercise types. Results show Lesson, Round, friendly Exercise type, a matching excerpt and, while Internal IDs are shown, the Exercise ID. View only opens a result in the ordinary read-only Exercise form, Inspection mode opens its read-only technical presentation, and Edit opens the ordinary editable form. Locked exposes no Search. Search reads the shared exercise-type field inventory and never modifies a Course.''',
  'editorHelp.optionalLessonLearningPaths.title':
      r'''Optional Lesson learning paths''',
  'editorHelp.optionalLessonLearningPaths.body':
      r'''Use GuideBook and Create Duels are on the Lessons page and both default ON. Use GuideBook OFF preserves all GuideBook content, Draft state and source references. The learner still sees the Lesson identity and book artwork, but no GuideBook tooltip, click or action semantics; the Round introduction also omits its GuideBook action, including in Preview. Only LESSON_GUIDEBOOK_EMPTY is suppressed; malformed existing content still receives canonical findings. Reenabling updates the current canonical Audit and ancestor borders. Create Duels ON uses the shared pool of 25 actual eligible, deduplicated Exercises. Disabled or insufficient Duels have no learner card or reserved Duel spacing. DUEL_UNAVAILABLE is Info only while Create Duels is ON. Neither switch erases content, existing Duel victories, completion or XP.''',
  'editorHelp.sectionAssignmentsAndNames.title':
      r'''Section assignments and names''',
  'editorHelp.sectionAssignmentsAndNames.body':
      r'''The Lesson Section selector offers No section, existing names, Add new section... and Manage sections.... New names are trimmed and must not be blank. The reusable course catalog also discovers existing Lesson assignments. Removing an assigned name is blocked with its Lesson usage count; change those assignments first. A name selected in the unsaved Lesson is protected too. New Lessons default to the immediately preceding Lesson's Section, or No section if none applies. Selecting No section explicitly clears this Lesson assignment. Consecutive assignments still determine visual Section blocks; Sections own no IDs, progress or unlocks.''',
  'editorHelp.courseFlagSources.title': r'''Course flag sources''',
  'editorHelp.courseFlagSources.body':
      r'''Create new course and Course Info Editor use the same searchable visual flag chooser. It identifies the current source as a QQL FlagPainter Flag, WORLD Flag or Custom Flag, then offers Upload custom flag, the permanent QQL FlagPainter Flags catalog and the complete WORLD Flags catalog. Search includes names, aliases, stable IDs, language codes and territorial codes. QQL FlagPainter Flags are programmatic graphical reinterpretations associated with languages and never depend on installed Courses. Opening, searching or cancelling changes nothing; only choosing a result, Use Automatic or Upload custom flag changes the current working selection. Use Automatic prefers the associated QQL FlagPainter Flag, then the primary associated WORLD Flag, and otherwise leaves no automatic flag. WORLD Flags store only their stable worldFlagId, QQL FlagPainter Flags store flagCode and custom flags store validated normalized PNG bytes in flagImageBase64.''',
  'editorHelp.oneCourseEditorTransaction.title':
      r'''One Course Editor transaction''',
  'editorHelp.oneCourseEditorTransaction.body':
      r'''Opening a custom course maintains a working copy beside an immutable snapshot of the persisted course. View only and Inspection mode never change that working copy. In Edit, every Course Info Editor, Lesson, Round, Exercise, GuideBook, generator and reorder operation changes only the working copy. Course delivery status is Published or Not published; publishing the Course preserves independent descendant Draft states. Nested Save stores a normal item in the working copy; Save as draft stores a Draft item there. Neither action changes the learner-visible course, creates a backup or increments the course version. Leaving an Exercise with unsaved form changes offers Keep editing, Discard changes, Save as draft or Save. Discard affects only that form; earlier working-copy changes remain. Switching away from Edit with unapplied course changes uses the same authoritative confirm/cancel protection rather than silently discarding them. Other nested pages retain their established Back behavior. Navigation among nested pages never shows the final course confirmation.''',
  'editorHelp.provisionalAndExplicitParentDrafts.title':
      r'''Provisional and explicit parent Drafts''',
  'editorHelp.provisionalAndExplicitParentDrafts.body':
      r'''Automatically created Lesson and Round Drafts can be provisional. Their blue Draft badges include the container itself, even when every child has a green Audit border. Saving reviewed Exercises as normal content makes a provisional Round eligible to become Published when its complete required content is ready and normal Save validation passes. A provisional Lesson also needs ready Published Rounds and, while Use GuideBook is ON, a Published nonempty GuideBook with its required content ready. Nonblocking Audit guidance remains visible. This reconciliation follows normal working-copy changes, including GuideBook changes, the Use GuideBook switch, deletion and Move; it never publishes an Exercise or GuideBook for you. Explicit Save as draft clears provisional eligibility, even if the container was already Draft. An explicitly Draft Lesson or Round and older Drafts without this eligibility stay Draft until their own normal Save. Imported authoring trees, copies and licensed forks also remain review Drafts. Course delivery stays an explicit Published or Not published choice, and no working-copy change reaches learners until Confirm course changes succeeds.''',
  'editorHelp.confirmOrCancelCompleteCourse.title':
      r'''Confirm or cancel the complete course''',
  'editorHelp.confirmOrCancelCompleteCourse.body':
      r'''Leaving the top-level Course Editor compares the complete working copy with the original course. If they are semantically identical, the Editor closes directly. Otherwise exactly one dialog offers Confirm course changes or Cancel course changes and an optional multiline version note. Confirm first creates and verifies a complete backup, then increments the separate internal course version by exactly one and atomically applies the whole working copy. Cancel discards the entire working copy without a backup or version increment. A failed backup or persistence keeps the working copy open and leaves the persisted course unchanged.''',
  'editorHelp.localCourseEditsAndBackups.title':
      r'''Local course edits and backups''',
  'editorHelp.localCourseEditsAndBackups.body':
      r'''Every confirmed change to an existing custom course first archives the complete currently persisted course in QQL's private storage, one folder per Course ID. Backup manifests include the full v11 Course, Course Maintainer, optional Assigned Team, provenance, versions, authors, UTC modification timestamp, optional notes, checksum and referenced managed audio assets. Backups are never pruned automatically. Version History lists the current version and verified backups newest first, with Open backup folder and Export JSON. Only custom history supports Restore into working copy. Official history contains publisher sources only; older backup directories are not loaded or deleted. A restore is still only a working-copy change until the top-level confirmation succeeds.''',
  'editorHelp.androidDeviceBackupTechnical.title':
      r'''Android device backup (technical)''',
  'editorHelp.androidDeviceBackupTechnical.body':
      r'''QuisquisLingo has no account and no server, so on Android the platform's own Auto Backup is deliberately left enabled: it is the only way a learner keeps their work through a lost or replaced phone. Backed up on purpose: learner profiles, progress, XP, streaks, Review history, local Course edits, authoring Teams, settings, the Access PIN verifier and the User Recovery Key credential. The Access PIN is included knowingly. It is a casual-access guard for a shared family device, not a security boundary, and excluding it would only mean a restored learner silently loses their PIN. Excluded from cloud backup: imported Image Banks, imported exercise images and recorded MP3s. The reason is capacity, not privacy. Android allows one app 25 MB of Auto Backup, a single Image Bank import may reach 50 MB, and an app that exceeds the quota has its backup silently switched off entirely rather than partially. That media can be imported again from your own files; progress cannot. A direct phone-to-phone transfer carries no such quota and still moves the media. For authors this matters in one practical way: a Course you have written is backed up, but the images and audio you imported into it are not, so keep the original media files and your exported Course JSON. Whether Auto Backup runs at all is an Android setting owned by the device owner; QQL never uploads anything itself. Two resource files define this and must always be changed together, because android:dataExtractionRules is ignored below API 31: res/xml/data_extraction_rules.xml for API 31 and above, and res/xml/backup_rules.xml for API 30 and below. A Device Administration reset removes local data but cannot reach a backup Android has already taken.''',
  'editorHelp.officialCourseUpdates.title': r'''Official course updates''',
  'editorHelp.officialCourseUpdates.body':
      r'''A newer verified official course update is accepted only for the same courseId and publisher and only when its checksum is valid. Before replacement, QuisquisLingo archives the previous official source. The new source becomes current. Existing custom forks and their histories stay unchanged, with no merge or rebase. Old Build 225 official overrides are not used, converted or deleted. If the publisher signature cannot be verified, import is blocked. An existing unverified course is preserved and requires explicit association with a newer signed release before reactivation.''',
  'editorHelp.courseInfoEditorAndLicense.title':
      r'''Course Info Editor and license''',
  'editorHelp.courseInfoEditorAndLicense.body':
      r'''Course Info Editor stores structured Authors / Contributors, Rights Holder, the content License and an optional Buy a Coffee HTTPS link separately from the MPL-2.0 license of the QuisquisLingo software. Attribution and rights information are descriptive and never grant QQL permissions. Rights Holder may name one or more people or organizations without requiring local user identities. Choose All rights reserved, CC0 1.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, CC BY-NC-SA 4.0, or Other / Custom license; a custom license also records its outsider derivative policy. Official content and provenance remain read-only.''',
  'editorHelp.courseResponsibilityPermissionsAndTeams.title':
      r'''Course responsibility, permissions and Teams''',
  'editorHelp.courseResponsibilityPermissionsAndTeams.body':
      r'''Original Course Creator, Course Maintainer, Assigned Team, Authors / Contributors, Rights Holder, License and fork/merge provenance are separate. Every v11 custom Course has an immutable Original Course Creator and one individual Course Maintainer. Only the current Course Maintainer can transfer maintainership or assign and revoke a Team for management. The Course Maintainer and every current member of the Assigned Team may manage Course content under QQL permissions; Team leadership controls Team membership and roles only. Teams are an experimental QQL collaboration model and may manage Courses maintained or created by different individuals. QQL permissions govern behavior inside QQL and do not by themselves determine copyright ownership, contractual rights or external organizational authority. Attribution, provenance and Rights Holder metadata never grant permissions. Outsiders cannot mutate or Copy as New Course under the current access policy and can Fork only when derivatives are allowed. Bundled Courses use this same Editor surface in read-only mode.''',
  'editorHelp.importCustomCourse.title': r'''Import a custom course''',
  'editorHelp.importCustomCourse.body':
      r'''1. Copy a supported Course ZIP to {folderCourseImports}/import.zip, or a media-free Course Model v11 JSON to import.json; keep only one. The ZIP normally has course.json, qql-course-package.json and media/ at its root. QQL also accepts one enclosing folder whose name exactly matches the ZIP filename without .zip and shows a non-blocking warning; for import.zip, the folder must be named import. 2. In Course Studio, open Course Import and select Quick Import. 3. QQL checks the whole package and Course Audit before installing the Course and its own media. Audit errors block import; warnings are reported. Images copied from an Admin Shared Image Library stay with the imported Course and are not added to the recipient device’s Shared Image Library. An external-official Course requires a valid approved-publisher signature; an ordinary custom import stays custom. The source file remains in {folderCourseImports}. A JSON import must be valid UTF-8 and at most 10 MB; a Course ZIP may be at most 300 MB compressed and expanded. Earlier Course formats are refused without migration or deletion.''',
  'editorHelp.exportCustomCourse.title': r'''Export a custom course''',
  'editorHelp.exportCustomCourse.body':
      r'''Quick Export in Export Course saves the complete Course Model v11 authoring JSON and all referenced Course-owned images and recordings in one ZIP under {folderCourseExports}. App-bundled media stay supplied by QQL. Admin-added Shared Image Library images used by the Course travel as Course media with their library ID, label, category, tags, origin and available per-image attribution. An Admin can enter author, license, title and source in the library’s Edit metadata dialog; importing the ZIP does not add images to the destination Shared Image Library. Original Creator, Maintainer, optional Team, authors, rights, License, fork/merge provenance, Draft/Published state and version metadata remain in the JSON. Fork preserves its source lineage; Copy as New Course starts an independent lineage. Save as… can write the same ZIP through the system dialog where available.''',
  'editorHelp.importCustomFlag.title': r'''Import a custom flag''',
  'editorHelp.importCustomFlag.body':
      r'''Copy a valid PNG or JPEG to {folderCourseFlagImports} as flag.png, flag.jpg or flag.jpeg, open the shared Course flag chooser and press Upload custom flag. If several names exist, QQL uses the first in that order. Maximum input: 2 MB (2,097,152 bytes). Minimum dimensions: 64 × 40 pixels; maximum: 4096 pixels on either side. QQL checks the actual PNG/JPEG signature and decodes the image. Images larger than 256 pixels on their longest side are reduced proportionally; smaller accepted images are not enlarged. The first image frame becomes PNG without cropping or a square canvas. Existing PNG transparency is retained; JPEG does not acquire a transparent background. PNG data are embedded in the Course and survive course JSON export/import and duplication. The transfer source is left in place and is no longer needed. Missing, unreadable, unsupported, oversized, too-small or over-resolution input produces an error; failed PNG conversion also stops import.''',
  'editorHelp.generateRoundsFromLessonGuidebook.title':
      r'''Generate Rounds from Lesson GuideBook''',
  'editorHelp.generateRoundsFromLessonGuidebook.body':
      r'''Open a Lesson and choose Generate Rounds from GuideBook. The generator uses only vocabulary pairs and examples in that Lesson GuideBook; at least three usable target/source pairs are required. Choose 1–12 Rounds and 1–15 Exercises per Round (defaults: 6 and 8). Review the count, total, normalized progressive-difficulty curve and planned registry presets before generation. Early drafts emphasize guided recognition with fewer distractors, middle drafts add construction and context, and later drafts add freer production. Generated Rounds remain drafts: edit, preview, delete or regenerate them, then explicitly approve them to append fresh-ID copies after existing Rounds. Generation cannot guarantee pedagogical correctness, so every Round and Exercise requires human review.''',
  'editorHelp.exerciseCreationWizard.title': r'''Exercise Creation Wizard''',
  'editorHelp.exerciseCreationWizard.body':
      r'''In a Round, Exercise Wizard sits beside New exercise. Choose 1–30 Exercises and select Balanced mix, Random mix, one or more categories, exact exercise types, or an ordered repeating pattern. The reviewed plan creates no Exercise objects. After confirmation, each planned step opens the ordinary preset-specific Exercise editor. Save validates and stays on the step; Preview returns to the same draft without copying or advancing; Next validates and advances one step; Finish returns the created Exercises in plan order. If you cancel after explicitly saving work, confirm whether to keep only those valid saved Exercises. Future and invalid placeholders are never inserted.''',
  'editorHelp.duplicateCopyMoveExercises.title':
      r'''Duplicate, Copy and Move exercises''',
  'editorHelp.duplicateCopyMoveExercises.body':
      r'''Duplicate inserts an independent fresh-ID copy immediately after the source. Move Exercise to… and Copy Exercise to… choose an explicit Course > Lesson > Round destination within the current course working copy. Move Round to… and Copy Round to… choose a Lesson there. Move preserves stable identity, content and Draft/Published state and removes the source from its previous parent. Copy allocates fresh IDs throughout the owned subtree and remaps internal references. Following the existing duplication policy, copies and their owned descendants start as Draft. Image and recording references (course media named by content) are copied unchanged, and the files stay in the Course’s media folder. These actions affect only the working copy until Confirm course changes.''',
  'editorHelp.exercisePreviewAndNavigation.title':
      r'''Exercise Preview and navigation''',
  'editorHelp.exercisePreviewAndNavigation.body':
      r'''Preview beside Inspection and Save uses the complete current unsaved Exercise form, including a new or Draft Exercise. It uses learner rendering without saving content, changing Draft/Published state, creating versions/backups or writing learner progress, XP, Weekly XP, streak, Laurel, Review or Duel state. Inspection is a local presentation toggle only: it shows or hides the technical representation without changing Course Editor access, saving, discarding or creating dirty state. Turning it off returns to the normal form; that form is editable only while the root state remains Edit and the user has actual permission. Existing unsaved Edit values remain intact through the presentation round trip. Insufficient runtime data produces a validation message without losing edits. Returning restores the same field values. Previous and Next follow the current Round order and stop at its boundaries. Back, sibling navigation and safe breadcrumb navigation protect unsaved Exercise changes with Keep editing, Discard changes, Save as draft or Save. Saving here affects only the course working copy. Breadcrumbs show readable Course, Lesson, Round and Exercise context.''',
  'editorHelp.fieldHelpAndUntitledRounds.title':
      r'''Field Help and untitled Rounds''',
  'editorHelp.fieldHelpAndUntitledRounds.body':
      r'''Use the Help control beside an Exercise field for its purpose, entry count, line rules, format, validation and examples. Context mode, each correct-translation entry and Exercise image have their own Help. Broad Exercise Help remains available beside the preset. Typed answers support the existing answer-expression syntax; Arrange answers and listening gap lists are literal. An empty Round title is intentionally supported in Create and Edit Round. Follow the untitled guidance to keep it blank; its displayed Round N label follows its position without creating a stored title.''',
  'editorHelp.audioLibrary.title': r'''Audio Library''',
  'editorHelp.audioLibrary.body':
      r'''Choose On-Device TTS, Recorded MP3 or Hybrid. On-Device TTS uses this device voice without recordings; Check unused MP3 files, Import MP3 and Open MP3 from... appear only in Recorded MP3 or Hybrid. There are two ways to add recordings, and both apply the same checks and store the file in the same place: copy MP3 files to {folderAudioImports} and press Import MP3 in Audio Library, or use Open from… to pick one or more MP3s (up to 100 files and 250 MB at a time) in the system file dialog; a summary then lists each file's result. Cancelling a dialog changes nothing, and a dialog that cannot open explains the fixed-folder route instead. Every .mp3 file there is copied into the Course’s own media folder, derived from the stable Course ID, and named by its content (media:<fingerprint>.mp3), so identical recordings are stored once, with a maximum of 50 MB (52,428,800 bytes) per file. The metadata and references belong to the Course. No MP3 files or an oversized file produces an error. Every file must be a real MP3: MPEG audio Layer III frames from start to end, optionally with ID3 or APE tags up to 2 MB in total. A file that is something else renamed to .mp3, is damaged or cut short, or carries embedded cover artwork is refused (remove the cover image and try again). From the folder, one refused file means nothing is imported. A recording the Course already has is skipped. The same check applies to the recordings inside a Course ZIP when it is imported. Import does not re-encode recordings or enforce a duration, bitrate or sample-rate rule; preview each recording to check playback. Source files remain in place, so move them out after successful import to avoid importing them again. Associate each recording with the exact word or expression it contains. Recorded playback uses longest-match segmentation and concatenates compatible clips. Hybrid falls back to TTS when a complete recorded sequence cannot be assembled. Course JSON stores clip metadata and these content references, not MP3 bytes; JSON alone does not transfer the recordings to another device. Verified course-version backups copy referenced recordings. Export my data is a separate learner backup and does not include course media; a distributable Audio Pack exporter is not currently available.''',
  'editorHelp.imageBank.title': r'''Image Bank''',
  'editorHelp.imageBank.body':
      r'''Images and Image Bank ZIPs can be added two ways, and both apply the same checks and store the file in the same place: through {folderImageImports}, or with Open image files from… (up to 100 images at once) and Open Image Bank ZIP from… in the system file dialog. Every image is checked by its content, not its name: it must really be a still PNG, JPEG or WebP of at most 4096 × 4096 pixels, undamaged and without oversized embedded metadata, and QQL stores it under a name it chooses. In the Course Editor’s Image Library, anyone editing the Course can also add images, several at once, or a whole Image Bank to that Course’s own library with Add images to this Course: they stay unused until an exercise uses them, travel in the Course ZIP, and never enter the Shared Image Library. For the fixed folder, keep exactly one supported image for a single-image import, or exactly one ZIP for Import Image Bank ZIP. Cancelling a dialog changes nothing, and a dialog that cannot open explains the fixed-folder route instead. A manifest is a small UTF-8 JSON text file that tells QQL which pictures are in the bank and how to label them. Write it in a plain-text editor, save it as image_bank_manifest.json (not .txt), and add it to the ZIP with every image it names. For a minimal example, write [{"id":"apple","primary_term":"apple","keywords":["apple"],"filename":"apple.png"}] and put apple.png in the ZIP too. A bank needs image_bank_manifest.json containing a JSON list, or an object whose images field is that list and whose optional attribution field credits every image that has no credit of its own. Every entry needs a unique id (1–128 letters, digits, dots, hyphens or underscores), primary_term or label (up to 200 characters), and a safe filename referring to a PNG, JPG/JPEG or WebP in the archive; at most 32 keywords of up to 80 characters each. The ZIP may hold only the manifest and the images it lists: a credits or readme file stops the import, because credits belong in the attribution field. Links, encrypted entries, archives inside the archive and unsafe paths are refused. When a bank brings categories this device does not have yet (at most 16), an Admin chooses Add them, Put these images under Other, or Cancel; nothing is stored before that choice. A picture that is already in Shared Images, byte for byte, is skipped without asking, whatever its name. When a bank image has the same id as a different picture already there, the Admin chooses Skip, Replace (never for QQL’s own images) or Keep both (the new one gets a new id), and can apply the answer to all the rest. Limits: 50 MB ZIP, 2 MB manifest, 5000 archive entries, 2500 image entries, 50 KB per image and 50 MB total decompressed image bytes. Missing assets, duplicate/colliding IDs, duplicate filenames, unsafe paths, unsupported extensions and exceeded limits stop import. Image bytes are copied unchanged to local app storage with a local manifest; they are not resized or made transparent. Source ZIPs remain in place. Preview images before selection. In the full-size preview, hover over the picture on a computer or long-press it on a phone to see its file name, approximate size, dimensions, format, added date, Image Bank name and attribution. A missing file says File missing; a merged Course copy is identified there too. Tiles do not show this tooltip. Choosing a library or bank image for an Exercise copies it into the Course’s own media, so later library changes do not affect the Course; Course JSON names it by content and does not embed the image bytes.''',
  'editorHelp.lessonThemeIconsAndPreview.title':
      r'''Lesson theme icons and Preview''',
  'editorHelp.lessonThemeIconsAndPreview.body':
      r'''Each Lesson can select a Preinstalled icon, a Custom Course icon, or Numbers. The Preinstalled icons show only the current choice until you tap them. For Import custom icon, keep exactly one PNG, JPG/JPEG or WebP in {folderLessonIconImports}. Maximum input: 2 MB (2,097,152 bytes); each dimension must be 1–4096 pixels. QQL decodes the first frame and scales it up or down proportionally, centered on a transparent 256 × 256 PNG canvas without cropping or distortion. Existing transparency is preserved; an opaque source background is not removed. Missing/multiple files, empty or unsupported images, exceeded size/dimensions and failed PNG conversion stop import. The source remains in place. The managed Course-owned asset stores embedded PNG data; its reference survives course JSON export/import and Course duplication, with no external source path required. Lesson duplication within the Course reuses the immutable asset. When a Lesson has no explicit icon, QQL uses the single theme-colored Lesson-number circle in Editor and learner views. Legacy fallback-style values still load but no longer alter this rendering. Explicitly selected icons remain unchanged. Every option uses the established 84 × 84 learner footprint. Preview writes no learner progress.''',
  'editorHelp.exerciseImageSpecifications.title':
      r'''Exercise image specifications''',
  'editorHelp.exerciseImageSpecifications.body':
      r'''For Import custom image, keep exactly one PNG, JPG/JPEG or WebP in {folderImageImports}. Maximum: 50 KB (51,200 bytes). A 256 × 256 resolution and 15 KB or less are recommendations; this importer imposes no pixel-dimension rule and performs no resizing, cropping or transparency conversion. It checks the filename extension, file count and byte size, then copies the bytes unchanged to local app storage. The source stays in place. Missing/multiple sources or an oversized image stops import; Preview reports missing or unreadable images. The Exercise then uses a copy in the Course’s own media, named by content; Course JSON stores that reference, not the file bytes, so importing the JSON alone elsewhere does not transfer custom exercise images. Built-in asset paths refer to images supplied with QQL. An Exercise image is optional except for Image-prompt ordering.''',
  'editorHelp.newExerciseTypes.title': r'''New exercise types''',
  'editorHelp.newExerciseTypes.body':
      r'''Missing Word plays audio while showing its transcript with one or more words removed. Image Word shows an image and asks the learner to build the corresponding target-language word from letter or syllable blocks. Dialogue Response contains a target-language context sentence, a target-language question and exactly two target-language response options; their display order is randomized. Word Match uses exactly three source-to-target translation pairs. Super Match uses exactly three target-language pairs and an explicit relationship such as synonyms or opposites. Audio Match uses three target-language audio items with exactly three matching texts and no distractors; the matching text may be in the target language or a translation. Listening Spelling / Type what you hear plays target-language audio and requires keyboard input; its prompt is displayed as entered and Return/Enter submits. Sentence Word Order exercises may use 0, 1 or at most 2 distractors. Image Word letter/syllable composition never uses distractors: include only the blocks required for the answer. Gap Choice shows a target-language sentence with one missing element and asks the learner to choose the single block that is correct in both meaning and grammar.''',
  'editorHelp.languageDuel.title': r'''Language Duel''',
  'editorHelp.languageDuel.body':
      r'''Each Lesson owns its Duel. The Duel attached to the final Lesson is presented as Final Duel, with the tooltip Final challenge for the last Lesson. It retains the same mechanics and never claims to unlock another Lesson. A standard Duel selects 25 unique eligible exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or pass threshold: completing all 25 questions before all four lives are lost wins. Availability is determined from the actual eligible exercise pool, not from the number of Rounds or the total theoretical exercise count. If fewer than 25 eligible exercises exist, the Duel is simply unavailable for that Lesson; this is normal supported behavior, not a course error.''',
  'editorHelp.courseCreationRules.title': r'''Course creation rules''',
  'editorHelp.courseCreationRules.body':
      r'''A Lesson should normally contain at least 6 Rounds, which in typical content may mean roughly 48 exercises. This is author guidance only: it is not a validity requirement and never determines Duel availability. The standard Round contains 15 exercises. Avoid accidental duplicate content inside one Round. Isolated words should normally be lowercase unless the language requires capitalization, as with German nouns or proper names. Opposite exercises belong in later Rounds, after the learner has already met the vocabulary. Sentence Word Order may use 0, 1 or at most 2 distractors; use fewer distractors early in a Lesson and more later. Distractors should be plausible but unambiguously wrong. Learner-facing operational instructions must use the course source language. Early Rounds should introduce and consolidate material; later Rounds can demand harder discrimination and combinations.''',
  'editorHelp.listeningSpelling.title': r'''Listening Spelling''',
  'editorHelp.listeningSpelling.body':
      r'''Type what you hear uses Audio text for playback and the Missing word field for accepted typed answers, one complete word or passage per line. Passage transcript is displayed as entered; this preset does not automatically remove the accepted word from it. Preview the visible prompt so it does not reveal the answer. For automatically hidden words in a complete transcript, the existing Listen for missing words preset supplies that workflow.''',
  'editorHelp.lessonGuidebook.title': r'''Lesson Guidebook''',
  'editorHelp.lessonGuidebook.body':
      r'''Each Lesson has its own Guidebook, available to learners when published and Use GuideBook is ON. Its primary authoring fields are Overview, Usage examples, Vocabulary and Grammar, in that order. Insights opens a second authoring page for ordered Title and Text sections; changes remain in the current GuideBook working copy until Save Guidebook or Save Guidebook as draft, and removing a section requires confirmation. Save Guidebook as draft keeps it out of learner delivery and shows one blue Draft badge on the Guidebook and its visible ancestors. The badge is independent from Audit: an empty Guidebook has a red border while Use GuideBook is ON; any other canonical Guidebook Error or Warning stays red regardless of that preference. A clean Draft Guidebook remains green with its blue badge. The editor can use its vocabulary and examples to propose new exercises.''',
  'editorHelp.courseMetadataAndAuthors.title':
      r'''Course metadata and authors''',
  'editorHelp.courseMetadataAndAuthors.body':
      r'''Course Info is available in Locked, View only and Inspection mode. Course Info Editor is available only in Edit for users with existing edit permission. It can change the visible Course name without changing the Course ID. Base and Learning language remain read-only and show their authoritative general or regional codes. Original Course Created is immutable lineage provenance; Last Version Editor and Modified describe the current Course version and instance. Opening the editor changes none of them. Automatic Course flag removes every explicit override and uses the language fallback; choosing a built-in, World Flag, uploaded flag or authorized reusable installed-course flag stores only its portable value. Structured Authors / Contributors and Rights Holder metadata are descriptive and never authorize access. Original Course Creator and Course Maintainer use separate stable internal identities. Course Info separately resolves the Assigned Team, Team Leaders and Team Members from Team Manager. Internal IDs additionally reveals their stable IDs and the read-only Course Model version. Fork provenance separately identifies who created a particular fork, when, and its immediate source Course. Official Courses retain publisher identity, official version, release notes, channel, checksum and verification. Lesson numbering is set on the Lessons page in Edit. Its selected term is shared by Editor labels, breadcrumbs and learner presentation; stored Lesson titles and IDs remain unchanged. Lessons without an explicit icon use the single theme-colored number circle. These presentation choices never change lessonId, progression or unlocks.''',
  'editorHelp.auditSeverityAndCodes.title': r'''Audit severity and codes''',
  'editorHelp.auditSeverityAndCodes.body':
      r'''Course Audit reports Errors, Warnings and Info. Error blocks publication or import because content is structurally or functionally invalid. Warning marks a likely authoring problem that needs review. Info is guidance or a neutral fact and never blocks publication by itself. Audit can sort by Lesson, friendly Exercise type or Recently modified and can be opened for a whole Course, one Lesson or one Round. Recent order uses updatedAt descending with deterministic ties; findings are numbered progressively inside each severity group after filtering. A red border marks an Audit Error or Warning and propagates through its represented branch. A luminous green border means the current branch has no Error or Warning; Info guidance may remain. One blue Draft indicator independently includes a Lesson or Round's own Draft state and follows Draft Guidebooks and Content through their visible ancestors. A green Audit border does not mean the item is Published. An explicitly Draft Lesson or Round keeps Published children hidden until that container is saved. A Guidebook concern affects its Lesson and Lessons hierarchy, but not the separate Rounds branch. Fewer than 3 Rounds is Info; fewer than 25 eligible Duel Exercises is Info only when Create Duels is ON. Missing Reading- or Listening-comprehension coverage produces no finding; malformed existing comprehension content still receives validation. Drafts are included for author review without making unrelated Published learner content invalid. Course Editor Help > Technical reference > Audit Codes displays the shared rule registry in Errors, Warnings, Info order. All three independently selectable categories start enabled, and text search applies within the selected categories.''',
  'editorHelp.courseAudit.title': r'''Course Audit''',
  'editorHelp.courseAudit.body':
      r'''Course Audit checks structural and authoring problems such as invalid exercise fields, duplicate IDs, Word Block problems, missing audio mappings and Missing Word errors. An empty Reading passage is an Error; one or two Unicode/apostrophe-aware lexical words produce READING_PASSAGE_TOO_SHORT, while three or more do not. HINT_REPEATS_PROMPT is a Warning and revealing any canonical correct answer remains an Error. It does not certify grammar, translation accuracy or pedagogical quality.''',
  'editorHelp.createNewCourse.title': r'''Create a new course''',
  'editorHelp.createNewCourse.body':
      r'''Course Studio creates an independent Course Model v11 project and opens it in Course Editor. New Course restores the same License / Rights, Authors / Contributors, language variant, levels, description and support metadata used by Course Info Editor. The active profile becomes the immutable Original Course Creator and defaults as Course Maintainer; another local individual may instead be selected as Maintainer. Assigned Team remains separate and is not selected during creation. Number of Lessons defaults to 3 (whole numbers 1–100), and Rounds per Lesson defaults to 1 (whole numbers 1–20). Invalid or missing values show inline errors and disable Create. The complete initial hierarchy is created atomically with fresh stable IDs and untitled Rounds, each with exactly one Draft Pick the translation (to target) sample Exercise. Review and explicitly save teaching content before publication. The new Not published Course remains only a working copy until Confirm course changes creates version 1; cancelling creates no stored Course. Imported v11 authoring content must state its provenance, Maintainer, Draft/Published state and required UTC timestamps explicitly; earlier Course Models are neither inferred nor migrated.''',
  'editorHelp.title': r'''Editor Help''',
  'courseStudioHelp.title': r'''Course Studio Help''',
  'editorHelp.technicalReference.title': r'''Technical reference''',
  'editorHelp.technicalReference.body':
      r'''Work in progress. These pages describe the current Course Model v11 implementation separately from the practical Editor instructions.''',
  'courseStudioHelp.findingCourses.title': r'''Finding Courses''',
  'courseStudioHelp.findingCourses.body':
      r'''Search filters Course titles and source or target languages in Course Studio, including Favorites. Favorites shows shortcuts for Courses in the active learner’s personal library; each remains in its usual section too. Sort by and Show unavailable apply to both Favorites and the ordinary sections. Each section has its own Expanded / Compact control. These controls change only the view.''',
  'courseStudioHelp.courseOperations.title': r'''Course operations''',
  'courseStudioHelp.courseOperations.body':
      r'''Copy as New Course creates an independent Custom Course from one you can manage. Fork creates a derivative Custom Course when the source license allows it; it keeps the source lineage and receives fresh IDs. Merge combines selected Lessons from compatible Courses into a third Course, leaving both sources unchanged. Delete course permanently removes a Custom Course from this device after two confirmations, when you have the required Course rights. Remove Publisher Course from device is available only to an Admin and is blocked while another profile includes the Course in their personal library; learner progress and version backups are kept. Remove from my courses changes only your personal membership. Hide in Learner keeps membership but removes the Course from the learner Course Selector; Unhide in Learner reverses that choice. Unavailable operations are greyed out with a reason.''',
  'courseStudioHelp.courseTypes.title': r'''Course types''',
  'courseStudioHelp.courseTypes.intro':
      r'''In QQL, there are three course types:''',
  'courseStudioHelp.courseTypes.type1':
      r'''1. Official Bundled Course: supplied with the QQL app; trusted through the app distribution.''',
  'courseStudioHelp.courseTypes.type2':
      r'''2. Publisher Course: distributed separately by a publisher and imported into QQL. Publisher verification is a separate status.''',
  'courseStudioHelp.courseTypes.type3':
      r'''3. Custom Course: created or imported by users, including copies, forks and merges.''',
  'courseStudioHelp.courseTypes.row1.col1': r'''Aspect''',
  'courseStudioHelp.courseTypes.row1.col2': r'''Official Bundled''',
  'courseStudioHelp.courseTypes.row1.col3': r'''Publisher Course''',
  'courseStudioHelp.courseTypes.row1.col4': r'''Custom''',
  'courseStudioHelp.courseTypes.row2.col1': r'''Origin''',
  'courseStudioHelp.courseTypes.row2.col2': r'''Included in QQL''',
  'courseStudioHelp.courseTypes.row2.col3': r'''Imported publisher release''',
  'courseStudioHelp.courseTypes.row2.col4': r'''Created or imported by users''',
  'courseStudioHelp.courseTypes.row3.col1': r'''Trust''',
  'courseStudioHelp.courseTypes.row3.col2': r'''App distribution''',
  'courseStudioHelp.courseTypes.row3.col3':
      r'''Valid signature from an approved publisher''',
  'courseStudioHelp.courseTypes.row3.col4':
      r'''No official publisher verification''',
  'courseStudioHelp.courseTypes.row4.col1': r'''Editing''',
  'courseStudioHelp.courseTypes.row4.col2': r'''Read only''',
  'courseStudioHelp.courseTypes.row4.col3': r'''Read only''',
  'courseStudioHelp.courseTypes.row4.col4': r'''Authorized Maintainer / Team''',
  'courseStudioHelp.courseTypes.row5.col1': r'''Copying''',
  'courseStudioHelp.courseTypes.row5.col2': r'''Use a licensed Fork''',
  'courseStudioHelp.courseTypes.row5.col3': r'''Use a licensed Fork''',
  'courseStudioHelp.courseTypes.row5.col4':
      r'''Copy as New Course, if authorized''',
  'courseStudioHelp.courseTypes.row6.col1': r'''Forking''',
  'courseStudioHelp.courseTypes.row6.col2':
      r'''Only if derivatives are allowed''',
  'courseStudioHelp.courseTypes.row6.col3':
      r'''Only if derivatives are allowed''',
  'courseStudioHelp.courseTypes.row6.col4':
      r'''Only if derivatives are allowed''',
  'courseStudioHelp.courseTypes.row7.col1': r'''Merging''',
  'courseStudioHelp.courseTypes.row7.col2': r'''Not a custom merge source''',
  'courseStudioHelp.courseTypes.row7.col3': r'''Not a custom merge source''',
  'courseStudioHelp.courseTypes.row7.col4':
      r'''Two custom sources; new custom result''',
  'courseStudioHelp.courseTypes.row8.col1': r'''Maintenance''',
  'courseStudioHelp.courseTypes.row8.col2': r'''QQL publisher''',
  'courseStudioHelp.courseTypes.row8.col3': r'''External publisher''',
  'courseStudioHelp.courseTypes.row8.col4':
      r'''Course Maintainer / Assigned Team''',
  'courseStudioHelp.courseTypes.row9.col1': r'''Publication''',
  'courseStudioHelp.courseTypes.row9.col2': r'''Included in app releases''',
  'courseStudioHelp.courseTypes.row9.col3': r'''Distributed by the publisher''',
  'courseStudioHelp.courseTypes.row9.col4': r'''Published or unpublished''',
  'courseStudioHelp.courseTypes.row10.col1': r'''Deletion''',
  'courseStudioHelp.courseTypes.row10.col2': r'''Personal removal only''',
  'courseStudioHelp.courseTypes.row10.col3':
      r'''Personal removal; admin-only uninstall if unused by others''',
  'courseStudioHelp.courseTypes.row10.col4':
      r'''Authorized deletion in Course Studio''',
  'courseStudioHelp.courseTypes.row11.col1': r'''Updates''',
  'courseStudioHelp.courseTypes.row11.col2': r'''New QQL app release''',
  'courseStudioHelp.courseTypes.row11.col3':
      r'''Newer release, same course ID and publisher''',
  'courseStudioHelp.courseTypes.row11.col4': r'''Independent custom versions''',
  'courseStudioHelp.courseTypes.note1':
      r'''Publisher Course imports require a verified publisher signature. Unverifiable stored courses and their progress are preserved with Verification required. See Publisher signing and approval in Technical reference.''',
  'courseStudioHelp.courseTypes.note2':
      r'''Bundled and External are two official origins; verified / unverified describes authenticity, not a fourth course type. An unverified file is not accepted as a new Publisher Course.''',
  'courseStudioHelp.courseTypes.note3':
      r'''A Copy creates an independent Custom Course. A Fork is also custom, preserves its source provenance and remains subject to the original licence. Neither becomes official because its source was official.''',
  'courseStudioHelp.courseTypes.note4':
      r'''A Merge creates a new Custom Course from two custom sources, which remain unchanged. Created, imported, copied, forked and merged describe how a custom course originated, not additional course types.''',
  'courseStudioHelp.courseTypes.contact':
      r'''For bundled distribution or approval as an external publisher, contact the QQL team. The publisher signing guide explains the approval procedure.''',
  'appInfo.versionAndBuild.title': r'''Version and Build''',
  'appInfo.choosingAndOpeningCourses.title':
      r'''Choosing and opening courses''',
  'appInfo.courseIdentityAndProgress.title':
      r'''Course identity and progress''',
  'appInfo.progressWeekXpAndGamification.title':
      r'''Progress, Week XP and Gamification''',
  'appInfo.streakAndFreezeRule.title': r'''Streak and the freeze rule''',
  'appInfo.daysStudied.title': r'''Days studied''',
  'appInfo.laurelCrowns.title': r'''Laurel crowns''',
  'appInfo.audioSettings.title': r'''Audio Settings''',
  'appInfo.betaExpiry.title': r'''Beta expiry''',
  'appInfo.status.title': r'''Status''',
  'appInfo.avatarAppearance.title': r'''Avatar appearance''',
  'appInfo.review.title': r'''Review''',
  'appInfo.guidebooks.title': r'''Guidebooks''',
  'appInfo.languageDuels.title': r'''Language Duels''',
  'appInfo.sourceAndTargetLanguages.title': r'''Source and target languages''',
  'appInfo.exportAndImportLearnerData.title':
      r'''Export and import learner data''',
  'appInfo.updates.title': r'''Updates''',
  'appInfo.crashLogAndDiagnosticLog.title': r'''Crash Log and Diagnostic Log''',
  'appInfo.courseStudioAndCourseEditor.title':
      r'''Course Studio and Course Editor''',
  'appInfo.courseContentAndAi.title': r'''Course content and AI''',
  'appInfo.choosingAndOpeningCourses.body':
      r'''The learner page Course Selector lists the current course, recently opened courses, bundled courses and local courses. Every row has Course Info and Remove from my courses. Course Library lets you add courses again with preserved progress. Import Course opens directly and returns to study. When Animations are enabled, switching to a different course briefly shows its valid Course JSON flag before revealing the new Learner Panel. If no flag is declared, the same established course-code flag fallback used elsewhere is shown; invalid declared flag data does not receive that fallback. Selecting the current course again, normal startup and disabled Animations enter immediately. Each learner resumes the last Lesson selected in that course, or the first Lesson when no saved selection is valid. The bottom Lesson display control cycles through Expanded, Collapse completed and Focused while the Section selector remains the sole Section-level navigation.''',
  'appInfo.courseIdentityAndProgress.body':
      r'''Every course has an immutable globally unique Course ID. Updates to the same course keep that ID and retain course progress. Importing a course with an existing Course ID lets you replace or update it, create a separate derived copy with a new ID, or cancel. Derived copies may record their parent Course ID and source version. Course completions, Review history, laurels and Language Duel wins are separate per Course ID. Language XP, streaks and study days remain shared by target language, while Week XP remains a total across all courses and languages.''',
  'appInfo.progressWeekXpAndGamification.body':
      r'''Language XP, streak, study days and Status are stored separately for each learner and target language. Profile > Statistics shows Total Study Days across languages and, for every studied language, its flag, name, canonical language ID, Study Days, Current Streak and Max Streak. Completed Rounds and laurel crowns are stored separately for each learner and Course ID. Week XP is different: it is the total XP earned by that learner across all courses during the current week. Profile > Gamification contains Weekly XP Target · All courses, Last Week XP · All courses and the Local leaderboard · All courses. Last Week XP refers to the previous completed week; tap your own Last Week XP to see the XP breakdown for each course. The local leaderboard ranks participating learner profiles on this device by their total XP across all courses during that same completed week. Participation can be turned off without deleting the learner’s XP history.''',
  'appInfo.streakAndFreezeRule.body':
      r'''Your streak increases when you study that language on a new day. If you spend a day studying a different language, this language streak is frozen: it does not increase and it does not reset. A full day with no study in any language breaks active streaks.''',
  'appInfo.daysStudied.body':
      r'''A Study Day is one distinct local calendar day on which the learner completes study. Several Rounds on the same day still count as one Study Day. Total Study Days counts distinct study dates across all languages, so studying two languages on the same day still adds one total day.''',
  'appInfo.laurelCrowns.body':
      r'''A round earns a laurel crown when you complete one full attempt with zero errors. This can happen from the normal course path or from Review. Once earned, the crown is permanent even if a later attempt contains errors. A newly earned crown also plays the victory sound when sound effects are enabled.''',
  'appInfo.audioSettings.body':
      r'''Settings > Audio Settings contains Enable Audio Exercises, Text-to-speech and the existing TTS voice selector with Test Voice, in that order. Enable Audio Exercises and Text-to-speech are stored per learner and initialize Off; TTS voice is also per learner and initializes System. Test Voice opens with an empty field and speaks only the text you enter, using the selected course language for voice resolution. While audio exercises are Off, recorded-MP3, TTS and hybrid exercises are excluded before their source or playback controller is initialized. When On, the Text-to-speech switch controls TTS availability without disabling valid recorded audio. Previous shared and negative audio-setting values remain untouched and unread. Authoring Preview ignores learner Audio Settings and remains no-write. Completing only the available non-audio part of a Round preserves the established leaf-style partial-audio completion behavior rather than awarding a full laurel crown.''',
  'appInfo.avatarAppearance.body':
      r'''Profile > Avatar Customization contains skin and hair choices. T-shirt color is not a customization preference: it always uses the vivid color assigned to the learner’s current Status for the selected learning language, and changes automatically when Status changes.''',
  'appInfo.review.body':
      r'''QuisquisLingo remembers up to 50 distinct recent Rounds for each learner and Course ID. Review prioritizes Rounds where the latest attempt contained more errors. Ties are ordered by recency. Repeating a Round updates its latest error count and can also earn a permanent laurel crown.''',
  'appInfo.guidebooks.body':
      r'''Every Lesson has its own GuideBook with explanations and reference material. The GuideBook is the first node on the current Lesson path and opens only when you select it.''',
  'appInfo.languageDuels.body':
      r'''Each Lesson has its own Duel. A standard Duel uses 25 suitable exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or separate pass threshold: complete all 25 questions before losing all four lives to win and unlock the next Lesson. If the Lesson does not contain 25 suitable exercises, its Duel is simply unavailable.''',
  'appInfo.sourceAndTargetLanguages.body':
      r'''The target language is the language you are learning. The source language is used for explanations and translations. Most sample courses use English as source; the English sample course uses Spanish as source.''',
  'appInfo.exportAndImportLearnerData.body':
      r'''Profile > User Data > Export my data creates a backup of the active learner profile, including learner-specific progress and preferences. It is saved directly in {folderLearnerDataExports} with an automatic filename; there is no Save As dialog. If that filename already exists, QuisquisLingo adds _2, _3 and later numeric suffixes. To import learner data, copy a supported backup to {folderLearnerDataImports}/learner_import.json and then choose Profile > User Data > Import my data. Course Editor projects, Image Bank packages and Audio Packs are separate authoring resources and are not part of this learner backup.''',
  'appInfo.updates.body':
      r'''At the bottom of Settings, Version and Build are shown immediately before Update. Settings > Update displays the published QuisquisLingo source repository https://github.com/Quisquisnaut/QuisquisLingo, lets you check the latest packaged GitHub Release manually, and can optionally check automatically at startup. If no packaged GitHub Release exists, the page distinguishes that from the published source repository. Automatic checks are on by default. Update checks send no learner data or course data and never download or install software. If a newer release exists, the page shows release information and installation guidance in the fixed order Windows, macOS, Linux, Android, iOS and Web, marking platforms that have no matching published release asset as not currently available.''',
  'appInfo.crashLogAndDiagnosticLog.body':
      r'''Settings > Debug contains both logging tools and concise reporting guidance. Use the Crash Log for startup/runtime crashes or unexpected closes. For non-crashing runtime problems, reproduce the issue when possible and export the Diagnostic Log shortly afterward; clearing it first is optional and is useful only to isolate a specific reproducible problem, while intermittent evidence should be exported before clearing. Quick Export saves copies of the Diagnostic Log and the Crash Log in {folderDiagnosticLogExports}; Settings > Debug also shows where the live Crash Log is kept. Learner audio diagnostics use short correlation IDs and bounded lifecycles with preparation, learner UI state, stable exercise ID/type, activation trigger, suppression, source, backend, playback, failure and disposal status. They are designed to avoid spoken text, answers, course content and full personal file paths.''',
  'appInfo.courseStudioAndCourseEditor.body':
      r'''Course Studio is opened from the learner Course Selector rather than Settings. It is the lifecycle hub: official courses provide read-only inspection, licensed Fork, Audit and supported Export; custom courses provide Edit, Copy as New Course, Merge, Audit, Export and Delete. Fork preserves the source lineage; Copy as New Course starts an independent Course lineage. Open Course Studio Help for library operations, and Editor Help from any Course Editor hierarchy page for authoring instructions.''',
  'appInfo.courseContentAndAi.body':
      r'''The bundled courses titled AI-Slop Demo are AI-generated, unreviewed demonstrations and are not reliable learning courses. Real QuisquisLingo course content is intended to be authored and reviewed by humans. This classification does not apply to other official or custom courses.''',
  'appInfo.versionAndBuild.body': r'''{version}''',
  'appInfo.betaExpiry.active':
      r'''This is a time-limited beta build. It expires on {expiryDate}. After expiry, learner exercises and Review are blocked until a newer beta is installed. Local progress, courses, course edits and settings are not deleted, and Course Editor remains available.''',
  'appInfo.betaExpiry.inactive': r'''This is not a time-limited beta build.''',
  'appInfo.status.body':
      r'''Status is calculated separately for each learner and learning language. Status points are your XP plus 40 points per current streak day, 25 per distinct study day, 15 per completed Round, and 20 per Laurel. Your current Status is the highest threshold your total has reached. Every Status has a vivid color that automatically becomes your avatar T-shirt color. The levels are Apprentice, Wanderer, Squire, Wordsmith, Knight, Lorekeeper, Language Wizard, Grand Master, Sage and Guru.''',
  'appInfo.title': r'''Info''',
  'appInfo.creditsButton': r'''App and image credits''',
  'allCoursesHelp.title': r'''Courses on this device''',
  'allCoursesHelp.allCoursesPageTitle': r'''All Courses — Help''',
  'allCoursesHelp.courseLibraryPageTitle': r'''Course Library — Help''',
  'allCoursesHelp.intro1':
      r'''All Courses shows every Course installed or stored on this QQL device, including Courses outside your personal library. Each learner chooses independently which of them to include.''',
  'allCoursesHelp.intro2':
      r'''Courses do not have to be created on this device. You can import a Course made elsewhere. For example, a friend can send you a Course they created, or a publisher may distribute or sell you a Publisher Course to install. QQL only imports the Course package; it does not sell or license Courses itself.''',
  'allCoursesHelp.intro3':
      r'''If your library has no courses available for study, Home keeps Settings and All Courses. Course Studio can be unlocked for your profile by tapping Version in Settings ten times. All Courses lets you add Courses again. No course flag is shown until a playable Course is selected.''',
  'allCoursesHelp.categories.title': r'''Categories''',
  'allCoursesHelp.categories.body':
      r'''Favorites: your shortcuts, also listed in their normal sections.
Bundled Courses: supplied with QuisquisLingo.
Publisher Courses: installed Publisher releases.
My Local Courses: Custom Courses created by your profile.
Other Local Courses: Custom Courses created by another profile or imported from somebody else.

Each category has its own section, and its header shows how many Courses it holds. Bold titles identify Bundled Courses in black (white on black in dark mode), Publisher Courses in purple and Custom Courses in orange.''',
  'allCoursesHelp.courseDetails.title': r'''Course details''',
  'allCoursesHelp.courseDetails.body':
      r'''Each row shows the Course cover, or the Course flag when there is no cover, followed by the languages, Version, Last edited date, Maintainer and, when the author declared it, Duration. Bundled and Publisher Courses show their release version; Custom Courses show their Course version. Maintainer shows the local profile responsible for a Custom Course, or the publisher for Bundled and Publisher Courses. A profile not present on this device is identified by its profile ID.''',
  'allCoursesHelp.availability.title': r'''Availability''',
  'allCoursesHelp.availability.body':
      r'''Show unavailable starts on, displaying unpublished Courses, Courses needing Publisher verification and Courses with Draft authoring content. Turn it off to filter those rows from both tabs. A filtered section says how many of its Courses are shown. Blue outlined labels identify Draft, Unpublished and Verification required. Showing them does not make them playable or verified. Only published Courses are available for study. Publisher Courses also require verified signatures.''',
  'allCoursesHelp.sortingAndCompactView.title': r'''Sorting and compact view''',
  'allCoursesHelp.sortingAndCompactView.body':
      r'''Sort by orders the Courses inside each section by Title, Language, Maintainer, Most recent or Duration. The sections themselves never change order. Most recent shows the latest edit first; Duration shows the shortest Course first and Courses without a declared duration last. Each section's Expanded / Compact button shows or hides version, date, maintainer and duration for that section only. Search filters titles and languages across all sections, including Favorites. These choices last while the page is open.''',
  'allCoursesHelp.personalLibrary.title': r'''Personal library''',
  'allCoursesHelp.personalLibrary.body':
      r'''Add to my courses adds an installed Course to your personal Course Selector and Course Studio. It does not copy the Course or give you editing rights. Removing it from your courses does not remove it from the device. Added · Remove lets you remove it here, with the same confirmation and optional progress reset.

Remove from my courses, in the Selector or Course Studio, removes the course only from your library. Progress is kept by default for when you add it again. You may explicitly reset your course progress during removal. Other learners and the shared file are unaffected. Even when Reset my progress is selected, all earned XP (including Weekly XP), total and per-language study days, streak and version backups are kept. XP earned from this course is not subtracted. Reset clears only your completed Rounds/Lessons, Perfect results, won Duels, read Guidebooks and recent Round entries for this course.''',
  'allCoursesHelp.coursesInLearnerMode.title': r'''Courses in learner mode''',
  'allCoursesHelp.coursesInLearnerMode.body':
      r'''Hide in Learner keeps a Course in your personal library and Course Studio but removes it from the learner Course Selector. Unhide in Learner restores it. The Course you are studying cannot be hidden until you switch Courses. Favorites are learner-specific shortcuts; favoriting never adds a Course to your personal library. All Courses keeps hidden Courses visible with a Hidden in Learner label so you can unhide them.''',
  'allCoursesHelp.importing.title': r'''Importing''',
  'allCoursesHelp.importing.body':
      r'''Courses may be transferred as QQL Course packages. Imported Custom Courses keep their ownership and provenance rules. Publisher Courses remain subject to Publisher verification.''',
  'allCoursesHelp.removingPublisherCourse.title':
      r'''Removing a Publisher Course from the device''',
  'allCoursesHelp.removingPublisherCourse.body':
      r'''Only an admin can remove a Publisher Course from the device, through its Course Studio menu. This is blocked while another profile includes the course in its library. Physical removal preserves learner progress and version backups for later reinstallation.''',
  'technical.courseModel.title': r'''QuisquisLingo Course Model v11''',
  'technical.courseModel.status.title': r'''Status''',
  'technical.courseModel.status.body':
      r'''Work in progress. QuisquisLingo uses formatVersion 11 as its only native Course Model. Earlier formats are rejected without migration or deletion. Every custom Course requires an immutable Original Course Creator and one individual Course Maintainer; an optional Assigned Team remains separate.''',
  'technical.courseModel.hierarchy.title': r'''Hierarchy''',
  'technical.courseModel.hierarchy.body':
      r'''Course > Lesson > Guidebook + Round > Content. Every Lesson owns its Guidebook and Duel. Exercise is one Content kind rather than the only object allowed inside a Round.''',
  'technical.courseModel.content.title': r'''Content''',
  'technical.courseModel.content.body':
      r'''Current kinds include exercise, presentation, explanation, example, vocabulary, text and dialogue. Content has a stable ID and can be required for normal completion. Lesson, Round and Exercise objects carry required UTC updatedAt timestamps. Presentation Content can be interactive without producing a correct/incorrect result.''',
  'technical.courseModel.guidebook.title': r'''Guidebook''',
  'technical.courseModel.guidebook.body':
      r'''Each Lesson GuideBook is structured Content rather than a single monolithic block. Its vocabulary, examples and explanations are learner reference material and can also act as the sole source for configurable, progressively harder draft Round generation and sourceRefs.''',
  'technical.courseModel.completionAndProgression.title':
      r'''Completion and progression''',
  'technical.courseModel.completionAndProgression.body':
      r'''required means required for normal completion. Completion, correctness and unlock state are separate. Completing a Lesson or winning its available Duel can unlock the next Lesson without marking skipped Content as completed.''',
  'technical.courseModel.languageDuel.title': r'''Language Duel''',
  'technical.courseModel.languageDuel.body':
      r'''Duel identity belongs directly to the Lesson. QuisquisLingo dynamically selects 25 unique eligible exercises from that Lesson and starts with 4 lives. There is no score or pass threshold. If the actual eligible pool is smaller than 25, the Lesson Duel is unavailable rather than invalid.''',
  'technical.courseModel.friendlyEditorTemplates.title':
      r'''Friendly Editor templates''',
  'technical.courseModel.friendlyEditorTemplates.body':
      r'''The Editor keeps names such as Choose a picture, What do you hear?, Build the sentence and Match the sounds. editorTemplate is optional authoring metadata. The learner executes the primitive representation.''',
  'technical.exercisePrimitives.title': r'''Exercise primitives''',
  'technical.exercisePrimitives.status.title': r'''Status''',
  'technical.exercisePrimitives.status.body':
      r'''Work in progress. The current primitive set is the implemented Course Model v11 baseline.''',
  'technical.exercisePrimitives.exerciseAnatomy.title': r'''Exercise anatomy''',
  'technical.exercisePrimitives.exerciseAnatomy.body':
      r'''Exercise = Prompt[] + Interaction + Evaluation, with optional hint and feedback.''',
  'technical.exercisePrimitives.interactions.title': r'''Interactions''',
  'technical.exercisePrimitives.interactions.body':
      r'''select: choose one or more Items. input: produce a typed response. arrange: order Items. match: create relationships between Items.''',
  'technical.exercisePrimitives.evaluations.title': r'''Evaluations''',
  'technical.exercisePrimitives.evaluations.body':
      r'''selected_items checks selected stable Item IDs. text_match checks accepted text with explicit normalization. ordered_items checks Item order. matched_items checks Item relationships.''',
  'technical.exercisePrimitives.promptAndItemMedia.title':
      r'''Prompt and Item media''',
  'technical.exercisePrimitives.promptAndItemMedia.body':
      r'''The initial media primitives are text, image and audio. Prompt elements may carry roles such as primary, passage, question, context or clue.''',
  'technical.exercisePrimitives.presentationContent.title':
      r'''Presentation Content''',
  'technical.exercisePrimitives.presentationContent.body':
      r'''Flashcard is presentation Content, not an Exercise. The learner chooses understood or review_later. Both complete the current presentation; review_later requests re-presentation and is not an incorrect answer.''',
  'technical.exercisePrimitives.friendlyTemplates.title':
      r'''Templates vs primitives''',
  'technical.exercisePrimitives.friendlyTemplates.body':
      r'''Friendly templates remain an authoring layer. Multiple templates can share the same primitive mechanics. Template constraints such as distractor limits do not become universal primitive rules.''',
  'technical.jsonStructure.title': r'''JSON data structure''',
  'technical.jsonStructure.status.title': r'''Status''',
  'technical.jsonStructure.status.body':
      r'''Work in progress. QuisquisLingo writes formatVersion: 9.''',
  'technical.jsonStructure.root.title': r'''Root''',
  'technical.jsonStructure.root.body':
      r'''The root contains formatVersion, Course metadata and lessons[]. Bundled samples and custom Courses use the native v11 model; a merged Course also carries mergeProvenance. Custom roots require immutable originalCourseCreator provenance and one individual maintainer; optional assignedTeamId is separate, while Team membership itself remains outside Course JSON. Earlier Course Models are not read or migrated.''',
  'technical.jsonStructure.guidebook.title': r'''Guidebook''',
  'technical.jsonStructure.guidebook.body':
      r'''Each Lesson contains a guidebook with optional publicationState and guidebook.content[] structured Content such as explanation, vocabulary and example entries. An omitted Guidebook publicationState means published; an explicit draft state keeps the Guidebook out of learner delivery. Its displayed Internal ID is derived from the immutable Lesson ID with the suffix _guidebook; no additional ID field is persisted. Guidebook Content retains its own stable IDs. The optional course useGuidebook switch changes learner access and the empty-Guidebook Warning, never the stored content.''',
  'technical.jsonStructure.lessonAndRound.title': r'''Lesson and Round''',
  'technical.jsonStructure.lessonAndRound.body':
      r'''Course, Lesson, Guidebook, Round and authored Exercise content carry draft/published state. Guidebook defaults to published when its optional state is absent. Lesson, Round and Exercise also require UTC updatedAt timestamps. A Course stores Lesson numbering, a legacy-compatible fallback-icon value and optional managed custom Lesson-icon assets. Both accepted legacy fallback values now render the same theme-colored number circle. A Lesson contains lessonId, title, optional Section and themeIconAsset metadata, guidebook, rounds[] and its Duel identity. Guidebook may contain ordered Insights sections with Title and Text. Round title is optional and falls back everywhere to its current Round N position without changing identity.''',
  'technical.jsonStructure.exerciseContent.title': r'''Exercise Content''',
  'technical.jsonStructure.exerciseContent.body':
      r'''Exercise Content stores editorTemplate plus exercise.prompt[], exercise.interaction and exercise.evaluation. Correctness uses stable Item IDs rather than display indexes. Build the translation stores one or more literal correctOrders with answer text and ordered Item IDs; legacy correctOrder is rejected.''',
  'technical.jsonStructure.duel.title': r'''Duel''',
  'technical.jsonStructure.duel.body':
      r'''A Lesson serializes a stable Duel ID and title. Availability is derived at runtime from the actual Lesson exercise pool under the standard eligibility and deduplication rules; it is not serialized and does not depend on Round count. Course createDuels and useGuidebook default true and serialize only when false. Optional sectionNames retains non-empty trimmed reusable names; an empty catalog is omitted. Optional worldFlagId references authoritative bundled SVG artwork and is omitted when empty.''',
  'technical.jsonStructure.compatibility.title': r'''Compatibility''',
  'technical.jsonStructure.compatibility.body':
      r'''Bundled Courses are native Course Model v11, and so are custom Courses. Every earlier format is unsupported and is not read, migrated, converted or deleted. Attribution, provenance and Rights Holder metadata never grant Course permissions or infer Team assignment.''',
  'debugHelp.title': r'''Debug Help''',
  'debugHelp.crashLog.title': r'''Crash Log''',
  'debugHelp.crashLog.body':
      r'''This Beta version keeps an automatic local Crash Log to help investigate crashes and other serious technical problems.

For cases where QQL crashes or closes unexpectedly. If available after a crash, copy or export this file and provide it with your report. It is primarily useful for startup and runtime crashes.

The live Crash Log is private to QQL; Settings > Debug shows where it is. Quick Export saves a copy as QQL_crash_log.txt in {folderLogs}, replacing the previous copy. Save log copy as… lets you choose the place, and on phones Share sends it directly.

Please use the app normally and reproduce the crash. After the app closes, reopen it if necessary. When you send the Crash Log, also say what you clicked immediately before the crash. Please send the whole log file, not a screenshot of it.

The Crash Log contains technical system information, session starts, uncaught errors and stack traces. It does not intentionally record learner names, exercise answers or course content.

If the Crash Log file is deleted, QuisquisLingo recreates it automatically at the next app start or crash write.''',
  'debugHelp.diagnosticLog.title': r'''Diagnostic Log''',
  'debugHelp.diagnosticLog.body':
      r'''For problems that do not necessarily crash QQL, including audio, TTS, Recorded MP3, unexpected playback, source-resolution problems, and other runtime anomalies. When possible, reproduce the problem and export this log shortly afterward. To isolate one specific reproducible problem, you may clear it first; clearing is optional. For intermittent or difficult-to-reproduce problems, export the current Diagnostic Log before clearing to preserve existing evidence.''',
  'debugHelp.privacy.title': r'''Privacy''',
  'debugHelp.privacy.body':
      r'''Learner audio diagnostics are designed to avoid recording spoken text, answers, course content, or full personal file paths.''',
  'deviceAdminHelp.title': r'''Device Administration Help''',
  'deviceAdminHelp.whatThisPageIs.title': r'''What this page is''',
  'deviceAdminHelp.whatThisPageIs.paragraph1':
      r'''Device Administration gathers the administrator features of this QQL installation in one place. It only exists on this device: QQL has no online account, so an admin looks after the learners and data stored here and nothing else.''',
  'deviceAdminHelp.whatThisPageIs.paragraph2':
      r'''Every feature on this page is also still available where it always was. Only admins can see the page.''',
  'deviceAdminHelp.whoIsAnAdmin.title': r'''Who is an admin''',
  'deviceAdminHelp.whoIsAnAdmin.paragraph1':
      r'''The first learner created on a device is automatically an admin. QQL always has at least one admin. An admin can make other learners admins, and an admin can give up their own admin role as long as another admin remains.''',
  'deviceAdminHelp.whatAdminsCanDo.title': r'''What admins CAN do''',
  'deviceAdminHelp.whatAdminsCanDo.bullet1':
      r'''Make another learner an admin.''',
  'deviceAdminHelp.whatAdminsCanDo.bullet2':
      r'''Delete any learner, together with that learner’s local progress and settings (see the limits below).''',
  'deviceAdminHelp.whatAdminsCanDo.bullet3':
      r'''Reset another learner’s PIN. This removes the PIN so the learner can choose a new one. Note that until a new PIN is set, anyone can open that profile.''',
  'deviceAdminHelp.whatAdminsCanDo.bullet4':
      r'''Change the QQL device name shown in the Learner Profiles list.''',
  'deviceAdminHelp.whatAdminsCanDo.bullet5':
      r'''Choose whether QQL asks who is learning each time it starts.''',
  'deviceAdminHelp.whatAdminsCanDo.bullet6':
      r'''Manage the shared image library and its descriptive metadata (Shared Image Library). It holds the images available to every course on this device, and only admins can add to or change it. Anyone who can edit a course can still add their own image to an exercise with Import custom image; that image is not added to the shared library.''',
  'deviceAdminHelp.whatAdminsCanDo.bullet7':
      r'''Run the reset options on this page, after setting an admin PIN and entering it for each reset.''',
  'deviceAdminHelp.whatAdminsCannotDo.title': r'''What admins CANNOT do''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet1':
      r'''Delete the only admin, or give up the admin role when they are the only admin. To remove the last admin, make another learner an admin first, or use “Wipe out everything”.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet2':
      r'''See any PIN. PINs are stored in a scrambled form that even QQL cannot read back. A forgotten PIN can only be reset, never recovered.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet3':
      r'''Reset their own PIN from the Learner Profiles list. Only another admin can reset an admin’s PIN.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet4':
      r'''Run any reset without a PIN. An admin who has not set a PIN cannot use the reset options at all, and the PIN is asked again for every reset.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet5':
      r'''Take ownership of courses. Being an admin gives no special right to edit or delete another person’s course. Course rights come only from being its Owner or a member of its owning Team.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet6':
      r'''Delete a learner who is the maintainer of a course, or the only Team Leader of a Team. Change the course maintainer or promote another Team Leader first.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet7':
      r'''Edit or delete the bundled official courses. They are read-only for everyone; like any learner, an admin can only fork them where their license allows it.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet8':
      r'''Manage Teams. Teams are run by their own Leads and members from Course Studio, not by device admins.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet9':
      r'''Act on other devices. Admin rights apply only to this installation.''',
  'deviceAdminHelp.whatAdminsCannotDo.bullet10':
      r'''Undo a reset or a deleted learner. Deleted data can only come back from a backup you made earlier.''',
  'deviceAdminHelp.inventory.title': r'''Inventory''',
  'deviceAdminHelp.inventory.paragraph1':
      r'''The Inventory button lists everything QQL has stored because of what people did, so you know what a reset would remove and where your files are. For every file it shows the full location (which you can select and copy), the size, the date it was last changed and, when it can be determined, the learner it belongs to.''',
  'deviceAdminHelp.inventory.bullet1':
      r'''Learners and custom courses are kept inside QQL’s own settings, not as files, so they show no path. Each course shows its maintainer or creator.''',
  'deviceAdminHelp.inventory.bullet2':
      r'''Export: exported Courses, learner backups, User Recovery Keys and Audit reports. The course backups the Course Editor makes automatically before saving a change are private to QQL and listed on their own.''',
  'deviceAdminHelp.inventory.bullet3':
      r'''Import and ToBeMerged: files you copied into those folders from outside QQL. Folders from earlier versions (Imports, Exports, Merges) are listed on their own; QQL no longer reads them.''',
  'deviceAdminHelp.inventory.bullet4':
      r'''Imported images, image banks and imported audio (MP3) files: the copies QQL made in its own storage. Audio shows the course it belongs to.''',
  'deviceAdminHelp.inventory.bullet5':
      r'''Logs: the copies of the Crash Log and Diagnostic Log saved with Quick Export. The live Crash Log and the session marker are private to QQL and listed on their own.''',
  'deviceAdminHelp.inventory.bullet6':
      r'''Other files in the QQL folder: anything added directly to the QuisquisLingo folder with the operating system, which QQL did not create and does not use.''',
  'deviceAdminHelp.inventory.bullet7':
      r'''Media and files that come with the app itself are not listed. Very large lists show the 500 most recent files per section.''',
  'deviceAdminHelp.qqlTools.title': r'''QQL-Tools''',
  'deviceAdminHelp.qqlTools.paragraph1':
      r'''QQL-Tools is an optional companion project for independent validation of QQL Course JSON files and package ZIP files. Its results do not replace QQL's own Course Audit, import validation, or safety checks.''',
  'deviceAdminHelp.qqlTools.paragraph2':
      r'''In Device Administration, an Admin uses Browse... to configure the QQL-Tools executable once per device, then Test to check it or Clear to remove it. Validate with QQL-Tools... runs in the background while QQL stays open. It does not modify or import the selected Course. Not available on mobile devices.''',
  'deviceAdminHelp.updates.title': r'''Updates''',
  'deviceAdminHelp.updates.paragraph1':
      r'''The Update entry opens the same page every learner can reach in Settings > Update: it checks GitHub for a newer release and shows the installation instructions. Only an admin can change “Check automatically at startup”, because it applies to the whole device.''',
  'deviceAdminHelp.updates.paragraph2':
      r'''When a newer version is found at startup, each learner is told about it once a day: the popup offers “Not today”, and reminds that learner again the next day. Other learners on the device are still told.''',
  'deviceAdminHelp.askWhoIsLearningAtStartup.title':
      r'''Ask who is learning at startup''',
  'deviceAdminHelp.askWhoIsLearningAtStartup.paragraph1':
      r'''Off (default): QQL opens directly as the learner who used it last. This suits a device used by one person.''',
  'deviceAdminHelp.askWhoIsLearningAtStartup.paragraph2':
      r'''On: every time QQL starts, the learner list is shown and nobody is resumed automatically, so each person chooses their own profile. This suits shared devices. It has no effect when the device has only one learner. Learners with a PIN still have to enter it.''',
  'deviceAdminHelp.resetOptions.title': r'''The reset options''',
  'deviceAdminHelp.resetOptions.paragraph1':
      r'''Resets delete data permanently. For that reason the Reset section is locked until you set your own 4-digit PIN. Each reset then walks you through: an explanation with the real numbers for this device, an offer to back up first, and finally your PIN. Nothing is deleted until you have finished every step. Remove imported media and the full wipe let you choose in the first step (see below), and the full wipe asks you to type NUKE EVERYTHING, exactly, before the PIN.''',
  'deviceAdminHelp.resetOptions.bullet1':
      r'''Reset learner progress: clears XP, streaks and completed lessons for every learner. Learners, PINs, settings and courses stay.''',
  'deviceAdminHelp.resetOptions.bullet2':
      r'''Remove all learners except admins: deletes every non-admin learner and their data, and removes the Team list if it names any of them.''',
  'deviceAdminHelp.resetOptions.bullet3':
      r'''Remove imported media: you choose whether to remove the imported images, the imported audio files (recorded MP3 files), or both; nothing is ticked at first. It deletes only the copies QQL made in its own storage. Media that comes with QQL itself (the built-in image library, flags, icons and the bundled courses’ recordings) is part of the app and is never removed; edits to the shared image library’s tags and labels go back to the defaults. Your original files are not touched.''',
  'deviceAdminHelp.resetOptions.bullet4':
      r'''Remove custom courses: deletes all custom and installed courses, all Teams and all imported media, meaning every imported image and every imported recorded MP3 audio file. Learners stay.''',
  'deviceAdminHelp.resetOptions.bullet5':
      r'''Wipe out everything: returns QQL to a brand-new installation, including all learners and admins. You can keep the Export folder, the Logs folder, and the Import and ToBeMerged folders; all are kept unless you untick them in the first step. Import and ToBeMerged hold the original files you copied there yourself. Course backups are always removed with the courses.''',
  'deviceAdminHelp.beforeResetBackups.title': r'''Before you reset: backups''',
  'deviceAdminHelp.beforeResetBackups.paragraph1':
      r'''Learner data is exported from Profile → User Data, and each backup covers only the learner who is logged in: an admin cannot export other learners’ data, so before a reset that affects other learners, ask each of them to export their own. Courses are exported one at a time from Course Studio. Exports are saved in {folderExport}, which the full wipe keeps unless you untick it.''',
  'deviceAdminHelp.forgottenPin.title': r'''Forgotten PIN''',
  'deviceAdminHelp.forgottenPin.paragraph1':
      r'''If another admin exists, they can reset your PIN from the Learner Profiles list. If you are the only admin and forget your PIN, there is no way to recover it: you cannot open your profile or use the reset options. Choose a PIN you will remember, and consider making a second person an admin.''',
  'publisherSigningHelp.title': r'''Publisher signing and approval''',
  'publisherSigningHelp.status.title':
      r'''Status: signature verification implemented''',
  'publisherSigningHelp.status.body':
      r'''Build 241 now verifies Ed25519 publisher signatures for Publisher Course imports, both with Quick Import and from the system file dialog. The storage service checks again before installation. Missing, invalid, unknown or revoked signatures are rejected. The normal trusted publisher registry currently has no approved external publishers; the Dummy identity is for explicitly enabled test builds only.

Publisher approval is a manual owner process. The owner maintains the public-key registry in lib/services/trusted_publishers.dart and distributes changes with an app update. There is no approval portal or in-app signing button. A developer command and OpenSSL provide course signing outside the app.

The Course Model is v11 (Build 243); v9/v10 Publisher Courses must be converted with tools/convert_course_to_v11.dart and signed again. The signature protocol is qql-ed25519-v1. Focused verification does not constitute final release validation; Build 241 still awaits the owner's final validation approval.''',
  'publisherSigningHelp.rolesAndTools.title': r'''1. Roles and tools''',
  'publisherSigningHelp.rolesAndTools.body':
      r'''Publisher: creates and protects an Ed25519 key pair, requests approval, and signs its own releases. The QQL owner never receives private keys and does not sign each course for the publisher.

QQL owner: independently checks the publisher identity and key possession, assigns a stable publisherId and records the approved public key. Trust changes are shipped in the app registry; no online service is required.

Tools: a maintained OpenSSL 3.x installation, a terminal, a plain-text editor, a password manager, protected offline backup storage and an independently verified communication channel. Obtain OpenSSL from a trusted OS/package provider. Run openssl version to confirm it is on PATH. On Windows, an executable path containing spaces is invoked in PowerShell as & 'FULL PATH TO openssl.exe', followed by its arguments.

Course signing additionally uses the QQL repository, its compatible Dart SDK and tools/sign_course.dart. Run flutter pub get in the repository before first use. The tool prepares canonical signing bytes and attaches a checked signature; OpenSSL alone must not sign arbitrary course JSON. A learner's User Recovery Key is unrelated to publisher keys.

Use a separate private working folder per publisher, outside Git, app course/media folders and shared folders. Keep private keys there; commands run from the repository can use quoted absolute paths. Stop on every error. Choose fresh output names; never overwrite existing keys.''',
  'publisherSigningHelp.createAndProtectKey.title':
      r'''2. Publisher: create and protect the key''',
  'publisherSigningHelp.createAndProtectKey.body': r'''Check your installation:

openssl version

It must report OpenSSL 3.x. Create an encrypted Ed25519 private key, entering a strong unique passphrase when prompted:

openssl genpkey -algorithm ED25519 -aes-256-cbc -out publisher-private.pem

Export its public key (enter the private-key passphrase when prompted):

openssl pkey -in publisher-private.pem -pubout -out publisher-public.pem

Calculate the public-key fingerprint using DER SubjectPublicKeyInfo, not the PEM text:

openssl pkey -pubin -in publisher-public.pem -outform DER -out publisher-public.der
openssl dgst -sha256 publisher-public.der

Record the SHA-256 hexadecimal result. The private PEM is secret; the public PEM, public DER and fingerprint may be shared. Keep the passphrase in a password manager and an encrypted offline backup of the private PEM. Test restoring that backup in a separate secure folder: export the public key again and check that its fingerprint matches.

Never send the private PEM or passphrase to the QQL owner, put them in course JSON, commit them to Git, or include them in learner backups. Do not use online key generators or paste private keys into websites or chats. Losing both the key and backup prevents signing further releases with that key.''',
  'publisherSigningHelp.requestApproval.title':
      r'''3. Publisher: request approval''',
  'publisherSigningHelp.requestApproval.body':
      r'''Use the contact channel agreed directly with the QQL owner; this guide does not establish a public submission address. Send only:

- Publisher name and the person authorized to represent it.
- Website or other independently checkable identity evidence and a contact address.
- Requested publisherId, if any; the owner assigns the final stable identifier.
- publisher-public.pem and its SHA-256 fingerprint from section 2.
- Intended course IDs/titles, distribution channel and a statement that you can distribute the content and media under the declared licenses.

The owner will verify your identity and send a one-use challenge file. Check that its publisherId, fingerprint, purpose and expiry match your request before signing it. Do not sign arbitrary files from an unverified sender. Approval concerns a publisher/key association, not an endorsement of all its teaching content or licenses.''',
  'publisherSigningHelp.verifyIdentityChallenge.title':
      r'''4. Owner: verify identity and issue a challenge''',
  'publisherSigningHelp.verifyIdentityChallenge.body':
      r'''Keep a private approval record. Verify the representative through an independently established channel, such as a known business contact or a contact obtained from the publisher's official website. Possessing a key or an email address alone does not establish the publisher's identity.

Save the submitted public PEM in a separate request folder. Inspect it:

openssl pkey -pubin -in publisher-public.pem -text -noout

Confirm it is an Ed25519 public key. Calculate its fingerprint with the two commands in section 2 and compare it through the independent channel. Reject a malformed key, wrong algorithm, identity mismatch or conflicting publisherId.

Assign a unique request ID and a stable publisherId. Generate a fresh random nonce:

openssl rand -hex 32

In a plain-text editor, create qql-approval-challenge.txt as UTF-8 text with these fields, replacing every placeholder:

Purpose: QQL publisher key approval only
Request ID: <unique request ID>
Publisher ID: <agreed stable publisherId>
Public key SHA-256: <fingerprint calculated by the owner>
Nonce: <fresh random hexadecimal output>
Expires UTC: <explicit UTC date and time>

Choose a short expiry, for example 48 hours. Store the exact file you send and its pending/used/expired status. Send it to the verified representative. Do not regenerate, reformat or reuse the challenge: verification requires the exact original bytes. The owner, not the requester, supplies the nonce and challenge.''',
  'publisherSigningHelp.proveKeyPossession.title':
      r'''5. Publisher and owner: prove key possession''',
  'publisherSigningHelp.proveKeyPossession.body':
      r'''Publisher: save the original challenge attachment without editing or changing line endings. Check its contents, then sign it locally:

openssl pkeyutl -sign -rawin -inkey publisher-private.pem -in qql-approval-challenge.txt -out qql-approval-proof.sig

Enter the passphrase at the prompt. Return qql-approval-proof.sig and the request ID. Never return the private key. This signature proves possession for this challenge; it is not a QQL course signature.

Owner: use your stored original challenge, the previously checked public PEM and the returned binary signature:

openssl pkeyutl -verify -rawin -pubin -inkey publisher-public.pem -in qql-approval-challenge.txt -sigfile qql-approval-proof.sig

Require a successful verification and exit code 0. In PowerShell, inspect $LASTEXITCODE immediately after the command. Also check that the request is pending, unexpired and unused, and its publisherId and fingerprint are still the ones verified independently. OpenSSL does not enforce these approval rules for you.

On failure, do not approve. Resolve the identity/key mismatch, or issue a new challenge if the attachment changed or expired. Do not modify the original challenge to make a signature pass. A valid proof establishes key control, not legal identity; both checks are required.''',
  'publisherSigningHelp.recordApproval.title':
      r'''6. Owner: record approval and activate trust''',
  'publisherSigningHelp.recordApproval.body':
      r'''Keep a private record of publisherId, approved display name, public PEM/fingerprint, representative/contact, identity-check method/date, original challenge and proof, decision date and key status. Mark accepted challenges used. Never publish identity evidence or private contact details in the app registry.

For an approved publisher, assign a stable keyId (1–64 ASCII letters, digits, dot, underscore or hyphen). Convert the public PEM to DER using section 2. An Ed25519 SubjectPublicKeyInfo DER is 44 bytes: the 12-byte header 302a300506032b6570032100 followed by the 32-byte public key. Store only the Base64 encoding of those 32 bytes in publicKeyBase64, not the entire DER or PEM.

In PowerShell, after checking the DER header and length, obtain the registry value with:

[Convert]::ToBase64String(([System.IO.File]::ReadAllBytes('C:/QQL-Publisher/publisher-public.der'))[12..43])

Add a TrustedPublisherKey to TrustedPublishers.application() in lib/services/trusted_publishers.dart: publisherId, publisherName (exact approved spelling), keyId, publicKeyBase64 and revoked: false. Duplicate publisherId/keyId entries are rejected by lookup. Keep Dummy outside the normal registry. Do not approve a key supplied only inside an imported course, and never approve by editing publisherVerificationStatus in a JSON file.

Review the registry change; test a course signed by that key plus altered, missing-signature and wrong-key cases. Build and distribute the app through the normal release process. Notify the publisher of the exact publisherId, publisherName, keyId, fingerprint and first app version containing the approval. Until users install it, their app will reject the unknown key.

Approval authenticates the publisher identity, not ownership of every course ID or content license. A new publisher cannot overwrite a course already installed under another publisher or take a bundled/custom course identity.''',
  'publisherSigningHelp.signAndDistribute.title':
      r'''7. Publisher: sign and distribute a course''',
  'publisherSigningHelp.signAndDistribute.body':
      r'''Start with a valid externalOfficial JSON for Course Model v11, with your exact approved publisherId and publisherName, publisher lineage, stable courseId and release metadata. For an update retain the course ID/provenance and increase officialCourseVersion. Resolve blocking Course Audit errors and check content/media licenses. The tool does not convert custom courses or invent publisher metadata.

Run from the QQL repository. Replace dummy-1 with your approved keyId and use your actual input/output/key paths. The examples use a separate working folder named C:/QQL-Publisher:

dart run tools/sign_course.dart prepare C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/payload.bin

The command validates the model and prepares the canonical digest-based signing payload. It does not read a private key. Sign those bytes with OpenSSL, entering the private-key passphrase interactively:

openssl pkeyutl -sign -rawin -inkey C:/QQL-Publisher/publisher-private.pem -in C:/QQL-Publisher/payload.bin -out C:/QQL-Publisher/signature.bin
openssl pkey -pubin -in C:/QQL-Publisher/publisher-public.pem -outform DER -out C:/QQL-Publisher/publisher-public.der

Attach the signature. This verifies the signature against the supplied public key before writing the result:

dart run tools/sign_course.dart attach C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/signature.bin C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.json

Place each referenced recording or image in C:/QQL-Publisher/media/ under its SHA-256 filename, such as <sha256>.mp3. Then package the signed JSON:

dart run tools/sign_course.dart package C:/QQL-Publisher/course-signed.json C:/QQL-Publisher/media C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.zip

The package command checks the signature against the supplied key, checks every referenced media file and its SHA-256, and includes only files the Course uses. An empty media folder is sufficient when the Course uses no separate media.

Check exit code 0 after each command ($LASTEXITCODE in PowerShell). The Dart tool refuses an existing output name. OpenSSL can overwrite output files, so use fresh names. Do not modify course.json between prepare and attach; any content change requires preparing and signing again. Verification with the supplied key is not QQL registry approval.

Import course-signed.zip in a QQL version containing your approved key. Check the verified publisher, version, content and media. Test an update against the previous installed release and its progress. Distribute that exact ZIP. Re-exporting through QQL preserves the normalized signed content and signature; editing signed content invalidates it.

The signature covers the normalized Course JSON, including embedded data and each media: SHA-256 reference. The ZIP verifies each file against its signed reference, so replacing media bytes fails import. An in-app publishing interface is not implemented.''',
  'publisherSigningHelp.mediaRules.title':
      r'''7a. Media a Publisher Course can and cannot carry''',
  'publisherSigningHelp.mediaRules.body':
      r'''A portable Course ZIP contains course.json, a package manifest and each non-bundled media file actually used by the Course. The app supplies bundled assets/ media.

Embedded custom Lesson icons, custom flags and Recognize characters images travel inside course.json. Recorded MP3s and ordinary imported exercise images travel as content-addressed media: files in the ZIP. The ZIP includes Admin-added Shared Image Library images used by the Course, without importing them into the recipient's Shared Image Library.

The Publisher must have distribution rights for every included file. A Course with media: references cannot be installed from JSON alone; use its complete ZIP. Missing, altered or oversized media is refused before installation.

An update backs up the previous official Course and its media, then removes media no longer used by the new version. Uninstall keeps the Course media and backup for later reinstallation.''',
  'publisherSigningHelp.mediaCredits.title': r'''7b. Media credits''',
  'publisherSigningHelp.mediaCredits.body':
      r'''Record the author and licence of any third-party image or recording in Course Info Editor, under License / Rights. The entries are stored in the course's mediaAttributions and are inside the signed payload. Admin-added Shared Image Library images may also carry per-image attribution in their metadata; this travels in the Course and ZIP manifest when used. Course Audit raises a warning when a course carries media of its own and records no credit; the warning does not block export or import. Media supplied with QuisquisLingo is already credited in the application and needs no entry.''',
  'publisherSigningHelp.importPolicy.title':
      r'''8. Import policy and existing courses''',
  'publisherSigningHelp.importPolicy.body':
      r'''New externalOfficial imports require a valid signature from an active approved key. Missing, malformed, invalid, revoked or unknown signatures are blocked before storage. A Publisher Course with media: references must arrive as a complete ZIP; package validation checks every file against its signed digest before installation. The app computes verification status; a serialized verified flag is never proof. A lower/equal official version or another publisher cannot replace an installed official course. Unsigned imports cannot downgrade verified courses.

Custom courses remain unsigned and subject to ordinary import validation. Unverified official files are not automatically converted to custom. Existing Publisher Course files that cannot be verified remain on disk and in Course Studio with Verification required; their progress is preserved and they are excluded from learner delivery. To reactivate, import a newer valid signed release with matching identity/provenance and explicitly confirm association with the existing course.

Authenticity is checked again when stored external courses and backup history are read. Revocation or file tampering removes verified status without deleting the course. Backups do not bypass import verification.

Bundled official courses rely on app distribution and retain their existing provenance/checksum checks. They need no separate per-course signature in this phase. An external JSON claiming bundledOfficial is rejected. Imported courses cannot replace bundled identities.

Signatures do not encrypt content, prevent copying, enforce payment, prove teaching quality or establish copyright ownership. Import structure, audit and licensing rules still apply. Older app versions without this verifier provide no signature assurance.''',
  'publisherSigningHelp.keyRotation.title':
      r'''9. Lost keys, rotation and revocation''',
  'publisherSigningHelp.keyRotation.body':
      r'''Publisher: restore a lost key from its protected backup. If recovery fails or compromise is suspected, stop using the key and contact the owner through the independent channel. Provide publisherId, old fingerprint, affected releases and incident details; never send the private key.

Owner: record the incident, recheck the representative and require a new key pair plus a fresh challenge/proof. Never accept a replacement solely because its publisher name or ID matches. Assign a new keyId. For planned rotation, retain the old approved entry while adding the new one if historical signatures should remain trusted. For compromise, mark the old key revoked in the registry and publish an app update.

A revoked key is rejected for new imports and is treated as unverified on stored-course/history reads, regardless of the release date claimed by a file. A valid newer replacement and explicit association can reactivate the preserved course. There is no trusted timestamp system for accepting historical signatures from a revoked key.

Offline devices learn about revocation only after an app update. Tell publishers and users which app version contains the change. Immediate worldwide revocation is not possible with the bundled registry. Key handling never requires deleting learner progress.''',
  'publisherSigningHelp.protocolReferences.title':
      r'''10. Protocol and references''',
  'publisherSigningHelp.protocolReferences.body':
      r'''publisherSignature uses qql-ed25519-v1:<keyId>:<signatureBase64>. The signature is 64 bytes in canonical standard Base64. The signed UTF-8 message is QQL-COURSE-SIGNATURE-V1, publisherId, keyId and the lowercase officialChecksum, each on its own LF-terminated line, including the final newline. No BOM is included.

The checksum is SHA-256 over model-normalized Course.toJson() after excluding officialChecksum, publisherSignature and publisherVerificationStatus, sorting object keys recursively and writing compact JSON. Array order is preserved. This is QQL canonicalization, not RFC 8785/JCS. Unknown fields discarded by the model are outside the signed payload. Use the QQL preparation tool; other-language serialization is not assumed compatible.

Publisher checklist: protected key/backup; approved identity and key; completed audit and licenses; prepared payload; signed bytes; attached signature; packaged media; import/update checked on a trusted-registry app; distribute the tested ZIP.

Owner checklist: independent identity check; fingerprint and one-use challenge checked; decision recorded; registry entry reviewed; valid/invalid import tests passed; media limits respected and third-party media credited in mediaAttributions; publisher informed of the supported app version. Keep the normal build free of the Dummy test opt-in.

References:
https://docs.openssl.org/3.0/man1/openssl-genpkey/
https://docs.openssl.org/3.0/man1/openssl-pkey/
https://docs.openssl.org/3.0/man1/openssl-pkeyutl/
https://pub.dev/documentation/cryptography/latest/cryptography/Ed25519-class.html''',
  'publisherSigningHelp.dummyPublisherTesting.title':
      r'''11. Dummy publisher: automated and manual tests''',
  'publisherSigningHelp.dummyPublisherTesting.body':
      r'''Dummy Publisher — TEST ONLY has publisherId org.quisquislingo.test.dummy and keyId dummy-1. Its public test key pair and course fixtures live under test/fixtures/publishers. The private key is intentionally public test data: never use it for a real publisher. It is not an app asset.

Automated tests inject the Dummy registry explicitly. Normal app builds do not trust it. For manual testing, enable the compile-time flag:

flutter run -d windows --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true

A release-mode test build is also possible:

flutter build windows --release --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true

These builds show a TEST ONLY banner and recognize Dummy. Do not distribute them as public production releases. A public build must omit the flag; build into a clean output location so artifacts cannot be confused.

Import test/fixtures/publishers/dummy-signed-media.zip through Course Studio → Course Import → Open from… or copy it to {folderCourseImports}/import.zip. Expect the verified publisher confirmation and the packaged recording. Then import dummy-signed-v2.json to test an update that removes the unused recording. dummy-unsigned.json must be rejected; changing a signed title must also be rejected, even if an attacker recalculates the checksum. A normal build without the flag rejects the Dummy signed files as an unknown key.

Dummy testing requires no approval request to a real publisher. All dummy release files must retain their TEST ONLY identification.''',
  'exerciseHelp.title': r'''Exercise Help''',
  'exerciseHelp.search': r'''Search Exercise Help''',
  'exerciseHelp.clearSearch': r'''Clear search''',
  'exerciseHelp.noResults': r'''No Exercise Help results match your search.''',
  'exerciseHelp.category.multipleChoice': r'''Multiple choice''',
  'exerciseHelp.category.translation': r'''Translation''',
  'exerciseHelp.category.textInput': r'''Text input''',
  'exerciseHelp.category.matching': r'''Matching''',
  'exerciseHelp.category.ordering': r'''Ordering''',
  'exerciseHelp.category.presentation': r'''Presentation''',
  'exerciseHelp.supplement.answerVariants.title': r'''Answer variants''',
  'exerciseHelp.supplement.answerVariants.body':
      r'''Multiple complete equivalent answers may be entered on separate lines. Compact syntax is optional: {Io} makes “Io” optional; [prendo|vorrei] chooses one independent alternative; and (non arrivo <> oggi) swaps only declared phrase parts. Grouped alternatives use *: to link by position: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] accepts “il tuo denaro” and “i tuoi soldi”, never “il tuoi soldi” or “i tuo denaro”. Two or more linked groups are required and every linked group must have the same number of alternatives. Linked groups compose with {}, ordinary [] and valid <> scopes. During reordering, terminal punctuation stays at the final sentence end. Expansion is deterministic, removes duplicates, and rejects malformed syntax or more than 128 variants instead of truncating.''',
  'exerciseHelp.supplement.textEvaluationAndCorrections.title':
      r'''Text evaluation and corrections''',
  'exerciseHelp.supplement.textEvaluationAndCorrections.body':
      r'''QQL accepts any configured complete answer or syntax-expanded variant after the established case, punctuation, whitespace, apostrophe and accent rules. Type the translation also permits one omitted or duplicated repeated letter in a word of at least five characters when every word position is otherwise unchanged. Its incorrect feedback shows up to three similarity-ranked valid answers and says Some possible translations when more exist. Its correct feedback shows up to two alternatives, excluding the matched canonical answer even after typo tolerance. No alternatives means no empty section. Ties keep author order and ranking never changes correctness. Other typed presets retain their canonical Correct answer. Feedback names only differences actually used; exact answers show no false difference reason.''',
  'exerciseHelp.supplement.contextualComprehensionExample.title':
      r'''Contextual comprehension example''',
  'exerciseHelp.supplement.contextualComprehensionExample.body':
      r'''Question: What does Jane mean?

Context:
Jane: I thought Jim was coming with us.
Jim: I changed my mind.
Jane: That’s just great.

Question and Context are separate. Context can be text, audio, or both. Dialogue turns are optional; an announcement, short passage or situation is equally valid. Configure answer choices separately.''',
  'exerciseHelp.preset.choice.description':
      r'''Learner chooses the correct translation from alternatives.''',
  'exerciseHelp.preset.gap_choice.description':
      r'''Learner selects the missing word or expression.''',
  'exerciseHelp.preset.icon_choice.description':
      r'''Learner chooses the image corresponding to the prompt.''',
  'exerciseHelp.preset.script_recognition.description':
      r'''Recognize printed or handwritten characters: Image to text or Text to image.''',
  'exerciseHelp.preset.listening_choice.description':
      r'''Learner listens and chooses the matching written answer.''',
  'exerciseHelp.preset.listening_comprehension.description':
      r'''Learner listens to a passage and selects the correct answer.''',
  'exerciseHelp.preset.reading_comprehension.description':
      r'''Learner reads a passage and selects the correct answer.''',
  'exerciseHelp.preset.dialogue_response.description':
      r'''Learner reads a situation and selects the best response.''',
  'exerciseHelp.preset.contextual_comprehension.description':
      r'''Learner reads and/or listens to context and answers a separate question.''',
  'exerciseHelp.preset.type_translation.description':
      r'''Learner types a translation in the target language.''',
  'exerciseHelp.preset.build_translation.description':
      r'''Learner constructs a translation using provided word blocks.''',
  'exerciseHelp.preset.translation_choice_to_target.description':
      r'''Select: learner sees source-language text and picks its target-language translation.''',
  'exerciseHelp.preset.translation_choice_to_source.description':
      r'''Select: learner sees target-language text and picks its source-language translation.''',
  'exerciseHelp.preset.fill_blank.description':
      r'''Learner types the text missing from a word or phrase.''',
  'exerciseHelp.preset.type_missing_word.description':
      r'''Complete a missing word after its first letter is provided.''',
  'exerciseHelp.preset.listening_spelling.description':
      r'''Learner listens and types the heard word or passage.''',
  'exerciseHelp.preset.missing_word.description':
      r'''Learner listens and completes one or more gaps in a transcript.''',
  'exerciseHelp.preset.matching.description':
      r'''Learner matches corresponding textual items.''',
  'exerciseHelp.preset.word_match.description':
      r'''Learner matches words with their translations.''',
  'exerciseHelp.preset.super_match.description':
      r'''Learner matches related target-language items.''',
  'exerciseHelp.preset.audio_match.description':
      r'''Learner matches audio with the corresponding item.''',
  'exerciseHelp.preset.word_order.description':
      r'''Learner restores target-language blocks to the correct order.''',
  'exerciseHelp.preset.image_word.description':
      r'''Learner builds the word represented by an image.''',
  'exerciseHelp.preset.flashcard.description':
      r'''Presents learning material without an ordinary scored answer.''',
  'exerciseHelp.preset.choice.body':
      r'''The learner sees a source-language prompt and text alternatives, then chooses the correct target-language translation. Provide a clear prompt, at least two text answers and one correct answer. Text is supported; optional prompt audio or an image can supplement it. Keep distractors plausible but unambiguously wrong. Example: “How do you say good morning?”''',
  'exerciseHelp.preset.gap_choice.body':
      r'''The learner sees a sentence containing ___ and chooses the missing word or expression. Provide one text gap, answer blocks and one correct answer. Text is supported. Use exactly one gap where possible and make only one option grammatically and semantically correct.''',
  'exerciseHelp.preset.icon_choice.body':
      r'''The learner sees a question and image choices, then selects the matching image. Provide one answer and image/icon entry per option plus the correct answer number. Text and images are supported. Every option needs a corresponding visual.''',
  'exerciseHelp.preset.script_recognition.body':
      r'''Each item pairs a character image with its corresponding text.

Image to text: learners see a character image and choose the matching text.

Text to image: learners see the text and choose the matching character image.

The text can be the character’s name, sound, pronunciation, transliteration or another identifying label.

Provide at least two options; exactly one is correct. Multiple prompt images may show print, handwriting or different fonts. Use bundled images or portable imported images, never absolute local paths. Preview uses the normal Select learner behavior.''',
  'exerciseHelp.preset.listening_choice.body':
      r'''The learner hears audio and chooses the matching written answer. Spoken text contains exactly what the learner should hear, for example: Buongiorno, come stai? On-Device TTS sends this text to the device’s native speech engine. Recorded MP3 resolves Course Audio Library text mappings; Hybrid tries a complete MP3 sequence before native TTS. For MP3, open Course Editor > Audio Library, copy files to {folderAudioImports}, press Import MP3, then Associate recording with its Word or expression and select Recorded MP3 only or Hybrid. There is no per-exercise MP3 attachment. Physical files are grouped by learning language; references belong to the Course. Verified Course backups copy referenced files; JSON alone does not transfer MP3 bytes. Provide written alternatives and exactly one correct answer; avoid visible text that gives away the audio.''',
  'exerciseHelp.preset.listening_comprehension.body':
      r'''The learner listens to a passage and selects the correct answer to a separate question. Provide audio text, the question, alternatives and one correct answer. Audio and text are supported. The answer should require understanding the passage.''',
  'exerciseHelp.preset.reading_comprehension.body':
      r'''The learner reads a passage and selects the answer to a separate question. Provide context text, the question, alternatives and one correct answer. Text is supported, with optional exercise imagery. Keep the passage long enough to test comprehension.''',
  'exerciseHelp.preset.dialogue_response.body':
      r'''The learner reads a situation and question, then chooses the best of two responses. Provide target-language context, a question, exactly two responses and one correct answer. Text is supported. Display order is randomized.''',
  'exerciseHelp.preset.contextual_comprehension.body':
      r'''The learner reads and/or listens to context and answers a separate multiple-choice question. Provide a question, text or audio context (or both), answers and one correct answer. Dialogue is optional: enter one “Speaker: text” turn per line. Text and audio are supported, and an exercise image may supplement the context. Example: ask what a speaker means after a short exchange.''',
  'exerciseHelp.preset.type_translation.body':
      r'''The learner sees source text and freely types a target-language translation. Provide the source, one or more complete accepted translations, and an optional hint. Use lowercase except for proper names. Accepted lines may use optional {}, independent [a|b], linked [*:a|b] groups with equal counts, and valid <> reorder scopes. Expand answers opens a selectable, copyable preview without changing content. Use expanded answers adds independent explicit lines; editing or deleting the source expression never changes them. Equivalent explicit answers are not added twice, and overflow beyond 128 answers is rejected without partial changes. Wrong feedback shows up to three valid translations ranked by existing similarity; correct feedback shows up to two other translations, excluding the matched canonical answer. Ties keep author order. Ranking never changes acceptance. One omitted or duplicated repeated letter is tolerated conservatively, but substitutions and missing or extra words are not.''',
  'exerciseHelp.preset.build_translation.body':
      r'''The learner sees source text and constructs its target-language translation from word blocks. Provide source text, available literal blocks and one or more complete literal correct translations. Answers can be added, removed and reordered; each must be constructible from distinct block occurrences. Repeated words require repeated blocks, and no more than two blocks may remain unused. Type-the-translation syntax, typo tolerance and similarity matching do not apply.''',
  'exerciseHelp.preset.translation_choice_to_target.body':
      r'''Select · single answer, checked immediately. Direction, languages and the learner instruction are set by this type.

The learner sees source-language text and picks its correct target-language translation. QQL generates the only learner instruction, “Pick the correct [Target language] translation”, from the course languages, so you never write it. Provide the text to translate, two to five different target-language answers and one correct answer. Text is supported, with an optional image. A wrong choice reveals the correct answer. After answering, the learner can play the correct answer with text-to-speech when it is available; the exercise never depends on audio. Keep distractors plausible but unambiguously wrong. Example (for an English → Italian course): “I am going to London” with Vado a Londra. / Sono andato a Londra. / Vengo da Londra.''',
  'exerciseHelp.preset.translation_choice_to_source.body':
      r'''Select · single answer, checked immediately. Direction, languages and the learner instruction are set by this type.

The learner sees target-language text and picks its correct source-language translation. QQL generates the only learner instruction, “Pick the correct [Source language] translation”, from the course languages, so you never write it. Provide the text to translate, two to five different source-language answers and one correct answer. Text is supported, with an optional image. A wrong choice reveals the correct answer. The learner can play the target-language text with text-to-speech when it is available; the exercise never depends on audio. Keep distractors plausible but unambiguously wrong. Example (for an English → Italian course): “Vado a Londra.” with I am going to London. / I went to London. / I am coming from London.''',
  'exerciseHelp.preset.fill_blank.body':
      r'''The learner sees an incomplete word or phrase and types the missing text. Provide the prompt, one or more accepted answers, an optional non-revealing hint and optional complete-phrase audio. Text and audio are supported. Accepted lines may use answer variants.''',
  'exerciseHelp.preset.type_missing_word.body':
      r'''Enter a sentence with one ___ gap and complete accepted words. Enter the complete missing word. The first letter shown is a hint. QQL derives the first Unicode grapheme automatically; all accepted words must share exactly that first grapheme. The complete word entered uses normal Input normalization and feedback. Example: the learner sees é______ and enters école, not cole. The complete sentence is shown after checking.''',
  'exerciseHelp.preset.listening_spelling.body':
      r'''The learner hears audio and types what was heard. Provide the audio text and accepted transcription. Audio and text are supported. Return or Enter submits the answer.''',
  'exerciseHelp.preset.missing_word.body':
      r'''The learner hears audio while reading a transcript with one or more gaps, then types each missing word. Provide the complete transcript/audio and every missing item in order. Audio and text are supported. Every missing item must occur in the transcript.''',
  'exerciseHelp.preset.matching.body':
      r'''The learner sees two shuffled columns and matches corresponding text items. Provide non-empty left = right pairs. Text is supported. Pair relationships, not display positions, define correctness.''',
  'exerciseHelp.preset.word_match.body':
      r'''The learner matches source-language words with their target-language translations. Provide exactly three text pairs. Text is supported. Each visible item must be unique after ordinary normalization.''',
  'exerciseHelp.preset.super_match.body':
      r'''The learner matches related target-language items such as synonyms or opposites. Provide exactly three text pairs and an instruction naming the relationship. Text is supported. Do not mix unrelated relationship rules.''',
  'exerciseHelp.preset.audio_match.body':
      r'''The learner plays audio items and matches each one to visible text. Provide exactly three audio-text pairs with no distractors. Audio and text are supported. Each audio and visible answer must be unique.''',
  'exerciseHelp.preset.word_order.body':
      r'''The learner rearranges target-language blocks into their correct order. Provide the available text blocks and correct order. Text is supported. Use no more than two distinct distractors; this preset tests ordering rather than translation.''',
  'exerciseHelp.preset.image_word.body':
      r'''The learner sees an image and orders letter or syllable blocks to form its word. Provide an image, instruction, blocks and correct order. Image and text are supported. Include only blocks used by the answer; distractors are not allowed.''',
  'exerciseHelp.preset.flashcard.body':
      r'''The learner sees a term, meaning, optional usage and optional pronunciation audio, then chooses Understood or Review later. Provide the learning material rather than a scored answer. Text and audio are supported, with optional imagery. Presentation content does not earn base correct-answer XP.''',
  'exerciseHelp.field.choice.prompt.body':
      r'''The instruction shown to the learner. Example: How do you say this in Italian?

What to enter
Enter the instruction here; put the word or phrase to translate in Question.

Checks
Keep the instruction consistent with the question and answer choices.

Example
How do you say this in Italian?''',
  'exerciseHelp.field.choice.question.body':
      r'''The word or phrase the learner must translate. Example: Good morning

What to enter
Enter the source-language word or phrase separately from the instruction in Prompt.

Checks
Provide matching target-language answer choices and mark exactly one correct.

Example
Good morning''',
  'exerciseHelp.field.choice.answers.body':
      r'''Defines the alternatives presented to the learner.

What to enter
Enter one literal answer per line, with at least two non-empty lines. Blank lines are ignored. The first non-empty line is answer 1. Compact accepted-answer syntax does not create choices.

Checks
Select one valid Correct answer number. Avoid duplicate answers and make distractors plausible but unambiguously wrong. Select the image also needs one icon/image key per answer in the same order.

Example
caffè
acqua
pane''',
  'exerciseHelp.field.choice.correct.body':
      r'''Identifies the correct option or options from the answer list.

What to enter
Enter one whole number, counting non-empty answer lines from 1. When Multiple correct answers is enabled, enter every correct number separated by commas, e.g. 1, 3.

Checks
Every number must be between 1 and the number of answers. Recheck it after reordering or deleting answer lines.

Example
2 selects the second non-empty answer line.''',
  'exerciseHelp.field.choice.requiredSelections.body':
      r'''Sets the minimum number of options the learner must select before checking a multiple-selection Choice exercise.

What to enter
Enter a whole number between 1 and the number of answers, or leave blank to default to the number of correct answers.

Checks
The Check button stays disabled until at least this many options are selected. This does not cap how many options may be selected; correctness always requires an exact match of the selected set to the correct set.

Example
2''',
  'exerciseHelp.field.choice.gapLayout.body':
      r'''Shows the fixed sentence with one or more inline blanks the learner fills, in order, by tapping options from a list.

What to enter
Write the sentence and put each answer word or phrase directly inside braces: {answer}. Example: I {am} going {to} London. Each tap fills the first remaining empty blank, whichever option is tapped — placement does not check correctness, so the right words in the wrong blanks are still marked incorrect. If the same word answers more than one gap, write it inside each of those braces: {Was} she happy? {Was} he late? — the learner taps it once per blank it needs to fill. Extra options that are not the answer to any gap go in Distractor options (optional).

Checks
At least one {…} gap is required, and every gap must contain non-empty text. Literal { or } characters cannot appear anywhere else in the sentence.

Example
I {am} going {to} London.''',
  'exerciseHelp.field.choice.tokens.body':
      r'''Adds options the learner can select that are not the answer to any gap.

What to enter
One extra option per line. Include 0, 1 or at most 2 distractors.

Checks
Distractor options must not repeat any gap answer text.

Example
perhaps''',
  'exerciseHelp.field.choice.tts.body':
      r'''Defines the word or passage that the learner hears.

What to enter
Enter one spoken text, not an MP3 filename or path. Multiple lines form the same passage. Course Audio Library selects On-Device TTS, Recorded MP3 or Hybrid and maps recordings to exact words or expressions.

Checks
Listening exercises require non-empty audio text. For contextual comprehension, supply the text/audio context selected by Context mode. Preview playback and review missing recorded mappings in Audit.

Example
Vorrei un caffè, per favore.''',
  'exerciseHelp.field.choice.image.body':
      r'''Adds one image to the exercise prompt or context.

What to enter
Choose a flat image from the shared image library (managed by admins), or place exactly one PNG, JPG, JPEG or WebP file in {folderImageImports} and press Import custom image. Any course editor can import a custom image; it is not added to the shared library. Import copies the original bytes to local app storage; it does not resize, crop or change transparency.

Checks
Maximum 50 KB (51,200 bytes). 256 × 256 pixels and 15 KB or less are recommendations, not enforced dimensions. Image-prompt ordering requires an image; other current presets may omit it. Missing or multiple source files and oversized files are rejected. Preview checks that the image displays. Course JSON stores the image path, not these image bytes, so custom exercise images are not portable through course JSON alone.

Example
Bundled path: assets/exercise_images/house.webp
Custom paths are selected and stored by the importer.''',
  'exerciseHelp.field.gap_choice.question.body':
      r'''Shows the sentence the learner completes by choosing a block.

What to enter
Use ___ (3 underscores) for the missing word. Example: The cat ___ black. Enter one target-language sentence with the missing word or expression replaced by that gap. Enter possible replacements as separate answer lines.

Checks
At least one ___ marker is required; more than one produces a warning. The sentence with the correct answer inserted must contain at least two words.

Example
Vorrei un ___, per favore.''',
  'exerciseHelp.field.gap_choice.correct.body':
      r'''Identifies the one correct option from the answer list.

What to enter
Enter one whole number, counting non-empty answer lines from 1. Do not paste the answer text or a JSON index.

Checks
The number must be between 1 and the number of answers. Dialogue response accepts 1 or 2. Recheck it after reordering or deleting answer lines.

Example
2 selects the second non-empty answer line.''',
  'exerciseHelp.field.gap_choice.hint.body':
      r'''Gives the learner a useful clue.

What to enter
Enter one optional plain-text clue. Leave blank if the exercise needs no hint. Line breaks remain part of the same clue.

Checks
A hint must not reveal a canonical correct answer. Merely repeating the prompt produces a warning.

Example
Think of a hot drink served in a small cup.''',
  'exerciseHelp.field.icon_choice.question.body':
      r'''The concrete content to which the learner responds.

What to enter
Enter one question as plain text, separately from the reading, audio or dialogue context. Line breaks do not create separate questions.

Checks
Contextual comprehension requires a separate question. For Dialogue response, use the target language. Match the question to the declared correct answer.

Example
How are you?''',
  'exerciseHelp.field.icon_choice.icons.body':
      r'''Associates each Select the image answer with its visual.

What to enter
Enter one icon key or existing bundled assets/ image path per line, in the same order as the answer options. Blank lines are ignored. Keys include water, home, coffee, person, hello, sun, moon, thanks, tree, flower, bread, train, bus, bike, shirt, book, food and shop.

Checks
The number of keys must equal the number of answers. An unknown key shows the generic image icon, so Preview every choice. A custom Exercise image below the form is a separate shared prompt image, not an option image.

Example
coffee
water
assets/exercise_images/house.webp''',
  'exerciseHelp.field.script_recognition.scriptMode.body':
      r'''Choose how the learner recognizes a character or syllable.

What to enter
Image to text shows one or more prompt images with text answer options. Text to image shows a text prompt with image answer options. Switching modes retains both sets of fields during this editing session; saving uses the selected mode.

Checks
Both modes use normal Select with at least two options and exactly one correct option. Mode changes do not create a different learner engine.

Example
Show several handwritten forms of 가 and ask the learner to choose ga.''',
  'exerciseHelp.field.script_recognition.scriptPrompt.body':
      r'''Supplies the text that the learner matches to an image.

What to enter
Enter the character, syllable, sound transcription or instruction as plain text. Keep the image answers in their separate option fields.

Checks
Text to image requires a nonempty text prompt, at least two image-only options and exactly one correct option.

Example
Choose the character pronounced ga.''',
  'exerciseHelp.field.script_recognition.scriptPromptImages.body':
      r'''Shows one or more representations of the same character or syllable.

What to enter
Add printed forms, different fonts, handwriting or stylistic variants. Choose an Image Bank image or import a PNG, JPEG or WEBP from {folderImageImports}. Imported bytes belong to the course and are retained in Course JSON; no absolute local path is saved.

Checks
Image to text requires at least one readable prompt image and at least two text options. Each imported image must be at most 50 KB (51,200 bytes) and no more than 4096 pixels in either dimension. Invalid image data blocks Save and Preview.

Example
Show a printed 가 and a handwritten 가 above the options ga and na.''',
  'exerciseHelp.field.script_recognition.scriptTextOptions.body':
      r'''Provides the possible readings of the prompt images.

What to enter
Enter one literal reading or label in each option field. Add or remove options with the adjacent controls. Reordering keeps the same option identity and correct-answer selection.

Checks
Image to text requires at least two nonempty text-only options and exactly one correct option. Answer-expression syntax is not expanded for Select options.

Example
Option 1: ga
Option 2: na''',
  'exerciseHelp.field.script_recognition.scriptImageOptions.body':
      r'''Provides the images from which the learner selects an answer.

What to enter
Choose one portable Image Bank or imported PNG, JPEG or WEBP image for each option. Imported bytes are stored with the course. Reordering keeps the image option identity and correct-answer selection.

Checks
Text to image requires at least two readable image-only options and exactly one correct option. Imported images must be at most 50 KB (51,200 bytes) and 4096 pixels in either dimension. Absolute local paths and invalid image data are rejected.

Example
For the prompt ga, offer an image of 가 and an image of 나.''',
  'exerciseHelp.field.script_recognition.scriptCorrect.body':
      r'''Identifies the single option that answers the prompt.

What to enter
Select the circle beside the correct option. Selecting a different circle replaces the previous correct choice. Reordering an option keeps its correct-answer status; deleting it requires choosing another correct option.

Checks
Exactly one existing option must be correct. A Draft may remain incomplete; Preview and Published Save require a valid correct choice.

Example
Mark ga correct for an image of 가.''',
  'exerciseHelp.field.listening_choice.tts.body':
      r'''Enter exactly what the learner should hear. On-Device TTS sends this text to the device’s native text-to-speech engine; no audio file is required in that mode. Example: Buongiorno, come stai?

What to enter
Playback follows the Course Audio Library mode. Recorded MP3 resolves this text against Course recordings; Hybrid tries a complete recording sequence before native TTS. Enter spoken words, not an MP3 filename or path. For MP3, open Course Editor > Audio Library, place files in {folderAudioImports}, press Import MP3, then Associate recording and enter its Word or expression. Select Recorded MP3 only or Hybrid. Exercises use these text mappings; there is no per-exercise file attachment.

Checks
Recordings are stored physically by learning language; metadata and references belong to the Course. Verified Course backups copy referenced recordings. Course JSON does not contain MP3 bytes and JSON alone does not transfer recordings.

Example
Buongiorno, come stai?''',
  'exerciseHelp.field.reading_comprehension.prompt.body':
      r'''Provides the passage needed to answer the separate comprehension question.

What to enter
Enter one passage in plain text. Multiple lines or paragraphs remain part of the passage.

Checks
A passage containing words is required. One or two lexical words produce a warning; at least three are recommended. The question should test comprehension.

Example
Maria prende il treno. Va a Roma.''',
  'exerciseHelp.field.dialogue_response.prompt.body':
      r'''Sets the situation for choosing the best dialogue response.

What to enter
Enter one situation in the target language. Keep the question separate and provide exactly two response options.

Checks
Context, question and both responses must be non-empty. Choose one response as correct.

Example
Un amico ti saluta al mattino.''',
  'exerciseHelp.field.dialogue_response.answers.body':
      r'''Provides the two possible responses to the dialogue situation.

What to enter
Enter exactly two non-empty lines, both in the target language. Each line is one complete response; blank lines are ignored.

Checks
Set Correct response number to 1 or 2. The learner sees randomized display order, while the chosen correct response remains the same.

Example
Buongiorno!
Buonanotte!''',
  'exerciseHelp.field.contextual_comprehension.contextMode.body':
      r'''Text is a presentation mode: learners read the main passage entered in Context text. Example: Marta takes the train to work every morning.

What to enter
Select one mode: Text, Audio, or Text and audio. Text modes expose Context text and optional structured dialogue; audio modes expose Context audio text.

Checks
Supply usable text, audio or dialogue context plus a separate question and answer options. An image alone is not sufficient context. Preview the selected mode.

Example
Choose Text, then enter: Marta takes the train to work every morning.''',
  'exerciseHelp.field.contextual_comprehension.context.body':
      r'''The passage or background the learner reads to answer the question. Example: Marta is describing her daily routine. Marta takes the train to work every morning.

What to enter
Enter one plain-text context, with paragraphs if useful. Use Structured dialogue for speaker-labelled turns. The question belongs in its own field.

Checks
At least one usable text, audio or dialogue context is required. When choosing Text and audio, check both representations convey the intended context.

Example
Marta is describing her daily routine. Marta takes the train to work every morning. Question: How does Marta travel to work?''',
  'exerciseHelp.field.contextual_comprehension.dialogue.body':
      r'''Presents context as a sequence of named speaker turns.

What to enter
Enter one turn per line as Speaker: text. The first colon separates the speaker from the spoken text. Blank lines are ignored. Leave blank for ordinary non-dialogue context.

Checks
Every entered turn needs both a non-empty speaker and non-empty text. Speaker labels do not create separate voice settings.

Example
Jane: Are you coming?
Jim: I changed my mind.''',
  'exerciseHelp.field.type_translation.prompt.body':
      r'''Supplies the text that the learner translates.

What to enter
Enter one source-language sentence or passage. Line breaks belong to the same prompt; accepted answers or correct translations go in their own fields.

Checks
Provide non-empty source text and complete equivalent target-language answers. Keep the intended meaning unambiguous.

Example
I would like a coffee.''',
  'exerciseHelp.field.type_translation.accepted.body':
      r'''Defines complete target-language translations accepted for the source text.

What to enter
Enter complete equivalent answers on separate lines. Blank lines are ignored. Optional text: {Io} prendo un cappuccino. Alternatives: [prendo|vorrei] un cappuccino. Linked alternatives: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] pairs alternatives by position; use at least two linked groups with equal alternative counts. Scoped reordering: (non arrivo <> oggi). Without parentheses, a casa <> domani reorders the whole expression. Terminal punctuation stays at the sentence end; generated sentence starts are capitalized. Use lowercase except for proper names.

Checks
At least one accepted answer is required. Malformed expressions are rejected. Expansion is deterministic, duplicate results are removed, and the combined limit is 128 answers; simplify an expression that exceeds it. Declare equivalent answers explicitly: syntax does not invent translations.

Example
{Io} [prendo|vorrei] un cappuccino''',
  'exerciseHelp.field.build_translation.tokens.body':
      r'''Supplies the blocks used to construct the configured correct translations.

What to enter
Enter one literal block per line. Blank lines are ignored. Include enough distinct occurrences to construct every correct translation; repeated words require repeated lines. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the {answer} braces in Target sentence with gaps, and this field only adds optional unused distractors.

Checks
Every correct translation must be constructible from these blocks. At most 2 blocks may be unused by every correct translation. A block used by any configured answer is not an unused distractor. Answer-expression syntax is not expanded.

Example
Io
prendo
vorrei
un
caffè''',
  'exerciseHelp.field.build_translation.correctTranslation.body':
      r'''Defines one complete literal answer for Build the translation.

What to enter
Each separate answer entry holds one complete target-language sentence. Use Add correct translation for another answer and the drag handle to reorder answers.

Checks
At least one non-empty answer is required. Answers must be unique after case, spacing and terminal-punctuation normalization, and constructible from distinct available block occurrences. Internal punctuation is preserved. No optional, alternative or reorder expressions, similarity matching or typo acceptance are applied.

Example
Io vorrei un caffè.''',
  'exerciseHelp.field.build_translation.gapLayout.body':
      r'''Shows the fixed sentence text with one or more inline blanks the learner fills with word or phrase tiles.

What to enter
Write the fixed sentence and put each answer word or phrase directly inside braces: {answer}. Example: I {am} going {to} London. Each {…} segment is both the gap and its correct answer, so no separate Correct answers / Correct sentence field is needed in this mode. Extra distractor blocks that are not used by any gap still go in Available word blocks / Extra distractor blocks (optional).

Checks
At least one {…} gap is required, and every gap must contain non-empty text. Literal { or } characters cannot appear anywhere else in the sentence — every { must be paired with a matching } directly around one answer. Existing whole-sentence Arrange exercises are unaffected unless Inline gaps is enabled.

Example
I {am} going {to} London.''',
  'exerciseHelp.field.translation_choice_to_target.question.body':
      r'''The source-language word or phrase the learner translates.

What to enter
Enter one source-language word, phrase or sentence. Do not write an instruction: QQL adds “Pick the correct [Target language] translation” automatically. Line breaks stay part of the same text.

Checks
Required. Provide target-language answer options and mark exactly one correct.''',
  'exerciseHelp.field.translation_choice_to_target.answers.body':
      r'''The target-language translations the learner chooses from.

What to enter
Enter one complete target-language translation per line, from 2 to 5 options. Blank lines are ignored. Options are shown in random order.

Checks
Between 2 and 5 options, none blank and no phrase repeated (ignoring case, extra spaces and final punctuation), and exactly one correct. Keep distractors plausible but clearly wrong.''',
  'exerciseHelp.field.translation_choice_to_target.correct.body':
      r'''Identifies the one correct option.

What to enter
Enter one whole number, counting non-empty answer lines from 1.

Checks
Must be between 1 and the number of answers. Recheck it after reordering or deleting lines.''',
  'exerciseHelp.field.translation_choice_to_target.image.body':
      r'''Adds one image to the exercise prompt or context.

What to enter
Choose a flat image from the shared image library (managed by admins), or place exactly one PNG, JPG, JPEG or WebP file in {folderImageImports} and press Import custom image. Any course editor can import a custom image; it is not added to the shared library. Import copies the original bytes to local app storage; it does not resize, crop or change transparency.

Checks
Maximum 50 KB (51,200 bytes). 256 × 256 pixels and 15 KB or less are recommendations, not enforced dimensions. Image-prompt ordering requires an image; other current presets may omit it. Missing or multiple source files and oversized files are rejected. Preview checks that the image displays. Course JSON stores the image path, not these image bytes, so custom exercise images are not portable through course JSON alone.''',
  'exerciseHelp.field.translation_choice_to_source.question.body':
      r'''The target-language word or phrase the learner translates.

What to enter
Enter one target-language word, phrase or sentence. Do not write an instruction: QQL adds “Pick the correct [Source language] translation” automatically. The learner can play this text with text-to-speech when it is available; the exercise stays fully solvable without audio.

Checks
Required. Provide source-language answer options and mark exactly one correct.''',
  'exerciseHelp.field.translation_choice_to_source.answers.body':
      r'''The source-language translations the learner chooses from.

What to enter
Enter one complete source-language translation per line, from 2 to 5 options. Blank lines are ignored. Options are shown in random order.

Checks
Between 2 and 5 options, none blank and no phrase repeated (ignoring case, extra spaces and final punctuation), and exactly one correct. Keep distractors plausible but clearly wrong.''',
  'exerciseHelp.field.fill_blank.question.body':
      r'''Shows the word or phrase that the learner completes by typing.

What to enter
Enter one incomplete word or phrase using visible gap text where useful. In Accepted answers, enter the text the learner should type, not a list of answer choices.

Checks
Supply at least one accepted answer. This existing preset does not automatically reveal a first letter.

Example
Vorrei un ___.
Accepted answer: caffè''',
  'exerciseHelp.field.fill_blank.accepted.body':
      r'''Defines the complete text the learner may type to complete the gap.

What to enter
Enter complete equivalent answers on separate lines. Blank lines are ignored. Optional text: {Io} prendo un cappuccino. Alternatives: [prendo|vorrei] un cappuccino. Linked alternatives: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] pairs alternatives by position; use at least two linked groups with equal alternative counts. Scoped reordering: (non arrivo <> oggi). Without parentheses, a casa <> domani reorders the whole expression. Terminal punctuation stays at the sentence end; generated sentence starts are capitalized. Use lowercase except for proper names.

Checks
At least one accepted answer is required. Malformed expressions are rejected. Expansion is deterministic, duplicate results are removed, and the combined limit is 128 answers; simplify an expression that exceeds it. Declare equivalent answers explicitly: syntax does not invent translations.

Example
caffè
un caffè''',
  'exerciseHelp.field.fill_blank.tts.body':
      r'''Supplies optional pronunciation text for the completed phrase.

What to enter
Enter one complete phrase, including the missing answer, or leave blank. This is spoken text, not a recording filename.

Checks
Keep this text consistent with the incomplete phrase and accepted answers. Test the pronunciation in Preview.

Example
Vorrei un caffè.''',
  'exerciseHelp.field.type_missing_word.prompt.body':
      r'''Enter the complete missing word. The first letter shown is a hint.

What to enter
Enter a sentence with exactly one ___ gap and complete accepted words, one per line. The first Unicode grapheme is derived automatically; the learner enters the complete word, including that first grapheme.

Checks
All complete accepted words must share exactly the same first grapheme. The complete word entered uses normal Input normalization and supported typo tolerance; the hint is not prepended to the response.

Example
Je vais à l’___. Answer: école. Learner sees é______ and enters école, not cole.''',
  'exerciseHelp.field.listening_spelling.prompt.body':
      r'''Supplies the visible prompt text for Type what you hear.

What to enter
Enter one text value. This preset displays the text as entered; it does not automatically remove the accepted answer from the transcript. Audio text controls what the learner hears.

Checks
Preview the prompt to make sure it does not reveal the answer you want the learner to type. Put accepted typed responses in Missing word.

Example
Listen and type the word you hear.''',
  'exerciseHelp.field.listening_spelling.missingWords.body':
      r'''Defines accepted typed responses for Type what you hear.

What to enter
Despite the compact field label, each entry is a complete accepted word or passage, not an instruction to remove text from the transcript. Enter complete equivalent answers on separate lines. Blank lines are ignored. Optional text: {Io} prendo un cappuccino. Alternatives: [prendo|vorrei] un cappuccino. Linked alternatives: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] pairs alternatives by position; use at least two linked groups with equal alternative counts. Scoped reordering: (non arrivo <> oggi). Without parentheses, a casa <> domani reorders the whole expression. Terminal punctuation stays at the sentence end; generated sentence starts are capitalized. Use lowercase except for proper names.

Checks
At least one accepted answer is required. Malformed expressions are rejected. Expansion is deterministic, duplicate results are removed, and the combined limit is 128 answers; simplify an expression that exceeds it. Declare equivalent answers explicitly: syntax does not invent translations. Match the accepted responses to Audio text and check the visible prompt in Preview.

Example
caffè''',
  'exerciseHelp.field.missing_word.prompt.body':
      r'''Supplies the complete text from which the learner view creates listening gaps.

What to enter
Enter one complete transcript including the word or expressions to hide. Use ordinary text, not pre-inserted dots or underscores. Line breaks remain part of the passage.

Checks
For Listen for missing words, every missing entry must occur in the transcript. Match Audio text to what the learner should hear.

Example
Vorrei un caffè, per favore.
Missing word: caffè''',
  'exerciseHelp.field.missing_word.missingWords.body':
      r'''Selects the words or expressions hidden in the listening transcript.

What to enter
Enter one literal word or expression per line. Multiple lines select multiple gaps, not alternative complete answers. Blank lines are ignored; do not insert gap markers in the transcript.

Checks
At least one entry is required and each entry must occur in Passage transcript, ignoring case. Duplicate entries produce a warning. Answer-expression syntax is not expanded for this list.

Example
caffè
per favore''',
  'exerciseHelp.field.matching.prompt.body':
      r'''The instruction or context shown to the learner.

What to enter
Enter one instruction or prompt as plain text. Line breaks remain part of that text; they do not create separate answers. Use the course source language for operational instructions.

Checks
Keep it consistent with the selected exercise and the separately entered question, pairs or blocks. For Match related words, state the relationship in the target language.

Example
Build the sentence.''',
  'exerciseHelp.field.matching.pairs.body':
      r'''Defines items that the learner matches across two columns.

What to enter
Enter one pair per line as left = right. The first equals sign separates the two sides. Blank lines are ignored.

Checks
At least one usable pair is required. Give both sides non-empty text and check every line contains its separator; fix incomplete lines before Preview or Save.

Example
casa = house
pane = bread''',
  'exerciseHelp.field.word_match.pairs.body':
      r'''Matches source-language words with their target-language translations.

What to enter
Enter exactly three non-empty lines as source = target. The first equals sign separates the two sides. Blank lines are ignored.

Checks
All three pairs need both sides. Check unique, unambiguous matching and remove malformed lines; fix lines without a usable separator before Preview or Save.

Example
house = casa
bread = pane
water = acqua''',
  'exerciseHelp.field.super_match.pairs.body':
      r'''Matches related words, such as synonyms or opposites.

What to enter
Enter exactly three non-empty lines as left = right, with both sides in the target language. State the relationship in Match type / instruction.

Checks
All three pairs need both sides and a usable equals separator. Check that every pair follows the stated relationship and that matching is unambiguous.

Example
grande = piccolo
caldo = freddo
aperto = chiuso''',
  'exerciseHelp.field.audio_match.pairs.body':
      r'''Matches three spoken target-language items to their visible texts.

What to enter
Enter exactly three lines as audio text = visible text. Visible text may be target-language text or its translation. The three right sides become the three visible choices; there is no separate distractor field.

Checks
Both sides are required. Avoid duplicate sounds and visible choices, including punctuation-only or capitalization-only differences. No distractors are permitted. Use Course Audio Library for recording mappings.

Example
casa = house
pane = bread
acqua = water''',
  'exerciseHelp.field.word_order.tokens.body':
      r'''Supplies the blocks the learner puts into sentence order.

What to enter
Enter one literal target-language block per line. Blank lines are ignored. Repeat a line when the answer needs another occurrence of that word or block. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the {answer} braces in Sentence with gaps, and this field only adds optional unused distractors.

Checks
Include every block occurrence used in Correct sentence. You may add 0, 1 or at most 2 unused distractor blocks. Keep block spelling and internal punctuation consistent with the correct order.

Example
Io
bevo
un
caffè
tè''',
  'exerciseHelp.field.word_order.order.body':
      r'''Defines the required order of the available word blocks.

What to enter
Enter one block per line in the correct order, not the whole sentence on one line. Blocks are joined with spaces. Blank lines are ignored. Not used when Inline gaps is enabled: gap answers are written directly inside braces in Sentence with gaps instead.

Checks
Each line must match an available block occurrence. Repeated words need separate available occurrences. This is one literal order; compact answer syntax is not expanded.

Example
Io
bevo
un
caffè''',
  'exerciseHelp.field.image_word.tokens.body':
      r'''Supplies the pieces of the word shown in the image.

What to enter
Enter one literal letter or syllable per line. Blank lines are ignored. Repeat a line if that piece occurs more than once in the word.

Checks
Include only the pieces needed for the answer: no distractors. Supply their order in Correct target-language word and select an Exercise image.

Example
ca
sa''',
  'exerciseHelp.field.image_word.order.body':
      r'''Defines the order of the letter or syllable blocks.

What to enter
Enter one letter or syllable block per line in answer order. The pieces are joined without spaces to form one word; blank lines are ignored.

Checks
Use each required available occurrence once, leave no distractors and supply the matching Exercise image.

Example
ca
sa
These pieces form casa.''',
  'exerciseHelp.field.flashcard.prompt.body':
      r'''Shows the target-language material on a Flashcard.

What to enter
Enter one word or expression. Put its meaning, pronunciation text and usage example in the separate fields.

Checks
A target word or phrase is required. Flashcard content is presentation and supplies no ordinary scored answer.

Example
buongiorno''',
  'exerciseHelp.field.flashcard.question.body':
      r'''Explains the Flashcard word or expression.

What to enter
Enter one plain-text meaning or translation. Multiple lines remain one explanation.

Checks
An empty meaning produces an Audit warning. Check that it matches the displayed word.

Example
good morning''',
  'exerciseHelp.field.flashcard.tts.body':
      r'''Supplies spoken pronunciation for the Flashcard.

What to enter
Enter the word or expression to pronounce as one text value. Do not enter a recording path; manage recordings in Course Audio Library.

Checks
Missing pronunciation text produces an Audit warning. Check that the selected course audio mode can play it.

Example
buongiorno''',
  'exerciseHelp.field.flashcard.answers.body':
      r'''Shows the Flashcard word in context.

What to enter
First non-empty line: usage sentence. Optional second non-empty line: its translation. The learner view adds “Usage:” automatically. Blank lines are ignored.

Checks
A missing usage sentence produces an Audit warning. These lines are presentation content, not answer options.

Example
Buongiorno, Maria!
Good morning, Maria!''',
  'courseInfo.title': r'''Course Info''',
  'courseInfo.authorSupportMissing':
      r'''This course does not provide an author support link.''',
  'courseInfo.authorSupportOpenFailed':
      r'''The author support link could not open.''',
  'courseInfo.authorsContributors': r'''Authors / Contributors: {value}''',
  'courseInfo.notSpecified': r'''Not specified''',
  'courseInfo.notRecorded': r'''Not recorded''',
  'courseInfo.contributors': r'''Contributors''',
  'courseInfo.illustrators': r'''Illustrators''',
  'courseInfo.origin.bundledOfficial': r'''Bundled official''',
  'courseInfo.origin.publisherCourse': r'''Publisher Course''',
  'courseInfo.origin.customCourse': r'''Custom course''',
  'courseInfo.origin.label': r'''Origin: {value}''',
  'courseInfo.publisher': r'''Publisher: {value}''',
  'courseInfo.originalCourseCreated': r'''Original Course Created: {value}''',
  'courseInfo.lastVersionEditor': r'''Last Version Editor: {value}''',
  'courseInfo.modified': r'''Modified: {value}''',
  'courseInfo.officialCourseVersion': r'''Official course version: {value}''',
  'courseInfo.officialRelease': r'''Official release: {value}''',
  'courseInfo.distributionChannel': r'''Distribution channel: {value}''',
  'courseInfo.publisherVerification': r'''Publisher verification: {value}''',
  'courseInfo.verificationRequired':
      r'''Verification required. The stored course and progress are preserved. Import a verified publisher release to reactivate it.''',
  'courseInfo.signatureScope':
      r'''Signature covers the course JSON. Separate media files are not authenticated by this signature.''',
  'courseInfo.officialChecksum': r'''Official checksum: {value}''',
  'courseInfo.officialReadOnly': r'''Official course - read only''',
  'courseInfo.courseVersion': r'''Course version: {value}''',
  'courseInfo.unconfirmed': r'''Unconfirmed''',
  'courseInfo.versionNotes': r'''Version notes:
{value}''',
  'courseInfo.internalCourseData': r'''Internal course data''',
  'courseInfo.courseModel': r'''Course Model: v{value}''',
  'courseInfo.temporarySample.title': r'''Temporary Sample''',
  'courseInfo.temporarySample.body':
      r'''This course is marked TEMPORARY SAMPLE. The preloaded material is provided only to demonstrate and test the editor. Replace sample material with reviewed content before publishing or distributing the course.''',
  'courseInfo.authorshipAndDescriptiveCredits':
      r'''Authorship and descriptive credits''',
  'courseInfo.teamLeaderTooltip':
      r'''This is descriptive information only. To assign or change Team Leader roles in QQL, use Team Manager.''',
  'courseInfo.languages': r'''Languages''',
  'courseInfo.learningLanguage': r'''Learning language: {value}''',
  'courseInfo.baseLanguage': r'''Base language: {value}''',
  'courseInfo.licenseRights': r'''License / Rights''',
  'courseInfo.license': r'''License: {value}''',
  'courseInfo.rightsHolder': r'''Rights Holder: {value}''',
  'courseInfo.derivativeWorks': r'''Derivative works: {value}''',
  'courseInfo.rightsHolderDisclaimer':
      r'''Rights Holder is descriptive legal metadata and does not control QQL permissions.''',
  'courseInfo.mediaCredits': r'''Media credits''',
  'courseInfo.mediaCreditsDisclaimer':
      r'''Media credits are descriptive and do not control QQL permissions.''',
  'courseInfo.source': r'''Source: {value}''',
  'courseInfo.courseDetails': r'''Course details''',
  'courseInfo.lessons': r'''Lessons: {value}''',
  'courseInfo.estimatedStudyTime': r'''Estimated study time: {value} {unit}''',
  'courseInfo.hour': r'''hour''',
  'courseInfo.hours': r'''hours''',
  'courseInfo.minimumAge': r'''Minimum age: {value}+''',
  'courseInfo.keywords': r'''Keywords: {value}''',
  'courseInfo.requiresBuild':
      r'''Requires QuisquisLingo build {value} or later''',
  'courseInfo.publisherContact': r'''Publisher contact''',
  'courseInfo.website': r'''Website: {value}''',
  'courseInfo.email': r'''Email: {value}''',
  'courseInfo.buyACoffee': r'''Buy a Coffee''',
  'courseInfo.supportAuthors': r'''Support this course's authors.''',
  'courseInfo.governance.title':
      r'''Course responsibility, Team assignment and authorization''',
  'courseInfo.governance.officialPublisher': r'''Official publisher: {value}''',
  'courseInfo.governance.originalCreator':
      r'''Original Course Creator: {value}''',
  'courseInfo.governance.maintainer': r'''Course Maintainer: {value}''',
  'courseInfo.governance.assignedTeam': r'''Assigned Team: {value}''',
  'courseInfo.governance.teamLeaders': r'''Team Leaders: {value}''',
  'courseInfo.governance.teamMembers': r'''Team Members: {value}''',
  'courseInfo.governance.none': r'''None''',
  'courseInfo.governance.noneAvailable': r'''None available''',
  'courseInfo.governance.disclaimer':
      r'''Course maintenance and Team governance are separate. Provenance, attribution and rights metadata do not grant editing permission.''',
  'courseInfo.fork.title': r'''Fork provenance''',
  'courseInfo.fork.notRecorded': r'''Not recorded''',
  'courseInfo.fork.fromCourseId': r'''Forked From Course ID: {value}''',
  'courseInfo.fork.sourceCourse': r'''Source Course: {value}''',
  'courseInfo.fork.sourceCourseVersion': r'''Source Course version: {value}''',
  'courseInfo.fork.sourcePublisher': r'''Source publisher: {value}''',
  'courseInfo.fork.sourcePublisherId': r'''Source publisher ID: {value}''',
  'courseInfo.fork.sourceAuthors': r'''Source Authors / Contributors:
{value}''',
  'courseInfo.fork.sourceOfficialChecksum':
      r'''Source official checksum: {value}''',
  'courseInfo.fork.createdBy': r'''Fork Created By: {value}''',
  'courseInfo.fork.createdDate': r'''Fork Created Date: {value}''',
  'courseInfo.fork.disclaimer':
      r'''Fork provenance is immutable. Rights Holder and attribution metadata remain separate from QQL permissions.''',
  'courseInfo.fork.creatorUser': r'''Fork creator user''',
  'locale.label': r'''Locale''',
  'locale.english': r'''English''',
  'locale.italian': r'''Italiano''',
  'locale.spanish': r'''Español''',
};

import '../widgets/help_language_toggle.dart';

/// One titled block of the Course Editor Help page.
typedef EditorHelpSection = ({String title, String body});

/// The Course Editor Help text in the requested language.
///
/// The two lists are kept side by side so a change to one is an obvious prompt
/// to change the other, and a test asserts they stay the same length.
///
/// Names that appear on screen — Course Manager, Save as draft, Confirm course
/// changes — stay in English inside the Italian text, because the interface
/// itself is English and the reader has to find them there. The technical
/// reference sections keep their technical vocabulary; the rest is written the
/// way an author would actually be told how to work.
List<EditorHelpSection> editorHelpSections(HelpLanguage language) =>
    language == HelpLanguage.italian ? _italian : _english;

/// Heading and blurb of the Technical reference card.
({String title, String body, String note}) editorHelpTechnicalIntro(
  HelpLanguage language,
) => language == HelpLanguage.italian
    ? (
        title: 'Riferimento tecnico',
        body:
            'Work in progress. Queste pagine descrivono l’implementazione attuale dei Course Model v11, separatamente dalle istruzioni pratiche dell’Editor.',
        note: 'Le pagine collegate qui sotto sono disponibili solo in inglese.',
      )
    : (
        title: 'Technical reference',
        body:
            'Work in progress. These pages describe the current Course Model v11 implementation separately from the practical Editor instructions.',
        note: '',
      );

const _english = <EditorHelpSection>[
  (
    title: 'Courses in learner mode',
    body:
        'Available on this device, at the bottom of Course Selector, lists Bundled Courses, Publisher Courses, My Custom Courses and Other Custom Courses. Add to my courses adds a shared course to your Selector and Manager without granting editing rights. Remove from my courses removes it from both for your profile only; progress is kept unless you explicitly choose Reset my progress. Even with reset selected, all XP (including Weekly XP), total and per-language study days and streak remain; XP earned from this course is not subtracted. Only an admin can Remove Publisher Course from device, and only if no other profile includes it. Progress and version backups survive uninstall. With no playable courses, Home keeps Settings and Course Manager when activated; no course flag is displayed. The device page has its own Help, alphabetic sections, Maintainer labels and an Added · Remove action. Import Course in the Selector returns directly to study; it does not activate Course Manager. Continue to Editor prepares a new course; it is saved only with Confirm course changes. Change course lists Published courses in your personal library: the bundled official courses included with QuisquisLingo and Published courses under Local courses. Courses that are Not published stay available for authoring but cannot become the active learner Course. Selecting a Published course makes it current. The learner page resumes the active Published Lesson for that learner and course. When a course has real Sections, the fixed Section selector opens its ordered consecutive Published Section blocks and jumps to each block\'s first Lesson.',
  ),
  (
    title: 'Course origin',
    body:
        'Bundled official courses are verified immutable source copies supplied with QuisquisLingo. Publisher Course imports require a valid Ed25519 signature from an approved publisher. Stored external courses that cannot be verified are preserved with Verification required and are excluded from learner delivery. Custom courses are created locally or imported without official provenance. Both official origins open Official course - read only: inspect Course Info, Audit, Preview, Version History and Lessons/Rounds/Exercises without an authoring transaction. Course Info shows publisher, official version, verification status and checksum. Only an explicit derivativeWorksPolicy of allowed enables Fork; forbidden or unspecified permission explains why it is unavailable. A Fork has fresh IDs and independent custom history while preserving its source lineage. Copy as New Course is a separate action that begins a new independent lineage.',
  ),
  (
    title: 'Temporary sample content',
    body:
        'Course Editor starts in View only for a course with no saved access choice. Choose Edit only for the course you intend to change. A course may be marked TEMPORARY SAMPLE while it contains development or demonstration material. View Course Info retains that description; the main Course Editor does not repeat it. Replace sample material with reviewed educational content before distribution.',
  ),
  (
    title: 'Course Editor lock and structure',
    body:
        'The single access control is on the Course Editor root. Locked uses a closed lock, keeps that root visible and blocks entry into Lessons. View only uses an eye, is the default and opens the ordinary Exercise form read-only while allowing Search, Help, Show/Hide IDs, Preview and Audit. Inspection mode uses the code icon and opens Exercises in their read-only technical presentation by default; their local Inspection toggle can show the ordinary form, which remains read-only. Edit uses the pencil and enables authoring only when the current user already has effective Course Maintainer or assigned-Team permission; the control never grants authorization. Official courses and outsiders offer Locked, View only and Inspection mode, with the Edit authorization reason shown in the Editor. The first View-only entry notice is dismissed per user and Course; Show one-time notices again resets it without changing the access state. For custom courses, Lessons is the first content section. Each Lesson page puts Rounds first, followed by Round / Exercises. A duplicate Lesson, Round or Exercise is inserted after its source with fresh IDs throughout its owned subtree and starts as Draft. Exercise type cannot be changed after creation. Each Lesson retains its GuideBook and stable Lesson-scoped Duel identity.',
  ),
  (
    title: 'Course Editor Search',
    body:
        'The Search icon appears on Lessons, Lesson, Rounds and Round while the Course Editor is unlocked. Lessons searches the whole Course; Lesson and Rounds search their current Lesson; Round searches only that Round. Search accepts complete words, contiguous multi-word phrases and exact or partial Exercise IDs. Text matching ignores case and diacritics. An optional Exercise Type filter defaults to All exercise types. Results show Lesson, Round, friendly Exercise type, a matching excerpt and, while Internal IDs are shown, the Exercise ID. View only opens a result in the ordinary read-only Exercise form, Inspection mode opens its read-only technical presentation, and Edit opens the ordinary editable form. Locked exposes no Search. Search reads the shared exercise-type field inventory and never modifies a Course.',
  ),
  (
    title: 'Optional Lesson learning paths',
    body:
        'Use GuideBook and Create Duels are on the Lessons page and both default ON. Use GuideBook OFF preserves all GuideBook content, Draft state and source references. The learner still sees the Lesson identity and book artwork, but no GuideBook tooltip, click or action semantics; the Round introduction also omits its GuideBook action, including in Preview. Only LESSON_GUIDEBOOK_EMPTY is suppressed; malformed existing content still receives canonical findings. Reenabling updates the current canonical Audit and ancestor borders. Create Duels ON uses the shared pool of 25 actual eligible, deduplicated Exercises. Disabled or insufficient Duels have no learner card or reserved Duel spacing. DUEL_UNAVAILABLE is Info only while Create Duels is ON. Neither switch erases content, existing Duel victories, completion or XP.',
  ),
  (
    title: 'Section assignments and names',
    body:
        'The Lesson Section selector offers No section, existing names, Add new section... and Manage sections.... New names are trimmed and must not be blank. The reusable course catalog also discovers existing Lesson assignments. Removing an assigned name is blocked with its Lesson usage count; change those assignments first. A name selected in the unsaved Lesson is protected too. New Lessons default to the immediately preceding Lesson\'s Section, or No section if none applies. Selecting No section explicitly clears this Lesson assignment. Consecutive assignments still determine visual Section blocks; Sections own no IDs, progress or unlocks.',
  ),
  (
    title: 'Course flag sources',
    body:
        'Create new course and Course Info Editor use the same searchable visual flag chooser. It identifies the current source as a QQL FlagPainter Flag, WORLD Flag or Custom Flag, then offers Upload custom flag, the permanent QQL FlagPainter Flags catalog and the complete WORLD Flags catalog. Search includes names, aliases, stable IDs, language codes and territorial codes. QQL FlagPainter Flags are programmatic graphical reinterpretations associated with languages and never depend on installed Courses. Opening, searching or cancelling changes nothing; only choosing a result, Use Automatic or Upload custom flag changes the current working selection. Use Automatic prefers the associated QQL FlagPainter Flag, then the primary associated WORLD Flag, and otherwise leaves no automatic flag. WORLD Flags store only their stable worldFlagId, QQL FlagPainter Flags store flagCode and custom flags store validated normalized PNG bytes in flagImageBase64.',
  ),
  (
    title: 'One Course Editor transaction',
    body:
        'Opening a custom course maintains a working copy beside an immutable snapshot of the persisted course. View only and Inspection mode never change that working copy. In Edit, every Course Info Editor, Lesson, Round, Exercise, GuideBook, generator and reorder operation changes only the working copy. Course delivery status is Published or Not published; publishing the Course preserves independent descendant Draft states. Nested Save stores a normal item in the working copy; Save as draft stores a Draft item there. Neither action changes the learner-visible course, creates a backup or increments the course version. Leaving an Exercise with unsaved form changes offers Keep editing, Discard changes, Save as draft or Save. Discard affects only that form; earlier working-copy changes remain. Switching away from Edit with unapplied course changes uses the same authoritative confirm/cancel protection rather than silently discarding them. Other nested pages retain their established Back behavior. Navigation among nested pages never shows the final course confirmation.',
  ),
  (
    title: 'Provisional and explicit parent Drafts',
    body:
        'Automatically created Lesson and Round Drafts can be provisional. Their blue Draft badges include the container itself, even when every child has a green Audit border. Saving reviewed Exercises as normal content makes a provisional Round eligible to become Published when its complete required content is ready and normal Save validation passes. A provisional Lesson also needs ready Published Rounds and, while Use GuideBook is ON, a Published nonempty GuideBook with its required content ready. Nonblocking Audit guidance remains visible. This reconciliation follows normal working-copy changes, including GuideBook changes, the Use GuideBook switch, deletion and Move; it never publishes an Exercise or GuideBook for you. Explicit Save as draft clears provisional eligibility, even if the container was already Draft. An explicitly Draft Lesson or Round and older Drafts without this eligibility stay Draft until their own normal Save. Imported authoring trees, copies and licensed forks also remain review Drafts. Course delivery stays an explicit Published or Not published choice, and no working-copy change reaches learners until Confirm course changes succeeds.',
  ),
  (
    title: 'Confirm or cancel the complete course',
    body:
        'Leaving the top-level Course Editor compares the complete working copy with the original course. If they are semantically identical, the Editor closes directly. Otherwise exactly one dialog offers Confirm course changes or Cancel course changes and an optional multiline version note. Confirm first creates and verifies a complete backup, then increments the separate internal course version by exactly one and atomically applies the whole working copy. Cancel discards the entire working copy without a backup or version increment. A failed backup or persistence keeps the working copy open and leaves the persisted course unchanged.',
  ),
  (
    title: 'Local course edits and backups',
    body:
        'Every confirmed change to an existing custom course first archives the complete currently persisted course under Documents/QuisquisLingo/Exports/Course Backups v11/<courseId>. Backup manifests include the full v11 Course, Course Maintainer, optional Assigned Team, provenance, versions, authors, UTC modification timestamp, optional notes, checksum and referenced managed audio assets. Backups are never pruned automatically. Version History lists the current version and verified backups newest first, with Open backup folder and Export JSON. Only custom history supports Restore into working copy. Official history contains publisher sources only; older backup directories are not loaded or deleted. A restore is still only a working-copy change until the top-level confirmation succeeds.',
  ),
  (
    title: 'Android device backup (technical)',
    body:
        'QuisquisLingo has no account and no server, so on Android the platform\'s own Auto Backup is deliberately left enabled: it is the only way a learner keeps their work through a lost or replaced phone. Backed up on purpose: learner profiles, progress, XP, streaks, Review history, local Course edits, authoring Teams, settings, the Access PIN verifier and the User Recovery Key credential. The Access PIN is included knowingly. It is a casual-access guard for a shared family device, not a security boundary, and excluding it would only mean a restored learner silently loses their PIN. Excluded from cloud backup: imported Image Banks, imported exercise images and recorded MP3s. The reason is capacity, not privacy. Android allows one app 25 MB of Auto Backup, a single Image Bank import may reach 50 MB, and an app that exceeds the quota has its backup silently switched off entirely rather than partially. That media can be imported again from your own files; progress cannot. A direct phone-to-phone transfer carries no such quota and still moves the media. For authors this matters in one practical way: a Course you have written is backed up, but the images and audio you imported into it are not, so keep the original media files and your exported Course JSON. Whether Auto Backup runs at all is an Android setting owned by the device owner; QQL never uploads anything itself. Two resource files define this and must always be changed together, because android:dataExtractionRules is ignored below API 31: res/xml/data_extraction_rules.xml for API 31 and above, and res/xml/backup_rules.xml for API 30 and below. A Device Administration reset removes local data but cannot reach a backup Android has already taken.',
  ),
  (
    title: 'Official course updates',
    body:
        'A newer verified official course update is accepted only for the same courseId and publisher and only when its checksum is valid. Before replacement, QuisquisLingo archives the previous official source. The new source becomes current. Existing custom forks and their histories stay unchanged, with no merge or rebase. Old Build 225 official overrides are not used, converted or deleted. If the publisher signature cannot be verified, import is blocked. An existing unverified course is preserved and requires explicit association with a newer signed release before reactivation.',
  ),
  (
    title: 'Course Info Editor and license',
    body:
        'Course Info Editor stores structured Authors / Contributors, Rights Holder, the content License and an optional Buy a Coffee HTTPS link separately from the MPL-2.0 license of the QuisquisLingo software. Attribution and rights information are descriptive and never grant QQL permissions. Rights Holder may name one or more people or organizations without requiring local user identities. Choose All rights reserved, CC0 1.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, CC BY-NC-SA 4.0, or Other / Custom license; a custom license also records its outsider derivative policy. Official content and provenance remain read-only.',
  ),
  (
    title: 'Course responsibility, permissions and Teams',
    body:
        'Original Course Creator, Course Maintainer, Assigned Team, Authors / Contributors, Rights Holder, License and fork/merge provenance are separate. Every v11 custom Course has an immutable Original Course Creator and one individual Course Maintainer. Only the current Course Maintainer can transfer maintainership or assign and revoke a Team for management. The Course Maintainer and every current member of the Assigned Team may manage Course content under QQL permissions; Team leadership controls Team membership and roles only. Teams are an experimental QQL collaboration model and may manage Courses maintained or created by different individuals. QQL permissions govern behavior inside QQL and do not by themselves determine copyright ownership, contractual rights or external organizational authority. Attribution, provenance and Rights Holder metadata never grant permissions. Outsiders cannot mutate or Copy as New Course under the current access policy and can Fork only when derivatives are allowed. Bundled Courses use this same Editor surface in read-only mode.',
  ),
  (
    title: 'Import a custom course',
    body:
        '1. Copy a supported Course ZIP to Documents/QuisquisLingo/Imports/import.zip, or a media-free Course Model v11 JSON to import.json; keep only one. 2. In Course Manager, open Course Import and select Import Course package or JSON. 3. QQL checks the whole package and Course Audit before installing the Course and its own media. Audit errors block import; warnings are reported. Images copied from an Admin Shared Image Library stay with the imported Course and are not added to the recipient device’s Shared Image Library. An external-official Course requires a valid approved-publisher signature; an ordinary custom import stays custom. The source file remains in Imports. A JSON import must be valid UTF-8 and at most 10 MB; a Course ZIP may be at most 300 MB compressed and expanded. Earlier Course formats are refused without migration or deletion.',
  ),
  (
    title: 'Export a custom course',
    body:
        'Export Course ZIP saves the complete Course Model v11 authoring JSON and all referenced Course-owned images and recordings in one ZIP under Documents/QuisquisLingo/Exports. App-bundled media stay supplied by QQL. Admin-added Shared Image Library images used by the Course travel as Course media with their library ID, label, category, tags, origin and available per-image attribution. An Admin can enter author, license, title and source in the library’s Edit metadata dialog; importing the ZIP does not add images to the destination Shared Image Library. Original Creator, Maintainer, optional Team, authors, rights, License, fork/merge provenance, Draft/Published state and version metadata remain in the JSON. Fork preserves its source lineage; Copy as New Course starts an independent lineage. Save to… can write the same ZIP through the system dialog where available.',
  ),
  (
    title: 'Import a custom flag',
    body:
        'Copy a valid PNG or JPEG to Documents/QuisquisLingo/Exports as flag.png, flag.jpg or flag.jpeg, open the shared Course flag chooser and press Upload custom flag. If several names exist, QQL uses the first in that order. Maximum input: 2 MB (2,097,152 bytes). Minimum dimensions: 64 × 40 pixels; maximum: 4096 pixels on either side. QQL checks the actual PNG/JPEG signature and decodes the image. Images larger than 256 pixels on their longest side are reduced proportionally; smaller accepted images are not enlarged. The first image frame becomes PNG without cropping or a square canvas. Existing PNG transparency is retained; JPEG does not acquire a transparent background. PNG data are embedded in the Course and survive course JSON export/import and duplication. The transfer source is left in place and is no longer needed. Missing, unreadable, unsupported, oversized, too-small or over-resolution input produces an error; failed PNG conversion also stops import.',
  ),
  (
    title: 'Generate Rounds from Lesson GuideBook',
    body:
        'Open a Lesson and choose Generate Rounds from GuideBook. The generator uses only vocabulary pairs and examples in that Lesson GuideBook; at least three usable target/source pairs are required. Choose 1–12 Rounds and 1–15 Exercises per Round (defaults: 6 and 8). Review the count, total, normalized progressive-difficulty curve and planned registry presets before generation. Early drafts emphasize guided recognition with fewer distractors, middle drafts add construction and context, and later drafts add freer production. Generated Rounds remain drafts: edit, preview, delete or regenerate them, then explicitly approve them to append fresh-ID copies after existing Rounds. Generation cannot guarantee pedagogical correctness, so every Round and Exercise requires human review.',
  ),
  (
    title: 'Exercise Creation Wizard',
    body:
        'In a Round, Creation Wizard sits beside New exercise. Choose 1–30 Exercises and select Balanced mix, Random mix, one or more categories, exact exercise types, or an ordered repeating pattern. The reviewed plan creates no Exercise objects. After confirmation, each planned step opens the ordinary preset-specific Exercise editor. Save validates and stays on the step; Preview returns to the same draft without copying or advancing; Next validates and advances one step; Finish returns the created Exercises in plan order. If you cancel after explicitly saving work, confirm whether to keep only those valid saved Exercises. Future and invalid placeholders are never inserted.',
  ),
  (
    title: 'Duplicate, Copy and Move exercises',
    body:
        'Duplicate inserts an independent fresh-ID copy immediately after the source. Move Exercise to… and Copy Exercise to… choose an explicit Course > Lesson > Round destination within the current course working copy. Move Round to… and Copy Round to… choose a Lesson there. Move preserves stable identity, content and Draft/Published state and removes the source from its previous parent. Copy allocates fresh IDs throughout the owned subtree and remaps internal references. Following the existing duplication policy, copies and their owned descendants start as Draft. Image and recording references (course media named by content) are copied unchanged, and the files stay in the Course’s media folder. These actions affect only the working copy until Confirm course changes.',
  ),
  (
    title: 'Exercise Preview and navigation',
    body:
        'Preview beside Inspection and Save uses the complete current unsaved Exercise form, including a new or Draft Exercise. It uses learner rendering without saving content, changing Draft/Published state, creating versions/backups or writing learner progress, XP, Weekly XP, streak, Laurel, Review or Duel state. Inspection is a local presentation toggle only: it shows or hides the technical representation without changing Course Editor access, saving, discarding or creating dirty state. Turning it off returns to the normal form; that form is editable only while the root state remains Edit and the user has actual permission. Existing unsaved Edit values remain intact through the presentation round trip. Insufficient runtime data produces a validation message without losing edits. Returning restores the same field values. Previous and Next follow the current Round order and stop at its boundaries. Back, sibling navigation and safe breadcrumb navigation protect unsaved Exercise changes with Keep editing, Discard changes, Save as draft or Save. Saving here affects only the course working copy. Breadcrumbs show readable Course, Lesson, Round and Exercise context.',
  ),
  (
    title: 'Field Help and untitled Rounds',
    body:
        'Use the Help control beside an Exercise field for its purpose, entry count, line rules, format, validation and examples. Context mode, each correct-translation entry and Exercise image have their own Help. Broad Exercise Help remains available beside the preset. Typed answers support the existing answer-expression syntax; Arrange answers and listening gap lists are literal. An empty Round title is intentionally supported in Create and Edit Round. Follow the untitled guidance to keep it blank; its displayed Round N label follows its position without creating a stored title.',
  ),
  (
    title: 'Audio Library',
    body:
        'Choose On-Device TTS, Recorded MP3 or Hybrid. On-Device TTS uses this device voice without recordings; Check unused MP3 files, Import MP3 and Open MP3 from... appear only in Recorded MP3 or Hybrid. There are two ways to add recordings, and both apply the same checks and store the file in the same place: copy MP3 files to Documents/QuisquisLingo/Imports/Audio and press Import MP3 in Audio Library, or use Open from… to pick one or more MP3s (up to 100 files and 250 MB at a time) in the system file dialog; a summary then lists each file\'s result. Cancelling a dialog changes nothing, and a dialog that cannot open explains the fixed-folder route instead. Every .mp3 file there is copied into the Course’s own media folder, derived from the stable Course ID, and named by its content (media:<fingerprint>.mp3), so identical recordings are stored once, with a maximum of 50 MB (52,428,800 bytes) per file. The metadata and references belong to the Course. No MP3 files or an oversized file produces an error. Every file must be a real MP3: MPEG audio Layer III frames from start to end, optionally with ID3 or APE tags up to 2 MB in total. A file that is something else renamed to .mp3, is damaged or cut short, or carries embedded cover artwork is refused (remove the cover image and try again). From the folder, one refused file means nothing is imported. A recording the Course already has is skipped. The same check applies to the recordings inside a Course ZIP when it is imported. Import does not re-encode recordings or enforce a duration, bitrate or sample-rate rule; preview each recording to check playback. Source files remain in place, so move them out after successful import to avoid importing them again. Associate each recording with the exact word or expression it contains. Recorded playback uses longest-match segmentation and concatenates compatible clips. Hybrid falls back to TTS when a complete recorded sequence cannot be assembled. Course JSON stores clip metadata and these content references, not MP3 bytes; JSON alone does not transfer the recordings to another device. Verified course-version backups copy referenced recordings. Export my data is a separate learner backup and does not include course media; a distributable Audio Pack exporter is not currently available.',
  ),
  (
    title: 'Image Bank',
    body:
        'Images and Image Bank ZIPs can be added two ways, and both apply the same checks and store the file in the same place: through Documents/QuisquisLingo/Imports/Images, or with Open image files from… (up to 100 images at once) and Open Image Bank ZIP from… in the system file dialog. Every image is checked by its content, not its name: it must really be a still PNG, JPEG or WebP of at most 4096 × 4096 pixels, undamaged and without oversized embedded metadata, and QQL stores it under a name it chooses. In the Course Editor’s Image Library, anyone editing the Course can also add images, several at once, or a whole Image Bank to that Course’s own library with Add images to this Course: they stay unused until an exercise uses them, travel in the Course ZIP, and never enter the Shared Image Library. For the fixed folder, keep exactly one supported image for a single-image import, or exactly one ZIP for Import Image Bank ZIP. Cancelling a dialog changes nothing, and a dialog that cannot open explains the fixed-folder route instead. A manifest is a small UTF-8 JSON text file that tells QQL which pictures are in the bank and how to label them. Write it in a plain-text editor, save it as image_bank_manifest.json (not .txt), and add it to the ZIP with every image it names. For a minimal example, write [{"id":"apple","primary_term":"apple","keywords":["apple"],"filename":"apple.png"}] and put apple.png in the ZIP too. A bank needs image_bank_manifest.json containing a JSON list, or an object whose images field is that list and whose optional attribution field credits every image that has no credit of its own. Every entry needs a unique id (1–128 letters, digits, dots, hyphens or underscores), primary_term or label (up to 200 characters), and a safe filename referring to a PNG, JPG/JPEG or WebP in the archive; at most 32 keywords of up to 80 characters each. The ZIP may hold only the manifest and the images it lists: a credits or readme file stops the import, because credits belong in the attribution field. Links, encrypted entries, archives inside the archive and unsafe paths are refused. When a bank brings categories this device does not have yet (at most 16), an Admin chooses Add them, Put these images under Other, or Cancel; nothing is stored before that choice. A picture that is already in Shared Images, byte for byte, is skipped without asking, whatever its name. When a bank image has the same id as a different picture already there, the Admin chooses Skip, Replace (never for QQL’s own images) or Keep both (the new one gets a new id), and can apply the answer to all the rest. Limits: 50 MB ZIP, 2 MB manifest, 5000 archive entries, 2500 image entries, 50 KB per image and 50 MB total decompressed image bytes. Missing assets, duplicate/colliding IDs, duplicate filenames, unsafe paths, unsupported extensions and exceeded limits stop import. Image bytes are copied unchanged to local app storage with a local manifest; they are not resized or made transparent. Source ZIPs remain in place. Preview images before selection. Choosing a library or bank image for an Exercise copies it into the Course’s own media, so later library changes do not affect the Course; Course JSON names it by content and does not embed the image bytes.',
  ),
  (
    title: 'Lesson theme icons and Preview',
    body:
        'Each Lesson can select a Preinstalled icon, a Custom Course icon, or Numbers. The Preinstalled icons show only the current choice until you tap them. For Import custom icon, keep exactly one PNG, JPG/JPEG or WebP in Documents/QuisquisLingo/Imports/Lesson Icons. Maximum input: 2 MB (2,097,152 bytes); each dimension must be 1–4096 pixels. QQL decodes the first frame and scales it up or down proportionally, centered on a transparent 256 × 256 PNG canvas without cropping or distortion. Existing transparency is preserved; an opaque source background is not removed. Missing/multiple files, empty or unsupported images, exceeded size/dimensions and failed PNG conversion stop import. The source remains in place. The managed Course-owned asset stores embedded PNG data; its reference survives course JSON export/import and Course duplication, with no external source path required. Lesson duplication within the Course reuses the immutable asset. When a Lesson has no explicit icon, QQL uses the single theme-colored Lesson-number circle in Editor and learner views. Legacy fallback-style values still load but no longer alter this rendering. Explicitly selected icons remain unchanged. Every option uses the established 84 × 84 learner footprint. Preview writes no learner progress.',
  ),
  (
    title: 'Exercise image specifications',
    body:
        'For Import custom image, keep exactly one PNG, JPG/JPEG or WebP in Documents/QuisquisLingo/Imports/Images. Maximum: 50 KB (51,200 bytes). A 256 × 256 resolution and 15 KB or less are recommendations; this importer imposes no pixel-dimension rule and performs no resizing, cropping or transparency conversion. It checks the filename extension, file count and byte size, then copies the bytes unchanged to local app storage. The source stays in place. Missing/multiple sources or an oversized image stops import; Preview reports missing or unreadable images. The Exercise then uses a copy in the Course’s own media, named by content; Course JSON stores that reference, not the file bytes, so importing the JSON alone elsewhere does not transfer custom exercise images. Built-in asset paths refer to images supplied with QQL. An Exercise image is optional except for Image-prompt ordering.',
  ),
  (
    title: 'New exercise types',
    body:
        'Missing Word plays audio while showing its transcript with one or more words removed. Image Word shows an image and asks the learner to build the corresponding target-language word from letter or syllable blocks. Dialogue Response contains a target-language context sentence, a target-language question and exactly two target-language response options; their display order is randomized. Word Match uses exactly three source-to-target translation pairs. Super Match uses exactly three target-language pairs and an explicit relationship such as synonyms or opposites. Audio Match uses three target-language audio items with exactly three matching texts and no distractors; the matching text may be in the target language or a translation. Listening Spelling / Type what you hear plays target-language audio and requires keyboard input; its prompt is displayed as entered and Return/Enter submits. Sentence Word Order exercises may use 0, 1 or at most 2 distractors. Image Word letter/syllable composition never uses distractors: include only the blocks required for the answer. Gap Choice shows a target-language sentence with one missing element and asks the learner to choose the single block that is correct in both meaning and grammar.',
  ),
  (
    title: 'Language Duel',
    body:
        'Each Lesson owns its Duel. The Duel attached to the final Lesson is presented as Final Duel, with the tooltip Final challenge for the last Lesson. It retains the same mechanics and never claims to unlock another Lesson. A standard Duel selects 25 unique eligible exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or pass threshold: completing all 25 questions before all four lives are lost wins. Availability is determined from the actual eligible exercise pool, not from the number of Rounds or the total theoretical exercise count. If fewer than 25 eligible exercises exist, the Duel is simply unavailable for that Lesson; this is normal supported behavior, not a course error.',
  ),
  (
    title: 'Course creation rules',
    body:
        'A Lesson should normally contain at least 6 Rounds, which in typical content may mean roughly 48 exercises. This is author guidance only: it is not a validity requirement and never determines Duel availability. The standard Round contains 15 exercises. Avoid accidental duplicate content inside one Round. Isolated words should normally be lowercase unless the language requires capitalization, as with German nouns or proper names. Opposite exercises belong in later Rounds, after the learner has already met the vocabulary. Sentence Word Order may use 0, 1 or at most 2 distractors; use fewer distractors early in a Lesson and more later. Distractors should be plausible but unambiguously wrong. Learner-facing operational instructions must use the course source language. Early Rounds should introduce and consolidate material; later Rounds can demand harder discrimination and combinations.',
  ),
  (
    title: 'Listening Spelling',
    body:
        'Type what you hear uses Audio text for playback and the Missing word field for accepted typed answers, one complete word or passage per line. Passage transcript is displayed as entered; this preset does not automatically remove the accepted word from it. Preview the visible prompt so it does not reveal the answer. For automatically hidden words in a complete transcript, the existing Listen for missing words preset supplies that workflow.',
  ),
  (
    title: 'Lesson Guidebook',
    body:
        'Each Lesson has its own Guidebook, available to learners when published and Use GuideBook is ON. Its primary authoring fields are Overview, Usage examples, Vocabulary and Grammar, in that order. Insights opens a second authoring page for ordered Title and Text sections; changes remain in the current GuideBook working copy until Save Guidebook or Save Guidebook as draft, and removing a section requires confirmation. Save Guidebook as draft keeps it out of learner delivery and shows one blue Draft badge on the Guidebook and its visible ancestors. The badge is independent from Audit: an empty Guidebook has a red border while Use GuideBook is ON; any other canonical Guidebook Error or Warning stays red regardless of that preference. A clean Draft Guidebook remains green with its blue badge. The editor can use its vocabulary and examples to propose new exercises.',
  ),
  (
    title: 'Course metadata and authors',
    body:
        'Course Info is available in Locked, View only and Inspection mode. Course Info Editor is available only in Edit for users with existing edit permission. It can change the visible Course name without changing the Course ID. Base and Learning language remain read-only and show their authoritative general or regional codes. Original Course Created is immutable lineage provenance; Last Version Editor and Modified describe the current Course version and instance. Opening the editor changes none of them. Automatic Course flag removes every explicit override and uses the language fallback; choosing a built-in, World Flag, uploaded flag or authorized reusable installed-course flag stores only its portable value. Structured Authors / Contributors and Rights Holder metadata are descriptive and never authorize access. Original Course Creator and Course Maintainer use separate stable internal identities. Course Info separately resolves the Assigned Team, Team Leaders and Team Members from Team Manager. Internal IDs additionally reveals their stable IDs and the read-only Course Model version. Fork provenance separately identifies who created a particular fork, when, and its immediate source Course. Official Courses retain publisher identity, official version, release notes, channel, checksum and verification. Lesson numbering is set on the Lessons page in Edit. Its selected term is shared by Editor labels, breadcrumbs and learner presentation; stored Lesson titles and IDs remain unchanged. Lessons without an explicit icon use the single theme-colored number circle. These presentation choices never change lessonId, progression or unlocks.',
  ),
  (
    title: 'Audit severity and codes',
    body:
        'Course Audit reports Errors, Warnings and Info. Error blocks publication or import because content is structurally or functionally invalid. Warning marks a likely authoring problem that needs review. Info is guidance or a neutral fact and never blocks publication by itself. Audit can sort by Lesson, friendly Exercise type or Recently modified and can be opened for a whole Course, one Lesson or one Round. Recent order uses updatedAt descending with deterministic ties; findings are numbered progressively inside each severity group after filtering. A red border marks an Audit Error or Warning and propagates through its represented branch. A luminous green border means the current branch has no Error or Warning; Info guidance may remain. One blue Draft indicator independently includes a Lesson or Round\'s own Draft state and follows Draft Guidebooks and Content through their visible ancestors. A green Audit border does not mean the item is Published. An explicitly Draft Lesson or Round keeps Published children hidden until that container is saved. A Guidebook concern affects its Lesson and Lessons hierarchy, but not the separate Rounds branch. Fewer than 3 Rounds is Info; fewer than 25 eligible Duel Exercises is Info only when Create Duels is ON. Missing Reading- or Listening-comprehension coverage produces no finding; malformed existing comprehension content still receives validation. Drafts are included for author review without making unrelated Published learner content invalid. Technical reference > Audit Codes displays the shared 102-rule registry in Errors, Warnings, Info order. All three independently selectable categories start enabled, and text search applies within the selected categories.',
  ),
  (
    title: 'Course Audit',
    body:
        'Course Audit checks structural and authoring problems such as invalid exercise fields, duplicate IDs, Word Block problems, missing audio mappings and Missing Word errors. An empty Reading passage is an Error; one or two Unicode/apostrophe-aware lexical words produce READING_PASSAGE_TOO_SHORT, while three or more do not. HINT_REPEATS_PROMPT is a Warning and revealing any canonical correct answer remains an Error. It does not certify grammar, translation accuracy or pedagogical quality.',
  ),

  (
    title: 'Create a new course',
    body:
        'Course Manager creates an independent Course Model v11 project and opens it in Course Editor. New Course restores the same License / Rights, Authors / Contributors, language variant, levels, description and support metadata used by Course Info Editor. The active profile becomes the immutable Original Course Creator and defaults as Course Maintainer; another local individual may instead be selected as Maintainer. Assigned Team remains separate and is not selected during creation. Number of Lessons defaults to 3 (whole numbers 1–100), and Rounds per Lesson defaults to 1 (whole numbers 1–20). Invalid or missing values show inline errors and disable Create. The complete initial hierarchy is created atomically with fresh stable IDs and untitled Rounds, each with exactly one Draft Pick the translation (to target) sample Exercise. Review and explicitly save teaching content before publication. The new Not published Course remains only a working copy until Confirm course changes creates version 1; cancelling creates no stored Course. Imported v11 authoring content must state its provenance, Maintainer, Draft/Published state and required UTC timestamps explicitly; earlier Course Models are neither inferred nor migrated.',
  ),
];

const _italian = <EditorHelpSection>[
  (
    title: 'I corsi in modalità studente',
    body:
        'Available on this device, in fondo al Course Selector, elenca Bundled Courses, Publisher Courses, My Custom Courses e Other Custom Courses. Add to my courses aggiunge il corso condiviso al tuo Selector e Manager senza concedere permessi di modifica. Remove from my courses lo rimuove da entrambi solo per il tuo profilo; i progressi restano salvo scelta esplicita di Reset my progress. Anche scegliendo il reset, restano tutti gli XP (compresi quelli settimanali), i giorni di studio totali e per lingua e la streak; gli XP ottenuti con questo corso non vengono sottratti. Solo un admin può usare Remove Publisher Course from device, purché nessun altro profilo includa il corso. Progressi e backup delle versioni restano dopo la disinstallazione. Senza corsi disponibili per lo studio, Home conserva Settings e Course Manager se attivato; non mostra una bandiera di corso. La pagina del dispositivo ha un proprio Help, sezioni alfabetiche, riga Maintainer e azione Added · Remove. Import Course nel Selector torna direttamente allo studio senza attivare Course Manager. Continue to Editor prepara il nuovo corso, salvato solo con Confirm course changes. Change course elenca i corsi Published della tua libreria personale: quelli ufficiali inclusi in QuisquisLingo e i corsi Published che stanno sotto Local courses. I corsi Not published restano disponibili per l’authoring, ma non possono diventare il corso attivo dello studente. Se selezioni un corso Published, quello diventa il corso corrente. La pagina di studio riprende dalla Lesson Published attiva per quello studente e quel corso. Se il corso ha delle Section vere, il Section selector fisso apre i blocchi di Section Published in ordine consecutivo e salta alla prima Lesson di ogni blocco.',
  ),
  (
    title: 'Origine del corso',
    body:
        'I corsi ufficiali inclusi nell’app sono copie sorgente verificate e immutabili, distribuite insieme a QuisquisLingo. Gli import Publisher Course richiedono una firma Ed25519 valida di un editore approvato. I corsi già salvati non verificabili vengono conservati con Verification required ed esclusi dallo studio. I corsi custom nascono in locale oppure vengono importati senza provenienza ufficiale. Entrambe le origini ufficiali si aprono come Official course - read only: puoi consultare Course Info, Audit, Preview, Version History e Lessons/Rounds/Exercises senza aprire nessuna transazione di authoring. Course Info mostra editore, versione ufficiale, stato di verifica e checksum. Solo un derivativeWorksPolicy esplicitamente allowed abilita il Fork; se il permesso è forbidden o non è indicato, la pagina spiega perché non è disponibile. Un Fork ha ID nuovi e una storia custom indipendente, ma conserva la discendenza dalla sorgente. Copy as New Course è invece un’azione separata, che fa partire una discendenza nuova e indipendente.',
  ),
  (
    title: 'Contenuti di esempio temporanei',
    body:
        'Il Course Editor si apre in View only per i corsi che non hanno ancora una scelta di accesso salvata. Passa a Edit solo per il corso che vuoi davvero modificare. Un corso può essere segnato come TEMPORARY SAMPLE finché contiene materiale di sviluppo o dimostrativo. Quella descrizione resta in Course Info; il Course Editor vero e proprio non la ripete. Sostituisci il materiale di esempio con contenuti didattici revisionati prima di distribuire il corso.',
  ),
  (
    title: 'Blocco e struttura del Course Editor',
    body:
        'L’unico controllo di accesso sta alla radice del Course Editor. Locked usa il lucchetto chiuso, lascia visibile quella radice e impedisce di entrare nelle Lessons. View only usa l’occhio, è l’impostazione di partenza e apre il normale modulo dell’esercizio in sola lettura, lasciando comunque disponibili Search, Help, Show/Hide IDs, Preview e Audit. Inspection mode usa l’icona del codice e apre gli esercizi nella loro rappresentazione tecnica, in sola lettura; il singolo interruttore Inspection può riportare al modulo normale, che resta comunque non modificabile. Edit usa la matita e abilita l’authoring solo se hai già i permessi di Course Maintainer o del Team assegnato: il controllo da solo non concede mai un’autorizzazione. Per i corsi ufficiali e per chi non ha i permessi restano Locked, View only e Inspection mode, e l’Editor spiega perché Edit non è disponibile. Il primo ingresso in View only mostra un avviso che si chiude una volta sola, per ogni utente e per ogni corso; Show one-time notices again lo rimette, senza cambiare lo stato di accesso. Nei corsi custom, Lessons è la prima sezione di contenuto. Ogni pagina Lesson mette prima i Rounds, poi Round / Exercises. Una Lesson, un Round o un esercizio duplicato viene inserito subito dopo l’originale, con ID nuovi in tutto il sottoalbero, e parte come Draft. Il tipo di esercizio non si può cambiare dopo la creazione. Ogni Lesson conserva il suo GuideBook e l’identità stabile del Duel che le appartiene.',
  ),
  (
    title: 'La ricerca nel Course Editor',
    body:
        'L’icona Search compare in Lessons, Lesson, Rounds e Round quando il Course Editor non è bloccato. Da Lessons cerchi in tutto il corso; da Lesson e da Rounds cerchi nella Lesson in cui ti trovi; da Round cerchi solo in quel Round. Puoi cercare parole intere, più parole di seguito e ID di esercizio interi o parziali. La ricerca nel testo ignora maiuscole e accenti. Il filtro sul tipo di esercizio è facoltativo e parte da All exercise types. I risultati mostrano Lesson, Round, il nome leggibile del tipo di esercizio, un estratto del punto trovato e, se gli Internal ID sono visibili, l’ID dell’esercizio. In View only il risultato si apre nel normale modulo in sola lettura, in Inspection mode nella rappresentazione tecnica in sola lettura, in Edit nel modulo modificabile. Con Locked la ricerca non c’è. La ricerca legge l’inventario condiviso dei campi per tipo di esercizio e non modifica mai un corso.',
  ),
  (
    title: 'Percorsi facoltativi della Lesson',
    body:
        'Use GuideBook e Create Duels stanno nella pagina Lessons e partono entrambi da ON. Con Use GuideBook su OFF il contenuto del GuideBook, il suo stato Draft e i riferimenti alle fonti restano tutti al loro posto. Lo studente continua a vedere l’identità della Lesson e il disegno del libro, ma senza tooltip, clic o azione sul GuideBook; anche l’introduzione del Round non propone più la sua azione GuideBook, nemmeno in Preview. Viene silenziato solo LESSON_GUIDEBOOK_EMPTY: il contenuto già presente ma malformato continua a produrre le sue segnalazioni. Riattivando l’opzione, l’Audit corrente e i bordi degli elementi superiori si aggiornano. Create Duels su ON usa il consueto insieme di 25 esercizi idonei e non duplicati. Se il Duel è disattivato o non ha abbastanza esercizi, lo studente non vede né la sua card né lo spazio riservato. DUEL_UNAVAILABLE resta solo Info finché Create Duels è ON. Nessuno dei due interruttori cancella contenuti, vittorie nei Duel già ottenute, completamenti o XP.',
  ),
  (
    title: 'Assegnare e denominare le Section',
    body:
        'Il selettore Section della Lesson propone No section, i nomi già esistenti, Add new section... e Manage sections.... I nomi nuovi vengono ripuliti dagli spazi e non possono essere vuoti. Il catalogo riutilizzabile del corso riconosce anche le assegnazioni già presenti nelle Lesson. Non puoi togliere un nome ancora assegnato: QQL ti dice in quante Lesson è usato, e prima devi cambiare quelle assegnazioni. Anche il nome scelto in una Lesson non ancora salvata è protetto allo stesso modo. Le Lesson nuove ereditano la Section della Lesson immediatamente precedente, oppure restano su No section se non c’è niente da ereditare. Scegliere No section cancella esplicitamente l’assegnazione di quella Lesson. I blocchi visivi di Section continuano a dipendere dalle assegnazioni consecutive; le Section non hanno ID, progressi o sblocchi propri.',
  ),
  (
    title: 'Da dove arriva la bandiera del corso',
    body:
        'Create new course e Course Info Editor usano lo stesso selettore visivo di bandiere, con ricerca. Il selettore riconosce la sorgente attuale — QQL FlagPainter Flag, WORLD Flag o Custom Flag — e poi propone Upload custom flag, il catalogo permanente delle QQL FlagPainter Flags e il catalogo completo delle WORLD Flags. La ricerca copre nomi, nomi alternativi, ID stabili, codici di lingua e codici territoriali. Le QQL FlagPainter Flags sono reinterpretazioni grafiche disegnate dal programma, associate alle lingue, e non dipendono mai dai corsi installati. Aprire il selettore, cercare o annullare non cambia niente: cambiano la selezione solo la scelta di un risultato, Use Automatic o Upload custom flag. Use Automatic preferisce la QQL FlagPainter Flag associata, poi la WORLD Flag principale associata, e se non trova nulla lascia il corso senza bandiera automatica. Le WORLD Flags salvano solo il loro worldFlagId stabile, le QQL FlagPainter Flags salvano flagCode, e le bandiere personalizzate salvano in flagImageBase64 i byte PNG già validati e normalizzati.',
  ),
  (
    title: 'Una sola transazione del Course Editor',
    body:
        'Quando apri un corso custom, QQL tiene una copia di lavoro accanto a un’istantanea immutabile del corso salvato. View only e Inspection mode non toccano mai quella copia di lavoro. In Edit, ogni operazione — Course Info Editor, Lesson, Round, esercizio, GuideBook, generatore, riordino — cambia solo la copia di lavoro. Lo stato di consegna del corso è Published o Not published; pubblicare il corso non tocca gli stati Draft dei suoi elementi. Il Save di una pagina interna mette l’elemento normale nella copia di lavoro; Save as draft ci mette un elemento Draft. Nessuna delle due azioni cambia il corso visto dagli studenti, crea un backup o incrementa la versione del corso. Se lasci un esercizio con modifiche non salvate, QQL ti propone Keep editing, Discard changes, Save as draft o Save. Discard riguarda solo quel modulo: le modifiche già fatte nella copia di lavoro restano. Anche uscire da Edit con modifiche non applicate passa dalla stessa protezione conferma/annulla, invece di buttare via tutto in silenzio. Le altre pagine interne mantengono il comportamento consueto del tasto Back. Spostarsi tra le pagine interne non fa mai comparire la conferma finale del corso.',
  ),
  (
    title: 'Draft provvisori e Draft espliciti',
    body:
        'Le Lesson e i Round creati automaticamente possono essere Draft provvisori. Il loro badge blu Draft riguarda anche il contenitore in sé, anche quando tutti gli elementi al suo interno hanno il bordo verde dell’Audit. Se salvi come contenuto normale gli esercizi che hai revisionato, un Round provvisorio diventa candidato a passare a Published, quando il contenuto richiesto è completo e il normale controllo di Save passa. Una Lesson provvisoria ha bisogno anche di Round Published pronti e, se Use GuideBook è ON, di un GuideBook Published non vuoto con il suo contenuto richiesto. Le indicazioni dell’Audit che non bloccano restano comunque visibili. Questa riconciliazione segue le normali modifiche alla copia di lavoro, comprese quelle al GuideBook, l’interruttore Use GuideBook, le eliminazioni e i Move; non pubblica mai un esercizio o un GuideBook al posto tuo. Un Save as draft esplicito toglie la candidatura, anche se il contenitore era già Draft. Una Lesson o un Round messi esplicitamente in Draft, e i vecchi Draft senza questa candidatura, restano Draft finché non fai tu un Save normale. Anche gli alberi di authoring importati, le copie e i fork su licenza restano Draft in attesa di revisione. La consegna del corso resta una scelta esplicita tra Published e Not published, e nessuna modifica della copia di lavoro arriva agli studenti finché Confirm course changes non va a buon fine.',
  ),
  (
    title: 'Confermare o annullare tutto il corso',
    body:
        'Quando esci dal Course Editor di primo livello, QQL confronta l’intera copia di lavoro con il corso di partenza. Se sono identici nella sostanza, l’Editor si chiude e basta. Altrimenti compare una sola finestra, con Confirm course changes o Cancel course changes e una nota di versione facoltativa su più righe. Confirm crea e verifica prima un backup completo, poi aumenta di esattamente uno la versione interna del corso e applica in blocco tutta la copia di lavoro. Cancel butta via l’intera copia di lavoro, senza backup e senza aumentare la versione. Se il backup o il salvataggio non riescono, la copia di lavoro resta aperta e il corso salvato non viene toccato.',
  ),
  (
    title: 'Modifiche locali e backup',
    body:
        'Ogni modifica confermata a un corso custom già esistente archivia prima il corso salvato in quel momento, sotto Documents/QuisquisLingo/Exports/Course Backups v11/<courseId>. Il manifest del backup contiene il corso v11 completo, il Course Maintainer, l’eventuale Assigned Team, la provenienza, le versioni, gli autori, la data di modifica UTC, le note facoltative, il checksum e i riferimenti agli audio gestiti. I backup non vengono mai eliminati automaticamente. Version History elenca la versione attuale e i backup verificati, dal più recente, con Open backup folder ed Export JSON. Solo la storia dei corsi custom permette il Restore into working copy. La storia dei corsi ufficiali contiene soltanto le sorgenti dell’editore; le cartelle di backup più vecchie non vengono né caricate né cancellate. Anche un restore resta una modifica alla sola copia di lavoro, finché la conferma di primo livello non va a buon fine.',
  ),
  (
    title: 'Backup del dispositivo Android (tecnico)',
    body:
        'QuisquisLingo non ha account né server, quindi su Android l’Auto Backup della piattaforma è lasciato attivo di proposito: è l’unico modo in cui uno studente conserva il suo lavoro quando perde o cambia telefono. Vengono salvati di proposito: profili degli studenti, progressi, XP, streak, cronologia di Review, modifiche locali ai corsi, Team di authoring, impostazioni, il verificatore dell’Access PIN e la credenziale della User Recovery Key. L’Access PIN è incluso consapevolmente: è una protezione contro l’accesso distratto su un dispositivo di famiglia, non una barriera di sicurezza, ed escluderlo significherebbe solo che uno studente ripristinato si ritrova senza PIN senza capire perché. Sono esclusi dal backup in cloud gli Image Bank importati, le immagini degli esercizi importate e gli MP3 registrati. Il motivo è lo spazio, non la riservatezza: Android concede a un’app 25 MB di Auto Backup, un singolo Image Bank può arrivare a 50 MB, e un’app che supera la soglia non ottiene un backup parziale — smette semplicemente di essere salvata, senza avvisi. Quei file multimediali puoi reimportarli dai tuoi originali; i progressi no. Il trasferimento diretto da telefono a telefono non ha questa soglia e porta con sé anche i file multimediali. Per chi crea corsi la cosa conta in modo molto concreto: il corso che hai scritto viene salvato, le immagini e gli audio che ci hai importato dentro no. Tieni quindi da parte i file originali e il tuo export del Course JSON. Se l’Auto Backup sia attivo o no è comunque una scelta di chi possiede il dispositivo; QQL non carica niente per conto proprio. Due file di risorse definiscono tutto questo e vanno sempre modificati insieme, perché android:dataExtractionRules viene ignorato prima delle API 31: res/xml/data_extraction_rules.xml per API 31 e successive, e res/xml/backup_rules.xml per API 30 e precedenti. Un reset da Device Administration cancella i dati locali, ma non può raggiungere un backup che Android ha già fatto.',
  ),
  (
    title: 'Aggiornamenti dei corsi ufficiali',
    body:
        'Un aggiornamento ufficiale più recente viene accettato solo per lo stesso courseId e lo stesso editore, e solo se il checksum è valido. Prima di sostituire, QuisquisLingo archivia la sorgente ufficiale precedente. La nuova sorgente diventa quella corrente. I fork custom già esistenti e la loro storia restano come sono: non c’è nessun merge e nessun rebase. Le vecchie sostituzioni ufficiali della Build 225 non vengono usate, convertite o cancellate. Se la firma dell’editore non è verificabile, l’import viene bloccato. Un corso esistente non verificato viene conservato e richiede l’associazione esplicita a una release firmata più recente per essere riattivato.',
  ),
  (
    title: 'Course Info Editor e licenza',
    body:
        'Course Info Editor conserva Authors / Contributors strutturati, Rights Holder, la licenza del contenuto e un link HTTPS facoltativo Buy a Coffee, tenuti separati dalla licenza MPL-2.0 del software QuisquisLingo. Le informazioni su attribuzione e diritti sono descrittive e non concedono mai permessi a QQL. Rights Holder può indicare una o più persone od organizzazioni, senza bisogno che esistano come utenti locali. Puoi scegliere All rights reserved, CC0 1.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, CC BY-NC-SA 4.0 oppure Other / Custom license; una licenza personalizzata registra anche la sua politica sulle opere derivate da parte di esterni. I contenuti e la provenienza dei corsi ufficiali restano in sola lettura.',
  ),
  (
    title: 'Responsabilità del corso, permessi e Team',
    body:
        'Original Course Creator, Course Maintainer, Assigned Team, Authors / Contributors, Rights Holder, License e la provenienza di fork e merge sono cose distinte. Ogni corso custom v11 ha un Original Course Creator immutabile e un solo Course Maintainer individuale. Solo il Course Maintainer attuale può passare la manutenzione a qualcun altro, oppure assegnare e revocare un Team per la gestione. Il Course Maintainer e tutti i membri attuali dell’Assigned Team possono gestire il contenuto del corso secondo i permessi QQL; la leadership del Team riguarda invece solo i membri del Team e i loro ruoli. I Team sono un modello di collaborazione sperimentale di QQL e possono gestire corsi mantenuti o creati da persone diverse. I permessi QQL regolano il comportamento dentro QQL e non stabiliscono da soli la titolarità del diritto d’autore, i diritti contrattuali o l’autorità di un’organizzazione esterna. Attribuzione, provenienza e Rights Holder non concedono mai permessi. Con la politica di accesso attuale, chi è esterno non può modificare il corso né usare Copy as New Course, e può fare un Fork solo dove le opere derivate sono permesse. I corsi inclusi nell’app usano questa stessa interfaccia dell’Editor, in sola lettura.',
  ),
  (
    title: 'Importare un corso personalizzato',
    body:
        '1. Copia uno ZIP di corso supportato in Documents/QuisquisLingo/Imports/import.zip, oppure un JSON Course Model v11 senza media propri in import.json; tienine uno solo. 2. In Course Manager apri Course Import e scegli Import Course package or JSON. 3. QQL controlla l’intero pacchetto e il Course Audit prima di installare il corso e i suoi media. Gli errori dell’Audit bloccano l’importazione; gli avvisi vengono segnalati. Le immagini copiate da una Shared Image Library gestita dall’Admin restano nel corso importato e non vengono aggiunte alla libreria condivisa del dispositivo di arrivo. Un corso external-official richiede la firma valida di un editore approvato; un normale import custom resta custom. Il file sorgente resta in Imports. Il JSON deve essere UTF-8 valido e non superare 10 MB; lo ZIP non può superare 300 MB, né compresso né espanso. I modelli di corso precedenti vengono rifiutati senza migrazione o cancellazione.',
  ),
  (
    title: 'Esportare un corso personalizzato',
    body:
        'Export Course ZIP salva in Documents/QuisquisLingo/Exports un solo ZIP con il JSON completo del Course Model v11 e le immagini e registrazioni proprie effettivamente usate dal corso. I media inclusi nell’app restano forniti da QQL. Le immagini aggiunte dall’Admin alla Shared Image Library viaggiano come media del corso, con ID, etichetta, categoria, tag, origine e attribuzione per immagine disponibile. L’Admin può inserire autore, licenza, titolo e fonte in Edit metadata della libreria; importare lo ZIP non aggiunge le immagini alla libreria condivisa del dispositivo di arrivo. Il JSON conserva Creator, Maintainer, eventuale Team, autori, diritti, License, provenienza di Fork e Merge, stato Draft/Published e metadati di versione. Fork conserva la discendenza dalla sorgente; Copy as New Course ne avvia una indipendente. Dove disponibile, Save to… salva lo stesso ZIP nella cartella scelta con il dialogo di sistema.',
  ),
  (
    title: 'Importare una bandiera personalizzata',
    body:
        'Copia un PNG o un JPEG valido in Documents/QuisquisLingo/Exports con il nome flag.png, flag.jpg o flag.jpeg, apri il selettore di bandiere del corso e premi Upload custom flag. Se esistono più nomi tra questi, QQL usa il primo in quest’ordine. Dimensione massima del file: 2 MB (2.097.152 byte). Dimensioni minime dell’immagine: 64 × 40 pixel; massime: 4096 pixel per lato. QQL controlla la firma PNG/JPEG vera e propria e decodifica l’immagine. Le immagini più larghe di 256 pixel sul lato lungo vengono ridotte in proporzione; quelle più piccole ma accettabili non vengono ingrandite. Il primo fotogramma diventa un PNG, senza ritagli e senza forzare un quadrato. La trasparenza già presente nei PNG viene mantenuta; un JPEG non acquista uno sfondo trasparente. I dati PNG vengono incorporati nel corso e sopravvivono all’export/import del JSON e alla duplicazione. Il file di partenza resta dov’è e non serve più. Se il file manca, è illeggibile, non è supportato, è troppo grande, troppo piccolo o troppo grande come risoluzione, l’importazione dà errore; anche una conversione PNG fallita la interrompe.',
  ),
  (
    title: 'Generare Round dal GuideBook della Lesson',
    body:
        'Apri una Lesson e scegli Generate Rounds from GuideBook. Il generatore usa soltanto le coppie di vocaboli e gli esempi presenti nel GuideBook di quella Lesson, e servono almeno tre coppie lingua studiata/lingua di partenza utilizzabili. Puoi chiedere da 1 a 12 Round e da 1 a 15 esercizi per Round (valori di partenza: 6 e 8). Prima di generare, controlla il numero, il totale, la curva di difficoltà progressiva normalizzata e i preset previsti. Le bozze iniziali puntano sul riconoscimento guidato, con pochi distrattori; quelle intermedie aggiungono costruzione e contesto; le ultime aggiungono produzione più libera. I Round generati restano bozze: puoi modificarli, vederli in Preview, cancellarli o rigenerarli, e solo quando li approvi esplicitamente vengono aggiunti in coda ai Round esistenti, come copie con ID nuovi. La generazione non può garantire la correttezza didattica, quindi ogni Round e ogni esercizio vanno revisionati da una persona.',
  ),
  (
    title: 'Creation Wizard degli esercizi',
    body:
        'Dentro un Round, Creation Wizard sta accanto a New exercise. Scegli da 1 a 30 esercizi e poi Balanced mix, Random mix, una o più categorie, i tipi esatti di esercizio, oppure uno schema ordinato che si ripete. Il piano che rivedi non crea ancora nessun esercizio. Dopo la conferma, ogni passo del piano apre il normale editor dell’esercizio per quel preset. Save convalida e resta sul passo; Preview torna alla stessa bozza senza copiarla e senza andare avanti; Next convalida e passa al punto successivo; Finish restituisce gli esercizi creati nell’ordine del piano. Se annulli dopo aver salvato esplicitamente qualcosa, QQL ti chiede se vuoi tenere solo quegli esercizi validi già salvati. Non vengono mai inseriti segnaposti o esercizi non validi.',
  ),
  (
    title: 'Duplicare, copiare e spostare gli esercizi',
    body:
        'Duplicate inserisce una copia indipendente, con ID nuovi, subito dopo l’originale. Move Exercise to… e Copy Exercise to… ti fanno scegliere una destinazione esplicita Course > Lesson > Round dentro la copia di lavoro del corso attuale. Move Round to… e Copy Round to… ti fanno scegliere una Lesson. Move conserva identità stabile, contenuto e stato Draft/Published, e toglie l’originale dal punto in cui stava. Copy assegna ID nuovi a tutto il sottoalbero che le appartiene e rimappa i riferimenti interni. Come per la duplicazione, le copie e tutto ciò che contengono partono come Draft. I riferimenti a immagini e registrazioni (media del corso, nominati in base al contenuto) vengono copiati così come sono, e i file restano nella cartella dei media del corso. Tutte queste azioni riguardano solo la copia di lavoro, fino a Confirm course changes.',
  ),
  (
    title: 'Preview degli esercizi e navigazione',
    body:
        'Preview, accanto a Inspection e Save, usa il modulo dell’esercizio così com’è in quel momento, anche se è nuovo o Draft e non l’hai salvato. Mostra l’esercizio come lo vedrebbe uno studente, senza salvare il contenuto, senza cambiare lo stato Draft/Published, senza creare versioni o backup e senza scrivere progressi, XP, Weekly XP, streak, Laurel, Review o stato dei Duel. Inspection è solo un interruttore di presentazione locale: mostra o nasconde la rappresentazione tecnica, senza toccare l’accesso al Course Editor, senza salvare, senza scartare e senza creare modifiche pendenti. Spegnendolo torni al modulo normale, che resta modificabile solo se la radice è in Edit e hai davvero i permessi. I valori non salvati che avevi inserito in Edit restano al loro posto anche dopo questo passaggio avanti e indietro. Se mancano dati necessari, compare un messaggio di validazione senza perdere quello che hai scritto. Tornando indietro ritrovi gli stessi valori nei campi. Previous e Next seguono l’ordine del Round e si fermano ai suoi estremi. Back, lo spostamento tra elementi vicini e le briciole di navigazione proteggono le modifiche non salvate con Keep editing, Discard changes, Save as draft o Save. Salvare qui riguarda comunque solo la copia di lavoro del corso. Le briciole mostrano in modo leggibile il contesto Course, Lesson, Round ed esercizio.',
  ),
  (
    title: 'Help dei campi e Round senza titolo',
    body:
        'Usa il pulsante Help accanto a un campo dell’esercizio per sapere a cosa serve, quante voci accetta, come vanno le righe, che formato vuole, come viene convalidato e qualche esempio. La modalità di contesto, ogni traduzione corretta e l’immagine dell’esercizio hanno un loro Help. L’Help generale sul tipo di esercizio resta accanto al preset. Le risposte digitate usano la sintassi delle espressioni di risposta già esistente; le risposte di Arrange e gli elenchi dei vuoti negli esercizi di ascolto sono invece letterali. Il titolo vuoto di un Round è previsto apposta, sia in Create sia in Edit Round. Segui l’indicazione per lasciarlo vuoto: l’etichetta Round N mostrata segue la posizione, senza creare un titolo memorizzato.',
  ),
  (
    title: 'Audio Library',
    body:
        'Scegli tra On-Device TTS, Recorded MP3 e Hybrid. On-Device TTS usa la voce del dispositivo senza registrazioni; Check unused MP3 files, Import MP3 e Open MP3 from... sono disponibili solo con Recorded MP3 o Hybrid. Ci sono due modi per aggiungere registrazioni, ed entrambi applicano gli stessi controlli e salvano il file nello stesso posto: copia i file MP3 in Documents/QuisquisLingo/Imports/Audio e premi Import MP3 dentro Audio Library, oppure usa Open from… per scegliere uno o più MP3 (fino a 100 file e 250 MB alla volta) nella finestra di sistema; un riepilogo mostra poi l’esito di ogni file. Annullare un dialogo non cambia nulla, e un dialogo che non si apre spiega come usare la cartella fissa. Ogni file .mp3 che si trova lì viene copiato nella cartella dei media del corso, ricavata dal Course ID stabile, e nominato in base al suo contenuto (media:<impronta>.mp3), così le registrazioni identiche si salvano una volta sola, con un massimo di 50 MB (52.428.800 byte) per file. I metadati e i riferimenti appartengono al corso. Se non ci sono MP3, o se un file è troppo grande, ottieni un errore. Ogni file deve essere un vero MP3: frame audio MPEG Layer III dall’inizio alla fine, con eventuali tag ID3 o APE fino a 2 MB in tutto. Un file di altro tipo rinominato in .mp3, danneggiato o troncato, o con una copertina incorporata viene rifiutato (togli l’immagine di copertina e riprova). Dalla cartella, basta un file rifiutato perché non venga importato nulla. Una registrazione che il corso ha già viene saltata. Lo stesso controllo vale per le registrazioni dentro uno ZIP di corso quando lo importi. L’importazione non ricodifica le registrazioni e non impone regole su durata, bitrate o frequenza di campionamento: ascolta ogni registrazione in anteprima per controllare che si senta bene. I file di partenza restano dove sono, quindi spostali altrove dopo un’importazione riuscita, per non reimportarli di nuovo. Associa ogni registrazione esattamente alla parola o all’espressione che contiene. La riproduzione delle registrazioni usa la segmentazione per corrispondenza più lunga e concatena le clip compatibili. Hybrid ripiega sul TTS quando non riesce a comporre una sequenza registrata completa. Il Course JSON contiene i metadati delle clip e questi riferimenti al contenuto, non i byte degli MP3: il solo JSON non porta le registrazioni su un altro dispositivo. I backup di versione verificati copiano le registrazioni referenziate. Export my data è invece una copia dei dati dello studente e non contiene i media dei corsi; al momento non esiste un esportatore di Audio Pack distribuibili.',
  ),
  (
    title: 'Image Bank',
    body:
        'Le immagini e gli ZIP di Image Bank si aggiungono in due modi, ed entrambi applicano gli stessi controlli e salvano il file nello stesso posto: da Documents/QuisquisLingo/Imports/Images, oppure con Open image files from… (fino a 100 immagini alla volta) e Open Image Bank ZIP from… nella finestra di sistema. Ogni immagine viene controllata in base al contenuto, non al nome: deve essere davvero un PNG, JPEG o WebP fisso di al massimo 4096 × 4096 pixel, integro e senza metadati incorporati eccessivi, e QQL la salva con un nome scelto da sé. Nella Image Library del Course Editor, chi può modificare il corso può anche aggiungere immagini, anche più di una alla volta, o un intero Image Bank alla libreria propria del corso con Add images to this Course: restano inutilizzate finché un esercizio non le usa, viaggiano nello ZIP del corso e non entrano mai nella Shared Image Library. Per la cartella fissa, tieni lì esattamente un’immagine supportata per importarne una singola, oppure esattamente uno ZIP per Import Image Bank ZIP. Annullare un dialogo non cambia nulla, e un dialogo che non si apre spiega come usare la cartella fissa. Un bank ha bisogno di image_bank_manifest.json, che contiene una lista JSON oppure un oggetto il cui campo images è quella lista e il cui campo facoltativo attribution vale come credito per ogni immagine che non ne ha uno suo. Ogni voce ha bisogno di un id unico (da 1 a 128 lettere, cifre, punti, trattini o trattini bassi), di primary_term o label (fino a 200 caratteri) e di un filename sicuro che rimandi a un PNG, JPG/JPEG o WebP presente nell’archivio; al massimo 32 parole chiave, ognuna fino a 80 caratteri. Lo ZIP può contenere solo il manifest e le immagini che elenca: un file di crediti o un readme ferma l’importazione, perché i crediti vanno nel campo attribution. Link, voci cifrate, archivi dentro l’archivio e percorsi non sicuri vengono rifiutati. Quando un bank porta categorie che il dispositivo non ha ancora (al massimo 16), un Admin sceglie tra Add them, Put these images under Other e Cancel; niente viene salvato prima di questa scelta. Un’immagine già presente in Shared Images, identica byte per byte, viene saltata senza chiedere, qualunque sia il suo nome. Quando un’immagine del bank ha lo stesso id di un’immagine diversa già presente, l’Admin sceglie tra Skip, Replace (mai per le immagini di QQL) e Keep both (la nuova riceve un nuovo id), e può applicare la risposta a tutte le altre. I limiti sono: 50 MB per lo ZIP, 2 MB per il manifest, 5000 voci nell’archivio, 2500 voci immagine, 50 KB per immagine e 50 MB totali di dati immagine decompressi. Asset mancanti, id duplicati o già presenti, nomi di file ripetuti, percorsi non sicuri, estensioni non supportate e limiti superati fermano l’importazione. I byte delle immagini vengono copiati senza modifiche nella memoria locale dell’app, con un manifest locale: non vengono ridimensionati né resi trasparenti. Gli ZIP di partenza restano dove sono. Guarda le immagini in anteprima prima di sceglierle. Scegliere per un esercizio un’immagine della libreria o di un bank la copia nei media del corso, così le modifiche successive alla libreria non toccano il corso; il Course JSON la indica in base al contenuto e non incorpora i byte dell’immagine.',
  ),
  (
    title: 'Icone tema della Lesson e Preview',
    body:
        'Ogni Lesson può usare un’icona Preinstalled, un’icona Custom Course oppure Numbers. Le icone preinstallate mostrano solo la scelta attuale finché non le tocchi. Per Import custom icon, tieni esattamente un PNG, JPG/JPEG o WebP in Documents/QuisquisLingo/Imports/Lesson Icons. Dimensione massima del file: 2 MB (2.097.152 byte); ogni lato deve stare tra 1 e 4096 pixel. QQL decodifica il primo fotogramma e lo ingrandisce o rimpicciolisce in proporzione, centrandolo su una tela PNG trasparente di 256 × 256, senza ritagliarlo e senza deformarlo. La trasparenza già presente viene mantenuta; uno sfondo opaco non viene rimosso. File mancanti o in numero eccessivo, immagini vuote o non supportate, dimensioni fuori limite e conversioni PNG fallite fermano l’importazione. Il file di partenza resta dov’è. L’asset gestito, che appartiene al corso, contiene i dati PNG incorporati: il suo riferimento sopravvive all’export/import del Course JSON e alla duplicazione del corso, senza bisogno di un percorso esterno. Duplicando una Lesson dentro lo stesso corso, l’asset immutabile viene riutilizzato. Quando una Lesson non ha un’icona esplicita, QQL usa il cerchio con il numero della Lesson, colorato secondo il tema, sia nell’Editor sia nelle schermate di studio. I vecchi valori di stile di ripiego si caricano ancora, ma non cambiano più questa resa. Le icone scelte esplicitamente restano come sono. Tutte le opzioni occupano lo stesso spazio di 84 × 84 nelle schermate di studio. La Preview non scrive nessun progresso.',
  ),
  (
    title: 'Requisiti delle immagini degli esercizi',
    body:
        'Per Import custom image, tieni esattamente un PNG, JPG/JPEG o WebP in Documents/QuisquisLingo/Imports/Images. Massimo: 50 KB (51.200 byte). Una risoluzione di 256 × 256 e un peso di 15 KB o meno sono consigli, non regole: questo importatore non impone nessun vincolo sui pixel e non ridimensiona, non ritaglia e non converte la trasparenza. Controlla l’estensione del nome, il numero di file e i byte, poi copia i byte senza modificarli nella memoria locale dell’app. Il file di partenza resta dov’è. Se il file manca, se ce n’è più di uno o se l’immagine è troppo grande, l’importazione si ferma; la Preview segnala le immagini mancanti o illeggibili. L’esercizio usa poi una copia nei media del corso, nominata in base al contenuto; il Course JSON contiene quel riferimento, non i byte: importare solo quel JSON altrove non porta con sé le immagini personalizzate degli esercizi. I percorsi degli asset integrati si riferiscono alle immagini distribuite con QQL. L’immagine di un esercizio è facoltativa, tranne che nell’ordinamento con immagine come prompt.',
  ),
  (
    title: 'Nuovi tipi di esercizio',
    body:
        'Missing Word riproduce l’audio e mostra la trascrizione con una o più parole tolte. Image Word mostra un’immagine e chiede di comporre la parola corrispondente nella lingua studiata, usando blocchi di lettere o di sillabe. Dialogue Response contiene una frase di contesto nella lingua studiata, una domanda nella stessa lingua ed esattamente due risposte possibili, sempre in quella lingua, mostrate in ordine casuale. Word Match usa esattamente tre coppie di traduzione dalla lingua di partenza a quella studiata. Super Match usa esattamente tre coppie nella lingua studiata e una relazione esplicita, per esempio sinonimi o contrari. Audio Match usa tre elementi audio nella lingua studiata con esattamente tre testi corrispondenti e nessun distrattore; il testo abbinato può essere nella lingua studiata o una traduzione. Listening Spelling / Type what you hear riproduce l’audio nella lingua studiata e richiede di scrivere con la tastiera; il testo mostrato appare come l’hai inserito e Invio conferma. Gli esercizi Sentence Word Order possono avere 0, 1 o al massimo 2 distrattori. La composizione di Image Word con lettere o sillabe non usa mai distrattori: metti solo i blocchi che servono per la risposta. Gap Choice mostra una frase nella lingua studiata a cui manca un elemento e chiede di scegliere l’unico blocco giusto sia per significato sia per grammatica.',
  ),
  (
    title: 'Language Duel',
    body:
        'Ogni Lesson ha il suo Duel. Il Duel dell’ultima Lesson viene presentato come Final Duel, con la descrizione Final challenge for the last Lesson. Il funzionamento è lo stesso e non promette di sbloccare un’altra Lesson. Un Duel normale prende 25 esercizi idonei e diversi tra loro da quella Lesson e parte con 4 vite. Ogni risposta sbagliata costa una vita. Non c’è punteggio né soglia di promozione: per vincere basta arrivare in fondo a tutte e 25 le domande prima di perdere le quattro vite. La disponibilità si calcola sugli esercizi realmente idonei, non sul numero di Round o sul totale teorico degli esercizi. Se gli esercizi idonei sono meno di 25, per quella Lesson il Duel semplicemente non c’è: è un comportamento normale e previsto, non un errore del corso.',
  ),
  (
    title: 'Regole per creare i corsi',
    body:
        'Una Lesson dovrebbe contenere di norma almeno 6 Round, che con contenuti tipici possono voler dire circa 48 esercizi. È un’indicazione per chi scrive: non è un requisito di validità e non decide mai la disponibilità del Duel. Il Round standard contiene 15 esercizi. Evita di ripetere per sbaglio lo stesso contenuto dentro un Round. Le parole isolate di solito vanno in minuscolo, a meno che la lingua non richieda la maiuscola, come per i sostantivi tedeschi o i nomi propri. Gli esercizi sui contrari stanno bene nei Round più avanzati, dopo che lo studente ha già incontrato quei vocaboli. Sentence Word Order può usare 0, 1 o al massimo 2 distrattori: pochi all’inizio di una Lesson, di più più avanti. I distrattori devono essere plausibili ma inequivocabilmente sbagliati. Le istruzioni operative rivolte allo studente vanno scritte nella lingua di partenza del corso. I primi Round dovrebbero introdurre e consolidare il materiale; quelli successivi possono chiedere distinzioni più fini e combinazioni più difficili.',
  ),
  (
    title: 'Listening Spelling',
    body:
        'Type what you hear usa il campo Audio text per la riproduzione e il campo Missing word per le risposte scritte accettate, una parola o un passaggio completo per riga. Il campo Passage transcript viene mostrato così come lo scrivi: questo preset non toglie da solo la parola accettata dalla trascrizione. Guarda il prompt in Preview per essere sicuro che non riveli la risposta. Se invece vuoi che le parole vengano nascoste automaticamente dentro una trascrizione completa, il preset Listen for missing words fa già quel lavoro.',
  ),
  (
    title: 'GuideBook della Lesson',
    body:
        'Ogni Lesson ha il suo GuideBook, disponibile agli studenti quando è pubblicato e Use GuideBook è ON. I suoi campi principali sono, in quest’ordine, Overview, Usage examples, Vocabulary e Grammar. Insights apre una seconda pagina per le sezioni ordinate con Title e Text; le modifiche restano nella copia di lavoro del GuideBook finché non usi Save Guidebook o Save Guidebook as draft, e togliere una sezione richiede una conferma. Save Guidebook as draft lo tiene fuori dalla consegna agli studenti e mostra un badge blu Draft sul GuideBook e sugli elementi che lo contengono. Il badge è indipendente dall’Audit: un GuideBook vuoto ha il bordo rosso finché Use GuideBook è ON, e qualsiasi altro errore o avviso dell’Audit lo tiene rosso comunque. Un GuideBook in Draft ma senza problemi resta verde, con il suo badge blu. L’editor può usare i suoi vocaboli e i suoi esempi per proporre esercizi nuovi.',
  ),
  (
    title: 'Metadati del corso e autori',
    body:
        'Course Info è consultabile in Locked, View only e Inspection mode. Course Info Editor è disponibile solo in Edit e solo per chi ha già i permessi di modifica. Da lì puoi cambiare il nome visibile del corso senza toccare il Course ID. Base language e Learning language restano in sola lettura e mostrano i loro codici ufficiali, generali o regionali. Original Course Created è provenienza immutabile; Last Version Editor e Modified descrivono invece la versione e l’istanza attuali del corso. Aprire l’editor non cambia nessuno di questi valori. L’opzione Automatic per la bandiera toglie ogni scelta esplicita e usa il ripiego basato sulla lingua; scegliere una bandiera integrata, una World Flag, una bandiera caricata o una bandiera riutilizzabile di un corso installato salva soltanto il suo valore trasferibile. Authors / Contributors e Rights Holder sono descrittivi e non autorizzano nessun accesso. Original Course Creator e Course Maintainer usano identità interne stabili e separate. Course Info risolve a parte l’Assigned Team, i Team Leader e i Team Member a partire da Team Manager. Con gli Internal ID visibili compaiono anche i loro ID stabili e la versione del Course Model, in sola lettura. La provenienza del fork indica separatamente chi ha creato quel fork, quando, e da quale corso. I corsi ufficiali conservano identità dell’editore, versione ufficiale, note di rilascio, canale, checksum e verifica. La numerazione delle Lesson si imposta nella pagina Lessons, in Edit. Il termine scelto lì vale per le etichette dell’Editor, per le briciole di navigazione e per quello che vede lo studente; i titoli e gli ID delle Lesson restano invariati. Le Lesson senza icona esplicita usano il cerchio con il numero, colorato secondo il tema. Queste scelte di presentazione non cambiano mai lessonId, progressi o sblocchi.',
  ),
  (
    title: 'Gravità e codici dell’Audit',
    body:
        'Il Course Audit segnala Error, Warning e Info. Error impedisce la pubblicazione o l’importazione, perché il contenuto non è valido dal punto di vista strutturale o funzionale. Warning indica un problema probabile, da rivedere. Info è un’indicazione o un fatto neutro e da solo non blocca mai la pubblicazione. L’Audit può ordinare per Lesson, per nome leggibile del tipo di esercizio o per Recently modified, e si può aprire su un corso intero, su una Lesson o su un Round. L’ordine per data usa updatedAt decrescente con criteri deterministici a parità di valore; le segnalazioni vengono numerate progressivamente dentro ogni gruppo di gravità, dopo i filtri. Il bordo rosso segnala un Error o un Warning e si propaga lungo il ramo che rappresenta. Il bordo verde acceso vuol dire che in quel ramo non ci sono Error né Warning; possono restare indicazioni Info. Un unico indicatore blu Draft comprende lo stato Draft della Lesson o del Round e segue i GuideBook e i contenuti Draft lungo gli elementi che li contengono. Un bordo verde dell’Audit non vuol dire che l’elemento è pubblicato. Una Lesson o un Round esplicitamente Draft tengono nascosti i figli pubblicati finché quel contenitore non viene salvato. Un problema nel GuideBook riguarda la sua Lesson e la gerarchia Lessons, ma non il ramo Rounds. Meno di 3 Round è Info; meno di 25 esercizi idonei per il Duel è Info soltanto quando Create Duels è ON. La mancanza di esercizi di comprensione scritta o orale non produce nessuna segnalazione; il contenuto di comprensione già presente ma malformato viene comunque controllato. Le bozze sono incluse perché chi scrive possa rivederle, senza che questo renda non valido il contenuto pubblicato che non c’entra. Technical reference > Audit Codes mostra il registro condiviso di 102 regole, nell’ordine Error, Warning, Info. Le tre categorie si possono selezionare indipendentemente e partono tutte attive; la ricerca testuale agisce dentro le categorie selezionate.',
  ),
  (
    title: 'Course Audit',
    body:
        'Il Course Audit controlla problemi di struttura e di scrittura: campi non validi negli esercizi, ID duplicati, problemi nei Word Block, mancate corrispondenze audio ed errori di Missing Word. Un brano di lettura vuoto è un Error; con una o due parole lessicali, riconosciute tenendo conto di Unicode e apostrofi, si ottiene READING_PASSAGE_TOO_SHORT, mentre da tre in su no. HINT_REPEATS_PROMPT è un Warning, e rivelare una qualsiasi risposta corretta canonica resta un Error. L’Audit non certifica la grammatica, la correttezza delle traduzioni o la qualità didattica.',
  ),
  (
    title: 'Creare un corso nuovo',
    body:
        'Course Manager crea un progetto Course Model v11 indipendente e lo apre nel Course Editor. New Course ripropone gli stessi campi License / Rights, Authors / Contributors, variante della lingua, livelli, descrizione e metadati di supporto che usa Course Info Editor. Il profilo attivo diventa l’Original Course Creator immutabile ed è anche il Course Maintainer predefinito; in alternativa puoi scegliere come Maintainer un’altra persona locale. L’Assigned Team resta una cosa a parte e non si sceglie durante la creazione. Number of Lessons parte da 3 (numeri interi da 1 a 100) e Rounds per Lesson parte da 1 (numeri interi da 1 a 20). I valori non validi o mancanti mostrano un errore accanto al campo e disattivano Create. L’intera gerarchia iniziale viene creata in blocco, con ID stabili nuovi e Round senza titolo, ciascuno con esattamente un esercizio di esempio Draft di tipo Pick the translation (to target). Rivedi e salva esplicitamente i contenuti didattici prima di pubblicare. Il nuovo corso Not published resta soltanto una copia di lavoro finché Confirm course changes non crea la versione 1; se annulli, non viene salvato nessun corso. I contenuti di authoring v11 importati devono dichiarare esplicitamente provenienza, Maintainer, stato Draft/Published e le date UTC richieste; i Course Model precedenti non vengono né dedotti né convertiti.',
  ),
];

/// The Course types card: heading, the three type definitions, the comparison
/// table and the closing notes.
({
  String title,
  String intro,
  List<String> types,
  List<List<String>> rows,
  List<String> notes,
  String contact,
})
editorHelpCourseTypes(HelpLanguage language) => language == HelpLanguage.italian
    ? _courseTypesItalian
    : _courseTypesEnglish;

const _courseTypesEnglish = (
  title: "Course types",
  intro: "In QQL, there are three course types:",
  types: [
    "1. Official Bundled Course: supplied with the QQL app; trusted through the app distribution.",
    "2. Publisher Course: distributed separately by a publisher and imported into QQL. Publisher verification is a separate status.",
    "3. Custom Course: created or imported by users, including copies, forks and merges.",
  ],
  rows: [
    ["Aspect", "Official Bundled", "Publisher Course", "Custom"],
    [
      "Origin",
      "Included in QQL",
      "Imported publisher release",
      "Created or imported by users",
    ],
    [
      "Trust",
      "App distribution",
      "Valid signature from an approved publisher",
      "No official publisher verification",
    ],
    ["Editing", "Read only", "Read only", "Authorized Maintainer / Team"],
    [
      "Copying",
      "Use a licensed Fork",
      "Use a licensed Fork",
      "Copy as New Course, if authorized",
    ],
    [
      "Forking",
      "Only if derivatives are allowed",
      "Only if derivatives are allowed",
      "Only if derivatives are allowed",
    ],
    [
      "Merging",
      "Not a custom merge source",
      "Not a custom merge source",
      "Two custom sources; new custom result",
    ],
    [
      "Maintenance",
      "QQL publisher",
      "External publisher",
      "Course Maintainer / Assigned Team",
    ],
    [
      "Publication",
      "Included in app releases",
      "Distributed by the publisher",
      "Published or unpublished",
    ],
    [
      "Deletion",
      "Personal removal only",
      "Personal removal; admin-only uninstall if unused by others",
      "Authorized deletion in Course Manager",
    ],
    [
      "Updates",
      "New QQL app release",
      "Newer release, same course ID and publisher",
      "Independent custom versions",
    ],
  ],
  notes: [
    "Publisher Course imports require a verified publisher signature. Unverifiable stored courses and their progress are preserved with Verification required. See Publisher signing and approval in Technical reference.",
    "Bundled and External are two official origins; verified / unverified describes authenticity, not a fourth course type. An unverified file is not accepted as a new Publisher Course.",
    "A Copy creates an independent Custom Course. A Fork is also custom, preserves its source provenance and remains subject to the original licence. Neither becomes official because its source was official.",
    "A Merge creates a new Custom Course from two custom sources, which remain unchanged. Created, imported, copied, forked and merged describe how a custom course originated, not additional course types.",
  ],
  contact:
      "For bundled distribution or approval as an external publisher, contact the QQL team. The publisher signing guide explains the approval procedure.",
);

const _courseTypesItalian = (
  title: "Tipi di corso",
  intro: "In QQL i tipi di corso sono tre:",
  types: [
    "1. Official Bundled Course: distribuito insieme all’app QQL; la fiducia deriva dalla distribuzione dell’app.",
    "2. Publisher Course: distribuito separatamente da un editore e importato in QQL. La verifica dell’editore è uno stato distinto.",
    "3. Custom Course: creato o importato dagli utenti, comprese copie, fork e merge.",
  ],
  rows: [
    ["Aspetto", "Official Bundled", "Publisher Course", "Custom"],
    [
      "Origine",
      "Incluso in QQL",
      "Release importata di un editore",
      "Creato o importato dagli utenti",
    ],
    [
      "Autenticità",
      "Distribuzione dell’app",
      "Firma valida di un editore approvato",
      "Nessuna verifica come editore ufficiale",
    ],
    [
      "Modifica",
      "Sola lettura",
      "Sola lettura",
      "Maintainer / Team autorizzati",
    ],
    [
      "Copia",
      "Usare Fork se consentito",
      "Usare Fork se consentito",
      "Copy as New Course, se autorizzati",
    ],
    [
      "Fork",
      "Solo se i derivati sono consentiti",
      "Solo se i derivati sono consentiti",
      "Solo se i derivati sono consentiti",
    ],
    [
      "Merge",
      "Non è una sorgente custom",
      "Non è una sorgente custom",
      "Due sorgenti custom; nuovo corso custom",
    ],
    [
      "Manutenzione",
      "Editore QQL",
      "Editore esterno",
      "Course Maintainer / Assigned Team",
    ],
    [
      "Pubblicazione",
      "Release dell’app",
      "Distribuzione dell’editore",
      "Pubblicato o non pubblicato",
    ],
    [
      "Eliminazione",
      "Solo rimozione personale",
      "Rimozione personale; disinstallazione admin se non usato da altri",
      "Da Course Manager, se autorizzati",
    ],
    [
      "Aggiornamenti",
      "Nuova release di QQL",
      "Release più recente, stesso ID e editore",
      "Versioni custom indipendenti",
    ],
  ],
  notes: [
    "Gli import ufficiali esterni richiedono una firma verificata dell’editore. I corsi già salvati non verificabili e i loro progressi vengono conservati con Verification required. Vedi Publisher signing and approval nel Riferimento tecnico.",
    "Bundled ed External distinguono due origini ufficiali; verified / unverified indica l’autenticità, non un quarto tipo di corso. Un file non verificato non è accettato come nuovo Publisher Course.",
    "Una copia crea un Custom Course indipendente. Anche un fork è custom, conserva la provenienza ed è soggetto alla licenza originale. Una sorgente ufficiale non rende ufficiali la copia o il fork.",
    "Un merge crea un nuovo Custom Course da due sorgenti custom, che restano invariate. Creato, importato, copiato, forkato e unito descrivono l’origine di un custom, non altri tipi di corso.",
  ],
  contact:
      "Per la distribuzione insieme all’app o l’approvazione come editore esterno, contatta il team QQL. La guida sulle firme descrive la procedura di approvazione.",
);

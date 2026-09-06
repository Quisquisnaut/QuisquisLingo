import 'package:flutter/material.dart';
import '../models/exercise_authoring.dart';
import 'audit_codes_screen.dart';

class EditorHelpScreen extends StatelessWidget {
  const EditorHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course Editor Help')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TechnicalLinks(),
        const SizedBox(height: 12),
        _HelpSection(
          title: 'Courses in learner mode',
          body:
              'Change course lists every Published course: the bundled official courses included with QuisquisLingo and Published courses under Local courses. Draft Courses stay available for authoring but cannot become the active learner Course. Selecting a Published course makes it current. The learner page resumes the active Published Lesson for that learner and course. When a course has real Sections, the fixed Section selector opens its ordered consecutive Published Section blocks and jumps to each block\'s first Lesson.',
        ),
        _HelpSection(
          title: 'Course origin',
          body:
              'Bundled official courses are verified immutable source copies supplied with QuisquisLingo. External official courses retain their declared publisher identity but are labelled unverified when QQL cannot authenticate that publisher. Custom courses are created locally or imported without official provenance. Both official origins open Official course - read only: inspect Course Info, Audit, Preview, Version History and Lessons/Rounds/Exercises without an authoring transaction. Course Info shows publisher, official version, verification status and checksum. Only an explicit derivativeWorksPolicy of allowed enables Fork as custom course; forbidden or unspecified permission explains why it is unavailable. A fork has fresh IDs and independent custom history, permanently retains original publisher/authors/provenance, and records the fork creator separately. Custom duplication remains a separate action.',
        ),
        _HelpSection(
          title: 'Temporary sample content',
          body:
              'Custom Course Editor starts locked for each course to prevent accidental changes. Unlock only the course you intend to edit. A course may be marked TEMPORARY SAMPLE while it contains development or demonstration material. Replace sample material with reviewed educational content before distribution. The notice continues to appear whenever the editor opens until the course-level marker is removed.',
        ),
        _HelpSection(
          title: 'Course structure',
          body:
              'For custom courses, Lessons is the first content section on the main Course page. The dedicated Lessons page keeps the single authoritative Lock control at its top, and each Lesson page puts Rounds first. From there the hierarchy continues through Round / Exercises. Course, Lesson and Round menus provide scoped Audit plus their appropriate Edit, Rename, Duplicate and Preview actions. A duplicate is inserted after its source with fresh IDs throughout its owned subtree and starts as Draft. Exercise type cannot be changed after creation. Each Lesson has its own learner-facing GuideBook and Lesson-scoped Duel.',
        ),
        _HelpSection(
          title: 'One Course Editor transaction',
          body:
              'Opening a custom course creates an editable working copy beside an immutable snapshot of the persisted course. Every Course Info, Lesson, Round, Exercise, GuideBook, generator and reorder operation changes only that working copy. Nested Save stores a normal item in the working copy; Save as draft stores a Draft item there. Neither action changes the learner-visible course, creates a backup or increments the course version. Leaving an Exercise with unsaved form changes offers Keep editing, Discard changes, Save as draft or Save. Discard affects only that form; earlier working-copy changes remain. Other nested pages retain their established Back behavior. Navigation among nested pages never shows the final course confirmation.',
        ),
        _HelpSection(
          title: 'Confirm or cancel the complete course',
          body:
              'Leaving the top-level Course Editor compares the complete working copy with the original course. If they are semantically identical, the Editor closes directly. Otherwise exactly one dialog offers Confirm course changes or Cancel course changes and an optional multiline version note. Confirm first creates and verifies a complete backup, then increments the separate internal course version by exactly one and atomically applies the whole working copy. Cancel discards the entire working copy without a backup or version increment. A failed backup or persistence keeps the working copy open and leaves the persisted course unchanged.',
        ),
        _HelpSection(
          title: 'Local course edits and backups',
          body:
              'Every confirmed change to an existing custom course first archives the complete currently persisted course under Documents/QuisquisLingo/Exports/Course Backups/<courseId>. Backup manifests include the full v6 course, provenance, versions, author, UTC timestamp displayed locally, optional notes, checksum and referenced managed audio assets. Backups are never pruned automatically. Version History lists the current version and verified backups newest first, with Open backup folder and Export JSON. Only custom history supports Restore into working copy. Official history contains publisher sources only; obsolete local-variant files are not loaded or deleted. A restore is still only a working-copy change until the top-level confirmation succeeds.',
        ),
        _HelpSection(
          title: 'Official course updates',
          body:
              'A newer verified official course update is accepted only for the same courseId and publisher and only when its checksum is valid. Before replacement, QuisquisLingo archives the previous official source. The new source becomes current. Existing custom forks and their histories stay unchanged, with no merge or rebase. Old Build 225 official overrides are not used, converted or deleted. If publisher authenticity cannot be verified, the course is clearly marked External official — unverified and installation requires an explicit warning confirmation.',
        ),
        _HelpSection(
          title: 'Course info and license',
          body:
              'Course info stores human author credit, the content license and optional Buy a Coffee HTTPS link separately from the MPL-2.0 license of the QuisquisLingo software. It also selects the learner Lesson prefix—Lesson, Unit, Topic, Module, Skill, Chapter, Stage, Step, Part, a custom label, number only or none—and the default Lesson icon style. Choose a common license from the menu or select Other / Custom license and enter the course-specific terms. Official content and provenance are read-only. In a custom fork, original authorship and provenance remain permanently visible alongside separate local creator and version-author credits. Eligible local custom courses show Export Course JSON as the final Course-page entry.',
        ),
        _HelpSection(
          title: 'Import a custom course',
          body:
              '1. Copy the Course Model v6 JSON file to Documents/QuisquisLingo/Exports. 2. Rename it exactly import.json. 3. Open Course Editor and press Import course JSON. 4. After parsing and Course Audit validation, the course is copied into QuisquisLingo local storage and appears under Local courses. Audit errors block import; warnings are reported for review but do not block it. An external-official file retains its declared publisher provenance but is marked unverified unless QQL can authenticate it; an ordinary import remains custom. The imported course no longer depends on import.json, and QuisquisLingo leaves import.json in place. Imports must be valid UTF-8 Course Model v6 JSON and may be no larger than 10 MB. v5 and older formats are rejected without migration, conversion or deletion.',
        ),
        _HelpSection(
          title: 'Export a custom course',
          body:
              'Open a local custom course and choose Export Course JSON, the final entry on its Course page. The entry is absent for bundled and external official sources and when a custom course is not opened through the local-course authoring path. A licensed fork follows this custom export path while preserving its original publisher, authorship, lineage, licence and fork-creator metadata. QQL has no separate export-permission field and does not distinguish team-supplied custom JSON from other imported custom JSON; eligibility uses the existing local custom-course boundary. QuisquisLingo saves the complete Course Model v6 authoring JSON directly in Documents/QuisquisLingo/Exports. Draft/Published state, required UTC modification timestamps, origin and version metadata, optional custom flag data, Buy a Coffee metadata, Lesson numbering/icon-style settings and managed custom Lesson icons are included. Course audio metadata and references are included, but MP3 bytes are not embedded; verified version backups retain their existing referenced-recording copy behavior. There is no Save As dialog. If a filename exists, _2, _3 and later suffixes avoid overwriting it.',
        ),
        _HelpSection(
          title: 'Import a custom flag',
          body:
              'Copy a valid PNG or JPEG to Documents/QuisquisLingo/Exports as flag.png, flag.jpg or flag.jpeg, then press Import flag in Create new course. If several names exist, QQL uses the first in that order. Maximum input: 2 MB (2,097,152 bytes). Minimum dimensions: 64 × 40 pixels; maximum: 8192 pixels on either side. QQL checks the actual PNG/JPEG signature and decodes the image. Images larger than 256 pixels on their longest side are reduced proportionally; smaller accepted images are not enlarged. The first image frame becomes PNG without cropping or a square canvas. Existing PNG transparency is retained; JPEG does not acquire a transparent background. PNG data are embedded in the Course and survive course JSON export/import and duplication. The transfer source is left in place and is no longer needed. Missing, unreadable, unsupported, oversized, too-small or over-resolution input produces an error; failed PNG conversion also stops import.',
        ),
        _HelpSection(
          title: 'Generate Rounds from Lesson GuideBook',
          body:
              'Open a Lesson and choose Generate Rounds from GuideBook. The generator uses only vocabulary pairs and examples in that Lesson GuideBook; at least three usable target/source pairs are required. Choose 1–12 Rounds and 1–15 Exercises per Round (defaults: 6 and 8). Review the count, total, normalized progressive-difficulty curve and planned registry presets before generation. Early drafts emphasize guided recognition with fewer distractors, middle drafts add construction and context, and later drafts add freer production. Generated Rounds remain drafts: edit, preview, delete or regenerate them, then explicitly approve them to append fresh-ID copies after existing Rounds. Generation cannot guarantee pedagogical correctness, so every Round and Exercise requires human review.',
        ),
        _HelpSection(
          title: 'Exercise Creation Wizard',
          body:
              'In a Round, Creation Wizard sits beside New exercise. Choose 1–30 Exercises and select Balanced mix, Random mix, one or more categories, exact exercise types, or an ordered repeating pattern. The reviewed plan creates no Exercise objects. After confirmation, each planned step opens the ordinary preset-specific Exercise editor. Save validates and stays on the step; Preview returns to the same draft without copying or advancing; Next validates and advances one step; Finish returns the created Exercises in plan order. If you cancel after explicitly saving work, confirm whether to keep only those valid saved Exercises. Future and invalid placeholders are never inserted.',
        ),
        _HelpSection(
          title: 'Duplicate, Copy and Move exercises',
          body:
              'Duplicate inserts an independent fresh-ID copy immediately after the source. Move Exercise to… and Copy Exercise to… choose an explicit Course > Lesson > Round destination within the current course working copy. Move Round to… and Copy Round to… choose a Lesson there. Move preserves stable identity, content and Draft/Published state and removes the source from its previous parent. Copy allocates fresh IDs throughout the owned subtree and remaps internal references. Following the existing duplication policy, copies and their owned descendants start as Draft. Shared immutable image/audio paths remain references. These actions affect only the working copy until Confirm course changes.',
        ),
        _HelpSection(
          title: 'Exercise Preview and navigation',
          body:
              'Preview beside Save uses the complete current unsaved Exercise form, including a new or Draft Exercise. It uses learner rendering without saving content, changing Draft/Published state, creating versions/backups or writing learner progress, XP, Weekly XP, streak, Laurel, Review or Duel state. Insufficient runtime data produces a validation message without losing edits. Returning restores the same field values. Previous and Next follow the current Round order and stop at its boundaries. Back, sibling navigation and safe breadcrumb navigation protect unsaved Exercise changes with Keep editing, Discard changes, Save as draft or Save. Saving here affects only the course working copy. Breadcrumbs show readable Course, Lesson, Round and Exercise context.',
        ),
        _HelpSection(
          title: 'Field Help and untitled Rounds',
          body:
              'Use the Help control beside an Exercise field for its purpose, entry count, line rules, format, validation and examples. Context mode, each correct-translation entry and Exercise image have their own Help. Broad Exercise Help remains available beside the preset. Typed answers support the existing answer-expression syntax; Arrange answers and listening gap lists are literal. An empty Round title is intentionally supported in Create and Edit Round. Follow the untitled guidance to keep it blank; its displayed Round N label follows its position without creating a stored title.',
        ),
        _HelpSection(
          title: 'Audio Library',
          body:
              'Choose System TTS, Recorded MP3 or Hybrid. Copy MP3 files to Documents/QuisquisLingo/Imports/Audio and press Import MP3 in Audio Library. Every .mp3 file there is copied to local app storage grouped by learning language, with a maximum of 50 MB (52,428,800 bytes) per file. The metadata and references belong to the Course even though physical files use that language grouping. No MP3 files or an oversized file produces an error. Import does not re-encode recordings or enforce a duration, bitrate or sample-rate rule; preview each recording to check playback. Source files remain in place, so move them out after successful import to avoid importing them again. Associate each recording with the exact word or expression it contains. Recorded playback uses longest-match segmentation and concatenates compatible clips. Hybrid falls back to TTS when a complete recorded sequence cannot be assembled. Course JSON stores clip metadata and local paths, not MP3 bytes; JSON alone does not transfer these recordings to another device. Verified course-version backups copy referenced recordings. Export my data is a separate learner backup and does not include course media; a distributable Audio Pack exporter is not currently available.',
        ),
        _HelpSection(
          title: 'Image Bank',
          body:
              'Images and Image Bank ZIPs use Documents/QuisquisLingo/Imports/Images without a file picker. Keep exactly one supported image for a single-image import, or exactly one ZIP for Import Image Bank ZIP. A bank needs image_bank_manifest.json containing a JSON list; every entry needs a unique id, primary_term or label, and a safe filename referring to a PNG, JPG/JPEG or WebP in the archive. Limits: 50 MB ZIP, 2 MB manifest, 5000 archive entries, 2500 image entries, 50 KB per image and 50 MB total decompressed image bytes. Missing assets, duplicate/colliding IDs, duplicate filenames, unsafe paths, unsupported extensions and exceeded limits stop import. Image bytes are copied unchanged to local app storage with a local manifest; they are not resized or made transparent. Source ZIPs remain in place. Preview images before selection. Keep the original bank package separately: course JSON contains image paths and does not embed bank images or make local paths portable.',
        ),
        _HelpSection(
          title: 'Lesson theme icons and Preview',
          body:
              'Each Lesson can select a Preinstalled icon, a Custom Course icon, or None. For Import custom icon, keep exactly one PNG, JPG/JPEG or WebP in Documents/QuisquisLingo/Imports/Lesson Icons. Maximum input: 2 MB (2,097,152 bytes); each dimension must be 1–8192 pixels. QQL decodes the first frame and scales it up or down proportionally, centered on a transparent 256 × 256 PNG canvas without cropping or distortion. Existing transparency is preserved; an opaque source background is not removed. Missing/multiple files, empty or unsupported images, exceeded size/dimensions and failed PNG conversion stop import. The source remains in place. The managed Course-owned asset stores embedded PNG data; its reference survives course JSON export/import and Course duplication, with no external source path required. Lesson duplication within the Course reuses the immutable asset. None uses the Course default monochrome GuideBook mark or deterministic colored number; every option uses the established 84 × 84 learner footprint. Preview writes no learner progress.',
        ),
        _HelpSection(
          title: 'Exercise image specifications',
          body:
              'For Import custom image, keep exactly one PNG, JPG/JPEG or WebP in Documents/QuisquisLingo/Imports/Images. Maximum: 50 KB (51,200 bytes). A 256 × 256 resolution and 15 KB or less are recommendations; this importer imposes no pixel-dimension rule and performs no resizing, cropping or transparency conversion. It checks the filename extension, file count and byte size, then copies the bytes unchanged to local app storage. The source stays in place. Missing/multiple sources or an oversized image stops import; Preview reports missing or unreadable images. Course JSON stores the local image path, not the file bytes, so importing that JSON elsewhere does not transfer custom exercise images. Built-in asset paths refer to images supplied with QQL. An Exercise image is optional except for Image-prompt ordering.',
        ),
        _HelpSection(
          title: 'New exercise types',
          body:
              'Missing Word plays audio while showing its transcript with one or more words removed. Image Word shows an image and asks the learner to build the corresponding target-language word from letter or syllable blocks. Dialogue Response contains a target-language context sentence, a target-language question and exactly two target-language response options; their display order is randomized. Word Match uses exactly three source-to-target translation pairs. Super Match uses exactly three target-language pairs and an explicit relationship such as synonyms or opposites. Audio Match uses three target-language audio items with exactly three matching texts and no distractors; the matching text may be in the target language or a translation. Listening Spelling / Type what you hear plays target-language audio and requires keyboard input; its prompt is displayed as entered and Return/Enter submits. Sentence Word Order exercises may use 0, 1 or at most 2 distractors. Image Word letter/syllable composition never uses distractors: include only the blocks required for the answer. Gap Choice shows a target-language sentence with one missing element and asks the learner to choose the single block that is correct in both meaning and grammar. The standard sample round length is 15 exercises.',
        ),
        _HelpSection(
          title: 'Language Duel',
          body:
              'Each Lesson owns its Duel. A standard Duel selects 25 unique eligible exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or pass threshold: completing all 25 questions before all four lives are lost wins. Availability is determined from the actual eligible exercise pool, not from the number of Rounds or the total theoretical exercise count. If fewer than 25 eligible exercises exist, the Duel is simply unavailable for that Lesson; this is normal supported behavior, not a course error.',
        ),
        _HelpSection(
          title: 'Course creation rules',
          body:
              'A Lesson should normally contain at least 6 Rounds, which in typical content may mean roughly 48 exercises. This is author guidance only: it is not a validity requirement and never determines Duel availability. The standard Round contains 15 exercises. Avoid accidental duplicate content inside one Round. Isolated words should normally be lowercase unless the language requires capitalization, as with German nouns or proper names. Opposite exercises belong in later Rounds, after the learner has already met the vocabulary. Sentence Word Order may use 0, 1 or at most 2 distractors; use fewer distractors early in a Lesson and more later. Distractors should be plausible but unambiguously wrong. Learner-facing operational instructions must use the course source language. Early Rounds should introduce and consolidate material; later Rounds can demand harder discrimination and combinations.',
        ),
        _HelpSection(
          title: 'Listening Spelling',
          body:
              'Type what you hear uses Audio text for playback and the Missing word field for accepted typed answers, one complete word or passage per line. Passage transcript is displayed as entered; this preset does not automatically remove the accepted word from it. Preview the visible prompt so it does not reveal the answer. For automatically hidden words in a complete transcript, the existing Listen for missing words preset supplies that workflow.',
        ),
        _HelpSection(
          title: 'Lesson Guidebook',
          body:
              'Each Lesson has its own Guidebook, available to learners from the Lesson page. It can contain vocabulary, example sentences, explanations and other learning material. The editor can use its vocabulary and examples to propose new exercises.',
        ),
        _HelpSection(
          title: 'Course metadata and authors',
          body:
              'Course info is always available, even while content is locked. It can change the visible Course name without changing the read-only Course ID. Source and Target language are also read-only for now. Multiple authors can hold multiple roles, including Illustrator. Roles describe contributions, not hierarchy. Custom-course metadata records creation and last-modification authors from the active local QQL profile, creation and modification times, internal course version and version notes. Official courses separately retain publisher identity, official version, release notes, channel, checksum and verification. Lesson presentation settings change labels and fallback art only; they never change lessonId, progression or unlocks.',
        ),
        _HelpSection(
          title: 'Audit severity and codes',
          body:
              'Course Audit reports Errors, Warnings and Info. Error blocks publication or import because content is structurally or functionally invalid. Warning marks a likely authoring problem that needs review. Info is guidance or a neutral fact and never blocks publication by itself. Audit can sort by Lesson, friendly Exercise type or Recently modified and can be opened for a whole Course, one Lesson or one Round. Recent order uses updatedAt descending with deterministic ties; findings are numbered progressively inside each severity group after filtering. A red border marks an Audit Error or Warning and propagates through its Round, Lesson and Course branch. A luminous green border means the current branch has no Error or Warning; Info guidance may remain. One blue Draft indicator independently follows Draft Exercises through the same hierarchy, including Rounds and Lessons links. Fewer than 3 Rounds and Duel availability below 25 eligible Exercises are Info. Missing Reading- or Listening-comprehension coverage produces no finding; malformed existing comprehension content still receives validation. Drafts are included for author review without making unrelated Published learner content invalid. Technical reference > Audit Codes displays the shared 103-rule registry in Errors, Warnings, Info order. All three independently selectable categories start enabled, and text search applies within the selected categories.',
        ),
        _HelpSection(
          title: 'Course Audit',
          body:
              'Course Audit checks structural and authoring problems such as invalid exercise fields, duplicate IDs, Word Block problems, missing audio mappings and Missing Word errors. An empty Reading passage is an Error; one or two Unicode/apostrophe-aware lexical words produce READING_PASSAGE_TOO_SHORT, while three or more do not. HINT_REPEATS_PROMPT is a Warning and revealing any canonical correct answer remains an Error. It does not certify grammar, translation accuracy or pedagogical quality.',
        ),

        _HelpSection(
          title: 'Create a new course',
          body:
              'Course Editor can create an independent Course Model v6 project from scratch. It starts as Draft with 3 Draft placeholder Lessons and stable IDs; no Rounds are created automatically. A manually created Round starts as Draft with three Draft dummy Exercises. The new custom course remains only a working copy until Confirm course changes creates version 1; cancelling creates no stored course. Custom courses appear under Local courses, whose menu provides Edit, Duplicate, Audit, Export and the established protected delete flow. Import and export use portable QuisquisLingo JSON. Imported authoring content must state Draft/Published state and required UTC updatedAt timestamps explicitly; this release does not infer or migrate them.',
        ),
      ],
    ),
  );
}

class _TechnicalLinks extends StatelessWidget {
  const _TechnicalLinks();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Technical reference',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Work in progress. These pages describe the Course Model v6 implementation separately from the practical Editor instructions.',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Exercise types'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseHelpScreen()),
            ),
          ),
          ListTile(
            key: const Key('editor-help-audit-codes'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Audit Codes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AuditCodesScreen())),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('QuisquisLingo Course Model v6'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CourseModelV4HelpScreen(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Exercise primitives'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExercisePrimitivesHelpScreen(),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('JSON data structure'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JsonV4HelpScreen())),
          ),
        ],
      ),
    ),
  );
}

class ExerciseHelpScreen extends StatelessWidget {
  const ExerciseHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exercise Help')),
    body: ListView(
      key: const Key('exercise-help-list'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final category in ExerciseCategory.values)
          if (ExercisePresetRegistry.inCategory(category).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                category.label,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final preset in ExercisePresetRegistry.inCategory(category))
              _HelpSection(
                title: preset.name,
                body: ExercisePresetRegistry.helpByPreset[preset.id]!,
              ),
          ],
        const _HelpSection(
          title: 'Answer variants',
          body:
              'Multiple complete equivalent answers may be entered on separate lines. Compact syntax is optional: {Io} makes “Io” optional; [prendo|vorrei] chooses one independent alternative; and (non arrivo <> oggi) swaps only declared phrase parts. Grouped alternatives use *: to link by position: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] accepts “il tuo denaro” and “i tuoi soldi”, never “il tuoi soldi” or “i tuo denaro”. Two or more linked groups are required and every linked group must have the same number of alternatives. Linked groups compose with {}, ordinary [] and valid <> scopes. During reordering, terminal punctuation stays at the final sentence end. Expansion is deterministic, removes duplicates, and rejects malformed syntax or more than 128 variants instead of truncating.',
        ),
        const _HelpSection(
          title: 'Text evaluation and corrections',
          body:
              'QQL accepts any configured complete answer or syntax-expanded variant after the established case, punctuation, whitespace, apostrophe and accent rules. Type the translation also permits one omitted or duplicated repeated letter in a word of at least five characters when every word position is otherwise unchanged. After every correct typed response, feedback shows the nearest canonical Correct answer; it names only differences actually used, such as capitalization, ignored punctuation, normalized whitespace, an omitted diacritic or the explicitly allowed typo. Exact answers show no false difference reason. Incorrect responses retain the same deterministic closest-correction selection, and correction choice never changes correctness.',
        ),
        const _HelpSection(
          title: 'Contextual comprehension example',
          body:
              'Question: What does Jane mean?\n\nContext:\nJane: I thought Jim was coming with us.\nJim: I changed my mind.\nJane: That’s just great.\n\nQuestion and Context are separate. Context can be text, audio, or both. Dialogue turns are optional; an announcement, short passage or situation is equally valid. Configure answer choices separately.',
        ),
      ],
    ),
  );
}

class CourseModelV4HelpScreen extends StatelessWidget {
  const CourseModelV4HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'QuisquisLingo Course Model v6',
    sections: const [
      _HelpSection(
        title: 'Status',
        body:
            'Work in progress. QuisquisLingo uses formatVersion 6 as its only native course model. Earlier formats are rejected without migration or deletion.',
      ),
      _HelpSection(
        title: 'Hierarchy',
        body:
            'Course > Lesson > Guidebook + Round > Content. Every Lesson owns its Guidebook and Duel. Exercise is one Content kind rather than the only object allowed inside a Round.',
      ),
      _HelpSection(
        title: 'Content',
        body:
            'Current kinds include exercise, presentation, explanation, example, vocabulary, text and dialogue. Content has a stable ID and can be required for normal completion. Lesson, Round and Exercise objects carry required UTC updatedAt timestamps. Presentation Content can be interactive without producing a correct/incorrect result.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson GuideBook is structured Content rather than a single monolithic block. Its vocabulary, examples and explanations are learner reference material and can also act as the sole source for configurable, progressively harder draft Round generation and sourceRefs.',
      ),
      _HelpSection(
        title: 'Completion and progression',
        body:
            'required means required for normal completion. Completion, correctness and unlock state are separate. Completing a Lesson or winning its available Duel can unlock the next Lesson without marking skipped Content as completed.',
      ),
      _HelpSection(
        title: 'Language Duel',
        body:
            'Duel identity belongs directly to the Lesson. QuisquisLingo dynamically selects 25 unique eligible exercises from that Lesson and starts with 4 lives. There is no score or pass threshold. If the actual eligible pool is smaller than 25, the Lesson Duel is unavailable rather than invalid.',
      ),
      _HelpSection(
        title: 'Friendly Editor templates',
        body:
            'The Editor keeps names such as Choose a picture, What do you hear?, Build the sentence and Match the sounds. editorTemplate is optional authoring metadata. The learner executes the primitive representation.',
      ),
    ],
  );
}

class ExercisePrimitivesHelpScreen extends StatelessWidget {
  const ExercisePrimitivesHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'Exercise primitives',
    sections: const [
      _HelpSection(
        title: 'Status',
        body:
            'Work in progress. The current primitive set is the implemented Course Model v6 baseline.',
      ),
      _HelpSection(
        title: 'Exercise anatomy',
        body:
            'Exercise = Prompt[] + Interaction + Evaluation, with optional hint and feedback.',
      ),
      _HelpSection(
        title: 'Interactions',
        body:
            'select: choose one or more Items. input: produce a typed response. arrange: order Items. match: create relationships between Items.',
      ),
      _HelpSection(
        title: 'Evaluations',
        body:
            'selected_items checks selected stable Item IDs. text_match checks accepted text with explicit normalization. ordered_items checks Item order. matched_items checks Item relationships.',
      ),
      _HelpSection(
        title: 'Prompt and Item media',
        body:
            'The initial media primitives are text, image and audio. Prompt elements may carry roles such as primary, passage, question, context or clue.',
      ),
      _HelpSection(
        title: 'Presentation Content',
        body:
            'Flashcard is presentation Content, not an Exercise. The learner chooses understood or review_later. Both complete the current presentation; review_later requests re-presentation and is not an incorrect answer.',
      ),
      _HelpSection(
        title: 'Templates vs primitives',
        body:
            'Friendly templates remain an authoring layer. Multiple templates can share the same primitive mechanics. Template constraints such as distractor limits do not become universal primitive rules.',
      ),
    ],
  );
}

class JsonV4HelpScreen extends StatelessWidget {
  const JsonV4HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'JSON data structure',
    sections: const [
      _HelpSection(
        title: 'Status',
        body: 'Work in progress. QuisquisLingo writes formatVersion: 6.',
      ),
      _HelpSection(
        title: 'Root',
        body:
            'The root contains formatVersion, Course metadata and lessons[]. Bundled samples and user-created courses are native v6 files.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson contains guidebook.content[] with structured Content such as explanation, vocabulary and example entries.',
      ),
      _HelpSection(
        title: 'Lesson and Round',
        body:
            'Course, Lesson, Round and authored Exercise content carry explicit draft/published state. Lesson, Round and Exercise also require UTC updatedAt timestamps. A Course stores Lesson numbering and fallback-icon settings plus optional managed custom Lesson-icon assets. A Lesson contains lessonId, title, optional Section and themeIconAsset metadata, guidebook, rounds[] and its Duel identity. Round title is optional and falls back everywhere to its current Round N position without changing identity.',
      ),
      _HelpSection(
        title: 'Exercise Content',
        body:
            'Exercise Content stores editorTemplate plus exercise.prompt[], exercise.interaction and exercise.evaluation. Correctness uses stable Item IDs rather than display indexes. Build the translation stores one or more literal correctOrders with answer text and ordered Item IDs; legacy correctOrder is rejected.',
      ),
      _HelpSection(
        title: 'Duel',
        body:
            'A Lesson serializes a stable Duel ID and title. Availability is derived at runtime from the actual Lesson exercise pool under the standard eligibility and deduplication rules; it is not serialized and does not depend on Round count.',
      ),
      _HelpSection(
        title: 'Compatibility',
        body:
            'Bundled and custom courses are native Course Model v6. v5 and older formats are unsupported and are not read, migrated, converted or deleted.',
      ),
    ],
  );
}

class _TechnicalPage extends StatelessWidget {
  final String title;
  final List<Widget> sections;
  const _TechnicalPage({required this.title, required this.sections});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(16), children: sections),
  );
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String body;
  const _HelpSection({required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    ),
  );
}

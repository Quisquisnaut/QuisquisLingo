import 'package:flutter/material.dart';

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
              'Change course lists every available course: the bundled courses included with QuisquisLingo and all courses under My custom courses, whether they were created in the editor or imported from JSON. Selecting a course makes it the current course. The Unified Learner page resumes the active Lesson for that learner and course. When a course has real Sections, the fixed Section selector opens its ordered consecutive Section blocks and jumps to each block\'s first Lesson.',
        ),
        _HelpSection(
          title: 'Bundled courses and custom courses',
          body:
              'Current bundled course is the copy supplied with QuisquisLingo. My custom courses contains courses created by the user and courses imported from JSON. Temporary sample material refers to bundled sample courses supplied for development and demonstration; creating a custom course does not automatically add sample lessons. Custom courses remain separate from bundled-course local overrides.',
        ),
        _HelpSection(
          title: 'Temporary sample content',
          body:
              'Course Editor starts locked for each course to prevent accidental changes. Unlock only the course you intend to edit. A course may be marked TEMPORARY SAMPLE while it contains development or demonstration material. Replace sample material with reviewed educational content before distribution. The notice continues to appear whenever the editor opens until the course-level marker is removed.',
        ),
        _HelpSection(
          title: 'Course structure',
          body:
              'Create, delete and reorder Lessons, Rounds and exercises in the Chapter-free Course > Lesson > Round > Content hierarchy. Exercise type cannot be changed after an exercise is created. Create a replacement exercise instead. Each Lesson has its own learner-facing Guidebook and Lesson-scoped Duel.',
        ),
        _HelpSection(
          title: 'Local course edits and backups',
          body:
              'Changes to built-in courses are stored locally. A future app update that contains a newer version of the same course can overwrite those local edits. Export edited courses separately before updating. Courses and course edits are not included in Export my data; learner-data exports contain progress, streaks and other learner information only.',
        ),
        _HelpSection(
          title: 'Course info and license',
          body:
              'Course info stores the human author credit and the content license separately from the MPL-2.0 license of the QuisquisLingo software. Choose a common license from the menu or select Other / Custom license and enter the course-specific terms. Copy edits as JSON applies to the Current bundled course: it copies the local bundled-course override to the clipboard and does not create a file. Export course JSON applies to My custom courses: it writes a complete portable Course Model v5 JSON file to Documents/QuisquisLingo/Exports. Learner Export/Import in Settings is separate and does not contain custom courses, course edits, Image Banks or Audio Packs.',
        ),
        _HelpSection(
          title: 'Import a custom course',
          body:
              '1. Copy the Course Model v5 JSON file to Documents/QuisquisLingo/Exports. 2. Rename it exactly import.json. 3. Open Course Editor and press Import course JSON. 4. After parsing and Course Audit validation, the course is copied into QuisquisLingo local custom-course storage and appears under My custom courses. Audit errors block import; warnings are reported for review but do not block it. The imported course no longer depends on import.json, and QuisquisLingo leaves import.json in place. Imports must be valid UTF-8 Course Model v5 JSON and may be no larger than 10 MB. Older Chapter-based formats are not imported or migrated. If the same courseId already exists, QuisquisLingo treats it as the same custom course and asks before replacing the stored copy.',
        ),
        _HelpSection(
          title: 'Export a custom course',
          body:
              'Open My custom courses and choose Export course JSON for the course you want to export. QuisquisLingo saves the complete portable Course Model v5 JSON directly in Documents/QuisquisLingo/Exports. There is no Save As dialog. If a file with the same name already exists, QuisquisLingo adds _2, _3 and later numeric suffixes instead of silently overwriting it. Optional custom flag data is included in the exported course JSON.',
        ),
        _HelpSection(
          title: 'Import a custom flag',
          body:
              '1. Copy the flag image to Documents/QuisquisLingo/Exports. 2. Name it flag.png, flag.jpg or flag.jpeg. 3. Open Create new course and press Import flag. The file must be a valid PNG or JPEG, no larger than 2 MB and at least 64×40 pixels. Large images are resized to at most 256 pixels on the longest side while preserving proportions. The imported flag is stored with the custom course, so the original image file does not need to remain in the transfer folder afterward.',
        ),
        _HelpSection(
          title: 'Generate 3 Rounds from Lesson Guidebook',
          body:
              'Open a learning Lesson and choose Generate 3 Rounds from Guidebook. The generator uses only vocabulary pairs and example sentences already stored in that Lesson Guidebook. It proposes three Rounds of increasing difficulty, randomizes suitable material and option order, and avoids exact duplicate exercises. The first Content item of Round 1 is a short non-exercise introduction based on essential Guidebook material and tells the learner to read the Lesson Guidebook for more. All three proposed Rounds are shown for review and passed through Course Audit. Nothing is created until the author explicitly chooses Approve and create 3 Rounds. Generated exercises remain editable after creation. At least three usable target/source vocabulary pairs are required.',
        ),
        _HelpSection(
          title: 'Copy and Move exercises',
          body:
              'Copy and Move use an explicit in-app transfer buffer. Choose Copy or Move on an exercise, navigate to the destination Round, then use the Paste button in that Round. Copy leaves the source exercise in place; Move removes it from the source Round and pastes it once at the destination. Copy never silently duplicates an exercise immediately underneath the original.',
        ),
        _HelpSection(
          title: 'Audio Library',
          body:
              'Choose System TTS, Recorded MP3 or Hybrid. To import recordings, copy the MP3 files to Documents/QuisquisLingo/Imports/Audio and press Import MP3 in Audio Library. All MP3 files in that folder are imported; the source files are left in place, so move or remove them after a successful import to avoid importing them again. Imported MP3 files can be associated with exact words or expressions. Recorded playback uses longest-match segmentation and concatenates compatible clips. The library supports preview playback, ordering and orphan-file checks. Audio assets can also be distributed as a separate course-specific Audio Pack containing audio_manifest.json and MP3 files. Audio Packs belong to one course and are not part of Export my data; export them separately when you need a backup or want to distribute them.',
        ),
        _HelpSection(
          title: 'Image Bank',
          body:
              'The Image Bank can contain built-in images, imported single images and separate Image Bank ZIP packages. Imports use the fixed folder Documents/QuisquisLingo/Imports/Images and do not open a file picker. For Import single image, keep exactly one PNG, JPG, JPEG or WEBP image in that folder. For Import Image Bank ZIP, keep exactly one ZIP there; the ZIP must contain image_bank_manifest.json and its referenced image assets. Source files are left in place after import. Tap an image to open a larger preview before selecting it; the preview also shows file/category metadata and a Use image action when selection is allowed. Importing a bank does not require recompiling QuisquisLingo. Missing image files are reported rather than silently ignored.',
        ),
        _HelpSection(
          title: 'Lesson theme icons and Preview',
          body:
              'Each Lesson can select one preinstalled theme icon from the visual grid or choose None for the default GuideBook icon. Theme icons cannot be uploaded or entered as arbitrary paths in build 223. Exercise images remain separate Image Bank content. Round Preview and Preview exercise let you test authored content before saving or distributing it.',
        ),
        _HelpSection(
          title: 'Exercise image specifications',
          body:
              'Recommended resolution: 256 × 256 px. Recommended file size: 15 KB or less. Maximum accepted size: 50 KB per image. PNG, JPG/JPEG and WebP are supported.',
        ),
        _HelpSection(
          title: 'New exercise types',
          body:
              'Missing Word plays audio while showing its transcript with one or more words removed. Image Word shows an image and asks the learner to build the corresponding target-language word from letter or syllable blocks. Dialogue Response contains a target-language context sentence, a target-language question and exactly two target-language response options; their display order is randomized. Word Match uses exactly three source-to-target translation pairs. Super Match uses exactly three target-language pairs and an explicit relationship such as synonyms or opposites. Audio Match uses three target-language audio items with exactly three matching texts and no distractors; the matching text may be in the target language or a translation. Listening Spelling plays target-language audio, shows the transcript with a missing word and requires keyboard input; Return/Enter submits. Sentence Word Order exercises may use 0, 1 or at most 2 distractors. Image Word letter/syllable composition never uses distractors: include only the blocks required for the answer. Gap Choice shows a target-language sentence with one missing element and asks the learner to choose the single block that is correct in both meaning and grammar. The standard sample round length is 15 exercises.',
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
              'Enter the complete sentence in Passage transcript and Audio text. Put the word that QuisquisLingo should hide in Missing word. Do not type dots or underscore characters into the transcript: the learner screen creates the gap automatically.',
        ),
        _HelpSection(
          title: 'Lesson Guidebook',
          body:
              'Each Lesson has its own Guidebook, available to learners from the Lesson page. It can contain vocabulary, example sentences, explanations and other learning material. The editor can use its vocabulary and examples to propose new exercises.',
        ),
        _HelpSection(
          title: 'Course metadata and authors',
          body:
              'Course info is always available, even while the course content is locked. It lets you change the visible Course name while keeping the Course ID unchanged. The Lock protects structural/content editing such as Lessons and exercises; it does not block course metadata editing. The Course ID identifies the course internally and remains read-only. Source language and Target language are also read-only for now. Course info can store multiple human authors, and each author can have more than one role. Course Creator means the person created the course or a substantial part of its original structure/content. Editor means the person maintains or substantially revises existing content over time. Contributor means a specific or limited contribution without creating or maintaining the course as a whole. Team Leader coordinates the team and may also hold another role. Reviewer checks content, Native Speaker contributes language-quality review, and Audio Contributor provides course audio. Custom role text is available for other contributions. Roles describe contributions, not hierarchy. Course metadata can also record language variant, starting level, target level, course version, last-updated date, course description and an optional support URL. Course-content licensing is separate from the MPL-2.0 software license.',
        ),
        _HelpSection(
          title: 'Audit severity and codes',
          body:
              'Course Audit reports Errors, Warnings and Suggestions. An Error identifies content that violates an editor rule and should be corrected. A Warning identifies content that may be valid but needs review. A Suggestion recommends an improvement. Each rule can have a stable audit code such as ROUND_DUPLICATE_CONTENT, OPPOSITE_TOO_EARLY or SINGLE_WORD_CASE. The code identifies the rule even if its explanatory text changes or is translated. A Lesson with fewer than 25 actual eligible Duel exercises has an unavailable Duel; this is informational author feedback and does not block saving, importing or exporting. When reporting an Audit problem, include the code and, when possible, the Lesson, Round and Exercise. Preview exercises while authoring and run Course Audit before distributing a course.',
        ),
        _HelpSection(
          title: 'Course Audit',
          body:
              'Course Audit checks structural and authoring problems such as invalid exercise fields, duplicate IDs, Word Block problems, missing audio mappings and Missing Word errors. It does not certify grammar, translation accuracy or pedagogical quality.',
        ),

        _HelpSection(
          title: 'Create a new course',
          body:
              'Course Editor can create an independent Course Model v5 project from scratch. Enter the course title, source language, target language and optional author. QuisquisLingo creates stable technical IDs automatically and starts with 3 placeholder Lessons, each with a stable Lesson-scoped Duel identity. No Rounds are created automatically when a course is created; add them explicitly when you are ready to build the Lesson. Every Round created manually contains three dummy exercises ready to edit. User-created courses are stored separately from the Current bundled course and its local overrides. When creating a course, choose one of QuisquisLingo’s built-in flags or import a PNG/JPG flag. Imported flags are checked for file size and resolution and resized safely while preserving proportions. Custom courses can be imported from and exported to portable QuisquisLingo JSON files. To import, place the file at Documents/QuisquisLingo/Exports/import.json and press Import course JSON; the course is then added under My custom courses.',
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
            'Work in progress. These pages describe the Course Model v5 implementation separately from the practical Editor instructions.',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('QuisquisLingo Course Model v5'),
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

class CourseModelV4HelpScreen extends StatelessWidget {
  const CourseModelV4HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => _TechnicalPage(
    title: 'QuisquisLingo Course Model v5',
    sections: const [
      _HelpSection(
        title: 'Status',
        body:
            'Work in progress. QuisquisLingo uses formatVersion 5 as its native course model.',
      ),
      _HelpSection(
        title: 'Hierarchy',
        body:
            'Course > Lesson > Guidebook + Round > Content. Every Lesson owns its Guidebook and Duel. Exercise is one Content kind rather than the only object allowed inside a Round.',
      ),
      _HelpSection(
        title: 'Content',
        body:
            'Current v4 kinds include exercise, presentation, explanation, example, vocabulary, text and dialogue. Content has a stable ID and can be required for normal completion. Presentation Content can be interactive without producing a correct/incorrect result.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson Guidebook is structured Content rather than a single monolithic block. Its vocabulary, examples and explanations are learner reference material and can also act as source material for the three-Round generator and sourceRefs.',
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
            'Work in progress. The current primitive set is the implemented Course Model v5 baseline.',
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
        body: 'Work in progress. QuisquisLingo writes formatVersion: 5.',
      ),
      _HelpSection(
        title: 'Root',
        body:
            'The root contains formatVersion, Course metadata and lessons[]. New bundled samples and user-created courses are native v5 files.',
      ),
      _HelpSection(
        title: 'Guidebook',
        body:
            'Each Lesson contains guidebook.content[] with structured Content such as explanation, vocabulary and example entries.',
      ),
      _HelpSection(
        title: 'Lesson and Round',
        body:
            'A Lesson contains lessonId, title, optional Section and themeIconAsset metadata, guidebook, rounds[] and its Duel identity. The obsolete decorative Lesson imageAsset field is rejected. Round contains id, title, visualType and content[]. The first Content of Round 1 may be a non-exercise lesson_intro drawn from the Lesson Guidebook.',
      ),
      _HelpSection(
        title: 'Exercise Content',
        body:
            'Exercise Content stores editorTemplate plus exercise.prompt[], exercise.interaction and exercise.evaluation. Correctness uses stable Item IDs rather than display indexes.',
      ),
      _HelpSection(
        title: 'Duel',
        body:
            'A Lesson serializes a stable Duel ID and title. Availability is derived at runtime from the actual Lesson exercise pool under the standard eligibility and deduplication rules; it is not serialized and does not depend on Round count.',
      ),
      _HelpSection(
        title: 'Compatibility',
        body:
            'Bundled and custom courses are native Course Model v5. Older Chapter-based formats are unsupported and are not read, migrated or converted automatically.',
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

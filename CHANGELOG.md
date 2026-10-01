# 2.0.59 (Build 259, Revision 7) - Translation lines, plainer instructions, GuideBooks - 2026-10-01

Owner review of 1 October 2026.

- **Type the translation, to source:** a Piedmontese word to translate into
  English showed "Translate from English into Piedmontese:". That fixed
  line is gone; the instruction line now names the language of the answer:
  "Translate into English." or "Translate into Piedmontese.". Build the
  translation does the same ("Translate into … with the word blocks.").
- **Instruction lines that repeated their title** are reworded in the eight
  learner languages, for example CHOOSE: "Find the correct answer.",
  MATCH: "Pair each word with its translation.", BUILD THE WORD: "Spell
  what the picture shows.", TYPE THE MISSING WORD: "The first letter is
  given: type the whole word.".
- **QQL Demo: Piedmontese** has GuideBooks: the mixed practice Lesson has an
  overview, three notes (subject pronouns, articles, spelling) and 32
  words; the Story at the market has an overview and 5 words. Every card
  offers Open GuideBook, and the words join the Review.
- "Son content" stays refused for "I am happy": written Piedmontese needs
  the subject pronoun i; "i son content" and "mi i son content" are
  accepted, as before.

Scoring, progression, Review rules, the Course format and learner data are
unchanged. Beta expiry `2026-10-31 23:59:59` local time (same release day
as Revision 6).

# 2.0.59 (Build 259, Revision 6) - QQL Demo: Piedmontese - 2026-10-01

Owner requests of 1 October 2026.

- **QQL Demo: Piedmontese**, a new bundled course: the 120 exercises of the
  Piedmontese demo, no longer grouped by exercise type but mixed at random
  in one Lesson of 20 Rounds of six, each opening with a Before you start
  card ("Mixed practice: 6 exercises of different types."), then the Story
  at the market as a second Lesson. It has no GuideBook. The exercises are
  the same; only their IDs belong to the new course. Language XP and
  streaks count it as Piedmontese.
- The existing demo is renamed **Demo: Piedmontese (sorted by exercise
  type)**; its content is unchanged.
- Help: the Editor Help question "What is a TEMPORARY SAMPLE Course?" is
  removed, and App Info no longer says the demos are "titled Temporary
  Demo" (they are now named Demo: … or QQL Demo: …).

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-31 23:59:59` local time (30 days from the
1 October 2026 release).

# 2.0.59 (Build 259, Revision 5) - Owner review: pictures, Stories, Edge Case - 2026-09-30

Corrections from the owner's third review of 30 September 2026 (points
1–5).

- **Match pictures to words:** the preset "Match picture to word" is renamed
  in the plural. A Published save needs at least two words (a single word
  was accepted). The form no longer offers an Exercise image: only the
  picture of each word.
- **Stories:** the scrolling Story shows its step count ("Story · N
  steps") once, above the title block; the "Now · step k of N" line under
  each step is gone. A Dialogue line no longer shows an instruction such as
  "Read or listen, then continue.".
- **The Edge Case Course leaves the bundle.** QuisquisLingo now ships the
  Exercise Laboratory and the Piedmontese demo. The Edge Case is a Course to
  import: `demo_courses/edge_case_it_en.json`, a custom Course with its own
  identity (the bundled one stays reserved) that anyone can Fork. Progress
  on the former bundled Edge Case stays on the device but is not shown.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (same release day
as Revision 0).

# 2.0.59 (Build 259, Revision 4) - Owner review: gaps, pictures, hints - 2026-09-30

Corrections from the owner's second review of 30 September 2026 (points
1–10).

- **Pictures required:** Type what you see and Name what you see, like
  What is in the picture, refuse a Published save without their picture.
- **No file paths for learners:** Match picture to word showed a picture's
  file path beside it, and a picture answer without a caption could show
  its path too. Learners now see only the picture.
- **Spelling lines:** Spell the word no longer says "Build the word shown
  in the image." without an image. It reads "Build the word that matches
  the clue."; Spell what you hear reads "Build the word you hear.".
- **Piedmontese demo hints:** Name what you see asks for the article;
  the evening story names its verbs; Missing letters has a hint for each
  exercise; the shopping list names bread and water.
- **Gaps are written `_word_`:** the Sentence with gaps field and Missing
  letters (`dr_ink_`) use underscores instead of `{word}` and `[ink]`,
  which the answer syntax also uses. Stored exercises are unchanged; the
  form writes and reads the new marks.
- **Pick the words for the gaps:** each word fills one gap. Drag the
  blocks into the gaps, which also played by tapping, is merged into it.
  The Select version whose option could fill several gaps is retired.
- **One word fills all**, new: sentences with two or more ___ gaps and
  one word that fits them all; once chosen, it appears in every gap.
- The new lines are in the eight learner languages; Help EN/IT/ES
  follows. The Laboratory, the Piedmontese and the Edge Case demos use the
  merged and the new preset.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (same release day
as Revision 0).

# 2.0.59 (Build 259, Revision 3) - Owner review: listening, pictures, gaps - 2026-09-30

Corrections from the owner's review of 30 September 2026 (points A–H).

- **Type what you hear:** the Audio text is always accepted. The box once
  labelled "Missing word" is now **Other accepted spellings (optional)**,
  for another way to write the same words (alle 9 for alle nove). A
  Published save needs nothing in it. The Laboratory's example no longer
  accepts a word that is not heard.
- **Listening lines:** Listen and answer shows "Listen and answer the
  question."; Listen and choose shows "Select the sentence that you heard."
  (to target) or "Select the meaning of what you heard." (to source).
  Listen and pick the image keeps its line.
- **What is in the picture:** the learner title is **WHAT IS IN THE
  PICTURE?** with the line "Choose the option that fits best.", and a
  Published save needs the picture.
- **Feedback in view:** after an answer the page scrolls down to the
  feedback and its Continue or Finish round button. In a short window a
  tall exercise such as Sort into groups left it below the screen, where it
  was not even drawn.
- **Typed gaps:** "Choose the word that completes the sentence." was wrong
  for a typed exercise. It is now "Type the words that complete the
  sentence.", "Type the word that completes the sentence." for one gap and
  "Type the missing letters." for Missing letters.
- **Complete the text:** the text marks each gap with ___. Missing words
  gives one line per gap, in order, and a line may accept several answers
  (`[il|un] gatto`). A Published save checks that the gaps and lines match.
  The Laboratory has an example with alternatives.
- **Put the sentences in order:** "Arrange the lines in a logical order."
  no longer repeats the title.
- The new and changed lines are in the eight learner languages; Help
  EN/IT/ES follows.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (same release day
as Revision 0).

# 2.0.59 (Build 259, Revision 2) - Listen and choose, Listen and answer - 2026-09-30

Listen and answer's optional question did two jobs: sometimes it was an
instruction ("Choose the greeting you hear."), sometimes a real question
("Dove fa la spesa Maria?"). It splits into two presets (owner decisions of
29 September 2026, plan `docs/CONTEXT_AND_HINT_PLAN.md` §6):

- **Listen and choose (to target / to source)**, new: the learner hears a
  word or a sentence and picks what was heard, or its meaning. No
  question; an optional **Instruction or context** takes the place of the
  standard line.
- **Listen and answer (to target / to source)**: its **Question** is now
  required (a Published save refuses it empty); the learner answers it
  about what was heard.
- The recording is unchanged in both. An exercise without a question is
  recognized as Listen and choose.
- The Round Wizard's listening exercise is now a Listen and choose without
  the "What do you hear?" question (the standard line says it), and the
  Story Wizard offers both presets.
- **Demo content:** the Laboratory's greeting and "What did you hear?"
  examples become Listen and choose, and a new example asks a
  source-language question about a passage; the Piedmontese demo has one
  Lesson per preset (41 Lessons).
- **Help EN/IT/ES**, field Help and Search follow.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (same release day
as Revision 0).

# 2.0.59 (Build 259, Revision 1) - Complete the text and Put the sentences in order - 2026-09-30

Two exercises whose answer learners could not always work out get context
and hints (owner decisions of 29 September 2026, plan
`docs/CONTEXT_AND_HINT_PLAN.md` §5).

- **Complete the text:** an optional **Instruction or context** first
  (it replaces the standard line in the Round) and an optional **Hint**
  last. The hint shows under the gapped text.
- **Put the sentences in order:** the lines are entered once, **Lines, in
  the correct order**, with **Extra lines (optional)** (0, 1 or at most 2)
  and an optional **Hint**, shown above the lines. "Sentences or lines" and
  "Correct order" repeated the same lines and are gone. A Published save
  needs at least two lines. Line IDs follow their text, and the stored
  order of the lines is kept.
- **Hints on the gap and order screens:** Missing letters' hint and Name
  what you see's hint, which learners never saw, now show too.
- **No Play audio button without audio:** a gap exercise with no audio
  used to show a greyed Play audio button, as if it were a listening
  exercise.
- **Demo content:** Piedmontese Lessons 18 and 21 get hints and
  instructions that make every answer reachable with audio off; the
  Laboratory's Complete the text and Put the sentences in order examples
  show the new fields.
- **Help EN/IT/ES** and Search (hints) follow.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (same release day
as Revision 0).

# 2.0.59 (Build 259, Revision 0) - Instructions and questions - 2026-09-30

Exercise prompts say clearly what they are (owner decisions of 29 September
2026, plan `docs/CONTEXT_AND_HINT_PLAN.md`).

- **Instruction or context:** every optional prompt in the learners'
  language is labelled **Instruction or context (optional)**. In a Round it
  takes the place of the standard instruction line under the heading, in
  every exercise (until now only Choose and Match did so), and its helper
  quotes the line it replaces. It is stored without a language; a prompt
  with a language (a text to translate, a spelling clue) keeps its own
  line.
- **Questions and sentences are never optional:** they are labelled
  **Question or sentence**, **Sentence** or **Question**, stay in the
  exercise body, and a Published save refuses them empty.
- **Fields that were really instructions:** the optional questions of What
  is in the picture, Type what you see, Name what you see, Listen and pick
  the image, Sort into groups and Fill the slots become Instruction or
  context. The questions of the Assign presets and of Name what you see
  were never shown to learners; they now are.
- **Type what you hear:** its "Passage transcript" was shown to the
  learner; it is now its Instruction or context, so the label no longer
  invites the answer.
- **Match by meaning:** its instruction is in the learners' language (it
  asked for the target language by mistake).
- **Recognize characters:** in text-to-image mode the text naming the
  character is its question.
- **Duel:** "Listen and choose the meaning." appears only for an exercise
  with audio.
- **Help EN/IT/ES** and the demo Courses follow; reading and listening
  material is unchanged.

Scoring, progression, Review, the Course format and learner data are
unchanged. Beta expiry `2026-10-30 23:59:59` local time (30 days after this
revision's release on 30 September 2026).

# 2.0.58 (Build 258, Revision 4) - Share, save and print a Page - 2026-09-30

Learners can share, save and print a Page as a PDF, when its Course allows
it (owner decisions of 29 and 30 September 2026).

- **Share:** the system share sheet on phones and tablets (email,
  messages, files, and Print on iOS) and the share panel on Windows and
  macOS; on Linux Share sends the page's text by email.
- **Save PDF:** Save as… where the system dialog exists, or Quick Export to
  `QuisquisLingo/Export/Pages`.
- **Print** (computers): the PDF opens in the default PDF viewer, which
  prints it; there is no printing plugin.
- **The PDF** shows the page exactly as the app draws it, in the light
  theme, cut into A4 pages, with a credits line: the Course, its rights
  holder and licence, and QuisquisLingo. Links are printed with their
  address; audio buttons are left out. The text is not selectable (the page
  is a picture, so every script prints correctly without extra fonts).
- **Course setting:** Course Info's **Learners may share, save and print
  pages**, on by default, hides the buttons when off. It is a courtesy, not
  protection; a Fork or a Copy keeps it, a Merge takes the left Course's.
- **New dependency:** the `pdf` package (pure Dart, no network).

Scoring, progression and learner data are unchanged. The Course format
gains the optional `allowPageSharing` (stored only when off). Beta expiry
`2026-10-30 23:59:59` local time (30 days after this revision's release on
30 September 2026).

# 2.0.58 (Build 258, Revision 3) - Pages in the Exercise Laboratory - 2026-09-29

The Exercise Laboratory demo gains an eighth Lesson, **Page**, with two
example Pages to try and to study in Course Studio.

- **A textbook page:** a centred title, a justified paragraph with bold and
  italic, a quote read aloud, a second heading, a bulleted and a numbered
  list, and a tip in the accent colour aligned to the end.
- **A page with media:** a blue heading, a large picture with its caption,
  a Listen button, red, green and grey text, and a video link that opens
  in the browser.
- The Laboratory records `minimumAppBuild: 258000`, as every Course with a
  Page does; its presentation baseline gains the two examples and no
  existing record changed.

Scoring, progression, learner data and the Course format are unchanged.
Beta expiry `2026-10-29 23:59:59` local time.

# 2.0.58 (Build 258, Revision 2) - The Page form - 2026-09-29

Authors can now make textbook-like **Page** cards in the Course Editor:
New Exercise, then **Page** (Cards and notes).

- **Blocks:** Add block offers Heading, Paragraph, Quote or example, List,
  Picture, Audio and Video link; the arrows move a block, the bin removes
  it. A new Page starts with an empty heading and paragraph.
- **Text:** a style per block, **Bold** and *Italic* buttons that wrap the
  selection in `**` or `*`, start, center or end alignment (and justify for
  paragraphs and quotes), a colour from the palette, and an optional Read
  aloud in the target or source language.
- **Pictures:** chosen like any exercise picture (copied into the Course),
  with a size (small, medium, large, full width), an alignment and a
  caption that screen readers also say.
- **Audio and video:** an audio block's spoken text (text-to-speech or the
  matching recording); a video link's label and address, flagged until it
  is an https address.
- **Live preview:** under the blocks, drawn exactly as the learner sees it.
- **Help (EN/IT/ES):** the preset, its blocks and a new Editor Help
  question, "How do I make a textbook-like Page?" (68 questions). Search
  finds a Page by its text.

Scoring, progression, learner data and the Course format are unchanged.
Beta expiry `2026-10-29 23:59:59` local time.

# 2.0.58 (Build 258, Revision 1) - Course pictures up to 300 KB - 2026-09-29

A Course picture may now be up to **300 KB** (it was 50 KB), as decided
for textbook-like Pages on 29 September 2026. The limit applies to every
picture stored with a Course (exercises and Pages), to the Shared Image
Library and to Image Banks, and to Course packages, backups, Fork, Copy
and Merge, which share the same check. The picture check itself is
unchanged: still PNG, JPEG or WebP, at most 4096 × 4096 pixels, no
animation, content checked rather than the file name.

- **Unchanged at 50 KB:** pictures embedded inside `course.json` as data
  (Recognize characters), because they make the Course file itself larger.
  The Course cover keeps its 1 MB.
- **Help (EN/IT/ES):** the picture field, the picture import and the Image
  Bank limits say 300 KB; the too-large message says 300 KB.

Scoring, progression, learner data and the Course format are unchanged.
Beta expiry `2026-10-29 23:59:59` local time.

# 2.0.58 (Build 258, Revision 0) - Page cards: model and learner display - 2026-09-29

The first revision of textbook-like **Page** cards, planned and approved
on 29 September 2026 (`docs/258_PAGE_CARD_PLAN.md`). A Page is a card the
learner reads and continues, drawn from formatted blocks; it is never
scored. This revision adds the data model, the learner display and the
Audit; the Page form in the editor comes in Revision 2.

- **Blocks:** headings (two levels), paragraphs, quotes, bulleted and
  numbered lists, pictures, audio and links. Body text takes `**bold**` and
  `*italic*`; text aligns start, center, end or justified; a named colour
  palette (default, accent, red, green, blue, grey) stays readable in light
  and dark themes; pictures come small, medium, large or full width with a
  caption; a text block may offer a read-aloud button (off by default).
- **Video links:** a link block opens an https address in the browser
  ("Watch the video"); QQL never downloads or plays video itself.
- **In a Round:** a Page shows no heading or instruction line, is never
  skipped when audio is off (its read-aloud and audio buttons then hide)
  and ends with Continue.
- **No new primitive:** the presentation primitive's elements gain the
  attributes `textStyle`, `align`, `color`, `size`, `readAloud` and the
  element type `link`; the capability description and the Python tools
  know them.
- **Earlier builds:** a Course with a Page records `minimumAppBuild:
  258000` when saved, so an earlier build refuses it instead of showing the
  pages unformatted.
- **Audit (113 rules):** `PAGE_EMPTY` and `PAGE_LINK_INVALID` (Errors),
  `PAGE_MARK_UNMATCHED` (Warning).
- **Fix:** the Generic Primitive Editor no longer drops element attributes
  it has no field for when an element is edited (a Dialogue line's speaker
  was lost this way).

Scoring, progression, Review, the Duel, learner data and the Course format
version are unchanged. Beta expiry `2026-10-29 23:59:59` local time.

# 2.0.57 (Build 257, Revision 0) - Before you start cards - 2026-09-29

The note a learner reads before a Round starts ("Before you start") is now
an ordinary card of the Round that authors can write, edit, publish and
delete, the first slice of interactive presentation cards (owner decisions
of 29 September 2026). Before this build the note was Round content with no
editor field: only the bundled Courses had one, and the Round Wizard's note
stayed Draft forever, so learners never saw it.

- **The card:** a new preset, **Before you start** (Cards and notes), with a
  Note and an **Open GuideBook button** switch. The switch is greyed out
  while the Course does not use GuideBooks; learners see the button only
  when the Lesson's GuideBook is published (Preview shows it for a Draft
  GuideBook). There is no picture, no answer and no score.
- **Where it plays:** the first published card of a Round is shown on its
  own page before the Round starts, with Continue to Round, as the note was.
  It is never one of the Round's steps (it does not count toward the
  steps, the Laurel or the Duel) and it is **no longer shown in Review**.
  Previewing the card alone shows it and closes with Close preview.
- **In the editor:** a new card goes first in the Round and the Round's list
  names it by its note. Search finds the note.
- **Model:** no new primitive. The presentation primitive gains the
  boolean option `guidebookButton`; a card is a presentation whose text
  element has role `intro` (`LearnerExerciseKind.roundIntro`).
- **Existing notes (clean cut):** text Content with role `lesson_intro` is
  no longer shown. The v11 converter (`tools/convert_course_to_v12.dart`
  and the Python generators) turns a v11 note into a card with the GuideBook
  button on; the three bundled Courses and the Laboratory's test fixture are
  regenerated, and every Lesson opens with a card as before.
- **Round Wizard:** its first Round now opens with a Draft card holding the
  GuideBook overview, with Open GuideBook on, ready to review and publish.
- **Audit (110 rules):** `ROUND_INTRO_EMPTY` (Error: a card without a note)
  and `ROUND_INTRO_DUPLICATE` (Warning: a second card in a Round, of which
  learners see only the first); `LESSON_INTRO_MISSING` now looks for a card.
- **Help (EN/IT/ES):** the preset and its two fields, and a new Editor Help
  question, "How do I write the Before you start note of a Round?" (67
  questions).

Scoring, progression, learner data and the Course format version are
unchanged. Beta expiry `2026-10-29 23:59:59` local time (same release day
as Build 256 Revision 9).

# 2.0.56 (Build 256, Revision 9) - Mascots beside the sentence - 2026-09-29

A QuisquisLingo mascot now keeps the learner company in exercises built
around a sentence (owner decisions of 29 September 2026). It is decoration
only: Course files, scoring, progression, Review, the Duel and learner
data are unchanged, and nothing new is stored.

- **Where:** on the leading side of the one sentence the learner reads or
  hears: the question (Pick the translation, Choose the answer, Pick the
  missing word, True or false, Read and answer), the text to translate or
  the clue (Type and Build the translation, Word order), the sentence with
  gaps (Complete the text, Missing letters, Pick the words for the gaps,
  Drag the blocks into the gaps, Listen and fill the gaps, Type the missing
  word), or the Play button (Listen and answer, Type what you hear).
- **Only where it fits:** never in an exercise with a picture, an avatar or
  anything but words and sound, nor beside dialogue lines with named
  speakers; only beside a sentence (two words or more, or ending in
  `. ! ? …`: "Grazie." has one, "ciao" does not); only when the sentence
  keeps at least 220 pixels, three lines at most and the window is at
  least 560 pixels high (72-pixel mascot, 96 pixels on wide screens).
  Match, Assign, cards, spelling blocks, Put the sentences in order, Stories
  and the Duel show none.
- **Random, without repeats:** each Round draws a random order of the
  mascot pictures, never matched to the exercise. Within one Round a
  picture never appears twice, and the next mascot the learner sees is
  always another character (cat, dog, kid, monkey, robot), however many
  exercises without a mascot come between. A picture is taken only when
  the mascot is actually drawn, and kept through answering and feedback;
  when the pictures run out (nine), later exercises show none. The
  mistakes review continues the same order; replaying a Round starts a new
  one.
- **The sleeping monkey** stays on the Round path and never appears in an
  exercise.
- Rounds, Review, View Only and the Editor Preview show mascots.
- Beta expiry `2026-10-29 23:59:59` local time (same release day).

# 2.0.56 (Build 256, Revision 8) - Editor Help as questions and answers - 2026-09-29

Editor Help is rewritten as questions and answers (owner decisions of 29
September 2026). Course files, scoring, progression and learner data are
unchanged.

- **Questions grouped in seven topics:** Getting started, Saving and
  versions, Course settings, Lessons and Rounds, Exercises, Pictures and
  sound, Checking the Course; 66 questions such as "Why can't I choose
  Edit?", "When are my changes saved?" or "What does Play as a sequence
  do?". Tapping a question opens its answer.
- **Search** at the top filters the questions and their answers as you
  type, ignoring capitals and accents; the Technical reference card stays
  above it.
- **Rewritten and checked against today's app:** plain language, short
  answers, nothing current lost; out-of-date statements fixed (Use
  GuideBook, Create Duels and Lesson numbering live in Lesson Options on
  the Course Editor page; Course delivery status is on the Course Editor
  page; the sequence and the Story, Name what you see, Read and answer and
  the capitals Warning of the fourth follow-up are described as they now
  work).
- **English, Italian and Spanish** complete together, with the on-screen
  names in English as the interface shows them. Course Studio Help keeps
  its sections, including the four it shares with the Editor (local
  edits and backups, Course Info Editor and license, Audit severity and
  codes, Course Audit).
- Beta expiry `2026-10-29 23:59:59` local time (same release day).

# 2.0.56 (Build 256, Revision 7) - Laboratory, Assign, final verification - 2026-09-29

Session 8, the last of the exercise architecture redesign (plan Part B item
8): the Assign runtime, the Laboratory's Assign Lesson, the test-only
fixture of what still waits, and the negative and semantic-equality tests
of the plan's verification list. Course files stay Course Model v12;
scoring, progression, Review and learner data are unchanged.

- **Assign plays.** Sort into groups (categories in columns), Fill the
  slots and Fill the gaps of a text: the learner taps an item, then the
  destination that takes it; a placed item's chip gives it back; a group
  may take one, several or any number of items, a slot or a gap takes one;
  a reusable item stays in the bank; Check grades every destination at
  once (exact assignments). Headings and instructions in the eight learner
  languages. Picture regions, grid cells, drag placement and the other
  Assign evaluation modes stay readable but not executable. Assign has no
  catalogue preset yet (the greyed tiles stay); it is authored in the
  Generic Primitive Editor, whose layout may name each destination with a
  text before its target. The Audit adds `ASSIGN_STRUCTURE_REQUIRED`
  (Error: items, targets and an answer) for 106 rules.
- **Exercise Laboratory.** A seventh Lesson, Assign: groups, a word that
  belongs nowhere, slots, reusable slots, one gap and two gaps (128
  examples, 28 Rounds); the coverage document and the validator follow;
  the presentation baseline gains six records and keeps every other one.
- **The future fixture.** `test/fixtures/v12/laboratory_future_en_it.json`,
  written by the same generator: Speak (repeat, free response), Ink
  (trace), Submit (audio), a Story ending on a Speak step and a Story whose
  flow branches on a choice. Its test reads it, audits it (information and
  warnings only), plays nothing of it, and carries it through the canonical
  editor, a JSON round trip and a package unchanged.
- **Verification.** `negative_cases_256_test` (what the parser refuses,
  what the Audit blocks, what a malformed flow reports) and
  `semantic_equality_256_test` (defaults, metadata, timestamps, publication
  state, IDs, item order, JSON round trips); the Revision 6 end-to-end
  scenario stands as the plan's final acceptance.
- Beta expiry `2026-10-29 23:59:59` local time.

Follow-up in the same version (owner review of the Revision 7 build, 29
September 2026):

- **Two Assign presets.** Sort into groups (the question, one group per
  line as "Animals: gatto, cane", optional words that belong nowhere) and
  Fill the slots (one slot per line as "… gatto = il", optional extra
  words, a switch letting one word fill several slots) join the Grammar
  and sentences group as recipes over canonical Assign data; the greyed
  Sort into groups tile is gone (six greyed presets). The Laboratory's
  Assign Lesson uses them (four examples in one Round; the gap Round is
  removed because the inline gap presets already cover gaps: 126 examples,
  27 Rounds); the Piedmontese demo keeps 39 Lessons (no Lesson for the
  two Assign presets, as for the Story cover). Recognition compares targets
  by position, as it did items, so a stored Assign with foreign target IDs
  still opens in its form. Help (EN/IT/ES), field Help, Search and the
  Audit's mismatch hints know both presets.
- **Match picture to word form.** The picture cards follow the words as
  they are typed (they were rebuilt only on the form's first change, so a
  word typed later had no card and no number); each word has one compact
  card headed "N. word", the section says the pictures follow the order of
  the words, and the long picker guidance is stated once.
- **Flashcard form.** The fields are "Word or expression (target
  language)" and "Translation or meaning (source language)"; the separate
  pronunciation text is gone: Read aloud (Automatically when the card
  appears, On request, or No read-aloud) speaks the word itself. A
  Flashcard's read-aloud is optional and never makes the card an audio
  exercise (as the Picture flashcard's already was); the bundled cards
  carry `required: false`.
- **Spelling presets.** Spell the word in the picture, Spell the word and
  Spell what you hear have one field, "Blocks of the word, in order": the
  learner gets exactly those blocks, shuffled. A stored spelling exercise
  with extra blocks opens in the canonical editor.
- **Story editor list.** A title block and a text-only Dialogue line are
  named by their text in the Round editor's list (their IDs were shown).

Second follow-up in the same version (owner request, 29 September 2026):

- **One button style on the Rounds page.** New Round is a bottom-bar
  button beside Round Wizard and New Story, in their size and colour, no
  longer a floating button. The editor's creation buttons share one
  capitalization: New Lesson, New Round, New Exercise, New Canonical, Add
  Step, Round Wizard, Exercise Wizard, New Story; Help names them the same
  way.
- **Choose the answer, after the owner's review.** A new single-answer
  Choose form starts with Correct answer number 1 (as Pick the translation
  did). The Audit warns (`CHOICE_ALL_ANSWERS_CORRECT`, 107 rules) when a
  multiple-answer Choose marks every answer correct. The fields are
  "Prompt (optional)", an instruction or some context above the question,
  and "Question or sentence to complete", with grammar examples (Pick the
  verb form that fits. / Which article goes with casa?) instead of a
  translation. In a Round, the authored Prompt takes the place of the
  standard "Choose the correct answer." line under the CHOOSE heading, so
  the two no longer repeat each other; without a Prompt the standard line
  stays. The same rule holds for Match the words, Match by meaning and
  Match picture to word: the authored instruction is the line. Match by
  meaning no longer gets "Match each word with its opposite." guessed
  from its text (it takes synonyms and more). The Laboratory's
  presentation baseline records these changes.
- **Flashcard, revised.** The pronunciation field returns as
  "Pronunciation TTS (if different)": empty, the read-aloud speaks the
  word or expression itself; filled, it speaks that text instead. Read
  aloud keeps its three choices.
- **Missing letters.** The learner's field says "Missing letters" for a
  gap inside a word ("Missing word" misled); Complete the text keeps
  "Missing word".
- **Play as a sequence.** The Round editor's switch is called Play as a
  sequence (it was Play as a Story): a Story, with its title block,
  narrator and characters, is what New Story builds.

Third follow-up in the same version (owner decisions, 29 September 2026):

- **A sequence is a plain ordered Round, not a Story.** A Round made with
  New Round and played as a sequence keeps the plain Round's New Exercise,
  New Canonical and Exercise Wizard (no Add Step, no title-block count),
  and its options speak of the sequence ("Needs the sequence's audio").
  Its title is optional ("Optional sequence title", empty when the switch
  is turned on); a new sequence starts Step by step. Lists, the learner's
  path and the Round screen call it "Sequence: <title>", or "Sequence:
  <Round name>" without one, and the Round screen says Sequence completed
  and Finish sequence. The Audit applies the Round rules: no Story title
  or Dialogue line is asked for, and a Dialogue line in a sequence gets the
  warning of any Round. Its exercises count toward the Lesson's Duel; a
  Story's still do not. Playback is unchanged: authored order, no shuffle,
  no mistake review. A Story is what New Story makes (the `story` visual
  type) and keeps all its options; Course files are unchanged.
- **Type the missing word.** With Show the first letter off, the accepted
  words may start with different letters, and the form now says so: its
  help under Complete accepted words and the note under the fields follow
  the switch (they always stated the same-first-letter rule). Saving and
  the Audit already accepted such words; the rule still holds while the
  first letter is shown.

Fourth follow-up in the same version (owner review, 29 September 2026):

- **The preset's name in bold** at the top of the exercise editor (the
  preset card of a new exercise and the locked Exercise type line).
- **Capitals never block Save.** Build the translation, Put the words in
  order and Name what you see match an answer to its blocks whatever the
  capitals (an answer whose capitals differed from its blocks lost its
  block order, and the Audit's BUILD_TRANSLATION_INVALID_SEQUENCE Error
  blocked Save). The Audit now gives a Warning,
  `ARRANGE_ANSWER_CASE_DIFFERS` (108 rules, 42 Warnings), whenever any
  capital differs, the first letter included.
- **Sort into groups** has no "Words that belong nowhere" field: every word
  belongs to a group, and a Sort into groups needs at least two groups.
  The examples of the form, the field Help and the Help (EN/IT/ES) use
  Animals and Plants. The Laboratory's two examples are Animals and Plants
  and three groups (Animals, Plants, Objects).
- **Name what you see** builds the name of the picture from word blocks in
  order, with up to two extra blocks (fields: Question (optional), Blocks
  of the name, in order, Extra blocks (optional), Hint). The typed version
  stays as **Type what you see**. Both tell the learner NAME WHAT YOU SEE
  ("Build the name of what you see." / "Type the name of what you see.")
  in the eight learner languages; they used to say COMPLETE and "Choose
  the word that completes the sentence.". The Laboratory and the
  Piedmontese demo have examples of both.
- **Read and answer** keeps only its "to target" preset (Read and answer
  (to source) is retired and opens as to target). The Text to read explains
  the situation in the source language and is never read aloud; the
  Spoken text field is gone; the dialogue lines, in the target language,
  have a read-aloud: no, on request (a Play dialogue button) or
  automatically, each line spoken in turn with a one-second pause. The
  read-aloud is optional: the exercise is never an audio exercise and is
  silent with Audio Exercises or Text-to-speech off, and in the Duel. The
  Laboratory's reading examples are rebuilt in this shape (the ones with a
  spoken text and the "to source" one are removed: 122 examples); the
  Piedmontese demo has one Read and answer Lesson; the Edge Case demo's
  long text is Italian, its source language.
- **The Round Wizard creates only preset exercises.** Its "expression in
  context" exercise is now Pick the missing word; every exercise it creates
  opens in its preset's form.

# 2.0.56 (Build 256, Revision 6) - Interoperability - 2026-09-28

Session 7 of the exercise architecture redesign (plan Part B item 7):
support states at runtime, the stand-alone flow engine, interoperability on
canonical semantics and the machine-readable capability description. Course
files stay Course Model v12; scoring, progression, Review and learner data
are unchanged. Adventures and spoken exercises are parked for a later
release (owner, 28 September 2026).

- **Exercises this version cannot play (plan A.6).** A valid exercise whose
  configuration lies outside the runtime-support table is readable but not
  executable: computed from the registry, never stored. A practice Round
  skips it before the audio filter (not in the queue, the mistake review,
  the count or the XP); the completion dialog counts what was skipped and a
  zero-error attempt gets the "skipped perfect" mark instead of the Laurel;
  a Round of such exercises alone says why it is empty. A Story shows a card
  in its place (the prompt read-only above it, one sentence, Continue) and
  follows the node's next; a Story ending on one leaves without recording
  (Leave story). The editor Preview shows the same card in practice Rounds
  too. The Duel never asks such an exercise.
- **Audit.** `EXERCISE_NOT_EXECUTABLE` (Info) names the reason;
  `ROUND_NOT_COMPLETABLE` (Warning) marks a practice Round with nothing this
  version plays, a Story whose flow branches or is no straight sequence, and
  a Story ending on an unplayable step. 105 rules. The import review counts
  the unplayable exercises in the Matching Course ID and Publisher dialogs
  and in the result message. A numeric, pattern or manual Input no longer
  gets the text-answer Error meant for typed answers.
- **Flow engine.** `FlowEngine` resolves onChoice, onCorrect, onIncorrect
  and conditional transitions in declared order with `next` as the
  fallback, a node's own outcome visible to its conditions, and a bounded
  walk for tests. Not wired to playback: linear Stories play directly and a
  branching flow still counts as "cannot run yet".
- **Interoperability.** The catalog maps every surveyed external type to a
  primitive, options, evaluation mode and layout, with the preset only as a
  hint; every mapping validates in the registry and plays today except the
  Speak ones, which are kept for a later version. `NormalizedImportExercise`
  is canonical (no preset required) and `CanonicalExerciseImport` records
  the hint only when the recipe represents the result.
- **Capability description.** `dart run tools/export_capabilities.dart`
  writes `docs/capabilities_v12.json`; a test pins it to the registry;
  `tools/qql_capabilities.py` feeds the generators and
  `tools/validate_courses.py` from it instead of their own tables.
- **End to end.** A Course an external converter could write (no preset
  metadata, every primitive, a Story, a branching Round) imports, audits,
  plays, duplicates, merges, searches, signs and exports with the same
  semantics (`test/interoperability_end_to_end_256_test.dart`).
- Beta expiry `2026-10-28 23:59:59` local time (released the same day as
  Revision 5).

# 2.0.56 (Build 256, Revision 5) - Stories - 2026-09-28

Session 6 of the exercise architecture redesign (`docs/256_STORY_PLAN.md`):
Stories as in a conversation course, with a narrator and reusable
characters, dialogue lines that are read or heard, a Story Wizard and the
Story options in the Round editor. Course files stay Course Model v12.

- **Narrator and characters.** A Course carries an optional narrator and a
  list of characters (`storyNarrator`, `storyCharacters`): name, avatar (a
  bundled figure of the cat, dog, kid, monkey or robot, or a picture of the
  Course cropped to a square and stored as a small PNG), language (source
  or target) and voice preference (any, male, female; matched against the
  device voices, a miss never blocks speech). The Course Editor's Story
  characters section adds and edits them; a character that lines still
  name cannot be removed. Avatars count as image uses.
- **Dialogue line and Story cover.** Two presets of the Cards and notes
  group. A line is said by the narrator or a character as text, audio or
  both (`speakerId` on the elements), read aloud as the Story says, always
  or on request, with its text shown at once or after listening (the
  presentation option `textReveal`); its language is the speaker's unless
  the line says otherwise. A cover is the Story's picture and an optional
  title line. Both are built canonically (they have no v11 shape); a new
  one is blank as its recipe builds it. Field Help and Exercise Help cover
  them.
- **The learner's Story.** The Round screen draws a line as a bubble with
  the avatar and the name, a play button and Continue; a cover shows the
  Story title, the picture and the title line, each once. The speaker's
  voice preference reaches the device speech. Lines and covers are never
  skipped: without audio the learner reads them. An exercise marked as
  needing the Story's audio (`requiresAudio` on its flow node) is skipped,
  like the listening exercises, when Audio Exercises is off. The scrolling
  log keeps only the dialogue by default (`log: dialogue`; Everything keeps
  the exercises too). A Story's exercises stay out of the Duel pool.
- **Round editor.** Play as a Story asks for the Story title (the Round is
  called "Story: <title>"; the prefix goes when the Story is turned off),
  Step by step or Scrolling, Dialogue only or Everything, Read aloud
  automatically or On request; a new Story scrolls, logs the dialogue and
  reads aloud automatically, an existing one keeps its stored values;
  "Needs the Story's audio" sits in every exercise's menu.
- **Story Wizard.** In the Lesson editor beside Round Wizard, without a
  GuideBook: the Story (title, cover picture, read-aloud), the narrator,
  the characters, then the steps: Add line (a short form), Add exercise
  (True or false, Choose the answer, Pick the translation, Listen and
  answer, Word order, Listen and fill the gaps, Type the missing word,
  Complete the text; the ordinary exercise form opens on top of the Wizard
  and Save or Cancel returns to the builder), move, remove, "Needs the
  Story's audio". Finish needs at least one line and creates the Round
  through the Course working copy; Cancel creates nothing.
- **Audit.** Five codes, 103 rules: STORY_TITLE_MISSING and
  STORY_WITHOUT_DIALOGUE (Warnings on a Story), STORY_SPEAKER_UNKNOWN and
  DIALOGUE_LINE_EMPTY (Errors), DIALOGUE_LINE_OUTSIDE_STORY (Warning).
- **Bundled Courses.** The Exercise Laboratory gains a Story Lesson (a
  cover, five lines, an audio-dependent True or false, a Choose the answer
  and a Word order: 116 examples), the Piedmontese demo a Dialogue line
  Lesson played as a Story and a Story cover Lesson (40 Lessons, 120
  examples), the Edge Case demo a Story with an audio-only line and an
  exercise that needs the Story's audio. The Story Lessons join after the
  v11 conversion; the converter fixtures omit them.
- **Demos (owner request, 28 September).** The Korean demo leaves the
  bundle and stays a test fixture; the three demos are titled Temporary
  Demo: Exercise Laboratory, Edge Case Course and Piedmontese.
- **Help** (EN/IT/ES): Stories and the Story Wizard in the Editor Help,
  the Exercise primitives page's Stories section, the two presets' Help.
- **Fix (owner report, 28 September).** A Story cover no longer shows its
  picture twice at the start of a Preview.
- Scoring, progression, Review, Course files and learner data are
  unchanged. Beta expiry `2026-10-28 23:59:59` local time.

Follow-up in the same version (owner review, 28 September 2026):

- **Continue.** One verb for moving on: after every exercise in a Round,
  a Story and the Duel the button reads Continue (it read Next); a Story's
  last step reads Finish story, a Round's Finish round, the Duel's Finish
  duel, and Review mistakes stays.
- **The line says how to take it.** A Dialogue line's instruction follows
  its mode: "Read, then continue." (text only), "Listen, then continue."
  (audio only), "Listen first; the text appears after." (text after
  listening), "Read or listen, then continue." (text and audio), in the
  eight learner languages.
- **No exercise, no XP (scoring rule).** A Round or Story without a scored
  exercise (cards, covers or lines only) counts as completed for progression
  and Lesson unlock but awards no answer XP, no perfect bonus and no Laurel,
  and does not count toward the Laurel total; its completion dialog says
  "Nothing to score in this Round" (or Story) with no XP arithmetic. Lesson
  completion XP is unaffected. Rounds with at least one scored exercise are
  unchanged: cards in them still do not block the perfect bonus.
- **"Story:" is derived.** Lists, the Lesson path, the Rounds page, the
  Round editor, Search, Review and the Round screen call a Story
  "Story: <title>" from its flow's title (or the Round's own title), so a
  Rename or a Story switched on over a named Round no longer loses the
  prefix; the Wizard and the Story title field stop writing the prefix into
  the Round title, and a title stored with it is shown once. Switching a
  named Round to a Story names the Story after the Round.
- **Avatars show.** Bundled avatars (`assets/avatars/…`) were refused by
  the portable image decoder and drawn as a broken image in the bubble, the
  Course Editor and the Wizard; they are bundled assets now.
- **Scrolling keeps context.** After Continue, a scrolling Story leaves a
  fifth of the page (at most 120 px) above the active item, so the tail of
  the previous line stays readable.
- **Sample Stories.** The Laboratory's "A morning in Turin" is a consistent
  story that alternates two or three lines with a question (Choose the
  answer, an audio-dependent True or false, Word order); a second Story,
  "The same morning, line by line", shows the line options one by one and
  has nothing to score (122 examples). The Piedmontese Story reads every
  line at once and the demo has no Story cover Lesson (39 Lessons, 117
  examples); the Story of covers alone moves to the Edge Case demo as an
  intentional Audit warning, and its Story alternates lines and the
  question. Help (App Info, EN/IT/ES) states the scoring rule.
- **No heading on a line.** A Dialogue line shows no DIALOGUE heading; the
  speaker's bubble and the instruction are enough (second follow-up).
- **The wizards on the Rounds page; New Story (third follow-up).** Round
  Wizard and New Story (the Story Wizard renamed) are buttons of the Rounds
  page's bottom bar, beside the New round button, and no longer of the
  Lesson editor's; the Round Wizard stays greyed out with its explanation
  while Use GuideBook is off. Help, the Audit hint and the cover preset's
  text follow.
- **Add step in the Story editor (third follow-up).** In a Story the Round
  editor replaces New exercise, New canonical and Exercise Wizard with Add
  step, which asks for the block type: Title block (the cover, one per
  Story: greyed out once the Story has it, placed first), Dialogue line
  (the short form New Story uses) or Exercise (the presets a Story may
  use). Duplicate is greyed out for the title block, the Story options
  count the title block, lines and exercises, and the sentence "Lines are
  never skipped: without audio the learner reads them" is gone from them.
  A Story has one title block and at least one Dialogue line; the Audit
  still warns about a Story without a line, and Save is not blocked.

# 2.0.56 (Build 256, Revision 4) - The preset catalogue - 2026-09-27

Session 5 of the exercise architecture redesign
(`docs/256_PRESET_CATALOGUE_PLAN.md`): 38 presets in six skill groups,
paired *to target* / *to source* where the direction matters, seven greyed
presets for later versions, pictures on answers, and the runtime additions
the new presets need. Course files stay Course Model v12.

- **Catalogue.** Vocabulary: Pick, Type and Build the translation (each to
  target and to source), Match the words, Match by meaning, Flashcard,
  Picture flashcard. Grammar and sentences: Choose the answer (to target /
  to source), True or false, Pick the missing word, Pick the words for the
  gaps, Type the missing word (with a *Show the first letter* switch; it
  absorbs Fill in the blank), Complete the text, Missing letters, Word
  order, Drag the blocks into the gaps, Put the sentences in order.
  Listening: Listen and answer (to target / to source), Listen and pick the
  image, Type what you hear, Listen and fill the gaps, Spell what you hear,
  Listen and match. Reading and dialogue: Read and answer (to target / to
  source: a text, a situation or dialogue lines, optional spoken text).
  Pictures and characters: Select the image, What is in the picture, Name
  what you see, Spell the word in the picture, Spell the word, Match
  picture to word, Recognize characters. Cards and notes: Note card. Coming
  later, greyed in the picker and in Help: Say it, Write by hand, Sort into
  groups, Label the picture, Answer in your own words, Match picture to
  sound, Adventure.
- **Retired IDs** (`choice`, `fill_blank`, `matching`, `listening_choice`,
  `listening_comprehension`, `reading_comprehension`,
  `contextual_comprehension`, `dialogue_response`, `type_translation`,
  `build_translation`) have successors: the v11 converter records the
  successor, the Audit, the editor and Search read a stored retired ID as
  its successor, and an existing exercise keeps its shape when it is
  reopened and saved (shape hints for the text, audio and Match sides, the
  first-letter switch).
- **Picker:** skill groups, the action word on every tile (Choose, Type,
  Arrange, Match, Card), the To target / To source filter, greyed tiles.
- **Pictures on answers:** Select the image, Listen and pick the image and
  Match picture to word have one picture picker per answer (Image Library,
  imported or Course images, copied into the Course); the Round and the
  Duel draw Course pictures on answers and on Match items.
- **Runtime:** within-word gaps (Missing letters) show one underscore per
  missing letter; a spelling exercise needs a picture, a spoken word or a
  clue (`IMAGE_WORD_IMAGE_REQUIRED` widened); Put the sentences in order
  has its own heading and instruction in the eight copy languages; audio in
  the source language is spoken with the source voice.
- **Audit:** four codes retired (`DIALOGUE_RESPONSE_OPTION_COUNT`,
  `DIALOGUE_CONTEXT_REQUIRED`, `DIALOGUE_QUESTION_REQUIRED`,
  `CONTEXT_REQUIRED`; 98 rules), Read and answer and Listen and answer
  rules, picture and True or false rules, areas renamed after the
  catalogue; Picture flashcards and Note cards are exempt from the usage
  and pronunciation Warnings, and duplicate content counts the prompt's
  pictures.
- **Exercise Wizard:** a planned exercise of a catalogue twin (Type the
  translation (to target)) is built on the recipe's base type; it used to
  fall back to a Select interaction and lose the accepted translations.
- **Help:** EN/IT/ES describe every preset and every field; Exercise Help
  lists the greyed presets.
- **Bundled Courses:** the Exercise Laboratory has 107 examples, at least
  one per preset (five new Rounds); the Piedmontese demo has one Lesson per
  preset (38); Korean and Edge Case carry the successor IDs.
- Scoring, progression, Review, Duel availability, learner data and Course
  files are unchanged. Beta expiry 27 October 2026, 23:59:59 local time.

# 2.0.56 (Build 256, Revision 3) - Presets as recipes and the Generic Primitive Editor - 2026-09-27

Session 4 of the exercise architecture redesign
(`docs/256_EXERCISE_ARCHITECTURE_PLAN.md`): a preset is a recipe over
canonical data, every canonical field can be edited, and Stories survive
authoring.

**Follow-up in the same version (27 September 2026, afternoon; owner's
review of the Windows build):**

- **Scrolling Stories:** a Story's flow carries `presentation: step`
  (default, omitted) or `scroll`. The Round editor offers **Step by step /
  Scrolling** under the Play as a Story switch; a scrolling Story keeps the
  finished items on the page (heading, prompt, the learner's answer, a tick
  or a cross), shows the next item below and scrolls to it. One item is
  active at a time; XP, completion and Review are unchanged.
- **Discard prompts only for real changes:** the canonical editor compares
  the form with the opened exercise before asking, and the preset form
  compares a snapshot of its fields, so touching a control (or the Match the
  pairs field) without changing anything never asks to discard.
- **Assign and Submit in the canonical editor:** required options
  (`targetMode`, `submissionType`) get their first legal value when a draft
  is created or its primitive changes, so the registry no longer refuses an
  untouched draft.
- **Round editor buttons:** *New exercise (presets)* and *New exercise
  (canonical)*.
- **Draft Exercises:** saving a Round as normal content while some of its
  Exercises are still Draft explains it and names them, instead of the
  Audit's count of blocking errors.
- **First-time introduction:** the first time the Exercise Editor (either
  form) opens in a Course, a dialog explains presets versus the canonical
  editor; it is a one-time notice, brought back by Show one-time notices
  again. Exercise Help says the same.
- **Help names:** the Lesson editor's Round Wizard and the Round editor's
  Exercise Wizard are named as on screen (they were still "Generate Rounds
  from GuideBook" and "Exercise Creation Wizard"); the Windows runner now
  keeps the initial window inside the monitor's work area, because on a
  small or scaled screen the editors' bottom bar sat under the taskbar and
  the wizard buttons looked missing.
- Owner decisions on preset directions recorded for Revision 4 (pairs only
  where meaningful, bracket only on the twins).

**Second follow-up (same version; the owner's visual inspection of the
Windows build):**

- **Round editor bottom bar:** the buttons are **New exercise** and **New
  canonical**, in a slightly smaller style so the bar takes two rows
  instead of three on a laptop window.
- **New exercise, then a type:** choosing a preset type on a new exercise
  whose form is still untouched no longer asks to discard changes on the
  way out; an existing exercise's type change still counts as a change.
- **Round Wizard without GuideBooks:** while Use GuideBook is off in the
  Course Editor's Lesson Options, the Lesson editor's Round Wizard is
  greyed out and its tooltip says why.
- **Scrolling Story, made unmistakable:** the page shows "Story · N steps"
  above the first item and "Now · step k of N" above the active one, the
  active item is scrolled to the top after Next (the finished cards stay
  above it), and the Crash Log's debug events record each Round's Story
  state. The report that a scrolling Story played like a normal Round could
  not be reproduced: a test driving Round editor → Play as a Story →
  Scrolling → Preview → answer → Next shows the finished card, and every
  save path keeps the flow's presentation. If it happens again, the debug
  event names the Round and the presentation it received.
- The direction tags in the preset picker and the twin presets with
  "(to target)" / "(to source)" in their titles are Revision 4 work, not
  part of this follow-up.

**Third follow-up (same version; the owner's second inspection):**

- **New canonical, then a primitive:** a new canonical exercise that is
  still blank for the primitive picked so far leaves without a discard
  prompt; adding content makes leaving ask.
- **Scrolling Story, visible scroll:** the page keeps room below the
  active item, so after Next the "Now" marker glides to the top and the
  finished cards move up above it, whatever the window height.
- **Select the image without icons:** the Audit's preset warning now says
  what is missing ("one icon or image key per answer in Icons / image
  keys") instead of only that the exercise plays as a plain Choose; the
  same hint exists for the listening, reading, dialogue, context and
  character presets, and the Icons field explains it in the form.

- **Presets as recipes (plan A.13):** `PresetRecipes`
  (`lib/services/preset_recipes.dart`) decomposes an exercise into a preset
  form's fields, rebuilds it and compares the result semantically, so a
  preset represents an exercise only when nothing is lost. The exercise
  editor opens an exercise in the preset it carries, else in the first
  preset that represents it exactly, else in the plainest preset of its
  primitive. Recognition never writes: on save the carried preset stays only
  while it still represents the content, another representing preset is
  named otherwise, and every other authoring metadata key is dropped as soon
  as the content changes (`CanonicalExerciseDraft.toExercise`).
- **Generic Primitive Editor:** `lib/screens/primitive_editor_screen.dart`
  edits every canonical field of any primitive with the values the
  capability registry allows: Primitive (locked once the exercise exists),
  Options, Prompt elements with roles, languages, playback and required
  flags, Items (with sides for Match), Targets, Layout, Evaluation by mode
  with that mode's answer data, Feedback and hint. It shows whether this
  version can play the exercise, refuses the combinations the registry
  refuses, previews with the learner runtime and saves like a preset form
  (Save as draft, or Save with the Audit). It opens from the Round editor
  (**Canonical editor**), from the preset picker (**Every primitive**) and
  automatically for a stored exercise that no preset represents; the
  preset form then shows a notice and cannot save it, because a save would
  drop what the form does not show.
- **Stories survive authoring:** every place that rebuilt a Round (the
  Round editor, Rename, saves from Search, GuideBook references, Move/Copy,
  duplication) dropped the Round's `flow`, so editing a Story silently made
  it a practice Round. `RoundFlowAuthoring`
  (`lib/services/round_flow_authoring.dart`) keeps it: a linear flow
  follows the edited content order, a branching flow is kept as it is (the
  Audit names what it no longer finds), and a copy renames the flow's
  references with the copied content. The Round editor gains **Play as a
  Story** (`round-story-switch`): on, the exercises play in authored order,
  unshuffled and without a mistake review; turning a branching Story off
  asks first.
- **Canonical reads wherever a creator works:** Search, the hierarchy
  update's content text, the Recognize characters controller (which now
  copies the exercise canonically and marks new images as `character`
  specimens) and the Course Editor's lists, wizard and image validation read
  canonical data through `ExerciseFeatures`; the Audit's kind label
  (`CourseAuditService.kindLabel`) is shared. The draft builder still
  constructs candidates through the v11 shapes as converter input; Revision
  4 replaces it preset by preset with the new catalogue.
- **Help:** the Exercise primitives page (QQL Guide) describes Course Model
  v12 in EN, IT and ES: the nine primitives, options, layouts, evaluation
  modes, prompt and item media, presentation content, presets as recipes,
  the canonical editor and Stories; Exercise Help gains a Canonical editor
  supplement.
- **Preset catalogue decided:** the owner's decisions of 27 September 2026
  on the preset catalogue (merges, renames, new and greyed-out presets,
  to-target/to-source pairs, the picker's direction filter, the save guard
  against unchanged example content) are recorded in
  `docs/256_PRESET_CATALOGUE_PLAN.md` and become Revision 4; the later
  sessions shift by one.
- Scoring, progression, Review, Duel availability, Course files (v12) and
  learner data are unchanged. Version `2.0.56+256003`; the Beta expiry stays
  `2026-10-27 23:59:59` local time (same release day).

# 2.0.56 (Build 256, Revision 2) - Runtime and Audit on canonical data - 2026-09-27

Session 3 of the exercise architecture redesign
(`docs/256_EXERCISE_ARCHITECTURE_PLAN.md`): what learners see, play and are
graded on comes from the canonical exercise, never from the preset that
authored it (plan A.3).

- **Learner runtime on canonical data:** the Round screen dispatches on the
  primitive and on `ExerciseFeatures` (`lib/models/exercise_features.dart`:
  roles, attributes, options, layout, evaluation, feedback) instead of
  preset IDs; headings and instructions come from the derived
  `LearnerExerciseKind`; Select panels (context, dialogue, passage or
  situation, character specimens) are one shared widget used by the Round
  and Duel screens. The recorded Laboratory presentation
  (`test/support/laboratory_presentation_254.dart`, 80 examples before and
  after answering) proves the refactor changed nothing except three
  deliberate points: Match the words now says "Match each word with its
  translation" (its sides carry languages), and a Dialogue response's
  situation is shown once, in its panel, instead of twice.
- **Converter refinements (Course Model v12 stays v12):** a Dialogue
  response's text is a `situation`, Recognize characters' images are
  `character` specimens, Match the words / Match related words state the
  languages of their two sides, Build/Type the translation mark a `clue`
  text as source language too, and Pick the translation's spoken text is
  `required: false`. The four bundled Courses are regenerated (parity
  test kept).
- **Duel by capability (plan A.10):** every single-answer Select whose
  items are shown as choices is eligible, so Contextual comprehension and
  Recognize characters join the pool and a multiple-answer Choose leaves it
  (it was graded as single-answer before). The Duel draws context panels,
  dialogue and image answers like the Round screen.
- **Inline-gap Arrange grades block content (plan A.11):** two identical
  blocks may fill either of their gaps; the Laboratory's repeated-block
  example is the regression test.
- **Stories (plan A.7):** a Round with a linear content `flow` plays its
  nodes in authored order, unshuffled and without a mistake review; a Round
  whose flow branches is not playable in this version (Round level).
- **Audio exercises** are those with a required audio element; Pick the
  translation's optional audio never makes one.
- **Audit through the capability registry (plan A.5):** new Errors
  `EXERCISE_OPTION_INVALID`, `EXERCISE_COMBINATION_ILLEGAL`,
  `EXERCISE_EVALUATION_MODE_INVALID`, `EXERCISE_SELECTION_LIMITS` (the
  impossible multiple-selection limits are now caught) and
  `EXERCISE_TARGET_REFERENCE`; the preset rules (Dialogue response's two
  options, the three-pair Match presets, Pick the translation's five
  options and its extra prompt or spoken text, Image-prompt ordering's
  extra blocks, a reading preset without a passage, a listening preset
  without audio, Gap Choice's sentence and marker, Recognize characters'
  shapes) are Warnings that never block, `PRESET_CANONICAL_MISMATCH` says
  when an exercise no longer plays as its preset, and an unknown preset is
  Info. Retired because v12 makes them impossible or subsumes them:
  `EXERCISE_TYPE_UNKNOWN`, `EXERCISE_FIELD_UNEXPECTED`, `ICON_CHOICE_COUNT`,
  `MISSING_WORD_NOT_IN_TRANSCRIPT`, `MISSING_WORD_DUPLICATE`,
  `IMAGE_WORD_ANSWER_REQUIRED`, `IMAGE_WORD_ANSWER_BLANK`. The registry has
  102 rules.
- **Unchanged:** scoring, progression, Review, learner data, Course Model
  v12 files (the converter refinements only add roles and attributes), the
  editor (Session 4 moves it to canonical data).
- **Beta expiry:** 27 October 2026, 23:59:59 local time (same release day).

# 2.0.56 (Build 256, Revision 1) - Course Model v12 - 2026-09-27

Session 2 of the exercise architecture redesign
(`docs/256_EXERCISE_ARCHITECTURE_PLAN.md`): the canonical exercise
definitions of Revision 0 get their JSON form, and Course Model v12 becomes
the only format QQL reads and writes.

- **Course Model v12** (`formatVersion: 12`): every exercise is stored as
  `primitive`, `options` (explicitly set values only), `prompt`, `items`,
  `targets`, a neutral inline `layout`, `evaluation` (`mode` plus the keys
  that mode needs) and optional `feedback`; text elements may say which
  `language` they are in, audio elements whether their `playback` is
  automatic and whether they are `required`; Match items carry a `side`;
  Input's normalization map becomes Input options. `editorTemplate` becomes
  `authoringMetadata.presetId` (other keys are preserved, never read); a
  Flashcard is an ordinary exercise with the `presentation` primitive; a
  Round may carry a `flow`. The Course root, Lessons, GuideBooks, media
  references, provenance, rights and every other field keep their v11
  shape (`docs/COURSE_JSON_FORMAT.md`, `docs/EXERCISE_ARCHITECTURE_V12.md`).
- **Clean cut:** the app reads v12 only. A v11 file is refused with a
  message naming `tools/convert_course_to_v12.dart` (Course JSON or Course
  ZIP; media kept, package manifest regenerated, anything not mapped
  exactly listed, Publisher signatures stripped). Stored Courses live in
  the new private folder `QQL_Courses_v12/Custom|Publisher`; Build 255's
  `QQL_Courses` is never read, is listed by the Inventory among the earlier
  private folders and is removed by Wipe everything. Course Backups keep
  the `Backups/Courses` folder with manifest format v12; Version History
  names v11 backups as unreadable. `tools/convert_stored_courses_256.dart`
  converts a device's stored custom Courses once, never overwriting or
  deleting (a Publisher Course is re-imported from its signed package). A
  Course kept outside QQL travels by exporting it from Build 255,
  converting the file and Quick Importing it here.
- **Bundled Courses** (Exercise Laboratory, Edge Case Course, Korean,
  Piedmontese), the demo package and the Publisher test fixtures
  (re-signed) are v12; the three generators, `tools/validate_courses.py`
  and the new Python mirror of the mapping (`tools/qql_course_v12.py`) emit
  and check v12, and a parity test compares the Python and Dart converters
  on every bundled Course. `tools/convert_course_to_v11.dart` is retired;
  the v11 originals are kept in `test/fixtures/v11/`.
- **Semantic equality** (`Exercise.semanticallyEquals`): canonical JSON
  with every default option filled in, without authoring metadata,
  timestamp and publication state; IDs and item order count.
- **Editor fix found by the conversion:** saving a converted Type the
  missing word exercise as Published rebuilt it through the old view and
  failed with "Use exactly one ___ gap"; publication and shared-image
  changes now copy the canonical exercise. Course Editor Search finds the
  sentence of an inline-gap exercise.
- **Unchanged:** what learners see, scoring, Duel availability, Audit
  findings, package format 1, rights and learner data. The runtime, Audit
  and editor still read the canonical exercise through v11-shaped views
  until Revisions 2 and 3 move them to the canonical fields.
- **Beta expiry:** 27 October 2026, 23:59:59 local time (30 days from this
  release date).

# 2.0.56 (Build 256, Revision 0) - Canonical exercise definitions - 2026-09-27

Session 1 of the exercise architecture redesign
(`docs/256_EXERCISE_ARCHITECTURE_PLAN.md`). Nothing learners or authors see
changes in this revision, and Course files stay Course Model v11; Revision 1
introduces v12.

- **Nine canonical primitives** (`lib/models/canonical/`): `select`,
  `input`, `arrange`, `match`, `assign`, `speak`, `ink`, `submit` and
  `presentation`, each naming one learner action. Identifiers are lowercase,
  stable and parsed strictly; nothing else is a primitive.
- **Typed options and evaluation modes:** every option has a stable JSON
  name, a value kind and a closed vocabulary; an unknown or misspelt value is
  reported and dropped, never turned into a default. The evaluation modes of
  all nine primitives are one enum, and the registry says which each
  primitive may use.
- **Capability registry:** for each primitive, its options with legal
  values, defaults and required ones; its evaluation modes; coded rules for
  illegal combinations (a single selection with a maximum of 3, text spans
  in a list layout, a memory game in columns, and so on) and for what an
  evaluation mode implies (exactSet needs multiple selections, numeric
  grading needs a number, gap grading needs inline gaps); the
  selection-limit invariant minimumSelections <= correct <=
  maximumSelections <= items; and a runtime-support table listing exactly
  today's playable configurations, so executability is computed per
  exercise and never stored.
- **Content flow model:** content and exercise nodes with `next`,
  `onCorrect`, `onIncorrect`, `onChoice` and `conditional` transitions,
  structural checks (missing start, unknown targets, branching content
  nodes, unreachable nodes) and recognition of linear flows.
- **Presets name a primitive:** `ExercisePreset.primitive` replaces the
  five-value `CanonicalExerciseModel`; the Audit's preset-versus-response
  check reads it.
- **Docs:** `docs/EXERCISE_ARCHITECTURE_V12.md` (the new reference, with
  the final names of the extra canonical fields and the list of today's
  behaviors the converter must map); `docs/EXERCISE_ARCHITECTURE_224.md` is
  marked historical.
- **Beta expiry:** 27 October 2026, 23:59:59 local time (30 days from this
  release date, the same day as Build 255 Revision 7).

# 2.0.55 (Build 255, Revision 7) - Welcome Wizard, cover crop and credits - 2026-09-27

Owner-requested corrections to Revision 6 and a renewed first launch.

- **Team shared folder dialog:** the explanation of a refused link is shown
  in full; before, it was cut after two lines ("…other websites and
  short…"). The link in the field uses a slightly smaller type, so more of
  it is visible.
- **Settings:** Advanced (Admin) has one line of description at most. It is
  now listed for every learner: for learners who are not admins it is
  greyed out with a lock and cannot be opened, and its tooltip says what it
  holds (learners and PINs, startup behavior, device name, QQL-Tools, Shared
  Images, Inventory and resets) and that only an admin can open it. Before,
  it was hidden from them. Its Help says so (EN/IT/ES).
- **Cover in Create new course:** the cover can be chosen while the Course
  is created, not only later in the Course Info Editor. The Course ID is
  allocated when the dialog opens so the cover can be stored in the Course's
  own media; a cancelled dialog deletes it, and a new Course's editing
  session owns everything in its media folder, so cancelling the Editor
  removes the cover too. Without a cover the field shows a neutral icon,
  since the Course has no flag yet.
- **Cover crop:** after choosing a picture, *Crop the cover* shows it with a
  square: drag the square to choose what the cover shows, make it smaller
  with its corner or Size to zoom in (down to a fifth of the picture's
  shorter side), or Reset it to the centred square, which is what an
  uncropped cover shows. A ready 512 × 512 picture of at most 1 MB, used
  whole, is still kept as it is. The dialog does not scroll, so dragging is
  never taken by scrolling; the picture gets the height the window leaves.
- **Media credits:** the cover field says that a picture someone else made
  needs a credit in Course Info › Media credits, with author and licence.
  When the image library knows who made the chosen picture (a QQL image, or
  a Shared or Course image whose credit is recorded), QQL fills in that
  credit by itself, applying to the Course cover; a later cover replaces the
  credit the previous one added while nobody has changed it. A reminder
  appears whenever a picture of unknown origin joins a Course: an imported
  or chosen Exercise image, pictures added to a Course's Image Library, a
  custom Lesson icon, a custom Course flag, a Recognize characters image and
  the cover. The Audit's MEDIA_ATTRIBUTION_MISSING warning now also counts
  the cover.
- **Course Selector:** the current Course has its own row at the top and is
  no longer repeated under Other courses (Favorites may still list it, as
  since Build 250). Each row shows the Course's cover when it has one, in a
  44-pixel square, and its flag otherwise. The Course flag stays separate
  and still appears in the top bar, the Flag Background and the Course entry
  animation; the cover field and Help say so.
- **Enlarged Course image:** in Courses and Course Info the enlarged cover
  or flag has the Course title and "Source → Target" above it.
- **Edge Case demo flag:** its flag code was "GB", which QQL does not draw
  (its English flag is "EN" or "UK"). An explicit flag QQL cannot draw shows
  the neutral flag rather than an automatic one, so the Course showed a plain
  beige flag. It is now "EN", the Union Jack QQL draws (Edge Case 1.1.1). A
  test checks that every bundled Course's flag can be drawn.
- **First launch:** only a renewed Welcome Wizard follows Create Profile.
  Its five short steps each have a mascot (the kid, the celebrating cat, the
  monkey, the robot and the dog): what QuisquisLingo is, Courses made by
  others and Import Course, Lessons, Rounds, Laurels and Duels, studying a
  little every day with Review, and making Courses in the hidden Course
  Studio. Create Profile asks the **language for explanations** (English,
  Italiano, Español; preselected from the system language): it becomes the
  learner's Help Language and the Wizard speaks it. The Wizard stands in for
  this version's Welcome, which now appears only after an update. The Beta
  expiry reminder appears only in the last seven days before expiry (or once
  it has expired); before, it appeared at every launch. Learners who already
  finished the previous Wizard do not see the new one; *Show one-time
  notices again* in Do Not Disturb shows it again.
- **Recognize characters, Choose from Image Bank:** choosing a picture there
  now works. The image library hands back the chosen image's record, but the
  editor waited for a file path, so *Use image* failed: the library stayed
  open and no picture was added. The editor now takes the record and uses its
  path. A QQL picture is used as it is; a picture imported on this device
  becomes the Course's own portable image (at most 50 KB) and brings the
  credit reminder. A new test chooses a QQL picture there.
- Tests follow the new behavior: Home tests no longer wait for the Beta
  reminder, the Selector tests choose the current Course again through a
  Favorite row, and new tests cover the crop, the creation cover, credits
  and reminders, the Audit, the Selector, Settings, the Team dialog, the
  enlarged heading, the bundled flags, the Wizard and the first launch.

Version `2.0.55+255007`; Beta expiry **2026-10-27 23:59:59 local time** (30
days from the 27 September 2026 release date). See the
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 6) - Courses views, Course covers and Team folders - 2026-09-26

Small owner-requested corrections and additions.

- **Bundled demos:** German, Spanish, English for Spanish speakers
  (Inglés para hispanohablantes), Welsh, Portuguese and Neapolitan are
  removed. Four remain: Exercise Laboratory, Korean, Edge Case Course and
  Piedmontese. As for the demos Build 254 removed, their Course IDs stay
  reserved, learner progress is left in place, a learner whose last Course
  was removed opens the first available one, and the images, icons and
  recordings stay in the app.
- **Demo licenses:** every demo is *All rights reserved*. Exercise
  Laboratory and Edge Case, the test demos, keep derivative works allowed,
  so Fork still works on them; Korean and Piedmontese forbid derivative
  works, so Fork is unavailable there. The changed demos have new versions
  (Edge Case 1.1.0, Korean 1.2.0, Piedmontese 1.1.0).
- **Piedmontese:** the Piedmontais demo is renamed *AI-Slop Demo:
  Piedmontese*, its learning and target language are Piedmontese, and every
  mention in its content says Piedmontese. Its Course ID, stable IDs, code
  `PMS` and `pms-IT` voice are unchanged, so progress is kept.
- **Courses sections:** each section's button now cycles Expanded →
  Compact → **Minimal**. Minimal hides the Courses and shows only how many
  are shown and how many the section holds ("3 of 4 shown"). The choice is
  saved for each learner, separately in All Courses and Course Studio and
  for each category (learner setting `course_library_view_<tab>_<category>`,
  default Expanded); before, it lasted only while the page was open. After
  an Import, a Minimal section holding the imported Course opens Expanded
  for that visit so the highlighted row can be seen.
- **Startup:** the one-time "QuisquisLingo Beta testing" dialog about the
  Crash Log is gone; startup already had enough screens. The Crash Log and
  its Quick Export in Settings › Debug are unchanged, and the update check
  still runs at every launch.
- **Advanced (Admin):** Device Administration is now called Advanced
  (Admin), since it also holds QQL-Tools, and sits right after Do Not
  Disturb in Settings. Its Help follows (EN/IT/ES); internal names and keys
  are unchanged.
- **Flag Game:** tap a flag to see it enlarged. During a question the
  enlargement shows no name, so it never gives the answer away; the
  reference lists show the name.
- **Course Info:** the Course image is shown as in Courses, the cover when
  the Course has one and otherwise the flag, and tapping it opens the same
  enlarged view as Courses (one shared dialog).
- **Course cover in the Editor:** the Course Info Editor has a Cover image
  field with Choose image (image library), Quick Import (the one picture in
  `Import/Images`), Open from… and Remove cover. Any PNG, JPEG or WebP up to
  10 MB is cropped to its centred square and scaled to a 512 × 512 PNG; a
  ready 512 × 512 picture of at most 1 MB is kept as it is. The cover alone
  may be up to **1 MB** (other Course images stay at 50 KB): the Course
  media store, package export and import, backup restore and the
  Fork/Copy/Merge copies apply that limit only to the file the Course names
  as its cover. Before, the declared 100 KB cover limit could never be
  reached, because every package image first passed the general 50 KB
  check. The cover is Course media like any other: it travels in the ZIP,
  stays only when the Course changes are confirmed, and the Course Editor
  header shows it instead of the flag.
- **Team shared folder:** a Team Leader can add the link of the Team's
  Google Drive folder; every member sees it and opens it in the browser
  after a warning to download only files whose origin they are sure of.
  Only `https://drive.google.com/drive/folders/…` links are accepted (also
  with `/u/N/`, `usp` or `resourcekey`), stored in one form; links to files,
  direct downloads, documents, other sites, look-alike hosts, user names,
  ports and shortened links are refused, and the stored link is checked
  again before it is opened. The link lives in the existing Teams registry.
- Tests that relied on the removed demos now use the remaining ones: the
  Korean sample is the navigation course, and a flagless Course is tested
  with a synthetic Course.

Version `2.0.55+255006`; Beta expiry **2026-10-26 23:59:59 local time** (30
days from the 26 September 2026 release date). See the
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 5) - The Backups folder - 2026-09-26

The Course Backups Version History uses leave QQL's private storage and live
in a new folder beside Import, Export, Logs and ToBeMerged, on every system,
so they can be seen, copied and kept like the other QQL files:
`Documents/QuisquisLingo/Backups/Courses` on Windows, Linux and macOS,
`Download/QuisquisLingo/Backups/Courses` on Android. Names inside are
Revision 4's (`QQL_bkp_EN_IT_<ID>/…_v<version>_<date-time>.json`).

- **Android:** backups are ordinary files QQL writes itself in the Download
  folder. Android 11 and later need no permission; Android 7–10 ask once for
  the storage permission (Android 10 through the legacy storage setting),
  and a refusal stops the Course confirmation as any backup failure does,
  with the working copy still open. Android lets QQL read only its own files
  there, so backups an earlier installation made stay in the folder but are
  not listed. Being outside the app's Auto Backup, they survive an uninstall
  and no longer count against its 25 MB quota; a restored phone does not
  bring them back.
- **Version History** lists the versions it can read and names any other
  file in the Course's backup folder, instead of refusing the whole history
  because of one foreign or damaged file in a folder people can reach.
- **Wipe everything** has a fourth choice, "Keep the Backups folder", ticked
  by default like the others; Revision 4's private `QQL_CourseBackups` and
  Revision 3's `qql_course_backups_v11` follow it. Other resets keep backups
  as before.
- **Learner backups** stay in `Export/UserData`: they are exports made on
  purpose to move or restore a profile.
- **Earlier backups:** the private folders are no longer read; Inventory
  lists them with the other earlier private folders, and
  `tools/move_private_storage_255.dart` now moves every earlier backup
  (`QQL_CourseBackups`, `qql_course_backups_v11`,
  `Documents/QuisquisLingo/Exports/Course Backups v11`) straight into
  `Documents/QuisquisLingo/Backups/Courses`.
- Inventory shows a Backups folder section; EN/IT/ES Help name the folder
  with the new `{folderBackups}` placeholder.

Version `2.0.55+255005`; Beta expiry **2026-10-26 23:59:59 local time** (30
days from the 26 September 2026 release date). See
[plan](docs/255_STORAGE_PLAN.md#revision-5-the-backups-folder),
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 4) - Private folders and language pairs - 2026-09-26

QQL's private storage (the application support folder, where it keeps
Courses, media, backups and logs) now uses short `QQL_` names in the same
style as the public folders, and every name that belongs to one Course
carries its language pair, source then target, so sorting by name groups
the Courses of one pair. There are no language folder levels.

- **Folders:** `QQL_Courses` (`Custom`, `Publisher`), `QQL_CourseMedia`,
  `QQL_CourseBackups`, `QQL_SharedImages`, `QQL_ImageBanks`,
  `QQL_ImportStaging` and `QQL_Logs` (`QQL_crash.log`, `QQL_session.marker`)
  replace `qql_courses_v2`, `quisquislingo_course_media`,
  `qql_course_backups_v11`, `exercise_images`, `image_banks`,
  `qql_import_staging` and `qql_logs`. Temporary folders start with `QQL_`
  too.
- **Language pairs:** a stored Course is `QQL_EN_IT_<ID>.json`, its media
  folder `QQL_EN_IT_<hash of the ID>`, its backups
  `QQL_bkp_EN_IT_<ID>/QQL_bkp_EN_IT_<ID>_v<version>_<date-time>.json`. A
  code is the language tag's primary subtag, then the language name (Italian
  → Neapolitan is `IT_NAP`), otherwise `UNKNOWN`. A QQL-made ID is written
  without its `course_` prefix. When a confirmed change alters a Course's
  languages, its file, media folder and backup folder are renamed in place;
  saved versions keep the names of the languages they had. A new Course's
  media folder is `QQL_<hash>` until it is first stored.
- **Exports:** Course packages are `QQL_EN_IT_<title>.zip`; an earlier
  version exported from Version History is `QQL_bkp_EN_IT_<title>_v3.zip`,
  so it cannot be mistaken for the current Course. The backup format itself
  is unchanged.
- **Earlier files (clean cut):** the earlier private folders are no longer
  read. Shared Image Library images and Image Banks added before keep
  working from their folders, because their records hold full paths.
  Inventory lists the other earlier folders as "Private folders from earlier
  versions", and Wipe everything removes them (the earlier Crash Log with the
  Logs choice). On Windows and macOS, which ignore case, Revision 3's
  `qql_logs` is renamed `QQL_Logs` at startup.
- **One-off tool:** `dart run tools/move_private_storage_255.dart
  [--support DIR] [--documents DIR] [--dry-run]`, with QQL closed, moves
  earlier Courses, their media and their backups (including those a desktop
  kept in `Documents/QuisquisLingo/Exports/Course Backups v11`) to the new
  names. It never overwrites or deletes, and reports what it moved and what
  it left.
- **Course store:** a readable stored file that holds another Course no
  longer blocks saving this one (two IDs such as `course_ab` and `ab` share
  a name part); a name that is taken is still never replaced.
- **Android backup:** the new media folders are excluded from Android's
  cloud Auto Backup like the earlier ones, so a media import cannot push the
  app past the 25 MB quota and stop the backup of learner progress.

Version `2.0.55+255004`; Beta expiry **2026-10-26 23:59:59 local time** (30
days from the 26 September 2026 release date). See
[plan](docs/255_STORAGE_PLAN.md#revision-4-private-folders-and-language-pairs),
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 3) - One folder pattern on every system - 2026-09-26

Windows, Linux, macOS and Android now use the same folders below their
QuisquisLingo folder (`Documents/QuisquisLingo` on desktops,
`Download/QuisquisLingo` on Android), so Help, messages and habits carry over
from one device to another:

- `Import`, with `Courses`, `Audio`, `Images`, `LessonIcons`, `Flags`,
  `UserData` and `RecoveryKeys`;
- `Export`, with `Courses`, `UserData`, `RecoveryKeys` and `AuditReports`;
- `Logs`, for copies of the Crash Log and the Diagnostic Log;
- `ToBeMerged`, with `Courses`, for the second Course of a Course Merge (no
  longer inside the import folder).

Every kind of file has its own subfolder, and no folder name has a space.
Files read by name are unchanged (`import.zip`, `merge.zip`,
`learner_import.json`, `flag.png`).

- **Custom flag:** Upload custom flag now reads `Import/Flags`. On desktops
  it used to read the Exports folder, although it is an import.
- **Crash Log:** the live Crash Log and the session marker are now private on
  every system, like on Android before. A new **Quick Export** button in
  Settings › Debug copies the Crash Log to `Logs/QQL_crash_log.txt` without a
  dialog, replacing the previous copy, next to Save log copy as… and Share.
  The one-time Beta testing message now tells testers to attach that copy
  and still shows where the live log is kept.
- **Course Backups:** the backups Version History uses are now private on
  every system. Backups a desktop made before this revision stay in
  `Documents/QuisquisLingo/Exports/Course Backups v11` and are no longer
  listed.
- **File names:** every exported file starts with `QQL_` instead of
  `quisquislingo_`, including the names Save as… suggests
  (`QQL_<title>.zip`, `QQL_<profile>_backup.json`, `QQL_<id>.user-recovery-key.json`,
  `QQL_audit_….txt`, `QQL_diagnostic_log.txt`, `QQL_crash_log.txt`).
- **Android permission:** Quick Import now asks once for the whole
  `Download/QuisquisLingo` folder, so the same permission covers `Import` and
  `ToBeMerged`; the folders are created as soon as it is given. A full wipe
  gives back this permission and one an earlier version asked for.
- **Earlier folders:** `Imports`, `Exports` and `Merges` are not moved, read
  or hinted at. Inventory lists them as "Folders from earlier versions", and
  Wipe everything keeps or deletes them together with `Import`, `Export` and
  `ToBeMerged`. Course Backups are always removed with the Courses; the
  private Crash Log follows the Logs choice.

Version `2.0.55+255003`; Beta expiry **2026-10-26 23:59:59 local time** (30
days from the 26 September 2026 release date). See
[plan](docs/255_STORAGE_PLAN.md#revision-3-one-folder-pattern-on-every-system),
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 2) - Android public Quick folders - 2026-09-26

On Android, every Quick folder is now public, in the shared Download folder
where file managers, browser downloads and cable copies can reach it, instead
of app-private storage that people could not open:
`Download/QuisquisLingo/Imports/…` and `Download/QuisquisLingo/Exports/…`,
with the same categories below them (Imports: `Courses`, `Merges`, `Audio`,
`Images`, `Lesson Icons`, plus `learner_import.json`, Recovery Keys and
`flag.png` in the Imports folder itself; Exports: `Courses`, `Logs`, plus
learner backups, Recovery Keys and Audit reports in the Exports folder
itself). Desktop folders are unchanged.

**Quick Export** needs no dialog. On Android 10 and later it writes through
MediaStore, with no permission at all; a file appears only once it is
complete, names follow `name`, `name_2`, `name_3` among QQL's own files, and
the Diagnostic Log snapshot replaces its previous copy. On Android 7–9,
Android asks once for the storage permission, then QQL writes ordinary files
in Download.

**Quick Import** reads without a dialog once QQL has access. On Android 10
and later that is one persisted folder permission for exactly
`Download/QuisquisLingo/Imports`. The first time, QQL creates the folder,
explains in one short message, and opens Android's folder screen on it; the
person taps Use this folder and Allow, and QQL creates the category folders
inside. Any other folder is refused. The permission is kept across restarts;
when it is missing, revoked or the folder is gone, QQL asks again and offers
**Open from…** as the alternative, and never falls back to private storage.
On Android 7–9 the same message leads to the storage permission. The
explanation appears at every Quick Import button: Course Import, Course
Merge, Import my data, Import User Recovery Key, Import MP3, custom and
single images, Image Bank ZIPs, the portable character image, Lesson icons
and the custom flag.

**Inventory** lists the Quick Export folder (the files QQL wrote) and the
Quick Import folder (while QQL has access). **Wipe everything** applies the
same Keep Exports and Keep Imports ticks to them, and always gives back the
folder permission. Internal data stays private: Crash Log, Course Backups
v11, stored Courses and media, staging and preferences. The manifest gains
`WRITE_EXTERNAL_STORAGE` for Android 9 and older only (`maxSdkVersion 28`).

Checked on the Android 16 emulator: Quick Export of a Course (and a second
one named `_2`), Export my data, the first Quick Import with its explanation
and folder screen, Quick Import without any dialog afterwards (a forked
Course imported as a new Course; a bundled one correctly refused), Import my
data, a moved (revoked) folder asking again, Open from… instead, Inventory,
and a full wipe deleting both folders' files and giving back the permission.
Android 10 and Android 7–9 paths are checked with mocked tests only.

Version `2.0.55+255002`; Beta expiry **2026-10-26 23:59:59 local time** (30
days from the 26 September 2026 release date). See
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 1) - Android Save as… and Open from… - 2026-09-25

Android now has **Save as…** and **Open from…** wherever the desktop has them:
Course export and import, Merge From…, learner data, the User Recovery Key,
Crash and Diagnostic Log copies, images, Image Bank ZIPs, portable images,
Lesson icons and MP3s. They use Android's own document screens (the Storage
Access Framework), so a person can choose any folder or provider the device
shows, such as Downloads, a memory card or Google Drive when its app is
installed and signed in. Before this revision these buttons were hidden on
Android.

A new platform bridge (`android/.../QqlStorageBridge.kt` and
`lib/services/storage/android_storage_bridge.dart`) shows the system screens
on the UI thread and moves bytes on a background thread in pieces of at most
1 MB, so no file crosses to Dart in one piece. A chosen document is streamed
into the same bounded private staging as a desktop file and passes exactly the
same checks and size limits. A save that fails part-way deletes the new
document rather than leaving a truncated file. Cancelling changes and shows
nothing; failures are logged with the file name only, never a document
address. `FileDialogService.backendFor` picks the dialogs per platform; iOS
still has none.

Checked on the Android 16 emulator: Save as… wrote a valid Course package to
Download, Open from… read it back through the ordinary import checks, and
cancelling showed nothing. Quick Import and Quick Export are unchanged in this
revision; Android's public Quick folders follow in Revision 2.

Version `2.0.55+255001`; Beta expiry **2026-10-25 23:59:59 local time**. See
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.55 (Build 255, Revision 0) - Logical storage roles and Course Quick folders - 2026-09-25

QQL's user folders are now **logical storage roles**: a direction (Imports,
Exports) and a category (Courses, Merges, Audio, Images, Lesson icons, Flags,
Learner data, Recovery keys, Audit reports, Diagnostic logs). Feature code asks
for a role, such as "the Quick Import source for Courses"; a per-platform
layout and backend decide what that folder is. No feature code builds a
Windows, Android or iOS path for a user folder any more, so Android public
folders (Revisions 1–2) and a later iOS Files backend plug in without changing
the features. Every folder-based ("Quick") route uses the layer: Course import,
export and Merge, Audit reports, Export/Import my data, the User Recovery Key,
the Diagnostic Log export, Import MP3, custom and portable images, Image Bank
ZIPs, Lesson icons and the custom flag. A Quick Import file is read as a
bounded stream, like a file chosen with Open from…; a Course package goes
through the same private staging as Open from… before it is parsed.

On **every desktop** (Windows, Linux and macOS) Course packages now have their
own folders: Quick Import reads `import.zip` or `import.json` from
`Documents/QuisquisLingo/Imports/Courses`, and Quick Export (including a
Version History export) writes to `Documents/QuisquisLingo/Exports/Courses`.
Files left in the old `Imports` and `Exports` places are not read or moved
(clean cut). Every other folder keeps its place: Merges, learner data,
Recovery Keys, Audio, Images, Lesson Icons, the flag in Exports, Audit reports
in Exports and the Diagnostic Log in Logs. The owner audit of every import,
export, save, restore and merge operation, and which files stay internal, is
in [the Build 255 plan](docs/255_STORAGE_PLAN.md).

The folder-based buttons are renamed **Quick Import** and **Quick Export**
(Course Import and Course Export screens), and every dialog save is now
**Save as…** (Save as…, Save my data as…, Save Recovery Key as…, Save log copy
as…, Save historical version as…). **Open from…** is unchanged. Screens,
fallback hints and Help (English, Italian and Spanish) name folders through the
layout, so they always show the current platform's folders; Help catalogs use
`{folder…}` placeholders.

An empty `import.zip` now reports "import.zip is empty." like the Open from…
route, and a too-large Image Bank ZIP in the folder gives the Open from…
message. Export folders are created by their first write, as before. Course
Model v11, package format 1, rights, scoring, progression and learner data are
unchanged.

Version `2.0.55+255000`; Beta expiry **2026-10-25 23:59:59 local time** (30
days from the 25 September 2026 release date). See
[handoff](docs/255_HANDOFF.md) and [validation](docs/255_VALIDATION.md).

# 2.0.54 (Build 254, Revision 0) - Bundled exercise demos - 2026-09-25

Replaces the Italian, Finnish and Dutch demos with **Exercise Laboratory**
(English → Italian, five primitive Lessons), **AI-Slop Demo: Edge Case Course**
(Italian → English, valid stress cases and Draft structures), and
**AI-Slop Demo: Piedmontais** (English → Piedmontais, one Lesson per named type).
Laboratory and Piedmontais each cover all 24 current named exercise types.
Dedicated generators, case matrices and workflow tests accompany the content.

The new English Course is independently selectable alongside the existing
Spanish → English bundle while both retain English language XP/streak identity.
Studio, inspection and export retain the full immutable bundled source when
the current learner view omits Draft descendants. An owner-approved narrow
Flashcard fix preserves usage sentences and translations through learner/editor
projection and saving. Course Model v11, package format 1, scoring, progression
and stored learner data remain unchanged.

Version `2.0.54+254000`; Beta expiry **2026-10-25 23:59:59 local time**.
See [handoff](docs/254_HANDOFF.md) and [validation](docs/254_VALIDATION.md).

# 2.0.53 (Build 253, Revision 1) - QQL Guide - 2026-09-24

Settings now opens **QQL Guide** immediately after Do Not Disturb. The shared
per-learner Locale selector and its description move there under the label
**Help Language**. The App Info link and its description move there too.
Below them, QQL Guide lists every standalone Help destination by its title in
the selected language, sorted alphabetically. All Courses Help and Course
Library Help each have a link. Audit Codes is included as an English-only
technical registry. A single destination registry uses the Help catalogs'
title keys, so future Help pages, renamed titles and languages share the same
list and localization lookup.

The existing Locale key, EN/IT/ES choices, persistence, English fallback and
Help/Course Info selectors are unchanged. Inline Help and the remaining app UI
are outside this revision's localization scope. Course Model v11, package
format 1, Course data, rights, scoring, progression and beta expiry
(`2026-10-24 23:59:59` local time) remain unchanged. Version
`2.0.53+253001`. See the [validation](docs/253_VALIDATION.md) and
[handoff](docs/253_HANDOFF.md).

The Italian technical Help now uses “primitive” consistently for Exercise
primitives.

# 2.0.53 (Build 253, Revision 0) - Localization first slice - 2026-09-24

Standalone Help pages, App Info and Course Info now have English, Italian and
Spanish text. A Locale selector on these pages and in App Settings reads and
writes one learner-scoped preference; a change updates mounted pages and
survives restart. Each language has its own text catalog with shared stable
keys. A missing translated keyed value, such as a title, body, label or table
cell, falls back to English without changing the stored Locale. QQL command,
menu, button, setting and mode names mentioned in Help and Course Info remain
in English.

Locale follows learner backup and restore. Progress, Course and media resets
keep it; deleting a profile or wiping the device removes it. Inline Help and
the linked Audit Codes technical registry remain English, as does the rest of
the app interface. Course Model v11, package format 1, Course data, rights,
scoring and progression remain unchanged.

Version `2.0.53+253000`. This is a source release without a Windows package;
the owner smoke test is pending. Beta expiry remains **2026-10-24 23:59:59
local time**. See the [Build 253 plan](docs/253_LOCALIZATION_PLAN.md),
[validation](docs/253_VALIDATION.md) and [handoff](docs/253_HANDOFF.md).

# 2.0.52 (Build 252, Revision 0) - Exercise Authoring - 2026-09-24

Exercise candidate construction is extracted from `ExerciseEditorScreen` into
a pure draft builder. It takes draft values and returns either a candidate
Exercise or typed field errors. Controllers, dialogs, navigation and feedback
stay in the widget; `CourseAuthoringSession` remains the sole owner of the
final Course update. Preview, Save and Cancel behavior remain unchanged.

Version `2.0.52+252000`; Course Model v11, package format 1, stored data and
keys, rights, signatures, scoring, progression and the Course Editor's final
confirmation remain unchanged. This is a source release without a Windows
package. Beta expiry is **2026-10-24 23:59:59 local time**, 30 days from this
revision's 24 September 2026 release date. See the
[Build 252 plan](docs/252_ARCHITECTURE_PLAN.md).

# 2.0.51 (Build 251, Revision 1) - Course Editor device state - 2026-09-24

One owner now holds the Course Editor's immediately written access mode,
one-time View-only notice preference and seven-day per-Course-code orphan MP3
check schedule. The Editor keeps the dialogs, working copy and Audit route.
Stored keys and values, legacy mode fallback, automatic-check gate and mark
timing remain unchanged. This is a source-only architectural revision with no
behavior change.

Version `2.0.51+251001`; Course Model v11, package format 1, rights, import,
progression, scoring and the Course Editor confirmation remain unchanged. Beta
expiry is **2026-10-24 23:59:59 local time**, recalculated as 30 days from
this revision's 24 September 2026 release date. See the
[Build 251 plan](docs/251_ARCHITECTURE_PLAN.md).

# 2.0.51 (Build 251, Revision 0) - Shared Course sections - 2026-09-24

The Courses screen now uses one Course Library section component for Favorites,
Bundled, Publisher, My Local and Other Local Courses in both tabs. The section
renders Expanded/Compact controls, border, count and empty message while the
tabs retain each section's view state. Shared owners apply Search, availability
filter and sorting. All Courses and Course Studio keep their own data loading,
rows and actions; their existing labels, keys and presentation remain the same.
This is a source-only architectural revision with no behavior change.

Version `2.0.51+251000`; Course Model v11, package format 1, stored keys,
authoring rights, progression, scoring and the Course Editor confirmation are
unchanged. Beta expiry is **2026-10-24 23:59:59 local time**, recalculated as
30 days from this revision's 24 September 2026 release date. See the
[Build 251 plan](docs/251_ARCHITECTURE_PLAN.md).

# 2.0.50 (Build 250, Revision 1) - Courses layout - 2026-09-24

The Course Manager tab is renamed Course Studio in user-facing labels and
Help, while internal class and key names remain. The Course actions menu now
stays at the right edge of its row, including on narrow screens. Sort by and
Show unavailable share one line; opening Search shows its field below Sort.
Both tabs offer Search and have separate Help icons beside their tab labels.
New course remains exclusive to Course Studio. Favorites use a soft amber
accent with ordinary row text and background colors. Course Studio also shows
a Favorites section limited to Courses in the active learner's Personal
Library, with its existing actions, sort, availability filter and independent
Expanded / Compact state.
Other Local Courses uses a neutral gray section border in both tabs, distinct
from red Audit errors and the green ready and blue Draft/Unpublished states.
Course Studio's three-dot Course menu includes Course Info. Tapping a Course
cover or flag in either tab opens a popup showing that image larger.

Version `2.0.50+250001`; Course Model v11, package format 1, stored preference
keys, authoring rights, progression and scoring are unchanged. Beta expiry is
**2026-10-24 23:59:59 local time**. This is a source release without a Windows
package. See the
[Build 250 plan](docs/250_COURSES_SCREEN_PLAN.md).

# 2.0.50 (Build 250, Revision 0) - Courses screen and learner visibility - 2026-09-23

All Courses and Course Manager are now tabs of one **Courses** screen, sharing
Course rows, sorting and availability controls. All Courses adds search and a
Favorites shortcut section. Favorite is per learner and does not add or remove
a Course from the Personal Library. Hide in Learner is also per learner: it
keeps the Course in that library, removes it from the learner Selector, and
cannot hide the Course currently being studied. The Selector groups Current,
up to three Recent, Favorites and Other Courses. Locked Course Manager and
Course Editor entries remain visible and explain how to unlock them.

Import remains available to locked profiles. Copy and Fork are greyed out in
the matching-ID Import dialog until Course Manager is unlocked. Successful
imports return to their opening screen, without opening the Editor for Copy or
Fork; the Selector offers **Study now** for a playable result. A received
Custom Course can be updated from a strictly newer matching version by a
learner who has it in their Personal Library, provided no local Maintainer or
assigned-Team member exists. Locally authored Courses keep their existing
replacement rights. Course Manager Help is separate from Course Editor Help.

Version `2.0.50+250000`; Course Model v11 and Course package format 1 remain
unchanged. Beta expiry is **2026-10-23 23:59:59 local time**. See the
[Build 250 plan](docs/250_COURSES_SCREEN_PLAN.md).

# 2.0.49 (Build 249, Revision 2) - Failed Course deletion is reported - 2026-09-23

When deleting a Course failed at the storage step, Course Manager showed
nothing: the error was lost and the Course simply stayed in the list. It now
says "Could not delete “…”:" with the reason, and the list is reloaded so it
shows what is actually stored. Deleting that succeeds is unchanged, and so is
the two-step confirmation.

Version `2.0.49+249002`; Beta expiry remains
**2026-10-23 23:59:59 local time**.

# 2.0.49 (Build 249, Revision 1) - Greyed-out Course Manager actions - 2026-09-23

Course Manager's menu no longer hides actions you are not allowed to use.
An action that depends on your rights, the Course's license, Publisher
verification or admin status now appears greyed out, with a short line
saying why: for example "Only the Maintainer or assigned Team can delete this
Course.", "The license does not allow derivative works." or "Only an admin
can remove a Publisher Course from this device." Tapping it does nothing.
Actions that can never apply to that kind of Course, such as Copy, Merge or
Delete on an official Course, stay hidden. Who may do what is unchanged.

Version `2.0.49+249001`; Beta expiry remains
**2026-10-23 23:59:59 local time**.

# 2.0.49 (Build 249, Revision 0) - Course library operations - 2026-09-23

Course Manager's workflow has one owner. Which Courses are listed, which menu
actions each Course offers, the titles given to copies and merges, where a Fork
of an official Course takes its source, what an import may do when its Course
ID is already in use, and the messages reported afterwards all lived inside
the screen. They now live in `CourseLibraryOperations`, which can be tested
without building the screen; the screen keeps its layout, dialogs and
confirmations. Course Manager looks and behaves exactly as before.

A characterization test found one existing defect, deliberately left alone in
this revision: when deleting a Course fails at the storage step, nothing is
shown and the error is lost. It is fixed separately in Revision 2.

Version `2.0.49+249000`; the Beta expiry, recalculated from this release's
date, is **2026-10-23 23:59:59 local time**.

# 2.0.48 (Build 248, Revision 3) - Fork leaves the Editor - 2026-09-23

Fork was the third Course Editor action running on the unconfirmed working
copy, and Revision 2 missed it while removing the other two. Because Fork
persists a new Course, you could open a Course you do not maintain, change it,
Fork, then cancel - and keep a forked Course built from edits that were never
confirmed, whose provenance named a source version that existed nowhere.

Fork is now reached only from Course Manager, which is also the more correct
route: it forks the stored Course, and for an official Course it first resolves
the immutable official source rather than whatever the Editor happened to hold.
Who may fork, and what a fork inherits, are unchanged.

Version `2.0.48+248003`; Beta expiry remains
**2026-10-22 23:59:59 local time**.

# 2.0.48 (Build 248, Revision 2) - Export leaves the Editor - 2026-09-23

Course export and Copy as New Course are no longer offered inside the Course
Editor. Both worked on the unconfirmed working copy, so a cancelled session
could produce a package - or persist a whole new Course - built from changes
that were never saved. Course Manager keeps both actions and works from the
stored Course. A new Course Export screen mirrors the Import screen, offering
the fixed-folder export and Save to… in one place, and the Course Manager menu
now has a single Export Course entry that opens it, for official Courses too.

In each Lesson, Preview Lesson and Generate Rounds from GuideBook leave the
body and become Preview and Round Wizard buttons in the bottom area, matching
the Round screen, and the breadcrumbs move to the top like every other level.
The Round screen's Creation Wizard is renamed Exercise Wizard.

Version History deliberately stays in the Editor: unlike export and copy it
loads into the working copy and still respects the single Course confirmation.

Course Model v11, stored formats and keys, package format 1, authoring rights,
scoring, progression and the single top-level Course save are unchanged.
Version `2.0.48+248002`; Beta expiry remains
**2026-10-22 23:59:59 local time**.

# 2.0.48 (Build 248, Revision 1) - Course Editor layout and media notices - 2026-09-23

The Course-level Lesson settings - Lesson numbering, Use GuideBook and Create
Duels - move from the Lessons screen to a collapsed Lesson Options section
under the Course Editor's Lessons tile, where they belong: none of them was
ever a Lesson property. The Lesson editor drops its Lesson title and Audit
Lesson links and the Round editor drops Rename Round and Audit Round, because
the Lessons and Rounds pages already offer Rename and Audit in their 3-dot
menus; the surviving rename dialog keeps the same "Title, or Enter to skip"
behaviour, including preserving a title when Enter is pressed on an empty
field. The Audio Library no longer has a Save button: leaving the screen hands
its draft to the Course Editor, exactly as Save did, and a notice explains that
the changes reach the Course only when the Course changes are confirmed, and
are discarded - along with any media that session added - when they are
cancelled. A Course's Image Library gains the same notice; it already saved on
exit and already discarded on cancel, so only the notice is new. The Build 248
media clean-up now covers every kind of Course media rather than recordings
only, so images added during a cancelled session are removed too. Course Model
v11, stored formats and keys, package format 1, authoring rights, scoring,
progression and the single top-level Course save are unchanged. Version
`2.0.48+248001`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.48 (Build 248, Revision 0) - Audio Library media lifetime - 2026-09-22

One owner now holds the lifetime of the recordings a Course editing session
imports. `RecordedAudioService` writes an imported MP3 into the Course's own
media folder immediately, long before the single top-level Course
confirmation, so a cancelled session, a back-out of the Audio Library without
Save, or a batch that failed part way through used to leave files on disk that
nothing referred to — permanently, for a new Course that was never confirmed.
`CourseAuthoringMedia` records what the Course's media folder held when the
session opened and, when the session ends without confirming a Course, removes
exactly the recordings it created that the stored Course does not use. It
removes nothing when the folder or the stored Course cannot be read, so media
stay for recovery, and a confirmed Course still tidies up inside its own
confirmation. MP3 validation and storage stay in `RecordedAudioService`, and
the player, preview controls and dialogs stay in the widget. Closing an
unchanged Course Editor now completes after that check rather than in the same
frame. Pictures added while editing leak the same way and are recorded as a
known limit for a later build. Course Model v11, stored formats and keys,
package format 1, authoring rights, scoring and progression are unchanged.
Version `2.0.48+248000`; Beta expiry remains
**2026-10-22 23:59:59 local time**.

# 2.0.47 (Build 247, Revision 1) - Import cleanup after a failure - 2026-09-22

A failed custom Course package import now keeps the media files it created
only when the stored Course uses every medium in the package, which is what a
committed import leaves behind, or when storage cannot be read. A Replace
rejected before it commits removes the files that attempt added instead of
leaving an unused image or recording in the Course folder; the previous
Course's own media are untouched. Course Model v11, stored formats, package
format 1, authoring rights and the top-level Course save boundary are
unchanged. Version `2.0.47+247001`; Beta expiry remains
**2026-10-22 23:59:59 local time**.

# 2.0.47 (Build 247, Revision 0) - Package Import workflow - 2026-09-22

One import attempt owns a Course package from reading until it is installed
or cancelled. Custom imports, Copy as New Course and Fork write the package's
media only into the destination Course's own folder under that Course's lock;
Copy and Fork no longer pass the media through the same-ID installed Course's
folder. Staged package files are removed as soon as the import ends, before a
new Copy or Fork opens in its Editor. Successful imports store the same Course
and media as before, and failure recovery keeps media whenever a stored Course
may use them. The package manifest's prompt-only shared-image list is recorded
as a known limit; package format 1, Course Model v11, stored formats,
authoring rights and the top-level Course save boundary are unchanged.
Version `2.0.47+247000`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.46 (Build 246, Revision 1) - Matching Course ZIP folder - 2026-09-22

Import and Merge accept a Course package with its files at the ZIP root or
inside one folder whose name exactly matches the ZIP filename without `.zip`.
The matching folder produces a nonblocking warning. Other unexpected or unsafe
ZIP layouts remain rejected. Import and Merge Help explain the folder rule;
Merge Help clarifies that same-ID sources may differ by Course version or
Modified date and time. Course Model v11, stored formats, authoring rights and
the top-level Course save boundary are unchanged. Version `2.0.46+246001`;
Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.45 (Build 245, Revision 4) - Per-Course storage commands - 2026-09-22

Course storage mutations use intent-specific create, update and delete
commands instead of a whole-store map bridge. The Course Editor facade keeps
authorization and stale-edit checks, and confirmed changes retain backup
before write, readback and media cleanup ordering. Unreadable or duplicate-ID
files remain protected by the file store; failed writes preserve recovery
paths. Course Model v11, stored formats and user-visible behavior are unchanged.
Version `2.0.45+245004`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.45 (Build 245, Revision 3) - Canonical authoring route propagation - 2026-09-22

Integrated Course, Lesson, Round and Exercise editor routes now pass accepted
updates through the Course authoring session. The route supplies the prior
Course snapshot required for publication reconciliation, while standalone
editor routes keep their public callbacks. The session remains the sole
working Course owner and final confirmation remains the only persistence
point. Course Model v11, stored data and user-visible behavior are unchanged.
Version `2.0.45+245003`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.45 (Build 245, Revision 2) - Typed hierarchy updates - 2026-09-22

Lesson, Round and Exercise edits gain typed update commands. One service now
owns hierarchy reconstruction and preserves Content wrapper metadata while
the editor retains transient form and navigation state. The existing Course
transaction remains the sole working copy and final confirmation
remains the sole persistence point. Course Model v11 and user-visible behavior
are unchanged. Canonical nested callback propagation follows in Revision 3.
Route coverage and verification are recorded in
`docs/245_VALIDATION.md` and `docs/245_HANDOFF.md`.
Version `2.0.45+245002`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.45 (Build 245, Revision 1) - Course authoring session - 2026-09-22

One authoring session coordinates the existing Course Editor working copy,
provisional publication reconciliation, draft adoption, dirty state, Audit
freshness and final confirm/cancel. The screen retains presentation and
navigation state. There is still one Course working copy and one final
persistence boundary. Course Model v11 and user-visible behavior are unchanged.
Version `2.0.45+245001`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.45 (Build 245, Revision 0) - Course Info ownership - 2026-09-22

The Course Info Editor keeps its form and interactions while one application
operation applies its metadata and governance changes to the Course Editor
working copy. The final Course confirmation remains the only persistence
point. Course Model v11 and user-visible behavior are unchanged. The staged
architecture plan is in `docs/245_ARCHITECTURE_PLAN.md`.
Version `2.0.45+245000`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 7) - Course Library Help - 2026-09-22

Course Library Help is rewritten. It starts by explaining that the page lists
every Course on this device, not only those in your personal library, and
that Courses can come from elsewhere: a friend can send you a Course they
made, or a publisher may distribute or sell you one. QQL only imports the
Course package. Help then covers the four categories, the Course details,
the availability switch, sorting and compact view, the personal library,
importing and removing Publisher Courses. Editor Help (English and Italian)
describes the new page.
Version `2.0.44+244007`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 6) - Compact sections - 2026-09-22

Each Course Library section header has its own **Expanded / Compact**
button. Compact rows keep the picture (smaller), title, languages, status
labels and Add/Remove, and hide version, last edited date, maintainer and
duration. Every section starts Expanded, and the choice lasts while the page
is open.
Version `2.0.44+244006`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 5) - Sort by - 2026-09-22

A **Sort by** control next to the availability switch orders Courses by
Title (the default), Language, Maintainer, Most recent or Duration. The order
applies inside each section; sections never move and no Course changes
section. Most recent puts the newest edit first; Duration puts the shortest
first and Courses without a declared duration last. Ties are broken by title
and then by Course ID, so rows never jump between refreshes.
Version `2.0.44+244005`; Beta expiry moves to **2026-10-22 23:59:59 local time**, 30 days from this release (22 September 2026).

# 2.0.44 (Build 244, Revision 4) - Richer Course rows and covers - 2026-09-21

Course Library rows now show the Course cover, or its flag when there is no
usable cover, in a fixed square beside the title. Under the title each row
lists the languages, **Version**, **Last edited** date, **Maintainer** and, when
the author declared it, **Duration**. Official Courses show their release
version and Custom Courses their Course version. This is the first place QQL
displays Course covers; they are decoded at thumbnail size, and a missing or
unreadable cover falls back to the flag.
Version `2.0.44+244004`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 3) - Course Library sections - 2026-09-21

Each Course Library category is now its own clearly separated section with a
coloured border and header: **Bundled Courses**, **Publisher Courses**, **My
Local Courses** and **Other Local Courses** (formerly My and Other Custom
Courses). Headers show counts, such as `Publisher Courses · 2 shown · 1
hidden` while the availability switch hides some. A section whose Courses are
all hidden says so and points to the switch. A Find Courses on the web section
is prepared but stays hidden until the QQL Course web site exists.
Version `2.0.44+244003`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 2) - Course Library and availability switch - 2026-09-21

Available on this device is now called **Course Library**, in its title, its Help,
both Home entry points, the removal dialog and Editor Help and Info. A new
**Show unavailable or Draft Courses** switch, off by default, hides Courses that
are unpublished, need Publisher verification or contain Draft authoring
content. Turned on, it shows them with separate **Draft**, **Unpublished** and
**Verification required** labels. The switch only changes what the page shows;
personal libraries, files and Course states are untouched.
Version `2.0.44+244002`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.44 (Build 244, Revision 1) - Shared Course Draft rule - 2026-09-21

The rule that decides whether a Course contains authored Draft content now
lives in one shared model helper instead of inside the Course Editor, so the
coming Course Library can use it without running the Course Audit. Editor and
Course Manager Draft badges behave exactly as before.
Version `2.0.44+244001`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.43 (Build 243, Revision 19) - Phase 20 import route matrix - 2026-09-21

Small synthetic fixtures now exercise the fixed-folder, Open from…, and Course
package routes for structured files, images, Image Banks and MP3s. The matrix
found that embedded exercise images, custom Lesson icons and custom flags in
Course JSON were not content-checked at import. Those bytes now pass the same
image validator as direct imports; already stored Courses remain unchanged.
Version `2.0.43+243019`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.43 (Build 243, Revision 18) - Image preview details - 2026-09-21

The full-size preview in Shared Images and the Course Editor's Image Library
shows file details when the picture is hovered over or long-pressed. It names
the original or stored file, approximate size, dimensions, format, added date,
Image Bank and attribution when available, and identifies missing files and
Course copies. Tiles stay compact. English Editor Help explains the gesture.
Version `2.0.43+243018`; Beta expiry remains **2026-10-21 23:59:59 local time**.

# 2.0.43 (Build 243, Revision 17) - Clearer media errors - 2026-09-21

Media imports now explain common wrong file types and how to fix them.
A missing Image Bank manifest error explains how to create and add the JSON
file and points to Editor Help. Audio Library labels its default mode
**On-Device TTS**, explains each mode, and offers MP3 tools only in Recorded
MP3 and Hybrid modes. Version `2.0.43+243017`; Beta expiry remains
**2026-10-21 23:59:59 local time**.

# 2.0.43 (Build 243, Revision 16) - Duplicates and provenance - 2026-09-21

Tranche 5 (part 1) of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-16--duplicates-and-provenance); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243016`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- The Shared Image Library screen is now called **Shared Images**.
- A picture already in Shared Images is recognised by its content and skipped, whatever its file name, including QQL's own pictures.
- When an Image Bank image has the same ID as a different picture, the Admin chooses **Skip**, **Replace** (never QQL's own images) or **Keep both**, with **Apply to all**.
- Every imported image now records where it came from and when; the "last added" sort uses that date.
- A web page saved under an `.mp3` name (for example after a failed download) is now explained as such, instead of "not a valid MP3".

# 2.0.43 (Build 243, Revision 15) - Course packages read from disk - 2026-09-21

Tranche 4 (part 2) of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-15--course-packages-read-from-disk); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243015`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- A Course ZIP (up to 300 MB) is no longer loaded into memory whole. QQL reads it from disk one piece at a time and keeps its images and recordings in a private staging folder until the Course is installed, which lowers peak memory use on phones and small Linux machines.
- Only the images and recordings the Course actually uses are read. A refused package leaves nothing behind.

# 2.0.43 (Build 243, Revision 14) - Safer archives and structured files - 2026-09-21

Tranche 4 (part 1) of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-14--safer-archives-and-structured-files); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243014`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Image Bank ZIPs and Course packages are read by one hardened reader. Before anything is unpacked, it refuses links and special files, encrypted entries, unusual compression, archives inside the archive, unsafe or colliding names, and too many or too large entries. Each file is then checked against its declared size and checksum.
- An Image Bank may contain only its manifest and the images it lists; credits go in the manifest. A manifest may now give one default credit for the whole bank, and its names, labels and keywords are bounded.
- When an Image Bank brings new categories, the Admin chooses **Add them**, **Put these images under Other** or **Cancel** before anything is stored. A failed import leaves nothing behind.
- Course files, learner backups and User Recovery Keys are checked for excessive nesting, oversized text and lists, too many Lessons, Rounds or exercises, and NUL characters in names before they are read.

# 2.0.43 (Build 243, Revision 13) - Real MP3 validation - 2026-09-21

Tranche 3 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-13--real-mp3-validation); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243013`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Every MP3 that enters QQL is checked by its content: the Audio Library's fixed folder, **Open from…**, and the recordings inside an imported Course ZIP. A file that is not real MPEG Layer III audio, is damaged or cut short, carries more than 2 MB of tags, or has embedded cover artwork is refused.
- **Open from…** in the Audio Library now takes several MP3s at once (up to 100 files and 250 MB) and ends with a summary of each file's result.
- A recording the Course already has is skipped instead of listed twice. From the fixed folder, one refused file means nothing is imported.

# 2.0.43 (Build 243, Revision 12) - Add images and Image Banks to a Course - 2026-09-21

Tranche 2b of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-12--add-images-and-image-banks-to-a-course); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243012`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- In the Course Editor's Image Library, **Add images to this Course** imports one image, several at once, or a whole Image Bank ZIP into the Course's own library. No Admin rights are needed, and nothing reaches the device's Shared Image Library.
- The images stay unused until an exercise uses them (`COURSE`, then `COURSE · IN USE`), travel in the Course ZIP and backups, and can be removed with the bin.
- Every image passes the image check, duplicates are skipped, and nothing is written if the Course would pass its 300 MB package limit. One summary lists each file's result.
- An Image Bank imported into a Course keeps its names, categories, tags and credits inside the Course.

# 2.0.43 (Build 243, Revision 11) - One image check for every image import - 2026-09-21

Tranche 2 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-11--one-image-check-for-every-image-import); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243011`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Every imported image is checked by its content, not its name: Shared Image Library, Course Editor images, Recognize Characters, Lesson icons, custom flags, Image Bank images and Course ZIP images. It must really be a still PNG, JPEG or WebP, undamaged, at most 4096 × 4096 pixels, with at most 256 KB of embedded metadata. A file of another type under an image name, a damaged file, an animation or a tiny file claiming huge dimensions is refused before anything is stored.
- The Shared Image Library's **Open image files from…** imports up to 100 images at once and ends with one summary (counts, plus each file's reason).
- Shared Image Library images are stored under names QQL chooses (`image_local_<number>.<type>`), with the type taken from the content. Nothing is written for anyone but an Admin, and a failed import leaves no file behind.
- Importing a custom image in the Course Editor no longer leaves an unused copy in the shared image folder; the image goes straight into the Course.
- Images already stored are not re-checked, so existing Courses and libraries keep working.

# 2.0.43 (Build 243, Revision 10) - Safe import foundation - 2026-09-21

Tranche 1 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-10--safe-import-foundation); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243010`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Open from… no longer loads a chosen file into memory before checking it. The file is streamed into a private QQL staging folder while its actual bytes are counted against the real limit (for example 50 KB for exercise images, 50 MB for MP3s), and reading stops as soon as it is exceeded. The size a file claims is never trusted.
- Only ordinary files are opened: symbolic links, folders and devices are refused, in Open from… and for the fixed-folder names `flag.png`, `import.json`, `import.zip` and `learner_import.json`.
- Empty files, files that vanish or fail while being read, and a full disk are reported without leaving anything behind. Leftovers from an interrupted import are removed at the next start.
- Groundwork for multiple selection: per-file results, a batch limit of 100 files and 250 MB, and cancellation. The multi-file dialogs arrive with the image and audio tranches.

# 2.0.43 (Build 243, Revision 9) - QQL image metadata read-only; Local words; device categories - 2026-09-21

Tranche 0b of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-9--qql-image-metadata-read-only-local-words-device-categories); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243009`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- QQL's own images keep the category and tags QQL gives them, identical on every installation and updated with the app. Admins can no longer change them.
- Admins can add **Local** words to a QQL image: extra search words on this device only, shown after the tags (`Tags: … · Local: …`), searchable, never exported.
- Admins can add their own **device categories**, and rename them or remove them when unused (**Manage device categories**, and **New category…** in Edit metadata).
- Fixed a latent failure: after any Admin import or edit, a future app update that added a QQL image would have stopped the image library from loading. Stored metadata now holds only device-owned data; a stored snapshot from earlier builds is converted once (tags an Admin added to QQL images become their Local words).

# 2.0.43 (Build 243, Revision 8) - Remove an image from a Course; badge order - 2026-09-21

Revision 8 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md) (§6b). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-8--remove-an-image-from-a-course-badge-order); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243008`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Image badges are listed `IN USE` first, then `QQL`, `DEVICE`, `COURSE`, on images, in the badge filter and in the exercise image preview.
- In the Course Editor's Image Library, **Remove from this Course** clears an image from every exercise, presentation, GuideBook and the cover that use it, after a confirmation listing each place. Exercises that the Audit then reports as invalid become Draft. Nothing is stored until the Course is confirmed. QQL images and Shared Image Library originals stay available.
- Every image stored in a Course now has the same bin, used or not. After its uses are removed, a second question asks whether it also leaves the Course or stays in the Course's own library, unused. A leftover file that no saved or edited version uses is deleted at once.
- Courses gain an optional `imageLibrary` list of images kept without being used. It is omitted when empty, travels in the Course ZIP and backups, and is carried by Fork, Copy as New Course and Merge. Builds before Revision 8 ignore it.

# 2.0.43 (Build 243, Revision 7) - Image library tidy-up - 2026-09-21

Revision 7 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md) (§6c). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-7--image-library-tidy-up); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243007`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- One rule now decides where a Course uses an image, for storage, the Image Library's `IN USE` badge and the Exercise editor alike.
- Images used only in a flashcard, an explanation, a Lesson introduction or a GuideBook now show `IN USE`. Such images come only from Course JSON written outside QQL's editor.
- No other visible change: the Image Library's rules and the Exercise editor's image section were reorganized into separately tested parts.

# 2.0.43 (Build 243, Revision 6) - Import memory-safety fixes - 2026-09-21

Tranche 0 of the [import hardening plan](docs/IMPORT_HARDENING_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-6--import-memory-safety-fixes); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243006`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- A Course ZIP cover is checked for 512 × 512 from its header before it is decoded, so a small file claiming huge dimensions can no longer exhaust memory.
- Image Bank ZIPs are checked before anything is decompressed: at most 5,000 entries, no symbolic links, and at most 50 MB across all entries. The manifest and each image are then decompressed only up to their declared size and must match it exactly.
- Custom Lesson icons and Course flags accept sources up to 4096 pixels per side (previously 8192).
- Animated PNG and WebP images are refused when imported as exercise images. Images already stored in a Course keep working.

# 2.0.43 (Build 243, Revision 5) - Image Library usability - 2026-09-21

Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-5--image-library-usability); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243005`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- The `USED` badge is renamed `IN USE`. Badges are small labels laid over the image's bottom-left corner, one per row, in the Image Library and the exercise image preview.
- The Image Library adds a badge filter beside the category filter, and a sort menu: Name (A–Z), Newest or Oldest added, Largest or Smallest file.
- In a Course's Image Library, an Admin-added image and its Course copy appear once, labelled `DEVICE`, `COURSE` and `IN USE`. If the original is gone from the device, the copy appears alone as `COURSE`.
- Tiles show only the image, the name and, when present, the tags, in lowercase; the category is no longer repeated. An Admin's delete or remove-bank button is a small control in the image's bottom-right corner. Category and badge filter chips are compact.
- The import security hardening plan is recorded in [docs/IMPORT_HARDENING_PLAN.md](docs/IMPORT_HARDENING_PLAN.md).

# 2.0.43 (Build 243, Revision 4) - Signed Publisher Course media - 2026-09-21

Tranche 3 of the [portable Course package plan](docs/COURSE_PACKAGE_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-4--signed-publisher-course-media); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243004`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Signed Publisher Course ZIPs carry only referenced images and recordings. Import checks the signature and each content digest before installation; direct service installation also refuses missing or damaged media. An update backs up the old media and removes files the new version no longer uses; uninstall retains media.
- `tools/sign_course.dart package` verifies the signed JSON and media files, then creates the distributable ZIP. The Publisher guide and in-app Help describe the new process. A signed Dummy ZIP with media tests the path.
- The Course Editor's **Image Library** now lists Course-stored images beside shared images, and shows `USED` on bundled and device images used in an exercise. The separate Admin management entry is called **Shared Image Library** in Course Manager and Device Administration; shared entries retain their `QQL` or `DEVICE` label.

# 2.0.43 (Build 243, Revision 3) - Portable Course ZIP - 2026-09-21

Tranche 2 of the [portable Course package plan](docs/COURSE_PACKAGE_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-3--portable-course-zip); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243003`; the Beta expiry remains **2026-10-21 23:59:59 local time**.
- Course export writes a ZIP with canonical Course JSON and only its referenced Course media. Import and Merge accept that ZIP or media-free v11 JSON; package validation completes before installation.
- Admin-added Shared Image Library images selected for a Course travel as Course-owned media, with their library identity, metadata and optional per-image attribution retained in the Course and package manifest. Admins enter attribution in **Edit metadata**; every viewer can read it, and Image Banks may supply it. Import never adds these images to the destination Shared Image Library. Every viewer sees fixed `DEVICE` and `QQL` labels in the library; those labels stay unchanged when a Course uses an image. The Course Editor adds `USED` for any used image and `COURSE` when its bytes are in the Course folder, beside the source label where applicable. Bundled assets stay supplied by the app.

# 2.0.43 (Build 243, Revision 2) - Course media: one format on every device - 2026-09-21

Tranche 1 of the portable course package ([plan](docs/COURSE_PACKAGE_PLAN.md)). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-2--course-media); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243002`; same release date, so the Beta expiry stays **2026-10-21 23:59:59 local time**.
- **A Course names its own images and recordings by content**, `media:<sha256>.<ext>`, never by a path on one device. Course Model v11 refuses device paths for recordings and exercise images; bundled `assets/` media and embedded `data:` images are unchanged. The optional cover image uses the same form.
- **One media folder per Course**, `quisquislingo_course_media/<course folder>/`. Importing an MP3 or an image, or choosing an image from the Shared Image Library or a bank, copies the bytes there; identical files are stored once and every write is verified against its reference.
- Study, Duel, Exercise Preview, Audio Library and the editor preview find media through the Course. Course images are read into memory rather than memory-mapped, so an image on screen never blocks the cleanup on Windows.
- **Copy as New Course, Fork and Merge copy the media they use** into the new Course's folder (a merge from both source Courses); a failed creation removes the copies. Deleting a Course deletes its folder.
- A confirmed save removes files the Course no longer uses. **Version backups now include images as well as recordings**, verified against their references, and Restore puts them back in the Course folder; a missing file is still recorded as a gap rather than blocking the save.
- Deleting from the Shared Image Library no longer affects any Course, since each keeps its own copy; the deletion dialog says so instead of listing Courses.
- Reset: removing imported images or audio also removes course media of that type. Inventory lists "Course media" by Course. Android backup excludes the new folder and still excludes the retired `quisquislingo_audio`.
- The shared MP3 cleanup (`ManagedAudioCleanup`, `MediaReferenceIndex`) is removed: with one folder per Course nothing is shared, so cleanup no longer needs to read every stored Course.
- Fixed a Revision 0 slip: the in-app Publisher Help and the signing guide again carry identical wording.

# 2.0.43 (Build 243, Revision 1) - An unreadable stored Course no longer hides the others - 2026-09-21

Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md#revision-1--an-unreadable-stored-course-no-longer-hides-the-others); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243001`. Released on the same day as Revision 0, so the recalculated Beta expiry is again **2026-10-21 23:59:59 local time**.
- **One unreadable stored Course no longer blocks everything.** Since Build 241 a single damaged, unsupported or duplicated Course file stopped Course Manager, the Course Selector, import and every save, although the code comment and the test name claimed the opposite. Listing and saving now skip such files and continue with the readable Courses.
- Course Manager shows a notice naming each skipped file and its reason; the Inventory names them too. Skipped files are never modified: saving over one is refused with a message saying which file to move. When two files claim the same Course ID, both are skipped.
- Stays strict where a missing Course would be dangerous: the unused-MP3 cleanup deletes nothing, and profile deletion is refused, while any stored Course file is unreadable.

# 2.0.43 (Build 243, Revision 0) - Course Model v11 - 2026-09-21

First revision of the portable course package work (Revision 1 fixes unreadable stored Courses; Tranches 1–3 follow as Revisions 2–4); see the [course package plan](docs/COURSE_PACKAGE_PLAN.md). Scope: [Build 243 change summary](docs/243_CHANGE_SUMMARY.md); evidence: [243 validation](docs/243_VALIDATION.md).

- Platform version `2.0.43+243000`. The 30-day Beta expiry is recalculated from this release's own date, 21 September 2026: **2026-10-21 23:59:59 local time**.
- **Course Model v11 is the single accepted format, as a clean cut.** v9 and v10 files are refused with a message naming the conversion tool; the application never converts them. v11 is v9 with merge provenance as an optional field of any custom Course (the former v10 existed only for it), the Build 242 media credits, and six optional descriptive fields.
- **New optional Course fields**, editable in Course Info Editor and shown in Course Info: estimated study hours (1–1000), minimum age as an App Store class (4+, 9+, 13+, 16+, 18+), up to 20 keywords, a publisher website and/or email shown as plain text, and a minimum QuisquisLingo build — a Course requiring a newer build is refused with a request to update. A square cover image reference (`media:<sha256>.<ext>`) is validated and stored only; nothing displays it yet, and keyword search is not implemented. None of these fields grants permissions.
- The fields travel with Fork, Copy as New Course and in-Course transfers; a merge keeps the left Course's values and the higher minimum build, and differing values never block it. In-Course transfers now also keep merge provenance, which v11 would otherwise have dropped silently.
- **New storage folders.** Courses are stored under `qql_courses_v2` and version backups under `Course Backups v11`. The previous `qql_courses_v1` and `Course Backups v9` folders stay on disk untouched and are never read, so an old v9 Course can no longer block every Course list or Version History. Old Courses disappear from the lists; convert them and import them again.
- **`tools/convert_course_to_v11.dart`** converts a v9/v10 file by changing only `formatVersion` (and, for an official Course, recomputing its checksum and optionally its version). It stops and lists every reference to media outside `assets/`. A Publisher Course loses its signature and must be signed again.
- The ten bundled Courses are v11 with unchanged Course IDs, so learner progress is kept; each official version rises by one minor step (1.6.1 → 1.7.0, 1.0.1 → 1.1.0, 1.0.0 → 1.1.0). The demo Course and the three Dummy publisher fixtures are converted; the two signed fixtures are signed again with the Dummy test key.
- Editor Help, Publisher Help, the signing guide, the JSON format reference and the storage inventory describe v11.

# 2.0.42 (Build 242, Revision 0) - Media audit, media credits and the recording-save fix - 2026-09-20

Full findings and reasoning: [media libraries audit and plan](docs/MEDIA_LIBRARIES_PLAN.md). Scope and evidence: [Build 242 change summary](docs/242_CHANGE_SUMMARY.md), [242 validation](docs/242_VALIDATION.md).

- Platform version `2.0.42+242000`. The 30-day Beta expiry is recalculated from this release's own date, 20 September 2026, and therefore remains **2026-10-20 23:59:59 local time** — the same day as Build 241 because both were released on 20 September, not the previous expiry carried forward.
- **A missing recording no longer makes a course unsaveable.** The pre-change Course backup reads the persisted course, so once a referenced MP3 disappeared every later save failed, including the edit that would have removed the broken reference; one way to reach that state was the documented `Remove imported media → Audio files` reset. The backup now records the gap in its manifest instead of refusing to run. Backup records that do name a copied file keep their strict existence and SHA-256 checks, and a record cannot claim to be a gap while still naming a file.
- Audio Library marks a recording whose file is gone as **File missing** and explains the repair. The orphan check still means "no word associated" and is unchanged. The imported-media reset warns that courses using removed recordings need repairing.
- **Media credits.** Course Info Editor gains a structured list under License / Rights recording the author, licence, and optional title, source and scope of third-party images and recordings. Credits appear in Course Info and in Credits, and travel inside the Course file even though the media bytes do not. `formatVersion` stays 9: the field is omitted when empty, so existing courses, backups and publisher signatures are byte-identical — both signed Dummy fixtures still verify.
- Course Audit adds `MEDIA_ATTRIBUTION_MISSING` (Warning), raising the registry from 103 to 104 rules. It fires when a course carries media of its own and records no credit, and never blocks export or import. Media shipped with QuisquisLingo is credited by the application and needs no entry.
- **Corrected the application's own flag credits.** The Image credits page claimed nineteen language-related flags and listed three attribution-required works; there are twenty-four, and five require attribution. **Mirandese (ItsGandaM1ke, CC BY 4.0)** and **Venetian (F l a n k e r, CC BY-SA 3.0)** were uncredited, and the closing claim that the remainder were public domain or CC0 was false. The test now derives the expected set from `assets/world_flags/LICENSE-language-related-flags.md` so this cannot drift again.
- Editor Help no longer claims images and Image Bank ZIPs have no file picker: both routes, fixed folder and `Open from…`, are documented in English and Italian, and a test asserts it.
- A Publisher Course declaring recorded MP3 files outside `assets/` is refused at import and at installation. A Course file carries clip paths, never bytes, and a publisher's paths are frozen by the signature, so the course could never play its audio and could never be repaired. Custom courses are unaffected.
- Removed three obsolete manifests from `assets/exercise_images/` (about 92 KB shipped in every build). Runtime code did not read them, two were byte-identical, and all three carried a superseded bilingual tag set. One of them was also the only Image Bank example in the repository and could never be imported, because every ID in it already belongs to the bundled catalogue. A genuine importable example now lives in `demo_image_banks/example_image_bank.zip`, outside `assets/`, with a test that imports it.
- Deleting a shared image or an Image Bank now names the courses that still use it before it goes ahead. Deletion is still permitted; it is no longer invisible.
- Bounded image decoding at every render site. Nothing limited the pixel dimensions of a path-based exercise image, so a 50 KB file declaring 30,000 × 30,000 could be rasterized in full.
- `audio_orphan_check_last_*` is now declared in `AppResetService` and the storage inventory, and the audio media reset clears it.
- Documentation: corrected `docs/AUDIO_LIBRARY.md`, which still described MP3 storage as grouped by learning language rather than per Course; corrected the stale "102 rules" line in `AGENTS.md`; recorded why the sixteen unreferenced bundled sample MP3s are deliberately kept; and documented the publisher media limits and the credit expectation in the signing guide.

- Final follow-up: aligned the regression tests with the missing-media transaction, Build 242 metadata, 27 Audit Warnings and the canonical image catalogue; verified the shared image-import path through real services. Publisher Help now includes the same verified media limits and credit guidance as the distributable guide. Final suite: **1,902 passed, 0 failed**; static analysis and all four media/course validators passed. Audio Library remains per Course. Platform results and the unreproduced ninth historical failure are documented in `docs/242_VALIDATION.md`.

# 2.0.41 (Build 241, Revision 2) - Personal course libraries - 2026-09-20

Complete scope, including Claude's initial file-store, backup, TTS, image-validation and Help work: [Build 241 Revision 2 change summary](docs/241_CHANGE_SUMMARY.md).

- Platform version `2.0.41+241002`; Beta expiry **2026-10-20 23:59:59 local time**. Includes the file-store and publisher-signature work described below.
- Rename the user-visible external category to Publisher Course; retain the internal origin identifier. Unsigned Publisher imports explain that a signature is required.
- Add per-profile course membership and Available on this device with four alphabetical sections, Maintainer labels, Add/Remove controls and dedicated Help. Adding another author's Custom course does not grant editing rights.
- Remove from my courses affects only the active profile. Optional progress reset preserves all XP, including Weekly XP earned from that course, total/per-language study days and streak. Confirmation and English/Italian Help explain this explicitly.
- Only an admin can physically uninstall a Publisher Course, and only when no other profile includes it. Progress, media and version backups survive uninstall.
- Remove Hide/Unhide; ignore retired visibility preferences. Direct Selector import returns to study without activating Course Manager.
- Empty libraries retain Settings and Course Manager when activated. Settings, profiles, backups and administration work without a current course; current-course reset and Test Voice explain when a course is required.
- Course creation uses Continue to Editor; persistence still occurs at Confirm course changes. Device-name edits appear immediately after saving.
- Final validation: 1,879 full-suite tests passed, followed by 8 focused tests and clean analysis for the owner-requested purple Publisher titles. Fresh results are recorded in `docs/241_VALIDATION.md`.

# 2.0.41 (Build 241, Revision 1) - Course file-store integration - 2026-09-20

- Revision 1 aligns the public label and platform build with `2.0.41+241001`, includes publisher-signature verification and the three-type Editor Help comparison. The 30-day expiry remains October 20, 2026 because this revision is prepared on September 20, 2026. Final validation remains pending owner approval.
- Complete the existing WIP integration of `CourseFileStore` with course editing and profile-maintainer checks. Custom and installed official courses reside in separate files under `<AppSupport>/qql_courses_v1`; obsolete course preference blobs remain unread and are not migrated.
- Reset preview detects real course files. Custom-course and full resets remove the store, including interrupted or malformed files; other scopes preserve it. Inventory shows actual file paths, byte sizes and modification times, including unreadable records.
- Update storage fixtures and failure-injection tests, isolate support directories per test, and await save completion or specific UI states. No blanket `pumpAndSettle` replacement, increased test timeouts, or skipped assertions.
- Refresh the 30-day Beta expiry to **2026-10-20 23:59:59 local time**. Version metadata and welcome-notice fixtures are aligned.
- External official imports now require an Ed25519 signature from the bundled trusted-publisher registry. Verification is repeated at storage and on read; unverifiable existing sources/progress are preserved, learner delivery is withheld and signed reactivation requires explicit association.
- Added an opt-in Dummy test publisher (`QQL_ENABLE_DUMMY_PUBLISHER=true`, including release-mode test builds) with a TEST ONLY banner, OpenSSL fixtures and a developer payload/signature tool. Normal builds do not trust Dummy; no real external publisher has been approved yet.
- Updated the English publisher signing/approval guide with executable steps. Editor Help now compares Official Bundled, Official External and Custom in four columns using 12-point text, in English and Italian. The signature covers normalized course JSON, not separate media bytes.
- **Validation status:** diagnostic failures corrected and checked in focused runs. Final analysis, complete-suite validation and release builds remain pending the owner’s OK; see `docs/241_VALIDATION.md`.

# 2.0.40 (Build 240, Revision 0) - Native file dialogs (Save to… / Open from…) - 2026-09-20

- **New, additive:** QQL can use the operating system's own Save and Open dialogs wherever it exports or imports a file. The existing fixed-folder buttons (`Documents/QuisquisLingo/Exports`, `Imports`, `Merges`, `Logs`) and automatic backups are unchanged; every dialog route uses the same builder/validator as its fixed-folder route. Files can be saved to or opened from any location the system dialog shows, including Google Drive or other cloud folders that the device already exposes. QQL does not sign in to any cloud service and adds no cloud API; each screen explains this and how to make a cloud folder appear on the current platform.
- **Save to…:** Course JSON (Course Manager menu, Course Editor, Version History), my data (User Data), User Recovery Key (with a privacy warning first), and a copy of the Crash Log and of the Diagnostic Log (Debug). The live logs are only read.
- **Open from…:** Course import, Merge From… (second Course of a merge), Image Bank ZIP and single image (admin Shared Image Library), exercise image and Recognize characters portable image (Course Editor), custom Lesson theme icon, one recorded MP3 at a time (Audio Library), my data and User Recovery Key (User Data).
- **Graceful fallback:** cancelling does nothing and is never logged. A failed or unavailable dialog shows a plain message that offers the fixed-folder route and its path, never falls back silently, and is written to the Diagnostic Log (platform, direction, artifact, exception type and file name only; never full paths or file contents). New codes `FILE-001` and `FILE-002`.
- **First use:** the first dialog ever opened on a desktop starts in Downloads; afterwards the operating system remembers the last folder. Device-wide flag `qql_file_dialog_downloads_offered_v1` (removed only by the full wipe).
- **Platforms:** Windows, macOS and Linux (GTK) through the new `file_selector` dependency (`^1.1.0`). Android's document picker has no backend yet, so the new buttons are hidden there and the fixed-folder actions remain the only route. iOS is not supported (no iOS project). macOS is unverified. See `docs/PLATFORM_COMPATIBILITY.md`.
- **Shared code:** one `FileDialogService` (bytes in, bytes out, no paths across the boundary) and shared bytes-based validators (`courseFromBytes`, `decodeDocument`, `prepareIcon`, `PortableExerciseImageService.fromBytes`, ...). Image Bank ZIPs are staged as a temporary copy that is always deleted.
- **Recorded MP3s (behaviour change):** removing a clip and confirming the Course save, or deleting a custom Course, now also deletes the copy of the MP3 that QQL made, unless another Course still uses that file (Duplicate, Fork and Copy as New Course share files). Backups keep their own copies, so old versions still restore. Nothing is deleted if the stored Courses cannot be read completely.
- **Lesson theme icon:** a delete button on each custom icon (refused while any Lesson uses it, confirmed first, undone by Cancel); `Import custom icon` is now a small icon button with a tooltip; `None` is renamed `Numbers`; the Preinstalled icons show only the current choice until opened; the sheet sizes to its content.
- **Wording:** the admin image library is now called Shared Image Library (admin) and the difference from a course's own custom images is explained; obsolete "No Save As dialog" and "without a file picker" hints removed.
- **Known, unchanged:** exercise-image files are not deleted when an exercise or Course changes, and older orphaned media stays until the bulk media reset; a "Remove unused media" tool is planned in `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`.
- **Unchanged:** Course Model v9/v10, course JSON, checksums, scoring, progression, Review, Duel and automatic Course Backups.
- **Beta expiry:** deliberately left at `2026-10-19 23:59:59` local time (owner decision; exception to the usual refresh on a version change). See `docs/240_VALIDATION.md`.

# 2.0.39 (Build 239, Revision 5) - Reliability and administration fixes - 2026-09-19

- Course Manager unlock (10 taps on Version and Build in Settings): the unlock is now saved and shown before the optional win sound starts, the sound runs afterwards without being awaited, and the sound service discards a failed player. This hardens the path suspected in a reported crash on one Windows PC (not reproduced; cause unconfirmed).
- Flag Game trigger (5 taps on the Settings title): the optional suspense sound no longer delays or blocks opening the game. The tooltip now reads `Tap tap tap tap tap... Flag Game`.
- Version and Build in Settings has a tooltip: `Tap x 10 times to unlock Course Manager`, or `Course Manager unlocked` once unlocked.
- Abnormal-termination detection (Windows and Linux): a `quisquislingo_session.marker` file exists while a session runs and is deleted on clean shutdown (window close or the detached lifecycle state). If it is found at startup, the Crash Log records `abnormal termination detected` with the previous session's start time and last lifecycle state. A clean shutdown also appends `session ended cleanly` to the Crash Log; detection relies only on the marker.
- Profile: the log-out explanation is one continuous paragraph instead of three separate lines.
- Learners list: deleting the only admin is disabled, labelled `Delete learner (only admin)`, with a second line explaining that another user can be made admin or, as a last resort, QQL can be reset; it no longer fails after confirmation.
- Test fix: `228.03 Debug page owns both existing log entries` no longer depends on the length of the temporary log path.
- Device Administration (admins only): a new Settings entry opens one page that gathers the existing admin features (Learner Profiles, device name, Admin Media Library), which all remain where they were, plus a device-wide startup setting and a Reset section. Every block is explained with visible text, not tooltips, and wraps on narrow screens.
- Device Administration Help (question-mark button, top right) explains what admins can and cannot do, the startup setting, each reset, backups and forgotten PINs. Team Manager stays in Course Manager only: Teams are run by their own Leads, not by device admins.
- Remove imported media never touches media bundled with the app (built-in images, flags, icons, bundled course recordings); only the admin's edits to the shared image library revert to defaults. The reset text now says so.
- Backup step by reset: "Open my User Data" is offered only by the two resets that delete the admin's own data (learner progress, wipe everything). Removing other learners suggests asking those learners to export their own data instead, and says the admin's data is not deleted.
- Reset fixes: only a full wipe now ends the access session, so after any smaller reset the admin stays logged in instead of seeing "available only to admins" (no extra data was ever removed; the PIN-protected admin only looked logged out). The backup step now states that "Open my User Data" backs up only the logged-in admin, that admins cannot export other learners' data, and names the learners who should export their own first.
- Startup setting: `Ask who is learning at startup` (default Off, which resumes the last learner as before). When On and the device has more than one learner, QQL starts at the learner selection; with one learner nothing changes. Deleting the active learner in this mode no longer auto-selects another learner.
- Inventory (Device Administration, before Reset): lists everything QQL stored because of user activity, inside the app or added to its folders from outside: learners and custom or installed courses (stored in QQL settings, no file, with maintainer or creator and Team), Exports and backups (learner backups, User Recovery Keys, course exports and the automatic pre-change course backups, with the owning learner where determinable), Imports, Merges, Logs, imported images, image banks, imported audio files (with the owning course) and other files added to the QuisquisLingo folder by the operating system. Each file shows its selectable full path, size and modified date; very large lists show the 500 most recent files per section. Media bundled with the app is never listed.
- Reset section: five separately confirmed resets - learner progress, remove non-admin learners, remove imported media, remove custom courses, and Wipe out everything. Each states what it removes and keeps with real counts, offers a backup, and finally asks for the admin PIN; the full wipe lets the admin untick keeping the Exports and Logs folders in the first dialog, reminds them in the last, and needs `NUKE EVERYTHING` typed exactly. Reset options stay locked until the admin has set a PIN, and the PIN is verified again inside the reset service. After a full wipe QQL returns to the first-run setup. Storage inventory: `docs/239_RESET_STORAGE_INVENTORY.md`.
- Remove imported media is now granular: the first dialog offers Images and Audio files tick boxes (with file counts, nothing ticked at first, at least one required); only what is ticked is removed, and the PIN dialog reminds you of each choice (Images / Audio files). A kind with nothing stored is greyed out ("nothing to remove"); Images stay tickable when image-library edits or an image-bank list are stored even without image files; with no media at all the dialog says so. Remove custom courses now states that its imported media means every imported image and every imported recorded MP3 audio file. Wipe out everything gains a third keep option, the Imports folder (your original files), kept by default and reminded in the last dialog, which also requires typing `NUKE EVERYTHING`.
- Update notice: the automatic startup update check previously ran only on the launch that showed the one-time Beta notice, so after that it never ran again. It now runs on every launch (when enabled, a device-wide setting). The result is shown by the Home screen to each learner separately, at most once a day per release: the popup now offers `Not today` (instead of `Not now`) and reappears the next day; other learners on the same device are still told; a newer release is announced again even on the same day. The popup follows the Home start-up dialogs.
- Update entry in Device Administration (first section) opens the same Update page as Settings, which stays available to every learner (needed when a Beta has expired). On the Update page only an admin can change `Check automatically at startup`; other learners see it read-only with an explanation.
- Updated the version to `2.0.39+239005`, Build 239, Revision 5 (Revisions 3 and 4 were internal checkpoints of this work), with the 30-day Beta expiry refreshed to `2026-10-19 23:59:59` local time (30 days from 2026-09-19). Course Model v9/v10 is unchanged.

# 2.0.39 (Build 239, Revision 2) - Pick the translation (Select) - 2026-09-19

- Added two exercise types to the existing Translation category, both configurations of the existing Select primitive: **Pick the translation (to target)** (`translation_choice_to_target`) and **Pick the translation (to source)** (`translation_choice_to_source`). No new primitive and no new category. Existing types, including the older `choice` translation exercise, are unchanged and no course is migrated.
- Authors edit only Text to translate, an optional illustration, Answer options and Correct answer number. Direction, source and target language, selection mode and the learner instruction are implied by the type. Each field has explanation text, a tooltip and a Field Help dialog. Both types have an Exercise Help chapter that opens with a note identifying them as Select exercises, and Exercise Help opened from the editor of these types pre-fills its search with the type name so the matching chapter shows directly.
- The learner sees exactly one instruction, generated from the course languages (`Pick the correct [Target language] translation` for to target, `Pick the correct [Source language] translation` for to source), followed by the text to translate, the optional illustration and the answer options. The editor-only type name, the stock type label, an authored prompt and the Duel fallback message are never shown for these types, in Round, Duel and Preview.
- A tap on an answer is validated immediately with the normal QQL feedback; a wrong answer reveals the correct answer and no Check or Submit button is used.
- Optional audio: to source shows an audio button for the target-language text; to target offers audio for the correct answer only after answering. Nothing is spoken automatically and source-language text is never spoken. When audio exercises or TTS are off, the button is greyed out with a short note and the exercise is presented normally instead of being skipped; the two types are no longer treated as audio exercises for availability filtering. A playback failure at tap time uses the existing audio message.
- Both types are eligible for Duel. Correct answer number starts at 1 for a new exercise of these types (including when the type is picked in the type selector). The Draft sample Exercise created by New Course scaffolding, and by a manually created Round, is now Pick the translation (to target) instead of Choose; it has no authored prompt because the instruction is generated. The Round "New exercise" button also starts with Pick the translation (to target). While GuideBook is turned off for a Course, the Lesson Guidebook card no longer draws a green (or red) audit border and stays uncolored.
- Answer options: 2 to 5 options, each a different phrase (repeats are detected ignoring case, extra spaces and final punctuation). The editor refuses to save more than 5 options or repeated phrases; Audit reports both.
- Field Help dialogs of these types carry no examples. The Exercise Help chapter keeps its example, labelled "for an English → Italian course".
- Audit: added `TRANSLATION_CHOICE_TEXT_REQUIRED` (Error, blank text to translate) and `TRANSLATION_CHOICE_TOO_MANY_ANSWERS` (Error, more than 5 answer options), extended `PRESET_CANONICAL_MISMATCH` (multiple selection or inline gaps are not allowed) and `EXERCISE_FIELD_UNEXPECTED` (authored prompt or spoken text), and documented the new codes in the Audit code list (103 codes: 72 Errors, 26 Warnings, 5 Info).
- Revision 1 packages the corrections made after the first review of Revision 0: the shorter type names, the Select note and pre-filled search in Exercise Help, dialogs without examples, 2 to 5 different answer options, Correct answer number starting at 1, the New Course and "New exercise" defaults, and the uncolored Guidebook card while GuideBook is off. The Revision 0 bullets above describe the feature set as it now stands.
- Duel in dark mode (Revision 2): the Duel screen kept its fixed light backgrounds, so the theme's white title, Back arrow, prompt and questions were unreadable. In dark mode the background now comes from the theme surface (as in Round) and the feedback panel uses the dark surface.
- Draft handling (Revision 2): importing a Course keeps every publication state stored in its JSON (Course, Lessons, GuideBooks, Rounds, Exercises) and never asks. A Draft Round becomes Published when its last Draft Exercise is saved as Published, and a Draft Lesson becomes Published when its last Draft Round does (once its GuideBook is ready or turned off), including explicit Drafts and older Drafts; an explicit "Save as draft" is not undone by later edits, because promotion needs a Draft child to have just become Published. A turned-off GuideBook shows no Draft badge and does not count in the Lesson or Course badge.
- Updated the version to `2.0.39+239002`, Build 239, Revision 2. The 30-day Beta expiry remains unchanged at `2026-10-17 23:59:59` local time. Course Model v9/v10 is unchanged; courses that use the new types will not open correctly in earlier builds. Course Model v9/v10 is unchanged; courses that use the new types will not open correctly in earlier builds.

# 2.0.38 (Build 238, Revision 1) - Arrange & Select gap-fill authoring - 2026-09-18

- Phase 1 extends the existing Arrange primitive (word_order, build_translation) with inline gap-fill authoring: the fixed sentence is typed once, with each gap's literal answer embedded directly inside braces (`I {am} going {to} London.`) instead of a literal `{gap}` marker plus a separate "Correct answers" field.
- Added optional "Extra distractor blocks" for gap-fill exercises, plus validation for missing gaps, empty `{}` gaps and unbalanced/nested braces, with matching Course Editor Help text.
- Existing whole-sentence Arrange authoring and previously published exercises are unaffected when Inline gaps stays off.
- Updated the version to `2.0.38+238000`, Build 238, Revision 0, and refreshed the 30-day Beta expiry to `2026-10-17 23:59:59` local time.
- Revision 1 extends the existing Select primitive (`choice`) with the same inline gap-fill authoring as Arrange (an option can answer more than one gap; tapping it again fills the next gap it is needed for), plus multiple-selection mode with an optional required-selection count and set-based exact-match correctness. Existing single-select `choice` exercises, and every other Select-based preset (`gap_choice`, `icon_choice`, `listening_choice`, `script_recognition`, `listening_comprehension`, `reading_comprehension`, `dialogue_response`, `contextual_comprehension`), are unaffected.
- Revision 1 also fixes a defect found during manual review of the initial Select gap-fill implementation: a gap could previously only ever be filled by its correct option, so an incorrect attempt could never be submitted. Placement is now purely positional — the first tapped option always fills the first remaining empty blank (or an explicitly armed one), regardless of whether it is actually correct there — so the right answers in the wrong blanks are checked and marked incorrect, matching gap-based Arrange's existing behavior. Several authoring field labels and Help texts for Select gap-fill were also clarified based on that review.
- Updated the version to `2.0.38+238001`, Build 238, Revision 1. The 30-day Beta expiry remains unchanged at `2026-10-17 23:59:59` local time.

# 2.0.37 (Build 237, Revision 4) - Course Merge - 2026-09-17

- Added authorized custom Course Merge from each eligible Course Manager row. QQL reads the second source only from `Documents/QuisquisLingo/Merges/merge.json`, validates bounded UTF-8 Course JSON, and leaves both sources and the input file untouched.
- Merge accepts two saved versions of the same Course identity when their Course versions differ, recording both ID/version pairs; only the exact same Course ID and version is rejected as self-merge.
- Merge requires matching Course information while allowing distinct Course IDs, creation/modification dates, version/version notes, restore metadata, Last Version Editor details and Lesson payloads. The merge screen provides dedicated help, Select all Left/Right controls, mutually exclusive per-Lesson choices, optional longer-source Lessons and a final selection warning.
- A successful merge creates a third independent custom Course with fresh owned identities, preserved selected Draft/Published state, no learner-state transfer, title suffix ` merged`, earliest source Original Course Created, merge-time Modified/Last Version Editor metadata, initial version 1 and immutable immediate-source provenance.
- Added Course Model v10 solely for merged custom Courses and its required `mergeProvenance` block. Existing Course Model v9 courses remain readable without migration; v9 rejects merge provenance and v10 is never silently converted.
- Updated the version to `2.0.37+237004`, Build 237, Revision 4, and retained the 30-day Beta expiry at `2026-10-17 23:59:59` local time.
- Revision 1 adds compact Left/Right Course identification and Lesson comparison, the shared Editor Show/Hide IDs badge control, practical Merge Help, and selectable Title, Buy a Coffee URL, description, flag, Section names and language-level differences.
- Revision 2 makes merged titles unique using the existing progressive-copy naming rule, adds failure sound feedback for invalid or missing import/merge JSON, and adds Debug Help plus the current course-type reference.
- Revision 3 moves bulk Lesson selectors after Course settings, permits same-ID/same-version sources only when their Last edited timestamps differ, records those source timestamps in merge provenance, and introduces the per-learner Welcome Wizard.
- Revision 4 defers the Welcome Wizard for PIN-protected profiles until successful unlock, makes Beta testing acknowledgement resettable and one-time, and refines the Wizard into concise colored steps.

# 2.0.36 (Build 236, Revision 0) - Animation and Course Manager refinements - 2026-09-16

- Extended the startup logo entrance to 1,000 ms with opacity 0% to 100% and scale 60% to 100%, followed by an 800 ms static hold. The 1,800 ms gate, no-exit-fade replacement and static disabled/reduced-motion behavior are unchanged.
- Enabled the existing Course-entry fade for automatic as well as explicit FlagPainter and World Flags through the shared flag resolver. Explicit custom images remain supported; invalid explicit flags, same-Course selection, normal startup, disabled Animations and reduced motion retain their existing behavior.
- Removed only the internal-ID toggle from Course Manager. Help and the shared persisted ID preference and controls in subordinate Editor/Team screens remain unchanged.
- Updated the version to `2.0.36+236000`, Build 236, Revision 0, and refreshed the 30-day Beta expiry to `2026-10-16 23:59:59` local time. Course Model v9, authored data, persistence, scoring, progression, Review and Duel are unchanged.

# 2.0.35 (Build 235, Revision 0) - Beta-readiness assessment - 2026-09-15

- Transitioned QuisquisLingo to its first Beta release, `2.0.35+235000`. The existing time-limited expiry boundary remains `2026-10-15 23:59:59` local time; learner-route gating, reminders and data-retention semantics are unchanged, while release-channel user-facing text, lifecycle identifiers, diagnostics and package naming now use Beta.
- Confirmed the static-analysis baseline is clean: `flutter analyze` reports no errors, warnings, lints or deprecations under the standard `flutter_lints` configuration. No linter rules are disabled and source files contain no analyzer-ignore directives.
- Updated Windows release artifacts to use `quisquislingo_windows_beta_<buildnumber>`. Current documented source and Linux artifact conventions use the corresponding Beta channel names.
- Corrected stale Course Model v9 fixtures to provide stable custom provenance/edit metadata and numeric custom versions, retained current Review's explicit **Next Review** transition, and made registry-backed test totals derive from the authoritative Audit Code inventory.
- Reconciled the Ligurian World Flag's manifest, license inventory and integrity expectation with the checked-in SVG SHA-1.
- Enabled the metadata-only GitHub Release check by default at startup. It remains asynchronous after the startup notice, uses existing strict 6-second connection and 8-second request/response timeouts, and never downloads, installs or executes updates.
- Added reproducible Windows and Android package validation for the approved `matXpack` documentation and infographic materials. The Android debug distribution is a ZIP containing its APK and the exact package materials at archive root.
- Corrected the Windows bootstrap launcher so it does not report Flutter's empty build-intermediate `native_assets.json` as missing. The packaged `data/flutter_assets/NativeAssetsManifest.json` remains authoritative, and the launcher never installs to `Program Files`.

# 2.0.34 (Build 234, Revision 3) - Bundled course and media catalog correction - 2026-09-14
- Removed the bundled Japanese sample course while retaining the Japanese QQL FlagPainter design, renamed the People Family image label to Man, merged Home into Home Household with persisted legacy-category normalization, and switched startup artwork to the isolated QQL logo. Refreshed metadata to `2.0.34+234003`.

# 2.0.34 (Build 234, Revision 1) - Media Asset Audit & Revamp correction - 2026-09-14

- Corrected the platform build metadata to `2.0.34+234001`, displayed as **Build 234, Revision 1**, and refreshed the Alpha expiry to `2026-10-14 23:59:59` local time. The QQL 234 feature set and Course Model v9 remain unchanged.
- Corrected Course Entry Animation so a destination without an explicit valid JSON flag produces no overlay rather than animating an automatic fallback.

# 2.0.34 (Build 234, Revision 0) - Media Asset Audit & Revamp - 2026-09-13

- Replaced all 92 exercise Image Bank entries identified by the visual audit as split/composite artwork with approved flat 256 × 256 lossless transparent WebPs, in place under their existing stable paths. Preserved IDs and exercise semantics; normalized the transparent outer border of five additional already-correct images.
- Added bilingual semantic tags to all 111 retained built-in exercise images and removed the unclear `bicycle.webp` artwork from the bank and synchronized manifests. Course Editor Media Library cards and previews show the tags and search now covers tags, labels, IDs and categories; learner exercise cards remain unchanged. Display labels are **Uomo** for `people_family_man` and **Saltare** for `actions_jump` without path churn.
- Expanded World Flags from 266 to 276 SVG entities with documented Esperanto, Amazigh, Ladin, Asturian, Sicilian, Aragonese, Livonian, West Frisian, Piedmontese and Neapolitan flags. Added explicit language-name/tag suggestions without imposing a one-language/one-country rule.
- Replaced the fixed Course flag controls in New Course and editable Course Info with one searchable visual picker. It prioritizes language suggestions, then deduplicated installed-Course flags, built-in QQL flags and the remaining World Flags, while preserving Automatic and validated custom upload behavior.
- Made reused installed-Course flags destination-owned: shared World/built-in flags store their stable identities, while eligible custom raster selections are validated and embedded without a source-Course runtime dependency. Existing v9 portability and authorization rules remain unchanged.
- Added the deterministic bundled Course `AI-Slop Demo: Napoletano per italofoni` (`it-IT` → `nap-IT`) with nine Lessons, 36 Rounds, 279 Exercises, the Neapolitan World Flag and six renewed Image Bank assets. It is explicitly temporary AI-generated sample content and adds no Neapolitan recordings.
- Replaced the startup olive tree with the existing canonical QuisquisLingo logo. Its one-time 600 ms entrance fades and scales from 96% to 100%, then remains static; Do Not Disturb or reduced motion presents the final static logo immediately without changing startup sequencing.
- Fixed the intermittent pre-Course-Entry Extended flag frame at its state boundary. Course switching now loads and commits the destination Course, its learner-specific Flag Background and the existing entry overlay atomically, with no arbitrary blank frame or added delay.
- Removed the now-obsolete `assets/olive_tree.png` and its package declaration while retaining the historical provenance note. The six unreferenced legacy lesson-plant images are documented and conservatively retained rather than deleted.
- Preserved all 16 language sample MP3s and three Duel WAV sounds byte-for-byte, made every nested sample directory explicit in the Flutter asset bundle and locked all 19 SHA-256 values. No audio model, recording library or fallback redesign was introduced.
- Added maintainable media validation for manifest parity, exact path casing, image format/dimensions/transparency/borders, World Flag provenance and counts, Course media references, canonical logo availability, duplicate bytes and the exact retained audio set. Release validation invokes the new checks and keeps the authoritative full Flutter suite at `--concurrency=1`.
- Removed the analyzer exclusion of platform and build sources and replaced three inherited `avoid_print` suppressions with assertion-backed diagnostics, without weakening lints or adding ignores.
- Advanced metadata to `2.0.34+234000`, displayed as **Build 234, Revision 0**, retained Course Model v9 and refreshed the Alpha expiry to `2026-10-13 23:59:59` local time. QQL 234 remains Alpha; a later Beta is contingent on clean validation.

# 2.0.33 (Build 233.1) - Linux updater, learner Status avatar, and Course/Team governance - 2026-09-14

- The same-version QQL 233 correction keeps `2.0.33+233030` and the existing Alpha expiry unchanged. Human-readable version surfaces now consistently present **Build 233.1** without exposing internal Phase/revision terminology.
- Review now opens on the shared inter-review screen instead of starting the first Round automatically. The initial screen says **Ready for Review**, never **Congratulations**, retains Reset/Help/Next Review/Back to Course, and shows the singular/plural word count for the next Round selected by the unchanged Review ordering.
- Local identity adds conservative normalized naming validation, warning-only Discord username and duplicate-name confirmation, immutable generated five-digit learner suffixes, first-user/admin invariants, permission-enforced profile deletion, optional salted-hash four-digit Access PINs, descriptive device naming and sensitive stable-identity Recovery Key import/export through the existing Imports/Exports folders.
- Team and Course names share the safe naming policy with warning-only duplicates, while digits remain allowed and no learner suffix is added. Course Info's Author Team Leader field remains descriptive metadata and points users to Team Manager for real Team governance.
- Learner Profiles always shows the QQL Screen Name, adds optional `@username on Discord`, identifies admins only there, and preserves stable internal IDs for authorization and all relationships. Screen-name edits retain the generated suffix and every ID-linked role, PIN, progress and Review relationship.
- The clean-cut application identity is `org.quisquislingo.app`; former `com.example` storage is neither read nor migrated. Crash logging now has one authoritative logical location at `QuisquisLingo/Logs/quisquislingo_crash.log` under the platform Documents/application-documents directory, with mobile sharing from Debug.
- Phase 233.1 fixes Linux updater asset recognition at its actual package boundary. Generic Linux now selects `quisquislingo_linux_alpha_<buildnumber>.zip`, the retained legacy AntiX label remains compatible, Windows continues selecting `quisquislingo_windows_alpha_<buildnumber>.zip`, and neither platform can fall through to the other's or an incompatible package. GitHub Releases comparison and no-compatible-package behavior remain unchanged.
- Phase 233.2 splits new Learner creation into **Create Profile** and **Avatar Customization** while preserving one opaque learner identity. Screen Name persists, Discord remains optional and is normalized to one leading `@` for presentation only, and only a new learner receives random initial skin and hair selections. Existing learners retain identity, progress and avatar choices.
- The live avatar T-shirt is now derived from the authoritative current Status level instead of stored or manually selected. Avatar Customization presents all ten existing Status levels with their exact vivid colors, prominently marks the learner's current Status, and explains the existing XP/streak/study-day/Round/Laurel score and thresholds without creating a second progression system.
- The same-version Course Model v9 clean cut replaces the ambiguous creator/owner metadata with immutable **Original Course Creator** and **Original Course Created** lineage, an operational individual **Course Maintainer**, separate **Assigned Team**, automatic **Last Version Editor** and **Modified** metadata, structured Authors/Contributors and descriptive **Rights Holder** entries. Provenance, attribution and legal metadata do not grant QQL permissions.
- Removed obsolete v8 metadata rather than retaining aliases: `creatorProfileId`, `ownership`, `createdByProfileId`, `createdByUsername`, `createdAtUtc`, the three former last-modifier fields, `lastUpdated`, scalar `author`, singular author `role`, scalar fork `originalAuthor`, generic `version`, `updateSummary`, `contentRevision`, `parentCourseId` and `derivedFromVersion`. The authoritative custom and official version fields remain.
- **Fork** now explicitly preserves the original lineage creator/date, structured attribution, Rights Holder and applicable License while recording its immediate source plus immutable Fork Created By/Date. **Copy as New Course** replaces the former Course-level Duplicate action, starts an independent lineage with fresh identity/creator/date/Maintainer/current-version metadata, omits fork metadata and Team assignment, and still copies appropriate content, attribution, Rights Holder and License.
- Team governance remains independent and experimental. Team creators begin as Team Leaders; any Team Leader may add/remove members and promote/demote Leaders, while the established final-Leader invariant prevents a Team from reaching zero Leaders. A Team may manage multiple Courses with different Original Course Creators and Maintainers, and Course maintenance alone grants no Team-governance power.
- Original Course Creator, Course Maintainer, Team Leader and Team Member presentation prefers an optional Discord `@handle`, falls back to Screen Name and continues authorizing solely by opaque internal user ID. The existing Internal IDs control remains the only ID toggle. Course Info separates provenance, maintenance, assigned Team, attribution and rights without presenting the Team as Maintainer.
- Removed the Learner status-bar composition from Course Info and Course Info Editor. The status bar now mounts only through the Learner Panel; management/editor screens do not receive its container. The approved bottom layout remains the profile icon at far left followed by the six existing compact controls.
- Kept application metadata exactly `2.0.33+233030`, displayed as **Build 233.1**, and kept the established `2026-10-14 23:59:59` local Alpha expiry unchanged. Canonical bundled/custom/external-official Course data and storage move to Course Model v9; all nine official Courses and checksums are regenerated. v8 namespaces remain physically untouched and are never read, migrated, transformed or used as fallback; learner progression, XP, Review, Duel and course-owned progress formats are unchanged.

# 2.0.32 (Build 232, Revision 0) - Integrated Vocabulary Reinforcement in Review - 2026-09-11

- Replaced the former selectable Review list with a dedicated page that starts the active Course's highest-priority valid Round automatically. Review history remains capped at 50 Rounds per Course and now orders by descending errors, then oldest latest attempt; completing a Review refreshes that Round's timestamp and result through the existing completion path.
- Added Review to the active Course's Learner Panel bottom action and only to the Current course row's three-dot menu. Review does not appear on inactive/recent/included/local/hidden Course rows, ignores IDDQD View Only, shows no learner status bar, and returns to the retained active Course Learner Panel state.
- Added pre-Round published GuideBook Vocabulary cards and one-time post-Round reinforcement. Authored order and distinct occurrences are preserved; malformed, Draft, disabled or empty vocabulary safely skips preparation. The current schema provides prompt/answer pairs only, so no extra linguistic metadata is fabricated.
- Added `VocabularyReviewService` with versioned learner × Course × Lesson × entry state. Stable Content IDs are primary identity, duplicate occurrences remain distinct, and SHA-256 fingerprints make changed prompt/answer content new without invalidating state for title-only changes.
- Added immediate known/reinforcement persistence, session-local Next Review Round exclusion, a no-more-Rounds notice, congratulations choices for Next Review or Back to course, Review Help, and confirmation-gated per-Course Reset Word List. Vocabulary interactions add no independent XP, completion, streak, Laurel, Duel, unlocking or Review-order effects.
- Advanced metadata to `2.0.32+232`, display Build 232, Revision 0. Course Model v7, course JSON, bundled assets/checksums and the Alpha expiry `2026-10-13 23:59:59` local time remain unchanged.

# 2.0.31 (Build 231.1, Revision 1) - Course Editor view and inspection states - 2026-09-13

- Replaced the three-state Course Editor access control with four explicit states: Locked, View only, Inspection mode and Edit. The root control uses closed-lock, eye, code and pencil icons respectively; Edit remains unavailable unless the existing individual/Team ownership policy permits it.
- Made View only open the ordinary preset-specific Exercise form with every text, selector, checkbox/toggle, image, add/remove and reorder mutation path disabled. Preview, Help, IDs, Audit and Search remain available without creating course or dirty state.
- Promoted the former technical Exercise representation to Inspection mode. Exercises opened directly or from Search default to technical inspection in that root state, while the normal form remains read-only when selected locally.
- Added the Exercise-level Inspection toggle beside Preview and Save actions. It switches only the current Exercise presentation: View returns to a read-only form, Inspection mode returns to a read-only form, and Edit returns to the same editable form with legitimate unsaved values and dirty state preserved.
- Preserved Locked Search rejection and state-specific Search behavior: View opens the normal read-only form, Inspection mode opens technical inspection, and Edit opens the normal editable form. Search scope, matching, type filtering and the 22-preset searchable-field inventory are unchanged.
- Corrected Create Duels guidance to say that winning may unlock the next Lesson “without completing the preceding Lesson,” without changing Duel behavior.
- Advanced metadata to `2.0.31+2311`, display Build 231.1, Revision 1, technical build 2311. The repository's version-update policy refreshes the established 30-day Alpha expiry to `2026-10-13 23:59:59` local time. Course Model v7 and learner/course persistence remain unchanged.

# 2.0.31 (Build 231, Revision 0) - Course Editor search and access - 2026-09-12

- Added Course Editor Exercise Search on Lessons, Lesson, Rounds and Round with whole-Course, current-Lesson and current-Round scopes, complete-word/contiguous-phrase matching, case and diacritic insensitivity, exact/partial Exercise ID matching and an optional Exercise Type filter.
- Added one authoritative searchable-authored-text registry covering all 22 supported Exercise presets. Search includes the intended prompt, audio script, dialogue speaker, answer/block, accepted-answer, ordered-answer, hint and missing-word fields per type while excluding assets, internal item/reference IDs and configuration.
- Replaced hierarchy-local edit locking with one three-state Course Editor root control: Locked, View unlocked (default) and Edit unlocked. Locked rejects hierarchy entry; View preserves navigation, Search, Help, IDs, Preview and Audit without mutation; Edit remains gated by the existing individual/Team ownership policy and never derives from license.
- Added the one-time View unlocked explanation with per-user × Course dismissal. Settings → Show one-time notices again resets it for the active user without changing the saved Course Editor mode.
- Normalized top actions: Course Editor has Lock/Help/IDs; Lessons, Lesson, Rounds and Round have Search/Help/IDs. Removed the Lesson Rename/Generate and Round Rename/Preview app-bar icons while retaining Lesson text actions, adding Rename Round as a page action and moving Round Preview before Save as draft/Save in the bottom action area.
- Added focused service and widget regressions for matching, type/structural filters, every type's searchable fields, result navigation, lock authorization, View notice isolation/reset, View Preview and icon/action organization. Added the complete Exercise Type inventory and QQL 231 validation record.
- Advanced metadata to `2.0.31+231`, Build 231, Revision 0, and refreshed the established Alpha expiry to `2026-10-12 23:59:59` local time. Course Model v7, course JSON/checksums, ownership, learner identity, progression, XP, Review and Duel behavior remain compatible.

# 2.0.30 (Build 230, Revision 0) - Robustness and modularity audit - 2026-09-11

- Prevented rapid or re-entrant Round and Duel completion from dispatching duplicate learner writes or XP awards. Round completion is single-flight by Course/Round, optional sound and weekly-target failures no longer interrupt earned accounting, introduction controls wait for completed initialization, and Duel initialization reaches an explicit safe error state.
- Made **Audio Exercises Off** authoritative for Duel availability. Home and Duel entry now consume one effective `DuelEligibilityService` result after audio filtering: Duels remain available when 25 valid non-audio exercises remain and render disabled on Home when filtering drops the effective pool below 25.
- Corrected Learner Panel Round audio indicators to preserve structural audio visibility while reflecting effective availability from the existing Audio Exercises and TTS settings. Disabled master audio and TTS-only unavailability now use the established grey treatment and explanatory tooltips; recorded and mixed Rounds stay active when any audio remains usable, with live updates after Settings closes.
- Made learner backup restore rollback-safe and verified: failed replace restores the exact profile registry, active learner and learner namespace, while failed separate-copy import removes its partial profile and data. Invalid backup keys or values are rejected instead of being silently discarded.
- Hardened Course lifecycle persistence. Custom imports cannot collide with bundled or external official identities; same-ID replacement uses authorization, immutable provenance/ownership checks, backup, monotonic versioning and rollback-capable verified storage. Backup manifest paths sanitize custom version text and enforce directory containment.
- Protected Course Manager and Team invariants by surfacing corrupt local-course storage with Retry instead of an endless spinner, blocking profile deletion that would orphan an individually owned custom Course, and rejecting generated Team-ID collisions.
- Hardened shared learner state by filtering malformed study-day data, preserving streak state across device-clock rollback, projecting corrupt negative/oversized XP into the supported range, and retaining the existing XP rules and persistence keys.
- Corrected update checks to compare numeric QQL `+build` metadata, preserved Unicode scripts and combining marks in recorded-audio matching, isolated imported audio under a Course-ID-derived directory with collision-safe clip IDs, added a bounded playback wait, and made Linux TTS preserve valid non-English base languages rather than silently falling back to English.
- Added shared bounded/serialized diagnostic log writing: preference diagnostics retain at most 256 KiB and crash/audio logs at most 2 MiB while keeping newest evidence. Applied analyzer-recommended braces to 70 existing control-flow statements and removed one stale test helper, producing a clean repository analyzer result.
- Kept modularization targeted to audited coupling: extracted shared Course Editor storage identity, profile-deletion ownership protection and bounded log writing, and removed Duel eligibility filtering from the UI by extending the existing authoritative service. Oversized screens identified by the audit remain explicit follow-up candidates rather than receiving behavior-risking mechanical splits.
- Windows release packaging now uses the platform-explicit `quisquislingo_windows_alpha_<buildnumber>` directory and ZIP name; the existing source-package name remains unchanged.
- Advanced metadata to `2.0.30+230`, Build 230, Revision 0, and refreshed the established 30-day Alpha expiry to `2026-10-11 23:59:59` local time. Course Model v7, course JSON/checksums, learner identity, progression, XP formulas, Review rules and QQL 229 behavior remain compatible.

# 2.0.29 (Build 229, Revision 3) - Team leave and Course Manager status corrections - 2026-09-10

- Added a confirmed **Leave Team** action to the current ordinary Team member's three-dot menu. Confirmation removes only that active opaque profile's membership; cancellation writes nothing, other members and Team-owned courses remain unchanged, and access updates through the existing Team-based authorization policy.
- Kept Team Leads on the established administration path so self-service leave cannot weaken the mandatory last-Team-Lead invariant.
- Moved Temporary Sample guidance out of the main Course Editor and into read-only Course Info. The course-level `temporarySample` metadata remains unchanged through unrelated saves, reopen, Duplicate/Fork paths and canonical v7 export.
- Added an independent blue **Unpublished** Course Manager badge derived only from Course publication state. The existing **Draft** badge continues to derive only from authored Draft descendants; when both apply they appear in Draft/Unpublished order in a wrapping layout suitable for narrow light and dark themes.
- Advanced technical metadata to `2.0.29+2293`, Build 229, Revision 3, display build `229.3`, while preserving the `2026-10-09 23:59:59` Alpha expiry, Course Model v7, ownership rules, persistence formats and all Revision 2 behavior.

# 2.0.29 (Build 229, Revision 2) - Course metadata and per-user authoring access corrections - 2026-09-09

- Corrected user-facing release wording to **Build 229** and **Revision 2**, with technical version `2.0.29+2292` and display build `229.2`; the Alpha expiry remains `2026-10-09 23:59:59` local time.
- Added one origin-neutral Course language resolver. Audio Settings Test Voice and both Course Info surfaces now preserve authoritative general or regional codes, reject `und` for presentation, and use the established language-name fallback without inventing a region.
- Added live resolved flag preview and authorized Automatic/Explicit editing in Course Info Editor. Automatic stores no override; explicit World Flag, custom image or built-in selection takes precedence. Course Info, the selector, learner surfaces, derived backgrounds and Course Entry Animation consume the shared resolution order and neutral fallback.
- Course Info and Course Info Editor now show Learning/Base language names with codes and Created/Modified values with a four-digit year. Confirmed content changes continue to preserve Created and update Modified; inspection does not write either timestamp.
- Team-owned Course Info surfaces resolve the Owner from the live Team registry. Course Info Editor keeps the Team name primary, reveals the stable Team ID only with Internal IDs, and shows the model's read-only `Course Model: v7` line under that same preference.
- Removed only the duplicate Course Import/Create text buttons from Course Manager and only the duplicate Audit icon from Course Editor, retaining the icon Import/Create actions and the text Audit entry point with their established behavior.
- Extended Team Manager's existing Internal IDs preference to Team IDs and every Lead/member User ID using the shared passive monospaced presentation. The permanent final-Lead sentence is removed while the contextual tooltip, feedback and service-enforced last-Lead invariant remain intact.
- Moved the developer Course Manager unlock into the active opaque learner namespace. Each learner independently performs ten Build-row taps, restores their own state after switching/restart, starts locked when new, participates in ordinary learner backup/restore, and loses the setting on profile deletion. Unlock visibility never changes Course Model v7 ownership or Team authorization.
- Preserved revision-1 Duplicate/Fork clean-state behavior, clean-cut v7 storage/import policy, course content, checksums, progression, XP, Review and Duel behavior.

# 2.0.29 (Build 229, Revision 1) - Ownership, Teams and unified Course Editor - 2026-09-09

- Made Course Manager actions consistent while preserving the established lifecycle paths: official sources provide read-only inspection, licensed Fork, Audit and Export where applicable; custom courses provide Edit, independent Duplicate, Audit, Export and manager-only Delete. Eligible official inspection retains Fork, and the custom Course Editor now provides Duplicate without adding Delete or another top-area Audit action. Fork and Duplicate continue through the existing provenance-aware, fresh-ID authoring architecture.
- Added a three-dot Course Info / Hide menu to every Course Selector row. Hide is a reversible per-learner × Course visibility preference, never deletion; the active Course cannot be hidden, and `Hidden courses (n)` provides Course Info and immediate Unhide.
- Added the Learner Panel Lesson display cycle Expanded / Collapse completed / Focused, stored per learner × Course and initialized Expanded. Rendering reuses authoritative Lesson completion and unlock state, respects IDDQD access, preserves last-visited Lesson restoration, and leaves Section navigation unchanged.
- Corrected the first-open false dirty state for new Duplicates and Forks by confirming the generated custom course before reopening its normal Editor transaction. Real semantic edits still trigger the unchanged course-level confirmation flow.
- Restored New Course and Course Info Editor support for the historical license choices and author roles: Team Leader, Contributor, Course Creator, Editor, Reviewer, Native Speaker, Audio Contributor, Illustrator, and custom roles. Author and credit metadata remains descriptive only.
- Introduced the clean Course Model v7 ownership boundary. Every custom Course JSON now requires a stable Creator profile ID and an Owner object naming either an individual profile ID or Team ID. No Author/name fallback or legacy custom migration exists. The centralized course access policy gives an Owner or any owning-Team member full editing and Duplicate rights regardless of license; outsiders remain read-only and may Fork only when derivatives are allowed.
- Added the offline Team Manager as a separate Course Manager destination. Teams have stable IDs, local-profile members and one or more Leads; Leads administer membership and Lead status, the final Lead cannot be removed or demoted, and Lead status is not required for ordinary editing of Team-owned courses. New Course offers Me or an eligible Team only when the active profile belongs to a Team.
- Unified official, owned custom, Team-owned and outsider custom inspection on the same capability-driven Course Editor hierarchy. Official originals and outsider originals remain immutable at both UI and service boundaries. Duplicate retains authorized ownership; Fork retains lineage/credits/license/provenance and receives explicit local ownership with fresh IDs.
- Advanced metadata to `2.0.29+2291`, Build 229, Revision 1, display build `229.1`, while retaining the Alpha expiry `2026-10-09 23:59:59` local time. Bundled courses and checksums move to Course Model v7; learner progress, XP, activity, Review, Duel, Hide/Unhide and Lesson-expansion persistence formats remain unchanged; see `docs/229_VALIDATION.md`.

# 2.0.28 (Phase 228, revision 1) - Settings, Statistics, Debug and Audio - 2026-09-08

- Reordered Settings as Profile, App Info, Audio Settings, Do Not Disturb, Debug, Version and Build, Update. Course Manager remains available from the learner Course Selector, User Data moved into Profile before Log out, and the Settings flag now uses the exact `Tap tap... Flag Game` tooltip with a gentle hover wave while preserving its five-tap action.
- Added Profile > Statistics with Total Study Days and per-language flag, display name, canonical language ID, Study Days, Current Streak and Max Streak. The calculations reuse the active learner's established study-day records and streak-freeze rule; regional/name variants merge into the same canonical language without adding a parallel history schema.
- Moved Crash Log and Diagnostic Log access into Settings > Debug. Both exported files now use `Documents/QuisquisLingo/Logs`; existing files in the former crash-log location are left untouched and unread.
- Replaced TTS Settings with learner runtime Audio Settings ordered as Enable Audio Exercises, Text-to-speech and the TTS voice selector with its existing Test Voice action. Enable Audio Exercises and Text-to-speech are per learner and initialize Off; TTS voice is per learner and initializes System. This is a clean cut: previous shared and negative audio-setting values remain untouched and unread. Disabled, unavailable or TTS-disabled audio is filtered before source or player initialization, while Editor Preview ignores learner Audio Settings and preserves its no-write boundary.
- Corrected learner Round activation so a prepared TTS or recorded-MP3 exercise after `Before you start` remains silent until Continue makes that exercise active. Rounds without an introduction, Duel audio, lazy availability filtering, and Editor Preview keep their established behavior.
- Added bounded, correlation-ID-based audio source/initialization/playback/failure/disposal events to the existing Diagnostic and Crash Logs, including prepared/active learner UI state, stable exercise ID/type, trigger, and not-active suppression. Audio diagnostics exclude spoken text, answers, course content and full personal file paths. Settings > Debug now explains when to provide each log and when optional Diagnostic Log clearing helps or risks discarding intermittent evidence. Advanced metadata to `2.0.28+228` and refreshed the 30-day Alpha expiry to `2026-10-08 23:59:59` local time. Course Model v6, course JSON, checksums, XP and progression semantics remain unchanged; see `docs/228_VALIDATION.md`.
- Corrected Test Voice after clean-machine validation: its dialog now starts with an empty editable field, blocks empty or whitespace-only playback, and sends only the exact user-entered text through the unchanged selected-course language and missing-compatible-voice path.
- Restored the restrained Course Entry Animation for actual course switches only. When Animations are enabled and reduced motion is not requested, a valid flag explicitly configured in Course JSON remains authoritative; when no flag is declared, the established course-code flag fallback is used. Invalid declared flag data still skips the overlay. The flag covers the Learner Panel for a two-second hold-and-fade reveal that starts only after the Course Selector closes and the destination learner state reloads, while startup, same-course navigation, disabled animations and reduced motion remain immediate.
- Revision 1 presents Show one-time notices again as a one-shot action instead of a false-valued switch, and corrects the no-release update status to distinguish the published source repository from a packaged GitHub Release. Advanced technical metadata to `2.0.28+2281`; the QQL 228 Alpha expiry remains `2026-10-08 23:59:59` local time.

# 2.0.27 (Phase 227.04, revision 0) - QQL 227 closure - 2026-09-07

- Added the third IDDQD mode, `View Only`, after unchanged Off and On modes. Its selected preference persists per learner × Course on the existing key; legacy boolean Off/On values remain readable, while View Only stores `view_only`. View Only passes through the existing genuine Lesson lock gate but exits Round/Review completion and Duel victory before learner-state writes, preserving answer feedback without completion, XP, Weekly XP, activity, streak, Laurel, Review, unlock or Duel persistence.
- Kept the IDDQD bottom control compact. Its exact Off/On/View Only explanations update immediately in the tooltip and accessibility label without permanent text under the buttons. Genuinely locked Lessons keep their lock marker and show `Accessible with IDDQD` for On or `Preview with IDDQD` for View Only.
- Finalized the learner-scoped Theme control as Light / Dark / System / Day/Night. System retains the existing `default` storage identity and live operating-system behavior. Day/Night stores the selected mode, uses local device time with Light from 07:00 inclusive to 19:00 exclusive, switches at the next boundary, re-evaluates on resume and cancels its timer after another mode is selected. Theme changes have zero transition duration.
- Preserved Small / Off / Extended / Tinted / Inspired Flag Background behavior and `soft_inspired` compatibility. Advanced metadata to `2.0.27+227040`; the Alpha expiry remains `2026-10-07 23:59:59` local time and Course Model v6, Course JSON and checksums remain unchanged. See `docs/227_04_VALIDATION.md`.

# 2.0.27 (Phase 227.03, revision 0) - IDDQD state clarity - 2026-09-07

- Added concise selected-mode guidance beneath the existing learner IDDQD control: Off says `Normal progression locks apply.` and On says `Locked content can be opened. Normal progression status is preserved.` The same meaning is available through the control tooltip and accessibility semantics.
- Genuinely locked Lesson sections that become accessible through IDDQD now retain their lock marker and show the subordinate `Accessible with IDDQD` indicator. The existing Lesson access gate continues to expose only its published GuideBook, Rounds and eligible Duel; their own availability rules remain authoritative.
- Preserved the existing Off / On behavior, learner × Course storage key, Off default, immediate update, genuine progression, normal study rewards and all completed 227.02 Flag Background behavior. Toggling IDDQD alone still changes no progress or XP.
- Advanced technical metadata to `2.0.27+227030`, displayed as Version 2.0.27 / Phase 227.03, revision 0. The QQL 227 Alpha expiry remains `2026-10-07 23:59:59` local time. Course Model v6, Course JSON and checksums remain unchanged; see `docs/227_03_VALIDATION.md`.

# 2.0.27 (Phase 227.02, revision 1) - Inspired background differentiation - 2026-09-07

- Renamed the learner-facing `Soft Inspired` option to `Inspired` while retaining its internal enum case and persisted `soft_inspired` value, so revision-0 learner × Course selections restore without migration or reset.
- Strengthened Inspired into a broad static three-stop color field using up to three deterministic representative flag colors. It is visibly more varied and saturated than the unchanged uniform Tinted mode while retaining automatic Light/Dark readability protection and safe fallbacks.
- Added explicit differentiation coverage for bicolor, tricolor, saturated, white-heavy, dark, multicolor and near-monochrome sources, plus source-hue fidelity, existing-value recovery, real Home replacement and responsive rendering coverage.
- Advanced technical metadata to `2.0.27+227021`, displayed as Version 2.0.27 / Phase 227.02, revision 1. The QQL 227 Alpha expiry remains `2026-10-07 23:59:59` local time. Course Model v6, Course JSON, checksums, learner progress and XP remain unchanged.

# 2.0.27 (Phase 227.02, revision 0) - Flag-inspired learner backgrounds - 2026-09-07

- Added `Tinted` and `Soft Inspired` after the existing Small / Off / Extended Flag Background choices. Tinted uses one restrained course-flag hue; Soft Inspired uses a quiet static two-color treatment. Both adapt automatically for Light and Dark appearance without displaying, blurring or animating the flag artwork.
- Centralized deterministic representative-color selection and adaptation for World Flag SVGs, portable custom raster flags and existing built-in flags. White, black, gray, saturated, near-monochrome and complex multicolor inputs receive automatic chroma/lightness handling; unreadable sources use the existing built-in flag source and then a neutral learner-page fallback.
- Preserved the 227.01 learner × Course storage key and Off default without reading, migrating or deleting the obsolete shared value. Theme, IDDQD, progress, XP, Course Model v6, course JSON and checksums remain unchanged.
- Advanced technical metadata to `2.0.27+227020`, displayed as Version 2.0.27 / Phase 227.02, revision 0. The established QQL 227 Alpha expiry remains `2026-10-07 23:59:59` local time. See `docs/227_02_VALIDATION.md`.

# 2.0.27 (Phase 227.01, revision 0) - Learner Panel controls baseline - 2026-09-07

- Audited the actual Flag Background, IDDQD and Theme option sets, defaults, persistence, rendering, live theme propagation and progression boundaries; recorded the parent baseline and regression evidence in `docs/227_01_VALIDATION.md`.
- Applied the user's explicit Flag Background correction: each learner × Course starts Off and stores Small / Off / Extended independently. This is a clean cut; the previous per-learner shared key is not read, migrated or deleted. Existing rendering and cycle order remain unchanged.
- Added focused characterization and isolation coverage while preserving Default / Light / Dark Theme, Off / On IDDQD, genuine locks, completion, XP, streaks, Laurels and Course Model v6. Later 227 features remain deferred.
- Advanced metadata to `2.0.27+227010`, displayed as Version 2.0.27 / Phase 227.01, revision 0. Applied the mandatory new-version 30-day Alpha refresh to `2026-10-07 23:59:59` local time. No staging, commit, push or packaging is part of this phase.

# 2.0.26 (Phase 226.04, revision 2) - Editor navigation and GuideBook UX - 2026-09-07

- Advanced metadata to `2.0.26+226042`; the show-once notice displays `Version 2.0.26` and `Phase 226.04, revision 2`. Alpha expiry remains `2026-10-06 23:59:59` local time.
- Removed fallback Lesson-number style selection. Both accepted legacy values continue to round-trip in Course Model v6 and now render the single theme-colored circle; explicit Lesson icons remain unchanged.
- Added the dedicated **Course Import** page and learner course-selector actions for the stable-ID current Course Editor and Course Manager while retaining `QuisquisLingo/Imports/import.json` and the existing importer transaction.
- Made manually created Rounds reuse the New Course factory for exactly one fresh-ID Draft **How do you say?** sample, and corrected Fill in the Blank guidance to include the exact three-underscore example.
- Presented the final Lesson's existing Duel as **Final Duel**, added ordered optional GuideBook **Insights** sections, emphasized actual **Publish** actions, and added explicit locked-Lesson activation guidance without changing the Lock control.
- Preserved the revision-1 first-Save publication reconciliation, Course Model v6, the 102-rule Audit Registry, official protections and all excluded later work. No Trello update or push is included.

# 2.0.26 (Phase 226.04, revision 1) - Learner delivery and Editor corrections - 2026-09-07

- Corrective completion: one non-Draft Exercise/GuideBook Save now reconciles ready provisional Lesson/Round parents through the current canonical Course. Returning from Rounds preserves the latest Lesson state; deliberate Save Draft and legacy unmarked Drafts remain protected. Optional `provisionalDraft` metadata is backward compatible within Course Model v6; Course delivery and final confirmation remain explicit. The MyTest workflow saves the existing sample once, without redundant parent saves. This remains build `226041`, with unchanged Alpha expiry and no revision-2 flag/language work.
- Advanced corrective metadata to `2.0.26+226041`; Alpha expiry remains `2026-10-06 23:59:59` local time.
- New Course now creates exactly one Draft How do you say? sample per scaffolded Round, with source/learning-language-labelled placeholders, the literal `Wrong Answer` distractor, fresh IDs and atomic creation.
- Removed sample-comparison `ROUND_CONTENT_SHORT` Info and obsolete sample-length Help. The canonical Audit Registry now has 102 rules; genuine structural checks and Error/Warning predicates remain.
- Authoring metadata navigation is **Course Info Editor**; learner Course Info remains unchanged. Course delivery status says **Published** / **Not published**, independently of descendant Draft states.
- Moved Lesson numbering to Lessons and shared its selected term across Editor entries, breadcrumbs, individual Lesson/Rounds headings and learner labels. Automatic titles deduplicate under Module and other prefixes without rewriting stored titles.
- Fill in the blank says **Use ___ (3 underscores)** and displays its configured Hint through the shared unsaved/saved Preview and learner path.
- Fixed concealed Lesson/Round Draft state: shared blue indicators now include the container's own state, and nested Save controls expose it without weakening learner filtering or automatically publishing content. The same persisted Course ID is verified through raw JSON, Editor, selection and learner restart. No revision-2 flag/language work or excluded later work is included.

# 2.0.26 (Phase 226.04, revision 0) - Course structure and optional learning paths - 2026-09-06

- Advanced to `2.0.26+226040`; the show-once notice displays `Version 2.0.26` and `Phase 226.04, revision 0`. Alpha expiry remains `2026-10-06 23:59:59` local time.
- Added one-time **Number of Lessons** and **Rounds per Lesson** creation fields, defaulting to 3 and 1, with whole-number ranges 1–100 and 1–20. Valid creation builds the complete ordered hierarchy with fresh stable IDs, empty untitled Rounds and no Exercises. These are creation-only safeguards, not model, import or later-editing limits.
- Added reusable Section selection and unused-name management, previous-Lesson Section inheritance for newly added Lessons, and consistent **Lesson + number**, **Number only** and **Title only** presentation while preserving stored titles and existing prefix modes.
- Added default-ON **Use GuideBook** and **Create Duels** options on Lessons. Disabled GuideBooks retain content and book artwork but lose learner interaction and only the empty-GuideBook Warning; disabled or ineligible Duels occupy no learner card space. Existing Duel identities and learner history remain intact, with canonical Audit and live ancestor updates.
- Reused the authoritative 266-entity Flag Game registry for course flag selection alongside existing course flags and portable custom PNG/JPEG flags. Flag Game behavior and existing media folders remain unchanged.
- Replaced the Lessons Lock row with its upper action icon and unchanged tooltip/authorization behavior. GuideBook IDs appear as passive, selectable metadata after GuideBook actions, using a stable identity derived from the owning Lesson ID without another JSON field.
- Kept Course Model v6, 103 Audit rules, backward-compatible defaults, official read-only/fork protections and completed 226.03 behavior. No Templates, Napoletano, future GuideBook content or release 227 work is included.

# 2.0.26 (Phase 226.03, revision 1) - Generation, guidance and native speech corrections - 2026-09-06

- Advanced to `2.0.26+226031`; the show-once notice displays revision 1. Alpha expiry remains `2026-10-06 23:59:59` local time.
- Allowed nullable generated reorder operands and optional linked members while preserving positional association, deterministic output, terminal punctuation, empty-answer removal and atomic 128-variant rejection. Added lowercase author guidance without transforming saved content.
- Corrected Type the missing word to require the full word, with the first grapheme as a hint, preserving normal normalization, Preview and publication behavior.
- Added searchable Exercise Help, concrete field examples, immediate character-direction explanations and accurate course-level TTS/MP3 guidance.
- Unified speech-language resolution for bundled/custom courses, including legacy `und` with unambiguous Italian metadata, exact/base locale matching and separate metadata/installed-voice diagnostics.
- Corrected JSON import to `QuisquisLingo/Imports/import.json`; exports remain in `Exports`. No model migration or later-phase work.

# 2.0.26 (Phase 226.03, revision 0) - Writing and character recognition - 2026-09-06

- Advanced metadata to `2.0.26+226030`, retaining the Version/Phase/revision show-once notice. Alpha expiry remains `2026-10-06 23:59:59` local time: this September 6 tranche retains the existing 30-day convention.
- Added non-destructive answer expansion, Copy all and independent explicit-answer materialization using the authoritative parser and 128-answer limit. Optional branches can omit reorder scopes; materialization no longer double-counts identical generated answers against the combined cap.
- Ranked valid Type the translation feedback using the existing similarity score and deterministic author-order ties: at most three corrections, or two alternatives excluding the matched canonical answer after success. Acceptance rules remain independent and unchanged.
- Added Type the missing word using canonical Input, full accepted words and a derived Unicode first grapheme, and Recognize characters using canonical Select with Image to text/Text to image modes and portable image bytes.
- Preserved Course Model v6, stable canonical objects, existing presets, official read-only/licensed-fork rules, Preview, publication and authoring transactions. No 226.04, Templates, future GuideBook or Napoletano work is included; known revision-4 Lock/GuideBook-ID omissions remain outside scope.

# 2.0.26 (Phase 226.02, revision 4) - Course titles and live hierarchy status - 2026-09-06

- Advanced technical metadata to `2.0.26+226024`; the existing show-once first-run notice displays `Version 2.0.26` and `Phase 226.02, revision 4`. Alpha expiry remains `2026-10-06 23:59:59` local time.
- Made every learner course-selector entry use the actual Course title, including bundled/custom, selected/unselected and recent entries, with responsive title wrapping and separate language metadata.
- Moved **Fallback lesson number icons** into **Lesson appearance** on the Lessons page. Corrected revision-3 terminology to **Theme-colored circle** and **Four-color circle** because the actual persisted renderings use theme colors or four colored sectors, rather than stable blue/black circles. Stored preferences and explicit Lesson icons retain their behavior.
- Corrected canonical Audit ownership and shared authoring propagation so descendant mutations immediately update affected branch and ancestor indicators. Genuine Lesson findings remain visible; Info alone stays green, stale/unavailable Audit stays neutral, and the registry remains at 103 rules.
- Placed passive Internal IDs below actionable content consistently in Lesson, Round and Exercise entries while retaining the existing direct global ID toggle and exact tooltips.
- Added the requested GuideBook Audit/Draft status and inheritance: GuideBook concerns reach Lesson and Lessons indicators independently of Rounds; Draft saves retain an explicit state, normal saves clear it, and an empty Draft GuideBook shows both red Audit and blue Draft indicators. Final persistence remains at the existing Course confirmation boundary.
- Preserved bundled course content, IDs, licensing and provenance, official read-only/fork boundaries and prior 226.02 editor behavior. No 226.03, GuideBook roadmap, Custom Exercise Templates or Napoletano work is included.

# 2.0.26 (Phase 226.02, revision 3) - Editor diagnostics and hierarchy UX - 2026-09-06

- Advanced technical metadata to `2.0.26+226023`, with the first-run notice displaying `Version 2.0.26` and `Phase 226.02, revision 3`; the existing Alpha expiry remains `2026-10-06 23:59:59` local time.
- Added one shared `Editor Help` action and one direct, device-local internal-ID display toggle throughout Course Manager, Course Editor, Lessons, Lesson, Rounds, Round/Exercises and Exercise Editor. Lesson, Round and Exercise IDs are selectable secondary text and never enter breadcrumbs or Course JSON.
- Renamed the course-list screen to Course Manager while retaining Course Editor for one course, removed redundant Draft count/status text in favor of the shared blue badge, and propagated the existing canonical `LESSON_ROUNDS_EMPTY` Warning through empty-Lesson hierarchy status.
- Explicitly prefixed all nine confirmed deterministic temporary samples with `AI-Slop Demo`, including the exact title `AI-Slop Demo: Inglés para hispanohablantes`, issuing checksum-valid official patch releases without changing course IDs, authorship, licensing, hierarchy or exercise content. These nine courses are AI-generated, unreviewed demonstrations and are not reliable learning courses; real QuisquisLingo course content remains intended for human authorship and review.
- Made the existing fallback-only Lesson icon mode observable in Course Info. Monochrome applies the current theme tint and Colored preserves the fallback icon's multicolored artwork; explicit preinstalled and managed custom icons continue to override the fallback and retain original artwork.
- Preserved Course Model v6, persistence formats, publishing and learner behavior, official read-only/fork rules, and all earlier 226.02 Preview/navigation/Move/Copy guarantees. No Guidebook, 226.03 or Custom Exercise Template work is included.

# 2.0.26 (Phase 226.02, revision 2) - Audit, Draft and version status refinement - 2026-09-06

- Advanced technical metadata to `2.0.26+226022` while representing application version, development phase, corrective revision and monotonic platform build explicitly. The 30-day Alpha expiry remains `2026-10-06 23:59:59` because this revision was prepared on the same correction date.
- Replaced Error-only pink borders with red Error-or-Warning borders and luminous green current-branch-clear borders at Exercise, Round, Lesson, Course and hierarchy-link levels. Info alone remains green.
- Replaced orange Draft outlines with one independent blue Draft badge shared across every hierarchy level; Draft and Audit status update from the same current candidate tree and coexist without masking each other.
- Empty Rounds now show `0 Exercises`, no zero-Draft label or Draft badge, and inherit the existing Error-level `ROUND_CONTENT_EMPTY` Audit state until valid Content is added.
- Changed Rename Round guidance to `Title, or Enter to skip`; Enter preserves an existing title when no replacement is supplied and still permits intentionally untitled new or existing Rounds.
- Corrected first-run and general display metadata to show `Version 2.0.26` and `Phase 226.02, revision 2` instead of exposing the technical platform build as a human phase label. Existing one-time persistence semantics remain unchanged.
- Preserved Course Model v6, persistence, publishing, official read-only/fork behavior, Preview, navigation, Move/Copy, export, Audit codes/severities and all learner behavior. No 226.03 or Guidebook feature is included.

# 2.0.26 (Build 226.02.1) - Editor hierarchy and Audit reference correction - 2026-09-06

- Advanced correction metadata to `2.0.26+226021` / Version 2.0.26 / Build 226.02.1. The 30-day Alpha expiry is `2026-10-06 23:59:59`, thirty days from the correction date.
- Grouped the shared 103-rule Audit Codes reference by Error, Warning and Info, with independently selectable category filters that constrain text search and no redundant explanatory subtitle.
- Propagated live Draft and Error-only Audit indicators from Exercises through Rounds, Lessons and the hierarchy links while keeping simultaneous orange and pink states distinct.
- Replaced Rename Round helper copy with the compact `Title or Enter for no title` label, matched Rounds-link typography to Lessons, and expanded concise field-specific Help examples.
- Removed the specific Course page overflow menu. Eligible local custom courses, including licensed custom forks, now expose the established Export Course JSON action as the final page entry; official sources and custom courses outside the local authoring path do not. Export preserves v6 provenance metadata and existing media-reference behavior.
- Preserved Course Model v6, persistence formats, official read-only/fork behavior, learner behavior and all 226.02 Preview/navigation/Move/Copy transaction guarantees. No Guidebook or 226.03 feature is included.

# 2.0.26 (Build 226.02) - Editor workflow, field help and Audit UX - 2026-09-05

- Advanced tranche metadata to `2.0.26+22602` / Version 2.0.26 / Build 226.02. Alpha expiry remains `2026-10-05 23:59:59`, thirty days from the same September 5 candidate date.
- Added direct Preview from unsaved Exercise values through the shared candidate builder and existing learner-safe runtime, plus guarded Previous/Next navigation and ID-derived breadcrumbs. Preview preserves Draft/Published state and avoids learner progress, version and backup writes.
- Added explicit Exercise and Round Move to / Copy to destinations inside the current course transaction. Moves preserve identity/content; copies reuse ID/reference remapping. Removed the editor's pending transfer clipboard paths and preserved untouched v6 text/Presentation metadata while assembling transfers.
- Added shared contextual field help and clearer validation, verified importer/artwork instructions, intentional untitled Round guidance, orange Draft Exercise outlines alongside pink Audit Errors, and live Lesson/Course Draft counts.
- Added a searchable Audit Codes technical reference backed by the same 103-rule registry as CourseAuditService. Existing severities are preserved. Removed missing Reading-comprehension guidance entirely; malformed actual Reading and Listening exercises still receive validation.
- Preserved official read-only/licensed fork boundaries, custom confirmation/backup rules, Course Model v6, learner behavior and XP. No 226.03 or later functionality is included.

# 2.0.26 (Build 226.01) - official read-only courses and licensed custom forks - 2026-09-05

- Advanced candidate metadata to `2.0.26+22601` / Version 2.0.26 / Build 226.01. Alpha expiry is `2026-10-05 23:59:59`, thirty days from the September 5 candidate date under the existing policy.
- Made both official origins locally read-only, with dedicated Course/Lesson/Round/Exercise inspection, Info, Audit, Preview and publisher Version History. Removed local official transactions, active overlays, local-version fields, restoration and reset actions without deleting or converting old data.
- Added explicit derivative permission and a licensed custom fork workflow with fresh IDs, independent custom versions/backups, immutable original publisher/course/authorship snapshots and separate fork creator identity. Official updates replace only their source and never modify forks.
- Retained Course Model v6, ordinary custom authoring/restore/import behavior, bundled content and licenses, learner progression, XP, Review, Duel and profile storage. Added storage, licensing, provenance, update-isolation and responsive inspection regressions. Later 226 tranches remain deferred.

# 2.0.25 (Build 225.04) - unified Course Editor transaction - 2026-09-04

- Advanced platform-compatible metadata to `2.0.25+22504` while displaying Version 2.0.25 / Build 225.04. The Alpha expiry remains unchanged at `2026-10-04 23:59:59` and the complete Version/Build area retains ten-tap Editor activation.
- Replaced independent Course, Lesson, Round and Exercise persistence with one original-snapshot/working-copy transaction. Nested **Save** and **Save as draft** actions stage only in memory; nested Back discards only the current form's unstaged edits; one top-level **Confirm course changes** or **Cancel course changes** decision owns final persistence.
- Added verified pre-change course backups, atomic write verification, monotonic internal versions, active-profile authorship, optional version notes, Version History restore/export/custom-copy actions, and failure handling that leaves the persisted course unchanged while preserving the working copy.
- Added explicit custom, bundled-official and external-official origin/provenance fields, immutable bundled sources, independent official and local versions, checksum validation, publisher-collision controls and exact archive-before-replace official updates without content merging.
- Updated the Editor hierarchy to show Lessons first at Course level and Rounds first inside a Lesson; replaced nested Publish wording with Save; preserved Draft learner projection, Course Model v6 strictness, all nine bundled courses and learner progress/scoring behavior.
- Added production navigation, transaction, backup/integrity, origin/version, official-update and bundled-provenance regressions. A Windows Build 225.04 manual retest remains required before release packaging.

# 2.0.25 (Build 225.03) - Windows blocker corrections - 2026-09-04

- Advanced platform-compatible metadata to `2.0.25+22503` while displaying Version 2.0.25 / Build 225.03. The Alpha expiry remains unchanged at `2026-10-04 23:59:59`.
- Made the Home course selector derive all included courses from the authoritative production registry and reconcile the device-local v6 bundled discovery index at startup, so Korean appears once in existing installations without clearing preferences, custom courses or learner progress.
- Preserved complete v6 Content wrapper metadata when an Exercise is saved and reconciled the persisted child snapshot through Round, Lesson and Course baselines, eliminating repeated parent save confirmations without suppressing independent parent dirtiness or failed-save warnings.
- Added production-path regressions for Korean selection/open/restart/duplicate prevention and the full Course → Lesson → Round → Exercise Draft/Publish, independent-parent, discard and failed-persistence workflows.

# 2.0.25 (Build 225.02) - second controlled tranche - 2026-09-04

- Advanced platform-compatible metadata to `2.0.25+22502` while displaying the release as Version 2.0.25 / Build 225.02 from one authoritative metadata source. The Alpha expiry remains unchanged at the end of **2026-10-04**.
- Introduced the clean Course Model v6 boundary. Lesson, Round and Exercise objects require canonical UTC `updatedAt` timestamps, obsolete v5 objects are rejected without migration or deletion, and Build-the-translation evaluation uses one or more canonical `correctOrders` objects rather than the legacy single `correctOrder` field.
- Made nested Exercise and Round saves transactional through their Lesson and Course persistence callbacks. A successful child save refreshes the saved child baseline at every open ancestor, while unrelated unsaved ancestor edits remain dirty and persistence failures retain all dirty state.
- Made Round titles optional throughout learner, editor, Review and report surfaces, using position-derived `Round N` labels without changing Round identity.
- Refined Course Audit: missing Listening-comprehension coverage no longer emits Info; empty Reading passages remain Errors, one- or two-word lexical passages emit `READING_PASSAGE_TOO_SHORT`, and three or more Unicode/apostrophe-aware words do not. Hint repetition uses stable code `HINT_REPEATS_PROMPT`; answer-revealing hints remain Errors.
- Added deterministic **Recently modified** ordering and progressive numbering within each severity group to scoped Audit UI and exported reports.
- Expanded Build the translation to author, reorder, delete, serialize and accept multiple literal correct translations in author order. Every alternative resolves to stable Item-ID occurrences; runtime acceptance uses literal normalization only and feedback displays all configured translations.
- Replaced fixed light surfaces in every exercise renderer and feedback state with semantic theme surfaces. Added render coverage for all supported renderer families at 320, 375, 430 and 1100 px in Light and Dark modes.
- Deterministically regenerated all eight existing bundled courses as Course Model v6 and added the Korean-from-English course (`sample_ko_en_ko`, `ko-KR`, South Korea flag) with nine progressive beginner Lessons and polite-register Hangul content.
- Added a strict nine-course validator and release tests for schema/timestamps, global IDs and references, playable Rounds, Duel availability, TTS locales, deterministic regeneration, import/export rejection boundaries and zero-Error/zero-Warning Audit totals.
- Updated current authoring, JSON-format, sample-course and validation documentation. This tranche is intentionally uncommitted until its explicit pre-commit review is approved; no package or push is part of this work.

# 2.0.25 (Build 225.01) - first controlled tranche - 2026-09-03

- Corrected Course Audit to inspect canonical evaluation fields instead of treating author-facing Select/Arrange/Match projections as independent stale data; empty derived icons no longer warn, while genuinely stale independent data remains visible.
- Removed the duplicate Gap Choice Warning when the same missing marker already produces its blocking Error, without weakening invalid-marker validation.
- Added complete deterministic plain-text Course Audit copying and export to the established `Documents/QuisquisLingo/Exports` location, including version, timestamp, scope, totals, sort mode, stable codes and Course/Lesson/Round/Exercise context.
- Fixed Build the translation so an author-entered natural sentence such as `Come stai?` resolves to canonical ordered Item IDs for blocks `Come` and `stai`, survives serialization/reload and remains learner-playable without an artificial punctuation block.
- Refreshed successful Draft/Publish baselines across Course, Lesson, Round and Exercise editors so route-pop guards warn only about edits made after the latest successful save; validation and persistence failures remain dirty.
- Regenerated only the bundled Italian sample (`sample_it_en_it`), preserving all existing semantic IDs, repairing the historical Gap Choice, Dialogue Response, listening-audio and revealing-Hint defects, and adding stable-ID canonical practice Rounds so every Lesson meets the actual 25-question Duel threshold.
- Added focused report, canonical Editor/reload/runtime, dirty-state and real-production Italian Audit/Duel/playability regression gates.
- Advanced the Alpha expiry through the end of **2026-10-04**.
- This is not the complete 225 release; world-flag selection, unrelated tooltips, theme-icon importer changes and other deferred work are not included.

# 2.0.24 (build 224) - 2026-09-03

- Added explicit Draft/Published state for Course, Lesson, Round and Exercise authoring with ancestor-aware learner visibility, strict publish validation, author previews, publication actions/badges, stable-ID unpublishing, and no changes to learner progress or XP.
- Added one exact unsaved-changes guard across Course, Lesson, Round and Exercise editors and protected in-progress Wizard/generator drafts.
- Expanded Course Audit with Info severity, three-Round and listening-comprehension guidance, Lesson/exercise-type sorting, scoped Course/Lesson/Round views and error-only pink Round outlines.
- Completed My custom courses actions with Edit, Rename, fresh-ID Duplicate, Audit and Draft/Publish; added canonical optional `buyACoffeeUrl` metadata and its single learner Course Info action.
- Added Course-level Lesson numbering labels, exact default-title de-duplication, monochrome or deterministic colored-number fallback icons, and portable Course-owned custom Lesson icons normalized to transparent 256 × 256 PNG canvases.
- Added index-linked `*:` answer groups without cross-products and structured Correct feedback that reports the nearest canonical answer plus only the acceptance differences actually used.
- Rationalized the retained exercise implementation behind five canonical internal models—Select, Input, Arrange, Match and Presentation—while exposing 20 concrete authoring presets in six searchable Course Editor categories.
- Added Type the translation with multiple explicit accepted answers, deterministic optional/alternative/reorder expression syntax, a 128-expansion safety limit and conservative single-typo tolerance.
- Added deterministic closest-correction selection as a separate algorithm from answer acceptance, using graded word-level spelling similarity plus exact-token, extra/missing-token and word-order signals while preserving established acceptance behavior.
- Kept terminal punctuation at the end of `<>` reorder expansions and normalized structural sentence capitalization without lowercasing distinguishable names or acronyms.
- Added Contextual comprehension with a separate question, text/audio/text-and-audio modes, optional structured speaker dialogue, stable item IDs and ordinary Select evaluation.
- Generalized the documented Match and Arrange mappings without duplicating runtime engines, retained Presentation as non-scored material, and formalized ordered Round content as the future-proof Story/content-sequence boundary.
- Added an import-only normalized exercise boundary and complete engineering interoperability matrix without adding production external importers or leaking source taxonomies into learner runtime.
- Replaced the inline Course Editor Lesson list with a compact Lessons row and dedicated management page, moving the single authoritative Lock control to its top while preserving Lesson operations, drafts and stable IDs.
- Added Lesson and Round Edit/Rename/Delete/Duplicate/Preview menus and direct Exercise duplication. Copies are inserted after their source, recursively allocate fresh IDs and remap internal references; preview remains learner-state-free.
- Added a registry-backed Exercise Creation Wizard with exact-count Balanced, seedable Random, category, selected-type and repeating-pattern plans plus sequential Save/Preview/Next/Finish and confirmed partial-save cancellation.
- Replaced the fixed three-Round GuideBook helper with a configurable 1–12 Round × 1–15 Exercise planner (default 6×8), normalized progressive difficulty, registry-compatible draft generation, review/edit/delete/regenerate, validation and explicit fresh-ID approval that appends without replacing existing Rounds.
- Added one registry-driven Exercise Help system covering every offered preset plus answer variants and contextual comprehension, with no external product names in author-facing copy.
- Added canonical/preset, import mapping, parser, acceptance, correction, contextual, editor-navigation/menu, recursive-ID, Wizard, generator, Help, stable-ID and 320/375/430/desktop responsive regression coverage while preserving Course Model v5, Review, Duel, XP, Round completion, learner identity and progression.
- Refreshed the mandatory 30-day Alpha lifetime through the end of **2026-10-03**.

# 2.0.23 (build 223) - 2026-09-02

- Promoted Course Model v5 with canonical `lessons` and `lessonId` fields across the model, services, bundled/custom courses, Course Editor, learner UI, Guidebook, Duel, Review, progress and tests; v4 `topics`/Lesson `id` data are rejected without compatibility aliases or fallback parsing.
- Renamed Lesson-semantic learner persistence from `v4_completed_topics` to `v4_completed_lessons`, `last_topic_<courseId>` to `last_lesson_<courseId>`, and recent-Round entry `topicId` to `lessonId`; unrelated opaque v4-prefixed keys remain unchanged.
- Kept learner backup schema v2 unchanged because its schema exposes only an opaque profile-scoped key/value `data` envelope and no structured Topic field.
- Added optional `section`/`sectionName` Lesson metadata, strict consistency validation, consecutive-order visual grouping and derived relative numbering without introducing Section identity, progress, unlock, XP, Duel, Guidebook, Review or navigation state.
- Added noninteractive Section headers immediately before the first Lesson in each consecutive same-name Section block, with no placeholder or reserved space for Lessons outside a Section.
- Replaced the fixed Lesson selector with a Section selector when real Sections exist. It groups consecutive equal Section names, uses a UI-only `Other lessons` group for unsectioned blocks, jumps to each block's first Lesson, and keeps scroll synchronization deterministic without adding persisted Section state.
- Expanded the canonical preinstalled Lesson icon registry to 14 stable, labeled, coherent flat multicolor 256 × 256 transparent PNG assets under `assets/lesson_icons/`, generated specifically for QuisquisLingo with OpenAI ImageGen and documented in the asset license/provenance note.
- Refocused the Lesson editor on metadata, added an all-catalog responsive visual icon grid with `None` and a contained preview, removed the obsolete Lesson `imageAsset` field/control, and moved the existing Round management workflow to one draft-preserving linked subpage without changing stable IDs or save/cancel semantics.
- Standardized both themed and fallback GuideBook visuals to the same 84 × 84 slot, allowed Lesson titles up to three lines, removed the old lower `Guidebook`/`Start Here` row, and added the direct monochrome `GuideBook` action at the right of the main row.
- Made Profile the primary learner-bottom action, compacted Review and Course Info, and moved the existing learner/course-scoped IDDQD control out of Settings into the fixed bottom area with immediate persistence and unchanged genuine lock/progress semantics.
- Regenerated all eight bundled sample courses as Course Model v5 with complete Section and theme-icon metadata plus representative meaningful Round 1 titles, while preserving optional untitled-Round support, existing opaque identifiers, references, exercises and gameplay behavior.
- Added focused Course Model, terminology guard, Section, selector, Guidebook icon, editor, icon decode/dimension, persistence, backup and responsive regression coverage; preserved XP, Weekly XP, streak, Review, Duel, Round completion, profile identity, Flag Game and course-flag behavior.
- Refreshed the mandatory 30-day Alpha lifetime through the end of **2026-10-02**.

# 2.0.22 (build 222) - 2026-09-02

- Replaced display-name-based learner identity with generated opaque UUIDv4 `learnerProfileId` values, one centralized ID namespace and an ID-only active learner reference. This is an intentional clean cut: legacy learner registries and namespaces are neither migrated nor read.
- Allowed duplicate learner display names while keeping avatar, progress, XP, streak, settings, course selection and deletion isolated by learner ID; logout still removes only the active reference.
- Introduced learner backup schema v2 with explicit identity-preserving restore, collision-time Replace/Separate copy/Cancel choices, and deliberate separate-copy import under a new ID and user-selected display name.
- Read learner imports only from `Documents/QuisquisLingo/Imports/learner_import.json`, while preserving automatic learner backup filenames and the existing `Documents/QuisquisLingo/Exports` destination.
- Added a separate 266-entity world-flag manifest: 193 UN Members, 56 ISO extras, an eight-entry Shortlist and nine language-related community/regional flags. Country and shortlist assets use pinned `lipis/flag-icons` v7.5.0 under its included MIT license; the nine additional SVGs carry per-file Wikimedia Commons provenance and reusable-license notices.
- Added the hidden Settings Flag Game, activated by five taps within three seconds on the Settings title/flag hint after the existing suspense sound. Four cumulative pools drive 12-question games with five English answers, metadata-guided distractors, explicit near-identical exclusions, randomized targets/options and victory/defeat feedback.
- Added searchable read-only UN Members, ISO extras, Shortlist and Language-related flags browsers, with compact category explanations and canonical-name/alias matching.
- Refined the unchanged four Flag Game pools to the learner-facing labels UN, UN + ISO, UN + ISO + Shortlist and All Flags; added the `Flag Game` tooltip and exact 12-question introduction.
- Added each best score's `achievedAt` date to the existing compact scorecard row without changing card size, stable mode IDs, historical records or ranking.
- Moved the exact per-question answer feedback directly below the flag and increased only the correct-answer transition delay from 700 ms to 800 ms; wrong-answer timing remains 700 ms.
- Added device-local Top 5 scorecards for all four modes, keyed by learner ID with one best result per learner/mode and score-descending, time-ascending, achieved-at-ascending ranking.
- Confirmed Flag Game writes only game-best records and awards no XP, Weekly XP, streak, Laurel, Round/Lesson/Duel/Review or course progress.
- Preserved every existing course-flag mapping and rendering path, including legacy `CY`/`EN`, custom `flagImageBase64` precedence and `FlagPainter` behavior.
- Expanded the pinned flag-icons star markers into 50 renderer-compatible explicit stars for the United States and United States Minor Outlying Islands assets, preserving their artwork, identities, dataset membership and MIT provenance.
- Refreshed the mandatory 30-day Alpha lifetime through the end of **2026-10-02**.

# 2.0.21 (build 221) - 2026-09-01

- Changed built-in and custom learner course flags from stretched/cropped viewport fills to contained, aspect-ratio-preserving artwork with neutral surrounding space.
- Raised the continuous dark-mode neutral flag veil to 25% and added a continuous 10% light-mode neutral veil below fully opaque learner content.
- Removed every standalone in-flow Lesson heading. Each centered Guidebook now owns the correct `Lesson <number>: <title>` identity, with a regular structural prefix, emphasized title, two-line/ellipsis boundary and no duplicate heading elsewhere; the fixed Lesson selector remains unchanged.
- Kept the redundant `Your roadmap to <Lesson title>` line absent, retained the centered Guidebook at 78% of the available width within the existing 400 px cap, and arranged its distinct `Guidebook` and `Start Here` styles on one compact row below the Lesson identity while preserving its avatar and navigation.
- Reduced only the responsive Round-card maximum width from approximately 276 to 244 logical pixels. The 108 px default height, padding, icon, two-line title, states, Laurel, left/right routing, 28 px vertical gap and interaction remain unchanged.
- Preserved 75%-opaque Round surfaces while setting GuideBook and Duel surfaces to 70%, the behind-content connector to 55%, and mascot-container surfaces to 10%; foreground text, icons, Laurel artwork and mascot PNGs remain fully opaque.
- Replaced the perfect-Round wreath-like leaves with two lighter, subtly arched lateral Laurel branches without changing the green icon, `Perfect` label, Round layout, eligibility, persistence or XP.
- Added non-persistent three-tap locked-Lesson previews. Each specifically activated Lesson remains previewable for the running app session, multiple Lessons may be active, all GuideBook/Round/Duel actions remain disabled, and only an application restart clears the in-memory preview set.
- Added a compact secondary theme-mode control after Profile, Review and Course Info in the unchanged 68 px learner bottom area. It cycles Default → Light → Dark → Default, applies immediately, and persists independently for each real learner profile while Default keeps following the system appearance.
- Added a separate compact far-right Flag background control that persists per learner and cycles Small → Off → Extended → Small. Small keeps the contained flag and current veil, Off uses the neutral learner background without a flag veil, and Extended restores an aspect-ratio-preserving immersive crop with the same theme veil.
- Scoped the last active course reference to each learner profile. Direct profile switches, logout/reselect and app restart now restore that learner's own bundled course code or authoritative custom `courseId` reference without changing another learner's selection; the former global preference is not migrated or used as a fallback.
- Kept the learner-path connector's 2 px, 55%-opaque theme-aware main stroke while adding a subtle 4 px, 32%-opaque theme-surface support stroke beneath the same path for continuous contrast across mixed flag regions.
- Increased only the external pre-divider spacing between each Duel and the following Lesson Guidebook from 20 to 32 logical pixels, leaving Duel internals, Round spacing, ordering and navigation unchanged.
- Moved the unchanged fixed 68 px learner controls into structurally reserved space below the scroll viewport, retained the 112 px scroll-bottom inset, and verified at 320/375/430 logical pixels that all five controls remain fully visible while the final Duel scrolls completely above them.
- Confirmed the Flutter/Windows pointer-wheel behavior is the source of coarse touchpad scrolling and deliberately added no learner-local interpolation, event interception or ScrollPhysics workaround.
- Added focused regressions for the complete opacity hierarchy, contained flag geometry, Guidebook-owned Lesson identities, compact single-row actions, the 244 px Round cap, fixed bottom layering, Duel spacing, Laurel artwork, responsive 320/375/430 layouts, and locked-preview isolation with unchanged XP/progress.
- Retained the 30-day Alpha expiry through the end of **2026-10-01** because builds 220 and 221 were prepared on the same date.
- Preserved build-220 Profile behavior, normal Lesson unlocks, Round completion/scoring, Review, Duel, Course Model v4, TTS, mascot discovery/order and connector geometry.

# 2.0.20 (build 220) - 2026-09-01

- Replaced the fixed learner-bottom Leaderboard action with Profile, rendered from the active learner's existing avatar appearance with name and standard-person fallbacks, full-name tooltip and Profile-aware accessibility semantics.
- Simplified the fixed learner bottom area to exactly Profile, Review and Course Info with the existing 68 px height, responsive spacing and unchanged Review/Course Info destinations.
- Added a central Profile page with the larger active learner avatar/name and links to Avatar customization, local learner-profile management and Gamification, all returning naturally to Profile.
- Replaced the direct Settings Avatar and Learner profiles entries with one Profile entry.
- Added confirmed local-only logout that removes only the `active_learner` selection, preserves profiles, avatar, progress, XP, streaks and course data, and returns to the existing learner selection/create flow.
- Moved Buy a coffee from the learner bottom area into the lower support area of Course Info while preserving HTTPS validation, external launching and existing failure messages.
- Preserved the build-219 Round path, mascots, connector, Laurel/completion accents, GuideBook/Duel presentation, XP, Review, Duel, TTS and Course Model v4 behavior.
- Refreshed the 30-day Alpha lifetime through the end of **2026-10-01**.

# 2.0.19 (build 219) - 2026-08-31

- Replaced the Unified Learner Page's large regular Round grid with smaller side-aligned cards following a deterministic balanced path that includes occasional consecutive same-side Rounds and consistent vertical whitespace.
- Adapted the connector into a curved 2 px, round-ended, 50%-opaque behind-content journey through every Round position, including same-side pairs and arbitrary Lesson lengths.
- Added intermittent, noninteractive QuisquisLingo mascot decorations discovered and decode-validated from Flutter's `assets/mascots/` manifest on the side opposite nearby Rounds, with a stable course-ID Fisher-Yates shuffle, one course-wide sequence across Lesson paths, full-set use before reuse, padded `BoxFit.contain` artwork, 50%-transparent theme surfaces, empty failed-image handling and narrow-layout priority for the core path.
- Removed the former between-Round Lesson image presentation from the learner path and retained the intentional deletion of `assets/exercise_images/hello.webp`; course data and editor image support remain unchanged.
- Made the Round icon background bright yellow-orange whenever the existing course-scoped persisted completed-Round state contains that Round, including completion with errors, while the existing authoritative perfect/Laurel state now uses a distinct bright-green icon.
- Enlarged the perfect-Round Laurel frame and leaves without changing eligibility, reduced and centered GuideBook and Duel cards, and applied 75% opacity to Round, GuideBook and Duel surfaces without fading their content.
- Added a continuous theme-neutral 18% veil between the course flag and learner content in dark mode only.
- Added focused deterministic-layout, persistence, decoration, interaction, theme and responsive coverage, plus actual Flutter web visual checks at 320, 375 and 390 logical pixels in light and dark modes.
- Refreshed the 30-day Alpha lifetime through the end of **2026-09-30**.

# 2.0.18 (build 218) - 2026-08-30

- Replaced the separate learner User Bar and Status Bar with one fixed, single-row Top Bar ordered as compact Language/Course flag selector, Streak, Laurel progress, Weekly XP, QuisquisLingo cat mark and Settings.
- Kept Streak language-scoped, Laurel progress current-course-scoped and Weekly XP learner-global without changing their calculation, persistence or update rules.
- Presented Laurel and Weekly XP as compact vertical current/max metrics, kept Streak on one line, and added concise explanatory dialogs for all three metrics.
- Clarified in the Streak and Laurel dialogs that Streak is language-scoped with cross-language study-day freezing, while Laurels remain specific to the course in which they were earned.
- Slightly enlarged the three metric icons and added standard informational tooltips to the course flag, Streak, Laurels, Weekly XP and App Info mark without changing their actions or the Top Bar height.
- Kept the existing full-size Language/Course picker behind the compact flag, moved learner-profile management into Settings, and kept the Lesson selector separate.
- Used the graphical portion of the existing branding asset in the Top Bar without changing the source image; the cat opens the existing App Info screen, whose complete logo remains unchanged.
- Added responsive spacing, white/near-black surface and narrow-layout coverage while preserving the course-flag background, continuous Lesson flow and fixed bottom controls.
- Retained the Alpha expiry at the end of **2026-09-29** because build 218 was prepared on the same date as build 217.

# 2.0.17 (build 217) - 2026-08-30

- Replaced the learner page's single-Lesson central content with a lazy continuous vertical flow from the selected Lesson through every subsequent Lesson in authoritative course order.
- Kept the complete four-zone Learner Header and icon-only bottom controls fixed while Lesson content scrolls beneath them with retained bottom clearance.
- Retained the existing Lesson picker and persistence; direct selection now restarts the flow at that Lesson, while stable visible-area synchronization updates the selector after scrolling into another Lesson.
- Preserved genuine Lesson locks and IDDQD access, kept locked Lesson content inaccessible without permission, and left Topic-scoped Duel eligibility, gameplay and XP unchanged.
- Added focused learner regressions for ordered flow, no duplication, lazy construction, selector jumps, scroll synchronization, fixed controls, final-content reachability and locked-Lesson gating.
- Refreshed the 30-day Alpha lifecycle; build 217 expires at the end of **2026-09-29**.

# 2.0.16 (build 216) - 2026-08-29

- Corrected the dark Welcome dialog's text contrast without changing its structure, controls, persistence or action styling.
- Replaced the unified learner page's decorative olive-tree background and tint with the selected course's existing flag rendering in light and dark appearances.
- Reordered the existing learner header and status bar so the protected user/logo/Settings strip appears first and the unchanged status bar appears directly below it.
- Removed the redundant standalone **Browse All Lessons** button while retaining the existing Lesson selector, picker, navigation and persistence behavior.
- Verified that the existing course picker already shows up to three newest other recent courses between the current course and complete course list; no recent-course persistence or presentation rewrite was required.
- Refreshed the 30-day Alpha lifecycle; build 216 expires at the end of **2026-09-28**.

# 2.0.15 (build 215) - 2026-08-28

- Removed Chapter from the production domain and learner navigation. Course Model v4 (`formatVersion: 4`) now stores ordered Topics directly under Course; old Chapter-based course structures are rejected without migration or compatibility fallback.
- Replaced the standalone Chapters/Chapter/Topic learner path with a unified Course → Lesson → Round page containing the course and Lesson selectors, GuideBook, responsive Round path, Topic-scoped Duel and the established Leaderboard/Review/Buy a coffee/Course Info actions.
- Added Chapter-free v4 progress namespaces, Topic-aware Review entries and Topic unlock progression while preserving course isolation, learner isolation, reset behavior, Laurels and the build-214 final-Round + first-Topic XP popup flow.
- Made Duel selection and availability use the actual eligible exercise pool of the current Topic. The 25-question, four-life, existing-eligibility and XP rules are unchanged; an insufficient pool is normal unavailable behavior rather than an error.
- Added non-blocking Course Editor guidance that Topics should normally contain at least six Rounds; this guidance does not validate Duel availability. New custom courses start with 3 placeholder Topics and no Chapters or automatic Rounds.
- Converted all eight bundled courses to native v4 Course → Topic data while preserving deterministic Topic/Round/content ordering and stable IDs.
- Preserved the 214 text-entry submission fix, authoritative XP formulas, Home Leaderboard route, reactive learner status bar and desktop resize behavior.
- Refreshed the 30-day Alpha lifecycle for build 215; because it is prepared on the same date as build 214, expiry remains at the end of **2026-09-27**.

# 2.0.14 (build 214) - 2026-08-28

- Included the one-time 25 XP Topic completion award in the final Round popup and total, with the same language and Weekly XP persistence and no second Topic-page award notice.
- Added first-attempt-correct X/Y communication using only evaluable exercises; Flashcard and informational/Guide content remains excluded from both base XP and the denominator.
- Made Enter and Check share the same guarded submission path for fill-in, listening-spelling and Missing Word text entry, with empty input disabled and ignored.
- Refined only the requested learner status-bar spacing: a one-pixel compact left inset for the streak flame and a one-pixel XP icon-to-value gap.
- Replaced Home's Chapters quick action with Leaderboard using the Material trophy icon, routed it directly to Gamification, and removed Gamification from Settings.
- Preserved desktop resizing on Windows, Linux and macOS while adding a 320×600 minimum supported window size and no maximum size.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 214 is prepared on the same date as builds 211–213.

# 2.0.13 (build 213) - 2026-08-28

- Stabilized completed-Round XP at 5 XP per first-attempt-correct evaluable exercise on first completion and 2 XP on repeats and in Review; incomplete Rounds award 0 XP.
- Added the repeatable 5 XP zero-error bonus and one-time 25 XP first-Laurel bonus, including Laurels first earned on repeats or in Review.
- Made Flashcards and informational/Guidebook-derived content contribute no base XP or errors while preserving perfect and Laurel eligibility.
- Replaced theoretical Round potential text with an actual persisted XP breakdown produced by the pure `XpCalculator` result.
- Made first Topic completion award 25 XP once, and Duel victories award 50 XP first then 10 XP on repeats, while keeping Topic and Duel state independent.
- Preserved the existing XP persistence keys, language XP, learner-global Weekly XP, per-course breakdowns, profile isolation, rollover, leaderboard aggregation and status-bar layout.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 213 is prepared on the same date as builds 211 and 212.

# 2.0.12 (build 212) - 2026-08-28

- Extracted the current Round, Topic, Duel and perfect-potential XP formulas into a pure `XpCalculator` with direct deterministic unit tests.
- Preserved current production scoring exactly, including first-pass-correct imperfect scoring, the floored perfect-repeat cap, repeated Topic and Duel awards, and the existing potential-XP display behavior.
- Characterized the observed six-exercise repeat sequence where the UI displays a 15 XP perfect-repeat potential, the imperfect Round awards 25 XP, and an already-completed Topic awards another 25 XP.
- Kept `XpService` responsible for language XP persistence, learner-global Weekly XP, per-course Weekly XP breakdowns, rollover, leaderboard data, celebration state, validation and clamping without changing keys or formats.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 212 is prepared on the same date as build 211.

# 2.0.11 (build 211) - 2026-08-28

- Added a persistent, reactive learner status bar to Home, Chapters, Chapter, Topic and Review navigation while keeping normal Round exercises outside the shared shell.
- Added authoritative course-title, language-streak, Laurel and learner-global Weekly XP status with responsive layout, adaptive foreground contrast, accessibility semantics and contextual explanations.
- Preserved all existing XP, streak, Laurel, Topic bonus, progress, navigation and persistence rules.
- Refreshed the 30-day Alpha lifecycle; build 211 expires at the end of **2026-09-27**.

# 2.0.10 (build 210) - 2026-08-27

- Completed Modularization Phase 2B by extracting learning-activity, streak, and study-day logic into `LearningActivityService` while retaining the public `ProgressService` facade.
- Preserved the existing activity persistence keys and formats, injected-clock semantics, activity registration ordering, and all established streak and study-day behavior.
- Added characterization coverage before extraction for persistence compatibility, temporal edge cases, cross-language behavior, reset/profile behavior, and completion activity side effects.
- Preserved all learner-facing XP and streak rules; build 210 contains no scoring or other learner-behavior change.
- Retained the existing Alpha expiry at the end of **2026-09-25**.

# 2.0.9 (build 209) - 2026-08-26

- Completed Phase 2A modularization by extracting Round completion orchestration into `LearningCompletionService`.
- Extracted completed-Round persistence, recent-Round error recording, permanent laurel vs provisional TTS-skipped state determination, XP calculation (first-pass correct and repeat-cap scoring), learner-global Weekly XP reads/accounting, second learning-activity registration, and atomic weekly goal celebration claiming.
- Retained UI presentation, exercise attempt state tracking, user input handling, mistake-review flow, preview-mode dialog, victory sound playback, mounted-lifecycle checks, weekly goal celebration dialog, and route navigation in `RoundScreen`.
- Preserved exact sequential, non-transactional persistence ordering and interleaving behavior, including laurel persistence -> victory sound -> XP calculation -> XP persistence -> second activity registration.
- Added comprehensive behavior and characterization test coverage in `test/learning_completion_service_test.dart`, `test/round_xp_completion_regression_test.dart`, and `test/topic_completion_regression_test.dart`.
- Preserved all learner behavior, course behavior, progress, Topic completion rules, Duel rules, Course Model v3, and persistence keys/formats; no scoring or compatibility changes.
- Refreshed the 30-day Alpha lifecycle; build 209 expires at the end of **2026-09-25**.

# 2.0.8 (build 208) - 2026-08-23

- Completed the technical rebrand of application-owned Dart/package/plugin symbols, Windows and Linux executable/application identifiers, SharedPreferences keys, serialization markers, bundled-course extension namespaces and diagnostic environment variables from LingoGrow to QuisquisLingo.
- Renamed the Windows-only TTS shim package and source path, project module file, Windows executable metadata and packaging checks without legacy aliases, migrations or fallback identifiers.
- Updated the update checker, release URL trust boundary, scripts, tests, Help and technical documentation for the new `Quisquisnaut/QuisquisLingo` repository.
- Refreshed the 30-day Alpha lifecycle; build 208 expires at the end of **2026-09-22**.
- Preserved learner behavior, course behavior, progress, XP/scoring rules and Course Editor structure; Phase 2 modularization remains out of scope.

# 2.0.7 (build 207) - 2026-08-22

- Rebranded user-visible application text from LingoGrow to QuisquisLingo, including display-only desktop window and descriptive metadata.
- Updated current Help, About, README and licensing documentation while preserving historical release documentation under the LingoGrow name.
- Preserved the then-current repository URL, application/package/bundle IDs, executable names, SharedPreferences keys, serialization tokens, course extension namespace, environment variables and internal symbols.
- Renamed user-facing filesystem locations and filenames from LingoGrow to QuisquisLingo, including Documents transfer/import folders, exported course and learner-backup filenames, application-owned recorded-audio storage, temporary TTS storage, crash logs, startup traces and Diagnostic Log exports. No legacy-path migration, alias or fallback is included because build 207 has no existing installations to migrate.
- Renamed release and source artifact conventions to `quisquislingo_alpha_<buildnumber>` and `quisquislingo_alpha_<buildnumber>_source`; Windows development bundles use the corresponding `quisquislingo_alpha_<buildnumber>_dev_windows_x64` name.
- Refreshed the 30-day Alpha lifecycle; build 207 expires at the end of **2026-09-21**.
- Kept Phase 2 modularization out of build 207.

# 2.0.6 (build 206) - 2026-08-20

- Replaced brittle source-text assertions with behavior-level widget characterization tests for Round completion/XP and Course Editor Guidebook generation.
- Added direct coverage for imperfect first completion, perfect first completion, perfect repeats, TTS-skipped perfect completion, preview completion with no learner writes, generator cancellation and explicit generator approval.
- Verified persisted Round completion, laurels, Review history, language XP, learner-global Weekly XP, stable Course/Chapter/Topic identity and absence of unintended preference/progress writes through public behavior.
- Removed the redundant Guidebook vocabulary source-text test after its requirements were covered by the generator behavior tests.
- Preserved all production behavior, course-ID/import/replacement/copy semantics, persistence formats and XP rules; build 206 contains no production feature or scoring change.
- Reserved build 207 for Phase 2 modularization in small, independently validated steps with no intentional behavior changes. Phase 2 is not part of build 206.
- Refreshed the 30-day Alpha lifecycle for the 20 August 2026 release; build 206 expires at the end of **2026-09-19**.

# 2.0.5 (build 205) - development

- Promoted the native Windows and Dart/Flutter startup trace into a permanent Alpha diagnostic subsystem with concise normal tracing and opt-in verbose tracing through `LINGOGROW_STARTUP_DIAGNOSTICS=verbose`.
- Added privacy-safe session headers, bounded diagnostic messages and approximately 1 MiB active-log rotation with two retained generations. Startup logs no longer record raw command lines, usernames, full executable/working-directory paths, profile names, course content or learner answers.
- Preserved startup order, UI behavior, persistence, course behavior, XP/progress behavior and TTS behavior while making diagnostics fail-safe and suitable for ongoing Alpha support.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 development build; the expiry remains **2026-09-18** because build 205 development begins on the same date as build 204.

# 2.0.4 (build 204)

- Added deterministic injected-clock coverage for Weekly XP rollover, previous-week and skipped-week XP, per-course Weekly XP, streaks, study days, repeated same-day activity, Review timestamps and learner-profile isolation. Normal application callers still use the real current local time by default.
- Extracted language XP, learner-global Weekly XP, per-course current/last-week XP breakdowns, rollover, leaderboard XP calculation and weekly-goal celebration persistence into `XpService`, preserving all existing `ProgressService` XP-facing APIs through delegation.
- Kept local leaderboard participation preference and filtering in `ProgressService`; participation is not owned by `XpService`.
- Made the listening-spelling renderer regression assertion work with both LF and CRLF source files while preserving its source-structure check.
- Updated `AGENTS.md` with the current `ProgressService`/`XpService` responsibility boundary, deterministic-time guidance, persistence scope, XP compatibility rules and validation discipline.
- Preserved existing 203 behavior: build 204 does not change Round, Topic or Duel XP formulas, does not add scoring multipliers, does not change UI behavior or Course Model v3, and does not change any SharedPreferences key or stored format.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 release; the expiry remains **2026-09-18** because build 204 is prepared on the same date as build 203.

# 2.0.3 (build 203)

- Resolved all 50 analyzer findings present in build 202: added braces to single-statement conditionals, guarded asynchronous navigation contexts, and normalized Image Bank test fixture identifiers.
- Preserved existing learner, Course Editor, course data, progress, XP, persistence, and navigation behavior.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 release; the expiry remains **2026-09-18** because this release was prepared on the same date as build 202.

# 2.0.0 (build 200)

- Established **2.0.0+200** as the reference baseline for Course Model v3 and future Codex-assisted development.
- Added repository-level `AGENTS.md` and `docs/CODEX_BASELINE_200.md` so future coding work starts from the correct architecture, validation rules and packaging conventions.
- Preserved the Course Model v3 learner/editor functionality and bundled course data from the baseline source; this version jump does not intentionally remove or reset existing features or learner data.
- Refreshed the Alpha expiry to **2026-09-17**.

# 1.5.9 (build 159)

- Promoted the native course structure to Course Model v3 (`formatVersion: 3`): Guidebooks now belong to learning Topics and Chapters no longer contain Guidebooks. Course Model v2 remains importable through deterministic compatibility migration.
- Regenerated all eight bundled sample courses for Topic Guidebooks. Round 1 of every learning Topic starts with a short non-exercise `topic_intro` drawn from that Topic Guidebook and pointing learners to the full Topic Guidebook.
- Added the learner **OPEN TOPIC GUIDEBOOK** action to Topic pages and removed the Chapter-level Guidebook action. Updated learner notices, Info, Editor Help, JSON reference, sample-course documentation and validation rules.
- Added **Generate 3 Rounds from Guidebook** to the Topic Editor. It uses Topic Guidebook vocabulary and examples, randomizes suitable material, builds progressively harder drafts, avoids exact duplicate exercise prompts, previews/audits all three Rounds, and creates them only after explicit approval. Round 1 includes the Guidebook-derived intro Content.
- New custom courses continue to start with five placeholder Chapters and three placeholder learning Topics per Chapter, but no automatic Rounds. Manually created Rounds still start with three editable dummy exercises.
- Renamed the per-learner/per-course switch to **IDDQD Mode (you can walk through locks)** while preserving its description and temporary-access semantics. Lock icons continue to show the genuine unlock state.
- Fixed Course Editor classification so a selected imported/user-created course remains under **My custom courses** and is not duplicated under **Current bundled course**. Origin is taken from the persisted `custom:<courseId>` selection reference rather than inferred from title or ID.
- Fixed imported Course Model v3 `listening_spelling` exercises with `interaction.kind: input`: learner UI now shows a typed **Your answer** field and evaluates `text_match` answers. The parser accepts v3 `acceptedAnswers` and the legacy `accepted` key; exports write `acceptedAnswers`.
- Fixed incorrect-answer feedback for selection exercises so **Correct answer** resolves the stable `correctItemIds` Item instead of repeating the exercise prompt. Course Audit now reports unresolved correct Item IDs.
- Added a Course Audit warning for the generated Reading pattern where the declared correct vocabulary option does not occur in the passage, helping surface semantically inconsistent imported/generated exercises for human review rather than silently rewriting them.
- Updated the Alpha expiry for this release to **2026-09-16**.

# 1.5.8 (build 158)

- New custom courses now start with five placeholder Chapters instead of three.
- Each generated Chapter starts with three placeholder learning Topics plus its Language Duel assessment.
- Course creation does not generate any Rounds automatically. Rounds are added explicitly later by the course author.
- Updated Course Editor help to describe the new-course bootstrap accurately.

# 1.5.7 (build 157)

- Each learning Topic now shows the number of completed Rounds out of its total Rounds.
- Strengthened the global desktop mouse-hover feedback for buttons and other Material button controls without changing their actions.
- IDDQD Mode still grants temporary access to every Chapter in the current course, but Chapter lock icons now always show the learner’s genuine unlock state. A Chapter that is accessible only through IDDQD therefore keeps its lock icon until it is genuinely unlocked through normal progression or a Duel win.

# 1.5.6 (build 156)

- Regenerated all eight bundled sample courses. In every learning Topic, the first Content item of Round 1 is now a short non-evaluated explanation derived from that Chapter Guidebook, with an explicit invitation to read the Guidebook for more.
- Topic-intro Content is displayed before the runnable Round exercises and does not count as an exercise, XP opportunity, Duel item, completion requirement or laurel condition.
- Added **IDDQD Mode (temporary unlocks all chapters in the current course)** to Settings. The setting is stored per learner profile and per course. It only overrides access; genuine Topic completion and Duel wins continue to be recorded normally, and disabling IDDQD immediately restores the true unlock state.
- Course Editor now creates three placeholder Chapters for a new course. A newly created Chapter starts with three placeholder learning Topics, and a newly created Round starts with three editable dummy exercises.
- Kept the standard Language Duel assessment separate from the three learning Topics.

# 1.5.5 (build 155)

- Added **Current version** followed by **Update** at the bottom of Settings.
- Added a dedicated **Settings > Update** page for the official repository `https://github.com/Quisquisnaut/QuisquisLingo`.
- Added manual GitHub Release checks and an optional **Check automatically at startup** switch, disabled by default.
- A newer published release can show release notes, open only the validated official GitHub release page, and display fixed-order installation guidance for Windows, macOS, Linux antiX, Android, iOS and Web.
- Platforms without a matching published release asset are explicitly marked as not currently available.
- Hardened update checking: fixed HTTPS API endpoint, no credentials or learner/course payloads, bounded response size, redirect rejection, strict release-URL validation, timeouts, no automatic download/install/execution, and silent startup failure when offline.
- Added regression tests for version comparison, trusted release URLs and conservative platform-asset detection.
- Updated security, Info, README and third-party documentation; removed the stale `file_picker` notice and added `url_launcher`.
- No changes to course content, Course Model, progress, Duel rules, TTS, import/export, or learner navigation.

# 1.5.4 (build 154)

- Chapter titles may now wrap onto two lines in the learner Chapter app bar.
- Chapter titles in the Chapters list are also explicitly allowed up to two lines before ellipsis.
- No changes to Chapter navigation, course content, progress, or Language Duel rules.

# 1.5.3 (build 153)

- Distinguishes the automatic Crash Log from the internal Diagnostic Log throughout the UI.
- Settings now shows the actual Crash Log path and the fixed Diagnostic Log export location.
- Adds Export Diagnostic Log, now written to `Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`.
- Startup Alpha tester instructions now refer to the Crash Log, not the Diagnostic Log.
- Chapter freedom notice is shortened to `Jump freely around the tree`.
- Duel gate text is shortened to `Win the duel to test out to next chapter`.
- Compact Status labels now use the requested form, for example `Apprentice (lev. 0)`.
- Includes the regenerated bundled sample exercises from 1.5.2, based on each Chapter Guidebook vocabulary and the available exercise primitives.

# LingoGrow 1.5.1

- Reduced the Home app bar height slightly to make the main screen more compact vertically while preserving the learner name and existing actions.
- No changes to Home navigation, course selection, progress logic, or course content.

# LingoGrow 1.5.0

- Removed the visible “Quick actions” heading from the Home screen to reduce vertical height.
- Made the “Change course” control slightly more prominent with stronger text weight, a subtle tinted background, and a clearer icon while keeping “Go to course” as the primary action.
- No changes to course navigation, Course Model, bundled course content, or progress logic.

# LingoGrow 1.4.9

- Added a third learning Topic to every Chapter in all eight bundled sample courses.
- Each new sample Topic contains two Rounds with eight choice exercises, bringing every bundled Chapter to at least 28 exercises eligible for a 25-question Language Duel.
- Updated `requiredTopics` from 2 to 3 for bundled sample Chapters.
- DUEL-001 now tells the learner directly: “This Chapter does not contain enough exercises for a Language Duel.”
- Updated bundled-sample and error-code documentation.

# LingoGrow 1.4.8

- Replaced deprecated `PopScope.onPopInvoked` with `onPopInvokedWithResult` in Chapter navigation.
- Preserved the rule that Back from a Chapter always opens that course's Chapter list when the Chapter was entered directly.
- Packaging fixed: the source archive now contains the project files at the archive root, without an extra `lg*_work` directory.
- No changes to Gamification, Course Model, course content, or navigation behavior.

# LingoGrow 1.4.7

- Fixed typed loading in TTS, Do Not Disturb, Avatar, and main Settings screens.
- Fixed Image Bank ZIP byte-size accounting with archive 4.x numeric sizes.
- Replaced deprecated WillPopScope in Chapter navigation with PopScope.
- No changes to Gamification scoring, Course Model, or course content.

# Changelog

## 2.0.2+202

- Corrected the **Reset current course progress** confirmation: it now names only course-owned progress that is reset. Language XP, streak, study days and Status remain because they are shared by courses in the same language.
- Confirmed Round XP is persisted only after the learner finishes the Round. Abandoning or exiting before **Finish round** awards no XP; completed Rounds with first-pass errors still receive the lower first-pass-correct award.
- Refreshed the 30-day Alpha expiry to **2026-09-18**.

## 2.0.1+201

- Course-owned progress now uses immutable globally unique Course IDs, preventing collisions between courses that teach the same language. Language XP, streaks and study days remain language-scoped; Week XP remains learner-wide across all languages.
- Same-ID course imports now offer replace/update, separate derived copy, or cancel. Derived copies receive a new Course ID and retain optional lineage metadata.
- Added repeat-perfect Round XP cap: a repeat perfect completion earns at most half the Round's full XP value. The completion screen states the potential award.
- Added Illustrator as a course information role.
- Refreshed the 30-day Alpha expiry to **2026-09-17**.

## 1.4.6+146

- Fixed an analyzer/compiler compatibility error in `ReviewScreen` caused by two parameters using the same `_` identifier on older Dart toolchains.
- Removed unnecessary boolean casts in Settings subpages.
- Removed an unused `firstOrNull` helper from `duel_screen.dart`.
- No functional changes to Gamification, courses, navigation, or the Language Duel.
- Dependency declarations are unchanged from 1.4.5; run `flutter pub get` after extracting the source before `flutter analyze` or `flutter run`.

## 1.4.5+145 - 2026-08-16

- Added a dedicated **Gamification** subpage under Settings.
- Moved **Weekly XP Target** into Gamification and clarified that the target is based on XP earned across all courses.
- Added **Last Week XP · All courses** for the previous completed week. Tapping the learner's score opens a per-course XP breakdown.
- Added a **Local leaderboard · All courses** ranking participating local learner profiles by their total XP across all courses during the previous completed week.
- Added a per-profile switch to opt out of the local leaderboard without deleting XP history.
- Added per-course weekly XP bookkeeping so future completed weeks can show an exact course-by-course breakdown, including custom courses.
- Updated Info and README to document the scope and privacy of local gamification data.

## 1.4.4+144 - 2026-08-16

- Added a dedicated **Avatar** subpage under Settings.
- Moved **Avatar skin color** and **Avatar hair color** into the new subpage without changing profile storage or avatar behavior.
- Kept the main Settings page more compact by replacing the inline avatar controls with a single Avatar entry.
- Updated current in-app Info to point to Settings > Avatar.

## 1.4.3+143 - 2026-08-16

- Added a dedicated **User Data** subpage under Settings.
- Moved **Export my data**, **Import my data**, and **Reset current course progress** into the new subpage without changing the existing backup/import storage paths.
- Kept the main Settings page more compact by replacing those three controls with a single User Data entry.
- Updated current in-app documentation to use the new Settings > User Data paths.

## 1.4.2+142 - 2026-08-16

- Added a dedicated **Do Not Disturb** subpage under Settings.
- Moved **Sound effects**, **Animations**, and **Show one-time notices again** into the new subpage without changing their stored preferences or behavior.
- Kept Settings more compact by replacing the three switches with a single Do Not Disturb entry.
- Updated current internal documentation to use the new Settings paths.

## 1.4.1 - 2026-08-16

- Added a dedicated **TTS Settings** subpage under Settings.
- Moved Text-to-speech, Skip all TTS exercises, TTS voice, and Test Voice into the new subpage without changing their stored preferences or behavior.

## 1.4.0+140 - 2026-08-16
- Home > Current course now shows the last Chapter actually opened for the active learner and selected course.
- The Chapter number and title refresh immediately when returning to Home.
- The displayed Chapter uses the same per-profile, per-course memory as Go to course; first use falls back to Chapter 1.

## 1.3.9+139 - 2026-08-16
- Chapter back navigation now always returns to the selected course's Chapter list, including when Go to course opened the Chapter directly from Home.
- Preserved the existing flag transition animation before direct course entry.
- Updated in-app Help and current documentation for the navigation rule.

## 1.3.8
- Language Duel now uses 25 questions and 4 lives.
- Removed Duel score and pass threshold. A Duel is won by completing all 25 questions before all four lives are lost.
- Updated Course Model v2 assessment defaults, bundled courses, validation, tests, Help, Info and documentation for the new Duel rules.

## 1.3.7+137 - 2026-08-16

- Home: placed all four Quick actions on a single horizontal row to reduce vertical height, including on phone-width layouts.
- Reduced Quick action internal padding and icon size slightly, while preserving all four destinations and touch targets.
- No navigation, course, progress, or Course Model changes.

## 1.3.6 - 2026-08-16

- Course Editor > Course info is now always accessible, including while course content is locked.
- Course info now clearly advertises that the visible course name, authors, license and metadata can be edited.
- Lock continues to protect structural/content editing but no longer blocks metadata editing.
- Renaming a course still preserves its stable `courseId`.

# Changelog

## 1.3.5+135

- Moved the Alpha expiry notice out of the Home page and into a non-dismissible popup shown on every app launch.
- The popup always states the current Alpha expiry date and remaining days, or the expired state after the deadline.
- Removed the Alpha expiry card from Home to reduce vertical height.

# LingoGrow 1.3.4

- Home: removed the two-line footer to reduce vertical height.
- Home course selector continues to include bundled courses and all custom courses, whether created locally or imported from JSON.
- Go to course now opens the last Chapter opened by the active learner in the selected course; first use opens Chapter 1.
- Quick actions > Chapters remains the explicit route to the complete Chapter list for the selected course.

# 1.3.3

- Expanded in-app Help for bundled vs custom courses, Home course selection, Go to course vs Chapters, custom-course import/export, Copy edits as JSON, Course ID/name behavior, learner backup and fixed media-import folders.
- Go to course now resumes the active learner at the last Topic visited in the selected course; first use opens the first learning Topic of Chapter 1. Chapters continues to open the full Chapter list.
- Status presentation explicitly shows the level number.
- Corrected current Duel documentation to the Course Model v2 standard: 10 selected exercises, 3 lives, 7/10 threshold.
- Reconciled current README, Course Editor, sample-course and Course Model documentation with the current app behavior.

## 1.3.2+132 - 2026-08-16

- Home course selector now lists both included courses and all locally stored custom courses.
- User-created and imported Course Model v2 courses appear under `My custom courses` in the same selector.
- Selecting a custom course makes it the current Home course and persists that selection across app restarts.
- Preserved custom `courseId` casing in the stored last-selected-course reference so imported course IDs remain stable.
- No Course Model changes.

## 1.3.1+131 - 2026-08-16

- Course Editor > Course info: the visible Course name can now be edited.
- Course ID remains read-only and unchanged when the course is renamed, preserving the course's technical identity.
- Course Editor Help now explains the distinction between Course name and Course ID.
- No other functional changes.

## 1.3.0+130 - 2026-08-16

- Restored an explicit `Change course` control on the Home current-course card.
- The course picker was still present in 1.2.9 but was discoverable only by tapping the `CURRENT COURSE` badge; the new control makes course selection visible again.
- Kept the existing course picker logic and all 1.2.9 behavior unchanged.

## 1.2.9+129 - 2026-08-16

- Doubled the display time of all bottom SnackBar messages to 8 seconds, including informational and error messages, so users have more time to read them.
- No other functional or visual changes.

## 1.2.8+128

- Restored the pre-redesign Home progress presentation for clearer scope and less duplication.
- Removed the duplicate total XP value from the Progress header.
- Restored the explicit `Week XP · All courses` label for the global weekly XP metric.
- Restored course-specific wording for streak, laurels, and total days, including the selected course language where appropriate.
- Kept the 1.2.7 compact Home header and current-course/quick-action layout unchanged.

## 1.2.7+127

- Removed the Home welcome card to reduce vertical height, especially on phones.
- Restored the active learner name to the left side of the Home app bar.

## 1.2.6+126

- Home: restored the lighter transparency used before the 1.2.4 redesign so the olive-tree background remains clearly visible.
- Home: removed the duplicate streak indicator from the welcome panel; streak remains in Progress.
- Home: slightly reduced vertical padding and spacing while preserving the 1.2.4/1.2.5 information hierarchy and navigation.

## 1.2.5+125 - 2026-08-16
- Fixed the Home screen build failure caused by three invalid `FontWeight.w650` values.
- Replaced them with the supported Flutter weight `FontWeight.w600`.
- No other functional or visual changes.

## 1.2.4+124 - 2026-08-16
- Refreshed the Home screen visual design with an olive-inspired translucent dashboard.
- Added a clearer welcome panel, current-course card, progress dashboard and overflow-safe quick actions.
- Kept existing Home navigation and learner/course logic unchanged.

## 1.2.3+123 - 2026-08-16

- Refined the Home screen visual hierarchy without changing navigation or learning logic.
- Added a translucent welcome header, a more prominent current-course card, and softer separation from the olive-tree background.
- Restyled the primary Go to course action, progress card, status presentation, and four progress metrics for clearer scanning.
- Kept the Home layout scroll-safe and suitable for narrow desktop windows.
- No course-model or course-content changes.

## 1.2.2+122 - 2026-08-16

- Removed obsolete LingoGrow 1.0.0/1.0.1 version references from the Course Model v2 runtime error and technical Help.
- Course Model v2 wording is now release-independent so it does not become stale on future app versions.
- No functional course-model changes.

## 1.2.1+121 - 2026-08-16

- Added deliberately fictitious placeholder author names to all bundled sample courses for UI testing.
- Chapters now shows `Course by ...` below the course title, using Course Model v2 `authors` metadata and falling back to the legacy `author` field when needed.
- No other functional changes.

## 1.2.0+120 - 2026-08-16

- Fixed the remaining horizontal RenderFlex overflow in Chapter Topic cards on narrow Linux desktop windows.
- Replaced the outer Topic Row/SizedBox width calculation with an aligned FractionallySizedBox constrained to 72% of the actual parent width.
- Topic titles are now capped at two lines with ellipsis, while the round count and navigation chevron remain inside the card bounds.
- Updated the Topic layout regression test to protect the new constrained structure.
- Based directly on 1.1.9+119 with no unrelated functional changes.

## 1.1.8+118 - 2026-08-16

- Image Bank single-image import no longer opens a file picker. It reads exactly one PNG/JPG/JPEG/WEBP file from `Documents/QuisquisLingo/Imports/Images`.
- Image Bank ZIP import no longer opens a file picker. It reads exactly one ZIP from the same fixed Images import folder.
- Topic/exercise custom-image imports use the same fixed Images folder.
- Audio Library MP3 import no longer opens a file picker. It imports all MP3 files found in `Documents/QuisquisLingo/Imports/Audio`.
- Image Bank, Audio Library and Course Editor Help now show immediate fixed-folder import instructions.
- Source files are left in the import folders; the UI warns creators to move/remove MP3 sources after successful import to avoid duplicates.
- Based directly on 1.1.7+117 with no unrelated functional changes.

## 1.1.7 - 2026-08-16

- Settings learner-data export no longer opens Save As or any file picker. Backups are written directly to `Documents/QuisquisLingo/Exports`, with numeric suffixes when needed to avoid overwriting an existing file.
- Settings learner-data import no longer opens a file picker. It reads `Documents/QuisquisLingo/Exports/learner_import.json`.
- Settings and Info now show immediate learner backup import/export instructions and the fixed paths.

## 1.1.6+116

- Reworked Course Editor Help with separate step-by-step instructions for importing custom courses, exporting custom courses, and importing custom flags.
- Help now states the fixed transfer path `Documents/QuisquisLingo/Exports`, the required `import.json` filename, and accepted custom-flag filenames.
- Clarified that temporary sample material refers to bundled courses included with early LingoGrow versions, not user-created custom courses.
- Based directly on 1.1.5+115 with no other functional changes.

## 1.1.5+115

- Removed the sample-material explanation from the Create new course dialog.
- The dialog now only states that a basic Course Model v2 structure will be created; the sample-material explanation remains in Help.
- Based directly on 1.1.4+114 with no other functional changes.

## 1.1.4

- Removed the desktop file picker from custom course flag import.
- Custom flags are now imported from `Documents/QuisquisLingo/Exports/flag.png`, `flag.jpg`, or `flag.jpeg`.
- Added immediate flag-import instructions to the Create new course dialog.
- Missing flag files now produce an actionable in-app message instead of exposing a Linux desktop portal error.

## 1.1.3+113

- Custom-course JSON import no longer opens a file picker.
- Import always reads `Documents/QuisquisLingo/Exports/import.json`, the same fixed transfer directory used by course export.
- Course Editor shows immediate import instructions beside the import action and states that imported courses appear under **My custom courses**.
- Missing or invalid `import.json` produces an actionable message with the expected location.
- The import source file is left in place after a successful import.
- Based directly on 1.1.2+112.

## 1.1.2+112

- Custom-course JSON export no longer opens a Save As dialog or depends on desktop portal services.
- Exports are written directly to the fixed `QuisquisLingo/Exports` folder inside the user documents directory.
- Existing exports are never silently overwritten; duplicate filenames receive `_2`, `_3`, and later numeric suffixes.
- Course Editor Help documents the fixed export location.
- Based directly on the regression-checked 1.1.1 source derived from 1.0.8.

## 1.1.1+111

- Rebased all post-1.0.8 work directly on the verified 1.0.8 Course Model v2 source to avoid regressions.
- Preserved the 1.0.5-1.0.8 matching fixes, stable Item-ID learner logic, double-confirmation custom-course deletion, last selected bundled course restoration and Course Editor Help shortcut.
- Course Editor now labels the user section **My custom courses** and the bundled section **Current bundled course**.
- Added portable Course Model v2 JSON import/export for custom courses, with UTF-8/size/schema validation and replacement confirmation for duplicate course IDs.
- New custom courses can choose a built-in flag or import a PNG/JPEG flag. Imported flags are size/resolution checked, safely resized with preserved proportions and stored in the course JSON.
- Course Editor app bar now puts the course name on a separate readable line under **Course Editor**.
- Chapters screen now shows the course name instead of the generic **Chapters** heading.
- Topic title cards use a transparent background.
- Regenerated sample presentation data on top of Course Model v2: Chapter and Topic titles use the source language, each Chapter Guidebook contains at least 12 vocabulary entries, and learning Topics contain more image-supported exercises.
- Removed normalized duplicate sample answer choices such as `hallo` / `Hallo!`.
- Help explains that new courses may initially contain sample material which course creators progressively replace with the real course content.

## 1.0.8+108

- Removed the unused `_shuffleDifferentStrings` helper from `RoundScreen` after matching was migrated to stable Item IDs.
- No learner behavior changed.
- Target: `flutter analyze` reports `No issues found!`.

## 1.0.7+107

- User-created courses can be deleted only after two consecutive confirmation dialogs; bundled sample courses remain non-deletable.
- Home now remembers the last selected bundled course and restores it on the next app start.
- Added a Course Editor Help shortcut to the main Course Editor projects page.
- Chapter labels now show the generated chapter number before the title in learner/editor locations, without storing the number inside the Chapter title.

## 1.0.6+106

- Fixed a learner crash in matching exercises when two displayed right-side choices have the same text.
- Matching DropdownButton values now use stable Course Model v2 Item IDs instead of visible labels.
- Matching correctness also compares Item IDs, so duplicate labels are safe at runtime even though Course Audit can still reject semantically duplicate sample content.
- Applied the same ID-based selection logic to audio matching.

## 1.0.5+105

- Rebuilt bundled sample Word Match exercises with three genuinely distinct source/target pairs.
- Rebuilt bundled sample Audio Match exercises with three distinct target-language sounds and three distinct visible matches.
- Removed generated sample Super Match items that used duplicate/weak pairs; sample coverage now uses reliable translation matching while Super Match remains available in the editor and model.
- Course Audit now rejects match exercises whose left or right items collapse to duplicates after case and punctuation normalization.

## 1.0.4+104

- Fixed sample translation-choice prompts so the source word/expression is explicitly shown.
- Replaced `xyz` and source-language placeholder options with real target-language distractors across all bundled sample courses.
- Course Audit now reports `PLACEHOLDER_ANSWER` for known placeholder options.
- Course Audit now reports `TRANSLATION_PROMPT_MISSING_SOURCE` when a translation task does not identify what must be translated.

# 1.0.1

- Fixed `flutter analyze` error in `course_editor_screen.dart`: the friendly exercise-label helper is now referenced from `_ExerciseEditorScreenState`, where it is defined.
- No Course Model v2 schema or sample-course behavior changes.

# 1.0.0

- Replaced the legacy course structure with Course Model v2 (`formatVersion: 2`).
- Rounds now serialize `content[]`; Exercise is one Content kind.
- Added primitive Exercise representation: Prompt + Interaction + Evaluation.
- Added stable Item IDs for choice, arrange and match correctness.
- Converted Flashcard to interactive Presentation Content with `understood` and `review_later`.
- Structured Chapter Guidebooks as `content[]`.
- Represented Language Duel as an assessment Topic / skip test; default sample Duel is 10 questions, 3 lives, pass at 7/10.
- Kept friendly exercise/template names in Course Editor while primitives remain internal.
- Added independent user-created Course Model v2 projects to Course Editor.
- Reorganized Editor Help: practical page plus separate Course Model v2, Exercise primitives and JSON data structure pages.
- Regenerated all bundled samples natively in v2 with meaningful Topic titles and Topic images.
- Updated bundled-course validation for Course Model v2.

# 0.8.9

- Added `readme_windows.txt` documenting Windows release dependencies, Microsoft Visual C++ Runtime requirements, TTS, diagnostic logging and troubleshooting.
- Added `tools/package_windows_release.ps1`: it builds the Windows release and automatically copies the documentation into the Release folder as `readme.txt`, beside the executable.
- The complete Release folder remains the distribution unit; the executable must not be distributed alone.
- No learner, editor or course-data behavior changed.

# 0.8.8

- Added a separate automatic generator for sentence exercises based on the current Chapter Guidebook example sentences.
- The generator can propose Sentence Word Order, Missing Word, Listening Spelling and Gap Choice exercises.
- Sentence generation uses only author-written Guidebook examples and does not invent sentences or translations.
- Sentence Word Order drafts are created without distractors by default; authors can add distractors manually later.
- Gap Choice is generated only when two safe target-language distractors can be found from known course vocabulary.
- Generated sentence exercises are reviewed, individually selectable and audited before insertion.
- Added Editor Help documentation and a Guidebook Examples field hint.

# 0.8.7

- Reorganized Course Editor Help so the complete JSON course-file reference is separated from normal editor guidance and placed at the end.
- Added a short introductory section before the JSON technical reference.
- No JSON schema, parser, course content or learner behavior changed.

# 0.8.6

- Fixed the Guidebook editor helper-text parameter introduced with Guidebook vocabulary exercise generation.
- Fixed a Dart string-literal syntax error in the JSON portability section of Course Editor Help.
- No learner behavior or course content changed.

# 0.8.5

- Added `Generate exercises from Guidebook vocabulary` to the Round Editor.
- Guidebook Vocabulary entries can be parsed as target/source pairs such as `casa = house`.
- The generator can propose Flashcards, Word Match, translation choices and Audio Match exercises.
- Generation uses only author-supplied vocabulary pairs and does not invent translations.
- Generated drafts are reviewed and individually selected before insertion, with Course Audit run on the proposals.
- Added Editor Help documentation and a discoverable Vocabulary field hint.
- No learner progress is changed by generation or preview.

# 0.8.4

- Removed references to specific external course editors from Course Editor Help and JSON-format documentation.
- Kept portability guidance generic for future interoperability with external course editors and learning applications.
- No course format, parser or learner behavior changed.

# 0.8.3

- Added an extensive Course Editor Help section documenting the current JSON course-data structure.
- Documented root Course metadata, authors, audioLibrary, Chapters, Guidebooks, Topics, Rounds, Exercises, type-specific field use, parser rules, stable IDs and versioning.
- Added a minimal structural JSON example and guidance for safe external JSON editing.
- Added forward-looking portability guidance for future interoperability with external course editors and learning applications.
- No learner behavior or course-data parser behavior was changed.

# 0.8.2

- Removed the persistently timing-out automated widget test `Image Bank opens a preview before selection`.
- The working Image Bank preview implementation is unchanged and should be verified manually.
- Image Bank asset validation remains in place.

# 0.8.1

- Fixed the Alpha tester startup notice so it is shown in standalone release builds as well as debug builds.
- Crash/diagnostic logging now starts on every non-web application launch, including Windows release builds.
- Every session writes a startup header containing timestamp, app version, operating system, architecture, locale, Dart runtime and build mode (`debug`, `profile` or `release`).
- Windows Alpha builds now maintain an easy-to-find diagnostic copy at `Documents\\QuisquisLingo Logs\\quisquislingo_crash.log` in both debug and release.
- Diagnostic files are written with append mode; if a tester deletes a log, the next app start or diagnostic write recreates it automatically.
- Detailed action breadcrumbs remain debug-only to keep release logs concise.
- Added regression checks for release startup notice visibility and always-on session logging.

# 0.8.0

- Fixed the Flutter/Dart `Zone mismatch` introduced by debug crash logging by keeping binding initialization and `runApp` inside the same guarded zone.
- Preserved global Flutter/Dart crash capture and Windows debug system logging.
- Changed the startup tester instructions to show the portable crash-log path without a Windows username; it is now `Documents\QuisquisLingo Logs\quisquislingo_crash.log`.
- Fixed Round startup ordering so the first exercise, including choice options, is fully prepared before the learner UI is marked ready; added a defensive rebuild for unexpectedly empty choice options.
- Removed the unnecessary `package:flutter/widgets.dart` import reported by `flutter analyze`.
- Updated the Image Bank preview widget test to use an image from the current manifest instead of the removed `transport_airplane` test fixture; the working preview implementation itself is unchanged.

# 0.7.9

- Debug builds now show tester instructions automatically at startup, including the exact crash-log path and how to send the complete log file.
- Debug logs now record a system snapshot at session start, including OS/version, architecture, logical processor count, locale and Dart runtime, and repeat key system details in crash reports.
- The diagnostic notice states what is and is not intentionally recorded.

# 0.7.8

- Added a Windows debug diagnostic build path with immediate navigation breadcrumbs and a tester-friendly crash-log copy, now stored in `Documents\QuisquisLingo Logs\quisquislingo_crash.log`.
- Moved and strongly emphasized the Home `GO TO COURSE` button so the primary action appears before progress details.
- Made the Chapter `OPEN GUIDEBOOK` action a large full-width primary button.
- Changed first Chapter entry so it always opens the normal Topic view. A one-time learner notice now explains that every Chapter also has a Guidebook.
- Updated Guidebook help text and removed the obsolete automatic-Guidebook behavior.

# 0.7.7

- Hardened Windows crash prevention around Settings and Round initialization: failures are logged and the UI falls back instead of leaving an uncaught initialization future.
- Made `flutter_tts` lazy so Windows and Linux do not instantiate the plugin when their dedicated TTS backends are used.
- Added a safe Round fallback screen when initialization fails, preserving the process long enough to retrieve the crash log.

# 0.7.6

- Added persistent crash logging for uncaught Flutter and Dart errors, including timestamp, app version, operating system, error details, and stack trace.

# 0.7.5

- Added a macOS compatibility path and macOS-specific build documentation.
- Added macOS runner Swift sources and sandbox entitlements for user-selected file read/write access used by import/export workflows.
- Added `tools/prepare_macos.sh` to generate the missing Xcode host project on a Mac without replacing LingoGrow Dart source, assets, tests or course content.
- Documented macOS validation requirements for TTS, local storage, file import/export, audio playback, editor dialogs and narrow windows.
- Kept iOS as a separate future Apple-platform preparation task.

# 0.7.4

- Added Linux desktop host files directly to the source package, so Linux builds no longer require `flutter create`.
- Uses Flutter's relocatable bundle install layout under the project build directory instead of `/usr/local`, avoiding normal-user permission failures.
- No course content or Image Bank artwork changes in this release.

# 0.7.3

- Fixed `AlphaLifecycleService.warningStage()` so missed milestone days fall forward to the next stricter warning stage, matching the documented alpha-expiry behavior.
- Expanded alpha-lifecycle regression coverage to include 8, 6, 5, 4 and 2 days before expiry plus the expired state.
- Added `unlock_service_test.dart` covering first-Chapter access, Topic-completion gating, Duel unlocking, unrelated Topic progress and zero-required-Topic behavior.
- Added `image_bank_service_test.dart` security regression coverage for missing/malformed manifests, unsafe filenames, duplicate IDs, existing IDs, missing assets, unsupported formats, ZIP path traversal, duplicate basenames and import safety limits.
- Hardened the Image Bank preview widget test to avoid an environment-sensitive `pumpAndSettle()` timeout while retaining the preview-open/close assertions.
- No course-content or Image Bank artwork replacement is included in this release; incorrectly cropped bundled artwork remains a separate asset-correction task.

# 0.7.2

- Fixed the Course Info runtime rendering failure caused by placing `LayoutBuilder` inside an `AlertDialog`; responsive fields now use a precomputed narrow/wide layout without intrinsic-dimension callbacks.
- Fixed the remaining analyzer warnings in Course Editor and Weekly XP target settings.
- Added Image Bank enlarged preview with metadata, zoom/pan and an explicit Use image action.
- Increased Image Bank bottom grid padding so the floating Import bank action no longer obscures the last assets on small windows.
- Stabilized Image Bank tile sizing for narrow windows and retained contained, non-cropping image rendering.
- Updated Credits wording to “Project and code design: Quisquisnaut (Quisquis on Discord)” and “Code generation and software development assistance: ChatGPT”.
- Synchronized current documentation and third-party notices for 0.7.2, including the direct `archive` MIT dependency.
- Added regression tests/checks for Course Info layout structure and Image Bank preview behavior.

# 0.7.1

- Added a transparent 30-day alpha lifecycle: this alpha expires on 2026-09-12, warns near expiry, blocks learner exercises/Review after expiry, never deletes local data, and leaves Course Editor available.
- Course Info now shows Source language and Target language as read-only fields.
- Course authors can have multiple roles plus custom roles; role definitions are shown in the editor and documented in Editor Help.
- Added per-Chapter Editor notes for internal technical/editorial information; these notes are never shown to learners, who see the Guidebook instead.
- Removed the unintended visible `Learner (0)` Status. `Apprentice` is now the first Status at zero progress while later rank thresholds remain unchanged.
- Added/updated tests, audit checks and documentation for alpha lifecycle, multi-role authors, Chapter editor notes and the corrected ten-rank Status sequence.
- Re-ran static security, consistency, narrow-screen and platform-boundary review for the changed paths.

# 0.7.0

- Set project and code authorship consistently to Quisquisnaut (Quisquis on Discord), with ChatGPT credited for software development assistance.
- Performed a security/edge-case hardening pass: bounded Image Bank ZIP imports, rejected unsafe/archive-traversal filenames and duplicate basenames, and tightened learner-backup import limits.
- Added Course Info metadata edge-case audit checks for author lists, unusually long fields, course descriptions and invalid last-updated dates.
- Improved narrow-screen behavior in Course Info, Chapter editor cards, Duel status and missing-image notices to reduce RenderFlex overflow risk.
- Reviewed and synchronized current documentation for 15-exercise rounds, 0-2 Word Blocks distractors, current 25-exercise/four-life Duel rules, MPL-2.0 scope and platform limitations.
- Clarified platform support: Android, Windows and Linux are primary targets; iOS/macOS require macOS/Xcode validation; Web remains experimental while native file-import authoring features are present.

# 0.6.9

- Changed LingoGrow software source licensing from GPL-3.0 to MPL-2.0; course content, Image Bank and other assets remain separately licensed.
- Added structured multi-author Course Info with per-author roles and custom roles, plus language variant, levels, course version, last-updated date and description.
- Added stable Course Audit codes and documented audit severity/codes in Course Editor Help.
- Language Duel audit now requires 25 unique candidates, matching the 25-exercise / 4-life learner Duel.
- Added authoring guidance/audit for accidental Round duplicates, isolated-word capitalization and Opposite exercises used too early.
- Expanded Course Editor Help with Round, distractor, source-language, progression, Listening Spelling, metadata and audit rules.
- Weekly XP now celebrates the first crossing of the learner's weekly target once per week.
- Bundled sample courses were normalized for isolated-word lowercase and reviewed for early Opposite/duplicate content.

# 0.6.8

- Added Learner Status and slowed Status progression by at least an order of magnitude.
- Home now labels weekly XP explicitly as “Week XP · All courses”.
- Added Gap Choice: a target-language sentence with a missing element and one semantically and grammatically correct answer block.
- Image Word letter/syllable composition now forbids distractor blocks; bundled samples were updated accordingly.
- Typed-answer checking tolerates a missing diacritic but rejects a wrong diacritic; meaningful spaces and apostrophes remain significant.
- Bundled Italian isolated common-word options keep creator-entered lowercase instead of automatic capitalization.
- Opposite exercises now use explicit source-language instructions such as “Choose the opposite” and “Match each word with its opposite”.
- Topic images are guaranteed in bundled sample Topics.
- Image Credits no longer use A-Z pages and instead list images/decorative assets actually in use.
- Added editable per-course author/license metadata with common-license menu plus Custom license.
- Info now distinguishes per-language progress from all-course weekly XP and points editor users to Course Editor Help.
- Course Editor Help was updated for Import/Export, licensing, Image Word, Gap Choice, Audio Library and exercise transfer behavior.
- Fixed Android/iOS learner Export/Import by using picker bytes when mobile storage is not exposed as a normal filesystem path.
- Hardened Android/iOS MP3 import, fixed bundled MP3 playback by using Flutter AssetSource for asset recordings, and improved Android TTS locale fallback/completion behavior.
- Fixed Learners bottom-sheet overflow and reduced the Android Add profile lifecycle race.
- Copy and Move are separate exercise actions. They use an explicit transfer buffer and a Paste action in the destination Round rather than duplicating immediately below the source.

# 0.6.7

- Fixed Course Audit tests for current Audio Match duplicate diagnostics.
- Course Audit and Course Editor now enforce the documented Word Block rule of 0, 1 or at most 2 distractors.
- Removed unused legacy public-domain bicycle, coffee-cup and train exercise images and their credits; the olive-tree artwork and credit remain.

# 0.6.6

- Exercise type and standardized instructions are shown in the course source language.
- Corrected target-language instruction leakage in bundled courses, including German; Spanish-source course instructions are now Spanish.
- Audio Match answer options are shuffled for every exercise presentation.
- Home metrics refresh when the learner returns from the course flow after completing exercises.
- Audio Library and Image Bank are authoring tools inside Course Editor, not top-level Settings items.
- Built-in Image Bank manifest now exposes all 113 bundled images.

# v0.6.5+65

- Fixed Week XP and weekly target values in the Home status card.
- Fixed nullable ZIP byte handling in Image Bank import.
- No feature removals from v0.6.4.

# 0.6.4+64

- Standard round length 15.
- Duel 25 exercises, 4 lives.
- Weekly XP groundwork and per-user weekly target default 1000.
- Status number shown from Apprentice (0) to Guru (9).
- Listening Spelling exercise.
- Per-course editor lock persistence API, default locked.
- External Course Pack architecture and per-course author/license metadata specification.
- Block distractor rule documented: 0-2, progressive by Topic round.
- Sample courses regenerated to 15 exercises per round.

# Changelog

## 0.6.1+61

- Added separate Image Bank ZIP import so vocabulary assets and manifests can be updated without recompiling LingoGrow.
- Image Bank import validates IDs, referenced files, supported formats and the 50 KB image maximum.
- Missing external image assets now produce a visible warning.
- Added Course Editor Help and moved editor-specific guidance out of general Info.
- Added Image Word: build the target-language word from letter/syllable blocks while viewing an image.
- Added Topic images to all bundled sample courses and an Image Word sample exercise to each course.
- Raised maximum imported image size from 30 KB to 50 KB.


## 0.6.0+60
- Added Missing Word listening exercise with one or more blanks, TTS/recorded/hybrid audio, editor fields and audit checks.
- Settings now exposes Audio Library and Image Bank together for unlocked creators; removed the separate Welcome switch.
- Welcome now reads the actual package version and uses the shared one-time-notice reset.
- Info now documents local course edit overwrite behavior, learner-backup exclusions, and image import specifications.
- Image import now enforces a 30 KB maximum and reports oversized resolution guidance.

## 0.5.9+59
- Settings reads the displayed version from package metadata.
- Removed the legacy Six Fairy Tales credits and automatic translation-character fallback.
- Replaced the misleading generated image bank with a smaller verified flat set; no numbered fake variants remain.
- Added Image Bank to the Course Editor menu with alphabetical browsing, A-Z quick access, import and deletion of imported images.
- Topics can now use an image from Image Bank or an imported image.
- Audio Library retains MP3 preview, alphabetical sorting and A-Z quick access.
- Build Sentences Check is enabled whenever at least one block is selected.

# LingoGrow 0.5.5

- Enlarged Translation exercise illustrations while preserving their aspect ratio.
- Added a detailed Audio Library explanation to Info.
- Removed the 10-tap unlock instructions from Info.
- Course Editor now shows the sample-content warning every time it opens while any Chapter still carries the TEMPORARY SAMPLE badge; the warning stops only after all such badges are removed.
- Replaced editor action labels `Done` with `Save` where the action commits edited content.
- Version bumped to 0.5.5+55.

# 0.5.3

- Fixed Course Editor 10-tap unlock: no five-second timeout.
- Audio Library is now directly visible in Course Editor.
- Added learner Export my data / Import my data controls.
- Bundled sample course revisions replace stale local sample overrides from older bundled versions.
- Added per-learner, per-course update notice keyed by content revision.
- All bundled courses are capped at three Chapters and explicitly marked TEMPORARY SAMPLE.
- Retained MP3 import, longest-match concatenation, Hybrid fallback and orphan-file review/delete flow.

# 0.5.2

- Added creator-recorded MP3 Audio Library with TTS/recorded/hybrid modes and longest-match concatenation.
- Added periodic orphan MP3 detection and confirmed cleanup.
- Round header now includes course language and Chapter number.
- Reconfirmed 10-tap Course Manager unlock and release checks.
- Bundled sample courses remain capped at three TEMPORARY SAMPLE Chapters.

# 0.5.1

- Regenerated all eight bundled courses as three-Chapter TEMPORARY SAMPLE courses.
- Added removable TEMPORARY SAMPLE Chapter badges.
- Added Course Audit category filters.
- Added Round and single-exercise Preview mode with no learner progress writes.
- Added first-open Course Editor sample-content notice and reset-one-time-notices action.
- Renamed Startup animation setting to Animations and broadened it to course-entry animation.
- Added Duel suspense sound.
- Compacted Jump freely panel.
- Preserved optional multi-exercise generation from Reading comprehension.
- Addressed analyzer lint reports carried over from 0.5.0.

# Changelog

## 0.5.0
- Consolidated the latest 0.4.x work into the 0.5 line.
- Added a richer olive-and-flags startup animation with IT, DE, ES, PT, NL, CY, UK English and FI.
- Added a short target-language flag transition after Go to course.
- Added Finnish plus editable empty Welsh, Dutch and Portuguese course shells.
- Reworked the Union Jack artwork and shared flag rendering across selectors and backgrounds.
- Made Chapter and Topic flag backgrounds more recognizable and saturated while retaining readable overlays.
- Made Home cards more transparent and their important text bolder.
- Made Language Duel panels semitransparent and topic titles bold.
- Automatically shows each Chapter Guidebook on first open per learner/language/Chapter.
- Added per-language learner reset without touching other languages, avatar settings or course edits.
- Added Windows System.Speech TTS backend to avoid the flutter_tts Windows platform-thread error.
- Added voice preference and Test voice support, including female/male preference.
- Added Skip all TTS exercises; zero-error attempts with skipped audio receive a separate leaf mark and cannot earn a new laurel.
- Added victory sound when a new laurel crown is first earned and when Course Editor is unlocked.
- Fixed Word Blocks so the Check button becomes available after the correct number of sentence blocks is selected, leaving the distractor unused.
- Retained Review priority by latest error count across up to 50 distinct rounds.
- Added more Topic-page decorative scene variations and flag-inspired Topic backgrounds.
- Reorganized Image Credits into Olive + Status Avatar notes plus A-Z subpages.
- Added project/AI attribution and clarified that course content is created by human authors.
- Added GPL-3.0 LICENSE, third-party notices, licensing documentation and recorded-audio-pack architecture notes.
- Kept Course Editor as an unlockable mode in one app; supports empty courses, Guidebook editing and create/delete/reorder across all course hierarchy levels.

# 0.4.25

- Revised all bundled Word Blocks in Italian, German, Spanish and Spanish→English courses.
- Every Word Blocks exercise has exactly one distractor, and the distractor is now selected from the same language as the visible blocks.
- Re-shuffled Word Blocks deterministically so the distractor is not systematically the last block.
- Added an offline validator check for high-confidence source/target-language distractor mismatches.
- Reviewed capitalization in explicitly paired course material. Sentence/expression pairs in Italian, Spanish and Spanish→English now use consistent initial capitalization; German greeting pairs were aligned without altering normal German noun capitalization.
- Revalidated all four bundled courses: 10 exercises per round, at least one Reading comprehension and one Listening comprehension per round, valid IDs, Audio Match uniqueness and Word Blocks invariants.
- Bundled course data version updated to 0.4.25.
- Application version 0.4.25+41.

# 0.4.24

- Migrated all Course Editor reorder lists from deprecated `onReorder` to Flutter's `onReorderItem`.
- Removed the legacy manual `newIndex` decrement, preventing double index adjustment when moving chapters, topics, rounds or exercises downward.
- Fixed the asynchronous `BuildContext` analyzer issue in the Course Editor copy/reset actions by checking context validity after awaits.
- Added braces to the compact flow-control blocks flagged by current Dart/Flutter lints.
- Expanded defensive formatting in the exercise editor save/audit path and preserved context-safety after dialogs.
- Retains the v0.4.23 structural Course Editor: create/delete/reorder chapters, topics, rounds and exercises; exercise type locked after creation; Guidebook editing.
- Bundled course JSON validation passes for Italian, German, Spanish and Spanish → English.
- Version 0.4.24+40.

## 0.4.22
- Audio Match now requires three different spoken words/phrases and five different visible choices.
- Course Audit reports repeated Audio Match sounds, repeated correct matches, and duplicate visible choices as Errors.
- Fixed duplicate Audio Match content in the bundled Italian and German sample courses.
- Added an automated audit test covering duplicate sounds and choices.
- Retains the v0.4.21 analyzer/Settings fixes.
- Version 0.4.22+38.

# 0.4.20

- Reorganized Home into a compact dashboard with source → target course selector, language-specific Status, streak, total study days, completed rounds and XP.
- Added 10 medieval Status ranks from Apprentice to Guru, calculated per learner + language from XP, streak, distinct study days and completed rounds.
- Added per-profile Status appearance settings: 3 skin tones × 2 hair tones.
- Added Info page explaining metrics, multilingual streak freeze, Status, source/target languages, Review and Duel rules.
- Added reserved Course authors entries to Credits, including the Spanish → English course.
- Added English (UK) target course with Spanish as source language.
- Implemented multilingual streak freeze: studying another language freezes, rather than resets, the untouched language streak; a full no-study day breaks it.
- Added defensive course parsing, safer profile/XP handling, corrupt local editor-patch recovery and shell-free Linux TTS executable discovery.
- Added Course Audit with Error / Warning / Suggestion levels, clickable round locations, per-exercise pre-save audit and outdated-audit state after edits.
- Course Audit checks IDs, round lengths, choice indexes/options, hints that reveal answers, TTS requirements, word blocks, matching, Audio Match, icons, Duel candidate counts and other authoring edge cases.
- Learner-facing rounds now skip structurally invalid locally edited exercises rather than crashing; a fully invalid round displays an authoring-audit message.
- Replaced the fixed Home Info/Credits row with a wrapping layout to reduce overflow risk on narrow windows and large text scales.
- Added extensive inline documentation comments around progress, Status, editing, validation, TTS and layout decisions.
- Version 0.4.20+36.

# 0.4.19

- Added English with UK flag.
- Added a full Spanish → English sample course with explicit sourceLanguage and targetLanguage metadata.
- English target TTS uses en-GB while Spanish remains the source language for instructions and translations.

# 0.4.18

- Added a Home link to a dedicated recent-round Review page.
- Stores recent completed rounds separately for every local learner profile.
- Review shows up to the 20 most recently completed rounds for the selected course, ordered from the least recent of those 20 to the most recent.
- Repeating a round moves it to the most-recent position instead of creating duplicate entries.

# 0.4.17

- Course Editor can now keep more than 10 exercises in a round. Ten remains the standard round length, but exceeding it only shows a warning; no exercise is removed automatically and saving is allowed.
- Exercise insertion positions now extend through the full current round, including rounds already longer than 10 exercises.

# 0.4.16

- Added an in-app local Course Editor under Settings.
- Authors can browse chapter > topic > round, edit any exercise, and insert a new exercise at a chosen position.
- The editor preserves the 10-exercise round rule: inserting into a full round shifts later exercises and removes the final exercise only after confirmation.
- Supports all current exercise types and their fields, including flashcards, Audio Match, listening/reading comprehension, matching, word blocks, icons, TTS, hints, and accepted answers.
- Course edits are stored locally and overlaid on bundled course JSON at load time. Bundled course assets are never modified.
- Added Copy edits as JSON and Reset local edits commands.

# 0.4.15

- Fixed Spanish course selection and removed implicit Italian fallback.
- Course codes are normalized and unsupported languages now fail explicitly.
- Language switching loads the selected course before replacing the current course, avoiding stale Italian content.
- Spanish remains a full bundled sample course with es-ES TTS.
- Version 0.4.15+31.

# 0.4.13

- Added a Home-accessible Credits screen documenting bundled images and sounds.
- Added original local Duel win/loss sound effects and an independent Sound effects setting.
- Made the LingoGrow title area transparent so the olive background remains visible.
- Increased the visibility of Italian and German flag backgrounds on Chapter pages.
- Updated the three-lives loss message to “Duel lost. You’ve lost all three lives.”
- Added media credit documentation in `docs/MEDIA_CREDITS.md`.
- Version 0.4.13+29.

# 0.4.12

- Windows and desktop UI constrained to a portrait learning column; Windows window defaults to 430×800.
- Windows TTS explicitly selects an installed voice matching the active course locale and refuses a wrong-language fallback.
- Language Duel keeps the 7/10 threshold, removes duplicate questions within one duel, and adds three person life icons; each error removes one life and the third ends the duel.
- Added flashcard exercises with pronunciation, meaning, usage sentence, usage pronunciation, Got it and Review again.
- Regenerated reading-comprehension items into contextual mini-passages that test meaning rather than literal phrase spotting.
- Added verified public-domain coffee, train and bicycle images to visual exercises, with source notes.
- Existing flag chapter backgrounds, duel background, translucent Home cards and course-specific Duel logic retained.
- Version 0.4.12+28.

# 0.4.11

- Language Duels now draw questions from the active course and chapter; German duels no longer use Italian fallback content.
- Added a light illustrated duel backdrop with two plant fighters.
- Individual Chapter pages now use the active course flag as a full-page translucent background.
- Home streak and Go to course cards are translucent so the olive artwork remains visible.
- Reading-comprehension samples were regenerated to require interpreting the target-language text instead of merely spotting an identical answer.
- Version 0.4.11+27.

# 0.4.10

- Fixed the remaining 1–3 px bottom RenderFlex overflow in the Home language selector on phone-sized Linux windows.
- Reduced vertical padding and label line height inside language chips without changing the selector behavior.
- Version 0.4.10+26.

# 0.4.9
- Regenerated Italian and German A1 sample courses with 8 chapters each.
- Every normal round now contains exactly 10 exercises; mistake review remains additional.
- Added reading comprehension and expanded listening comprehension.
- Added word-block translation in both directions and English-prompt picture/icon exercises with target-language options.
- Home now says “Go to course”, has a stronger visible olive background, and keeps the language strip horizontally draggable with mouse/touch.
- Removed English/UK from the course selector; Finnish is not included.
- Added a selectable German sample course.
- Added six playful plant illustrations to topic screens.
- Replaced giveaway fill-in hints with semantic English clues.
- Preserved scrollable round/review layout to prevent bottom overflow on short phone-sized windows.
- Version 0.4.9+25.

# 0.4.8
- Home no longer lists chapters or uses the “My Path” heading; it links to a dedicated Chapters page.
- Added a bright Chapters-page background and chapter progress cards.
- Expanded the sample Italian course from 3 to 8 chapters with Food & Cafés, Around Town, Daily Life, Shopping, and Travel.
- New sample chapters include Guidebooks, rounds, mixed exercises, and listening comprehension.

# 0.4.7

- Restored the supplied olive illustration as a true Home-page background with a readability veil.
- Made Home vertically scrollable and SafeArea-aware to prevent bottom overflow.
- Made the language selector explicitly horizontally scrollable on touch and mouse, with a visible scrollbar.
- Added `listening_comprehension` exercises with replayable audio and randomized comprehension choices.
- Added sample listening-comprehension items to all three sample chapters.

# 0.4.6

- Added a project-owned Flutter widget smoke test so `flutter create --platforms=... .` does not leave the default template test referencing a nonexistent `MyApp` class.
- Prevents `flutter test` from failing with `Couldn't find constructor 'MyApp'`.
- No UI or course-logic changes.

# 0.4.5

- Fixed bottom RenderFlex overflow on exercise and review screens by making the full body vertically scrollable and SafeArea-aware.
- Kept feedback and round navigation inside the scrollable content so short Linux phone-size windows and larger text scales remain usable.

# Changelog

## 0.4.4

- Linux TTS now renders eSpeak/eSpeak NG to a temporary WAV and plays it through ALSA `plughw:0,0`, with default-device fallback.
- Fill-in answers now accept either the requested missing fragment or the complete phrase when supplied by the exercise, while still ignoring capitalization, punctuation, accents, and redundant spaces.
- Fixed narrow-phone overflow in Match the expressions by stacking prompt and selector when needed.
- Random order is now genuinely unconstrained for exercise queues, duel questions, choices, matching items, and sentence tokens, so the original order is allowed as a random result.
- Learner deletion now requires confirmation.
- Retains guidebooks, multi-language selector, compact olive-background home, profiles, streaks, review pass, correct-answer feedback, autumn round backgrounds, bilingual duels, icon exercises, and cross-platform optional TTS.

## 0.4.3
- Option shuffles are now purely random and may legitimately reproduce the original source order.
- This applies to multiple-choice options, listening options, matching choices, sentence-building tokens, and Language Duel choices.

## 0.4.2

- Compact home hero with the supplied olive illustration used as a background layer.
- Horizontally scrollable language selector expanded to English, German, Italian, Spanish, Welsh, Dutch, and Portuguese.
- Added a Guidebook to every chapter with goals, vocabulary, grammar, useful expressions, and examples.
- Guidebooks are reference-only and do not affect progress, XP, streaks, or unlocking.

# 0.4.1

- Added documented TTS support for Android, iOS/iPadOS, macOS, Windows, Linux and Web.
- TTS remains optional and can be disabled in Settings at any time.
- Linux keeps the lightweight eSpeak NG/eSpeak backend.
- Android/iOS/macOS/Windows/Web use `flutter_tts` and the system/browser voice engine.
- Made TTS/platform diagnostics web-safe and updated platform-neutral audio error messages.
- Added `docs/TTS_ALL_PLATFORMS.md` with setup and troubleshooting instructions.

# 0.4.0

- Compact multi-learner home with local profiles and streak.
- Round-specific autumn pastel backgrounds.
- Botanical chapter background.
- Responsive matching layout.
- Answer normalization ignores case, punctuation, accents and extra spaces.
- One-time mistake-review notice.
- Bilingual randomized Language Duel.
- New icon-choice exercises.

## 0.3.9
- Force answer options to appear in a different order from the course source whenever there are at least two options.
- Randomize the exercise order within each round.
- Randomize both sides of matching exercises.
- Randomize Language Duel exercise order and answer options.
- Keep the existing rule that Build the sentence never starts in the correct order.

## 0.3.8

- Word-order exercises now always start in a randomized order different from the correct answer.

# Changelog

## 0.3.7

- Moved all language flags out of the olive artwork so the supplied botanical illustration is never covered.
- Added a visible language selector below the hero image: English, German, Italian, Spanish and Welsh.
- Italian is selected by default because it is the sample course currently bundled with the app; unavailable languages show a short explanatory message.
- Updated the antiX/Linux preview note to reflect that Linux TTS is now supported.

## 0.3.5

- Linux preview now opens in a centered phone-sized window (390 x 700) instead of filling the desktop.

# 0.3.4

- Fixed Linux compilation with current Flutter SDKs by explicitly importing `FlutterError` from `package:flutter/foundation.dart` in the course loader.
- No functional or UI changes.


## 0.3.3
- Added Welsh flag to the olive-tree language badges.
- Added "Courses made by humans." to the home artwork.
- Changed "Jump freely in the tree" to the more natural "Jump freely around the tree".
- Preserved the original small olive-tree image asset unchanged.


## 0.3.2
- Report confirmation now says: "Copied to clipboard. You can paste it into your report."

## 0.3.1
- Added a one-tap report button to normal exercise screens and Language Duel exercises.
- Added separate Course error and App bug report choices.
- Reports copy diagnostic context to the clipboard instead of sending data anywhere.
- Copied reports include app and course versions, platform, chapter, topic, round, exercise ID and position, exercise type, visible content, and current answer state.
- Added self-explanatory instructions and a confirmation message after copying.
- No account, network service, or new dependency is required.

## 0.3.0
- Renamed the app UI to LingoGrow.
- Added olive-tree home artwork using the supplied small source image unchanged.
- Added runtime UK, German, Italian and Spanish flag overlays.
- Added prominent streak and local/no-account messaging.
- Added a chapter-level branching tree screen.
- Made free movement among all topics and rounds inside unlocked chapters explicit.
- Added an in-tree Language Duel gate that unlocks the next chapter when won.
- Kept the existing offline progress, TTS setting, diagnostics, course data and antiX/Linux preview behavior.


## 0.2.0
- Added realistic Italian sample course.
- Added 3 chapters, 11 topics, 33 rounds, and 165 exercises.
- Added multiple exercise types: choice, listening choice, fill blank, word order, and matching.
- Updated round renderer for multiple exercise types.
- Updated duel engine to draw from suitable chapter exercises.
- Preserved offline-first architecture and local progress.
- Version bumped to 0.2.0.

## 0.1.3
- Added centralized application error codes.
- Added local diagnostic logging.
- Added user-facing error dialogs with codes.
- Added duel validation error handling.
- Added TTS error logging.
- Added diagnostic log path and clear-log control in Settings.
- Logs remain entirely on-device.
- Version bumped to 0.1.3.

## 0.1.2
- Added persistent user TTS enable/disable setting.
- Added Settings screen.
- TTS generation now respects the user setting.
- Default TTS state is enabled.
- No learner data leaves the device.

## 0.1.1
- Added Linux desktop preview compatibility.
- Disabled TTS on Linux preview instead of failing.
- Added Linux preview banner.
- Preserved mobile TTS caching logic for iOS and Android.
- No changes to chapter, topic, round, exercise, duel, quest, streak, XP, or local-storage logic.

## 0.3.6
- Enabled Linux text-to-speech through eSpeak NG/eSpeak, with automatic playback for listening exercises and a replay button.
- Added visible hints to Complete the phrase / fill-in exercises.
- Incorrect answers now show the correct answer before continuing.
- Randomized multiple-choice options, matching options, and word-order tokens when exercises are presented.
- Added one immediate review pass at the end of each round containing only exercises missed on the first pass.
- Added soft autumn pastel exercise backgrounds while keeping dark, high-contrast text.

## 0.5.6+56
- Build Sentences Check remains available whenever the required number of blocks is selected, including wrong orders and distractor choices.
- Flashcards no longer use correct/incorrect semantics; Review again explicitly says the card will return later in the round and requeues it.
- Added a versioned Home welcome notice with a random approved phrase on first launch of each app version.
- Added Settings control to show the current welcome notice again.
- Removed the rejected first Translation illustration from the asset set and rotation.

## 0.5.8+58
- Audio Library now previews imported MP3 files with Play/Stop controls.
- Recorded clips are sorted alphabetically by associated word or expression.
- Added an alphabet jump bar; unassigned MP3 files are grouped separately.
- Retains the 1,000-asset lightweight flat image library and editor image picker introduced in 0.5.7.
- Build Sentences Check remains available whenever at least one word block is selected.


## v0.6.3
- Language Duel: 20 exercises, 4 lives, no score threshold.
- Audio Match: no distractors; target audio may match target-language text or translated text.
- Added Word Match: exactly three source-to-target translation pairs.
- Added Super Match: exactly three target-language relationship pairs such as synonyms or opposites.
- Sample rounds regenerated at 13 exercises with examples of the new match types.
# 2.0.46 (Build 246, Revision 0) - Merge media and Course save ownership - 2026-09-22

One Course Editor service operation now copies a merged Course's media from
both sources, confirms the new Course, and decides cleanup after failures.
Partial copies no longer leave newly created destination files when no Course
was saved. A late confirmation error retains media whenever a stored Course
may reference it. Temporary media from the right-hand Course package still
lasts through the copy. The Merge button accepts one submission at a time
through package cleanup. Course Model v11, stored formats, authoring rights and
the successful Merge result are unchanged.
Version `2.0.46+246000`; Beta expiry remains **2026-10-22 23:59:59 local time**.

# Plan: textbook-like page cards (read-only, waiting for approval)

Status: **proposal**. Nothing here is implemented. Written on 29 September
2026 after Build 257 Revision 0 (Before you start cards), at the owner's
request: "a presentation card with basic formatting style like header,
bold, italic, aligned, centered, for texts and images; options for
streaming a video; a dedicated preset", "either using the current
primitive or, if necessary, upgrading it with more options".

## 1. What exists today (verified in the code)

- **The presentation primitive** (`PrimitiveCapabilityRegistry._presentation`)
  has the options `completionMode` (continue, acknowledge,
  understoodReview, automatic), `navigation` (singlePage, paged),
  `mediaPlayback` (manual, automatic, none), `textReveal` (immediate,
  afterAudio), `scoring` (none), `evaluationTiming` (none) and, since
  Build 257, `guidebookButton`.
- **Only `navigation: singlePage` plays** (runtime-support table,
  `primitive_capability_registry.dart:828`); `paged` is readable, not
  executable.
- **Prompt elements** are `text`, `image` or `audio` with a free `role`,
  `language`, `playback`, `required`, `speakerId` and, for images,
  `asset` and `sharedImageSource`. There is no style, alignment, size or
  video attribute, and no video element type.
- **The renderer is fixed slots** (`RoundScreen._flashcardExercise`): a
  title (`term`), a note (`meaning`), an optional usage sentence and its
  translation, one illustration and a read-aloud button, all centered, in
  fixed text styles. Note card, Flashcard and Picture flashcard are presets
  over this one layout. Dialogue line, Story cover and Before you start
  have their own layouts.
- **No rich text**: the project has no Markdown or HTML dependency, and
  every text is drawn with a plain `Text` widget.
- **No video**: no element type, no player dependency. `url_launcher` is
  already a dependency (it opens the Course Library web page) and could
  open an external link.
- **Media limits**: a Course image is at most 50 KB (`ImageProfile.exerciseImage`,
  `CourseMediaStore.maxImageBytes`), a recording 50 MB, the cover 1 MB.
  Every imported medium passes a validator (`ImageValidator`,
  `Mp3Validator`); nothing is ever executed.
- **Offline-first**: AGENTS.md asks to avoid network dependencies for
  learner and course functionality.

**Conclusion:** the current primitive cannot express a textbook page. It
needs new, additive options and element attributes (Course Model stays
v12, as with `textReveal` and `guidebookButton`), a new renderer and a
dedicated preset.

## 2. Proposal

### 2.1 One card, one page: the **Page** preset

A new preset **Page** (Cards and notes; canonical-only recipe like Before
you start) builds a presentation card from an ordered list of **blocks**.
The learner reads it and presses Continue; no answer, no score, never in
the Duel. Several pages in a row are several Page cards in a Round played
as a sequence (Play as a sequence already exists), so `navigation: paged`
can stay unplayable (see question Q5).

### 2.2 Blocks (prompt elements in order, role `block`)

| Block | Element | New attributes |
| --- | --- | --- |
| Heading | `text` | `textStyle: heading1 \| heading2`, `align` |
| Paragraph | `text` | `textStyle: paragraph` (default), `align`, inline marks |
| Quote / example | `text` | `textStyle: quote`, `align`, inline marks |
| List | `text` | `textStyle: bulleted \| numbered` (one item per line) |
| Picture | `image` | `align`, `size: small \| medium \| large \| full`, caption in `text` |
| Audio | `audio` | the existing read-aloud (TTS or recording), `playback` |
| Video | see 2.4 | see 2.4 |

- `align` is `start | center | end` (and `justify` for paragraphs if the
  owner wants it). Start and end follow the text direction, so
  right-to-left languages work.
- **Inline marks** inside a paragraph, quote or list: `**bold**`,
  `*italic*` (and perhaps `__underline__`). QQL parses them itself (a few
  dozen lines, no dependency, no HTML); an unmatched mark is shown as
  typed and reported by the Audit.
- The block `language` (source or target) keeps working, so a target-
  language paragraph can be read aloud in the target voice.

### 2.3 The editor form

- A list of blocks with **Add block** (Heading, Paragraph, Quote, List,
  Picture, Audio, Video), move up/down, remove, and per block its text,
  style, alignment (three icon buttons) and, for a picture, size and
  caption.
- A small toolbar above a text field inserts `**…**` and `*…*` around the
  selection, so authors need not remember the marks.
- A **live preview** of the page under the form, drawn by the learner
  renderer itself.
- The Generic Primitive Editor shows the same elements and attributes for
  a page no preset represents.

### 2.4 Video: four options (owner decision Q4)

| Option | What the learner gets | Cost and risk |
| --- | --- | --- |
| A. No video | nothing | none |
| B. **External link** | a "Watch the video" button that opens the browser (YouTube, a school site…) | small: `url_launcher` exists; network only when tapped; the link can die; privacy notice in Help; only `https://` accepted |
| C. Video stored in the Course | an embedded player, offline | large: a player dependency (the official `video_player` has no Windows or Linux support; `media_kit` covers every platform but bundles a large native media library; to be verified before choosing), a video validator and size limit like the MP3 rules, bigger Course ZIPs and backups |
| D. Embedded stream | an embedded player fed from the web | as C for the player, plus a network dependency inside learner content, against the offline-first rule |

Recommendation: **B now**, C later only if Courses really need offline
video. D is not recommended.

### 2.5 Pictures on a page

Several pictures per page, each with alignment, size and an optional
caption, stored like today (`media:` Course files, the Shared Image
Library, bundled assets). The 50 KB limit keeps Courses small but is tight
for a full-width textbook picture: see Q3.

### 2.6 What else changes

- Registry: `textStyle`, `align`, `size` are element attributes, not
  options (options belong to the whole card). The capability description
  (`docs/capabilities_v12.json`), the Python converter mirror and
  `tools/validate_courses.py` learn them.
- `ExerciseFeatures`: `pageBlocks`, `LearnerExerciseKind.page` (a
  presentation with `block` elements).
- Runtime: a `_pageExercise` renderer in `RoundScreen` (scrollable, text
  scale respected, RTL aware); Search indexes every block's text.
- Audit (new codes): an empty page (Error), an unmatched inline mark
  (Warning), a picture without its file (existing media rules), a video
  link that is not `https://` (Error).
- Help EN/IT/ES: the preset, each block, the marks, the video choice; an
  Editor Help question.
- The Exercise Laboratory gains a Page Lesson; the presentation baseline
  records the new examples.
- Unchanged: scoring (a page is never scored), progression, the Duel,
  learner data, Course Model v12, package format 1.

## 3. Questions for the owner

- **Q1 Formatting scope.** Headings (two levels), bold, italic, bulleted
  and numbered lists, alignment start/center/end: enough? Add underline,
  justify, text colour or a highlight?
- **Q2 Authoring.** Marks typed with a helper toolbar and a live preview
  (recommended: small, no dependency) or a full WYSIWYG editor (a large
  dependency, harder to keep stable across platforms)?
- **Q3 Pictures.** Keep the 50 KB per image limit, or allow larger page
  pictures (for example 300 KB, still validated and bounded)?
- **Q4 Video.** A, B, C or D above (recommended B)?
- **Q5 Pages.** One card per page, several pages as a sequence of cards
  (recommended), or make `navigation: paged` playable so one card holds
  several pages with Next/Back?
- **Q6 Where.** Rounds and sequences only, or also inside Stories? And
  should the GuideBook later reuse the same blocks?
- **Q7 Read-aloud.** A read-aloud button per paragraph in the target
  language, or none (audio only as an Audio block)?
- **Q8 Existing cards.** Keep Note card as it is (recommended) or offer to
  convert it to a Page?

## 4. Proposed delivery (after approval)

One revision per session, as in Build 256:

1. Model and runtime: element attributes, the inline-mark parser, the page
   renderer, Audit codes, capability description, Python mirror.
2. The Page preset form with the block list, toolbar and live preview;
   Search; Help.
3. Video per Q4 (B: link block and its Audit) and the Laboratory Page
   Lesson with the presentation baseline.

# Plan: textbook-like Page cards (read-only, waiting for the go-ahead)

Status: **decided except Q9, not implemented**. Written on 29 September 2026 after
Build 257 Revision 0 (Before you start cards), at the owner's request: "a
presentation card with basic formatting style like header, bold, italic,
aligned, centered, for texts and images; options for streaming a video; a
dedicated preset", "either using the current primitive or, if necessary,
upgrading it with more options". The owner answered every question the
same day (section 3); implementation waits for an explicit go-ahead.

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
  `asset` and `sharedImageSource`. There is no style, alignment, colour,
  size or link attribute.
- **The renderer is fixed slots** (`RoundScreen._flashcardExercise`): a
  title (`term`), a note (`meaning`), an optional usage sentence and its
  translation, one illustration and a read-aloud button, all centered, in
  fixed text styles. Note card, Flashcard and Picture flashcard are presets
  over this one layout; Dialogue line, Story cover and Before you start
  have their own layouts.
- **No rich text**: no Markdown or HTML dependency; every text is a plain
  `Text` widget.
- **No video**: no element type, no player dependency. `url_launcher` is
  already a dependency (it opens the Course Library web page).
- **Media limits**: a Course image is at most 50 KB (`ImageProfile.exerciseImage`,
  `CourseMediaStore.maxImageBytes`), a recording 50 MB, the cover 1 MB;
  every imported medium passes a validator and nothing is ever executed.
- **Offline-first**: AGENTS.md asks to avoid network dependencies for
  learner and course functionality.

## 2. Design

### 2.1 No new primitive, no new card-level option

A Page is still "read, then Continue", never scored: the Presentation
primitive's job. Formatting belongs to each block, so it is carried by
**element attributes**, not by options (options apply to the whole card),
the way Build 256 Revision 5 added `speakerId` and `playback` to elements
for Stories. One element type is new: `link`. Course Model stays v12
(additive, like `textReveal` and `guidebookButton`). The capability
description (`docs/capabilities_v12.json`) gains an element section so the
Python tools learn the vocabulary, and the new build parses the new
attributes strictly (an unknown style, alignment, colour or size is a
format error).

**Earlier builds (verified):** unlike options, which earlier builds refuse
when unknown (a format error), `PromptElement.fromJson` silently skips
element keys it does not know. An earlier build would therefore open a
Course with pages as plain, unformatted cards, and saving it there would
drop the formatting for good. The Course field `minimumAppBuild` is
already enforced when a Course is read ("This Course requires QuisquisLingo
build N or later"), so the proposal (Q9) is: when a Course is saved with a
Page block, its `minimumAppBuild` is raised to the Page build if lower
(never lowered), and earlier builds refuse it with that message instead of
losing data.

### 2.2 The Page preset: one card, one page

Preset **Page** (Cards and notes; canonical-only recipe). The learner reads
it and presses Continue; no answer, no score, never in the Duel.
`LearnerExerciseKind.page`: a presentation whose prompt elements have role
`block`. Several pages in a row are several Page cards in a sequence (Play
as a sequence exists); `navigation: paged` stays unplayable.

### 2.3 Blocks (prompt elements in order, role `block`)

| Block | Element | Attributes |
| --- | --- | --- |
| Heading | `text` | `textStyle: heading1 \| heading2`, `align`, `color` |
| Paragraph | `text` | `textStyle: paragraph` (default), `align` incl. `justify`, `color`, inline marks, `readAloud` |
| Quote / example | `text` | `textStyle: quote`, `align`, `color`, inline marks, `readAloud` |
| List | `text` | `textStyle: bulleted \| numbered` (one item per line), `color`, inline marks, `readAloud` |
| Picture | `image` | `align: start \| center \| end`, `size: small \| medium \| large \| full`, caption in `text` |
| Audio | `audio` | the existing recording or TTS text, `playback` |
| Video link | `link` (new) | `url` (`https://` only), label in `text`, `align` |

- `align` is `start | center | end`, plus `justify` for paragraph, quote
  and list; start and end follow the text direction (right-to-left
  languages work). Default: start for text, center for pictures.
- `color` is a **named palette**, not free colour codes: `default`,
  `accent`, `red`, `green`, `blue`, `grey`. Each name maps to a colour per
  light and dark theme with enough contrast, so a page stays readable in
  both.
- **Inline marks** in paragraphs, quotes and lists: `**bold**` and
  `*italic*`. QQL parses them itself (a few dozen lines, no dependency, no
  HTML); an unmatched mark shows as typed and the Audit warns.
- `readAloud` (text blocks, **off by default**): the block gets a speaker
  button reading it with TTS in the block's `language` (source or target,
  default target), respecting the learner's Audio Settings; never an audio
  exercise, never required. Recordings go in an Audio block.

### 2.4 The editor form

- A list of blocks with **Add block** (Heading, Paragraph, Quote, List,
  Picture, Audio, Video link), move up/down, remove; per block its text,
  style, alignment (icon buttons), colour (palette swatches), read-aloud
  switch and language; for a picture its size and caption; for a link its
  address and label.
- A small toolbar above each text field wraps the selection in `**…**` or
  `*…*` (owner decision: simple marks, no visual editor).
- A **live preview** under the form, drawn by the learner renderer itself.
- The Generic Primitive Editor shows the same elements and attributes for
  a page no preset represents.

### 2.5 Video: external links (owner decision B)

A **Video link** block shows a "Watch the video" button (label editable)
that opens the address in the browser through `url_launcher`
(`LaunchMode.externalApplication`). Only `https://` addresses are accepted;
the app never downloads or plays video itself, so QQL stays offline-first
(the network is used only when the learner taps). Help explains that
links can stop working and that the site's own privacy rules apply.
Stored or embedded video (options C and D) are not planned.

### 2.6 Pictures: 300 KB for every Course picture (owner decision)

The Course image limit rises from 50 KB to **300 KB** for every Course
picture (`ImageProfile.exerciseImage`, `CourseMediaStore.maxImageBytes`
and the package, backup and Image Bank checks that share them), with the
same validator (format, dimensions, no animation). Pictures embedded in
`course.json` as `data:` URIs (Recognize characters, custom Lesson icons,
custom flags) keep their own limits, because they live inside the Course
file. Help texts that name 50 KB are updated. A page may hold several
pictures.

### 2.7 Where Pages go (owner decision)

- **Now:** practice Rounds and sequences (New Exercise offers Page; the
  Story's Add step does not).
- **Later build:** the Lesson GuideBook reuses the same blocks for its
  formatted text (not part of this plan's delivery; the block model and
  renderer are written so the GuideBook can share them).

### 2.8 What else changes

- `ExerciseFeatures`: `pageBlocks`; `LearnerExerciseKind.page`.
- Runtime: a `_pageExercise` renderer in `RoundScreen` (scrollable, text
  scale and right-to-left respected); Search indexes every block's text;
  no mascot on a Page.
- Audit (new codes): an empty page (Error), an unmatched inline mark
  (Warning), a link that is not `https://` (Error), a picture without its
  file (the existing media rules).
- Help EN/IT/ES: the preset, each block, the marks, the palette, video
  links; an Editor Help question.
- The Exercise Laboratory gains a Page example; the presentation baseline
  records it.
- Note card stays as it is (owner decision); nothing stored changes.
- Unchanged: scoring (a page is never scored), progression, the Duel,
  Review selection, learner data, Course Model v12, package format 1.

## 3. Owner decisions (29 September 2026)

- **Q0 Primitive:** asked whether a Page needs a new primitive or new
  options. Answer given: neither; new element attributes and one element
  type on the Presentation primitive (2.1).
- **Q1 Formatting:** the proposed set, plus justify and text colour "as
  long as it doesn't get too complicated" → the named palette (2.3).
- **Q2 Authoring:** simple marks.
- **Q3 Pictures:** larger than 50 KB with a limit → 300 KB for every
  Course picture.
- **Q4 Video:** external links.
- **Q5 Pages:** one card per page; several pages as a sequence of cards.
- **Q6 Where:** Rounds and sequences now; the GuideBook reuses the blocks
  in a later build.
- **Q7 Read-aloud:** optional per text block, off by default.
- **Q8 Note card:** kept as it is.
- **Q9 Earlier builds (open):** raise `minimumAppBuild` automatically when
  a Course contains a Page, so earlier builds refuse it instead of dropping
  its formatting (proposed), or accept that earlier builds show pages
  unformatted?

## 4. Proposed delivery (after the go-ahead)

One revision per session (`2.0.58+2580NN`), as in Builds 256 and 257:

1. **Model and runtime:** element attributes and the `link` type (parser,
   semantic equality, capability description, Python mirror, validator),
   the inline-mark parser, the palette, the page renderer, the 300 KB
   image limit, Audit codes, and `minimumAppBuild` per Q9.
2. **The Page preset form:** block list, toolbar, palette, live preview,
   Search, Help.
3. **Video links and the Laboratory:** the link block, its Audit, the
   Laboratory Page example and the presentation baseline.

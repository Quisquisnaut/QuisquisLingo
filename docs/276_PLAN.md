# Build 276 plan: hearing every target-language text

The owner's brief of 17 October 2026, his answers of the same day, and the
order of the revisions. Change of plan of 17 October 2026: Build 275 ended
at its Revision 5; the GuideBook's several correct translations (Build 275's
planned Revision 6) and the raw preset IDs in two older dialogs move to
Build 277, the modularization leftovers to Build 278.

## The brief

"Let learners hear every target-language text a Course has a voice for, and
fix how recordings are matched to texts with an apostrophe."

1. Select the image: each picture answer gets the corner speaker, playing
   the answer's word (not shown). Not in Listen and pick the image or any
   listening exercise.
2. Pick the missing word: a speaker beside each target-language answer (a
   tap plays and does not choose). Once answered, Listen to the answer
   plays the whole sentence with the right answer in the gap.
3. Match the words: each target-language word can be heard, as in Match
   pictures to words (the speaker plays and does not match).
4. Build the translation into the target, and Spell the word: each
   target-language block or syllable can be heard. Source-language blocks
   stay silent.
5. Every other preset: the target-language text a learner sees but cannot
   hear is listed for the owner before anything changes.

For all of them: only while the learner's audio is on; the Course's audio
source decides the sound; never source-language text, except the meanings
of a same-language Course; `PlaybackOnRequest` stays the one place that
decides what can be heard, so `CourseAudioUsage.spokenTexts`, Used in N
exercises, Check unused MP3 files and Texts in this Course count the new
texts; Course files do not change and nothing is asked of authors.

Apostrophes: `AudioSegmenter.key` keeps an apostrophe that ends a word
after a letter (L', un', dell') or starts one before a letter ('n, 'r), and
reads ' ’ ʼ as one character, inside words too (dov'è = dov’è); every user
of the key is checked; Texts in this Course shows a text that loses its
borrowed recording as missing, and the CHANGELOG says so.

Help EN/IT/ES for the presets that change, tests (L' / L / l’ and
un / un' / un’), the Laboratory presentation baseline, a CHANGELOG entry.

## The owner's answers (17 October 2026)

1. Picture answers: heard **before** answering, as the brief says ("the
   question can also name the word in source language while tapping the
   picture says the word in target language").
2. Blocks: **every** tile plays, single letters too; a single letter is
   recorded and played as the letter's name.
3. The Audit's duplicate recordings (`AUDIO_MAPPING_DUPLICATE`): today's
   rule (capitals and the spaces around a text) with ' ’ ʼ read as one
   apostrophe, not the playback key.
4. Build 275 merged into `main` first; `build-276` from `main` `7f0e7cab`.
5. Later the same day: go on with the revisions without asking again,
   unless something needs his decision.

Stated by the session and not objected to: blocks play when tapped (no
speaker icons on them), taking a block back out is silent; a word quoted at
both ends ('ciao', ‘ciao’) loses both marks; the Duel is unchanged.

Decided by the session after Revision 0's independent review (within the
brief): single quotes are paired on the whole text, so a phrase in single
quotes ('come here') keeps finding its words' recordings; around a single
letter (rock 'n' roll) they stay apostrophes; an opening elision and a later
word-final one ('O sole, pe' te) pair as well, so every run of words is
looked up as written first ('O, pe'), then without the paired marks (o, pe,
as before Build 276). A block tapped into an answer that cannot be heard says
nothing (choosing is what the tap does).

## The owner's answers of 18 October 2026

1. Build 276 goes on in its order; the GuideBook syntax stays in Build
   277 (a message about Build 275 Revision 5 was an old one).
2. Item 5: everything on the list is to be heard, never the answers of
   the listening exercises: the two faults, the "to target" answers (Pick
   the translation's answers before answering, Choose the answer's
   question, answers and correct-answer line, Type the translation's
   alternatives), the exercises with gaps (Type the missing word, One word
   fills all, Pick the words for the gaps, Complete the text, Missing
   letters), and all the rest.
3. The tiles of all three spelling exercises play when tapped: Spell the
   word, Spell the word in the picture and Spell what you hear.
4. Revision 0 keeps the Beta expiry of 16 November 2026 (prepared on
   17 October, committed after midnight); Revision 1 moves it.

## Revisions

| Rev | What |
|---|---|
| 0 | The apostrophe in the audio key (`AudioSegmenter.key`, the Audit's duplicate rule) |
| 1 | Items 1–4: picture answers, Pick the missing word, Match the words, the blocks of Build the translation (to target) and the tiles of the three spelling exercises |
| 2 | Item 5, part 1: the two faults and the "to target" answers |
| 3 | Item 5, part 2: the exercises with gaps |
| 4 | Item 5, part 3: everything else on the list |

## Item 5: what learners see but cannot hear (all chosen, 18 October 2026)

A read-only survey of the presets (17 October 2026). Most target-language
text carries no `language` mark, so hearing it means reading an unmarked
text as the target language, as Select the image's words already do (Build
274 Revision 2).

- Pick the translation (to target): the answers before answering.
- Type the translation (to target): the ranked alternatives shown after an
  answer.
- Match by meaning: every word (no speaker at all).
- Flashcards with Read aloud None.
- Choose the answer (to target): the question, the answers and the
  correct-answer line.
- Type the missing word; Word order.
- True or false: the statement (with a Spoken statement the audio counts as
  required, so the exercise is skipped while audio is off).
- Pick the words for the gaps; One word fills all; Complete the text (the
  text is never shown whole); Missing letters.
- Put the sentences in order; Sort into groups; Fill the slots.
- Listening presets: their answers, on purpose (hearing them would give the
  answer).
- Read and answer: the dialogue while read-aloud is off, the question, the
  answers.
- Recognize characters.
- Spell the word in the picture (moved to item 4 by the owner's answer of
  18 October 2026, with Spell what you hear).
- What is in the picture; Type what you see; Name what you see.
- Match pictures to words: the closed field and the words after answering.
- Note card: its title shows a greyed speaker.
- Dialogue line: text-only lines and the Story's log.
- Story cover; a Page's text blocks without read-aloud.
- Every preset: a Test Round has no Listen to the answer; a scrolling
  Story's log is never heard again; same-language meanings still unheard in
  some of the places above.

Two faults found by the survey, to fix (owner, 18 October 2026):

- The Flashcard's speakers and the app bar's Play audio do not check the
  learner's audio switch: recordings play while it is off.
- With manual read-aloud, Read and answer's Play audio in the app bar says
  only the first dialogue line.

# Build 271 change summary

Build 271 fixes the more relevant findings still open after Build 270 (the
audit `docs/270_AUDIT.md`, the side findings of the modularization audit
`docs/272_MODULARIZATION_PLAN.md` and two older findings, Build 259 C and E)
and reorganizes the Audio Library. Plan and owner decisions:
`docs/271_PLAN.md`.

## Revision 0 (2.0.71+271000): content that plays wrong

Owner decisions of 10 and 11 October 2026.

### Missing letters with a spoken text

Before: the form's **Spoken text (optional)** was stored as audio the
exercise needs (`required` absent, which means true). A learner with Audio
Exercises off never saw the exercise: it was skipped with the listening
exercises (Build 259 finding C).

Now:

- Saving stores the spoken text as an aid: the audio element carries
  `required: false`. Its `playback` stays `automatic`.
- With the learner's audio on, nothing changes in what is heard: the text is
  read aloud when the exercise opens and **Play audio** repeats it.
- With the learner's audio off, the exercise stays in the Round. Nothing
  plays, there is no Play audio button (in the exercise or in the top bar)
  and no "audio unavailable" message (`RoundScreen._gapAudioSilent`).
- The line under the title is **"Write the missing letters."** with or
  without a spoken text. Before, a spoken text made it "Fill in the missing
  word you hear.", which was wrong for letters and wrong without sound.
  `ExerciseFeatures.kind` is `inputListenGaps` only when the audio that
  plays by itself is required; with optional audio the kind is
  `inputComplete`.
- Listen and fill the gaps (the listening preset) keeps its required audio.

### Put the sentences in order

Before: whether an Arrange showed lines or words was guessed from the text
of its blocks (two or more blocks, each with three words or ending with
. ! ? …). Two short lines such as "Ciao Anna" and "Ciao Marco" showed the
title PUT THE SENTENCES IN ORDER over the line "Arrange the words in the
correct order." (Build 259 finding E).

Now:

- Saving marks every block as a line: the item's text element has the role
  `line`. `ExerciseFeatures.isLineOrder` reads the mark first; the guess
  from the text remains only for an exercise without it.
- `line` is in `ElementRoles` (item place), so the canonical editor's Role
  menu offers it and describes it.

### Exercises saved before this version

Owner decision: no handling of earlier exercises. Nothing is converted.

- A Missing letters stored with required audio is still an audio exercise
  and is still skipped without audio.
- A Put the sentences in order without the mark is still guessed from its
  text.
- Both still open in their preset's form and keep their title:
  `PresetVariants.withSaveMarks` is what saving adds that no form field
  shows, and `PresetRecipes.represents` compares with those marks on both
  sides. Saving such an exercise in its form stores the new shape.

### The Audit flow copies the Round

`CourseEditorScreen._openAuditIssue` rebuilt the Round field by field after
an exercise opened from an Audit finding was saved. A Round field added
later would have been dropped there without any test noticing. It now calls
`CourseHierarchyUpdateService.roundWithContent`, which copies the whole
Round and replaces only its content. Nothing changes on screen.

### Content

- `tools/generate_exercise_laboratory_254.py`: the `missing_letters_audio`
  example has optional audio; the two `sentence_order` examples carry the
  `line` role.
- Regenerated: `assets/courses/exercise_laboratory_en_it.json`,
  `docs/254_LABORATORY_COVERAGE.md`,
  `test/fixtures/v12/laboratory_future_en_it.json` and
  `test/fixtures/v11/exercise_laboratory_en_it.json`.
- QQL Demo: English from Italian has neither exercise type and is unchanged.

### Help

EN/IT/ES: the Missing letters answer says the spoken text is an aid and that
a learner with audio off gets the exercise without it; the Put the sentences
in order answer says a line may be as short as two words. The form's Spoken
text helper says the same.

### Not changed

Scoring, progression, Review, the Duel, learner data and the Course format
(roles are free strings; `required` already existed). No `minimumAppBuild`
is raised: an earlier app version plays both exercises as it did before.

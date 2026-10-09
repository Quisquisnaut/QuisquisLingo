# Build 268 change summary

Evidence: `docs/268_VALIDATION.md`. Handoff: `docs/268_HANDOFF.md`.

## Revision 0 (2.0.68+268000): two-sided Flashcards

Owner report of 9 October 2026: QQL's Flashcards had no two sides; the
picture, the word, the translation and the example were all shown at once.
Decisions of the same day, after a mock-up of five cards and a short
review of what teaches best (you get good at the direction you practise;
word → meaning suits new words, meaning → word builds production, both is
best):

- the learner may skip a card they know: **Got it** on the front;
- the **word** is on the front the first time, also on a Picture flashcard
  (a picture alone in front would ask what "What is in the picture?" asks);
- the direction changes by itself (choice (b)), with no stored setting and
  no "to source" / "to target" twins;
- the example is read aloud only on request.

### What learners see

- **The first time through a Round** the front shows the word or expression
  with its read-aloud button (with read-aloud set to Automatically, the word
  is spoken here, as before). The back shows the word small, the
  translation, then the example with its translation. A Picture flashcard's
  back has the picture with the translation, then the example.
- **Turning**: a tap on the card, **Turn over**, Enter or Space; again to
  turn it back. Screen readers find the card as a "Turn over" button. With
  Animations on and no reduced motion asked by the system the card turns
  (about half a second); otherwise the sides just swap. The card says "Tap
  the card to turn it over".
- **Buttons**: Turn over and Got it on the front; Review again and Got it
  after turning. Got it on the front skips a card the learner already knows.
  After Got it the card can still be turned.
- **Reversed (repeat and Review)**: when a Round the learner has already
  completed is played again, and in Review, the front shows the meaning
  (for a Picture flashcard the picture with the translation) and the back
  the meaning small, the word with its read-aloud button, then the example.
  The instruction asks "Think of the Italian word, then turn the card."
  (the learning language named in the instruction language). Nothing gives
  the word away before turning: no automatic read-aloud, no Play audio in
  the top bar. With read-aloud set to Automatically the word is read the
  first time the back shows.
- **The editor's Preview** always shows the word first.
- **Instruction**, the word first: "Think of what it means, then turn the
  card."
- **Unchanged**: a card that ends with Continue stays one page: the Note
  card, Before you start, Page, Story lines and covers; the Duel has no
  cards. A card without a translation and without a picture stays as it
  was.

### For authors

Nothing to change: no Course file changes, and every existing Flashcard and
Picture flashcard becomes two-sided. Help EN/IT/ES describes the two sides,
the reversed card and when Automatically reads the word: Flashcard, Picture
flashcard, the Read-aloud field, What is a FlashCard Round?

### Code

- `lib/services/flashcard_sides.dart` (new, pure Dart): `FlashcardFront`
  (word, meaning) and `FlashcardSides` (`isTwoSided`: a presentation of
  learner kind `presentation` with completion mode `understoodReview`, a
  `term` and a `meaning` or a picture; `frontFor(roundCompleted:, review:,
  preview:)`).
- `lib/screens/round_screen.dart`: `_twoSidedFlashcard` (keys
  `flashcard-card`, `flashcard-front`, `flashcard-back`, `flashcard-word`,
  `flashcard-meaning`, `flashcard-back-front-text`, `flashcard-back-answer`,
  `flashcard-turn-hint`, `flashcard-turn-over`, `flashcard-review-again`,
  `flashcard-got-it`), `_turnCard`, `_cardMeaningFirst` (from
  `_wasCompleted`, `reviewMode`, `previewMode`), `_cardWordHidden`,
  `RoundScreen.cardTurnDuration` (450 ms); the shared illustration is not
  drawn above a two-sided card; `_automaticAudioOf` holds back a reversed
  card's read-aloud; the one-sided card shares `_cardWordButton` and
  `_cardUsage` and is drawn as before.
- `ExerciseCopyService.instructionForExercise(meaningFirst:)` and the
  catalog keys `instruction.flashcardWordFirst`,
  `instruction.flashcardMeaningFirst` (seven languages); learner panel
  `turnOver`, `tapToTurn` (seven languages). The six translations are
  AI-written.

Scoring, progression, Course files and learner data are unchanged; cards
still give no XP. Beta expiry `2026-11-08 23:59:59` local time (the same
release day as 267010).

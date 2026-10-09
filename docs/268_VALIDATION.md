# Build 268 validation

## Revision 0 (2.0.68+268000), 9 October 2026

Run on the owner's Windows PC (4 cores, 8 GB), `TEMP`/`TMP` on
`D:\QQL_test_temp` for the test processes only.

- `dart format` on the changed Dart files only.
- `flutter analyze --no-pub`: **No issues found.**
- New tests, `test/two_sided_flashcards_268_test.dart`: **16 passed**:
  - which cards have two sides (the Laboratory's Flashcards and Picture
    flashcards; never a Note card; a card needs a translation or a picture
    behind its word) and the direction (word first, meaning first on a
    repeat and in Review, word first in the Preview whatever else);
  - the instruction lines in English ("Think of what it means, then turn the
    card." / "Think of the Italian word, then turn the card."; a Note card
    keeps its line) and the new texts in every learner language;
  - on the learner screen: the Preview shows only the word and its
    read-aloud button, Turn over and Got it; a tap turns the card to the
    translation, the word small and the example (Review again and Got it)
    and back; Turn over, Enter and Space turn it; Got it on the front gives
    Card reviewed and the card can still be turned; Review again requeues
    the card, which comes back word first; a Picture flashcard draws its
    picture only on the back; the turn is animated with Animations on and
    swaps at once with reduced motion; a Note card stays one page with
    Continue; the first time through a Round an automatic read-aloud reads
    the word on the front; a repeat of a completed Round shows the
    translation first with no read-aloud and no Play audio, reads the word
    once when the card turns, and not again on later turns; Review shows a
    Picture flashcard's picture with its translation first.
- Laboratory: `exercise_laboratory_254_test.dart` turns the card before
  Review again; the presentation baseline re-records its 8 Flashcards
  (before turning only the word shows, the instruction asks for the
  meaning, Turn over beside Got it; the meaning, picture and example are no
  longer counted on the front); the two Note cards record unchanged. The
  card and Presentation tests: **22 passed**.
- Focused batch (35 files near the change: copy and learner panel, titles,
  languages, the XP regression with cards, Stories, sequences, Review,
  Preview, mascots, Help and field Help, bundled Courses, audio settings,
  dark mode, responsive layout, the version pins): **322 passed.**
- Complete suite (`flutter test --no-pub --concurrency=1 --reporter compact`,
  Windows kept awake, 22:38–23:14): **4,038 passed, 1 skipped** (POSIX only),
  exit code 0.

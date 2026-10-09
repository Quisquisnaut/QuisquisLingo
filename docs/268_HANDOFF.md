# Build 268 handoff

Started 9 October 2026 (owner: two-sided Flashcards), on the branch
`build-268` in the main checkout `C:\QQL\QuisquisLingo` (from `main` at
`bebb8b20`, Build 267 Revision 10, pushed). Git rule from Build 268: one
branch per Build; after each revision's commit push the branch
(`git push -u origin build-268`, standing permission, a backup, no pull
request); merge into `main` and push `main` only on the owner's go.
Summary: `docs/268_CHANGE_SUMMARY.md`; evidence: `docs/268_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`,
`docs/COLLOCATION_PICTURES_PROPOSAL.*`.

## Revision 0 (2.0.68+268000), two-sided Flashcards

Owner decisions of 9 October 2026 (mock-up: https://claude.ai/artifact/Ht8pkCiqugsJWYSUJamWuM,
five cards; the plan was approved with "Keep the plan"):
- Got it on the front skips a known card; Review again and Got it after
  turning.
- The word is on the front the first time, also on a Picture flashcard; the
  picture goes on the back with the translation (card 3 of the mock-up).
- Direction (b), automatic: the meaning first on a repeat of a completed
  Round and in Review; the Preview always word first; nothing stored.
- No "to source" / "to target" Flashcard twins (asked and answered: keep
  one Flashcard; graded "to target" practice exists in Type / Build / Pick
  the translation). A per-card "Front: Automatic / Word / Meaning" option
  was offered for later (a Course format change and `minimumAppBuild`);
  not wanted now.
- The example is read aloud only on request.

Decisions taken in this session (told to the owner in the final report):
- A card is two-sided only with a translation or a picture behind its word
  (`FlashcardSides.isTwoSided`); otherwise it stays as before.
- Reversed card: the back shows the picture, the meaning small, the word
  large with its read-aloud button, then the example (symmetrical with the
  word-first back). No automatic read-aloud and no top-bar Play audio until
  turned; Automatically reads the word the first time the back shows, once.
- After Got it on the front the card may still be turned (the mock-up hid
  the buttons; here they stay, greyed, as before).
- The hint "Tap the card to turn it over" is on both faces (the mock-up's
  "Tap to turn it back" and its FRONT / BACK labels are not in the plan's
  texts).
- Italian uses "scheda" for card, as the learner panel's "Scheda
  ripassata"; Portuguese is European, as its catalog.
- IDDQD View Only replays read the word first (`_wasCompleted` is false
  there, as for its XP).

State: done. Focused tests green (new file 16, Laboratory cards 22,
focused batch 322), analyzer clean, complete suite 4,038 passed, 1 skipped
(9 October 2026, 22:38–23:14). Committed on `build-268` and the branch
pushed as a backup (commit hash in the commit log; no pull request).

Next: the owner reviews the Windows build; corrections are a same-version
follow-up commit.

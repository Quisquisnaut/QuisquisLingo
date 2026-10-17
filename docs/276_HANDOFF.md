# Build 276 handoff

Branch `build-276` from `main` `7f0e7cab` (Build 275 fast-forwarded into
`main` and pushed on 17 October 2026 at the owner's go; `build-275` deleted
locally and on origin). Plan: `docs/276_PLAN.md`, the owner's brief and
answers of 17 October 2026 (hear every target-language text a Course has a
voice for; the apostrophe in the audio key). Every revision: version
`2.0.76+276RRR`, Beta expiry 30 days from its release day, `CHANGELOG.md`,
`README.md`, the `AGENTS.md` release entry, `docs/276_CHANGE_SUMMARY.md`,
`docs/276_VALIDATION.md`, this file; focused tests while working (a new
test file is run six times before the suite), an independent read-only
review and its re-read, `flutter analyze` and the complete suite once on
the final tree; one commit, the branch pushed. Help EN/IT/ES wherever a
screen or a rule an author reads changes. The owner (17 October 2026): go
on with the revisions without asking again, unless something needs his
decision.

## Revision order

| Rev | What | State |
|---|---|---|
| 0 | The apostrophe in the audio key | done |
| 1 | Picture answers, Pick the missing word, Match the words, the blocks of Build the translation (to target), the tiles of the three spelling exercises | next |
| 2 | Item 5, part 1: the two faults and the "to target" answers | after 1 |
| 3 | Item 5, part 2: the exercises with gaps | after 2 |
| 4 | Item 5, part 3: everything else on the list | after 3 |

## Open points for the owner

- None. Answered on 18 October 2026: Build 276 keeps its order; the whole
  item 5 list is to be heard (never the listening answers), with the two
  faults fixed; the tiles of all three spelling exercises play; Revision 0
  keeps the expiry of 16 November.

## To do

- Revision 0: the review and its re-read are done; the corrections of the
  re-read (each run of words looked up as written first) await a third
  read, then six runs, `flutter analyze`, the complete suite, commit
  (message in the session scratchpad `commit_276000.txt`), push.
- Revision 1: the four presets of the brief (see the plan). Drafts in the
  session scratchpad `r276_1/` (`playback.py`, `round.py`, `help.py`, the
  test file): `PlaybackOnRequest.optionWord` for every Select the image
  answer, Pick the missing word (`selectComplete`) and Match the words
  (`matchTranslation`); `answerText` gives Pick the missing word's
  sentence with its right answer; `blockWords` for Build the translation
  into the target and Spell the word without a picture (not
  `arrangeInline`); the Round screen's `_withListSpeaker`,
  `RadioListTile.secondary`, `match-row-speaker-<id>` and `_tapBlock`.
  `playback_on_request_274_test` changes where the owner changed the rule
  (picture answers heard; Build the translation's blocks heard).

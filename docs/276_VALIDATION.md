# Build 276 validation

## Revision 0 (2.0.76+276000), the apostrophe in a recording's text

- New tests: `test/apostrophe_key_276_test.dart`, **25 passed**: the key
  (L' / L’ / Lʼ against L, un / un' / un’, 'n and 'o, dov'è = dov’è, quoted
  words and phrases, ʼ at the edges, rock 'n' roll, 'O … dell',
  digits, punctuation alone), playback (`segment` and
  `RecordedAudioService.segment`, a phrase in single quotes, no borrowed
  letter n, Neapolitan 'O … pe' with and without their own recordings),
  the missing parts as written, Associate recording's
  `ownRecordingOf`, Texts in this Course (a text that borrowed a recording
  now missing; a curly apostrophe's recording its own), Used in N
  exercises and Check unused MP3 files (`usesByClip`, `unused`), the
  Audit's duplicate recordings, and a sweep: every spoken and recorded
  text of seven Course files without an apostrophe or a single quote at a
  word's edge (210) keys exactly as before. Six clean runs on the final
  file (25 tests each).
- The test files that use the key, the Audio Library or the Audit's
  registry (twelve files: audio import paths, Audio Library, audio
  settings, usage, Edge Case, the Round's audio indicator,
  `RecordedAudioService`, same-language meanings, Listen and pick the
  missing word, playback on request, the Audit registry and its branch
  ownership), on the final code: **178 passed**.
- Independent read-only review: one blocking regression, found before
  the suite: single quotes around several words ("She said 'come here'.")
  no longer matched the words' recordings, because the quotes were judged
  word by word. Corrected: the quotes are paired on the whole text before
  it is cut into words. Also corrected: ʼ (a letter for Unicode) was never
  an apostrophe at the edges; the documents said "Recorded MP3 only is
  silent" (an exercise that needs the audio is left out) and did not say
  that a Course holding L' and L’ now has an Audit Error that blocks
  publishing and import; tests for `usesByClip`, quoted phrases, ʼ and a
  sweep of ordinary texts; the RegExps made static and each recording
  keyed once; Help names the single quotes. Not tested on purpose:
  `AudioExerciseAvailabilityService` (it calls `segment`; a test would
  need recording files). Its re-read of the corrections found one more
  regression: an elision opening a text and another ending a later word
  ('O sole, pe' te, common in Neapolitan) were paired as a quotation and
  no longer found their own recordings ('O, pe'), which the recordings'
  own keys keep. Corrected: each run of words is looked up as written
  first, then without the paired marks (as before Build 276), with
  `segment` tests for both; a missing run is shown with its own quotes
  paired. Left: nested quotes ('Rock 'n' roll' is music) pair the outer
  opening mark with the inner closing one (rare). A third read of that
  correction: nothing blocking; the lookup keeps the longest run first
  and the written form before the unquoted one at each length, and what
  matched before Build 276 still matches. Acted on: the CHANGELOG says
  that in such a text an elision without its own recording can still
  borrow ('Ndo vai, l' amico). Left: when only one word of a quoted phrase
  is missing, Texts in this Course shows it with its opening mark
  ("'come"); a recording of either form plays it.
- `flutter analyze`: **No issues found**.
- Complete suite (`flutter test --concurrency=1`, 45 minutes): **5,014
  passed, 1 skipped, 0 failed**.

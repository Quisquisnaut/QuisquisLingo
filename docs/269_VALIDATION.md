# Build 269 validation

## Revision 0 (2.0.69+269000), 10 October 2026

Run on the owner's Windows PC (4 cores, 8 GB), `TEMP`/`TMP` on
`D:\QQL_test_temp` for the test processes only.

- `dart format` on the changed Dart files only (the three new files needed
  it; the others were already formatted).
- `flutter analyze --no-pub`: **No issues found.**
- New tests, `test/spoken_lines_269_test.dart`: **12 passed**:
  - the pace: 12 characters a second until measured, 0.8 s for the
    shortest line, the measured pace (start-up included) and its bounds
    (6–25), nothing measured from an empty line or no time; an end before
    40% of the estimate is not the real end;
  - the words: a word with its punctuation brightens when its first
    character's share of the time has passed; the first word at once, the
    whole line at the end;
  - on the learner screen (the Preview, a voice timed on the test's clock):
    the whole line shows at once, the words not yet read dimmer (alpha
    below .5), the first word bright as the voice starts, more words bright
    halfway, every word bright at the estimate (the line's ordinary text
    again) while Continue still waits for the voice, Continue usable when
    the voice ends, the pace measured from that real end (33 characters in
    3 s: 11 a second); a voice ending before the estimate brightens the rest
    within a quarter of a second and frees Continue at once; a voice that
    returns at once leaves the line to its estimate (Continue at 2.75 s, no
    measurement); a failing voice shows the line, frees Continue and shows
    the usual message; reduced motion shows the line whole and Continue
    still waits; text after listening shows "Listen first…" and Continue
    waits, then the whole text; an audio-only line holds Continue until it
    is read; Play on request changes nothing (no dim text, Continue usable
    while the voice plays); with the learner's audio off the line shows at
    once with Continue usable.
- Updated tests: `story_runtime_256_test.dart` waits for Continue on lines
  that read themselves aloud and checks that the audio-only line's Continue
  starts greyed; `exercise_laboratory_254_test.dart` lets a line's time pass
  before Continue (its presentation baseline is unchanged: the "before"
  record of every line matched).
- Focused batch (16 files: the new tests, Stories, the Laboratory, two-sided
  Flashcards, audio settings, Before you start, sequences, the runtime,
  titles, Word Lookup, support states, interoperability, Listen and choose,
  Pick the translation, learner-flow hardening): 458 passed, 8 failed, all
  the Laboratory's Story lines pressing Continue while the line was read;
  after the test change the Laboratory's Story and line-option examples:
  **34 passed**.
- Complete suite (`flutter test --no-pub --concurrency=1 --reporter compact`,
  Windows kept awake, Android Studio closed for memory, 01:21–01:53):
  **4,050 passed, 1 skipped** (POSIX only), exit code 0.

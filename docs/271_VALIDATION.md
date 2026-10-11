# Build 271 validation

## Revision 0 (2.0.71+271000), content that plays wrong

11 October 2026, owner's Windows 10 PC, `build-271`.

- New tests: `test/content_plays_right_271_test.dart`, **16 passed**:
  - Missing letters (8): the spoken text stored as optional audio that
    still plays by itself; the kind and the line "Write the missing
    letters."; the preset represents it and reads its fields back; an
    exercise stored earlier keeps its required audio, is still represented
    by its preset and takes the new shape when its form rebuilds it; Listen
    and fill the gaps is still an audio exercise; the Laboratory example;
    as a learner with audio off, the exercise is in the Round, with no Play
    audio, nothing spoken and no message; with audio on, the text is spoken
    and Play audio shows; an earlier exercise is still skipped without
    audio.
  - Put the sentences in order (6): the blocks carry the role `line` and
    two short lines are lines; without the mark the text is still guessed
    (two short lines read as words, three-word or closed lines as lines)
    and such an exercise still opens in its form, which saves the mark; Put
    the words in order is not marked; the canonical editor offers the role;
    the two Laboratory examples; as a learner, two short lines show PUT THE
    SENTENCES IN ORDER and "Arrange the lines in a logical order."
  - A Round copied whole (2): a Test Round keeps every field (state,
    provisional mark, time stamp, title, type, fixed order, passing percent,
    focus and supporting modules); a Timed Round keeps its limits and a
    sequence its flow.
- Generators: `tools/generate_exercise_laboratory_254.py --check`,
  `tools/generate_english_from_italian_260.py --check` and
  `tools/generate_edge_case_demo_254.py --check` pass;
  `tools/validate_courses.py`: 2 bundled Course Model v12 files validated.
  The regenerated Laboratory differs from the committed one only in the
  Missing letters example's `required: false`, the eight `line` roles of the
  two Put the sentences in order examples and the checksum.
- Laboratory presentation baseline
  (`test/support/laboratory_presentation_254.dart`): one record changed,
  `qql_lab254_missing_letters_audio`, its instruction only ("Write the
  missing letters." before and after answering); 123 records unchanged.
- Related files, first batch (22 files, two test processes): 609 passed,
  2 failed. One was the baseline record above before it was updated. The
  other, `exercise_laboratory_254_test` "learner completes
  qql_lab254_reading_dialogue_automatic", recorded the two dialogue lines in
  the wrong order; the file run alone afterwards: **253 passed**.
- Related files, second batch (33 files with the new file and the version
  pins): **280 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,175 passed, 1 skipped**, 40:49 (11 October 2026,
  10:03–10:44). It ran with about 1.2 GB of memory free (two browsers
  open), slower than usual; no test failed and none failed to load.

Not checked: the Linux, Android, iOS and macOS builds (no platform code
changed); a Windows release build was not made for this revision.

# Build 269 handoff

Started 10 October 2026 (owner: Story lines read aloud word by word), on the
branch `build-269` in the main checkout `C:\QQL\QuisquisLingo` (from
`build-268` at `12a764db`, which `main` also points to, pushed). Git rule
from Build 268: one branch per Build; after each revision's commit push the
branch (`git push -u origin build-269`, standing permission, a backup, no
pull request); merge into `main` and push `main` only on the owner's go.
Summary: `docs/269_CHANGE_SUMMARY.md`; evidence: `docs/269_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`.

## Revision 0 (2.0.69+269000), Story lines read aloud word by word

Owner request of 10 October 2026: in Story Rounds the dialogue text shows
gradually while it is spoken, and Continue is greyed out until the line has
been read. Owner decisions of the same day (questions with mock-ups):
- **Style**: the whole line appears at once, dimmer; each word becomes
  bright when its time to be read has passed (karaoke; the owner first
  chose "word by word", then specified this).
- The owner's idea: even without knowing when the voice plays, wait a time
  in proportion to the line's length.
- Lines that are not spoken (text only, or the learner's audio off) show at
  once, Continue usable at once, as before.
- Story read-aloud "On request": a tap on Play changes nothing (text shown,
  Continue usable).

Findings that shaped the design: no voice QQL uses reports word timing;
Windows (System.Speech through PowerShell, about a second to start),
Linux (eSpeak + aplay) and Android (`awaitSpeakCompletion`) return when
speech ends; recorded MP3s too; iOS/macOS flutter_tts returns at once.

Decisions taken in this session (to tell the owner in the final report):
- The pace starts at 12 characters a second and follows the device: each
  line whose voice reported its real end is measured (start-up included),
  kept between 6 and 25 characters a second, for the app session only
  (`SpokenLinePace.shared`); nothing stored. Shortest line 0.8 s.
- A voice that "ends" before 40% of the estimate did not report its real
  end: the line is then paced by the estimate alone (Continue at the
  estimate).
- When the voice really ends, the words still dim brighten within 250 ms
  and Continue is usable at once; if the words are all bright first,
  Continue waits for the voice.
- A word becomes bright when the share of time its first letter holds in
  the line has passed (the first word as soon as the reading starts).
- Text after listening lines, audio-only lines and Animations off / reduced
  motion: no karaoke, Continue still waits for the voice.
- A voice that fails: whole text, Continue at once, the usual SnackBar.
- A held line whose voice never starts releases Continue after 5 s
  (`RoundScreen.lineWatchdogDelay`, a Crash Log debug entry).
- Word Lookup works on the line once every word is bright.

State: done. Code, Help EN/IT/ES, tests and docs (CHANGELOG, README,
AGENTS release boundary, change summary, validation); version
2.0.69+269000 (Beta expiry 2026-11-09 23:59:59). New tests 12 passed; the
focused batch found the Laboratory test pressing Continue on lines being
read (test fixed, 34 passed); formatted, analyzer clean; complete suite
4,050 passed, 1 skipped (10 October 2026, 01:21–01:53; the owner closed
Android Studio for memory). Committed on `build-269` and the branch pushed
as a backup; `main` is untouched (merge and push only on the owner's go).

Next: the owner reviews the Windows build; corrections are a same-version
follow-up commit on `build-269`.

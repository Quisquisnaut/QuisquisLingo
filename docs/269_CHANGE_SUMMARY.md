# Build 269 change summary

Evidence: `docs/269_VALIDATION.md`. Handoff: `docs/269_HANDOFF.md`.

## Revision 0 (2.0.69+269000): Story lines read aloud word by word

Owner request of 10 October 2026: in Story Rounds the dialogue text should
show gradually while it is spoken, and Continue should be greyed out until
the line has been read. Decisions of the same day:

- the whole line appears at once, dimmer, and each word becomes bright when
  the time to read it has passed;
- since no voice tells QQL which word it is saying, the words follow a time
  in proportion to the line's length (the owner's idea);
- lines that are not spoken (text only, or the learner's audio off) show at
  once, with Continue usable at once, as before;
- with the Story's read-aloud On request, a tap on Play changes nothing.

### What learners see

- **A line that reads itself aloud** (the Story's or the line's read-aloud
  Automatic, the learner's audio on): the whole line is in the bubble at
  once, in a dimmer colour; from the moment the voice is asked to speak,
  the words become bright one after another, each with its punctuation.
  When every word is bright the line is ordinary text again, and Word
  Lookup works on it.
- **Continue** is greyed out until the line has been read: the voice has
  finished and the line's time has passed. When the voice finishes before
  the last words are bright, they brighten at once (within a quarter of a
  second) and Continue is usable; when the words are all bright first,
  Continue waits for the voice.
- **The pace** starts at a usual speaking speed (12 characters a second)
  and follows the voices of the device: each line whose voice reports its
  end is measured (the time the voice takes to start included) and later
  lines use the measured pace, for as long as the app runs. Nothing is
  stored. A voice that returns almost at once (some systems do not wait for
  speech) has not reported its end: the line then follows the estimated
  time.
- **An audio-only line** ("Listen…") and **a line whose text shows after
  listening** look as before; Continue now waits for them too.
- **Animations off or reduced motion**: the line shows whole at once, and
  Continue still waits for the voice.
- **A voice that fails**: the line shows whole, Continue is usable at once,
  and the usual message explains the audio problem.
- **A voice that never starts** (it should not happen): Continue is usable
  after five seconds, and the Crash Log notes it.
- **Unchanged**: lines that are not spoken; a tap on Play (On request, or a
  replay); the lines already in a scrolling Story's log; the other
  exercises, Read and answer dialogues and the Duel. The editor's Preview
  behaves like the learner's Round.

### For authors

Nothing to change: no Course file changes. Help EN/IT/ES describes the
reading in Dialogue line and its Read-aloud and Text reveal fields.

### Code

- `lib/services/spoken_line_pace.dart` (new, pure Dart): `SpokenLinePace`
  (`estimate`, `record`, `isRealEnd`, `charactersPerSecond`, `shared`,
  `reset`) and `SpokenLineWords.brightLength`.
- `lib/widgets/spoken_line_text.dart` (new): `SpokenLineText` (key
  `story-line-spoken`, the bright and dim parts of one `Text.rich`, its own
  ticker; `speaking`, `finished` (catch-up), `onDone`; then `LookupText`).
- `lib/screens/round_screen.dart`: `_lineHeld`, `_lineSpeaking`,
  `_lineVoiceEnded`, `_lineFinished`, `_lineEstimate`, `_lineTimer`,
  `_lineWaits`; `_prepareLineHold`, `_armLineWatchdog`
  (`lineWatchdogDelay`), `_lineVoiceDone`, `_lineRead`;
  `_speak(automatic:)` (only `_activatePreparedAudio` passes true) times the
  voice with `RoundScreen.lineStopwatch` (a test seam); `_lineBubble(spoken:)`;
  `story-line-continue` and `_continueLine` respect `_lineWaits`.

Scoring, progression, Course files and learner data are unchanged. Beta
expiry `2026-11-09 23:59:59` local time.

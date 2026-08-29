# App logic

```text
LEARNER PROFILE
|
+-- language
|    +-- XP / streak / study days
|
+-- course ID
|    +-- completed Rounds / Topics / Duel wins
|    +-- permanent Laurel crowns
|    +-- up to 50 distinct Review Round results
|
+-- learner-global Weekly XP and weekly-goal celebration state
|
+-- avatar appearance (shared across languages)
```

```text
COURSE
|
+-- TOPIC (shown to learners as Lesson)
|    |
|    +-- GUIDEBOOK
|    |
|    +-- ROUND
|    |    +-- exercises/content
|    |    +-- latest attempt error count
|    |    +-- perfectAchieved -> permanent Laurel crown
|    |
|    +-- TOPIC DUEL
|         +-- actual eligible pool from this Topic only
|         +-- available at 25 or more eligible exercises
|         +-- standard: 25 questions, 4 lives, no score or pass threshold
|
+-- next TOPIC unlocks when the immediately previous Topic is completed
    OR when the immediately previous Topic Duel is won
```

The first Topic is genuinely unlocked. Learners may open its Rounds freely. IDDQD Mode grants temporary access to genuinely locked Topics without changing their lock state or the progress recorded while they are open.

## Review priority

For each learner + Course ID, keep at most 50 distinct recently completed Rounds. Repeating a Round replaces its latest-attempt record.

```text
sort key 1: latestErrors descending
sort key 2: completedAt descending
```

A Review attempt can earn a permanent Laurel crown exactly like a normal course attempt.

## Streak freeze rule

A language streak advances only on a new day when that language is studied. A day spent studying another language freezes it. A completed day with no learning activity in any language breaks active language streaks.

## Course authoring boundary

Bundled JSON files are read-only. Course Editor stores a validated local Course Model v4 override. The Topic/Round/content hierarchy can be created, deleted and reordered locally. Reset local edits returns to the bundled asset.

## Storage boundary

```text
DEVICE ONLY
- learner profiles and avatar preferences
- language-scoped XP, streaks, study days and Status inputs
- learner-global Weekly XP and per-course Weekly XP breakdowns
- course-scoped Round/Topic/Duel progress, Laurels and Review history
- local Course Model v4 Course Editor overrides
- settings
- automatic Crash Log plus separate exportable Diagnostic Log

SERVER
- none required by the current prototype
```

## TTS

Android, iOS and macOS use the platform TTS engine through `flutter_tts`. Windows uses the System.Speech backend with same-language locale fallback. Linux uses an installed eSpeak NG/eSpeak executable and does not invoke a shell parser. Web TTS remains experimental and must be smoke-tested separately.

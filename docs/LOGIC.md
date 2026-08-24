# App logic

```text
LEARNER PROFILE
|
+-- target language/course
|    |
|    +-- language-specific XP / streak / study days / Status
|    +-- completed rounds/topics / Duel wins
|    +-- permanent laurel crowns
|    +-- up to 50 distinct Review round results
|
+-- avatar appearance (shared across languages)
```

```text
COURSE
|
+-- CHAPTER
|    |
|    +-- TOPIC
|    |    |
|    |    +-- ROUND
|    |         |
|    |         +-- exercises
|    |         +-- latest attempt error count
|    |         +-- perfectAchieved -> permanent laurel crown
|    |
|    +-- CHAPTER GATE
|         +-- complete required topics
|         OR
|         +-- win Language Duel (standard: 25 questions, 4 lives, no score or pass threshold)
|
+-- next CHAPTER
```

Learners may jump freely among topics and rounds inside an available chapter.

## Review priority

For each learner + target language, keep at most 50 distinct recently completed rounds. Repeating a round replaces its latest-attempt record.

```text
sort key 1: latestErrors descending
sort key 2: completedAt descending
```

A Review attempt can earn a permanent laurel crown exactly like a normal course attempt.

## Streak freeze rule

A language streak advances only on a new day when that language is studied. A day spent studying another language freezes it. A completed day with no learning activity in any language breaks active language streaks.

## Course authoring boundary

Bundled JSON files are read-only. Course Editor stores a validated local course override. The hierarchy can be created, deleted and reordered locally. Reset local edits returns to the bundled asset.

## Storage boundary

```text
DEVICE ONLY
- learner profiles and avatar preferences
- language-specific progress and Status inputs
- Review history
- local Course Editor overrides
- settings
- automatic Crash Log plus separate exportable Diagnostic Log

SERVER
- none required by the current prototype
```

## TTS

Android, iOS and macOS use the platform TTS engine through `flutter_tts`. Windows uses the System.Speech backend with same-language locale fallback. Linux uses an installed eSpeak NG/eSpeak executable and does not invoke a shell parser. Web TTS remains experimental and must be smoke-tested separately.

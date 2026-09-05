# App logic

```text
LEARNER PROFILE
|
+-- language
|    +-- XP / streak / study days
|
+-- course ID
|    +-- completed Rounds / Lessons / Duel wins
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
+-- LESSON (shown to learners as Lesson)
|    |
|    +-- GUIDEBOOK
|    |
|    +-- ROUND
|    |    +-- exercises/content
|    |    +-- latest attempt error count
|    |    +-- perfectAchieved -> permanent Laurel crown
|    |
|    +-- LESSON DUEL
|         +-- actual eligible pool from this Lesson only
|         +-- available at 25 or more eligible exercises
|         +-- standard: 25 questions, 4 lives, no score or pass threshold
|
+-- next LESSON unlocks when the immediately previous Lesson is completed
    OR when the immediately previous Lesson Duel is won
```

The first Lesson is genuinely unlocked. Learners may open its Rounds freely. IDDQD Mode grants temporary access to genuinely locked Lessons without changing their lock state or the progress recorded while they are open.

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

Bundled JSON files are immutable official sources. Opening Course Editor creates an immutable snapshot of the persisted course and a separate editable working copy. Every nested authoring operation changes only the working copy. Nested Save/Save as draft never touches the learner-visible course, creates a backup, or increments a version. Canonical semantic comparison decides whether the complete working copy differs from the snapshot.

Only the top-level Confirm course changes action may persist authoring work. For an existing course it first creates and verifies a complete versioned backup, then increments the separate internal course version and atomically writes and verifies the entire working copy. Cancel course changes discards the working copy without backup or version change. Failed backup or persistence preserves the original and keeps the working copy open. Official sources keep their publisher-owned version separately from local course versions.

## Storage boundary

```text
DEVICE ONLY
- learner profiles and avatar preferences
- language-scoped XP, streaks, study days and Status inputs
- learner-global Weekly XP and per-course Weekly XP breakdowns
- course-scoped Round/Lesson/Duel progress, Laurels and Review history
- local Course Model v6 Course Editor overrides
- settings
- automatic Crash Log plus separate exportable Diagnostic Log

Build 223 makes three clean-cut Lesson-semantic persistence changes: `v4_completed_topics` becomes `v4_completed_lessons`, `last_topic_<encodedCourseId>` becomes `last_lesson_<encodedCourseId>`, and each `v4_recent_rounds` JSON entry uses `lessonId` instead of `topicId`. The other `v4_` prefixes identify the established chapter-free progress namespace rather than Topic semantics and remain unchanged. Course Editor overrides/user-course storage moves from the v4/build-215 keys to the v5/build-223 keys so old-format course objects are not parsed as v5.

Build 225.02 moves Course Editor override/user-course storage to the v6/build-225 namespace. Older namespaces remain untouched and are never migrated into v6. Malformed current-namespace data is preserved and copied to the corrupt-backup key before a clear failure; incompatible course files are rejected without deleting the source.

Build 225.03 keeps that clean v6 storage boundary. At startup, the device-local bundled-course discovery index is reconciled idempotently with the current authoritative registry so newly bundled courses become visible without clearing application data. This initialization does not inspect or modify custom-course storage, learner progress or any older course schema.

Build 225.04 retains that namespace and introduces a course-level transaction without a schema migration. Confirmed existing-course changes are backed up below `Documents/QuisquisLingo/Exports/Course Backups/<courseId>` with canonical SHA-256 integrity and referenced managed audio. `custom`, `bundledOfficial`, and `externalOfficial` origins are explicit. Bundled official sources remain immutable; local variants and official update archives remain separate. No v5 compatibility or migration is reintroduced.

Learner backup schema v2 remains unchanged. Its only learner-state payload is an opaque `data` map of profile namespace suffixes to primitive/list values; it does not define Topic/Lesson fields of its own. Export/restore therefore carries the current Lesson keys without changing `schemaVersion`, `format`, or `learnerProfileId` semantics.

SERVER
- none required by the current prototype
```

## TTS

Android, iOS and macOS use the platform TTS engine through `flutter_tts`. Windows uses the System.Speech backend with same-language locale fallback. Linux uses an installed eSpeak NG/eSpeak executable and does not invoke a shell parser. Web TTS remains experimental and must be smoke-tested separately.

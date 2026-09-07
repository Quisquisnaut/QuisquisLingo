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
|    +-- Flag Background (initially Off) / IDDQD (initially Off)
|
+-- learner-global Weekly XP and weekly-goal celebration state
|
+-- avatar appearance (shared across languages)
+-- Theme (Default / Light / Dark, initially Default; shared across Courses)
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

The first Lesson is genuinely unlocked. Learners may open its Rounds freely. IDDQD Mode grants access to genuinely locked Lessons without changing their lock state or the progress recorded while they are open. The learner control explains Off as `Normal progression locks apply.` and On as `Locked content can be opened. Normal progression status is preserved.` A locked Lesson accessed this way keeps its lock marker and shows `Accessible with IDDQD`; through the existing Lesson gate, its published GuideBook, Rounds and eligible Duel become actionable while unpublished GuideBooks and ineligible Duels keep their own availability rules.

Phase 227.01 establishes the [Learner Panel controls baseline](227_01_VALIDATION.md). Phase 227.02 adds [Tinted and Inspired](227_02_VALIDATION.md) through one deterministic flag-color pipeline. Tinted is a restrained uniform adapted hue. Inspired is a stronger static three-stop field that uses up to three meaningfully separated representative colors; single-useful-color inputs receive related tonal variation without unrelated hues. World Flag SVG colors, portable custom raster pixels and existing built-in flag colors share neutral, extreme-lightness, saturation and theme adaptation. Inspired retains the revision-0 `soft_inspired` persisted value. An unreadable preferred source falls back to the existing built-in source, then to a safe neutral learner-page palette. Small / Off / Extended rendering remains unchanged. Phase 227.03 adds [IDDQD state communication](227_03_VALIDATION.md) at the existing control and genuine Lesson gate without changing access, persistence or progression logic.

Flag Background keeps the clean-cut opaque learner ID × immutable Course ID storage established by 227.01 and remains initialized Off; old shared values are left untouched and unread. Theme remains learner-scoped with Default following live system brightness. Changing these visual controls or toggling IDDQD does not award XP, complete content or alter genuine unlock state; actual study while IDDQD is On still records normal progress and rewards. No Flag Background value enters Course JSON or course checksums.

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

Bundled and external official courses open read-only inspection. Opening a custom Course Editor creates an immutable snapshot of the persisted course and a separate editable working copy. Every nested authoring operation changes only the working copy. Nested Save/Save as draft never touches the learner-visible course, creates a backup, or increments a version. Canonical semantic comparison decides whether the complete working copy differs from the snapshot.

Only the top-level Confirm course changes action may persist authoring work. For an existing course it first creates and verifies a complete versioned backup, then increments the separate internal course version and atomically writes and verifies the entire working copy. Cancel course changes discards the working copy without backup or version change. Failed backup or persistence preserves the original and keeps the working copy open. Official sources use only their publisher-owned version. Explicitly licensed forks are independent custom courses with permanent original authorship/provenance and a separate fork creator.

## Storage boundary

```text
DEVICE ONLY
- learner profiles and avatar preferences
- language-scoped XP, streaks, study days and Status inputs
- learner-global Weekly XP and per-course Weekly XP breakdowns
- course-scoped Round/Lesson/Duel progress, Laurels and Review history
- local Course Model v6 custom courses and external official sources
- settings
- automatic Crash Log plus separate exportable Diagnostic Log

Build 223 makes three clean-cut Lesson-semantic persistence changes: `v4_completed_topics` becomes `v4_completed_lessons`, `last_topic_<encodedCourseId>` becomes `last_lesson_<encodedCourseId>`, and each `v4_recent_rounds` JSON entry uses `lessonId` instead of `topicId`. The other `v4_` prefixes identify the established chapter-free progress namespace rather than Topic semantics and remain unchanged. Course Editor overrides/user-course storage moves from the v4/build-215 keys to the v5/build-223 keys so old-format course objects are not parsed as v5.

Build 225.02 moves Course Editor override/user-course storage to the v6/build-225 namespace. Older namespaces remain untouched and are never migrated into v6. Malformed current-namespace data is preserved and copied to the corrupt-backup key before a clear failure; incompatible course files are rejected without deleting the source.

Build 225.03 keeps that clean v6 storage boundary. At startup, the device-local bundled-course discovery index is reconciled idempotently with the current authoritative registry so newly bundled courses become visible without clearing application data. This initialization does not inspect or modify custom-course storage, learner progress or any older course schema.

Build 225.04 retains that namespace and introduces a course-level transaction without a schema migration. Confirmed existing-course changes are backed up below `Documents/QuisquisLingo/Exports/Course Backups/<courseId>` with canonical SHA-256 integrity and referenced managed audio. `custom`, `bundledOfficial`, and `externalOfficial` origins are explicit. Bundled official sources remain immutable; local variants and official update archives remain separate. No v5 compatibility or migration is reintroduced.

Build 226.01 removes active official local overrides without deleting or converting stored remnants. Bundled loading uses the source asset; external loading and updates use the source record only. Obsolete local-variant backup manifests are excluded from official history. Custom storage, transactions and backups remain compatible; licensed forks have independent IDs/history and never follow official updates. Optional derivative policy and immutable fork provenance stay within Course Model v6.

Learner backup schema v2 remains unchanged. Its only learner-state payload is an opaque `data` map of profile namespace suffixes to primitive/list values; it does not define Topic/Lesson fields of its own. Export/restore therefore carries the current Lesson keys without changing `schemaVersion`, `format`, or `learnerProfileId` semantics.

SERVER
- none required by the current prototype
```

## TTS

Android, iOS and macOS use the platform TTS engine through `flutter_tts`. Windows uses the System.Speech backend with same-language locale fallback. Linux uses an installed eSpeak NG/eSpeak executable and does not invoke a shell parser. Web TTS remains experimental and must be smoke-tested separately.

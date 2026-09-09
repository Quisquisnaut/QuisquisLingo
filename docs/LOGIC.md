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
|    +-- Flag Background (initially Off) / IDDQD (Off / On / View Only; initially Off)
|
+-- learner-global Weekly XP and weekly-goal celebration state
|
+-- avatar appearance (shared across languages)
+-- Theme (Light / Dark / System / Day/Night, initially System; shared across Courses)
+-- Audio Settings (shared across Courses)
     +-- Enable Audio Exercises (initially Off)
     +-- Text-to-speech (initially Off)
     +-- TTS voice (initially System)
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

The first Lesson is genuinely unlocked. Learners may open its Rounds freely. IDDQD Off applies normal locks. On grants access to genuinely locked Lessons and records actual study normally. View Only grants the same access and immediate answer feedback but exits Round completion before `LearningCompletionService` and suppresses the Duel victory write, so no learner progress, XP, Weekly XP, activity, streak, Laurel, Review, unlock or Duel state is recorded. The selected mode itself persists per learner × Course. Locked Lessons keep their real lock marker and show `Accessible with IDDQD` for On or `Preview with IDDQD` for View Only; the shared Lesson gate exposes published GuideBooks, Rounds and eligible Duels without overriding their own availability rules. The compact IDDQD control exposes the exact selected-mode explanation through its tooltip and accessibility label rather than permanent text beneath the buttons.

The QQL 229 Lesson display preference is independent of these access rules and persists per opaque learner ID × immutable Course ID. Expanded shows every accessible Lesson and collapses normally inaccessible Lessons. Collapse completed hides the paths of completed Lessons while showing every incomplete accessible Lesson. Focused shows only the current accessible Lesson path; explicitly opening another accessible Lesson makes it current and collapses the previous path. If IDDQD access to the current Lesson is removed, Focused returns to the nearest genuinely accessible Lesson. Section headers and the established Section selector remain navigation-only and never become collapsible. Changing display mode writes no progress, XP, activity, Review, Duel or Course data.

Course Selector Hide uses a separate per opaque learner ID × immutable Course ID preference. It removes a non-active Course only from that learner's normal selector and is immediately reversible through `Hidden courses (n)`. It never uninstalls a Course or changes Course JSON, identity, metadata, authoring state, progress, XP, streak or history. The active Course's Hide action is disabled.

Phase 227.01 establishes the [Learner Panel controls baseline](227_01_VALIDATION.md). Phase 227.02 adds [Tinted and Inspired](227_02_VALIDATION.md) through one deterministic flag-color pipeline. Tinted is a restrained uniform adapted hue. Inspired is a stronger static three-stop field that uses up to three meaningfully separated representative colors; single-useful-color inputs receive related tonal variation without unrelated hues. World Flag SVG colors, portable custom raster pixels and existing built-in flag colors share neutral, extreme-lightness, saturation and theme adaptation. Inspired retains the revision-0 `soft_inspired` persisted value. An unreadable preferred source falls back to the existing built-in source, then to a safe neutral learner-page palette. Small / Off / Extended rendering remains unchanged. Phase 227.03 adds [IDDQD state communication](227_03_VALIDATION.md) for the pre-existing Off/On modes. Phase 227.04 adds functional [View Only and final Theme behavior](227_04_VALIDATION.md) and closes QQL 227.

Flag Background keeps the clean-cut opaque learner ID × immutable Course ID storage established by 227.01 and remains initialized Off; old shared values are left untouched and unread. Theme remains learner-scoped: Light and Dark are fixed, System preserves the former `default` storage and follows live platform brightness, and Day/Night stores `day_night` while resolving local wall-clock time as Light from 07:00 inclusive to 19:00 exclusive and Dark otherwise. A single timer targets the next boundary and is cancelled outside Day/Night; resume re-evaluates local time. Changing these controls or the selected IDDQD preference does not itself award XP, complete content or alter genuine unlock state. No learner control enters Course JSON or course checksums.

## Review priority

For each learner + Course ID, keep at most 50 distinct recently completed Rounds. Repeating a Round replaces its latest-attempt record.

```text
sort key 1: latestErrors descending
sort key 2: completedAt descending
```

A Review attempt can earn a permanent Laurel crown exactly like a normal course attempt.

## Streak freeze rule

A language streak advances only on a new day when that language is studied. A day spent studying another language freezes it. A completed day with no learning activity in any language breaks active language streaks.

Profile > Statistics is a read-only projection of this same learner activity. Total Study Days counts distinct local calendar dates across all languages. Per-language Study Days, Current Streak and Max Streak use the existing study-day sets and freeze rule. Locale/name variants are canonicalized for display and aggregation (for example `en-US`, `en_GB` and English become `en`) without creating a second activity history.

## Learner audio availability

Learner Round and Duel queues first read the active profile's positive `audio_exercises_enabled` value. When it is Off, every recorded, TTS and hybrid exercise is excluded without initializing learner playback infrastructure. When it is On, the queues resolve actual source availability; the separate per-learner Text-to-speech setting controls only the TTS branch and also initializes Off. A valid recorded source remains usable while TTS is Off. A Round may prepare its first eligible listening exercise behind `Before you start`, but automatic playback is suppressed until Continue makes that exercise the active learner UI state; an ordinary Round without an introduction keeps its established post-frame playback. Authoring Preview bypasses learner Audio Settings and persistent audio diagnostics and preserves its established no-write boundary. Normal learner playback writes bounded privacy-safe correlated lifecycles to the existing Diagnostic and Crash Logs, including preparation/activation timing and explicit not-active suppression.

## Course authoring boundary

All origins use the same capability-driven Course Editor hierarchy. Bundled/external official courses and outsider-owned custom courses open read-only; an individual Owner and every member of an owning Team receive full custom editing. Opening an editable custom Course Editor creates an immutable snapshot of the persisted course and a separate editable working copy. Every nested authoring operation changes only the working copy. Nested Save/Save as draft never touches the learner-visible course, creates a backup, or increments a version. Canonical semantic comparison decides whether the complete working copy differs from the snapshot.

Creator, Owner, credits, license and provenance are separate. `creatorProfileId` is immutable creation provenance. `ownership` names one stable profile ID or Team ID and is the only authoring ownership boundary. Author, Contributor, Illustrator, Team Leader and other credit strings are descriptive and never grant authorization. The Owner or any owning-Team member can Edit and Duplicate regardless of license; Team Lead status controls Team membership administration only. An outsider cannot mutate or Duplicate the original and may Fork only when derivative works are allowed. Duplicate preserves individual/Team ownership; Fork receives explicit local ownership, fresh IDs and source lineage/provenance.

Only the top-level Confirm course changes action may persist authoring work. For an existing course it first creates and verifies a complete versioned backup, then increments the separate internal course version and atomically writes and verifies the entire working copy. Cancel course changes discards the working copy without backup or version change. Failed backup or persistence preserves the original and keeps the working copy open. Official sources use only their publisher-owned version. Explicitly licensed forks are independent custom courses with permanent original authorship/provenance and a separate fork creator.

## Storage boundary

```text
DEVICE ONLY
- learner profiles and avatar preferences
- language-scoped XP, streaks, study days and Status inputs
- learner-global Weekly XP and per-course Weekly XP breakdowns
- course-scoped Round/Lesson/Duel progress, Laurels and Review history
- local Course Model v7 custom courses and external official sources
- offline authoring Teams keyed by stable Team and profile IDs, with one or more Leads
- settings, including per-profile Enable Audio Exercises, Text-to-speech and TTS voice
- automatic Crash Log plus separate exportable Diagnostic Log under `Documents/QuisquisLingo/Logs`

Build 223 makes three clean-cut Lesson-semantic persistence changes: `v4_completed_topics` becomes `v4_completed_lessons`, `last_topic_<encodedCourseId>` becomes `last_lesson_<encodedCourseId>`, and each `v4_recent_rounds` JSON entry uses `lessonId` instead of `topicId`. The other `v4_` prefixes identify the established chapter-free progress namespace rather than Topic semantics and remain unchanged. Course Editor overrides/user-course storage moves from the v4/build-215 keys to the v5/build-223 keys so old-format course objects are not parsed as v5.

Build 225.02 moves Course Editor override/user-course storage to the v6/build-225 namespace. Older namespaces remain untouched and are never migrated into v6. Malformed current-namespace data is preserved and copied to the corrupt-backup key before a clear failure; incompatible course files are rejected without deleting the source.

Build 225.03 keeps that clean v6 storage boundary. At startup, the device-local bundled-course discovery index is reconciled idempotently with the current authoritative registry so newly bundled courses become visible without clearing application data. This initialization does not inspect or modify custom-course storage, learner progress or any older course schema.

Build 225.04 retains that namespace and introduces a course-level transaction without a schema migration. Confirmed existing-course changes are backed up below `Documents/QuisquisLingo/Exports/Course Backups/<courseId>` with canonical SHA-256 integrity and referenced managed audio. `custom`, `bundledOfficial`, and `externalOfficial` origins are explicit. Bundled official sources remain immutable; local variants and official update archives remain separate. No v5 compatibility or migration is reintroduced.

Build 226.01 removes active official local overrides without deleting or converting stored remnants. Bundled loading uses the source asset; external loading and updates use the source record only. Obsolete local-variant backup manifests are excluded from official history. Custom storage, transactions and backups remain compatible; licensed forks have independent IDs/history and never follow official updates. Optional derivative policy and immutable fork provenance stay within Course Model v6.

Learner backup schema v2 remains unchanged. Its only learner-state payload is an opaque `data` map of profile namespace suffixes to primitive/list values; it does not define Topic/Lesson fields of its own. Export/restore therefore carries the current Lesson keys without changing `schemaVersion`, `format`, or `learnerProfileId` semantics.

Build 228 makes a clean per-profile Audio Settings cut. Below the active opaque learner prefix, `audio_exercises_enabled` and `tts_enabled` default Off and `tts_voice_preference` defaults System. Previous device-level `tts_enabled` / `tts_voice_preference`, device-level `skip_tts_exercises`, and per-profile `skip_all_audio_exercises` values are left untouched and unread; none are migrated or converted. Statistics uses only existing profile-prefixed `study_days_<language>` and `study_days_all` records. Learner backup schema v2 already carries opaque profile-prefixed values, so no backup or Course Model schema change is required.

QQL 229 revision 1 moves custom authoring storage to the clean v7/build-2291 namespace. Older custom data remains untouched and unread; no ownership migration or name-based fallback runs. Custom Course JSON requires stable Creator and individual/Team Owner identities. Team membership and Lead state live separately in the verified `quisquislingo_authoring_teams_v1_2291` registry and never enter Course JSON. Course Selector Hide and Lesson expansion mode retain their revision-0 per-learner × Course keys unchanged.

SERVER
- none required by the current prototype
```

## TTS

Android, iOS and macOS use the platform TTS engine through `flutter_tts`. Windows uses the System.Speech backend with same-language locale fallback. Linux uses an installed eSpeak NG/eSpeak executable and does not invoke a shell parser. Web TTS remains experimental and must be smoke-tested separately.

Test Voice keeps the two inputs separate: its initially empty dialog supplies only the exact user-entered text, while the selected Course's existing TTS metadata supplies the voice language. Empty and whitespace-only input never reaches the backend; UI locale and text contents do not alter voice resolution.

The Course Entry Animation is requested only by the two explicit bundled/custom Course switch paths after a destination learner Course is resolved. A valid `worldFlagId`, `flagImageBase64`, or supported `flagCode` explicitly stored on that destination Course remains authoritative in the existing resolution order. When all three JSON fields are absent, revision 1 uses the same `CourseService.codeForCourse` built-in flag fallback already used by other Course flag surfaces. Invalid declared flag data does not fall back. With animations enabled and reduced motion absent, the resolved flag covers the newly selected Learner Panel during a restrained two-second fade. Course selection is queued until the Course Selector route has closed, and the overlay controller is created only after selection persistence and the destination learner reload complete. Normal startup, same-Course navigation, disabled animations, reduced motion, and an unsupported fallback install no transition overlay. Course-selection persistence and Flag Background remain independent.

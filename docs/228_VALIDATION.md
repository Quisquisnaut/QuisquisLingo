# QQL 228 closure and validation

## Release boundary

QQL 228 is released as Version `2.0.28`, Phase/build `228`, revision `0`, and pubspec `2.0.28+228`. The 30-day Alpha lifetime ends at exactly `2026-10-08 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`), the Course Audit Registry remains at 102 rules, and bundled Course JSON and checksums are unchanged.

The implementation starts from the completed QQL 227 checkout and contains only the requested Settings, Profile, Statistics, Debug/logging, and learner runtime Audio Settings work. QQL 227 remains closed.

## 228.01 Settings and Profile reorganization

Settings now presents Profile, App Info, Audio Settings, Do Not Disturb, Debug, Version and Build, and Update in that order. Course Manager is no longer a Settings row and remains available from the Course Selector after the existing Version and Build activation gesture. User Data moved from Settings into Profile after Statistics and before the Log out section. Existing Avatar, Learner profiles, and Gamification entries retain their order and behavior.

The Flag Game button keeps its established action. Its tooltip is exactly `Tap tap... Flag Game`, and pointer hover produces a gentle centered waving animation that stops when hover ends. The former TTS Settings destination is learner-facing Audio Settings.

## 228.02 Learner Statistics

Profile links to the new Statistics page. The page shows Total Study Days and one section per studied canonical language with its flag, display name, lowercase canonical language ID, Study Days, Current Streak, and Max Streak.

Statistics derive from the active opaque learner profile's existing study-day records. Regional tags and known language names are merged into their authoritative canonical language ID. Total Study Days are the distinct local calendar days across languages. Current and maximum streaks use the existing local-day and streak-freeze semantics. No new statistics history, maximum-streak preference, migration, or Course Model field is introduced.

## 228.03 Debugging Logs

The Debug page owns the existing Crash Log and Diagnostic Logs tools. Both now resolve under:

```text
Documents/QuisquisLingo/Logs
```

The crash log is `quisquislingo_crash.log` in that directory. Previous crash-log locations are left untouched and unread; there is no migration or cleanup. Existing diagnostic-log export behavior is preserved. The Debug page explains that Crash Log is for startup/runtime crashes or unexpected closes and should be provided when available. It identifies Diagnostic Log as the reproduction-oriented tool for non-crashing audio and runtime anomalies, recommends prompt export, and presents clearing only as an optional isolation step while warning users to export intermittent evidence first. Its privacy guidance accurately applies to learner audio diagnostics.

## 228.04 Learner runtime Audio Settings

Audio Settings contains exactly these controls in order: Enable Audio Exercises, Text-to-speech, and the TTS voice selector including the existing Test Voice action. Enable Audio Exercises and Text-to-speech initialize Off; TTS voice initializes System. All three settings are scoped to the active opaque learner across Courses.

While Enable Audio Exercises is Off, learner Round and Duel candidates that require TTS, recorded MP3, or hybrid audio are filtered before audio-source resolution or player/controller initialization. While On, recorded sources are verified before playback initialization and TTS availability follows the separate Text-to-speech switch; unavailable audio exercises are excluded. Duel eligibility continues to use the actual filtered Lesson-local pool and the established 25-exercise threshold. Editor Preview explicitly bypasses learner Audio Settings and produces no learner-audio diagnostic writes.

Round preparation no longer starts automatic learner audio behind `Before you start`. The next exercise and its source eligibility may be prepared early, but TTS or recorded playback is suppressed until Continue makes that stable target exercise active. Rounds without an introduction retain immediate post-frame activation; Duel audio and Editor Preview are unchanged.

TTS and recorded playback emit bounded, correlated lifecycles to the existing Diagnostic Log and Crash Log. Round activation diagnostics add the learner UI state (`before_you_start` or `exercise_active`), stable target exercise ID, exercise type, prepared/active state, playback trigger, and explicit not-active suppression. Records contain technical status only, reserve a disposal event, and redact path-like values. They do not include spoken text, answers, Course content, raw exceptions, stack traces, or full personal paths.

## Clean-machine validation corrections

Test Voice no longer chooses a built-in language sample. Its dialog owns an initially empty editable field with the UI-only hint `Enter text to test`; the Play action remains disabled for empty or whitespace-only input. Nonblank input is passed unchanged to the existing TTS service together with the selected Course's `ttsLanguage`, `learningLanguage`, and `targetLanguage`. The UI locale and text contents do not participate in voice resolution, and the existing missing-compatible-voice result remains specific.

The restored Course Entry Animation is a current-architecture overlay rather than the former pre-215 navigation screen. Only the explicit bundled/custom Course selection handlers request it, after resolving a different destination Course. The decision reads the existing Animations preference and Flutter reduced-motion flag, then resolves only the destination's explicit Course JSON flag in the established `worldFlagId`, portable `flagImageBase64`, and supported `flagCode` order. It never derives a flag from language, locale, title, or `CourseService.codeForCourse`. A valid source covers the newly selected Learner Panel and holds/fades out over 680 ms. A missing or invalid source, disabled Animations, reduced motion, normal startup, and same-Course navigation install no overlay and switch immediately. Course selection persistence, Flag Background, Course Model v6, and Course JSON schema remain unchanged.

## Persistence and compatibility

The clean-cut learner-scoped preferences are:

```text
<opaque learner prefix>audio_exercises_enabled
<opaque learner prefix>tts_enabled
<opaque learner prefix>tts_voice_preference
```

Previous device-level `tts_enabled` / `tts_voice_preference`, device-level `skip_tts_exercises`, and per-profile negative `skip_all_audio_exercises` values are left untouched and unread. There is no migration or conversion. Statistics reuse existing profile-scoped `study_days_*` records. Log files move through a clean path cut without reading or moving old files. Course Model v6, Course JSON, learner progress, XP, Review, Duel, Theme, Flag Background, IDDQD, and update behavior are otherwise unchanged.

## Automated coverage

New release tests cover:

- exact Settings and Profile ordering, removed rows, routes, Flag Game tooltip, and hover animation;
- canonical per-language statistics, distinct total days, current/max streak derivation, profile isolation, and rendered page fields;
- the shared Logs directory, Debug destinations, Crash/Diagnostic reporting guidance, optional-clear warning, and audio privacy explanation;
- exact Audio Settings controls and Test Voice retention; its empty user-text dialog, blank suppression, exact-text forwarding, course-language metadata, UI-locale independence and missing-voice result; new learner defaults; per-learner persistence/isolation; old-key non-use; pre-controller TTS/recorded filtering; enabled eligibility; missing-source handling; Preview bypass; `Before you start` TTS/recorded suppression and post-Continue activation; ordinary Round timing; bounded/redacted diagnostic ordering/content; and TTS failure privacy;
- Course Entry Animation decision and rendering for exact destination JSON flags, preference/reduced-motion suppression, invalid/missing flags, same-Course selection, normal persisted startup, 680 ms fade completion, Home switch wiring, selected-Course persistence, Flag Background isolation, and unchanged Course Model serialization.

Existing metadata, Alpha lifecycle, Course Audit, Home/Course Selector, Round XP, Duel eligibility, Duel XP, startup logging, TTS language, recorded-audio, authoring Preview, and production-course regressions were updated or rerun where their established boundary changed.

## Validation results

| Check | Result |
| --- | --- |
| Activation timing, Audio Settings, diagnostics and Debug guidance focus | 17 passed, 0 failed |
| QQL 228-focused and neighboring regression set | 119 passed, 0 failed in 1:10 |
| Complete Flutter suite before the clean-machine corrections | 1,233 passed, 0 failed in 10:32 |
| Clean-machine correction focus | 12 passed, 0 failed |
| Corrections plus neighboring Audio Settings and TTS-language regressions | 37 passed, 0 failed |
| Full Flutter analyzer before the clean-machine corrections | 0 errors; 71 inherited diagnostics (70 info, 1 warning) |
| Diagnostics in changed files | 1 inherited info-level brace lint on an unchanged `SettingsService` line; 0 new findings |
| Focused static analysis for the two corrections | 6 modified production/test files, no issues |
| Bundled Course validation | 9 Course Model v6 Courses valid |
| Image asset validation | 112 assets, 0 issues |
| `git diff --check` | Passed |

The analyzer warning is the pre-existing unused `_tapAndSettle` helper in `test/guidebook_sentence_generator_test.dart`. The remaining analyzer findings are inherited info-level lint debt. No analyzer error or new QQL 228 diagnostic remains.

## Remaining validation boundary

Automated tests use injected/fake playback seams. The earlier standalone 228 package launched on a clean Azure Windows VM and established installed/missing voice behavior, leading to these two corrections. A rebuilt package still needs the updated Test Voice field and Course Entry Animation checked on the target machine alongside the bundled/portable recorded-audio and Debug log actions documented in `WINDOWS_RELEASE_TEST.md`. No package, commit, or push is part of this implementation.

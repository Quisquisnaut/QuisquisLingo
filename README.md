# QuisquisLingo App

**Current source version: 2.0.20+220 · Course Model v4 (`formatVersion: 4`).**


**QuisquisLingo 2.0.20 Alpha**

Current project version: 2.0.20

Build 220 makes Profile the central learner-personalization hub for the active avatar and name, Avatar customization, local learner profiles and Gamification. The fixed learner bottom area now contains only Profile, Review and Course Info; Buy a coffee remains available inside Course Info. Local logout clears only the active-profile selection and returns to the stored learner selection/create flow without deleting any learner data. The build-219 Round path and all scoring, Review, Duel and course behavior remain unchanged. The official repository is `Quisquisnaut/QuisquisLingo`.


A Flutter prototype for an offline-first language-learning app.

## Baseline 200

Version **2.0.0+200** remains the historical Course Model v3 baseline. Current development starts from this Course Model v4 source tree rather than an older archive. Repository-level agent instructions are in `AGENTS.md`.

## Project authorship

Project and code design: **Quisquisnaut (Quisquis on Discord)**.
Code generation and software development assistance: ChatGPT.

The MPL-2.0 covers the QuisquisLingo software source. Courses, the Image Bank and other content/assets retain their separately stated licenses or rights.


## Alpha lifecycle

Version 2.0.20 is a time-limited alpha and expires on **2026-10-01**. Near expiry it displays reminders. After expiry, learner exercises and Review are blocked until a newer alpha is installed. QuisquisLingo does not delete learner progress, locally installed courses, local course edits or settings when an alpha expires; Course Editor remains available for recovery/export. The check intentionally trusts the device clock and is not DRM. Future stable builds can disable alpha expiry.

## Core logic

Course
- Topic (shown to learners as Lesson)
  - GuideBook
  - Round
    - Content / Exercise
  - Duel

Each Topic has its own GuideBook, ordered Rounds and Topic-scoped Duel in Course Model v4. The first Content item of a Topic’s first Round may present a short essential introduction drawn from that GuideBook.

The learner page shows one current Lesson, opens the complete Lesson picker from the Lesson selector, and opens its GuideBook, Rounds and Duel directly.

The next Lesson unlocks when the current Topic is completed or its Duel is won. A Duel remains unavailable when its actual eligible pool has fewer than the required 25 exercises; Round count is not used to decide availability.

All learner data remains on-device.

## Included in this prototype

- Course-language selector
- Unified Course → Lesson → Round learner page
- Lesson selector with complete Lesson picker
- Topic-scoped Duel skip mechanism with actual-pool availability
- Round and exercise model
- Local progress persistence
- Local streak
- Local daily quest
- XP
- Local TTS service with generated-file caching
- Sample Italian course data
- No account
- Local offline leaderboard for the previous completed week, based on each participating learner’s XP across all courses
- No server dependency

## Run

If Flutter is installed:

```bash
flutter pub get
flutter run
```

If you create native platform folders separately, you can run:

```bash
flutter create .
flutter pub get
flutter run
```

The official Flutter CLI can bootstrap any missing Android/iOS host files.

## TTS

`TtsCacheService` hashes language + voice + rate + text to derive a cache filename.
On iOS and Android it asks the native TTS engine to synthesize to a local file, then reuses that file.

This is an architectural prototype. Native TTS file-format behavior can differ by platform and voice engine, so playback/caching should be tested on actual iOS and Android devices before production.


## Linux preview mode

On Linux the complete learner interface works. TTS uses a locally installed `espeak-ng` or `espeak` backend when available, and can be disabled in Settings. The desktop layout remains constrained to a phone-like width to make low-memory Linux preview/testing practical.

### Run on Linux

From the project folder:

```bash
flutter create .
flutter pub get
flutter run -d linux
```

If Flutter reports missing Linux desktop build packages, install the packages it names through your Debian/antiX package manager.


## TTS setting

Version 0.1.2 adds a persistent user setting:

- Text-to-speech: ON/OFF
- Default: ON
- Stored only on the device
- When OFF, the app does not request TTS generation
- Existing cached audio files are left untouched


## Error handling

Version 0.1.3 adds application-level error codes and a local diagnostic log.

Examples:
- COURSE-001: missing course file
- COURSE-002: invalid course data
- TTS-003: TTS generation failed
- APP-001: unexpected internal error

User-facing dialogs show a short message plus the error code.
Technical details remain in a local log file and are never uploaded automatically.


## Italian sample course

Version 0.3.0 includes a larger Italian course sample with:
- 3 chapters
- 11 topics
- 33 rounds
- 165 exercises
- 5 exercise types
- chapter Language Duels


## QuisquisLingo 0.3.0 interface

- Uses the supplied 250 px olive-tree image unchanged as a local asset.
- Overlays UK, German, Italian and Spanish flags at runtime; the source image itself is not edited.
- No accounts or sign-up flow. Progress remains local.
- Prominent local learning streak.
- Each chapter has a visible branching topic tree.
- All topics and rounds inside an unlocked chapter can be opened in any order.
- The next chapter remains gated by the normal completion rule, but winning the current chapter's Language Duel unlocks it immediately.
- The Language Duel gate is shown at the bottom of the chapter tree.
- The visual palette is cream and olive green and is intended to remain light enough for low-memory antiX Linux preview use.


## Reporting problems

During any exercise, tap the flag in the top-right corner and choose **Course error** or **App bug**. QuisquisLingo copies a ready-to-paste report containing the exact course, Topic, Round and exercise context. Nothing is uploaded automatically. See `docs/REPORTING.md`.

## Cross-platform text-to-speech

TTS can be enabled or disabled at any time in **Settings > TTS Settings > Text-to-speech**.

- Windows: native `System.Speech` through a dedicated backend, avoiding the current `flutter_tts` Windows platform-thread issue.
- Android, iOS/iPadOS, macOS and Web: platform/browser TTS through `flutter_tts`.
- Linux: eSpeak NG, with eSpeak fallback.

See `docs/TTS_ALL_PLATFORMS.md` for platform-specific setup and run instructions.

## Listening comprehension

Rounds can include `listening_comprehension` exercises. The learner hears a short sentence or mini-dialogue, may replay it, and answers a comprehension question with randomized choices. If TTS is disabled or unavailable, audio exercises should be skipped or replaced by course logic in a production course.


## Authoring safety

The local Course Editor includes a Course Audit that reports structural errors, warnings and suggestions before course content is used. See `docs/COURSE_EDITOR.md`.

- Security/robustness notes: `docs/SECURITY_AND_ROBUSTNESS.md`


## QuisquisLingo 0.5.1

Version 0.5.1 consolidates the authoring, review and visual changes developed during the 0.4.x prototype cycle.

Highlights:
- richer startup animation with Italian, German, Spanish, Portuguese, Dutch, Welsh, UK English and Finnish flags
- language-specific transition when entering a course
- more visible flag-inspired Chapter and Topic backgrounds
- first-open Topic Guidebook availability notice per learner
- Finnish, Welsh, Dutch and Portuguese empty course shells that can be authored in Course Editor
- per-language reset for each learner
- Windows System.Speech TTS backend and Female/Male/System voice preference
- optional skipping of every TTS exercise, with a non-laurel zero-error completion mark
- permanent laurel crowns after any full zero-error attempt, including Review, with victory sound when first earned
- Review keeps 50 distinct recent rounds and prioritizes the latest attempts with the most errors
- Course Editor supports empty courses, Topic Guidebooks and create/delete/reorder at Chapter, Topic, Round and Exercise level
- exercise type is immutable after creation
- Word Blocks use 0 to 2 same-language distractors; early Topic rounds should normally use fewer distractors than later rounds
- Image Credits are alphabetically indexed, with the olive and Status avatar notes on the main Image Credits page
- MPL-2.0 software license, separate human-authored course-content rights, and third-party notices

See `docs/COURSE_EDITOR.md`, `docs/TTS_ALL_PLATFORMS.md`, `docs/AUDIO_PACKS.md`, `docs/LICENSING.md` and `docs/SECURITY_AND_ROBUSTNESS.md`.

## Image Bank packages (0.6.1)

Large vocabulary image collections can be distributed separately from the app. Place exactly one Image Bank ZIP in `Documents/QuisquisLingo/Imports/Images`, then open **Settings > Image Bank** or **Course Editor > Image Bank** and choose **Import Image Bank ZIP**. The package must contain `image_bank_manifest.json` plus its referenced image assets. This allows new banks to be installed without recompiling QuisquisLingo.

The editor now has a dedicated **Course Editor Help** button. General Info no longer carries the editor-specific operational instructions.

The **Image Word** exercise displays an image and asks the learner to build the corresponding target-language word from letter or syllable blocks.


## v0.6.3
- Historical Duel variants existed in earlier prototypes. The current standard is 25 questions and 4 lives, with no score and no pass threshold. The learner wins by completing all 25 questions before losing all four lives.
- Audio Match: no distractors; target audio may match target-language text or translated text.
- Added Word Match: exactly three source-to-target translation pairs.
- Added Super Match: exactly three target-language relationship pairs such as synonyms or opposites.
- Sample rounds regenerated at 13 exercises with examples of the new match types.

## Platform runners

The shared QuisquisLingo code is primarily validated for Android, Windows and Linux. iOS/macOS use Flutter-compatible code paths but require macOS/Xcode for builds. Web remains an experimental target because local authoring/import features rely on native file APIs and must be disabled or adapted before a production web build. If a source archive does not already contain a runner folder for the platform you are building on, run the included `tools/prepare_flutter_platforms.ps1` (Windows PowerShell) or `tools/prepare_flutter_platforms.sh` (Linux/macOS shell) once from the project root with Flutter installed. The script asks Flutter to generate the standard Android, Windows, Linux and Web runner folders without creating a separate application project.

See `docs/PLATFORM_COMPATIBILITY.md` for target-specific validation and macOS build guidance.

Recommended validation sequence after dependencies are available:

```text
flutter doctor
flutter pub get
flutter analyze
flutter test
```

Then use `flutter run -d <device>` for development or the appropriate `flutter build ...` command for a release build.



## Updates

Settings shows the installed **Current version** immediately before **Update**. The Update subpage uses the official public repository `https://github.com/Quisquisnaut/QuisquisLingo` and checks only its published GitHub Releases. Automatic checks at startup are optional and disabled by default. QuisquisLingo does not download or install updates itself; when a newer release is available, the page links to the official GitHub release and shows installation guidance for Windows, macOS, Linux antiX, Android, iOS and Web, explicitly marking platforms with no matching release asset as not currently available.

The update check is metadata-only and sends no learner or course data. Offline use is never blocked by GitHub availability.

## Windows Alpha diagnostic logging (0.8.1)

Both debug and standalone release Alpha builds display tester instructions at startup. QuisquisLingo creates or re-creates the **Crash Log** on every launch, appends a session snapshot, and keeps an easy-to-find Windows copy at `Documents\QuisquisLingo Logs\quisquislingo_crash.log`. Uncaught errors are recorded in all non-web build modes; detailed navigation breadcrumbs remain debug-only. The separate **Diagnostic Log** stores application troubleshooting events internally and can be exported from Settings to `Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`.

Alpha builds also keep a privacy-safe **Startup Trace** at `%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log`, with `%TEMP%\quisquislingo_startup_trace.log` as fallback. Normal lifecycle tracing is enabled by default. Set `QUISQUISLINGO_STARTUP_DIAGNOSTICS=verbose` before launch only when low-level Windows startup detail is needed. The active trace rotates at approximately 1 MiB and retains two previous generations. See [docs/LOGGING.md](docs/LOGGING.md).

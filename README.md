# QuisquisLingo App

**Current source version: 2.0.44+244001 · Build 244, Revision 1 · Course Model v11 (`formatVersion: 11`).**

**QuisquisLingo 2.0.44 Beta — QQL 244 Course Library**

Current project version: 2.0.44

See the [Build 244 change summary](docs/244_CHANGE_SUMMARY.md). Build 244 turns Available on this device into the Course Library; the plan is in [docs/COURSE_LIBRARY_244_PLAN.md](docs/COURSE_LIBRARY_244_PLAN.md). Revision 1 moves the Course Draft rule out of the Course Editor into a shared model helper, with no visible change.

**QuisquisLingo 2.0.43 Beta — QQL 243 Course Model v11**

See the [Build 243 change summary](docs/243_CHANGE_SUMMARY.md) for Course Model v11 and portable Course ZIPs. Export includes only referenced Course media, including images selected from the Admin Shared Image Library; bundled QQL assets remain supplied by the app. Import keeps those images with the Course and does not add them to the destination Shared Image Library. Revision 4 lets signed Publisher ZIPs carry recordings and images; updates archive the previous media and remove files no longer used. The Course Editor's Image Library lists shared and Course-owned images with source and use labels; Admins manage the device-wide Shared Image Library from Course Manager or Device Administration. Revision 5 overlays small `QQL`/`DEVICE`/`COURSE`/`IN USE` badges on each image and adds a badge filter and sorting to the Image Library. Revision 6 hardens Course cover and Image Bank ZIP import against memory-exhaustion files and limits Lesson icon and flag sources to 4096 pixels. Revision 7 gives image usage a single rule and reorganizes the Image Library code; images used only in presentations or GuideBooks now show `IN USE`. Revision 8 lists `IN USE` first and lets Course editors remove an image from a Course, turning exercises that need it into Drafts, and keep unused images in the Course's own image library. Revision 9 makes QQL's own image metadata read-only and adds Admin Local words and device categories. Revision 10 streams every Open from… file into a private staging folder under its real size limit and opens only ordinary files. Revision 11 checks every imported image by its content and lets Admins import up to 100 Shared Library images at once. Revision 12 lets Course editors add images and whole Image Banks to a Course's own library. Revision 13 checks every imported MP3 by its content and lets the Audio Library open several MP3s at once. Revision 14 reads Image Bank and Course ZIPs through one hardened reader, lets an Admin decide about new bank categories, and bounds imported JSON. Revision 15 reads Course ZIPs from disk a piece at a time instead of loading them into memory. Revision 16 renames the library to Shared Images, skips pictures that are already there, lets an Admin resolve Image Bank ID clashes, and records where each imported image came from. Revision 17 explains media import errors, including how to create a missing Image Bank manifest, and makes the Audio Library modes and their available MP3 tools clearer. Revision 18 adds file details on hover or long-press in the full-size image preview, including the original name, format, size, date, bank and credit when known. Revision 19 tests every import route with synthetic adversarial files and checks embedded Course JSON images at import. See the [course package plan](docs/COURSE_PACKAGE_PLAN.md).

QQL 241 completes the course file-store integration: custom and installed official courses use individual files under application support, Reset removes those files for the appropriate scopes, and Inventory reports their real paths and sizes. Tests use isolated directories and explicit save/UI completion conditions. Old course preference blobs are not migrated. Final validation passed (1,879 full-suite tests, plus 8 focused tests for the final Publisher title color); see `docs/241_VALIDATION.md`.

**QuisquisLingo 2.0.40 Beta — QQL 240 native file dialogs (Save to… / Open from…)**

QQL 240 adds the operating system's Save and Open dialogs next to the existing fixed-folder Export and Import (which are unchanged): `Save to…` for Course JSON, my data, the User Recovery Key and copies of the Crash and Diagnostic Logs, and `Open from…` for Course import, Merge From…, Image Bank ZIPs, single images, custom Lesson icons, recorded MP3s, my data and the User Recovery Key. Cloud folders such as Google Drive appear only if the device already shows them; QQL does not sign in to any cloud service. A failed or unavailable dialog explains how to use the fixed-folder route and is logged. Windows, macOS and Linux are supported; Android's picker is not wired yet (the buttons stay hidden) and iOS is not supported. See `docs/240_FILE_DIALOGS_PLAN.md`, `docs/240_VALIDATION.md` and `CHANGELOG.md`.

**QuisquisLingo 2.0.39 Beta — QQL 239 Pick the translation (Select)**

QQL 239 adds two Select-based exercise types to the Translation category: **Pick the translation (to target)** and **Pick the translation (to source)**. Each shows one generated learner instruction (`Pick the correct [language] translation`), the text to translate, an optional illustration and answer options; a tap is validated immediately and a wrong answer reveals the correct one. An optional audio button speaks target-language text only and is greyed out, never skipping the exercise, when audio or TTS is off. Existing exercise types, including the older translation choice, are unchanged.

**QuisquisLingo 2.0.38 Beta — QQL 238 Arrange & Select gap-fill authoring**

QQL 238 extends both the existing Arrange and Select primitives with inline gap-fill authoring: the fixed sentence/question is typed once, with each gap's literal answer written directly inside braces (`I {am} going {to} London.`), optional extra distractor blocks/options, and clear validation when braces are unbalanced or empty. Existing whole-sentence Arrange and single-select Select exercises are unaffected. Select also gains multiple-selection mode with optional required-selection count and set-based exact-match correctness. In both primitives, filling a gap out of order (the right answer in the wrong blank) is checked per gap and marked incorrect; Select's linked-gap options are never consumed, so the same option can be tapped again to fill a later gap that needs it. Revision 1 fixes a Revision 0 defect where a gap-based Select exercise could only ever be filled by its correct option, making an incorrect attempt impossible to submit, and improves several authoring labels/Help texts based on manual review.

**QuisquisLingo 2.0.37 Beta — QQL 237 Course Merge**

QQL 237 adds authorized custom Course Merge from Course Manager. The selected Course and `Documents/QuisquisLingo/Merges/merge.json` must have matching identity, rights, language and media information; users choose the left or right source for each included Lesson and permitted differing Course settings. The result is a third independent Course with fresh authoring IDs, preserved selected publication state, no transferred learner state, and immutable v10 merge provenance for both immediate sources. Existing v9 Courses remain readable without migration; only merged Courses use Course Model v10. See the [QQL 237 validation](docs/237_VALIDATION.md).

**QuisquisLingo 2.0.33 Alpha — QQL 233 Linux Update, Learner Status Avatar, and Course/Team Governance**

QQL 233 is delivered through three planned phases. Phase 233.1 recognizes the actual generic Linux Alpha ZIP while preserving Windows and GitHub Releases policy. Phase 233.2 adds the two-step Learner profile/avatar flow, optional normalized Discord presentation, random initial skin and hair, and the authoritative ten-level Status display whose vivid current-level color drives the avatar T-shirt. Phase 233.3 separates individual Course responsibility from optional Team assignment and Team governance, adds assignment warnings and experimental-model Help, corrects role identity/ID presentation, and keeps the Learner status bar exclusively inside the Learner Panel. The same-version QQL 233.03 correction makes Course Model v9 a clean cut with no v8 migration or fallback reads. See [QQL 233 validation](docs/233_VALIDATION.md).

The same-version QQL 233 correction keeps `2.0.33+233030` and the existing Alpha expiry unchanged. Review now waits on **Ready for Review** before the first Round; profile identity adds formal naming/Discord warnings, immutable five-digit Screen Name suffixes, admin invariants, optional Access PINs, a descriptive device name and private stable-identity Recovery Keys; and Team/Course names receive the shared safe-label policy. The application identity is the clean-cut `org.quisquislingo.app`, and the single crash log lives under the platform Documents/application-documents `QuisquisLingo/Logs` structure.

Course Model v9 separates immutable lineage (**Original Course Creator**, **Original Course Created**, and fork-specific source/creator/date metadata) from operational responsibility (**Course Maintainer**, **Assigned Team**), structured attribution, descriptive legal metadata (**License**, **Rights Holder**) and current-version metadata (**Last Version Editor**, **Modified**). **Fork** preserves lineage; **Copy as New Course** starts an independent lineage while retaining content, structured attribution, Rights Holder and applicable License. None of the provenance, attribution or legal fields grants QQL permissions. v8 data remains physically untouched and is not read, migrated or used as fallback.

QQL 232 remains the completed Review and Vocabulary reinforcement baseline. See [QQL 232 validation](docs/232_VALIDATION.md).

QQL 231 remains the completed Course Editor Search & Access baseline. See [QQL 231 validation](docs/231_VALIDATION.md), [Exercise Type inventory](docs/EXERCISE_TYPE_INVENTORY_231.md), and [Course Manager and Editor](docs/COURSE_EDITOR.md).

QQL 230 remains the completed robustness and modularity baseline. See [QQL 230 validation](docs/230_VALIDATION.md).

QQL 229 remains the completed Course Actions, ownership/Teams and Learner Panel baseline. See [QQL 229 validation](docs/229_VALIDATION.md).

QQL 228 remains the completed Settings/Profile, Statistics, Debug/logging, learner Audio Settings and Course Entry Animation baseline. See [QQL 228 validation](docs/228_VALIDATION.md).

Phase 227.04 remains the closed QQL 227 baseline. Flag Background remains **Small / Off / Extended / Tinted / Inspired** per learner and Course, initialized Off, with the compatible `soft_inspired` identity. IDDQD remains **Off / On / View Only** per learner and Course, and Theme remains **Light / Dark / System / Day/Night** per learner. See [227.01 baseline](docs/227_01_VALIDATION.md), [227.02 validation](docs/227_02_VALIDATION.md), [227.03 validation](docs/227_03_VALIDATION.md) and [227.04 validation](docs/227_04_VALIDATION.md).

Phase 226.04 adds one-time Course scaffolding (default 3 Lessons with 1 Round and 1 Draft sample Exercise per Round), reusable Sections, clear Lesson naming modes, optional GuideBook and Duel paths, World Flag selection, the upper Lessons Lock icon and passive GuideBook IDs. Revision 2 gives newly added Rounds the same single sample, removes fallback-icon style selection in favor of one theme-colored circle, adds Course Import navigation and learner-selector Editor actions, presents the last Lesson's Duel as Final Duel, and adds ordered GuideBook Insights. Creation counts do not restrict existing/imported courses or later editing. Course Model remains v6, with backward-compatible defaults and 102 Audit rules. See [226.04 validation](docs/226_04_VALIDATION.md). Templates, Napoletano and future exercise links remain deferred.

Revision-1 completion lets ready provisional Lesson/Round parents become non-Draft after their required content is saved, without a second parent-save pass. Explicit Save Draft and legacy unmarked Drafts remain protected; Course delivery and the final Course confirmation stay explicit. The optional parent eligibility marker is backward compatible within Course Model v6.

Phase 226.03 adds selectable answer expansion and independent materialization for Type the translation, deterministic similarity-ranked feedback (up to three corrections or two other correct translations), Type the missing word with an automatically derived first Unicode grapheme, and Recognize characters with Image to text and Text to image modes. Existing Input/Select models, correctness rules, Course Model v6, official read-only boundaries and no-write Preview are preserved. See [226.03 validation](docs/226_03_VALIDATION.md). Revision 1 corrects nullable/linked answer generation and terminal punctuation, requires the complete Missing Word, adds searchable Exercise Help and concrete field/audio guidance, resolves custom-course native TTS from canonical language metadata, and imports JSON from `QuisquisLingo/Imports/import.json` while preserving exports in `Exports`. These behaviors remain preserved in 226.04.

Phase 226.02 revision 4 uses actual Course titles in every learner selector entry, including selected, recent and unselected bundled/custom courses. Its historical fallback-icon choice remains readable in Course JSON, while 226.04 revision 2 renders either legacy value as the single theme-colored Lesson-number circle; explicit Lesson icons remain unchanged. Authoring mutations refresh current canonical Audit findings through the visible hierarchy; Info alone stays green, unavailable or stale Audit stays neutral, and the blue Draft badge remains independent. Lesson, Round and Exercise entries place passive Internal IDs below their actionable lines. GuideBook status exposes its own Audit border and Draft state, inherited by Lesson and Lessons indicators without affecting an otherwise clean Rounds branch; an empty Draft GuideBook is both red and blue. Shared Editor Help, the global ID toggle, Preview, guarded navigation, transactional Move/Copy and custom-course export remain available.

Build 226.01 makes bundled and external official courses locally read-only, with Info, Audit, Preview and publisher Version History inspection. An explicit publisher policy may allow a custom fork with fresh IDs, permanent original authorship/provenance and a separately recorded fork creator. Forks use the existing custom working-copy transaction, backups and version rules, and remain unchanged by later official updates. Build 225 official local overrides are ignored without migration or deletion. Ordinary custom courses, Course Model v6, progression, XP, Review, Duel and learner identity remain compatible. The official repository is `Quisquisnaut/QuisquisLingo`.


A Flutter prototype for an offline-first language-learning app.

## Baseline 200

Version **2.0.0+200** remains the historical Course Model v3 baseline. Current development starts from this Course Model v9 source tree rather than an older archive. Repository-level agent instructions are in `AGENTS.md`.

## Project authorship

Project and code design: **Quisquisnaut (Quisquis on Discord)**.
Code generation and software development assistance: ChatGPT.

The MPL-2.0 covers the QuisquisLingo software source. Courses, the Image Bank and other content/assets retain their separately stated licenses or rights.


## Beta lifecycle

Version 2.0.44, Build 244, Revision 1 is a time-limited Beta with an expiry of **2026-10-21 23:59:59 local time** (30 days from September 21, 2026, its own release date). Near expiry it displays reminders. After expiry, learner exercises and Review are blocked until a newer Beta is installed. QuisquisLingo does not delete learner progress, locally installed courses, local course edits or settings when a Beta expires; Course Editor remains available for recovery/export. The check intentionally trusts the device clock and is not DRM.

## Core logic

Course
- Lesson (shown to learners as Lesson)
  - GuideBook
  - Round
    - Content / Exercise
  - Duel

Each Lesson has its own GuideBook, ordered Rounds and Lesson-scoped Duel in Course Model v9. The first Content item of a Lesson’s first Round may present a short essential introduction drawn from that GuideBook.

The learner page shows a continuous Lesson path, opens the Section picker from the fixed Section selector when real Sections exist, and opens GuideBooks, Rounds and Duels directly. Its Lesson display control cycles through Expanded, Collapse completed and Focused; it never collapses Sections or changes progression. The Course Selector can hide non-active Courses separately for each learner without uninstalling them or changing Course or learner data.

The next Lesson unlocks when the current Lesson is completed or its Duel is won. A Duel remains unavailable when its effective eligible pool has fewer than the required 25 exercises after the learner's Audio Exercises setting and runtime audio availability are applied; Home and Duel entry use the same calculation. Round count is not used to decide availability.

All learner data stays on the device and on any backup the device itself makes. QuisquisLingo has no account, no server and no synchronization of its own, and never uploads anything.

On Android, the platform's own Auto Backup is deliberately left enabled, because without a server it is the only way a learner keeps progress through a lost or replaced phone. It covers learner profiles, progress, XP, streaks, Review history, local course edits, settings and the Access PIN verifier. Imported Image Banks, exercise images and recorded MP3s are excluded from cloud backup only because Android's 25 MB backup quota is smaller than a single Image Bank import, and an app that exceeds the quota has its backup silently switched off altogether; that media is re-importable from the user's own files, while progress is not. A direct phone-to-phone transfer has no such quota and still carries the media. Whether Auto Backup runs at all remains an Android setting the device owner controls. See `docs/SECURITY_AND_ROBUSTNESS.md`.

## Included in this prototype

- Course-language selector
- Unified Course → Lesson → Round learner page
- Section selector with consecutive-block navigation
- Lesson-scoped Duel skip mechanism with actual-pool availability
- Round and exercise model
- Local progress persistence
- Local streak
- Local daily quest
- XP
- Local TTS service with generated-file caching
- Ten bundled sample courses, including Korean from English and Neapolitan from Italian
- Local authoring Teams with stable profile-ID membership and one or more Team Leaders
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

During any exercise, tap the flag in the top-right corner and choose **Course error** or **App bug**. QuisquisLingo copies a ready-to-paste report containing the exact course, Lesson, Round and exercise context. Nothing is uploaded automatically. See `docs/REPORTING.md`.

## Cross-platform text-to-speech

TTS can be enabled or disabled at any time in **Settings > Audio Settings > Text-to-speech**. Enable Audio Exercises and Text-to-speech are stored per learner and initialize Off; TTS voice is also per learner and initializes System. Enable Audio Exercises excludes recorded-MP3, TTS and hybrid audio exercises before learner playback initialization when Off. When On, the Text-to-speech setting, course audio configuration and actual source availability determine eligibility. Test Voice opens an empty field and speaks only the text the user enters; voice resolution still follows the selected course language, not the UI locale or typed text. Authoring Preview ignores these learner settings. QQL 228 makes a clean persistence cut and does not read or migrate previous shared or negative audio-setting values.

- Windows: native `System.Speech` through a dedicated backend, avoiding the current `flutter_tts` Windows platform-thread issue.
- Android, iOS/iPadOS, macOS and Web: platform/browser TTS through `flutter_tts`.
- Linux: eSpeak NG, with eSpeak fallback.

See `docs/TTS_ALL_PLATFORMS.md` for platform-specific setup and run instructions.

## Listening comprehension

Rounds can include `listening_comprehension` exercises. The learner hears a short sentence or mini-dialogue, may replay it, and answers a comprehension question with randomized choices. Learner runtime filters audio exercises whose configured recorded or TTS source is unavailable before playback initialization.


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

Large vocabulary image collections can be distributed separately from the app. Place exactly one Image Bank ZIP in `Documents/QuisquisLingo/Imports/Images`, then open **Settings > Image Bank** or **Course Editor > Image Bank** and choose **Import Image Bank ZIP**. The package must contain `image_bank_manifest.json` plus its referenced image assets, and nothing else (see `docs/IMAGE_BANK_PACKAGES.md`). This allows new banks to be installed without recompiling QuisquisLingo.

Course Manager and every Course Editor hierarchy page provide the same direct **Editor Help** button. General Info keeps only a link to those authoring instructions.

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

Settings shows the installed **Current version** immediately before **Update**. The Update subpage links to the published source repository `https://github.com/Quisquisnaut/QuisquisLingo` and checks its GitHub Releases for packaged application updates. If no GitHub Release exists, the status says that the source repository is published but no packaged application release is available. Automatic checks at startup are on by default, run asynchronously after the startup notice is dismissed, and use strict connection/request/response timeouts without delaying `runApp` or the first interactive UI. QuisquisLingo does not download or install updates itself; when a newer packaged release is available, the page links to the official GitHub release and shows installation guidance for Windows, macOS, Linux antiX, Android, iOS and Web, explicitly marking platforms with no matching release asset as not currently available.

The update check is metadata-only and sends no learner or course data. Offline use is never blocked by GitHub availability.

## Windows Beta diagnostic logging (0.8.1)

Both debug and standalone release Beta builds display tester instructions at startup. QuisquisLingo creates or re-creates one authoritative **Crash Log** at `Documents/QuisquisLingo/Logs/quisquislingo_crash.log` on desktop, using the platform's native Documents directory. On Android and iOS the same logical `QuisquisLingo/Logs/quisquislingo_crash.log` path is inside the app's private application-documents directory, and **Settings > Debug > Share Crash Log** provides access through the platform share UI. QQL does not write another active crash-log copy in application preferences or migrate an older preferences-folder log. The log appends a session snapshot and records uncaught errors in all non-web build modes; detailed navigation breadcrumbs remain debug-only. The separate **Diagnostic Log** stores application troubleshooting events internally and can be exported from **Settings > Debug** to `Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`. Bounded learner-audio lifecycle events use correlation IDs and omit spoken text, answers, course content and full personal file paths.

Beta builds also keep a privacy-safe **Startup Trace** at `%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log`, with `%TEMP%\quisquislingo_startup_trace.log` as fallback. Normal lifecycle tracing is enabled by default. Set `QUISQUISLINGO_STARTUP_DIAGNOSTICS=verbose` before launch only when low-level Windows startup detail is needed. The active trace rotates at approximately 1 MiB and retains two previous generations. See [docs/LOGGING.md](docs/LOGGING.md).


### Publisher signatures (Build 241 working tree)

External official imports require an approved Ed25519 publisher key. See
[Publisher signing and approval](docs/PUBLISHER_SIGNING_GUIDE.md) for approval,
signing commands and manual Dummy tests. The normal registry has no approved
external publishers yet. Dummy is trusted only with the explicit compile-time
`QQL_ENABLE_DUMMY_PUBLISHER=true` flag and a TEST ONLY banner; this is also
available for release-mode **test** builds. Never distribute that configuration
as a public production release. Bundled courses and unsigned custom courses
retain their distinct trust rules. Course Model is v11; v9/v10 Publisher Courses must be converted and signed again.

Final Build 241 Revision 2 validation passed; see the report for full-suite and final focused evidence. Build 242 evidence is in [242 validation](docs/242_VALIDATION.md); Build 243 evidence is in [243 validation](docs/243_VALIDATION.md); Build 244 evidence is in [244 validation](docs/244_VALIDATION.md).

Manual inspection: [Build 242 visual checklist (Italian)](docs/242_VISUAL_CHECKLIST_IT.md), and the previous [Build 241 Revision 2 checklist](docs/241_REVISION_2_VISUAL_CHECKLIST_IT.md).

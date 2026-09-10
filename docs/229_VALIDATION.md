# QQL 229 revision 3 implementation and validation

## Release boundary

QQL 229 revision 3 is Version `2.0.29`, Build `229`, Revision `3`, display build `229.3`, technical build `2293`, and pubspec `2.0.29+2293`. User-facing metadata uses Build/Revision terminology and does not label 229 as a Phase. The Alpha lifetime remains exactly `2026-10-09 23:59:59` local time. Course Model remains v7 (`formatVersion: 7`).

Revision 3 retains every revision-2 language, flag, Course Info, Internal-ID and per-user developer-unlock correction; revision-1 Course Model v7 ownership, Team authorization and clean Duplicate/Fork behavior; and revision-0 Course Manager action consistency, Course Selector Course Info/Hide/Unhide, and Learner Panel Expanded / Collapse completed / Focused behavior. QQL 227 IDDQD/Theme/Flag Background behavior and QQL 228 Settings/Profile, Statistics, Debug/logging, Audio Settings, and Course Entry behavior remain closed baselines.

## Revision 3 corrections

### Ordinary Team-member departure

`TeamService.leaveTeam` resolves the active opaque profile through `ProfileService` and removes only that profile's ordinary membership after Team Manager confirmation. Cancel performs no write. The Team, its other members and Leads, Team-owned courses, learner progress and authoring data remain untouched. Course access changes immediately because `CourseAccessPolicy` continues to derive authorization from the authoritative Team registry. Team Leads cannot use the self-service path; their existing administration flow and the service-enforced mandatory final-Lead invariant remain unchanged.

### Temporary Sample placement

The course-level `temporarySample` field remains canonical Course Model v7 metadata and continues through `Course.toJson`, editor working-copy spreads, Duplicate/Fork copying and `CustomCourseTransferService` export. Course Info now owns the Temporary Sample description. The main Course Editor no longer renders the redundant badge/description or the reopen dialog, so opening or saving unrelated metadata neither alters the flag nor restores that presentation.

### Independent Unpublished state

Course Manager now passes Course publication state separately from `AuthoringHierarchyStatus.courseHasDraft`. A published Course with no authored Draft descendants has no badge; a published Course with Draft descendants shows Draft; an unpublished Course without Draft descendants shows Unpublished; and a Course meeting both conditions shows Draft followed by Unpublished. Both indicators use the established theme-aware blue badge presentation in one wrapping container. Publication changes never synthesize authored Draft state, and descendant Draft changes never alter Course delivery state.

## Authoritative language resolution

The custom-course `und` defect had two linked causes: New Course always stored the undefined `ttsLanguage` sentinel, and Audio Settings rendered/passed that raw field instead of resolving the Course's complete learning-language metadata. Bundled courses happened to carry populated TTS values, which concealed the origin-dependent difference.

`CourseLanguageResolver` now applies one origin-neutral order to valid stored target variants, TTS codes, and established language-name fallback. It preserves variants such as `it-IT`, `en-GB` and `en-US`, preserves general `it`/`en`, rejects absent, malformed and undefined codes, and never invents a regional subtag. Audio Settings Test Voice consumes that result without changing its backend, selected-voice logic, lazy initialization or playback path. Course Info and Course Info Editor show both Learning and Base language names with those authoritative codes and never present blank/`und` when the established fallback resolves them.

## Course Info identity, dates and flag

Course Info and Course Info Editor format Created and Modified with `MaterialLocalizations.formatFullDate`, retaining the existing interface locale and time formatting while guaranteeing a four-digit year. Opening/inspection remains read-only. The existing confirmed authoring transaction preserves Created and updates Modified only after an actual saved semantic change.

`CourseOwnerResolver` reads current Profile/Team records by the stable v7 ownership identity. A Team name is therefore the primary Owner label and changes automatically after a Team rename; Course JSON continues to store only the Team ID. Course Info Editor reveals that ID only under the existing Internal IDs preference. The same preference reveals `Course Model: v<formatVersion>` from the parsed Course schema value and never makes it editable.

`CourseFlagService.resolve` is the shared explicit/automatic precedence source used by Course Info, Course Info Editor preview, selectors, learner surfaces, derived backgrounds and Course Entry Animation. Automatic clears `worldFlagId`, `flagImageBase64` and `flagCode` and resolves the learning-language fallback. Explicit selection persists exactly one authorized built-in, World Flag or custom source and takes precedence. Read-only courses display the resolved result without editing; invalid/unsupported data retains the neutral fallback.

## Authoring-control and Team Manager corrections

Course Manager keeps its AppBar Course Import and Create icon buttons, while their duplicate text buttons are removed. Course Editor keeps the text **Run audit** entry point while its duplicate AppBar Audit icon is removed. No service, registry, count, filter, result or other Audit route changes.

Team Manager applies the existing Internal IDs preference to every Team, Team Lead and ordinary member using the shared selectable monospaced passive presentation. Names remain primary. The permanent final-Lead explanatory sentence is removed; its contextual tooltip, action feedback and independent `TeamService` invariant remain.

## Per-user developer unlock

The developer unlock was device-wide because `SettingsService` read and wrote the unprefixed `course_editor_unlocked` SharedPreferences key. It now resolves the active opaque learner ID and uses the existing Profile namespace. New users default locked; switching/restarting restores only that user's setting; normal learner backup/restore carries it; deleting the profile removes it with the existing namespace lifecycle. Loading Settings resets the in-progress tap counter, so taps cannot be shared across a profile switch. The Course Selector and Settings exposure both read this per-user value, while `CourseAccessPolicy` continues to enforce v7 individual/Team ownership independently.

## Duplicate/Fork first-open correction

The false dirty state was caused by the UI opening a freshly generated Duplicate or Fork as `isNewCourse: true`. `CourseEditorTransaction.hasChanges` deliberately treats every unconfirmed new course as dirty, even when its semantic snapshot is unchanged. Duplicate/Fork generation itself was not corrupting the model.

The authoritative `CourseEditorService.createDuplicate` and `createFork` paths now generate, confirm, persist, and verify the version-1 custom course before the UI starts its ordinary Editor transaction. That Editor opens the persisted result as an existing course, so immediate Back is clean. New Course retains its intentionally unconfirmed behavior, and any real semantic edit still invokes the unchanged confirmation dialog. No dialog suppression or Duplicate/Fork-only dirty bypass exists.

## Metadata restored

New Course and Course Info Editor share `CourseMetadataOptions`. The restored standard licenses are **All rights reserved**, **CC0 1.0**, **CC BY 4.0**, **CC BY-SA 4.0**, **CC BY-NC 4.0**, **CC BY-NC-SA 4.0**, and **Other / Custom license**. The restored roles are **Team Leader**, **Contributor**, **Course Creator**, **Editor**, **Reviewer**, **Native Speaker**, **Audio Contributor**, and **Illustrator**, plus historically supported custom roles. Multiple named authors can hold multiple roles.

The shared editable metadata also covers Course name, language variant, starting/target levels, last-updated date, description/information, and optional Buy a Coffee URL. Source/target language and stable identity/provenance remain read-only where already established. Course Info presents Owner, Creator, License, all structured credits, and existing source/version provenance separately.

## Course Model v7 ownership

Every custom Course JSON requires:

- immutable `creatorProfileId`, a stable UUIDv4 local profile identity;
- `ownership.type`, exactly `individual` or `team`;
- `ownership.id`, a stable UUIDv4 profile or Team identity.

Official Course JSON must not contain local custom ownership. Creator, Owner, visible Credits, License, and fork/source provenance are separate concepts. No Author, contributor, display name, filename, title, or other visible string is consulted for authorization. Earlier custom Course formats and pre-v7 custom namespaces remain untouched and unread; no migration or fallback ownership inference runs.

All nine bundled official files now use formatVersion 7. Their stable Course/content IDs and content remain intact; their official checksums intentionally change because `formatVersion` is authenticated. Custom export/import and verified backup checksums include the required ownership fields. Team membership is not Course JSON.

## Authoritative permission policy

`CourseAccessPolicy` is the shared capability source consumed by Course Manager, the unified Course Editor, and authoritative Duplicate/Fork/save/confirm/delete/import-replacement services:

`Owner / owning Team -> full authoring rights`

`License -> derivative/use rights granted to users outside that ownership boundary`

An individual Owner and every member of an owning Team can edit, Duplicate, and perform existing authorized lifecycle actions regardless of license. Team Lead status is not required for ordinary course authoring. An outsider cannot edit or Duplicate the original; they receive read-only inspection and can Fork only when derivative works are allowed. Official originals are always immutable and may be Forked only when their explicit policy allows it. The storage layer independently enforces these rules.

Duplicate remains an authorized-owner operation. It generates fresh Course/content identities, preserves credits/license/lineage, and retains individual ownership or the same Team ownership. Fork remains a derivative operation. It generates fresh identities, preserves source credits/license/parent-version and existing fork provenance, leaves the source untouched, and defaults to individual ownership by the active profile; an explicitly selected eligible Team may own the Fork.

## Team Manager

Course Manager contains a visible **Team Manager** destination that opens a separate page. `TeamService` stores a verified JSON registry under `quisquislingo_authoring_teams_v1_2291`. A Team has a stable UUIDv4 Team ID, display name, immutable creator profile ID, UTC creation timestamp, stable local-profile member IDs, and one or more Lead IDs.

The creator starts as a Lead. A Lead may add an existing local profile, remove a member, promote a member, or demote a Lead. Multiple Leads are supported. The UI disables invalid final-Lead actions with an explanation, and the service rejects removal or demotion that would leave zero Leads. Ordinary members cannot administer the Team. A creator has no permanent special privilege. Profile deletion also refuses to remove the final Lead; otherwise membership is removed while historical creator provenance remains.

New Course offers **Me** plus Teams the active profile belongs to only when at least one such Team exists. Ownership references the stable Team ID, so renaming a Team does not affect courses. Removing a member immediately removes Team-derived editing/Duplicate rights; the course remains Team-owned even if its Creator later leaves or loses Lead status.

## Unified Course Editor

Bundled official, external official, individually owned custom, Team-owned custom, and outsider-owned custom courses all use `CourseEditorScreen` and the same hierarchy/navigation. Capability state controls mutation: official and outsider courses show the read-only notice and cannot unlock or mutate, while an individual Owner or any owning-Team member receives full editing. Course Info, Audit, Help, IDs, metadata inspection, Lessons/Rounds/Exercises, and navigation remain available as appropriate. Fork or Duplicate appears from the policy; Delete remains Course Manager-only; Audit keeps its single top-level text entry rather than a duplicate AppBar icon.

## Preserved revision-0 learner behavior

Every Course Selector row retains an independent three-dot **Course Info / Hide** menu. Hide remains a reversible per-learner × Course visibility preference, active-course Hide remains disabled, and `Hidden courses (n)` provides immediate Unhide. It does not change Course storage, progress, XP, streak, history, or authoring data.

The bottom Lesson display control retains **Expanded**, **Collapse completed**, and **Focused**, per learner × Course and defaulting Expanded. It continues to use authoritative Progress and `LessonUnlockService`, respects IDDQD Off / On / View Only, keeps locked Lessons collapsed, maintains Focused one-open-Lesson behavior and manual switching, preserves last-visited restoration, and never collapses Sections.

## Automated coverage

Focused revision-3 coverage exercises ordinary-member Leave Team visibility, confirmation/cancellation, self-only removal, immediate authorization loss, preservation of the Team, other members and Team-owned course data, and Team-Lead self-leave protection; Temporary Sample placement plus unrelated-save and real-export preservation; every Draft/Unpublished combination in light and dark themes; and independent narrow-layout badge updates with Draft ordered before Unpublished. The retained revision-2 coverage exercises Build/Revision wording; general/variant language preservation and custom/bundled parity; Test Voice fallback without `und`; language codes, live Team ownership, full-year dates and model visibility in both Course Info surfaces; Created/Modified save semantics; automatic/explicit/read-only flag behavior and cross-consumer resolution; retained icon/text controls; Team/User ID toggling and final-Lead enforcement; per-user unlock isolation, restart/default/backup/deletion behavior and independent ownership enforcement; plus revision-1 Duplicate/Fork cleanliness.

The retained revision-0 suites cover Course Selector menus, Course Info, Hide/Unhide, active-course protection, profile isolation, Lesson expansion default/cycle/persistence, progression and Duel unlock edges, IDDQD interaction, Focused manual switching, Sections, and last-visited behavior.

## Validation results

- Focused revision-3 suite: **9 tests passed**. The revision-3 plus retained revision-2/revision-1 and adjacent authoring regression batch: **70 tests passed**.
- Complete Flutter suite: **1,306 tests passed** in **11 minutes 27 seconds** with zero failures.
- `flutter analyze --no-pub`: **0 errors and 0 new findings**. The repository retains its revision-1 baseline of **71 inherited findings**: **70 infos** (`curly_braces_in_flow_control_structures`) and **1 warning** (`unused_element` in `test/guidebook_sentence_generator_test.dart`). Focused analysis of all changed production and test files reported **no issues**.
- Bundled Course validator: **9 Course Model v7 files passed**.
- Deterministic bundled-course generator/checksum check: **9 files passed**.
- Lesson icon validator: **14 assets, 0 issues**.
- Image Bank validator: **112 assets, 0 issues**.
- Audit Code Registry: **102 rules**, unchanged.
- `git diff --check`: passed; existing LF/CRLF conversion notices are not product failures.

No Course Model or learner backup format changed. The revision-0 profile-scoped Hide (`course_hidden_<encoded courseId>`) and Lesson expansion (`lesson_expansion_mode_<encoded courseId>`) key families remain unchanged. Revision 2 moves only the existing developer-unlock suffix into the ordinary active-profile namespace; obsolete global data is left untouched and unread. Revision 3 mutates only the existing Team registry when an ordinary member confirms self-removal; it adds no persistence family. The revision-1 Team registry and clean v7 custom/official Course namespaces remain unchanged. Nothing was staged, committed, tagged, pushed, reset, reverted or cleaned, and no worktree was created or switched.

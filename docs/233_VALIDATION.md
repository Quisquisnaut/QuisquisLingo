# QQL 233 validation

Validated for QuisquisLingo `2.0.33+233030`, Build 233.1, on the QQL 232 baseline.

## Phase 233.1 — Linux updater

The repository packages Linux as `quisquislingo_linux_alpha_<buildnumber>.zip` and Windows as `quisquislingo_windows_alpha_<buildnumber>.zip`. The updater previously exposed Linux only as `linuxAntix` and required the asset name to contain `antix`, so the real generic Linux ZIP was reported unavailable. No architecture-specific package convention exists in the packaging output.

`UpdatePlatform` now recognizes the generic `linux` operating-system value. Asset matching accepts the real Linux marker and the retained historical antiX marker only with compatible Linux archive/package extensions, rejects conflicting platform markers, and never falls through to a Windows or source package. Windows selection and the existing GitHub Releases comparison/no-release policy are unchanged. A Release can remain newer while exposing no usable asset for the selected platform.

Focused updater coverage uses the real Build 232 package names and verifies Linux/Windows recognition, cross-platform rejection, incompatible/source rejection, no-compatible-package handling, version comparison and trusted Release URLs.

## Phase 233.2 — Learner profile, avatar and Status

New Learner creation is one two-step transaction: **Create Profile** records Screen Name and an optional Discord name, then **Avatar Customization** edits the same stable learner ID. Discord input does not require `@`; stored presentation is normalized to one leading `@`. It is backed up/restored as display metadata and is never used for identity, progress, Course maintenance, Team membership or authorization.

Only a new profile receives randomly selected initial skin and hair values. Existing profile appearance is read without randomization, and both choices remain editable. T-shirt color is no longer a preference: `LearnerAvatar` maps the current authoritative Status rank directly to the ten confirmed vivid colors. Profile, Avatar Customization and the active learner bottom icon refresh from existing XP, streak, distinct-study-day, completed-Round and Laurel invalidations.

Avatar Customization prominently shows the current Status, the live level-colored avatar, all ten names and visible color samples, and a marked Current row. Its Help text states the existing score formula and thresholds rather than introducing new progression rules.

Focused coverage verifies profile/Discord persistence and backup, no-Discord creation, stable identity across edits and both creation steps, new-only random skin/hair, editable appearance, exact Status names/colors/threshold behavior, level-driven shirt changes, all-level/current-level presentation, Help text, and absence of a manual shirt control.

## Phase 233.3 — Course maintenance, Team assignment, identity and UI composition

The final same-version v9 correction gives a custom Course immutable Original Course Creator/Created provenance, one individual Course Maintainer, and an optional separate `assignedTeamId`. A Team cannot be Maintainer. The v9 custom/external-official/bundled-discovery namespaces do not read or rewrite v8 or older Course namespaces.

The Original Course Creator may choose any existing local individual as initial Maintainer. Only the current Maintainer in Course Editor Edit mode can transfer maintenance, assign a Team after the required warning, or revoke the assignment. These changes preserve Original Course Creator/Created and Course identity. Team members receive the established management access through the assigned Team, but neither membership nor Team leadership grants maintenance-transfer or assignment power. Team governance remains independent: the Team creator is the first Team Leader, any Leader manages membership and Leader roles, and service checks prevent removal or demotion of the final Leader.

Course Info distinguishes Original Course Creator, Course Maintainer, Assigned Team, Team Leaders and ordinary Team Members. User presentation prefers normalized Discord `@handle` and falls back to Screen Name, while every decision continues to use the stable user ID. The existing Internal IDs control remains the only toggle. Official publisher provenance is presented as publisher information rather than an individual operational role. Team Manager includes the experimental-model Help and the limits of QQL permissions.

The underlying learner-shell composition was corrected: only `home_screen.dart` mounts `LearnerStatusPage`/`LearnerStatusAppBar`. Course Info and all editor/manager screens use ordinary scaffolds, while the Learner Panel retains the status bar. The bottom row remains Profile at the far left followed by the existing six compact controls.

Focused governance and retained QQL 229 coverage exercise individual-only maintenance, another initial Maintainer, Maintainer-only/Edit-only transfer, immutable Original Course Creator/Created, warning confirmation/cancellation, assignment/revocation, no self-assignment, Team/Course authority independence, multi-Course Team assignment, Leader invariants, Discord/Screen Name presentation, ID visibility, Course Info role labels, management-screen status-bar absence and learner-bottom ordering.

## Same-version QQL 233 corrections

This correction remains application version `2.0.33+233030`, user-facing **Build 233.1**, and the established `2026-10-14 23:59:59` local Alpha expiry. It introduces Course Model v9 without creating a new app release or reinterpreting the three internal development phases as public revisions.

- Review uses the same inter-review screen before the first Round and between completed Rounds. The initial heading is **Ready for Review** and does not say **Congratulations**. Reset, Help, Next Review and Back to Course remain available; the displayed singular/plural word count is recalculated from the next Round chosen by the unchanged authoritative ordering.
- Screen Names use NFC comparison and a conservative Latin-letter user-name policy. New learners receive a collision-checked immutable five-digit display suffix. Team/Course labels use the shared safe Unicode, whitespace, control/invisible, emoji and problematic-symbol policy without the learner-only digit restriction or suffix. Identical visible labels remain legal after an explicit warning.
- Discord input is optional username presentation. One optional leading `@` is ignored for validation and accepted values are stored/presented with exactly one leading `@`; formally invalid values use the requested warning-only Edit/Continue flow. Learner Profiles always shows the QQL Screen Name and adds `@username on Discord` only when present.
- The first local user is an admin, at least one admin must remain, and admins can promote users or relinquish their own role only while another admin remains. Profile deletion is limited to self for ordinary users and any integrity-safe profile for admins. Admin status remains independent from Course and Team roles and appears only in Learner Profiles.
- Optional four-digit Access PINs use salted SHA-256 verification rather than plaintext storage. A PIN gates profile switching; users can create/change/remove their own PIN and an admin can remove another user's PIN. Device naming is descriptive, initialized from the local computer name and editable only by admins.
- User Recovery Keys export directly to Exports and import directly from Imports, with zero/one/multiple-file handling and explicit same-installation identity conflict handling. A key carries the stable user UUID plus sensitive recovery secret, never the visible Screen Name, Discord handle or Access PIN. Help describes recovery, multi-device identity, recognition of ID-linked Course/Team relationships and credential privacy.
- Screen-name renaming retains the immutable suffix and stable ID, Original Course Creator/Course Maintainer references, Team roles, admin/PIN associations, progress and Review state. Course Info's Author Team Leader field is explicitly descriptive and cannot change Team membership, leadership or permissions.
- The status-bar composition remains exclusive to the Learner Panel, and the approved profile-left/six-controls-right bottom layout remains unchanged. The Status color explanation is exactly: `Each level has its own T-shirt color.`
- Application identity is a clean cut to `org.quisquislingo.app`; no `com.example` fallback or migration exists. CrashLogService has one active writer and uses the shared Documents/application-documents `QuisquisLingo/Logs/quisquislingo_crash.log` path; mobile Debug UI can share the private-file copy.

## Same-version Course Model v9 cleanup

Course Model v9 separates metadata by purpose:

- **Provenance:** immutable Original Course Creator and Original Course Created; for forks, immutable Fork Created By/Date and an authoritative immediate source-Course reference.
- **Operational responsibility:** one individual Course Maintainer plus optional Assigned Team.
- **Attribution:** structured Authors/Contributors with `roles[]`.
- **Legal/rights metadata:** License and structured person/organization Rights Holders.
- **Current editing/version metadata:** Last Version Editor, automatic Modified, the authoritative custom/official Course version fields, version notes and existing version history.

None of Original Course Creator, Fork Created By, Rights Holder or Authors/Contributors grants QQL permission. Authorization remains based on the stable Maintainer ID, current Assigned Team membership, and official/custom/License policy. Any user with ordinary Edit permission may edit Rights Holder, while view-only and official read-only Courses remain read-only.

**Fork** creates a derivative in the same lineage. It inherits Original Course Creator/Created, structured attribution, Rights Holder and applicable License; records its immediate source plus Fork Created By/Date; makes the active user Maintainer and Last Version Editor; initializes Modified; and does not inherit Assigned Team.

**Copy as New Course** replaces the Course-level Duplicate action and creates an independent lineage. It resets Original Course Creator/Created, Maintainer, Last Version Editor and Modified for the active user/new instance; creates a new Course identity; omits fork metadata and Assigned Team; and copies content, structured attribution, Rights Holder and applicable License without implying a legal-rights transfer.

The v9 parser and serializer remove obsolete v8 fields rather than retaining aliases: the old creator/ownership objects, Created by and last-modifier fields, manual Last Updated, scalar `author`, singular author `role`, scalar fork `originalAuthor`, generic `version`, `updateSummary`, `contentRevision`, `parentCourseId` and `derivedFromVersion`. All nine bundled Courses are regenerated from the authoritative process in canonical v9 form.

Active storage uses `quisquislingo_user_courses_v9_233030`, `quisquislingo_external_official_courses_v9_233030`, `quisquislingo_course_editor_corrupt_backup_v9_233030` and `quisquislingo_bundled_course_codes_v9_233030`. Course Version History uses the v9-only `Documents/QuisquisLingo/Exports/Course Backups v9/<courseId>` directory and `QuisquisLingo Course Backup v9` manifest format; the canonical Course payload is the sole source for Last Version Editor and Modified metadata. v8 data and backup directories remain physically untouched, are never read or transformed, and are not used as fallback when v9 data is absent.

## Version, model and validation evidence

- Application: `2.0.33+233030`; display: `Version 2.0.33`, `Build 233.1`.
- Course Model: v9 (`formatVersion: 9`).
- Alpha expiry: `2026-10-14 23:59:59` local time.
- Focused correction suites: **PASS — 119 tests**, plus **56 retained compatibility tests**, **27 Learner/Profile UI tests**, and **2 narrowed fixture regressions**.
- Full analyzer: **PASS — no issues** (`flutter analyze --no-pub`).
- Scoped formatter check: **PASS — 38 changed Dart files, 0 changes required**.
- Bundled Course validator: all 9 Course Model v9 files and canonical checksums must pass the final regenerated-source validation.
- Image Bank validator: **PASS — 112 assets, 0 issues**.
- `git diff --check`: **PASS** (Git emitted only the repository's line-ending conversion warnings).
- Full Flutter suite: **1,453 passed with 2 non-reproducing failures in the unchanged Lesson-controls area**. The two implicated files passed **24/24** immediately in a targeted rerun; per instruction, the expensive full suite was not launched again.
- Windows package: **SUCCESS** — `build/packages/quisquislingo_windows_alpha_233030.zip`; repository launcher/unit/integration and ZIP checks passed.
- Linux package: **SUCCESS** through Ubuntu WSL using native `/home/dex/flutter/bin/flutter`, not the Windows SDK — `build/packages/quisquislingo_linux_alpha_233030.zip`; ZIP integrity passed.
- Android release APK/AAB and debug APK: **SUCCESS** — `build/app/outputs/flutter-apk/app-release.apk`, `build/app/outputs/bundle/release/app-release.aab`, and `build/app/outputs/flutter-apk/app-debug.apk`. The debug APK declares minSdk 24 and is installable on Android 11 (API 30), subject to normal device requirements.
- macOS and iOS: **BLOCKED** — this is a Windows/WSL host with no macOS/Xcode environment, so their host-restricted build commands were not run.
- Release actions: no commit, stage, tag, push, publish, upload or GitHub Release. Generated local packages remain unpublished.

The final full-suite run contained two failures in unchanged Lesson-control tests. Both affected files passed all 24 tests immediately when rerun together, so the failures are recorded as non-reproducing full-run-only results rather than QQL 233 regressions. No second full suite was launched.

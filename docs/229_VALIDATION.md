# QQL 229 revision 1 implementation and validation

## Release boundary

QQL 229 revision 1 is Version `2.0.29`, Phase `229`, revision `1`, display build `229.1`, technical build `2291`, and pubspec `2.0.29+2291`. The Alpha lifetime remains exactly `2026-10-09 23:59:59` local time. Course Model is v7 (`formatVersion: 7`).

Revision 1 starts from and retains the uncommitted revision-0 Course Manager action consistency, Course Selector Course Info/Hide/Unhide, and Learner Panel Expanded / Collapse completed / Focused implementation. QQL 227 IDDQD/Theme/Flag Background behavior and QQL 228 Settings/Profile, Statistics, Debug/logging, Audio Settings, and Course Entry behavior remain closed baselines.

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

Bundled official, external official, individually owned custom, Team-owned custom, and outsider-owned custom courses all use `CourseEditorScreen` and the same hierarchy/navigation. Capability state controls mutation: official and outsider courses show the read-only notice and cannot unlock or mutate, while an individual Owner or any owning-Team member receives full editing. Course Info, Audit, Help, IDs, metadata inspection, Lessons/Rounds/Exercises, and navigation remain available as appropriate. Fork or Duplicate appears from the policy; Delete remains Course Manager-only; the existing top Lock and Audit placements remain distinct.

## Preserved revision-0 learner behavior

Every Course Selector row retains an independent three-dot **Course Info / Hide** menu. Hide remains a reversible per-learner × Course visibility preference, active-course Hide remains disabled, and `Hidden courses (n)` provides immediate Unhide. It does not change Course storage, progress, XP, streak, history, or authoring data.

The bottom Lesson display control retains **Expanded**, **Collapse completed**, and **Focused**, per learner × Course and defaulting Expanded. It continues to use authoritative Progress and `LessonUnlockService`, respects IDDQD Off / On / View Only, keeps locked Lessons collapsed, maintains Focused one-open-Lesson behavior and manual switching, preserves last-visited restoration, and never collapses Sections.

## Automated coverage

Focused revision-1 coverage exercises first-open Duplicate/Fork cleanliness and real edit dirtiness; required v7 ownership; metadata creation/round trips/Course Info; owner, Team member, removed member, outsider and official permission matrices; no-derivatives enforcement; Duplicate ownership; Fork lineage; Team creation/membership/multiple Leads/final-Lead invariants/rename/profile deletion; New Course ownership choices; unified Editor read-only/editable surfaces; and Course Manager Team navigation.

The retained revision-0 suites cover Course Selector menus, Course Info, Hide/Unhide, active-course protection, profile isolation, Lesson expansion default/cycle/persistence, progression and Duel unlock edges, IDDQD interaction, Focused manual switching, Sections, and last-visited behavior.

## Validation results

- Focused revision-1 and retained 229 regression batch: **118 tests passed**.
- Complete Flutter suite: **1,278 tests passed** in 20:33 with zero failures.
- `flutter analyze --no-pub`: **0 errors**, **1 inherited warning**, and **70 inherited info diagnostics** (71 total); revision-1 delta: **0**.
- Bundled Course validator: **9 Course Model v7 files passed**.
- Deterministic bundled-course generator/checksum check: **9 files passed**.
- Lesson icon validator: **14 assets, 0 issues**.
- Image Bank validator: **112 assets, 0 issues**.
- Audit Code Registry: **102 rules**, unchanged.
- `git diff --check`: passed; existing LF/CRLF conversion notices are not product failures.

No learner persistence format changed. The revision-0 profile-scoped Hide (`course_hidden_<encoded courseId>`) and Lesson expansion (`lesson_expansion_mode_<encoded courseId>`) key families remain unchanged. Revision 1 adds only the Team registry and clean v7 custom/official Course JSON changes described above. No package, Git stage, commit, tag, or push is part of this implementation.

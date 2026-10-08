# QQL 226.01 pre-commit validation report

Status: **226.01 implementation and required automated validation complete; awaiting pre-commit approval.** The documented baseline analyzer/image findings and outstanding native checks are reported below.

## Scope and immutable parent

Implemented tranche **226.01: Official courses read-only and licensed custom forks**, from the complete controlling `qql_226_prompt.txt`. No 226.02 or later requirement was implemented.

Before editing, `git status --short`, `git diff --cached --name-only`, untracked-file inspection and `git diff --check` were empty/passing. The required recent history was inspected. HEAD, `origin/main` and the live `origin` main ref all matched:

```text
ede21f813a235e8455d2691da4cf3bb43162a39a
```

This is the approved Build 225.04 plus 226.00 documentation correction. The working tree was clean. Baseline metadata was `2.0.25+22504`, with Alpha expiry October 4, 2026 at 23:59:59. The interruption was a usage-limit stop; resumption verified the same HEAD and preserved the existing uncommitted work.

Candidate metadata: **Version 2.0.26 / Build 226.01 / `2.0.26+22601`**. Alpha expiry is **October 5, 2026 at 23:59:59 local time**, following the existing thirty-day policy from the September 5 candidate date. Course Model remains **v6**; learner backup remains **v2**.

## Architecture and working-copy implications

- `CourseEditorScreen` dispatches in its stateless build: official sources enter dedicated inspection; a private custom editor alone owns `CourseEditorTransaction`. Official Course Info, Audit, Guidebook, Lesson/Round/Exercise inspection and existing Preview routes remain available, with the explicit **Official course - read only** notice.
- Official authoring controls are absent. Transaction construction and confirmation reject official origins, direct custom persistence rejects official objects and reserved/installed official IDs, and a custom transaction cannot become official.
- Bundled discovery loads the current asset only. External discovery resolves only the validated publisher `source` record. Source identity, publisher, version, checksum and supported verification classification are checked; external file packages remain explicitly unverified after the existing warning flow. No signature authentication or network downloading was invented.
- `CourseEditorService.forkOfficialCourse` requires explicit allowed derivative permission, valid source integrity and an active local profile. It creates an unsaved custom draft with a fresh `Course.newCourseId()` identity, fresh owned IDs/references and an immutable provenance snapshot. Forked JSON metadata and author roles are detached from the source.
- A permitted fork opens the ordinary new-custom transaction. First confirmation is custom version `"1"`; later confirmations, atomic writes, pre-change backups, failure preservation, cancellation and historical restore retain Build 225 custom behavior. Cancelling creation leaves no persisted fork. Custom duplication remains distinct from licensed official forking.
- Original publisher, official course ID/version/checksum/title and original authors (including roles and legacy author credit) are permanently separate from the fork creator and later custom/version authors. Existing-course save, transaction replacement and confirmation reject provenance removal/replacement. Restore retains the active course's authoritative provenance. Export/import and separate custom copies preserve it.
- External updates archive the previous publisher source and replace only that source after validation. Existing fork content, provenance, versions and custom storage remain unchanged. No merge, rebase or replacement of forks exists.

## Persistence, schema and checksum contract

The existing custom key `quisquislingo_user_courses_v6_225` and external-source key `quisquislingo_external_official_courses_v6_22504` remain. There is no custom-course migration or namespace invalidation. Learner/profile/progress/XP keys are unchanged. External envelopes retain opaque old fields when updating their source, without parsing or activating the obsolete override payload.

Optional v6 additions:

- `derivativeWorksPolicy`: `allowed`, `forbidden`, `unspecified`; missing/null is unspecified and omitted by canonical serialization. Unrecognized values fail parsing. Only explicit allowed permits a fork; free-text licensing is never interpreted as permission. All nine bundled assets retain their existing licenses and unspecified policy, so none currently enables a fork.
- `forkProvenance`: immutable original publisher ID/name, original course ID/title, original official version/checksum, legacy original author and original author/role list; separately fork creator profile ID/username and UTC creation time. It is permitted only on custom courses. Required identifiers/titles are nonempty, the checksum is lowercase SHA-256 and the creation timestamp is UTC.

Removed model fields: `baseCourseId`, `basePublisherId`, `baseOfficialCourseVersion`, `baseOfficialChecksum`, `localCourseVersion`, `localAuthorProfileId`, `localAuthorUsername`, `localModifiedAtUtc`, `localVersionNotes`.

The official digest hashes parsed `Course.toJson()` after removing exactly the root `officialChecksum`, `publisherVerificationStatus` and `publisherSignature`. Remaining object keys are recursively sorted with Dart string ordering, list order/scalars are preserved, compact JSON is UTF-8 encoded without BOM/newline, and SHA-256 yields lowercase hex. Explicit derivative permission is covered. Removed local fields no longer serialize; `restoredFromVersion`, if serialized, is covered. Ordinary full-course backup hashing excludes nothing. Existing bundled digests are unchanged, confirmed through production loading and byte-for-byte regeneration checks.

Backup format remains `QuisquisLingo Course Backup v1` below `Documents/QuisquisLingo/Exports/Course Backups/<sanitized courseId>`. Official backup names use official versions and publisher/release metadata. Official history validates publisher sources and excludes obsolete local-variant manifests before model loading. Audio copies are integrity-checked for both origins; only custom restore remaps their paths. Official history/export retains original payload paths and its publisher checksum.

## Removed legacy production paths and clean cut

Removed:

- Bundled override storage-key declaration and automatic overlay selection (`applyToCourse`, bundled `saveCourse`, `_asLocalOfficialVariant`).
- Official confirmation/storage branches and `_confirmedOfficialVariant`.
- External `override ?? source` selection and active-local archival semantics.
- Local-version/base metadata fields, getters and Course Info/Home/history presentation.
- Official restore-to-working-copy, copy-local-edits JSON and unlicensed historical custom-copy UI/selection paths.
- Overlay update-notice persistence/consumption and Home archival notice.

No old authoring branch is intentionally retained as a compatibility mode. The only remaining production references to removed field names identify legacy manifests to skip in official history. Generic custom backup loading remains for ordinary custom history; official UI uses the dedicated filtered history API. Shared nested authoring screens remain reachable only through custom authoring; official inspection supplies no mutation callbacks and persistence rejects official objects independently.

Old bundled override storage is never read, including malformed payloads. Existing external override members are opaque and inactive. Old local-variant backup files remain on disk but are not presented as active/publisher versions or converted into forks. No destructive cleanup or automatic conversion was introduced. This intentionally removes in-app use of Build 225 official local modifications while retaining ordinary custom courses.

## Focused evidence against the 22 required cases

| Specification cases | Evidence |
| --- | --- |
| 1–2: both official origins read-only | UI tests for both origins; official transaction construction, confirmation and direct custom-save rejection. |
| 3–5: Info, Audit and Preview work | Production inspection tests navigate Info, Audit, history, Lessons, Rounds and Exercises, then run the existing exercise Preview and compare stored preferences. |
| 6: no local official Save/Edit mutation | No authoring controls or transaction in official inspection; service-origin and collision guards; closing official inspection creates no confirmation or backup and preserves custom storage. |
| 7–8: obsolete overrides/local versions ignored | Real bundled loader seeded with an old edited title/local version 99; malformed obsolete bundled storage ignored; external source selection ignores unsupported old override payloads; history filters old local manifests without deleting them. |
| 9: publisher update changes only source | Source-only external update regression, validated official-source backup and opaque old payload preservation. |
| 10–12: permission policy | Both origins exercise allowed/forbidden/unspecified; UI disables disallowed actions with explanations; changing policy/content without recomputing integrity fails; free-text licensing does not grant permission. |
| 13–16: independent editable custom identity | Fresh course/subtree IDs and correct internal references; actual custom editor rename/confirm; first version 1 and later increments; original JSON/checksum unchanged; nested metadata detached. |
| 17–20: original authors and separate creator persist | Immutable original author/role snapshots, separate active-profile fork creator, rename and version-author changes; provenance tampering rejected. |
| 21: export/import | Provenance survives JSON export/import/reload and separate custom copies; historical restore retains active provenance. |
| 22: update isolation | Official v3→v4 update leaves the existing fork's complete JSON and custom persistence unchanged, still based on v3; invalid update/publisher/collision cases reject. |

Additional coverage verifies official audio history preserves publisher payload/checksum and custom backup audio restore keeps its established behavior. Widget layout checks cover 320, 375, 430 and 1200 px in Light/Dark themes.

## Automated validation

| Check | Exact result |
| --- | --- |
| Initial characterization on Build 225 behavior | Expected failure: old bundled overlay became active, proving the regression detects the removed behavior. |
| Final focused regression run | **137 passed, exit 0, 2m17s**. Command below. |
| Final full test suite | **612 passed, exit 0, 7m48s**; no failures. |
| Final analyzer | **Exit 1, 73 findings, 16.5s**: the same 72 `curly_braces_in_flow_control_structures` Info notices in untouched files and one `unused_element` warning at `test/guidebook_sentence_generator_test.dart:255`. No errors and no findings in changed files. |
| Dart format, changed files only | Exit 0; 27 Dart files formatted. Final pass changed two files; no unformatted candidate Dart remains. |
| `flutter pub get` | Exit 0; 25 newer packages outside constraints reported. Flutter transiently changed four unrelated resolved dependencies and inserted analyzer exclusions; those tracked changes were removed. Existing lockfile content and analyzer configuration are unchanged. |
| `python tools/validate_courses.py` | Exit 0; all **9** bundled v6 files pass. |
| `python tools/validate_lesson_icons.py` | Exit 0; **14 assets, 0 issues**. |
| `python tools/validate_images.py` | Exit 1; **113 assets, 1 issue**: missing `assets/exercise_images/hello.webp`, already documented and characterized in Build 225.04. |
| `python tools/regenerate_bundled_courses_225_02.py --check` | Exit 0; all nine source assets match byte-for-byte, with unchanged per-file SHA-256 values. |
| Bundled production Course Audit | All **9** courses: **0 Errors, 0 Warnings, 0 Info**, individually and in aggregate. |
| `git diff --check` | **Exit 0**, no whitespace errors. Git may emit only LF/CRLF conversion warnings. |

Final focused command:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/official_course_storage_226_01_test.dart test/licensed_course_forks_226_01_test.dart test/official_course_ui_226_01_test.dart test/course_editor_transaction_225_04_test.dart test/production_course_transaction_225_04_test.dart test/course_official_provenance_225_04_test.dart test/course_version_history_225_04_test.dart test/app_metadata_225_04_test.dart test/alpha_lifecycle_test.dart test/course_audit_report_225_test.dart test/course_editor_layout_regression_test.dart test/leaderboard_navigation_test.dart test/learner_round_path_test.dart
```

Full test command:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --timeout 60s
```

Analyzer command: `flutter analyze --no-pub`. All Flutter commands used the installed SDK outside the filesystem sandbox; serial tests follow the established repository validation convention. Tests use the environment's resolved package configuration. No dependency upgrade is proposed in the tracked lockfile. No analyzer findings were suppressed.

Earlier integration results are retained for traceability: the first focused run passed 87 with four failures (one misspelled test path, two missing Preview test filesystem stubs and one incorrect seeded-storage expectation). Those were corrected; the UI subset then passed 24 and the next core subset passed 64. An initial full run passed 575 and failed 36 while required metadata/menu expectations were still stale, including Welcome-notice fixtures; the final focused run validates those corrections. Two newly introduced analyzer Info findings were fixed, not suppressed. Only the final results above are delivery evidence.

Local evidence logs are under ignored `build/22601/`: `focused-verified.log`, `full-tests-final.log`, `analyze-verified.log`, `pub-get.log`, `format-final.log`, `validate-courses-final.log`, `validate-lesson-icons.log`, `validate-images.log`, and `bundled-regeneration.log`. Intermediate logs and task-local editing helpers remain there and are not proposed commit files.

## Complete changed-file list and file-by-file summary

| File | Change |
| --- | --- |
| `AGENTS.md` | Records the 226.01 boundary and official clean-cut invariants. |
| `CHANGELOG.md` | Adds the 226.01 candidate entry and thirty-day Alpha date. |
| `README.md` | Current metadata, Alpha date, read-only/fork behavior and scope. |
| `docs/226_01_VALIDATION.md` | This complete pre-commit report and validation evidence. |
| `docs/COURSE_EDITOR.md` | Custom-only authoring, official inspection, licensing, fork provenance/history and current metadata. |
| `docs/COURSE_JSON_FORMAT.md` | Exact v6 policy/provenance additions, removed local fields, canonical checksum and source-history behavior. |
| `docs/EXTERNAL_CONTENT_PACKS.md` | Read-only publisher packages, licensed forks and source-only updates. |
| `docs/LOGIC.md` | Custom transaction boundary and explicit 226.01 storage cut after historical Build 225 notes. |
| `docs/SAMPLE_COURSE.md` | Current tranche and unchanged bundled licenses/unspecified derivative permission. |
| `docs/SECURITY_AND_ROBUSTNESS.md` | Official storage/authoring guards and permanent fork provenance. |
| `lib/models/course_models.dart` | Explicit policy and immutable fork provenance; removes official-local metadata; disallows generic official copying. |
| `lib/screens/course_editor_screen.dart` | Stateless origin routing, private custom transaction owner, permanent provenance card, removal of local official UI paths. |
| `lib/screens/course_info_screen.dart` | Read-only official details and separate permanent original/fork attribution display. |
| `lib/screens/course_projects_screen.dart` | Official inspection actions, custom-only duplication and source-update wording. |
| `lib/screens/course_version_history_screen.dart` | Publisher-only official history; removes official local restore/copy and local-version presentation. |
| `lib/screens/editor_help_screen.dart` | Narrow factual Help changes for official inspection, forks, backups and source updates. |
| `lib/screens/home_screen.dart` | Removes active-local overlay notice and local-version course labels. |
| `lib/screens/official_course_inspection_screen.dart` | New dedicated source-resolving official hierarchy/Info/Audit/Preview/history and licensed fork action. |
| `lib/services/alpha_lifecycle_service.dart` | Existing thirty-day Alpha policy applied to September 5 candidate. |
| `lib/services/app_metadata.dart` | Version 2.0.26, display Build 226.01 and technical build 22601. |
| `lib/services/authoring_duplication_service.dart` | Explicit licensed official-copy entry; independent IDs/metadata and preserved original credits. |
| `lib/services/course_backup_service.dart` | Official source history/filtering, publisher-version backup metadata, current digest exclusions and immutable official audio payload paths. |
| `lib/services/course_editor_service.dart` | Source-only storage/update selection, official write guards, licensed fork creation and immutable provenance persistence guards. |
| `lib/services/course_editor_transaction.dart` | Custom-only transaction and restore with protected original provenance. |
| `lib/services/course_service.dart` | Removes bundled overlay service dependency; loads source assets only. |
| `pubspec.yaml` | Technical version `2.0.26+22601`, no dependency changes. |
| `test/alpha_lifecycle_test.dart` | Inclusive expiry and existing milestone semantics for the new candidate date. |
| `test/app_metadata_225_04_test.dart` | New tranche metadata and preserved ten-tap Editor activation expectations. |
| `test/course_audit_report_225_test.dart` | Audit report metadata expectations for 226.01. |
| `test/course_editor_layout_regression_test.dart` | Explicit Duplicate custom course label; retains custom transaction/cancellation coverage. |
| `test/course_editor_transaction_225_04_test.dart` | Replaces obsolete official-local assertions with read-only/source update cases and keeps custom transaction regression coverage. |
| `test/course_version_history_225_04_test.dart` | Removes the obsolete separate-copy result assertion while retaining custom restore evidence. |
| `test/leaderboard_navigation_test.dart` | Custom-course Settings reload fixture, current Welcome key and Alpha text; learner behavior assertions retained. |
| `test/learner_round_path_test.dart` | Current version-scoped Welcome fixture only. |
| `test/licensed_course_forks_226_01_test.dart` | New policy, identity, authorship, creator, immutable metadata, persistence, restore and update-isolation cases. |
| `test/official_course_storage_226_01_test.dart` | New actual-loader legacy-data cut, source-only history/update, digest and audio payload integrity cases. |
| `test/official_course_ui_226_01_test.dart` | New official inspection, policy, licensed editing/confirm and responsive widget coverage. |
| `test/production_course_transaction_225_04_test.dart` | Official close/persistence assertions replace local-edit workflow; all custom production flows retained. |
| `tools/regenerate_bundled_courses_225_02.py` | Aligns canonical digest exclusions and unspecified-policy omission; no assets regenerated. |
| `tools/validate_courses.py` | Aligns digest algorithm and validates explicit derivative policy/official provenance constraints. |

No bundled assets, learner/scoring services, app IDs, release packaging, dependency pins or analyzer policy are proposed changes. Historical Build 225 validation reports remain unchanged. Existing comments were retained except where the official clean cut or candidate date made them obsolete.

## Exact repository state

Branch: `main`. HEAD and `origin/main` both remain `ede21f813a235e8455d2691da4cf3bb43162a39a`. No staged changes. **40 proposed files: 35 modified tracked files and 5 new untracked files.** The working tree is intentionally dirty with the reviewed tranche; nothing was committed.

Exact `git status --short`:

```text
 M AGENTS.md
 M CHANGELOG.md
 M README.md
 M docs/COURSE_EDITOR.md
 M docs/COURSE_JSON_FORMAT.md
 M docs/EXTERNAL_CONTENT_PACKS.md
 M docs/LOGIC.md
 M docs/SAMPLE_COURSE.md
 M docs/SECURITY_AND_ROBUSTNESS.md
 M lib/models/course_models.dart
 M lib/screens/course_editor_screen.dart
 M lib/screens/course_info_screen.dart
 M lib/screens/course_projects_screen.dart
 M lib/screens/course_version_history_screen.dart
 M lib/screens/editor_help_screen.dart
 M lib/screens/home_screen.dart
 M lib/services/alpha_lifecycle_service.dart
 M lib/services/app_metadata.dart
 M lib/services/authoring_duplication_service.dart
 M lib/services/course_backup_service.dart
 M lib/services/course_editor_service.dart
 M lib/services/course_editor_transaction.dart
 M lib/services/course_service.dart
 M pubspec.yaml
 M test/alpha_lifecycle_test.dart
 M test/app_metadata_225_04_test.dart
 M test/course_audit_report_225_test.dart
 M test/course_editor_layout_regression_test.dart
 M test/course_editor_transaction_225_04_test.dart
 M test/course_version_history_225_04_test.dart
 M test/leaderboard_navigation_test.dart
 M test/learner_round_path_test.dart
 M test/production_course_transaction_225_04_test.dart
 M tools/regenerate_bundled_courses_225_02.py
 M tools/validate_courses.py
?? docs/226_01_VALIDATION.md
?? lib/screens/official_course_inspection_screen.dart
?? test/licensed_course_forks_226_01_test.dart
?? test/official_course_storage_226_01_test.dart
?? test/official_course_ui_226_01_test.dart
```

Exact `git diff --stat`:

```text
 AGENTS.md                                          |   3 +
 CHANGELOG.md                                       |   7 +
 README.md                                          |  10 +-
 docs/COURSE_EDITOR.md                              |  32 +-
 docs/COURSE_JSON_FORMAT.md                         |  31 +-
 docs/EXTERNAL_CONTENT_PACKS.md                     |   2 +-
 docs/LOGIC.md                                      |   8 +-
 docs/SAMPLE_COURSE.md                              |   4 +-
 docs/SECURITY_AND_ROBUSTNESS.md                    |   2 +-
 lib/models/course_models.dart                      | 235 +++++++++----
 lib/screens/course_editor_screen.dart              | 271 ++++-----------
 lib/screens/course_info_screen.dart                |  59 +++-
 lib/screens/course_projects_screen.dart            |  43 ++-
 lib/screens/course_version_history_screen.dart     |  64 ++--
 lib/screens/editor_help_screen.dart                |  14 +-
 lib/screens/home_screen.dart                       |  34 +-
 lib/services/alpha_lifecycle_service.dart          |   4 +-
 lib/services/app_metadata.dart                     |   6 +-
 lib/services/authoring_duplication_service.dart    |  43 ++-
 lib/services/course_backup_service.dart            |  87 +++--
 lib/services/course_editor_service.dart            | 374 +++++++--------------
 lib/services/course_editor_transaction.dart        |  41 ++-
 lib/services/course_service.dart                   |  33 +-
 pubspec.yaml                                       |   2 +-
 test/alpha_lifecycle_test.dart                     |  30 +-
 test/app_metadata_225_04_test.dart                 |  10 +-
 test/course_audit_report_225_test.dart             |   6 +-
 test/course_editor_layout_regression_test.dart     |   4 +-
 test/course_editor_transaction_225_04_test.dart    | 137 ++------
 test/course_version_history_225_04_test.dart       |   1 -
 test/leaderboard_navigation_test.dart              |  33 +-
 test/learner_round_path_test.dart                  |   2 +-
 .../production_course_transaction_225_04_test.dart |  56 ++-
 tools/regenerate_bundled_courses_225_02.py         |  18 +-
 tools/validate_courses.py                          |  14 +-
 35 files changed, 770 insertions(+), 950 deletions(-)
```

`git diff --stat` does not count the five untracked additions until staging; all five appear in the complete list above. The old lockfile's transient resolver changes and generated line-ending/stat differences were verified against HEAD and removed; `pubspec.lock` and `analysis_options.yaml` have no proposed diff. The index has no staged content. Git's LF/CRLF warnings are conversion notices only.

`git diff --check`: exit 0 with no stdout/whitespace errors. Untracked additions were also inspected for trailing whitespace. `git diff --cached --name-only`: no output.

Exact `git log -4 --oneline --decorate`:

```text
ede21f8 (HEAD -> main, origin/main, origin/HEAD) Correct QQL 225.04 version and checksum documentation
1fce54d Unify QQL 225.04 course transactions and version history
94a7c00 Fix QQL 225.03 Korean discovery and hierarchical saves
a999428 Complete QQL 2.0.25+225 bundled courses and editor corrections
```

## Manual checks, risks and unresolved questions

Manual checks actually performed: source/diff review, provenance and persistence call-path tracing, test-log review and repository-state verification. **No native Windows interaction, audio playback or visual inspection was performed.** Automated widget overflow/navigation checks are not claimed as manual checks.

Outstanding native checks:

- Inspect bundled and imported official courses at Course/Lesson/Round/Exercise levels; verify Info, Audit, Guidebook, Preview, history/export/folder opening and absence of authoring actions in both themes.
- Use an identified publisher fixture with explicit allowed permission to fork, cancel, confirm, edit, rename, increment versions, export/import and restore; verify original credits and separate creator remain visible after restart.
- Check forbidden and unspecified explanations, official source v3→v4 update, existing fork independence and old-device override/history remnants without migration or deletion.
- Exercise file-backed audio, platform folder launching, keyboard/back navigation, narrow desktop windows, Version/Build and Alpha reminder display on a native candidate.

Known limitations/risks:

1. The documented pre-existing analyzer findings and missing `hello.webp` validator issue remain; neither was hidden or repaired outside scope.
2. External publisher authenticity remains unverified; checksum integrity does not prove authorship. This is the preserved Build 225 trust model.
3. No bundled course currently grants explicit derivative permission. Enabling one requires a publisher-approved licensing decision; none was invented.
4. The intentional clean cut makes old official local edits unavailable in runtime/history. Their physical data remain, with no migration/recovery workflow added.
5. Existing external audio paths retain their file references; publisher JSON updates do not rewrite those bytes. Custom audio deletion removes references, not source files. Files modified or removed outside QQL retain the existing media-availability risk; backups verify their own copies.
6. Native Windows validation remains outstanding. No 226.01 Windows release build/package was created; the final Windows test-candidate build belongs to the deferred 226.08 requirements.
7. Final approval/release timing should be checked against the recorded September 5 candidate date before distribution if it is delayed.

No unresolved implementation or schema design question blocks 226.01. A future decision to grant bundled derivative permission and native validation remain user/publisher decisions, not assumed approval here.

No commit, amend, push, package, release or 226.02 implementation has been performed. The index is empty of staged changes. Stop for explicit approval.

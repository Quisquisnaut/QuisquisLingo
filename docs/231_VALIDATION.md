# QQL 231 Validation

## Revision 1

### Release identity and boundary

QQL 231 revision 1 is Version `2.0.31+2311`, display Build 231.1, Revision 1 and technical build 2311. Phase remains 231 and Course Model remains v7. The repository's required version-update lifecycle policy refreshes the established 30-day Alpha expiry to `2026-10-13 23:59:59` local time.

The revision changes no Course Model field, JSON/checksum rule, ownership rule, Search matching rule, learner progression, XP, Review, Duel or activity behavior. It retains the complete QQL 231 revision-0 implementation and corrects only Course Editor access/presentation semantics plus one Create Duels sentence.

### Four access states and Exercise presentation

- The Course Editor root now owns four explicit persisted states: **Locked** (closed lock), **View only** (eye), **Inspection mode** (code `</>`) and **Edit** (pencil). Lower hierarchy pages retain the QQL 231 Search/Help/IDs app-bar organization and do not regain an access icon.
- **Locked** keeps the root visible, rejects hierarchy entry and exposes no Search.
- **View only** is the fresh default. It opens the ordinary preset-specific Exercise form used by Edit, but text fields, selectors, toggles, image operations, answer expansion, add/remove/reorder operations, Script Recognition controls and Save actions are disabled. Help and Preview remain available.
- **Inspection mode** is always read-only and opens Exercises in their technical representation by default, whether reached directly or through Search. Turning the local Inspection toggle off shows the ordinary form read-only.
- **Edit** retains the ordinary editable form only for a user whose existing `CourseAccessPolicy` grants edit permission. Turning local Inspection on changes presentation only; turning it off restores the same unsaved controller values and dirty state.
- The bottom **Inspection** toggle never changes or persists the root state, grants authorization, saves/discards content or marks content dirty. Preview likewise stays no-write.
- Search remains unchanged in scope, matching, type filtering and authoritative 22-preset searchable-field mapping. A result opens the normal read-only form in View only, technical inspection in Inspection mode and the normal editable form in Edit.

### Permissions, notices and dirty state

- Individual Owners and all members of an owning Team retain Edit regardless of Team Lead status. Official originals and outsiders cannot select Edit; View only and Inspection mode remain read-only. Fork licensing never grants mutation of the original.
- The one-time View-only explanation retains per opaque user ID × Course ID persistence. Settings → Show one-time notices again resets it without changing the stored access state.
- Merely opening View only or Inspection, toggling the local Inspection presentation, Previewing or navigating read-only creates no dirty state. Legitimate unsaved Exercise edits survive an Inspection round trip and retain the existing Exercise leave guard.
- Switching from Edit to View only, Inspection mode or Locked while the course working copy differs from its baseline invokes the authoritative course-level confirmation dialog. Keep editing leaves the state in Edit; Cancel course changes restores the baseline before switching; Confirm course changes performs the existing verified transaction before switching.
- Create Duels guidance now says `without completing the preceding Lesson`; Duel eligibility, completion and unlock behavior are unchanged.

### Focused revision-1 evidence

| Check | Result |
| --- | --- |
| Combined revision/UI/Search/metadata/Alpha/audit report focused suite | Passed: 34 tests. |
| `flutter analyze --no-pub` after the integrated revision slice | Passed: no issues found. |

### Final revision-1 verification

| Check | Result |
| --- | --- |
| Focused `qql_231_revision1_test.dart`, Course Editor UI and Search suite | Passed: 22 tests; process exit code 0. |
| Complete `flutter test --no-pub --reporter compact --timeout 60s` suite | Passed: 1,378 tests; process exit code 0. |
| Final `flutter analyze --no-pub` | Passed: no issues found in 18.3 seconds. |
| `flutter build windows --release --no-pub` | Passed in 357.6 seconds; produced `build/windows/x64/runner/Release/quisquislingo_app.exe`. |
| Linux native release build | Not runnable on this validation host: the Windows Subsystem for Linux optional component is unavailable, Docker and Podman are absent, and the repository has no configured Linux workflow. No Linux-build success is claimed. |
| `git diff --check` | Passed; only LF-to-CRLF working-copy notices were reported. |

## Revision 0 historical validation

### Release identity and boundary

QQL 231 is Version `2.0.31+231`, Build 231, Revision 0. It is a Course Editor usability/productivity release on the completed QQL 230 baseline.

The release changes no Course Model field or parser rule. `formatVersion: 7`, custom ownership, official provenance, course JSON/checksums, learner identity, progression, XP, Review, Duel and activity behavior remain unchanged. The Alpha expiry is `2026-10-12 23:59:59` local time under the established policy.

### Delivered behavior

- Lessons searches the whole Course; Lesson and Rounds search their current Lesson; Round searches its current Round. There is no separate Lesson filter.
- Search matches complete words and contiguous word sequences with case and diacritics ignored. Exercise IDs match exactly or partially and case-insensitively. Exercise Type defaults to All exercise types.
- Every result shows Lesson, numbered Round/title, friendly Exercise type and a matching excerpt. Exercise ID follows the shared Show/Hide IDs preference. Selection opens the exact Exercise.
- `ExerciseSearchRegistry` is the single searchable-authored-text definition for all 22 supported presets. The complete inventory is in [EXERCISE_TYPE_INVENTORY_231.md](EXERCISE_TYPE_INVENTORY_231.md).
- Course Editor root owns Locked / View unlocked / Edit unlocked. Fresh state defaults View. Locked blocks hierarchy entry. View permits navigation, Search, Help, IDs, Preview and Audit without authoring. Edit remains subordinate to `CourseAccessPolicy`.
- The View explanation is dismissed per opaque user ID × Course ID. Settings → Show one-time notices again resets that active-user notice and does not reset Course Editor mode.
- App bars follow the cross-cutting rule: Course Editor has Lock/Help/IDs; Lessons, Lesson, Rounds and Round have Search/Help/IDs.
- Lesson retains Rename and Generate Rounds from GuideBook as body actions without duplicate app-bar icons. Round gains a Rename Round body action and moves Preview before Save as draft / Save in its bottom action area.

### Compatibility decisions

- The former two-state `course_editor_locked_<COURSE>` value is read only as a compatibility fallback: `true` maps to Locked and `false` maps to the former editable behavior. Fresh courses have no legacy value and default to View unlocked. New three-state persistence is per user × Course.
- Search reads canonical authored Exercise data and never writes Course or learner state. Assets, item/reference IDs, correct indexes, timestamps, normalization flags and feedback configuration are excluded.
- View mode reuses the ordinary four-page hierarchy but routes Exercise selection to the established canonical read-only inspector and no-progress Preview.
- License continues to govern outsider Fork eligibility only; it never enables Edit on the original. Team membership continues to grant the existing edit right regardless of Team Lead status.

### Focused evidence

| Check | Result |
| --- | --- |
| `flutter test --no-pub --reporter expanded --timeout 60s test/qql_231_search_service_test.dart` | Passed: inventory coverage, searchable/excluded fields, matching, ID, type and structural scopes. |
| `flutter test --no-pub --reporter expanded --timeout 60s test/qql_231_course_editor_ui_test.dart` | Passed: per-user/course notice and reset isolation, default View Search/direct navigation, Locked rejection, unauthorized Edit denial, icon/action normalization, View Preview and Team membership policy. |
| `flutter analyze --no-pub` | Passed after the integrated Search/lock/UI slice: no issues. A final post-release run is recorded below. |

### Final verification

| Check | Result |
| --- | --- |
| Complete `flutter test --no-pub` suite with a JSON file reporter | Passed: 1,526 successful tests; process exit code 0. |
| Final `flutter analyze --no-pub` | Passed: no issues found. |
| `flutter build windows --release --no-pub` | Passed after closing the running prior build that held the output executable open. Produced `build/windows/x64/runner/Release/quisquislingo_app.exe`. |
| Linux native release build | Not runnable on this validation host: WSL has no installed distribution, no Docker/Podman runtime is available, and the repository has no configured Linux CI workflow. No Linux-build success is claimed. |
| `git diff --check` | Passed; only the repository's existing LF-to-CRLF working-copy warnings were reported. |

The first Windows build attempt reached the linker but correctly failed with `LNK1104` because an already-running QuisquisLingo process held the destination executable open. After that process was explicitly closed, the same release-build command completed successfully. This was an environment lock rather than a source or toolchain defect.

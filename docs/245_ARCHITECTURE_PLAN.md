# QQL 245 — architecture audit and extraction plan

Status: **approved for staged implementation** on 2026-09-22 against
`2.0.44+244007` (commit `2d40d81`). The user requested a version bump,
handoff and commit at the end of each revision.

## Intent and boundary

Make large workflows easier to understand, change, and recover after failure.
First define who owns state, rules, persistence, and cleanup. Extract code only
after a boundary has a behavioral contract. File size is a signal, not an
acceptance criterion. Keep QQL as one Flutter package and retain the current
tree as the baseline. Preserve Course Model v11, stored data and keys, package
and signature formats, IDs, authoring rights, scoring, progression, user-visible
behavior, and the single confirmed Course save boundary.

This is a staged structural release. A suspected defect found during the audit
gets a reproducing test and its own explicitly reviewed behavior correction;
it is not silently repaired during an extraction.

## Audit evidence

The `lib` tree has 203 Dart files and 75,275 physical lines. Its six largest
files contain 26,271 lines (34.9%). Counts include blank lines and are a
snapshot, not targets.

| File | Lines | Responsibilities observed |
| --- | ---: | --- |
| `screens/course_editor_screen.dart` | 11,160 | Course transaction UI, metadata form, hierarchy editors, generator, Audit view, Exercise form, Audio Library. Public screen classes start at lines 476, 3032, 3741, 4175, 5333, 5748, 6340, 7555, 7957, 8170, and 10720. |
| `screens/home_screen.dart` | 3,942 | Learner loading, profile actions, Course switching, access/navigation, Lesson scrolling, path presentation. `_reload` starts at line 485. |
| `models/course_models.dart` | 3,519 | Course Model v11 values, validation and JSON codecs. `Course` starts at line 785; `Exercise` at 2774. |
| `screens/round_screen.dart` | 2,940 | Round queue, review transition, answer UI, audio lifecycle, completion dispatch. `_next` starts at line 1041. |
| `screens/course_projects_screen.dart` | 2,583 | Course creation, merge, import, management and package lifetime. Import starts near line 1978. |
| `screens/flat_image_library_screen.dart` | 2,127 | Catalog presentation, import, metadata, Course image mutation and preview. |

The problem is mixed ownership within those workflows, not simply the number
of classes in one file. For example, `CourseEditorTransaction` already owns the
working Course and dirty comparison, but nested editor screens return whole
Course values and the top-level widget reconciles them (`course_editor_screen.dart`
lines 539–600, 673–686). `RoundScreen` already delegates answer evaluation and
completion to services, but owns queue/review state, audio generations, and
rendering together (`round_screen.dart` lines 105–161, 258–538, 1041–1221).

Existing boundaries worth retaining:

* `CourseEditorTransaction` holds the sole in-memory working copy; the
  `CourseEditorService.confirmCourseTransaction` path checks authorization and
  stale state, creates a backup, writes, reads back, then cleans unused media
  (`course_editor_transaction.dart` lines 6–56;
  `course_editor_service.dart` lines 647–788).
* `AnswerEngine`, `LearningCompletionService`, `CourseImageUsage`,
  `CourseImageRemoval`, `CourseLibraryPresentation`, `BoundedZipReader`, and
  `ImageValidator` already centralize important rules. Retain these authorities
  rather than cloning their logic in a new controller.
* `CourseFileStore.readReadable` and `readAll` deliberately serve different
  safety needs: listing may skip unreadable Courses; decisions that could
  delete data must refuse an incomplete snapshot (`course_file_store.dart`
  lines 84–103).

## Target logical architecture

Define ownership before changing file placement. The middle row below is a
possible seam, not a requirement to introduce a coordinator for every screen:

```text
Screens and widgets
  -> existing workflow/session owner, when state or side effects need one
    -> pure domain policies and Course Model v11
    -> storage, media, import, audio and platform adapters
```

Dependencies should point inward. A screen may format and render a result; it
should not independently decide Course identity, publication, XP, file
ownership, or rollback. A domain rule should not depend on a widget or a
platform service. Keep existing public screen and service entry points as
facades while callers migrate. Introduce a new owner only where it removes a
real duplicated decision or isolates a side effect; reject pass-through
coordinators. Do not add a second global state system or a second Course
representation.

| Boundary | One owner and contract | Keep out of it |
| --- | --- | --- |
| Course authoring session | One working Course, dirty state, permitted update, audit invalidation, cancel, and final confirm result. Nested editors return an explicit draft update; top-level confirmation remains the only persistence action. | Direct nested writes, duplicate publication reconciliation, UI-owned provenance rules. |
| Learner session | Load/switch learner and Course, derive current Lesson access, and publish a snapshot guarded by the current request generation. | Path painting and profile administration dialogs. |
| Round attempt | Pure queue, first-pass error, answer/review and finish transitions; completion is dispatched once through `LearningCompletionService`. | Widget controllers, platform audio handles, and direct XP formulas. |
| Course storage workflow | Intent-specific create/update/delete/confirm operations over per-Course files, with explicit stale-write and recovery behavior. | Whole-store-map semantics at call sites. |
| Media/import workflow | One owner for staging lifetime, validation, provenance, commit/rollback, and cleanup timing; authoritative image traversal is `CourseImageUsage`. | Duplicate image walkers or cleanup based on a partial Course list. |
| Audit | One public `CourseAuditService` result and registry; internally group pure Course/Lesson/Round/Exercise rules. Preserve issue code, severity, order, and location. | UI-specific rule copies. |
| Course Model | One v11 wire contract and canonical values. Build compatibility is an application policy at a later, separately characterized boundary. | UI imports and a mass model/codec move. |

For every boundary, record inputs, output or error, side effects, cancellation,
and the owner of every mutable field before extracting anything. Keep async
generation tokens where they prevent stale results from reaching the UI:
Home's reload and flag-transition generations (`home_screen.dart` lines
253–256, 485–736) and Round's prepared-audio generation
(`round_screen.dart` lines 125–130, 551–624).

## Findings requiring a separate proof

1. **Course save map bridge.** `_loadKey` reads all readable Course records;
   `_saveKey` reads them again, compares serialized entries, and removes IDs
   absent from its input (`course_editor_service.dart` lines 146–165). A
   single-Course save therefore has whole-store work and ambiguous update vs
   delete intent. A stale concurrent snapshot appears capable of removing a
   newly added Course; this is an inference, not a reproduced defect. Test
   interleavings before changing persistence. Then introduce per-Course
   commands and an explicit compare-and-swap or serialized commit under the
   current `CourseEditorService` facade.
2. **Image provenance traversal.** Package manifest generation scans only
   Round Exercise prompt elements (`course_package_service.dart` lines
   507–536). `CourseImageUsage` covers GuideBook, presentation, answer-item,
   layout and cover uses (`course_image_usage.dart` lines 25–105), and
   `CourseMediaStore.referencesOf` already delegates to it. Establish whether
   provenance in these other locations produces a missing manifest entry.
   If so, correct it as a separate behavior change with a fixture, then use
   the shared walker. Preserve manifest ordering and compatibility deliberately.
3. **Dependency direction.** The model reads `AppMetadata.buildNumber`
   (`course_models.dart` lines 5, 799–800, 1139–1157), and
   `CourseFileStore` imports backup code for filename sanitization
   (`course_file_store.dart` lines 6, 73–78). These are small but inverted
   dependencies. Characterize their exact behavior before moving policy to a
   lower-level owner; do not alter v11 acceptance or existing paths.
4. **Source-layout tests.** `course_editor_layout_regression_test.dart`
   lines 32–69 and 226–247 read source substrings and class placement. They
   will fail on a harmless extraction. Replace their intent with behavioral
   layout/navigation tests before moving the corresponding code.

## QQL 245 revision plan

Build 245 is an **authoring architecture** release. Version starts at
`2.0.45+245000`; each completed revision increments the build suffix and
`AppMetadata.correctiveRevision` by one. Recompute the 30-day Beta expiry
from that revision's actual release date. Each revision updates
`docs/245_CHANGE_SUMMARY.md`, `docs/245_VALIDATION.md`,
`docs/245_HANDOFF.md`, README, CHANGELOG, AGENTS, version tests and metadata,
then ends in one local commit. The handoff records the tested state, known
risks, exact next step and the commit as "this commit" until the hash is
available. The unrelated untracked `devtools_options.yaml` is never staged.

A revision is an architectural change only when a rule or side effect gains a
single identifiable owner and its caller can use a defined input/output
contract. Moving a screen class unchanged to another file does not qualify.
Existing public routes and service facades stay compatible while ownership
changes. Separate intentional behavior fixes from these structural commits.

| Revision | Owner change and resulting code | Required evidence before its commit |
| --- | --- | --- |
| **0 — Course Info update** | Introduce a typed `CourseInfoChange` and one `CourseInfoUpdateService.apply` operation. It owns the order of Team assignment and Maintainer transfer, optional-field omission, and construction of the updated Course. The dialog keeps only form/interaction state and stages the result through the existing transaction. New owner: `lib/services/course_info_update_service.dart`; modify `course_editor_screen.dart`. | First characterize untouched nested metadata and cancel/confirm through the production route. Test cleared optional fields, unchanged unrelated fields, governance change and rejection, then run focused editor and governance suites, analyzer and validators. |
| **1 — authoring session** | Introduce one non-UI session owner that composes `CourseEditorTransaction` and the canonical publication reconciler. Move top-level draft adoption, dirty/audit-freshness state and confirm/cancel coordination out of widget state, without adding another working Course or write path. Preserve every `previous` snapshot passed to reconciliation. | Session tests for apply/restore/cancel/audit invalidation and production-route tests for nested save, failed confirm, backup and version. |
| **2 — hierarchy mutations** | Give Lesson, Round and Exercise edits typed update commands. The top-level session remains the only working Course owner; nested widgets retain transient form and navigation state. Move whole-Course reconstruction and Content-wrapper rules to the typed command service while retaining existing route callbacks and reconciliation until their `previous` semantics are characterized. Keep standalone public editor entry points functional. | Traverse Course → Lesson → Round → Exercise with nondefault `LearningContent.required`, `sourceRefs`, icons, presentation and GuideBook data; compare before/after JSON and Draft/Audit behavior. |
| **3 — canonical route propagation and presentation** | Pass one authoritative Course updater through the integrated nested editor routes. Each accepted update reconciles once through the session, with the exact prior Course (or no prior Course where that is the existing rule). Keep standalone routes on their compatible callback path. Deduplicate live callbacks versus pop results, then compose cohesive route views only after this contract is verified; a file move alone does not qualify. Keep `course_editor_screen.dart` as a compatibility entry point. | Test integrated and standalone routes, Draft promotion, transfer, pending Lesson metadata, pop deduplication, navigation keys, unsaved-change guards, narrow layouts, Preview and no-write cancellation. Replace source-location assertions before moving a route. |
| **4 — Course storage commands** | Retire the whole-store map bridge under `CourseEditorService` in favor of intent-specific per-Course create/update/delete operations. Preserve the facade, authorization, stale-edit rejection, backup-before-write, readback and media cleanup order. | Reproduce stale-snapshot interleavings first; test unreadable/duplicate-ID files, write failure and recovery, concurrent create/update/delete, strict versus readable listing, backups and media retention. |

Revision 0 is the first implementation step. Revisions 1–4 are ordered,
independently reviewable changes. If a required contract cannot be preserved,
record the finding in that revision's handoff and resolve it before committing
or incrementing the revision. Round play, Home, Course Model and Audit are
separate later builds; they are not bundled into QQL 245 because their state
and persistence contracts differ from Course authoring.

### Resulting file architecture

The planned files reflect owners, not a screen-by-screen partition:

```text
lib/screens/course_editor_screen.dart             route composition and dialogs
lib/services/course_info_update_service.dart      Course Info command/application
lib/services/course_authoring_session.dart        one authoring session and update path
lib/services/course_editor_transaction.dart       one working Course and dirty comparison
lib/services/provisional_publication_service.dart canonical Draft reconciliation
lib/services/course_editor_service.dart           confirmation facade and persistence
lib/services/course_file_store.dart                per-Course storage adapter
```

Other UI files are named only when a whole route has a stable contract. An
`exercise_editor_screen.dart` that still reconstructs a Course and decides
publication would be a physical split, so Revision 3 must not create it.
The current 11,160-line file should shrink as decisions leave it, but no line
count is a release gate.

## Verification and release gate

For each extraction, run the affected behavior tests before and after and
inspect the diff for unintended JSON, key, route, text, error, or side-effect
changes. Relevant existing suites include
`production_course_transaction_225_04_test.dart`,
`course_editor_transaction_225_04_test.dart`,
`learning_completion_service_test.dart`,
`round_xp_completion_regression_test.dart`,
`import_route_matrix_revision19_test.dart`, `course_media_243_test.dart`,
and the Build 244 Course Library suites. A green isolated test is not proof of
the production navigation path.

Before calling QQL 245 validated: format touched Dart files; run focused
tests, full `flutter analyze`, one full `flutter test --no-pub`, the four Course,
image, Lesson-icon and media asset validators, and `git diff --check`. Check
Course Model v11 round-trip, package/signature bytes where touched, Audit
issue output where touched, backup/recovery ordering, and absence of writes in
preview/cancel paths. Perform a manual device smoke check before release; it
was still outstanding at the end of Build 244 (`244_VALIDATION.md` lines 5–18).

## Execution record

Track the revision currently in progress, its fresh checks and the next
dependency in `docs/245_HANDOFF.md`. A revision is committed only after its
own tests, version checks and handoff are written. The final Build 245 gate
is run on the integrated tree, not inferred from earlier revision results.

# Build 241 Revision 2 — complete change summary

Version: **2.0.41+241002**. Beta expiry: **2026-10-20 23:59:59 local**.

This summary covers the integrated changes since Build 240 (`338dbab`), including
the interrupted Claude session saved in `15da081` and the subsequent completion
in `919c341`. Attribution to Claude follows the owner's handoff and the WIP diff;
it does not replace the Git authorship records. Both implementation commits are
preserved in the history of `main`.

## Work introduced in the Claude WIP

- **Course file storage:** introduced `CourseFileStore` and its ten initial tests.
  Custom and installed external courses use individual JSON files below
  application support, in `qql_courses_v1/custom` and
  `qql_courses_v1/external_official`. Wired CourseEditorService to the store and
  made maintainer checks asynchronous, including their ProfileService caller.
  The directory's `v1` identifies the storage layout, not the course model.
- **Android backup policy:** corrected the application label/round-icon manifest
  declaration and added backup rules for older and newer Android versions.
  Platform cloud backup excludes the large imported image-bank, exercise-image
  and audio directories; device transfer retains them. App data and credential
  verifiers remain covered by the platform policy. This adds no QQL cloud server.
- **Learner restore:** preserves existing local Access PIN and Recovery Key
  credentials when replacing the learner preference namespace. Exported learner
  backups still exclude these credentials and do not supply replacement secrets.
- **TTS process handling:** separates Linux espeak options from spoken text with
  `--`; prefers the Windows system PowerShell executable before the fallback.
  Added process-argument regression tests and matching platform stubs.
- **Image validation:** reads encoded dimensions for course flags and exercise
  images without first rasterizing the entire source, checks Lesson icon
  dimensions before decoding, and checks image-bank limits against actual
  inflated bytes as well as declared archive sizes. Added forged-image and
  misleading-size regression fixtures. These checks are not a claim that every
  possible resource-exhaustion archive is prevented.
- **Export audit notices:** Course Editor, Course Manager and Version History
  exports explain outstanding errors/warnings. Export remains possible for work
  in progress; the notice explains when import will reject the result.
- **Help and App Info:** extracted content and added English/Italian language
  controls and translation tests, including backup/security explanations.
  Credits no longer hardcode the number of AI-Slop demo courses.
- **Test lifecycle:** added an injectable Beta clock and a stable test clock so
  tests do not expire merely because the calendar advances.
- **Supporting material:** added the code-audit report, security/robustness notes,
  an Italian Pick the translation demo JSON, diagnostic test output and ignore
  rules for Java keystores.

The WIP was not a passing release: the handoff identified obsolete constructor
arguments and filesystem/plugin-dependent failures. The validation below applies
to the completed implementation, not to that checkpoint.

## Completion of storage and tests

- Updated tests using the removed `preferenceWriter` constructor argument and
  retained persistence-failure coverage through file-write injection.
- Isolated support/document directories in filesystem-dependent tests; awaited
  actual saves or observable UI states, including real I/O outside fake-async
  execution. Cleared test asset caches to avoid cross-test pending futures.
  No indiscriminate timeout increases or blanket `pumpAndSettle()` substitutions.
- Aligned AppResetService and InventoryService with physical course files,
  including malformed/interrupted files, real paths, sizes and modification
  times. Updated the storage inventory and reset documentation.
- Retired course preference blobs are not read or migrated into the new store.
  Existing Course Models v9/v10 remain in use; no v11 migration was introduced.

## Signed Publisher Courses

- Added Ed25519 verification against a bundled trusted-publisher registry.
  Verification checks publisher/key identity, key status, canonical content
  checksum and signature. A serialized verification flag is not trusted.
- Applied verification to import/install and reassessment of stored sources and
  backups. Unsigned or untrusted external files cannot be accepted as Publisher
  Courses. Unverifiable stored courses retain their files/progress, are read-only
  and show **Verification required**, and are excluded from learner delivery.
- Signed updates require the same course/publisher identity and a newer version;
  previous versions are backed up. Forking remains subject to verification and
  the course license. External imports cannot impersonate bundled courses.
- User-facing **Publisher Course** replaces Official External; the internal
  `externalOfficial`/`external_official` identifiers remain stable.
- Added `tools/sign_course.dart` prepare/attach tooling and an English guide for
  publishers and registry approval, also linked as technical Editor Help.
  Private production keys need not be passed to this Dart tool.
- Added a Dummy publisher, public test-only key material and signed v1/v2
  fixtures. Dummy trust requires `--dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true`,
  including for release-mode test builds; normal builds reject Dummy. The
  enabled configuration displays a test-only warning. No production publisher
  approval is implied by these fixtures.
- Signature coverage is normalized course JSON, including embedded bytes, not
  separately supplied media files. Registry revocation requires an app registry
  update. Binary fixture Git attributes prevent Windows newline conversion.
- Updated the English/Italian Course Types comparison to three course categories
  with four readable columns and smaller table text.

## Personal course libraries and shared device courses

- Added per-profile **My courses** membership. **Remove from my courses** removes
  a course from that profile's Selector and Manager without deleting the shared
  course file. Adding it again does not grant editing rights.
- Removal optionally resets only the active profile's progress for that course.
  Confirmation and Help explicitly preserve all XP, including Weekly XP and XP
  previously earned in that course, total/per-language study days and streak.
  Other profiles and existing backups are unaffected.
- Physical Publisher Course removal is admin-only and blocked while any other
  profile includes the course. Progress, media and backups remain available for
  future reinstallation; removing personal membership is a separate action.
- Added **Available on this device**, with dedicated Help and four alphabetical
  sections: Bundled Courses, Publisher Courses, My Custom Courses and Other
  Custom Courses. Rows include Maintainer and Add/Added/Remove controls.
- Course titles are bold: bundled black in light mode and white on black in dark
  mode, Publisher purple, Custom orange. Blocking states such as Not published,
  Draft and Verification required have blue outlined labels. Narrow layouts put
  controls below metadata; 320 px light/dark layouts are covered by tests.
- Removed Hide/Unhide and associated Help/API references. Old hidden preferences
  are ignored rather than converted into personal removals.

## Navigation and empty-library behavior

- Course Selector can open Import Course directly and return to study without
  enabling or redirecting to Course Manager. Authoring actions remain gated;
  import collision checks inspect all installed courses.
- New course creation uses **Continue to Editor**, making the subsequent
  confirmation of edits understandable.
- A personal library containing only eligible Publisher or Custom courses works
  normally. An empty library shows My courses without an arbitrary course flag,
  keeps Settings and enabled Course Manager accessible, and offers device
  discovery. The discovery and Manager buttons have a 12 px gap.
- Settings, Profile, Avatar, User Data, Audio and administration navigation
  support no current course. Course-specific reset/voice testing requires a
  selected course. Removed courses are not silently re-added.
- The saved device name is reflected immediately before course reload finishes.

## Validation and delivery limits

- Full Flutter suite: **1,879 passed, zero failures**, exit 0.
- After the final Publisher pink-to-purple change: **8 focused course-library
  tests passed**. The owner explicitly waived repeating the successful full
  suite for this presentation-only change.
- Final full static analysis: **No issues found**. Dependency resolution and
  whitespace checks passed.
- Validators passed: 10 bundled courses, 111 image-bank assets, 443 media files
  and 14 Lesson icons. Media checks included 19 locked audio files, 281 flags
  and 22 static references.
- Explicit Dummy-enabled verification passed 28 overlapping focused tests; this
  is not an additional unique full-suite count. OpenSSL independently verified
  the checked-in signing fixture.
- No platform release executable/installer was generated. Manual device checks
  are documented, not claimed as executed. This follow-up summary changes only
  documentation and does not require repeating Flutter tests.

See [validation evidence](241_VALIDATION.md), the
[Italian visual checklist](241_REVISION_2_VISUAL_CHECKLIST_IT.md), the
[publisher signing guide](PUBLISHER_SIGNING_GUIDE.md) and the
[storage/reset inventory](239_RESET_STORAGE_INVENTORY.md).

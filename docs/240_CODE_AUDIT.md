# QQL 240 full code audit

Independent audit of the QuisquisLingo source tree at commit `338dbab`
(version 2.0.40+240000, Build 240 Revision 0, Course Model v9/v10).

Scope: safety, vulnerabilities, robustness, resilience to regressions, ease of
maintenance and edge cases across `lib/`, `test/`, `android/`, `tools/` and the
build configuration. This is a static review plus a full analyzer and test run.
It cannot prove the absence of defects.

## Verification performed

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | **No issues found** (20.6 s) |
| `flutter test --no-pub` | **1809 / 1809 passed** (10 m 42 s) |
| Source size | 169 Dart files, 64,490 lines in `lib/` |
| Test size | 202 files, 68,517 lines (1.06 test lines per source line) |
| `TODO` / `FIXME` / `HACK` markers | 0 |

---

## 1. Summary judgement

The codebase is in unusually good shape for a solo-authored prototype of this
size. Input validation, transactional storage writes, process execution and the
single network feature are all deliberately hardened, and the documentation is
honest about what is and is not a security boundary. The test-to-source ratio is
above 1:1 and the whole suite is green.

The weaknesses are concentrated in three places, none of which is a flaw in the
Dart logic:

1. **Release engineering** — the Android manifest was malformed and silently
   dropping attributes; that is fixed. The rest is now a set of explicit
   decisions rather than defaults: backup scope is documented and deliberate
   (S1), release signing stays on the scaffold's debug key until Play enrolment
   (S2, with a tester data-export step owed before that switch), and automated
   CI is declined in favour of the existing `AGENTS.md` local-validation rule
   (R1, accepting ungated merges and Windows-only test coverage). Verification
   therefore rests entirely on that discipline being followed.
2. **Type identity** — an exercise type is a bare string dispatched across 8
   files, so the compiler cannot help when one is added or changed. The manual
   checklist in `NEW_EXERCISE_TYPE_CHECKLIST.md` exists to cover that gap.
3. **Concurrency** — every expensive operation (10 MB JSON, 50 MB ZIP, SHA-256,
   image decode) runs on the UI isolate.

A separate, time-sensitive item: the Beta expiry constant is **2026-10-19**,
which will also break a large part of the test suite (section 3.2).

---

## 2. Security findings

### S1 — Android backup scope (Accepted decision, resolved)

**Originally raised as High. The owner reviewed it and decided to keep backup
enabled. That decision is recorded here, with its reasoning, so it is not
re-raised as a finding by the next reader.**

The audit observed that the manifest set neither `android:allowBackup` nor any
extraction rules, so Android Auto Backup defaulted to **on** and copied
`shared_prefs` — every learner profile, all progress, the Access PIN verifier
and the User Recovery Key secret — to the user's Google Drive. The finding was
that this contradicted the README's "All learner data remains on-device".

The finding was half right. The documentation was wrong, but the behaviour was
not: the audit had treated the backup as an accident and assumed the fix was to
disable it. Two facts change the conclusion.

**QuisquisLingo has no server.** Auto Backup is the only mechanism by which a
learner survives a lost or replaced phone. Disabling it would mean that losing
the device always costs every streak, every completed Lesson and every locally
authored Course. For an offline learning app with no account, that is a worse
outcome than the exposure it would prevent.

**The Access PIN is not a security boundary.** It is a casual-access guard for a
shared family device: four digits behind one salted SHA-256 pass, which does not
resist anyone with file access, and which this document has never claimed
otherwise (see S6). Excluding it from backup would not make it stronger — it
would only mean a restored learner silently loses their PIN. The same holds for
the User Recovery Key credential, which *is* the learner's stable identity;
restoring it is the point of the backup.

There is a real constraint, but it is capacity rather than privacy. Android's
Auto Backup quota is **25 MB per app**, and an app that exceeds it does not get
a partial backup — the platform silently stops backing that app up at all. A
single Image Bank import is capped at 50 MB, so one import would quietly cost
the learner every backup of their progress, with no warning. Bulk media is
re-importable from the user's own files; progress is not.

**Resolution as shipped.** Backup stays on, and only the three bulk-media folders
are excluded from *cloud* backup:

| Excluded from cloud backup | Reason |
| --- | --- |
| `image_banks/` | 25 MB Auto Backup quota |
| `exercise_images/` | 25 MB Auto Backup quota |
| `quisquislingo_audio/` | 25 MB Auto Backup quota; recorded MP3s are unbounded |

These are the folders `AppResetService` already treats as bulk media
(`_imageFolders`, `_audioFolders`). They sit under
`getApplicationSupportDirectory()`, which is `getFilesDir()` on Android, hence
`domain="file"`.

Device-to-device transfer is deliberately **not** restricted — it carries no
quota, so a phone-to-phone migration takes the media too. `<device-transfer>` is
therefore omitted from the rules file rather than left empty.

Two resource files carry this, and they must change together, because
`android:dataExtractionRules` is ignored below API 31:

- `res/xml/data_extraction_rules.xml` — API 31 and above
- `res/xml/backup_rules.xml` — API 30 and below

**What remained to fix was the documentation, not the manifest.** The README
claim has been corrected to describe what is actually backed up and why, and
`docs/SECURITY_AND_ROBUSTNESS.md` now carries an *Android device backup* section
recording this decision. A residual, accepted consequence: a user who deletes
local data with a Device Administration reset may still have it in a backup
Android took earlier, which no app-side reset can reach.

### S2 — Android release signing (Deferred to Play enrolment)

**Originally raised as High, and briefly implemented. The owner reverted it and
deferred release signing to Play Store enrolment. The finding stands; only its
timing has changed.**

`android/app/build.gradle.kts` remains the unmodified Flutter scaffold:

    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }

The technical observation is unchanged: a debug-signed APK cannot be uploaded to
Play, the debug keystore password is public so it carries no integrity
guarantee, and the debug key is per-machine, so a build made on a second machine
cannot update an install from the first.

**Why deferral is reasonable here.** Distribution is currently a handful of debug
APKs to friends, which is exactly the case the debug key is for. Play App
Signing generates and custodies the app signing key during enrolment and walks
the developer through registering an upload key, so configuring one by hand now
would mostly be work to redo. Doing it later costs nothing extra **at Play
enrolment** — but it does cost the current testers something (below).

**The one-way door, which is the real reason this is worth writing down.** An
Android app's identity is its signing certificate, and it cannot be changed for
an already-installed app. When the first Play build arrives signed with a
different key, every existing tester install hits:

    INSTALL_FAILED_UPDATE_INCOMPATIBLE

The only route forward is uninstall and reinstall, and uninstalling clears the
app's data directory: **learner profiles, all progress, XP, streaks, Review
history, local Course edits and imported media are lost.**

Android's own backup does not rescue this. Auto Backup data is bound to the
signing certificate, and a restore onto an app signed with a different key is
rejected — so the backup enabled under S1 will not carry testers across this
transition. The two decisions interact, and neither is a substitute for the
other.

**Therefore, before the first Play-signed build ships:** tell every tester to
export their data first — `Export my data` / `Save to…` for the learner backup,
the User Recovery Key for their identity, and Course JSON export for any Course
they have authored — and confirm they have done it. That is a release-process
step, not a code change, and it is the part of this finding that has a deadline
attached even though the signing work does not.

**Remedy, when Play enrolment happens.** Enrol in Play App Signing, generate an
upload key, load it from `key.properties` (already git ignored by
`android/.gitignore`), and fail the release build when that file is missing
rather than silently falling back to debug.

### S3 — Windows TTS resolves `powershell.exe` through the process search path (Medium)

`lib/services/tts_windows_backend_io.dart:63` starts
`Process.start('powershell.exe', ...)` with a bare executable name. On Windows,
`CreateProcess` searches the application directory and (depending on
`SafeProcessSearchMode`) the current directory before `PATH`. A `powershell.exe`
dropped next to the QQL executable is therefore executed with the user's rights,
inheriting the full environment and the Base64 payload.

**Remedy.** Resolve through the system root:

    final system = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final candidates = <String>[
      '$system\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
      'powershell.exe', // last-resort fallback only
    ];

The same reasoning applies to the Linux backend's `PATH` scan
(`tts_linux_backend_io.dart:19`), though a writable early `PATH` entry is a
pre-existing compromise there rather than a new one.

### S4 — eSpeak argument injection through course text (Medium)

`lib/services/tts_linux_backend_io.dart:48` passes learner/course text as the
final argv element:

    await Process.run(command, ['-v', voice, '-s', '$wpm', '-w', wav.path, text]);

There is no shell, which the documentation correctly emphasises — but eSpeak
parses options with `getopt_long`, which scans *all* arguments. Course text
beginning with `-` is consumed as options. A line such as
`-w /home/user/.bashrc` makes eSpeak write a WAV over an arbitrary
user-writable path; `--stdin`, `--path` and friends are similarly reachable.
The text is author-controlled and arrives through untrusted course import.

**Remedy.** One token:

    await Process.run(command, ['-v', voice, '-s', '$wpm', '-w', wav.path, '--', text]);

Add a regression test that speaks a string starting with `-w`.

### S5 — Restoring a learner backup strips the Access PIN and Recovery Key (Medium)

`LearnerBackupService.restorePreservingIdentity(replaceExisting: true)` calls
`_replaceNamespace`, which is:

    await _removeNamespace(preferences, learnerProfileId);   // removes EVERY prefixed key
    await _writeNamespace(preferences, learnerProfileId, data); // skips sensitive suffixes

`_removeNamespace` deletes all keys under the learner prefix, including
`access_pin_verifier_v1` and `user_recovery_secret_v1`. `_writeNamespace` then
deliberately refuses to write those two suffixes back (correctly — they must not
be importable). The asymmetry means a restore **silently removes** the learner's
Access PIN and destroys the stable Recovery Key credential.

Two consequences: a PIN-protected learner can be un-protected by anyone able to
restore a backup for that ID, and the identity secret is lost with no warning.
No test covers this; `learner_profile_identity_test.dart` and
`qql_229_revision2_test.dart` exercise the restore but never assert credential
survival.

**Remedy.** Read the two sensitive values before `_removeNamespace` and write
them back after `_writeNamespace`, or have `_removeNamespace` accept a
`preserveSuffixes` set. Add a test asserting `hasAccessPin` is still true after
`restorePreservingIdentity(replaceExisting: true)`.

### S6 — Access PIN strength and the wording around it (Low–Medium)

`_writePinVerifier` uses a 16-byte `Random.secure()` salt and a **single**
SHA-256 pass over a **4-digit** PIN. The whole keyspace is 10,000 candidates, so
an attacker with the preferences file recovers the PIN in microseconds. There is
also no attempt throttling on `setActiveProfileById`.

The construction is reasonable for a local family-device gate, and the project
is right not to claim DRM. But `device_administration_screen.dart:146` tells the
user that destructive resets "are protected by your PIN", which reads as a
security boundary.

**Remedy.** Either soften the wording to describe it as an accidental-access
guard, or raise the cost: allow 6+ digits, use PBKDF2/scrypt with a real work
factor, and add a short backoff after repeated failures. Note that no local
scheme resists an attacker with file access — that limitation belongs in the
Help text.

### S7 — ZIP size guards trusted the archive's declared size (Low–Medium, fixed)

`ImageBankService.importBankZip` enforces `maxImageBytes` and
`maxTotalImageBytes` against `ArchiveFile.size`, which is the *header's* claimed
uncompressed size, and only then calls `source.readBytes()` to inflate. An
archive that understates `size` passes both guards and still decompresses its
real payload into memory.

**Confirmed exploitable before fixing.** A ZIP was built with a 200,000-byte
entry, then every declared uncompressed size, local and central, was patched
down to 500. `ZipDecoder` reported `size == 500` while `readBytes()` returned
the full 200,000 bytes: the decoder does not clamp inflation to the declared
size, so the guard could be walked straight past.

**Fixed.** The declared-size loop is retained as a cheap pre-flight that rejects
an obviously oversized bank before any directory is created, and is now
documented as non-authoritative. The real per-image and total limits are
enforced against `sourceBytes.length` after inflation, before each file is
written. `image_bank_service_test.dart` carries the regression, which fails
against the pre-fix code.

**Remedy as applied:**

    final sourceBytes = source.readBytes();
    if (sourceBytes == null || sourceBytes.length > maxImageBytes) {
      throw FormatException('Image asset exceeds the 50 KB maximum: $filename');
    }

and accumulate `totalImageBytes` from the actual lengths.

### S8 — Windows reserved device names pass the filename allowlist (Low)

The Image Bank filename check is `^[A-Za-z0-9._-]+$`, which accepts `CON.png`,
`NUL.jpg`, `AUX.webp`, `COM1.png` and `LPT1.png`. On Windows these still name
character devices even with an extension, so writing
`imagesDir\CON.png` does not produce the file the manifest then points at.

`ExerciseImageService._managedTarget` is not affected — it prefixes a
microsecond timestamp. Only the Image Bank writes the bare name.

**Remedy.** Reject the reserved stems, or apply the same timestamp prefix used
elsewhere.

### S9 — Untrusted images were decoded before their dimensions were checked (Medium, fixed)

**This finding originally listed five sites. Two of those were wrong, and the
correction is recorded here rather than quietly dropped.** Three sites were
genuinely affected and have been fixed.

The pattern was:

    codec = await ui.instantiateImageCodec(bytes);       // full-resolution raster
    final frame = await codec.getNextFrame();
    if (frame.image.width > maxSourceDimension) throw ...; // too late

A 50 KB PNG can legitimately decode to 30,000 x 30,000 x 4 bytes, roughly
3.6 GB, so the byte-size caps do not bound memory. The dimension check ran only
after the allocation that would fail.

**Genuinely affected, now fixed:**

| Site | What it needed |
| --- | --- |
| `exercise_image_service.dart` (`inspect`) | Only ever returned width, height and byte length, throwing the pixels away immediately — it never needed to rasterize at all. Now a descriptor read. |
| `course_flag_service.dart` | Rasterized only to learn width/height, disposed the image, then re-decoded correctly with `targetWidth`/`targetHeight`. The first decode is now a descriptor read; the second is unchanged. |
| `lesson_icon_service.dart` (`prepareIcon`) | Genuinely needs the decoded image for `canvas.drawImageRect`, so it still rasterizes — but the limit is now checked against the descriptor first, and `descriptor.instantiateCodec()` runs only after that check passes. |

**Incorrectly listed, no change needed:**

- `flag_background_palette_service.dart` already passes
  `targetWidth: 48, allowUpscaling: false`, so its raster is bounded to 48 px
  wide regardless of what the header declares.
- `course_entry_animation.dart` calls `instantiateImageCodec` purely as a
  decodability probe and disposes the codec without ever calling
  `getNextFrame()`. Creating a codec parses the header; it does not rasterize a
  frame, so nothing large is allocated.

The distinction the original finding missed is that `instantiateImageCodec` is
not itself the allocation — `getNextFrame()` is. A site is only exposed when it
reaches an *unbounded* frame, so a bounded `targetWidth` or an absent
`getNextFrame()` is already sufficient protection.

**Pattern applied**, from `portable_exercise_image.dart` which already did this
correctly: `ui.ImmutableBuffer.fromUint8List` → `ui.ImageDescriptor.encoded` →
check `descriptor.width`/`height` → only then instantiate a codec, with buffer,
descriptor and codec disposed in a `finally`. Each service keeps its own
dimension constant; they are deliberately not unified.

**Regression cover.** `test/support/forged_png.dart` builds a structurally valid
PNG whose IHDR declares 20000 x 20000 (width, height and chunk CRC rewritten)
while carrying only an 8 x 8 image's data. Rendering a real image that size to
test the guard would cost the very allocation the guard prevents. Both
`world_flag_course_226_04_test.dart` and `custom_lesson_icon_224_test.dart`
assert it is rejected with the dimension message, and both fail against the
pre-fix code.

### S10 — Imported courses can put an arbitrary host behind the support button (Low)

`Course.normalizeBuyACoffeeUrl` requires HTTPS with an authority but accepts any
host. `CourseInfoScreen._buyCoffee` then opens it in the external browser. A
third-party course file can therefore present an attacker-chosen destination
behind a trusted-looking "support the author" control.

**Remedy.** Display the host next to the button, or confirm the full URL before
launching. HTTPS-only is the right floor but is not the whole story.

### S11 — An unknown exercise type is echoed unbounded and unsanitized (Low, downgraded)

Found while assessing whether the proposed M1 enum could introduce an injection
path. It cannot — but this pre-existing behaviour sits in the same code path and
is worth fixing while that branch is being rewritten.

`Exercise.editorTemplate` is read straight from course JSON with no length or
character-set validation:

    editorTemplate: _optionalString(j, 'editorTemplate', ''),

`_optionalString` only trims whitespace. `Exercise.type` then passes any
unrecognised value through verbatim (`_legacyTypeFromTemplate` ends with
`if (template.isNotEmpty) return template;`), and that string is displayed or
written in five places:

| Site | Surface |
| --- | --- |
| `round_screen.dart:2563` | `Text('Unsupported exercise type: ${ex.type}')` — the learner's screen |
| `course_editor_screen.dart:5075` | Editor location label |
| `course_audit_service.dart:1145`, `:1217` | Audit finding messages |
| `report_service.dart:46` | Written into an exported report file |

**This is not code execution.** The string never reaches a file path, a process
argument, a URL or an asset lookup, and Dart has no `eval`. Flutter's `Text`
renders literal characters and interprets no markup, so there is no
XSS-equivalent. The exposure is display spoofing and layout: the only ceiling is
the 10 MB course JSON limit, so a template may be megabytes long, and nothing
strips bidi or control characters that could reorder what the learner sees.

The project already treats this class of problem correctly elsewhere —
`UpdateService._plainText` strips `\x00-\x1F`, `\x7F` and the
`‪-‮` / `⁦-⁩` bidi range from GitHub release text before
display. The same instinct simply has not been applied to course-supplied
values.

**Existing mitigation — stronger than this finding first claimed.** An earlier
revision of this section stated that import does not audit and that an unknown
type would install silently. **That was wrong.** `_importCourse`
(`course_projects_screen.dart:1870`) audits every imported Course and refuses
the import outright when any Error is present, showing a *Course import blocked*
dialog. `EXERCISE_TYPE_UNKNOWN` is an Error, so a Course carrying an
unrecognised exercise type is already rejected at the boundary. Warnings do not
block; they import with an advisory notice.

That reduces this finding considerably. The unbounded string is no longer
reachable through the learner screen by way of an ordinary import, because such
a Course never installs. What remains reachable is narrower: the rejection
dialog itself renders `issue.message`, and the message for this rule is
`'Unknown exercise type: ${ex.type}'` — so the attacker-controlled, unbounded
value is displayed while being refused. A Course stored before the rule existed,
or altered directly in preferences, could also still reach the learner screen.

The remedy below is therefore **defence in depth rather than a gap to close**,
and its priority should be read accordingly.

**Remedy.** Bound and sanitize `editorTemplate` at the parse boundary: cap its
length (the longest real preset id is 28 characters, so 64 is generous) and
reject anything outside `[a-z0-9_]`. That is a stricter fix than sanitizing at
each display site and removes the problem for all five at once.

**Interaction with M1.** If M1 adopts strict rejection of unknown types, this
finding disappears with it — an unrecognised template would never be stored. If
M1 keeps unknown types representable, the bound above becomes necessary rather
than optional, because the unknown branch is then a permanent, reachable state.

### Security properties that are already correct

Worth recording so they are not weakened later:

- The GitHub update check is genuinely metadata-only: hard-coded HTTPS endpoint,
  `followRedirects = false`, 256 KiB response cap, strict URL allowlisting, and
  control/bidi character stripping on release text. It never downloads or
  executes an asset.
- Windows TTS passes spoken text as Base64 in a child-process environment
  variable, so course text is never parsed as PowerShell source. `-NoProfile`
  and `-NonInteractive` are set and `runInShell` is false.
- Learner profile IDs are UUIDv4 from `Random.secure()` and validated against a
  strict pattern before any namespace operation.
- Sensitive preference suffixes are excluded from backup export **and** from
  backup import — defence in depth in both directions.
- The ZIP importer bounds entry count, per-file size, total decompressed size
  and image count, rejects absolute paths, `..` components, duplicate basenames
  and unsupported extensions, and deletes its target directory on any failure.
- Course and learner stores use verified writes with rollback, and corrupt JSON
  is copied aside rather than overwritten.

---

## 3. Robustness and resilience to regressions

### R1 — There is no CI (Declined)

**Originally raised as High, and briefly implemented. The owner removed the
workflow and declined automated CI. The observation is recorded here with its
accepted residual risks; it is a deliberate choice, not an oversight.**

There is no `.github/` directory. The test suite and the clean analyzer run
exist only as long as someone remembers to run them locally before a merge.
Nine of the last twenty commits are merges of PR branches, none of which could
have been gated.

**What does not change.** `AGENTS.md` already requires, under *Validation before
delivery*, that `flutter pub get`, `flutter analyze` and `flutter test` are run
on the final working tree before delivery, and under *Test execution efficiency*
that the complete suite is run exactly once on that final tree. That
requirement is unaffected by this decision. The project's actual safety net has
always been that discipline; CI would have enforced it rather than replaced it,
and the suite is genuinely green when it is run.

**Accepted residual risks.** Two, both worth naming precisely so that a future
failure is recognised rather than puzzled over:

1. **Merges are ungated.** Nothing mechanically prevents a branch being merged
   without the suite having been run, and nothing records whether it was. A
   regression reaches `main` and is found at the next manual run, which may be
   several commits later; bisecting is then the only way to locate it.
2. **Coverage is Windows-only.** The suite only ever executes on the developer's
   Windows machine, so nothing exercises the Linux, macOS or Android paths.
   That matters more in this codebase than in most, because it has real
   platform branching: `tts_linux_backend_io.dart` versus
   `tts_windows_backend_io.dart`, `Platform.pathSeparator` throughout the
   transfer and media services, the `file_selector` desktop backend versus the
   unavailable Android one, and `window_setup_io.dart`. A Linux-only or
   Android-only break is invisible until someone builds for that platform.

A third, smaller consequence: formatting is no longer checked anywhere.
`dart format --output=none --set-exit-if-changed lib test` currently passes and
is worth running alongside the analyzer, since nothing else will catch drift.

**If the decision is revisited**, the workflow that was removed ran checkout →
`flutter pub get` → format check → `flutter analyze` → `flutter test` on
`ubuntu-latest` with Flutter pinned to 3.47.4, which would have addressed both
residual risks at once — the Linux runner covers point 2 for free.

### R2 — The Beta expiry date is a fuse under the test suite (High)

`BetaLifecycleService.expiryDate` is `DateTime(2026, 10, 19, 23, 59, 59)` and
`isExpired()` reads `DateTime.now()` when called with no argument. Six UI sites
call it that way:

- `home_screen.dart:410`, `:1663`, `:2091`
- `round_screen.dart:2588`
- `duel_screen.dart:441`
- `review_screen.dart:284`

There is no injection seam — the service is a static class and widget tests
cannot substitute a clock. On **2026-10-20**, every widget test that renders
Home, a Round, a Duel or Review will get `BetaExpiredView` instead of the screen
it asserts against. Given the audit date of 2026-09-20 that is 29 days away.

Only one test file uses `DateTime.now()` directly, so the suite is otherwise
well insulated from the clock — which makes this the single exception worth
fixing properly.

**Remedy.** Give the service an overridable clock and set it in
`flutter_test_config.dart` (or a shared `setUpAll`) to a fixed date well inside
the Beta window:

    class BetaLifecycleService {
      @visibleForTesting
      static DateTime Function() clock = DateTime.now;
      static bool isExpired([DateTime? now]) =>
          isBetaBuild && (now ?? clock()).isAfter(expiryDate);
    }

Separately, the product risk stands on its own: after 2026-10-19 real users are
blocked from lessons until a new build ships.

### R3 — Everything expensive runs on the UI isolate (Medium)

There is no `compute()`, `Isolate.run` or `Isolate.spawn` anywhere in `lib/`.
The following all execute on the main isolate and block the frame loop:

| Operation | Bound | Site |
| --- | --- | --- |
| Course JSON parse | 10 MB | `custom_course_transfer_service.dart:134` |
| ZIP decode | 50 MB | `image_bank_service.dart:152` |
| Course SHA-256 + canonical JSON | 8 MB | `course_backup_service.dart:92` |
| Image decode | now header-bounded (S9) | `lesson_icon_service.dart` |
| Course deep copy (`jsonEncode` then `jsonDecode`) | 8 MB | `course_editor_transaction.dart:114` |

On a low-end Android device a 50 MB ZIP decode is several seconds of frozen UI
and a plausible ANR.

**Remedy.** Move the ZIP decode, the course parse and the backup hash to
`Isolate.run`. They are already pure functions over bytes, so the change is
contained.

### R4 — All authoring data lives in one preferences string (Medium)

Every custom course is serialised into a single `SharedPreferences` string under
`quisquislingo_user_courses_v9_233030`, capped at 8 MB.

- `_loadKey` JSON-decodes the entire store on every read, and it is called
  several times per save (`saveUserCourse` alone calls it twice before writing).
- A single malformed entry makes `listUserCourses` throw, so one bad course
  makes **all** courses unlistable. The corrupt blob is preserved, which is the
  right instinct, but the failure is total rather than partial.
- `_replaceKeyAtomically` is atomic only in memory; `SharedPreferences` gives no
  crash-consistency guarantee across the underlying file write.

**Remedy (incremental).** Keep the format, but (a) let `listUserCourses` skip
and report individual unreadable entries instead of aborting, and (b) cache the
decoded store behind a small repository object so one save does not re-parse
megabytes three times. A per-course file store under application support is the
longer-term answer.

### R5 — Change detection re-serialises the whole course (Medium)

`CourseEditorTransaction.hasChanges` calls `_semanticJson` on both the working
and original course — two full `toJson()` walks plus two `jsonEncode` passes —
and `_copy` round-trips through `jsonEncode`/`jsonDecode`. If `hasChanges` is
consulted from a `build()` or a `PopScope` predicate, this runs per frame.

**Remedy.** Maintain a dirty flag set by `replaceWorkingCourse`, and keep the
semantic comparison for the confirmation step only.

### R6 — Silent failure paths (Low)

100 `catch` blocks discard the error; 23 are literally `catch (_) {}`. Most are
deliberate best-effort cleanup (temp-directory deletion, unreferenced-audio
removal, log writes) and are correctly commented as such. But
`ImageBankService.banks()` silently drops any bank whose directory is missing,
and `loadImportedEntries` silently skips an unreadable manifest, so imported
media can disappear from the UI with no diagnostic.

**Remedy.** Route the non-cleanup cases through `DiagnosticLogService` — the
infrastructure already exists and is already privacy-reviewed.

### R7 — The suite takes 10 m 42 s (Low)

Long enough to discourage running it before every commit. With CI declined
(R1), nothing absorbs that cost: the full 10 m 42 s is paid locally, on the
developer's machine, every single time the suite is run — and it is now the
only thing standing between a regression and `main`. The incentive to skip it
and the consequence of skipping it both point the same way, which is what makes
a Low finding worth keeping on the list.

Much of the time is widget tests pumping full screens. A `--tags` split (unit
versus widget) would give a fast loop for the common case while keeping the
full run for delivery, which is the cheapest available mitigation now that the
automated fallback is gone.

---

## 4. Maintainability

### M1 — Exercise types are strings, not a type (High)

**Correction.** This section first claimed roughly *320 literals across 16
files*. That count was inflated and is corrected below. The finding itself
stands; its size does not.

`ExercisePresetRegistry` is a clean single registry of 25 presets over 5
canonical runtime models — good design. But `ExercisePreset.id` is a `String`,
and the real dispatch surface is **8 files** containing **18 switch or
comparison sites**:

- `course_models.dart`
- `course_editor_screen.dart`
- `round_screen.dart`
- `duel_screen.dart`
- `audio_exercise_availability_service.dart`
- `course_audit_service.dart`
- `exercise_copy_service.dart`
- `guidebook_round_generator.dart`

The original figure swept in two unrelated things: `PromptElement.type` values
(`'text'`, `'audio'`, `'image'`, `'gap'`), which are a separate vocabulary that
happens to use the same field name, and the registry's own declaration lines,
which are definitions rather than dispatch.

**A second correction, more consequential than the count.** The type set is not
closed, which the original remedy assumed. `Exercise.type` is a computed getter,
not a stored field:

    String get type => _legacyTypeFromTemplate(editorTemplate, interaction.kind);

and `_legacyTypeFromTemplate` ends with `if (template.isNotEmpty) return
template;`, so any string an imported course places in `editorTemplate` flows
through as a type. It also maps legacy template names (`choose_answer` →
`choice`). In practice the ten bundled courses use only 8 distinct templates,
all valid preset ids, and every literal compared in code is within the 25-preset
set — but the model permits more.

That makes "parse once at the JSON boundary" a compatibility decision rather
than a mechanical change, because it forces a policy for unrecognised
templates. See S11, which shares this code path.

This is still why `NEW_EXERCISE_TYPE_CHECKLIST.md` has to be ten pages long: the
compiler cannot tell an author which sites a new type touches, so a human
checklist substitutes for exhaustiveness checking. A typo in one literal is a
silent runtime fallthrough, not a build error.

**Limits of the remedy, which the original section did not state.** Dart
enforces exhaustiveness only on switch expressions and on switch statements over
enums or sealed types, and a single `default:` or `_ =>` disables it silently for
that site. The codebase already uses that wildcard in 23 places. Two further
consequences: several of the 8 dispatch sites are `||` chains of `==` rather
than switches and gain nothing without restructuring; and if unrecognised types
stay representable, every switch must handle that case — which tempts exactly
the `default:` that removes the protection. An `unknown` value must therefore be
a named case, never a wildcard, and `fromWire` must never fall back to a real
preset, which would silently reclassify an imported exercise.

**Remedy.** Introduce

    enum ExercisePresetId {
      choice('choice'), gapChoice('gap_choice'), /* ... */;
      const ExercisePresetId(this.wireId);
      final String wireId;
      static ExercisePresetId? fromWire(String id) => ...;
    }

Parse once at the JSON boundary, then convert the dispatch sites to exhaustive
`switch` expressions. Dart will then report every unhandled site the moment a
value is added. This turns most of the checklist into a compile error, which is
the highest-leverage change available in this codebase.

### M2 — `course_editor_screen.dart` is 10,789 lines (High)

| Metric | Value |
| --- | --- |
| Lines | 10,789 |
| Classes in one file | 29 |
| Methods | 197 |
| `setState` calls | 81 |
| `_editCourseInfo()` | **991 lines** |
| `_specificFields()` | 610 lines |
| `_buildCandidate()` | 343 lines |
| Largest `build()` | 316 lines |

A 991-line method cannot be reviewed, unit-tested in isolation, or safely edited
by two people. `_editCourseInfo` builds an entire multi-section form — course
identity, licence, authors, rights holders, flags, counts — inside a single
`showDialog` closure with locally captured controllers.

**Remedy.** Extract in this order, each step independently shippable:

1. `_editCourseInfo` into a `CourseInfoEditorScreen` with a form model object.
2. `_specificFields` into one widget per `CanonicalExerciseModel` (5 files),
   selected by the enum from M1.
3. The 29 co-located classes into `lib/screens/course_editor/`.

### M3 — Storage access is not centralised (Medium)

`SharedPreferences.getInstance()` is called **111 times** across the tree, with
raw string keys at each site. There is no repository layer and no dependency
container; services are constructed ad hoc (`ProfileService()`,
`CourseEditorService()`) wherever needed. Constructor injection is used
consistently for *testing* seams, which is good, but the production graph is
implicit.

The practical cost shows up in `239_RESET_STORAGE_INVENTORY.md` — an excellent
document that exists because the key layout has to be reconstructed by hand.

**Remedy.** A thin `PreferenceStore` wrapper holding the single instance and the
key constants, with the existing services delegating to it. No behaviour change,
and the inventory doc becomes derivable from code.

### M4 — Lint configuration is stock (Medium)

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and adds
nothing. Given the code quality on display, the ceiling is higher:

    analyzer:
      language:
        strict-casts: true
        strict-raw-types: true
      errors:
        unawaited_futures: error

    linter:
      rules:
        - avoid_dynamic_calls
        - unawaited_futures
        - prefer_final_locals
        - cancel_subscriptions
        - close_sinks
        - always_declare_return_types

`strict-casts` in particular is worth having in a codebase that does this much
`Map<String, dynamic>` handling. Expect a one-off cleanup, then permanent
protection.

### M5 — Version identity is duplicated and pinned in tests (Low)

`AppMetadata` hardcodes `2.0.40` / `240000` / `'Build 240, Revision 0'`,
duplicating `pubspec.yaml`, while `package_info_plus` — already a dependency —
could supply it at runtime. The duplication *is* tested
(`app_metadata_225_04_test.dart` compares against the pubspec), but eight test
files pin the literal version, so a bump is a multi-file edit.

**Remedy.** Keep the pubspec as the single source and derive `AppMetadata` from
it at build time, or accept the duplication and reduce the pinned assertions to
the one cross-check test that already exists.

### M6 — Parallel language maps can drift (Low)

`CourseService` holds three 10-entry maps keyed by the same codes —
`courseAssets`, `targetLabels`, `sourceLabels` — with nothing asserting they
stay aligned.

**Remedy.** One `const List<BundledCourse>` of records, or a test asserting the
three key sets are identical.

### M7 — No localization in a language-learning app (Medium, strategic)

Neither `flutter_localizations` nor `intl` is a dependency. There is no ARB
file, no `AppLocalizations`, and roughly **780+ literal `Text('...')` strings**
in `lib/`. Meanwhile `readme/` contains 59 translated README files, so the
intent to reach non-English speakers clearly exists.

Every month of new UI makes this refactor larger. The Course content is already
multilingual; the chrome around it is not.

**Remedy.** Adopt `flutter_localizations` + ARB now, even if `en` is the only
locale initially. Convert new screens as they are written and back-fill
opportunistically. Deferring this is the single largest compounding cost in the
project.

### M8 — Per-rune `RegExp` construction (Low)

`FormalNamePolicy.validatePresentationLabel` constructs
`RegExp(r'^[\p{M}]$', unicode: true)` **inside** the rune loop, recompiling it
for every character of every validated label.

**Remedy.** Hoist to a `static final`, as `_unicodeLetterMarkOrNumber` already
is two lines above.

### M9 — The Android manifest is malformed (Low, but user-visible)

    <application
        android:label="quisquislingo_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        android:roundIcon="@mipmap/ic_launcher_round">

The `<application>` start tag is closed after `android:icon`. The next line is
therefore **character data inside the element**, not an attribute:
`android:roundIcon` is silently dropped, so Android launchers that prefer round
icons fall back to the square one. The stray `">` is also left in the document.

Separately, `android:label="quisquislingo_app"` means the app appears in the
Android launcher and app list as `quisquislingo_app` rather than
`QuisquisLingo`.

**Remedy.**

    <application
        android:label="QuisquisLingo"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:allowBackup="true"
        android:fullBackupContent="@xml/backup_rules"
        android:dataExtractionRules="@xml/data_extraction_rules">

---

## 5. Edge cases and smaller observations

| # | Observation | Site |
| --- | --- | --- |
| E1 | Dialog-scoped `TextEditingController`s are disposed after `await showDialog` with no `try`/`finally`; an exception in the dialog leaks them. | `device_administration_screen.dart:135`, `gamification_settings_screen.dart:77`, `user_data_settings_screen.dart:403` |
| E2 | Windows TTS tries two executable names, each with a 30 s timeout, so a hung PowerShell blocks speech for up to 60 s. | `tts_windows_backend_io.dart:62` |
| E3 | `verifyAccessPin` returns `true` when no verifier is stored. Correct as a default, but it means preference loss silently removes the gate. | `profile_service.dart:741` |
| E4 | `int.parse` on a text field in a submit callback, safe only because the button is disabled by a separate validator. | `course_projects_screen.dart:1495` |
| E5 | `BoundedLogWriter._appendFileOnce` rewrites the whole file on rotation without a temp-and-rename, so a crash mid-rotation truncates the log it is protecting. | `bounded_log_writer.dart:84` |
| E6 | `markCleanShutdown` appends to the crash log directly, bypassing the 2 MB bound until the next bounded write. Self-correcting; noted for completeness. | `crash_log_service.dart:163` |
| E7 | Orphaned MP3 and exercise-image files after clip / exercise / course deletion. **Already known and documented** in `240_FILE_DIALOGS_PLAN.md` section 8.3. | — |
| E8 | `demo_courses/` is untracked and not in `.gitignore`, so it shows in every `git status`. | repo root |

---

## 6. What is already strong

Stated explicitly so that refactoring does not erode it:

- **Test discipline.** 1,809 tests, 1.06 test lines per source line, all green,
  and only one test touching the wall clock.
- **Input validation.** `Course.fromJson` rejects unknown-version, obsolete and
  legacy fields explicitly rather than ignoring them, with a specific message
  per case. Learner backups validate key shape, value type, entry count and name
  policy before writing anything.
- **Bounded everything.** Answer expressions cap at 128 variants and
  `_checkLimit` is called incrementally at nine points during expansion, so
  factorial reorder growth is bounded *during* the walk, not after it.
- **Transactional storage.** Verified writes with read-back comparison and
  explicit rollback in both `CourseEditorService` and `LearnerBackupService`.
- **Honest documentation.** `SECURITY_AND_ROBUSTNESS.md` states that the Beta
  expiry is not DRM and that preferences are not encrypted;
  `239_RESET_STORAGE_INVENTORY.md` names its own known orphan cases. This is
  rarer than it should be.
- **A 103-rule audit registry** as an exhaustive enum, used by the service, the
  Help screens and the tests from one definition.
- **Zero `TODO`/`FIXME`/`HACK` markers** in 64,490 lines.

---

## 7. Prioritised recommendations

### Do before the next Beta ships

| # | Action | Effort |
| --- | --- | --- |
| 1 | Make `BetaLifecycleService` clock-injectable and pin it in tests (R2). | 2 h |
| 2 | Fix the Android manifest: backup rules, `roundIcon`, `label` (S1, M9). | 30 min |
| 3 | Add `--` before eSpeak text; absolute path for `powershell.exe` (S4, S3). | 1 h |
| 4 | Preserve PIN and Recovery Key across backup restore, with a test (S5). | 2 h |

### Next cycle

| # | Action | Effort |
| --- | --- | --- |
| 5 | `ExercisePresetId` enum and exhaustive `switch` dispatch (M1). | 2–3 d |
| 6 | ~~`ImageDescriptor` dimension pre-check at the affected decode sites (S9).~~ Done — three sites, two of the five originally listed were already safe. | done |
| 7 | Bound and sanitize `editorTemplate` at the parse boundary (S11, defence in depth). | 1 h |
| 8 | ~~Verify inflated size after `readBytes()` in the ZIP importer (S7).~~ Done. | done |
| 9 | Move ZIP decode, course parse and backup hash to `Isolate.run` (R3). | 1 d |
| 10 | Tighten `analysis_options.yaml`, then clear the fallout (M4). | 1–2 d |
| 11 | Split `_editCourseInfo` out of the editor screen (M2, step 1). | 2 d |
| 12 | Split the suite with `--tags` (unit versus widget) (R7). | half d |

### Strategic

| # | Action | Rationale |
| --- | --- | --- |
| 13 | Release signing at Play enrolment (S2). | Deferred deliberately. Not urgent as code — but the switch to a Play-signed key permanently breaks updates for existing installs, so testers must export their data *before* that build ships. |
| 14 | Adopt `flutter_localizations` + ARB (M7). | Compounding cost; ~780 strings today and growing every build. |
| 15 | Introduce a `PreferenceStore` repository (M3, R4). | Removes 111 scattered call sites and makes the storage inventory derivable. |
| 16 | Continue the `course_editor_screen` decomposition (M2, steps 2–3). | The file is the project's main review bottleneck. |
| 17 | Per-course file storage instead of one 8 MB preference blob (R4). | Removes the total-failure mode and the size ceiling. |

---

*Audit performed 2026-09-20 against commit `338dbab`.*

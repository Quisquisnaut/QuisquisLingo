# Build 272 validation

## Revision 0 (2.0.72+272000), the credits and licence owner

12 October 2026, owner's Windows 10 PC, `build-272`.

- Characterization, on the code **before** the change (`main` at
  `4963cb42` plus only the new test file): the 6 screen cases of
  `test/course_credits_272_test.dart` **passed** (Course Info 3, New Course
  2, Course Wizard 1). A first run failed on three of them for reasons of
  the test alone (a Dart record holding a list never compares equal; the
  Wizard shows a step's refusal when Save now is pressed, not while typing);
  the values the app produced were the expected ones.
- New tests after the change: `test/course_credits_272_test.dart`, **11
  passed**:
  - the owner (5): a credit's roles (standard order, the others once and as
    typed, Contributor for none, only standard roles count as chosen);
    stored roles split into chips and text; a row without a name is no
    credit and no Rights Holder, names trimmed; the licence list (the entry
    for a stored licence, the licence of an entry, an empty custom text);
    the policy stored with a licence, the stored policy kept for an
    unchanged licence, the policy shown after a choice;
  - Course Info (3): roles and the Contributor default through the dialog,
    an unchanged licence keeps its stored policy; a licence of the list
    brings its policy, Other / Custom license keeps the policy shown, shows
    the stored licence in its field and needs a text; a licence changed and
    changed back keeps the stored policy, a changed one replaces it;
  - New Course (2): the creator as Author, roles, Rights Holder and custom
    licence as typed, Other / Custom license shown as "Not specified"; a
    licence of the list stored with its own policy;
  - Course Wizard (1): roles as in Course Info, a licence of the list
    stored with its own policy whatever the Course stored, the Custom
    license field empty for a licence of the list, the refusal without a
    text, a custom licence keeping the policy shown.
- Focused files (12): `course_credits_272_test`,
  `course_library_operations_249_test`, `course_metadata_ui_v9_test`,
  `course_wizard_267_test`, `course_ownership_team_229_r1_test`,
  `course_editor_layout_regression_test`, `course_author_metadata_test`,
  `new_course_structure_226_04_test`, `course_creation_flags_226_04_test`,
  `wizard_wording_267_test`, `check_and_publish_267_test`,
  `course_manager_workflow_249_test`: **170 passed**.
- `flutter analyze --no-pub`: **No issues found** (272.7 s).
- Complete suite, `flutter test --no-pub --concurrency=1` with the PC kept
  awake and `TEMP` on `D:\QQL_test_temp`: **4,338 passed, 1 skipped, 0
  failed** (17:13 to 18:39, 85 minutes). The run took about twice the usual
  time: the PC had 0.75 to 1.5 GB of memory free while Chrome, Firefox and
  the Claude app were open.
- Not run: the Windows package, the Android build (no code of theirs
  changed).

## Revision 1 (2.0.72+272001), the three screens follow the same rules

12 October 2026, owner's Windows 10 PC, `build-272`.

- Changed tests: `test/course_credits_272_test.dart`, **12 passed**. The
  screen cases that pinned a difference in Revision 0 now pin the one rule:
  - Course Info: the Custom license field starts empty for a licence of the
    list and shows the author's own licence when reopened; Apply without a
    text says "Type the custom license, or choose a license from the list."
    and the dialog stays;
  - New Course: after "CC BY-SA 4.0", Other / Custom license shows and
    stores "Allowed" (before: "Not specified"); Continue to Editor without a
    text says the same sentence and no Course Editor opens;
  - Course Wizard: a person added with Add a person starts as Contributor
    and is stored so; a Course stored with "CC BY 4.0" and an unspecified
    policy keeps "unspecified" when its About step is saved without
    touching the licence (before: it became "allowed");
  - the owner: `customLicenseTextFor` for every licence of the list and for
    a text of the author's own, the refusal text, the creator's and the
    default role.
- Focused files (12): `course_library_operations_249_test`,
  `course_metadata_ui_v9_test`, `course_wizard_267_test`,
  `course_ownership_team_229_r1_test`,
  `course_editor_layout_regression_test`,
  `new_course_structure_226_04_test`, `course_creation_flags_226_04_test`,
  `wizard_wording_267_test`, `check_and_publish_267_test`,
  `course_manager_workflow_249_test`, `module_wizard_267_test`,
  `course_info_v11_fields_243_test`: **167 passed**.
- `flutter analyze --no-pub`: **No issues found** (134.4 s).
- Complete suite, `flutter test --no-pub --concurrency=1` with the PC kept
  awake and `TEMP` on `D:\QQL_test_temp`: **4,339 passed, 1 skipped, 0 failed** (18:49 to 19:32, 43 minutes; the PC had about 2.4 GB of memory free this time).
- Not checked by hand in the running app: the three forms were driven by
  widget tests only.
- Not run: the Windows package, the Android build.

## Revision 2 (2.0.72+272002), the Course Info Editor's form and its own file

12 October 2026, owner's Windows 10 PC, `build-272`.

- Characterization, on the code **before** the move (Revision 1's commit
  `4d0d708c` plus only the new test file):
  `test/course_info_editor_272_test.dart`, **5 passed**. Two first runs
  failed for reasons of the test alone (Apply reads the stored Courses
  before its other checks, so the test must wait for the message; the words
  "Version history" are on the page behind the dialog too; the Version
  history page shows a spinner while it reads). After the review below the
  test was widened (the help sentence that names QQL's own language name,
  "Rights Holder 1", "Media credit 1", the build number in a help text) and
  run again on the code before the move, with the moved files set aside:
  **5 passed**.
- Every text and key of the old dialog compared with the new files
  (`compare_literals.py`): 186 before; none missing, none new besides file
  imports and the empty defaults of the new row class; five messages differ
  only by the renamed variable inside them (read in full).
- **Independent review** (a second reader, read-only, old code against new
  code, asked only for differences in what an author sees or what is
  stored): one real mistake found and fixed before the commit (the help
  sentence under "Learning language name for learners" would have shown
  "Instance of 'CourseInfoForm'" instead of the language's name); one
  remark taken (the form is made before the dialog opens, so a Course it
  cannot read opens no dialog, as before); no other difference found in the
  Apply path, the cover credit, the initial values, the language tags, the
  fields' lifetime, the contexts and the new `_editCourseInfo`.
- New tests after the move: `test/course_info_form_272_test.dart`, **21
  passed** (two first failures were wrong expectations of the test: a name
  with spaces before or after is refused, not trimmed; a Course without a
  stored policy has "unspecified"); `test/course_info_editor_272_test.dart`,
  **5 passed**.
- Focused files (17): the two above, `course_credits_272_test`,
  `course_cover_255_test`, `course_info_v11_fields_243_test`,
  `course_backups_270_test`, `qql_233_identity_status_ui_test`,
  `course_editor_top_bar_271_test`, `qql_229_revision2_test`,
  `qql_229_revision3_test`, `official_course_ui_226_01_test`,
  `course_ownership_team_229_r1_test`, `course_metadata_ui_v9_test`,
  `course_editor_layout_regression_test`, `labels_in_english_271_test`,
  `save_now_270_test`, `qql_233_revision_platform_contract_test`: **163
  passed** (run again after the review's fix).
- `flutter analyze --no-pub`: **No issues found** (77.5 s).
- Complete suite, `flutter test --no-pub --concurrency=1` with the PC kept
  awake and `TEMP` on `D:\QQL_test_temp`: **4,367 passed, 1 skipped, 0 failed** (19:57 to 20:45, 48 minutes).
- Not checked by hand in the running app: the dialog was driven by widget
  tests only. Worth a look by the owner: open Course Info Editor on a
  Course, scroll through it once, change something, Apply.
- Not run: the Windows package, the Android build.

## Revision 3 (2.0.72+272003), New Course's form and its own file

12 October 2026, owner's Windows 10 PC, `build-272`.

- Characterization, on the code **before** the move:
  `test/new_course_dialog_272_test.dart`, **2 passed** (a name that cannot
  be stored, no languages, Buy a Coffee not HTTPS and the fields as typed;
  a name another Course of the learner has). Run while Revision 2 was still
  uncommitted; New Course's code was the same then as in Revision 2's
  commit `89b51291`.
- Every text and key of the old dialog compared with the new files
  (`after_move.py`): 76 before; none missing; "Author" and "Contributor"
  now come from `CourseCredits`; nothing new besides file imports. No bare
  interpolation was renamed (the script reports 0 braced).
- **Independent review** before the suite (a second reader, read-only, old
  code against new code, token by token for the dialog): no difference in
  what an author sees or what is stored, in the order of the checks, the 22
  values handed to `CourseLibraryOperations.newCourse`, the initial values,
  the cover and its deletion on Cancel, the controls, the fields' lifetime,
  the contexts and the Course Wizard's rows. One point was not exactly the
  old code and was made exact: the name check now asks the Course list as
  it is when Continue to Editor is pressed.
- New tests after the move: `test/new_course_form_272_test.dart`, **11
  passed**; `test/new_course_dialog_272_test.dart`, **2 passed**.
- Focused files (17): the two above, `course_credits_272_test`,
  `new_course_structure_226_04_test`, `course_creation_flags_226_04_test`,
  `course_ownership_team_229_r1_test`,
  `course_editor_layout_regression_test`, `course_metadata_ui_v9_test`,
  `qql_233_revision_platform_contract_test`, `course_wizard_267_test`,
  `wizard_wording_267_test`, `check_and_publish_267_test`,
  `module_wizard_267_test`, `course_manager_workflow_249_test`,
  `course_library_operations_249_test`, `provisional_mytest_workflow_test`,
  `course_cover_255_test`: **209 passed**; the three New Course files again
  after the review's point: 30 passed.
- `flutter analyze --no-pub`: **No issues found** (42.5 s).
- Complete suite, `flutter test --no-pub --concurrency=1` with the PC kept
  awake and `TEMP` on `D:\QQL_test_temp`: **4,380 passed, 1 skipped, 0 failed** (20:58 to 21:42, 44 minutes).
- Not checked by hand in the running app. Worth a look by the owner: New
  Course, Continue by hand, fill the form once, Continue to Editor.
- Not run: the Windows package, the Android build.

## Revision 4 (2.0.72+272004), Lesson Options

12 October 2026, owner's Windows 10 PC, `build-272`.

- Characterization, on the code **before** the move (Revision 3's commit
  `213dc5c6` plus only the test file):
  `test/lesson_options_panel_272_test.dart`, first 2 cases, **2 passed** at
  the first run (a custom Round label, the picture border and the default
  Timed limits added, replaced, refused, moved, removed and saved; View
  only). After the review two cases were added and all four run again on
  the code before the move, with the moved files set aside: **4 passed**.
- Every text and key of the moved code compared with the new files
  (`compare.py`): 109 before; none missing; one text differs by the renamed
  variable inside it.
- **Independent review** before the commit (a second reader, read-only, old
  code against new code, Flutter's ExpansionTile source for the layout):
  the writes of every setting, the default Timed limits, the Course
  Wizard's step, the keys and initial values, the layout, the two moved
  dialogs and the interpolations: no difference. **Two edge cases found in
  the first version of the panel and fixed**: a dialog's answer dropped
  when the list lets go of the panel while the dialog is open (the panel
  waited instead of the page); and of two changes made before the screen is
  drawn again only the second kept (the panel started from the Course it
  had drawn). Both are as before the move now, and each has a test that the
  first version failed (the reviewer's analysis; the tests pass on the code
  before the move and on the corrected panel).
- New tests after the move: `test/lesson_options_272_test.dart`, **7
  passed** (the rules alone; the Course Wizard's options step against the
  Course it wrote before); `test/lesson_options_panel_272_test.dart`, **4
  passed**.
- Focused files: 20 files **195 passed** before the fix (one more file name
  in my list did not exist; not a test failure); after the fix the two new
  files, `lesson_naming_226_04_test`, `timed_round_261_test`,
  `lesson_controls_226_04_test`, `owner_review_263_revision2_test`,
  `picture_border_267_test`, `word_lookup_ui_265_test`,
  `course_wizard_267_test`, `optional_learning_paths_226_04_test`: **145
  passed**.
- `flutter analyze --no-pub`: **No issues found** (17.9 s).
- Complete suite, `flutter test --no-pub --concurrency=1` with the PC kept
  awake and `TEMP` on `D:\QQL_test_temp`: **4,391 passed, 1 skipped, 0 failed** (22:40 to 23:24, 44 minutes). A first run, started
  before the review ended, was stopped at the review's findings and is not
  counted.
- Not checked by hand in the running app; the Windows package below is for
  that.
- **Windows package** (owner decision: after this revision, to try the
  changed forms by hand). `flutter build windows --release --no-pub` built
  in 143 s. `tools/package_windows_release.ps1` then stopped at its line 494
  ("invalid characters in the path"): since Build 270 Revision 7 that line
  held a BEL control character where `\a` of `data\app.so` belongs, so the
  script could not have finished since 10 October 2026. With the one
  character corrected the script ran through on the same build: the Dummy
  publisher check passed, 24 launcher unit tests and 4 packaged-launcher
  tests passed, 4,405 files frozen. Package:
  `build\packages\quisquislingo_windows_beta_272004.zip` (and the folder
  of the same name), version 2.0.72+272004. Not started by me: the owner
  tries it.

## Revision 5 (2.0.72+272005), the exercise editor has its own file

12 October 2026, owner's Windows 10 PC, `build-272`.

- The moved class against its old text (`diff_region.py`, blank lines and
  indentation ignored): 3,081 lines before, 3,077 after, **18 differing
  lines**, all at the five ties (the preset's name, the action chip twice,
  the blank exercise, the publication line, the hierarchy update).
- No public declaration of the rest of the Course Editor file is used by
  the exercise editor, so the new file does not import the Course Editor
  file (no import cycle).
- New tests: `test/exercise_editor_move_272_test.dart`, **4 passed** (the
  exercise editor reachable from both files; a new exercise of every preset
  is a Draft of that preset with the ID given and opens in its form; the
  recipes without an earlier shape; the name of every preset and of an
  unknown one).
- Focused files (12): the one above, `exercise_creation_wizard_test`,
  `exercise_responsive_224_test`, `owner_review_263_revision1_test` (Fill
  with an example and Clear all for every preset),
  `editor_notes_267_test`, `complete_text_and_sentence_order_259_test`,
  `plural_pictures_265_test`, `exercise_field_help_ui_226_02_test`,
  `arrange_gap_fill_editor_238_test`, `before_you_start_card_257_test`,
  `canonical_authoring_route_245_test`, `revision3_followup_256_test`:
  **153 passed**.
- `flutter analyze --no-pub`: **No issues found** (23.4 s).
- Complete suite and independent review: shared with Revision 6 (owner
  decision of 12 October 2026 for pure file moves); see there.

## Revision 6 (2.0.72+272006), four more pages leave the Course Editor file

12 October 2026, owner's Windows 10 PC, `build-272`.

- Each moved run against its old text (`diff_region.py`, blank lines and
  indentation ignored): the Audit page, the Lesson preview and
  `AuthoringHierarchyStatus` **0 differing lines**; the Audio Library
  **3 differing lines**, the three calls that changed their name
  (`ExerciseLabels.summary`, `ExerciseLabels.typeLabel`,
  `openSearchResult`).
- The three label functions against `ExerciseLabels`: same bodies, the
  names apart. `exerciseEditorFor` and `openSearchResult`: same bodies,
  public names.
- No new file imports `course_editor_screen.dart` (no import cycle); the
  Course Editor file imports and re-exports the four moved declarations.
- New tests: `test/exercise_labels_272_test.dart`, **5 passed** (the moved
  pages reachable from the Course Editor file; the kind name, the type
  label and the summary on every exercise of the bundled Courses; an
  exercise without words and a Story cover without a title).
- Focused files (18), among them the Audio Library's
  (`audio_library_271_test`, `audio_library_letters_270_test`,
  `audio_library_media_248_test`, `audio_usage_270_test`), the Audit's and
  the hierarchy status's (`authoring_hierarchy_indicators_226_02_test`,
  `audit_speed_271_test`, `editor_diagnostics_226_02_revision3_test`) and
  the layout regression tests: **166 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review of Revisions 5 and 6 (one review for both)

A second reader (read only, no access to this session's reasoning) compared
both revisions with the commit before them (`9765999e`): **no behaviour
difference found**.

- Every moved class against its old text: the Audit page, the Lesson
  preview and the status rule identical; the Audio Library 3 lines and the
  exercise editor 6 places, all the intended renames.
- `PresetRecipes.blankFor`, `ExercisePresetRegistry.nameOrId` and the three
  `ExerciseLabels` functions: the same text as the private functions they
  replace. The two helpers written out in the exercise editor
  (`jsonEncode(a) != jsonEncode(b)`, `withPublicationState`) and
  `const CourseHierarchyUpdateService()` give the same results.
- Private names: nothing a new file needs stayed behind, nothing is declared
  twice; `AuthoringHierarchyStatus` has one declaration and one cache.
- No new file imports the Course Editor file; every user of the five
  re-exported names still resolves (about 70 test files among them).

Two tidy-ups it pointed out, done before the suite:

- `import 'dart:async'` was needed only by the Audio Library's code; removed
  from the Course Editor file, the exercise editor's file and the Audit
  page's file.
- `ExerciseLabels`' comment said "Pure Dart"; it reaches the Audit service,
  which reaches a widget file, so the comment now says what is true: an
  exercise in, a text out, no screen state.

Analyzer after them: **No issues found** (65.0 s).

### Complete suite for Revisions 5 and 6 (one suite for both)

13 October 2026, 00:05–00:51, `flutter test --no-pub --concurrency=1` on the final tree (after the review's two tidy-ups): **4,400 passed, 1 skipped, 0 failed** (45 min 29 s). Revision 4's suite had 4,391; the 9 more are Revision 5's 4 and Revision 6's 5.

## Revision 7 (2.0.72+272007), the Timed Round's clock

13 October 2026, owner's Windows 10 PC, `build-272`.

- **Before the change**: `test/timed_round_screen_272_test.dart`, 7 cases on
  the Round screen as it was, **7 passed** (the first run had one wrong
  expectation of mine, the label of the last button, "Review mistakes";
  the test was corrected, never the app). The same file after the change:
  **7 passed**.
- **Two faults of that test file, found by the first complete suite and by
  repeating the file** (the app was right both times):
  1. one case tapped the answer of question 1, but a Round shows its
     questions in a new order each time, so the case failed about one run
     in two; it now taps the answer shown;
  2. the file did not keep the Crash Log out, as the other Round screen
     tests do (`keepCrashLogUnavailable()`): a real file write left
     unfinished at the end of one case could hold every later case (seen
     once in nine runs).
  With both corrected: **12 runs of 12 passed** on the changed screen, and
  **4 of 4** on the screen as it was before the change (the old file put
  back for those runs, then the change restored and compared byte by byte).
- New: `test/timed_round_clock_272_test.dart`, **11 passed** (the limit
  shown whole; no start without a limit; a started second counts until it
  ends; the deadline told at the next refresh and again until the page ends
  the attempt; the deadline told after the limit of timer time whatever the
  time read; the deadline itself is due, one moment before is not; a second
  start keeps the first deadline; nothing refreshed while the page cannot
  refresh; the last answer in time; no start after the time ran out; stopped
  timers leave the state).
- The Round screen's diff, read whole: 29 lines added, 61 removed; every
  one of the eight old names is gone from the file (asserted by the script
  that made the change, `apply_r7.py`).
- Focused files (16): the two above, `timed_round_261_test`,
  `round_type_compatibility_test`, `content_plays_right_271_test`,
  `test_round_attempt_test`, `round_xp_completion_regression_test`,
  `before_you_start_card_257_test`, `celebrations_264_test`,
  `sequence_round_256_test`, `story_runtime_256_test`,
  `spoken_lines_269_test`, `page_card_258_test`,
  `two_sided_flashcards_268_test`, `exercise_mascot_256_test`,
  `learning_completion_service_test`: **171 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review

A second reader (read only, no access to this session's reasoning) compared
the Round screen and the new clock with the commit before them
(`bd1c2550`): **no behaviour difference found**.

- Starting: the five old conditions (the Round's type, a deadline already
  set, the time already out, no limit, an empty queue) are all still there,
  shared between the screen and `start()`.
- Timers: the deadline's timer is created first, then the refresh every
  250 ms, as before; both are cancelled at the same four moments (the time
  ran out, the last answer in time, finishing, leaving the page). In every
  state (page gone, finishing, already out of time, finished in time) a
  timer that fires does what it did before.
- The seconds become 0 a moment earlier (inside `expire()`, before the
  keyboard is dismissed and the notice closed). Not visible: once the time
  is out the page draws the Time's up page, which shows no seconds.
- `late final`: creating the clock builds only closures; nothing reads
  `widget`, `mounted` or `context` at that moment, also when the first use
  is in `dispose` for a Round that is not Timed.
- No old name is left in `lib/` or `test/`; nothing outside the Round screen
  reads its Timed state.

What reading alone could not show (that the files compile and lint clean,
and the frame-level timing) is covered by the analyzer run and by the seven
screen tests written before the change.

### Complete suite

First run (13 October 2026, 01:01–01:46): 4,417 passed, 1 skipped, **1 failed**: the case of the new test file named in fault 1 above. Second run on the final tree (01:54–02:40), `flutter test --no-pub --concurrency=1`: **4,418 passed, 1 skipped, 0 failed** (45 min 33 s). Revision 6's suite had 4,400; the 18 more are this revision's 7 and 11.

## Revision 8 (2.0.72+272008), one owner for the media reference rule

13 October 2026, owner's Windows 10 PC, `build-272`.

- **Before the change**: `test/course_media_reference_272_test.dart`, 28
  cases on the code as it was (twenty references asked of
  `Course.isValidImageReference`, `isValidAudioReference`,
  `coverImagePattern`, `CourseMediaStore.isReference` / `isImageReference` /
  `isAudioReference` and `StorySpeaker.avatarPattern`; the parts of a
  reference; seven refusals of the Laboratory's own file changed in one
  place each, with the exact messages): **28 passed** at the first run.
- **After the change**: the same 28 unchanged, and 25 on the owner (each
  pattern's text against the earlier literal; the model and the media store
  hold the owner's own patterns and sets; the kinds of file equal to the
  ones the patterns name; the twenty references asked of the owner; the
  stored file's name and the path in a package; the walk of a Course
  file): **53 passed** (52 before the review's follow-ups, three runs of
  three).
- The change was made by `apply_r8.py` (exact texts, each asserted to match
  once; it also asserts that no copy of the pattern is left in the three
  `lib/` files). One line the formatter rewrapped in
  `course_media_store.dart`, unrelated to the change, was put back.
- Focused files (24): the one above, `course_media_243_test`,
  the Course package tests (`course_package_243_test`,
  `course_package_import_247_test`, `course_package_on_disk_tranche4b_test`,
  `course_package_media_recovery_245_test`, `publisher_package_243_test`,
  `demo_package_roundtrip_254_test`), `sign_course_media_270_test`, the
  import tests (`import_side_doors_270_test`, `import_safety_271_test`,
  `import_route_matrix_revision19_test`), `story_model_256_test`,
  `course_model_v11_243_test`, `course_model_v12_256_test`,
  `guidebook_modules_266_test`, `bundled_courses_225_02_test`,
  `course_merge_media_workflow_246_test`, the backup tests
  (`course_backups_270_test`, `course_backup_missing_asset_test`),
  `audio_library_media_248_test`, `publisher_recorded_audio_test`,
  `media_attribution_test`, `plural_pictures_265_test`:
  **316 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review

A second reader (read only, no access to this session's reasoning) compared
the change with the commit before it: **no behaviour difference found**.

- The six pattern texts, worked out from the owner's pieces by hand and by a
  script, are character for character the earlier literals (the Story
  avatar's included).
- Groups: the signing tool's pattern now has the hash as group 1 where it
  had the extension, but the tool only asks whether a text matches; the
  media store reads group 1, the hash, before and after.
- `checkCourseJson` and the old `_validateMediaReferences`: the same text
  after the three renames, called at the same place of `Course.fromJson`, so
  the same error wins when a file has several faults.
- The new file imports only the bundled-asset rule: no Flutter, no cycle;
  the signing tool gains only that import.

What it pointed out, and what was done before the suite:

- The pattern was written in **nine** places, not eight (the media store
  had two): the documents and the owner's comment say nine.
- The media store kept its own list of the kinds of file
  (`audioExtensions`, `imageExtensions`), which had to stay equal to the
  owner's by hand: the two sets are the owner's now, the store's names
  point at them, and a test compares the patterns' kinds with the sets.
- `CourseMediaReference.isAny` had no user: `CourseMediaStore.isReference`
  asks it.

Left as they are, on purpose: `tools/convert_course_to_v12.dart` (a looser
pattern that only takes the hash out of a name) and
`tools/validate_courses.py` (Python, cannot read the Dart owner); the places
that build a name with `'media:'` in front of a file name (they make a
name, they do not check one).

After these: analyzer **No issues found**; the new test file 53 passed;
seven affected files 147 passed.

### Complete suite

First run (13 October 2026, 02:55–04:19; 83 min 34 s instead of the usual 45, the PC was busy): 4,470 passed, 1 skipped, **1 failed**: `qql_230_course_persistence_hardening_test`, "Course Manager surfaces corrupt storage instead of spinning". Its wait for Course Studio to read the stored Courses has a guard against a wait that never ends, and the guard's 10 seconds ran out. Nothing of this revision is involved: the file passed alone 4 times out of 4 (8 tests, about 11 seconds each). Done before the second run: the guard is 30 seconds (`test/support/pump_file_io.dart`, used by 75 test files; it only matters when a wait fails), and the disposable test folder `D:\QQL_test_temp` (4,182 leftover entries, 1.2 GB; D: had 2.1 GB free) was emptied. Second run on the final tree (04:32–05:51, 77 min 47 s, the PC still busy), `flutter test --no-pub --concurrency=1`: **4,471 passed, 1 skipped, 0 failed**. Revision 7's suite had 4,418; the 53 more are this revision's test file.

## Revision 9 (2.0.72+272009), shared readers for a Course file

13 October 2026, owner's Windows 10 PC, `build-272`.

- **Before the change**: `test/json_read_272_test.dart`, 6 cases on the
  Laboratory's own file broken in one place each, with the exact words:
  **6 passed**. Two of my first expectations were wrong and were corrected
  to what the code says (never the code): an exercise without `prompt` is
  refused by a check of its own ("Exercise requires prompt[] and an
  evaluation object."), and so is `course.sectionNames` ("course.sectionNames
  must be a list of strings."), so the models' wording for a list of texts
  is pinned on a content's `sourceRefs` instead.
- **After the change**: the same 6 unchanged and 9 on the readers
  themselves: **15 passed**, three runs of three.
- The renaming (`apply_r9.py`): 135 calls in `course_models.dart`, 32 in
  `exercise_canonical.dart`; no old name is left (asserted). `same_code.py`
  compared each formatted file with the renamed old text, all white space
  and the commas before a closing bracket ignored: **the same code**
  (151,936 and 19,531 characters).
- Both files were fully formatted before (checked on their committed
  versions), so every re-wrapped line of the diff comes from a longer name.
- Focused files (26): the one above,
  `course_media_reference_272_test`, the Course model tests
  (`course_model_v12_256_test`, `course_model_v11_243_test`,
  `course_model_v6_test`, `course_model_v9_clean_cut_test`),
  `negative_cases_256_test`, `semantic_equality_256_test`,
  `canonical_primitives_256_test`, `runtime_canonical_256_test`,
  `laboratory_future_256_test`, `exercise_architecture_224_test`,
  `imported_course_v6_regression_test`, `bundled_courses_225_02_test`,
  `story_model_256_test`, `guidebook_modules_266_test`,
  `import_side_doors_270_test`, `import_route_matrix_revision19_test`,
  `course_package_243_test`, `demo_package_roundtrip_254_test`,
  `editor_notes_267_test`, `plural_pictures_265_test`,
  `page_card_258_test`, `stored_course_edge_cases_266_test`,
  `publisher_verification_test`, `sign_course_media_270_test`:
  **334 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review

A second reader (read only, no access to this session's reasoning) compared
the three files with the commit before them, with a small lexer of its own:
**no behaviour difference found**.

- The 14 old helpers equal their `JsonRead` function token for token: the
  same conditions in the same order, the same values returned, the same
  `FormatException`, every message byte for byte. Each of the two pairs that
  differed is the faithful copy of the right old helper.
- Calls, counted before and after: `course_models.dart` 135 and 135
  (`_stringList` 6 → `stringListByKey` 6, `_mapList` 13 → `requiredList` 13);
  `exercise_canonical.dart` 32 and 32 (`_stringList` 8 → `stringList` 8,
  `_mapList` 4 → `optionalList` 4). No call crossed from one rule to the
  other.
- All 167 calls were paired in order and their arguments compared: 0
  differences, the 56 calls that span several lines included. Each whole
  file, renamed and without its helper block, is the new file token for
  token (30,200 and 4,284 tokens).
- No old name is left, none was passed as a value, no other file used them;
  `json_read.dart` imports nothing, so the tools that run with `dart run`
  are unaffected.

What reading alone could not show (that the files compile, and that the
tests pass) is covered by the analyzer run and the suite. One visible
difference outside the app's behaviour: a logged stack trace names
`JsonRead.requiredString` where it named `_requiredString`.

### Complete suite

13 October 2026, 06:03–06:44, `flutter test --no-pub --concurrency=1` on the final tree: **4,486 passed, 1 skipped, 0 failed** (39 min 48 s). Revision 8's suite had 4,471; the 15 more are this revision's test file.

## Revision 10 (2.0.72+272010), one wording, one rule for a list that may be left out

13 October 2026, owner's Windows 10 PC, `build-272`. A behaviour change by
the owner's decision.

- **What the code said before** (a probe run on Revision 9, then removed):

  | Case | Before |
  |---|---|
  | GuideBook module, `sentences` and `words` written as `null` | refused: "guidebook module.sentences must be a list." |
  | GuideBook module, `words` a text | refused: "guidebook module.words must be a list." |
  | Earlier exercise shape, `items` a text | read as an empty list |
  | Earlier exercise shape, `items` and `layout` as `null` | read as empty |
  | Earlier evaluation, `correctItemIds` a text | refused: "correctItemIds must be a list." |
  | Earlier evaluation, `acceptedAnswers` holding a number | refused: "acceptedAnswers must contain strings only." |
  | Earlier evaluation, `pairs` a text | refused: "pairs must be a list." |
  | Earlier evaluation, a pair of one text | refused: "pairs entries must contain exactly two strings." |
  | Earlier evaluation, `correctOrders`, `correctItemIds`, `pairs` as `null` | read as empty |
  | A card's `actions` a text | refused: "actions must be a list." |

- **After**: `test/json_read_272_test.dart`, **19 passed**, three runs of
  three: the 15 of Revision 9 with the cases that changed rewritten (the
  models' wording; the readers' own cases without `stringListByKey`,
  `pairList` with its place), and 4 new (every list of the models tells its
  place and its field; a list written as `null` is a list left out; a list
  that may be left out but is not a list is refused; a list left out is an
  empty list of its own kind, run on every exercise of the Laboratory that
  leaves `targets` or `items` out).
- The change was made by `apply_r10.py` (exact texts, each asserted to
  match once); the diff of `course_models.dart` read whole: seven renamed
  calls and seven checks replaced, nothing else.
- No other code matches on the old wordings (`tools/validate_courses.py`
  has messages of its own, in Python).
- Focused files (26): the one above, the Course model tests,
  `negative_cases_256_test`, `semantic_equality_256_test`,
  `canonical_primitives_256_test`, `runtime_canonical_256_test`,
  `laboratory_future_256_test`, `exercise_architecture_224_test`,
  `imported_course_v6_regression_test`, `bundled_courses_225_02_test`,
  `story_model_256_test`, `guidebook_modules_266_test`,
  `guidebook_authoring_aids_266_test`, the import and package tests,
  `editor_notes_267_test`, `plural_pictures_265_test`, `page_card_258_test`,
  `stored_course_edge_cases_266_test`, `exercise_laboratory_254_test`,
  `course_media_reference_272_test`: **605 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review

A second reader (read only, no access to this session's reasoning) checked
the change against the two decisions.

**Confirmed**: every change in the two files is one of the two; the seven
replaced checks, input by input (absent, `null`, a list of objects, an empty
list, a list holding a non-object, a text, an object, a number): only two
cells change, the ones intended (a GuideBook module's `sentences` / `words`
as `null`: refused, now empty; the earlier exercise shape's `items` /
`layout` when not a list: empty, now refused); each new wording is the old
one with its place in front, and the place is the one each factory uses in
its other messages. No other code matches on the old wordings. Every writer
of QQL writes a real list or leaves the key out, so no file QQL wrote is
refused now or was before; no bundled Course or fixture holds a `null` list.

**Found, and fixed before the suite**: a list left out came back from the
shared reader as an empty list "of nothing" (a bare `const []` in a generic
function is a `List<Never>`), where the checks written at each place gave an
empty list of exercise items, targets or layout pieces. Nothing in `lib/`
was found to stumble on it, but a search with a fallback
(`firstWhere(…, orElse: …)`) or an `add` on such a list throws. The reader
now returns `List<T>.unmodifiable(…)`; a test first showed the fault
(`type 'String' is not a subtype of type 'Never'`) and passes with the fix.

**Corrected in the documents**: the readers' comment and the format
document claimed more than is true. Seven lists of the Course root
(`sectionNames`, `keywords`, `authors`, `rightsHolders`, `lessonIconAssets`,
`audioLibrary`, `defaultTimedLimitsSeconds`) are still read by checks of
their own and are named as such; a module's `sentences` / `words` are always
written, so "written only when not empty" was wrong.

**Known and left**: the earlier exercise shape is read only by the converter
from v11 (`tools/convert_course_to_v12.dart`,
`tools/convert_stored_courses_256.dart`), never by the app: a v11 file with
`items` that is not a list now stops the conversion with
"interaction.items must be a list.". `tools/validate_courses.py` still
reports a module's `sentences` / `words` written as `null`; it checks QQL's
own files, which never have one.

### Complete suite

13 October 2026, 07:11–07:49, `flutter test --no-pub --concurrency=1` on the final tree (after the review's fix; 12 affected files had been run again first, 359 passed): **4,490 passed, 1 skipped, 0 failed** (37 min 55 s). Revision 9's suite had 4,486; the 4 more are this revision's new cases.

## Revision 11 (2.0.72+272011), the Merge page's choices

13 October 2026, owner's Windows 10 PC, `build-272`.

- **Before the change**: `test/course_merge_selection_272_test.dart`, 10
  cases on the Course Merge page as it was (no side offered for equal
  settings; the ten sides offered in order; what is handed to the merge
  with every setting Left, with four Right, with all Right; the rows and
  the cell that cannot be ticked; Select all Right, Select all Left after
  it, Select all Left with the shorter Course on the left; a Lesson from
  one Course or from neither): **10 passed, six runs of six**. Two of my
  first cases opened the page twice in one test and were split; the app
  was right.
- **After the change**: the same 10 unchanged and 5 on the owner: **15
  passed, six runs of six**.
- The change to the page was made by `apply_r11.py` (exact texts, each
  asserted to match once; it asserts that no old name is left); the diff
  read whole: 34 lines added, 177 removed.
- Focused files (8): the one above,
  `course_merge_submission_246_test`, `course_merge_media_workflow_246_test`,
  `course_merge_service_test`, `course_manager_workflow_249_test`,
  `course_package_import_ui_247_test`, `courses_screen_250_test`,
  `course_library_operations_249_test`: **104 passed**.
- `flutter analyze --no-pub`: **No issues found**.

### Independent review

A second reader (read only, no access to this session's reasoning) compared
the page and the owner with the commit before them: **no behaviour
difference found**.

- The ten settings: the same order, the same labels, the same conditions
  for offering a side, and every field of the merged Course's settings
  taken from the same side as before (the numbering with its custom label,
  the flag with its three fields).
- The choices: the same rows and starting values, the same Select all, the
  same tick and untick, DO MERGE! greyed in the same states (also with no
  rows), and the list handed to the merge still a copy of its own.
- The page: the same branch in every state; the dropdowns' keys the same
  texts; each change of the selection once, inside `setState`; loading that
  fails leaves the selection as it was, as the old fields were left.
- No other code used the removed members; no test reads this page's source.

Two differences in theory, neither reachable in the app: the left Course is
taken once when the second is loaded, where the old code read it at each
use (the one caller always passes the same Course); and a tap delivered
between two overlapping loads would now write into the selection being
replaced, where it wrote into the new list.

### Complete suite

13 October 2026, 08:06–08:48, `flutter test --no-pub --concurrency=1` on the final tree: **4,505 passed, 1 skipped, 0 failed** (41 min 7 s). Revision 10's suite had 4,490; the 15 more are this revision's test file.

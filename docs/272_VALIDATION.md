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

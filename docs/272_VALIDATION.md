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

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

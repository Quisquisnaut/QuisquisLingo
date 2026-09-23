# Build 250 handoff

## Revision 0 source state

Build 250 Revision 0 is `2.0.50+250000`, Course Model v11, on
`codex/build-250-courses`, implementing
roadmap Steps 3 and 4 together. The starting baseline was Build 249 Revision
2 on `main`, as recorded in
[250_COURSES_SCREEN_PLAN.md](250_COURSES_SCREEN_PLAN.md). See
[250_CHANGE_SUMMARY.md](250_CHANGE_SUMMARY.md) for behavior and file ownership.
Beta expiry is `2026-10-23 23:59:59` local time.

The one **Courses** screen owns ALL COURSES and COURSE MANAGER tab selection,
shared Sort by / Show unavailable controls, and Import return navigation.
The former Course Library and Course Manager widgets remain the tab bodies;
their rows share one renderer. ALL COURSES owns Search, Favorites and
membership actions. COURSE MANAGER keeps the Build 249 operations owner and
rights decisions. Both tabs offer Hide / Unhide in Learner. The Selector
groups Current, Recent, Favorites and Other and uses the same per-learner
Favorite and Hide services. Locked Course Manager and Course Editor entries
remain visible with the profile unlock explanation.

Successful Import returns a `Course` to its caller, including Copy and Fork;
the latter no longer opens the Editor. The Courses caller selects ALL COURSES
and highlights the result. The Selector caller returns Home and offers Study
now only when the learner delivery rules allow it. The received-Custom-Course
exception is device local and is rechecked under the Course storage lock;
ordinary authoring rights and signed Publisher updates remain separate.

The new stored flags, their reset/inventory scope and the clean cut for the
retired hidden key are in the plan and
[239_RESET_STORAGE_INVENTORY.md](239_RESET_STORAGE_INVENTORY.md). Manager
operations Help is separate from editing Help, with English/Italian section
parity. Course Model v11, package format 1 and the top-level Course save
boundary stay unchanged.

## Tested source state

The uninterrupted solo `flutter test --no-pub --concurrency=1 --reporter
expanded` run passed **2,402/2,402**. `flutter analyze --no-pub` found no
issues; bundled Course, image, Lesson icon and media validators all passed.
Focused red/green tests covered the received-update World Flag and assigned
Team rules, phone-width Import dialog and narrow All Courses row. The exact
commands, exploratory failures and corrections are in
[250_VALIDATION.md](250_VALIDATION.md). Manual smoke testing and platform
release artifacts are separate from source validation.

## Known limits

* Custom received updates are unsigned. The accepted impersonation risk and
  its narrow constraints are recorded in the change summary and roadmap;
  signed Custom Courses require a later trust and package-format decision.
* The received flag and Course file are separate stores. A process crash
  between writing the provisional flag and creating its Course file may leave
  a stale flag with no Course. Caught pre-commit failures clear it; an import
  under that ID reconciles the flag from the stored Course and local author.
* No existing stored Course is inferred to be received. No retired
  `course_hidden_` value is converted; Build 250 reuses the key as a clean
  cut because there were no released users when the decision was made.
* Copy and merge title suggestions still check only the active profile's
  Personal Library, not every Course stored on the device.
* The known `CourseProjectsScreen._openUser` default Editor service wiring
  and inert `CourseEditorScreen.transferService` are unchanged.

## Next revision sequence

1. **Build 250 Revision 1 only if a defect is later proven:** make a narrow
   correction with a failing characterization, its own validation, handoff
   and local commit. Later corrections receive the next revision number;
   none is assumed in advance.
2. In the following roadmap build, begin **Step 5, Revision 0**: give the
   Course Editor's immediately written device preferences and seven-day
   orphan-audio schedule one owner, preserving timing and dialogs. Start
   from the then-current baseline in a separate task.
3. Change the automatic orphan prompt's interaction with a dirty working
   copy only in a later revision if the owner chooses a rule. Signed Custom
   Course updates and other paused architecture work remain separate.

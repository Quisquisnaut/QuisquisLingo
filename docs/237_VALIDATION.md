# QQL 237 validation

Validation target: `2.0.37+237004`, **Build 237, Revision 4**.
The 30-day Beta expiry is `2026-10-17 23:59:59` local time.

## Scope

- Course Manager exposes Merge only for custom Courses with the established
  operational access capability.
- Merge reads only `Documents/QuisquisLingo/Merges/merge.json`; QQL creates
  the folder as needed and never modifies the input or source Courses. A
  matching Course ID is valid when the two source versions differ.
- Compatible custom v9/v10 sources produce a v10 third Course with immutable
  immediate-source merge provenance. Existing v9 data remains readable without
  migration or conversion.
- The output keeps selected Lesson Draft/Published state, uses fresh owned
  identities, has no inherited learner state, appends ` merged` to its title,
  retains the earliest Original Course Created date, records merge-time
  modification/editor metadata and starts at custom Course version 1.
- Source Course publication state may differ; either unpublished source makes
  the output unpublished. Create Duels, Use GuideBooks, Lesson
  numbering/custom label and Section names may differ and use an explicit
  Left/Right selection.
- Revision 1 accepts differing Title, Buy a Coffee URL, description, flag and
  start/target levels through explicit Left/Right choices. The merge view
  identifies both sources by title/version/edit date, reuses the Editor ID
  badge and keeps the aligned compact comparison table legible at narrow
  widths.
- Revision 2 assigns the first available progressive suffix when a merged
  Course title already exists, uses failure sound feedback for invalid or
  missing merge/import JSON, and adds Debug Help plus the current Course-type
  reference to Editor Help. The startup Crash Log notice is shorter while its
  full reporting and privacy guidance remains available in Debug Help.
- Revision 3 places Select all Left/Right after the available Course-setting
  selectors, permits same-ID/same-version sources only when their Last edited
  timestamps differ, records both source timestamps in merge provenance, and
  explains where the resulting Course appears. The new per-profile Welcome
  Wizard appears once for existing and new learners, and Show one-time notices
  again resets its completion marker without changing learner data.
- Revision 4 defers the Welcome Wizard until a PIN-protected learner has
  successfully unlocked their profile, so its completed state is persistently
  recorded. Beta testing acknowledgement is now a resettable global one-time
  notice. The five Wizard steps use concise, legible color-coded identities.

## Execution

| Check | Result |
| --- | --- |
| Focused Course Model/Merge/Manager/Debug tests | PASS: 77 tests |
| `flutter analyze --no-pub` | PASS: no issues |
| `flutter test --no-pub --concurrency=1` | PASS: 1,568 tests |
| `python tools/validate_courses.py` | PASS: 10 bundled v9 courses |
| `python tools/validate_images.py` | PASS: 111 assets, 0 issues |
| `python tools/validate_media_assets.py` | PASS: 443 files, 19 locked audio, 281 World Flags, 0 issues |
| `git diff --check` | PASS |

# Course Library (Build 244) — handoff

Keep this file current after **every** commit and at least every 30 minutes
while working. Plan and decisions:
[COURSE_LIBRARY_244_PLAN.md](COURSE_LIBRARY_244_PLAN.md). Rules: `AGENTS.md`.
Release checklist and gotchas: see
[IMPORT_HARDENING_HANDOFF.md](IMPORT_HARDENING_HANDOFF.md) (same checklist,
with `docs/244_CHANGE_SUMMARY.md` and `docs/244_VALIDATION.md`).

## Where things stand (updated 2026-09-22)

| Revision | Version | Commit | Content |
|---|---|---|---|
| 1 | `2.0.44+244001` | `4516bd0` | Draft predicates extracted to `lib/models/course_draft_status.dart` |
| 2 | `2.0.44+244002` | `0c96cf5` | Rename to Course Library; availability switch; Draft / Unpublished / Verification required badges |
| 3 | `2.0.44+244003` | `711f29a` | Bordered sections with counts; My/Other Local Courses; web section hidden (`courseLibraryWebSite = null`) |
| 4 | `2.0.44+244004` | `0c993bf` | Richer rows; `CourseArtwork` cover-or-flag; `CourseLibraryPresentation` version/date/duration |
| 5 | `2.0.44+244005` | `b388e67` | Sort by inside each section; Beta expiry → 2026-10-22 (release dated 2026-09-22) |
| 6 | `2.0.44+244006` | (this commit) | Expanded/Compact per section |

The untracked `devtools_options.yaml` predates this work and must not be
committed or deleted.

## Next steps

Revision 7 next: Help rewrite (plan §2.11), Editor Help/Info sentence, then
the full suite once before committing. The web section is gated by `courseLibraryWebSite` (null), not the
`_courseWebSiteAvailable` flag named in the plan. The full
suite runs once, before the Revision 7 commit.

## Working notes

- Beta expiry: releases dated 2026-09-22 use **2026-10-22 23:59:59**
  (moved in Revision 5). If a later revision is released on another date,
  apply the 30-day policy again (`beta_lifecycle_service.dart`,
  `beta_lifecycle_test.dart`, `leaderboard_navigation_test.dart`, README).

- Release helpers used for each revision (scratchpad, not in the repo): bump
  the version in `pubspec.yaml`, `app_metadata.dart` and the four version
  tests; add CHANGELOG, README, `AGENTS.md`, `docs/244_CHANGE_SUMMARY.md` and
  `docs/244_VALIDATION.md` entries.
- Rows are keyed `device-course-<id>`; titles `device-course-title-<id>`.
  Lazy `ListView`: tests that need late rows use a tall surface.
- Dates use `formatShortDate` (`formatMediumDate` has no year).
- The shared test Course builder is `test/support/course_library_fixtures.dart`.
- The formatter check: `dart format --output=show <file>` inside the repo.
  Formatting a copy outside the package uses another language version.

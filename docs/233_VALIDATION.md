# QQL 233 validation

Validated for QuisquisLingo `2.0.33+233030`, Phase 233.3 revision 0, on the QQL 232 baseline.

## Phase 233.1 — Linux updater

The repository packages Linux as `quisquislingo_linux_alpha_<buildnumber>.zip` and Windows as `quisquislingo_windows_alpha_<buildnumber>.zip`. The updater previously exposed Linux only as `linuxAntix` and required the asset name to contain `antix`, so the real generic Linux ZIP was reported unavailable. No architecture-specific package convention exists in the packaging output.

`UpdatePlatform` now recognizes the generic `linux` operating-system value. Asset matching accepts the real Linux marker and the retained historical antiX marker only with compatible Linux archive/package extensions, rejects conflicting platform markers, and never falls through to a Windows or source package. Windows selection and the existing GitHub Releases comparison/no-release policy are unchanged. A Release can remain newer while exposing no usable asset for the selected platform.

Focused updater coverage uses the real Build 232 package names and verifies Linux/Windows recognition, cross-platform rejection, incompatible/source rejection, no-compatible-package handling, version comparison and trusted Release URLs.

## Phase 233.2 — Learner profile, avatar and Status

New Learner creation is one two-step transaction: **Create Profile** records Screen Name and an optional Discord name, then **Avatar Customization** edits the same stable learner ID. Discord input does not require `@`; stored presentation is normalized to one leading `@`. It is backed up/restored as display metadata and is never used for identity, progress, ownership, Team membership or authorization.

Only a new profile receives randomly selected initial skin and hair values. Existing profile appearance is read without randomization, and both choices remain editable. T-shirt color is no longer a preference: `LearnerAvatar` maps the current authoritative Status rank directly to the ten confirmed vivid colors. Profile, Avatar Customization and the active learner bottom icon refresh from existing XP, streak, distinct-study-day, completed-Round and Laurel invalidations.

Avatar Customization prominently shows the current Status, the live level-colored avatar, all ten names and visible color samples, and a marked Current row. Its Help text states the existing score formula and thresholds rather than introducing new progression rules.

Focused coverage verifies profile/Discord persistence and backup, no-Discord creation, stable identity across edits and both creation steps, new-only random skin/hair, editable appearance, exact Status names/colors/threshold behavior, level-driven shirt changes, all-level/current-level presentation, Help text, and absence of a manual shirt control.

## Phase 233.3 — Course ownership, Team assignment, identity and UI composition

Course Model v8 is a clean cut. A custom Course has immutable individual Creator provenance, one individual Owner, and an optional separate `assignedTeamId`. Team ownership is rejected. The v8 custom/official storage namespaces do not read or rewrite older custom namespaces.

The Creator may choose any existing local individual as initial Owner. Only the current Owner in Course Editor Edit mode can transfer ownership, assign a Team after the required warning, or revoke the assignment. These changes preserve Creator and Course identity. Team members receive the established management access through the assigned Team, but neither membership nor Team leadership grants ownership-transfer or assignment power. Team governance remains independent: the creator is the first Team Leader, any Leader manages membership and Leader roles, and service checks prevent removal or demotion of the final Leader.

Course Info distinguishes Creator, Owner, assigned Team, Team Leaders and ordinary Team Members. User presentation prefers normalized Discord `@handle` and falls back to Screen Name, while every decision continues to use the stable user ID. The existing Internal IDs control remains the only toggle. Official publisher provenance is presented as publisher information rather than individual Course ownership. Team Manager includes the experimental-model Help and the limits of QQL permissions.

The underlying learner-shell composition was corrected: only `home_screen.dart` mounts `LearnerStatusPage`/`LearnerStatusAppBar`. Course Info and all editor/manager screens use ordinary scaffolds, while the Learner Panel retains the status bar. The bottom row remains Profile at the far left followed by the existing six compact controls.

Focused governance and retained QQL 229 coverage exercise individual-only ownership, another initial Owner, Owner-only/Edit-only transfer, immutable Creator, warning confirmation/cancellation, assignment/revocation, no self-assignment, Team/Course authority independence, multi-Course Team assignment, Leader invariants, Discord/Screen Name presentation, ID visibility, Course Info role labels, management-screen status-bar absence and learner-bottom ordering.

## Version, model and validation evidence

- Application: `2.0.33+233030`; display: `Version 2.0.33`, `Phase 233.3, revision 0`.
- Course Model: v8 (`formatVersion: 8`).
- Alpha expiry: `2026-10-14 23:59:59` local time.
- Focused QQL 233/retained suites: **PASS — 87 tests**.
- Corrected logout-navigation regressions: **PASS — 2 focused tests**.
- Full analyzer: **PASS — no issues**.
- Bundled Course validator: **PASS — 9 Course Model v8 files and canonical checksums**.
- `git diff --check`: **PASS** (Git emitted only the repository's line-ending conversion warnings).
- Full Flutter suite: **1,428 passed, 1 unchanged order-dependent TTS test failed**. All QQL 233 and repaired Profile-navigation coverage passed in the full run.
- Files changed: **86 working-tree entries** — 4 root metadata/docs, 9 bundled Course assets, 8 files under `docs/`, 34 under `lib/`, 28 under `test/`, and 3 under `tools/`; 78 are tracked modifications and 8 are new files.
- Release actions: none. The working tree remains uncommitted and unstaged, with **0 staged files**.

The first sequential full-suite run completed with 1,424 passes and three failures: two legacy Profile-test helpers scrolled a fixed distance that no longer reached the logout control after the requested Profile content was added, and one unchanged TTS voice-resolution test failed only in the full-run ordering. The two helpers now scroll to the keyed control; both focused reruns and both tests inside the final full suite pass. The unchanged TTS file passes 10/10 in isolation but reproduced its single failure only in the final full-run ordering. No TTS production or test file changed in QQL 233, so this is recorded as a pre-existing order-dependent/flaky failure rather than a QQL 233 regression.

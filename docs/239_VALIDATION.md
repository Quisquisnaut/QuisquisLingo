# QQL 239 validation

Validation target: `2.0.39+239005`, **Build 239, Revision 5**.
The 30-day Beta expiry is `2026-10-19 23:59:59` local time (30 days from
2026-09-19). Course Model v9/v10 is unchanged.

## Scope

- Revision 2: Pick the translation (Select) exercise types.
- Reliability: Course Manager unlock (10 taps) and Flag Game (5 taps) triggers
  no longer wait for or depend on audio; a failed sound player is discarded.
- Abnormal-termination detection (Windows/Linux): session marker file, an
  `abnormal termination detected` Crash Log entry at the next start and a
  `session ended cleanly` entry at clean shutdown.
- Device Administration (admins only): Update shortcut, device-wide
  `Ask who is learning at startup`, Inventory of user-created and user-added
  files, Help, and five PIN-gated, explained resets (`AppResetService`).
  Storage inventory: `docs/239_RESET_STORAGE_INVENTORY.md`.
- Update notice: the startup check runs on every launch; each learner is told
  at most once a day per release (`Not today`).
- Learner list: the only admin cannot be deleted (explained in the menu).

## Results

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test --no-pub --concurrency=1` (full suite) | 1738 tests, all passed |
| `git diff --check` | No whitespace errors |
| `tools/validate_courses.py`, `validate_images.py`, `validate_media_assets.py` | Not run: Python is not installed on the validating machine. No file under `assets/` was changed in this release. |

## Manual visual checks still recommended

1. Device Administration and its Help at narrow and wide window sizes, light
   and dark.
2. A small reset and the full wipe on a throwaway profile; the app must land
   on first-run setup after the wipe.
3. `Ask who is learning at startup` with two learners, including a PIN.
4. Ten taps on Version and Build, five taps on the Settings title.
5. The update popup: `Not today`, and again the next day.

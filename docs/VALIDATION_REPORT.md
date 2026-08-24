# QuisquisLingo 2.0.8+208 release validation report

Date: 23 August 2026

## Baseline and scope

- Build 208 starts from the completed `2.0.7+207` display-rebranding baseline.
- The package version is `2.0.8+208`.
- The established 30-day Alpha policy is unchanged. Build 208 expires at the end of 22 September 2026.
- Application-owned package/plugin names, internal symbols, executable/application identifiers, preference keys, serialization markers, course namespaces and diagnostic environment variables now use QuisquisLingo branding without legacy compatibility aliases or migrations.
- The update checker and release URL trust boundary now use the new `Quisquisnaut/QuisquisLingo` repository without an old-repository fallback.
- Learner behavior, course behavior, XP/scoring rules, wallpaper/settings behavior and Course Editor structure are unchanged. Phase 2 modularization is not part of build 208.

## Lightweight validation

- Dart formatting was limited to changed files; formatter-only churn outside the rebrand was excluded from the final diff.
- Repository searches classified every remaining case-insensitive occurrence of the former name.
- Package metadata and generated dependency metadata were refreshed with `flutter pub get` without running Flutter analysis or tests.
- `git diff --check`, final status inspection and full diff review were completed.

## External Flutter validation

- `flutter analyze` and `flutter test` were intentionally not run in this change session at the user's request.
- The bundled course validator, Image Bank validator and full release-validation script were also left for the user's external validation to avoid duplicating that script.

## Platform notes

- Windows now builds `quisquislingo_app.exe`; its internal name, original filename and product name use `quisquislingo_app`.
- Linux now builds `quisquislingo_app` with application ID `com.example.quisquislingo_app`.
- The checked-in macOS runner subset contains no branded bundle identifier or display metadata to rename. Android and iOS runner projects are not present in this source tree.
- No Windows release bundle was built or launched during this lightweight validation.

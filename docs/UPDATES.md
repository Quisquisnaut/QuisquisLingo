# QuisquisLingo update checking

QuisquisLingo remains offline-first. Settings > Update is the only application feature that deliberately contacts a remote HTTP service.

## Source of truth

Repository:

`https://github.com/Quisquisnaut/QuisquisLingo`

Latest-release API:

`https://api.github.com/repos/Quisquisnaut/QuisquisLingo/releases/latest`

Only a published GitHub Release is treated as an available application version. Repository commits and ordinary tags are not used as update notifications.

## User controls

- Current version is shown immediately before Update at the bottom of Settings.
- Manual **Check for updates** is always available.
- **Check automatically at startup** is off by default.
- Failed automatic checks are silent and never block offline use.
- Last checked records the time of the most recent manual or automatic attempt.

## Download and installation

QuisquisLingo does not download, install, extract or execute update assets. If a newer release exists, the user can open the validated GitHub release page in the system browser and follow the installation instructions shown in the app.

The installation sections always use this order:

1. Windows
2. macOS
3. Linux antiX
4. Android
5. iOS
6. Web

A platform is marked **Available in this release** only when the release contains a conservatively recognized matching asset. Otherwise it is shown as **Not currently available in this release**.

For reliable asset detection, release asset filenames should include a clear platform marker, for example `windows`, `macos`, `antix`, `android`, `ios`, or `web`, or use a recognized native suffix such as `.msi`, `.exe`, `.dmg`, `.pkg`, `.apk`, `.aab`, or `.ipa`.

## Security boundary

The checker:

- uses a hard-coded HTTPS GitHub API URL
- sends no learner, progress, course, profile or analytics payload
- uses no authentication token
- rejects redirects
- limits the response body to 256 KiB
- accepts only supported semantic release versions
- validates GitHub release URLs before opening them
- strips control and bidirectional-override characters from release text before display
- treats release notes only as text
- never fetches or executes release assets

Update functionality must remain isolated from course import/export and learner-data import/export.

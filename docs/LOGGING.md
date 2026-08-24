# Startup Trace, Crash Log and Diagnostic Log

QuisquisLingo keeps three separate troubleshooting logs with different purposes.

## Startup Trace

The Startup Trace records concise native and Dart lifecycle boundaries needed to diagnose an application that does not start. Normal tracing is enabled by default in Alpha builds. It includes a session header with the diagnostic schema, a unique session ID, UTC start time, app version/build, Alpha status, build mode, platform, CPU architecture and diagnostic level.

On Windows, the active trace is:

`%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log`

If that location cannot be used, QuisquisLingo falls back to:

`%TEMP%\quisquislingo_startup_trace.log`

For a support investigation, verbose tracing can be enabled before launching the app by setting:

`QUISQUISLINGO_STARTUP_DIAGNOSTICS=verbose`

Verbose mode adds low-level runner and window checkpoints. It does not use or change SharedPreferences. Restart without that environment variable to return to normal tracing.

The active trace rotates at approximately 1 MiB and keeps at most two previous files (`.1` and `.2`). Startup trace records exclude learner/profile names, course content, learner answers, command lines, usernames and full personal paths. Logging failures are ignored and never block startup.

## Crash Log

The Crash Log is an automatic text file. It is created or recreated when the app starts and is appended when QuisquisLingo catches an uncaught Flutter/Dart error. Settings shows the actual path used on the current platform. On Windows Alpha builds, the easy-to-find visible copy is `Documents\QuisquisLingo Logs\quisquislingo_crash.log`.

Each launch appends a session header with the app version, operating system, architecture, locale, Dart runtime and build mode. If a crash-log file is deleted, append mode recreates it at the next launch or diagnostic write. Uncaught Flutter/Dart errors are recorded in all non-web build modes, while detailed action breadcrumbs remain debug-only. Logs remain local and are never uploaded automatically.

The startup Alpha testing popup refers to this Crash Log.

## Diagnostic Log

The Diagnostic Log is a separate internal event log stored by QuisquisLingo. It records application troubleshooting events such as coded application errors and relevant platform decisions. It is not automatically created as a user-visible file.

Settings shows the fixed export destination and provides **Export Diagnostic Log**. Export writes the current snapshot to:

`Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`

Clearing the Diagnostic Log clears only the internal diagnostic-event store. It does not clear the Crash Log or Startup Trace.

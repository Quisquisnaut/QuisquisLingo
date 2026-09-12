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

The Crash Log is intended for cases where QuisquisLingo crashes or closes unexpectedly, especially startup and runtime crashes. It is an automatic text file created or recreated when the app starts and appended when QuisquisLingo catches an uncaught Flutter/Dart error. **Settings > Debug** shows the actual path. On desktop systems, the one authoritative file is:

`Documents/QuisquisLingo/Logs/quisquislingo_crash.log`

This uses the platform's native Documents directory. On Android and iOS, the same `QuisquisLingo/Logs/quisquislingo_crash.log` structure is inside the app's private application-documents directory; **Settings > Debug > Share Crash Log** provides access through the platform share UI. QuisquisLingo does not intentionally keep another active crash-log copy in application preferences. Files left in former locations are not read, migrated, copied or deleted.

Each launch appends a session header with the app version, operating system, architecture, locale, Dart runtime and build mode. If a crash-log file is deleted, append mode recreates it at the next launch or diagnostic write. Uncaught Flutter/Dart errors are recorded in all non-web build modes, while detailed action breadcrumbs remain debug-only. Logs remain local and are never uploaded automatically.

The startup Alpha testing popup refers to this Crash Log.

## Diagnostic Log

The Diagnostic Log is a separate internal event log for problems that do not necessarily crash QuisquisLingo, including audio, TTS, recorded MP3, unexpected playback, source-resolution problems and other runtime anomalies. It records application troubleshooting events such as coded application errors and relevant platform decisions. It is not automatically created as a user-visible file.

**Settings > Debug** shows the fixed export destination and provides **Export Diagnostic Log**. Export writes the current snapshot to:

`Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`

When possible, reproduce a problem and export the Diagnostic Log shortly afterward so the relevant events are easier to identify. To isolate one specific reproducible problem, clearing the Diagnostic Log before reproduction can make the export easier to read, but clearing is optional and is not routine maintenance. For intermittent or difficult-to-reproduce problems, existing evidence may be more valuable; export the current Diagnostic Log before clearing it.

Clearing the Diagnostic Log clears only the internal diagnostic-event store. It does not clear the Crash Log or Startup Trace.

## Learner audio diagnostics

Normal learner TTS and recorded-audio requests write short correlated lifecycles to both existing logs: preparation, learner UI state, stable target exercise ID/type, prepared/active status, playback trigger, not-active suppression, source resolution, backend initialization, playback, failure where applicable, and disposal. Each lifecycle writes at most eight events. Events contain only bounded technical tokens, generated correlation IDs and small counts. Learner audio diagnostics are designed to avoid spoken text, answers, course content and full personal file paths. Authoring Preview preserves its established no-write boundary and does not persist these events.

When a listening exercise follows `Before you start`, source eligibility and exercise preparation may occur while the introduction remains visible. The activation lifecycle records that preparation and the suppressed not-active playback attempt. After Continue makes the exercise active, the log records the activation trigger and normal playback request; the existing TTS or recorded lifecycle then records its source, backend, initialization, playback, failure and disposal result.

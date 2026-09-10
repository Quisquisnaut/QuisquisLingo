QuisquisLingo Alpha - Windows README
================================

This package contains the unchanged QQL 2.0.29+2293 Flutter application plus a
separate native Windows bootstrap launcher and external documentation. There are
no QQL application, UI, behavior, data, version, date or Alpha-expiry changes in
this packaging update.

START QQL
---------

Normally start:

    QuisquisLingo.exe

Shortcuts and future installers should point to that file. It resolves all QQL
files from its own package directory, performs bounded compatibility/package
preflight checks, then starts the unchanged internal Flutter application:

    quisquislingo_app.exe

Directly starting quisquislingo_app.exe remains possible and bypasses bootstrap
checks. Keep the entire extracted package together; do not distribute or move
only an EXE or selected DLLs.

BOOTSTRAP CHECKS
----------------

The launcher checks the internal app, the packaged Flutter/native runtime files,
Windows compatibility and Media Foundation. It does not download, install,
repair, elevate, change the registry or modify the system.

On native Windows earlier than Windows 10, or for another recoverable startup
problem, one consolidated warning offers Continue anyway and Cancel. Continue
anyway genuinely attempts to start QQL. A missing quisquislingo_app.exe means the
package is incomplete and is fatal; that dialog offers Close only.

Wine is detected before native Windows version policy. Wine support is
Experimental, and Wine does not receive the normal old-Windows warning.

REQUIRED FILES
--------------

The folder containing QuisquisLingo.exe and quisquislingo_app.exe must also
contain the Flutter runtime files, native plugin DLLs and complete data folder
supplied with the release.

Microsoft Visual C++ Runtime
----------------------------

The complete QuisquisLingo Windows package includes these Microsoft Visual C++ x64
runtime files beside quisquislingo_app.exe:

    msvcp140.dll
    vcruntime140.dll
    vcruntime140_1.dll

No manual Visual C++ runtime installation or DLL copying is required when the
complete package is extracted and kept together. If one is missing, first
download the complete QQL Windows package again, fully extract the entire
archive, and avoid manually copying only selected EXEs or DLLs. Installing the
official Microsoft Visual C++ Redistributable is only a secondary option; a
complete QQL package already contains these required x64 runtime files.

Official Microsoft information:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

Flutter documents this packaging model as "application-local" deployment.

Official Flutter Windows deployment information:
https://docs.flutter.dev/platform-integration/windows/building

IMPORTANT
---------

Download Microsoft runtime installers only from official Microsoft sources.

Do not download individual missing DLL files from third-party DLL websites.

Do not delete or rename files inside the QuisquisLingo Release folder.

MEDIA FOUNDATION
----------------

QQL's audio/media stack expects the operating environment to provide
MFPlat.dll. QQL does not ship a private copy of this Microsoft system library.

On native Windows, a missing MFPlat.dll warning explains that the applicable
Windows edition may require the Microsoft Media Feature Pack through its
Optional Features or edition-specific mechanism. Not every edition exposes the
same settings path.

Under Wine, the warning instead explains that Wine support is Experimental and
that missing Media Foundation may prevent startup or audio/media functionality.
The launcher does not install winetricks components, codecs, Wine packages, DLL
overrides or other workarounds.

TEXT-TO-SPEECH
--------------

QuisquisLingo uses Windows speech voices for text-to-speech. Available languages
and voices depend on what is installed in Windows. If a requested language has
no compatible installed voice, speech may be unavailable until the relevant
Windows language/voice component is installed.

Audio Settings > Test Voice opens with an empty field. It speaks only the text
you enter, using the voice language configured by the selected course.

CRASH AND DIAGNOSTIC LOGS
-------------------------

QuisquisLingo stores its Crash Log at:

    Documents\QuisquisLingo\Logs\quisquislingo_crash.log

If this file is deleted, QuisquisLingo recreates it automatically at the next
application start or diagnostic write. Settings > Debug shows the Crash Log
location and lets you export or clear the separate Diagnostic Log. Diagnostic
Log exports use the same Documents\QuisquisLingo\Logs directory.

The logs remain on the local computer and are not uploaded automatically.

STARTUP TRACE
-------------

The native launcher keeps a separate bounded diagnostic log at:

    %LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

If that location is unavailable, it falls back to `%TEMP%`. The log is limited
to approximately 128 KiB plus one previous file. It records runtime/version,
architecture, missing component names, user decision and process-creation
result. It does not record arguments, the full environment, learner/course
content or full package paths.

Alpha builds also keep a bounded startup lifecycle trace at:

    %LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log

If that location is unavailable, the fallback is:

    %TEMP%\quisquislingo_startup_trace.log

Normal tracing is enabled automatically. For a support investigation, set
QUISQUISLINGO_STARTUP_DIAGNOSTICS=verbose before launching QuisquisLingo to add safe
low-level Windows startup detail. Remove the variable to return to normal
tracing. The active trace is limited to approximately 1 MiB and keeps two
rotated previous logs. It does not contain learner answers or course content.

TROUBLESHOOTING
---------------

1. Extract the complete QuisquisLingo release archive before launching it.
2. Start QuisquisLingo.exe from the extracted folder.
3. If Windows reports VCRUNTIME140_1.dll, VCRUNTIME140.dll or MSVCP140.dll as
   missing, obtain or extract the complete QuisquisLingo Windows package again.
4. If QuisquisLingo still does not start, keep the full error message and, if
   available, send the launcher log and quisquislingo_crash.log to the developer.

EXTERNAL REFERENCE
------------------

QQL infographic.png is an external overview/reference image included unchanged
in the package root. It is not a Flutter asset and is not integrated into QQL's
UI, navigation or first-run behavior.

Alpha software may contain unfinished features or bugs.

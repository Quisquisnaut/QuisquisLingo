QuisquisLingo Alpha - Windows README
================================

QuisquisLingo is a portable Flutter desktop application. Keep the entire Release
folder together. Do not move or distribute only the .exe file.

REQUIRED FILES
--------------

The folder containing quisquislingo_app.exe must also contain the Flutter runtime
files, DLLs and the data folder supplied with the release.

Microsoft Visual C++ Runtime
----------------------------

The complete QuisquisLingo Windows package includes these Microsoft Visual C++ x64
runtime files beside quisquislingo_app.exe:

    msvcp140.dll
    vcruntime140.dll
    vcruntime140_1.dll

No manual Visual C++ runtime installation or DLL copying is required when the
complete package is extracted and kept together. If any of these files is
missing, the package is incomplete; obtain or extract the complete package
again.

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

TEXT-TO-SPEECH
--------------

QuisquisLingo uses Windows speech voices for text-to-speech. Available languages
and voices depend on what is installed in Windows. If a requested language has
no compatible installed voice, speech may be unavailable until the relevant
Windows language/voice component is installed.

DIAGNOSTIC LOG
--------------

QuisquisLingo Alpha creates a local diagnostic log at startup.

On Windows, an easy-to-find copy is stored at:

    Documents\QuisquisLingo Logs\quisquislingo_crash.log

If this file is deleted, QuisquisLingo recreates it automatically at the next
application start or diagnostic write.

The log remains on the local computer and is not uploaded automatically.

STARTUP TRACE
-------------

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
2. Start quisquislingo_app.exe from the extracted folder.
3. If Windows reports VCRUNTIME140_1.dll, VCRUNTIME140.dll or MSVCP140.dll as
   missing, obtain or extract the complete QuisquisLingo Windows package again.
4. If QuisquisLingo still does not start, keep the full error message and, if
   available, send the complete quisquislingo_crash.log file to the developer.

Alpha software may contain unfinished features or bugs.

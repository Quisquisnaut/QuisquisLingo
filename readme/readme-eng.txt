QuisquisLingo - Windows Guide
============================

QuisquisLingo is a language-learning application for learners and course
creators. It combines structured lessons, interactive exercises, audio
activities and review tools, while also providing tools for creating and
editing language courses.

It is designed both for people who want to study a language and for authors,
teachers or other users who want to build their own courses.

For a quick visual overview of how QuisquisLingo works, see
QQL infographic.png, included with the application package.

To start QuisquisLingo, run QuisquisLingo.exe.

USING THE PACKAGE
-----------------

This package contains the QQL application. Extract the entire ZIP archive
before starting it, and keep all supplied files and the data folder together.
Do not distribute, move, delete or rename individual EXE or DLL files.

STARTUP CHECKS
--------------

Before starting, QuisquisLingo checks the required package files, Windows
compatibility and Media Foundation. These checks never download or install
software, request elevation, change the registry or modify Windows.

A recoverable problem produces one message with Continue anyway and Cancel.
Continue anyway attempts to start QQL; Cancel closes it. If an essential
program file is missing, the message offers Close because the package must be
downloaded and extracted again.

Wine support is Experimental. Missing Media Foundation under Wine may prevent
startup or audio and media features from working.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

The complete package includes these Microsoft Visual C++ x64 runtime files:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

If one is missing, download the complete QuisquisLingo Windows package again
and fully extract it. Use only official Microsoft sources for runtime
installers, and never download individual DLL files from third-party websites.

Official Microsoft information:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N editions may require Microsoft Media Feature Pack for audio and
media functionality. Media Feature Pack is normally available under Windows
Optional Features. On some versions of Windows N, Media Feature Pack may not
be available under Optional Features. In that case, download the appropriate
Media Feature Pack for your version of Windows from the Microsoft website.

Restart Windows after installing Media Feature Pack. QuisquisLingo does not
download or install it automatically and does not change system settings.

TEXT-TO-SPEECH
--------------

QuisquisLingo uses the speech voices installed in Windows. Available languages
and voices depend on the Windows language and voice components installed on
the computer. If no compatible voice is available, install the appropriate
component through Windows settings.

Audio Settings > Test Voice speaks only the text you enter and uses the voice
language configured by the selected course.

LOGS AND DIAGNOSTICS
--------------------

The main crash log is stored at:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

The startup-check log is stored at:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug shows diagnostic options. Logs remain on the local computer
and are not uploaded automatically.

TROUBLESHOOTING
---------------

1. Fully extract the complete ZIP archive.
2. Run QuisquisLingo.exe from the extracted package.
3. If a runtime DLL is reported missing, download and extract the complete
   package again before considering an official Microsoft runtime installer.
4. If Media Feature Pack is required, follow the guidance above and restart
   Windows after installation.
5. If QQL still does not start, keep the complete error message and the
   available log files for support.

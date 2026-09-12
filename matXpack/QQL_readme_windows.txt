# QUISQUISLINGO - WINDOWS GUIDE

## ABOUT QUISQUISLINGO

QuisquisLingo is an offline-first language-learning application for learners
and course creators.

It provides structured language courses made of Lessons, GuideBooks, Rounds,
interactive exercises, review activities and Duels. Depending on the course,
exercises may use text, images, recorded audio and text-to-speech.

QuisquisLingo also includes authoring tools for creating, editing, inspecting,
importing and exporting language courses. It is therefore intended both for
people who want to study a language and for authors, teachers and other users
who want to create their own learning material.

Learner progress, profiles, settings and locally created content are stored
locally. QuisquisLingo does not require a user account or a permanent server
connection for its normal learning functions.

For a quick visual overview of how QuisquisLingo works, see:

```
QQL infographic.png
```

The infographic is included with the Windows application package.

QuisquisLingo is open-source software. The software source is licensed under
the Mozilla Public License 2.0. Courses, images, audio and other content may
have their own separate licences or rights.

Official source repository:

```
https://github.com/Quisquisnaut/QuisquisLingo
```

## STARTING QUISQUISLINGO

To start the packaged Windows version, run:

```
QuisquisLingo.exe
```

This is the Windows package launcher. It performs basic compatibility and
package-integrity checks before starting the Flutter application.

The package also contains:

```
quisquislingo_app.exe
```

This is the internal Flutter application executable. Users of the distributed
Windows package should normally start QuisquisLingo.exe instead.

No installation procedure is required. Extract the package and run it from
the extracted directory.

## USING THE PACKAGE

Extract the entire ZIP archive before starting QuisquisLingo.

Do not try to run the application directly from inside the ZIP archive.

Keep all supplied files and directories together. The application executable
depends on DLLs, Flutter runtime files, assets and data supplied with the
package.

Do not distribute, move, delete or rename individual EXE or DLL files inside
the package unless you are deliberately creating a modified build and
understand the package structure.

If the package becomes incomplete, download it again and fully extract a fresh
copy.

QuisquisLingo does not need to be installed under Program Files and does not
normally require Administrator privileges.

## SYSTEM REQUIREMENTS

The requirements for the packaged Windows version are deliberately modest.

The supplied package is intended for 64-bit x86 Windows systems.

Windows 10 or later is recommended.

The application requires:

* a normal Windows graphical desktop session;
* the files supplied in the complete QuisquisLingo package;
* Windows media components required by the application;
* working audio output when audio exercises or text-to-speech are used;
* sufficient memory to run a modern graphical desktop application.

Flutter, Dart, Android Studio, Visual Studio and other development tools are
NOT required to run the packaged application.

An Internet connection is not required for normal offline learning.

Features that deliberately access external web resources naturally require
an Internet connection.

## STARTUP CHECKS

Before starting the internal application, QuisquisLingo.exe performs a set of
startup checks.

These include checks for:

* essential files belonging to the QuisquisLingo package;
* required Microsoft Visual C++ runtime DLLs supplied with the package;
* Windows compatibility;
* Media Foundation availability;
* conditions associated with running under Wine.

These checks are diagnostic only.

They do not:

* download or install software;
* request Administrator elevation;
* change the Windows Registry;
* enable or disable Windows components;
* modify Windows configuration;
* install Media Feature Pack;
* install Visual C++ runtimes.

When a recoverable problem is detected, the launcher displays one consolidated
message with:

```
Continue anyway
Cancel
```

Continue anyway attempts to start QuisquisLingo despite the warning.

Cancel closes the launcher without starting the application.

If an essential internal QuisquisLingo file is missing, continuing is not
possible. In that case the message offers Close because the package should be
downloaded and fully extracted again.

## WINDOWS PACKAGE FILES

The Windows ZIP is a self-contained application package.

Among its top-level files are:

```
QuisquisLingo.exe
quisquislingo_app.exe
flutter_windows.dll
```

The package also contains the Flutter data and runtime files required by the
application, documentation and other supplied resources.

The exact set of package files can change between QuisquisLingo versions.

Do not assume that copying only the EXE files to another directory creates a
working installation. Keep the complete extracted package together.

## MICROSOFT VISUAL C++ RUNTIME

The complete QuisquisLingo Windows package includes the Microsoft Visual C++
x64 runtime DLLs required by the application:

```
msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll
```

These files must remain with the application package.

If the launcher reports that one of these files is missing, the first action
should be to download the complete QuisquisLingo Windows package again and
fully extract it.

Do not download individual DLL files from third-party DLL websites.

If a separate Microsoft Visual C++ runtime installation is genuinely required
for another reason, use only an official Microsoft source.

Official Microsoft information:

https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

## MEDIA FOUNDATION

QuisquisLingo uses Windows media facilities for audio and media functionality.

Standard Windows installations normally include the required Media Foundation
components.

Windows N editions may require Microsoft Media Feature Pack.

Media Feature Pack is normally available through Windows Optional Features.
The exact location and installation procedure depend on the version of
Windows.

On some Windows N versions, Media Feature Pack may not appear in the same
Optional Features interface. In that case, consult Microsoft's instructions
for the specific Windows version.

Restart Windows if Microsoft instructs you to do so after installing Media
Feature Pack.

QuisquisLingo does not download or install Media Feature Pack automatically
and does not enable Windows features on the user's behalf.

## TEXT-TO-SPEECH

On Windows, QuisquisLingo uses speech voices installed in Windows.

Available languages and voices therefore depend on the Windows language and
speech components installed on the computer.

QuisquisLingo attempts to use a voice suitable for the language configured by
the selected course. Voice availability varies between Windows installations.

If no compatible voice is available, install the appropriate Windows language
or speech component through Windows Settings.

QuisquisLingo provides learner audio controls under:

```
Settings > Audio Settings
```

These include text-to-speech controls and voice preference.

The Test Voice function speaks only the text entered by the user. It uses the
speech language configured by the selected course. It does not translate the
entered text or infer a language from the text itself.

Text-to-speech is optional. If TTS is unavailable or disabled, QuisquisLingo
can still be used, although exercises that require unavailable audio may be
excluded according to the current audio settings and course configuration.

## FILES AND DIRECTORIES WRITTEN BY QUISQUISLINGO

QuisquisLingo stores user data in locations belonging to the current Windows
user.

It does not normally need to modify the directory containing the application
package.

User-visible QuisquisLingo files are generally organised below:

```
Documents\QuisquisLingo\
```

Depending on which features are used, this directory may contain:

```
Documents\QuisquisLingo\Logs\
Documents\QuisquisLingo\Imports\
Documents\QuisquisLingo\Exports\
```

Additional subdirectories may be created for particular functions.

For example, Course Editor backups may be stored under:

```
Documents\QuisquisLingo\Exports\Course Backups\
```

Imports, exports, backup files and diagnostic exports are intentionally kept
in user-accessible locations where appropriate.

Other application preferences, learner progress and internal state may be
stored using Windows application-storage mechanisms rather than as ordinary
user-editable files.

Diagnostic files associated with startup are also written under:

```
%LOCALAPPDATA%\QuisquisLingo\Logs\
```

Temporary operating-system locations may be used when required by runtime
components.

## LEARNER DATA AND PRIVACY

QuisquisLingo is designed as an offline-first application.

Learner profiles, progress, course state and settings are stored locally.

Normal learning does not require:

* a QuisquisLingo online account;
* cloud synchronization;
* a QuisquisLingo server connection.

Logs and diagnostic information are not uploaded automatically.

Import, export and reporting features operate only when the user explicitly
invokes them.

Users should nevertheless review any diagnostic or exported file before
sharing it with another person if they have privacy concerns.

## CRASH LOG

QuisquisLingo maintains a local crash log to help diagnose application
failures.

The main crash log is:

```
Documents\QuisquisLingo\Logs\quisquislingo_crash.log
```

The crash log may contain technical information such as:

* date and time;
* QuisquisLingo version;
* operating-system information;
* architecture;
* logical processor count;
* locale;
* Dart runtime information;
* error information;
* stack traces when available.

The QuisquisLingo crash logger is designed not to record course answers,
profile names or other ordinary learner content.

The log is bounded so that it cannot grow indefinitely.

## DIAGNOSTIC LOG

QuisquisLingo also maintains an application diagnostic log for selected errors
and technical events.

Settings > Debug provides diagnostic functions where available.

An exported readable diagnostic log is stored under the QuisquisLingo Logs
directory and may be named:

```
quisquislingo_diagnostic_log.txt
```

Diagnostic information can include:

* timestamps;
* QQL error codes;
* technical context;
* exceptions;
* stack traces;
* audio and text-to-speech diagnostic events.

This information remains local unless the user deliberately shares it.

## WINDOWS LAUNCHER LOG

The Windows launcher writes startup-check information to:

```
%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log
```

This log relates to the external QuisquisLingo.exe launcher and can be useful
when the application does not start at all.

It can contain information about package validation, compatibility checks and
other launcher decisions.

The launcher log is local and is not uploaded automatically.

## STARTUP DIAGNOSTIC TRACE

QuisquisLingo may also maintain a more detailed Windows startup diagnostic
trace under:

```
%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log
```

This trace is intended for diagnosing startup problems occurring around the
boundary between the Windows launcher, the Flutter runtime and application
initialization.

Older rotated startup traces may also be retained when diagnostic rotation is
required.

The startup diagnostic system is designed so that failure to write a log does
not prevent QuisquisLingo from starting.

## REPORTING A PROBLEM

If QuisquisLingo displays an application error during use, keep the error code
shown by the application.

When reporting a Windows-specific problem, useful information includes:

* Windows version and edition;
* whether the system is a Windows N edition;
* QuisquisLingo version;
* what you were doing immediately before the problem;
* whether the problem can be reproduced;
* the complete error or warning message;
* the crash log, when relevant;
* an exported diagnostic log, when available;
* the launcher log if startup failed;
* the startup diagnostic trace if startup failed before the main interface
  appeared.

Do not edit a log before using it for your own diagnosis. If you intend to
send it to another person, review its contents first.

## WINE

Running the Windows package under Wine is Experimental.

QuisquisLingo attempts to recognise Wine so that Windows-specific compatibility
messages can provide more appropriate guidance.

Missing Media Foundation or incomplete multimedia support under Wine may
prevent startup or cause audio and media features not to work correctly.

Successful operation on native Windows does not guarantee identical behaviour
under Wine.

When using Linux, the native QuisquisLingo Linux package is preferable when
available.

## TROUBLESHOOTING

1. Fully extract the complete ZIP archive before running QuisquisLingo.

2. Start the packaged application with:

   ```
   QuisquisLingo.exe
   ```

3. If an essential QQL file or runtime DLL is reported missing, download the
   complete Windows package again and fully extract it before making system
   changes.

4. If a Microsoft Visual C++ runtime problem remains after verifying the
   package, use only Microsoft's official runtime installer or documentation.
   Never download individual DLL files from third-party websites.

5. If Media Feature Pack is required, follow Microsoft's instructions for the
   installed Windows version and restart Windows if required.

6. If text-to-speech does not work, check that an appropriate Windows speech
   voice is installed for the language used by the selected course.

7. If audio or video functions fail while the rest of QQL works, verify Media
   Foundation and the Windows audio configuration.

8. If QuisquisLingo still does not start, keep the complete warning or error
   message and inspect:

   ```
   %LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log
   ```

   and, when present:

   ```
   %LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_startup_trace.log
   ```

9. If QuisquisLingo starts but later crashes, inspect:

   ```
   Documents\QuisquisLingo\Logs\quisquislingo_crash.log
   ```

10. An exported Diagnostic Log may provide additional information about
    application-level errors, audio and TTS decisions.

## BUILDING QUISQUISLINGO FROM SOURCE

The complete QuisquisLingo source code is publicly available on GitHub:

```
https://github.com/Quisquisnaut/QuisquisLingo
```

The distributed Windows package is therefore not the only way to run
QuisquisLingo. Developers can download the source and compile the Windows
application themselves.

Building from source requires a Windows Flutter development environment.

Typical requirements include:

* Git;
* a current compatible Flutter SDK;
* the Windows development components required by Flutter;
* Visual Studio with Desktop development with C++ support;
* the associated Windows SDK and C++ build tools.

Android Studio is not required to build the Windows desktop application.

Check the environment with:

```
flutter doctor
```

A typical build procedure is:

```
git clone https://github.com/Quisquisnaut/QuisquisLingo.git
cd QuisquisLingo
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

The normal Flutter Windows release output is produced below the project's
build directory.

QuisquisLingo's public Windows distribution package contains additional
packaging and launcher logic beyond the raw Flutter release bundle.

The repository contains the Windows packaging script:

```
tools\package_windows_release.ps1
```

This script is used to assemble and validate the complete distributable
Windows package, including the QQL launcher and required package resources.

Users compiling only for their own development or testing can run the Flutter
application directly. Users reproducing the public packaged distribution
should follow the repository's current packaging instructions and validation
rules.

## MISSING PLATFORM RUNNER FILES

If a source archive does not contain all standard Flutter platform runner
files, the repository provides a preparation script for Windows:

```
tools\prepare_flutter_platforms.ps1
```

Run it from the project root with Flutter installed, then repeat the normal
dependency and validation commands.

The preparation script generates the standard Flutter platform host files. It
does not replace QuisquisLingo's Dart source, courses or application assets.

## SOURCE CODE AND LICENCE

Official repository:

```
https://github.com/Quisquisnaut/QuisquisLingo
```

The QuisquisLingo software source is licensed under the Mozilla Public License
2.0.

Courses, images, audio material, Image Bank content and other resources may
have separately stated licences, attribution requirements or rights.

Refer to the licence and attribution information supplied with QuisquisLingo
and with individual content packages.

## SECURITY NOTES

QuisquisLingo startup checks do not download executable components.

If a required runtime or Windows component is missing:

* obtain Microsoft components only from Microsoft;
* obtain QuisquisLingo packages only from the project's intended distribution
  source;
* do not download isolated DLL files from third-party DLL repositories;
* do not replace package executables with files from unrelated sources.

If the integrity of an extracted package is uncertain, delete that extracted
copy and extract a fresh copy from the original trusted archive.

## IMPORTANT

QuisquisLingo is under active development.

Windows behaviour can vary according to the Windows edition, installed media
components, available speech voices, audio devices and system configuration.

If the application does not start, the most useful first steps are to preserve
the exact launcher message and inspect the launcher and startup diagnostic
logs before modifying the system.

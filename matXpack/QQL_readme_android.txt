QUISQUISLINGO - ANDROID GUIDE
=============================

ABOUT QUISQUISLINGO
-------------------

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

QuisquisLingo is open-source software. The software source is licensed under
the Mozilla Public License 2.0. Courses, images, audio and other content may
have their own separate licences or rights.

Official source repository:

    https://github.com/Quisquisnaut/QuisquisLingo


ABOUT THE INITIAL ANDROID VERSION
---------------------------------

The first publicly distributed Android package of QuisquisLingo is intended
primarily for testing and evaluation.

It is initially distributed as a DEBUG APK rather than as a production release
build.

A debug APK is a complete installable Android application, but it differs from
a final production package in several important ways.

A debug build:

- is intended for development and testing;
- is signed with development/debug signing credentials rather than a final
  production signing key;
- contains debugging support;
- may be larger than a production build;
- may use more resources or perform less efficiently than an optimized release
  build;
- is not intended for publication through Google Play as the final production
  application;
- may produce additional diagnostic information useful during testing.

The debug status does NOT mean that the application is incomplete or that it
must be run from Android Studio.

The supplied APK can be copied directly to a compatible Android phone or
tablet and installed as a normal application, subject to the security policy
of that device.

A later QuisquisLingo Android distribution may use a separately signed release
APK or Android App Bundle.


THE APK FILE
------------

The initial test package may be supplied as:

    app-debug.apk

or under a QuisquisLingo-specific distribution filename.

If you build the debug APK yourself with Flutter, the default output is
normally:

    build/app/outputs/flutter-apk/app-debug.apk

The APK is the application installation package.

Unlike the Windows or Linux packages, the APK does not need to be extracted.
Do not unzip it before installation.


INSTALLING THE APK ON AN ANDROID DEVICE
---------------------------------------

The APK can be transferred to the Android device using, for example:

- USB;
- a cloud-storage service;
- email or messaging;
- a web download;
- another file-transfer method.

Once the APK is on the device:

1. Open the APK using the Files application, browser, cloud application or
   other application from which it was received.

2. Android may ask for permission to install applications from that particular
   source.

3. If requested, allow that source to install this APK.

4. Return to the APK and confirm installation.

5. When installation is complete, open QuisquisLingo from the Android
   application launcher.

Android calls this type of installation sideloading because the application
is being installed directly rather than through Google Play.

The exact wording and location of the installation permission varies between
Android versions and device manufacturers.

Only enable installation permission for a source that you trust.


ANDROID SECURITY WARNINGS
-------------------------

Because the initial QuisquisLingo Android APK is a directly distributed debug
build and is not installed through Google Play, Android or Google Play Protect
may display additional security or verification messages.

These messages do not by themselves indicate that QuisquisLingo has
malfunctioned.

Read every Android security message before proceeding and install the APK only
if you obtained it from the intended QuisquisLingo distribution source.

Some devices may prevent installation entirely because of:

- corporate or school management policies;
- parental or administrative restrictions;
- device security configuration;
- restrictions on installation from external sources;
- other manufacturer or Android security policies.

QuisquisLingo cannot override these device policies.


MANAGED AND WORK DEVICES
------------------------

An Android device managed by an employer, school or other administrator may
restrict or completely disable sideloading.

The APK may therefore work on an ordinary Android device but be refused on a
managed device.

If installation is blocked by device-management policy, the restriction must
be changed by the device administrator. QuisquisLingo does not attempt to
circumvent Android management or security controls.


UPDATING A DEBUG INSTALLATION
-----------------------------

Android requires application updates to be signed compatibly with the
application already installed.

During the initial debug-testing period, this has an important consequence.

If two QuisquisLingo debug APKs are produced using different debug signing
keys, Android may refuse to install the new APK over the existing one.

In that case it may be necessary to uninstall the existing QuisquisLingo
installation before installing the new APK.

WARNING:

Uninstalling an Android application normally removes that application's local
private data.

Before uninstalling QuisquisLingo, export or back up any learner or course
data that you need to preserve using the application's available backup and
export functions.

Once QuisquisLingo moves to a stable production signing process, maintaining
the same signing identity between releases will be important for normal
in-place updates.


SYSTEM REQUIREMENTS
-------------------

The Android package requires:

- an Android device compatible with the Android version requirements encoded
  in the supplied APK;
- sufficient free storage for the application and its local data;
- sufficient memory to run a modern Flutter application;
- working audio output if audio exercises or text-to-speech are used.

Android itself checks application compatibility during installation. If the
device's Android version is below the minimum supported by the APK,
installation will be refused.

An Internet connection is not required for normal offline learning.

Features that deliberately access external web resources naturally require
an Internet connection.

Android Studio, Flutter, Dart and development tools are NOT required to install
or use a supplied APK.


TEXT-TO-SPEECH ON ANDROID
-------------------------

On Android, QuisquisLingo uses the device's Android text-to-speech facilities.

Available languages and voices therefore depend on:

- the Android version;
- the text-to-speech engine installed on the device;
- the speech languages and voices installed for that engine;
- device-manufacturer configuration.

QuisquisLingo provides learner audio controls under:

    Settings > Audio Settings

These include audio-exercise settings, text-to-speech and voice preference.

Test Voice speaks only the text entered by the user and uses the speech
language configured by the selected course.

It does not translate the entered text or infer a language from the text
itself.

If a required voice is unavailable, check the Android text-to-speech settings
and install an appropriate language or voice if the device supports it.

Text-to-speech is optional. If TTS is unavailable or disabled, QuisquisLingo
can still be used, although exercises that require unavailable audio may be
excluded according to the current audio settings and course configuration.


FILES AND APPLICATION DATA
--------------------------

QuisquisLingo stores learner data, preferences and other application state
locally on the Android device.

Android isolates application-private files from ordinary user-accessible
storage.

Some QuisquisLingo operations deliberately allow the user to import or export
files through Android's storage and file-selection interfaces.

Depending on the feature being used, QuisquisLingo may create or access:

- learner backup files;
- course export files;
- course import files;
- diagnostic exports;
- images and other course resources selected by the user.

The exact physical Android storage path can vary according to Android version,
device manufacturer and the storage API used.

Users should normally use QuisquisLingo's own Import, Export and backup
functions rather than attempting to edit internal application directories
manually.


LEARNER DATA AND PRIVACY
------------------------

QuisquisLingo is designed as an offline-first application.

Learner profiles, progress, course state and settings remain on the device
during normal use.

Normal learning does not require:

- a QuisquisLingo account;
- cloud synchronization;
- a QuisquisLingo server connection.

QuisquisLingo does not automatically upload its crash or diagnostic logs.

Files leave the device only when a user deliberately uses an applicable
sharing, export or external-resource function.


CRASH AND DIAGNOSTIC INFORMATION
--------------------------------

QuisquisLingo includes application-level crash and diagnostic logging.

The crash logger can record technical information such as:

- date and time;
- QuisquisLingo version;
- operating-system information;
- device/runtime architecture information;
- processor information;
- locale;
- runtime information;
- error information;
- stack traces when available.

The QuisquisLingo crash logger is designed not to record ordinary learner
content such as course answers or profile names.

QuisquisLingo also maintains diagnostic information for selected application
errors and technical events.

Settings > Debug provides diagnostic functions where available.

On Android, application-private logs may not be directly visible through an
ordinary file manager. Use QuisquisLingo's available diagnostic/export
functions when possible.


ANDROID SYSTEM LOGS AND ADB
---------------------------

During testing, developers can obtain additional Android runtime information
using Android Debug Bridge, normally called ADB.

ADB is part of the Android SDK Platform Tools.

With a device connected and USB debugging enabled, check the connection with:

    adb devices

Android system and application messages can be viewed with:

    adb logcat

To save a diagnostic log to a file on the development computer:

    adb logcat > android_logcat.txt

Press Ctrl+C when enough information has been collected.

For a more focused debugging session, clear the previous Logcat buffer before
reproducing a problem:

    adb logcat -c
    adb logcat

Then reproduce the problem and save the relevant output.

Android Logcat is an operating-system diagnostic facility. It can contain
messages produced by Android, device services and other software, not only
QuisquisLingo.

Review a Logcat file before sharing it.


INSTALLING WITH ADB
-------------------

Developers and testers can also install the APK directly from a development
computer.

First verify that the device is visible:

    adb devices

Then install the APK:

    adb install path_to_apk

To replace an already installed compatible build while preserving its
application data when Android permits it:

    adb install -r path_to_apk

An update can still be rejected if the existing and new APKs have incompatible
signatures.

USB debugging must be enabled on the Android device before ADB can communicate
with it.


TESTING WITH AN ANDROID EMULATOR
--------------------------------

QuisquisLingo can also be tested using an Android Emulator.

With a running emulator detected by Flutter:

    flutter devices

A development build can be compiled, installed and started with:

    flutter run -d emulator-5554

Replace `emulator-5554` with the device identifier actually shown by
`flutter devices`.

An emulator is useful for development and interface testing, but it does not
perfectly reproduce every physical Android device.

QuisquisLingo Android testing should therefore include at least one real
Android phone or tablet in addition to emulator testing, especially for:

- text-to-speech;
- recorded audio;
- file import and export;
- device storage;
- small-screen layouts;
- Android lifecycle behaviour.


DEBUG BUILD PERFORMANCE
-----------------------

The initial distributed Android APK is a debug build.

A debug build is not optimized in the same way as a production release build.

As a result:

- startup may be slower;
- some operations may be slower;
- application size may be larger;
- memory and CPU use may differ from a release build;
- development assertions and debugging facilities may be present.

Performance observations made with the initial debug APK should therefore not
automatically be treated as representative of the future production release.

Functional problems should still be reported.


REPORTING A PROBLEM
-------------------

When reporting an Android problem, useful information includes:

- phone or tablet manufacturer and model;
- Android version;
- QuisquisLingo version;
- whether the APK is a debug or release build;
- whether the device is personally managed or organization-managed;
- what you were doing immediately before the problem;
- whether the problem can be reproduced;
- the complete Android error message, if one appeared;
- screenshots when useful;
- QuisquisLingo diagnostic information;
- relevant ADB Logcat output when available.

For audio or TTS problems, also report:

- whether ordinary device audio works;
- which Android TTS engine is selected;
- whether the required speech language is installed;
- whether QuisquisLingo's Test Voice works.


TROUBLESHOOTING
---------------

1. Confirm that the APK was downloaded or copied completely.

2. Open the APK and allow installation from that source if Android requests
   permission and you trust the source.

3. If Android reports that the application cannot be installed, check whether
   an older QuisquisLingo build is already installed.

4. If an older build exists and the new APK has a different debug signature,
   back up important QuisquisLingo data before uninstalling the previous build.

5. If the device is managed by an employer, school or administrator, check
   whether sideloading is prohibited by policy.

6. If QuisquisLingo installs but does not start correctly, restart the
   application and, if possible, collect ADB Logcat output while reproducing
   the problem.

7. If text-to-speech does not work, verify the Android TTS engine and installed
   speech languages.

8. If recorded audio does not work, confirm that normal media playback works
   on the device and that the device volume is not muted.

9. If import or export fails, verify that the required file or storage
   permission has been granted when Android requests it.

10. When testing a debug build, distinguish functional failures from general
    performance differences associated with debug mode.


BUILDING QUISQUISLINGO FROM SOURCE
----------------------------------

The complete QuisquisLingo source code is publicly available on GitHub:

    https://github.com/Quisquisnaut/QuisquisLingo

Developers can build the Android application directly from source.

Typical requirements include:

- Git;
- a compatible current Flutter SDK;
- Java as required by the Flutter/Gradle toolchain;
- the Android SDK;
- Android SDK Platform Tools;
- the Android SDK components required by the current project.

Android Studio is a convenient way to install and manage the Android SDK and
emulators, but the actual Flutter build can be executed from a terminal once
the required toolchain is configured.

Check the development environment with:

    flutter doctor

A typical source preparation sequence is:

    git clone https://github.com/Quisquisnaut/QuisquisLingo.git
    cd QuisquisLingo
    flutter doctor
    flutter pub get
    flutter analyze
    flutter test


BUILDING A DEBUG APK
--------------------

To create the same general type of APK used during the initial Android testing
period:

    flutter build apk --debug

The resulting file is normally:

    build/app/outputs/flutter-apk/app-debug.apk

This APK can be copied to a compatible Android device and installed for
testing.


RUNNING DIRECTLY ON A DEVICE
----------------------------

With a compatible Android device or emulator connected:

    flutter devices

Then:

    flutter run -d DEVICE_ID

For example:

    flutter run -d emulator-5554

Flutter builds the development application, installs it on the selected
device and starts it.


FUTURE RELEASE BUILDS
---------------------

A production-oriented Android APK can be built with:

    flutter build apk --release

The default output is normally:

    build/app/outputs/flutter-apk/app-release.apk

For Google Play distribution, Android applications are commonly distributed
using an Android App Bundle:

    flutter build appbundle --release

which normally produces:

    build/app/outputs/bundle/release/app-release.aab

A true public production release also requires an intentional, persistent
release-signing configuration.

A debug signing key should not be treated as the permanent identity of a
production Android application.

Future QuisquisLingo Android release procedures should preserve the production
signing identity so that users can update the application without
uninstalling it.


MISSING PLATFORM RUNNER FILES
-----------------------------

If a particular source archive does not contain all standard Flutter platform
runner files, the QuisquisLingo repository includes platform-preparation
scripts.

On Windows:

    tools\prepare_flutter_platforms.ps1

On Linux or macOS:

    chmod +x tools/prepare_flutter_platforms.sh
    ./tools/prepare_flutter_platforms.sh

These scripts prepare standard Flutter platform host files without replacing
QuisquisLingo's Dart source, courses or application assets.


SOURCE CODE AND LICENCE
-----------------------

Official repository:

    https://github.com/Quisquisnaut/QuisquisLingo

The QuisquisLingo software source is licensed under the Mozilla Public License
2.0.

Courses, images, audio material, Image Bank content and other resources may
have separately stated licences, attribution requirements or rights.

Refer to the licence and attribution information supplied with QuisquisLingo
and with individual content packages.


SECURITY NOTES
--------------

Install QuisquisLingo APK files only from a source you trust.

A directly distributed APK bypasses the normal Google Play installation
channel, so the user is responsible for deciding whether to trust the package.

Do not disable Android security features globally simply to install
QuisquisLingo.

If Android requires permission to install from an external source, grant it
only to the specific application being used to open the trusted APK, and
revoke it later if desired.

Do not install modified QuisquisLingo APKs from unknown third-party sources.


IMPORTANT
---------

The initial Android package is a TESTING DEBUG BUILD.

It should be evaluated primarily for functionality, compatibility and bug
discovery rather than final production performance.

QuisquisLingo Android behaviour can vary according to Android version, device
manufacturer, installed text-to-speech engine, storage implementation, device
management policy and hardware configuration.

Testing on an emulator is useful, but testing on at least one physical Android
device is strongly recommended before the Android build is considered ready
for normal release distribution.

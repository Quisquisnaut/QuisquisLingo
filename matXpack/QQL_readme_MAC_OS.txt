QUISQUISLINGO - macOS BETA TESTING GUIDE
=========================================

WHAT QUISQUISLINGO IS
---------------------

QuisquisLingo (QQL) is an offline-first language-learning application for
learners and course creators.

It provides structured language courses with Lessons, GuideBooks, Rounds,
interactive exercises, audio activities, Review and Duels. It also includes
tools for creating, editing, importing and exporting language courses.

Learner progress, profiles, settings and locally created content are stored
locally. Normal learning does not require a QuisquisLingo account or a
permanent Internet connection.

The project is open source under the Mozilla Public License 2.0.

Official source repository:

    https://github.com/Quisquisnaut/QuisquisLingo


WHY THERE IS NO READY macOS PACKAGE YET
---------------------------------------

QuisquisLingo is built with Flutter and is designed as a multiplatform
application. The same shared application code is intended to run on Windows,
Linux, Android and macOS.

However, producing and properly testing a native macOS build requires Apple
hardware and Apple's macOS development tools.

For this reason, the macOS version is not yet distributed as a ready-to-run
package.

This does not mean that QuisquisLingo must be rewritten for macOS. The main
application is already based on a multiplatform codebase. What is still needed
is compilation, platform-specific validation and testing on real Mac hardware.


HOW macOS BETA TESTERS CAN HELP
-------------------------------

If you own a Mac and would like to help test QuisquisLingo, you can compile the
public source code directly on your own machine.

Useful testing includes:

- whether QQL starts correctly;
- window layout and resizing;
- normal Lessons, Rounds, Review and Duels;
- Course Editor functions;
- local persistence;
- file import and export;
- text-to-speech in different languages;
- recorded audio playback;
- any macOS-specific warnings, crashes or visual problems.

Please report any problems you find to the QuisquisLingo author, including the
macOS version and Mac model or chip when relevant.


WHAT YOU NEED TO INSTALL
------------------------

You need two main development tools:

1. Xcode
2. Flutter

Xcode
-----

Install Xcode from the Mac App Store if it is not already installed.

After installation, open Xcode once and allow it to install any additional
components it requests.

If needed, install the Xcode command-line tools from Terminal with:

    xcode-select --install


Flutter
-------

Install the current stable Flutter SDK for your Mac.

Choose the package that matches your Mac:

- Apple Silicon for M-series Macs;
- Intel for older Intel Macs.

Extract Flutter to a convenient folder and add its `bin` directory to your
PATH so that the `flutter` command works in Terminal.

Then check the installation with:

    flutter doctor

Follow any instructions shown by `flutter doctor`.

If it reports that CocoaPods is required by the current project configuration,
install CocoaPods as instructed by Flutter.


GET THE QQL SOURCE
------------------

Clone the official repository:

    git clone https://github.com/Quisquisnaut/QuisquisLingo.git

Then enter the project folder:

    cd QuisquisLingo


PREPARE AND TEST THE macOS BUILD
--------------------------------

From the project folder, run:

    chmod +x tools/prepare_macos.sh
    ./tools/prepare_macos.sh

Then:

    flutter pub get
    flutter analyze
    flutter test

To compile and run QQL directly on the Mac:

    flutter run -d macos

If the application starts, please test the main learner and authoring features
and report any macOS-specific problems.


BUILD A macOS RELEASE
---------------------

A release build can be created with:

    flutter build macos --release

The resulting application bundle is normally created under:

    build/macos/Build/Products/Release/

This locally built application is suitable for testing on the Mac that built
it.

Normal public distribution to other Macs may require additional Apple code
signing and notarization procedures. That distribution work is one of the
reasons an official ready-made macOS package is not yet provided.


IMPORTANT
---------

You do not need to modify QuisquisLingo source code just to test the existing
macOS build path.

The most useful contribution from a Mac beta tester is simply:

1. install Xcode and Flutter;
2. compile the current QQL source;
3. run and test it on real Mac hardware;
4. report anything that behaves differently or fails under macOS.

Thank you for helping test QuisquisLingo on another native platform.

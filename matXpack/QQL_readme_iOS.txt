QUISQUISLINGO - iOS BETA TESTING GUIDE
=======================================

WHAT QUISQUISLINGO IS
---------------------

QuisquisLingo (QQL) is an offline-first language-learning application for learners and course creators.

It provides structured language courses with Lessons, GuideBooks, Rounds, interactive exercises, audio activities, Review and Duels. It also includes tools for creating, editing, importing and exporting language courses.

Learner progress, profiles, settings and locally created content are stored locally. Normal learning does not require a QuisquisLingo account or a permanent Internet connection.

The project is open source under the Mozilla Public License 2.0.

Official source repository:

    https://github.com/Quisquisnaut/QuisquisLingo


iOS STATUS
----------

QuisquisLingo is built with Flutter and is designed as a multiplatform application, including support for Apple platforms.

The iOS version is not yet distributed as a ready-to-install package because building and properly testing an iPhone or iPad version requires Apple hardware and Apple's development environment.

The main QQL application does not need to be rewritten for iOS. What is still needed is platform-specific compilation, testing and validation on real Apple devices.


HOW BETA TESTERS CAN HELP
-------------------------

If you own a Mac and an iPhone or iPad, you can help by compiling the public QQL source and testing it on your own device.

Useful feedback includes:

- whether QQL builds and starts correctly;
- whether the interface works well on the device;
- whether audio and text-to-speech work correctly;
- whether import, export and local data behave as expected;
- any crashes, warnings or other iOS-specific problems.

Please report any problems to the QuisquisLingo author and include the iOS version and device model when relevant.


WHAT YOU NEED
-------------

You need:

1. A Mac.
2. Xcode.
3. Flutter.
4. An iPhone or iPad for real-device testing.

Install Xcode from the Mac App Store.

Install the current stable Flutter SDK for your Mac and check the setup with:

    flutter doctor

Follow any instructions shown by Flutter.


GET THE QQL SOURCE
------------------

Clone the official repository:

    git clone https://github.com/Quisquisnaut/QuisquisLingo.git

Then enter the project folder:

    cd QuisquisLingo


PREPARE AND TEST
----------------

Prepare the Flutter project if needed:

    chmod +x tools/prepare_flutter_platforms.sh
    ./tools/prepare_flutter_platforms.sh

Then run:

    flutter pub get
    flutter analyze
    flutter test

Connect the iPhone or iPad to the Mac and follow the normal Xcode/Flutter device setup if requested.

Check available devices with:

    flutter devices

Then run QQL on the Apple device with:

    flutter run -d DEVICE_ID

Replace DEVICE_ID with the identifier shown by Flutter.


IMPORTANT
---------

The iOS build path is still in beta-testing status.

No official ready-made iOS package is currently distributed.

The most useful contribution from an iOS beta tester is simply to compile the current source on a Mac, run QQL on a real iPhone or iPad, and report any platform-specific problems.

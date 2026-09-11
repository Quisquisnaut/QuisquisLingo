# QuisquisLingo platform compatibility

## Primary targets

### Windows

Windows is a supported code path. TTS uses System.Speech. QQL itself is `2.0.30+230`; the Windows package wraps the unchanged `quisquislingo_app.exe` with a separate native x64 bootstrap named `QuisquisLingo.exe`. Packaged users should start the bootstrap, while direct runner and `flutter run` development behavior remain available and unchanged.

The bootstrap resolves package files relative to its own executable, checks the explicit native runtime set and system `MFPlat.dll`, and consolidates recoverable findings into one Continue anyway / Cancel warning. A missing internal Flutter executable is fatal and Close-only. Native Windows earlier than Windows 10 receives a compatibility warning rather than a hard block. Wine is detected first and is Experimental; missing Media Foundation under Wine receives Wine-specific guidance rather than Windows Optional Features guidance. A complete QQL package already ships the expected Visual C++ runtime DLLs, so re-downloading and fully extracting the package is the primary remediation for missing package files.

Validate both debug and `flutter build windows --release`, then run `tools/package_windows_release.ps1` and launch the complete packaged application on a Windows machine without Flutter or VS Code installed. For the frozen packaging-only intervention, the script defaults to reusing the existing validated Flutter Release bytes and rebuilds only the native bootstrap/tests. Its explicit `-RebuildFlutterApplication` option is for a separately authorized future app build, not this frozen QQL package.

### Android

Android is a supported code path. Validate on an emulator and at least one physical device. Check platform TTS, recorded MP3 playback, file-picker import/export and small-screen layouts.

### Linux

Linux is a supported code path. TTS uses eSpeak NG/eSpeak when installed and must fail gracefully when no supported executable or voice is available. Validate on the intended distribution, including antiX where applicable.

## Build-host-dependent targets

### iOS and macOS

The shared Flutter/Dart architecture includes iOS/macOS-compatible paths, but builds require macOS and Xcode. Do not claim validated support until the application has been built and smoke-tested there.

For macOS, install Flutter stable, Xcode and its command-line tools, plus CocoaPods if requested by the resolved plugins. From the project root, prepare a missing host project without replacing the Dart source, assets, tests or course content:

```bash
chmod +x tools/prepare_macos.sh
./tools/prepare_macos.sh
```

Then run:

```bash
flutter analyze
flutter test
flutter run -d macos
```

Build a release with `flutter build macos --release`. The app bundle is normally under `build/macos/Build/Products/Release/`. Validate launch and resizing, learner persistence, Course Editor and Course Info, Image Bank preview/import, learner backup import/export, system TTS in at least two languages, recorded MP3 playback, Alpha expiry UI and narrow-window dialogs. The macOS sandbox entitlements permit user-selected read/write access for the existing file-picker workflows. Distribution outside the developer's own Mac may require signing and notarization.

## Experimental target

### Web

Web is not a production-certified target. Several Course Editor and import paths depend on native file APIs such as `dart:io`, local filesystem paths and `Image.file`. Those paths must be conditionally disabled or replaced with web implementations before production web compatibility can be claimed.

## Runner folders

If standard Flutter platform runner folders are missing from a source archive, use `tools/prepare_flutter_platforms.ps1` on Windows or `tools/prepare_flutter_platforms.sh` on Linux/macOS with Flutter installed. Generated runners should remain with the development checkout used for platform builds.

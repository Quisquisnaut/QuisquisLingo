# antiX Linux preview

QuisquisLingo 0.3.0 keeps the lightweight Linux preview behavior from the earlier project.

From the project directory:

```bash
flutter create .
flutter pub get
flutter run -d linux
```

For a release build:

```bash
flutter build linux --release
./build/linux/x64/release/bundle/quisquislingo_app
```

If Flutter reports missing Linux desktop development packages, install the packages named by Flutter using the antiX/Debian package manager, then rerun the command.

TTS remains disabled on Linux preview mode. Course navigation, exercises, local progress, streaks and Language Duels remain active.

## Linux text-to-speech
QuisquisLingo 0.3.6 can use eSpeak NG (preferred) or eSpeak for course audio on Linux.
Install the lightweight backend with:

    sudo apt install espeak-ng

Text-to-speech can still be turned on or off in QuisquisLingo Settings.

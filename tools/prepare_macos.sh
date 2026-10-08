#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or not on PATH."
  exit 1
fi

if [[ ! -d macos/Runner.xcodeproj ]]; then
  echo "Generating missing macOS Xcode host project..."
  flutter create --platforms=macos .
else
  echo "macOS Xcode host project already exists."
fi

flutter pub get
echo "macOS host preparation complete."
echo "Next:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d macos"
echo "  flutter build macos --release"

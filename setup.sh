#!/usr/bin/env bash
# One-time setup: generates the android/ and ios/ folders around the existing lib/ code.
set -euo pipefail

if ! command -v flutter >/dev/null; then
  echo "Flutter SDK not found. Install it from https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

flutter create --org com.tasksforallah --project-name tasks_for_allah --platforms android,ios .
python3 tool/patch_android.py
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze || true
flutter test
echo
echo "Done. Connect a device or emulator and run:  flutter run"

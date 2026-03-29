#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../mobile"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found. Install Flutter SDK first." >&2
  exit 1
fi

if [ ! -d android ] || [ ! -d ios ]; then
  flutter create . --platforms=android,ios
fi

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo "Flutter mobile foundation bootstrapped."

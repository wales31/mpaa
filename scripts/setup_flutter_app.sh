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

if [ -f android/build.gradle.kts ]; then
  python3 - <<'PY'
from pathlib import Path
import re

build_file = Path("android/build.gradle.kts")
content = build_file.read_text()

updated, count = re.subn(
    r'\n?tasks\.register<Delete>\("clean"\)\s*\{\s*delete\(rootProject\.layout\.buildDirectory\)\s*\}\s*\n?',
    "\n",
    content,
    count=1,
    flags=re.S,
)

if count:
    build_file.write_text(updated)
    print("Removed duplicate clean task from android/build.gradle.kts.")
PY
fi

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo "Flutter mobile foundation bootstrapped."

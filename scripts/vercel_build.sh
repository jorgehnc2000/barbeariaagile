#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-/vercel/flutter}"
if [ ! -d "${FLUTTER_HOME}/bin" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release

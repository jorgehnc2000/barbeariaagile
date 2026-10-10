#!/usr/bin/env bash
set -euo pipefail

# Cliente web na raiz. O admin Flutter fica em /painel/ e é servido
# nas rotas /:slug/admin e /:slug/login.
npm run build --prefix web-client

FLUTTER_HOME="${FLUTTER_HOME:-/vercel/flutter}"
if [ ! -d "${FLUTTER_HOME}/bin" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"
flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release --base-href /painel/

mkdir -p web-client/dist/painel
cp -a build/web/. web-client/dist/painel/

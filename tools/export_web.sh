#!/usr/bin/env bash
# Exporte le jeu en HTML5 dans build/web/ et crée build/tomato-wars-web.zip (prêt pour itch.io).
# Prérequis : Godot 4.7.x dans le PATH (commande `godot`) + templates d'export Web installés.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
mkdir -p build/web
# Godot ne doit pas scanner build/ (sinon il y crée des .import qui finissent dans le zip).
touch build/.gdignore
"$GODOT" --headless --path . --export-release "Web" build/web/index.html

rm -f build/tomato-wars-web.zip
(cd build/web && zip -qr ../tomato-wars-web.zip .)
echo "OK : build/web/ et build/tomato-wars-web.zip"

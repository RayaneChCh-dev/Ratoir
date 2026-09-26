#!/usr/bin/env bash
# Exporte le jeu en HTML5 dans build/web/ et crée build/ratoir-web.zip (prêt pour itch.io).
# Prérequis : Godot 4.7.x dans le PATH (commande `godot`) + templates d'export Web installés.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html

rm -f build/ratoir-web.zip
(cd build/web && zip -qr ../ratoir-web.zip .)
echo "OK : build/web/ et build/ratoir-web.zip"

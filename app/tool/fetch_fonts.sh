#!/usr/bin/env bash
# Re-fetch the self-hosted brand fonts from the upstream google/fonts repo.
# Run from the `app/` directory. Nothing here needs credentials.
set -euo pipefail

BASE="https://raw.githubusercontent.com/google/fonts/main"
DEST="assets/fonts"

mkdir -p "$DEST"

fetch() {
  curl -fsSL --max-time 120 -o "$DEST/$2" "$BASE/$1"
  echo "fetched $2"
}

fetch "ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf" "PlayfairDisplay-Variable.ttf"
fetch "ofl/worksans/WorkSans%5Bwght%5D.ttf"               "WorkSans-Variable.ttf"
fetch "ofl/robotomono/RobotoMono%5Bwght%5D.ttf"           "RobotoMono-Variable.ttf"

fetch "ofl/playfairdisplay/OFL.txt" "OFL-PlayfairDisplay.txt"
fetch "ofl/worksans/OFL.txt"        "OFL-WorkSans.txt"
fetch "ofl/robotomono/OFL.txt"      "OFL-RobotoMono.txt"

echo "done. Run: flutter test test/core/theme/fonts_test.dart"

#!/bin/zsh
set -euo pipefail

cd "${0:A:h}"
swift build -c release

app="CoffeeTime.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/CoffeeTime "$app/Contents/MacOS/CoffeeTime"
cp Info.plist "$app/Contents/Info.plist"
cp CoffeeTime.png "$app/Contents/Resources/CoffeeTime.png"
chmod +x "$app/Contents/MacOS/CoffeeTime"

printf 'Built %s\n' "$PWD/$app"

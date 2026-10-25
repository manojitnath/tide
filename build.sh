#!/bin/zsh
# Builds "Tide.app" from src/ into build.noindex/ (Spotlight skips folders ending in .noindex,
# so only the installed copy shows up in search). Re-run after editing anything in src/.
#   ./build.sh            build the app
#   ./build.sh --install  also copy it to /Applications and open it
#   ./build.sh --zip      also make build.noindex/Tide.zip for a GitHub release
set -e
here="${0:A:h}"
dir="$here/build.noindex"
out="$dir/Tide.app"
version="3.0"

rm -rf "$out"
mkdir -p "$out/Contents/MacOS" "$out/Contents/Resources"
swiftc -O -swift-version 5 "$here/src/main.swift" -o "$out/Contents/MacOS/Tide"
cp "$here/src/panel.html" "$here/src/dashboard.html" "$here/src/island.html" "$here/src/AppIcon.icns" "$here/src/fonts/Manrope.ttf" "$out/Contents/Resources/"
cp "$here/src/fonts/OFL.txt" "$out/Contents/Resources/Manrope-OFL.txt"

cat > "$out/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Tide</string>
  <key>CFBundleDisplayName</key><string>Tide</string>
  <key>CFBundleIdentifier</key><string>local.focusmn.app</string>  <!-- kept from Focus MN, so settings, notifications and login stay -->
  <key>CFBundleExecutable</key><string>Tide</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSUserNotificationAlertStyle</key><string>alert</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Ad-hoc signature: enough to run locally, not notarized.
codesign --force --deep -s - "$out"
echo "Built: $out"

if (( ${@[(Ie)--zip]} )); then
  rm -f "$dir/Tide.zip"
  ditto -c -k --keepParent "$out" "$dir/Tide.zip"
  echo "Zipped: $dir/Tide.zip"
fi

if (( ${@[(Ie)--install]} )); then
  osascript -e 'tell application id "local.focusmn.app" to quit' 2>/dev/null || true
  while pgrep -xq "Tide" || pgrep -xq "Focus MN"; do sleep 0.2; done
  # The app was called Focus MN before; the old copy goes so there is only one.
  rm -rf "/Applications/Tide.app" "/Applications/Focus MN.app"
  ditto "$out" "/Applications/Tide.app"
  # macOS can still be closing the old copy; retry until it opens (error -600 otherwise).
  for i in {1..20}; do open "/Applications/Tide.app" 2>/dev/null && break; sleep 0.5; done
  echo "Installed: /Applications/Tide.app"
fi

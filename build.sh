#!/bin/zsh
set -euo pipefail
task_source=$(cd "$(dirname "$0")" && pwd)
task_root="$task_source/dist"
mkdir -p "$task_root"
task_app="$task_root/KeyRelay.app"
mkdir -p "$task_app/Contents/MacOS" "$task_app/Contents/Resources"
task_sources=("$task_source"/Sources/KeyRelay/**/*.swift)
xcrun swiftc -O -swift-version 5 -target arm64-apple-macosx13.0 "${task_sources[@]}" -o "$task_app/Contents/MacOS/KeyRelay"
cat > "$task_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>io.github.liunnnnn.keyrelay</string>
<key>CFBundleName</key><string>KeyRelay</string>
<key>CFBundleDisplayName</key><string>KeyRelay</string>
<key>CFBundleExecutable</key><string>KeyRelay</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>6</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf 'APPL????' > "$task_app/Contents/PkgInfo"
codesign --force --sign - -r='designated => identifier "io.github.liunnnnn.keyrelay"' "$task_app"
"$task_app/Contents/MacOS/KeyRelay" --self-test

cp "$task_source/vmtype" "$task_root/vmtype"
chmod +x "$task_root/vmtype"
cp "$task_root/vmtype" "$task_root/keyrelay"

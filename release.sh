#!/bin/zsh
set -euo pipefail
task_root=$(cd "$(dirname "$0")" && pwd)
zsh "$task_root/build.sh"
task_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$task_root/dist/KeyRelay.app/Contents/Info.plist")
task_name="keyrelay-$task_version-macos-arm64"
task_stage=$(mktemp -d "${TMPDIR:-/tmp}/keyrelay-release.XXXXXXXX")
trap 'rm -rf "$task_stage"' EXIT
mkdir -p "$task_stage/$task_name" "$task_stage/text-to-keyboard-input/agents" "$task_root/releases"
cp -R "$task_root/dist/KeyRelay.app" "$task_stage/$task_name/"
cp "$task_root/dist/keyrelay" "$task_root/dist/vmtype" "$task_root/README.md" "$task_root/LICENSE" "$task_stage/$task_name/"
cp "$task_root/SKILL.md" "$task_stage/$task_name/"
cp -R "$task_root/docs" "$task_stage/$task_name/"
cp "$task_root/SKILL.md" "$task_stage/text-to-keyboard-input/"
cp "$task_root/LICENSE" "$task_stage/text-to-keyboard-input/"
cp "$task_root/openai.yaml" "$task_stage/text-to-keyboard-input/agents/"
ditto -c -k --sequesterRsrc --keepParent "$task_stage/$task_name" "$task_root/releases/$task_name.zip"
ditto -c -k --sequesterRsrc --keepParent "$task_stage/text-to-keyboard-input" "$task_root/releases/text-to-keyboard-input-$task_version.zip"
cd "$task_root/releases"
shasum -a 256 "$task_name.zip" "text-to-keyboard-input-$task_version.zip" > SHA256SUMS.txt
print "Release files: $task_root/releases"

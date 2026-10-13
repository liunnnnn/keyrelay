#!/bin/zsh
set -euo pipefail
task_root=$(cd "$(dirname "$0")" && pwd)
task_tmp=$(mktemp -d "${TMPDIR:-/tmp}/keyrelay-tests.XXXXXXXX")
trap 'rm -rf "$task_tmp"' EXIT
task_sources=("$task_root"/Sources/KeyRelay/**/*.swift)
task_sources=("${(@)task_sources:#*/main.swift}")
# Compile without optimization so all assertions stay enabled.
xcrun swiftc -swift-version 5 -target arm64-apple-macosx13.0 "${task_sources[@]}" "$task_root"/Tests/**/*.swift -o "$task_tmp/KeyRelayChecks"
"$task_tmp/KeyRelayChecks"

# Remote-client adapters

KeyRelay runs on macOS. Remote adapters describe the software carrying physical keyboard events, not the guest operating system or editor. Do not add a Vim mode, file writer or clipboard transport to an adapter.

## Current flow

`GUI / CLI -> RemoteClients -> InputPlanner -> KeySender -> focused remote client`

- `Adapters/RemoteClient.swift` is the shared registry used by GUI and CLI. An entry contains its stable ID, display name, evidence status, focus guidance, optional known bundle ID, interval and keyboard behavior.
- `Core/InputPlanner.swift` validates text and expands Tabs. It is shared by every adapter and does not interpret shell commands.
- `Platform/KeySender.swift` checks permission and foreground PID, sends physical US keys and releases modifiers on interruption. Its original Shift/Ctrl device flags are preserved.
- `KeyboardBehavior` isolates modifier settling and key hold times. All current entries retain the original 12 ms values. Do not invent different timings without a remote test showing why they are needed.

## Add or improve an adapter

1. Record the actual macOS client/version, remote OS/program, input source and keyboard layouts. A screenshot of a connection proves availability, not keyboard compatibility.
2. Test a short, harmless payload containing lowercase, uppercase, digits and shifted symbols. Inspect target-side text before extending the test to lines, indentation or long files.
3. Add/update the registry entry. Use a bundle ID only when confirmed on the intended installation; unknown IDs should use manual focus. Do not infer the target OS from the client name.
4. Keep behavior differences inside the adapter and sender. Update the shared defaults/CLI tests and add regression coverage for the observed difference before changing existing adapters.
5. Run `zsh test.sh` and `zsh build.sh`; then test via the exact client and read back the result. For files, compare hashes of the Tab-expanded bytes. A successful send status is not acceptance.
6. Update `docs/COMPATIBILITY.md` with actual evidence and any remaining limits. Change a client from awaiting tests only after a real remote read-back succeeds.

Currently Sunlogin, ToDesk and UU Remote are experimental presets using the original sender. They exist to support staged testing with the user; they are not finished, independently verified adapters.

Never include customer credentials, private clipboard contents or internal host addresses in public fixtures or issues. Use harmless synthetic text.

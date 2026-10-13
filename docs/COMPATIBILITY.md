# Compatibility evidence

The sender runs on Apple Silicon macOS 13+. Remote Windows/Linux/macOS destinations are possible through the selected remote client; this is not a native sender for those operating systems.

| Adapter | Implementation | Target-side evidence | Remaining work |
| --- | --- | --- | --- |
| ESXi (`esxi`) | Existing physical US sender, 100 ms default, manual browser focus | Legacy Bash temporary-file test containing ASCII, shifted symbols and encoded Chinese matched SHA-256 | Retest this release in the user's current console |
| Windows App (`winapp`) | Known bundle ID; preserves physical Shift/Ctrl flagsChanged behavior; 100 ms default | Earlier modifier troubleshooting is retained | Complete remote regression; previous session was occupied by another user |
| Sunlogin (`sunlogin`) | Experimental original-sender preset, manual focus | None | Test with the user, investigate any event differences |
| ToDesk (`todesk`) | Experimental original-sender preset, manual focus | None | Test with the user, investigate any event differences |
| UU Remote (`uu`) | Experimental original-sender preset, manual focus | None | Test with the user, investigate any event differences |
| Other (`generic`) | Original 45 ms CLI default and explicit/manual target | Depends on actual software | No universal compatibility claim |

## Shared limits

- Printable ASCII, Tab-to-spaces and explicit line breaks only. Chinese has no universal physical key mapping; use a target-specific ASCII decoder command to write UTF-8 files.
- Matching US layouts and an English input source are required.
- Foreground PID changes stop input; same-app tab, connection and field changes are not detectable. Manual targeting still requires the user to choose the correct field during the countdown.
- A partial here-doc or interrupted append must be inspected before retrying.
- Legacy local AppKit/TextEdit tests duplicated characters. This unresolved local-field limitation remains; do not imply that remote presets fix it.

## Acceptance template

For the next real client test, record client/version, OS/program, layouts, harmless payload, selected adapter, timing and actual read-back/hash. Mark short text, shifted symbols, multiline and file hash separately. Do not publish host addresses or customer content.

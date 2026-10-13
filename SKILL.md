---
name: text-to-keyboard-input
description: Use macOS KeyRelay / vmtype only as a fallback when the AI's built-in keyboard tools are unavailable or cannot reliably complete the target input. If native keyboard input works, do not invoke KeyRelay; failed paste alone is not a reason to switch. Includes remote-window typing and Bash/tee file workflows. Not for general SSH administration or building the tool.
---

# KeyRelay text-to-keyboard input

## Prefer the AI's built-in keyboard tools

1. Assess whether the AI's available native keyboard tools can reliably complete input in the authorized target field. If they can, use them directly; do not invoke, build, open or request permissions for KeyRelay.
2. If capability is uncertain, verify a short harmless sample in a suitable, authorized input field and read back what it receives. Reuse existing failure evidence for the same environment rather than probing again. Do not submit long commands, business operations or file overwrites just to test capability.
3. Use the KeyRelay workflow below only when native keyboard tools are unavailable or a concrete failure prevents reliable input, such as lost characters, incorrect key events or an unsupported required key sequence. Briefly state the reason. Resolve focus, permission and layout problems rather than treating the fallback as a way around them. Stop repeating failed sends if KeyRelay also fails.

Paste failure does not imply keyboard failure. Client name, text length, multiline content and non-ASCII content do not automatically justify KeyRelay. If native tools can enter the text or a prepared encoding command, continue with native input. The tee / Base64 preparation below can be used with either input route; both require target-side verification.

## Locate the tool

Use the user-provided keyrelay / vmtype path, VMTYPE_BIN environment variable, or keyrelay / vmtype on PATH. Never assume a maintainer-specific path or infer the destination from clipboard content. Keep the CLI wrappers and KeyRelay.app together. Use the wrapper, not the app executable, for input.

Run --list-clients, then choose --client esxi, winapp, sunlogin, todesk, uu or generic according to the actual outer remote client. With no --client, legacy generic behavior is preserved. The client is not the remote OS: Windows App may contain a Linux shell. Sunlogin, ToDesk and UU are experimental presets awaiting target-side testing; do not claim support based on a preset name. Explicit --delay-ms overrides the preset. Windows App defaults to its known Mac bundle ID; other presets need manual focus or --target. A conflicting Windows App --target is rejected.

Check --help and --check-permission. Continue when existing permission is valid; do not ask again. If missing, explain the macOS Accessibility requirement and let the user complete authorization.

## Type text

Review the full text, start typing, and focus the target field during the countdown. In the GUI, explicitly allow line breaks for multiline input. Every Tab becomes a fixed number of spaces: default 4, configurable from 1 to 32. No column-based alignment and no extra Enter.

CLI, using the verified tool path in vmtype_bin:

```sh
"$vmtype_bin" --client esxi --file commands.sh --tab-spaces 4 --allow-enter --dry-run
"$vmtype_bin" --client esxi --file commands.sh --tab-spaces 4 --allow-enter --countdown 5 --delay-ms 100
```

--file reads local text; --stdin is also supported. --target BUNDLE_ID activates only the outer Mac app, not a tab, connection or input field. Verify the requested host, program and focus. A Windows App session may contain Windows software or a Linux terminal; use the actual target program's syntax.

Without a final newline the final line is not submitted. --allow-enter authorizes only the line breaks present in the text; they may execute commands. CLI defaults are 5 seconds and 4 spaces per Tab, independent of GUI preferences; generic uses 45 ms and remote presets use 100 ms unless --delay-ms overrides it. Original and expanded text are limited to 64 KB. Use an English input source and matching US layouts. Run one task at a time, keep focus, test a short harmless payload first, and read the target result before sending long content.

## User-controlled tee commands

There is no Vim mode or destination-file field. Put tee, the requested path, overwrite/append choices and sudo directly in the command text. Do not silently change paths or business content.

For ASCII content at a Linux Bash prompt:

```sh
tee /tmp/example.conf > /dev/null <<'VMTYPE_EOF'
name: example
port: 8080
VMTYPE_EOF
```

Include a newline after the final delimiter. Quote the delimiter to prevent expansion; it must occupy its own line, with no whitespace, and not collide with a content line. tee overwrites, tee -a appends, sudo tee elevates the writer. Follow the user's authorized operation. Finish sudo authentication and return to the shell prompt before typing. Relative paths use the target shell's working directory; do not create parent directories without scope.

Examples do not authorize their execution. Once a specific write is authorized, complete it without repetitive permission requests. Windows CMD/PowerShell and macOS shells need their own compatible syntax.

## Non-ASCII and long files

Non-ASCII text has no universal physical key mapping. For Linux Bash file input, convert content Tabs to the requested number of spaces locally, encode the remaining UTF-8 bytes as Base64, and prepare an ASCII decoder/tee command. The tool types the command; it does not decode or rewrite Base64 content.

```python
from pathlib import Path
import base64, shlex, textwrap

source = Path('content.txt')  # User-provided local content
remote_path = '/tmp/example.conf'  # Authorized remote path
width = 4  # User choice, 1-32; default 4
assert 1 <= width <= 32
assert remote_path and not any(c in remote_path for c in '\0\n\r')
body = source.read_bytes().replace(b'\t', b' ' * width)
encoded = base64.b64encode(body).decode('ascii')
path64 = base64.b64encode(remote_path.encode('utf-8')).decode('ascii')
target = '"$(printf %s ' + shlex.quote(path64) + ' | base64 -d)"'
tee = 'tee -- '  # Choose tee -a -- or sudo tee -- only as authorized
command = "base64 -d <<'VMTYPE_DATA' | " + tee + target + ' > /dev/null\n'
command += '\n'.join(textwrap.wrap(encoded, 76)) + '\nVMTYPE_DATA\n'
assert len(command.encode('ascii')) <= 64 * 1024
Path('commands.sh').write_text(command, encoding='ascii')
```

This prepares a file only; do not execute its remote command in the local shell. Check bash -n and vmtype --dry-run, then type into the authorized target Bash. Require base64 -d, tee, an existing parent directory and write permission. Encoding increases key count; if needed, split within authorized scope, overwrite the first chunk and append later chunks, and verify each. Never blindly resend an append chunk.

Encode the path to keep the command ASCII while preserving UTF-8 path bytes; reject NUL, CR and LF in paths. Content Tab replacement must happen before encoding: --tab-spaces cannot change indentation inside Base64.

## Verify and recover

Exit 0 or a sent status means key events were posted, not that the target received the correct text. Read the destination or compare its SHA-256 with the locally Tab-converted content. Distinguish typing, file writing, script execution and configuration activation.

Esc, GUI Stop or CLI Ctrl+C cancels. Focus checks cannot detect same-app tab/connection/input-field changes. A switch before countdown completion can change the selected destination app. On interruption, inspect whether the target is at a shell prompt, here-doc continuation or password prompt before recovery; never blindly send EOF or Enter.

The prerelease has a known repeated-character issue in local AppKit text fields. Remote compatibility requires target-side readback. Missing non-ASCII glyphs are not proof of wrong bytes; verify content without changing fonts, locale, permissions or restarting systems. Stop repeating the same failed send and report the concrete blocker.

Sensitive content should use files/stdin, not process arguments, public logs or issues. Normal completion cleans private temporary files; forced termination may leave them behind.

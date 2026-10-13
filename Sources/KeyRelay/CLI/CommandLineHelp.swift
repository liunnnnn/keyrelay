import Foundation

extension CommandLineInterface {
  static let help = """
    KeyRelay / keyrelay (vmtype compatibility alias)
    A macOS keyboard input tool for remote desktop clients and VM consoles.
    Without arguments, opens the GUI. Paths, tee, redirection and sudo belong in your input text.
    Examples:
      vmtype --text 'docker ps' --countdown 5
      vmtype --file commands.sh --allow-enter --tab-spaces 4

    --text TEXT         Input text (prefer --stdin / --file for sensitive content)
    --file PATH         Local UTF-8 input file, not a remote destination path
    --stdin             Read UTF-8 from standard input
    --target BUNDLE_ID  Activate a running Mac application
    --client ID        Remote client adapter; default generic. See --list-clients
    --list-clients     Show adapters and their actual validation status
    --countdown N       0-60 seconds, default 5
    --delay-ms N        Delay per key, 15-500 ms; generic 45, remote presets 100
    --allow-enter       Allow line breaks; Enter may execute terminal commands
    --tab-spaces N      Replace each Tab with N spaces, 1-32, default 4
    --dry-run           Validate input without sending keys
    --self-test         Run mapping and input validation checks without typing
    --check-permission  Check Accessibility permission
    --mode keys         Legacy compatibility; Vim input has been removed

    Supports printable ASCII and line breaks. Tabs become spaces; no extra Enter is appended.
    For non-ASCII file contents, prepare a Base64 decoder / tee command for the target shell.
    Use an English input source and US keyboard layout. Input and expanded text are limited to 64 KB.
    Always verify actual target content after sending.
    """

}

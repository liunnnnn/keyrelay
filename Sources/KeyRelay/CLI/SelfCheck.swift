import Foundation

enum SelfCheck {
  static func run() throws {
    for n in 32...126 { _ = try USKeyboard.stroke(Character(String(UnicodeScalar(n)!))) }
    guard try USKeyboard.stroke("a").code == 0, try USKeyboard.stroke("b").code == 11,
      try USKeyboard.stroke("Z").flags.contains(.maskShift), try USKeyboard.stroke("@").code == 19
    else { fatalError("key map") }
    do {
      _ = try InputPlanner.plan("\u{4E2D}\u{6587}", allowEnter: true)
      fatalError("must reject Unicode keys")
    } catch is ToolError {}
    do {
      _ = try InputPlanner.plan("a\nb", allowEnter: false)
      fatalError("must reject newline")
    } catch is ToolError {}
    do {
      _ = try InputPlanner.plan("a\0b", allowEnter: true)
      fatalError("must reject NUL")
    } catch is ToolError {}
    guard try InputPlanner.plan("a\r\nb", allowEnter: true).count == 3 else { fatalError("CRLF") }
    let tee = "tee './path with spaces' <<'EOF'\n  key: $HOME `id`\nEOF\n"
    let plan = try InputPlanner.plan(tee, allowEnter: true)
    guard plan.count == tee.count, plan.last?.code == 36 else { fatalError("here-doc plan") }
    for (width, text, expected) in [
      (4, "\ta\t\tb\r\n", "    a        b\n"), (1, "a\tb", "a b"), (8, "\t", "        "),
    ] {
      let actual = try InputPlanner.plan(text, allowEnter: true, tabSpaces: width)
      let wanted = try expected.map(USKeyboard.stroke)
      guard actual.map({ $0.code }) == wanted.map({ $0.code }),
        actual.map({ $0.flags.rawValue }) == wanted.map({ $0.flags.rawValue })
      else { fatalError("Tab expansion") }
      guard !actual.contains(where: { $0.code == 48 }) else { fatalError("must not send Tab") }
    }
    guard try InputPlanner.plan("\t", allowEnter: false).count == 4 else {
      fatalError("default Tab width")
    }
    for width in [0, 33] {
      do {
        _ = try InputPlanner.plan("a", allowEnter: false, tabSpaces: width)
        fatalError("invalid Tab width")
      } catch is ToolError {}
    }
    do {
      _ = try InputPlanner.plan(
        String(repeating: "\t", count: 2049), allowEnter: false, tabSpaces: 32)
      fatalError("expanded size limit")
    } catch is ToolError {}
    print(
      "PASS: ASCII, modifiers, here-docs, line breaks and validation; default/custom Tab expansion, consecutive Tabs and expanded size limit."
    )
  }

}

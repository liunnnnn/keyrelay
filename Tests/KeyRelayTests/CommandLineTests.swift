import Foundation

final class CommandLineTests {
  func testDefaultsAndLiteralOptionLikeText() throws {
    let command = try CommandLineInterface.parse(["--text", "--dry-run"])
    expectEqual(
      command,
      .type(
        TypingOptions(
          text: "--dry-run", target: nil, countdown: 5, delay: 45, tabSpaces: 4, allowEnter: false,
          dryRun: false)))
  }

  func testCustomOptionsAndLegacyKeysMode() throws {
    let command = try CommandLineInterface.parse([
      "--mode", "keys", "--text", "a\tb\n", "--allow-enter", "--dry-run",
      "--tab-spaces", "8", "--countdown", "0", "--delay-ms", "100", "--target", "test.target",
    ])
    expectEqual(
      command,
      .type(
        TypingOptions(
          text: "a\tb\n", target: "test.target", countdown: 0, delay: 100, tabSpaces: 8,
          allowEnter: true, dryRun: true)))
  }

  func testInvalidValuesAndConflictingInputsAreRejected() {
    for args in [
      ["--text"], ["--text", "a", "--text", "b"],
      ["--text", "a", "--tab-spaces", "0"], ["--text", "a", "--tab-spaces", "33"],
      ["--text", "a", "--countdown", "61"], ["--text", "a", "--delay-ms", "14"],
      ["--text", "a", "--mode", "vim"], ["--text", "a", "--write-target", "/tmp/example"],
      ["--unknown"], ["--self-test", "--text", "a"],
    ] {
      expectThrows(try CommandLineInterface.parse(args))
    }
  }

  func testCommandOrderingMatchesExistingHelpBehavior() throws {
    expectEqual(try CommandLineInterface.parse(["--help", "--unknown"]), .help)
    expectThrows(try CommandLineInterface.parse(["--unknown", "--help"]))
    expectEqual(try CommandLineInterface.parse(["--self-test"]), .selfTest)
    expectEqual(try CommandLineInterface.parse(["--check-permission"]), .checkPermission)
  }

  func testUTF8FileInput() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = directory.appendingPathComponent("input.txt")
    let content = "a\tb\r\n"
    try content.write(to: file, atomically: true, encoding: .utf8)
    guard case .type(let options) = try CommandLineInterface.parse(["--file", file.path]) else {
      return fail("Expected file input")
    }
    expectEqual(options.text, content)
  }
}

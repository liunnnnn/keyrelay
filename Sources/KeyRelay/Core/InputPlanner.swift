import Foundation

enum InputPlanner {
  private static func validateText(_ text: String) throws {
    guard !text.isEmpty else { throw ToolError.message("Text is empty.") }
    guard !text.contains("\0") else {
      throw ToolError.message("Binary content containing NUL is not supported.")
    }
    guard text.utf8.count <= 64 * 1024 else {
      throw ToolError.message("Each input is limited to 64 KB.")
    }
  }

  static func plan(_ text: String, allowEnter: Bool, tabSpaces: Int = 4) throws -> [KeyStroke] {
    guard (1...32).contains(tabSpaces) else {
      throw ToolError.message("Spaces per Tab must be between 1 and 32.")
    }
    try validateText(text)
    guard
      !text.unicodeScalars.contains(where: {
        ($0.value < 32 && ![9, 10, 13].contains($0.value)) || $0.value == 127
      })
    else {
      throw ToolError.message("Only Tab and line breaks are allowed as control characters.")
    }
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")
    guard allowEnter || !normalized.contains("\n") else {
      throw ToolError.message(
        "Text contains line breaks. Explicitly allow Enter with --allow-enter.")
    }
    let expanded = normalized.replacingOccurrences(
      of: "\t", with: String(repeating: " ", count: tabSpaces))
    try validateText(expanded)
    return try expanded.map(USKeyboard.stroke)
  }

}

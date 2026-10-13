import AppKit
import ApplicationServices
import Foundation

struct KeyStroke {
  let code: CGKeyCode
  let flags: CGEventFlags
  init(_ code: CGKeyCode, _ flags: CGEventFlags = []) {
    self.code = code
    self.flags = flags
  }
}

enum ToolError: Error, LocalizedError {
  case message(String)
  var errorDescription: String? {
    if case .message(let value) = self { return value }
    return nil
  }
}

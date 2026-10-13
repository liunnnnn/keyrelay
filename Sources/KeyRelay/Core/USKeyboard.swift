import AppKit

enum USKeyboard {
  // ANSI US physical key positions. Unicode payloads never substitute for keycodes.
  private static let plainKeys: [Character: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
    "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
    "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25,
    "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31, "u": 32, "[": 33,
    "i": 34, "p": 35, "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42,
    ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "`": 50, " ": 49,
    "\t": 48, "\n": 36,
  ]
  private static let shiftedKeys: [Character: Character] = [
    "!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6", "&": "7", "*": "8",
    "(": "9", ")": "0", "_": "-", "+": "=", "{": "[", "}": "]", ":": ";", "\"": "'",
    "|": "\\", "<": ",", ">": ".", "?": "/", "~": "`",
  ]

  static func stroke(_ char: Character) throws -> KeyStroke {
    if let code = plainKeys[char] { return KeyStroke(code) }
    if let base = shiftedKeys[char], let code = plainKeys[base] {
      return KeyStroke(code, .maskShift)
    }
    let scalars = String(char).unicodeScalars
    if scalars.count == 1, let value = scalars.first?.value, (65...90).contains(value),
      let code = plainKeys[Character(String(char).lowercased())]
    {
      return KeyStroke(code, .maskShift)
    }
    throw ToolError.message(
      "Non-ASCII text cannot be mapped to physical keys. For files, prepare a Base64 decoding command with tee."
    )
  }

}

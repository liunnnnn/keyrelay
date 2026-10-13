import Foundation

// Keep regression checks usable with Command Line Tools alone, without XCTest.
func expectEqual<T: Equatable>(
  _ actual: T, _ expected: T, file: StaticString = #file, line: UInt = #line
) {
  precondition(actual == expected, "Expected \(expected), got \(actual)", file: file, line: line)
}

func expectFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
  precondition(!value, "Expected false", file: file, line: line)
}

func expectThrows<T>(
  _ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line,
  inspect: (Error) -> Void = { _ in }
) {
  do {
    _ = try expression()
    preconditionFailure("Expected an error", file: file, line: line)
  } catch {
    inspect(error)
  }
}

func fail(_ message: String, file: StaticString = #file, line: UInt = #line) {
  preconditionFailure(message, file: file, line: line)
}

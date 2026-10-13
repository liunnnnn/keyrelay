import AppKit
import Foundation

if CommandLine.arguments.count > 1 {
  let environment = ProcessInfo.processInfo.environment
  if let pidFile = environment["VMTYPE_PID_FILE"] {
    try? String(ProcessInfo.processInfo.processIdentifier).write(
      toFile: pidFile, atomically: true, encoding: .utf8)
  }
  var result = 0
  do { try CommandLineInterface.run(Array(CommandLine.arguments.dropFirst())) } catch {
    FileHandle.standardError.write(Data(("Error: \(error.localizedDescription)\n").utf8))
    result = 1
  }
  if let resultFile = environment["VMTYPE_RESULT_FILE"] {
    try? String(result).write(toFile: resultFile, atomically: true, encoding: .utf8)
  }
  exit(Int32(result))
} else {
  let app = NSApplication.shared
  let delegate = ApplicationDelegate()
  app.delegate = delegate
  app.run()
}

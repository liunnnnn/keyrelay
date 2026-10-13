import AppKit

enum ApplicationFocus {
  static var current: NSRunningApplication? {
    // CLI execution must pump workspace notifications, or focus state stays cached.
    if Thread.isMainThread {
      _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
    }
    return NSWorkspace.shared.frontmostApplication
  }
}

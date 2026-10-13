import AppKit
import ApplicationServices

final class KeySender {
  private let lock = NSLock()
  private var cancelled = false
  func cancel() {
    lock.lock()
    cancelled = true
    lock.unlock()
  }
  func check(_ pid: pid_t? = nil) throws {
    lock.lock()
    let stop = cancelled
    lock.unlock()
    guard !stop else { throw ToolError.message("Cancelled.") }
    guard !CGEventSource.keyState(.combinedSessionState, key: 53) else {
      throw ToolError.message("Cancelled with Esc.")
    }
    if let pid, ApplicationFocus.current?.processIdentifier != pid {
      throw ToolError.message(
        "Target application lost focus (current: \(ApplicationFocus.current?.bundleIdentifier ?? "unknown")). Input stopped."
      )
    }
  }
  func run(
    plan: [KeyStroke], countdown: Int, delay: Int, target: String?, forbiddenPID: pid_t?,
    keyboard: KeyboardBehavior = .physicalUS, update: @escaping (String) -> Void
  ) throws {
    guard AccessibilityPermission.isGranted else {
      throw ToolError.message(AccessibilityPermission.message)
    }
    var expectedPID: pid_t?
    if let target {
      guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: target).first
      else {
        throw ToolError.message("Target application is not running: \(target)")
      }
      guard app.activate(options: [.activateIgnoringOtherApps]) else {
        throw ToolError.message("Could not activate the target application.")
      }
      expectedPID = app.processIdentifier
      for _ in 0..<30 {
        if ApplicationFocus.current?.processIdentifier == app.processIdentifier { break }
        try check()
        Thread.sleep(forTimeInterval: 0.1)
      }
    }
    if countdown > 0 {
      for left in stride(from: countdown, through: 1, by: -1) {
        try check()
        update("Starting in \(left) seconds. Click the target input field...")
        for _ in 0..<10 {
          try check()
          Thread.sleep(forTimeInterval: 0.1)
        }
      }
    }
    guard let foreground = ApplicationFocus.current,
      foreground.processIdentifier != forbiddenPID
    else {
      throw ToolError.message("Switch to the target window during the countdown.")
    }
    if let expectedPID, foreground.processIdentifier != expectedPID {
      throw ToolError.message(
        "Foreground application does not match --target (current: \(foreground.bundleIdentifier ?? "unknown"))."
      )
    }
    let pid = foreground.processIdentifier
    update("Sending keys to \(foreground.localizedName ?? "target application")...")
    let source = CGEventSource(stateID: .combinedSessionState)
    for (position, item) in plan.enumerated() {
      try check(pid)
      if position > 0 && position % 64 == 0 { update("Sending: \(position)/\(plan.count) keys...") }
      let modifier: CGKeyCode? =
        item.flags.contains(.maskControl) ? 59 : (item.flags.contains(.maskShift) ? 56 : nil)
      if let modifier {
        try post(modifier, true, item.flags, source)
        Thread.sleep(forTimeInterval: Double(keyboard.modifierSettleMilliseconds) / 1000)
      }
      do {
        try check(pid)
        try post(item.code, true, item.flags, source)
        Thread.sleep(forTimeInterval: Double(keyboard.keyHoldMilliseconds) / 1000)
        try post(item.code, false, item.flags, source)
      } catch {
        try? post(item.code, false, item.flags, source)
        if let modifier { try? post(modifier, false, [], source) }
        throw error
      }
      if let modifier { try post(modifier, false, [], source) }
      Thread.sleep(forTimeInterval: Double(delay) / 1000)
    }
    update("Key events sent. Verify the actual content in the target.")
  }
  private func post(
    _ code: CGKeyCode, _ down: Bool, _ flags: CGEventFlags, _ source: CGEventSource?
  ) throws {
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else {
      throw ToolError.message("Could not create a keyboard event.")
    }
    // Physical modifiers use flagsChanged plus device-dependent left-side flags.
    if code == 56 || code == 59 { event.type = .flagsChanged }
    var physicalFlags = flags
    // IOKit/hidsystem/IOLLEvent.h: NX_DEVICELSHIFTKEYMASK / NX_DEVICELCTLKEYMASK.
    if flags.contains(.maskShift) { physicalFlags.insert(CGEventFlags(rawValue: 0x0000_0002)) }
    if flags.contains(.maskControl) { physicalFlags.insert(CGEventFlags(rawValue: 0x0000_0001)) }
    event.flags = physicalFlags
    event.post(tap: .cghidEventTap)
  }
}

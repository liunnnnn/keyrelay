import AppKit

final class ApplicationDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate,
  NSTextFieldDelegate
{
  var window: NSWindow!
  var editor: NSTextView!
  let countdown = NSTextField(string: "3")
  let delay = NSTextField(string: "100")
  let tabSpaces = NSTextField(string: "4")
  let clientPicker = NSPopUpButton(frame: .zero, pullsDown: false)
  let clientStatus = NSTextField(wrappingLabelWithString: "")
  let allowEnter = NSButton(
    checkboxWithTitle: "Send line breaks (may execute commands in a terminal)", target: nil,
    action: nil)
  let status = NSTextField(
    wrappingLabelWithString: "Capture the clipboard or paste text, then start typing.")
  let summary = NSTextField(labelWithString: "0 characters / 0 lines")
  let hint = NSTextField(wrappingLabelWithString: "")
  let settingsPane = NSStackView()
  var settingsButton: NSButton!, captureButton: NSButton!, permissionButton: NSButton!
  var sendButton: NSButton!, cancelButton: NSButton!
  var sender: KeySender?
  var globalMonitor: Any?, localMonitor: Any?
  let preferences = UserDefaults.standard
  var selectedClient: RemoteClient {
    RemoteClients.all[max(0, clientPicker.indexOfSelectedItem)]
  }
  func currentPlan() throws -> [KeyStroke] {
    guard let width = Int(tabSpaces.stringValue) else {
      throw ToolError.message("Spaces per Tab must be between 1 and 32.")
    }
    return try InputPlanner.plan(
      editor.string, allowEnter: allowEnter.state == .on, tabSpaces: width)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    preferences.register(defaults: [
      "countdownSeconds": 3, "keyDelayMilliseconds": 100, "tabSpaces": 4,
    ])
    configureMenu()
    configureWindow()
    configureKeyboardMonitors()
    refreshInput()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  private func configureKeyboardMonitors() {
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if event.keyCode == 53 { self?.sender?.cancel() }
    }
    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if event.keyCode == 53 { self?.sender?.cancel() }
      return event
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  func textDidChange(_ notification: Notification) { refreshInput() }
  func controlTextDidChange(_ notification: Notification) { settingsChanged() }
  func refreshInput() {
    clientStatus.stringValue = "\(selectedClient.status). \(selectedClient.guidance)"
    let text = editor.string
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")
    let breaks = normalized.filter { $0 == "\n" }.count
    summary.stringValue =
      "\(text.count) characters / \(text.isEmpty ? 0 : breaks + 1) lines / Tab = \(tabSpaces.stringValue) spaces"
    hint.stringValue =
      "Click the target input field during the countdown. Use an English input source and US layout. Include paths and tee commands in your text."
    hint.textColor = .secondaryLabelColor
    var valid = !text.isEmpty
    if valid {
      do { _ = try currentPlan() } catch {
        valid = false
        hint.textColor = .systemOrange
        if normalized.contains(where: { (try? USKeyboard.stroke($0)) == nil }) {
          hint.stringValue =
            "Non-ASCII text needs a target-specific method. To write files, prepare a Base64 decoding command with tee."
        } else if breaks > 0 && allowEnter.state != .on {
          hint.stringValue =
            "Text contains \(breaks) line breaks. Allow line breaks in Settings. A here-doc terminator also needs Enter."
        } else {
          hint.stringValue = error.localizedDescription
        }
      }
    }
    sendButton.isEnabled = sender == nil && valid
  }
  @objc func toggleSettings() {
    guard sender == nil else { return }
    let opening = settingsPane.isHidden
    settingsPane.isHidden = !opening
    settingsButton.title = opening ? "Hide Settings" : "Settings"
    var frame = window.frame
    frame.origin.y -= opening ? 196 : -196
    frame.size.height += opening ? 196 : -196
    window.setFrame(frame, display: true, animate: true)
  }
  @objc func settingsChanged() {
    if let seconds = Int(countdown.stringValue), (1...60).contains(seconds) {
      preferences.set(seconds, forKey: "countdownSeconds")
    }
    if let ms = Int(delay.stringValue), (15...500).contains(ms) {
      preferences.set(ms, forKey: "keyDelayMilliseconds")
    }
    if let width = Int(tabSpaces.stringValue), (1...32).contains(width) {
      preferences.set(width, forKey: "tabSpaces")
    }
    refreshInput()
  }
  @objc func clientChanged() {
    guard sender == nil else { return }
    preferences.set(selectedClient.id, forKey: "remoteClient")
    delay.integerValue = selectedClient.id == "generic" ? 100 : selectedClient.defaultDelay
    settingsChanged()
  }
  @objc func captureClipboard() {
    guard let value = NSPasteboard.general.string(forType: .string) else {
      status.stringValue = "The clipboard contains no text."
      return
    }
    editor.string = value
    refreshInput()
    status.stringValue = "Captured \(value.count) characters."
  }
  @objc func openPermission() {
    if AccessibilityPermission.isGranted {
      status.stringValue = "Accessibility permission is ready."
      return
    }
    NSWorkspace.shared.open(
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    status.stringValue = AccessibilityPermission.message
  }
  @objc func cancelTyping() {
    sender?.cancel()
    status.stringValue = "Stopping. Check the target for partial input..."
  }
  func setBusy(_ busy: Bool) {
    editor.isEditable = !busy
    cancelButton.isEnabled = busy
    for button in [captureButton, settingsButton, permissionButton] { button?.isEnabled = !busy }
    countdown.isEnabled = !busy
    delay.isEnabled = !busy
    tabSpaces.isEnabled = !busy
    allowEnter.isEnabled = !busy
    clientPicker.isEnabled = !busy
    sendButton.title = busy ? "Typing..." : "Start Typing"
    refreshInput()
  }
  @objc func start() {
    guard sender == nil else { return }
    window.makeFirstResponder(sendButton)
    do {
      guard let seconds = Int(countdown.stringValue), (1...60).contains(seconds),
        let ms = Int(delay.stringValue), (15...500).contains(ms)
      else {
        throw ToolError.message("Countdown must be 1-60 seconds and delay must be 15-500 ms.")
      }
      let plan = try currentPlan()
      let client = selectedClient
      guard AccessibilityPermission.isGranted else {
        throw ToolError.message(AccessibilityPermission.message)
      }
      settingsChanged()
      let task = KeySender()
      sender = task
      setBusy(true)
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        do {
          try task.run(
            plan: plan, countdown: seconds, delay: ms, target: client.defaultTarget,
            forbiddenPID: ProcessInfo.processInfo.processIdentifier, keyboard: client.keyboard
          ) { message in
            DispatchQueue.main.async { self?.status.stringValue = message }
          }
        } catch {
          DispatchQueue.main.async { self?.status.stringValue = error.localizedDescription }
        }
        DispatchQueue.main.async {
          self?.sender = nil
          self?.setBusy(false)
        }
      }
    } catch { status.stringValue = error.localizedDescription }
  }
}

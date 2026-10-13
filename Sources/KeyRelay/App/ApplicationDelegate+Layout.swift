import AppKit

extension ApplicationDelegate {
  func configureMenu() {
    let menu = NSMenu()
    let item = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "Quit KeyRelay", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    item.submenu = appMenu
    menu.addItem(item)
    let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
    let editMenu = NSMenu(title: "Edit")
    for (name, selector, key) in [
      ("Undo", Selector(("undo:")), "z"), ("Cut", #selector(NSText.cut(_:)), "x"),
      ("Copy", #selector(NSText.copy(_:)), "c"), ("Paste", #selector(NSText.paste(_:)), "v"),
      ("Select All", #selector(NSText.selectAll(_:)), "a"),
    ] {
      editMenu.addItem(withTitle: name, action: selector, keyEquivalent: key)
    }
    editItem.submenu = editMenu
    menu.addItem(editItem)
    NSApp.mainMenu = menu
  }

  func configureWindow() {
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 780, height: 730),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "KeyRelay"
    window.center()
    window.minSize = NSSize(width: 740, height: 690)
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    let content = window.contentView!
    content.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
      stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
      stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
    ])
    func fullWidth(_ view: NSView) {
      view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
    func row(_ views: [NSView], spacer: Bool = false) -> NSStackView {
      let result = NSStackView()
      result.orientation = .horizontal
      result.spacing = 12
      result.alignment = .centerY
      for (index, view) in views.enumerated() {
        result.addArrangedSubview(view)
        if spacer && index == 0 { result.addArrangedSubview(NSView()) }
      }
      return result
    }
    let title = NSTextField(labelWithString: "KeyRelay")
    title.font = .systemFont(ofSize: 25, weight: .semibold)
    settingsButton = NSButton(title: "Settings", target: self, action: #selector(toggleSettings))
    let header = row([title, settingsButton], spacer: true)
    stack.addArrangedSubview(header)
    fullWidth(header)
    stack.addArrangedSubview(
      NSTextField(labelWithString: "Keyboard input adapters for remote desktops and VM consoles on macOS."))
    clientPicker.addItems(withTitles: RemoteClients.all.map(\.name))
    if let index = RemoteClients.all.firstIndex(where: {
      $0.id == preferences.string(forKey: "remoteClient")
    }) { clientPicker.selectItem(at: index) }
    clientPicker.target = self
    clientPicker.action = #selector(clientChanged)
    stack.addArrangedSubview(row([NSTextField(labelWithString: "Remote client"), clientPicker]))
    clientStatus.font = .systemFont(ofSize: 12)
    clientStatus.textColor = .secondaryLabelColor
    stack.addArrangedSubview(clientStatus)
    fullWidth(clientStatus)
    captureButton = NSButton(
      title: "Capture Clipboard", target: self, action: #selector(captureClipboard))
    let textHeader = row(
      [NSTextField(labelWithString: "Text to type"), captureButton], spacer: true)
    stack.addArrangedSubview(textHeader)
    fullWidth(textHeader)
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 650, height: 260))
    editor.delegate = self
    editor.isRichText = false
    editor.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
    editor.isAutomaticQuoteSubstitutionEnabled = false
    editor.isAutomaticDashSubstitutionEnabled = false
    editor.isAutomaticTextReplacementEnabled = false
    editor.isAutomaticSpellingCorrectionEnabled = false
    editor.isVerticallyResizable = true
    editor.autoresizingMask = [.width]
    editor.textContainer?.widthTracksTextView = true
    editor.textContainerInset = NSSize(width: 12, height: 12)
    scroll.documentView = editor
    stack.addArrangedSubview(scroll)
    fullWidth(scroll)
    scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 190).isActive = true
    summary.font = .systemFont(ofSize: 12)
    summary.textColor = .secondaryLabelColor
    let note = NSTextField(labelWithString: "No extra Enter")
    note.font = .systemFont(ofSize: 12)
    note.textColor = .secondaryLabelColor
    let metadata = row([summary, note], spacer: true)
    stack.addArrangedSubview(metadata)
    fullWidth(metadata)
    hint.font = .systemFont(ofSize: 13)
    stack.addArrangedSubview(hint)
    fullWidth(hint)

    settingsPane.orientation = .vertical
    settingsPane.alignment = .leading
    settingsPane.spacing = 12
    countdown.integerValue = min(60, max(1, preferences.integer(forKey: "countdownSeconds")))
    delay.integerValue = min(500, max(15, preferences.integer(forKey: "keyDelayMilliseconds")))
    tabSpaces.integerValue = min(32, max(1, preferences.integer(forKey: "tabSpaces")))
    tabSpaces.widthAnchor.constraint(equalToConstant: 55).isActive = true
    countdown.widthAnchor.constraint(equalToConstant: 55).isActive = true
    delay.widthAnchor.constraint(equalToConstant: 55).isActive = true
    for field in [countdown, delay, tabSpaces] {
      field.target = self
      field.action = #selector(settingsChanged)
      field.delegate = self
    }
    settingsPane.addArrangedSubview(
      row([
        NSTextField(labelWithString: "Countdown (seconds)"), countdown,
        NSTextField(labelWithString: "Delay per key (ms)"), delay,
      ]))
    settingsPane.addArrangedSubview(
      row([
        NSTextField(labelWithString: "Spaces per Tab"), tabSpaces,
        NSTextField(labelWithString: "1-32, default 4"),
      ]))
    allowEnter.target = self
    allowEnter.action = #selector(settingsChanged)
    settingsPane.addArrangedSubview(allowEnter)
    permissionButton = NSButton(
      title: "Check Accessibility", target: self, action: #selector(openPermission))
    settingsPane.addArrangedSubview(permissionButton)
    stack.addArrangedSubview(settingsPane)
    fullWidth(settingsPane)
    settingsPane.isHidden = true
    sendButton = NSButton(title: "Start Typing", target: self, action: #selector(start))
    sendButton.bezelStyle = .rounded
    sendButton.keyEquivalent = "\r"
    sendButton.keyEquivalentModifierMask = [.command]
    sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
    cancelButton = NSButton(title: "Stop (Esc)", target: self, action: #selector(cancelTyping))
    cancelButton.isEnabled = false
    let buttons = row([sendButton, cancelButton])
    stack.addArrangedSubview(buttons)
    status.font = .systemFont(ofSize: 12)
    status.textColor = .secondaryLabelColor
    stack.addArrangedSubview(status)
    fullWidth(status)
  }
}

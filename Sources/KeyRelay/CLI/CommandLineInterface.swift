import Foundation

struct TypingOptions: Equatable {
  let text: String
  let target: String?
  let countdown: Int
  let delay: Int
  let tabSpaces: Int
  let allowEnter: Bool
  let dryRun: Bool
  var clientID: String = "generic"
}

enum CLICommand: Equatable {
  case help
  case selfTest
  case checkPermission
  case listClients
  case type(TypingOptions)
}

enum CommandLineInterface {
  static func parse(_ args: [String]) throws -> CLICommand {
    if args == ["--self-test"] { return .selfTest }
    if args == ["--check-permission"] { return .checkPermission }
    if args == ["--list-clients"] { return .listClients }
    if args == ["--help"] || args == ["-h"] { return .help }
    var text: String?
    var target: String?
    var countdown = 5
    var delay: Int?
    var clientID = "generic"
    var tabSpaces = 4
    var allowEnter = false
    var dryRun = false
    var index = 0
    func value() throws -> String {
      index += 1
      guard index < args.count else { throw ToolError.message("An option value is missing.") }
      return args[index]
    }
    func setText(_ value: String) throws {
      guard text == nil else {
        throw ToolError.message("Choose only one of --text, --file or --stdin.")
      }
      text = value
    }
    while index < args.count {
      switch args[index] {
      case "--help", "-h": return .help
      case "--mode":
        guard try value() == "keys" else {
          throw ToolError.message(
            "Vim input was removed. Provide your own tee / here-doc command as text.")
        }
      case "--write-target", "--append", "--sudo":
        throw ToolError.message(
          "The tool does not choose destination files. Put tee, paths and options in your input text."
        )
      case "--text": try setText(value())
      case "--file": try setText(String(contentsOfFile: value(), encoding: .utf8))
      case "--stdin":
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard let decoded = String(data: data, encoding: .utf8) else {
          throw ToolError.message("Standard input must be UTF-8.")
        }
        try setText(decoded)
      case "--target": target = try value()
      case "--client": clientID = try value()
      case "--countdown":
        guard let number = Int(try value()), (0...60).contains(number) else {
          throw ToolError.message("Countdown must be between 0 and 60 seconds.")
        }
        countdown = number
      case "--delay-ms":
        guard let number = Int(try value()), (15...500).contains(number) else {
          throw ToolError.message("Delay must be between 15 and 500 milliseconds.")
        }
        delay = number
      case "--tab-spaces":
        guard let number = Int(try value()), (1...32).contains(number) else {
          throw ToolError.message("Spaces per Tab must be between 1 and 32.")
        }
        tabSpaces = number
      case "--allow-enter": allowEnter = true
      case "--dry-run": dryRun = true
      default: throw ToolError.message("Unknown option: \(args[index]). Use --help for usage.")
      }
      index += 1
    }
    guard let text else { throw ToolError.message("Provide --text, --file or --stdin.") }
    let client = try RemoteClients.find(clientID)
    let resolvedTarget = try RemoteClients.target(for: client, override: target)
    return .type(
      TypingOptions(
        text: text, target: resolvedTarget, countdown: countdown, delay: delay ?? client.defaultDelay,
        tabSpaces: tabSpaces, allowEnter: allowEnter, dryRun: dryRun, clientID: clientID))
  }

  static func run(_ args: [String]) throws {
    switch try parse(args) {
    case .help:
      print(help)
    case .selfTest:
      try SelfCheck.run()
    case .checkPermission:
      guard AccessibilityPermission.isGranted else {
        throw ToolError.message(AccessibilityPermission.message)
      }
      print("Accessibility permission check passed.")
    case .listClients:
      for client in RemoteClients.all {
        print("\(client.id)\t\(client.name)\t\(client.status)")
      }
    case .type(let options):
      try type(options)
    }
  }

  private static func type(_ options: TypingOptions) throws {
    let client = try RemoteClients.find(options.clientID)
    let text = options.text
    let plan = try InputPlanner.plan(
      text, allowEnter: options.allowEnter, tabSpaces: options.tabSpaces)
    if options.dryRun {
      if options.clientID != "generic" {
        print("Client: \(client.name). \(client.status). Delay: \(options.delay) ms.")
      }
      print(
        "Validated: \(text.utf8.count) source UTF-8 bytes, \(plan.count) keys; each Tab becomes \(options.tabSpaces) spaces. No keys sent."
      )
      return
    }
    let sender = KeySender()
    if options.clientID != "generic" {
      print("Client: \(client.name). \(client.status). \(client.guidance)")
    }
    let interrupts = [SIGINT, SIGTERM].map { number -> DispatchSourceSignal in
      signal(number, SIG_IGN)
      let source = DispatchSource.makeSignalSource(signal: number, queue: .global())
      source.setEventHandler { sender.cancel() }
      source.resume()
      return source
    }
    defer {
      for source in interrupts { source.cancel() }
      signal(SIGINT, SIG_DFL)
      signal(SIGTERM, SIG_DFL)
    }
    try sender.run(
      plan: plan, countdown: options.countdown, delay: options.delay, target: options.target,
      forbiddenPID: nil, keyboard: client.keyboard
    ) {
      print($0)
      fflush(stdout)
    }
  }
}

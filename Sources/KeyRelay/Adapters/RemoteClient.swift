import Foundation

struct KeyboardBehavior: Equatable {
  let modifierSettleMilliseconds: Int
  let keyHoldMilliseconds: Int

  // Preserve the modifier and key timing used by the original remote sender.
  static let physicalUS = KeyboardBehavior(
    modifierSettleMilliseconds: 12, keyHoldMilliseconds: 12)
}

struct RemoteClient: Equatable {
  let id: String
  let name: String
  let status: String
  let guidance: String
  let defaultTarget: String?
  let defaultDelay: Int
  let keyboard: KeyboardBehavior
}

enum RemoteClients {
  static let all: [RemoteClient] = [
    RemoteClient(
      id: "generic", name: "Other / manual selection", status: "Unverified client",
      guidance: "Focus the intended input field. Test a short sample before sending long text.",
      defaultTarget: nil, defaultDelay: 45, keyboard: .physicalUS),
    RemoteClient(
      id: "esxi", name: "ESXi browser console", status: "Previous Bash file test passed",
      guidance: "Select the VM console and focus its shell. The browser, not the guest OS, receives local keys.",
      defaultTarget: nil, defaultDelay: 100, keyboard: .physicalUS),
    RemoteClient(
      id: "winapp", name: "Windows App", status: "Modifier fix retained; full retest pending",
      guidance: "Select the intended connection and input field. Match the remote keyboard layout.",
      defaultTarget: "com.microsoft.rdc.macos", defaultDelay: 100, keyboard: .physicalUS),
    RemoteClient(
      id: "sunlogin", name: "Sunlogin", status: "Awaiting remote-client testing",
      guidance: "Experimental: uses the existing physical sender. Focus the remote window and test a short sample.",
      defaultTarget: nil, defaultDelay: 100, keyboard: .physicalUS),
    RemoteClient(
      id: "todesk", name: "ToDesk", status: "Awaiting remote-client testing",
      guidance: "Experimental: uses the existing physical sender. Focus the remote window and test a short sample.",
      defaultTarget: nil, defaultDelay: 100, keyboard: .physicalUS),
    RemoteClient(
      id: "uu", name: "UU Remote", status: "Awaiting remote-client testing",
      guidance: "Experimental: uses the existing physical sender. Focus the remote window and test a short sample.",
      defaultTarget: nil, defaultDelay: 100, keyboard: .physicalUS),
  ]

  static func find(_ id: String) throws -> RemoteClient {
    guard let client = all.first(where: { $0.id == id }) else {
      throw ToolError.message("Unknown remote client: \(id). Use --list-clients.")
    }
    return client
  }

  static func target(for client: RemoteClient, override: String?) throws -> String? {
    if let override, let expected = client.defaultTarget, override != expected {
      throw ToolError.message(
        "--target conflicts with \(client.name). Use \(expected), or choose --client generic for a custom target.")
    }
    return override ?? client.defaultTarget
  }
}

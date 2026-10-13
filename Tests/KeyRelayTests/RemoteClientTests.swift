import Foundation

final class RemoteClientTests {
  func testUniqueIdentifiersAndPreservedKeyboardBehavior() throws {
    expectEqual(Set(RemoteClients.all.map(\.id)).count, RemoteClients.all.count)
    expectEqual(RemoteClients.all.count, 6)
    for client in RemoteClients.all {
      expectEqual(try RemoteClients.find(client.id), client)
      expectEqual(client.keyboard.modifierSettleMilliseconds, 12)
      expectEqual(client.keyboard.keyHoldMilliseconds, 12)
    }
    expectThrows(try RemoteClients.find("unknown"))
  }

  func testClientDefaultsOverridesAndOptionOrdering() throws {
    for client in RemoteClients.all {
      for args in [
        ["--client", client.id, "--text", "a"],
        ["--text", "a", "--client", client.id],
      ] {
        guard case .type(let options) = try CommandLineInterface.parse(args) else {
          return fail("Expected typing options")
        }
        expectEqual(options.clientID, client.id)
        expectEqual(options.delay, client.defaultDelay)
        expectEqual(options.target, client.defaultTarget)
        expectEqual(options.text, "a")
      }
      guard case .type(let custom) = try CommandLineInterface.parse([
        "--delay-ms", "72", "--text", "a", "--client", client.id,
      ]) else { return fail("Expected custom delay") }
      expectEqual(custom.delay, 72)
    }
    expectEqual(try CommandLineInterface.parse(["--list-clients"]), .listClients)
  }

  func testTargetConflictsAndUnknownClientsAreRejected() throws {
    expectThrows(try CommandLineInterface.parse(["--text", "a", "--client", "not-a-client"]))
    expectThrows(try CommandLineInterface.parse([
      "--text", "a", "--client", "winapp", "--target", "another.app",
    ]))
    for id in ["generic", "esxi", "sunlogin", "todesk", "uu"] {
      guard case .type(let options) = try CommandLineInterface.parse([
        "--text", "a", "--client", id, "--target", "custom.app",
      ]) else { return fail("Expected custom target") }
      expectEqual(options.target, "custom.app")
    }
    expectThrows(try CommandLineInterface.parse(["--client"]))
  }
}

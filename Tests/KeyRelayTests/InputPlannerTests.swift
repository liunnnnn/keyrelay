import AppKit

final class InputPlannerTests {
  func testPlanningMatchesPreRefactorFixtures() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures/PlanningBaseline.json")
    let cases = try JSONDecoder().decode([PlanningCase].self, from: Data(contentsOf: url))

    for sample in cases {
      if let expectedError = sample.error {
        expectThrows(
          try InputPlanner.plan(
            sample.text, allowEnter: sample.allowEnter, tabSpaces: sample.tabSpaces)
        ) {
          expectEqual($0.localizedDescription, expectedError)
        }
      } else {
        let plan = try InputPlanner.plan(
          sample.text, allowEnter: sample.allowEnter, tabSpaces: sample.tabSpaces)
        expectEqual(plan.map { [UInt64($0.code), $0.flags.rawValue] }, sample.keys ?? [])
      }
    }
  }

  func testEveryTabBecomesSpacesWithoutSendingTabKeys() throws {
    for width in 1...32 {
      let plan = try InputPlanner.plan("\tA\t\tB", allowEnter: false, tabSpaces: width)
      expectEqual(plan.count, width * 3 + 2)
      expectEqual(plan.filter { $0.code == 49 }.count, width * 3)
      expectFalse(plan.contains { $0.code == 48 })
    }
  }

  func testLineBreakNormalizationDoesNotAppendEnter() throws {
    let plan = try InputPlanner.plan("a\r\nb\rc", allowEnter: true)
    expectEqual(plan.map(\.code), [0, 36, 11, 36, 8])
    expectEqual(try InputPlanner.plan("abc", allowEnter: false).count, 3)
  }

  func testExpandedTextSizeLimit() throws {
    expectEqual(
      try InputPlanner.plan(String(repeating: "\t", count: 2048), allowEnter: false, tabSpaces: 32)
        .count, 65536)
    expectThrows(
      try InputPlanner.plan(String(repeating: "\t", count: 2049), allowEnter: false, tabSpaces: 32))
    expectThrows(
      try InputPlanner.plan(String(repeating: "a", count: 65537), allowEnter: false))
  }

  private struct PlanningCase: Decodable {
    let text: String
    let allowEnter: Bool
    let tabSpaces: Int
    let keys: [[UInt64]]?
    let error: String?
  }
}

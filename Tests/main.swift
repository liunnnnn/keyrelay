import Foundation

let planner = InputPlannerTests()
let cli = CommandLineTests()
let clients = RemoteClientTests()

try planner.testPlanningMatchesPreRefactorFixtures()
try planner.testEveryTabBecomesSpacesWithoutSendingTabKeys()
try planner.testLineBreakNormalizationDoesNotAppendEnter()
try planner.testExpandedTextSizeLimit()
try cli.testDefaultsAndLiteralOptionLikeText()
try cli.testCustomOptionsAndLegacyKeysMode()
cli.testInvalidValuesAndConflictingInputsAreRejected()
try cli.testCommandOrderingMatchesExistingHelpBehavior()
try cli.testUTF8FileInput()
try clients.testUniqueIdentifiersAndPreservedKeyboardBehavior()
try clients.testClientDefaultsOverridesAndOptionOrdering()
try clients.testTargetConflictsAndUnknownClientsAreRejected()
print(
  "PASS: 12 regression checks; planning fixtures, Tab widths, line breaks, limits, CLI/file input and remote client adapters."
)

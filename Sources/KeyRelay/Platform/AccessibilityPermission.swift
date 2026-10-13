import ApplicationServices
import Foundation

enum AccessibilityPermission {
  static var isGranted: Bool {
    CGPreflightPostEventAccess() || AXIsProcessTrusted()
  }

  static let message =
    "Accessibility permission is missing. Enable KeyRelay in System Settings > Privacy & Security > Accessibility. If CLI input is blocked, also check the calling terminal or AI application."
}

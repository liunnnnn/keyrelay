// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "KeyRelay",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "KeyRelay", targets: ["KeyRelay"])],
  targets: [.executableTarget(name: "KeyRelay")],
  swiftLanguageVersions: [.v5]
)

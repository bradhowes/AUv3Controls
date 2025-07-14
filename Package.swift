// swift-tools-version: 6.1

import PackageDescription

// Set to `true` to depend on CustomAlert package. SPM traits do not seem to let us skip depending on a
// package.
let useCustomAlert = false

let packageDependencies: [Package.Dependency] = [
  .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.20.0"),
  .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
  .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
] + (useCustomAlert ? [.package(url: "https://github.com/divadretlaw/CustomAlert.git", from: "4.1.0")] : [])

let targetDependencies: [Target.Dependency] = [
  .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
  .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
] + (useCustomAlert ? [.product(name: "CustomAlert", package: "CustomAlert")] : [])

let swiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
] + (useCustomAlert ? [.define("useCustomAlert")] : [])

let package = Package(
  name: "AUv3Controls",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "AUv3Controls",
      targets: ["AUv3Controls"])
  ],
  dependencies: packageDependencies,
  targets: [
    .target(
      name: "AUv3Controls",
      dependencies: targetDependencies,
      exclude: ["Examples/README.md", "Knob/README.md", "Toggle/README.md"],
      resources: [.process("Resources/Assets.xcassets")],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "AUv3ControlsTests",
      dependencies: [
        "AUv3Controls",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      exclude: ["__Snapshots__/"],
      swiftSettings: swiftSettings
    )
  ]
)

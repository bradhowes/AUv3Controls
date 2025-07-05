// swift-tools-version: 6.0

import PackageDescription

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
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.20.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/divadretlaw/CustomAlert.git", from: "4.1.0"),
    .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.3.0")
  ],
  targets: [
    .target(
      name: "AUv3Controls",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "CustomAlert", package: "CustomAlert"),
        .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
      ],
      exclude: ["Examples/README.md", "Knob/README.md", "Toggle/README.md"],
      resources: [.process("Resources/Assets.xcassets")],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=complete")
      ]
    ),
    .testTarget(
      name: "AUv3ControlsTests",
      dependencies: [
        "AUv3Controls",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      exclude: ["__Snapshots__/"]
   )
  ]
)

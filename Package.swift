// swift-tools-version: 6.1

import PackageDescription

// Set to `true` to depend on CustomAlert package
let useCustomAlert: Trait = .init(name: "useCustomAlert", description: "Use CustomAlert package")

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
  traits: [useCustomAlert],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.20.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/divadretlaw/CustomAlert.git", from: "4.1.0")
  ],
  targets: [
    .target(
      name: "AUv3Controls",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "CustomAlert", package: "CustomAlert", condition: .when(traits: [useCustomAlert.name]))
      ],
      exclude: ["Examples/README.md", "Knob/README.md", "Toggle/README.md"],
      resources: [.process("Resources/Assets.xcassets")],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .define("SUPPORT_CUSTOM_ALERT", .when(traits: [useCustomAlert.name]))
      ]
    ),
    .testTarget(
      name: "AUv3ControlsTests",
      dependencies: [
        "AUv3Controls",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      exclude: ["__Snapshots__/"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .define("SUPPORT_CUSTOM_ALERT", .when(traits: [useCustomAlert.name]))
      ]
    )
  ]
)

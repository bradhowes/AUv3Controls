// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "AUv3Controls",
  platforms: [
    .iOS(.v16),
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "AUv3Controls",
      targets: ["AUv3Controls"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.3.0")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.14.2")
  ],
  targets: [
    .target(
      name: "AUv3Controls",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=complete")
      ]
    ),
    .testTarget(
      name: "AUv3ControlsTests",
      dependencies: [
        "AUv3Controls",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ])
  ]
)

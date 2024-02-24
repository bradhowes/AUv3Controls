// swift-tools-version: 5.9

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
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.8.0")),
    .package(url: "https://github.com/doordash-oss/swiftui-preview-snapshots", from: "1.0.0")
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
        .product(name: "PreviewSnapshotsTesting", package: "swiftui-preview-snapshots"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ])
  ]
)

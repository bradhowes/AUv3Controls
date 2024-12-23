import AVFoundation
import Clocks
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

final class DemoPreviewTests: XCTestCase {

  @MainActor
  func testDualityPreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = DualityViewPreview.previews
      try withSnapshotTesting(record: .failed) {
        try assertSnapshot(matching: view, size: CGSize(width: 400, height: 800))
      }
    }
  }

  @MainActor
  func testEvenlopePreview() async throws {
    try withDependencies { $0 = .live } operation: {
      let view = EnvelopeViewPreview.previews
      try assertSnapshot(matching: view, size: CGSize(width: 400, height: 800))
    }
  }
}

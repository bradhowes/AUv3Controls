import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

extension XCTest {

  @inlinable
  func makeUniqueSnapshotName(_ funcName: String) -> String {
    let platform: String
    platform = "iOS"
    return funcName + "-" + platform
  }

  @inlinable
  func assertSnapshot<V: SwiftUI.View>(matching: V, file: StaticString = #file, testName: String = #function,
                                       line: UInt = #line) throws {
    isRecording = false
    try XCTSkipIf(ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW"), "GitHub CI")
    SnapshotTesting.assertSnapshot(of: matching,
                                   as: .image(layout: .fixed(width: 220, height: 220)),
                                   named: makeUniqueSnapshotName(testName),
                                   file: file, testName: testName, line: line)
  }
}
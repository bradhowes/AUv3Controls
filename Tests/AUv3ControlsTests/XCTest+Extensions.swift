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
    print(ProcessInfo.processInfo.environment)

    if let path = ProcessInfo.processInfo.environment["XCTestBundlePath"] {
      let isOnGithub = path.contains("/Users/runner/work")
      try XCTSkipIf(isOnGithub, "GitHub CI")
    }

#if os(iOS)
    SnapshotTesting.assertSnapshot(of: matching,
                                   as: .image(drawHierarchyInKeyWindow: false,
                                              layout: .fixed(width: 220, height: 220)),
                                   named: makeUniqueSnapshotName(testName),
                                   file: file, testName: testName, line: line)
#endif
  }
}

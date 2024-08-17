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
  func assertSnapshot<V: SwiftUI.View>(
    matching: V,
    size: CGSize = CGSize(width: 220, height: 220),
    file: StaticString = #file, testName: String = #function,
    line: UInt = #line
  ) throws {
    isRecording = false

    let uniqueTestName = makeUniqueSnapshotName(testName)
    let isOnGithub = ProcessInfo.processInfo.environment["XCTestBundlePath"]?.contains("/Users/runner/work") ?? false

#if os(iOS)
    if let result = SnapshotTesting.verifySnapshot(
      of: matching,
      as: .image(
        drawHierarchyInKeyWindow: false,
        layout: .fixed(width: size.width, height: size.height)
      ),
      named: uniqueTestName,
      file: file,
      testName: testName,
      line: line
    ) {
      print("uniqueTestName:", uniqueTestName)
      print("file:", file)
      if isOnGithub {
        print("***", result)
      } else {
        XCTFail(result, file: file, line: line)
      }
    }
#endif
  }
}

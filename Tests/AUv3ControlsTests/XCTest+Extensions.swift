import SnapshotTesting
import SwiftUI
import XCTest

@testable import AUv3Controls

public struct __SnapshotTestViewWrapper<Content: View>: View {
  let size: CGSize
  let content: Content

  public init(size: CGSize, @ViewBuilder _ content: () -> Content) {
    self.size = size
    self.content = content()
  }

  public var body: some View {
    Group {
      content
    }
    .frame(width: size.width, height: size.height)
    .background(Color.black)
    .environment(\.colorScheme, .dark)
  }
}

extension XCTest {

  @inlinable
  func makeUniqueSnapshotName(_ funcName: String) -> String {
    let platform: String
    platform = "iOS"
    return funcName + "-" + platform
  }

  @MainActor @inlinable
  func assertSnapshot<V: SwiftUI.View>(
    matching: V,
    size: CGSize = CGSize(width: 220, height: 220),
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
  ) throws {
    let uniqueTestName = makeUniqueSnapshotName(testName)
    let isOnGithub = ProcessInfo.processInfo.environment["XCTestBundlePath"]?.contains("/Users/runner/work") ?? false

#if os(iOS)

    let view = __SnapshotTestViewWrapper(size: size) {
      matching
    }

    if let result = SnapshotTesting.verifySnapshot(
      of: view,
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

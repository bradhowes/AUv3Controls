//import SnapshotTesting
//import SwiftUI
//import XCTest
//
//@testable import AUv3Controls
//
//extension XCTest {
//
//  @inlinable
//  func makeUniqueSnapshotName(_ funcName: String) -> String {
//    let platform: String
//    platform = "iOS"
//    return funcName + "-" + platform
//  }
//
//  @inlinable
//  func assertSnapshot<V: SwiftUI.View>(matching: V, size: CGSize = CGSize(width: 220, height: 220),
//                                       file: StaticString = #file, testName: String = #function,
//                                       line: UInt = #line) throws {
//    isRecording = false
//    // print(ProcessInfo.processInfo.environment)
//
//    let isOnGithub = ProcessInfo.processInfo.environment["XCTestBundlePath"]?.contains("/Users/runner/work") ?? false
//
//#if os(iOS) || os(tvOS)
//    let result = SnapshotTesting.verifySnapshot(of: matching,
//                                                as: .image(drawHierarchyInKeyWindow: false,
//                                                           layout: .fixed(width: size.width, height: size.height)),
//                                                named: makeUniqueSnapshotName(testName),
//                                                file: file, testName: testName, line: line)
//#elseif os(macOS)
//    let result = SnapshotTesting.verifySnapshot(of: matching,
//                                                as: .image(drawHierarchyInKeyWindow: false,
//                                                           layout: .fixed(width: size.width, height: size.height)),
//                                                named: makeUniqueSnapshotName(testName),
//                                                file: file, testName: testName, line: line)
//#endif
//      if isOnGithub {
//        print("***", result)
//      } else {
//        XCTFail(result, file: file, line: line)
//      }
//    }
//
//#if os(iOS)
////    SnapshotTesting.assertSnapshot(of: matching,
////                                   as: .image(drawHierarchyInKeyWindow: false,
////                                              layout: .fixed(width: size.width, height: size.height)),
////                                   named: makeUniqueSnapshotName(testName),
////                                   file: file, testName: testName, line: line)
//#endif
//  }
//}

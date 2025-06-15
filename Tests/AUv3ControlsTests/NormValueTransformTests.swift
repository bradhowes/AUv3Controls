import SwiftUI
import XCTest

@testable import AUv3Controls

final class LoggerTests: XCTestCase {

  @MainActor
  func testLogger() {
    let log = Logger.shared
    XCTAssertNotNil(log)
    log.log(level: .error, "Blah")
    XCTAssertTrue(log.logs.isEmpty)

    log.isEnabled = true
    log.log(level: .error, "Blah")
    XCTAssertFalse(log.logs.isEmpty)

    log.clear()
    XCTAssertTrue(log.logs.isEmpty)
  }
}

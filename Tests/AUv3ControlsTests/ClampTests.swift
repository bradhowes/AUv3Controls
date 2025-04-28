import SwiftUI
import XCTest

@testable import AUv3Controls

final class ClampTests: XCTestCase {

  func testClosedRange() {
    XCTAssertEqual(-10.0, (-10...10).clamp(value: -20.0))
    XCTAssertEqual(-8.0, (-10...10).clamp(value: -8.0))
    XCTAssertEqual(9.999, (-10...10).clamp(value: 9.999))
    XCTAssertEqual(10.0, (-10...10).clamp(value: 10.00001))
  }

  func testBinaryFloatingPoint() {
    XCTAssertEqual(-10.0, -20.0.clamped(to: -10...10))
    XCTAssertEqual(-8.0, -8.0.clamped(to: -10...10))
    XCTAssertEqual(9.999, 9.999.clamped(to: -10...10))
    XCTAssertEqual(10.0, 10.00001.clamped(to: -10...10))

    XCTAssertEqual(-10.0, -20.clamped(to: -10...10))
    XCTAssertEqual(-8.0, -8.clamped(to: -10...10))
    XCTAssertEqual(9.999, 9.999.clamped(to: -10...10))
    XCTAssertEqual(10.0, 10.00001.clamped(to: -10...10))
  }
}

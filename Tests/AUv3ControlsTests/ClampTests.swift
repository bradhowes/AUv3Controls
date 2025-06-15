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

    XCTAssertEqual(-10.0, (-10.0...10.0).clamp(value: -20.0))
    XCTAssertEqual(-8.0, (-10.0...10.0).clamp(value: -8.0))
    XCTAssertEqual(9.999, (-10.0...10.0).clamp(value: 9.999))
    XCTAssertEqual(10.0, (-10.0...10.0).clamp(value: 10.00001))
  }

  func testNormalize() {
    XCTAssertEqual(0.0, (-10...10).normalize(value: -13))
    XCTAssertEqual(1.0, (-10...10).normalize(value: 13))
    XCTAssertEqual(0.5, (-10...10).normalize(value: 0.0))

    XCTAssertEqual(0.0, (4...7).normalize(value: -13))
    XCTAssertEqual(1.0, (4...7).normalize(value: 13))
    XCTAssertEqual(0.5, (4...7).normalize(value: 5.5))
  }
}

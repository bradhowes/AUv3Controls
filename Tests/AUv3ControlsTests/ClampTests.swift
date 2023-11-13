import SwiftUI
import XCTest

@testable import AUv3Controls

final class ClampTests: XCTestCase {

  func testClosedRange() {
    XCTAssertEqual(-10.0, (-10...10).clamp(-20.0))
    XCTAssertEqual(-8.0, (-10...10).clamp(-8.0))
    XCTAssertEqual(9.999, (-10...10).clamp(9.999))
    XCTAssertEqual(10.0, (-10...10).clamp(10.00001))
  }

  func testBinaryFloatingPoint() {
    XCTAssertEqual(-10.0, Double.clamp(-20, to: -10...10))
    XCTAssertEqual(-8.0, Double.clamp(-8, to: -10...10))
    XCTAssertEqual(9.999, Double.clamp(9.999, to: -10...10))
    XCTAssertEqual(10.0, Double.clamp(10.00001, to: -10...10))

    XCTAssertEqual(-10.0, Float.clamp(-20, to: -10...10))
    XCTAssertEqual(-8.0, Float.clamp(-8, to: -10...10))
    XCTAssertEqual(9.999, Float.clamp(9.999, to: -10...10))
    XCTAssertEqual(10.0, Float.clamp(10.00001, to: -10...10))

    XCTAssertEqual(-10.0, -20.clamped(to: -10...10))
    XCTAssertEqual(-8.0, -8.clamped(to: -10...10))
    XCTAssertEqual(9.999, 9.999.clamped(to: -10...10))
    XCTAssertEqual(10.0, 10.00001.clamped(to: -10...10))
  }
}

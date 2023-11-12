import SwiftUI
import XCTest

@testable import AUv3Controls

final class AngleTests: XCTestCase {

  func testNormalize() {
    XCTAssertEqual(0.0, Angle(degrees: -360.0).normalized, accuracy: 1e-6)
    XCTAssertEqual(0.5, Angle(degrees: -180.0).normalized, accuracy: 1e-6)
    XCTAssertEqual(0.0, Angle(degrees: 0.0).normalized, accuracy: 1e-6)
    XCTAssertEqual(0.5, Angle(degrees: 180.0).normalized, accuracy: 1e-6)
    XCTAssertEqual(1.0, Angle(degrees: 360.0).normalized, accuracy: 1e-6)
    XCTAssertEqual(1.0, Angle(degrees: 720).normalized, accuracy: 1e-6)
  }
}

import SwiftUI
import XCTest

@testable import AUv3Controls

final class NormValueTransformTests: XCTestCase {

  func testValueToNormTransformLinear() {
    let nvt = NormValueTransform(minimumValue: 0.0, maximumValue: 4.0, logScale: false)
    XCTAssertEqual(0.0, nvt.valueToNorm(0.0), accuracy: 0.0001)
    XCTAssertEqual(0.05, nvt.valueToNorm(0.2), accuracy: 0.0001)
    XCTAssertEqual(0.5, nvt.valueToNorm(2.0), accuracy: 0.0001)
    XCTAssertEqual(1.0, nvt.valueToNorm(4.0), accuracy: 0.0001)
  }

  func testValueToNormTransformLog() {
    let nvt = NormValueTransform(minimumValue: 0.0, maximumValue: 4.0, logScale: true)
    XCTAssertEqual(0.0, nvt.valueToNorm(0.0), accuracy: 0.0001)
    XCTAssertEqual(0.7403626894942439, nvt.valueToNorm(2.0), accuracy: 0.0001)
    XCTAssertEqual(1.0, nvt.valueToNorm(4.0), accuracy: 0.0001)
  }

  func testNormToValueTransformLinear() {
    let nvt = NormValueTransform(minimumValue: 0.0, maximumValue: 4.0, logScale: false)
    XCTAssertEqual(0.0, nvt.normToValue(0.0), accuracy: 0.0001)
    XCTAssertEqual(2.0, nvt.normToValue(0.5), accuracy: 0.0001)
    XCTAssertEqual(4.0, nvt.normToValue(1.0), accuracy: 0.0001)
  }

  func testNormToValueTransformLog() {
    let nvt = NormValueTransform(minimumValue: 0.0, maximumValue: 4.0, logScale: true)
    XCTAssertEqual(0.0, nvt.normToValue(0.0), accuracy: 0.0001)
    XCTAssertEqual(0.9610122934081686, nvt.normToValue(0.5), accuracy: 0.0001)
    XCTAssertEqual(4.0, nvt.normToValue(1.0), accuracy: 0.0001)
  }
}

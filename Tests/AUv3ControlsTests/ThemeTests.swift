import SwiftUI
import XCTest

@testable import AUv3Controls

final class ThemeTests: XCTestCase {

  func testInit() {
    var theme = Theme()
    XCTAssertEqual(.gray, theme.controlBackgroundColor)
    XCTAssertEqual(16.0, theme.controlIndicatorLength)

    theme.controlIndicatorLength = 12.34
    XCTAssertEqual(12.34, theme.controlIndicatorLength)

    theme.controlIndicatorStartAngle = .degrees(90)
    XCTAssertEqual(0.888888, theme.controlIndicatorEndAngleNormalized, accuracy: 0.00001)

    theme.controlIndicatorEndAngle = .degrees(-34)
    XCTAssertEqual(0.9055555555555556, theme.controlIndicatorEndAngleNormalized, accuracy: 0.00001)

    XCTAssertEqual(-2.1642082724729685, theme.controlIndicatorStartEndSpanRadians)
    XCTAssertEqual(0.25, theme.endTrim(for: 0.0))
  }

  func testControlForegroundGradient() {
    let theme = Theme()
    _ = theme.controlForegroundGradient(radius: 1.0)
  }

  func testControlBackgroundGradient() {
    let theme = Theme()
    _ = theme.controlBackgroundGradient(radius: 1.0)
  }
}

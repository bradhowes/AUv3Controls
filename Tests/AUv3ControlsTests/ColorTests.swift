import SwiftUI
import XCTest

@testable import AUv3Controls

final class ColorTests: XCTestCase {

  func testSkipping() {
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:" #888").description)
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:"  0x888").description)
  }

  func testFromHex3() {
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 0.0).description,
                   Color(hex:"000").description)
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:"888").description)
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:"888").description)
    XCTAssertEqual(Color(red: 1.0, green: 1.0, blue: 1.0),
                   Color(hex:"FFF"))
    XCTAssertEqual(Color(red: 1.0, green: 0.0, blue: 0.0),
                   Color(hex:"F00"))
    XCTAssertEqual(Color(red: 0.0, green: 1.0, blue: 0.0),
                   Color(hex:"0F0"))
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 1.0),
                   Color(hex:"00F"))
  }

  func testFromHex6() {
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 0.0).description,
                   Color(hex:"000000").description)
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:"888888").description)
    XCTAssertEqual(Color(red: 1.0, green: 1.0, blue: 1.0),
                   Color(hex:"FFFFFF"))
    XCTAssertEqual(Color(red: 1.0, green: 0.0, blue: 0.0),
                   Color(hex:"FF0000"))
    XCTAssertEqual(Color(red: 0.0, green: 1.0, blue: 0.0),
                   Color(hex:"00FF00"))
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 1.0),
                   Color(hex:"0000FF"))
  }

  func testFromHex8() {
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0).description,
                   Color(hex:"00000000").description)
    XCTAssertEqual(Color(red: 0.5333, green: 0.5333, blue: 0.5333).description,
                   Color(hex:"FF888888").description)
    XCTAssertEqual(Color(red: 1.0, green: 1.0, blue: 1.0),
                   Color(hex:"FFFFFFFF"))
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0),
                   Color(hex:"FF000000"))
    XCTAssertEqual(Color(red: 0.0, green: 1.0, blue: 0.0),
                   Color(hex:"FF00FF00"))
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 1.0),
                   Color(hex:"FF0000FF"))
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.5).description,
                   Color(hex:"80000000").description)
    XCTAssertEqual(Color(red: 0.0, green: 1.0, blue: 0.0, opacity: 0.5).description,
                   Color(hex:"8000FF00").description)
    XCTAssertEqual(Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 0.5).description,
                   Color(hex:"800000FF").description)
  }

  func testInvalidParse() {
    XCTAssertEqual(Color.black, Color(hex:""))
    XCTAssertEqual(Color.black, Color(hex:" "))
    XCTAssertEqual(Color.black, Color(hex:" 0"))
  }
}

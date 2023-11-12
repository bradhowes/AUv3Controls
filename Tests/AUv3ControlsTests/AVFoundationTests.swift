import AVFoundation
import XCTest

@testable import AUv3Controls

final class AUParameterTests: XCTestCase {

  func testRange() {
    let parameter = AUParameterTree.createFloat(withIdentifier: "foo", name: "Foo", address: 123, range: -3...13)
    XCTAssertEqual(-3, parameter.range.lowerBound)
    XCTAssertEqual(13, parameter.range.upperBound)
  }

  func testBoolConversions() {
    XCTAssertEqual(false, AUValue(-1.0).asBool)
    XCTAssertEqual(false, AUValue(0.0).asBool)
    XCTAssertEqual(false, AUValue(0.4).asBool)
    XCTAssertEqual(false, AUValue(0.49).asBool)
    XCTAssertEqual(true, AUValue(0.5).asBool)
    XCTAssertEqual(true, AUValue(1.0).asBool)
    XCTAssertEqual(true, AUValue(1e5).asBool)

    XCTAssertEqual(0.0, false.asValue)
    XCTAssertEqual(1.0, true.asValue)
  }
}


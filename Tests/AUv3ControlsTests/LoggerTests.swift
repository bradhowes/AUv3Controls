import SwiftUI
import XCTest
import os

@testable import AUv3Controls

final class LoggerTests: XCTestCase {

  func canThrow() throws {}
  func canThrowAndReturn() throws -> String { "hello" }
  func plain() {}
  func plainAndReturn() -> String { "world" }

  func testLogger() throws {
    let log: Logger = .init(category: "mother")

    try log.measure("block that throws") {
      try canThrow()
    }

    var value = try log.measure("block that throws and returns") {
      try canThrowAndReturn()
    }

    XCTAssertEqual(value, "hello")

    log.measure("block") {
      plain()
    }

    value = log.measure("block that returns") {
      plainAndReturn()
    }

    XCTAssertEqual(value, "world")
  }
}

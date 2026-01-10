// Copyright © 2025 Brad Howes. All rights reserved.

import OSLog

private class BundleTag {}

extension Logger {

  init(category: String) {
    let subsystem = Bundle(for: BundleTag.self).bundleIdentifier?.lowercased() ?? "?"
    self.init(subsystem: subsystem, category: category)
  }
}

extension Logger {

  func measure<T>(_ label: String, _ block: () throws -> T) throws -> T {
    let start = Date()
    defer { self.info("\(label, privacy: .public) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label, privacy: .public) BEGIN")
    return try block()
  }

  func measure<T>(_ label: String, _ block: () -> T) -> T {
    let start = Date()
    defer { self.info("\(label, privacy: .public) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label, privacy: .public) BEGIN")
    return block()
  }

  func measure(_ label: String, _ block: () throws -> Void) throws {
    let start = Date()
    defer { self.info("\(label, privacy: .public) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label, privacy: .public) BEGIN")
    try block()
  }

  func measure(_ label: String, _ block: () -> Void) {
    let start = Date()
    defer { self.info("\(label, privacy: .public) END - duration: \(Date().timeIntervalSince(start))s") }
    self.info("\(label, privacy: .public) BEGIN")
    block()
  }
}

private let isRunningForPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

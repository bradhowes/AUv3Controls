// Copyright © 2025 Brad Howes. All rights reserved.

// Taken from TCA

import OSLog

public final class Logger {
  @MainActor
  public static let shared = Logger()
  public var isEnabled = false
  @Published public var logs: [String] = []

#if DEBUG

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  private var logger: os.Logger { os.Logger(subsystem: "AUv3Controls", category: "tracing") }

  public func log(level: OSLogType = .default, _ string: @autoclosure () -> String) {
    guard self.isEnabled else { return }

    let msg = string()
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      print("\(msg)")
    } else {
      if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
        self.logger.log(level: level, "\(msg)")
      }
    }
    self.logs.append(msg)
  }

  public func clear() { self.logs = [] }

#else

  @inlinable @inline(__always)
  public func log(level: OSLogType = .default, _ string: @autoclosure () -> String) {}

  @inlinable @inline(__always)
  public func clear() {}

#endif
}

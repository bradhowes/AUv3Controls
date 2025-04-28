// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation

extension UUID {
  // From https://gist.github.com/xsleonard/b28573142215e25858bebb9ba907829c
  public var asUInt64: UInt64 {
    let bytes = self.uuid
    let first = (UInt64(bytes.0) << (8 * 0) |
       UInt64(bytes.1) << (8 * 1) |
       UInt64(bytes.2) << (8 * 2) |
       UInt64(bytes.3) << (8 * 3) |
       UInt64(bytes.4) << (8 * 4) |
       UInt64(bytes.5) << (8 * 5) |
       UInt64(bytes.6) << (8 * 6) |
       UInt64(bytes.7) << (8 * 7))
    let second = (UInt64(bytes.8) << (8 * 0) |
       UInt64(bytes.9) << (8 * 1) |
       UInt64(bytes.10) << (8 * 2) |
       UInt64(bytes.11) << (8 * 3) |
       UInt64(bytes.12) << (8 * 4) |
       UInt64(bytes.13) << (8 * 5) |
       UInt64(bytes.14) << (8 * 6) |
       UInt64(bytes.15) << (8 * 7))
    return first ^ second
  }
}

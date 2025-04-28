// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

extension Angle {

  /**
   Computes a normalized representation of the current angle such that the final value is between 0.0 (inclusive)
   and 1.0 (exclusive).

   - returns: normalized value
   */
  public var normalized: Double {
    var value = self.degrees
    while value >= 360 { value -= 360.0 }
    while value < 0.0 { value += 360.0 }
    return value / 360.0
  }
}

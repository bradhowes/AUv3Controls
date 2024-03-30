import SwiftUI

extension Angle {

  /**
   Computes a normalized representation of the current angle such that the final value is between 0.0 (inclusive)
   and 1.0 (exclusive). The angle value is first constrained to be between 0° and 360° (exclusive), the result being
   that the final value will never reach 1.0.

   - returns: normalized value
   */
  var normalized: Double {
    var value = self.degrees
    while value >= 360 { value -= 360.0 }
    while value < 0.0 { value += 360.0 }
    return value / 360.0
  }
}

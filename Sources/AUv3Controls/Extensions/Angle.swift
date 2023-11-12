import SwiftUI

extension Angle {
  var normalized: Double {
    var value = self.degrees
    while value > 360 {
      value -= 360.0
    }
    while value < 0.0 {
      value += 360.0
    }
    return value / 360.0
  }
}

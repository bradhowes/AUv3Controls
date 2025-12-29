// Copyright © 2025 Brad Howes. All rights reserved.

import AudioUnit
import Foundation

public struct NormValueTransform: Equatable {
  public let minimumValue: Double
  public let maximumValue: Double
  public let logScale: Bool

  public init(parameter: AUParameter) {
    self.minimumValue = Double(parameter.minValue)
    self.maximumValue = Double(parameter.maxValue)
    self.logScale = parameter.flags.contains(.flag_DisplayLogarithmic)
  }

  public init(minimumValue: Double, maximumValue: Double, logScale: Bool) {
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    self.logScale = logScale
  }

  public func normToValue(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  public func valueToNorm(_ value: Double) -> Double {
    let norm = (value.clamped(to: minimumValue...maximumValue) - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log10(norm * 9 + 1) : norm
  }
}

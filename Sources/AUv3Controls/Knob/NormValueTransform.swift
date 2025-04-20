import AudioUnit
import Foundation

public struct NormValueTransform: Equatable {
  private let minimumValue: Double
  private let maximumValue: Double
  private let logScale: Bool

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
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  public func valueToNorm(_ value: Double) -> Double {
    let norm = (value.clamped(to: minimumValue...maximumValue) - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log(1.0 + norm * 9.0) / 10.0 : norm
  }

  /**
   Convert a normalized value (0.0-1.0) into a 'trim' value that is used as the endpoint of the knob indicator.

   @par norm the value to convert
   */
  public func normToTrim(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (Self.maxTrim - Self.minTrim) + Self.minTrim
  }

  static private let minTrim: CGFloat = 0.11111115  // Use non-zero value to leave a tiny circle at "zero"
  static private let maxTrim: CGFloat = 1 - minTrim
}

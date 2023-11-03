import SwiftUI

public struct KnobConfig : Equatable {
  public let minTrim: CGFloat = 0.11111115 // Use non-zero value to leave a tiny circle at "zero"
  public var maxTrim: CGFloat { 1 - minTrim }

  public let title: String
  public let id: Int
  public let minimumValue: Double
  public let maximumValue: Double
  public let logScale: Bool
  public let controlWidth: CGFloat
  public let maxHeight: CGFloat
  public let dragScaling: CGFloat

  public let valueStrokeWidth: CGFloat
  public let font: Font
  public let formatter: NumberFormatter = Self.formatter

  /// How much travel is need to change the knob from `minimumValue` to `maximumValue`.
  /// By default this is 1x the `controlSize` value. Setting it to 2 will require 2x the `controlSize` to go from
  /// `minimumValue` to `maximumValue`.
  public let touchSensitivity: CGFloat

  /// Percentage of `controlSize` where a touch/mouse event will perform maximum value change. This defines a
  /// vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
  /// over value changes.
  public let maxChangeRegionWidthPercentage: CGFloat = 0.1

  let minimumAngle = Angle(degrees: 40)
  let maximumAngle = Angle(degrees: 320)

  let maxChangeRegionWidthHalf: CGFloat
  let halfControlSize: CGFloat

  public init(title: String, id: Int, minimumValue: Double, maximumValue: Double, controlSize: CGFloat = 80.0,
              maxHeight: CGFloat = 100.0, touchSensitivity: CGFloat = 2.0, logScale: Bool = false,
              valueStrokeWidth: CGFloat = 6.0, font: Font = .callout) {
    self.title = title
    self.id = id
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    self.controlWidth = controlSize
    self.maxHeight = 100.0
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlSize * touchSensitivity)
    self.logScale = logScale
    self.maxChangeRegionWidthHalf = max(8, controlSize * maxChangeRegionWidthPercentage) / 2
    self.halfControlSize =  controlSize / 2
    self.valueStrokeWidth = valueStrokeWidth
    self.font = font
  }

  func normToTrim(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maxTrim - minTrim) + minTrim
  }

  func normToValue(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  func formattedValue(_ value: Double) -> String { formatter.string(from: NSNumber(floatLiteral: value)) ?? "NaN" }

  func formattedValue(_ value: Float) -> String { formattedValue(Double(value)) }

  func normToFormattedValue(_ norm: Double) -> String { formattedValue(normToValue(norm)) }

  func valueToNorm(_ value: Double) -> Double {
    let norm = (value - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log(1.0 + norm * 9.0) / 10.0 : norm
  }

  static public var formatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

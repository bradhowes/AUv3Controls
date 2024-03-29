import AVFoundation
import SwiftUI

public struct KnobConfig: Equatable {
  public let theme: Theme
  public let parameter: AUParameter

  public var id: ObjectIdentifier { ObjectIdentifier(parameter) }
  public var title: String { self.parameter.displayName }
  public var range: ClosedRange<Double> { minimumValue...maximumValue }

  let minTrim: CGFloat = 0.11111115 // Use non-zero value to leave a tiny circle at "zero"
  var maxTrim: CGFloat { 1 - minTrim }

  public let minimumValue: Double
  public let maximumValue: Double

  public var logScale: Bool
  public var controlDiameter: CGFloat { didSet { updateDragScaling() } }
  public var controlRadius: CGFloat { controlDiameter / 2.0 }
  public var controlEditorWidth: CGFloat = 200

  /// How much travel is need to change the knob from `minimumValue` to `maximumValue`.
  /// By default this is 1x the `controlSize` value. Setting it to 2 will require 2x the `controlSize` to go from
  /// `minimumValue` to `maximumValue`.
  var touchSensitivity: CGFloat { didSet { updateDragScaling() } }

  var maxHeight: CGFloat

  public var indicatorStrokeWidth: CGFloat
  public let indicatorStartAngle = Angle(degrees: 40)
  public let indicatorEndAngle = Angle(degrees: 320)

  public var showValueDuration = 1.25

  /// Percentage of `controlDiameter` where a touch/mouse event will perform maximum value change. This defines a
  /// vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
  /// over value changes.
  let maxChangeRegionWidthPercentage: CGFloat = 0.1

  let maxChangeRegionWidthHalf: CGFloat

  public init(parameter: AUParameter, controlDiameter: CGFloat = 80.0,
              maxHeight: CGFloat = 100.0, touchSensitivity: CGFloat = 2.0, logScale: Bool = false,
              valueStrokeWidth: CGFloat = 6.0, theme: Theme) {
    self.parameter = parameter
    self.controlDiameter = controlDiameter
    self.minimumValue = Double(parameter.minValue)
    self.maximumValue = Double(parameter.maxValue)
    self.maxHeight = 100.0
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlDiameter * touchSensitivity)
    self.logScale = logScale
    self.maxChangeRegionWidthHalf = max(8, controlDiameter * maxChangeRegionWidthPercentage) / 2
    self.indicatorStrokeWidth = valueStrokeWidth
    self.theme = theme
  }

  private var dragScaling: CGFloat

  private mutating func updateDragScaling() {
    dragScaling = 1.0 / (controlDiameter * touchSensitivity)
  }

  func controlWidthIf(_ value: Bool) -> CGFloat { value ? controlEditorWidth : controlDiameter }

  func controlWidthIf<T>(_ value: T?) -> CGFloat { controlWidthIf(value != nil) }

  func normToTrim(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maxTrim - minTrim) + minTrim
  }

  func normToValue(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  func formattedValue(_ value: Double) -> String { theme.format(value: value) }

  func formattedValue(_ value: Float) -> String { formattedValue(Double(value)) }

  func valueToNorm(_ value: Double) -> Double {
    let norm = (value.clamped(to: minimumValue...maximumValue) - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log(1.0 + norm * 9.0) / 10.0 : norm
  }

  func dragChangeValue(last: CGPoint, position: CGPoint) -> CGFloat {
    let dY = last.y - position.y
    // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
    let dX = min(abs(position.x - controlRadius), controlRadius - 1)
    // Calculate scaling effect -- no scaling if in small vertical path in the middle of the knob, otherwise the
    // value gets smaller than 1.0 as the touch moves farther away from the center.
    let scrubberScaling = (dX < maxChangeRegionWidthHalf ? 1.0 : (1.0 - dX / controlRadius))
    // Finally, calculate change to `norm` value
    let normChange = dY * dragScaling * scrubberScaling
    return normChange
  }

  static private var formatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

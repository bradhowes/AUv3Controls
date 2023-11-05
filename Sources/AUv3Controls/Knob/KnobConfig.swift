import AVFoundation
import SwiftUI

public struct KnobConfig: Equatable {
  let minTrim: CGFloat = 0.11111115 // Use non-zero value to leave a tiny circle at "zero"
  var maxTrim: CGFloat { 1 - minTrim }

  let title: String
  let minimumValue: Double
  let maximumValue: Double
  let logScale: Bool

  let controlRadius: CGFloat
  let maxHeight: CGFloat
  let dragScaling: CGFloat

  let indicatorStrokeWidth: CGFloat

  let theme: Theme

  /// How much travel is need to change the knob from `minimumValue` to `maximumValue`.
  /// By default this is 1x the `controlSize` value. Setting it to 2 will require 2x the `controlSize` to go from
  /// `minimumValue` to `maximumValue`.
  let touchSensitivity: CGFloat

  /// Percentage of `controlSize` where a touch/mouse event will perform maximum value change. This defines a
  /// vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
  /// over value changes.
  let maxChangeRegionWidthPercentage: CGFloat = 0.1

  let minimumAngle = Angle(degrees: 40)
  let maximumAngle = Angle(degrees: 320)

  let maxChangeRegionWidthHalf: CGFloat
  let halfControlSize: CGFloat

  public init(parameter: AUParameter, controlSize: CGFloat = 80.0,
              maxHeight: CGFloat = 100.0, touchSensitivity: CGFloat = 2.0, logScale: Bool = false,
              valueStrokeWidth: CGFloat = 6.0, theme: Theme) {
    self.title = parameter.displayName
    self.minimumValue = Double(parameter.minValue)
    self.maximumValue = Double(parameter.maxValue)
    self.controlRadius = controlSize
    self.maxHeight = 100.0
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlSize * touchSensitivity)
    self.logScale = logScale
    self.maxChangeRegionWidthHalf = max(8, controlSize * maxChangeRegionWidthPercentage) / 2
    self.halfControlSize =  controlSize / 2
    self.indicatorStrokeWidth = valueStrokeWidth
    self.theme = theme
  }

  func controlWidthIf(_ value: Bool) -> CGFloat { value ? 200 : controlRadius }

  func normToTrim(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maxTrim - minTrim) + minTrim
  }

  func normToValue(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  func formattedValue(_ value: Double) -> String { theme.format(value: value) }

  func formattedValue(_ value: Float) -> String { formattedValue(Double(value)) }

  func valueToNorm(_ value: Double) -> Double {
    let norm = (value - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log(1.0 + norm * 9.0) / 10.0 : norm
  }

  func dragChangeValue(lastY: CGFloat, dragValue: DragGesture.Value) -> CGFloat {
    let dY = lastY - dragValue.location.y
    // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
    let dX = min(abs(dragValue.location.x - halfControlSize), halfControlSize - 1)
    // Calculate scaling effect -- no scaling if in small vertical path in the middle of the knob, otherwise the
    // value gets smaller than 1.0 as the touch moves farther away from the center.
    let scrubberScaling = (dX < maxChangeRegionWidthHalf ? 1.0 : (1.0 - dX / halfControlSize))
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

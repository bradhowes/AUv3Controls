import AVFoundation
import SwiftUI

/**
 Shabby attempt at isolating customizations for a `KnobFeature`. Right now there is a 1-1 relationship between this and
 an AUParameter instance. Appearance configuration has been split out into a separate `Theme` class, but there are
 still too many details here that would be better shared across `KnobFeature` instances.
 */
public struct KnobConfig: Equatable {

  /// The AUParameter being displayed
  public let parameter: AUParameter

  /// The common themeable settings to use
  public let theme: Theme

  /// Holds `true` if the parameter uses the logarithmic scale
  public let logScale: Bool

  /// The height of the control (knob + title)
  public let controlHeight: CGFloat

  /// The unique ID to identify the task that reverts the knob's title after a value change. This is based on
  /// the `id` value above, but it must not collide with any other visible `showCancelId` values.
  public var showValueCancelId: UInt64 { parameter.associatedTaskId }

  /// The unique ID to identify the SwiftUI view -- this is the same as the AUParamete `address` attribute
  public var id: UInt64 { parameter.address }

  /// The title to show in the control when the value is not changing.
  public var title: String { self.parameter.displayName }

  /// The range of the values over which the control can move
  public var range: ClosedRange<Double> { minimumValue...maximumValue }

  /// The minimum value of the AUParameter
  public var minimumValue: Double { Double(parameter.minValue) }

  /// The maximum value of the AUParameter
  public var maximumValue: Double { Double(parameter.maxValue) }

  /// The diameter (width and height) of the knob
  public var controlDiameter: CGFloat { didSet { updateDragScaling() } }

  /// The radius of the knob
  public var controlRadius: CGFloat { controlDiameter / 2.0 }

  /// The width of the standard knob value editor
  public var controlEditorWidth: CGFloat = 200

  /**
   How much travel is need to change the knob from `minimumValue` to `maximumValue`.
   By default this is 2x the `controlSize` value. Setting it to 4 will require 4x the `controlSize` distance
   to go from `minimumValue` to `maximumValue`, thus making it more sensitive in general.
   */
  public var touchSensitivity: CGFloat { didSet { updateDragScaling() } }

  /**
   Amount of time to wait with no more AUParameter changes before emitting the last one in the async stream of
   values. Reduces traffic at the expense of increased latency. Note that this is *not* the same as throttling where
   one limits the rate of emission but ultimately emits all events: debouncing drops all but the last event in a
   window of time.
   */
  public var debounceDuration: Duration = .milliseconds(10)

  /**
   Percentage of `controlDiameter` where a touch/mouse event will perform maximum value change. This defines a
   vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
   over value changes.
   */
  private let maxChangeRegionWidthPercentage: CGFloat = 0.1

  private let maxChangeRegionWidthHalf: CGFloat

  private var dragScaling: CGFloat

  public init(
    parameter: AUParameter,
    controlDiameter: CGFloat = 100.0,
    controlHeight: CGFloat = 120.0,
    touchSensitivity: CGFloat = 2.0,
    theme: Theme
  ) {
    precondition(parameter.address < AUParameter.maxParameterAddress,
                 "AUParameter address must be < \(AUParameter.maxParameterAddress)")

    self.parameter = parameter
    self.controlDiameter = controlDiameter
    self.logScale = parameter.flags.contains(.flag_DisplayLogarithmic)

    self.controlHeight = controlHeight
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlDiameter * touchSensitivity)
    self.maxChangeRegionWidthHalf = max(8, controlDiameter * maxChangeRegionWidthPercentage) / 2
    self.theme = theme
  }
}

extension KnobConfig {

  public func controlWidthIf(_ value: Bool) -> CGFloat { value ? controlEditorWidth : controlDiameter }

  public func controlWidthIf<T>(_ value: T?) -> CGFloat { controlWidthIf(value != nil) }
}

extension KnobConfig {

  private mutating func updateDragScaling() {
    dragScaling = 1.0 / (controlDiameter * touchSensitivity)
  }

  private var minTrim: CGFloat { 0.11111115 } // Use non-zero value to leave a tiny circle at "zero"
  private var maxTrim: CGFloat { 1 - minTrim }

  /**
   Convert a normalized value (0.0-1.0) into a 'trim' value that is used as the endpoint of the knob indicator.

   @par norm the value to convert
   */
  public func normToTrim(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maxTrim - minTrim) + minTrim
  }

  public func normToValue(_ norm: Double) -> Double {
    (logScale ? (pow(10, norm) - 1.0) / 9.0 : norm) * (maximumValue - minimumValue) + minimumValue
  }

  public func valueToNorm(_ value: Double) -> Double {
    let norm = (value.clamped(to: minimumValue...maximumValue) - minimumValue) / (maximumValue - minimumValue)
    return logScale ? log(1.0 + norm * 9.0) / 10.0 : norm
  }
}

extension KnobConfig {

  public func formattedValue(_ value: Double) -> String { theme.format(value: value) }

  public func formattedValue(_ value: Float) -> String { formattedValue(Double(value)) }

  public func dragChangeValue(last: CGPoint, position: CGPoint) -> CGFloat {
    let dY = last.y - position.y
    // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
    let dX = min(abs(position.x - controlRadius), controlRadius - 1)
    // Calculate "scrubber" scaling effect, where the change in dx gets smaller the further away from the center one
    // moves the touch/pointer. No scaling if in +/- maxChangeRegionWidthHalf vertical path in the middle of the knob,
    // otherwise the value gets smaller than 1.0 as the touch moves farther away outside of the maxChangeRegionWidthHalf
    let scrubberScaling = (dX < maxChangeRegionWidthHalf ? 1.0 : (1.0 - (dX - maxChangeRegionWidthHalf) / controlRadius))
    // Finally, calculate change to `norm` value
    return dY * dragScaling * scrubberScaling
  }

  static private var formatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

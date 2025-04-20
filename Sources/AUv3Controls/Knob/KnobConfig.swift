import AVFoundation
import SwiftUI

/**
 Shabby attempt at isolating customizations for a `KnobFeature`. Right now there is a 1-1 relationship between this and
 an AUParameter instance. Appearance configuration has been split out into a separate `Theme` class, but there are
 still too many details here that would be better shared across `KnobFeature` instances.
 */
public struct KnobConfig: Equatable {

  /// Holds `true` if the parameter uses the logarithmic scale
  public let logScale: Bool

  /// The height of the control (knob + title)
  public let controlHeight: CGFloat

  /// The title to show in the control when the value is not changing.
  public let displayName: String

  /// The minimum value of the AUParameter
  public let minimumValue: Double

  /// The maximum value of the AUParameter
  public let maximumValue: Double

  /// The range of the values over which the control can move
  public var range: ClosedRange<Double> { minimumValue...maximumValue }

  /// The diameter (width and height) of the knob
  public var controlDiameter: CGFloat { didSet { updateDragScaling() } }

  /// The radius of the knob
  public var controlRadius: CGFloat { controlDiameter / 2.0 }

  /// The width of the standard knob value editor
  public var controlEditorWidth: CGFloat = 200

  /// How long to show the value in the knob's label
  public var controlShowValueDuration = 1.25

  /// Duration of the animation when changing between value and title in control label
  public var controlChangeAnimationDuration: TimeInterval = 0.35

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

  /// The formatter to use when creating textual representations of a control's numeric value
  public var valueFormatter: NumberFormatter

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
    valueFormatter: NumberFormatter? = nil
  ) {
    self.displayName = parameter.displayName
    self.minimumValue = Double(parameter.minValue)
    self.maximumValue = Double(parameter.maxValue)

    self.controlDiameter = controlDiameter
    self.logScale = parameter.flags.contains(.flag_DisplayLogarithmic)

    self.controlHeight = controlHeight
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlDiameter * touchSensitivity)
    self.maxChangeRegionWidthHalf = max(8, controlDiameter * maxChangeRegionWidthPercentage) / 2
    self.valueFormatter = valueFormatter ?? Self.defaultFormatter
  }

  public init(
    value: Double,
    displayName: String,
    minimumValue: Double,
    maximumValue: Double,
    logarithmic: Bool = false,
    controlDiameter: CGFloat = 100.0,
    controlHeight: CGFloat = 120.0,
    touchSensitivity: CGFloat = 2.0,
    valueFormatter: NumberFormatter? = nil
  ) {
    self.displayName = displayName
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue

    self.controlDiameter = controlDiameter
    self.logScale = logarithmic

    self.controlHeight = controlHeight
    self.touchSensitivity = touchSensitivity
    self.dragScaling = 1.0 / (controlDiameter * touchSensitivity)
    self.maxChangeRegionWidthHalf = max(8, controlDiameter * maxChangeRegionWidthPercentage) / 2
    self.valueFormatter = valueFormatter ?? Self.defaultFormatter
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
}

extension KnobConfig {

//  /**
//   Obtain a text representation of the given value.
//
//   - parameter value the numeric value to format
//   - returns the formatted value
//   */
//  public func format(value: Double) -> String { valueFormatter.string(from: NSNumber(value: value)) ?? "NaN" }
//
//  /**
//   Obtain a text representation of the given value.
//
//   - parameter value the numeric value to format
//   - returns the formatted value
//   */
//  public func format(value: Float) -> String { format(value: Double(value)) }

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

  static var defaultFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

extension NumberFormatter {
  public func format(value: Double) -> String { self.string(from: NSNumber(value: value)) ?? "NaN" }
  public func format(value: Float) -> String { format(value: Double(value)) }
}

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
}

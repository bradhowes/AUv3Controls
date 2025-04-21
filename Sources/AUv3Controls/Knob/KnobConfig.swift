import AVFoundation
import SwiftUI

/**
 Shabby attempt at isolating customizations for a `KnobFeature`. Right now there is a 1-1 relationship between this and
 an AUParameter instance. Appearance configuration has been split out into a separate `Theme` class, but there are
 still too many details here that would be better shared across `KnobFeature` instances.
 */
public struct KnobConfig: Equatable, Sendable {
  public static let `default` = KnobConfig()

  /// The height of the control (knob + title)
  public let controlHeight: CGFloat
  /// The diameter (width and height) of the knob
  public let controlDiameter: CGFloat
  /// The radius of the knob
  public var controlRadius: CGFloat { controlDiameter / 2.0 }
  /// The width of the standard knob value editor
  public let controlEditorWidth: CGFloat = 200
  /// How long to show the value in the knob's label
  public let controlShowValueDuration = 1.25
  /// Duration of the animation when changing between value and title in control label
  public let controlChangeAnimationDuration: TimeInterval = 0.35
  /**
   How much travel is need to change the knob from `minimumValue` to `maximumValue`.
   By default this is 2x the `controlSize` value. Setting it to 4 will require 4x the `controlSize` distance
   to go from `minimumValue` to `maximumValue`, thus making it more sensitive in general.
   */
  public let touchSensitivity: CGFloat
  /**
   Amount of time to wait with no more AUParameter changes before emitting the last one in the async stream of
   values. Reduces traffic at the expense of increased latency. Note that this is *not* the same as throttling where
   one limits the rate of emission but ultimately emits all events: debouncing drops all but the last event in a
   window of time.
   */
  public let debounceDuration: Duration

  public func controlWidthIf(_ value: Bool) -> CGFloat { value ? controlEditorWidth : controlDiameter }

  public func controlWidthIf<T>(_ value: T?) -> CGFloat { controlWidthIf(value != nil) }

  public init(
    controlDiameter: CGFloat = 100.0,
    controlHeight: CGFloat = 120.0,
    touchSensitivity: CGFloat = 2.0,
    debounceDuration: Duration = .milliseconds(10),
    valueFormatter: NumberFormatter? = nil
  ) {
    self.controlDiameter = controlDiameter
    self.controlHeight = controlHeight
    self.touchSensitivity = touchSensitivity
    self.debounceDuration = debounceDuration
    self.dragScaling = 1.0 / (controlDiameter * touchSensitivity)
    self.maxChangeRegionWidthHalf = max(8, controlDiameter * maxChangeRegionWidthPercentage) / 2
  }

  /**
   Percentage of `controlDiameter` where a touch/mouse event will perform maximum value change. This defines a
   vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
   over value changes.
   */
  private let maxChangeRegionWidthPercentage: CGFloat = 0.1
  private let maxChangeRegionWidthHalf: CGFloat
  private var dragScaling: CGFloat
}

extension KnobConfig {

  public func dragChangeValue(last: CGPoint, position: CGPoint) -> CGFloat {
    let dY = last.y - position.y
    // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
    let dX = min(abs(position.x - controlRadius), controlRadius - 1)
    // Calculate "scrubber" scaling effect, where the change in dx gets smaller the further away from the center one
    // moves the touch/pointer. No scaling if in +/- maxChangeRegionWidthHalf vertical path in the middle of the knob,
    // otherwise the value gets smaller than 1.0 as the touch moves farther away outside of the maxChangeRegionWidthHalf
    let scrubberScaling = (dX < maxChangeRegionWidthHalf
                           ? 1.0
                           : (1.0 - (dX - maxChangeRegionWidthHalf) / controlRadius))
    // Finally, calculate change to `norm` value
    return dY * dragScaling * scrubberScaling
  }
}

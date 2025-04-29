// Copyright © 2025 Brad Howes. All rights reserved.

import AudioUnit
import SwiftUI

/// Shared attributes for controls that represents some theme of an app/view.
public class Theme: @unchecked Sendable {

  public enum EditorStyle: Sendable {
    case original
    case grouped
  }

  /// The height of the control (knob + title)
  public let controlHeight: Double
  /// The diameter (width and height) of the knob
  public let controlDiameter: Double
  /// The radius of the knob
  public var controlRadius: Double { controlDiameter / 2.0 }
  /// The width of the standard knob value editor
  public let controlEditorWidth: Double = 200
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

  public func controlWidthIf(_ value: Bool) -> CGFloat { value ? controlEditorWidth : controlDiameter }
  public func controlWidthIf<T>(_ value: T?) -> CGFloat { controlWidthIf(value != nil) }

  /// The background color to use when drawing the control
  public var controlBackgroundColor: Color
  /// The foreground color to use when drawing the control
  public var controlForegroundColor: Color
  /// The color of any text components of the control
  public var textColor: Color
  /// The font to use for any text components of the control
  public var font: Font = .callout
  /// The indicator to use for a toggle control when the value is `true`
  public var toggleOnIndicatorSystemName: String = "circle.inset.filled"
  /// The indicator to use for a toggle control when the value is `false`
  public var toggleOffIndicatorSystemName: String = "circle"
  /// Stroke style to use when drawing the control track (backgound)
  public var controlTrackStrokeStyle: StrokeStyle
  /// Stroke style to use when drawiing the control value indicator (foreground)
  public var controlValueStrokeStyle: StrokeStyle {
    didSet {
      controlValueStrokeLineWidth = controlValueStrokeStyle.lineWidth
    }
  }
  /// The line width of the value stroke style
  private(set) public lazy var controlValueStrokeLineWidth: CGFloat = self.controlValueStrokeStyle.lineWidth {
    didSet {
      controlValueStrokeLineWidthHalf = controlValueStrokeLineWidth / 2
      controlIndicatorLength = max(controlIndicatorLength, controlValueStrokeLineWidthHalf)
    }
  }
  /// Half of the line width of the value stroke style
  private(set) public lazy var controlValueStrokeLineWidthHalf: CGFloat = controlValueStrokeLineWidth / 2
  /// The spacing to put between the knob control and the title below it
  public var controlTitleGap: CGFloat
  /// The length of the indicator at the end of the progress track. Positive value points toward the center of the
  /// track, negative values will point away from the center.
  public var controlIndicatorLength: CGFloat {
    didSet {
      controlIndicatorLength = max(controlIndicatorLength, controlValueStrokeLineWidthHalf)
    }
  }
  /// Starting angle for the Knob track0
  public var controlIndicatorStartAngle = Angle(degrees: 40) {
    didSet {
      controlIndicatorStartAngleNormalized = controlIndicatorStartAngle.normalized
    }
  }
  /// Normalized starting angle value for the knob track
  private(set) public lazy var controlIndicatorStartAngleNormalized: CGFloat = controlIndicatorStartAngle.normalized
  /// Ending angle for the Knob track
  public var controlIndicatorEndAngle = Angle(degrees: 320) {
    didSet {
      self.controlIndicatorEndAngleNormalized = controlIndicatorEndAngle.normalized
    }
  }
  /// Normalized ending angle for the knob track
  private(set) public lazy var controlIndicatorEndAngleNormalized: CGFloat = controlIndicatorEndAngle.normalized

  private(set) public lazy var controlIndicatorStartEndSpanRadians: CGFloat = (
    controlIndicatorEndAngle.radians - controlIndicatorStartAngle.radians
  )

  public let editorStyle: EditorStyle

  /**
   Initialize instance.

   - parameter bundle the Bundle to use for assets
   - parameter controlTrackStrokeStyle the stroke style to use when drawing the background track of a knob
   - parameter controlValueStrokeStyle the stroke style to use when drawing the value track of a knob
   */
  public init(
    bundle: Bundle? = nil,
    controlDiameter: CGFloat = 100.0,
    controlHeight: CGFloat = 120.0,
    controlTrackStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlValueStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlIndicatorLength: CGFloat = 16.0,
    controlTitleGap: CGFloat = 0.0,
    font: Font = .callout,
    parameterValueChanged: ((AUParameterAddress) -> Void)? = nil,
    editorStyle: EditorStyle = .original,
    touchSensitivity: CGFloat = 2.0,
  ) {
    self.controlDiameter = controlDiameter
    self.controlHeight = controlHeight
    self.controlBackgroundColor = Self.color(.controlBackgroundColor, from: bundle,
                                             default: .init(hex: "333333") ?? .gray)
    self.controlForegroundColor = Self.color(.controlForegroundColor, from: bundle,
                                             default: .init(hex: "FF9500") ?? .orange)
    self.textColor = Self.color(.textColor, from: bundle, default: .init(hex: "C08000") ?? .orange)
    self.controlTrackStrokeStyle = controlTrackStrokeStyle
    self.controlValueStrokeStyle = controlValueStrokeStyle
    self.controlIndicatorLength = max(controlValueStrokeStyle.lineWidth / 2, controlIndicatorLength)
    self.controlTitleGap = controlTitleGap
    self.font = font
    self.editorStyle = editorStyle
    self.touchSensitivity = touchSensitivity
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

private extension Theme {

  enum ColorTag: String {
    case controlBackgroundColor
    case controlForegroundColor
    case textColor
  }

  static func color(_ tag: ColorTag, from bundle: Bundle?, default: Color) -> Color {
    bundle != nil ? Color(tag.rawValue, bundle: bundle) : `default`
  }

  func color(tag: ColorTag) -> Color {
    switch tag {
    case .controlForegroundColor: return controlForegroundColor.disabled
    case .controlBackgroundColor: return controlBackgroundColor.disabled
    case .textColor: return textColor.disabled
    }
  }

  func disabled(tag: ColorTag) -> Color {
    color(tag: tag).disabled
  }
}

extension Color {

  var disabled: Color {
    @Environment(\.colorScheme) var colorScheme
    if #available(iOS 18.0, macOS 15.0, *) {
      return self.mix(with: colorScheme == .dark ? .black : .white, by: 0.5)
    } else {
      return self.mix_shim(with: colorScheme == .dark ? .black : .white, by: 0.5)
    }
  }
}

extension Theme {

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

extension Theme {
  public func endTrim(for norm: Double) -> Double {
    Angle(radians: norm * controlIndicatorStartEndSpanRadians + controlIndicatorStartAngle.radians).normalized
  }
}

extension Theme: Equatable {
  public static func == (lhs: Theme, rhs: Theme) -> Bool {
    lhs.controlBackgroundColor == rhs.controlBackgroundColor &&
    lhs.controlForegroundColor == rhs.controlForegroundColor &&
    lhs.textColor == rhs.textColor &&
    lhs.font == rhs.font &&
    lhs.toggleOnIndicatorSystemName == rhs.toggleOnIndicatorSystemName &&
    lhs.toggleOffIndicatorSystemName == rhs.toggleOffIndicatorSystemName &&
    lhs.controlTrackStrokeStyle == rhs.controlTrackStrokeStyle &&
    lhs.controlValueStrokeStyle == rhs.controlValueStrokeStyle &&
    lhs.controlTitleGap == rhs.controlTitleGap &&
    lhs.controlIndicatorLength == rhs.controlIndicatorLength &&
    lhs.controlIndicatorStartAngle == rhs.controlIndicatorStartAngle &&
    lhs.controlIndicatorEndAngle == rhs.controlIndicatorEndAngle
  }
}

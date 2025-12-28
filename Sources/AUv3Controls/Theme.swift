// Copyright © 2025 Brad Howes. All rights reserved.

import AudioUnit
import SwiftUI

/// Shared attributes for controls that represents some theme of an app/view.
public struct Theme: Sendable, Equatable {
  public let bundle: Bundle?
  public let prefix: String
  /// The width of the standard knob value editor. This is wide enough with the given font settings
  /// to show 20000.123456789
  public let controlEditorWidth: Double = 140
  /// How long to show the value in the knob's label
  public let controlShowValueDuration: TimeInterval = 1.25
  /// Duration of the animation when changing between value and title in control label
  public let controlChangeAnimationDuration: TimeInterval = 0.35
  /**
   How much travel is need to change the knob from `minimumValue` to `maximumValue`.
   By default this is 2x the `controlSize` value. Setting it to 4 will require 4x the `controlSize` distance
   to go from `minimumValue` to `maximumValue`, thus making it more sensitive in general.
   */
  public let touchSensitivity: Double
  /// The background color to use when drawing the control
  public var controlBackgroundColor: Color {
    Self.taggedColor(
      .controlBackgroundColor,
      in: bundle,
      prefix: prefix,
      default: .gray
    )
  }
  /// The foreground color to use when drawing the control
  public var controlForegroundColor: Color {
    Self.taggedColor(
      .controlForegroundColor,
      in: bundle,
      prefix: prefix,
      default: .orange
    )
  }
  /// The color of any text components of the control
  public var textColor: Color {
    Self.taggedColor(
      .textColor,
      in: bundle,
      prefix: prefix,
      default: .orange
    )
  }
  /// The background color to use for the value editor box
  public var editorBackgroundColor: Color {
    Self.taggedColor(
      .editorBackgroundColor,
      in: bundle,
      prefix: prefix,
      default: .gray
    )
  }
  /// The color to use for the Cancel button in the editor box
  public var editorCancelButtonColor: Color {
    Self.taggedColor(
      .editorCancelButtonColor,
      in: bundle,
      prefix: prefix,
      default: .yellow
    )
  }
    /// The color to use for the OK button in the editor box
  public var editorOKButtonColor: Color {
    Self.taggedColor(
      .editorOKButtonColor,
      in: bundle,
      prefix: prefix,
      default: .yellow
    )
  }
  /// The font to use for any text components of the control
  public var font: Font = .callout
  /// The indicator to use for a toggle control when the value is `true`
  public var toggleOnIndicatorSystemName: String = "circle.inset.filled"
  /// The indicator to use for a toggle control when the value is `false`
  public var toggleOffIndicatorSystemName: String = "circle"
  /// Stroke style to use when drawing the control track (backgound)
  public var controlTrackStrokeStyle: StrokeStyle
  /// Stroke style to use when drawiing the control value indicator (foreground)
  public var controlValueStrokeStyle: StrokeStyle
  /// The line width of the value stroke style
  public var controlValueStrokeLineWidth: Double { self.controlValueStrokeStyle.lineWidth }
  /// Half of the line width of the value stroke style
  public var controlValueStrokeLineWidthHalf: Double { controlValueStrokeLineWidth / 2 }
  /// The spacing to put between the knob control and the title below it
  public var controlTitleGap: Double
  /// The length of the indicator at the end of the progress track. Positive value points toward the center of the
  /// track, negative values will point away from the center.
  public var controlIndicatorLength: Double {
    didSet {
      controlIndicatorLength = max(controlIndicatorLength, controlValueStrokeLineWidthHalf)
    }
  }
  /// Starting angle for the Knob track
  public var controlIndicatorStartAngle: Angle {
    didSet {
      controlIndicatorStartAngleNormalized = controlIndicatorStartAngle.normalized
    }
  }
  /// Normalized starting angle value for the knob track
  private(set) public var controlIndicatorStartAngleNormalized: Double
  /// Ending angle for the Knob track
  public var controlIndicatorEndAngle: Angle {
    didSet {
      self.controlIndicatorEndAngleNormalized = controlIndicatorEndAngle.normalized
    }
  }
  /// Normalized ending angle for the knob track
  private(set) public var controlIndicatorEndAngleNormalized: Double

  public var controlIndicatorStartEndSpanRadians: Double {
    controlIndicatorEndAngle.radians - controlIndicatorStartAngle.radians
  }

  // WIP

  public func controlForegroundGradient(radius: Double) -> RadialGradient {
    .init(
      gradient: Gradient(colors: [.black, controlForegroundColor, .white]),
      center: .center,
      startRadius: radius - controlValueStrokeLineWidth * 1.5,
      endRadius: radius + controlValueStrokeLineWidth / 2
    )
  }

  public func controlBackgroundGradient(radius: Double) -> RadialGradient {
    .init(
      gradient: Gradient(colors: [.white, controlBackgroundColor, .black]),
      center: .center,
      startRadius: radius - controlValueStrokeLineWidth * 1.5,
      endRadius: radius + controlValueStrokeLineWidth / 2
    )
  }

  /**
   Percentage of `controlDiameter` where a touch/mouse event will perform maximum value change. This defines a
   vertical region in the middle of the view. Events outside of this region will have finer sensitivity and control
   over value changes.
   */
  public let maxChangeRegionWidthPercentage: Double

  /**
   Initialize instance.

   - parameter bundle the Bundle to use for assets
   - parameter controlTrackStrokeStyle the stroke style to use when drawing the background track of a knob
   - parameter controlValueStrokeStyle the stroke style to use when drawing the value track of a knob
   */
  public init(
    prefix: String = "",
    bundle: Bundle? = nil,
    controlTrackStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlValueStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlIndicatorLength: Double = 16.0,
    controlTitleGap: Double = 12.0,
    controlIndicatorStartAngle: Angle = Angle(degrees: 40.0),
    controlIndicatorEndAngle: Angle = Angle(degrees: 320.0),
    font: Font = .callout,
    parameterValueChanged: ((AUParameterAddress) -> Void)? = nil,
    touchSensitivity: Double = 2.0,
    maxChangeRegionWidthPercentage: Double = 0.1
  ) {
    self.bundle = bundle
    self.prefix = prefix
    self.controlTrackStrokeStyle = controlTrackStrokeStyle
    self.controlValueStrokeStyle = controlValueStrokeStyle
    self.controlIndicatorLength = max(controlValueStrokeStyle.lineWidth / 2, controlIndicatorLength)
    self.controlTitleGap = controlTitleGap
    self.font = font
    self.touchSensitivity = touchSensitivity
    self.maxChangeRegionWidthPercentage = maxChangeRegionWidthPercentage

    self.controlIndicatorStartAngle = controlIndicatorStartAngle
    self.controlIndicatorEndAngle = controlIndicatorEndAngle
    self.controlIndicatorStartAngleNormalized = controlIndicatorStartAngle.normalized
    self.controlIndicatorEndAngleNormalized = controlIndicatorEndAngle.normalized
  }
}

private extension Theme {

  enum ColorTag: String {
    case controlBackgroundColor
    case controlForegroundColor
    case editorBackgroundColor
    case editorCancelButtonColor
    case editorOKButtonColor
    case textColor
  }

  static func colorAssetName(prefix: String, tag: ColorTag) -> String {
    return (prefix.isEmpty ? prefix : prefix + "_") + tag.rawValue
  }

  static func taggedColor(_ tag: ColorTag, in bundle: Bundle?, prefix: String, default: Color) -> Color {
    guard let bundle = bundle else { return `default` }
    return Color(named: colorAssetName(prefix: prefix, tag: tag), bundle: bundle) ?? `default`
  }

  func color(tag: ColorTag) -> Color {
    switch tag {
    case .controlBackgroundColor: return controlBackgroundColor
    case .controlForegroundColor: return controlForegroundColor
    case .editorBackgroundColor: return editorBackgroundColor
    case .editorCancelButtonColor: return editorCancelButtonColor
    case .editorOKButtonColor: return editorOKButtonColor
    case .textColor: return textColor
    }
  }
}

extension Theme {
  public func endTrim(for norm: Double) -> Double {
    Angle(radians: norm * controlIndicatorStartEndSpanRadians + controlIndicatorStartAngle.radians).normalized
  }
}

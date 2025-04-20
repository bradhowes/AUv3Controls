import AudioUnit
import SwiftUI

/// Shared attributes for controls that represents some theme of an app/view.
public class Theme: @unchecked Sendable {

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
  public var controlValueStrokeStyle: StrokeStyle
  /// The spacing to put between the knob control and the title below it
  public var controlTitleGap: CGFloat
  /// The length of the indicator at the end of the progress track. Positive value points toward the center of the
  /// track, negative values will point away from the center.
  public var controlIndicatorLength: CGFloat
  /// Starting angle for a Knob track
  public var controlIndicatorStartAngle = Angle(degrees: 40)
  /// Ending angle for a Knob track
  public var controlIndicatorEndAngle = Angle(degrees: 320)

  /**
   Initialize instance.

   - parameter bundle the Bundle to use for assets
   - parameter controlTrackStrokeStyle the stroke style to use when drawing the background track of a knob
   - parameter controlValueStrokeStyle the stroke style to use when drawing the value track of a knob
   */
  public init(
    bundle: Bundle? = nil,
    controlTrackStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlValueStrokeStyle: StrokeStyle = .init(lineWidth: 10.0, lineCap: .round),
    controlIndicatorLength: CGFloat = 16.0,
    controlTitleGap: CGFloat = 0.0,
    font: Font = .callout,
    parameterValueChanged: ((AUParameterAddress) -> Void)? = nil
  ) {
    self.controlBackgroundColor = Self.color(.controlBackgroundColor, from: bundle,
                                             default: .init(hex: "333333") ?? .gray)
    self.controlForegroundColor = Self.color(.controlForegroundColor, from: bundle,
                                             default: .init(hex: "FF9500") ?? .orange)
    self.textColor = Self.color(.textColor, from: bundle, default: .init(hex: "C08000") ?? .orange)
    self.controlTrackStrokeStyle = controlTrackStrokeStyle
    self.controlValueStrokeStyle = controlValueStrokeStyle
    self.controlIndicatorLength = controlIndicatorLength
    self.controlTitleGap = controlTitleGap
    self.font = font
  }
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

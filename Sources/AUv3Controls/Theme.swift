import SwiftUI

/// Shared attributes for controls that represents some theme of an app/view.
public class Theme {

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
  /// The formatter to use when creating textual representations of a control's numeric value
  public var formatter: NumberFormatter
  /// Stroke style to use when drawing the control track (backgound)
  public var controlTrackStrokeStyle: StrokeStyle
  /// Stroke style to use when drawiing the control value indicator (foreground)
  public var controlValueStrokeStyle: StrokeStyle
  /// The spacing to put between the knob control and the title below it
  public var controlTitleGap: CGFloat
  /// The length of the indicator at the end of the progress track. Positive value points toward the center of the
  /// track, negative values will point away from the center.
  public var controlIndicatorLength: CGFloat

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
    valueFormatter: NumberFormatter? = nil
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
    self.formatter = valueFormatter ?? Self.defaultFormatter
  }

  /**
   Obtain a text representation of the given value. Uses the existing `formatter` to do the generation.

   - parameter value the numeric value to format
   - returns the formatted value
   */
  public func format(value: Double) -> String { formatter.string(from: NSNumber(value: value)) ?? "NaN" }
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

  static var defaultFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

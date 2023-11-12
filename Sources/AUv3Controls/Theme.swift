import SwiftUI

/// Experiment to extract out attributes that would be part of some theme of an app/view

public struct Theme: Equatable {

  public let controlBackgroundColor: Color
  public let controlForegroundColor: Color
  public let textColor: Color
  public let font: Font = .callout

  public let toggleOnIndicatorSystemName: String = "circle.inset.filled"
  public let toggleOffIndicatorSystemName: String = "circle"

  public let formatter: NumberFormatter

  public enum ColorTag: String {
    case controlBackgroundColor
    case controlForegroundColor
    case textColor
  }

  public init(bundle: Bundle? = nil, valueFormatter: NumberFormatter? = nil) {
    controlBackgroundColor = Self.color(.controlBackgroundColor, from: bundle, default: .init(hex: "333333"))
    controlForegroundColor = Self.color(.controlForegroundColor, from: bundle, default: .init(hex: "FF9500"))
    textColor = Self.color(.textColor, from: bundle, default: .init(hex: "C08000"))
    formatter = valueFormatter ?? Self.formatter
  }

  func format(value: Double) -> String { formatter.string(from: NSNumber(value: value)) ?? "NaN" }

  private static func color(_ tag: ColorTag, from bundle: Bundle?, default: Color) -> Color {
    bundle != nil ? Color(tag.rawValue, bundle: bundle) : `default`
  }

  static private var formatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    return formatter
  }
}

import SwiftUI

/// Experiment to extract out attributes that would be part of some theme of an app/view

public enum ThemeColorTag: String {
  case controlBackgroundColor
  case controlForegroundColor
  case textColor
}

public protocol ThemeProtocol: Equatable {

  var controlBackgroundColor: Color { get }
  var controlForegroundColor: Color { get }
  var textColor: Color { get }
  var font: Font { get }

  var toggleOnIndicatorSystemName: String { get }
  var toggleOffIndicatorSystemName: String { get }

  var formatter: NumberFormatter { get }
}

public struct Theme: ThemeProtocol {

  public let controlBackgroundColor: Color
  public let controlForegroundColor: Color
  public let textColor: Color
  public let font: Font = .callout

  public let toggleOnIndicatorSystemName: String = "circle.inset.filled"
  public let toggleOffIndicatorSystemName: String = "circle"

  public let formatter: NumberFormatter

  public init(bundle: Bundle? = nil, valueFormatter: NumberFormatter? = nil) {
    controlBackgroundColor = Self.color(.controlBackgroundColor, from: bundle, default: .init(hex: "333333"))
    controlForegroundColor = Self.color(.controlForegroundColor, from: bundle, default: .init(hex: "FF9500"))
    textColor = Self.color(.textColor, from: bundle, default: .init(hex: "C08000"))
    formatter = valueFormatter ?? Self.formatter
  }

  func format(value: Double) -> String { formatter.string(from: NSNumber(floatLiteral: value)) ?? "NaN" }

  private static func color(_ tag: ThemeColorTag, from bundle: Bundle?, default: Color) -> Color {
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

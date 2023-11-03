import SwiftUI

public struct Theme: Equatable {

  public let controlBackgroundColor: Color
  public let controlForegroundColor: Color
  public let textColor: Color
  public let font: Font = .callout
  public let toggleOnIndicator = "circle.inset.filled"
  public let toggleOffIndicator = "circle"

  public init(bundle: Bundle? = nil) {
    controlBackgroundColor = Self.color(name: "controlBackgroundColor", bundle: bundle,
                                        default: Color(hex: "333333"))
    controlForegroundColor = Self.color(name: "controlForegroundColor", bundle: bundle,
                                        default: Color(hex: "FF9500"))
    textColor = Self.color(name: "textColor", bundle: bundle, default: Color(hex: "C08000"))

  }

  private static func color(name: String, bundle: Bundle?, default: Color) -> Color {
    bundle != nil ? Color(name, bundle: bundle) : `default`
  }
}


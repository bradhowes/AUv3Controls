import SwiftUI

public struct CheckedToggleStyle: ToggleStyle {

  public let indicatorColor: Color
  public let labelColor: Color

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      Label {
        configuration.label
      } icon: {
        Image(systemName: configuration.isOn ? "circle.inset.filled" : "circle")
          .foregroundColor(indicatorColor)
          .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
          .imageScale(.large)
      }
    }
    .buttonStyle(.plain)
    .foregroundColor(labelColor)
  }
}

extension ToggleStyle where Self == CheckedToggleStyle {
  static public func checked(indicatorColor: Color, labelColor: Color) -> CheckedToggleStyle {
    .init(indicatorColor: indicatorColor, labelColor: labelColor)
  }
}

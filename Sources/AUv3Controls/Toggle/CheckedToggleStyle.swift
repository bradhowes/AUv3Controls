import SwiftUI

public struct CheckedToggleStyle: ToggleStyle {

  public let theme: Theme

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      Label {
        configuration.label
      } icon: {
        Image(systemName: configuration.isOn ? theme.toggleOnIndicatorSystemName : theme.toggleOffIndicatorSystemName)
          .foregroundColor(theme.controlForegroundColor)
          .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
          .imageScale(.large)
      }
    }
    .buttonStyle(.plain)
    .foregroundColor(theme.textColor)
  }
}

extension ToggleStyle where Self == CheckedToggleStyle {
  static public func checked(theme: Theme) -> CheckedToggleStyle {
    .init(theme: theme)
  }
}

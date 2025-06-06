// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 A custom toggle style that shows an image and the label. Pretty much taken from comment block for ToggleStyle but
 with theme additions.
 */
public struct CheckedToggleStyle: ToggleStyle {

  public let theme: Theme

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: configuration.isOn ? theme.toggleOnIndicatorSystemName : theme.toggleOffIndicatorSystemName)
          .foregroundColor(theme.controlForegroundColor)
          .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
          .animation(.smooth, value: configuration.isOn)
        configuration.label
          .font(theme.font)
          .foregroundStyle(theme.textColor)
          .animation(.smooth, value: configuration.isOn)
      }
    }
    .buttonStyle(.borderless)
    .foregroundColor(theme.textColor)
  }
}

extension ToggleStyle where Self == CheckedToggleStyle {
  static public func checked(theme: Theme) -> CheckedToggleStyle {
    .init(theme: theme)
  }
}
